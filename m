From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 28 Apr 2026 17:07:28 +0100
Subject: [PATCH v10 3/3] gpio: gpio-ltc4283: Add support for the LTC4283
 Swap Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260428-ltc4283-support-v10-3-4f26f46491c3@analog.com>
References: <20260428-ltc4283-support-v10-0-4f26f46491c3@analog.com>
In-Reply-To: <20260428-ltc4283-support-v10-0-4f26f46491c3@analog.com>
To: linux-gpio@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777392450; l=8619;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=wO2eYhQ1QAyG4tDbVM3m77DgMlDdrHUHpO1jtVnuCnw=;
 b=20QIfzDy5/CSyi1gMUbZ+249TC9GkMatcb5PXpBbPECDgS1OnfrAuiKttzeG/aCyQA94FH/8D
 eeyGC0++aWyDNv3/KxC8cYHrvDkd9IL38fmRhiKKXM+XYD3ikQdsW20
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC4283 device has up to 8 pins that can be configured as GPIOs.

Note that PGIO pins are not set as GPIOs by default so if they are
configured to be used as GPIOs we need to make sure to initialize them
to a sane default. They are set as inputs by default.

Acked-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Reviewed-by: Linus Walleij <linusw@kernel.org>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 MAINTAINERS                 |   2 +
 drivers/gpio/Kconfig        |  15 +++
 drivers/gpio/Makefile       |   1 +
 drivers/gpio/gpio-ltc4283.c | 218 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 236 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index a63833b6fe8b..0947cdbac5e5 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -15163,9 +15163,11 @@ F:	drivers/hwmon/ltc4282.c
 
 LTC4283 HARDWARE MONITOR AND GPIO DRIVER
 M:	Nuno Sá <nuno.sa@analog.com>
+L:	linux-gpio@vger.kernel.org
 L:	linux-hwmon@vger.kernel.org
 S:	Supported
 F:	Documentation/devicetree/bindings/hwmon/adi,ltc4283.yaml
+F:	drivers/gpio/gpio-ltc4283.c
 F:	drivers/hwmon/ltc4283.c
 
 LTC4286 HARDWARE MONITOR DRIVER
diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index b45fb799e36c..ba2621024598 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -1758,6 +1758,21 @@ config GPIO_WM8994
 
 endmenu
 
+menu "Auxiliary Bus GPIO drivers"
+	depends on AUXILIARY_BUS
+
+config GPIO_LTC4283
+	tristate "Analog Devices LTC4283 GPIO support"
+	depends on SENSORS_LTC4283
+	help
+	  If you say yes here you want the GPIO function available in Analog
+	  Devices LTC4283 Negative Voltage Hot Swap Controller.
+
+	  This driver can also be built as a module. If so, the module will
+	  be called gpio-ltc4283.
+
+endmenu
+
 menu "PCI GPIO expanders"
 	depends on PCI
 
diff --git a/drivers/gpio/Makefile b/drivers/gpio/Makefile
index c05f7d795c43..ff37aca5029c 100644
--- a/drivers/gpio/Makefile
+++ b/drivers/gpio/Makefile
@@ -102,6 +102,7 @@ obj-$(CONFIG_GPIO_LP873X)		+= gpio-lp873x.o
 obj-$(CONFIG_GPIO_LP87565)		+= gpio-lp87565.o
 obj-$(CONFIG_GPIO_LPC18XX)		+= gpio-lpc18xx.o
 obj-$(CONFIG_GPIO_LPC32XX)		+= gpio-lpc32xx.o
+obj-$(CONFIG_GPIO_LTC4283)		+= gpio-ltc4283.o
 obj-$(CONFIG_GPIO_MACSMC)		+= gpio-macsmc.o
 obj-$(CONFIG_GPIO_MADERA)		+= gpio-madera.o
 obj-$(CONFIG_GPIO_MAX3191X)		+= gpio-max3191x.o
