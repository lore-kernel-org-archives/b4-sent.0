From: Hans-Frieder Vogt <hfdevel@gmx.net>
Date: Tue, 18 Mar 2025 23:06:55 +0100
Subject: [PATCH net-next v6 4/7] net: phy: aquantia: add essential
 functions to aqr105 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-tn9510-v3a-v6-4-808a9089d24b@gmx.net>
References: <20250318-tn9510-v3a-v6-0-808a9089d24b@gmx.net>
In-Reply-To: <20250318-tn9510-v3a-v6-0-808a9089d24b@gmx.net>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hans-Frieder Vogt <hfdevel@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742335636; l=8764;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=/eA6SDWVHD3SADXqLt2kQjcqtjSVgIlrVW1BBWTFIvY=;
 b=nnh5GDoVac3ptJYnt9TaGoadUXJB3nRKUZ6IDFTtEf1fp6WmbIjiarTPcCOeUM6majVPhLn7V
 1Csf4ZzIHDTB/wcSPgMlDid6pErGEsLINsA/RMiHjzcKKEHLJeLynaI
X-Developer-Key: i=hfdevel@gmx.net; a=ed25519;
 pk=s3DJ3DFe6BJDRAcnd7VGvvwPXcLgV8mrfbpt8B9coRc=
X-Endpoint-Received: by B4 Relay for hfdevel@gmx.net/20240915 with auth_id=209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch makes functions that were provided for aqr107 applicable to
aqr105, or replaces generic functions with specific ones. Since the aqr105
was introduced before NBASE-T was defined (or 802.3bz), there are a number
of vendor specific registers involved in the definition of the
advertisement, in auto-negotiation and in the setting of the speed. The
functions have been written following the downstream driver for TN4010
cards with aqr105 PHY, and use code from aqr107 functions wherever it
seemed to make sense.

Signed-off-by: Hans-Frieder Vogt <hfdevel@gmx.net>
---
 drivers/net/phy/aquantia/aquantia_main.c | 239 ++++++++++++++++++++++++++++++-
 1 file changed, 237 insertions(+), 2 deletions(-)

diff --git a/drivers/net/phy/aquantia/aquantia_main.c b/drivers/net/phy/aquantia/aquantia_main.c
index 86b0e63de5d88fa1050919a8826bdbec4bbcf8ba..ce479b588a34ff4c705a7c9bf770d8864ea0d77a 100644
--- a/drivers/net/phy/aquantia/aquantia_main.c
+++ b/drivers/net/phy/aquantia/aquantia_main.c
@@ -50,6 +50,7 @@
 #define MDIO_AN_VEND_PROV_1000BASET_HALF	BIT(14)
 #define MDIO_AN_VEND_PROV_5000BASET_FULL	BIT(11)
 #define MDIO_AN_VEND_PROV_2500BASET_FULL	BIT(10)
+#define MDIO_AN_VEND_PROV_EXC_PHYID_INFO	BIT(6)
 #define MDIO_AN_VEND_PROV_DOWNSHIFT_EN		BIT(4)
 #define MDIO_AN_VEND_PROV_DOWNSHIFT_MASK	GENMASK(3, 0)
 #define MDIO_AN_VEND_PROV_DOWNSHIFT_DFLT	4
@@ -333,6 +334,238 @@ static int aqr_read_status(struct phy_device *phydev)
 	return genphy_c45_read_status(phydev);
 }
 
