From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 09 Dec 2024 09:01:28 +0100
Subject: [PATCH net-next 2/2] net: phy: dp83822: Add support for GPIO2
 clock output
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241209-dp83822-gpio2-clk-out-v1-2-fd3c8af59ff5@liebherr.com>
References: <20241209-dp83822-gpio2-clk-out-v1-0-fd3c8af59ff5@liebherr.com>
In-Reply-To: <20241209-dp83822-gpio2-clk-out-v1-0-fd3c8af59ff5@liebherr.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733731307; l=3387;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=+5oy5JM7MjH9Hc6sWExhve+FSfnhs7DrBAy0XVFi3K0=;
 b=+yNF54o5d7WetSzBSMyi2D3Yu8++eOTV7qlp5Qh6orhx4nd62W0nJAAlri4PPOHUcZxsmkceO
 QNwWYW8By2vCrs8aD5406iLjqMsQX8jcR7VGFbkphVln8vd8VkDIi5z
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPIO2 pin on the DP83822 can be configured as clock output. Add support
for configuration via DT.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/dp83822.c | 44 ++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/drivers/net/phy/dp83822.c b/drivers/net/phy/dp83822.c
index cf8b6d0bfaa9812eee98c612c0d4259d87da7572..2abb066c3b8fe701c551c278ba31a08f9cb3fc15 100644
--- a/drivers/net/phy/dp83822.c
+++ b/drivers/net/phy/dp83822.c
@@ -14,6 +14,8 @@
 #include <linux/netdevice.h>
 #include <linux/bitfield.h>
 
+#include <dt-bindings/net/ti-dp83822.h>
+
 #define DP83822_PHY_ID	        0x2000a240
 #define DP83825S_PHY_ID		0x2000a140
 #define DP83825I_PHY_ID		0x2000a150
@@ -33,6 +35,7 @@
 #define MII_DP83822_RCSR	0x17
 #define MII_DP83822_RESET_CTRL	0x1f
 #define MII_DP83822_GENCFG	0x465
+#define MII_DP83822_IOCTRL2	0x463
 #define MII_DP83822_SOR1	0x467
 
 /* DP83826 specific registers */
@@ -106,6 +109,11 @@
 #define DP83822_RX_CLK_SHIFT	BIT(12)
 #define DP83822_TX_CLK_SHIFT	BIT(11)
 
+/* IOCTRL2 bits */
+#define DP83822_IOCTRL2_GPIO2_CLK_SRC		GENMASK(6, 4)
+#define DP83822_IOCTRL2_GPIO2_CTRL		GENMASK(2, 0)
+#define DP83822_IOCTRL2_GPIO2_CTRL_CLK_REF	GENMASK(1, 0)
+
 /* SOR1 mode */
 #define DP83822_STRAP_MODE1	0
 #define DP83822_STRAP_MODE2	BIT(0)
@@ -141,6 +149,8 @@ struct dp83822_private {
 	u8 cfg_dac_minus;
 	u8 cfg_dac_plus;
 	struct ethtool_wolinfo wol;
+	bool set_gpio2_clk_out;
+	u32 gpio2_clk_out;
 };
 
 static int dp83822_config_wol(struct phy_device *phydev,
@@ -415,6 +425,15 @@ static int dp83822_config_init(struct phy_device *phydev)
 	int err = 0;
 	int bmcr;
 
+	if (dp83822->set_gpio2_clk_out)
+		phy_modify_mmd(phydev, DP83822_DEVADDR, MII_DP83822_IOCTRL2,
+			       DP83822_IOCTRL2_GPIO2_CTRL |
+			       DP83822_IOCTRL2_GPIO2_CLK_SRC,
+			       FIELD_PREP(DP83822_IOCTRL2_GPIO2_CTRL,
+					  DP83822_IOCTRL2_GPIO2_CTRL_CLK_REF) |
+			       FIELD_PREP(DP83822_IOCTRL2_GPIO2_CLK_SRC,
+					  dp83822->gpio2_clk_out));
+
 	if (phy_interface_is_rgmii(phydev)) {
 		rx_int_delay = phy_get_internal_delay(phydev, dev, NULL, 0,
 						      true);
@@ -613,6 +632,7 @@ static int dp83822_of_init(struct phy_device *phydev)
 {
 	struct dp83822_private *dp83822 = phydev->priv;
 	struct device *dev = &phydev->mdio.dev;
+	int ret;
 
 	/* Signal detection for the PHY is only enabled if the FX_EN and the
 	 * SD_EN pins are strapped. Signal detection can only enabled if FX_EN
@@ -625,6 +645,30 @@ static int dp83822_of_init(struct phy_device *phydev)
 		dp83822->fx_enabled = device_property_present(dev,
 							      "ti,fiber-mode");
 
+	ret = of_property_read_u32(dev->of_node, "ti,gpio2-clk-out",
+				   &dp83822->gpio2_clk_out);
+	if (!ret) {
+		dp83822->set_gpio2_clk_out = true;
+		switch (dp83822->gpio2_clk_out) {
+		case DP83822_CLK_SRC_MAC_IF:
+			break;
+		case DP83822_CLK_SRC_XI:
+			break;
+		case DP83822_CLK_SRC_INT_REF:
+			break;
+		case DP83822_CLK_SRC_RMII_MASTER_MODE_REF:
+			break;
+		case DP83822_CLK_SRC_FREE_RUNNING:
+			break;
+		case DP83822_CLK_SRC_RECOVERED:
+			break;
+		default:
+			phydev_err(phydev, "ti,gpio2-clk-out value %u not valid\n",
+				   dp83822->gpio2_clk_out);
+			return -EINVAL;
+		}
+	}
+
 	return 0;
 }
 

-- 
2.39.5

