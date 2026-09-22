From: Kim Wooseok <5mghybrid@khu.ac.kr>
Date: Tue, 22 Sep 2026 18:10:51 +0900
Subject: [PATCH net-next 3/4] net: macb: Disable one-step mode when TX
 timestamping is off
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260922-codex-macb-hwtstamp-submit-v1-3-9d1abaa53296@khu.ac.kr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790068248; l=2010;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=AaQyUqH6VFPMs1/0x+Fd3W9TD7i8rMBiz5TU2m1yxnc=;
 b=IQurmeYA7DFWjdPRj7UfRJHg8TwEQJeTOEO1xUU+9bThz0nVwSi7KxOqUJzNwWxhb9H4P5PQi
 Wc04hm8+RtRBQmK/THGGcmYXqVBPDTHVPh0eO4DTVX4ecXJoxz2Vtj7
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switching from HWTSTAMP_TX_ONESTEP_SYNC to HWTSTAMP_TX_OFF turns off
descriptor timestamping, but leaves NCR.OSSMODE set, so one-step mode
remains enabled.

Update OSSMODE for every accepted TX mode and set it only for
HWTSTAMP_TX_ONESTEP_SYNC. This also clears the previous one-step setting
when switching to OFF. Since the update mask now always includes
OSSMODE, drop the check for an empty mask.

Fixes: ab91f0a9b5f4 ("net: macb: Add hardware PTP support")
Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
 drivers/net/ethernet/cadence/macb_ptp.c | 11 ++++-------
 1 file changed, 4 insertions(+), 7 deletions(-)

diff --git a/drivers/net/ethernet/cadence/macb_ptp.c b/drivers/net/ethernet/cadence/macb_ptp.c
index b6d17fef4..6376b6631 100644
--- a/drivers/net/ethernet/cadence/macb_ptp.c
+++ b/drivers/net/ethernet/cadence/macb_ptp.c
@@ -390,7 +390,7 @@ int gem_set_hwtst(struct net_device *netdev,
 		  struct kernel_hwtstamp_config *tstamp_config,
 		  struct netlink_ext_ack *extack)
 {
-	u32 ncr_mask = 0;
+	u32 ncr_mask = MACB_BIT(OSSMODE);
 	enum macb_bd_control tx_bd_control = TSTAMP_DISABLED;
 	enum macb_bd_control rx_bd_control = TSTAMP_DISABLED;
 	int rx_filter = tstamp_config->rx_filter;
@@ -409,7 +409,6 @@ int gem_set_hwtst(struct net_device *netdev,
 		ncr_bits |= MACB_BIT(OSSMODE);
 		fallthrough;
 	case HWTSTAMP_TX_ON:
-		ncr_mask |= MACB_BIT(OSSMODE);
 		tx_bd_control = TSTAMP_ALL_FRAMES;
 		break;
 	default:
@@ -445,11 +444,9 @@ int gem_set_hwtst(struct net_device *netdev,
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

