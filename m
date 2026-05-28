From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 29 May 2026 00:55:06 +0200
Subject: [PATCH v5 2/7] fuse: {io-uring} Rename ring->nr_queues to
 max_nr_queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-reduced-nr-ring-queues_3-v5-2-1dc08c2fccf6@bsbernd.com>
References: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
In-Reply-To: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, Luis Henriques <luis@igalia.com>, 
 Gang He <dchg2000@gmail.com>, fuse-devel@lists.linux.dev, 
 Bernd Schubert <bschubert@ddn.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780008905; l=4025;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=L1wc6JFQU0CQu21/LW/lH+hsGLhIBO5epAZp8l6FLT8=;
 b=cyDCWscFS12BTbwksPbL3d1to7PSyqDAqOawG49n3RO1pNAO5lj648bf4oY/Ey+OrdFZxIrqe
 ekdrapFXm5sCg0ZfumsxEnVgDDpfKg/AppxRTyNNXWWtFai0CZ61ZQC
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bernd Schubert <bschubert@ddn.com>

This is preparation for follow up commits that allow to run with a
reduced number of queues.

Signed-off-by: Bernd Schubert <bschubert@ddn.com>
Reviewed-by: Joanne Koong <joannelkoong@gmail.com>
---
 fs/fuse/dev_uring.c   | 22 +++++++++++-----------
 fs/fuse/dev_uring_i.h |  2 +-
 2 files changed, 12 insertions(+), 12 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index beea0eed203d3dfa90a54a698feb78a20778d9db..01cf372e7d9cafe2dfca003b881d9027098c8af4 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -126,7 +126,7 @@ void fuse_uring_abort_end_requests(struct fuse_ring *ring)
 	struct fuse_ring_queue *queue;
 	struct fuse_chan *fch = ring->chan;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		queue = READ_ONCE(ring->queues[qid]);
 		if (!queue)
 			continue;
@@ -167,7 +167,7 @@ bool fuse_uring_request_expired(struct fuse_chan *fch)
 	if (!ring)
 		return false;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		queue = READ_ONCE(ring->queues[qid]);
 		if (!queue)
 			continue;
@@ -194,7 +194,7 @@ void fuse_uring_destruct(struct fuse_chan *fch)
 	if (!ring)
 		return;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		struct fuse_ring_queue *queue = ring->queues[qid];
 		struct fuse_ring_ent *ent, *next;
 
@@ -254,7 +254,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 
 	init_waitqueue_head(&ring->stop_waitq);
 
-	ring->nr_queues = nr_queues;
+	ring->max_nr_queues = nr_queues;
 	ring->chan = fch;
 	ring->max_payload_sz = max_payload_size;
 	smp_store_release(&fch->ring, ring);
@@ -402,7 +402,7 @@ static void fuse_uring_teardown_all_queues(struct fuse_ring *ring)
 {
 	int qid;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		struct fuse_ring_queue *queue = READ_ONCE(ring->queues[qid]);
 
 		if (!queue)
@@ -420,7 +420,7 @@ static void fuse_uring_log_ent_state(struct fuse_ring *ring)
 	int qid;
 	struct fuse_ring_ent *ent;
 
-	for (qid = 0; qid < ring->nr_queues; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		struct fuse_ring_queue *queue = ring->queues[qid];
 
 		if (!queue)
@@ -889,7 +889,7 @@ static int fuse_uring_commit_fetch(struct io_uring_cmd *cmd, int issue_flags,
 	if (!ring)
 		return err;
 
-	if (qid >= ring->nr_queues)
+	if (qid >= ring->max_nr_queues)
 		return -EINVAL;
 
 	queue = ring->queues[qid];
@@ -952,7 +952,7 @@ static bool is_ring_ready(struct fuse_ring *ring, int current_qid)
 	struct fuse_ring_queue *queue;
 	bool ready = true;
 
-	for (qid = 0; qid < ring->nr_queues && ready; qid++) {
+	for (qid = 0; qid < ring->max_nr_queues && ready; qid++) {
 		if (current_qid == qid)
 			continue;
 
@@ -1094,7 +1094,7 @@ static int fuse_uring_register(struct io_uring_cmd *cmd,
 			return err;
 	}
 
-	if (qid >= ring->nr_queues) {
+	if (qid >= ring->max_nr_queues) {
 		pr_info_ratelimited("fuse: Invalid ring qid %u\n", qid);
 		return -EINVAL;
 	}
@@ -1238,9 +1238,9 @@ static struct fuse_ring_queue *fuse_uring_task_to_queue(struct fuse_ring *ring)
 
 	qid = task_cpu(current);
 
-	if (WARN_ONCE(qid >= ring->nr_queues,
+	if (WARN_ONCE(qid >= ring->max_nr_queues,
 		      "Core number (%u) exceeds nr queues (%zu)\n", qid,
-		      ring->nr_queues))
+		      ring->max_nr_queues))
 		qid = 0;
 
 	queue = ring->queues[qid];
diff --git a/fs/fuse/dev_uring_i.h b/fs/fuse/dev_uring_i.h
index 9488d77c42ece6f7798992e5abd3a9f5d5151fad..45d16e3d0de67cb42d3d7390fc402b56ba4ea270 100644
--- a/fs/fuse/dev_uring_i.h
+++ b/fs/fuse/dev_uring_i.h
@@ -113,7 +113,7 @@ struct fuse_ring {
 	struct fuse_chan *chan;
 
 	/* number of ring queues */
-	size_t nr_queues;
+	size_t max_nr_queues;
 
 	/* maximum payload/arg size */
 	size_t max_payload_sz;

-- 
2.43.0

