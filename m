From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Fri, 07 Mar 2025 11:30:02 +0100
Subject: [PATCH net-next 2/3] net: phy: Add helper for getting MAC series
 termination resistance
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250307-dp83822-mac-impedance-v1-2-bdd85a759b45@liebherr.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741343404; l=2019;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=WXDkCrvzATPSi65GNE8o3JjF1okiabDROoUJFOca/BU=;
 b=HsvITFP/0xYqQgKZ5aaR6H2UpueG8ibiadZdL3FDAk8+wWN5/uy2FE4Dx4vyvphHrYySYZWeO
 sEprLXq8I/gAy0Fm1Ol8lEjybCBk8GtLY/vikDlo0YyOKbWuZmg+beQ
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add helper which returns the MAC series termination resistance value.
Modifying the resistance to an appropriate value can reduce signal
reflections and therefore improve signal quality.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/phy_device.c | 15 +++++++++++++++
 include/linux/phy.h          |  3 +++
 2 files changed, 18 insertions(+)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index b2d32fbc8c8507f6280e4c3c671466f672c1cc8f..575583aa8b4d49bef796e96059e4f0dd56b351f9 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -2975,6 +2975,21 @@ int phy_get_tx_amplitude_gain(struct phy_device *phydev, struct device *dev,
 }
 EXPORT_SYMBOL_GPL(phy_get_tx_amplitude_gain);
 
+/**
+ * phy_get_mac_series_termination - stores MAC series termination in @val
+ * @phydev: phy_device struct
+ * @dev: pointer to the devices device struct
+ * @val: MAC series termination
+ *
+ * Returns: 0 on success, < 0 on failure
+ */
+int phy_get_mac_series_termination(struct phy_device *phydev,
+				   struct device *dev, u32 *val)
+{
+	return phy_get_u32_property(dev, "mac-series-termination-ohms", val);
+}
+EXPORT_SYMBOL_GPL(phy_get_mac_series_termination);
+
 static int phy_led_set_brightness(struct led_classdev *led_cdev,
 				  enum led_brightness value)
 {
diff --git a/include/linux/phy.h b/include/linux/phy.h
index c4a6385faf41c3156d1a9086eaf5c746640cddbe..633899c4250c91a366849ee0c11d93feec48262f 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -2052,6 +2052,9 @@ int phy_get_tx_amplitude_gain(struct phy_device *phydev, struct device *dev,
 			      enum ethtool_link_mode_bit_indices linkmode,
 			      u32 *val);
 
+int phy_get_mac_series_termination(struct phy_device *phydev,
+				   struct device *dev, u32 *val);
+
 void phy_resolve_pause(unsigned long *local_adv, unsigned long *partner_adv,
 		       bool *tx_pause, bool *rx_pause);
 

-- 
2.39.5

