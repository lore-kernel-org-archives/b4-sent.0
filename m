From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 06 Oct 2026 13:29:47 +0900
Subject: [PATCH 5/6] nfsd: poll a layout recall with a new seqid when the
 client is past it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-nfsd-layout-recall-v1-5-b59b31caf342@samsung.com>
References: <20261006-nfsd-layout-recall-v1-0-b59b31caf342@samsung.com>
In-Reply-To: <20261006-nfsd-layout-recall-v1-0-b59b31caf342@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <bcodding@redhat.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791260982; l=5823;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=IGletPNKnOjSG4vyFldCHDro8K0vh082o4ksy2O+QTM=;
 b=3YJBhDhmAdcloCxlePctn3lkaO81PgbkIuYinArpzAqgW8w4XQs4YXKdAujsEiH5nav14CE5P
 MYD4YEdAVuCBV9UgcSGYNggkTexpzY6qlA6n/T9EVcgjuclQIfzW9VB
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd4_cb_layout_done() polls a client that answers a CB_LAYOUTRECALL
with NFS4ERR_OLD_STATEID, as "nfsd: keep polling a layout recall
answered with NFS4ERR_OLD_STATEID" has it do, and each poll repeats the
seqid that ->prepare gave the recall.  NFS4ERR_OLD_STATEID says that
the client is at or past that seqid.  A client that has answered
NFS4_OK to the recall is returning its layouts, and the polls end when
it has.  A client that has not is past the seqid without having taken
the recall up.  A LAYOUTRETURN that returns some layouts and leaves
others gets a new seqid; if nfsd processes it after ->prepare, the
client takes in a seqid above the recall's from its reply.  Such a
client answers every poll with NFS4ERR_OLD_STATEID.  The recall goes on
for two lease periods, a LAYOUTGET for the file from another client
gets NFS4ERR_RECALLCONFLICT meanwhile, and the client is then fenced,
although it was never asked for the layouts it still holds.

RFC 8881 section 12.5.3 has a new seqid for each CB_LAYOUTRECALL
request.  When a client that has not answered NFS4_OK answers
NFS4ERR_OLD_STATEID, give the next poll a new seqid, which the client
takes up.  ->prepare clears ls_recall_accepted, and ->done sets it when
the client answers NFS4_OK.  The new seqid is traced as
nfsd_layout_recall_new_seqid.

->done runs in rpciod and does not take ls_mutex, which could block it.
While a recall is out, only a LAYOUTRETURN changes the seqid besides,
since "nfsd: fail a LAYOUTGET in progress when the layout lease is
broken" keeps LAYOUTGET from adding layouts to a recalled layout
stateid, and nfsd4_preprocess_layout_stateid() only checks that the
seqid a client presents is not above the current one.

A pynfs client that holds a layout answers a recall whose seqid is not
above the first seqid of the recall with NFS4ERR_OLD_STATEID, and
returns the layout on a later one.  Without this patch, nfsd sent the
recall 501 times in six seconds, all with the first seqid, and a
LAYOUTGET of another client still got NFS4ERR_RECALLCONFLICT.  With it,
the second recall carried a new seqid, 10 ms later, the client returned
the layout, and the LAYOUTGET succeeded.  The block layout runs of the
earlier patches give the same results with this one and the next: no
recall failed, and every block written to a new file was found.

This builds on "nfsd: keep polling a layout recall answered with
NFS4ERR_OLD_STATEID" and "nfsd: fail a LAYOUTGET in progress when the
layout lease is broken", earlier in this series, and should go to
stable kernels with them.

Fixes: c5c707f96fc9 ("nfsd: implement pNFS layout recalls")

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 29 ++++++++++++++++++++++++++---
 fs/nfsd/state.h       |  2 ++
 fs/nfsd/trace.h       |  1 +
 3 files changed, 29 insertions(+), 3 deletions(-)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index 66f79e4e4..c140c9bde 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -727,6 +727,7 @@ nfsd4_cb_layout_prepare(struct nfsd4_callback *cb)
 	mutex_lock(&ls->ls_mutex);
 	nfs4_inc_and_copy_stateid(&ls->ls_recall_sid, &ls->ls_stid);
 	mutex_unlock(&ls->ls_mutex);
+	ls->ls_recall_accepted = false;
 	return true;
 }
 
@@ -742,13 +743,35 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 
 	trace_nfsd_cb_layout_done(&ls->ls_stid.sc_stateid, task);
 	switch (task->tk_status) {
-	case 0:
-	case -NFS4ERR_DELAY:
 	case -NFS4ERR_OLD_STATEID:
+		/*
+		 * The client is at or past the seqid of the request.  Unless
+		 * it has answered NFS4_OK to this recall and is returning
+		 * layouts, it has not taken the recall up, for instance
+		 * because a LAYOUTRETURN moved it past the seqid.  Poll with a
+		 * new seqid then (RFC 8881 section 12.5.3), which such a
+		 * client answers afresh.
+		 *
+		 * ->done runs in rpciod and does not take ls_mutex, which
+		 * could block it.  While the recall is out, only a
+		 * LAYOUTRETURN changes the seqid besides, and the check of the
+		 * seqid a client presents only asks whether it is above the
+		 * current one.
+		 */
+		if (!ls->ls_recall_accepted) {
+			nfs4_inc_and_copy_stateid(&ls->ls_recall_sid,
+						  &ls->ls_stid);
+			trace_nfsd_layout_recall_new_seqid(&ls->ls_recall_sid);
+		}
+		fallthrough;
+	case -NFS4ERR_DELAY:
+	case 0:
+		if (!task->tk_status)
+			ls->ls_recall_accepted = true;
 		/*
 		 * RFC 8881 section 12.5.3 wants a new seqid in each
 		 * CB_LAYOUTRECALL request.  The poll below sends the request
-		 * again with the seqid of the first one.  A client that has
+		 * again with the seqid it last had.  A client that has
 		 * processed that one is at its seqid or past it, and the
 		 * Linux client answers the repeat with NFS4ERR_OLD_STATEID
 		 * while it is returning the layouts.
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index ff840a311..3ad87c85a 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -853,6 +853,8 @@ struct nfs4_layout_stateid {
 	struct nfsd4_callback		ls_recall;
 	stateid_t			ls_recall_sid;
 	ktime_t				ls_recall_start;
+	/* The client has answered NFS4_OK to the recall */
+	bool				ls_recall_accepted;
 	bool				ls_recalled;
 	struct mutex			ls_mutex;
 
diff --git a/fs/nfsd/trace.h b/fs/nfsd/trace.h
index 78f682bfd..f6bdf69d4 100644
--- a/fs/nfsd/trace.h
+++ b/fs/nfsd/trace.h
@@ -681,6 +681,7 @@ DEFINE_STATEID_EVENT(layout_return_lookup_fail);
 DEFINE_STATEID_EVENT(layout_recall);
 DEFINE_STATEID_EVENT(layout_recall_empty);
 DEFINE_STATEID_EVENT(layout_recall_done);
+DEFINE_STATEID_EVENT(layout_recall_new_seqid);
 DEFINE_STATEID_EVENT(layout_recall_fail);
 DEFINE_STATEID_EVENT(layout_recall_release);
 

-- 
2.43.0