diff --git a/drivers/gpio/gpio-ltc4283.c b/drivers/gpio/gpio-ltc4283.c
new file mode 100644
index 000000000000..6609443c5d62
--- /dev/null
+++ b/drivers/gpio/gpio-ltc4283.c
@@ -0,0 +1,218 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Analog Devices LTC4283 GPIO driver
+ *
+ * Copyright 2025 Analog Devices Inc.
+ */
+
+#include <linux/auxiliary_bus.h>
+#include <linux/bitfield.h>
+#include <linux/bitmap.h>
+#include <linux/bits.h>
+#include <linux/device.h>
+#include <linux/gpio/driver.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/regmap.h>
+
+#define LTC4283_PINS_MAX			8
+#define LTC4283_PGIOX_START_NR			4
+#define LTC4283_INPUT_STATUS			0x02
+#define LTC4283_PGIO_CONFIG			0x10
+#define   LTC4283_PGIO_CFG_MASK(pin) \
+	GENMASK(((pin) - LTC4283_PGIOX_START_NR) * 2 + 1, (((pin) - LTC4283_PGIOX_START_NR) * 2))
+#define LTC4283_PGIO_CONFIG_2			0x11
+
+#define LTC4283_ADIO_CONFIG			0x12
+/* starts at bit 4 */
+#define   LTC4283_ADIOX_CONFIG_MASK(pin)	BIT((pin) + 4)
+#define LTC4283_PGIO_DIR_IN			3
+#define LTC4283_PGIO_DIR_OUT			2
+
+struct ltc4283_gpio {
+	struct gpio_chip gpio_chip;
+	struct regmap *regmap;
+};
+
+static int ltc4283_pgio_get_direction(const struct ltc4283_gpio *st, unsigned int off)
+{
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(st->regmap, LTC4283_PGIO_CONFIG, &val);
+	if (ret)
+		return ret;
+
+	val = field_get(LTC4283_PGIO_CFG_MASK(off), val);
+	if (val == LTC4283_PGIO_DIR_IN)
+		return GPIO_LINE_DIRECTION_IN;
+
+	return GPIO_LINE_DIRECTION_OUT;
+}
+
+static int ltc4283_gpio_get_direction(struct gpio_chip *gc, unsigned int off)
+{
+	struct ltc4283_gpio *st = gpiochip_get_data(gc);
+	unsigned int val;
+	int ret;
+
+	if (off >= LTC4283_PGIOX_START_NR)
+		return ltc4283_pgio_get_direction(st, off);
+
+	ret = regmap_read(st->regmap, LTC4283_ADIO_CONFIG, &val);
+	if (ret)
+		return ret;
+
+	if (val & LTC4283_ADIOX_CONFIG_MASK(off))
+		return GPIO_LINE_DIRECTION_IN;
+
+	return GPIO_LINE_DIRECTION_OUT;
+}
+
+static int ltc4283_gpio_direction_set(const struct ltc4283_gpio *st,
+				      unsigned int off, bool input)
+{
+	if (off >= LTC4283_PGIOX_START_NR) {
+		unsigned int val = LTC4283_PGIO_DIR_OUT;
+
+		if (input)
+			val = LTC4283_PGIO_DIR_IN;
+
+		val = field_prep(LTC4283_PGIO_CFG_MASK(off), val);
+		return regmap_update_bits(st->regmap, LTC4283_PGIO_CONFIG,
+					  LTC4283_PGIO_CFG_MASK(off), val);
+	}
+
+	return regmap_update_bits(st->regmap, LTC4283_ADIO_CONFIG,
+				  LTC4283_ADIOX_CONFIG_MASK(off),
+				  field_prep(LTC4283_ADIOX_CONFIG_MASK(off), input));
+}
+
+static int __ltc4283_gpio_set_value(const struct ltc4283_gpio *st,
+				    unsigned int off, int val)
+{
+	u32 reg = off < LTC4283_PGIOX_START_NR ? LTC4283_ADIO_CONFIG : LTC4283_PGIO_CONFIG_2;
+
+	return regmap_update_bits(st->regmap, reg, BIT(off),
+				  field_prep(BIT(off), !!val));
+}
+
+static int ltc4283_gpio_direction_input(struct gpio_chip *gc, unsigned int off)
+{
+	struct ltc4283_gpio *st = gpiochip_get_data(gc);
+
+	return ltc4283_gpio_direction_set(st, off, true);
+}
+
+static int ltc4283_gpio_direction_output(struct gpio_chip *gc, unsigned int off, int val)
+{
+	struct ltc4283_gpio *st = gpiochip_get_data(gc);
+	int ret;
+
+	ret = ltc4283_gpio_direction_set(st, off, false);
+	if (ret)
+		return ret;
+
+	return __ltc4283_gpio_set_value(st, off, val);
+}
+
+static int ltc4283_gpio_get_value(struct gpio_chip *gc, unsigned int off)
+{
+	struct ltc4283_gpio *st = gpiochip_get_data(gc);
+	unsigned int val, reg;
+	int ret, dir;
+
+	dir = ltc4283_gpio_get_direction(gc, off);
+	if (dir < 0)
+		return dir;
+
+	if (dir == GPIO_LINE_DIRECTION_IN) {
+		ret = regmap_read(st->regmap, LTC4283_INPUT_STATUS, &val);
+		if (ret)
+			return ret;
+
+		/* ADIO1 is at bit 3. */
+		if (off < LTC4283_PGIOX_START_NR)
+			return !!(val & BIT(3 - off));
+
+		/* PGIO1 is at bit 7. */
+		return !!(val & BIT(7 - (off - LTC4283_PGIOX_START_NR)));
+	}
+
+	if (off < LTC4283_PGIOX_START_NR)
+		reg = LTC4283_ADIO_CONFIG;
+	else
+		reg = LTC4283_PGIO_CONFIG_2;
+
+	ret = regmap_read(st->regmap, reg, &val);
+	if (ret)
+		return ret;
+
+	return !!(val & BIT(off));
+}
+
+static int ltc4283_gpio_set_value(struct gpio_chip *gc, unsigned int off, int val)
+{
+	struct ltc4283_gpio *st = gpiochip_get_data(gc);
+
+	return __ltc4283_gpio_set_value(st, off, val);
+}
+
+static int ltc4283_init_valid_mask(struct gpio_chip *gc, unsigned long *valid_mask,
+				   unsigned int ngpios)
+{
+	unsigned long *mask = dev_get_platdata(gc->parent);
+
+	bitmap_copy(valid_mask, mask, ngpios);
+	return 0;
+}
+
+static int ltc4283_gpio_probe(struct auxiliary_device *adev,
+			      const struct auxiliary_device_id *id)
+{
+	struct device *dev = &adev->dev;
+	struct ltc4283_gpio *st;
+	struct gpio_chip *gc;
+
+	st = devm_kzalloc(dev, sizeof(*st), GFP_KERNEL);
+	if (!st)
+		return -ENOMEM;
+
+	st->regmap = dev_get_regmap(dev->parent, NULL);
+	if (!st->regmap)
+		return dev_err_probe(dev, -ENODEV,
+				     "Failed to get regmap\n");
+
+	gc = &st->gpio_chip;
+	gc->parent = dev;
+	gc->get_direction = ltc4283_gpio_get_direction;
+	gc->direction_input = ltc4283_gpio_direction_input;
+	gc->direction_output = ltc4283_gpio_direction_output;
+	gc->get = ltc4283_gpio_get_value;
+	gc->set = ltc4283_gpio_set_value;
+	gc->init_valid_mask = ltc4283_init_valid_mask;
+	gc->can_sleep = true;
+
+	gc->base = -1;
+	gc->ngpio = LTC4283_PINS_MAX;
+	gc->label = adev->name;
+	gc->owner = THIS_MODULE;
+
+	return devm_gpiochip_add_data(dev, &st->gpio_chip, st);
+}
+
+static const struct auxiliary_device_id ltc4283_aux_id_table[] = {
+	{ "ltc4283.gpio" },
+	{ }
+};
+MODULE_DEVICE_TABLE(auxiliary, ltc4283_aux_id_table);
+
+static struct auxiliary_driver ltc4283_gpio_driver = {
+	.probe = ltc4283_gpio_probe,
+	.id_table = ltc4283_aux_id_table,
+};
+module_auxiliary_driver(ltc4283_gpio_driver);
+
+MODULE_AUTHOR("Nuno Sá <nuno.sa@analog.com>");
+MODULE_DESCRIPTION("GPIO LTC4283 Driver");
+MODULE_LICENSE("GPL");

-- 
2.54.0

