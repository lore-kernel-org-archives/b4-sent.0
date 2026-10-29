From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 29 Oct 2026 13:21:25 -0500
Subject: [PATCH net v8 4/4] net/smc: bound the link failover cursor advance
 to the send buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-b4-disp-33001ace-v8-4-f9bb96e17827@proton.me>
References: <20261029-b4-disp-33001ace-v8-0-f9bb96e17827@proton.me>
In-Reply-To: <20261029-b4-disp-33001ace-v8-0-f9bb96e17827@proton.me>
To: Sidraya Jayagond <sidraya@linux.ibm.com>, 
 Jakub Kicinski <kuba@kernel.org>, Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Paolo Abeni <pabeni@redhat.com>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Dust Li <dust.li@linux.alibaba.com>, Eric Dumazet <edumazet@kernel.org>
Cc: Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Ursula Braun <ubraun@linux.ibm.com>, Stefan Raspl <raspl@linux.ibm.com>, 
 linux-s390@vger.kernel.org, Wen Gu <guwen@linux.alibaba.com>, 
 linux-kernel@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>, Wenjia Zhang <wenjia@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, linux-rdma@vger.kernel.org, 
 netdev@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793298082; l=3862;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=pYvkTNfmgfYrChtl4QYbezukLNrDt2+mNDHk+pdZyKE=;
 b=QL6rWqrPTQJK5V3L71fhYkkY904avKa6++vytE2wVeuMzY/+PDyCEq7EeSIk8D93QKbpxDrUk
 MYUB2XWaREfDhHQyJNAAMOUfCx6+voiw9yvqv9v+b1IA/vVe3HWhha2
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SMC-R link failover, smc_switch_cursor() rewinds the send and
producer cursors to their values at the last completed CDC send, then
advances them by the distance the peer's consumer cursor is ahead. That
cursor comes from the wire, so a forged one adds an arbitrary amount to
sndbuf_space and to the cursors. smc_curs_add() wraps them only once, so
the next RDMA write takes its source past the send buffer.

A conforming peer keeps its cursor count inside its RMB and cannot
consume past the data in the send buffer. Advance only for such a count,
and no further than tx_curs_prep. The pre-failover tx_curs_sent cannot
be the bound: an earlier failover may have rewound it below the peer's
cursor. The destination side is not bounded here: smc_write_space()
still sizes the window from the peer's cursor, so a forged one can take
the next write past the peer's own RMB, where its HCA refuses it and
the link goes down.

Fixes: c6f02ebeea3a ("net/smc: switch connections to alternate link")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Bounding the copy in smc_tx_sendmsg() (3/4) does not cover this: the
RDMA write takes its offsets from the cursors. Measured on rxe, send
buffer 16K, peer RMB 32K, 4096 bytes sent and unconfirmed, the consumer
cursor forged one wrap ahead at count 64: unpatched, tx_curs_sent lands
64 bytes past the send buffer and the next write takes its source from
there (rxe refuses that WR); with the patch the advance stops at
tx_curs_prep, nothing is pending, and nothing is written after the
switch. The destination side, with the consumer cursor forged two wraps
ahead at the peer's RMB + 4096 (send buffer 64K, peer RMB 16K): with the
patch the catch-up is skipped, the window is the whole RMB and the first
write after the switch, from prod.count 1, ends one byte past the peer's
RMB; its HCA refuses the write and the link goes down. Without the patch
the catch-up lands prod on the forged count, smc_write_space() is 0 and
nothing more is written.
---
 net/smc/smc_core.c | 18 ++++++++++++------
 1 file changed, 12 insertions(+), 6 deletions(-)

diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index fe6e4a2f7935..42d83a002ffb 100644
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
-
-	if (smc_curs_comp(conn->peer_rmbe_size, &cons, &fin) < 0) {
-		/* cons cursor advanced more than fin, and prod was set
-		 * fin above, so now prod is smaller than cons. Fix that.
+	smc_curs_copy(&prep, &conn->tx_curs_prep, conn);
+
+	if (cons.count < conn->peer_rmbe_size &&
+	    smc_curs_comp(conn->peer_rmbe_size, &cons, &fin) < 0) {
+		/* cons cursor advanced more than fin, and prod was set fin
+		 * above, so now prod is smaller than cons. cons comes off the
+		 * wire: catch up only for a count inside the peer's RMB and no
+		 * further than the send buffer holds, else that peer stalls.
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

