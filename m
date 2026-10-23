From: Daejun Park <daejun7.park@samsung.com>
Date: Fri, 23 Oct 2026 11:10:23 +0900
Subject: [PATCH v2 2/4] nfsd: resend a layout recall once before trusting
 NOMATCHING_LAYOUT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-nfsd-layout-refcall-v2-2-2160bddced0c@samsung.com>
References: <20261023-nfsd-layout-refcall-v2-0-2160bddced0c@samsung.com>
In-Reply-To: <20261023-nfsd-layout-refcall-v2-0-2160bddced0c@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <ben.coddington@hammerspace.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792721421; l=17899;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=kOmvM+6LAwF5h2tgKzc/ZfMJdDK9z8svYelvajNxF0c=;
 b=ue73yf5Ejs5qkBscbqq/qS9HpyX5ZZdPqedJ1a9jeSnVCgbWFzA+AHyrnjg8hHorSevxLWJKq
 9kCLoBYw5d5BtsG9AgDGtNJOL7ZFMhsEqRpZga2AhqLUtzDBlnyZQC4
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the lease of a layout is broken right after nfsd has handed the
layout out, the CB_LAYOUTRECALL can reach the client before the reply to
the LAYOUTGET. A client that does not know the layout stateid yet
answers NFS4ERR_NOMATCHING_LAYOUT, nfsd4_cb_layout_done() takes that as
the end of the recall and drops the layouts, and the client then gets
the reply and writes through a layout that the server no longer has.

The Linux client loses those writes. Its next LAYOUTGET with that layout
stateid gets NFS4ERR_BAD_STATEID, and it calls
pnfs_mark_layout_stateid_invalid(), which clears NFS_INO_LAYOUTCOMMIT
and the layout segments; the block layout driver drops the extents it
has written through the layout with the layout header. No LAYOUTCOMMIT
is sent for them, they stay unwritten extents on the server, they read
back as zeroes, and fsync() on the client succeeds.

Since "nfsd: fail a LAYOUTGET in progress when the layout lease is
broken", a lease break that meets the LAYOUTGET before it has added its
layout fails it, so the recall can only overtake the reply to a
LAYOUTGET that has added its layout. In three traced runs of the test
below without a delay on the client, a recall overtook a reply once, and
the client lost that block; with a test-only delay of one second it lost
every block whose reply the recall overtook.

The delegation code has the same problem with NFS4ERR_BAD_STATEID [1].
It trusts the answer if the slot that carried the grant had retired when
the recall was sent, and otherwise sends the recall once more after two
seconds. Do the same for layouts. The layouts of a layout stateid can
come from several LAYOUTGETs on several slots, so the layout stateid
keeps a record of each LAYOUTGET that added a layout or merged into
one. nfsd4_layoutget() allocates the record before
->proc_layoutget() allocates any blocks, and fails with NFS4ERR_DELAY
if it cannot, so that no layout goes out without one. Once the layout
has been added, nfsd4_record_layout_grant() puts the record on the list
while ls_mutex, which nfsd4_cb_layout_prepare() takes as well, is still
held. Records whose slots have retired are dropped there and in
->prepare, which notes whether any is left. When the client answers
NFS4ERR_NOMATCHING_LAYOUT while layouts are left, a record was left at
the send and the client has not answered NFS4_OK to this recall, ->done
sends the recall once more after two seconds. The Linux client frees
the slot of a LAYOUTGET only after pnfs_layout_process() has taken the
layout in.

Only the first LAYOUTGET of a layout stateid can meet a client that
does not know it, as every later one presents the layout stateid. A
client that has sent a later one tells a reply that arrives late by its
seqid (RFC 8881 section 12.5.5.2.1.2). So the list keeps the latest
NFSD4_LAYOUT_MAX_GRANTS (eight) records and drops the oldest one past
that. Records of a destroyed session, which never show as retired, leave
the same way.

The resend repeats the request with its seqid, as the polls do, although
RFC 8881 section 12.5.3 has a new seqid for each request: a client that
did not take the request in expects that seqid next, whether or not it
has processed the LAYOUTGET reply since, and the Linux client answers a
seqid that skips one with NFS4ERR_DELAY unless the recall names
referring calls that are complete, which this patch does not send.

