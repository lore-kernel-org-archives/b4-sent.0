From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 13 Apr 2026 11:41:28 +0200
Subject: [PATCH v4 5/8] fuse: {io-uring} Allow reduced number of ring
 queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260413-reduced-nr-ring-queues_3-v4-5-982b6414b723@bsbernd.com>
References: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
In-Reply-To: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, linux-fsdevel@vger.kernel.org, 
 Luis Henriques <luis@igalia.com>, Gang He <dchg2000@gmail.com>, 
 Bernd Schubert <bschubert@ddn.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776073284; l=10088;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=PmA84fINNB6ANqH1vlW6VLQUVsus2Autb25CQKOz73o=;
 b=rDdGoJoS/wCUehdMq6MXaCINncEQx8hLVgnWk3iEu0K7pRzWAzCzRDuCbaL40clFMTWtyyihF
 ul4X3ISVrGCAjegdMiTwcIoY9rA15fBmob8bziR/dquY6lmnpxKf+FK
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bernd Schubert <bschubert@ddn.com>

Queues selection (fuse_uring_get_queue) can handle reduced number
queues - using io-uring is possible now even with a single
queue and entry.

The FUSE_URING_REDUCED_Q flag is being introduce tell fuse server that
reduced queues are possible, i.e. if the flag is set, fuse server
is free to reduce number queues.

Signed-off-by: Bernd Schubert <bschubert@ddn.com>
---
 fs/fuse/dev_uring.c       | 160 ++++++++++++++++++++++++----------------------
 fs/fuse/inode.c           |   2 +-
 include/uapi/linux/fuse.h |   3 +
 3 files changed, 88 insertions(+), 77 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 9dcbc39531f0e019e5abf58a29cdf6c75fafdca1..e68089babaf89fb81741e4a5e605c6e36a137f9e 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -249,15 +249,17 @@ static int fuse_uring_init_q_map(struct fuse_queue_map *q_map, size_t nr_cpu)
 
 	q_map->cpu_to_qid = kzalloc_objs(*q_map->cpu_to_qid, nr_cpu,
 					 GFP_KERNEL_ACCOUNT);
+	if (!q_map->cpu_to_qid)
+		return -ENOMEM;
 
 	return 0;
 }
 
-static int fuse_uring_create_q_masks(struct fuse_ring *ring)
+static int fuse_uring_create_q_masks(struct fuse_ring *ring, size_t nr_queues)
 {
 	int err, node;
 
-	err = fuse_uring_init_q_map(&ring->q_map, ring->max_nr_queues);
+	err = fuse_uring_init_q_map(&ring->q_map, nr_queues);
 	if (err)
 		return err;
 
@@ -267,7 +269,7 @@ static int fuse_uring_create_q_masks(struct fuse_ring *ring)
 		return -ENOMEM;
 	for (node = 0; node < ring->nr_numa_nodes; node++) {
 		err = fuse_uring_init_q_map(&ring->numa_q_map[node],
-					   ring->max_nr_queues);
+					    nr_queues);
 		if (err)
 			return err;
 	}
@@ -299,7 +301,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_conn *fc)
 	max_payload_size = max(FUSE_MIN_READ_BUFFER, fc->max_write);
 	max_payload_size = max(max_payload_size, fc->max_pages * PAGE_SIZE);
 
-	err = fuse_uring_create_q_masks(ring);
+	err = fuse_uring_create_q_masks(ring, nr_queues);
 	if (err)
 		goto out_err;
 
@@ -328,12 +330,36 @@ static struct fuse_ring *fuse_uring_create(struct fuse_conn *fc)
 	return res;
 }
 
