From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 28 Nov 2026 09:23:45 -0500
Subject: [PATCH net v2 3/6] net/smc: store each cursor once in
 smc_switch_cursor()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-b4-disp-360e65c5-v2-3-d9c05004d430@proton.me>
References: <20261128-b4-disp-360e65c5-v2-0-d9c05004d430@proton.me>
In-Reply-To: <20261128-b4-disp-360e65c5-v2-0-d9c05004d430@proton.me>
To: Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Eric Dumazet <edumazet@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>, Dust Li <dust.li@linux.alibaba.com>
Cc: Stefan Raspl <raspl@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Wen Gu <guwen@linux.alibaba.com>, linux-s390@vger.kernel.org, 
 linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Tony Lu <tonylu@linux.alibaba.com>, 
 Ursula Braun <ubraun@linux.ibm.com>, Hidayath Khan <hidayath@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795875822; l=3574;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=98ffgvy6neDZFGK0/AHk8UeD5iToECyiXrfIc5npmQM=;
 b=7voRKV6I2RqIJjCN0B2kkIJsk9oq+a1Q9cKIjmN+BCnqvA0eUiPD1JS0DBh5lhQphagPWtqlI
 LbhZJhciWmAC0ZX9DetgMXaM6+K2oSH9LH+05AUaMatOXeGCyBWclR8
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_switch_cursor() rewinds tx_curs_sent and local_tx_ctrl.prod, then
advances them and the two fin cursors in place with smc_curs_add(),
which updates count and wrap in separate steps. smc_tx_prepared_sends()
reads tx_curs_sent without send_lock or the socket spinlock, e.g. from
smc_close_stream_wait(): a cursor caught between the wrap increment and
the reduction of the count reads as nothing left to send, and close()
stops waiting while data is still queued.

Compute the cursors on local copies and store each of them once with
smc_curs_copy(), as smc_tx_rdma_writes() does.

Fixes: c6f02ebeea3a ("net/smc: switch connections to alternate link")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-215218@kernel.org/
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_core.c | 37 +++++++++++++++++++------------------
 1 file changed, 19 insertions(+), 18 deletions(-)

diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index fb9f6a4eb683..4ee9e6f0d659 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -1054,36 +1054,37 @@ static int smc_switch_cursor(struct smc_sock *smc, struct smc_cdc_tx_pend *pend,
 			     struct smc_wr_buf *wr_buf)
 {
 	struct smc_connection *conn = &smc->conn;
-	union smc_host_cursor cons, fin;
+	union smc_host_cursor cons, prod, sent;
 	int rc = 0;
 	int diff;
 
 	conn->tx_switch_gen++;	/* completions of earlier sends: no credit */
-	smc_curs_copy(&conn->tx_curs_sent, &conn->tx_curs_fin, conn);
-	smc_curs_copy(&fin, &conn->local_tx_ctrl_fin, conn);
-	/* set prod cursor to old state, enforce tx_rdma_writes() */
-	smc_curs_copy(&conn->local_tx_ctrl.prod, &fin, conn);
+	/* The cursors of the connection have readers outside send_lock and
+	 * the socket spinlock: work on copies and store each cursor once.
+	 */
+	smc_curs_copy(&sent, &conn->tx_curs_fin, conn);
+	smc_curs_copy(&prod, &conn->local_tx_ctrl_fin, conn);
 	smc_curs_copy(&cons, &conn->local_rx_ctrl.cons, conn);
 
-	if (smc_curs_comp(conn->peer_rmbe_size, &cons, &fin) < 0) {
-		/* cons cursor advanced more than fin, and prod was set
-		 * fin above, so now prod is smaller than cons. Fix that.
+	if (smc_curs_comp(conn->peer_rmbe_size, &cons, &prod) < 0) {
+		/* cons cursor advanced more than fin: the peer has read
+		 * that far, so resend from there and count it as confirmed.
 		 */
-		diff = smc_curs_diff(conn->peer_rmbe_size, &fin, &cons);
-		smc_curs_add(conn->sndbuf_desc->len,
-			     &conn->tx_curs_sent, diff);
-		smc_curs_add(conn->sndbuf_desc->len,
-			     &conn->tx_curs_fin, diff);
+		diff = smc_curs_diff(conn->peer_rmbe_size, &prod, &cons);
+		smc_curs_add(conn->sndbuf_desc->len, &sent, diff);
+		smc_curs_add(conn->peer_rmbe_size, &prod, diff);
+		smc_curs_copy(&conn->tx_curs_fin, &sent, conn);
+		smc_curs_copy(&conn->local_tx_ctrl_fin, &prod, conn);
 
 		smp_mb__before_atomic();
 		atomic_add(diff, &conn->sndbuf_space);
 		smp_mb__after_atomic();
-
-		smc_curs_add(conn->peer_rmbe_size,
-			     &conn->local_tx_ctrl.prod, diff);
-		smc_curs_add(conn->peer_rmbe_size,
-			     &conn->local_tx_ctrl_fin, diff);
 	}
+	/* set the sent and prod cursors to the resend's start, enforce
+	 * tx_rdma_writes()
+	 */
+	smc_curs_copy(&conn->tx_curs_sent, &sent, conn);
+	smc_curs_copy(&conn->local_tx_ctrl.prod, &prod, conn);
 	/* recalculate, value is used by tx_rdma_writes() */
 	atomic_set(&smc->conn.peer_rmbe_space, smc_write_space(conn));
 

-- 
2.56.1

