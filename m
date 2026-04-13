From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 13 Apr 2026 11:41:26 +0200
Subject: [PATCH v4 3/8] fuse: {io-uring} Use bitmaps to track registered
 queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260413-reduced-nr-ring-queues_3-v4-3-982b6414b723@bsbernd.com>
References: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
In-Reply-To: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, linux-fsdevel@vger.kernel.org, 
 Luis Henriques <luis@igalia.com>, Gang He <dchg2000@gmail.com>, 
 Bernd Schubert <bschubert@ddn.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776073284; l=5867;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=IxpFzkQ3nKj25urIGq6DcXr1YNJfsUdHhSKe8a+Ez2o=;
 b=QQdlHpkqg01ifYnqW1uDcpgQRE7LDUozzowdKGiHmZ3Uh9m43SSM5Rdts4bGB5daVw0+UlSXL
 4OYi5MZ6mS/AVqerjK7K1p14Sm84vXUjCENKr3dQfjWmIp5Vrd5GLib
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bernd Schubert <bschubert@ddn.com>

Add per-CPU and per-NUMA node bitmasks to track which
io-uring queues are registered.

Signed-off-by: Bernd Schubert <bschubert@ddn.com>
---
 fs/fuse/dev_uring.c   | 73 +++++++++++++++++++++++++++++++++++++++++++++++++++
 fs/fuse/dev_uring_i.h | 20 ++++++++++++++
 2 files changed, 93 insertions(+)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 08c49e5b65ee950a9749a034b1e9d0a8883e1d31..1d1305d38efa07641128a865aec1745d2e040b93 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -186,6 +186,25 @@ bool fuse_uring_request_expired(struct fuse_conn *fc)
 	return false;
 }
 
+static void fuse_ring_destruct_q_map(struct fuse_queue_map *q_map)
+{
+	free_cpumask_var(q_map->registered_q_mask);
+	kfree(q_map->cpu_to_qid);
+}
+
+static void fuse_uring_destruct_q_masks(struct fuse_ring *ring)
+{
+	int node;
+
+	fuse_ring_destruct_q_map(&ring->q_map);
+
+	if (ring->numa_q_map) {
+		for (node = 0; node < ring->nr_numa_nodes; node++)
+			fuse_ring_destruct_q_map(&ring->numa_q_map[node]);
+		kfree(ring->numa_q_map);
+	}
+}
+
 void fuse_uring_destruct(struct fuse_conn *fc)
 {
 	struct fuse_ring *ring = fc->ring;
@@ -217,11 +236,44 @@ void fuse_uring_destruct(struct fuse_conn *fc)
 		ring->queues[qid] = NULL;
 	}
 
+	fuse_uring_destruct_q_masks(ring);
 	kfree(ring->queues);
 	kfree(ring);
 	fc->ring = NULL;
 }
 
+static int fuse_uring_init_q_map(struct fuse_queue_map *q_map, size_t nr_cpu)
+{
+	if (!zalloc_cpumask_var(&q_map->registered_q_mask, GFP_KERNEL_ACCOUNT))
+		return -ENOMEM;
+
+	q_map->cpu_to_qid = kzalloc_objs(*q_map->cpu_to_qid, nr_cpu,
+					 GFP_KERNEL_ACCOUNT);
+
+	return 0;
+}
+
+static int fuse_uring_create_q_masks(struct fuse_ring *ring)
+{
+	int err, node;
+
+	err = fuse_uring_init_q_map(&ring->q_map, ring->max_nr_queues);
+	if (err)
+		return err;
+
+	ring->numa_q_map = kzalloc_objs(*ring->numa_q_map, ring->nr_numa_nodes,
+					GFP_KERNEL_ACCOUNT);
+	if (!ring->numa_q_map)
+		return -ENOMEM;
+	for (node = 0; node < ring->nr_numa_nodes; node++) {
+		err = fuse_uring_init_q_map(&ring->numa_q_map[node],
+					   ring->max_nr_queues);
+		if (err)
+			return err;
+	}
+	return 0;
+}
+
 /*
  * Basic ring setup for this connection based on the provided configuration
  */
@@ -231,6 +283,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_conn *fc)
 	size_t nr_queues = num_possible_cpus();
 	struct fuse_ring *res = NULL;
 	size_t max_payload_size;
+	int err;
 
 	ring = kzalloc_obj(*fc->ring, GFP_KERNEL_ACCOUNT);
 	if (!ring)
