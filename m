From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 01 Jul 2025 15:32:02 +0100
Subject: [PATCH v7 07/20] mfd: adp5585: Add support for adp5589
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250701-dev-adp5589-fw-v7-7-b1fcfe9e9826@analog.com>
References: <20250701-dev-adp5589-fw-v7-0-b1fcfe9e9826@analog.com>
In-Reply-To: <20250701-dev-adp5589-fw-v7-0-b1fcfe9e9826@analog.com>
To: linux-gpio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-input@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Liu Ying <victor.liu@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751380320; l=9101;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=RJt07nEki9HKnMs3jvuPES7fZWUGCpZJ2fFKJRnKBF0=;
 b=ZzUGMivCMCQvwTxlcr4qsjqrnX70mzNexLoEMnulJ/sg51z0Z2PRpz2/rUddKnLZsGWDSp+Y+
 k82/6UU0UCvDiwSSR5JxmVJS8kT57uu0GsEpLzT503vJvxpqy4JFWsi
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADP5589 is a 19 I/O port expander with built-in keypad matrix decoder,
programmable logic, reset generator, and PWM generator.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c       | 123 ++++++++++++++++++++++++++++++++++++++++----
 include/linux/mfd/adp5585.h |  10 ++++
 2 files changed, 124 insertions(+), 9 deletions(-)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 4d92b63629289c816bc46b70d3171ce16b1ee33e..00996571ef900bece2d634cd9d05394fa04d550a 100644
--- a/drivers/mfd/adp5585.c
+++ b/drivers/mfd/adp5585.c
@@ -29,6 +29,11 @@ static const struct mfd_cell adp5585_devs[ADP5585_DEV_MAX] = {
 	MFD_CELL_NAME("adp5585-pwm"),
 };
 
+static const struct mfd_cell adp5589_devs[] = {
+	MFD_CELL_NAME("adp5589-gpio"),
+	MFD_CELL_NAME("adp5589-pwm"),
+};
+
 static const struct regmap_range adp5585_volatile_ranges[] = {
 	regmap_reg_range(ADP5585_ID, ADP5585_GPI_STATUS_B),
 };
@@ -38,6 +43,15 @@ static const struct regmap_access_table adp5585_volatile_regs = {
 	.n_yes_ranges = ARRAY_SIZE(adp5585_volatile_ranges),
 };
 
+static const struct regmap_range adp5589_volatile_ranges[] = {
+	regmap_reg_range(ADP5585_ID, ADP5589_GPI_STATUS_C),
+};
+
+static const struct regmap_access_table adp5589_volatile_regs = {
+	.yes_ranges = adp5589_volatile_ranges,
+	.n_yes_ranges = ARRAY_SIZE(adp5589_volatile_ranges),
+};
+
 /*
  * Chip variants differ in the default configuration of pull-up and pull-down
  * resistors, and therefore have different default register values:
@@ -81,12 +95,54 @@ static const u8 adp5585_regmap_defaults_04[ADP5585_MAX_REG + 1] = {
 	/* 0x38 */ 0x00, 0x00, 0x00, 0x00, 0x00,
 };
 
