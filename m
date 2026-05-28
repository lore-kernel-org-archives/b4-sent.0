From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 29 May 2026 00:55:05 +0200
Subject: [PATCH v5 1/7] fuse: {io-uring} Add queue length counters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-reduced-nr-ring-queues_3-v5-1-1dc08c2fccf6@bsbernd.com>
References: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
In-Reply-To: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, Luis Henriques <luis@igalia.com>, 
 Gang He <dchg2000@gmail.com>, fuse-devel@lists.linux.dev, 
 Bernd Schubert <bschubert@ddn.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780008905; l=3149;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=lEOl0gCRG4ScH4ID6B4KJc22niR/P4p/C9tlTSztQOs=;
 b=9avE0fsoVp9mEhQwl+rUZMycVS042bJvJhYeh5YUqV2cirNfAi7lKO2dLwn4Dbai1GqyPAs0H
 l4OqDXttlLGAwZcz3DlD7+oooF33DPLQL5pSc99wh3uPDwHY1wmtU8r
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bernd Schubert <bschubert@ddn.com>

This is another preparation and will be used for decision
which queue to add a request to.

Signed-off-by: Bernd Schubert <bschubert@ddn.com>
Reviewed-by: Joanne Koong <joannelkoong@gmail.com>
---
 fs/fuse/dev_uring.c   | 17 +++++++++++++++--
 fs/fuse/dev_uring_i.h |  3 +++
 2 files changed, 18 insertions(+), 2 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index e467b23e689592aa8a7656ccb851a16ac26b3156..beea0eed203d3dfa90a54a698feb78a20778d9db 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -87,13 +87,13 @@ static void fuse_uring_req_end(struct fuse_ring_ent *ent, struct fuse_req *req,
 	spin_lock(&queue->lock);
 	ent->fuse_req = NULL;
 	list_del_init(&req->list);
+	queue->nr_reqs--;
 	if (test_bit(FR_BACKGROUND, &req->flags)) {
 		queue->active_background--;
 		spin_lock(&fch->bg_lock);
 		fuse_uring_flush_bg(queue);
 		spin_unlock(&fch->bg_lock);
 	}
-
 	spin_unlock(&queue->lock);
 
 	if (error)
@@ -113,6 +113,7 @@ static void fuse_uring_abort_end_queue_requests(struct fuse_ring_queue *queue)
 	list_for_each_entry(req, &queue->fuse_req_queue, list)
 		clear_bit(FR_PENDING, &req->flags);
 	list_splice_init(&queue->fuse_req_queue, &req_list);
+	queue->nr_reqs = 0;
 	spin_unlock(&queue->lock);
 
 	/* must not hold queue lock to avoid order issues with fi->lock */
@@ -1280,10 +1281,13 @@ void fuse_uring_queue_fuse_req(struct fuse_iqueue *fiq, struct fuse_req *req)
 	req->ring_queue = queue;
 	ent = list_first_entry_or_null(&queue->ent_avail_queue,
 				       struct fuse_ring_ent, list);
+	queue->nr_reqs++;
+
 	if (ent)
 		fuse_uring_add_req_to_ring_ent(ent, req);
 	else
 		list_add_tail(&req->list, &queue->fuse_req_queue);
+
 	spin_unlock(&queue->lock);
 
 	if (ent)
@@ -1319,6 +1323,7 @@ bool fuse_uring_queue_bq_req(struct fuse_req *req)
 	set_bit(FR_URING, &req->flags);
 	req->ring_queue = queue;
 	list_add_tail(&req->list, &queue->fuse_req_bg_queue);
+	queue->nr_reqs++;
 
 	ent = list_first_entry_or_null(&queue->ent_avail_queue,
 				       struct fuse_ring_ent, list);
@@ -1351,8 +1356,16 @@ bool fuse_uring_queue_bq_req(struct fuse_req *req)
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
index 368f4d0790ebbf588277a3eb20e55ede216201ff..9488d77c42ece6f7798992e5abd3a9f5d5151fad 100644
--- a/fs/fuse/dev_uring_i.h
+++ b/fs/fuse/dev_uring_i.h
@@ -94,6 +94,9 @@ struct fuse_ring_queue {
 	/* background fuse requests */
 	struct list_head fuse_req_bg_queue;
 
+	/* number of requests queued or in userspace */
+	unsigned int nr_reqs;
+
 	struct fuse_pqueue fpq;
 
 	unsigned int active_background;

-- 
2.43.0

