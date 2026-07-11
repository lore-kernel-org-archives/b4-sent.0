From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 11 Jul 2026 02:45:05 -0500
Subject: [PATCH net] net/smc: guard the CDC receive path against an unset
 RMB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-b4-disp-c36a9798-v1-1-340b0c6053fb@proton.me>
X-B4-Tracking: v=1; b=H4sIAID0UWoC/x3MQQqAIBBA0avErBtQK82uEi0yx5qNhUYE0d2Tl
 m/x/wOZElOGoXog0cWZ91gg6wqWbY4rIftiUEJpYaRE16LnfODS6Nka26N0Tee8tsEbBSU7EgW
 +/+UIkU6Y3vcDmVyAM2cAAAA=
To: Paolo Abeni <pabeni@redhat.com>, Wen Gu <guwen@linux.alibaba.com>, 
 Eric Dumazet <edumazet@google.com>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Tony Lu <tonylu@linux.alibaba.com>, 
 Dust Li <dust.li@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Jakub Kicinski <kuba@kernel.org>
Cc: netdev@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-s390@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783755904; l=2576;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=yh7714RV6Cc4s3RDFou/eCDussZT7vcBjhLsr4ZeUcM=;
 b=Vuf9mDuj3w2B5nPA+qf5Tbf1h0yrJMdX2RH27z3Uj+NAYdJbs56Ch06TWSEojM/H7bCWfWEJ5
 bO8b2caGqWECB+3WZ4YOTFo63lNPdGDfV3K1ucad2XC0bayn9Jxj1hb
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SMC CDC receive handlers look up a connection by its wire token and
then dereference conn->rmb_desc -- smcd_cdc_rx_tsklet() reads
rmb_desc->cpu_addr and smc_cdc_msg_recv_action() reads rmb_desc->len --
but a connection is published to the link group's token tree in
smc_conn_create(), before smc_buf_create() allocates its RMB.  A peer
that sends a CDC message carrying the connection's token in that setup
window reaches the handlers with conn->rmb_desc still NULL and crashes
the host with a NULL pointer dereference.

Bail out of both receive handlers when the RMB is not yet allocated, as
they already do for a killed or out-of-sync connection.

Closes: https://sashiko.dev/#/patchset/20260705-b4-disp-28a1bbca-v4-1-be089b98acc6@proton.me?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reachability is by source inspection: smc_conn_create() registers the
connection before smc_buf_create() allocates conn->rmb_desc, and the
receive handlers guard only !conn/out_of_sync/killed.  Verified with an
in-kernel KASAN model reproducing the deref with rmb_desc == NULL (fault
at the ->len / ->cpu_addr offsets) and clean with the guard.  af_smc runs
over an RDMA fabric or an ISM device, so this is the model rather than a
live trigger; reproducer available on request.

No Fixes: tag: the CDC receive path predates the history available here;
the introducing commits are the original CDC support and its SMC-D
addition -- please add whichever tag you prefer.
---
 net/smc/smc_cdc.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/net/smc/smc_cdc.c b/net/smc/smc_cdc.c
index 32d6d03df321..d60f68facbc3 100644
--- a/net/smc/smc_cdc.c
+++ b/net/smc/smc_cdc.c
@@ -446,7 +446,7 @@ static void smcd_cdc_rx_tsklet(struct tasklet_struct *t)
 	struct smcd_cdc_msg cdc;
 	struct smc_sock *smc;
 
-	if (!conn || conn->killed)
+	if (!conn || conn->killed || !conn->rmb_desc)
 		return;
 
 	data_cdc = (struct smcd_cdc_msg *)conn->rmb_desc->cpu_addr;
@@ -483,7 +483,7 @@ static void smc_cdc_rx_handler(struct ib_wc *wc, void *buf)
 	lgr = smc_get_lgr(link);
 	read_lock_bh(&lgr->conns_lock);
 	conn = smc_lgr_find_conn(ntohl(cdc->token), lgr);
-	if (!conn || conn->out_of_sync) {
+	if (!conn || conn->out_of_sync || !conn->rmb_desc) {
 		read_unlock_bh(&lgr->conns_lock);
 		return;
 	}

---
base-commit: dd3210c47e8d3ac6b4e9141fc68acc03b38c0ba3
change-id: 20260711-b4-disp-c36a9798-1b35bd69fd72

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

