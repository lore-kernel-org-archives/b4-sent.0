From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 13 Nov 2026 08:59:32 -0800
Subject: [PATCH net-next v11 13/14] net: phy: ncn26000: Support for
 onsemi's S2500 internal phy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-s2500-mac-phy-support-v11-13-7a186141952c@onsemi.com>
References: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
In-Reply-To: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794589162; l=6216;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=eNZtNTzA+zfsluvB/d2CgKml8D7BQRin83kl7tYthuk=;
 b=oEYT3ON6XSGZnmeecmB5Q7tAAbKFu105Twdqaf4CNokg90wEpOKRiZSoWNxSmIJrd/omZBb1w
 78kOnM+UEUMCqecX8nDv5r/uv1EbDYKimXWLdWhIaywxc8S8wqn1sVZ
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for internal PHY of the integrated media access
controller S2500. PLCA tx opportunity timer's default value
is correct in this device, compared to the currently supported
PHY NCN26000.

The S2500 entry additionally supports SQI reporting, OATC14 cable
testing and loopback, and enables direct Clause 45 MMD access. The
S2500 entry works in polled mode only.

S2500 uses its own config_aneg that sets BMCR_ANENABLE without
affecting other bits in BMCR register. Also this keeps NCN26000
behavior unchanged.

Also add S2500 support to the Kconfig help text, add a MAINTAINERS
entry and a MODULE_AUTHOR line.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v11
  - Copyright year changed from 2022 to 2022-2026
    Previous patch had 2026 only.
  - Added more information in commit message
  - s2500 has its own config_aneg so that it won't cause any
    change in behavior to ncn26000.
changes in v10
  - removed config_intr callback as PHY driver is in polled mode
changes in v9
  - Added Reviewed tag
changes in v8
  - changes to use newer API for read/write_mmd callback
changes in v7
  - No change
changes in v6
  - No change
changes in v5
  - No change
changes in v4
  - no change
changes in v3
   added new PHY support in a separate patch
   changed model comparison to use phy_id_compare_model
changes in v2
   Removed bug fixes. Retained only S2500 specific changes
changes in v1
   Added support for an internal PHY of onsemi's MAC-PHY S2500
---
 MAINTAINERS                |  1 +
 drivers/net/phy/Kconfig    |  2 +-
 drivers/net/phy/ncn26000.c | 44 +++++++++++++++++++++++++++++++++++++++++---
 3 files changed, 43 insertions(+), 4 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index e5ac39026ef2..78f5de606df0 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -21008,6 +21008,7 @@ F:	arch/mips/boot/dts/ralink/omega2p.dts
 
 ONSEMI ETHERNET PHY DRIVERS
 M:	Piergiorgio Beruto <piergiorgio.beruto@gmail.com>
+M:	Selvamani Rajagopal <selvamani.rajagopal@onsemi.com>
 L:	netdev@vger.kernel.org
 S:	Supported
 W:	http://www.onsemi.com
diff --git a/drivers/net/phy/Kconfig b/drivers/net/phy/Kconfig
index 30e9d22c8d1a..cff58dbe391d 100644
--- a/drivers/net/phy/Kconfig
+++ b/drivers/net/phy/Kconfig
@@ -396,7 +396,7 @@ config NCN26000_PHY
 	help
 	  Adds support for the onsemi 10BASE-T1S Ethernet PHY.
 	  Currently supports the NCN26000 10BASE-T1S Industrial PHY
-	  with MII interface.
+	  with MII interface and the S2500 10BASE-T1S PHY.
 
 source "drivers/net/phy/qcom/Kconfig"
 
diff --git a/drivers/net/phy/ncn26000.c b/drivers/net/phy/ncn26000.c
index 888d74b83125..0e2c978b73d4 100644
--- a/drivers/net/phy/ncn26000.c
+++ b/drivers/net/phy/ncn26000.c
@@ -2,7 +2,7 @@
 /*
  *  Driver for the onsemi 10BASE-T1S NCN26000 PHYs family.
  *
- * Copyright 2022 onsemi
+ * Copyright 2022-2026 onsemi
  */
 #include <linux/kernel.h>
 #include <linux/bitfield.h>
@@ -14,6 +14,7 @@
 
 #include "mdio-open-alliance.h"
 