A client that took the request in answers the resend with
NFS4ERR_OLD_STATEID: when the Linux client has the layout stateid but no
layout segment that the recall matches, initiate_file_draining() takes
in the seqid of the recall before it answers NFS4ERR_NOMATCHING_LAYOUT.
"nfsd: keep polling a layout recall answered with NFS4ERR_OLD_STATEID"
has the polls carry a new seqid then, which the client answers afresh. A
LAYOUTRETURN during the delay that returns the last layout does not stop
the resend, but the answer to it then ends the recall without fencing
the client, as "nfsd: do not fence a client for a layout recall with no
layouts left" has it. The resend is traced as nfsd_layout_recall_resend.

The answer to the resend is trusted, where the delegation code trusts it
only if the slot has retired by then and otherwise leaves the delegation
to the laundromat, which revokes it. The counterpart for a layout is to
poll until the slot retires, which an idle Linux client does only with
its lease renewal, two thirds of a lease period after its last request,
and only on its lowest free slot. Every LAYOUTGET for the file fails
meanwhile, and a recall that comes from a lease break has the client
fenced after fs.lease-break-time, also when it really has no layout.

The resend covers a client that takes the reply in within the two
seconds before it; a client that takes longer still loses the data. The
next patch lets a client that honors referring calls hold the recall
back instead.

The resend costs the writer that broke the lease. A pNFS block layout
client writes 1 MiB blocks with O_DIRECT to a new file for 60 seconds
while an NFSv4.0 client writes to another range of it, so that the
writes of the NFSv4.0 client keep breaking the layout lease. With a
test-only delay of one second in the pNFS client before
pnfs_layout_process(), 13 of 57 and 14 of 58 blocks written through a
layout read back as zeroes in two runs, each one a block whose
LAYOUTGET reply the recall overtook. With this patch none did (30 and
41 blocks), although the recall overtook the reply 3 times in each run.
The NFSv4.0 client wrote all its 600 blocks in 14.6 and 15.0 seconds
without this patch and in 21.2 and 20.9 seconds with it: each recall
that overtook a reply lasted two seconds longer, and the WRITEs of the
NFSv4.0 client got NFS4ERR_DELAY meanwhile. With fs.lease-break-time at
two seconds or less, a resent recall can outlast the lease break and
have the client fenced, also one that really has no layout, where the
recall used to end at its first answer.

The writer pays also when the client that holds the layout is idle: in a
test where a client read a file, kept it open and did no further I/O
while another client wrote to it, the write ended 11.8 seconds after the
first read with this patch and 8.8 seconds after it without; the writer
starts 8 seconds after the reader starts. The idle client answered
NFS4ERR_NOMATCHING_LAYOUT to the recall and to the resend. That stays so
with the referring call of the next patch: a client that processed the
reply long ago finds the referring call complete and answers
NFS4ERR_NOMATCHING_LAYOUT again (11.9 seconds with the whole series),
and nfsd cannot tell a client that waits for referring calls from one
that does not.

This needs the previous patch, and with it [1], and from "nfsd: layout
recall and lease break fixes" the patches named above: without
"nfsd: keep polling a layout recall answered with NFS4ERR_OLD_STATEID",
the NFS4ERR_OLD_STATEID answer to the resend has the client fenced.

Link: https://lore.kernel.org/r/20260802-nfsd-deleg-destroy-badhandle-v1-8-323aa7196055@kernel.org # [1]
Link: https://lore.kernel.org/r/20261015-nfsd-layout-recall-v3-0-ba3269f8ca22@samsung.com
Fixes: c5c707f96fc9 ("nfsd: implement pNFS layout recalls")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 107 +++++++++++++++++++++++++++++++++++++++++++++++++-
 fs/nfsd/nfs4proc.c    |  12 ++++++
 fs/nfsd/pnfs.h        |   3 ++
 fs/nfsd/state.h       |  20 ++++++++++
 fs/nfsd/trace.h       |   1 +
 5 files changed, 141 insertions(+), 2 deletions(-)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index 679da5ba96..fdce9ddeba 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -238,6 +238,7 @@ nfsd4_free_layout_stateid(struct nfs4_stid *stid)
 	struct nfs4_layout_stateid *ls = layoutstateid(stid);
 	struct nfs4_client *clp = ls->ls_stid.sc_client;
 	struct nfs4_file *fp = ls->ls_stid.sc_file;
