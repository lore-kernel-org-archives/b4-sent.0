From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 21 Oct 2026 10:03:04 +0900
Subject: [PATCH 2/4] nfsd: resend a layout recall once before trusting
 NOMATCHING_LAYOUT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-nfsd-layout-refcall-v1-2-797096b92377@samsung.com>
References: <20261021-nfsd-layout-refcall-v1-0-797096b92377@samsung.com>
In-Reply-To: <20261021-nfsd-layout-refcall-v1-0-797096b92377@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <ben.coddington@hammerspace.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792544582; l=11784;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=1awGlEX3eaa62kNCVXfBAkAaQI+ZyZMa5d0+Jm6EidI=;
 b=ed8Co4rP8FG0WBEIYDC7ASPctXJGM3QIHi9LrxmoKOcA/WQmuORjxCtY+JPabjuyeFyB/qhVd
 w6gz2hm8NrpAW5wVWfTfQvpLA5I+J8s5QHJQsRjGZlmfEQDqgCMRv4o
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
LAYOUTGET that has added its layout. In eight traced runs of the test
below without a delay on the client, no recall overtook a reply; with a
test-only delay of one second the client lost every block whose reply
the recall overtook.

The delegation code has the same problem with NFS4ERR_BAD_STATEID [1].
It trusts the answer if the slot that carried the grant had retired when
the recall was sent, and otherwise sends the recall once more after two
seconds. Do the same for layouts. nfsd4_layoutget() records the slot of
the request in the layout stateid once the layout has been added, while
it still holds ls_mutex, which nfsd4_cb_layout_prepare() takes as well.
->prepare notes whether that slot had retired, and when the client
answers NFS4ERR_NOMATCHING_LAYOUT while layouts are left, the slot had
not retired and the client has not answered NFS4_OK to this recall,
->done sends the recall once more after two seconds. The Linux client
frees the slot of a LAYOUTGET only after pnfs_layout_process() has taken
the layout in.

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
poll until the slot retires and fence the client after two lease
periods, and a client that is idle leaves its slot unretired also when
it really has no layout.

The resend covers a client that takes the reply in within the two
seconds before it; a client that takes longer still loses the data. The
next patch lets a client that honors referring calls hold the recall
back instead.

The resend costs the writer that broke the lease. A pNFS block layout
client writes 1 MiB blocks with O_DIRECT to a new file for 60 seconds
while an NFSv4.0 client writes to another range of it, so that the
writes of the NFSv4.0 client keep breaking the layout lease. With a
test-only delay of one second in the pNFS client before
pnfs_layout_process(), 14 of 58 and 14 of 57 blocks written through a
layout read back as zeroes in two runs, each one a block whose LAYOUTGET
reply the recall overtook. With this patch none did (27 and 26 blocks),
although the recall overtook the reply 11 and 18 times. The NFSv4.0
client wrote all its 600 blocks in 15.0 and 15.3 seconds without this
patch and in 37.8 and 51.9 seconds with it: each recall that overtook a
reply lasted two seconds longer, and the WRITEs of the NFSv4.0 client
got NFS4ERR_DELAY meanwhile. With fs.lease-break-time at two seconds or
less, a resent recall can outlast the lease break and have the client
fenced, also one that really has no layout, where the recall used to end
at its first answer. Without the delay, both clients wrote all their 600
blocks in each of three traced runs of 30 seconds with this patch, and
no recall overtook a reply.

The writer pays also when the client that holds the layout is idle: in a
test where a client read a file, kept it open and did no further I/O
while another client wrote to it, the write ended 12.1 seconds after the
first read with this patch and 8.8 seconds after it without; the writer
starts 8 seconds after the reader starts. The idle client answered
NFS4ERR_NOMATCHING_LAYOUT to the recall and to the resend.

This needs the previous patch, and with it [1], and from "nfsd: layout
recall and lease break fixes" [2] the patches named above: without
"nfsd: keep polling a layout recall answered with NFS4ERR_OLD_STATEID",
the NFS4ERR_OLD_STATEID answer to the resend has the client fenced.

Link: https://lore.kernel.org/r/20260802-nfsd-deleg-destroy-badhandle-v1-8-323aa7196055@kernel.org # [1]
Link: https://lore.kernel.org/r/20261015-nfsd-layout-recall-v3-0-ba3269f8ca22@samsung.com # [2]
Fixes: c5c707f96fc9 ("nfsd: implement pNFS layout recalls")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 45 +++++++++++++++++++++++++++++++++++++++++++--
 fs/nfsd/nfs4proc.c    |  6 ++++++
 fs/nfsd/state.h       | 10 ++++++++++
 fs/nfsd/trace.h       |  1 +
 4 files changed, 60 insertions(+), 2 deletions(-)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index 679da5ba96..78ce4fc94d 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -330,6 +330,7 @@ nfsd4_alloc_layout_stateid(struct nfsd4_compound_state *cstate,
 	}
 
 	ls->ls_recall_start = 0;