+static int aqr105_get_features(struct phy_device *phydev)
+{
+	int ret;
+
+	/* Normal feature discovery */
+	ret = genphy_c45_pma_read_abilities(phydev);
+	if (ret)
+		return ret;
+
+	/* The AQR105 PHY misses to indicate the 2.5G and 5G modes, so add them
+	 * here
+	 */
+	linkmode_set_bit(ETHTOOL_LINK_MODE_5000baseT_Full_BIT,
+			 phydev->supported);
+	linkmode_set_bit(ETHTOOL_LINK_MODE_2500baseT_Full_BIT,
+			 phydev->supported);
+
+	/* The AQR105 PHY suppports both RJ45 and SFP+ interfaces */
+	linkmode_set_bit(ETHTOOL_LINK_MODE_TP_BIT, phydev->supported);
+	linkmode_set_bit(ETHTOOL_LINK_MODE_FIBRE_BIT, phydev->supported);
+
+	return 0;
+}
+
+static int aqr105_config_speed(struct phy_device *phydev)
+{
+	int vend = MDIO_AN_VEND_PROV_EXC_PHYID_INFO;
+	int ctrl10 = 0;
+	int adv = ADVERTISE_CSMA;
+	int ret;
+
+	switch (phydev->speed) {
+	case SPEED_100:
+		adv |= ADVERTISE_100FULL;
+		break;
+	case SPEED_1000:
+		adv |= ADVERTISE_NPAGE;
+		if (phydev->duplex == DUPLEX_FULL)
+			vend |= MDIO_AN_VEND_PROV_1000BASET_FULL;
+		else
+			vend |= MDIO_AN_VEND_PROV_1000BASET_HALF;
+		break;
+	case SPEED_2500:
+		adv |= (ADVERTISE_NPAGE | ADVERTISE_RESV);
+		vend |= MDIO_AN_VEND_PROV_2500BASET_FULL;
+		break;
+	case SPEED_5000:
+		adv |= (ADVERTISE_NPAGE | ADVERTISE_RESV);
+		vend |= MDIO_AN_VEND_PROV_5000BASET_FULL;
+		break;
+	case SPEED_10000:
+		adv |= (ADVERTISE_NPAGE | ADVERTISE_RESV);
+		ctrl10 |= MDIO_AN_10GBT_CTRL_ADV10G;
+		break;
+	default:
+		return -EINVAL;
+	}
+	ret = phy_write_mmd(phydev, MDIO_MMD_AN, MDIO_AN_ADVERTISE, adv);
+	if (ret < 0)
+		return ret;
+	ret = phy_write_mmd(phydev, MDIO_MMD_AN, MDIO_AN_VEND_PROV, vend);
+	if (ret < 0)
+		return ret;
+	ret = phy_write_mmd(phydev, MDIO_MMD_AN, MDIO_AN_10GBT_CTRL, ctrl10);
+	if (ret < 0)
+		return ret;
+
+	/* set by vendor driver, but should be on by default */
+	ret = phy_set_bits_mmd(phydev, MDIO_MMD_AN, MDIO_CTRL1,
+			       MDIO_AN_CTRL1_XNP);
+	if (ret < 0)
+		return ret;
+
+	return genphy_c45_an_disable_aneg(phydev);
+}
+
+static int aqr105_config_aneg(struct phy_device *phydev)
+{
+	bool changed = false;
+	u16 reg;
+	int ret;
+
+	ret = aqr_set_mdix(phydev, phydev->mdix_ctrl);
+	if (ret < 0)
+		return ret;
+	if (ret > 0)
+		changed = true;
+
+	if (phydev->autoneg == AUTONEG_DISABLE)
+		return aqr105_config_speed(phydev);
+
+	ret = genphy_c45_an_config_aneg(phydev);
+	if (ret < 0)
+		return ret;
+	if (ret > 0)
+		changed = true;
+
+	/* Clause 45 has no standardized support for 1000BaseT, therefore
+	 * use vendor registers for this mode.
+	 */
+	reg = 0;
+	if (linkmode_test_bit(ETHTOOL_LINK_MODE_1000baseT_Full_BIT,
+			      phydev->advertising))
+		reg |= MDIO_AN_VEND_PROV_1000BASET_FULL;
+
+	if (linkmode_test_bit(ETHTOOL_LINK_MODE_1000baseT_Half_BIT,
+			      phydev->advertising))
+		reg |= MDIO_AN_VEND_PROV_1000BASET_HALF;
+
+	/* Handle the case when the 2.5G and 5G speeds are not advertised */
+	if (linkmode_test_bit(ETHTOOL_LINK_MODE_2500baseT_Full_BIT,
+			      phydev->advertising))
+		reg |= MDIO_AN_VEND_PROV_2500BASET_FULL;
+
+	if (linkmode_test_bit(ETHTOOL_LINK_MODE_5000baseT_Full_BIT,
+			      phydev->advertising))
+		reg |= MDIO_AN_VEND_PROV_5000BASET_FULL;
+
+	ret = phy_modify_mmd_changed(phydev, MDIO_MMD_AN, MDIO_AN_VEND_PROV,
+				     MDIO_AN_VEND_PROV_1000BASET_HALF |
+				     MDIO_AN_VEND_PROV_1000BASET_FULL |
+				     MDIO_AN_VEND_PROV_2500BASET_FULL |
+				     MDIO_AN_VEND_PROV_5000BASET_FULL, reg);
+	if (ret < 0)
+		return ret;
+	if (ret > 0)
+		changed = true;
+
+	return genphy_c45_check_and_restart_aneg(phydev, changed);
+}
+
+static int aqr105_read_rate(struct phy_device *phydev)
+{
+	int val;
+
+	val = phy_read_mmd(phydev, MDIO_MMD_AN, MDIO_AN_TX_VEND_STATUS1);
+	if (val < 0)
+		return val;
+
+	if (val & MDIO_AN_TX_VEND_STATUS1_FULL_DUPLEX)
+		phydev->duplex = DUPLEX_FULL;
+	else
+		phydev->duplex = DUPLEX_HALF;
+
+	switch (FIELD_GET(MDIO_AN_TX_VEND_STATUS1_RATE_MASK, val)) {
+	case MDIO_AN_TX_VEND_STATUS1_10BASET:
+		phydev->speed = SPEED_10;
+		break;
+	case MDIO_AN_TX_VEND_STATUS1_100BASETX:
+		phydev->speed = SPEED_100;
+		break;
+	case MDIO_AN_TX_VEND_STATUS1_1000BASET:
+		phydev->speed = SPEED_1000;
+		break;
+	case MDIO_AN_TX_VEND_STATUS1_2500BASET:
+		phydev->speed = SPEED_2500;
+		break;
+	case MDIO_AN_TX_VEND_STATUS1_5000BASET:
+		phydev->speed = SPEED_5000;
+		break;
+	case MDIO_AN_TX_VEND_STATUS1_10GBASET:
+		phydev->speed = SPEED_10000;
+		break;
+	default:
+		phydev->speed = SPEED_UNKNOWN;
+	}
+
+	return 0;
+}
+
+static int aqr105_read_status(struct phy_device *phydev)
+{
+	int ret;
+	int val;
+
+	ret = aqr_read_status(phydev);
+	if (ret)
+		return ret;
+
+	if (!phydev->link || phydev->autoneg == AUTONEG_DISABLE)
+		return 0;
+
+	/**
+	 * The status register is not immediately correct on line side link up.
+	 * Poll periodically until it reflects the correct ON state.
+	 * Only return fail for read error, timeout defaults to OFF state.
+	 */
+	ret = phy_read_mmd_poll_timeout(phydev, MDIO_MMD_PHYXS,
+					MDIO_PHYXS_VEND_IF_STATUS, val,
+					(FIELD_GET(MDIO_PHYXS_VEND_IF_STATUS_TYPE_MASK, val) !=
+					MDIO_PHYXS_VEND_IF_STATUS_TYPE_OFF),
+					AQR107_OP_IN_PROG_SLEEP,
+					AQR107_OP_IN_PROG_TIMEOUT, false);
+	if (ret && ret != -ETIMEDOUT)
+		return ret;
+
+	switch (FIELD_GET(MDIO_PHYXS_VEND_IF_STATUS_TYPE_MASK, val)) {
+	case MDIO_PHYXS_VEND_IF_STATUS_TYPE_KR:
+		phydev->interface = PHY_INTERFACE_MODE_10GKR;
+		break;
+	case MDIO_PHYXS_VEND_IF_STATUS_TYPE_KX:
+		phydev->interface = PHY_INTERFACE_MODE_1000BASEKX;
+		break;
+	case MDIO_PHYXS_VEND_IF_STATUS_TYPE_XFI:
+		phydev->interface = PHY_INTERFACE_MODE_10GBASER;
+		break;
+	case MDIO_PHYXS_VEND_IF_STATUS_TYPE_USXGMII:
+		phydev->interface = PHY_INTERFACE_MODE_USXGMII;
+		break;
+	case MDIO_PHYXS_VEND_IF_STATUS_TYPE_XAUI:
+		phydev->interface = PHY_INTERFACE_MODE_XAUI;
+		break;
+	case MDIO_PHYXS_VEND_IF_STATUS_TYPE_SGMII:
+		phydev->interface = PHY_INTERFACE_MODE_SGMII;
+		break;
+	case MDIO_PHYXS_VEND_IF_STATUS_TYPE_RXAUI:
+		phydev->interface = PHY_INTERFACE_MODE_RXAUI;
+		break;
+	case MDIO_PHYXS_VEND_IF_STATUS_TYPE_OCSGMII:
+		phydev->interface = PHY_INTERFACE_MODE_2500BASEX;
+		break;
+	case MDIO_PHYXS_VEND_IF_STATUS_TYPE_OFF:
+	default:
+		phydev->link = false;
+		phydev->interface = PHY_INTERFACE_MODE_NA;
+		break;
+	}
+
+	/* Read rate from vendor register */
+	return aqr105_read_rate(phydev);
+}
+
 static int aqr107_read_rate(struct phy_device *phydev)
 {
 	u32 config_reg;
@@ -911,11 +1144,13 @@ static struct phy_driver aqr_driver[] = {
 {
 	PHY_ID_MATCH_MODEL(PHY_ID_AQR105),
 	.name		= "Aquantia AQR105",
-	.config_aneg    = aqr_config_aneg,
+	.get_features	= aqr105_get_features,
 	.probe		= aqr107_probe,
+	.config_init	= aqr107_config_init,
+	.config_aneg    = aqr105_config_aneg,
 	.config_intr	= aqr_config_intr,
 	.handle_interrupt = aqr_handle_interrupt,
-	.read_status	= aqr_read_status,
+	.read_status	= aqr105_read_status,
 	.suspend	= aqr107_suspend,
 	.resume		= aqr107_resume,
 },

-- 
2.47.2

