From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 16 Apr 2025 19:14:49 +0200
Subject: [PATCH net-next v3 3/4] net: phy: Add helper for getting MAC
 termination resistance
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-dp83822-mac-impedance-v3-3-028ac426cddb@liebherr.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744823698; l=2028;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=/Fzsr/MDdwggR68hmMYpD2e1XBjCEnFaHjMzV6fLczs=;
 b=CArExZsnBMLPb47XmDpyue2G8JsTUSRt+ct01dNLMn9+fQlppo5ZA3VG3+QSLD9R2bGDNg3zh
 arH3MAWbODaCUlyke20Yqo7v34abi0g/xTIN6zuCPdBPJfsfprSFmvF
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add helper which returns the MAC termination resistance value. Modifying
the resistance to an appropriate value can reduce signal reflections and
therefore improve signal quality.

Reviewed-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/phy_device.c | 15 +++++++++++++++
 include/linux/phy.h          |  3 +++
 2 files changed, 18 insertions(+)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index cc6c209fe702293c25e619899a699a53638f0f66..f85c172c446c56e1da1d13baa18c581f2213dcc5 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -2975,6 +2975,21 @@ int phy_get_tx_amplitude_gain(struct phy_device *phydev, struct device *dev,
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
index fb755358d965b728d502bfc1c0d6e5a6b779f1ef..066a28a4b64b25a7c6033a3bb1e3bc48b20c96dc 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -2040,6 +2040,9 @@ int phy_get_tx_amplitude_gain(struct phy_device *phydev, struct device *dev,
 			      enum ethtool_link_mode_bit_indices linkmode,
 			      u32 *val);
 
+int phy_get_mac_termination(struct phy_device *phydev, struct device *dev,
+			    u32 *val);
+
 void phy_resolve_pause(unsigned long *local_adv, unsigned long *partner_adv,
 		       bool *tx_pause, bool *rx_pause);
 

-- 
2.39.5

