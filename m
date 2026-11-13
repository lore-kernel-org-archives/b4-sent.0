From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 12 Nov 2026 19:32:50 -0500
Subject: [PATCH net v6 3/3] net/smc: skip the DMB nocopy accounting until
 the send buffer is set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-b4-disp-1c8d3a53-v6-3-36a38ae35021@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794529967; l=3196;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=nt/R23dT6xDo9Kn8+8jVzh2IwHUKALEJsmXM6ZDy9BQ=;
 b=HzbPDA+YBBZlmDLCZNEqGeHNImMERgtKIKu+RQ4NThQ/oEpwpqGqMSwI6y5Fx8DGQhXBMN/y9
 CcDJ+EVvKd9BvlMFFWrYRHcjBL1o1Eq60+xvoOuPJr/aJGAINtpjKNr
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With SMC-D DMB nocopy (the loopback device), smcd_buf_attach() sets
conn->sndbuf_desc after the connection can already receive a CDC. When
a DMB is reused, the peer of its previous connection can still hold
the DMB token, and its next consumer update makes
smc_cdc_msg_recv_action() dereference the NULL sndbuf_desc in the
nocopy accounting.

Set sndbuf_desc with a release store after sndbuf_space, and skip the
nocopy accounting while sndbuf_desc is unset. Nothing of ours can have
been consumed before the attach, so the skipped accounting has nothing
to credit. The update's cursors and flags are still applied to the new
connection, as those of a CDC that leaves the consumer cursor alone
already are. The rest of the receive path handles an unset sndbuf_desc
since commit b395dd319cea ("net/smc: do not dereference an unset send
buffer on the SMC-D teardown path").

Fixes: cc0ab806fc52 ("net/smc: adapt cursor update when sndbuf and peer DMB are merged")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_cdc.c  | 10 +++++++++-
 net/smc/smc_core.c |  7 ++++---
 2 files changed, 13 insertions(+), 4 deletions(-)

diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index b3bcc206efe3..4a4a279b405b 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -333,6 +333,7 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 	union smc_host_cursor cons_old, prod_old;
 	struct smc_connection *conn = &smc->conn;
 	int diff_cons, diff_prod, diff_tx;
+	struct smc_buf_desc *sndbuf_desc;
 
 	/* smc_conn_create() can have cleared rmb_desc */
 	if (!smp_load_acquire(&conn->rmb_desc))
@@ -357,12 +358,19 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 		 * peer RMB, then update tx_curs_fin and sndbuf_space
 		 * here since peer has already consumed the data.
 		 */
+		sndbuf_desc = NULL;
 		if (conn->lgr->is_smcd &&
 		    smc_ism_support_dmb_nocopy(conn->lgr->smcd)) {
+			/* NULL until smcd_buf_attach(), but the old peer of
+			 * a reused DMB can already signal us.
+			 */
+			sndbuf_desc = smp_load_acquire(&conn->sndbuf_desc);
+		}
+		if (sndbuf_desc) {
 			/* Calculate consumed data and
 			 * increment free send buffer space.
 			 */
-			diff_tx = smc_curs_diff(conn->sndbuf_desc->len,
+			diff_tx = smc_curs_diff(sndbuf_desc->len,
 						&conn->tx_curs_fin,
 						&conn->local_rx_ctrl.cons);
 			/* increase local sndbuf space and fin_curs */
diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index 9ef9019bc497..982cfc79ee1c 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -2654,9 +2654,10 @@ int smcd_buf_attach(struct smc_sock *smc)
 	buf_desc->cpu_addr =
 		(u8 *)buf_desc->cpu_addr + sizeof(struct smcd_cdc_msg);
 	buf_desc->len -= sizeof(struct smcd_cdc_msg);
-	conn->sndbuf_desc = buf_desc;
-	conn->sndbuf_desc->used = 1;
-	atomic_set(&conn->sndbuf_space, conn->sndbuf_desc->len);
+	buf_desc->used = 1;
+	atomic_set(&conn->sndbuf_space, buf_desc->len);
+	/* Set last; pairs with the acquire in smc_cdc_msg_recv_action() */
+	smp_store_release(&conn->sndbuf_desc, buf_desc);
 	return 0;
 
 free:

-- 
2.56.0

