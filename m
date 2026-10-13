From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 13 Oct 2026 15:12:51 -0500
Subject: [PATCH net v7 4/4] net/smc: bound the link failover cursor advance
 to the send buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-disp-f345196c-v7-4-ef3dddfbfa68@proton.me>
References: <20261013-b4-disp-f345196c-v7-0-ef3dddfbfa68@proton.me>
In-Reply-To: <20261013-b4-disp-f345196c-v7-0-ef3dddfbfa68@proton.me>
To: "D. Wythe" <alibuda@linux.alibaba.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Eric Dumazet <edumazet@kernel.org>, Dust Li <dust.li@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>
Cc: netdev@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 linux-kernel@vger.kernel.org, Wenjia Zhang <wenjia@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, linux-s390@vger.kernel.org, 
 Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Ursula Braun <ubraun@linux.ibm.com>, linux-rdma@vger.kernel.org, 
 Stefan Raspl <raspl@linux.ibm.com>, Hidayath Khan <hidayath@linux.ibm.com>, 
 Wen Gu <guwen@linux.alibaba.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791922368; l=2755;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=WmGU8zUppN7BH0rV8o+Estl5Zae56D3SssXqw8plQEU=;
 b=A3NOyHr0oJ7D6eONfsU+V5uBJSVuv/KU5E1/NhUJkpSNObgkRkpdqMrywMz1DlFzcm+ftTPRW
 R+LFpRK7IhkD9tDv89mYG47MaUgCRO13Rs+dzCN+JZvvqMuSkxEY/Me
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SMC-R link failover, smc_switch_cursor() rewinds the send and
producer cursors to their values at the last completed CDC send, then
advances them by however far the peer's consumer cursor is ahead. That
cursor comes from the wire, so a forged one adds an arbitrary amount to
sndbuf_space and to the cursors. smc_curs_add() wraps them only once, so
the next RDMA write can take its source past the send buffer and its
destination past the peer's RMB.

A conforming peer keeps its cursor count inside its RMB and cannot
consume past the data in the send buffer. Advance only for such a count,
and no further than tx_curs_prep. The pre-failover tx_curs_sent cannot
be the bound: an earlier failover may have rewound it below the peer's
cursor.

Fixes: c6f02ebeea3a ("net/smc: switch connections to alternate link")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Bounding the copy in smc_tx_sendmsg() (3/4) does not cover this: the
RDMA write takes its offsets from the cursors.
---
 net/smc/smc_core.c | 14 ++++++++++----
 1 file changed, 10 insertions(+), 4 deletions(-)

diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index 8829517299de..36aee89e5f5f 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -1034,7 +1034,7 @@ static int smc_switch_cursor(struct smc_sock *smc, struct smc_cdc_tx_pend *pend,
 			     struct smc_wr_buf *wr_buf)
 {
 	struct smc_connection *conn = &smc->conn;
-	union smc_host_cursor cons, fin;
+	union smc_host_cursor cons, fin, prep;
 	int rc = 0;
 	int diff;
 
@@ -1043,12 +1043,18 @@ static int smc_switch_cursor(struct smc_sock *smc, struct smc_cdc_tx_pend *pend,
 	/* set prod cursor to old state, enforce tx_rdma_writes() */
 	smc_curs_copy(&conn->local_tx_ctrl.prod, &fin, conn);
 	smc_curs_copy(&cons, &conn->local_rx_ctrl.cons, conn);
+	smc_curs_copy(&prep, &conn->tx_curs_prep, conn);
 
-	if (smc_curs_comp(conn->peer_rmbe_size, &cons, &fin) < 0) {
+	if (cons.count < conn->peer_rmbe_size &&
+	    smc_curs_comp(conn->peer_rmbe_size, &cons, &fin) < 0) {
 		/* cons cursor advanced more than fin, and prod was set
-		 * fin above, so now prod is smaller than cons. Fix that.
+		 * fin above, so now prod is smaller than cons. cons comes
+		 * off the wire: catch up only for a count inside the peer's
+		 * RMB and no further than the data in the send buffer.
 		 */
-		diff = smc_curs_diff(conn->peer_rmbe_size, &fin, &cons);
+		diff = min(smc_curs_diff(conn->peer_rmbe_size, &fin, &cons),
+			   smc_curs_diff(conn->sndbuf_desc->len,
+					 &conn->tx_curs_sent, &prep));
 		smc_curs_add(conn->sndbuf_desc->len,
 			     &conn->tx_curs_sent, diff);
 		smc_curs_add(conn->sndbuf_desc->len,

-- 
2.56.0

