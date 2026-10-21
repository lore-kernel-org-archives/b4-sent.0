From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 21 Oct 2026 10:03:06 +0900
Subject: [PATCH 4/4] nfsd: do not fail a LAYOUTGET on a lease break by the
 same client
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-nfsd-layout-refcall-v1-4-797096b92377@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792544582; l=12853;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=JCuGa7HbHYd3/G/Txl5rtH7+m3X1MhOD7vksMy5gAr4=;
 b=5tU9uAoq1qm/eF1LT7kdBCDS7y/+E1a6lPR83L/Kun95/lbuI019h1YsuB8L3JN2CSWk0t+rI
 QBaf/CHKJNZA5/hqB3kvbBePbxOONCHjU9sVy0FTF9kKRR57aoicnrF
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

"nfsd: fail a LAYOUTGET in progress when the layout lease is broken"
fails a LAYOUTGET whose layout stateid has no layouts yet when the lease
is broken, so that no layout is handed out after the break without a
recall. Since "nfsd: answer NFS4ERR_DELAY instead of waiting for a
layout recall", a WRITE through the metadata server that meets a layout
of its own client gets NFS4ERR_DELAY, and the Linux client resends it
every 0.1 seconds; a resend breaks the lease of any LAYOUTGET that the
same client has in progress. A client that writes through the metadata
server while it does I/O through a layout of the same file, as the Linux
client does for O_DIRECT writes that are not aligned to a page, then
gets NFS4ERR_RECALLCONFLICT for LAYOUTGET after LAYOUTGET, and waits up
to 15 seconds between them.

When the break comes from a request of the client that holds the layout
stateid, nfsd4_break_file_layout() notes that the break met a LAYOUTGET
in progress and when the break times out (fl_break_time), and
nfsd4_insert_layout() recalls the layout as soon as it adds it. The
LAYOUTGET succeeds and the client is asked for the layout back at once.
nfsd4_layout_breaker_is_holder() finds the client of the breaker as
nfsd_breaker_owns_lease() does for delegations. A break by another
client or by a local process fails the LAYOUTGET as before, and the
conflicting operation goes ahead without waiting for a recall, unless a
break by the holder came first. The new case is traced as
nfsd_layout_break_pending.

A LAYOUTGET that would add its layout after the break has timed out
fails as before, whether or not the timeout has been noticed yet:
time_out_leases() notices it only when another lease operation on the
file comes, and a layout added in between would be recalled when it is
already due and have its client fenced if that operation comes before
the layout is back. When the timeout is noticed first,
nfsd4_layout_lm_breaker_timedout() marks the layout stateid recalled, so
that the LAYOUTGET fails. A layout added shortly before the break times
out is recalled with what is left of fs.lease-break-time, and its client
is fenced if it does not return the layout by then, where the LAYOUTGET
failed before this patch. With the default of 45 seconds that takes a
LAYOUTGET that has been in progress for most of that time.

The recall is queued before the LAYOUTGET reply is sent and can reach
the client first; a client that answers NFS4ERR_NOMATCHING_LAYOUT then
would have its layout thrown away while it uses it. The resent recall of
"nfsd: resend a layout recall once before trusting NOMATCHING_LAYOUT"
and the referring call that CB_LAYOUTRECALL carries since "nfsd: send a
referring call with CB_LAYOUTRECALL" cover that, for a client that takes
the reply in within about three seconds or holds the recall back, which
is why this comes after them.

One client writing 1 MiB blocks with O_DIRECT through its block layout
and 512 bytes at the middle of a page through the metadata server to the
same file, for 30 seconds: before this patch 54, 54 and 51 of the 1 MiB
writes were done in three runs, as the LAYOUTGETs failed and the client
backed off; with it 244, 249 and 241, with no 1 MiB block lost. The 512
byte writes went from 5054, 4992 and 5072 to 1309, 1117 and 1415: the
client now holds a layout most of the time, and such a WRITE meets it
and gets NFS4ERR_DELAY. The same change without the two patches above
lost 85 of 600, 87 of 584 and 79 of 600 blocks.

With fs.lease-break-time at one second and a test-only delay before
nfsd4_insert_layout(), a 512 byte write through the metadata server 0.3
seconds into the LAYOUTGET broke the lease and was resent every 0.1
seconds; the first resend after the break timed out came 37 to 44 ms
after it. A layout added 25 to 29 ms before the break timed out was
recalled at once and returned in each of five runs, without fencing.
LAYOUTGETs that would add their layout about 17 or 30 ms after the break
had timed out, before that resend, failed with NFS4ERR_RECALLCONFLICT in
each of five runs at each offset. With the test of the deadline taken
out, they handed the layout out. At 17 ms the client returned it before
the resend in each of five runs, and nothing was fenced; at 30 ms the
resend timed the break out while the client still held the layout, and
had it fenced, in four of five, and came first in the fifth.

