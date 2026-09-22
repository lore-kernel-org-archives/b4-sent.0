From: Kim Wooseok <5mghybrid@khu.ac.kr>
Date: Tue, 22 Sep 2026 18:10:52 +0900
Subject: [PATCH net-next 4/4] net: macb: Clear SRTSM outside PTPv2 receive
 filters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260922-codex-macb-hwtstamp-submit-v1-4-9d1abaa53296@khu.ac.kr>
References: <20260922-codex-macb-hwtstamp-submit-v1-0-9d1abaa53296@khu.ac.kr>
In-Reply-To: <20260922-codex-macb-hwtstamp-submit-v1-0-9d1abaa53296@khu.ac.kr>
To: netdev@vger.kernel.org, 
 =?utf-8?q?Th=C3=A9o_Lebrun?= <theo.lebrun@bootlin.com>, 
 Rafal Ozieblo <rafalo@cadence.com>
Cc: Conor Dooley <conor.dooley@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Nicolai Buchwitz <nb@tipi-net.de>, linux-kernel@vger.kernel.org, 
 Kim Wooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790068248; l=1561;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=JVParaFvYlI5ctrTvZ9cMHt5duuXvX87rDYRzFSFD6M=;
 b=yDHkKLNMdhwfr3PA1TyM75Ir9TcFgbgFsB/o4BCDOc8MqWYVha0PilBgnXwLJns4E73h94EX3
 +fjSqn/T49bCh9oXBIX5oEgOWeyZ0FngClcGGVDyamGc+VRMngrpppe
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A PTPv2 receive filter sets NCR.SRTSM, but switching to NONE, ALL or a
PTPv1 filter leaves it set. As a result, selecting the same filter can
produce a different register setting depending on whether PTPv2 was
used before.

Update SRTSM whenever the RX filter changes, setting it only for PTPv2.
Switching away from PTPv2 then clears the old setting, so the bit follows
the currently selected filter.

Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
 drivers/net/ethernet/cadence/macb_ptp.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/cadence/macb_ptp.c b/drivers/net/ethernet/cadence/macb_ptp.c
index 6376b6631..637d0da32 100644
--- a/drivers/net/ethernet/cadence/macb_ptp.c
+++ b/drivers/net/ethernet/cadence/macb_ptp.c
@@ -390,7 +390,7 @@ int gem_set_hwtst(struct net_device *netdev,
 		  struct kernel_hwtstamp_config *tstamp_config,
 		  struct netlink_ext_ack *extack)
 {
-	u32 ncr_mask = MACB_BIT(OSSMODE);
+	u32 ncr_mask = MACB_BIT(OSSMODE) | MACB_BIT(SRTSM);
 	enum macb_bd_control tx_bd_control = TSTAMP_DISABLED;
 	enum macb_bd_control rx_bd_control = TSTAMP_DISABLED;
 	int rx_filter = tstamp_config->rx_filter;
@@ -429,7 +429,6 @@ int gem_set_hwtst(struct net_device *netdev,
 	case HWTSTAMP_FILTER_PTP_V2_L4_DELAY_REQ:
 		rx_bd_control = TSTAMP_ALL_PTP_FRAMES;
 		rx_filter = HWTSTAMP_FILTER_PTP_V2_EVENT;
-		ncr_mask |= MACB_BIT(SRTSM);
 		ncr_bits |= MACB_BIT(SRTSM);
 		break;
 	case HWTSTAMP_FILTER_PTP_V1_L4_SYNC:

-- 
2.53.0

