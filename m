From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 10 Nov 2026 21:38:52 +0200
Subject: [PATCH v2 2/2] backlight: add ktd3137 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-6768-ktd3137-v2-2-9496c51efea4@protonmail.com>
References: <20261110-6768-ktd3137-v2-0-9496c51efea4@protonmail.com>
In-Reply-To: <20261110-6768-ktd3137-v2-0-9496c51efea4@protonmail.com>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794339538; l=10109;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=kRX2DsfK/P16Pc7K10xoV7BnyUBL78NnDS9+cOkdHAY=;
 b=+U26cyiqgX+/1KRpU5+27JOcBm4PzBE2qGWn6+oX9T/Cw5XmSHQeVNnTN5weFTtsh921w+HKz
 daO5+CnGF6zDhlDYJrU0UpBYPg7VSIXlRQIyZOb0Bx7p+R7ARh300jF
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the KTD3137 display backlight IC. It's used in various
Xiaomi phones, such as Xiaomi Redmi Note 9.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 MAINTAINERS                       |   1 +
 drivers/video/backlight/Kconfig   |  11 ++
 drivers/video/backlight/Makefile  |   1 +
 drivers/video/backlight/ktd3137.c | 258 ++++++++++++++++++++++++++++++++++++++
 4 files changed, 271 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 24dd5b43f167..23114fd09445 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -14622,6 +14622,7 @@ KTD3137 BACKLIGHT DRIVER
 M:	Roman Vivchar <rva333@protonmail.com>
 S:	Maintained
 F:	Documentation/devicetree/bindings/leds/backlight/kinetic,ktd3137.yaml
+F:	drivers/video/backlight/ktd3137.c
 
 KTEST
 M:	Steven Rostedt <rostedt@goodmis.org>
diff --git a/drivers/video/backlight/Kconfig b/drivers/video/backlight/Kconfig
index 7c66b8840d88..0196b8597367 100644
--- a/drivers/video/backlight/Kconfig
+++ b/drivers/video/backlight/Kconfig
@@ -199,6 +199,17 @@ config BACKLIGHT_KTD2801
 	  Say Y to enable the backlight driver for the Kinetic KTD2801 1-wire
 	  GPIO-controlled backlight found in Samsung Galaxy Core Prime VE LTE.
 
+config BACKLIGHT_KTD3137
+	tristate "Backlight Driver for Kinetic KTD3137"
+	depends on I2C
+	select REGMAP_I2C
+	help
+	  Say Y to enable the backlight driver for the Kinetic KTD3137
+	  found in various Xiaomi smartphones.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called ktd3137.
+
 config BACKLIGHT_KTZ8866
 	tristate "Backlight Driver for Kinetic KTZ8866"
 	depends on I2C
diff --git a/drivers/video/backlight/Makefile b/drivers/video/backlight/Makefile
index 34469711c6cd..b2d3b69e9e32 100644
--- a/drivers/video/backlight/Makefile
+++ b/drivers/video/backlight/Makefile
@@ -38,6 +38,7 @@ obj-$(CONFIG_BACKLIGHT_HP700)		+= jornada720_bl.o
 obj-$(CONFIG_BACKLIGHT_IPAQ_MICRO)	+= ipaq_micro_bl.o
 obj-$(CONFIG_BACKLIGHT_KTD253)		+= ktd253-backlight.o
 obj-$(CONFIG_BACKLIGHT_KTD2801)		+= ktd2801-backlight.o
+obj-$(CONFIG_BACKLIGHT_KTD3137)		+= ktd3137.o
 obj-$(CONFIG_BACKLIGHT_KTZ8866)		+= ktz8866.o
 obj-$(CONFIG_BACKLIGHT_LM3509)		+= lm3509_bl.o
 obj-$(CONFIG_BACKLIGHT_LM3533)		+= lm3533_bl.o
