From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 13 Nov 2026 23:14:42 -0500
Subject: [PATCH net 3/4] net/smc: fix the failover catch-up across the
 cursor wrap rollover
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-b4-disp-1a9ab9b0-v1-3-4a7c8d85d849@proton.me>
References: <20261113-b4-disp-1a9ab9b0-v1-0-4a7c8d85d849@proton.me>
In-Reply-To: <20261113-b4-disp-1a9ab9b0-v1-0-4a7c8d85d849@proton.me>
To: Dust Li <dust.li@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Jakub Kicinski <kuba@kernel.org>, 
 Eric Dumazet <edumazet@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Paolo Abeni <pabeni@redhat.com>, Sidraya Jayagond <sidraya@linux.ibm.com>
Cc: Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, netdev@vger.kernel.org, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Ursula Braun <ubraun@linux.ibm.com>, 
 Hidayath Khan <hidayath@linux.ibm.com>, linux-s390@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 Wen Gu <guwen@linux.alibaba.com>, Stefan Raspl <raspl@linux.ibm.com>, 
 linux-rdma@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794629679; l=4137;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=MVHarJC77cCCLJEzqiGRuVpi6O8XQzj00ArzQHD908I=;
 b=F74AfkgSmjHIJIkI11G6+klEgg5afXLKUyZ+MgiafeDZN5uFBsKxa2QREh+gp2N2FTyRZcd3/
 sEaJOr5FktXDaaM12ytCJMfZ4oOK01LFbHkVs6yBy5KhEbQS6xLAT2A
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_switch_cursor() orders the peer's consumer cursor against
local_tx_ctrl_fin with smc_curs_comp(), which misorders them across the
65535 -> 0 rollover of the u16 wrap. A consumer cursor behind reads as
ahead: the catch-up can credit sndbuf_space for bytes never sent and
tell the peer they are in its RMB, so the next send() can copy past the
end of the send buffer. One ahead reads as behind and the catch-up is
skipped. With a send buffer larger than the peer's RMB, the catch-up can
also be short once the peer is more than one RMB past local_tx_ctrl_fin,
and the connection then stalls.

Use the signed cursor distance, advance the RMB cursors across any
number of wraps, and bound the catch-up by the bytes sent, which a
peer's consumer cursor cannot legitimately pass.

Fixes: c6f02ebeea3a ("net/smc: switch connections to alternate link")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20261029-b4-disp-33001ace-v8-0-f9bb96e17827%40proton.me?part=4
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_cdc.h  | 10 ++++++++++
 net/smc/smc_core.c | 22 ++++++++++++++--------
 2 files changed, 24 insertions(+), 8 deletions(-)

diff --git a/net/smc/smc_cdc.h b/net/smc/smc_cdc.h
index 597acb2e123f..4b586a20dfc2 100644
--- a/net/smc/smc_cdc.h
+++ b/net/smc/smc_cdc.h
@@ -97,6 +97,16 @@ static inline void smc_curs_add(int size, union smc_host_cursor *curs,
 	}
 }
 
+/* smc_curs_add() for a value that may span more than one ring */
+static inline void smc_curs_advance(unsigned int size,
+				    union smc_host_cursor *curs, u32 value)
+{
+	u32 count = curs->count + value;
+
+	curs->wrap += count / size;
+	curs->count = count % size;
+}
+
 /* Copy cursor src into tgt */
 static inline void smc_curs_copy(union smc_host_cursor *tgt,
 				 union smc_host_cursor *src,
diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index fb9f6a4eb683..76a577a20e4a 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -1054,22 +1054,28 @@ static int smc_switch_cursor(struct smc_sock *smc, struct smc_cdc_tx_pend *pend,
 			     struct smc_wr_buf *wr_buf)
 {
 	struct smc_connection *conn = &smc->conn;
-	union smc_host_cursor cons, fin;
+	union smc_host_cursor cons, fin, sent;
 	int rc = 0;
-	int diff;
+	s64 diff;
 
 	conn->tx_switch_gen++;	/* completions of earlier sends: no credit */
+	smc_curs_copy(&sent, &conn->tx_curs_sent, conn);
 	smc_curs_copy(&conn->tx_curs_sent, &conn->tx_curs_fin, conn);
 	smc_curs_copy(&fin, &conn->local_tx_ctrl_fin, conn);
 	/* set prod cursor to old state, enforce tx_rdma_writes() */
 	smc_curs_copy(&conn->local_tx_ctrl.prod, &fin, conn);
 	smc_curs_copy(&cons, &conn->local_rx_ctrl.cons, conn);
 
-	if (smc_curs_comp(conn->peer_rmbe_size, &cons, &fin) < 0) {
+	/* not past what was sent, whatever cons says; that also keeps
+	 * diff within one send buffer for smc_curs_add()
+	 */
+	diff = min(smc_curs_sdiff(conn->peer_rmbe_size, &fin, &cons),
+		   smc_curs_sdiff(conn->sndbuf_desc->len,
+				  &conn->tx_curs_fin, &sent));
+	if (diff > 0) {
 		/* cons cursor advanced more than fin, and prod was set
 		 * fin above, so now prod is smaller than cons. Fix that.
 		 */
-		diff = smc_curs_diff(conn->peer_rmbe_size, &fin, &cons);
 		smc_curs_add(conn->sndbuf_desc->len,
 			     &conn->tx_curs_sent, diff);
 		smc_curs_add(conn->sndbuf_desc->len,
@@ -1079,10 +1085,10 @@ static int smc_switch_cursor(struct smc_sock *smc, struct smc_cdc_tx_pend *pend,
 		atomic_add(diff, &conn->sndbuf_space);
 		smp_mb__after_atomic();
 
-		smc_curs_add(conn->peer_rmbe_size,
-			     &conn->local_tx_ctrl.prod, diff);
-		smc_curs_add(conn->peer_rmbe_size,
-			     &conn->local_tx_ctrl_fin, diff);
+		smc_curs_advance(conn->peer_rmbe_size,
+				 &conn->local_tx_ctrl.prod, diff);
+		smc_curs_advance(conn->peer_rmbe_size,
+				 &conn->local_tx_ctrl_fin, diff);
 	}
 	/* recalculate, value is used by tx_rdma_writes() */
 	atomic_set(&smc->conn.peer_rmbe_space, smc_write_space(conn));

-- 
2.56.0

