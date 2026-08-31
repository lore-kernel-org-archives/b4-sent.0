From: Quanye Yang <quanyeyang@proton.me>
Date: Mon, 31 Aug 2026 20:30:58 +0800
Subject: [PATCH] RDMA/ucma: Serialize join and leave on copy_to_user
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-rdma-ucma-mc-uaf-v1-1-b8eeb7046aff@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC2ND3aKU3ETd0mQgkZusW5qYpmuZZJ5oYGGZZGmQaKwE1FZQlJqWWQE
 2MjoWwi8uTcpKTS4BmaNUWwsAh1Te03QAAAA=
X-Change-ID: 20260831-rdma-ucma-mc-uaf-9b7a089b90a3
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>, 
 Avihai Horon <avihaih@nvidia.com>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+a6ffe86390c8a6afc818@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Quanye Yang <quanyeyang@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788179458; l=2901;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=N3XkbQXD0jkOovzK5vafwV1Ou+3QGRVYe0LDvdcx34w=;
 b=IxVh3gAhyL0mBxvWCrkT21TIG7bhE4/cOXVYVi7bUaf+5wjESyYMnZDFcznT1819Fj+uxfp9U
 QB9yZwh8dm/CzZryGy83ptOgevddwWJSAupMaSBNI5RcNPTl2H4xYNp
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rdma_join_multicast() queues RoCE work that later reads the ucma_multicast
through event->param.ud.private_data, then list_add()s the CMA multicast
at the head of id_priv->mc_list. rdma_leave_multicast() matches only by
sockaddr and destroys the first hit.

ucma_process_join() used to drop ctx->mutex after a successful join and
retake it only if copy_to_user() failed. Two concurrent JOIN_MCAST calls
with the same address can therefore insert a second CMA entry before the
first thread's leave. leave then cancels the newer work and the older
worker still dereferences the ucma_multicast that the first thread frees.

Keep ctx->mutex held from rdma_join_multicast() through copy_to_user() and,
on -EFAULT, through rdma_leave_multicast() so leave cannot miss this join.
Do not leave if join itself failed: that path never published this address
on mc_list, and a leave-by-addr would destroy an earlier successful join.

Reported-by: syzbot+a6ffe86390c8a6afc818@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=a6ffe86390c8a6afc818
Fixes: fe454dc31e84 ("RDMA/ucma: Fix use-after-free bug in ucma_create_uevent")
Cc: stable@vger.kernel.org
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
KASAN + rxe, virtme-ng. The syzbot C repro (two concurrent JOIN_MCAST
with response=0) no longer reports slab-use-after-free in
ucma_create_uevent.

Based on linus/master
---
 drivers/infiniband/core/ucma.c | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/drivers/infiniband/core/ucma.c b/drivers/infiniband/core/ucma.c
index 4929636f7c53..c3611e2f3248 100644
--- a/drivers/infiniband/core/ucma.c
+++ b/drivers/infiniband/core/ucma.c
@@ -1556,27 +1556,27 @@ static ssize_t ucma_process_join(struct ucma_file *file,
 	mutex_lock(&ctx->mutex);
 	ret = rdma_join_multicast(ctx->cm_id, (struct sockaddr *)&mc->addr,
 				  join_state, mc);
-	mutex_unlock(&ctx->mutex);
-	if (ret)
+	if (ret) {
+		mutex_unlock(&ctx->mutex);
 		goto err_xa_erase;
+	}
 
 	resp.id = mc->id;
 	if (copy_to_user(u64_to_user_ptr(cmd->response),
 			 &resp, sizeof(resp))) {
 		ret = -EFAULT;
-		goto err_leave_multicast;
+		rdma_leave_multicast(ctx->cm_id, (struct sockaddr *)&mc->addr);
+		mutex_unlock(&ctx->mutex);
+		ucma_cleanup_mc_events(mc);
+		goto err_xa_erase;
 	}
+	mutex_unlock(&ctx->mutex);
 
 	xa_store(&multicast_table, mc->id, mc, 0);
 
 	ucma_put_ctx(ctx);
 	return 0;
 
-err_leave_multicast:
-	mutex_lock(&ctx->mutex);
-	rdma_leave_multicast(ctx->cm_id, (struct sockaddr *) &mc->addr);
-	mutex_unlock(&ctx->mutex);
-	ucma_cleanup_mc_events(mc);
 err_xa_erase:
 	xa_lock(&multicast_table);
 	list_del(&mc->list);

---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260831-rdma-ucma-mc-uaf-9b7a089b90a3

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