+	struct nfsd4_layout_grant *lg, *next;
 
 	trace_nfsd_layoutstate_free(&ls->ls_stid.sc_stateid);
 
@@ -254,6 +255,8 @@ nfsd4_free_layout_stateid(struct nfs4_stid *stid)
 	if (ls->ls_recalled)
 		atomic_dec(&ls->ls_stid.sc_file->fi_lo_recalls);
 
+	list_for_each_entry_safe(lg, next, &ls->ls_grants, lg_list)
+		kfree(lg);
 	kmem_cache_free(nfs4_layout_stateid_cache, ls);
 }
 
@@ -310,6 +313,7 @@ nfsd4_alloc_layout_stateid(struct nfsd4_compound_state *cstate,
 	INIT_LIST_HEAD(&ls->ls_perfile);
 	spin_lock_init(&ls->ls_lock);
 	INIT_LIST_HEAD(&ls->ls_layouts);
+	INIT_LIST_HEAD(&ls->ls_grants);
 	mutex_init(&ls->ls_mutex);
 	mutex_init(&ls->ls_fence_mutex);
 	ls->ls_layout_type = layout_type;
@@ -592,6 +596,66 @@ nfsd4_insert_layout(struct nfsd4_layoutget *lgp, struct nfs4_layout_stateid *ls)
 	return nfserr;
 }
 
+/* Forget the LAYOUTGETs whose replies the client has seen. */
+static void
+nfsd4_prune_layout_grants(struct nfs4_layout_stateid *ls)
+{
+	struct nfs4_client *clp = ls->ls_stid.sc_client;
+	struct nfsd4_layout_grant *lg, *next;
+
+	lockdep_assert_held(&ls->ls_mutex);
+	list_for_each_entry_safe(lg, next, &ls->ls_grants, lg_list) {
+		if (nfsd41_grant_slot_retired(clp, &lg->lg_slot)) {
+			list_del(&lg->lg_list);
+			kfree(lg);
+		}
+	}
+}
+
+/**
+ * nfsd4_record_layout_grant - remember a LAYOUTGET that added a layout
+ * @ls: layout stateid that the LAYOUTGET added a layout to or merged into
+ * @lg: record for the LAYOUTGET, which @ls takes over
+ * @cstate: compound state of the LAYOUTGET
+ *
+ * RFC 8881 section 2.10.6.3 has a recall carry every such request until
+ * its slot retires. Keeping the latest NFSD4_LAYOUT_MAX_GRANTS instead
+ * bounds the record and the CB_LAYOUTRECALL request. Every LAYOUTGET
+ * after the first one of a layout stateid presents that layout stateid,
+ * so a layout stateid with more than one record is known to the client,
+ * which tells a reply that arrives late by its seqid (RFC 8881 section
+ * 12.5.5.2.1.2); the Linux client drops such a reply
+ * (pnfs_layout_stateid_blocked()). Past NFSD4_LAYOUT_MAX_GRANTS, the
+ * oldest record goes; that is also how records of a destroyed session,
+ * which never show as retired, leave.
+ *
+ * Context: Caller holds ls_mutex, which nfsd4_cb_layout_prepare() takes
+ * as well, so that a recall of the new layout finds the LAYOUTGET
+ * recorded. Takes nn->client_lock.
+ */
+void
+nfsd4_record_layout_grant(struct nfs4_layout_stateid *ls,
+			  struct nfsd4_layout_grant *lg,
+			  const struct nfsd4_compound_state *cstate)
+{
+	struct nfsd4_layout_grant *old;
+
+	nfsd4_prune_layout_grants(ls);
+	if (list_count_nodes(&ls->ls_grants) >= NFSD4_LAYOUT_MAX_GRANTS) {
+		old = list_first_entry(&ls->ls_grants,
+				       struct nfsd4_layout_grant, lg_list);
+		list_del(&old->lg_list);
+		kfree(old);
+	}
+	lg->lg_slot.valid = false;
+	nfsd41_record_grant_slot(&lg->lg_slot, cstate);
+	if (!lg->lg_slot.valid) {
+		kfree(lg);
+		return;
+	}
+	list_add_tail(&lg->lg_list, &ls->ls_grants);
+}
+
 static void
 nfsd4_free_layouts(struct list_head *reaplist)
 {
@@ -883,8 +947,16 @@ nfsd4_cb_layout_prepare(struct nfsd4_callback *cb)
 
 	mutex_lock(&ls->ls_mutex);
 	nfs4_inc_and_copy_stateid(&ls->ls_recall_sid, &ls->ls_stid);
+	/*
+	 * nfsd4_layoutget() records each LAYOUTGET that adds a layout
+	 * under ls_mutex. With none left whose slot has not retired, there
+	 * is no reply to wait for.
+	 */
+	nfsd4_prune_layout_grants(ls);
+	ls->ls_recall_retired_at_send = list_empty(&ls->ls_grants);
 	mutex_unlock(&ls->ls_mutex);
 	ls->ls_recall_accepted = false;
+	ls->ls_recall_resent = false;
 	return true;
 }
 
