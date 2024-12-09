From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 09 Dec 2024 18:50:42 +0100
Subject: [PATCH net-next] net: phy: dp83822: Replace DP83822_DEVADDR with
 MDIO_MMD_VEND2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241209-dp83822-mdio-mmd-vend2-v1-1-4473c7284b94@liebherr.com>
X-B4-Tracking: v=1; b=H4sIAPEtV2cC/x3MQQqEMAxA0atI1gZqKrR6FXExM4ljFo3Sigji3
 afM8i3+v6FIVikwNjdkObXoZhVd28BnfdlXULkayFHfkRuQ9+gjESbWDVNiPMWYMPoQfHRL798
 BarxnWfT6jycwOdDkOmB+nh8DxbvrcgAAAA==
X-Change-ID: 20241209-dp83822-mdio-mmd-vend2-8377380f43b7
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733766655; l=9020;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=y2zn+L/aWE1Ero8F6H4omU9e4vAI0N/THmMcxqt/cio=;
 b=aplgF5k7dWDI6IDBJarFpSHt9HI3DAtjsQfg4wF+4kPTUgjWolR3JKiP1bVZVQ54EEJ4VMbbk
 YJJj+Wru2anCWf5Msqt1aNjm9yhH9B/W7nal6eeK8r95kS0XYBvRNMs
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of using DP83822_DEVADDR which is locally defined use
MDIO_MMD_VEND2.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/dp83822.c | 58 +++++++++++++++++++++++------------------------
 1 file changed, 28 insertions(+), 30 deletions(-)

diff --git a/drivers/net/phy/dp83822.c b/drivers/net/phy/dp83822.c
index cf8b6d0bfaa9812eee98c612c0d4259d87da7572..25ee09c48027c86b7d8f4acb5cbe2e157c56a85a 100644
--- a/drivers/net/phy/dp83822.c
+++ b/drivers/net/phy/dp83822.c
@@ -22,8 +22,6 @@
 #define DP83826C_PHY_ID		0x2000a130
 #define DP83826NC_PHY_ID	0x2000a110
 
-#define DP83822_DEVADDR		0x1f
-
 #define MII_DP83822_CTRL_2	0x0a
 #define MII_DP83822_PHYSTS	0x10
 #define MII_DP83822_PHYSCR	0x11
