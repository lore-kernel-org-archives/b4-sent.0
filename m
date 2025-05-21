From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 21 May 2025 14:02:56 +0100
Subject: [PATCH v4 06/20] mfd: adp5585: refactor how regmap defaults are
 handled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250521-dev-adp5589-fw-v4-6-f2c988d7a7a0@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747832589; l=5705;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=+bKRPRHDlB5UcRH6Y+ry0EWgZpgBRDClxWSUnGqJZE0=;
 b=gYczCTw9p7/GoJPHSI1pXb4smrf7B0zW1ynsJnAYuc/G6infEBGx6L5dv1HGYJRsyfkhI7BzC
 cmQxfRizV3ECoQLmiZy7CXRp8LxSd1/Pz2htX344JMnwozk6tdazF6w
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The only thing changing between variants is the regmap default
registers. Hence, instead of having a regmap condig for every variant
(duplicating lots of fields), add a chip info type of structure with a
regmap id to identify which defaults to use and populate regmap_config
at runtime given a template plus the id. Also note that between
variants, the defaults can be the same which means the chip info
structure can be used in more than one compatible.

This will also make it simpler adding new chips with more variants.

Also note that the chip info structures are deliberately not const as
they will also contain lots of members that are the same between the
different devices variants and so we will fill those at runtime.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c       | 74 +++++++++++++++++++++------------------------
 include/linux/mfd/adp5585.h | 10 ++++++
 2 files changed, 44 insertions(+), 40 deletions(-)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 179dc284833ae8f39eefc6787dd2c7158dfd3ad7..672f3468bda5be6af85a5982c3626053b4cb59bf 100644
--- a/drivers/mfd/adp5585.c
+++ b/drivers/mfd/adp5585.c
@@ -81,42 +81,31 @@ static const u8 adp5585_regmap_defaults_04[ADP5585_MAX_REG + 1] = {
 	/* 0x38 */ 0x00, 0x00, 0x00, 0x00, 0x00,
 };
 
