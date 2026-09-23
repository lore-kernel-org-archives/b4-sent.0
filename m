From: Kim Wooseok <5mghybrid@khu.ac.kr>
Date: Wed, 23 Sep 2026 18:13:25 +0900
Subject: [PATCH net-next v2 1/3] net: macb: Preserve timestamp settings on
 rejected requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260923-macb-hwtstamp-rework-v2-1-75c909b2676d@khu.ac.kr>
References: <20260923-macb-hwtstamp-rework-v2-0-75c909b2676d@khu.ac.kr>
In-Reply-To: <20260923-macb-hwtstamp-rework-v2-0-75c909b2676d@khu.ac.kr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790154804; l=4775;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=cZ8HFk0QBR/lBfFLhEs1nXctgIhBJl26Kd7OTZMobvU=;
 b=jXR2Hp81kDBB3dOP8irV6q2Rx5YAdBZQMd8sWvVWGMMsBH3D1l8FJBewrR/bxeNt+gKTp8ScO
 85iVRyD56rfBNfyHJSFTrY6bXEzZLx1vUDk2/T94vRxUxJPIi2lfC/4
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gem_set_hwtst() can reject a request after changing the TX one-step
setting, because it programs the TX mode before checking the RX
filter. The call returns -ERANGE, but the hardware may no longer match
the cached configuration.

Validate both settings first and keep the adjusted RX filter local
until validation succeeds. Then apply the register settings and update
the configuration. A rejected request now leaves the hardware, the
caller's settings and the cached configuration unchanged.

Protect the NCR read-modify-write with bp->lock, keeping the descriptor
writes and cache update in the same section. With the register writes
now in the setter, remove gem_ptp_set_one_step_sync() and
gem_ptp_set_ts_mode().

Fixes: ab91f0a9b5f4 ("net: macb: Add hardware PTP support")
Reviewed-by: Nicolai Buchwitz <nb@tipi-net.de>
Reviewed-by: Théo Lebrun <theo.lebrun@bootlin.com>
Tested-by: Nicolai Buchwitz <nb@tipi-net.de>
Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
 drivers/net/ethernet/cadence/macb_ptp.c | 59 ++++++++++++++-------------------
 1 file changed, 25 insertions(+), 34 deletions(-)

diff --git a/drivers/net/ethernet/cadence/macb_ptp.c b/drivers/net/ethernet/cadence/macb_ptp.c
index 14ae57fa0..02face93a 100644
--- a/drivers/net/ethernet/cadence/macb_ptp.c
+++ b/drivers/net/ethernet/cadence/macb_ptp.c
@@ -374,16 +374,6 @@ void gem_ptp_remove(struct net_device *netdev)
 		 GEM_PTP_TIMER_NAME);
 }
 
