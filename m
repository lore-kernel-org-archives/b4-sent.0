From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 13 Apr 2026 11:41:30 +0200
Subject: [PATCH v4 7/8] fuse: Add retry attempts for numa local queues for
 load distribution
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260413-reduced-nr-ring-queues_3-v4-7-982b6414b723@bsbernd.com>
References: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
In-Reply-To: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, linux-fsdevel@vger.kernel.org, 
 Luis Henriques <luis@igalia.com>, Gang He <dchg2000@gmail.com>, 
 Bernd Schubert <bschubert@ddn.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776073284; l=2788;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=qpG0ubP0wjO/E0aaRE8uP8XLGn7GvVV5imcxnF0GZf8=;
 b=HG4a8nd3nc9k6Ws7jB8PgxdJzrBH/zLkqHpkhj+0CKvzjSpabk+BkydQmN+qCfcq3Izb7kDLd
 AVqnVItcpXkB9q2U2wLs99PIz/9u4kX0YH2kNco/1DVjWV45jEqB1Rd
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bernd Schubert <bschubert@ddn.com>

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
---
 fs/fuse/dev_uring.c | 30 ++++++++++++++++++++++++++++--
 1 file changed, 28 insertions(+), 2 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index ed061e239b8ed70ff36deb51dd6957fe1704ec87..e06d45b161d5000e24431314b2222b66bdea58aa 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -19,6 +19,7 @@ MODULE_PARM_DESC(enable_uring,
 
 #define FUSE_URING_IOV_SEGS 2 /* header and payload */
 
+#define FUSE_URING_Q_THRESHOLD 2
 
 bool fuse_uring_enabled(void)
 {
@@ -1310,9 +1311,10 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 						       bool background)
 {
 	unsigned int qid;
-	int node;
+	int node, retries = 0;
 	unsigned int nr_queues;
 	unsigned int cpu = task_cpu(current);
+	struct fuse_ring_queue *queue, *primary_queue = NULL;
 
 	/*
 	 *  Background requests result in better performance on a different
@@ -1321,6 +1323,7 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 	if (background)
 		cpu++;
 
+retry:
 	cpu = cpu % ring->max_nr_queues;
 
 	/* numa local registered queue bitmap */
@@ -1336,12 +1339,35 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 		qid = ring->numa_q_map[node].cpu_to_qid[cpu];
 		if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
 			return NULL;
-		return READ_ONCE(ring->queues[qid]);
+		queue = READ_ONCE(ring->queues[qid]);
+
+		/* Might happen on teardown */
+		if (unlikely(!queue))
+			return NULL;
+
+		if (queue->nr_reqs < FUSE_URING_Q_THRESHOLD)
+			return queue;
+
+		/* Retries help for load balancing */
+		if (retries < FUSE_URING_Q_THRESHOLD) {
+			if (!retries)
+				primary_queue = queue;
+
+			/* Increase cpu, assuming it will map to a differet qid*/
+			cpu++;
+			retries++;
+			goto retry;
+		}
 	}
 
+	/* Retries exceeded, take the primary target queue */
+	if (primary_queue)
+		return primary_queue;
+
 	/* global registered queue bitmap */
 	qid = ring->q_map.cpu_to_qid[cpu];
 	if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
+	/* Might happen on teardown */
 		return NULL;
 	return READ_ONCE(ring->queues[qid]);
 }

-- 
2.43.0

