From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 14 Oct 2026 16:29:57 +0900
Subject: [PATCH v2 1/7] nfsd: fail a LAYOUTGET in progress when the layout
 lease is broken
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-nfsd-layout-recall-v2-1-764462bddfd1@samsung.com>
References: <20261014-nfsd-layout-recall-v2-0-764462bddfd1@samsung.com>
In-Reply-To: <20261014-nfsd-layout-recall-v2-0-764462bddfd1@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <bcodding@redhat.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791962996; l=6926;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=4bJJiIPxraygbzsSNShaQe8i6TfnVKwmG+3A33C/QIk=;
 b=7a22KTrhtXWoQ+rg8pPlIk5N7+3FVtJvlmETyX8fAOwB1taKbnprDrAH0H8Y5twDgSlMFOUXr
 qTwDN2/pF/dCeRzpg/qgANxd1cibzS2BE30bV2PA2T//G17M6uPROHI
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A layout stateid takes its FL_LAYOUT lease when it is allocated, before
the first layout is added to it. When the lease is broken in between,
nfsd4_recall_file_layout() finds no layouts and does nothing. The
LAYOUTGET then hands out a layout that is not recalled: the lease is
already marked as breaking, so ->lm_break() is not called for it again.
The breaker waits until the client gives the layout up by itself or the
lease break time is over; with the SCSI layout the client is then
fenced although it was never sent a recall. While the breaker waits,
kernel_setlease() fails for new layout stateids and the LAYOUTGETs of
other clients get NFS4ERR_DELAY.

Commit c5c707f96fc9 ("nfsd: implement pNFS layout recalls") marked such
a layout stateid as recalled, and since nothing kept the LAYOUTGET from
adding its layout afterwards, that layout was never recalled. Commit
fb610c4dbc99 ("nfsd: fix race to check ls_layouts") therefore made the
recall skip a layout stateid without layouts, which left the case
above.

Let the lease break mark such a layout stateid as recalled again, and
make nfsd4_insert_layout() refuse to add layouts to a recalled layout
stateid, which is what was missing the first time. The LAYOUTGET fails
with NFS4ERR_RECALLCONFLICT, the layout stateid is freed and the lease
goes away. No callback is sent for it; the new
nfsd_layout_recall_empty tracepoint shows where fi_lo_recalls was
raised without one. NFS4ERR_RECALLCONFLICT is what nfsd already answers
to a LAYOUTGET for a file with a recall in progress, also when the
recall went to another client (RFC 8881 section 15.1.14.3: "a
conflicting recall operation that is currently in progress for that
object"). The check in nfsd4_insert_layout() also covers a
layout stateid with layouts that is recalled between the checks in
nfsd4_layoutget() and nfsd4_insert_layout().

Only a lease break does this. A LAYOUTGET that finds a layout stateid
without layouts of another client leaves it alone, as before.

The window is the time a LAYOUTGET needs from allocating the layout
stateid to inserting the layout.

Two clients writing to one file while the server writes 4 KiB to it
every 50 ms, for 30 seconds, block layout (the runs without this patch
on nfsd-testing 32eb1a60b456, the runs with it with this whole series).
Without this patch one write on the server took 9.7 seconds in one run
and 13.9 seconds in another, in both until the clients were done; in a
third run it did not happen. With this patch the longest write on the
server took 55 ms.

To see the new path at work, a delay of 100 ms was added to LAYOUTGET
between the two steps for one pair of runs. Without the patch the
second write on the server took 30 seconds, the whole run. With it the
longest write took 108 ms and nfsd_layout_recall_empty fired 16 times.
(With that delay every LAYOUTGET meets a write on the server, so the
clients got no layout in that run. It shows the path and nothing else.)

Fixes: c5c707f96fc9 ("nfsd: implement pNFS layout recalls")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 49 +++++++++++++++++++++++++++++++++++++++++++------
 fs/nfsd/trace.h       |  1 +
 2 files changed, 44 insertions(+), 6 deletions(-)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index 898776c9d7..72b53eebd1 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -336,14 +336,15 @@ nfsd4_preprocess_layout_stateid(struct svc_rqst *rqstp,
 }
 
 static void
-nfsd4_recall_file_layout(struct nfs4_layout_stateid *ls)
+nfsd4_recall_file_layout_locked(struct nfs4_layout_stateid *ls)
 {
-	spin_lock(&ls->ls_lock);
+	lockdep_assert_held(&ls->ls_lock);
+
 	if (ls->ls_recalled)
-		goto out_unlock;
+		return;
 
 	if (list_empty(&ls->ls_layouts))
-		goto out_unlock;
+		return;
 
 	ls->ls_recalled = true;
 	atomic_inc(&ls->ls_stid.sc_file->fi_lo_recalls);
@@ -353,7 +354,34 @@ nfsd4_recall_file_layout(struct nfs4_layout_stateid *ls)
 		refcount_inc(&ls->ls_stid.sc_count);
 		nfsd4_run_cb(&ls->ls_recall);
 	}
-out_unlock:
+}
+
+static void
+nfsd4_recall_file_layout(struct nfs4_layout_stateid *ls)
+{
+	spin_lock(&ls->ls_lock);
+	nfsd4_recall_file_layout_locked(ls);
+	spin_unlock(&ls->ls_lock);
+}
+
+/*
+ * A lease break also has to stop a LAYOUTGET that is in progress. Its
+ * layout stateid has the lease and no layouts yet, so there is nothing to
+ * recall, and the breaker goes on once that layout stateid is gone. Mark it
+ * as recalled without sending a callback: nfsd4_insert_layout() then fails
+ * the LAYOUTGET instead of handing out a layout after the break.
+ */
+static void
+nfsd4_break_file_layout(struct nfs4_layout_stateid *ls)
+{
+	spin_lock(&ls->ls_lock);
+	if (!ls->ls_recalled && list_empty(&ls->ls_layouts)) {
+		ls->ls_recalled = true;
+		atomic_inc(&ls->ls_stid.sc_file->fi_lo_recalls);
+		trace_nfsd_layout_recall_empty(&ls->ls_stid.sc_stateid);
+	} else {
+		nfsd4_recall_file_layout_locked(ls);
+	}
 	spin_unlock(&ls->ls_lock);
 }
 
