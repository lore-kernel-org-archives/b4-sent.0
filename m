From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Fri, 27 Nov 2026 16:27:05 +0100
Subject: [PATCH v5 04/12] phy: amlogic: rename Meson8 HDMI TX PHY driver to
 be SoC-generic
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-meson-drm-create-hdmitx-phy-v5-4-88c43eb95468@aliel.fr>
References: <20261127-meson-drm-create-hdmitx-phy-v5-0-88c43eb95468@aliel.fr>
In-Reply-To: <20261127-meson-drm-create-hdmitx-phy-v5-0-88c43eb95468@aliel.fr>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Vinod Koul <vkoul@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, dri-devel@lists.freedesktop.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>, linux-pm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7248;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=+Sa3VAnyG7mxwHscfV5CH9pZg3lPumtOGpHuVXBmS/s=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQzbnwt5Xj6Wd3k9onfpsRdnRCCPpnnW/HmjKPD90eolYd
 5uxzR+VjlIWBjEuBlkxRZb+uZYn3l0+eubrHvUUmDmsTCBDGLg4BWAiTv8Z/odJNgW9vOv6aJ3G
 83mrjEsrFwq/6Jkd/vbhwVn7E4+sqlrPyPBk65wnz87aNnB23V2+7uAkueadGtN3qiZ8sEjdmrl
 v9jNWAA==
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HDMI TX PHY driver is currently named after the Meson8 family
(Meson8, Meson8b and Meson8m2), but the same IP block is found, with
SoC-specific register programming, on the newer GXBB, GXL, GXM and
G12A SoCs.

In preparation for adding support for these SoCs, make the driver
generic:

 - rename phy-meson8-hdmi-tx.c to phy-meson-hdmi-tx.c
 - rename the Kconfig symbol PHY_MESON8_HDMI_TX to PHY_MESON_HDMI_TX
   and update the Makefile accordingly
 - drop the "(ARCH_MESON && ARM)" dependency in favour of
   "ARCH_MESON", since the driver is no longer ARM32-only, and
   select GENERIC_PHY
 - rename the phy_meson8_hdmi_tx_* symbols to meson_hdmi_phy_*
 - update the platform driver name, the Kconfig help text and the
   module description
 - drop the unused <linux/property.h> include

No functional change intended: the only supported compatible remains
"amlogic,meson8-hdmi-tx-phy".

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/phy/amlogic/Kconfig                        |  9 ++--
 drivers/phy/amlogic/Makefile                       |  2 +-
 .../{phy-meson8-hdmi-tx.c => phy-meson-hdmi-tx.c}  | 54 +++++++++++-----------
 3 files changed, 33 insertions(+), 32 deletions(-)

diff --git a/drivers/phy/amlogic/Kconfig b/drivers/phy/amlogic/Kconfig
index ce7ba3eb2a8e..294996869e83 100644
--- a/drivers/phy/amlogic/Kconfig
+++ b/drivers/phy/amlogic/Kconfig
@@ -2,14 +2,15 @@
 #
 # Phy drivers for Amlogic platforms
 #
-config PHY_MESON8_HDMI_TX
-	tristate "Meson8, Meson8b and Meson8m2 HDMI TX PHY driver"
-	depends on (ARCH_MESON && ARM) || COMPILE_TEST
+config PHY_MESON_HDMI_TX
+	tristate "Meson HDMI TX PHY driver"
+	depends on ARCH_MESON || COMPILE_TEST
 	depends on OF
+	select GENERIC_PHY
 	select MFD_SYSCON
 	help
 	  Enable this to support the HDMI TX PHYs found in Meson8,
-	  Meson8b and Meson8m2 SoCs.
+	  Meson8b, Meson8m2, GXBB, GXL, GXM and G12A SoCs.
 	  If unsure, say N.
 
 config PHY_MESON8B_USB2
