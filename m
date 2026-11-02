From: Joseph Telaak <joseph@telaak.dev>
Date: Sun, 01 Nov 2026 21:12:30 -0500
Subject: [PATCH 06/10] leds: rgb: ktd202x: Add Etek ET6326 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261101-ktd202x-et6326-v1-6-eb51eddad08c@telaak.dev>
References: <20261101-ktd202x-et6326-v1-0-eb51eddad08c@telaak.dev>
In-Reply-To: <20261101-ktd202x-et6326-v1-0-eb51eddad08c@telaak.dev>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Griffin Kroah-Hartman <griffin@kroah.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793585580; l=7205;
 i=joseph@telaak.dev; s=20261102; h=from:subject:message-id;
 bh=EDSEEKnZbgPM84oqWMmfTjcdXc8/pynn0DZ6HSEYqy0=;
 b=y61qxLIjTsX8AO6fuo+ealRBWXF8ThvZVs0APTjtakRodlSOCC9o4PKYYxswtWwSaxDXcrSVQ
 7QNLRsQg2UaCKuCBDWUho8vs+VZWRhWUMPKLXJezdzSGFZoo99JTTA6
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=OmwSusdK4grZpiuZVfCZAvYyqz9FBkNemsV1EnHyVr4=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261102 with auth_id=1382
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Etek ET6326 is a KTD2026 with a different flash period encoding:
Reg1 = n selects (n + 1) * 128 ms, from 128 ms to 16.38 s, where the
KTD202x selects 256 ms + n * 128 ms and uses Reg1 = 127 for one shot
mode.

Move the number of LEDs and the flash period limits into per chip data
and add the ET6326, so the timer trigger gets the delays it asked for.

Link: https://www.etekmicro.com/wp-content/uploads/datasheets/ET6326_datasheet.pdf

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/Kconfig        |  3 +-
 drivers/leds/rgb/leds-ktd202x.c | 64 +++++++++++++++++++++++++++++++----------
 2 files changed, 51 insertions(+), 16 deletions(-)

diff --git a/drivers/leds/rgb/Kconfig b/drivers/leds/rgb/Kconfig
index 6e9ab5f60..3a57e5819 100644
--- a/drivers/leds/rgb/Kconfig
+++ b/drivers/leds/rgb/Kconfig
@@ -20,7 +20,8 @@ config LEDS_KTD202X
 	select REGMAP_I2C
 	help
 	  This option enables support for the Kinetic KTD2026/KTD2027
-	  RGB/White LED driver found in different BQ mobile phones.
+	  RGB/White LED driver found in different BQ mobile phones, and
+	  for the compatible Etek ET6326.
 	  It is a 3 or 4 channel LED driver programmed via an I2C interface.
 
 	  To compile this driver as a module, choose M here: the module
diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index feea33b7e..67e65c1fc 100644
--- a/drivers/leds/rgb/leds-ktd202x.c
+++ b/drivers/leds/rgb/leds-ktd202x.c
@@ -5,6 +5,7 @@
  * Copyright 2023 André Apitzsch <git@apitzsch.eu>
  *
  * Datasheet: https://www.kinet-ic.com/uploads/KTD2026-7-04h.pdf
+ * Datasheet: https://www.etekmicro.com/wp-content/uploads/datasheets/ET6326_datasheet.pdf
  */
 
 #include <linux/i2c.h>
@@ -65,9 +66,7 @@
 /* Register 6-9 */
 #define KTD202X_LED_CURRENT_10_mA		0x4f
 
-#define KTD202X_FLASH_PERIOD_MIN_MS 256
 #define KTD202X_FLASH_PERIOD_STEP_MS 128
-#define KTD202X_FLASH_PERIOD_MAX_STEPS 126
 #define KTD202X_FLASH_ON_MAX 256
 
 #define KTD202X_MAX_BRIGHTNESS 192
@@ -86,6 +85,33 @@ static const struct reg_default ktd202x_reg_defaults[] = {
 	{ KTD202X_REG_LED_IOUT(3), KTD202X_LED_CURRENT_10_mA },
 };
 
