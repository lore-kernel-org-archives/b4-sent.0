From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 29 May 2026 00:55:08 +0200
Subject: [PATCH v5 4/7] fuse: {io-uring} Allow reduced number of ring
 queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-reduced-nr-ring-queues_3-v5-4-1dc08c2fccf6@bsbernd.com>
References: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
In-Reply-To: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, Luis Henriques <luis@igalia.com>, 
 Gang He <dchg2000@gmail.com>, fuse-devel@lists.linux.dev, 
 Bernd Schubert <bschubert@ddn.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780008905; l=11630;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=mFbYznAaoos+vjj7A8c5LeUWOmUvJftFeg4c9UqhtdQ=;
 b=nnE7IJZ3smn3kbrqa/Nb1vNOvvATAe3vk4ZC71G6Gt5RPJ7sKPKYxXD4U+OBKyP+WioKvoS1y
 D42ARDFaBbyC07bGO10tFGwshPPmhhKDXOokGmUevMecO4gw8DdCxCl
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bernd Schubert <bschubert@ddn.com>

Queues selection (fuse_uring_get_queue) can handle reduced number
queues - using io-uring is possible now even with a single
queue and entry.

The FUSE_URING_REDUCED_Q flag is introduced tell fuse server that
reduced queues are possible, i.e. if the flag is set, fuse server
is free to reduce number queues.

Notheworth is also that a fuse-io-uring is now marked as ready
after the fist queue was created.

Signed-off-by: Bernd Schubert <bschubert@ddn.com>
---
 fs/fuse/dev_uring.c       | 171 +++++++++++++++++++++++++++-------------------
 fs/fuse/dev_uring_i.h     |   3 +
 fs/fuse/inode.c           |   2 +-
 include/uapi/linux/fuse.h |  10 ++-
 4 files changed, 112 insertions(+), 74 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 497093384c31e729053d2f5046c9ec59461ac035..d02266b483c89d105bd6301133820697f7caba9c 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -255,11 +255,11 @@ static int fuse_uring_init_q_map(struct fuse_queue_map *q_map, size_t nr_cpu)
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
 
@@ -269,7 +269,7 @@ static int fuse_uring_create_q_masks(struct fuse_ring *ring)
 		return -ENOMEM;
 	for (node = 0; node < ring->nr_numa_nodes; node++) {
 		err = fuse_uring_init_q_map(&ring->numa_q_map[node],
-					   ring->max_nr_queues);
+					    nr_queues);
 		if (err)
 			return err;
 	}
@@ -301,7 +301,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 	max_payload_size = max(FUSE_MIN_READ_BUFFER, fch->max_write);
 	max_payload_size = max(max_payload_size, fch->max_pages * PAGE_SIZE);
 
-	err = fuse_uring_create_q_masks(ring);
+	err = fuse_uring_create_q_masks(ring, nr_queues);
 	if (err)
 		goto out_err;
 
@@ -330,12 +330,36 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
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
 	struct fuse_chan *fch = ring->chan;
 	struct fuse_ring_queue *queue;
 	struct list_head *pq;
+	int node;
 
 	queue = kzalloc_obj(*queue, GFP_KERNEL_ACCOUNT);
 	if (!queue)
