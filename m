From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 21 May 2025 14:02:57 +0100
Subject: [PATCH v4 07/20] mfd: adp5585: add support for adp5589
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250521-dev-adp5589-fw-v4-7-f2c988d7a7a0@analog.com>
References: <20250521-dev-adp5589-fw-v4-0-f2c988d7a7a0@analog.com>
In-Reply-To: <20250521-dev-adp5589-fw-v4-0-f2c988d7a7a0@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747832589; l=9911;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=k2KSVoX2Jn3blHW/gOtL9OAtF5V+oBG5KQcm9ApKYkk=;
 b=AbkQ58K3pDZBSzUlWmKoxVs9xM9dEr2vwxyNeEIHBcVALbk0F/yVuMqq7lpYZZ31kR61ohWQ5
 GGBG+yZA/j0BooLbsztmBisRFHoe6QWxypKoqSRZYp6hvW2vbZHOVz1
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADP5589 is a 19 I/O port expander with built-in keypad matrix decoder,
programmable logic, reset generator, and PWM generator.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c       | 139 +++++++++++++++++++++++++++++++++++++++-----
 include/linux/mfd/adp5585.h |  11 ++++
 2 files changed, 134 insertions(+), 16 deletions(-)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 672f3468bda5be6af85a5982c3626053b4cb59bf..53ac46365e56874a05855f1df1843717148f181a 100644
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
@@ -81,6 +95,45 @@ static const u8 adp5585_regmap_defaults_04[ADP5585_MAX_REG + 1] = {
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
 /* -1 since the enum starts at 1 for error checking in i2c_get_match_data()*/
 static const u8 *adp5585_regmap_defaults[ADP5585_MAX - 1] = {
 	[ADP5585_00 - 1] = adp5585_regmap_defaults_00,
@@ -88,6 +141,9 @@ static const u8 *adp5585_regmap_defaults[ADP5585_MAX - 1] = {
 	[ADP5585_02 - 1] = adp5585_regmap_defaults_02,
 	[ADP5585_03 - 1] = adp5585_regmap_defaults_00,
 	[ADP5585_04 - 1] = adp5585_regmap_defaults_04,
+	[ADP5589_00 - 1] = adp5589_regmap_defaults_00,
+	[ADP5589_01 - 1] = adp5589_regmap_defaults_01,
+	[ADP5589_02 - 1] = adp5589_regmap_defaults_02,
 };
 
 static const struct regmap_config adp5585_regmap_config_template = {
@@ -99,11 +155,39 @@ static const struct regmap_config adp5585_regmap_config_template = {
 	.num_reg_defaults_raw = ADP5585_MAX_REG + 1,
 };
 
-static void adp5585_fill_regmap_config(const struct adp5585_dev *adp5585,
+static const struct regmap_config adp5589_regmap_config_template = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = ADP5589_MAX_REG,
+	.volatile_table = &adp5589_volatile_regs,
+	.cache_type = REGCACHE_MAPLE,
+	.num_reg_defaults_raw = ADP5589_MAX_REG + 1,
+};
+
+static int adp5585_fill_variant_config(struct adp5585_dev *adp5585,
 				       struct regmap_config *regmap_config)
 {
-	*regmap_config = adp5585_regmap_config_template;
+	switch (adp5585->variant) {
+	case ADP5585_00:
+	case ADP5585_01:
+	case ADP5585_02:
+	case ADP5585_03:
+	case ADP5585_04:
+		*regmap_config = adp5585_regmap_config_template;
+		adp5585->id = ADP5585_MAN_ID_VALUE;
+		break;
+	case ADP5589_00:
+	case ADP5589_01:
+	case ADP5589_02:
+		*regmap_config = adp5589_regmap_config_template;
+		adp5585->id = ADP5589_MAN_ID_VALUE;
+		break;
+	default:
+		return -ENODEV;
+	}
+
 	regmap_config->reg_defaults_raw = adp5585_regmap_defaults[adp5585->variant - 1];
+	return 0;
 }
 
 static void adp5585_remove_devices(void *dev)
@@ -111,29 +195,35 @@ static void adp5585_remove_devices(void *dev)
 	mfd_remove_devices(dev);
 }
 
-static int adp5585_add_devices(struct device *dev)
+static int adp5585_add_devices(const struct adp5585_dev *adp5585)
 {
+	const struct mfd_cell *cells;
 	int ret;
 
-	if (device_property_present(dev, "#pwm-cells")) {
-		ret = mfd_add_devices(dev, PLATFORM_DEVID_AUTO,
-				      &adp5585_devs[ADP5585_DEV_PWM], 1, NULL, 0, NULL);
+	if (adp5585->id == ADP5585_MAN_ID_VALUE)
+		cells = adp5585_devs;
+	else
+		cells = adp5589_devs;
+
+	if (device_property_present(adp5585->dev, "#pwm-cells")) {
+		ret = mfd_add_devices(adp5585->dev, PLATFORM_DEVID_AUTO,
+				      &cells[ADP5585_DEV_PWM], 1, NULL, 0, NULL);
 		if (ret)
-			return dev_err_probe(dev, ret, "Failed to add pwm device\n");
+			return dev_err_probe(adp5585->dev, ret, "Failed to add pwm device\n");
 	}
 
-	if (device_property_present(dev, "#gpio-cells")) {
-		ret = mfd_add_devices(dev, PLATFORM_DEVID_AUTO,
-				      &adp5585_devs[ADP5585_DEV_GPIO], 1, NULL, 0, NULL);
+	if (device_property_present(adp5585->dev, "#gpio-cells")) {
+		ret = mfd_add_devices(adp5585->dev, PLATFORM_DEVID_AUTO,
+				      &cells[ADP5585_DEV_GPIO], 1, NULL, 0, NULL);
 		if (ret) {
-			ret = dev_err_probe(dev, ret, "Failed to add gpio device\n");
+			ret = dev_err_probe(adp5585->dev, ret, "Failed to add gpio device\n");
 			goto out_error;
 		}
 	}
 
-	return devm_add_action_or_reset(dev, adp5585_remove_devices, dev);
+	return devm_add_action_or_reset(adp5585->dev, adp5585_remove_devices, adp5585->dev);
 out_error:
-	mfd_remove_devices(dev);
+	mfd_remove_devices(adp5585->dev);
 	return ret;
 }
 
@@ -161,19 +251,24 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 	if (!adp5585->variant)
 		return -ENODEV;
 
-	adp5585_fill_regmap_config(adp5585, &regmap_config);
+	ret = adp5585_fill_variant_config(adp5585, &regmap_config);
+	if (ret)
+		return ret;
 
 	adp5585->regmap = devm_regmap_init_i2c(i2c, &regmap_config);
 	if (IS_ERR(adp5585->regmap))
 		return dev_err_probe(&i2c->dev, PTR_ERR(adp5585->regmap),
 				     "Failed to initialize register map\n");
 
+	adp5585->dev = &i2c->dev;
+
 	ret = regmap_read(adp5585->regmap, ADP5585_ID, &id);
 	if (ret)
 		return dev_err_probe(&i2c->dev, ret,
 				     "Failed to read device ID\n");
 
-	if ((id & ADP5585_MAN_ID_MASK) != ADP5585_MAN_ID_VALUE)
+	id &= ADP5585_MAN_ID_MASK;
+	if (id != adp5585->id)
 		return dev_err_probe(&i2c->dev, -ENODEV,
 				     "Invalid device ID 0x%02x\n", id);
 
@@ -193,7 +288,7 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 	if (ret)
 		return ret;
 
-	return adp5585_add_devices(&i2c->dev);
+	return adp5585_add_devices(adp5585);
 }
 
 static int adp5585_suspend(struct device *dev)
@@ -233,6 +328,18 @@ static const struct of_device_id adp5585_of_match[] = {
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
index 2813b20e638b6e73ef198e43af07ef29ff25f273..40c87981e5a24f8a175cc41e38b1495ed9f194e5 100644
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
@@ -125,12 +131,17 @@ enum adp5585_variant {
 	ADP5585_02,
 	ADP5585_03,
 	ADP5585_04,
+	ADP5589_00,
+	ADP5589_01,
+	ADP5589_02,
 	ADP5585_MAX
 };
 
 struct adp5585_dev {
 	struct regmap *regmap;
+	struct device *dev;
 	enum adp5585_variant variant;
+	unsigned int id;
 };
 
 #endif

-- 
2.49.0

