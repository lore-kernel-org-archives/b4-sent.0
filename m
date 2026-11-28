From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 28 Nov 2026 09:23:46 -0500
Subject: [PATCH net v2 4/6] net/smc: fix the failover catch-up across the
 cursor wrap rollover
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-b4-disp-360e65c5-v2-4-d9c05004d430@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795875822; l=3940;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=q6yzVhoWdbn0tEnEe3VJrfFDCgfbXJKEGJz8IQcFsjQ=;
 b=crUA3JbW0g7b1fnp0KpgBheQxsYZcii6NmXK2y0TVCiVtwb3au2LiwL6R75/QhGoHgbsrE/IK
 Mt7Mbsw/S9PBpmN9m+re1pfHZJgBk/iqHWY7mGnz36YOvHqYYApCE5y
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_switch_cursor() orders the peer's consumer cursor against
local_tx_ctrl_fin with smc_curs_comp(), which misorders them across the
65535 -> 0 rollover of the u16 wrap. A consumer cursor that is behind
reads as ahead: the catch-up can credit sndbuf_space for bytes never
sent and tell the peer they are in its RMB, so the next send() can copy
past the end of the send buffer. One that is ahead reads as behind and
the catch-up is skipped. With a send buffer larger than the peer's RMB,
the catch-up can also be short once the peer is more than one RMB past
local_tx_ctrl_fin, and the connection then stalls.

Use the signed cursor distance, advance the RMB cursors across any
number of wraps, and bound the catch-up by tx_curs_prep: a conforming
peer has read no further, and unlike tx_curs_sent no failover rewinds
it. The bound also caps what a forged consumer cursor, which is taken
off the wire unchecked, can add to sndbuf_space.

Fixes: c6f02ebeea3a ("net/smc: switch connections to alternate link")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20261029-b4-disp-33001ace-v8-0-f9bb96e17827%40proton.me?part=4
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_cdc.h  | 10 ++++++++++
 net/smc/smc_core.c | 16 +++++++++++-----
 2 files changed, 21 insertions(+), 5 deletions(-)

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
index 4ee9e6f0d659..22a9a818a046 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -1054,9 +1054,9 @@ static int smc_switch_cursor(struct smc_sock *smc, struct smc_cdc_tx_pend *pend,
 			     struct smc_wr_buf *wr_buf)
 {
 	struct smc_connection *conn = &smc->conn;
-	union smc_host_cursor cons, prod, sent;
+	union smc_host_cursor cons, prep, prod, sent;
 	int rc = 0;
-	int diff;
+	s64 diff;
 
 	conn->tx_switch_gen++;	/* completions of earlier sends: no credit */
 	/* The cursors of the connection have readers outside send_lock and
@@ -1065,14 +1065,20 @@ static int smc_switch_cursor(struct smc_sock *smc, struct smc_cdc_tx_pend *pend,
 	smc_curs_copy(&sent, &conn->tx_curs_fin, conn);
 	smc_curs_copy(&prod, &conn->local_tx_ctrl_fin, conn);
 	smc_curs_copy(&cons, &conn->local_rx_ctrl.cons, conn);
+	smc_curs_copy(&prep, &conn->tx_curs_prep, conn);
 
-	if (smc_curs_comp(conn->peer_rmbe_size, &cons, &prod) < 0) {
+	/* cons comes off the wire: go no further than tx_curs_prep, which
+	 * a conforming peer has not read past and no failover rewinds. That
+	 * also keeps diff within one send buffer for smc_curs_add().
+	 */
+	diff = min(smc_curs_sdiff(conn->peer_rmbe_size, &prod, &cons),
+		   smc_curs_sdiff(conn->sndbuf_desc->len, &sent, &prep));
+	if (diff > 0) {
 		/* cons cursor advanced more than fin: the peer has read
 		 * that far, so resend from there and count it as confirmed.
 		 */
-		diff = smc_curs_diff(conn->peer_rmbe_size, &prod, &cons);
 		smc_curs_add(conn->sndbuf_desc->len, &sent, diff);
-		smc_curs_add(conn->peer_rmbe_size, &prod, diff);
+		smc_curs_advance(conn->peer_rmbe_size, &prod, diff);
 		smc_curs_copy(&conn->tx_curs_fin, &sent, conn);
 		smc_curs_copy(&conn->local_tx_ctrl_fin, &prod, conn);
 

-- 
2.56.1

