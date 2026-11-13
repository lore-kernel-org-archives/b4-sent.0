From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 12 Nov 2026 19:32:49 -0500
Subject: [PATCH net v6 2/3] net/smc: clear the buffer pointers before
 registering a connection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-b4-disp-1c8d3a53-v6-2-36a38ae35021@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794529967; l=4207;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=bG+MdtaWg2DbS51xfN4NR/c6TdcQBHG7qU+o+c2GvIg=;
 b=JFCZVpCVOyTE6TV+qBWePlJO5xSk/u6QKeZzP2ZohBWsv7te65w/rzwDU2V1sTeP/wi7khLjN
 xzZb1KEuz5kAmS6MqbAL2L0qasxJONmalyy7B8fD87UL4Vi7KZRDYNY
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_conn_abort() releases the buffers of a failed handshake attempt
and leaves conn->rmb_desc and conn->sndbuf_desc pointing at them.
When the SMC-Rv2 attempt of the listen worker fails in
smc_listen_rdma_reg(), which a peer forces with a negative
CONFIRM_RKEY response, the SMC-Rv1 retry registers the connection
under a new token with the stale pointers; a client can do the same
with further connect() calls after a failed non-blocking one. A CDC
with that token then passes the rmb_desc test in
smc_cdc_rx_handler() and is handled on a buffer the connection no
longer owns, and a retry that cannot create its buffers releases the
stale ones a second time.

Clear both pointers in smc_conn_create(), which every registration
goes through, under the socket spinlock, and let
smc_cdc_msg_recv_action(), which runs under it, return while
rmb_desc is unset: a handler that found the connection before the
clear then does not dereference NULL.

Fixes: 35112271672a ("net/smc: Reset connection when trying to use SMCRv2 fails.")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/179241208347.3135.18021879529736748765@kernel.org/
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
The Fixes tag names the listen retry, which a remote peer reaches.
The connect() re-entry needs the local caller and is older (by
inspection); I have not dated it.

The clear takes the slock with spin_lock_bh(): smc_conn_create() runs in
process context with the socket owned, and the CDC handlers take the
same lock with bh_lock_sock(). Lockdep is silent on it, and reports an
inconsistent lock state with spin_lock() there.

After the second test the function loads rmb_desc plainly: the clear
needs the lock it runs under, so a pointer seen set stays set. The
SMC-D tasklet loads rmb_desc before that lock and the clear cannot
meet it: the connection is unpublished from the device, and its
tasklet killed or the connection marked killed, before a retry
reaches smc_conn_create().
---
 net/smc/smc_cdc.c  | 7 ++++++-
 net/smc/smc_core.c | 9 +++++++++
 2 files changed, 15 insertions(+), 1 deletion(-)

diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index ee5ba6c7a5b4..b3bcc206efe3 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -334,6 +334,10 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 	struct smc_connection *conn = &smc->conn;
 	int diff_cons, diff_prod, diff_tx;
 
+	/* smc_conn_create() can have cleared rmb_desc */
+	if (!smp_load_acquire(&conn->rmb_desc))
+		return;
+
 	smc_curs_copy(&prod_old, &conn->local_rx_ctrl.prod, conn);
 	smc_curs_copy(&cons_old, &conn->local_rx_ctrl.cons, conn);
 	smc_cdc_msg_to_host(&conn->local_rx_ctrl, cdc, conn);
@@ -484,7 +488,8 @@ static void smc_cdc_rx_handler(struct ib_wc *wc, void *buf)
 	read_lock_bh(&lgr->conns_lock);
 	conn = smc_lgr_find_conn(ntohl(cdc->token), lgr);
 	/* The connection is in the token tree before __smc_buf_create()
-	 * sets its RMB: drop a CDC that comes earlier.
+	 * sets its RMB: drop a CDC that comes earlier. rmb_desc is cleared
+	 * under the socket spinlock; smc_cdc_msg_recv_action() tests it there.
 	 */
 	if (!conn || conn->out_of_sync || !smp_load_acquire(&conn->rmb_desc)) {
 		read_unlock_bh(&lgr->conns_lock);
diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index 02269cede641..9ef9019bc497 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -2024,6 +2024,15 @@ int smc_conn_create(struct smc_sock *smc, struct smc_init_info *ini)
 	spinlock_t *lgr_lock;
 	int rc = 0;
 
+	/* A retried handshake comes back with the buffer pointers of the
+	 * failed attempt still set: clear them before the connection is
+	 * registered. smc_cdc_msg_recv_action() tests rmb_desc under this lock.
+	 */
+	spin_lock_bh(&smc->sk.sk_lock.slock);
+	WRITE_ONCE(conn->rmb_desc, NULL);
+	WRITE_ONCE(conn->sndbuf_desc, NULL);
+	spin_unlock_bh(&smc->sk.sk_lock.slock);
+
 	lgr_list = ini->is_smcd ? &ini->ism_dev[ini->ism_selected]->lgr_list :
 				  &smc_lgr_list.list;
 	lgr_lock = ini->is_smcd ? &ini->ism_dev[ini->ism_selected]->lgr_lock :

-- 
2.56.0