With a test-only delay of three seconds and a local write on the server
that breaks the lease during that delay and goes ahead one second later,
the LAYOUTGET fails with NFS4ERR_RECALLCONFLICT with this patch, as
without it, in each of three runs: a local process is not the holder, so
this patch leaves that case alone. With another client breaking the
lease, as in the test of "nfsd: resend a layout recall once before
trusting NOMATCHING_LAYOUT" without the delay, the 1 MiB writes went on
with the whole series as without it: 600 blocks in each of three runs of
30 seconds, as in each of six without the series, and no recall overtook
a reply.

No Fixes: tag, as "nfsd: fail a LAYOUTGET in progress when the layout
lease is broken" is not upstream yet. Where that patch is backported,
this one is needed too, but only together with the two patches before
it, so only where "NFSD: Send referring calls with CB_RECALL" and its
series are, and not before v7.1.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 81 ++++++++++++++++++++++++++++++++++++++++++++-------
 fs/nfsd/state.h       | 11 +++++++
 fs/nfsd/trace.h       |  1 +
 3 files changed, 82 insertions(+), 11 deletions(-)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index 33d78595f7..834f73a6f5 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -333,6 +333,8 @@ nfsd4_alloc_layout_stateid(struct nfsd4_compound_state *cstate,
 
 	ls->ls_recall_start = 0;
 	ls->ls_grant.valid = false;
+	ls->ls_break_pending = false;
+	ls->ls_break_time = 0;
 	ls->ls_fenced = false;
 	ls->ls_fence_inflight = false;
 	ls->ls_fence_stopped = false;
@@ -456,16 +458,42 @@ nfsd4_recall_file_layout(struct nfs4_layout_stateid *ls)
 	spin_unlock(&ls->ls_lock);
 }
 
+/* Whether the lease break comes from a request of the client of @ls */
+static bool
+nfsd4_layout_breaker_is_holder(const struct nfs4_layout_stateid *ls)
+{
+	struct svc_rqst *rqstp = nfsd_current_rqst();
+	struct nfsd_thread_local_info *ntli;
+
+	if (!nfsd_v4client(rqstp))
+		return false;
+	ntli = rqstp->rq_private;
+	return *ntli->ntli_lease_breaker == ls->ls_stid.sc_client;
+}
+
 /*
- * A layout stateid with no layouts belongs to a LAYOUTGET in progress
- * and already holds the lease. Mark the stateid recalled so that
- * nfsd4_insert_layout() fails the LAYOUTGET and the lease is released.
+ * A lease break also has to reach a LAYOUTGET in progress, whose layout
+ * stateid holds the lease but has no layouts yet. Mark the stateid
+ * recalled so that nfsd4_insert_layout() fails the LAYOUTGET and the
+ * lease is released. When the break comes from a request of the same
+ * client, as a WRITE through the metadata server that the Linux client
+ * sends next to its I/O through the layout, failing its LAYOUTGET would
+ * have it back off and fail again: note the break and its deadline
+ * instead, and let nfsd4_insert_layout() recall the layout as soon as it
+ * adds it, unless the break is past its deadline by then.
+ * ->lm_break() is not called again for a lease that is already breaking.
  */
 static void
