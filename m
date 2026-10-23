From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 23 Oct 2026 22:28:45 +0200
Subject: [PATCH v6 3/8] fuse: {io-uring} Add CPU to queue maps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-reduced-nr-ring-queues_3-v6-3-658235c9b9bd@bsbernd.com>
References: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
In-Reply-To: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=6225; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=XUBIaxc6DlzIhY7R4yro3EiTJmHWTtYcJ9TDERm8L7Y=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJuH26M05NeYPpue9gJlcMv/zbvznwQtWZ7x3nfFenpA
 o/NTqtu7ChlYRDjYJAVU2TpkthjO+Ufn6za1/XXYeawMoEMYeDiFICJ3M5l+Ml47fV+b132Y0vf
 zL66e9d5tTbuzwwntU7/3HTL++imLncjRoZrx++ZT03ew2pnrlj3yn4rj1Ioo0bqtH9frl7r2Hj
 m9EduAA==
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a preparation for a follow up commit that lets a server register
fewer queues than CPUs. A request issued on a CPU without its own queue
then needs another queue, preferably on the same NUMA node.

fuse_uring_create() builds a global and a per NUMA node CPU to queue
map. Every CPU maps to its own queue, and the maps do not change after
fuse_uring_create(). No change in behaviour: the next commit selects
queues through the maps.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c   | 116 +++++++++++++++++++++++++++++++++++++++++++++++++-
 fs/fuse/dev_uring_i.h |  17 ++++++++
 2 files changed, 132 insertions(+), 1 deletion(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index c9a78c2bee99..e24cca4c3df4 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -260,6 +260,25 @@ bool fuse_uring_request_expired(struct fuse_chan *fch)
 	return false;
 }
 
+static void fuse_uring_free_q_map(struct fuse_queue_map *q_map)
+{
+	free_cpumask_var(q_map->registered_q_mask);
+	kfree(q_map->cpu_to_qid);
+}
+
+static void fuse_uring_free_q_maps(struct fuse_queue_maps *maps)
+{
+	int node;
+
+	if (!maps)
+		return;
+
+	fuse_uring_free_q_map(&maps->global);
+	for (node = 0; node < nr_node_ids; node++)
+		fuse_uring_free_q_map(&maps->numa[node]);
+	kfree(maps);
+}
+
 void fuse_uring_destruct(struct fuse_chan *fch)
 {
 	struct fuse_ring *ring = fch->ring;
@@ -292,11 +311,96 @@ void fuse_uring_destruct(struct fuse_chan *fch)
 		WRITE_ONCE(ring->queues[qid], NULL);
 	}
 
+	fuse_uring_free_q_maps(ring->q_maps);
 	kfree(ring->queues);
 	kfree(ring);
 	fch->ring = NULL;
 }
 
+static int fuse_uring_alloc_q_map(struct fuse_queue_map *q_map)
+{
+	if (!zalloc_cpumask_var(&q_map->registered_q_mask, GFP_KERNEL_ACCOUNT))
+		return -ENOMEM;
+
+	q_map->cpu_to_qid = kzalloc_objs(*q_map->cpu_to_qid, nr_cpu_ids,
+					 GFP_KERNEL_ACCOUNT);
+	if (!q_map->cpu_to_qid)
+		return -ENOMEM;
+
+	return 0;
+}
+
+static struct fuse_queue_maps *fuse_uring_alloc_q_maps(void)
+{
+	struct fuse_queue_maps *maps, *result = NULL;
+	int node;
+
+	maps = kzalloc(struct_size(maps, numa, nr_node_ids),
+		       GFP_KERNEL_ACCOUNT);
+	if (!maps)
+		goto out;
+
+	if (fuse_uring_alloc_q_map(&maps->global))
+		goto out;
+
+	for (node = 0; node < nr_node_ids; node++) {
+		if (fuse_uring_alloc_q_map(&maps->numa[node]))
+			goto out;
+	}
+	result = maps;
+	maps = NULL;
+out:
+	fuse_uring_free_q_maps(maps);
+	return result;
+}
+
+static int fuse_uring_cpu_to_node(int cpu)
+{
+	int node = cpu_to_node(cpu);
+
+	/* a possible CPU that is not present can have no node */
+	if (node == NUMA_NO_NODE)
+		node = 0;
+
+	return node;
+}
+
+static void fuse_uring_cpu_qid_mapping(struct fuse_ring *ring,
+				       struct fuse_queue_map *q_map, int node)
+{
+	int cpu, qid_idx, mapping_count = 0;
+
+	q_map->nr_queues = cpumask_weight(q_map->registered_q_mask);
+	if (!q_map->nr_queues)
+		return;
+
+	for (cpu = 0; cpu < ring->max_nr_queues; cpu++) {
+		if (node != -1 && fuse_uring_cpu_to_node(cpu) != node)
+			continue;
+
+		qid_idx = mapping_count % q_map->nr_queues;
+		q_map->cpu_to_qid[cpu] = cpumask_nth(qid_idx,
+						     q_map->registered_q_mask);
+		mapping_count++;
+	}
+}
+
+static void fuse_uring_build_q_maps(struct fuse_ring *ring,
+				    struct fuse_queue_maps *maps)
+{
+	int node, registered_qid;
+
+	for_each_cpu(registered_qid, maps->global.registered_q_mask) {
+		node = fuse_uring_cpu_to_node(registered_qid);
+		cpumask_set_cpu(registered_qid,
+				maps->numa[node].registered_q_mask);
+	}
+
+	fuse_uring_cpu_qid_mapping(ring, &maps->global, -1);
+	for (node = 0; node < nr_node_ids; node++)
+		fuse_uring_cpu_qid_mapping(ring, &maps->numa[node], node);
+}
+
 /*
  * Basic ring setup for this connection based on the provided configuration
  */