diff --git a/drivers/video/backlight/ktd3137.c b/drivers/video/backlight/ktd3137.c
new file mode 100644
index 000000000000..1595aefd46e6
--- /dev/null
+++ b/drivers/video/backlight/ktd3137.c
@@ -0,0 +1,258 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (c) 2025-2026 Roman Vivchar <rva333@protonmail.com>
+ *
+ * Backlight driver for the Kinetic KTD3137
+ */
+
+#include <linux/backlight.h>
+#include <linux/bitfield.h>
+#include <linux/delay.h>
+#include <linux/err.h>
+#include <linux/gpio/consumer.h>
+#include <linux/i2c.h>
+#include <linux/module.h>
+#include <linux/property.h>
+#include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
+
+#define KTD3137_REG_DEV_ID		0x00
+#define KTD3137_REG_SW_RESET		0x01
+#define KTD3137_REG_MODE		0x02
+#define KTD3137_REG_CONTROL		0x03
+#define KTD3137_REG_RATIO_LSB		0x04
+#define KTD3137_REG_RATIO_MSB		0x05
+#define KTD3137_REG_PWM			0x06
+#define KTD3137_REG_RAMP_ON		0x07
+#define KTD3137_REG_TRANS_RAMP		0x08
+#define KTD3137_REG_FLASH_SETTING	0x09
+#define KTD3137_REG_STATUS		0x0a
+#define KTD3137_REG_MAX			0x0a
+
+/* KTD3137_REG_DEV_ID */
+#define KTD3137_DEV_ID_A		0x12
+#define KTD3137_DEV_ID_B		0x18
+
+/* KTD3137_REG_MODE */
+#define KTD3137_MODE_BL_EN		BIT(0)
+#define KTD3137_MODE_CURRENT_MASK	GENMASK(7, 3)
+
+/* KTD3137_REG_CONTROL */
+#define KTD3137_CONTROL_LINEAR		(BIT(1) | BIT(2))
+#define KTD3137_CONTROL_IND_2P6A	BIT(3)
+#define KTD3137_CONTROL_OVP_32V		BIT(5)
+#define KTD3137_CONTROL_FREQ_1000KHZ	BIT(6)
+#define KTD3137_CONTROL_DEFAULT		(KTD3137_CONTROL_IND_2P6A | \
+					 KTD3137_CONTROL_OVP_32V | \
+					 KTD3137_CONTROL_FREQ_1000KHZ)
+
+/* KTD3137_REG_RATIO_LSB */
+#define KTD3137_RATIO_LSB_MASK		GENMASK(2, 0)
+
+/* KTD3137_REG_PWM */
+#define KTD3137_PWM_CH1_EN		BIT(0)
+#define KTD3137_PWM_CH2_EN		BIT(1)
+#define KTD3137_PWM_FILTER_6LSB		(BIT(3) | BIT(4))
+#define KTD3137_PWM_DISABLE		BIT(7)
+#define KTD3137_PWM_DEFAULT		(KTD3137_PWM_CH1_EN | \
+					 KTD3137_PWM_CH2_EN | \
+					 KTD3137_PWM_FILTER_6LSB | \
+					 KTD3137_PWM_DISABLE)
+
+/* KTD3137_REG_RAMP_ON */
+#define KTD3137_RAMP_ON_MASK		GENMASK(7, 4)
+#define KTD3137_RAMP_OFF_MASK		GENMASK(3, 0)
+/* Ramp ON: 2ms, OFF: 8ms */
+#define KTD3137_RAMP_DEFAULT		(FIELD_PREP(KTD3137_RAMP_ON_MASK, 4) | \
+					 FIELD_PREP(KTD3137_RAMP_OFF_MASK, 4))
+
+#define KTD3137_MAX_BRIGHTNESS		2047
+
+#define KTD3137_I_MIN_UA		5000
+#define KTD3137_I_MAX_UA		29800
+#define KTD3137_I_STEP_UA		800
+#define KTD3137_I_DEFAULT_UA		20200
+
+struct ktd3137 {
+	struct device *dev;
+	struct regmap *regmap;
+	struct gpio_desc *enable_gpio;
+	u32 led_current;
+};
+
+static const struct regmap_config ktd3137_regmap_config = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = KTD3137_REG_MAX,
+};
+
+static int ktd3137_init(struct ktd3137 *ktd)
+{
+	int ret;
+
+	ret = regmap_write(ktd->regmap, KTD3137_REG_CONTROL,
+			   KTD3137_CONTROL_DEFAULT | KTD3137_CONTROL_LINEAR);
+	if (ret)
+		return ret;
+
+	ret = regmap_write(ktd->regmap, KTD3137_REG_PWM, KTD3137_PWM_DEFAULT);
+	if (ret)
+		return ret;
+
+	ret = regmap_write(ktd->regmap, KTD3137_REG_RAMP_ON, KTD3137_RAMP_DEFAULT);
+	if (ret)
+		return ret;
+
+	ret = regmap_write(ktd->regmap, KTD3137_REG_TRANS_RAMP, 0x00);
+	if (ret)
+		return ret;
+
+	return regmap_update_bits(ktd->regmap, KTD3137_REG_MODE,
+				  KTD3137_MODE_CURRENT_MASK, ktd->led_current);
+}
+
+static int ktd3137_backlight_update_status(struct backlight_device *backlight_dev)
+{
+	struct ktd3137 *ktd = bl_get_data(backlight_dev);
+	unsigned int brightness = backlight_get_brightness(backlight_dev);
+	int ret;
+
+	if (brightness > 0) {
+		ret = regmap_write(ktd->regmap, KTD3137_REG_RATIO_LSB,
+				   brightness & KTD3137_RATIO_LSB_MASK);
+		if (ret)
+			return ret;
+
+		ret = regmap_write(ktd->regmap, KTD3137_REG_RATIO_MSB,
+				   brightness >> 3);
+		if (ret)
+			return ret;
+	}
+
+	return regmap_update_bits(ktd->regmap, KTD3137_REG_MODE,
+				  KTD3137_MODE_BL_EN,
+				  brightness ? KTD3137_MODE_BL_EN : 0);
+}
+
+static const struct backlight_ops ktd3137_backlight_ops = {
+	.options = BL_CORE_SUSPENDRESUME,
+	.update_status = ktd3137_backlight_update_status,
+};
+
+static int ktd3137_parse_dt(struct ktd3137 *ktd)
+{
+	u32 max_ua = KTD3137_I_DEFAULT_UA;
+	u32 val;
+
+	device_property_read_u32(ktd->dev, "led-max-microamp", &max_ua);
+
+	if (max_ua < KTD3137_I_MIN_UA || max_ua > KTD3137_I_MAX_UA)
+		return dev_err_probe(ktd->dev, -EINVAL,
+				     "led-max-microamp (%u) out of range\n", max_ua);
+
+	val = (max_ua - KTD3137_I_MIN_UA) / KTD3137_I_STEP_UA;
+	ktd->led_current = FIELD_PREP(KTD3137_MODE_CURRENT_MASK, val);
+
+	return 0;
+}
+
+static int ktd3137_probe(struct i2c_client *client)
+{
+	struct backlight_device *backlight_dev;
+	struct backlight_properties props = { };
+	struct ktd3137 *ktd;
+	u32 val;
+	int ret;
+
+	ktd = devm_kzalloc(&client->dev, sizeof(*ktd), GFP_KERNEL);
+	if (!ktd)
+		return -ENOMEM;
+
+	ktd->dev = &client->dev;
+
+	ret = devm_regulator_get_enable(ktd->dev, "vin");
+	if (ret)
+		return dev_err_probe(ktd->dev, ret, "failed to power up\n");
+
+	ktd->enable_gpio = devm_gpiod_get_optional(ktd->dev, "enable",
+						   GPIOD_OUT_HIGH);
+	if (IS_ERR(ktd->enable_gpio))
+		return dev_err_probe(ktd->dev, PTR_ERR(ktd->enable_gpio),
+				     "failed to get enable gpio\n");
+
+	/* HWEN should stay HIGH for at least 150us before I2C can be used */
+	fsleep(150);
+
+	ktd->regmap = devm_regmap_init_i2c(client, &ktd3137_regmap_config);
+	if (IS_ERR(ktd->regmap))
+		return dev_err_probe(ktd->dev, PTR_ERR(ktd->regmap),
+				     "failed to init regmap\n");
+
+	ret = regmap_read(ktd->regmap, KTD3137_REG_DEV_ID, &val);
+	if (ret)
+		return dev_err_probe(ktd->dev, ret, "failed to read chip id\n");
+
+	if (val != KTD3137_DEV_ID_A && val != KTD3137_DEV_ID_B)
+		return dev_err_probe(ktd->dev, -ENODEV,
+				     "unsupported chip id: 0x%02x\n", val);
+
+	ret = ktd3137_parse_dt(ktd);
+	if (ret)
+		return ret;
+
+	ret = ktd3137_init(ktd);
+	if (ret)
+		return dev_err_probe(ktd->dev, ret, "failed to init chip\n");
+
+	props.type = BACKLIGHT_RAW;
+	props.max_brightness = KTD3137_MAX_BRIGHTNESS;
+	props.brightness = KTD3137_MAX_BRIGHTNESS;
+	props.scale = BACKLIGHT_SCALE_LINEAR;
+	device_property_read_u32(ktd->dev, "default-brightness", &props.brightness);
+
+	backlight_dev = devm_backlight_device_register(ktd->dev,
+						       "ktd3137-backlight",
+						       ktd->dev, ktd,
+						       &ktd3137_backlight_ops,
+						       &props);
+	if (IS_ERR(backlight_dev))
+		return dev_err_probe(ktd->dev, PTR_ERR(backlight_dev),
+				     "failed to register backlight device\n");
+
+	i2c_set_clientdata(client, backlight_dev);
+	return backlight_update_status(backlight_dev);
+}
+
+static void ktd3137_remove(struct i2c_client *client)
+{
+	struct backlight_device *backlight_dev = i2c_get_clientdata(client);
+
+	backlight_dev->props.brightness = 0;
+	backlight_update_status(backlight_dev);
+}
+
+static const struct i2c_device_id ktd3137_ids[] = {
+	{ "ktd3137" },
+	{ }
+};
+MODULE_DEVICE_TABLE(i2c, ktd3137_ids);
+
+static const struct of_device_id ktd3137_match_table[] = {
+	{ .compatible = "kinetic,ktd3137" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ktd3137_match_table);
+
+static struct i2c_driver ktd3137_driver = {
+	.driver = {
+		.name = "ktd3137",
+		.of_match_table = ktd3137_match_table,
+	},
+	.probe = ktd3137_probe,
+	.remove = ktd3137_remove,
+	.id_table = ktd3137_ids,
+};
+module_i2c_driver(ktd3137_driver);
+
+MODULE_DESCRIPTION("Kinetic KTD3137 Backlight Driver");
+MODULE_LICENSE("GPL");

-- 
2.56.0