+static const u8 adp5589_regmap_defaults_00[ADP5589_MAX_REG + 1] = {
+	/* 0x00 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x08 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x10 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x18 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x20 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x28 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x30 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x38 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x40 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x48 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+};
+
+static const u8 adp5589_regmap_defaults_01[ADP5589_MAX_REG + 1] = {
+	/* 0x00 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x08 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x10 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x18 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x20 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x28 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x30 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x38 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00,
+	/* 0x40 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x48 */ 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00,
+};
+
+static const u8 adp5589_regmap_defaults_02[ADP5589_MAX_REG + 1] = {
+	/* 0x00 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x08 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x10 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x18 */ 0x00, 0x41, 0x01, 0x00, 0x11, 0x04, 0x00, 0x00,
+	/* 0x20 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x28 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x30 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x38 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x40 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	/* 0x48 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+};
+
 static const u8 *adp5585_regmap_defaults[ADP5585_MAX] = {
 	[ADP5585_00] = adp5585_regmap_defaults_00,
 	[ADP5585_01] = adp5585_regmap_defaults_00,
 	[ADP5585_02] = adp5585_regmap_defaults_02,
 	[ADP5585_03] = adp5585_regmap_defaults_00,
 	[ADP5585_04] = adp5585_regmap_defaults_04,
+	[ADP5589_00] = adp5589_regmap_defaults_00,
+	[ADP5589_01] = adp5589_regmap_defaults_01,
+	[ADP5589_02] = adp5589_regmap_defaults_02,
 };
 
 static const struct regmap_config adp5585_regmap_config_template = {
@@ -98,33 +154,69 @@ static const struct regmap_config adp5585_regmap_config_template = {
 	.num_reg_defaults_raw = ADP5585_MAX_REG + 1,
 };
 
-static struct regmap_config *adp5585_fill_regmap_config(const struct adp5585_dev *adp5585)
+static const struct regmap_config adp5589_regmap_config_template = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = ADP5589_MAX_REG,
+	.volatile_table = &adp5589_volatile_regs,
+	.cache_type = REGCACHE_MAPLE,
+	.num_reg_defaults_raw = ADP5589_MAX_REG + 1,
+};
+
+static struct regmap_config *adp5585_fill_variant_config(struct adp5585_dev *adp5585)
 {
 	struct regmap_config *regmap_config;
 
-	regmap_config = devm_kmemdup(adp5585->dev, &adp5585_regmap_config_template,
-				     sizeof(*regmap_config), GFP_KERNEL);
+	switch (adp5585->variant) {
+	case ADP5585_00:
+	case ADP5585_01:
+	case ADP5585_02:
+	case ADP5585_03:
+	case ADP5585_04:
+		adp5585->id = ADP5585_MAN_ID_VALUE;
+		regmap_config = devm_kmemdup(adp5585->dev, &adp5585_regmap_config_template,
+					     sizeof(*regmap_config), GFP_KERNEL);
+		break;
+	case ADP5589_00:
+	case ADP5589_01:
+	case ADP5589_02:
+		adp5585->id = ADP5589_MAN_ID_VALUE;
+		regmap_config = devm_kmemdup(adp5585->dev, &adp5589_regmap_config_template,
+					     sizeof(*regmap_config), GFP_KERNEL);
+		break;
+	default:
+		return ERR_PTR(-ENODEV);
+	}
+
 	if (!regmap_config)
 		return ERR_PTR(-ENOMEM);
 
 	regmap_config->reg_defaults_raw = adp5585_regmap_defaults[adp5585->variant];
+
 	return regmap_config;
 }
 
-static int adp5585_add_devices(struct device *dev)
+static int adp5585_add_devices(const struct adp5585_dev *adp5585)
 {
+	struct device *dev = adp5585->dev;
+	const struct mfd_cell *cells;
 	int ret;
 
+	if (adp5585->id == ADP5585_MAN_ID_VALUE)
+		cells = adp5585_devs;
+	else
+		cells = adp5589_devs;
+
 	if (device_property_present(dev, "#pwm-cells")) {
 		ret = devm_mfd_add_devices(dev, PLATFORM_DEVID_AUTO,
-					   &adp5585_devs[ADP5585_DEV_PWM], 1, NULL, 0, NULL);
+					   &cells[ADP5585_DEV_PWM], 1, NULL, 0, NULL);
 		if (ret)
 			return dev_err_probe(dev, ret, "Failed to add PWM device\n");
 	}
 
 	if (device_property_present(dev, "#gpio-cells")) {
 		ret = devm_mfd_add_devices(dev, PLATFORM_DEVID_AUTO,
-					   &adp5585_devs[ADP5585_DEV_GPIO], 1, NULL, 0, NULL);
+					   &cells[ADP5585_DEV_GPIO], 1, NULL, 0, NULL);
 		if (ret)
 			return dev_err_probe(dev, ret, "Failed to add GPIO device\n");
 	}
@@ -157,7 +249,7 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 	if (!adp5585->variant)
 		return -ENODEV;
 
-	regmap_config = adp5585_fill_regmap_config(adp5585);
+	regmap_config = adp5585_fill_variant_config(adp5585);
 	if (IS_ERR(regmap_config))
 		return PTR_ERR(regmap_config);
 
@@ -171,7 +263,8 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 		return dev_err_probe(&i2c->dev, ret,
 				     "Failed to read device ID\n");
 
-	if ((id & ADP5585_MAN_ID_MASK) != ADP5585_MAN_ID_VALUE)
+	id &= ADP5585_MAN_ID_MASK;
+	if (id != adp5585->id)
 		return dev_err_probe(&i2c->dev, -ENODEV,
 				     "Invalid device ID 0x%02x\n", id);
 
@@ -187,7 +280,7 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 	if (ret)
 		return ret;
 
-	return adp5585_add_devices(&i2c->dev);
+	return adp5585_add_devices(adp5585);
 }
 
 static int adp5585_suspend(struct device *dev)
@@ -227,6 +320,18 @@ static const struct of_device_id adp5585_of_match[] = {
 	}, {
 		.compatible = "adi,adp5585-04",
 		.data = (void *)ADP5585_04,
+	}, {
+		.compatible = "adi,adp5589-00",
+		.data = (void *)ADP5589_00,
+	}, {
+		.compatible = "adi,adp5589-01",
+		.data = (void *)ADP5589_01,
+	}, {
+		.compatible = "adi,adp5589-02",
+		.data = (void *)ADP5589_02,
+	}, {
+		.compatible = "adi,adp5589",
+		.data = (void *)ADP5589_00,
 	},
 	{ /* sentinel */ }
 };
diff --git a/include/linux/mfd/adp5585.h b/include/linux/mfd/adp5585.h
index c56af8d8d76c4ebc0ede1ee4769ca059de29f53c..70e58122a36a7321dc95d095b806f06fa57c97c9 100644
--- a/include/linux/mfd/adp5585.h
+++ b/include/linux/mfd/adp5585.h
@@ -117,6 +117,12 @@
 #define ADP5585_BANK(n)			((n) >= 6 ? 1 : 0)
 #define ADP5585_BIT(n)			((n) >= 6 ? BIT((n) - 6) : BIT(n))
 
+/* ADP5589 */
+#define		ADP5589_MAN_ID_VALUE		0x10
+#define ADP5589_GPI_STATUS_C		0x18
+#define ADP5589_INT_EN			0x4e
+#define ADP5589_MAX_REG			ADP5589_INT_EN
+
 struct regmap;
 
 enum adp5585_variant {
@@ -125,6 +131,9 @@ enum adp5585_variant {
 	ADP5585_02,
 	ADP5585_03,
 	ADP5585_04,
+	ADP5589_00,
+	ADP5589_01,
+	ADP5589_02,
 	ADP5585_MAX
 };
 
@@ -132,6 +141,7 @@ struct adp5585_dev {
 	struct device *dev;
 	struct regmap *regmap;
 	enum adp5585_variant variant;
+	unsigned int id;
 };
 
 #endif

-- 
2.50.0