@@ -241,9 +294,15 @@ static struct fuse_ring *fuse_uring_create(struct fuse_conn *fc)
 	if (!ring->queues)
 		goto out_err;
 
+	ring->nr_numa_nodes = num_online_nodes();
+
 	max_payload_size = max(FUSE_MIN_READ_BUFFER, fc->max_write);
 	max_payload_size = max(max_payload_size, fc->max_pages * PAGE_SIZE);
 
+	err = fuse_uring_create_q_masks(ring);
+	if (err)
+		goto out_err;
+
 	spin_lock(&fc->lock);
 	if (fc->ring) {
 		/* race, another thread created the ring in the meantime */
@@ -263,6 +322,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_conn *fc)
 	return ring;
 
 out_err:
+	fuse_uring_destruct_q_masks(ring);
 	kfree(ring->queues);
 	kfree(ring);
 	return res;
@@ -425,6 +485,7 @@ static void fuse_uring_log_ent_state(struct fuse_ring *ring)
 			pr_info(" ent-commit-queue ring=%p qid=%d ent=%p state=%d\n",
 				ring, qid, ent, ent->state);
 		}
+
 		spin_unlock(&queue->lock);
 	}
 	ring->stop_debug_log = 1;
@@ -471,6 +532,7 @@ static void fuse_uring_async_stop_queues(struct work_struct *work)
 void fuse_uring_stop_queues(struct fuse_ring *ring)
 {
 	int qid;
+	int node;
 
 	for (qid = 0; qid < ring->max_nr_queues; qid++) {
 		struct fuse_ring_queue *queue = READ_ONCE(ring->queues[qid]);
@@ -481,6 +543,13 @@ void fuse_uring_stop_queues(struct fuse_ring *ring)
 		fuse_uring_teardown_entries(queue);
 	}
 
+	/* Reset all queue masks, we won't process any more IO */
+	cpumask_clear(ring->q_map.registered_q_mask);
+	for (node = 0; node < ring->nr_numa_nodes; node++) {
+		if (ring->numa_q_map)
+			cpumask_clear(ring->numa_q_map[node].registered_q_mask);
+	}
+
 	if (atomic_read(&ring->queue_refs) > 0) {
 		ring->teardown_time = jiffies;
 		INIT_DELAYED_WORK(&ring->async_teardown_work,
@@ -988,6 +1057,10 @@ static void fuse_uring_do_register(struct fuse_ring_ent *ent,
 	struct fuse_ring *ring = queue->ring;
 	struct fuse_conn *fc = ring->fc;
 	struct fuse_iqueue *fiq = &fc->iq;
+	int node = cpu_to_node(queue->qid);
+
+	if (WARN_ON_ONCE(node >= ring->nr_numa_nodes))
+		node = 0;
 
 	fuse_uring_prepare_cancel(cmd, issue_flags, ent);
 
diff --git a/fs/fuse/dev_uring_i.h b/fs/fuse/dev_uring_i.h
index 708412294982566919122a1a0d7f741217c763ce..83506f431b97249c8f0c82f89f0fce41021288dd 100644
--- a/fs/fuse/dev_uring_i.h
+++ b/fs/fuse/dev_uring_i.h
@@ -104,6 +104,17 @@ struct fuse_ring_queue {
 	bool stopped;
 };
 
+struct fuse_queue_map {
+	/* Tracks which queues are registered */
+	cpumask_var_t registered_q_mask;
+
+	/* number of registered queues */
+	size_t nr_queues;
+
+	/* cpu to qid mapping */
+	int *cpu_to_qid;
+};
+
 /**
  * Describes if uring is for communication and holds alls the data needed
  * for uring communication
@@ -115,6 +126,9 @@ struct fuse_ring {
 	/* number of ring queues */
 	size_t max_nr_queues;
 
+	/* number of numa nodes */
+	int nr_numa_nodes;
+
 	/* maximum payload/arg size */
 	size_t max_payload_sz;
 
@@ -125,6 +139,12 @@ struct fuse_ring {
 	 */
 	unsigned int stop_debug_log : 1;
 
+	/* per numa node queue tracking */
+	struct fuse_queue_map *numa_q_map;
+
+	/* all queue tracking */
+	struct fuse_queue_map q_map;
+
 	wait_queue_head_t stop_waitq;
 
 	/* async tear down */

-- 
2.43.0

