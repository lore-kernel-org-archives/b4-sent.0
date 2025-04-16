From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 16 Apr 2025 19:14:50 +0200
Subject: [PATCH net-next v3 4/4] net: phy: dp83822: Add support for
 changing the MAC termination
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-dp83822-mac-impedance-v3-4-028ac426cddb@liebherr.com>
References: <20250416-dp83822-mac-impedance-v3-0-028ac426cddb@liebherr.com>
In-Reply-To: <20250416-dp83822-mac-impedance-v3-0-028ac426cddb@liebherr.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, Andrew Davis <afd@ti.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744823698; l=3207;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=aUB5dQ6e7my0jObP7hS6jVNZ0SSji5tioyizzZyZ9Wo=;
 b=HVfJ/PMe7SX0eZJKufHILN7AgzuaTJja2DNEup344W4GrcWoMxNqv3A7aYOtREJCSY97U8Tdb
 ZkSIfbvU2/tAgWtVHw+Dgdj1LZxOt2tcD9uouwo12ww3xX2Vm/7m9b4
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dp83822 provides the possibility to set the resistance value of the
the MAC termination. Modifying the resistance to an appropriate value can
reduce signal reflections and therefore improve signal quality.

Reviewed-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/dp83822.c | 33 +++++++++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/drivers/net/phy/dp83822.c b/drivers/net/phy/dp83822.c
index 14f36154963841dff98be5af4dfbd2760325c13d..490c9f4e5d4e4dc866ef99f426f7497b5e1b49b4 100644
--- a/drivers/net/phy/dp83822.c
+++ b/drivers/net/phy/dp83822.c
@@ -33,6 +33,7 @@
 #define MII_DP83822_MLEDCR	0x25
 #define MII_DP83822_LDCTRL	0x403
 #define MII_DP83822_LEDCFG1	0x460
+#define MII_DP83822_IOCTRL	0x461
 #define MII_DP83822_IOCTRL1	0x462
 #define MII_DP83822_IOCTRL2	0x463
 #define MII_DP83822_GENCFG	0x465
@@ -118,6 +119,9 @@
 #define DP83822_LEDCFG1_LED1_CTRL	GENMASK(11, 8)
 #define DP83822_LEDCFG1_LED3_CTRL	GENMASK(7, 4)
 
+/* IOCTRL bits */
+#define DP83822_IOCTRL_MAC_IMPEDANCE_CTRL	GENMASK(4, 1)
+
 /* IOCTRL1 bits */
 #define DP83822_IOCTRL1_GPIO3_CTRL		GENMASK(10, 8)
 #define DP83822_IOCTRL1_GPIO3_CTRL_LED3		BIT(0)
@@ -202,6 +206,7 @@ struct dp83822_private {
 	u32 gpio2_clk_out;
 	bool led_pin_enable[DP83822_MAX_LED_PINS];
 	int tx_amplitude_100base_tx_index;
+	int mac_termination_index;
 };
 
 static int dp83822_config_wol(struct phy_device *phydev,
@@ -533,6 +538,12 @@ static int dp83822_config_init(struct phy_device *phydev)
 			       FIELD_PREP(DP83822_100BASE_TX_LINE_DRIVER_SWING,
 					  dp83822->tx_amplitude_100base_tx_index));
 
+	if (dp83822->mac_termination_index >= 0)
+		phy_modify_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_IOCTRL,
+			       DP83822_IOCTRL_MAC_IMPEDANCE_CTRL,
+			       FIELD_PREP(DP83822_IOCTRL_MAC_IMPEDANCE_CTRL,
+					  dp83822->mac_termination_index));
+
 	err = dp83822_config_init_leds(phydev);
 	if (err)
 		return err;
@@ -736,6 +747,10 @@ static const u32 tx_amplitude_100base_tx_gain[] = {
 	93, 95, 97, 98, 100, 102, 103, 105,
 };
 
+static const u32 mac_termination[] = {
+	99, 91, 84, 78, 73, 69, 65, 61, 58, 55, 53, 50, 48, 46, 44, 43,
+};
+
 static int dp83822_of_init_leds(struct phy_device *phydev)
 {
 	struct device_node *node = phydev->mdio.dev.of_node;
@@ -852,6 +867,23 @@ static int dp83822_of_init(struct phy_device *phydev)
 		}
 	}
 
+	ret = phy_get_mac_termination(phydev, dev, &val);
+	if (!ret) {
+		for (i = 0; i < ARRAY_SIZE(mac_termination); i++) {
+			if (mac_termination[i] == val) {
+				dp83822->mac_termination_index = i;
+				break;
+			}
+		}
+
+		if (dp83822->mac_termination_index < 0) {
+			phydev_err(phydev,
+				   "Invalid value for mac-termination-ohms property (%u)\n",
+				   val);
+			return -EINVAL;
+		}
+	}
+
 	return dp83822_of_init_leds(phydev);
 }
 
@@ -931,6 +963,7 @@ static int dp8382x_probe(struct phy_device *phydev)
 		return -ENOMEM;
 
 	dp83822->tx_amplitude_100base_tx_index = -1;
+	dp83822->mac_termination_index = -1;
 	phydev->priv = dp83822;
 
 	return 0;

-- 
2.39.5

