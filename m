From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 13 Nov 2026 23:14:40 -0500
Subject: [PATCH net 1/4] net/smc: take the socket spinlock across the
 failover cursor switch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-b4-disp-1a9ab9b0-v1-1-4a7c8d85d849@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794629679; l=2185;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=37BN2RSRyNVISAdMhu9n+tShj+W04N891tvq1vKJV+g=;
 b=5LRDNp6vYOhJa6/IMBrS0OG2KlkbSab4J5qV2/36bqF9pkHNS0hXMJhzwQOpBN6jgbZMFuyYY
 4OyNeH447zFBTKsymUsm8DiSeaZsvoMg2k7wgsoheL/FHEe5JYjTOhu
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_switch_cursor() rewrites the send cursors, sndbuf_space and
peer_rmbe_space under send_lock only. smc_cdc_tx_handler() updates
tx_curs_fin, local_tx_ctrl_fin and sndbuf_space, and
smc_cdc_msg_recv_action() updates the peer's consumer cursor and
peer_rmbe_space, under bh_lock_sock(). A CDC completion handled during a
link switch can credit its bytes twice and leave tx_curs_fin ahead of
tx_curs_sent, or leave tx_curs_sent and the producer cursor out of step,
so the resend writes at the wrong RMB offset. A CDC received at the same
time can be counted twice in peer_rmbe_space.

Take bh_lock_sock() around the link change and the cursor switch, in
the order the receive path already uses (the socket spinlock, then
send_lock).

Fixes: c6f02ebeea3a ("net/smc: switch connections to alternate link")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20261029-b4-disp-33001ace-v8-0-f9bb96e17827%40proton.me?part=4
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/smc/smc_core.c | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/net/smc/smc_core.c b/net/smc/smc_core.c
index a3164201c142..73e86100e6db 100644
--- a/net/smc/smc_core.c
+++ b/net/smc/smc_core.c
@@ -1171,11 +1171,18 @@ struct smc_link *smc_switch_conns(struct smc_link_group *lgr,
 		/* pre-fetch buffer outside of send_lock, might sleep */
 		rc = smc_cdc_get_free_slot(conn, to_lnk, &wr_buf, NULL, &pend);
 		if (!rc) {
-			/* avoid race with smcr_tx_sndbuf_nonempty() */
-			spin_lock_bh(&conn->send_lock);
+			/* the CDC completion handler and the receive path
+			 * update the same cursors under the socket's spinlock,
+			 * smcr_tx_sndbuf_nonempty() under send_lock
+			 */
+			local_bh_disable();
+			bh_lock_sock(&smc->sk);
+			spin_lock(&conn->send_lock);
 			smc_switch_link_and_count(conn, to_lnk);
 			rc = smc_switch_cursor(smc, pend, wr_buf);
-			spin_unlock_bh(&conn->send_lock);
+			spin_unlock(&conn->send_lock);
+			bh_unlock_sock(&smc->sk);
+			local_bh_enable();
 		}
 		sock_put(&smc->sk);
 		if (rc)

-- 
2.56.0

