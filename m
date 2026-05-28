From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 29 May 2026 00:55:10 +0200
Subject: [PATCH v5 6/7] fuse: {io-uring} Add retry attempts for numa local
 queues for load distribution
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-reduced-nr-ring-queues_3-v5-6-1dc08c2fccf6@bsbernd.com>
References: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
In-Reply-To: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, Luis Henriques <luis@igalia.com>, 
 Gang He <dchg2000@gmail.com>, fuse-devel@lists.linux.dev, 
 Bernd Schubert <bschubert@ddn.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780008905; l=2695;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=/JoNay03ra6U1JLIygA2pq3cl7kfAQ5Hf2U4zr91+WM=;
 b=EzBKzAKFwKs/ZnEONPUIehZkwsvic94RA1MhUM/cAAty2i9IGAIWgoPJnfx+laQrgjDCyNhUX
 w7859xBXV4WDmqsxOkedc8+v9fHeW5QuEmOhm0lE07jUemFARf1dG+5
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
 fs/fuse/dev_uring.c | 33 +++++++++++++++++++++++++++++++--
 1 file changed, 31 insertions(+), 2 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index a79007c36e6be33f662bd5bcb80949a814d426c8..b68b2153dd11fd06962c06aa227a5144f4210aa0 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -19,6 +19,10 @@ MODULE_PARM_DESC(enable_uring,
 
 #define FUSE_URING_IOV_SEGS 2 /* header and payload */
 
+/* Number of requests in the queue until another queue is checked */
+#define FUSE_URING_Q_THRESHOLD 2
+
+#define FUSE_URING_Q_RETRIES 2 /* number of retries for a better queue */
 
 bool fuse_uring_enabled(void)
 {
@@ -1312,9 +1316,10 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 						       bool background)
 {
 	unsigned int qid;
-	int node;
+	int node, retries = 0;
 	unsigned int nr_queues;
 	unsigned int cpu = task_cpu(current);
+	struct fuse_ring_queue *queue, *primary_queue = NULL;
 
 	cpu = cpu % ring->max_nr_queues;
 
@@ -1344,11 +1349,35 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 		if (qid == cpu && background)
 			qid = cpumask_next_wrap(qid, mask);
 
+retry:
 		if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
 			return NULL;
-		return READ_ONCE(ring->queues[qid]);
+		queue = READ_ONCE(ring->queues[qid]);
+
+		/* Might happen on teardown */
+		if (unlikely(!queue))
+			return NULL;
+
+		/* Not atomic and with lock, approximate is enough */
+		if (READ_ONCE(queue->nr_reqs) < FUSE_URING_Q_THRESHOLD)
+			return queue;
+
+		/* Retries help for load balancing */
+		if (retries < FUSE_URING_Q_RETRIES) {
+			if (!retries)
+				primary_queue = queue;
+
+			/* Increase cpu, assuming it will map to a differet qid*/
+			qid = cpumask_next_wrap(qid, mask);
+			retries++;
+			goto retry;
+		}
 	}
 
+	/* Retries exceeded, take the primary target queue */
+	if (primary_queue)
+		return primary_queue;
+
 	/* global registered queue bitmap */
 	if (!smp_load_acquire(&ring->q_map.nr_queues))
 		return NULL;

-- 
2.43.0

