From: Daniel Braunwarth <daniel.braunwarth@kuka.com>
Date: Tue, 29 Apr 2025 13:33:37 +0200
Subject: [PATCH net-next v2] net: phy: realtek: Add support for WOL magic
 packet on RTL8211F
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250429-realtek_wol-v2-1-8f84def1ef2c@kuka.com>
X-B4-Tracking: v=1; b=H4sIABC5EGgC/1WNQQrCMBREr1L+2kjz20p05T2kSEh+bGhNShJrp
 eTuhuJGZvUY5s0GkYKlCJdqg0CLjda7AnioQA3SPYhZXRiwxq5usWOB5JRovL/9xE6E2giSQhm
 EspgDGbvuths4SszRmqAvzWBj8uGz3yx8739G8WdcOCvpNDW8OetWiOv4GuVR+Sf0OecvlqjPA
 K8AAAA=
X-Change-ID: 20250425-realtek_wol-6e2df8ea8cf2
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daniel Braunwarth <daniel.braunwarth@kuka.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745926419; l=4645;
 i=daniel.braunwarth@kuka.com; s=20250425; h=from:subject:message-id;
 bh=ChV+u/ks2Uqcp91+NgxHSn2KSL8dX25AcJihbW7i1X8=;
 b=BA5/W37PJ/01mpYTddzw6c/DQFIjmwfcLaa4gaEhNK4XOKB7AwCgRC8N3HZXubbIY2rXgeWr6
 eq7RFbM5sxKD6FOdsJ9K107LG0Yx5ZvNdAKfnOfsT6aAnDmG2yH0MOT
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
Changes in v2:
- Read current WOL configuration from PHY
- Replace magic numbers with defines
- Link to v1: https://lore.kernel.org/r/20250428-realtek_wol-v1-1-15de3139d488@kuka.com
---
 drivers/net/phy/realtek/realtek_main.c | 69 ++++++++++++++++++++++++++++++++++
 1 file changed, 69 insertions(+)

diff --git a/drivers/net/phy/realtek/realtek_main.c b/drivers/net/phy/realtek/realtek_main.c
index 893c824796715a905bab99646a474c3bea95ec11..05c4f4d394a5ff32b43dd51f0bff08f437ad0494 100644
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
@@ -38,6 +39,24 @@
 
 #define RTL8211F_INSR				0x1d
 
+/* RTL8211F WOL interrupt configuration */
+#define RTL8211F_INTBCR_PAGE			0xd40
+#define RTL8211F_INTBCR				0x16
+#define RTL8211F_INTBCR_INTB_PMEB		BIT(5)
+
+/* RTL8211F WOL settings */
+#define RTL8211F_WOL_SETTINGS_PAGE		0xd8a
+#define RTL8211F_WOL_SETTINGS_EVENTS		16
+#define RTL8211F_WOL_EVENT_MAGIC		BIT(12)
+#define RTL8211F_WOL_SETTINGS_STATUS		17
+#define RTL8211F_WOL_STATUS_RESET		(BIT(15) | 0x1fff)
+
+/* RTL8211F Unique phyiscal and multicast address (WOL) */
+#define RTL8211F_PHYSICAL_ADDR_PAGE		0xd8c
+#define RTL8211F_PHYSICAL_ADDR_WORD0		16
+#define RTL8211F_PHYSICAL_ADDR_WORD1		17
+#define RTL8211F_PHYSICAL_ADDR_WORD2		18
+
 #define RTL8211F_LEDCR				0x10
 #define RTL8211F_LEDCR_MODE			BIT(15)
 #define RTL8211F_LEDCR_ACT_TXRX			BIT(4)
@@ -123,6 +142,7 @@ struct rtl821x_priv {
 	u16 phycr2;
 	bool has_phycr2;
 	struct clk *clk;
+	u32 saved_wolopts;
 };
 
 static int rtl821x_read_page(struct phy_device *phydev)
@@ -354,6 +374,53 @@ static irqreturn_t rtl8211f_handle_interrupt(struct phy_device *phydev)
 	return IRQ_HANDLED;
 }
 
+static void rtl8211f_get_wol(struct phy_device *dev, struct ethtool_wolinfo *wol)
+{
+	wol->supported = WAKE_MAGIC;
+	if (phy_read_paged(dev, RTL8211F_WOL_SETTINGS_PAGE, RTL8211F_WOL_SETTINGS_EVENTS)
+	    & RTL8211F_WOL_EVENT_MAGIC)
+		wol->wolopts = WAKE_MAGIC;
+}
+
+static int rtl8211f_set_wol(struct phy_device *dev, struct ethtool_wolinfo *wol)
+{
+	const u8 *mac_addr = dev->attached_dev->dev_addr;
+	int oldpage;
+
+	oldpage = phy_save_page(dev);
+	if (oldpage < 0)
+		goto err;
+
+	if (wol->wolopts & WAKE_MAGIC) {
+		/* Store the device address for the magic packet */
+		rtl821x_write_page(dev, RTL8211F_PHYSICAL_ADDR_PAGE);
+		__phy_write(dev, RTL8211F_PHYSICAL_ADDR_WORD0, mac_addr[1] << 8 | (mac_addr[0]));
+		__phy_write(dev, RTL8211F_PHYSICAL_ADDR_WORD1, mac_addr[3] << 8 | (mac_addr[2]));
+		__phy_write(dev, RTL8211F_PHYSICAL_ADDR_WORD2, mac_addr[5] << 8 | (mac_addr[4]));
+
+		/* Enable magic packet matching and reset WOL status */
+		rtl821x_write_page(dev, RTL8211F_WOL_SETTINGS_PAGE);
+		__phy_write(dev, RTL8211F_WOL_SETTINGS_EVENTS, RTL8211F_WOL_EVENT_MAGIC);
+		__phy_write(dev, RTL8211F_WOL_SETTINGS_STATUS, RTL8211F_WOL_STATUS_RESET);
+
+		/* Enable the WOL interrupt */
+		rtl821x_write_page(dev, RTL8211F_INTBCR_PAGE);
+		__phy_set_bits(dev, RTL8211F_INTBCR, RTL8211F_INTBCR_INTB_PMEB);
+	} else {
+		/* Disable the WOL interrupt */
+		rtl821x_write_page(dev, RTL8211F_INTBCR_PAGE);
+		__phy_clear_bits(dev, RTL8211F_INTBCR, RTL8211F_INTBCR_INTB_PMEB);
+
+		/* Disable magic packet matching and reset WOL status */
+		rtl821x_write_page(dev, RTL8211F_WOL_SETTINGS_PAGE);
+		__phy_write(dev, RTL8211F_WOL_SETTINGS_EVENTS, 0);
+		__phy_write(dev, RTL8211F_WOL_SETTINGS_STATUS, RTL8211F_WOL_STATUS_RESET);
+	}
+
+err:
+	return phy_restore_page(dev, oldpage, 0);
+}
+
 static int rtl8211_config_aneg(struct phy_device *phydev)
 {
 	int ret;
@@ -1400,6 +1467,8 @@ static struct phy_driver realtek_drvs[] = {
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

