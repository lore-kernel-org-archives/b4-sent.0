From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Thu, 12 Dec 2024 09:44:07 +0100
Subject: [PATCH net-next v3 2/2] net: phy: dp83822: Add support for GPIO2
 clock output
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241212-dp83822-gpio2-clk-out-v3-2-e4af23490f44@liebherr.com>
References: <20241212-dp83822-gpio2-clk-out-v3-0-e4af23490f44@liebherr.com>
In-Reply-To: <20241212-dp83822-gpio2-clk-out-v3-0-e4af23490f44@liebherr.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733993055; l=3688;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=8vNC532plUP4IGqLwiYlEq3xWmFx4qwBlb44h2NCtjU=;
 b=H0BtmX5BYZhsh3jBWob2FmLYnNpPWjJQvO+YL2bnCAL1YocLdEAo65UsDEOoEK5ZYYQJMtK85
 tKih3uXcaMyDOW0PikNMliMYKI17ldxDc/YXBPMvnJTe8l21dso5Mvy
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPIO2 pin on the DP83822 can be configured as clock output. Add support
for configuration via DT.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/dp83822.c | 48 +++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/drivers/net/phy/dp83822.c b/drivers/net/phy/dp83822.c
index 25ee09c48027c86b7d8f4acb5cbe2e157c56a85a..334c17a68edd7c2a0f707b3ccafaa7a870818fbe 100644
--- a/drivers/net/phy/dp83822.c
+++ b/drivers/net/phy/dp83822.c
@@ -30,6 +30,7 @@
 #define MII_DP83822_FCSCR	0x14
 #define MII_DP83822_RCSR	0x17
 #define MII_DP83822_RESET_CTRL	0x1f
+#define MII_DP83822_IOCTRL2	0x463
 #define MII_DP83822_GENCFG	0x465
 #define MII_DP83822_SOR1	0x467
 
@@ -104,6 +105,18 @@
 #define DP83822_RX_CLK_SHIFT	BIT(12)
 #define DP83822_TX_CLK_SHIFT	BIT(11)
 
+/* IOCTRL2 bits */
+#define DP83822_IOCTRL2_GPIO2_CLK_SRC		GENMASK(6, 4)
+#define DP83822_IOCTRL2_GPIO2_CTRL		GENMASK(2, 0)
+#define DP83822_IOCTRL2_GPIO2_CTRL_CLK_REF	GENMASK(1, 0)
+
+#define DP83822_CLK_SRC_MAC_IF			0x0
+#define DP83822_CLK_SRC_XI			0x1
+#define DP83822_CLK_SRC_INT_REF			0x2
+#define DP83822_CLK_SRC_RMII_MASTER_MODE_REF	0x4
+#define DP83822_CLK_SRC_FREE_RUNNING		0x6
+#define DP83822_CLK_SRC_RECOVERED		0x7
+
 /* SOR1 mode */
 #define DP83822_STRAP_MODE1	0
 #define DP83822_STRAP_MODE2	BIT(0)
@@ -139,6 +152,8 @@ struct dp83822_private {
 	u8 cfg_dac_minus;
 	u8 cfg_dac_plus;
 	struct ethtool_wolinfo wol;
+	bool set_gpio2_clk_out;
+	u32 gpio2_clk_out;
 };
 
 static int dp83822_config_wol(struct phy_device *phydev,
@@ -413,6 +428,15 @@ static int dp83822_config_init(struct phy_device *phydev)
 	int err = 0;
 	int bmcr;
 
+	if (dp83822->set_gpio2_clk_out)
+		phy_modify_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_IOCTRL2,
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
@@ -611,6 +635,7 @@ static int dp83822_of_init(struct phy_device *phydev)
 {
 	struct dp83822_private *dp83822 = phydev->priv;
 	struct device *dev = &phydev->mdio.dev;
+	const char *of_val;
 
 	/* Signal detection for the PHY is only enabled if the FX_EN and the
 	 * SD_EN pins are strapped. Signal detection can only enabled if FX_EN
@@ -623,6 +648,29 @@ static int dp83822_of_init(struct phy_device *phydev)
 		dp83822->fx_enabled = device_property_present(dev,
 							      "ti,fiber-mode");
 
+	if (!device_property_read_string(dev, "ti,gpio2-clk-out", &of_val)) {
+		if (strcmp(of_val, "mac-if") == 0) {
+			dp83822->gpio2_clk_out = DP83822_CLK_SRC_MAC_IF;
+		} else if (strcmp(of_val, "xi") == 0) {
+			dp83822->gpio2_clk_out = DP83822_CLK_SRC_XI;
+		} else if (strcmp(of_val, "int-ref") == 0) {
+			dp83822->gpio2_clk_out = DP83822_CLK_SRC_INT_REF;
+		} else if (strcmp(of_val, "rmii-master-mode-ref") == 0) {
+			dp83822->gpio2_clk_out = DP83822_CLK_SRC_RMII_MASTER_MODE_REF;
+		} else if (strcmp(of_val, "free-running") == 0) {
+			dp83822->gpio2_clk_out = DP83822_CLK_SRC_FREE_RUNNING;
+		} else if (strcmp(of_val, "recovered") == 0) {
+			dp83822->gpio2_clk_out = DP83822_CLK_SRC_RECOVERED;
+		} else {
+			phydev_err(phydev,
+				   "Invalid value for ti,gpio2-clk-out property (%s)\n",
+				   of_val);
+			return -EINVAL;
+		}
+
+		dp83822->set_gpio2_clk_out = true;
+	}
+
 	return 0;
 }
 

-- 
2.39.5

