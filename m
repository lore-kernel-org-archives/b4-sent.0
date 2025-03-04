From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Tue, 04 Mar 2025 19:37:27 +0100
Subject: [PATCH net-next v2 2/2] net: phy: tja11xx: enable PHY in sleep
 mode for TJA1102S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-tja1102s-support-v2-2-cd3e61ab920f@liebherr.com>
References: <20250304-tja1102s-support-v2-0-cd3e61ab920f@liebherr.com>
In-Reply-To: <20250304-tja1102s-support-v2-0-cd3e61ab920f@liebherr.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, Marek Vasut <marex@denx.de>, 
 Oleksij Rempel <o.rempel@pengutronix.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741113448; l=1700;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=DWnLX8up0ewgoQK/chnywysY6pNuZir0wY9kYTPFSC8=;
 b=Pe8Mg7UQFFHMEDej+r44aZcmqA5f+skjcS/S5M6mcZnkLLmh1yvcNMQd66xMM9h+9lMwZ8B4i
 aJ7cBieHtiMDdKw9SYpsrW+6oxvhxJhXJnzKhwhYuD0GKZucyKs9eXU
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Due to pin strapping the PHY maybe disabled per default. TJA1102 devices
can be enabled by setting the PHY_EN bit. Support is provided for TJA1102S
devices but can be easily added for TJA1102 too.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/nxp-tja11xx.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/net/phy/nxp-tja11xx.c b/drivers/net/phy/nxp-tja11xx.c
index 9cf5e6d32fab88cae5cd556623a9ffa285227ab6..601094fe24ca8273a845512b111ccdd9d2785758 100644
--- a/drivers/net/phy/nxp-tja11xx.c
+++ b/drivers/net/phy/nxp-tja11xx.c
@@ -28,6 +28,7 @@
 #define MII_ECTRL_POWER_MODE_MASK	GENMASK(14, 11)
 #define MII_ECTRL_POWER_MODE_NO_CHANGE	(0x0 << 11)
 #define MII_ECTRL_POWER_MODE_NORMAL	(0x3 << 11)
+#define MII_ECTRL_POWER_MODE_SLEEP	(0xa << 11)
 #define MII_ECTRL_POWER_MODE_STANDBY	(0xc << 11)
 #define MII_ECTRL_CABLE_TEST		BIT(5)
 #define MII_ECTRL_CONFIG_EN		BIT(2)
@@ -79,6 +80,9 @@
 #define MII_COMMCFG			27
 #define MII_COMMCFG_AUTO_OP		BIT(15)
 
+#define MII_CFG3			28
+#define MII_CFG3_PHY_EN			BIT(0)
+
 /* Configure REF_CLK as input in RMII mode */
 #define TJA110X_RMII_MODE_REFCLK_IN       BIT(0)
 
@@ -180,6 +184,14 @@ static int tja11xx_wakeup(struct phy_device *phydev)
 			return ret;
 
 		return tja11xx_enable_link_control(phydev);
+	case MII_ECTRL_POWER_MODE_SLEEP:
+		switch (phydev->phy_id & PHY_ID_MASK) {
+		case PHY_ID_TJA1102S:
+			/* Enable PHY, maybe it is disabled due to pin strapping */
+			return phy_set_bits(phydev, MII_CFG3, MII_CFG3_PHY_EN);
+		default:
+			return 0;
+		}
 	default:
 		break;
 	}

-- 
2.39.5

