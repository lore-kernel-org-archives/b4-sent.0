From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 15 Oct 2026 06:53:32 -0500
Subject: [PATCH net v5 2/2] net/smc: skip the DMB nocopy accounting until
 the send buffer is set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-b4-disp-2a8d85ef-v5-2-6b795e8263c9@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792065211; l=3069;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=xXN+n7Qm/oywh+j/Q9jQUIu7QO9vC0hGn4Ru7SfMqHU=;
 b=ezgGqPvdMVh4D5CMq1SL5vDgT0+V7ZD18szmPex16OUdp9CoC7DNfuBJlqA79BrSA27spm5hi
 rXH48rquBpdAcs4/gREeXXIywRyBOjx/zCSd8rr+dwnxGDlFWr5n5Lr
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
nocopy accounting while sndbuf_desc is unset. Before the attach the
current peer has consumed nothing of ours, so no update from it is
lost. The rest of the receive path handles an unset sndbuf_desc since
commit b395dd319cea ("net/smc: do not dereference an unset send buffer
on the SMC-D teardown path").

Fixes: cc0ab806fc52 ("net/smc: adapt cursor update when sndbuf and peer DMB are merged")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_cdc.c  | 10 +++++++++-
 net/smc/smc_core.c |  7 ++++---
 2 files changed, 13 insertions(+), 4 deletions(-)

diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index 7bf902ebd7ab..d6825f48f568 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -333,6 +333,7 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
 	union smc_host_cursor cons_old, prod_old;
 	struct smc_connection *conn = &smc->conn;
 	int diff_cons, diff_prod, diff_tx;
+	struct smc_buf_desc *sndbuf_desc;
 
 	smc_curs_copy(&prod_old, &conn->local_rx_ctrl.prod, conn);
 	smc_curs_copy(&cons_old, &conn->local_rx_ctrl.cons, conn);
@@ -353,12 +354,19 @@ static void smc_cdc_msg_recv_action(struct smc_sock *smc,
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
index 26f19a00c159..9322c27145df 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -2603,9 +2603,10 @@ int smcd_buf_attach(struct smc_sock *smc)
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

