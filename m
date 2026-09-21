From: Quanye Yang <quanyeyang@proton.me>
Date: Mon, 21 Sep 2026 07:04:47 -0700
Subject: [PATCH] RDMA/rtrs-clt: Fix recv repost to satisfy ib_drain_rq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-rtrs-fix-ib-drain-rq-v1-1-11b1637958ba@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBCF4auQWTNJ2wS0XsW4gM6o46LqDBCSh
 rtTZfkl7/0FjFXY4NIUUF7E5J0rfNtAeg75wShUDcGF3sXgUSc1vMuKMiLpIBn1i72ndO7I0am
 LUK8f5Tr5Z6+3wzaPL07TrwXbtgOecvaveAAAAA==
X-Change-ID: 20260921-rtrs-fix-ib-drain-rq-61dc85d0d759
To: "Md. Haris Iqbal" <haris.iqbal@ionos.com>, 
 Jack Wang <jinpu.wang@ionos.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Leon Romanovsky <leon@kernel.org>, 
 Danil Kipnis <danil.kipnis@cloud.ionos.com>
Cc: Jack Wang <jinpu.wang@cloud.ionos.com>, linux-rdma@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Farhad Alemi <farhad.alemi@berkeley.edu>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789999487; l=4263;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=jdc5f+VeX4vAQ0/q8YB5nswDUjlqTyT+yz3ZwEQCWWY=;
 b=+awDQrn+dez9ucZjiFAkkNLaPHDRTNQIeM5P7NDol8KqpSlUy1wmgTg9CugVwqJom/A2cBEA9
 aGVHk5ZyiFkArqRyHQcyNqHRjqw64nAXv8JeKgelmeP+Mbfrw/kzFa6
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On disconnect the client error recovery path calls ib_drain_qp(), which
requires one free RQ slot and that no recv WQEs are posted while the
queue is being drained.

The legacy recv completion path deferred reposting invalidate receives
and instead posted two empty recv WQEs when handling RDMA-with-IMM
responses marked with invalidation.  If an invalidate receive never
arrived, each such response increased RQ occupancy by one until
ib_post_recv() started returning -ENOMEM and __ib_drain_rq() failed with:

  failed to drain recv queue: -12

Repost one empty recv WQE for every receive completion, including legacy
SEND_WITH_INV invalidates, and only while the path is still connected
so CQ polling cannot race with ib_drain_qp().  Size IO connection RQs to
2 * queue_depth + 1 to match the posted recv count and leave the drain
slot.

Tested with a synthetic RTRS client flooding unpaired
RTRS_IO_RSP_W_INV_IMM messages; error recovery no longer triggers
__ib_drain_rq() warnings.

Fixes: 6a98d71daea1 ("RDMA/rtrs: client: main functionality")
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
Tested-by: Quanye Yang <quanyeyang@proton.me>
Reported-by: Farhad Alemi <farhad.alemi@berkeley.edu>
Link: https://lore.kernel.org/linux-rdma/CA+0ovCihE2_pxLimjmmR8NMz4g-ie8dvvq1jmAj-Om33y3Vzfg@mail.gmail.com
---
 drivers/infiniband/ulp/rtrs/rtrs-clt.c | 45 ++++++++++++----------------------
 1 file changed, 15 insertions(+), 30 deletions(-)

diff --git a/drivers/infiniband/ulp/rtrs/rtrs-clt.c b/drivers/infiniband/ulp/rtrs/rtrs-clt.c
index eac38b57b00d..ee6d5c3de16c 100644
--- a/drivers/infiniband/ulp/rtrs/rtrs-clt.c
+++ b/drivers/infiniband/ulp/rtrs/rtrs-clt.c
@@ -577,25 +577,21 @@ static struct ib_cqe io_comp_cqe = {
 	.done = rtrs_clt_rdma_done
 };
 
-/*
- * Post x2 empty WRs: first is for this RDMA with IMM,
- * second is for RECV with INV, which happened earlier.
- */
-static int rtrs_post_recv_empty_x2(struct rtrs_con *con, struct ib_cqe *cqe)
+static int rtrs_clt_repost_recv(struct rtrs_clt_con *con)
 {
-	struct ib_recv_wr wr_arr[2], *wr;
-	int i;
+	struct rtrs_clt_path *clt_path = to_clt_path(con->c.path);
+	int err;
 
-	memset(wr_arr, 0, sizeof(wr_arr));
-	for (i = 0; i < ARRAY_SIZE(wr_arr); i++) {
-		wr = &wr_arr[i];
-		wr->wr_cqe  = cqe;
-		if (i)
-			/* Chain backwards */
-			wr->next = &wr_arr[i - 1];
-	}
+	if (READ_ONCE(clt_path->state) != RTRS_CLT_CONNECTED)
+		return 0;
 
-	return ib_post_recv(con->qp, wr, NULL);
+	err = rtrs_post_recv_empty(&con->c, &io_comp_cqe);
+	if (err) {
+		rtrs_err(con->c.path, "rtrs_post_recv_empty(): %pe\n",
+			 ERR_PTR(err));
+		rtrs_rdma_error_recovery(con);
+	}
+	return err;
 }
 
 static void rtrs_clt_rdma_done(struct ib_cq *cq, struct ib_wc *wc)
@@ -650,19 +646,7 @@ static void rtrs_clt_rdma_done(struct ib_cq *cq, struct ib_wc *wc)
 			rtrs_wrn(con->c.path, "Unknown IMM type %u\n",
 				  imm_type);
 		}
-		if (w_inval)
-			/*
-			 * Post x2 empty WRs: first is for this RDMA with IMM,
-			 * second is for RECV with INV, which happened earlier.
-			 */
-			err = rtrs_post_recv_empty_x2(&con->c, &io_comp_cqe);
-		else
-			err = rtrs_post_recv_empty(&con->c, &io_comp_cqe);
-		if (err) {
-			rtrs_err(con->c.path, "rtrs_post_recv_empty(): %pe\n",
-				 ERR_PTR(err));
-			rtrs_rdma_error_recovery(con);
-		}
+		rtrs_clt_repost_recv(con);
 		break;
 	case IB_WC_RECV:
 		/*
@@ -678,6 +662,7 @@ static void rtrs_clt_rdma_done(struct ib_cq *cq, struct ib_wc *wc)
 
 			return  rtrs_clt_rkey_rsp_done(con, wc);
 		}
+		rtrs_clt_repost_recv(con);
 		break;
 	case IB_WC_RDMA_WRITE:
 		/*
@@ -1693,7 +1678,7 @@ static int create_con_cq_qp(struct rtrs_clt_con *con)
 		clt_path->s.dev_ref++;
 		/* QD * (REQ + RSP + FR REGS or INVS) + drain */
 		max_send_wr = min(wr_limit, clt_path->queue_depth * 4 + 1);
-		max_recv_wr = min(wr_limit, clt_path->queue_depth * 3 + 1);
+		max_recv_wr = min(wr_limit, clt_path->queue_depth * 2 + 1);
 		max_send_sge = 2;
 	}
 	atomic_set(&con->c.sq_wr_avail, max_send_wr);

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-rtrs-fix-ib-drain-rq-61dc85d0d759

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