diff --git a/drivers/phy/amlogic/Makefile b/drivers/phy/amlogic/Makefile
index 91e3b9790c03..2611ec8a056d 100644
--- a/drivers/phy/amlogic/Makefile
+++ b/drivers/phy/amlogic/Makefile
@@ -1,5 +1,5 @@
 # SPDX-License-Identifier: GPL-2.0-only
-obj-$(CONFIG_PHY_MESON8_HDMI_TX)		+= phy-meson8-hdmi-tx.o
+obj-$(CONFIG_PHY_MESON_HDMI_TX)			+= phy-meson-hdmi-tx.o
 obj-$(CONFIG_PHY_MESON8B_USB2)			+= phy-meson8b-usb2.o
 obj-$(CONFIG_PHY_MESON_GXL_USB2)		+= phy-meson-gxl-usb2.o
 obj-$(CONFIG_PHY_MESON_G12A_USB2)		+= phy-meson-g12a-usb2.o
diff --git a/drivers/phy/amlogic/phy-meson8-hdmi-tx.c b/drivers/phy/amlogic/phy-meson-hdmi-tx.c
similarity index 68%
rename from drivers/phy/amlogic/phy-meson8-hdmi-tx.c
rename to drivers/phy/amlogic/phy-meson-hdmi-tx.c
index f6b5df74a58f..e4e606ab4eef 100644
--- a/drivers/phy/amlogic/phy-meson8-hdmi-tx.c
+++ b/drivers/phy/amlogic/phy-meson-hdmi-tx.c
@@ -1,6 +1,7 @@
 // SPDX-License-Identifier: GPL-2.0+
 /*
- * Meson8, Meson8b and Meson8m2 HDMI TX PHY.
+ * Amlogic Meson HDMI TX PHY driver
+ * (Meson8/8b/8m2)
  *
  * Copyright (C) 2021 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
  */
@@ -13,7 +14,6 @@
 #include <linux/of.h>
 #include <linux/phy/phy.h>
 #include <linux/platform_device.h>
