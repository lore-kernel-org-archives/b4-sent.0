From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 13 Mar 2025 14:19:24 +0000
Subject: [PATCH 07/18] gpio: adp5585: add support for the ad5589 expander
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250313-dev-adp5589-fw-v1-7-20e80d4bd4ea@analog.com>
References: <20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com>
In-Reply-To: <20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741875561; l=9246;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=En/L9MCOHXbURTimhYsnktNaqCUSWhDUSGL0YSjg2b4=;
 b=GLsjrr6HEqHGMIJ06AjYlbAdVNkx4dcE2FlN1hmWi7lCe+hKlo8Vw2jqtlKhWU0b1sI8izUTw
 wdkIRfzPGTsDQAbBksHAbOrB7W6PNk9/RVUBuJ7CEVmsUXlw+8dFoRT
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support the adp5589 I/O expander which supports up to 19 pins. We need
to add a chip_info based struct since accessing register "banks"
and "bits" differs between devices.

Also some register addresses are different.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/gpio/gpio-adp5585.c | 120 ++++++++++++++++++++++++++++++++------------
 1 file changed, 88 insertions(+), 32 deletions(-)

diff --git a/drivers/gpio/gpio-adp5585.c b/drivers/gpio/gpio-adp5585.c
index 000d31f09671022e27b9087f9f01593520535b12..fded9ff35a59fc1a0ce173c58dbd7b6af176958f 100644
--- a/drivers/gpio/gpio-adp5585.c
+++ b/drivers/gpio/gpio-adp5585.c
@@ -4,6 +4,7 @@
  *
  * Copyright 2022 NXP
  * Copyright 2024 Ideas on Board Oy
+ * Copyright 2025 Analog Devices, Inc.
  */
 
 #include <linux/device.h>
@@ -14,21 +15,49 @@
 #include <linux/regmap.h>
 #include <linux/types.h>
 
-#define ADP5585_GPIO_MAX	11
+struct adp5585_gpio_chip {
+	unsigned int max_gpio;
+	int (*bank)(unsigned int off);
+	int (*bit)(unsigned int off);
+	bool has_bias_hole;
+};
 
 struct adp5585_gpio_dev {
 	struct gpio_chip gpio_chip;
+	const struct adp5585_gpio_chip *info;
 	struct regmap *regmap;
+	const struct adp5585_regs *regs;
 };
 
+static int adp5585_gpio_bank(unsigned int off)
+{
+	return ADP5585_BANK(off);
+}
+
+static int adp5585_gpio_bit(unsigned int off)
+{
+	return ADP5585_BIT(off);
+}
+
+static int adp5589_gpio_bank(unsigned int off)
+{
+	return ADP5589_BANK(off);
+}
+
+static int adp5589_gpio_bit(unsigned int off)
+{
+	return ADP5589_BIT(off);
+}
+
 static int adp5585_gpio_get_direction(struct gpio_chip *chip, unsigned int off)
 {
 	struct adp5585_gpio_dev *adp5585_gpio = gpiochip_get_data(chip);
-	unsigned int bank = ADP5585_BANK(off);
-	unsigned int bit = ADP5585_BIT(off);
+	const struct adp5585_regs *regs = adp5585_gpio->regs;
+	unsigned int bank = adp5585_gpio->info->bank(off);
+	unsigned int bit = adp5585_gpio->info->bit(off);
 	unsigned int val;
 
-	regmap_read(adp5585_gpio->regmap, ADP5585_GPIO_DIRECTION_A + bank, &val);
+	regmap_read(adp5585_gpio->regmap, regs->gpio_dir_a + bank, &val);
 
 	return val & bit ? GPIO_LINE_DIRECTION_OUT : GPIO_LINE_DIRECTION_IN;
 }