+static void fuse_uring_cpu_qid_mapping(struct fuse_ring *ring, int qid,
+				       struct fuse_queue_map *q_map,
+				       int node)
+{
+	int cpu, qid_idx, mapping_count = 0;
+	size_t nr_queues;
+
+	cpumask_set_cpu(qid, q_map->registered_q_mask);
+	nr_queues = cpumask_weight(q_map->registered_q_mask);
+	for (cpu = 0; cpu < ring->max_nr_queues; cpu++) {
+		if (node != -1 && cpu_to_node(cpu) != node)
+			continue;
+
+		qid_idx = mapping_count % nr_queues;
+		q_map->cpu_to_qid[cpu] = cpumask_nth(qid_idx,
+						     q_map->registered_q_mask);
+		mapping_count++;
+		pr_debug("%s node=%d qid=%d qid_idx=%d nr_queues=%zu %d->%d\n",
+			 __func__, node, qid, qid_idx, nr_queues, cpu,
+			 q_map->cpu_to_qid[cpu]);
+	}
+}
+
 static struct fuse_ring_queue *fuse_uring_create_queue(struct fuse_ring *ring,
 						       int qid)
 {
 	struct fuse_conn *fc = ring->fc;
 	struct fuse_ring_queue *queue;
 	struct list_head *pq;
+	int node;
 
 	queue = kzalloc_obj(*queue, GFP_KERNEL_ACCOUNT);
 	if (!queue)
@@ -371,6 +397,22 @@ static struct fuse_ring_queue *fuse_uring_create_queue(struct fuse_ring *ring,
 	 * write_once and lock as the caller mostly doesn't take the lock at all
 	 */
 	WRITE_ONCE(ring->queues[qid], queue);
+
+	/* Static mapping from cpu to per numa queues */
+	node = cpu_to_node(qid);
+	fuse_uring_cpu_qid_mapping(ring, qid, &ring->numa_q_map[node], node);
+
+	/*
+	 * smp_store_release, as the variable is read without fc->lock and
+	 * we need to avoid compiler re-ordering of updating the nr_queues
+	 * and setting ring->numa_queues[node].cpu_to_qid above
+	 */
+	smp_store_release(&ring->numa_q_map[node].nr_queues,
+			  ring->numa_q_map[node].nr_queues + 1);
+
+	/* global mapping */
+	fuse_uring_cpu_qid_mapping(ring, qid, &ring->q_map, -1);
+
 	spin_unlock(&fc->lock);
 
 	return queue;
@@ -1021,65 +1063,6 @@ static int fuse_uring_commit_fetch(struct io_uring_cmd *cmd, int issue_flags,
 	return 0;
 }
 
-static bool is_ring_ready(struct fuse_ring *ring, int current_qid)
-{
-	int qid;
-	struct fuse_ring_queue *queue;
-	bool ready = true;
-
-	for (qid = 0; qid < ring->max_nr_queues && ready; qid++) {
-		if (current_qid == qid)
-			continue;
-
-		queue = ring->queues[qid];
-		if (!queue) {
-			ready = false;
-			break;
-		}
-
-		spin_lock(&queue->lock);
-		if (list_empty(&queue->ent_avail_queue))
-			ready = false;
-		spin_unlock(&queue->lock);
-	}
-
-	return ready;
-}
-
-/*
- * fuse_uring_req_fetch command handling
- */
-static void fuse_uring_do_register(struct fuse_ring_ent *ent,
-				   struct io_uring_cmd *cmd,
-				   unsigned int issue_flags)
-{
-	struct fuse_ring_queue *queue = ent->queue;
-	struct fuse_ring *ring = queue->ring;
-	struct fuse_conn *fc = ring->fc;
-	struct fuse_iqueue *fiq = &fc->iq;
-	int node = cpu_to_node(queue->qid);
-
-	if (WARN_ON_ONCE(node >= ring->nr_numa_nodes))
-		node = 0;
-
-	fuse_uring_prepare_cancel(cmd, issue_flags, ent);
-
-	spin_lock(&queue->lock);
-	ent->cmd = cmd;
-	fuse_uring_ent_avail(ent, queue);
-	spin_unlock(&queue->lock);
-
-	if (!ring->ready) {
-		bool ready = is_ring_ready(ring, queue->qid);
-
-		if (ready) {
-			WRITE_ONCE(fiq->ops, &fuse_io_uring_ops);
-			WRITE_ONCE(ring->ready, true);
-			wake_up_all(&fc->blocked_waitq);
-		}
-	}
-}
-
 /*
  * sqe->addr is a ptr to an iovec array, iov[0] has the headers, iov[1]
  * the payload
@@ -1163,6 +1146,7 @@ static int fuse_uring_register(struct io_uring_cmd *cmd,
 	struct fuse_ring *ring = smp_load_acquire(&fc->ring);
 	struct fuse_ring_queue *queue;
 	struct fuse_ring_ent *ent;
+	struct fuse_iqueue *fiq = &fc->iq;
 	int err;
 	unsigned int qid = READ_ONCE(cmd_req->qid);
 
@@ -1194,8 +1178,18 @@ static int fuse_uring_register(struct io_uring_cmd *cmd,
 	if (IS_ERR(ent))
 		return PTR_ERR(ent);
 
-	fuse_uring_do_register(ent, cmd, issue_flags);
+	fuse_uring_prepare_cancel(cmd, issue_flags, ent);
+	if (!ring->ready) {
+		WRITE_ONCE(fiq->ops, &fuse_io_uring_ops);
+		WRITE_ONCE(ring->ready, true);
+		wake_up_all(&fc->blocked_waitq);
+	}
 
+	spin_lock(&queue->lock);
+	ent->cmd = cmd;
+	spin_unlock(&queue->lock);
+
+	/* Marks the ring entry as ready */
 	fuse_uring_next_fuse_req(ent, queue, issue_flags);
 
 	return 0;
@@ -1312,22 +1306,36 @@ static void fuse_uring_send_in_task(struct io_tw_req tw_req, io_tw_token_t tw)
 	fuse_uring_send(ent, cmd, err, issue_flags);
 }
 
-static struct fuse_ring_queue *fuse_uring_task_to_queue(struct fuse_ring *ring)
+static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring)
 {
 	unsigned int qid;
-	struct fuse_ring_queue *queue;
+	int node;
+	unsigned int nr_queues;
+	unsigned int cpu = task_cpu(current);
 
-	qid = task_cpu(current);
+	cpu = cpu % ring->max_nr_queues;
 
-	if (WARN_ONCE(qid >= ring->max_nr_queues,
-		      "Core number (%u) exceeds nr queues (%zu)\n", qid,
-		      ring->max_nr_queues))
-		qid = 0;
+	/* numa local registered queue bitmap */
+	node = cpu_to_node(cpu);
+	if (WARN_ONCE(node >= ring->nr_numa_nodes,
+		      "Node number (%d) exceeds nr nodes (%d)\n",
+		      node, ring->nr_numa_nodes)) {
+		node = 0;
+	}
 
-	queue = ring->queues[qid];
-	WARN_ONCE(!queue, "Missing queue for qid %d\n", qid);
+	nr_queues = READ_ONCE(ring->numa_q_map[node].nr_queues);
+	if (nr_queues) {
+		qid = ring->numa_q_map[node].cpu_to_qid[cpu];
+		if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
+			return NULL;
+		return READ_ONCE(ring->queues[qid]);
+	}
 
-	return queue;
+	/* global registered queue bitmap */
+	qid = ring->q_map.cpu_to_qid[cpu];
+	if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
+		return NULL;
+	return READ_ONCE(ring->queues[qid]);
 }
 
 static void fuse_uring_dispatch_ent(struct fuse_ring_ent *ent)
