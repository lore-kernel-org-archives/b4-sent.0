From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 23 Oct 2026 22:28:49 +0200
Subject: [PATCH v6 7/8] fuse: Add retry attempts for numa local queues for
 load distribution
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-reduced-nr-ring-queues_3-v6-7-658235c9b9bd@bsbernd.com>
References: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
In-Reply-To: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2847; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=afKh8no6J8draXNBRGUiEHPXHePoWcIqpU8eOSHSuPY=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJuH24WunBoXabR9N33Mg1OL/q9z6r91zWrKKXP1iqBZ
 zheLM9S6ShlYRDjYJAVU2TpkthjO+Ufn6za1/XXYeawMoEMYeDiFICJ1KsyMlwwjWj9s0/uZcOD
 trkHEj4KB5bWKqlVOsVZ7Xh3/Ui6liAjw+z1J5ff3GAkcODy1JxrpxaemVG1+vt3t+tNEdtikj7
 EXmUEAA==
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
 fs/fuse/dev_uring.c | 42 +++++++++++++++++++++++++++++++++++-------
 1 file changed, 35 insertions(+), 7 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 87c8ea35d2c9..c4c0230d02fc 100644
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
@@ -1960,10 +1965,10 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 {
 	struct fuse_queue_maps *maps;
 	struct fuse_queue_map *q_map;
-	struct fuse_ring_queue *queue = NULL;
+	struct fuse_ring_queue *queue = NULL, *primary_queue = NULL;
 	unsigned int cpu = task_cpu(current);
 	unsigned int qid;
-	int node;
+	int node, retries = 0;
 
 	cpu = cpu % ring->max_nr_queues;
 	node = fuse_uring_cpu_to_node(cpu);
@@ -1974,11 +1979,34 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
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