@@ -36,35 +65,37 @@ static int adp5585_gpio_get_direction(struct gpio_chip *chip, unsigned int off)
 static int adp5585_gpio_direction_input(struct gpio_chip *chip, unsigned int off)
 {
 	struct adp5585_gpio_dev *adp5585_gpio = gpiochip_get_data(chip);
-	unsigned int bank = ADP5585_BANK(off);
-	unsigned int bit = ADP5585_BIT(off);
+	const struct adp5585_regs *regs = adp5585_gpio->regs;
+	unsigned int bank = adp5585_gpio->info->bank(off);
+	unsigned int bit = adp5585_gpio->info->bit(off);
 
-	return regmap_clear_bits(adp5585_gpio->regmap,
-				 ADP5585_GPIO_DIRECTION_A + bank, bit);
+	return regmap_clear_bits(adp5585_gpio->regmap, regs->gpio_dir_a + bank,
+				 bit);
 }
 
 static int adp5585_gpio_direction_output(struct gpio_chip *chip, unsigned int off, int val)
 {
 	struct adp5585_gpio_dev *adp5585_gpio = gpiochip_get_data(chip);
-	unsigned int bank = ADP5585_BANK(off);
-	unsigned int bit = ADP5585_BIT(off);
+	const struct adp5585_regs *regs = adp5585_gpio->regs;
+	unsigned int bank = adp5585_gpio->info->bank(off);
+	unsigned int bit = adp5585_gpio->info->bit(off);
 	int ret;
 
-	ret = regmap_update_bits(adp5585_gpio->regmap,
-				 ADP5585_GPO_DATA_OUT_A + bank, bit,
-				 val ? bit : 0);
+	ret = regmap_update_bits(adp5585_gpio->regmap, regs->gpo_data_a + bank,
+				 bit, val ? bit : 0);
 	if (ret)
 		return ret;
 
-	return regmap_set_bits(adp5585_gpio->regmap,
-			       ADP5585_GPIO_DIRECTION_A + bank, bit);
+	return regmap_set_bits(adp5585_gpio->regmap, regs->gpio_dir_a + bank,
+			       bit);
 }
 
 static int adp5585_gpio_get_value(struct gpio_chip *chip, unsigned int off)
 {
 	struct adp5585_gpio_dev *adp5585_gpio = gpiochip_get_data(chip);
-	unsigned int bank = ADP5585_BANK(off);
-	unsigned int bit = ADP5585_BIT(off);
+	const struct adp5585_regs *regs = adp5585_gpio->regs;
+	unsigned int bank = adp5585_gpio->info->bank(off);
+	unsigned int bit = adp5585_gpio->info->bit(off);
 	unsigned int reg;
 	unsigned int val;
 
@@ -79,8 +110,8 @@ static int adp5585_gpio_get_value(struct gpio_chip *chip, unsigned int off)
 	 * .direction_input(), .direction_output() or .set() operations racing
 	 * with this.
 	 */
-	regmap_read(adp5585_gpio->regmap, ADP5585_GPIO_DIRECTION_A + bank, &val);
-	reg = val & bit ? ADP5585_GPO_DATA_OUT_A : ADP5585_GPI_STATUS_A;
+	regmap_read(adp5585_gpio->regmap, regs->gpio_dir_a + bank, &val);
+	reg = val & bit ? regs->gpo_data_a : regs->gpi_stat_a;
 	regmap_read(adp5585_gpio->regmap, reg + bank, &val);
 
 	return !!(val & bit);
@@ -89,16 +120,19 @@ static int adp5585_gpio_get_value(struct gpio_chip *chip, unsigned int off)
 static void adp5585_gpio_set_value(struct gpio_chip *chip, unsigned int off, int val)
 {
 	struct adp5585_gpio_dev *adp5585_gpio = gpiochip_get_data(chip);
-	unsigned int bank = ADP5585_BANK(off);
-	unsigned int bit = ADP5585_BIT(off);
+	const struct adp5585_regs *regs = adp5585_gpio->regs;
+	unsigned int bank = adp5585_gpio->info->bank(off);
+	unsigned int bit = adp5585_gpio->info->bit(off);
 
-	regmap_update_bits(adp5585_gpio->regmap, ADP5585_GPO_DATA_OUT_A + bank,
+	regmap_update_bits(adp5585_gpio->regmap, regs->gpo_data_a + bank,
 			   bit, val ? bit : 0);
 }
 
 static int adp5585_gpio_set_bias(struct adp5585_gpio_dev *adp5585_gpio,
 				 unsigned int off, unsigned int bias)
 {
+	const struct adp5585_gpio_chip *info = adp5585_gpio->info;
+	const struct adp5585_regs *regs = adp5585_gpio->regs;
 	unsigned int bit, reg, mask, val;
 
 	/*
@@ -106,8 +140,10 @@ static int adp5585_gpio_set_bias(struct adp5585_gpio_dev *adp5585_gpio,
 	 * consecutive registers ADP5585_RPULL_CONFIG_*, with a hole of 4 bits
 	 * after R5.
 	 */
-	bit = off * 2 + (off > 5 ? 4 : 0);
-	reg = ADP5585_RPULL_CONFIG_A + bit / 8;
+	bit = off * 2;
+	if (info->has_bias_hole)
+		bit += (off > 5 ? 4 : 0);
+	reg = regs->rpull_cfg_a + bit / 8;
 	mask = ADP5585_Rx_PULL_CFG_MASK << (bit % 8);
 	val = bias << (bit % 8);
 
@@ -117,22 +153,24 @@ static int adp5585_gpio_set_bias(struct adp5585_gpio_dev *adp5585_gpio,
 static int adp5585_gpio_set_drive(struct adp5585_gpio_dev *adp5585_gpio,
 				  unsigned int off, enum pin_config_param drive)
 {
-	unsigned int bank = ADP5585_BANK(off);
-	unsigned int bit = ADP5585_BIT(off);
+	const struct adp5585_regs *regs = adp5585_gpio->regs;
+	unsigned int bank = adp5585_gpio->info->bank(off);
+	unsigned int bit = adp5585_gpio->info->bit(off);
 
 	return regmap_update_bits(adp5585_gpio->regmap,
-				  ADP5585_GPO_OUT_MODE_A + bank, bit,
+				  regs->gpo_out_a + bank, bit,
 				  drive == PIN_CONFIG_DRIVE_OPEN_DRAIN ? bit : 0);
 }
 
 static int adp5585_gpio_set_debounce(struct adp5585_gpio_dev *adp5585_gpio,
 				     unsigned int off, unsigned int debounce)
 {
-	unsigned int bank = ADP5585_BANK(off);
-	unsigned int bit = ADP5585_BIT(off);
+	const struct adp5585_regs *regs = adp5585_gpio->regs;
+	unsigned int bank = adp5585_gpio->info->bank(off);
+	unsigned int bit = adp5585_gpio->info->bit(off);
 
 	return regmap_update_bits(adp5585_gpio->regmap,
-				  ADP5585_DEBOUNCE_DIS_A + bank, bit,
+				  regs->debounce_dis_a + bank, bit,
 				  debounce ? 0 : bit);
 }
 
@@ -173,6 +211,7 @@ static int adp5585_gpio_set_config(struct gpio_chip *chip, unsigned int off,
 static int adp5585_gpio_probe(struct platform_device *pdev)
 {
 	struct adp5585_dev *adp5585 = dev_get_drvdata(pdev->dev.parent);
+	const struct platform_device_id *id = platform_get_device_id(pdev);
 	struct adp5585_gpio_dev *adp5585_gpio;
 	struct device *dev = &pdev->dev;
 	struct gpio_chip *gc;
@@ -183,6 +222,11 @@ static int adp5585_gpio_probe(struct platform_device *pdev)
 		return -ENOMEM;
 
 	adp5585_gpio->regmap = adp5585->regmap;
+	adp5585_gpio->regs = adp5585->info->regs;
+
+	adp5585_gpio->info = (const struct adp5585_gpio_chip *)id->driver_data;
+	if (!adp5585_gpio->info)
+		return -ENODEV;
 
 	device_set_of_node_from_dev(dev, dev->parent);
 
@@ -197,7 +241,7 @@ static int adp5585_gpio_probe(struct platform_device *pdev)
 	gc->can_sleep = true;
 
 	gc->base = -1;
-	gc->ngpio = ADP5585_GPIO_MAX;
+	gc->ngpio = adp5585->info->max_cols + adp5585->info->max_rows;
 	gc->label = pdev->name;
 	gc->owner = THIS_MODULE;
 
@@ -209,8 +253,20 @@ static int adp5585_gpio_probe(struct platform_device *pdev)
 	return 0;
 }
 
+static const struct adp5585_gpio_chip adp5585_gpio_chip_info = {
+	.bank = adp5585_gpio_bank,
+	.bit = adp5585_gpio_bit,
+	.has_bias_hole = true,
+};
+
+static const struct adp5585_gpio_chip adp5589_gpio_chip_info = {
+	.bank = adp5589_gpio_bank,
+	.bit = adp5589_gpio_bit,
+};
+
 static const struct platform_device_id adp5585_gpio_id_table[] = {
-	{ "adp5585-gpio" },
+	{ "adp5585-gpio", (kernel_ulong_t)&adp5585_gpio_chip_info },
+	{ "adp5589-gpio", (kernel_ulong_t)&adp5589_gpio_chip_info },
 	{ /* Sentinel */ }
 };
 MODULE_DEVICE_TABLE(platform, adp5585_gpio_id_table);

-- 
2.48.1

