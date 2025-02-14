From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Fri, 14 Feb 2025 15:14:11 +0100
Subject: [PATCH net-next v5 3/3] net: phy: dp83822: Add support for
 changing the transmit amplitude voltage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250214-dp83822-tx-swing-v5-3-02ca72620599@liebherr.com>
References: <20250214-dp83822-tx-swing-v5-0-02ca72620599@liebherr.com>
In-Reply-To: <20250214-dp83822-tx-swing-v5-0-02ca72620599@liebherr.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739542465; l=3488;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=Or6PDXKPMq4kk1AHxpqPQpxSNSkTyzooFMkd9jkPUKk=;
 b=WVZP1AGB+0WKyM2keetZIyKR2MJ5QQffba06je+G7obuCNMafoggYpuEJfP6BkMf7viovLvSl
 Bz2qj6R74dWBe3FDQ3ZIy6c5+QDQRXv06FQkJPJYoGrIzEU7BT6jGGV
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for changing the transmit amplitude voltage in 100BASE-TX mode.
Modifying it can be necessary to compensate losses on the PCB and
connector, so the voltages measured on the RJ45 pins are conforming.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/dp83822.c | 38 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/drivers/net/phy/dp83822.c b/drivers/net/phy/dp83822.c
index 6599feca1967d705331d6e354205a2485ea962f2..3662f3905d5ade8ad933608fcaeabb714a588418 100644
--- a/drivers/net/phy/dp83822.c
+++ b/drivers/net/phy/dp83822.c
@@ -31,6 +31,7 @@
 #define MII_DP83822_RCSR	0x17
 #define MII_DP83822_RESET_CTRL	0x1f
 #define MII_DP83822_MLEDCR	0x25
+#define MII_DP83822_LDCTRL	0x403
 #define MII_DP83822_LEDCFG1	0x460
 #define MII_DP83822_IOCTRL1	0x462
 #define MII_DP83822_IOCTRL2	0x463
@@ -123,6 +124,9 @@
 #define DP83822_IOCTRL1_GPIO1_CTRL		GENMASK(2, 0)
 #define DP83822_IOCTRL1_GPIO1_CTRL_LED_1	BIT(0)
 
+/* LDCTRL bits */
+#define DP83822_100BASE_TX_LINE_DRIVER_SWING	GENMASK(7, 4)
+
 /* IOCTRL2 bits */
 #define DP83822_IOCTRL2_GPIO2_CLK_SRC		GENMASK(6, 4)
 #define DP83822_IOCTRL2_GPIO2_CTRL		GENMASK(2, 0)
@@ -197,6 +201,7 @@ struct dp83822_private {
 	bool set_gpio2_clk_out;
 	u32 gpio2_clk_out;
 	bool led_pin_enable[DP83822_MAX_LED_PINS];
+	int tx_amplitude_100base_tx_index;
 };
 
 static int dp83822_config_wol(struct phy_device *phydev,
@@ -522,6 +527,12 @@ static int dp83822_config_init(struct phy_device *phydev)
 			       FIELD_PREP(DP83822_IOCTRL2_GPIO2_CLK_SRC,
 					  dp83822->gpio2_clk_out));
 
+	if (dp83822->tx_amplitude_100base_tx_index >= 0)
+		phy_modify_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_LDCTRL,
+			       DP83822_100BASE_TX_LINE_DRIVER_SWING,
+			       FIELD_PREP(DP83822_100BASE_TX_LINE_DRIVER_SWING,
+					  dp83822->tx_amplitude_100base_tx_index));
+
 	err = dp83822_config_init_leds(phydev);
 	if (err)
 		return err;
@@ -720,6 +731,11 @@ static int dp83822_phy_reset(struct phy_device *phydev)
 }
 
 #ifdef CONFIG_OF_MDIO
+static const u32 tx_amplitude_100base_tx_gain[] = {
+	80, 82, 83, 85, 87, 88, 90, 92,
+	93, 95, 97, 98, 100, 102, 103, 105,
+};
+
 static int dp83822_of_init_leds(struct phy_device *phydev)
 {
 	struct device_node *node = phydev->mdio.dev.of_node;
@@ -780,6 +796,8 @@ static int dp83822_of_init(struct phy_device *phydev)
 	struct dp83822_private *dp83822 = phydev->priv;
 	struct device *dev = &phydev->mdio.dev;
 	const char *of_val;
+	int i, ret;
+	u32 val;
 
 	/* Signal detection for the PHY is only enabled if the FX_EN and the
 	 * SD_EN pins are strapped. Signal detection can only enabled if FX_EN
@@ -815,6 +833,26 @@ static int dp83822_of_init(struct phy_device *phydev)
 		dp83822->set_gpio2_clk_out = true;
 	}
 
+	dp83822->tx_amplitude_100base_tx_index = -1;
+	ret = phy_get_tx_amplitude_gain(phydev, dev,
+					ETHTOOL_LINK_MODE_100baseT_Full_BIT,
+					&val);
+	if (!ret) {
+		for (i = 0; i < ARRAY_SIZE(tx_amplitude_100base_tx_gain); i++) {
+			if (tx_amplitude_100base_tx_gain[i] == val) {
+				dp83822->tx_amplitude_100base_tx_index = i;
+				break;
+			}
+		}
+
+		if (dp83822->tx_amplitude_100base_tx_index < 0) {
+			phydev_err(phydev,
+				   "Invalid value for tx-amplitude-100base-tx-percent property (%u)\n",
+				   val);
+			return -EINVAL;
+		}
+	}
+
 	return dp83822_of_init_leds(phydev);
 }
 

-- 
2.39.5

