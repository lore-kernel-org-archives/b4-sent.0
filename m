From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Tue, 08 Apr 2025 09:45:33 +0200
Subject: [PATCH net-next v2 2/3] net: phy: Add helper for getting MAC
 termination resistance
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250408-dp83822-mac-impedance-v2-2-fefeba4a9804@liebherr.com>
References: <20250408-dp83822-mac-impedance-v2-0-fefeba4a9804@liebherr.com>
In-Reply-To: <20250408-dp83822-mac-impedance-v2-0-fefeba4a9804@liebherr.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744098338; l=1963;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=3rPSnMTtXUybCDZzRHxcQdj0rW3ShNxaNA2Hqxzp20o=;
 b=RzeHcv3bxb4pNq+oou9OTP8EPu91EcvX4bUD80IzWFxMsMqw06vIkTHvLevnaltX76Yo2Vzcw
 8eEEn1Yr9/xD5DcfxkUVa3A8JqvCmq0ZyIL6WzTlaMBB1o2McbWVFQf
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add helper which returns the MAC termination resistance value. Modifying
the resistance to an appropriate value can reduce signal reflections and
therefore improve signal quality.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/phy_device.c | 15 +++++++++++++++
 include/linux/phy.h          |  3 +++
 2 files changed, 18 insertions(+)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 675fbd225378796085cdc6c92ee2d7e9bff0b6f6..6bd888a7ad14f0e71670e43cf0dd7ecebc2b23b9 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -2948,6 +2948,21 @@ int phy_get_tx_amplitude_gain(struct phy_device *phydev, struct device *dev,
 }
 EXPORT_SYMBOL_GPL(phy_get_tx_amplitude_gain);
 
+/**
+ * phy_get_mac_termination - stores MAC termination in @val
+ * @phydev: phy_device struct
+ * @dev: pointer to the devices device struct
+ * @val: MAC termination
+ *
+ * Returns: 0 on success, < 0 on failure
+ */
+int phy_get_mac_termination(struct phy_device *phydev, struct device *dev,
+			    u32 *val)
+{
+	return phy_get_u32_property(dev, "mac-termination-ohms", val);
+}
+EXPORT_SYMBOL_GPL(phy_get_mac_termination);
+
 static int phy_led_set_brightness(struct led_classdev *led_cdev,
 				  enum led_brightness value)
 {
diff --git a/include/linux/phy.h b/include/linux/phy.h
index a2bfae80c44975db013760413867cebdf20c8216..63d237763f842e80d04bb534e32cd42110129e41 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -2046,6 +2046,9 @@ int phy_get_tx_amplitude_gain(struct phy_device *phydev, struct device *dev,
 			      enum ethtool_link_mode_bit_indices linkmode,
 			      u32 *val);
 
+int phy_get_mac_termination(struct phy_device *phydev, struct device *dev,
+			    u32 *val);
+
 void phy_resolve_pause(unsigned long *local_adv, unsigned long *partner_adv,
 		       bool *tx_pause, bool *rx_pause);
 

-- 
2.39.5