@@ -915,8 +987,10 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 		 * The poll reuses the recall's seqid, against RFC 8881
 		 * section 12.5.3, so a client returning its layouts answers
 		 * NFS4ERR_OLD_STATEID too. A client that has not taken the
-		 * recall up is past that seqid, e.g. after a LAYOUTRETURN,
-		 * and gets a new one. ls_mutex could block rpciod, so the bump
+		 * recall up is past that seqid and gets a new one: after a
+		 * LAYOUTRETURN, or when the resend below repeats the seqid of a
+		 * recall that the Linux client took in although it matched no
+		 * layout segment. ls_mutex could block rpciod, so the bump
 		 * relies on sc_lock.
 		 */
 		if (!ls->ls_recall_accepted) {
@@ -994,6 +1068,35 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 		}
 		return 1;
 	case -NFS4ERR_NOMATCHING_LAYOUT:
+		/*
+		 * The recall can reach the client before the reply to a
+		 * LAYOUTGET that added a layout, and a client that has not
+		 * processed that reply answers this way too. As the
+		 * delegation code does for NFS4ERR_BAD_STATEID, trust the
+		 * answer if the slots of the LAYOUTGETs had retired when the
+		 * recall was sent, and send the recall once more after a
+		 * delay otherwise. Unlike the delegation code, trust the
+		 * answer to that resend: not trusting it would end in fencing
+		 * the client, and an idle client leaves its slot unretired
+		 * also when it has no layout. A client that has not
+		 * processed the reply by the resend still has its layout
+		 * dropped. A client that has answered NFS4_OK to this recall
+		 * knew the layout stateid, so its answer to a poll is trusted
+		 * at once.
+		 *
+		 * The resend repeats the request with its seqid, as the polls
+		 * do, although RFC 8881 section 12.5.3 has a new one for each
+		 * request: a client that did not take the request in expects
+		 * that seqid next, and a client that did answers
+		 * NFS4ERR_OLD_STATEID, which the polls handle.
+		 */
+		if (!list_empty(&ls->ls_layouts) && !ls->ls_recall_accepted &&
+		    !ls->ls_recall_retired_at_send && !ls->ls_recall_resent) {
+			ls->ls_recall_resent = true;
+			trace_nfsd_layout_recall_resend(&ls->ls_recall_sid);
+			rpc_delay(task, 2 * HZ);
+			return 0;
+		}
 		trace_nfsd_layout_recall_done(&ls->ls_stid.sc_stateid);
 		task->tk_status = 0;
 		return 1;
