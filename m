From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 12 Nov 2026 19:32:48 -0500
Subject: [PATCH net v6 1/3] net/smc: order the CDC receive path against RMB
 publication
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-b4-disp-1c8d3a53-v6-1-36a38ae35021@proton.me>
References: <20261112-b4-disp-1c8d3a53-v6-0-36a38ae35021@proton.me>
In-Reply-To: <20261112-b4-disp-1c8d3a53-v6-0-36a38ae35021@proton.me>
To: Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Jakub Kicinski <kuba@kernel.org>, Dust Li <dust.li@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>
Cc: Hans Wippel <hwippel@linux.ibm.com>, linux-kernel@vger.kernel.org, 
 Wenjia Zhang <wenjia@linux.ibm.com>, netdev@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>, Ursula Braun <ubraun@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, linux-rdma@vger.kernel.org, 
 Wen Gu <guwen@linux.alibaba.com>, linux-s390@vger.kernel.org, 
 Simon Horman <horms@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794529967; l=2887;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=2rv6B0D/pQPP0IMQU/D54a72ysNQDMpYUG+Lt+SivGA=;
 b=sgG6hWAl3Na+CyT1IqdbjAOCV7bhuNGI1OMumuUojRDCCkeZ5m7U2H/FgLCvK1TGhYUIoF/PX
 CrLBKzcQ7rnAOs6QSYNwpp/Xnz5xDdHY7tKHkBFGTKGOJZNuLS03WFV
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
The Closes tag is Sashiko's report of this window, in its review of
v6 of the cursor series. v9 of that series is at
https://lore.kernel.org/all/20261112-b4-disp-0287c16e-v9-0-e5e8fa688177@proton.me/
and its 2/6 conflicts with this patch in __smc_buf_create(): keep
its rmb_len store at the top of the is_rmb block, before the release
store. The tree is the same in either order.
---
 net/smc/smc_cdc.c  | 5 ++++-
 net/smc/smc_core.c | 3 ++-
 2 files changed, 6 insertions(+), 2 deletions(-)

diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index 32d6d03df321..ee5ba6c7a5b4 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -483,7 +483,10 @@ static void smc_cdc_rx_handler(struct ib_wc *wc, void *buf)
 	lgr = smc_get_lgr(link);
 	read_lock_bh(&lgr->conns_lock);
 	conn = smc_lgr_find_conn(ntohl(cdc->token), lgr);
-	if (!conn || conn->out_of_sync) {
+	/* The connection is in the token tree before __smc_buf_create()
+	 * sets its RMB: drop a CDC that comes earlier.
+	 */
+	if (!conn || conn->out_of_sync || !smp_load_acquire(&conn->rmb_desc)) {
 		read_unlock_bh(&lgr->conns_lock);
 		return;
 	}
diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index a3164201c142..02269cede641 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -2544,12 +2544,13 @@ static int __smc_buf_create(struct smc_sock *smc, bool is_smcd, bool is_rmb)
 	}
 
 	if (is_rmb) {
-		conn->rmb_desc = buf_desc;
 		conn->rmbe_size_comp = bufsize_comp;
 		smc->sk.sk_rcvbuf = bufsize * 2;
 		atomic_set(&conn->bytes_to_rcv, 0);
 		conn->rmbe_update_limit =
 			smc_rmb_wnd_update_limit(buf_desc->len);
+		/* Set last; smc_cdc_rx_handler() tests it with an acquire */
+		smp_store_release(&conn->rmb_desc, buf_desc);
 		if (is_smcd)
 			smc_ism_set_conn(conn); /* map RMB/smcd_dev to conn */
 	} else {

-- 
2.56.0

