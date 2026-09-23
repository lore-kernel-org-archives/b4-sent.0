From: Quanye Yang <quanyeyang@proton.me>
Date: Tue, 22 Sep 2026 21:09:58 -0700
Subject: [PATCH] RDMA/rtrs-clt: Reject invalid queue_depth from the peer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260922-rtrs-fix-warning-rtrs-clt-rdma-cm-handler-v1-1-2076c0ee1455@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWN3Q6CMAxGX4X02iajKlFfxXAxtoo1ME07fxLCu
 zPk8nzJ+c4ExipscKkmUP6IyTMVqHcVhLtPPaPEwkCOGncmQs1qeJMffr0mSf02hCGjxtFjGLF
 ocWBFqhvHvD+eugND+XspF+/furYb27t7cMhrAOZ5AQ4XHHCNAAAA
X-Change-ID: 20260922-rtrs-fix-warning-rtrs-clt-rdma-cm-handler-2160ee358b4e
To: "Md. Haris Iqbal" <haris.iqbal@ionos.com>, 
 Jack Wang <jinpu.wang@ionos.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Leon Romanovsky <leon@kernel.org>, 
 Danil Kipnis <danil.kipnis@cloud.ionos.com>
Cc: Jack Wang <jinpu.wang@cloud.ionos.com>, linux-rdma@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Farhad Alemi <farhad.alemi@berkeley.edu>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790136599; l=1555;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=D5EbnVMniwVpv/h4+71Ucz1i6HnqTkhM/rK1ZxWuGb0=;
 b=9effqmgmW2GTIc9ttanljElvpmgL2uBAofiD0G+t96vNEPW/HX/9oacwNvbMiBQH//GA8macQ
 A03allaNXfNDivP+J5/D9RpRBmW/d+cg6x6QAHE/rTENoNYKNQfQuzb
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

queue_depth is taken from the server's CM private_data and later
used as a session invariant.  A peer can send 0, which the client
stores and then trips WARN_ON() in create_con_cq_qp() when the
next connection is set up.

Reject a zero queue_depth on ESTABLISHED, same as a bad
magic or version, and fail the handshake with -ECONNRESET.

Fixes: 6a98d71daea1 ("RDMA/rtrs: client: main functionality")
Reported-by: Farhad Alemi <farhad.alemi@berkeley.edu>
Link: https://lore.kernel.org/linux-rdma/CA+0ovCg_sG8gaZXXj9zmOrpxRt=8+-x9wvycVNUKwWmMbr6-Yg@mail.gmail.com
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 drivers/infiniband/ulp/rtrs/rtrs-clt.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/infiniband/ulp/rtrs/rtrs-clt.c b/drivers/infiniband/ulp/rtrs/rtrs-clt.c
index eac38b57b00d..7fbbb9a53607 100644
--- a/drivers/infiniband/ulp/rtrs/rtrs-clt.c
+++ b/drivers/infiniband/ulp/rtrs/rtrs-clt.c
@@ -1853,6 +1853,10 @@ static int rtrs_rdma_conn_established(struct rtrs_clt_con *con,
 	}
 	if (con->c.cid == 0) {
 		queue_depth = le16_to_cpu(msg->queue_depth);
+		if (!queue_depth) {
+			rtrs_err(clt, "Invalid queue depth %u\n", queue_depth);
+			return -ECONNRESET;
+		}
 
 		if (clt_path->queue_depth > 0 && queue_depth != clt_path->queue_depth) {
 			rtrs_err(clt, "Error: queue depth changed\n");

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260922-rtrs-fix-warning-rtrs-clt-rdma-cm-handler-2160ee358b4e

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