@@ -373,6 +397,30 @@ static struct fuse_ring_queue *fuse_uring_create_queue(struct fuse_ring *ring,
 	 * write_once and lock as the caller mostly doesn't take the lock at all
 	 */
 	WRITE_ONCE(ring->queues[qid], queue);
+
+	/* Static mapping from cpu to per numa queues */
+	node = cpu_to_node(qid);
+	fuse_uring_cpu_qid_mapping(ring, qid, &ring->numa_q_map[node], node);
+
+	/* global mapping */
+	fuse_uring_cpu_qid_mapping(ring, qid, &ring->q_map, -1);
+
+	/*
+	 * Pairs with smp_load_acquire() in fuse_uring_select_queue().
+	 * Released before the per-numa bump below so that observing
+	 * numa_q_map[node].nr_queues > 0 implies q_map.nr_queues > 0.
+	 */
+	smp_store_release(&ring->q_map.nr_queues,
+			  ring->q_map.nr_queues + 1);
+
+	/*
+	 * smp_store_release, as the variable is read without fc->lock and
+	 * we need to avoid compiler re-ordering of updating the nr_queues
+	 * and setting ring->numa_queues[node].cpu_to_qid above
+	 */
+	smp_store_release(&ring->numa_q_map[node].nr_queues,
+			  ring->numa_q_map[node].nr_queues + 1);
+
 	spin_unlock(&fch->lock);
 
 	return queue;
@@ -1017,61 +1065,6 @@ static int fuse_uring_commit_fetch(struct io_uring_cmd *cmd, int issue_flags,
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
-	struct fuse_chan *fch = ring->chan;
-	struct fuse_iqueue *fiq = &fch->iq;
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
-			wake_up_all(&fch->blocked_waitq);
-		}
-	}
-}
-
 /*
  * sqe->addr is a ptr to an iovec array, iov[0] has the headers, iov[1]
  * the payload
@@ -1155,6 +1148,7 @@ static int fuse_uring_register(struct io_uring_cmd *cmd,
 	struct fuse_ring *ring = smp_load_acquire(&fch->ring);
 	struct fuse_ring_queue *queue;
 	struct fuse_ring_ent *ent;
+	struct fuse_iqueue *fiq = &fch->iq;
 	int err;
 	unsigned int qid = READ_ONCE(cmd_req->qid);
 
@@ -1186,7 +1180,19 @@ static int fuse_uring_register(struct io_uring_cmd *cmd,
 	if (IS_ERR(ent))
 		return PTR_ERR(ent);
 
-	fuse_uring_do_register(ent, cmd, issue_flags);
+	fuse_uring_prepare_cancel(cmd, issue_flags, ent);
+	if (!READ_ONCE(ring->ready)) {
+		WRITE_ONCE(fiq->ops, &fuse_io_uring_ops);
+		WRITE_ONCE(ring->ready, true);
+		wake_up_all(&fch->blocked_waitq);
+	}
+
+	spin_lock(&queue->lock);
+	ent->cmd = cmd;
+	spin_unlock(&queue->lock);
+
+	/* fetch requests that got queued during registration */
+	fuse_uring_next_fuse_req(ent, queue, issue_flags);
 
 	return 0;
 }
@@ -1302,22 +1308,43 @@ static void fuse_uring_send_in_task(struct io_tw_req tw_req, io_tw_token_t tw)
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
+	/*
+	 * Pairs with smp_store_release() in fuse_uring_create_queue().
+	 * Ensures that if nr_queues is observed > 0, the matching
+	 * cpu_to_qid[] and ring->queues[] writes are visible too.
+	 */
+	nr_queues = smp_load_acquire(&ring->numa_q_map[node].nr_queues);
+	if (nr_queues) {
+		qid = ring->numa_q_map[node].cpu_to_qid[cpu];
+		if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
+			return NULL;
+		return READ_ONCE(ring->queues[qid]);
+	}
 
-	return queue;
+	/* global registered queue bitmap */
+	if (!smp_load_acquire(&ring->q_map.nr_queues))
+		return NULL;
+	qid = ring->q_map.cpu_to_qid[cpu];
+	if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
+		return NULL; /* Might happen on teardown */
+	return READ_ONCE(ring->queues[qid]);
 }
 
 static void fuse_uring_dispatch_ent(struct fuse_ring_ent *ent)
@@ -1337,7 +1364,7 @@ void fuse_uring_queue_fuse_req(struct fuse_iqueue *fiq, struct fuse_req *req)
 	int err;
 
 	err = -EINVAL;
-	queue = fuse_uring_task_to_queue(ring);
+	queue = fuse_uring_select_queue(ring);
 	if (!queue)
 		goto err;
 
@@ -1381,7 +1408,7 @@ bool fuse_uring_queue_bq_req(struct fuse_req *req)
 	struct fuse_ring_queue *queue;
 	struct fuse_ring_ent *ent = NULL;
 
