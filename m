From: =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
Date: Fri, 11 Sep 2026 11:50:59 +0300
Subject: [PATCH RFC 02/10] backlight: add Kinetic KTD3136 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260911-ginkgo-submission-final-v1-2-0e68e63a18d4@gmail.com>
References: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
In-Reply-To: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, freedreno@lists.freedesktop.org, 
 =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789116671; l=9823;
 i=kavakliyigitcan@gmail.com; s=20260911; h=from:subject:message-id;
 bh=8Ih2UoC1pWddpS9nkG45rJdtms13+QwT/ouhD5LyozY=;
 b=Dx8bPGEZ2uGrLkJT2P7tEyqMXH4gUyoY3n3rwJuwml4sJGe16fC18INNJnQmQXjXTq0Cl5K6D
 b791WhHQrfiAWAOnnHoNjN7b35Iorgi4cMcXxqJGU8ZEyqQySohuWlj
X-Developer-Key: i=kavakliyigitcan@gmail.com; a=ed25519;
 pk=W2GaxVotULs2vAjRMMLheaDtMMYs4037zO1LVVfFtPI=
X-Endpoint-Received: by B4 Relay for kavakliyigitcan@gmail.com/20260911 with auth_id=1024
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement a generic Linux backlight driver for the Kinetic Technologies
KTD3136 36V, 6-channel LED driver.

The driver provides:
- Standard Linux backlight class interface (struct backlight_ops)
- 11-bit linear dimming resolution (0..2047 steps)
- Optional hardware enable (HWEN) GPIO sequencing
- Chip shutdown and register re-initialization upon resume/power-up
- Clean devm-managed resource allocation

Hardware evidence:
Tested on Qualcomm SM6125 platforms (Xiaomi Redmi Note 8) with smooth
dimming across the full 11-bit range and robust recovery across display
power cycles.

Signed-off-by: YİĞİTCAN KAVAKLI <kavakliyigitcan@gmail.com>
---
 drivers/video/backlight/Kconfig             |  12 ++
 drivers/video/backlight/Makefile            |   1 +
 drivers/video/backlight/ktd3136-backlight.c | 262 ++++++++++++++++++++++++++++
 3 files changed, 275 insertions(+)

diff --git a/drivers/video/backlight/Kconfig b/drivers/video/backlight/Kconfig
index dbf4ca23a9b6d8575a86e39618b312b4df43ea19..010e2ae3fa8cbd8e2f38e7941b373fbfeb5ede3f 100644
--- a/drivers/video/backlight/Kconfig
+++ b/drivers/video/backlight/Kconfig
@@ -207,6 +207,18 @@ config BACKLIGHT_KTZ8866
 		Say Y to enable the backlight driver for the Kinetic KTZ8866
 		found in Xiaomi Mi Pad 5 series.
 
+config BACKLIGHT_KTD3136
+	tristate "Backlight Driver for Kinetic KTD3136"
+	depends on I2C
+	select REGMAP_I2C
+	help
+	  Say Y to enable the backlight driver for the Kinetic Technologies
+	  KTD3136 3-channel I2C-controlled LED backlight driver found in mobile
+	  phones such as the Xiaomi Redmi Note 8.
+
+	  To compile this driver as a module, choose M here: the module will
+	  be called ktd3136-backlight.
+
 config BACKLIGHT_SY7758
 	tristate "Backlight Driver for Silergy SY7758"
 	depends on I2C
diff --git a/drivers/video/backlight/Makefile b/drivers/video/backlight/Makefile
index 34469711c6cd957dae63c7072ade4830879aba1a..c6d324f60e021afaab1a3da1b4de74f6f2acc8f8 100644
--- a/drivers/video/backlight/Makefile
+++ b/drivers/video/backlight/Makefile
@@ -39,6 +39,7 @@ obj-$(CONFIG_BACKLIGHT_IPAQ_MICRO)	+= ipaq_micro_bl.o
 obj-$(CONFIG_BACKLIGHT_KTD253)		+= ktd253-backlight.o
 obj-$(CONFIG_BACKLIGHT_KTD2801)		+= ktd2801-backlight.o
 obj-$(CONFIG_BACKLIGHT_KTZ8866)		+= ktz8866.o
+obj-$(CONFIG_BACKLIGHT_KTD3136)		+= ktd3136-backlight.o
 obj-$(CONFIG_BACKLIGHT_LM3509)		+= lm3509_bl.o
 obj-$(CONFIG_BACKLIGHT_LM3533)		+= lm3533_bl.o
 obj-$(CONFIG_BACKLIGHT_LM3630A)		+= lm3630a_bl.o
