From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 12 May 2025 13:39:00 +0100
Subject: [PATCH v3 08/22] mfd: adp5585: add support for adp5589
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250512-dev-adp5589-fw-v3-8-092b14b79a88@analog.com>
References: <20250512-dev-adp5589-fw-v3-0-092b14b79a88@analog.com>
In-Reply-To: <20250512-dev-adp5589-fw-v3-0-092b14b79a88@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747053537; l=8627;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=7qn1pDEf2sTXJl+c3cm0c/bVSfL9pSKfy2RjaXpglzM=;
 b=TWxCFplEKaic4WWNCC3bq62E9fHJ/E8Y1LlN/i/0FSjOiQD17+VxP4Rdhni1ot17O0sjnp+nr
 4hLvdYftnf5D8AfzfYF2i8NIbq3dXgdgHqaxUKztH4IYht3XZM6ylKa
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADP5589 is a 19 I/O port expander with built-in keypad matrix decoder,
programmable logic, reset generator, and PWM generator.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c       | 119 ++++++++++++++++++++++++++++++++++++++++++--
 include/linux/mfd/adp5585.h |  10 ++++
 2 files changed, 125 insertions(+), 4 deletions(-)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 874aed7d7cfe052587720d899096c995c19667af..d593d21920c960f397a79f1b3f5c7118fedea73a 100644
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
@@ -81,6 +95,54 @@ static const u8 adp5585_regmap_defaults_04[ADP5585_MAX_REG + 1] = {
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
+static const struct regmap_config adp5589_regmap_config_template = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = ADP5589_MAX_REG,
+	.volatile_table = &adp5589_volatile_regs,
+	.cache_type = REGCACHE_MAPLE,
+	.num_reg_defaults_raw = ADP5589_MAX_REG + 1,
+};
+
 static const struct regmap_config adp5585_regmap_config_template = {
 	.reg_bits = 8,
 	.val_bits = 8,
@@ -93,7 +155,10 @@ static const struct regmap_config adp5585_regmap_config_template = {
 static int adp5585_fill_regmap_config(const struct adp5585_dev *adp5585,
 				      struct regmap_config *regmap_config)
 {
-	*regmap_config = adp5585_regmap_config_template;
+	if (adp5585->info->id == ADP5585_MAN_ID_VALUE)
+		*regmap_config = adp5585_regmap_config_template;
+	else
+		*regmap_config = adp5589_regmap_config_template;
 
 	switch (adp5585->info->regmap_type) {
 	case ADP5585_REGMAP_00:
@@ -105,6 +170,15 @@ static int adp5585_fill_regmap_config(const struct adp5585_dev *adp5585,
 	case ADP5585_REGMAP_04:
 		regmap_config->reg_defaults_raw = adp5585_regmap_defaults_04;
 		return 0;
+	case ADP5589_REGMAP_00:
+		regmap_config->reg_defaults_raw = adp5589_regmap_defaults_00;
+		return 0;
+	case ADP5589_REGMAP_01:
+		regmap_config->reg_defaults_raw = adp5589_regmap_defaults_01;
+		return 0;
+	case ADP5589_REGMAP_02:
+		regmap_config->reg_defaults_raw = adp5589_regmap_defaults_02;
+		return 0;
 	default:
 		return -ENODEV;
 	}
@@ -114,6 +188,7 @@ static int adp5585_parse_fw(struct device *dev, struct adp5585_dev *adp5585,
 			    struct mfd_cell **devs)
 {
 	unsigned int has_pwm = 0, has_gpio = 0, rc = 0;
+	const struct mfd_cell *cells;
 
 	if (device_property_present(dev, "#pwm-cells"))
 		has_pwm = 1;
@@ -129,10 +204,15 @@ static int adp5585_parse_fw(struct device *dev, struct adp5585_dev *adp5585,
 	if (!*devs)
 		return -ENOMEM;
 
+	if (adp5585->info->id == ADP5585_MAN_ID_VALUE)
+		cells = adp5585_devs;
+	else
+		cells = adp5589_devs;
+
 	if (has_pwm)
-		(*devs)[rc++] = adp5585_devs[ADP5585_DEV_PWM];
+		(*devs)[rc++] = cells[ADP5585_DEV_PWM];
 	if (has_gpio)
-		(*devs)[rc++] = adp5585_devs[ADP5585_DEV_GPIO];
+		(*devs)[rc++] = cells[ADP5585_DEV_GPIO];
 
 	return rc;
 }
@@ -176,7 +256,8 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 		return dev_err_probe(&i2c->dev, ret,
 				     "Failed to read device ID\n");
 
-	if ((id & ADP5585_MAN_ID_MASK) != ADP5585_MAN_ID_VALUE)
+	id &= ADP5585_MAN_ID_MASK;
+	if (id != adp5585->info->id)
 		return dev_err_probe(&i2c->dev, -ENODEV,
 				     "Invalid device ID 0x%02x\n", id);
 
@@ -225,14 +306,32 @@ static DEFINE_SIMPLE_DEV_PM_OPS(adp5585_pm, adp5585_suspend, adp5585_resume);
 
 static struct adp5585_info adp5585_info = {
 	.regmap_type = ADP5585_REGMAP_00,
+	.id = ADP5585_MAN_ID_VALUE,
 };
 
 static struct adp5585_info adp5585_02_info = {
 	.regmap_type = ADP5585_REGMAP_02,
+	.id = ADP5585_MAN_ID_VALUE,
 };
 
 static struct adp5585_info adp5585_04_info = {
 	.regmap_type = ADP5585_REGMAP_04,
+	.id = ADP5585_MAN_ID_VALUE,
+};
+
+static struct adp5585_info adp5589_info = {
+	.regmap_type = ADP5589_REGMAP_00,
+	.id = ADP5589_MAN_ID_VALUE,
+};
+
+static struct adp5585_info adp5589_01_info = {
+	.regmap_type = ADP5589_REGMAP_01,
+	.id = ADP5589_MAN_ID_VALUE,
+};
+
+static struct adp5585_info adp5589_02_info = {
+	.regmap_type = ADP5589_REGMAP_02,
+	.id = ADP5589_MAN_ID_VALUE,
 };
 
 static const struct of_device_id adp5585_of_match[] = {
@@ -251,6 +350,18 @@ static const struct of_device_id adp5585_of_match[] = {
 	}, {
 		.compatible = "adi,adp5585-04",
 		.data = &adp5585_04_info,
+	}, {
+		.compatible = "adi,adp5589-00",
+		.data = &adp5589_info,
+	}, {
+		.compatible = "adi,adp5589-01",
+		.data = &adp5589_01_info,
+	}, {
+		.compatible = "adi,adp5589-02",
+		.data = &adp5589_02_info,
+	}, {
+		.compatible = "adi,adp5589",
+		.data = &adp5589_info,
 	},
 	{ /* sentinel */ }
 };
diff --git a/include/linux/mfd/adp5585.h b/include/linux/mfd/adp5585.h
index 4b48614970a811a8a95116faa20e58ea4f19ede6..5e19e38d4eac563275b01c3ec613ea62eba9d6c6 100644
--- a/include/linux/mfd/adp5585.h
+++ b/include/linux/mfd/adp5585.h
@@ -117,16 +117,26 @@
 #define ADP5585_BANK(n)			((n) >= 6 ? 1 : 0)
 #define ADP5585_BIT(n)			((n) >= 6 ? BIT((n) - 6) : BIT(n))
 
+/* ADP5589 */
+#define		ADP5589_MAN_ID_VALUE		0x10
+#define ADP5589_GPI_STATUS_C		0x18
+#define ADP5589_INT_EN			0x4e
+#define ADP5589_MAX_REG			ADP5589_INT_EN
+
 struct regmap;
 
 enum adp5585_regmap_type {
 	ADP5585_REGMAP_00,
 	ADP5585_REGMAP_02,
 	ADP5585_REGMAP_04,
+	ADP5589_REGMAP_00,
+	ADP5589_REGMAP_01,
+	ADP5589_REGMAP_02,
 };
 
 struct adp5585_info {
 	enum adp5585_regmap_type regmap_type;
+	unsigned int id;
 };
 
 struct adp5585_dev {

-- 
2.49.0

