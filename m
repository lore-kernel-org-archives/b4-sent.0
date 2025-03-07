From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Fri, 07 Mar 2025 11:30:03 +0100
Subject: [PATCH net-next 3/3] net: phy: dp83822: Add support for changing
 the MAC series termination
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250307-dp83822-mac-impedance-v1-3-bdd85a759b45@liebherr.com>
References: <20250307-dp83822-mac-impedance-v1-0-bdd85a759b45@liebherr.com>
In-Reply-To: <20250307-dp83822-mac-impedance-v1-0-bdd85a759b45@liebherr.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741343404; l=3131;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=HGx3jZ3iRbaor8YQ4l/v589zbjDXDV4BuTqPK5lXQCQ=;
 b=6xTTwI4vff9S3WRwowD+chdnuG01Uw6ZeqVP8ZOee20QLpuRK7P8h1jklsmWGlm5Kl1GKGjkZ
 v1SNGmwcxQqCDVBOUb/DCtQ2SjlZx+kZ+aWVKyuZf/u5H7mi875X5AB
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dp83822 provides the possibility to set the resistance value of the
the MAC series termination. Modifying the resistance to an appropriate
value can reduce signal reflections and therefore improve signal quality.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/dp83822.c | 36 ++++++++++++++++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/drivers/net/phy/dp83822.c b/drivers/net/phy/dp83822.c
index 3662f3905d5ade8ad933608fcaeabb714a588418..bd8082cdc00e4abe165ee7c515b252eb32149d45 100644
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
@@ -202,6 +206,8 @@ struct dp83822_private {
 	u32 gpio2_clk_out;
 	bool led_pin_enable[DP83822_MAX_LED_PINS];
 	int tx_amplitude_100base_tx_index;
+	bool mac_series_termination_modify;
+	int mac_series_termination_index;
 };
 
 static int dp83822_config_wol(struct phy_device *phydev,
@@ -533,6 +539,12 @@ static int dp83822_config_init(struct phy_device *phydev)
 			       FIELD_PREP(DP83822_100BASE_TX_LINE_DRIVER_SWING,
 					  dp83822->tx_amplitude_100base_tx_index));
 
+	if (dp83822->mac_series_termination_modify)
+		phy_modify_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_IOCTRL,
+			       DP83822_IOCTRL_MAC_IMPEDANCE_CTRL,
+			       FIELD_PREP(DP83822_IOCTRL_MAC_IMPEDANCE_CTRL,
+					  dp83822->mac_series_termination_index));
+
 	err = dp83822_config_init_leds(phydev);
 	if (err)
 		return err;
@@ -736,6 +748,10 @@ static const u32 tx_amplitude_100base_tx_gain[] = {
 	93, 95, 97, 98, 100, 102, 103, 105,
 };
 
+static const u32 mac_series_termination[] = {
+	99, 91, 84, 78, 73, 69, 65, 61, 58, 55, 53, 50, 48, 46, 44, 43,
+};
+
 static int dp83822_of_init_leds(struct phy_device *phydev)
 {
 	struct device_node *node = phydev->mdio.dev.of_node;
@@ -853,6 +869,26 @@ static int dp83822_of_init(struct phy_device *phydev)
 		}
 	}
 
+	dp83822->mac_series_termination_index = -1;
+	ret = phy_get_mac_series_termination(phydev, dev, &val);
+	if (!ret) {
+		for (i = 0; i < ARRAY_SIZE(mac_series_termination); i++) {
+			if (mac_series_termination[i] == val) {
+				dp83822->mac_series_termination_index = i;
+				break;
+			}
+		}
+
+		if (dp83822->mac_series_termination_index < 0) {
+			phydev_err(phydev,
+				   "Invalid value for mac-series-termination-ohms property (%u)\n",
+				   val);
+			return -EINVAL;
+		}
+
+		dp83822->mac_series_termination_modify = true;
+	}
+
 	return dp83822_of_init_leds(phydev);
 }
 

-- 
2.39.5

