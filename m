From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 23 Oct 2026 22:28:43 +0200
Subject: [PATCH v6 1/8] fuse: {io-uring} Add queue length counters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-reduced-nr-ring-queues_3-v6-1-658235c9b9bd@bsbernd.com>
References: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
In-Reply-To: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=3112; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=ew8Loht7/s/v9+CJ7lFhSnfg10fFKeD1z4veh1XOTUw=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJuH24ocLj76i7z/D0Rh986JHuz7F8kHXHU8MjPXu7u8
 zqvfc7odJSyMIhxMMiKKbJ0SeyxnfKPT1bt6/rrMHNYmUCGMHBxCsBErA0Z/odKHJcy2K2y1lFs
 eiDP1Bxt7zXyb/S2LPlzpH2ZF5vdjHkM/7RYGmTNVj962dshLqd+m/9ujs5lhZ31xudCg5b6bbF
 wZQMA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is another preparation and will be used for decision
which queue to add a request to.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
Reviewed-by: Joanne Koong <joannelkoong@gmail.com>
---
 fs/fuse/dev_uring.c   | 15 +++++++++++++--
 fs/fuse/dev_uring_i.h |  3 +++
 2 files changed, 16 insertions(+), 2 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 460776cd69cd..1aca6ce906f0 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -159,6 +159,7 @@ static void fuse_uring_req_end(struct fuse_ring_ent *ent, struct fuse_req *req,
 	spin_lock(&queue->lock);
 	ent->fuse_req = NULL;
 	list_del_init(&req->list);
+	queue->nr_reqs--;
 	if (test_bit(FR_BACKGROUND, &req->flags)) {
 		queue->active_background--;
 		spin_lock(&fch->bg_lock);
@@ -166,7 +167,6 @@ static void fuse_uring_req_end(struct fuse_ring_ent *ent, struct fuse_req *req,
 		fuse_uring_flush_bg(queue);
 		spin_unlock(&fch->bg_lock);
 	}
-
 	spin_unlock(&queue->lock);
 
 	zero_copy_unregister(ent->cmd, ent, issue_flags);
@@ -188,6 +188,7 @@ static void fuse_uring_abort_end_queue_requests(struct fuse_ring_queue *queue)
 	list_for_each_entry(req, &queue->fuse_req_queue, list)
 		clear_bit(FR_PENDING, &req->flags);
 	list_splice_init(&queue->fuse_req_queue, &req_list);
+	queue->nr_reqs = 0;
 	spin_unlock(&queue->lock);
 
 	/* must not hold queue lock to avoid order issues with fi->lock */
@@ -1823,6 +1824,7 @@ void fuse_uring_queue_fuse_req(struct fuse_iqueue *fiq, struct fuse_req *req)
 	req->ring_queue = queue;
 	ent = list_first_entry_or_null(&queue->ent_avail_queue,
 				       struct fuse_ring_ent, list);
+	queue->nr_reqs++;
 
 	if (!ent || fuse_uring_prep_buffer(ent, req)) {
 		list_add_tail(&req->list, &queue->fuse_req_queue);
@@ -1863,6 +1865,7 @@ bool fuse_uring_queue_bq_req(struct fuse_req *req)
 	set_bit(FR_URING, &req->flags);
 	req->ring_queue = queue;
 	list_add_tail(&req->list, &queue->fuse_req_bg_queue);
+	queue->nr_reqs++;
 
 	ent = list_first_entry_or_null(&queue->ent_avail_queue,
 				       struct fuse_ring_ent, list);
@@ -1894,8 +1897,16 @@ bool fuse_uring_queue_bq_req(struct fuse_req *req)
 bool fuse_uring_remove_pending_req(struct fuse_req *req)
 {
 	struct fuse_ring_queue *queue = req->ring_queue;
+	bool removed = fuse_remove_pending_req(req, &queue->lock);
 
-	return fuse_remove_pending_req(req, &queue->lock);
+	if (removed) {
+		/* Update counters after successful removal */
+		spin_lock(&queue->lock);
+		queue->nr_reqs--;
+		spin_unlock(&queue->lock);
+	}
+
+	return removed;
 }
 
 static const struct fuse_iqueue_ops fuse_io_uring_ops = {
diff --git a/fs/fuse/dev_uring_i.h b/fs/fuse/dev_uring_i.h
index 263d0f8b9714..77f87075f62d 100644
--- a/fs/fuse/dev_uring_i.h
+++ b/fs/fuse/dev_uring_i.h
@@ -135,6 +135,9 @@ struct fuse_ring_queue {
 	/* background fuse requests */
 	struct list_head fuse_req_bg_queue;
 
+	/* number of requests queued or in userspace */
+	unsigned int nr_reqs;
+
 	struct fuse_pqueue fpq;
 
 	unsigned int active_background;

-- 
2.55.0