-nfsd4_break_file_layout(struct nfs4_layout_stateid *ls)
+nfsd4_break_file_layout(struct nfs4_layout_stateid *ls,
+			unsigned long break_time)
 {
 	spin_lock(&ls->ls_lock);
-	if (!ls->ls_recalled && list_empty(&ls->ls_layouts)) {
+	if (!ls->ls_recalled && list_empty(&ls->ls_layouts) &&
+	    nfsd4_layout_breaker_is_holder(ls)) {
+		ls->ls_break_pending = true;
+		ls->ls_break_time = break_time;
+		trace_nfsd_layout_break_pending(&ls->ls_stid.sc_stateid);
+	} else if (!ls->ls_recalled && list_empty(&ls->ls_layouts)) {
 		ls->ls_recalled = true;
 		atomic_inc(&ls->ls_stid.sc_file->fi_lo_recalls);
 		trace_nfsd_layout_recall_empty(&ls->ls_stid.sc_stateid);
@@ -475,6 +503,18 @@ nfsd4_break_file_layout(struct nfs4_layout_stateid *ls)
 	spin_unlock(&ls->ls_lock);
 }
 
+/*
+ * Whether the lease break noted by nfsd4_break_file_layout() is past its
+ * deadline. A layout added now would be recalled too late, whether or
+ * not time_out_leases() has noticed the timeout yet.
+ */
+static bool
+nfsd4_layout_break_expired(const struct nfs4_layout_stateid *ls)
+{
+	return ls->ls_break_pending && ls->ls_break_time &&
+	       time_after(jiffies, ls->ls_break_time);
+}
+
 static inline u64
 layout_end(struct nfsd4_layout_seg *seg)
 {
@@ -550,7 +590,7 @@ nfsd4_insert_layout(struct nfsd4_layoutget *lgp, struct nfs4_layout_stateid *ls)
 	if (nfserr)
 		goto out;
 	spin_lock(&ls->ls_lock);
-	if (ls->ls_recalled) {
+	if (ls->ls_recalled || nfsd4_layout_break_expired(ls)) {
 		nfserr = nfserr_recallconflict;
 		goto out_unlock_ls;
 	}
@@ -572,7 +612,7 @@ nfsd4_insert_layout(struct nfsd4_layoutget *lgp, struct nfs4_layout_stateid *ls)
 	if (nfserr)
 		goto out;
 	spin_lock(&ls->ls_lock);
-	if (ls->ls_recalled) {
+	if (ls->ls_recalled || nfsd4_layout_break_expired(ls)) {
 		nfserr = nfserr_recallconflict;
 		goto out_unlock_ls;
 	}
@@ -586,6 +626,10 @@ nfsd4_insert_layout(struct nfsd4_layoutget *lgp, struct nfs4_layout_stateid *ls)
 	new = NULL;
 done:
 	nfs4_inc_and_copy_stateid(&lgp->lg_sid, &ls->ls_stid);
+	if (ls->ls_break_pending) {
+		ls->ls_break_pending = false;
+		nfsd4_recall_file_layout_locked(ls);
+	}
 out_unlock_ls:
 	spin_unlock(&ls->ls_lock);
 out:
@@ -1087,7 +1131,7 @@ nfsd4_layout_lm_break(struct file_lease *fl)
 	 * Enforce break lease timeout to prevent NFSD
 	 * thread from hanging in __break_lease.
 	 */
-	nfsd4_break_file_layout(fl->c.flc_owner);
+	nfsd4_break_file_layout(fl->c.flc_owner, fl->fl_break_time);
 	return false;
 }
 
@@ -1278,7 +1322,9 @@ static void nfsd4_layout_fence_worker(struct work_struct *work)
  *
  * Schedule a worker to fence the client from accessing the block device.
  * If the layout type has no fence operation, the worker runs the fence
- * script instead.
+ * script instead. If a lease break of its own client met the LAYOUTGET
+ * of a layout stateid that has no layouts yet, mark it recalled instead,
+ * so that the LAYOUTGET fails.
  *
  * This function runs under the protection of the spin_lock flc_lock.
  * At this time, the file_lease associated with the layout stateid is
@@ -1318,8 +1364,21 @@ nfsd4_layout_lm_breaker_timedout(struct file_lease *fl)
 		spin_unlock(&ls->ls_lock);
 		return false;
 	}
-	if (list_empty(&ls->ls_layouts) ||
-			!refcount_inc_not_zero(&ls->ls_stid.sc_count)) {
+	if (list_empty(&ls->ls_layouts)) {
+		/*
+		 * The lease goes away and the conflicting operation goes
+		 * ahead, so a LAYOUTGET that the break met must not add a
+		 * layout any more: fail it as nfsd4_insert_layout() fails one
+		 * on a recalled layout stateid.
+		 */
+		if (ls->ls_break_pending && !ls->ls_recalled) {
+			ls->ls_recalled = true;
+			atomic_inc(&ls->ls_stid.sc_file->fi_lo_recalls);
+		}
+		spin_unlock(&ls->ls_lock);
+		return true;
+	}
+	if (!refcount_inc_not_zero(&ls->ls_stid.sc_count)) {
 		spin_unlock(&ls->ls_lock);
 		return true;
 	}
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index 075fd3d107..805bbdc16e 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -862,6 +862,17 @@ struct nfs4_layout_stateid {
 	/* The client has answered NFS4_OK to the recall */
 	bool				ls_recall_accepted;
 	bool				ls_recalled;
+	/*
+	 * A lease break of this client met a LAYOUTGET in progress: recall
+	 * the layout it adds, or fail it once the break is past its time.
+	 * Under ls_lock.
+	 */
+	bool				ls_break_pending;
+	/*
+	 * fl_break_time of that break: 0 if it does not time out.
+	 * Under ls_lock.
+	 */
+	unsigned long			ls_break_time;
 	struct mutex			ls_mutex;
 	/*
 	 * Forward-channel slot that carried the last LAYOUTGET that added
diff --git a/fs/nfsd/trace.h b/fs/nfsd/trace.h
index bd031b7124..5471ec825a 100644
--- a/fs/nfsd/trace.h
+++ b/fs/nfsd/trace.h
@@ -680,6 +680,7 @@ DEFINE_STATEID_EVENT(layout_commit_lookup_fail);
 DEFINE_STATEID_EVENT(layout_return_lookup_fail);
 DEFINE_STATEID_EVENT(layout_recall);
 DEFINE_STATEID_EVENT(layout_recall_empty);
+DEFINE_STATEID_EVENT(layout_break_pending);
 DEFINE_STATEID_EVENT(layout_recall_done);
 DEFINE_STATEID_EVENT(layout_recall_resend);
 DEFINE_STATEID_EVENT(layout_recall_new_seqid);

-- 
2.43.0