@@ -1348,7 +1356,7 @@ void fuse_uring_queue_fuse_req(struct fuse_iqueue *fiq, struct fuse_req *req)
 	int err;
 
 	err = -EINVAL;
-	queue = fuse_uring_task_to_queue(ring);
+	queue = fuse_uring_select_queue(ring);
 	if (!queue)
 		goto err;
 
@@ -1392,7 +1400,7 @@ bool fuse_uring_queue_bq_req(struct fuse_req *req)
 	struct fuse_ring_queue *queue;
 	struct fuse_ring_ent *ent = NULL;
 
-	queue = fuse_uring_task_to_queue(ring);
+	queue = fuse_uring_select_queue(ring);
 	if (!queue)
 		return false;
 
diff --git a/fs/fuse/inode.c b/fs/fuse/inode.c
index c795abe47a4f4a488b9623c389e4afce43c6647d..5cb903186c29a77727551fe72c4cabf705a22258 100644
--- a/fs/fuse/inode.c
+++ b/fs/fuse/inode.c
@@ -1506,7 +1506,7 @@ static struct fuse_init_args *fuse_new_init(struct fuse_mount *fm)
 		FUSE_SECURITY_CTX | FUSE_CREATE_SUPP_GROUP |
 		FUSE_HAS_EXPIRE_ONLY | FUSE_DIRECT_IO_ALLOW_MMAP |
 		FUSE_NO_EXPORT_SUPPORT | FUSE_HAS_RESEND | FUSE_ALLOW_IDMAP |
-		FUSE_REQUEST_TIMEOUT;
+		FUSE_REQUEST_TIMEOUT | FUSE_URING_REDUCED_Q;
 #ifdef CONFIG_FUSE_DAX
 	if (fm->fc->dax)
 		flags |= FUSE_MAP_ALIGNMENT;
diff --git a/include/uapi/linux/fuse.h b/include/uapi/linux/fuse.h
index c13e1f9a2f12bd39f535188cb5466688eba42263..3da20d9bba1cb6336734511d21da9f64cea0e720 100644
--- a/include/uapi/linux/fuse.h
+++ b/include/uapi/linux/fuse.h
@@ -448,6 +448,8 @@ struct fuse_file_lock {
  * FUSE_OVER_IO_URING: Indicate that client supports io-uring
  * FUSE_REQUEST_TIMEOUT: kernel supports timing out requests.
  *			 init_out.request_timeout contains the timeout (in secs)
+ * FUSE_URING_REDUCED_Q: Client (kernel) supports less queues - Server is free
+ *			 to register between 1 and nr-core io-uring queues
  */
 #define FUSE_ASYNC_READ		(1 << 0)
 #define FUSE_POSIX_LOCKS	(1 << 1)
@@ -495,6 +497,7 @@ struct fuse_file_lock {
 #define FUSE_ALLOW_IDMAP	(1ULL << 40)
 #define FUSE_OVER_IO_URING	(1ULL << 41)
 #define FUSE_REQUEST_TIMEOUT	(1ULL << 42)
+#define FUSE_URING_REDUCED_Q (1ULL << 43)
 
 /**
  * CUSE INIT request/reply flags

-- 
2.43.0

