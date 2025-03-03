From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 03 Mar 2025 16:14:37 +0100
Subject: [PATCH 2/2] net: phy: tja11xx: enable PHY in sleep mode for
 TJA1102S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250303-tja1102s-support-v1-2-180e945396e0@liebherr.com>
References: <20250303-tja1102s-support-v1-0-180e945396e0@liebherr.com>
In-Reply-To: <20250303-tja1102s-support-v1-0-180e945396e0@liebherr.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, Marek Vasut <marex@denx.de>, 
 Oleksij Rempel <o.rempel@pengutronix.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741014885; l=1657;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=fBVwJfKA7vzb3FvQIQ+c8V1qrobOuDv18BhKafbdQZE=;
 b=FdXcsDo2MrmnegrJeWJl01AAbNIN2MwO2dE2AqikztnZHnXJ1ZWgENF8egIt/ke00SojEpV3+
 TUBuD61aB5eBIkkczmouE+W/Fmvq7sQ/VtWqMlkvRyA+i6vbVqYln+H
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Due to pin strapping the PHY maybe disabled per default. TJA1102 devices
can be enabled by setting the PHY_EN bit. Support is provided for TJA1102S
devices but can be easily added for TJA1102 too.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/nxp-tja11xx.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/net/phy/nxp-tja11xx.c b/drivers/net/phy/nxp-tja11xx.c
index 8f3bd27b023b5755c223b6769980aad0b76aad89..42a21371c7502a2bd08ae1a9385bf90dfab9105c 100644
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