+	ls->ls_grant.valid = false;
 	ls->ls_fenced = false;
 	ls->ls_fence_inflight = false;
 	ls->ls_fence_stopped = false;
@@ -880,11 +881,22 @@ nfsd4_cb_layout_prepare(struct nfsd4_callback *cb)
 {
 	struct nfs4_layout_stateid *ls =
 		container_of(cb, struct nfs4_layout_stateid, ls_recall);
+	struct nfs4_client *clp = ls->ls_stid.sc_client;
+	struct nfsd4_grant_slot grant;
 
 	mutex_lock(&ls->ls_mutex);
 	nfs4_inc_and_copy_stateid(&ls->ls_recall_sid, &ls->ls_stid);
+	grant = ls->ls_grant;
 	mutex_unlock(&ls->ls_mutex);
 	ls->ls_recall_accepted = false;
+	/*
+	 * A layout stateid with layouts has its slot recorded, as
+	 * nfsd4_layoutget() records it under ls_mutex; without one there
+	 * is no reply to wait for.
+	 */
+	ls->ls_recall_retired_at_send = !grant.valid ||
+		nfsd41_grant_slot_retired(clp, &grant);
+	ls->ls_recall_resent = false;
 	return true;
 }
 
@@ -915,8 +927,10 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
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
@@ -994,6 +1008,33 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 		}
 		return 1;
 	case -NFS4ERR_NOMATCHING_LAYOUT:
+		/*
+		 * The recall can reach the client before the reply to the
+		 * LAYOUTGET that added the layout, and a client that has not
+		 * processed that reply answers this way too. As the
+		 * delegation code does for NFS4ERR_BAD_STATEID, trust the
+		 * answer if the slot of the LAYOUTGET had retired when the
+		 * recall was sent, and send the recall once more after a
+		 * delay otherwise. Unlike the delegation code, trust the
+		 * answer to that resend: not trusting it would end in fencing
+		 * the client, and an idle client leaves its slot unretired
+		 * also when it has no layout. A client that has answered
+		 * NFS4_OK to this recall knew the layout stateid, so its
+		 * answer to a poll is trusted at once.
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
index a50f9dcb3a..506007cac5 100644
--- a/fs/nfsd/nfs4proc.c
+++ b/fs/nfsd/nfs4proc.c
@@ -2968,6 +2968,12 @@ nfsd4_layoutget(struct svc_rqst *rqstp,
 		goto out_put_stid;
 
 	nfserr = nfsd4_insert_layout(lgp, ls);
+	/*
+	 * Under ls_mutex, which nfsd4_cb_layout_prepare() takes as well, so
+	 * that a recall of the new layout finds the slot recorded.
+	 */
+	if (!nfserr)
+		nfsd41_record_grant_slot(&ls->ls_grant, cstate);
 
 out_put_stid:
 	mutex_unlock(&ls->ls_mutex);
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index 2c00b334c3..71a4b6fa5a 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -863,6 +863,16 @@ struct nfs4_layout_stateid {
 	bool				ls_recall_accepted;
 	bool				ls_recalled;
 	struct mutex			ls_mutex;
+	/*
+	 * Forward-channel slot that carried the last LAYOUTGET that added
+	 * a layout to this layout stateid, or extended one by merging.
+	 * Under ls_mutex. Until that slot retires, the client may not
+	 * have processed the reply to the LAYOUTGET.
+	 */
+	struct nfsd4_grant_slot		ls_grant;
+	/* Recall state for ->done, reset in ->prepare */
+	bool				ls_recall_retired_at_send;
+	bool				ls_recall_resent;
 
 	struct delayed_work		ls_fence_work;
 	struct mutex			ls_fence_mutex; /* serializes fence shutdown */
diff --git a/fs/nfsd/trace.h b/fs/nfsd/trace.h
index e0908cb21c..bd031b7124 100644
--- a/fs/nfsd/trace.h
+++ b/fs/nfsd/trace.h
@@ -681,6 +681,7 @@ DEFINE_STATEID_EVENT(layout_return_lookup_fail);
 DEFINE_STATEID_EVENT(layout_recall);
 DEFINE_STATEID_EVENT(layout_recall_empty);
 DEFINE_STATEID_EVENT(layout_recall_done);
+DEFINE_STATEID_EVENT(layout_recall_resend);
 DEFINE_STATEID_EVENT(layout_recall_new_seqid);
 DEFINE_STATEID_EVENT(layout_recall_fail);
 DEFINE_STATEID_EVENT(layout_recall_release);

-- 
2.43.0