+#define PHY_ID_S2500			0x180FF411
 #define PHY_ID_NCN26000			0x180FF5A1
 
 #define NCN26000_REG_IRQ_CTL            16
@@ -40,13 +41,18 @@
 
 static int ncn26000_config_init(struct phy_device *phydev)
 {
+	int ret = 0;
+
 	/* HW bug workaround: the default value of the PLCA TO_TIMER should be
 	 * 32, where the current version of NCN26000 reports 24. This will be
 	 * fixed in future PHY versions. For the time being, we force the
 	 * correct default here.
 	 */
-	return phy_write_mmd(phydev, MDIO_MMD_VEND2, MDIO_OATC14_PLCA_TOTMR,
-			     TO_TMR_DEFAULT);
+	if (phy_id_compare_model(phydev->drv->phy_id, PHY_ID_NCN26000))
+		ret = phy_write_mmd(phydev, MDIO_MMD_VEND2,
+				    MDIO_OATC14_PLCA_TOTMR,
+				    TO_TMR_DEFAULT);
+	return ret;
 }
 
 static int ncn26000_config_aneg(struct phy_device *phydev)
@@ -62,6 +68,17 @@ static int ncn26000_config_aneg(struct phy_device *phydev)
 	return phy_write(phydev, MII_BMCR, NCN26000_BCMR_LINK_CTRL_BIT);
 }
 
+/* Kept separate to leave ncn26000_config_aneg() unchanged. BMCR is
+ * modified instead of overwritten, to keep loopback enabled.
+ */
+static int s2500_config_aneg(struct phy_device *phydev)
+{
+	phydev->mdix_ctrl = ETH_TP_MDI_AUTO;
+	phydev->mdix = ETH_TP_MDI;
+
+	return phy_set_bits(phydev, MII_BMCR, NCN26000_BCMR_LINK_CTRL_BIT);
+}
+
 static int ncn26000_read_status(struct phy_device *phydev)
 {
 	/* The NCN26000 reports NCN26000_LINK_STATUS_BIT if the link status of
@@ -162,6 +179,25 @@ static int ncn26000_config_intr(struct phy_device *phydev)
 }
 
 static struct phy_driver ncn26000_driver[] = {
+	{
+		PHY_ID_MATCH_MODEL(PHY_ID_S2500),
+		.name                  = "S2500",
+		.features              = PHY_BASIC_T1S_P2MP_FEATURES,
+		.config_init           = ncn26000_config_init,
+		.config_aneg           = s2500_config_aneg,
+		.read_status           = ncn26000_read_status,
+		.set_loopback          = genphy_loopback_no_speed,
+		.set_plca_cfg          = ncn26000_c45_plca_set_cfg,
+		.get_plca_cfg          = genphy_c45_plca_get_cfg,
+		.get_plca_status       = genphy_c45_plca_get_status,
+		.soft_reset            = genphy_soft_reset,
+		.get_sqi               = genphy_c45_oatc14_get_sqi,
+		.get_sqi_max           = genphy_c45_oatc14_get_sqi_max,
+		.read_mmd              = genphy_read_mmd_c45,
+		.write_mmd             = genphy_write_mmd_c45,
+		.cable_test_get_status = genphy_c45_oatc14_cable_test_get_status,
+		.cable_test_start      = genphy_c45_oatc14_cable_test_start,
+	},
 	{
 		PHY_ID_MATCH_MODEL(PHY_ID_NCN26000),
 		.name			= "NCN26000",
@@ -182,11 +218,13 @@ module_phy_driver(ncn26000_driver);
 
 static const struct mdio_device_id __maybe_unused ncn26000_tbl[] = {
 	{ PHY_ID_MATCH_MODEL(PHY_ID_NCN26000) },
+	{ PHY_ID_MATCH_MODEL(PHY_ID_S2500) },
 	{ }
 };
 
 MODULE_DEVICE_TABLE(mdio, ncn26000_tbl);
 
+MODULE_AUTHOR("Selvamani Rajagopal <selvamani.rajagopal@onsemi.com>");
 MODULE_AUTHOR("Piergiorgio Beruto");
 MODULE_DESCRIPTION("onsemi 10BASE-T1S PHY driver");
 MODULE_LICENSE("Dual BSD/GPL");

-- 
2.43.0