-	queue = fuse_uring_task_to_queue(ring);
+	queue = fuse_uring_select_queue(ring);
 	if (!queue)
 		return false;
 
diff --git a/fs/fuse/dev_uring_i.h b/fs/fuse/dev_uring_i.h
index cb60d6a1dd5573b3e8f80a2581df25738b94ade0..8761f8ef101630424e4090573ec8a377ae968062 100644
--- a/fs/fuse/dev_uring_i.h
+++ b/fs/fuse/dev_uring_i.h
@@ -108,6 +108,9 @@ struct fuse_queue_map {
 	/* Tracks which queues are registered */
 	cpumask_var_t registered_q_mask;
 
+	/* number of registered queues */
+	size_t nr_queues;
+
 	/* cpu to qid mapping */
 	int *cpu_to_qid;
 };
diff --git a/fs/fuse/inode.c b/fs/fuse/inode.c
index 0897f8e62b4d18f11a1c60642b32a299e0ef22a0..a768ef3938ea8853a697ef2281a789919716332f 100644
--- a/fs/fuse/inode.c
+++ b/fs/fuse/inode.c
@@ -1465,7 +1465,7 @@ static struct fuse_init_args *fuse_new_init(struct fuse_mount *fm)
 		FUSE_SECURITY_CTX | FUSE_CREATE_SUPP_GROUP |
 		FUSE_HAS_EXPIRE_ONLY | FUSE_DIRECT_IO_ALLOW_MMAP |
 		FUSE_NO_EXPORT_SUPPORT | FUSE_HAS_RESEND | FUSE_ALLOW_IDMAP |
-		FUSE_REQUEST_TIMEOUT;
+		FUSE_REQUEST_TIMEOUT | FUSE_URING_REDUCED_Q;
 #ifdef CONFIG_FUSE_DAX
 	if (fm->fc->dax)
 		flags |= FUSE_MAP_ALIGNMENT;
diff --git a/include/uapi/linux/fuse.h b/include/uapi/linux/fuse.h
index c13e1f9a2f12bd39f535188cb5466688eba42263..3f3afbecfd34b3a239234086072683ef69bc48e2 100644
--- a/include/uapi/linux/fuse.h
+++ b/include/uapi/linux/fuse.h
@@ -240,6 +240,9 @@
  *  - add FUSE_COPY_FILE_RANGE_64
  *  - add struct fuse_copy_file_range_out
  *  - add FUSE_NOTIFY_PRUNE
+ *
+ *  7.46
+ *  - add FUSE_URING_REDUCED_Q
  */
 
 #ifndef _LINUX_FUSE_H
@@ -275,7 +278,7 @@
 #define FUSE_KERNEL_VERSION 7
 
 /** Minor version number of this interface */
-#define FUSE_KERNEL_MINOR_VERSION 45
+#define FUSE_KERNEL_MINOR_VERSION 46
 
 /** The node ID of the root inode */
 #define FUSE_ROOT_ID 1
@@ -448,6 +451,10 @@ struct fuse_file_lock {
  * FUSE_OVER_IO_URING: Indicate that client supports io-uring
  * FUSE_REQUEST_TIMEOUT: kernel supports timing out requests.
  *			 init_out.request_timeout contains the timeout (in secs)
+ * FUSE_URING_REDUCED_Q: Client (kernel) supports less queues - Server is free
+ *			 to register between 1 and nr-core io-uring queues
+ *			 Flag for fuse-sever only, kernel always supports
+ *			 1..nr-cores queues.
  */
 #define FUSE_ASYNC_READ		(1 << 0)
 #define FUSE_POSIX_LOCKS	(1 << 1)
@@ -495,6 +502,7 @@ struct fuse_file_lock {
 #define FUSE_ALLOW_IDMAP	(1ULL << 40)
 #define FUSE_OVER_IO_URING	(1ULL << 41)
 #define FUSE_REQUEST_TIMEOUT	(1ULL << 42)
+#define FUSE_URING_REDUCED_Q	(1ULL << 43)
 
 /**
  * CUSE INIT request/reply flags

-- 
2.43.0

