From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 08 Aug 2026 02:21:23 -0500
Subject: [PATCH net v2 1/2] net/smc: unregister the connection before
 draining the rx tasklet
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-b4-disp-22f119e6-v2-1-61647601a6f3@proton.me>
References: <20260808-b4-disp-22f119e6-v2-0-61647601a6f3@proton.me>
In-Reply-To: <20260808-b4-disp-22f119e6-v2-0-61647601a6f3@proton.me>
To: Dust Li <dust.li@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, Wen Gu <guwen@linux.alibaba.com>, 
 Eric Dumazet <edumazet@google.com>
Cc: linux-kernel@vger.kernel.org, linux-rdma@vger.kernel.org, 
 netdev@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786173683; l=2661;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=Nd2Ah3VugjHz7UvVYOJKMppfI+jftDy275brVglOEvs=;
 b=QE3npRELgIChYQZFpoZO00PLr29iOAKSyZlw+h7E+Fj5mJBV1QLOe0hUI+cqO53eoFlWnCfGi
 FTHK6uamdGSDmWku6KTtiG7GUIRBSm9T4wNh2rCQ/Zqxh2kch/rGrjD
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_conn_free() calls smc_ism_unset_conn() only while the link group is
still on its device list, and never sets conn->killed.
smc_lgr_terminate_sched() unlinks the group immediately and defers killing
its connections to a work item, so a connection freed in that window keeps
its smcd->conn[] slot with both gates in smcd_handle_irq() open, and the
device can re-arm the receive tasklet after tasklet_kill() has returned. On
the DMB-nocopy path the ghost send buffer is freed right after that drain,
so the re-armed tasklet dereferences it.

Unregister unconditionally and drain before the detach at both teardown
sites, mirroring rmb_desc, which smc_buf_unuse() releases after the drain.
Clear conn->sndbuf_desc before freeing it as well, so a reader that samples
the pointer cannot get one that is already freed.

Fixes: ae2be35cbed2 ("net/smc: {at|de}tach sndbuf to peer DMB if supported")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_core.c | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index b4208cb186c5..181647982490 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -1209,14 +1209,16 @@ static void smcd_buf_detach(struct smc_connection *conn)
 {
 	struct smcd_dev *smcd = conn->lgr->smcd;
 	u64 peer_token = conn->peer_token;
+	struct smc_buf_desc *buf_desc;
 
 	if (!conn->sndbuf_desc)
 		return;
 
 	smc_ism_detach_dmb(smcd, peer_token);
 
-	kfree(conn->sndbuf_desc);
+	buf_desc = conn->sndbuf_desc;
 	conn->sndbuf_desc = NULL;
+	kfree(buf_desc);
 }
 
 static void smc_buf_unuse(struct smc_connection *conn,
@@ -1268,11 +1270,10 @@ void smc_conn_free(struct smc_connection *conn)
 		goto lgr_put;
 
 	if (lgr->is_smcd) {
-		if (!list_empty(&lgr->list))
-			smc_ism_unset_conn(conn);
+		smc_ism_unset_conn(conn);
+		tasklet_kill(&conn->rx_tsklet);
 		if (smc_ism_support_dmb_nocopy(lgr->smcd))
 			smcd_buf_detach(conn);
-		tasklet_kill(&conn->rx_tsklet);
 	} else {
 		smc_cdc_wait_pend_tx_wr(conn);
 		if (current_work() != &conn->abort_work)
@@ -1525,12 +1526,12 @@ static void smc_conn_kill(struct smc_connection *conn, bool soft)
 	smc_sk_wake_ups(smc);
 	if (conn->lgr->is_smcd) {
 		smc_ism_unset_conn(conn);
-		if (smc_ism_support_dmb_nocopy(conn->lgr->smcd))
-			smcd_buf_detach(conn);
 		if (soft)
 			tasklet_kill(&conn->rx_tsklet);
 		else
 			tasklet_unlock_wait(&conn->rx_tsklet);
+		if (smc_ism_support_dmb_nocopy(conn->lgr->smcd))
+			smcd_buf_detach(conn);
 	} else {
 		smc_cdc_wait_pend_tx_wr(conn);
 	}

-- 
2.55.0

