From: Daniel Braunwarth <daniel.braunwarth@kuka.com>
Date: Mon, 28 Apr 2025 09:09:07 +0200
Subject: [PATCH net-next] net: phy: realtek: Add support for WOL magic
 packet on RTL8211F
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250428-realtek_wol-v1-1-15de3139d488@kuka.com>
X-B4-Tracking: v=1; b=H4sIAJMpD2gC/x3M0QpAMBSH8VfRubbihORVJC3+40SjbbGSd7dc/
 i6+7yEPJ/DUZQ85XOLlsAllntG0artAyZxMXHBdVFwrB70HbON97KoBz6aFbifDlIrTwUj8bz1
 ZBGURAw3v+wGUun0/ZwAAAA==
X-Change-ID: 20250425-realtek_wol-6e2df8ea8cf2
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daniel Braunwarth <daniel.braunwarth@kuka.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745824177; l=3620;
 i=daniel.braunwarth@kuka.com; s=20250425; h=from:subject:message-id;
 bh=gwVptqcSBToB7LxapLAcdpkwFvRzQXaqfiCXknN+ioA=;
 b=aAVHeljm7rXfuaeD+CRsjGEUjPEMIKxdF078yC+p/gTJpu9UzyKz9FJhSpwdFUf4Ohq7SUQb3
 nXyrXk0y3ToC6k5LKYsG77hr67h8Qllu1iHiLVFlb5OJwemO1LoCIN/
X-Developer-Key: i=daniel.braunwarth@kuka.com; a=ed25519;
 pk=fTSYKvKU5SCGGLHVz5NaznQ2MbXNWUZzdqPihgCfYms=
X-Endpoint-Received: by B4 Relay for daniel.braunwarth@kuka.com/20250425 with auth_id=388
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RTL8211F supports multiple WOL modes. This patch adds support for
magic packets.

The PHY notifies the system via the INTB/PMEB pin when a WOL event
occurs.

Signed-off-by: Daniel Braunwarth <daniel.braunwarth@kuka.com>
---
 drivers/net/phy/realtek/realtek_main.c | 58 ++++++++++++++++++++++++++++++++++
 1 file changed, 58 insertions(+)

diff --git a/drivers/net/phy/realtek/realtek_main.c b/drivers/net/phy/realtek/realtek_main.c
index 893c824796715a905bab99646a474c3bea95ec11..ed2fd6a0d7466e9638ab988efb03934556f52794 100644
--- a/drivers/net/phy/realtek/realtek_main.c
+++ b/drivers/net/phy/realtek/realtek_main.c
@@ -10,6 +10,7 @@
 #include <linux/bitops.h>
 #include <linux/of.h>
 #include <linux/phy.h>
+#include <linux/netdevice.h>
 #include <linux/module.h>
 #include <linux/delay.h>
 #include <linux/clk.h>
@@ -38,6 +39,10 @@
 
 #define RTL8211F_INSR				0x1d
 
+#define RTL8211F_WOL_MAGIC			BIT(12)
+#define RTL8211F_WOL_CLEAR			(BIT(15) | 0x1fff)
+#define RTL8211F_WOL_INT_ENABLE			BIT(5)
+
 #define RTL8211F_LEDCR				0x10
 #define RTL8211F_LEDCR_MODE			BIT(15)
 #define RTL8211F_LEDCR_ACT_TXRX			BIT(4)
@@ -123,6 +128,7 @@ struct rtl821x_priv {
 	u16 phycr2;
 	bool has_phycr2;
 	struct clk *clk;
+	u32 saved_wolopts;
 };
 
 static int rtl821x_read_page(struct phy_device *phydev)
@@ -354,6 +360,56 @@ static irqreturn_t rtl8211f_handle_interrupt(struct phy_device *phydev)
 	return IRQ_HANDLED;
 }
 
+static void rtl8211f_get_wol(struct phy_device *dev, struct ethtool_wolinfo *wol)
+{
+	struct rtl821x_priv *priv = dev->priv;
+
+	wol->supported = WAKE_MAGIC;
+	wol->wolopts = priv->saved_wolopts;
+}
+
+static int rtl8211f_set_wol(struct phy_device *dev, struct ethtool_wolinfo *wol)
+{
+	struct rtl821x_priv *priv = dev->priv;
+	const u8 *mac_addr = dev->attached_dev->dev_addr;
+	int oldpage;
+
+	oldpage = phy_save_page(dev);
+	if (oldpage < 0)
+		goto err;
+
+	if (wol->wolopts & WAKE_MAGIC) {
+		/* Store the device address for the magic packet */
+		rtl821x_write_page(dev, 0xd8c);
+		__phy_write(dev, 16, mac_addr[1] << 8 | (mac_addr[0]));
+		__phy_write(dev, 17, mac_addr[3] << 8 | (mac_addr[2]));
+		__phy_write(dev, 18, mac_addr[5] << 8 | (mac_addr[4]));
+
+		/* Clear WOL status and enable magic packet matching */
+		rtl821x_write_page(dev, 0xd8a);
+		__phy_write(dev, 16, RTL8211F_WOL_MAGIC);
+		__phy_write(dev, 17, RTL8211F_WOL_CLEAR);
+
+		/* Enable the WOL interrupt */
+		rtl821x_write_page(dev, 0xd40);
+		__phy_set_bits(dev, 0x16, RTL8211F_WOL_INT_ENABLE);
+	} else {
+		/* Disable the WOL interrupt */
+		rtl821x_write_page(dev, 0xd40);
+		__phy_clear_bits(dev, 0x16, RTL8211F_WOL_INT_ENABLE);
+
+		/* Clear WOL status and disable magic packet matching */
+		rtl821x_write_page(dev, 0xd8a);
+		__phy_write(dev, 16, 0x0);
+		__phy_write(dev, 17, RTL8211F_WOL_CLEAR);
+	}
+
+	priv->saved_wolopts = wol->wolopts;
+
+err:
+	return phy_restore_page(dev, oldpage, 0);
+}
+
 static int rtl8211_config_aneg(struct phy_device *phydev)
 {
 	int ret;
@@ -1400,6 +1456,8 @@ static struct phy_driver realtek_drvs[] = {
 		.read_status	= rtlgen_read_status,
 		.config_intr	= &rtl8211f_config_intr,
 		.handle_interrupt = rtl8211f_handle_interrupt,
+		.set_wol	= rtl8211f_set_wol,
+		.get_wol	= rtl8211f_get_wol,
 		.suspend	= rtl821x_suspend,
 		.resume		= rtl821x_resume,
 		.read_page	= rtl821x_read_page,

---
base-commit: 4acf6d4f6afc3478753e49c495132619667549d9
change-id: 20250425-realtek_wol-6e2df8ea8cf2

Best regards,
-- 
Daniel Braunwarth <daniel.braunwarth@kuka.com>