@@ -432,6 +460,10 @@ nfsd4_insert_layout(struct nfsd4_layoutget *lgp, struct nfs4_layout_stateid *ls)
 	if (nfserr)
 		goto out;
 	spin_lock(&ls->ls_lock);
+	if (ls->ls_recalled) {
+		nfserr = nfserr_recallconflict;
+		goto out_unlock_ls;
+	}
 	list_for_each_entry(lp, &ls->ls_layouts, lo_perstate) {
 		if (layouts_try_merge(&lp->lo_seg, seg))
 			goto done;
@@ -450,6 +482,10 @@ nfsd4_insert_layout(struct nfsd4_layoutget *lgp, struct nfs4_layout_stateid *ls)
 	if (nfserr)
 		goto out;
 	spin_lock(&ls->ls_lock);
+	if (ls->ls_recalled) {
+		nfserr = nfserr_recallconflict;
+		goto out_unlock_ls;
+	}
 	list_for_each_entry(lp, &ls->ls_layouts, lo_perstate) {
 		if (layouts_try_merge(&lp->lo_seg, seg))
 			goto done;
@@ -460,6 +496,7 @@ nfsd4_insert_layout(struct nfsd4_layoutget *lgp, struct nfs4_layout_stateid *ls)
 	new = NULL;
 done:
 	nfs4_inc_and_copy_stateid(&lgp->lg_sid, &ls->ls_stid);
+out_unlock_ls:
 	spin_unlock(&ls->ls_lock);
 out:
 	spin_unlock(&fp->fi_lock);
@@ -779,7 +816,7 @@ nfsd4_layout_lm_break(struct file_lease *fl)
 	 * Enforce break lease timeout to prevent NFSD
 	 * thread from hanging in __break_lease.
 	 */
-	nfsd4_recall_file_layout(fl->c.flc_owner);
+	nfsd4_break_file_layout(fl->c.flc_owner);
 	return false;
 }
 
diff --git a/fs/nfsd/trace.h b/fs/nfsd/trace.h
index e5d19c6f48..abfdbc637c 100644
--- a/fs/nfsd/trace.h
+++ b/fs/nfsd/trace.h
@@ -679,6 +679,7 @@ DEFINE_STATEID_EVENT(layout_get_lookup_fail);
 DEFINE_STATEID_EVENT(layout_commit_lookup_fail);
 DEFINE_STATEID_EVENT(layout_return_lookup_fail);
 DEFINE_STATEID_EVENT(layout_recall);
+DEFINE_STATEID_EVENT(layout_recall_empty);
 DEFINE_STATEID_EVENT(layout_recall_done);
 DEFINE_STATEID_EVENT(layout_recall_fail);
 DEFINE_STATEID_EVENT(layout_recall_release);

-- 
2.43.0

