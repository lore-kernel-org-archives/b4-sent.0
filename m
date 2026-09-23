From: Kim Wooseok <5mghybrid@khu.ac.kr>
Date: Wed, 23 Sep 2026 18:13:27 +0900
Subject: [PATCH net-next v2 3/3] net: macb: Clear SRTSM outside PTPv2
 receive filters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260923-macb-hwtstamp-rework-v2-3-75c909b2676d@khu.ac.kr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790154804; l=2127;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=WiaT0nCaU15dA1T8GkP2fmhDBGDx/aNqNtDuGkweupA=;
 b=0N7PocSRbYgU05JIYfAPz0pnVoXtFrYkAN3zVWXha3BIC3O+1hbZZA4+qI4C8YWab9iOVP7j1
 YTZqNNYyCEkAoHtH8nPgJTcqrNTndP/jGaGOY1ELzsAnHZgiMKua6vE
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

Reviewed-by: Nicolai Buchwitz <nb@tipi-net.de>
Reviewed-by: Théo Lebrun <theo.lebrun@bootlin.com>
Tested-by: Nicolai Buchwitz <nb@tipi-net.de>
Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
 drivers/net/ethernet/cadence/macb_ptp.c | 11 ++++-------
 1 file changed, 4 insertions(+), 7 deletions(-)

diff --git a/drivers/net/ethernet/cadence/macb_ptp.c b/drivers/net/ethernet/cadence/macb_ptp.c
index af2e36f81..2fd063394 100644
--- a/drivers/net/ethernet/cadence/macb_ptp.c
+++ b/drivers/net/ethernet/cadence/macb_ptp.c
@@ -394,8 +394,8 @@ int gem_set_hwtst(struct net_device *netdev,
 	enum macb_bd_control rx_bd_control = TSTAMP_DISABLED;
 	int rx_filter = tstamp_config->rx_filter;
 	struct macb *bp = netdev_priv(netdev);
+	u32 ncr_mask = MACB_BIT(SRTSM);
 	unsigned long flags;
-	u32 ncr_mask = 0;
 	u32 ncr_bits = 0;
 	u32 regval;
 
@@ -432,7 +432,6 @@ int gem_set_hwtst(struct net_device *netdev,
 	case HWTSTAMP_FILTER_PTP_V2_L4_DELAY_REQ:
 		rx_bd_control = TSTAMP_ALL_PTP_FRAMES;
 		rx_filter = HWTSTAMP_FILTER_PTP_V2_EVENT;
-		ncr_mask |= MACB_BIT(SRTSM);
 		ncr_bits |= MACB_BIT(SRTSM);
 		break;
 	case HWTSTAMP_FILTER_PTP_V1_L4_SYNC:
@@ -447,11 +446,9 @@ int gem_set_hwtst(struct net_device *netdev,
 	}
 
 	spin_lock_irqsave(&bp->lock, flags);
-	if (ncr_mask) {
-		regval = macb_readl(bp, NCR);
-		regval = (regval & ~ncr_mask) | ncr_bits;
-		macb_writel(bp, NCR, regval);
-	}
+	regval = macb_readl(bp, NCR);
+	regval = (regval & ~ncr_mask) | ncr_bits;
+	macb_writel(bp, NCR, regval);
 
 	gem_writel(bp, TXBDCTRL, GEM_BF(TXTSMODE, tx_bd_control));
 	gem_writel(bp, RXBDCTRL, GEM_BF(RXTSMODE, rx_bd_control));

-- 
2.53.0

