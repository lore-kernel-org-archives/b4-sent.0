From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 13 May 2026 15:12:03 +0200
Subject: [PATCH v5 2/2] phy: add basic support for NXPs TJA1145 CAN
 transceiver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260513-tja1145-support-v5-2-38720a7ee63e@liebherr.com>
References: <20260513-tja1145-support-v5-0-38720a7ee63e@liebherr.com>
In-Reply-To: <20260513-tja1145-support-v5-0-38720a7ee63e@liebherr.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, lee.lockhey@gmail.com, 
 Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778677926; l=7419;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=cTwa7LJ4WYrfE9uhGBTMXWFXb7E3Zcyu/daqVib881Q=;
 b=KIIvZ/zU3Gq4STWp5pzqja9TX6gficBqv9/1O0vo4Djp98oBOvfFXFfZEOJn+lm/406L2f0qA
 rclv3xoCLDtAF8iDdUFQjW7wpfcUtlJnm/pxd2ArTDsSRX8cHN/CFnY
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add basic driver support for NXPs TJA1145 CAN transceiver which brings the
PHY up/down by switching to normal/standby mode using SPI commands.

Tested-by: <lee.lockhey@gmail.com>
Reviewed-by: Marc Kleine-Budde <mkl@pengutronix.de>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/phy/Kconfig           |  10 +++
 drivers/phy/Makefile          |   1 +
 drivers/phy/phy-nxp-tja1145.c | 184 ++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 195 insertions(+)

diff --git a/drivers/phy/Kconfig b/drivers/phy/Kconfig
index ab96ee5858c1a9dee2aea3a896c09b397cc30c7f..a3f9a05e222002e23d5080aa22b56f2a822a4b97 100644
--- a/drivers/phy/Kconfig
+++ b/drivers/phy/Kconfig
@@ -124,6 +124,16 @@ config PHY_NXP_PTN3222
 	  schemes. It supports all three USB 2.0 data rates: Low Speed, Full
 	  Speed and High Speed.
 
+config PHY_NXP_TJA1145
+	tristate "NXP TJA1145 CAN transceiver PHY"
+	select GENERIC_PHY
+	select REGMAP_SPI
+	depends on SPI
+	help
+	  This option enables support for NXPs TJA1145 CAN transceiver as a PHY.
+	  This driver provides function for putting the transceiver in various
+	  functional modes using SPI commands.
+
 config PHY_PISTACHIO_USB
 	tristate "IMG Pistachio USB2.0 PHY driver"
 	depends on MIPS || COMPILE_TEST
diff --git a/drivers/phy/Makefile b/drivers/phy/Makefile
index f31767745123773757e84b0b5fb85ec286c1d977..65ea9f0bc7f151378caa6e161f8b8a5c6884d7e5 100644
--- a/drivers/phy/Makefile
+++ b/drivers/phy/Makefile
@@ -14,6 +14,7 @@ obj-$(CONFIG_PHY_GOOGLE_USB)		+= phy-google-usb.o
 obj-$(CONFIG_USB_LGM_PHY)		+= phy-lgm-usb.o
 obj-$(CONFIG_PHY_LPC18XX_USB_OTG)	+= phy-lpc18xx-usb-otg.o
 obj-$(CONFIG_PHY_NXP_PTN3222)		+= phy-nxp-ptn3222.o
+obj-$(CONFIG_PHY_NXP_TJA1145)		+= phy-nxp-tja1145.o
 obj-$(CONFIG_PHY_PISTACHIO_USB)		+= phy-pistachio-usb.o
 obj-$(CONFIG_PHY_SNPS_EUSB2)		+= phy-snps-eusb2.o
 obj-$(CONFIG_PHY_XGENE)			+= phy-xgene.o
