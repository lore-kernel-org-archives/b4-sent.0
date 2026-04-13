From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 13 Apr 2026 11:41:31 +0200
Subject: [PATCH v4 8/8] fuse: {io-uring} Prefer the current core over
 mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260413-reduced-nr-ring-queues_3-v4-8-982b6414b723@bsbernd.com>
References: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
In-Reply-To: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, linux-fsdevel@vger.kernel.org, 
 Luis Henriques <luis@igalia.com>, Gang He <dchg2000@gmail.com>, 
 Bernd Schubert <bschubert@ddn.com>, Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776073284; l=3547;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=VTAyHIcmMVaS2enGiELEFeYVNj8yRgmYjZrm6d617lo=;
 b=E9eR8PKfaoL98m8/LZFSwddFHVy5+J4c4fJxh1u9xBQd93xCfiInkTFlgmpcklPTdbTNSY1hi
 AOvxpcz51ktDoMKjVmy2i2igQHl5JBi4iO1+DOt5dQitCzBF32GNhrM
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bernd Schubert <bschubert@ddn.com>

Mapping might point to a totally different core due to
random assignment. For performance using the current
core might be beneficial

Example (with core binding)

unpatched WRITE: bw=841MiB/s
patched   WRITE: bw=1363MiB/s

With
fio --name=test --ioengine=psync --direct=1 \
    --rw=write --bs=1M --iodepth=1 --numjobs=1 \
    --filename_format=/redfs/testfile.\$jobnum --size=100G \
    --thread --create_on_open=1 --runtime=30s --cpus_allowed=1

In order to get the good number `--cpus_allowed=1` is needed.
This could be improved by a future change that avoids
cpu migration in fuse_request_end() on wake_up() call.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 41 ++++++++++++++++++++++++++++-------------
 1 file changed, 28 insertions(+), 13 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index e06d45b161d5000e24431314b2222b66bdea58aa..5c00fd047c8bd359ec34fb6a41abba44f6794517 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -19,8 +19,12 @@ MODULE_PARM_DESC(enable_uring,
 
 #define FUSE_URING_IOV_SEGS 2 /* header and payload */
 
+/* Threshold that determines if a better queue should be searched for */
 #define FUSE_URING_Q_THRESHOLD 2
 
+/* Number of (re)tries to find a better queue */
+#define FUSE_URING_Q_TRIES 3
+
 bool fuse_uring_enabled(void)
 {
 	return enable_uring;
@@ -1311,7 +1315,7 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 						       bool background)
 {
 	unsigned int qid;
-	int node, retries = 0;
+	int node, tries = 0;
 	unsigned int nr_queues;
 	unsigned int cpu = task_cpu(current);
 	struct fuse_ring_queue *queue, *primary_queue = NULL;
@@ -1336,26 +1340,36 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 
 	nr_queues = READ_ONCE(ring->numa_q_map[node].nr_queues);
 	if (nr_queues) {
+		/* prefer the queue that corresponds to the current cpu */
+		queue = READ_ONCE(ring->queues[cpu]);
+		if (queue) {
+			if (queue->nr_reqs <= FUSE_URING_Q_THRESHOLD)
+				return queue;
+			primary_queue = queue;
+		}
+
 		qid = ring->numa_q_map[node].cpu_to_qid[cpu];
 		if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
 			return NULL;
-		queue = READ_ONCE(ring->queues[qid]);
+		if (qid != cpu) {
+			queue = READ_ONCE(ring->queues[qid]);
 
-		/* Might happen on teardown */
-		if (unlikely(!queue))
-			return NULL;
+			/* Might happen on teardown */
+			if (unlikely(!queue))
+				return NULL;
 
-		if (queue->nr_reqs < FUSE_URING_Q_THRESHOLD)
-			return queue;
+			if (queue->nr_reqs <= FUSE_URING_Q_THRESHOLD)
+				return queue;
+		}
 
 		/* Retries help for load balancing */
-		if (retries < FUSE_URING_Q_THRESHOLD) {
-			if (!retries)
+		if (tries < FUSE_URING_Q_TRIES && tries + 1 < nr_queues) {
+			if (!primary_queue)
 				primary_queue = queue;
 
-			/* Increase cpu, assuming it will map to a differet qid*/
+			/* Increase cpu, assuming it will map to a different qid*/
 			cpu++;
-			retries++;
+			tries++;
 			goto retry;
 		}
 	}
@@ -1366,9 +1380,10 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
 
 	/* global registered queue bitmap */
 	qid = ring->q_map.cpu_to_qid[cpu];
-	if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
-	/* Might happen on teardown */
+	if (WARN_ON_ONCE(qid >= ring->max_nr_queues)) {
+		/* Might happen on teardown */
 		return NULL;
+	}
 	return READ_ONCE(ring->queues[qid]);
 }
 

-- 
2.43.0

