From: Bernd Schubert <bernd@bsbernd.com>
Date: Sun, 25 Oct 2026 23:29:12 +0100
Subject: [PATCH v8 4/8] fuse: {io-uring} Select the queue through the CPU
 to queue maps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-reduced-nr-ring-queues_3-v8-4-8a2570e8d2a4@bsbernd.com>
References: <20261025-reduced-nr-ring-queues_3-v8-0-8a2570e8d2a4@bsbernd.com>
In-Reply-To: <20261025-reduced-nr-ring-queues_3-v8-0-8a2570e8d2a4@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2237; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=4GfEBMk8qXIbomD/0fLssBxsa+zlIp/Mrzffd0M4Cmo=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLLuNe2X4fU5wtf5Rd3A4rjoji9ngst2cPD/t2cV1ZUVf
 xSgEbe4o5SFQYyDQVZMkaVLYo/tlH98smpf11+HmcPKBDKEgYtTACaSFMLwP9o3qd36n5jxG9FY
 o81svjlVdjJeFW8V0g3S8+U5YjZMZmSYm2e6c52AtVbYh7v2GVq3a6IvnDiwzD1mxQWum7dXcnf
 wAgA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a preparation for a follow up commit that lets a server register
fewer queues than CPUs. The queue of a request then cannot be the queue
of the CPU that issued the request.

fuse_uring_select_queue() picks the queue through the NUMA node map of
the issuing CPU, or through the global map when that node has no queue.
No change in behaviour, every CPU still maps to its own queue.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 24 ++++++++++++++----------
 1 file changed, 14 insertions(+), 10 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 32c8e2db26b7..d243e124cb4c 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -1892,17 +1892,21 @@ static void fuse_uring_send_in_task(struct io_tw_req tw_req, io_tw_token_t tw)
 	}
 }
 
-static struct fuse_ring_queue *fuse_uring_task_to_queue(struct fuse_ring *ring)
+static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring)
 {
-	unsigned int qid;
+	struct fuse_queue_maps *maps = ring->q_maps;
+	struct fuse_queue_map *q_map;
 	struct fuse_ring_queue *queue;
+	unsigned int cpu = task_cpu(current);
+	unsigned int qid;
+	int node = fuse_uring_cpu_to_node(cpu);
 
-	qid = task_cpu(current);
-
-	if (WARN_ONCE(qid >= ring->max_nr_queues,
-		      "Core number (%u) exceeds nr queues (%zu)\n", qid,
-		      ring->max_nr_queues))
-		qid = 0;
+	q_map = &maps->numa[node];
+	if (!q_map->nr_queues)
+		q_map = &maps->global;
+	qid = q_map->cpu_to_qid[cpu];
+	if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
+		return NULL;
 
 	queue = READ_ONCE(ring->queues[qid]);
 	WARN_ONCE(!queue, "Missing queue for qid %d\n", qid);
@@ -1927,7 +1931,7 @@ void fuse_uring_queue_fuse_req(struct fuse_iqueue *fiq, struct fuse_req *req)
 	int err;
 
 	err = -EINVAL;
-	queue = fuse_uring_task_to_queue(ring);
+	queue = fuse_uring_select_queue(ring);
 	if (!queue)
 		goto err;
 
@@ -1970,7 +1974,7 @@ bool fuse_uring_queue_bq_req(struct fuse_req *req)
 	struct fuse_ring_queue *queue;
 	struct fuse_ring_ent *ent = NULL;
 
-	queue = fuse_uring_task_to_queue(ring);
+	queue = fuse_uring_select_queue(ring);
 	if (!queue)
 		return false;
 

-- 
2.55.0