diff --git a/fs/nfsd/nfs4proc.c b/fs/nfsd/nfs4proc.c
index a50f9dcb3a..c4c451dc0a 100644
--- a/fs/nfsd/nfs4proc.c
+++ b/fs/nfsd/nfs4proc.c
@@ -2904,6 +2904,7 @@ nfsd4_layoutget(struct svc_rqst *rqstp,
 	struct svc_fh *current_fh = &cstate->current_fh;
 	const struct nfsd4_layout_ops *ops;
 	struct nfs4_layout_stateid *ls;
+	struct nfsd4_layout_grant *lg = NULL;
 	__be32 nfserr;
 	int accmode = NFSD_MAY_READ_IF_EXEC | NFSD_MAY_OWNER_OVERRIDE;
 
@@ -2962,16 +2963,27 @@ nfsd4_layoutget(struct svc_rqst *rqstp,
 	if (atomic_read(&ls->ls_stid.sc_file->fi_lo_recalls))
 		goto out_put_stid;
 
+	/* Allocate the record first, so that every layout handed out has one */
+	nfserr = nfserr_jukebox;
+	lg = kmalloc_obj(*lg);
+	if (!lg)
+		goto out_put_stid;
+
 	nfserr = ops->proc_layoutget(rqstp, d_inode(current_fh->fh_dentry),
 				     current_fh, lgp);
 	if (nfserr)
 		goto out_put_stid;
 
 	nfserr = nfsd4_insert_layout(lgp, ls);
+	if (!nfserr) {
+		nfsd4_record_layout_grant(ls, lg, cstate);
+		lg = NULL;
+	}
 
 out_put_stid:
 	mutex_unlock(&ls->ls_mutex);
 	nfs4_put_stid(&ls->ls_stid);
+	kfree(lg);
 out:
 	return nfserr;
 }
diff --git a/fs/nfsd/pnfs.h b/fs/nfsd/pnfs.h
index e5f2e11c88..b2fcc28bf2 100644
--- a/fs/nfsd/pnfs.h
+++ b/fs/nfsd/pnfs.h
@@ -61,6 +61,9 @@ __be32 nfsd4_preprocess_layout_stateid(struct svc_rqst *rqstp,
 		bool create, u32 layout_type, struct nfs4_layout_stateid **lsp);
 __be32 nfsd4_insert_layout(struct nfsd4_layoutget *lgp,
 		struct nfs4_layout_stateid *ls);
+void nfsd4_record_layout_grant(struct nfs4_layout_stateid *ls,
+		struct nfsd4_layout_grant *lg,
+		const struct nfsd4_compound_state *cstate);
 __be32 nfsd4_return_file_layouts(struct svc_rqst *rqstp,
 		struct nfsd4_compound_state *cstate,
 		struct nfsd4_layoutreturn *lrp);
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index 2c00b334c3..b3338cf171 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -848,6 +848,15 @@ static inline struct nfs4_ol_stateid *openlockstateid(struct nfs4_stid *s)
 
 struct nfsd4_fence_script;
 
+/* A LAYOUTGET that added a layout, until its slot retires */
+struct nfsd4_layout_grant {
+	struct list_head		lg_list;
+	struct nfsd4_grant_slot		lg_slot;
+};
+
+/* The most LAYOUTGETs that a layout stateid keeps records of */
+#define NFSD4_LAYOUT_MAX_GRANTS		8
+
 struct nfs4_layout_stateid {
 	struct nfs4_stid		ls_stid;
 	struct list_head		ls_perclnt;
@@ -863,6 +872,17 @@ struct nfs4_layout_stateid {
 	bool				ls_recall_accepted;
 	bool				ls_recalled;
 	struct mutex			ls_mutex;
+	/*
+	 * The latest NFSD4_LAYOUT_MAX_GRANTS LAYOUTGETs that added a
+	 * layout to this layout stateid or merged into one, and whose
+	 * slots had not retired when last looked at. Under ls_mutex.
+	 * Until a slot retires, the client may not have processed the reply
+	 * to the LAYOUTGET it carried.
+	 */
+	struct list_head		ls_grants;
+	/* Recall state for ->done, reset in ->prepare */
+	bool				ls_recall_retired_at_send;
+	bool				ls_recall_resent;
 
 	struct delayed_work		ls_fence_work;
 	struct mutex			ls_fence_mutex; /* serializes fence shutdown */
diff --git a/fs/nfsd/trace.h b/fs/nfsd/trace.h
index 951af645d1..a2c21d491a 100644
--- a/fs/nfsd/trace.h
+++ b/fs/nfsd/trace.h
@@ -830,6 +830,7 @@ DEFINE_STATEID_EVENT(layout_return_lookup_fail);
 DEFINE_STATEID_EVENT(layout_recall);
 DEFINE_STATEID_EVENT(layout_recall_empty);
 DEFINE_STATEID_EVENT(layout_recall_done);
+DEFINE_STATEID_EVENT(layout_recall_resend);
 DEFINE_STATEID_EVENT(layout_recall_new_seqid);
 DEFINE_STATEID_EVENT(layout_recall_fail);
 DEFINE_STATEID_EVENT(layout_recall_release);

-- 
2.43.0