-#include <linux/property.h>
 #include <linux/regmap.h>
 
 /*
@@ -32,30 +32,30 @@
 
 #define HHI_HDMI_PHY_CNTL2				0x3a8
 
-struct phy_meson8_hdmi_tx_priv {
+struct meson_hdmi_phy {
 	struct regmap		*hhi;
 	struct clk		*tmds_clk;
 };
 
-static int phy_meson8_hdmi_tx_init(struct phy *phy)
+static int meson_hdmi_phy_init(struct phy *phy)
 {
-	struct phy_meson8_hdmi_tx_priv *priv = phy_get_drvdata(phy);
+	struct meson_hdmi_phy *priv = phy_get_drvdata(phy);
 
 	return clk_prepare_enable(priv->tmds_clk);
 }
 
-static int phy_meson8_hdmi_tx_exit(struct phy *phy)
+static int meson_hdmi_phy_exit(struct phy *phy)
 {
-	struct phy_meson8_hdmi_tx_priv *priv = phy_get_drvdata(phy);
+	struct meson_hdmi_phy *priv = phy_get_drvdata(phy);
 
 	clk_disable_unprepare(priv->tmds_clk);
 
 	return 0;
 }
 
-static int phy_meson8_hdmi_tx_power_on(struct phy *phy)
+static int meson_hdmi_phy_power_on(struct phy *phy)
 {
-	struct phy_meson8_hdmi_tx_priv *priv = phy_get_drvdata(phy);
+	struct meson_hdmi_phy *priv = phy_get_drvdata(phy);
 	unsigned int i;
 	u16 hdmi_ctl0;
 
@@ -85,9 +85,9 @@ static int phy_meson8_hdmi_tx_power_on(struct phy *phy)
 	return 0;
 }
 
-static int phy_meson8_hdmi_tx_power_off(struct phy *phy)
+static int meson_hdmi_phy_power_off(struct phy *phy)
 {
-	struct phy_meson8_hdmi_tx_priv *priv = phy_get_drvdata(phy);
+	struct meson_hdmi_phy *priv = phy_get_drvdata(phy);
 
 	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0,
 		     FIELD_PREP(HHI_HDMI_PHY_CNTL0_HDMI_CTL1, 0x0841) |
@@ -96,18 +96,18 @@ static int phy_meson8_hdmi_tx_power_off(struct phy *phy)
 	return 0;
 }
 
-static const struct phy_ops phy_meson8_hdmi_tx_ops = {
-	.init		= phy_meson8_hdmi_tx_init,
-	.exit		= phy_meson8_hdmi_tx_exit,
-	.power_on	= phy_meson8_hdmi_tx_power_on,
-	.power_off	= phy_meson8_hdmi_tx_power_off,
+static const struct phy_ops meson_hdmi_phy_ops = {
+	.init		= meson_hdmi_phy_init,
+	.exit		= meson_hdmi_phy_exit,
+	.power_on	= meson_hdmi_phy_power_on,
+	.power_off	= meson_hdmi_phy_power_off,
 	.owner		= THIS_MODULE,
 };
 
-static int phy_meson8_hdmi_tx_probe(struct platform_device *pdev)
+static int meson_hdmi_phy_probe(struct platform_device *pdev)
 {
 	struct device_node *np = pdev->dev.of_node;
-	struct phy_meson8_hdmi_tx_priv *priv;
+	struct meson_hdmi_phy *priv;
 	struct phy_provider *phy_provider;
 	struct resource *res;
 	struct phy *phy;
@@ -128,7 +128,7 @@ static int phy_meson8_hdmi_tx_probe(struct platform_device *pdev)
 	if (IS_ERR(priv->tmds_clk))
 		return PTR_ERR(priv->tmds_clk);
 
-	phy = devm_phy_create(&pdev->dev, np, &phy_meson8_hdmi_tx_ops);
+	phy = devm_phy_create(&pdev->dev, np, &meson_hdmi_phy_ops);
 	if (IS_ERR(phy))
 		return PTR_ERR(phy);
 
@@ -140,21 +140,21 @@ static int phy_meson8_hdmi_tx_probe(struct platform_device *pdev)
 	return PTR_ERR_OR_ZERO(phy_provider);
 }
 
-static const struct of_device_id phy_meson8_hdmi_tx_of_match[] = {
+static const struct of_device_id meson_hdmi_phy_of_match[] = {
 	{ .compatible = "amlogic,meson8-hdmi-tx-phy" },
 	{ /* sentinel */ }
 };
-MODULE_DEVICE_TABLE(of, phy_meson8_hdmi_tx_of_match);
+MODULE_DEVICE_TABLE(of, meson_hdmi_phy_of_match);
 
-static struct platform_driver phy_meson8_hdmi_tx_driver = {
-	.probe	= phy_meson8_hdmi_tx_probe,
+static struct platform_driver meson_hdmi_phy_driver = {
+	.probe	= meson_hdmi_phy_probe,
 	.driver	= {
-		.name		= "phy-meson8-hdmi-tx",
-		.of_match_table	= phy_meson8_hdmi_tx_of_match,
+		.name		= "meson-hdmi-tx-phy",
+		.of_match_table	= meson_hdmi_phy_of_match,
 	},
 };
-module_platform_driver(phy_meson8_hdmi_tx_driver);
+module_platform_driver(meson_hdmi_phy_driver);
 
 MODULE_AUTHOR("Martin Blumenstingl <martin.blumenstingl@googlemail.com>");
-MODULE_DESCRIPTION("Meson8, Meson8b and Meson8m2 HDMI TX PHY driver");
+MODULE_DESCRIPTION("Amlogic Meson HDMI TX PHY driver");
 MODULE_LICENSE("GPL v2");

-- 
2.56.1