-static int gem_ptp_set_ts_mode(struct macb *bp,
-			       enum macb_bd_control tx_bd_control,
-			       enum macb_bd_control rx_bd_control)
-{
-	gem_writel(bp, TXBDCTRL, GEM_BF(TXTSMODE, tx_bd_control));
-	gem_writel(bp, RXBDCTRL, GEM_BF(RXTSMODE, rx_bd_control));
-
-	return 0;
-}
-
 int gem_get_hwtst(struct net_device *netdev,
 		  struct kernel_hwtstamp_config *tstamp_config)
 {
@@ -396,25 +386,17 @@ int gem_get_hwtst(struct net_device *netdev,
 	return 0;
 }
 
-static void gem_ptp_set_one_step_sync(struct macb *bp, u8 enable)
-{
-	u32 reg_val;
-
-	reg_val = macb_readl(bp, NCR);
-
-	if (enable)
-		macb_writel(bp, NCR, reg_val | MACB_BIT(OSSMODE));
-	else
-		macb_writel(bp, NCR, reg_val & ~MACB_BIT(OSSMODE));
-}
-
 int gem_set_hwtst(struct net_device *netdev,
 		  struct kernel_hwtstamp_config *tstamp_config,
 		  struct netlink_ext_ack *extack)
 {
 	enum macb_bd_control tx_bd_control = TSTAMP_DISABLED;
 	enum macb_bd_control rx_bd_control = TSTAMP_DISABLED;
+	int rx_filter = tstamp_config->rx_filter;
 	struct macb *bp = netdev_priv(netdev);
+	unsigned long flags;
+	u32 ncr_mask = 0;
+	u32 ncr_bits = 0;
 	u32 regval;
 
 	if (!macb_dma_ptp(bp))
@@ -424,18 +406,19 @@ int gem_set_hwtst(struct net_device *netdev,
 	case HWTSTAMP_TX_OFF:
 		break;
 	case HWTSTAMP_TX_ONESTEP_SYNC:
-		gem_ptp_set_one_step_sync(bp, 1);
+		ncr_bits |= MACB_BIT(OSSMODE);
+		ncr_mask |= MACB_BIT(OSSMODE);
 		tx_bd_control = TSTAMP_ALL_FRAMES;
 		break;
 	case HWTSTAMP_TX_ON:
-		gem_ptp_set_one_step_sync(bp, 0);
+		ncr_mask |= MACB_BIT(OSSMODE);
 		tx_bd_control = TSTAMP_ALL_FRAMES;
 		break;
 	default:
 		return -ERANGE;
 	}
 
-	switch (tstamp_config->rx_filter) {
+	switch (rx_filter) {
 	case HWTSTAMP_FILTER_NONE:
 		break;
 	case HWTSTAMP_FILTER_PTP_V1_L4_SYNC:
@@ -451,25 +434,33 @@ int gem_set_hwtst(struct net_device *netdev,
 	case HWTSTAMP_FILTER_PTP_V2_DELAY_REQ:
 	case HWTSTAMP_FILTER_PTP_V2_L2_DELAY_REQ:
 	case HWTSTAMP_FILTER_PTP_V2_L4_DELAY_REQ:
-		rx_bd_control =  TSTAMP_ALL_PTP_FRAMES;
-		tstamp_config->rx_filter = HWTSTAMP_FILTER_PTP_V2_EVENT;
-		regval = macb_readl(bp, NCR);
-		macb_writel(bp, NCR, (regval | MACB_BIT(SRTSM)));
+		rx_bd_control = TSTAMP_ALL_PTP_FRAMES;
+		rx_filter = HWTSTAMP_FILTER_PTP_V2_EVENT;
+		ncr_mask |= MACB_BIT(SRTSM);
+		ncr_bits |= MACB_BIT(SRTSM);
 		break;
 	case HWTSTAMP_FILTER_PTP_V1_L4_EVENT:
 	case HWTSTAMP_FILTER_ALL:
 		rx_bd_control = TSTAMP_ALL_FRAMES;
-		tstamp_config->rx_filter = HWTSTAMP_FILTER_ALL;
+		rx_filter = HWTSTAMP_FILTER_ALL;
 		break;
 	default:
-		tstamp_config->rx_filter = HWTSTAMP_FILTER_NONE;
 		return -ERANGE;
 	}
 
-	bp->tstamp_config = *tstamp_config;
+	spin_lock_irqsave(&bp->lock, flags);
+	if (ncr_mask) {
+		regval = macb_readl(bp, NCR);
+		regval = (regval & ~ncr_mask) | ncr_bits;
+		macb_writel(bp, NCR, regval);
+	}
 
-	if (gem_ptp_set_ts_mode(bp, tx_bd_control, rx_bd_control) != 0)
-		return -ERANGE;
+	gem_writel(bp, TXBDCTRL, GEM_BF(TXTSMODE, tx_bd_control));
+	gem_writel(bp, RXBDCTRL, GEM_BF(RXTSMODE, rx_bd_control));
+
+	tstamp_config->rx_filter = rx_filter;
+	bp->tstamp_config = *tstamp_config;
+	spin_unlock_irqrestore(&bp->lock, flags);
 
 	return 0;
 }

-- 
2.53.0

