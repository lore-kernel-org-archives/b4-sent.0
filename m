From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 18 May 2026 18:37:31 +0200
Subject: [PATCH 3/4] fuse: {io-uring} Make a fuse_req on SQE commit only
 findable after memcpy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-fuse-io-uring-race-fixes-v1-3-36c9eba8ab18@bsbernd.com>
References: <20260518-fuse-io-uring-race-fixes-v1-0-36c9eba8ab18@bsbernd.com>
In-Reply-To: <20260518-fuse-io-uring-race-fixes-v1-0-36c9eba8ab18@bsbernd.com>
To: security@kernel.org, Pavel Begunkov <asml.silence@gmail.com>, 
 Luis Henriques <luis@igalia.com>, Joanne Koong <joannelkoong@gmail.com>
Cc: Miklos Szeredi <mszeredi@redhat.com>, Berkant Koc <me@berkoc.com>, 
 Zhenghang Xiao <kipreyyy@gmail.com>, Bernd Schubert <bernd@bsbernd.com>, 
 xlabai <xlabai@tencent.com>, stable@kernel.org
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=3435; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=7bYAAUwzHzSgAnS/R9hI6VaXZg0XWJ6yjPYXi9iI7F0=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK4HfwrX5t8O3d+orbElHleHTfDOP/c6ah6vuVXd8+xc
 nHjkuSVHaUsDGIcDLJiiixdEntsp/zjk1X7uv46zBxWJpAhDFycAjCRNk5Ghmue6XXrvlo1Biz6
 t9chQKJwx96v+x4Vl76U67KWnLZU8C7DP61JfpO+s55wcDHIr1rZdmZ1w/Lqjj1br+ZOT94j2Os
 wkx8A
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bad userspace might try to trick us and send commit SQEs request
unique / commit-id of requests that are not even send to
fuse-server (io_uring_cmd_done() not called) yet.

fuse_uring_commit_fetch() ends the fuse request when the ring entry
has a wrong state, but that could have caused a use-after-free
with the memcpy operations in fuse_uring_send_in_task().
In order to avoid such races the call of fuse_uring_add_to_pq()
is moved after the copy operations and just before completing
the io-uring request - malicious userspace cannot find the request
anymore until all prepration work in fuse-client/kernel is completed.

This also moves fuse_uring_add_to_pq() a bit up in the code to
avoid a forward declaration. Also not with a preparation commit,
to make it easier to back port to older kernels.

Reported-by: xlabai <xlabai@tencent.com>
Reported-by: Berkant Koc <me@berkoc.com>
Fixes: c090c8abae4b6b ("fuse: Add io-uring sqe commit and fetch support")
Cc: stable@kernel.org # 6.14
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 29 +++++++++++++++--------------
 1 file changed, 15 insertions(+), 14 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index c24a0b5b5357..ebbfec9a0014 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -714,6 +714,19 @@ static int fuse_uring_prepare_send(struct fuse_ring_ent *ent,
 	return err;
 }
 
+/* Used to find the request on SQE commit */
+static void fuse_uring_add_to_pq(struct fuse_ring_ent *ent)
+{
+	struct fuse_ring_queue *queue = ent->queue;
+	struct fuse_pqueue *fpq = &queue->fpq;
+	unsigned int hash;
+	struct fuse_req *req = ent->fuse_req;
+
+	req->ring_entry = ent;
+	hash = fuse_req_hash(req->in.h.unique);
+	list_move_tail(&req->list, &fpq->processing[hash]);
+}
+
 /*
  * Write data to the ring buffer and send the request to userspace,
  * userspace will read it
@@ -736,6 +749,7 @@ static int fuse_uring_send_next_to_ring(struct fuse_ring_ent *ent,
 	ent->cmd = NULL;
 	ent->state = FRRS_USERSPACE;
 	list_move_tail(&ent->list, &queue->ent_in_userspace);
+	fuse_uring_add_to_pq(ent);
 	spin_unlock(&queue->lock);
 
 	io_uring_cmd_done(cmd, 0, issue_flags);
@@ -753,19 +767,6 @@ static void fuse_uring_ent_avail(struct fuse_ring_ent *ent,
 	ent->state = FRRS_AVAILABLE;
 }
 
-/* Used to find the request on SQE commit */
-static void fuse_uring_add_to_pq(struct fuse_ring_ent *ent,
-				 struct fuse_req *req)
-{
-	struct fuse_ring_queue *queue = ent->queue;
-	struct fuse_pqueue *fpq = &queue->fpq;
-	unsigned int hash;
-
-	req->ring_entry = ent;
-	hash = fuse_req_hash(req->in.h.unique);
-	list_move_tail(&req->list, &fpq->processing[hash]);
-}
-
 /*
  * Assign a fuse queue entry to the given entry
  */
@@ -786,7 +787,6 @@ static void fuse_uring_add_req_to_ring_ent(struct fuse_ring_ent *ent,
 	ent->fuse_req = req;
 	ent->state = FRRS_FUSE_REQ;
 	list_move_tail(&ent->list, &queue->ent_w_req_queue);
-	fuse_uring_add_to_pq(ent, req);
 }
 
 /* Fetch the next fuse request if available */
@@ -1209,6 +1209,7 @@ static void fuse_uring_send(struct fuse_ring_ent *ent, struct io_uring_cmd *cmd,
 	ent->state = FRRS_USERSPACE;
 	list_move_tail(&ent->list, &queue->ent_in_userspace);
 	ent->cmd = NULL;
+	fuse_uring_add_to_pq(ent);
 	spin_unlock(&queue->lock);
 
 	io_uring_cmd_done(cmd, ret, issue_flags);

-- 
2.53.0

