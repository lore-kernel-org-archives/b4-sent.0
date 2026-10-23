From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 23 Oct 2026 22:28:46 +0200
Subject: [PATCH v6 4/8] fuse: {io-uring} Select the queue through the CPU
 to queue maps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-reduced-nr-ring-queues_3-v6-4-658235c9b9bd@bsbernd.com>
References: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
In-Reply-To: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2398; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=0bSOn8HFfQToLCRbRk/6dBwfmGzXgifFo7XsyJ2NPnA=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJuH26sOyHzzfeE854VBaELhF/8O8Fau6L3wg3pr8U/Z
 z/fElcY31HKwiDGwSArpsjSJbHHdso/Plm1r+uvw8xhZQIZwsDFKQAT0U1hZHh1S5Mx7lmddib/
 35a1laciH2pzevcbLVxi3rn1bPJENi+G//GWc4zK2xmKp00P/N+0Ynb381OKv428bh2VP1jnVf/
 qIi8A
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

A CPU id at or above the number of queues wraps around now. Before, the
request went to queue 0 with a warning.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 25 ++++++++++++++++---------
 1 file changed, 16 insertions(+), 9 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index e24cca4c3df4..b683fefe5cf6 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -1888,17 +1888,24 @@ static void fuse_uring_send_in_task(struct io_tw_req tw_req, io_tw_token_t tw)
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
+	int node;
 
-	qid = task_cpu(current);
+	cpu = cpu % ring->max_nr_queues;
+	node = fuse_uring_cpu_to_node(cpu);
 
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
@@ -1923,7 +1930,7 @@ void fuse_uring_queue_fuse_req(struct fuse_iqueue *fiq, struct fuse_req *req)
 	int err;
 
 	err = -EINVAL;
-	queue = fuse_uring_task_to_queue(ring);
+	queue = fuse_uring_select_queue(ring);
 	if (!queue)
 		goto err;
 
@@ -1966,7 +1973,7 @@ bool fuse_uring_queue_bq_req(struct fuse_req *req)
 	struct fuse_ring_queue *queue;
 	struct fuse_ring_ent *ent = NULL;
 
-	queue = fuse_uring_task_to_queue(ring);
+	queue = fuse_uring_select_queue(ring);
 	if (!queue)
 		return false;
 

-- 
2.55.0