@@ -305,6 +409,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 	struct fuse_ring *ring;
 	size_t nr_queues = num_possible_cpus();
 	size_t max_payload_size;
+	int qid;
 
 	ring = kzalloc_obj(*ring, GFP_KERNEL_ACCOUNT);
 	if (!ring)
@@ -314,6 +419,15 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 				    GFP_KERNEL_ACCOUNT);
 	if (!ring->queues)
 		goto out_err;
+	ring->max_nr_queues = nr_queues;
+
+	/* Legacy behavior by default, one queue per cpu */
+	ring->q_maps = fuse_uring_alloc_q_maps();
+	if (!ring->q_maps)
+		goto out_err;
+	for (qid = 0; qid < nr_queues; qid++)
+		cpumask_set_cpu(qid, ring->q_maps->global.registered_q_mask);
+	fuse_uring_build_q_maps(ring, ring->q_maps);
 
 	max_payload_size = max(FUSE_MIN_READ_BUFFER, fch->max_write);
 	max_payload_size = max(max_payload_size, fch->max_pages * PAGE_SIZE);
@@ -326,7 +440,6 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 
 	init_waitqueue_head(&ring->stop_waitq);
 
-	ring->max_nr_queues = nr_queues;
 	ring->chan = fch;
 	ring->max_payload_sz = max_payload_size;
 	smp_store_release(&fch->ring, ring);
@@ -335,6 +448,7 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 	return ring;
 
 out_err:
+	fuse_uring_free_q_maps(ring->q_maps);
 	kfree(ring->queues);
 	kfree(ring);
 	return NULL;
diff --git a/fs/fuse/dev_uring_i.h b/fs/fuse/dev_uring_i.h
index 10e3936814cc..268570e1477c 100644
--- a/fs/fuse/dev_uring_i.h
+++ b/fs/fuse/dev_uring_i.h
@@ -153,6 +153,20 @@ struct fuse_ring_queue {
 	bool zero_copy;
 };
 
+struct fuse_queue_map {
+	/* Tracks which queues are registered */
+	cpumask_var_t registered_q_mask;
+	size_t nr_queues;
+
+	/* cpu to qid mapping */
+	int *cpu_to_qid;
+};
+
+struct fuse_queue_maps {
+	struct fuse_queue_map global;
+	struct fuse_queue_map numa[];
+};
+
 /*
  * Describes if uring is for communication and holds alls the data needed
  * for uring communication
@@ -174,6 +188,9 @@ struct fuse_ring {
 	 */
 	unsigned int stop_debug_log : 1;
 
+	/* static CPU to queue mapping which queue a fuse request goes to */
+	struct fuse_queue_maps *q_maps;
+
 	wait_queue_head_t stop_waitq;
 
 	/* async tear down */

-- 
2.55.0

