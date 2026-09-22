From: Quanye Yang <quanyeyang@proton.me>
Date: Mon, 21 Sep 2026 21:25:25 -0700
Subject: [PATCH] RDMA/rtrs-clt: Don't WARN on unexpected info-response
 opcode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-rtrs-fix-rtrs-clt-info-rsp-done-v1-1-c64281ed97c0@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWN0QrCMAxFf2Xk2cBW64b+iuxB03SLSDuSKsLYv
 1vd2z1wOWcFYxU2uDQrKL/FJKcK3aEBmm9pYpRQGVzr+vbsOtSihlE++6BnQUkxo9qCISfGI5+
 CHygG8h6qZVGu73/hOu5sr/uDqfy0sG1f8/XGQIMAAAA=
X-Change-ID: 20260921-rtrs-fix-rtrs-clt-info-rsp-done-3e5d47cfdc44
To: "Md. Haris Iqbal" <haris.iqbal@ionos.com>, 
 Jack Wang <jinpu.wang@ionos.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Leon Romanovsky <leon@kernel.org>, 
 Danil Kipnis <danil.kipnis@cloud.ionos.com>
Cc: Jack Wang <jinpu.wang@cloud.ionos.com>, linux-rdma@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Farhad Alemi <farhad.alemi@berkeley.edu>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790051127; l=1693;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=1KtQGLrqV0R0BQYhjKlwQ9iV1kF2blHHJCa4XJfhFPc=;
 b=ztk4kocaZeI6fjK/rweVJJ/ecZOd3V+zNTHRFeettpbcrCQOCnLC3kdBa6EOTVP1Y7vILPb13
 wLIczuZIP+JAxqzdXPZwYSpMY8GAzeR5Ty+WljWvBnhFKJYgqcBHGHy
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The info-response receive is posted for a SEND.  The completion
opcode comes from the peer, so RDMA WRITE with Immediate is a
legal WC on that WQE even though it violates the RTRS handshake.

WARN_ON(wc->opcode != IB_WC_RECV) treats that peer-controlled
field as an internal invariant and panics with panic_on_warn.
Treat a non-SEND completion as a handshake failure: log it and
keep the existing CONNECTING_ERR cleanup.

Fixes: 6a98d71daea1 ("RDMA/rtrs: client: main functionality")
Reported-by: Farhad Alemi <farhad.alemi@berkeley.edu>
Link: https://lore.kernel.org/linux-rdma/CA+0ovCge-K+hcGHXZ4R3Ww5+cg159uxHBeVbKeUSLBRSMT8OWA@mail.gmail.com
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 drivers/infiniband/ulp/rtrs/rtrs-clt.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/infiniband/ulp/rtrs/rtrs-clt.c b/drivers/infiniband/ulp/rtrs/rtrs-clt.c
index eac38b57b00d..3c23c27725a5 100644
--- a/drivers/infiniband/ulp/rtrs/rtrs-clt.c
+++ b/drivers/infiniband/ulp/rtrs/rtrs-clt.c
@@ -2514,7 +2514,12 @@ static void rtrs_clt_info_rsp_done(struct ib_cq *cq, struct ib_wc *wc)
 			  ib_wc_status_msg(wc->status));
 		goto out;
 	}
-	WARN_ON(wc->opcode != IB_WC_RECV);
+	if (wc->opcode != IB_WC_RECV) {
+		rtrs_err(clt_path->clt,
+			 "Path info response has unexpected opcode %d\n",
+			 wc->opcode);
+		goto out;
+	}
 
 	if (wc->byte_len < sizeof(*msg)) {
 		rtrs_err(clt_path->clt, "Path info response is malformed: size %d\n",

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-rtrs-fix-rtrs-clt-info-rsp-done-3e5d47cfdc44

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

