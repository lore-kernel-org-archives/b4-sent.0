From: Bernd Schubert <bernd@bsbernd.com>
Date: Sat, 24 Oct 2026 00:50:31 +0200
Subject: [PATCH v7 2/8] fuse: {io-uring} Rename ring->nr_queues to
 max_nr_queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-reduced-nr-ring-queues_3-v7-2-4e77e284fd48@bsbernd.com>
References: <20261024-reduced-nr-ring-queues_3-v7-0-4e77e284fd48@bsbernd.com>
In-Reply-To: <20261024-reduced-nr-ring-queues_3-v7-0-4e77e284fd48@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=4621; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=zahWFXAlAGLUS/1774IaoMuoQhlkxGF5zpMuxg/js4Y=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJuP9n9bqdUTYp475Hbz8+rviuw2Bsw9e2e19mLqxdxy
 Z95GPVxTkcpC4MYB4OsmCJLl8Qe2yn/+GTVvq6/DjOHlQlkCAMXpwBM5OI3hr+yN0tluOvbcx8p
 tukv3rXG7eN9a9/QWZrHi76n6ydIhj5jZFj0aelrntaM5lecxemCuwNSztZk3Nwf7LixuPBHUHz
 PO1YA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is preparation for follow up commits that allow to run with a
reduced number of queues.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
Reviewed-by: Joanne Koong <joannelkoong@gmail.com>
---
 fs/fuse/dev_uring.c   | 26 +++++++++++++-------------
 fs/fuse/dev_uring_i.h |  2 +-
 2 files changed, 14 insertions(+), 14 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 1aca6ce906f0..c9a78c2bee99 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -201,7 +201,7 @@ void fuse_uring_abort_end_requests(struct fuse_ring *ring)
 	struct fuse_ring_queue *queue;
 	struct fuse_chan *fch = ring->chan;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		queue = READ_ONCE(ring->queues[qid]);
 		if (!queue)
 			continue;
@@ -241,7 +241,7 @@ bool fuse_uring_request_expired(struct fuse_chan *fch)
 	if (!ring)
 		return false;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		queue = READ_ONCE(ring->queues[qid]);
 		if (!queue)
 			continue;
@@ -268,7 +268,7 @@ void fuse_uring_destruct(struct fuse_chan *fch)
 	if (!ring)
 		return;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		struct fuse_ring_queue *queue = READ_ONCE(ring->queues[qid]);
 		struct fuse_ring_ent *ent, *next;
 
@@ -326,7 +326,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 
 	init_waitqueue_head(&ring->stop_waitq);
 
-	ring->nr_queues = nr_queues;
+	ring->max_nr_queues = nr_queues;
 	ring->chan = fch;
 	ring->max_payload_sz = max_payload_size;
 	smp_store_release(&fch->ring, ring);
@@ -485,7 +485,7 @@ static void fuse_uring_teardown_all_queues(struct fuse_ring *ring)
 {
 	int qid;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		struct fuse_ring_queue *queue = READ_ONCE(ring->queues[qid]);
 
 		if (!queue)
@@ -503,7 +503,7 @@ static void fuse_uring_log_ent_state(struct fuse_ring *ring)
 	int qid;
 	struct fuse_ring_ent *ent;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		struct fuse_ring_queue *queue = READ_ONCE(ring->queues[qid]);
 
 		if (!queue)
@@ -1256,7 +1256,7 @@ static int fuse_uring_commit_fetch(struct io_uring_cmd *cmd, int issue_flags,
 	if (!ring)
 		return err;
 
-	if (qid >= ring->nr_queues)
+	if (qid >= ring->max_nr_queues)
 		return -EINVAL;
 
 	queue = READ_ONCE(ring->queues[qid]);
@@ -1339,7 +1339,7 @@ static bool is_ring_ready(struct fuse_ring *ring, int current_qid)
 	struct fuse_ring_queue *queue;
 	bool ready = true;
 
-	for (qid = 0; qid < ring->nr_queues && ready; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues && ready; qid++) {
 		if (current_qid == qid)
 			continue;
 
@@ -1517,7 +1517,7 @@ static int fuse_uring_register(struct io_uring_cmd *cmd,
 	if (!ring)
 		return -EINVAL;
 
-	if (qid >= ring->nr_queues) {
+	if (qid >= ring->max_nr_queues) {
 		pr_info_ratelimited("fuse: Invalid ring qid %u\n", qid);
 		return -EINVAL;
 	}
@@ -1554,7 +1554,7 @@ static int fuse_uring_add_queue(struct io_uring_cmd *cmd, struct fuse_chan *fch)
 	if (!ring)
 		return -EINVAL;
 
-	if (qid >= ring->nr_queues) {
+	if (qid >= ring->max_nr_queues) {
 		pr_info_ratelimited("fuse: Invalid ring qid %u\n", qid);
 		return -EINVAL;
 	}
@@ -1588,7 +1588,7 @@ static int fuse_uring_add_bufpool(struct io_uring_cmd *cmd,
 	size_t pool_size, buf_size;
 	bool registered = cmd->flags & IORING_URING_CMD_FIXED;
 
-	if (!ring || qid >= ring->nr_queues || flags)
+	if (!ring || qid >= ring->max_nr_queues || flags)
 		return -EINVAL;
 
 	/* reserved for future use, must be zero */
@@ -1781,9 +1781,9 @@ static struct fuse_ring_queue *fuse_uring_task_to_queue(struct fuse_ring *ring)
 
 	qid = task_cpu(current);
 
-	if (WARN_ONCE(qid >= ring->nr_queues,
+	if (WARN_ONCE(qid >= ring->max_nr_queues,
 		      "Core number (%u) exceeds nr queues (%zu)\n", qid,
-		      ring->nr_queues))
+		      ring->max_nr_queues))
 		qid = 0;
 
 	queue = READ_ONCE(ring->queues[qid]);
diff --git a/fs/fuse/dev_uring_i.h b/fs/fuse/dev_uring_i.h
index 77f87075f62d..10e3936814cc 100644
--- a/fs/fuse/dev_uring_i.h
+++ b/fs/fuse/dev_uring_i.h
@@ -162,7 +162,7 @@ struct fuse_ring {
 	struct fuse_chan *chan;
 
 	/* number of ring queues */
-	size_t nr_queues;
+	size_t max_nr_queues;
 
 	/* maximum payload/arg size */
 	size_t max_payload_sz;

-- 
2.55.0

