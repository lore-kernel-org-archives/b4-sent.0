From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 06 Oct 2026 13:29:43 +0900
Subject: [PATCH 1/6] nfsd: make the time limit of a layout recall work
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-nfsd-layout-recall-v1-1-b59b31caf342@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791260982; l=3899;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=7a8YQH4siINWl94YKs4xNfmjqEN+ZG2FEdQK48SLAiQ=;
 b=vdQdQjiCaOzFFcMgwME9j15pMhtzVCf2k1g8SH3Yd3vBwIsBc/o3vfOFVx/jnMGrCvpRsCzDx
 UJ+iAnXwnMmAXOmrJe5fHZwTyJstvFdoYwGzdor1FRYUfFEhK/8JeM/
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd4_cb_layout_done() polls a client that has answered CB_LAYOUTRECALL
and still holds layouts, and is meant to give up after two lease
periods: the recall then fails and the client is fenced.  The limit is
computed from task->tk_start.  The poll restarts the RPC task from
->rpc_call_done(), and rpc_exit_task() resets the statistics of a task
that was restarted there, tk_start included.  So tk_start is the time
of the last poll, and the limit is never reached: a client that keeps
answering is polled every 10 ms for as long as it holds the layout.

Count the two lease periods from the first answer of the client, so
that the time in which a callback could not be delivered is not taken
from it.  A layout stateid is recalled once in its life (ls_recalled is
not cleared), so the time needs no reset.

When the limit is reached, the existing failure path is taken.  It does
not look at the result of ->fence_client(), so a SCSI layout client
whose fencing fails is treated as fenced there.

A Linux client before v6.8 answers every poll with NFS4_OK until its
LAYOUTRETURN is prepared (read from the code, not run).  If such a
client does not return the layout, it was polled without end and is now
fenced after two lease periods, which is what commit 6b9b21073d3b
("nfsd: give up on CB_LAYOUTRECALLs after two lease periods") and
commit 851238a22f3b ("nfsd: fix error handling for clients that fail to
return the layout") set out to do.

Found by reading the code.  The limit could only be tested together
with "nfsd: keep polling a layout recall answered with
NFS4ERR_OLD_STATEID", because a current Linux client does not keep
answering a recall with NFS4_OK or NFS4ERR_DELAY: a client writing
through a block layout whose path to the device is cut for 70 seconds
while it can still talk to the server, a lease time of 15 seconds, and
a write to the file on the server.  The recall fails 30 seconds after
the first answer of the client and /sbin/nfsd-recall-failed is run.
With the default lease time the limit is 180 seconds; a recall that
comes from a lease break is not waited for that long, the breaker gives
up after fs.lease-break-time.

Fixes: 6b9b21073d3b ("nfsd: give up on CB_LAYOUTRECALLs after two lease periods")

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 11 +++++++++--
 fs/nfsd/state.h       |  1 +
 2 files changed, 10 insertions(+), 2 deletions(-)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index 898776c9d..3731b4db7 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -257,6 +257,7 @@ nfsd4_alloc_layout_stateid(struct nfsd4_compound_state *cstate,
 		return NULL;
 	}
 
+	ls->ls_recall_start = 0;
 	ls->ls_fenced = false;
 	ls->ls_fence_inflight = false;
 	ls->ls_fence_stopped = false;
@@ -718,8 +719,14 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 		now = ktime_get();
 		nn = net_generic(ls->ls_stid.sc_client->net, nfsd_net_id);
 
-		/* Client gets 2 lease periods to return it */
-		cutoff = ktime_add_ns(task->tk_start,
+		/*
+		 * Client gets 2 lease periods to return it, counted from its
+		 * first answer.  task->tk_start cannot be used for this, it
+		 * is set anew each time the callback is restarted.
+		 */
+		if (!ls->ls_recall_start)
+			ls->ls_recall_start = now;
+		cutoff = ktime_add_ns(ls->ls_recall_start,
 					 (u64)nn->nfsd4_lease * NSEC_PER_SEC * 2);
 
 		if (ktime_before(now, cutoff)) {
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index 910f4eac7..ff840a311 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -852,6 +852,7 @@ struct nfs4_layout_stateid {
 	struct nfsd_file		*ls_file;
 	struct nfsd4_callback		ls_recall;
 	stateid_t			ls_recall_sid;
+	ktime_t				ls_recall_start;
 	bool				ls_recalled;
 	struct mutex			ls_mutex;
 

-- 
2.43.0

