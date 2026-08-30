From: Quanye Yang <quanyeyang@proton.me>
Date: Sun, 30 Aug 2026 15:09:55 +0800
Subject: [PATCH] RDMA/rtrs-clt: Fix CQ pool leak when connect is
 interrupted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-rdma-rtrs-clt-cq-pool-leak-v1-1-b169434fd3df@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMAwA0F8hPdtkA+KIv2I8jFG0Ohm005AQ/
 t2px3d5GygJk8Kp2kDozcppKrCHCsLNT1dCHoqhNvXRdI1BGZ4eJYtiiBnDgnNKESP5B7putL1
 xjprWQglmoZHXX36+/K2v/k4hf0fY9w/JgTQkfgAAAA==
X-Change-ID: 20260830-rdma-rtrs-clt-cq-pool-leak-78f1b077e341
To: "Md. Haris Iqbal" <haris.iqbal@ionos.com>, 
 Jack Wang <jinpu.wang@ionos.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Leon Romanovsky <leon@kernel.org>
Cc: Jack Wang <jinpu.wang@cloud.ionos.com>, linux-rdma@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+d396918a29afb8543e1c@syzkaller.appspotmail.com, 
 Quanye Yang <quanyeyang@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788073795; l=3778;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=cn9IkRUu0B89uWfK7vLWOhB21IgObrIMhVPL+RLvT4M=;
 b=aDuIS6UusZbS31KSqt2aMZnI1gtCGGold4AKeQ8ALgGzI9GcUH8Rxd2ul3d4COI5PPUaBxmHb
 6dVUDASJ/bWCiY+RaiE8sp1ALqEDqC8ASBTQjiJx0xgPfa8rdyhgCgx
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The client borrows shared CQ credits in the ADDR_RESOLVED handler via
ib_cq_pool_get(), before the peer is connected. create_cm() can return
-ERESTARTSYS from wait_event_interruptible_timeout() without destroying
the CM ID. The init_conns() and stop-and-destroy paths then call
destroy_con_cq_qp() while cq is still NULL (no PUT) and only afterwards
rdma_destroy_id().

CMA serializes the handler against rdma_destroy_id() with handler_mutex,
but that does not order the GET against destroy_con_cq_qp(). If
ADDR_RESOLVED has already passed the DESTROYING check, it can take
con_mutex, GET credits, and then lose the con to kfree. Device
unregister later hits WARN_ON(cq->cqe_used) in ib_cq_pool_cleanup().

Set a per-connection flag under con_mutex before CQ/QP teardown so a
racing ADDR_RESOLVED cannot borrow credits after teardown has begun.

Reported-by: syzbot+d396918a29afb8543e1c@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=d396918a29afb8543e1c
Fixes: 3b89e92c2a95 ("RDMA/rtrs: Use new shared CQ mechanism")
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
Fix a syzbot WARNING in ib_cq_pool_cleanup(): an ADDR_RESOLVED handler
can ib_cq_pool_get() after connection teardown has already skipped the
matching PUT.

Reproduced on rxe with rnbd-client only (no rtrs server): write
map_device with path=ip:127.0.0.1, interrupt create_cm() with a signal,
then rdma link delete. Device unregister no longer reports leftover
cqe_used after this change.
---
 drivers/infiniband/ulp/rtrs/rtrs-clt.c | 8 ++++++++
 drivers/infiniband/ulp/rtrs/rtrs-clt.h | 2 ++
 2 files changed, 10 insertions(+)

diff --git a/drivers/infiniband/ulp/rtrs/rtrs-clt.c b/drivers/infiniband/ulp/rtrs/rtrs-clt.c
index 7b2c51ae614f..eac38b57b00d 100644
--- a/drivers/infiniband/ulp/rtrs/rtrs-clt.c
+++ b/drivers/infiniband/ulp/rtrs/rtrs-clt.c
@@ -1732,6 +1732,8 @@ static void destroy_con_cq_qp(struct rtrs_clt_con *con)
 	/*
 	 * Be careful here: destroy_con_cq_qp() can be called even
 	 * create_con_cq_qp() failed, see comments there.
+	 * Caller must set con->destroyed under this lock first so a
+	 * racing ADDR_RESOLVED cannot ib_cq_pool_get() after we PUT/SKIP.
 	 */
 	lockdep_assert_held(&con->con_mutex);
 	rtrs_cq_qp_destroy(&con->c);
@@ -1766,6 +1768,10 @@ static int rtrs_rdma_addr_resolved(struct rtrs_clt_con *con)
 	int err;
 
 	mutex_lock(&con->con_mutex);
+	if (con->destroyed) {
+		mutex_unlock(&con->con_mutex);
+		return -ECONNABORTED;
+	}
 	err = create_con_cq_qp(con);
 	mutex_unlock(&con->con_mutex);
 	if (err) {
@@ -2221,6 +2227,7 @@ static void rtrs_clt_stop_and_destroy_conns(struct rtrs_clt_path *clt_path)
 			break;
 		con = to_clt_con(clt_path->s.con[cid]);
 		mutex_lock(&con->con_mutex);
+		con->destroyed = true;
 		destroy_con_cq_qp(con);
 		mutex_unlock(&con->con_mutex);
 		destroy_cm(con);
@@ -2387,6 +2394,7 @@ static int init_conns(struct rtrs_clt_path *clt_path)
 		if (con->c.cm_id) {
 			stop_cm(con);
 			mutex_lock(&con->con_mutex);
+			con->destroyed = true;
 			destroy_con_cq_qp(con);
 			mutex_unlock(&con->con_mutex);
 			destroy_cm(con);
diff --git a/drivers/infiniband/ulp/rtrs/rtrs-clt.h b/drivers/infiniband/ulp/rtrs/rtrs-clt.h
index 1305601a6251..ad64f4517c4b 100644
--- a/drivers/infiniband/ulp/rtrs/rtrs-clt.h
+++ b/drivers/infiniband/ulp/rtrs/rtrs-clt.h
@@ -75,6 +75,8 @@ struct rtrs_clt_con {
 	unsigned int		cpu;
 	struct mutex		con_mutex;
 	int			cm_err;
+	/* Set under con_mutex before CQ/QP teardown. */
+	bool			destroyed;
 };
 
 /**

---
base-commit: 08dbfad3f5040f5bdb6c529da20d6d4e81fefd72
change-id: 20260830-rdma-rtrs-clt-cq-pool-leak-78f1b077e341

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

