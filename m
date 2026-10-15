From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 15 Oct 2026 06:53:31 -0500
Subject: [PATCH net v5 1/2] net/smc: order the CDC receive path against RMB
 publication
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-b4-disp-2a8d85ef-v5-1-6b795e8263c9@proton.me>
References: <20261015-b4-disp-2a8d85ef-v5-0-6b795e8263c9@proton.me>
In-Reply-To: <20261015-b4-disp-2a8d85ef-v5-0-6b795e8263c9@proton.me>
To: Jakub Kicinski <kuba@kernel.org>, Dust Li <dust.li@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Simon Horman <horms@kernel.org>, Wenjia Zhang <wenjia@linux.ibm.com>, 
 Ursula Braun <ubraun@linux.ibm.com>, Hans Wippel <hwippel@linux.ibm.com>, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Tony Lu <tonylu@linux.alibaba.com>, linux-rdma@vger.kernel.org, 
 Wen Gu <guwen@linux.alibaba.com>, linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792065211; l=2567;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=kHI7XJJXDLRn/IVI2eJi27K/PrutBbPvH2QzLorLnNQ=;
 b=lhNYkaeY++smtZE7MyF5+Dw8w8T9hdojbqE04iKZvw0WFI93sfcMsaHK0U+mMXCmQ2Jd3K1gf
 dvgUdqKGiHRC7qkbCtADeerab3D+D+WjXoPMxHPjkeLg8/H8skphmQQ
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_conn_create() adds an SMC-R connection to the token tree before
smc_buf_create() sets conn->rmb_desc. Tokens come from one global
counter, so a peer in the link group can predict the next one. A CDC
with that token, arriving in the window, makes
smc_cdc_msg_recv_action() dereference a NULL rmb_desc in softirq.

Set rmb_desc with a release store after the receive fields that go
with it, and drop a CDC in smc_cdc_rx_handler() while rmb_desc is
unset. A conforming peer learns the token only from the CLC accept or
confirm, sent after smc_buf_create(), so nothing it sends is dropped.
The SMC-D receive tasklet needs no check: smc_ism_set_conn() publishes
the connection under smcd->lock, which smcd_handle_irq() also takes.

Fixes: 69cb7dc0218b ("net/smc: add common buffer size in send and receive buffer descriptors")
Closes: https://sashiko.dev/#/patchset/20261008-b4-disp-f7cd3d96-v6-0-fba616c0920c@proton.me?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_cdc.c  | 6 +++++-
 net/smc/smc_core.c | 3 ++-
 2 files changed, 7 insertions(+), 2 deletions(-)

diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index 32d6d03df321..7bf902ebd7ab 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -483,7 +483,11 @@ static void smc_cdc_rx_handler(struct ib_wc *wc, void *buf)
 	lgr = smc_get_lgr(link);
 	read_lock_bh(&lgr->conns_lock);
 	conn = smc_lgr_find_conn(ntohl(cdc->token), lgr);
-	if (!conn || conn->out_of_sync) {
+	/* The connection is in the token tree before __smc_buf_create()
+	 * sets its RMB: drop a CDC that comes earlier. rmb_desc is never
+	 * cleared, so the callees can load it plainly.
+	 */
+	if (!conn || conn->out_of_sync || !smp_load_acquire(&conn->rmb_desc)) {
 		read_unlock_bh(&lgr->conns_lock);
 		return;
 	}
diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index 9974149659c2..26f19a00c159 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -2502,12 +2502,13 @@ static int __smc_buf_create(struct smc_sock *smc, bool is_smcd, bool is_rmb)
 	}
 
 	if (is_rmb) {
-		conn->rmb_desc = buf_desc;
 		conn->rmbe_size_comp = bufsize_comp;
 		smc->sk.sk_rcvbuf = bufsize * 2;
 		atomic_set(&conn->bytes_to_rcv, 0);
 		conn->rmbe_update_limit =
 			smc_rmb_wnd_update_limit(buf_desc->len);
+		/* Set last; pairs with the acquire in smc_cdc_rx_handler() */
+		smp_store_release(&conn->rmb_desc, buf_desc);
 		if (is_smcd)
 			smc_ism_set_conn(conn); /* map RMB/smcd_dev to conn */
 	} else {

-- 
2.56.0