diff --git a/drivers/phy/phy-nxp-tja1145.c b/drivers/phy/phy-nxp-tja1145.c
new file mode 100644
index 0000000000000000000000000000000000000000..1e8bd169743abfaeee6948d200e6ac320cd616ff
--- /dev/null
+++ b/drivers/phy/phy-nxp-tja1145.c
@@ -0,0 +1,184 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2025 Liebherr-Electronics and Drives GmbH
+ */
+#include <linux/module.h>
+#include <linux/regmap.h>
+
+#include <linux/phy/phy.h>
+#include <linux/spi/spi.h>
+
+#define TJA1145_MODE_CTRL		0x01
+#define TJA1145_MODE_CTRL_MC		GENMASK(2, 0)
+#define TJA1145_MODE_CTRL_STBY		BIT(2)
+#define TJA1145_MODE_CTRL_NORMAL	TJA1145_MODE_CTRL_MC
+
+#define TJA1145_CAN_CTRL		0x20
+#define TJA1145_CAN_CTRL_CMC		GENMASK(1, 0)
+#define TJA1145_CAN_CTRL_ACTIVE		BIT(1)
+
+#define TJA1145_IDENT			0x7e
+#define TJA1145_IDENT_TJA1145T		0x70
+
+#define TJA1145_SPI_READ_BIT		BIT(0)
+#define TJA1145T_MAX_BITRATE		1000000
+
+static int tja1145_phy_power_on(struct phy *phy)
+{
+	struct regmap *map = phy_get_drvdata(phy);
+	int ret;
+
+	/*
+	 * Switch operating mode to normal which is the active operating mode.
+	 * In this mode, the device is fully operational.
+	 */
+	ret = regmap_update_bits(map, TJA1145_MODE_CTRL, TJA1145_MODE_CTRL_MC,
+				 TJA1145_MODE_CTRL_NORMAL);
+	if (ret)
+		return ret;
+
+	/*
+	 * Switch to CAN operating mode active where the PHY can transmit and
+	 * receive data.
+	 */
+	return regmap_update_bits(map, TJA1145_CAN_CTRL, TJA1145_CAN_CTRL_CMC,
+				  TJA1145_CAN_CTRL_ACTIVE);
+}
+
+static int tja1145_phy_power_off(struct phy *phy)
+{
+	struct regmap *map = phy_get_drvdata(phy);
+
+	/*
+	 * Switch to operating mode standby, the PHY is unable to transmit or
+	 * receive data in standby mode.
+	 */
+	return regmap_update_bits(map, TJA1145_MODE_CTRL, TJA1145_MODE_CTRL_MC,
+				  TJA1145_MODE_CTRL_STBY);
+}
+
+static const struct phy_ops tja1145_phy_ops = {
+	.power_on = tja1145_phy_power_on,
+	.power_off = tja1145_phy_power_off,
+	.owner = THIS_MODULE,
+};
+
+static const struct regmap_range tja1145_wr_holes_ranges[] = {
+	regmap_reg_range(0x00, 0x00),
+	regmap_reg_range(0x02, 0x03),
+	regmap_reg_range(0x05, 0x05),
+	regmap_reg_range(0x0b, 0x1f),
+	regmap_reg_range(0x21, 0x22),
+	regmap_reg_range(0x24, 0x25),
+	regmap_reg_range(0x30, 0x4b),
+	regmap_reg_range(0x4d, 0x60),
+	regmap_reg_range(0x62, 0x62),
+	regmap_reg_range(0x65, 0x67),
+	regmap_reg_range(0x70, 0xff),
+};
+
+static const struct regmap_access_table tja1145_wr_table = {
+	.no_ranges = tja1145_wr_holes_ranges,
+	.n_no_ranges = ARRAY_SIZE(tja1145_wr_holes_ranges),
+};
+
+static const struct regmap_range tja1145_rd_holes_ranges[] = {
+	regmap_reg_range(0x00, 0x00),
+	regmap_reg_range(0x02, 0x02),
+	regmap_reg_range(0x05, 0x05),
+	regmap_reg_range(0x0b, 0x1f),
+	regmap_reg_range(0x21, 0x21),
+	regmap_reg_range(0x24, 0x25),
+	regmap_reg_range(0x30, 0x4a),
+	regmap_reg_range(0x4d, 0x5f),
+	regmap_reg_range(0x62, 0x62),
+	regmap_reg_range(0x65, 0x67),
+	regmap_reg_range(0x70, 0x7d),
+	regmap_reg_range(0x7f, 0xff),
+};
+
+static const struct regmap_access_table tja1145_rd_table = {
+	.no_ranges = tja1145_rd_holes_ranges,
+	.n_no_ranges = ARRAY_SIZE(tja1145_rd_holes_ranges),
+};
+
+static const struct regmap_config tja1145_regmap_config = {
+	.reg_bits = 8,
+	.reg_shift = -1,
+	.val_bits = 8,
+	.wr_table = &tja1145_wr_table,
+	.rd_table = &tja1145_rd_table,
+	.read_flag_mask = TJA1145_SPI_READ_BIT,
+	.max_register = TJA1145_IDENT,
+};
+
+static int tja1145_check_ident(struct device *dev, struct regmap *map)
+{
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(map, TJA1145_IDENT, &val);
+	if (ret)
+		return ret;
+
+	if (val != TJA1145_IDENT_TJA1145T) {
+		dev_err(dev, "Expected device id: 0x%02x, got: 0x%02x\n",
+			TJA1145_IDENT_TJA1145T, val);
+		return -ENODEV;
+	}
+
+	return 0;
+}
+
+static int tja1145_probe(struct spi_device *spi)
+{
+	struct phy_provider *phy_provider;
+	struct device *dev = &spi->dev;
+	struct regmap *map;
+	struct phy *phy;
+	int ret;
+
+	map = devm_regmap_init_spi(spi, &tja1145_regmap_config);
+	if (IS_ERR(map))
+		return dev_err_probe(dev, PTR_ERR(map), "failed to init regmap\n");
+
+	ret = tja1145_check_ident(dev, map);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to identify device\n");
+
+	phy = devm_phy_create(dev, dev->of_node, &tja1145_phy_ops);
+	if (IS_ERR(phy))
+		return dev_err_probe(dev, PTR_ERR(phy), "failed to create PHY\n");
+
+	phy->attrs.max_link_rate = TJA1145T_MAX_BITRATE;
+	phy_set_drvdata(phy, map);
+	phy_provider = devm_of_phy_provider_register(dev, of_phy_simple_xlate);
+
+	return PTR_ERR_OR_ZERO(phy_provider);
+}
+
+static const struct spi_device_id tja1145_spi_id[] = {
+	{ "tja1145" },
+	{ }
+};
+MODULE_DEVICE_TABLE(spi, tja1145_spi_id);
+
+static const struct of_device_id tja1145_of_match[] = {
+	{ .compatible = "nxp,tja1145" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, tja1145_of_match);
+
+static struct spi_driver tja1145_driver = {
+	.driver = {
+		.name = "tja1145",
+		.of_match_table = tja1145_of_match,
+	},
+	.probe = tja1145_probe,
+	.id_table = tja1145_spi_id,
+};
+module_spi_driver(tja1145_driver);
+
+MODULE_DESCRIPTION("NXP TJA1145 CAN transceiver PHY driver");
+MODULE_AUTHOR("Dimitri Fedrau <dimitri.fedrau@liebherr.com>");
+MODULE_LICENSE("GPL");

-- 
2.39.5

