From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Tue, 11 Feb 2025 09:33:48 +0100
Subject: [PATCH net-next v4 2/3] net: phy: Add helper for getting tx
 amplitude gain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250211-dp83822-tx-swing-v4-2-1e8ebd71ad54@liebherr.com>
References: <20250211-dp83822-tx-swing-v4-0-1e8ebd71ad54@liebherr.com>
In-Reply-To: <20250211-dp83822-tx-swing-v4-0-1e8ebd71ad54@liebherr.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739262831; l=4168;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=rkHlk2CzqTSrJQGoCX2wMldHNiCaKztaZdt09yvcqgc=;
 b=VQd9j96AQ8kCorAnx+eg2QTWTonJS6mQjcf2v8Tmb4zGeSpUidKooO25OiaBB0mR7o8Z/sCjP
 ul6iejQkwIiCjY0pVRMCFDmvf2B76U1H60PNiB4DhhY7ab6UClLCbbA
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add helper which returns the tx amplitude gain defined in device tree.
Modifying it can be necessary to compensate losses on the PCB and
connector, so the voltages measured on the RJ45 pins are conforming.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/phy_device.c | 44 ++++++++++++++++++++++++++------------------
 include/linux/phy.h          |  4 ++++
 2 files changed, 30 insertions(+), 18 deletions(-)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 46713d27412b76077d2e51e29b8d84f4f8f0a86d..25ee085816b711c8a90ebf93001d892488935575 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -3096,19 +3096,12 @@ void phy_get_pause(struct phy_device *phydev, bool *tx_pause, bool *rx_pause)
 EXPORT_SYMBOL(phy_get_pause);
 
 #if IS_ENABLED(CONFIG_OF_MDIO)
-static int phy_get_int_delay_property(struct device *dev, const char *name)
+static int phy_get_u32_property(struct device *dev, const char *name, u32 *val)
 {
-	s32 int_delay;
-	int ret;
-
-	ret = device_property_read_u32(dev, name, &int_delay);
-	if (ret)
-		return ret;
-
-	return int_delay;
+	return device_property_read_u32(dev, name, val);
 }
 #else
-static int phy_get_int_delay_property(struct device *dev, const char *name)
+static int phy_get_u32_property(struct device *dev, const char *name, u32 *val)
 {
 	return -EINVAL;
 }
@@ -3133,12 +3126,12 @@ static int phy_get_int_delay_property(struct device *dev, const char *name)
 s32 phy_get_internal_delay(struct phy_device *phydev, struct device *dev,
 			   const int *delay_values, int size, bool is_rx)
 {
-	s32 delay;
-	int i;
+	u32 delay;
+	int i, ret;
 
 	if (is_rx) {
-		delay = phy_get_int_delay_property(dev, "rx-internal-delay-ps");
-		if (delay < 0 && size == 0) {
+		ret = phy_get_u32_property(dev, "rx-internal-delay-ps", &delay);
+		if (ret < 0 && size == 0) {
 			if (phydev->interface == PHY_INTERFACE_MODE_RGMII_ID ||
 			    phydev->interface == PHY_INTERFACE_MODE_RGMII_RXID)
 				return 1;
@@ -3147,8 +3140,8 @@ s32 phy_get_internal_delay(struct phy_device *phydev, struct device *dev,
 		}
 
 	} else {
-		delay = phy_get_int_delay_property(dev, "tx-internal-delay-ps");
-		if (delay < 0 && size == 0) {
+		ret = phy_get_u32_property(dev, "tx-internal-delay-ps", &delay);
+		if (ret < 0 && size == 0) {
 			if (phydev->interface == PHY_INTERFACE_MODE_RGMII_ID ||
 			    phydev->interface == PHY_INTERFACE_MODE_RGMII_TXID)
 				return 1;
@@ -3157,8 +3150,8 @@ s32 phy_get_internal_delay(struct phy_device *phydev, struct device *dev,
 		}
 	}
 
-	if (delay < 0)
-		return delay;
+	if (ret < 0)
+		return ret;
 
 	if (size == 0)
 		return delay;
@@ -3193,6 +3186,21 @@ s32 phy_get_internal_delay(struct phy_device *phydev, struct device *dev,
 }
 EXPORT_SYMBOL(phy_get_internal_delay);
 
+int phy_get_tx_amplitude_gain(struct phy_device *phydev, struct device *dev,
+			      enum ethtool_link_mode_bit_indices linkmode,
+			      u32 *val)
+{
+	switch (linkmode) {
+	case ETHTOOL_LINK_MODE_100baseT_Full_BIT:
+		return phy_get_u32_property(dev,
+					    "tx-amplitude-100base-tx-percent",
+					    val);
+	default:
+		return -EINVAL;
+	}
+}
+EXPORT_SYMBOL(phy_get_tx_amplitude_gain);
+
 static int phy_led_set_brightness(struct led_classdev *led_cdev,
 				  enum led_brightness value)
 {
diff --git a/include/linux/phy.h b/include/linux/phy.h
index 19f076a71f9462cd37588a5da240a1d54df0fe0f..7c9da26145d30e6659bf6c664e77a63b5d668a5c 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -2114,6 +2114,10 @@ void phy_get_pause(struct phy_device *phydev, bool *tx_pause, bool *rx_pause);
 s32 phy_get_internal_delay(struct phy_device *phydev, struct device *dev,
 			   const int *delay_values, int size, bool is_rx);
 
+int phy_get_tx_amplitude_gain(struct phy_device *phydev, struct device *dev,
+			      enum ethtool_link_mode_bit_indices linkmode,
+			      u32 *val);
+
 void phy_resolve_pause(unsigned long *local_adv, unsigned long *partner_adv,
 		       bool *tx_pause, bool *rx_pause);
 

-- 
2.39.5

