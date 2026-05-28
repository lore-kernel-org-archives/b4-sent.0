From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 29 May 2026 00:55:07 +0200
Subject: [PATCH v5 3/7] fuse: {io-uring} Use bitmaps to track registered
 queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-reduced-nr-ring-queues_3-v5-3-1dc08c2fccf6@bsbernd.com>
References: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
In-Reply-To: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, Luis Henriques <luis@igalia.com>, 
 Gang He <dchg2000@gmail.com>, fuse-devel@lists.linux.dev, 
 Bernd Schubert <bschubert@ddn.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780008905; l=5033;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=/OVBLFCQIJga3t5g9sqoDYiXOSaMgi6qlDVEbyMJPCA=;
 b=dcQfk9arZj75cY9ZOtasCDmSzCBRa+LWMjbh8wIk4ukUq57a3y1LkTkdGZU8T402gbU2gF7b7
 CqXhaJesLjLADewIT9x9KPjS80oeuDr7Spr7WAmxXCBuL9YsqSQC9V5
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bernd Schubert <bschubert@ddn.com>

Add per-CPU and per-NUMA node bitmasks to track which
io-uring queues are registered.

Signed-off-by: Bernd Schubert <bschubert@ddn.com>
---
 fs/fuse/dev_uring.c   | 71 +++++++++++++++++++++++++++++++++++++++++++++++++++
 fs/fuse/dev_uring_i.h | 17 ++++++++++++
 2 files changed, 88 insertions(+)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 01cf372e7d9cafe2dfca003b881d9027098c8af4..497093384c31e729053d2f5046c9ec59461ac035 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -186,6 +186,25 @@ bool fuse_uring_request_expired(struct fuse_chan *fch)
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
 void fuse_uring_destruct(struct fuse_chan *fch)
 {
 	struct fuse_ring *ring = fch->ring;
@@ -217,11 +236,46 @@ void fuse_uring_destruct(struct fuse_chan *fch)
 		ring->queues[qid] = NULL;
 	}
 
+	fuse_uring_destruct_q_masks(ring);
 	kfree(ring->queues);
 	kfree(ring);
 	fch->ring = NULL;
 }
 
+static int fuse_uring_init_q_map(struct fuse_queue_map *q_map, size_t nr_cpu)
+{
+	if (!zalloc_cpumask_var(&q_map->registered_q_mask, GFP_KERNEL_ACCOUNT))
+		return -ENOMEM;
+
+	q_map->cpu_to_qid = kzalloc_objs(*q_map->cpu_to_qid, nr_cpu,
+					 GFP_KERNEL_ACCOUNT);
+	if (!q_map->cpu_to_qid)
+		return -ENOMEM;
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
@@ -231,6 +285,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 	size_t nr_queues = num_possible_cpus();
 	struct fuse_ring *res = NULL;
 	size_t max_payload_size;
+	int err;
 
 	ring = kzalloc_obj(*ring, GFP_KERNEL_ACCOUNT);
 	if (!ring)
@@ -241,9 +296,15 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 	if (!ring->queues)
 		goto out_err;
 
+	ring->nr_numa_nodes = num_online_nodes();
+
 	max_payload_size = max(FUSE_MIN_READ_BUFFER, fch->max_write);
 	max_payload_size = max(max_payload_size, fch->max_pages * PAGE_SIZE);
 
+	err = fuse_uring_create_q_masks(ring);
+	if (err)
+		goto out_err;
+
 	spin_lock(&fch->lock);
 	if (fch->ring) {
 		/* race, another thread created the ring in the meantime */
@@ -263,6 +324,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 	return ring;
 
 out_err:
+	fuse_uring_destruct_q_masks(ring);
 	kfree(ring->queues);
 	kfree(ring);
 	return res;
@@ -475,8 +537,17 @@ static void fuse_uring_async_stop_queues(struct work_struct *work)
  */
 void fuse_uring_stop_queues(struct fuse_ring *ring)
 {
+	int node;
+
 	fuse_uring_teardown_all_queues(ring);
 
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
diff --git a/fs/fuse/dev_uring_i.h b/fs/fuse/dev_uring_i.h
index 45d16e3d0de67cb42d3d7390fc402b56ba4ea270..cb60d6a1dd5573b3e8f80a2581df25738b94ade0 100644
--- a/fs/fuse/dev_uring_i.h
+++ b/fs/fuse/dev_uring_i.h
@@ -104,6 +104,14 @@ struct fuse_ring_queue {
 	bool stopped;
 };
 
+struct fuse_queue_map {
+	/* Tracks which queues are registered */
+	cpumask_var_t registered_q_mask;
+
+	/* cpu to qid mapping */
+	int *cpu_to_qid;
+};
+
 /*
  * Describes if uring is for communication and holds alls the data needed
  * for uring communication
@@ -115,6 +123,9 @@ struct fuse_ring {
 	/* number of ring queues */
 	size_t max_nr_queues;
 
+	/* number of numa nodes */
+	int nr_numa_nodes;
+
 	/* maximum payload/arg size */
 	size_t max_payload_sz;
 
@@ -125,6 +136,12 @@ struct fuse_ring {
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