diff --git a/drivers/video/backlight/ktd3136-backlight.c b/drivers/video/backlight/ktd3136-backlight.c
new file mode 100644
index 0000000000000000000000000000000000000000..a8ebe3b23c99f3ada9f45c60688f8b8c78d72def
--- /dev/null
+++ b/drivers/video/backlight/ktd3136-backlight.c
@@ -0,0 +1,262 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Kinetic Technologies KTD3136 3-Channel LED Backlight Driver
+ *
+ * Copyright (C) 2026
+ */
+
+#include <linux/backlight.h>
+#include <linux/delay.h>
+#include <linux/err.h>
+#include <linux/gpio/consumer.h>
+#include <linux/i2c.h>
+#include <linux/init.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/of.h>
+#include <linux/property.h>
+#include <linux/regulator/consumer.h>
+
+#define KTD3136_REG_DEV_ID		0x00
+#define KTD3136_REG_SW_RESET		0x01
+#define KTD3136_REG_MODE		0x02
+#define KTD3136_REG_CONTROL		0x03
+#define KTD3136_REG_RATIO_LSB		0x04
+#define KTD3136_REG_RATIO_MSB		0x05
+#define KTD3136_REG_PWM			0x06
+#define KTD3136_REG_STATUS		0x0A
+
+#define KTD3136_DEV_ID_VAL		0x18
+#define KTD3136_DEV_ID_VAL2		0x19
+
+#define KTD3136_MODE_ON			0xC9	/* Boost ON, 3 channels enabled */
+#define KTD3136_MODE_STANDBY		0x98	/* Standby mode */
+#define KTD3136_CONTROL_LINEAR		0x02	/* Linear dimming mapping */
+#define KTD3136_PWM_DEFAULT		0x1B	/* Default PWM/boost frequency */
+
+#define KTD3136_DEFAULT_MAX_BRIGHTNESS	2047	/* 11-bit resolution */
+#define KTD3136_DEFAULT_BRIGHTNESS	2047
+
+struct ktd3136_data {
+	struct i2c_client *client;
+	struct backlight_device *bd;
+	struct gpio_desc *enable_gpio;
+	struct regulator *vin;
+	/* Protects chip registers and state */
+	struct mutex lock;
+	bool is_enabled;
+};
+
+static int ktd3136_write(struct ktd3136_data *chip, u8 reg, u8 val)
+{
+	int ret;
+
+	ret = i2c_smbus_write_byte_data(chip->client, reg, val);
+	if (ret < 0)
+		dev_err(&chip->client->dev, "failed to write reg 0x%02x: %d\n", reg, ret);
+
+	return ret;
+}
+
+static int ktd3136_read(struct ktd3136_data *chip, u8 reg)
+{
+	int ret;
+
+	ret = i2c_smbus_read_byte_data(chip->client, reg);
+	if (ret < 0)
+		dev_err(&chip->client->dev, "failed to read reg 0x%02x: %d\n", reg, ret);
+
+	return ret;
+}
+
+static int ktd3136_power_on(struct ktd3136_data *chip)
+{
+	int ret;
+
+	if (chip->is_enabled)
+		return 0;
+
+	if (chip->enable_gpio) {
+		gpiod_set_value_cansleep(chip->enable_gpio, 1);
+		/* Allow oscillator and internal logic to stabilize */
+		usleep_range(2000, 3000);
+	}
+
+	ret = ktd3136_write(chip, KTD3136_REG_CONTROL, KTD3136_CONTROL_LINEAR);
+	if (ret < 0)
+		goto err_off;
+
+	ret = ktd3136_write(chip, KTD3136_REG_PWM, KTD3136_PWM_DEFAULT);
+	if (ret < 0)
+		goto err_off;
+
+	chip->is_enabled = true;
+	return 0;
+
+err_off:
+	if (chip->enable_gpio)
+		gpiod_set_value_cansleep(chip->enable_gpio, 0);
+	return ret;
+}
+
+static void ktd3136_power_off(struct ktd3136_data *chip)
+{
+	if (!chip->is_enabled)
+		return;
+
+	ktd3136_write(chip, KTD3136_REG_MODE, KTD3136_MODE_STANDBY);
+
+	if (chip->enable_gpio)
+		gpiod_set_value_cansleep(chip->enable_gpio, 0);
+
+	chip->is_enabled = false;
+}
+
+static int ktd3136_update_status(struct backlight_device *bd)
+{
+	struct ktd3136_data *chip = bl_get_data(bd);
+	int brightness = backlight_get_brightness(bd);
+	int ret = 0;
+	u8 lsb, msb;
+
+	mutex_lock(&chip->lock);
+
+	if (backlight_is_blank(bd) || brightness == 0) {
+		ktd3136_power_off(chip);
+		goto out;
+	}
+
+	ret = ktd3136_power_on(chip);
+	if (ret < 0)
+		goto out;
+
+	lsb = brightness & 0x07;
+	msb = (brightness >> 3) & 0xFF;
+
+	ret = ktd3136_write(chip, KTD3136_REG_RATIO_LSB, lsb);
+	if (ret < 0)
+		goto out;
+
+	ret = ktd3136_write(chip, KTD3136_REG_RATIO_MSB, msb);
+	if (ret < 0)
+		goto out;
+
+	ret = ktd3136_write(chip, KTD3136_REG_MODE, KTD3136_MODE_ON);
+
+out:
+	mutex_unlock(&chip->lock);
+	return ret;
+}
+
+static const struct backlight_ops ktd3136_backlight_ops = {
+	.options = BL_CORE_SUSPENDRESUME,
+	.update_status = ktd3136_update_status,
+};
+
+static int ktd3136_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct backlight_properties props;
+	struct ktd3136_data *chip;
+	int ret, val;
+	u32 def_brightness = KTD3136_DEFAULT_BRIGHTNESS;
+	u32 max_brightness = KTD3136_DEFAULT_MAX_BRIGHTNESS;
+
+	chip = devm_kzalloc(dev, sizeof(*chip), GFP_KERNEL);
+	if (!chip)
+		return -ENOMEM;
+
+	chip->client = client;
+	mutex_init(&chip->lock);
+
+	chip->vin = devm_regulator_get_optional(dev, "vin");
+	if (IS_ERR(chip->vin)) {
+		ret = PTR_ERR(chip->vin);
+		if (ret != -ENODEV)
+			return dev_err_probe(dev, ret, "Failed to get vin regulator\n");
+		chip->vin = NULL;
+	}
+
+	if (chip->vin) {
+		ret = regulator_enable(chip->vin);
+		if (ret)
+			return dev_err_probe(dev, ret, "Failed to enable vin regulator\n");
+	}
+
+	chip->enable_gpio = devm_gpiod_get_optional(dev, "enable", GPIOD_OUT_HIGH);
+	if (IS_ERR(chip->enable_gpio))
+		return dev_err_probe(dev, PTR_ERR(chip->enable_gpio),
+				     "Failed to get enable GPIO\n");
+
+	if (chip->enable_gpio)
+		usleep_range(2000, 3000);
+
+	val = ktd3136_read(chip, KTD3136_REG_DEV_ID);
+	if (val < 0)
+		return dev_err_probe(dev, val, "Failed to read device ID\n");
+
+	if (val != KTD3136_DEV_ID_VAL && val != KTD3136_DEV_ID_VAL2) {
+		dev_err(dev, "Unknown device ID: 0x%02x\n", val);
+		return -ENODEV;
+	}
+
+	dev_info(dev, "Kinetic KTD3136 detected (ID: 0x%02x)\n", val);
+
+	device_property_read_u32(dev, "max-brightness", &max_brightness);
+	if (max_brightness > KTD3136_DEFAULT_MAX_BRIGHTNESS)
+		max_brightness = KTD3136_DEFAULT_MAX_BRIGHTNESS;
+
+	device_property_read_u32(dev, "default-brightness", &def_brightness);
+	if (def_brightness > max_brightness)
+		def_brightness = max_brightness;
+
+	memset(&props, 0, sizeof(props));
+	props.type = BACKLIGHT_RAW;
+	props.max_brightness = max_brightness;
+	props.brightness = def_brightness;
+
+	chip->bd = devm_backlight_device_register(dev, dev_name(dev), dev, chip,
+						  &ktd3136_backlight_ops, &props);
+	if (IS_ERR(chip->bd))
+		return dev_err_probe(dev, PTR_ERR(chip->bd),
+				     "Failed to register backlight device\n");
+
+	backlight_update_status(chip->bd);
+
+	return 0;
+}
+
+static void ktd3136_remove(struct i2c_client *client)
+{
+	struct ktd3136_data *chip = i2c_get_clientdata(client);
+
+	if (chip)
+		ktd3136_power_off(chip);
+}
+
+static const struct of_device_id ktd3136_of_match[] = {
+	{ .compatible = "kinetic,ktd3136" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ktd3136_of_match);
+
+static const struct i2c_device_id ktd3136_i2c_id[] = {
+	{ "ktd3136", 0 },
+	{ }
+};
+MODULE_DEVICE_TABLE(i2c, ktd3136_i2c_id);
+
+static struct i2c_driver ktd3136_driver = {
+	.driver = {
+		.name = "ktd3136-backlight",
+		.of_match_table = ktd3136_of_match,
+	},
+	.probe = ktd3136_probe,
+	.remove = ktd3136_remove,
+	.id_table = ktd3136_i2c_id,
+};
+module_i2c_driver(ktd3136_driver);
+
+MODULE_AUTHOR("Antigravity Team");
+MODULE_DESCRIPTION("Kinetic Technologies KTD3136 Backlight Driver");
+MODULE_LICENSE("GPL");

-- 
2.47.3

