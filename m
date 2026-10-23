From: Bernd Schubert <bernd@bsbernd.com>
Date: Sat, 24 Oct 2026 00:50:36 +0200
Subject: [PATCH v7 7/8] fuse: Add retry attempts for numa local queues for
 load distribution
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-reduced-nr-ring-queues_3-v7-7-4e77e284fd48@bsbernd.com>
References: <20261024-reduced-nr-ring-queues_3-v7-0-4e77e284fd48@bsbernd.com>
In-Reply-To: <20261024-reduced-nr-ring-queues_3-v7-0-4e77e284fd48@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2856; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=adBEJ1BmwJtbJvMferBwXqU975gjTI5Gx8GJUfvKlOo=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJuP9mb5yQZ1aehoZw2uzRg0pVd2xlXPbI6ybrI+52ni
 KngJtGXHaUsDGIcDLJiiixdEntsp/zjk1X7uv46zBxWJpAhDFycAjCRDacYGW4YfGFg45fRPv7n
 gH9/ab3zqe46M5Hu4oQLs1LDrd5bvmb4K+Jcqyj89gC3Wtt8qd/1+Ru3Hd3bLj71QUTRc5kFLkV
 XmQE=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is to further improve performance.

fio --directory=/tmp/dest --name=iops.\$jobnum --rw=randread \
--bs=4k --size=1G --numjobs=1 --iodepth=4 --time_based\
--runtime=30s --group_reporting --ioengine=io_uring\
--direct=1

unpatched
   READ: bw=650MiB/s (682MB/s)
patched:
   READ: bw=995MiB/s (1043MB/s)

with --iodepth=8

unpatched
   READ: bw=641MiB/s (672MB/s)
patched
   READ: bw=966MiB/s (1012MB/s)

Reason is that with --iodepth=x (x > 1) fio submits multiple async
requests and a single queue might become CPU limited. I.e. spreading
the load helps.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 41 +++++++++++++++++++++++++++++++++++------
 1 file changed, 35 insertions(+), 6 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index f22a1b5fc7fb..ca82965fdee1 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -24,6 +24,11 @@ MODULE_PARM_DESC(enable_uring,
 
 #define FUSE_URING_ADD_QUEUE_FLAGS	(FUSE_URING_ZERO_COPY)
 
+/* Number of requests in the queue until another queue is checked */
+#define FUSE_URING_Q_THRESHOLD 2
+
+#define FUSE_URING_Q_RETRIES 2 /* number of retries for a better queue */
+
 bool fuse_uring_enabled(void)
 {
 	return enable_uring;
@@ -1964,10 +1969,11 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 {
 	struct fuse_queue_maps *maps;
 	struct fuse_queue_map *q_map;
-	struct fuse_ring_queue *queue = NULL;
+	struct fuse_ring_queue *queue = NULL, *primary_queue = NULL;
 	unsigned int cpu = task_cpu(current);
 	unsigned int qid;
 	int node = fuse_uring_cpu_to_node(cpu);
+	int retries = 0;
 
 	rcu_read_lock();
 	maps = rcu_dereference(ring->q_maps);
@@ -1975,11 +1981,34 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 		goto out;
 
 	q_map = &maps->numa[node];
-	if (!q_map->nr_queues)
-		q_map = &maps->global;
-	qid = q_map->cpu_to_qid[cpu];
-	if (qid == cpu && background)
-		qid = cpumask_next_wrap(qid, q_map->registered_q_mask);
+	if (q_map->nr_queues) {
+		qid = q_map->cpu_to_qid[cpu];
+		if (qid == cpu && background)
+			qid = cpumask_next_wrap(qid, q_map->registered_q_mask);
+retry:
+		if (WARN_ON_ONCE(qid >= ring->max_nr_queues)) {
+			queue = NULL;
+			goto out;
+		}
+		queue = READ_ONCE(ring->queues[qid]);
+		if (unlikely(!queue))
+			goto out;
+
+		if (READ_ONCE(queue->nr_reqs) < FUSE_URING_Q_THRESHOLD)
+			goto out;
+
+		if (retries < FUSE_URING_Q_RETRIES) {
+			if (!retries)
+				primary_queue = queue;
+			qid = cpumask_next_wrap(qid, q_map->registered_q_mask);
+			retries++;
+			goto retry;
+		}
+		queue = primary_queue;
+		goto out;
+	}
+
+	qid = maps->global.cpu_to_qid[cpu];
 	if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
 		goto out;
 

-- 
2.55.0