@@ -159,14 +157,14 @@ static int dp83822_config_wol(struct phy_device *phydev,
 		/* MAC addresses start with byte 5, but stored in mac[0].
 		 * 822 PHYs store bytes 4|5, 2|3, 0|1
 		 */
-		phy_write_mmd(phydev, DP83822_DEVADDR, MII_DP83822_WOL_DA1,
+		phy_write_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_WOL_DA1,
 			      (mac[1] << 8) | mac[0]);
-		phy_write_mmd(phydev, DP83822_DEVADDR, MII_DP83822_WOL_DA2,
+		phy_write_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_WOL_DA2,
 			      (mac[3] << 8) | mac[2]);
-		phy_write_mmd(phydev, DP83822_DEVADDR, MII_DP83822_WOL_DA3,
+		phy_write_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_WOL_DA3,
 			      (mac[5] << 8) | mac[4]);
 
-		value = phy_read_mmd(phydev, DP83822_DEVADDR,
+		value = phy_read_mmd(phydev, MDIO_MMD_VEND2,
 				     MII_DP83822_WOL_CFG);
 		if (wol->wolopts & WAKE_MAGIC)
 			value |= DP83822_WOL_MAGIC_EN;
@@ -174,13 +172,13 @@ static int dp83822_config_wol(struct phy_device *phydev,
 			value &= ~DP83822_WOL_MAGIC_EN;
 
 		if (wol->wolopts & WAKE_MAGICSECURE) {
-			phy_write_mmd(phydev, DP83822_DEVADDR,
+			phy_write_mmd(phydev, MDIO_MMD_VEND2,
 				      MII_DP83822_RXSOP1,
 				      (wol->sopass[1] << 8) | wol->sopass[0]);
-			phy_write_mmd(phydev, DP83822_DEVADDR,
+			phy_write_mmd(phydev, MDIO_MMD_VEND2,
 				      MII_DP83822_RXSOP2,
 				      (wol->sopass[3] << 8) | wol->sopass[2]);
-			phy_write_mmd(phydev, DP83822_DEVADDR,
+			phy_write_mmd(phydev, MDIO_MMD_VEND2,
 				      MII_DP83822_RXSOP3,
 				      (wol->sopass[5] << 8) | wol->sopass[4]);
 			value |= DP83822_WOL_SECURE_ON;
@@ -194,10 +192,10 @@ static int dp83822_config_wol(struct phy_device *phydev,
 		value |= DP83822_WOL_EN | DP83822_WOL_INDICATION_SEL |
 			 DP83822_WOL_CLR_INDICATION;
 
-		return phy_write_mmd(phydev, DP83822_DEVADDR,
+		return phy_write_mmd(phydev, MDIO_MMD_VEND2,
 				     MII_DP83822_WOL_CFG, value);
 	} else {
-		return phy_clear_bits_mmd(phydev, DP83822_DEVADDR,
+		return phy_clear_bits_mmd(phydev, MDIO_MMD_VEND2,
 					  MII_DP83822_WOL_CFG,
 					  DP83822_WOL_EN |
 					  DP83822_WOL_MAGIC_EN |
@@ -226,23 +224,23 @@ static void dp83822_get_wol(struct phy_device *phydev,
 	wol->supported = (WAKE_MAGIC | WAKE_MAGICSECURE);
 	wol->wolopts = 0;
 
-	value = phy_read_mmd(phydev, DP83822_DEVADDR, MII_DP83822_WOL_CFG);
+	value = phy_read_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_WOL_CFG);
 
 	if (value & DP83822_WOL_MAGIC_EN)
 		wol->wolopts |= WAKE_MAGIC;
 
 	if (value & DP83822_WOL_SECURE_ON) {
-		sopass_val = phy_read_mmd(phydev, DP83822_DEVADDR,
+		sopass_val = phy_read_mmd(phydev, MDIO_MMD_VEND2,
 					  MII_DP83822_RXSOP1);
 		wol->sopass[0] = (sopass_val & 0xff);
 		wol->sopass[1] = (sopass_val >> 8);
 
-		sopass_val = phy_read_mmd(phydev, DP83822_DEVADDR,
+		sopass_val = phy_read_mmd(phydev, MDIO_MMD_VEND2,
 					  MII_DP83822_RXSOP2);
 		wol->sopass[2] = (sopass_val & 0xff);
 		wol->sopass[3] = (sopass_val >> 8);
 
-		sopass_val = phy_read_mmd(phydev, DP83822_DEVADDR,
+		sopass_val = phy_read_mmd(phydev, MDIO_MMD_VEND2,
 					  MII_DP83822_RXSOP3);
 		wol->sopass[4] = (sopass_val & 0xff);
 		wol->sopass[5] = (sopass_val >> 8);
@@ -430,18 +428,18 @@ static int dp83822_config_init(struct phy_device *phydev)
 		if (tx_int_delay <= 0)
 			rgmii_delay |= DP83822_TX_CLK_SHIFT;
 
-		err = phy_modify_mmd(phydev, DP83822_DEVADDR, MII_DP83822_RCSR,
+		err = phy_modify_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_RCSR,
 				     DP83822_RX_CLK_SHIFT | DP83822_TX_CLK_SHIFT, rgmii_delay);
 		if (err)
 			return err;
 
-		err = phy_set_bits_mmd(phydev, DP83822_DEVADDR,
+		err = phy_set_bits_mmd(phydev, MDIO_MMD_VEND2,
 				       MII_DP83822_RCSR, DP83822_RGMII_MODE_EN);
 
 		if (err)
 			return err;
 	} else {
-		err = phy_clear_bits_mmd(phydev, DP83822_DEVADDR,
+		err = phy_clear_bits_mmd(phydev, MDIO_MMD_VEND2,
 					 MII_DP83822_RCSR, DP83822_RGMII_MODE_EN);
 
 		if (err)
@@ -496,7 +494,7 @@ static int dp83822_config_init(struct phy_device *phydev)
 			return err;
 
 		if (dp83822->fx_signal_det_low) {
-			err = phy_set_bits_mmd(phydev, DP83822_DEVADDR,
+			err = phy_set_bits_mmd(phydev, MDIO_MMD_VEND2,
 					       MII_DP83822_GENCFG,
 					       DP83822_SIG_DET_LOW);
 			if (err)
@@ -514,10 +512,10 @@ static int dp8382x_config_rmii_mode(struct phy_device *phydev)
 
 	if (!device_property_read_string(dev, "ti,rmii-mode", &of_val)) {
 		if (strcmp(of_val, "master") == 0) {
-			ret = phy_clear_bits_mmd(phydev, DP83822_DEVADDR, MII_DP83822_RCSR,
+			ret = phy_clear_bits_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_RCSR,
 						 DP83822_RMII_MODE_SEL);
 		} else if (strcmp(of_val, "slave") == 0) {
-			ret = phy_set_bits_mmd(phydev, DP83822_DEVADDR, MII_DP83822_RCSR,
+			ret = phy_set_bits_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_RCSR,
 					       DP83822_RMII_MODE_SEL);
 		} else {
 			phydev_err(phydev, "Invalid value for ti,rmii-mode property (%s)\n",
@@ -539,7 +537,7 @@ static int dp83826_config_init(struct phy_device *phydev)
 	int ret;
 
 	if (phydev->interface == PHY_INTERFACE_MODE_RMII) {
-		ret = phy_set_bits_mmd(phydev, DP83822_DEVADDR, MII_DP83822_RCSR,
+		ret = phy_set_bits_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_RCSR,
 				       DP83822_RMII_MODE_EN);
 		if (ret)
 			return ret;
@@ -548,7 +546,7 @@ static int dp83826_config_init(struct phy_device *phydev)
 		if (ret)
 			return ret;
 	} else {
-		ret = phy_clear_bits_mmd(phydev, DP83822_DEVADDR, MII_DP83822_RCSR,
+		ret = phy_clear_bits_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_RCSR,
 					 DP83822_RMII_MODE_EN);
 		if (ret)
 			return ret;
@@ -560,7 +558,7 @@ static int dp83826_config_init(struct phy_device *phydev)
 				 FIELD_GET(DP83826_CFG_DAC_MINUS_MDIX_5_TO_4,
 					   dp83822->cfg_dac_minus));
 		mask = DP83826_VOD_CFG1_MINUS_MDIX_MASK | DP83826_VOD_CFG1_MINUS_MDI_MASK;
-		ret = phy_modify_mmd(phydev, DP83822_DEVADDR, MII_DP83826_VOD_CFG1, mask, val);
+		ret = phy_modify_mmd(phydev, MDIO_MMD_VEND2, MII_DP83826_VOD_CFG1, mask, val);
 		if (ret)
 			return ret;
 
@@ -568,7 +566,7 @@ static int dp83826_config_init(struct phy_device *phydev)
 				 FIELD_GET(DP83826_CFG_DAC_MINUS_MDIX_3_TO_0,
 					   dp83822->cfg_dac_minus));
 		mask = DP83826_VOD_CFG2_MINUS_MDIX_MASK;
-		ret = phy_modify_mmd(phydev, DP83822_DEVADDR, MII_DP83826_VOD_CFG2, mask, val);
+		ret = phy_modify_mmd(phydev, MDIO_MMD_VEND2, MII_DP83826_VOD_CFG2, mask, val);
 		if (ret)
 			return ret;
 	}
@@ -577,7 +575,7 @@ static int dp83826_config_init(struct phy_device *phydev)
 		val = FIELD_PREP(DP83826_VOD_CFG2_PLUS_MDIX_MASK, dp83822->cfg_dac_plus) |
 		      FIELD_PREP(DP83826_VOD_CFG2_PLUS_MDI_MASK, dp83822->cfg_dac_plus);
 		mask = DP83826_VOD_CFG2_PLUS_MDIX_MASK | DP83826_VOD_CFG2_PLUS_MDI_MASK;
-		ret = phy_modify_mmd(phydev, DP83822_DEVADDR, MII_DP83826_VOD_CFG2, mask, val);
+		ret = phy_modify_mmd(phydev, MDIO_MMD_VEND2, MII_DP83826_VOD_CFG2, mask, val);
 		if (ret)
 			return ret;
 	}
@@ -673,7 +671,7 @@ static int dp83822_read_straps(struct phy_device *phydev)
 	int fx_enabled, fx_sd_enable;
 	int val;
 
-	val = phy_read_mmd(phydev, DP83822_DEVADDR, MII_DP83822_SOR1);
+	val = phy_read_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_SOR1);
 	if (val < 0)
 		return val;
 
@@ -748,7 +746,7 @@ static int dp83822_suspend(struct phy_device *phydev)
 {
 	int value;
 
-	value = phy_read_mmd(phydev, DP83822_DEVADDR, MII_DP83822_WOL_CFG);
+	value = phy_read_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_WOL_CFG);
 
 	if (!(value & DP83822_WOL_EN))
 		genphy_suspend(phydev);
@@ -762,9 +760,9 @@ static int dp83822_resume(struct phy_device *phydev)
 
 	genphy_resume(phydev);
 
-	value = phy_read_mmd(phydev, DP83822_DEVADDR, MII_DP83822_WOL_CFG);
+	value = phy_read_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_WOL_CFG);
 
-	phy_write_mmd(phydev, DP83822_DEVADDR, MII_DP83822_WOL_CFG, value |
+	phy_write_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_WOL_CFG, value |
 		      DP83822_WOL_CLR_INDICATION);
 
 	return 0;

---
base-commit: 6145fefc1e42c1895c0c1c2c8593de2c085d8c56
change-id: 20241209-dp83822-mdio-mmd-vend2-8377380f43b7

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