-enum adp5585_regmap_type {
-	ADP5585_REGMAP_00,
-	ADP5585_REGMAP_02,
-	ADP5585_REGMAP_04,
+/* -1 since the enum starts at 1 for error checking in i2c_get_match_data()*/
+static const u8 *adp5585_regmap_defaults[ADP5585_MAX - 1] = {
+	[ADP5585_00 - 1] = adp5585_regmap_defaults_00,
+	[ADP5585_01 - 1] = adp5585_regmap_defaults_00,
+	[ADP5585_02 - 1] = adp5585_regmap_defaults_02,
+	[ADP5585_03 - 1] = adp5585_regmap_defaults_00,
+	[ADP5585_04 - 1] = adp5585_regmap_defaults_04,
 };
 
-static const struct regmap_config adp5585_regmap_configs[] = {
-	[ADP5585_REGMAP_00] = {
-		.reg_bits = 8,
-		.val_bits = 8,
-		.max_register = ADP5585_MAX_REG,
-		.volatile_table = &adp5585_volatile_regs,
-		.cache_type = REGCACHE_MAPLE,
-		.reg_defaults_raw = adp5585_regmap_defaults_00,
-		.num_reg_defaults_raw = sizeof(adp5585_regmap_defaults_00),
-	},
-	[ADP5585_REGMAP_02] = {
-		.reg_bits = 8,
-		.val_bits = 8,
-		.max_register = ADP5585_MAX_REG,
-		.volatile_table = &adp5585_volatile_regs,
-		.cache_type = REGCACHE_MAPLE,
-		.reg_defaults_raw = adp5585_regmap_defaults_02,
-		.num_reg_defaults_raw = sizeof(adp5585_regmap_defaults_02),
-	},
-	[ADP5585_REGMAP_04] = {
-		.reg_bits = 8,
-		.val_bits = 8,
-		.max_register = ADP5585_MAX_REG,
-		.volatile_table = &adp5585_volatile_regs,
-		.cache_type = REGCACHE_MAPLE,
-		.reg_defaults_raw = adp5585_regmap_defaults_04,
-		.num_reg_defaults_raw = sizeof(adp5585_regmap_defaults_04),
-	},
+static const struct regmap_config adp5585_regmap_config_template = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = ADP5585_MAX_REG,
+	.volatile_table = &adp5585_volatile_regs,
+	.cache_type = REGCACHE_MAPLE,
+	.num_reg_defaults_raw = ADP5585_MAX_REG + 1,
 };
 
+static void adp5585_fill_regmap_config(const struct adp5585_dev *adp5585,
+				       struct regmap_config *regmap_config)
+{
+	*regmap_config = adp5585_regmap_config_template;
+	regmap_config->reg_defaults_raw = adp5585_regmap_defaults[adp5585->variant - 1];
+}
+
 static void adp5585_remove_devices(void *dev)
 {
 	mfd_remove_devices(dev);
@@ -157,7 +146,7 @@ static void adp5585_osc_disable(void *data)
 
 static int adp5585_i2c_probe(struct i2c_client *i2c)
 {
-	const struct regmap_config *regmap_config;
+	struct regmap_config regmap_config;
 	struct adp5585_dev *adp5585;
 	unsigned int id;
 	int ret;
@@ -168,8 +157,13 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 
 	i2c_set_clientdata(i2c, adp5585);
 
-	regmap_config = i2c_get_match_data(i2c);
-	adp5585->regmap = devm_regmap_init_i2c(i2c, regmap_config);
+	adp5585->variant = (enum adp5585_variant)(uintptr_t)i2c_get_match_data(i2c);
+	if (!adp5585->variant)
+		return -ENODEV;
+
+	adp5585_fill_regmap_config(adp5585, &regmap_config);
+
+	adp5585->regmap = devm_regmap_init_i2c(i2c, &regmap_config);
 	if (IS_ERR(adp5585->regmap))
 		return dev_err_probe(&i2c->dev, PTR_ERR(adp5585->regmap),
 				     "Failed to initialize register map\n");
@@ -226,19 +220,19 @@ static DEFINE_SIMPLE_DEV_PM_OPS(adp5585_pm, adp5585_suspend, adp5585_resume);
 static const struct of_device_id adp5585_of_match[] = {
 	{
 		.compatible = "adi,adp5585-00",
-		.data = &adp5585_regmap_configs[ADP5585_REGMAP_00],
+		.data = (void *)ADP5585_00,
 	}, {
 		.compatible = "adi,adp5585-01",
-		.data = &adp5585_regmap_configs[ADP5585_REGMAP_00],
+		.data = (void *)ADP5585_01,
 	}, {
 		.compatible = "adi,adp5585-02",
-		.data = &adp5585_regmap_configs[ADP5585_REGMAP_02],
+		.data = (void *)ADP5585_02,
 	}, {
 		.compatible = "adi,adp5585-03",
-		.data = &adp5585_regmap_configs[ADP5585_REGMAP_00],
+		.data = (void *)ADP5585_03,
 	}, {
 		.compatible = "adi,adp5585-04",
-		.data = &adp5585_regmap_configs[ADP5585_REGMAP_04],
+		.data = (void *)ADP5585_04,
 	},
 	{ /* sentinel */ }
 };
diff --git a/include/linux/mfd/adp5585.h b/include/linux/mfd/adp5585.h
index 016033cd68e46757aca86d21dd37025fd354b801..2813b20e638b6e73ef198e43af07ef29ff25f273 100644
--- a/include/linux/mfd/adp5585.h
+++ b/include/linux/mfd/adp5585.h
@@ -119,8 +119,18 @@
 
 struct regmap;
 
+enum adp5585_variant {
+	ADP5585_00 = 1,
+	ADP5585_01,
+	ADP5585_02,
+	ADP5585_03,
+	ADP5585_04,
+	ADP5585_MAX
+};
+
 struct adp5585_dev {
 	struct regmap *regmap;
+	enum adp5585_variant variant;
 };
 
 #endif

-- 
2.49.0

