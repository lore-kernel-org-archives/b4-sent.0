From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 05 Jun 2026 13:33:43 +0200
Subject: [PATCH v3 3/4] fuse: {io-uring} Make a fuse_req on SQE commit only
 findable after memcpy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-fuse-io-uring-race-fixes-v3-3-f1c22904af10@bsbernd.com>
References: <20260605-fuse-io-uring-race-fixes-v3-0-f1c22904af10@bsbernd.com>
In-Reply-To: <20260605-fuse-io-uring-race-fixes-v3-0-f1c22904af10@bsbernd.com>
To: Pavel Begunkov <asml.silence@gmail.com>, 
 Luis Henriques <luis@igalia.com>, Joanne Koong <joannelkoong@gmail.com>
Cc: Miklos Szeredi <mszeredi@redhat.com>, Berkant Koc <me@berkoc.com>, 
 Zhenghang Xiao <kipreyyy@gmail.com>, Bernd Schubert <bernd@bsbernd.com>, 
 xlabai <xlabai@tencent.com>, stable@kernel.org
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=3598; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=0J2ELZj79o2Eiq/7V7sCD7bhhOLiecCA9UCTX0goXjU=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLKUtkjMO2Okdtn6WFzIlb/qN034G/TSDEpzPx6RfqgSz
 eOeMf94RykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAEwkt5+RoenmLAG1Pb3PGeQ3
 HpZlPu1yV0LqtNe1xqIfwu8id/3KjGb4pydud/604/3J+hs23WKyWBOXIM/5ySLRWOzyogkmjW9
 mMAMA
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
 fs/fuse/dev_uring.c | 33 +++++++++++++++++++--------------
 1 file changed, 19 insertions(+), 14 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index c24a0b5b5357..5dde86e8653b 100644
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
@@ -783,10 +784,13 @@ static void fuse_uring_add_req_to_ring_ent(struct fuse_ring_ent *ent,
 	}
 
 	clear_bit(FR_PENDING, &req->flags);
+
+	/* Until fuse_uring_add_to_pq() the req is not attached to any list */
+	list_del_init(&req->list);
+
 	ent->fuse_req = req;
 	ent->state = FRRS_FUSE_REQ;
 	list_move_tail(&ent->list, &queue->ent_w_req_queue);
-	fuse_uring_add_to_pq(ent, req);
 }
 
 /* Fetch the next fuse request if available */
@@ -1209,6 +1213,7 @@ static void fuse_uring_send(struct fuse_ring_ent *ent, struct io_uring_cmd *cmd,
 	ent->state = FRRS_USERSPACE;
 	list_move_tail(&ent->list, &queue->ent_in_userspace);
 	ent->cmd = NULL;
+	fuse_uring_add_to_pq(ent);
 	spin_unlock(&queue->lock);
 
 	io_uring_cmd_done(cmd, ret, issue_flags);

-- 
2.53.0