+struct ktd202x_info {
+	unsigned long num_leds;
+	/* Flash period encoded by a Reg1 value of 0 */
+	unsigned int flash_period_min_ms;
+	unsigned int flash_period_max_steps;
+};
+
+/* Reg1 = 127 selects one shot mode on the KTD202x */
+static const struct ktd202x_info ktd2026_info = {
+	.num_leds = KTD2026_NUM_LEDS,
+	.flash_period_min_ms = 256,
+	.flash_period_max_steps = 126,
+};
+
+static const struct ktd202x_info ktd2027_info = {
+	.num_leds = KTD2027_NUM_LEDS,
+	.flash_period_min_ms = 256,
+	.flash_period_max_steps = 126,
+};
+
+/* The ET6326 flash period is (Reg1 + 1) * 128 ms, up to 16.38 s */
+static const struct ktd202x_info et6326_info = {
+	.num_leds = KTD2026_NUM_LEDS,
+	.flash_period_min_ms = 128,
+	.flash_period_max_steps = 127,
+};
+
 struct ktd202x_led {
 	struct ktd202x *chip;
 	union {
@@ -100,6 +126,7 @@ struct ktd202x {
 	struct regulator_bulk_data regulators[2];
 	struct device *dev;
 	struct regmap *regmap;
+	const struct ktd202x_info *info;
 	bool enabled;
 	unsigned long num_leds;
 	struct ktd202x_led leds[] __counted_by(num_leds);
@@ -271,6 +298,7 @@ static int ktd202x_blink_set(struct ktd202x_led *led, unsigned long *delay_on,
 			     unsigned long *delay_off, struct mc_subled *subleds,
 			     unsigned int num_channels)
 {
+	const struct ktd202x_info *info = led->chip->info;
 	unsigned long delay_total_ms;
 	int ret, num_steps, on;
 	u8 ctrl_mask = 0;
@@ -300,11 +328,11 @@ static int ktd202x_blink_set(struct ktd202x_led *led, unsigned long *delay_on,
 	/* Integer representation of time of flash period */
 	if (check_add_overflow(*delay_on, *delay_off, &delay_total_ms))
 		delay_total_ms = ULONG_MAX;
-	if (delay_total_ms < KTD202X_FLASH_PERIOD_MIN_MS)
+	if (delay_total_ms < info->flash_period_min_ms)
 		num_steps = 0;
 	else
-		num_steps = min_t(unsigned long, KTD202X_FLASH_PERIOD_MAX_STEPS,
-				  (delay_total_ms - KTD202X_FLASH_PERIOD_MIN_MS) /
+		num_steps = min_t(unsigned long, info->flash_period_max_steps,
+				  (delay_total_ms - info->flash_period_min_ms) /
 				  KTD202X_FLASH_PERIOD_STEP_MS);
 
 	/*
@@ -315,7 +343,7 @@ static int ktd202x_blink_set(struct ktd202x_led *led, unsigned long *delay_on,
 	on = clamp(on, 1, KTD202X_FLASH_ON_MAX - 1);
 
 	/* Actually used delay_{on,off} values */
-	delay_total_ms = num_steps * KTD202X_FLASH_PERIOD_STEP_MS + KTD202X_FLASH_PERIOD_MIN_MS;
+	delay_total_ms = num_steps * KTD202X_FLASH_PERIOD_STEP_MS + info->flash_period_min_ms;
 	*delay_on = (delay_total_ms * on) / KTD202X_FLASH_ON_MAX;
 	*delay_off = delay_total_ms - *delay_on;
 
@@ -543,8 +571,8 @@ static const struct regmap_config ktd202x_regmap_config = {
 static int ktd202x_probe(struct i2c_client *client)
 {
 	struct device *dev = &client->dev;
+	const struct ktd202x_info *info;
 	struct ktd202x *chip;
-	unsigned long num_leds;
 	int count;
 	int ret;
 
@@ -552,13 +580,17 @@ static int ktd202x_probe(struct i2c_client *client)
 	if (!count || count > KTD202X_MAX_LEDS)
 		return dev_err_probe(dev, -EINVAL, "Incorrect number of leds (%d)", count);
 
+	info = i2c_get_match_data(client);
+	if (!info)
+		return -ENODEV;
+
 	/* Loops over the LEDs go up to the number of channels, not of child nodes */
-	num_leds = (unsigned long)i2c_get_match_data(client);
-	chip = devm_kzalloc(dev, struct_size(chip, leds, num_leds), GFP_KERNEL);
+	chip = devm_kzalloc(dev, struct_size(chip, leds, info->num_leds), GFP_KERNEL);
 	if (!chip)
 		return -ENOMEM;
 
-	chip->num_leds = num_leds;
+	chip->info = info;
+	chip->num_leds = info->num_leds;
 	chip->dev = dev;
 	i2c_set_clientdata(client, chip);
 
@@ -618,15 +650,17 @@ static void ktd202x_shutdown(struct i2c_client *client)
 }
 
 static const struct i2c_device_id ktd202x_id[] = {
-	{ .name = "ktd2026", .driver_data = KTD2026_NUM_LEDS },
-	{ .name = "ktd2027", .driver_data = KTD2027_NUM_LEDS },
+	{ .name = "et6326", .driver_data = (kernel_ulong_t)&et6326_info },
+	{ .name = "ktd2026", .driver_data = (kernel_ulong_t)&ktd2026_info },
+	{ .name = "ktd2027", .driver_data = (kernel_ulong_t)&ktd2027_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(i2c, ktd202x_id);
 
 static const struct of_device_id ktd202x_match_table[] = {
-	{ .compatible = "kinetic,ktd2026", .data = (void *)KTD2026_NUM_LEDS },
-	{ .compatible = "kinetic,ktd2027", .data = (void *)KTD2027_NUM_LEDS },
+	{ .compatible = "etekmicro,et6326", .data = &et6326_info },
+	{ .compatible = "kinetic,ktd2026", .data = &ktd2026_info },
+	{ .compatible = "kinetic,ktd2027", .data = &ktd2027_info },
 	{}
 };
 MODULE_DEVICE_TABLE(of, ktd202x_match_table);
@@ -644,5 +678,5 @@ static struct i2c_driver ktd202x_driver = {
 module_i2c_driver(ktd202x_driver);
 
 MODULE_AUTHOR("André Apitzsch <git@apitzsch.eu>");
-MODULE_DESCRIPTION("Kinetic KTD2026/7 LED driver");
+MODULE_DESCRIPTION("Kinetic KTD2026/7 and Etek ET6326 LED driver");
 MODULE_LICENSE("GPL");

-- 
Git-155)

