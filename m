From: Marc Paolo Sosa <marcpaolo.sosa@analog.com>
Date: Mon, 23 Feb 2026 19:03:40 +0800
Subject: [PATCH 2/2] input: misc: add driver for max16150
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260223-max16150-v1-2-38e2a4f0d0f1@analog.com>
References: <20260223-max16150-v1-0-38e2a4f0d0f1@analog.com>
In-Reply-To: <20260223-max16150-v1-0-38e2a4f0d0f1@analog.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Marc Paolo Sosa <marcpaolo.sosa@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771844627; l=6397;
 i=marcpaolo.sosa@analog.com; s=20260223; h=from:subject:message-id;
 bh=Ongk+INNU1hweeGnvmpedbO1bI8VrW669dIDgtzalgk=;
 b=8a6pK2xxpBYhYhavLO45z0fORG3FFfj+sKxwtWl+FNIjv+4P8WU63SRTLpZ+OExHI9A1amAtN
 QvmfDszAVkTD/zU9pjMCwQpKJ4aJEdjC5w0DsV7CjTqnQqZqrh27ipN
X-Developer-Key: i=marcpaolo.sosa@analog.com; a=ed25519;
 pk=RR72PZYRimO/84huVqlVyHN3IM3AL984DRKCEXnOJuE=
X-Endpoint-Received: by B4 Relay for marcpaolo.sosa@analog.com/20260223 with auth_id=646
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MAX16150/MAX16169 nanoPower Pushbutton On/Off Controller

Signed-off-by: Marc Paolo Sosa <marcpaolo.sosa@analog.com>
---
 drivers/input/misc/Kconfig    |   9 +++
 drivers/input/misc/Makefile   |   1 +
 drivers/input/misc/max16150.c | 161 ++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 171 insertions(+)

diff --git a/drivers/input/misc/Kconfig b/drivers/input/misc/Kconfig
index 94a753fcb64f..a31d3d2a7fd6 100644
--- a/drivers/input/misc/Kconfig
+++ b/drivers/input/misc/Kconfig
@@ -178,6 +178,15 @@ config INPUT_E3X0_BUTTON
 	  To compile this driver as a module, choose M here: the
 	  module will be called e3x0_button.
 
+config INPUT_MAX16150_PWRBUTTON
+	tristate "MAX16150/MAX16169 Pushbutton driver"
+	help
+	  Say Y here if you want to enable power key reporting via
+	  MAX16150/MAX16169 nanoPower Pushbutton On/Off Controller.
+
+	  To compile this driver as a module, choose M here. The module will
+	  be called max16150.
+
 config INPUT_PCSPKR
 	tristate "PC Speaker support"
 	depends on PCSPKR_PLATFORM
diff --git a/drivers/input/misc/Makefile b/drivers/input/misc/Makefile
index 415fc4e2918b..c2c1c45f2df6 100644
--- a/drivers/input/misc/Makefile
+++ b/drivers/input/misc/Makefile
@@ -52,6 +52,7 @@ obj-$(CONFIG_INPUT_IQS7222)		+= iqs7222.o
 obj-$(CONFIG_INPUT_KEYSPAN_REMOTE)	+= keyspan_remote.o
 obj-$(CONFIG_INPUT_KXTJ9)		+= kxtj9.o
 obj-$(CONFIG_INPUT_M68K_BEEP)		+= m68kspkr.o
+obj-$(CONFIG_INPUT_MAX16150_PWRBUTTON)	+= max16150.o
 obj-$(CONFIG_INPUT_MAX7360_ROTARY)	+= max7360-rotary.o
 obj-$(CONFIG_INPUT_MAX77650_ONKEY)	+= max77650-onkey.o
 obj-$(CONFIG_INPUT_MAX77693_HAPTIC)	+= max77693-haptic.o
diff --git a/drivers/input/misc/max16150.c b/drivers/input/misc/max16150.c
new file mode 100644
index 000000000000..ae353b926afc
--- /dev/null
+++ b/drivers/input/misc/max16150.c
@@ -0,0 +1,161 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Analog Devices MAX16150/MAX16169 Pushbutton Driver
+ *
+ * Copyright 2025 Analog Devices Inc.
+ */
+
+#include <linux/delay.h>
+#include <linux/init.h>
+#include <linux/input.h>
+#include <linux/interrupt.h>
+#include <linux/gpio/consumer.h>
+#include <linux/kernel.h>
+#include <linux/mod_devicetable.h>
+#include <linux/platform_device.h>
+#include <linux/property.h>
+
+#define MAX16150_LONG_INTERRUPT 120000000
+
+struct max16150_chip_info {
+	bool has_clr_gpio;
+};
+
+struct max16150_device {
+	struct input_dev *input;
+	struct gpio_desc *gpiod;
+	struct gpio_desc *clr_gpiod;
+	const struct max16150_chip_info *chip_info;
+	u64 low, high, duration;
+	unsigned int keycode;
+};
+
+static irqreturn_t max16150_irq_handler(int irq, void *_max16150)
+{
+	struct max16150_device *max16150 = _max16150;
+	int value;
+
+	value = gpiod_get_value(max16150->gpiod);
+
+	if (!value) {
+		max16150->low = ktime_get_ns();
+		return IRQ_HANDLED;
+	}
+
+	max16150->high = ktime_get_ns();
+	if (max16150->low) {
+		max16150->duration = max16150->high - max16150->low;
+
+		if (max16150->duration > MAX16150_LONG_INTERRUPT) {
+			gpiod_set_value(max16150->clr_gpiod, 1);
+			input_report_key(max16150->input, max16150->keycode, 1);
+			input_sync(max16150->input);
+			input_report_key(max16150->input, max16150->keycode, 0);
+			input_sync(max16150->input);
+		}
+
+		max16150->low = 0;
+	}
+
+	return IRQ_HANDLED;
+}
+
+static const struct max16150_chip_info max16150_variant_a = {
+	.has_clr_gpio = true,
+};
+
+static const struct max16150_chip_info max16150_variant_b = {
+	.has_clr_gpio = false,
+};
+
+static int max16150_probe(struct platform_device *pdev)
+{
+	const struct max16150_chip_info *chip_info;
+	struct max16150_device *max16150;
+	struct device *dev = &pdev->dev;
+	int err, irq, ret;
+	u32 keycode;
+
+	chip_info = device_get_match_data(dev);
+	if (!chip_info)
+		return -EINVAL;
+
+	max16150 = devm_kzalloc(dev, sizeof(*max16150), GFP_KERNEL);
+	if (!max16150)
+		return -ENOMEM;
+
+	max16150->chip_info = chip_info;
+
+	max16150->input = devm_input_allocate_device(dev);
+	if (!max16150->input)
+		return -ENOMEM;
+
+	max16150->input->name = "MAX16150 Pushbutton";
+	max16150->input->phys = "max16150/input0";
+	max16150->input->id.bustype = BUS_HOST;
+
+	keycode = KEY_POWER;
+	ret = device_property_read_u32(dev, "linux,code", &keycode);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to get keycode\n");
+
+	max16150->keycode = keycode;
+
+	input_set_capability(max16150->input, EV_KEY, max16150->keycode);
+
+	max16150->gpiod = devm_gpiod_get(dev, "interrupt", GPIOD_IN);
+	if (IS_ERR(max16150->gpiod))
+		return dev_err_probe(dev, PTR_ERR(max16150->gpiod),
+				     "Failed to get interrupt GPIO\n");
+
+	if (chip_info->has_clr_gpio) {
+		max16150->clr_gpiod = devm_gpiod_get(dev, "clr", GPIOD_OUT_HIGH);
+		if (IS_ERR(max16150->clr_gpiod))
+			return dev_err_probe(dev, PTR_ERR(max16150->clr_gpiod),
+					     "Failed to get clr GPIO\n");
+
+		if (!max16150->clr_gpiod)
+			return dev_err_probe(dev, -ENODEV,
+						 "clr GPIO is mandatory\n");
+
+		if (max16150->clr_gpiod) {
+			fsleep(1000);
+			gpiod_set_value(max16150->clr_gpiod, 0);
+		}
+	}
+
+	irq = gpiod_to_irq(max16150->gpiod);
+	if (irq < 0)
+		return dev_err_probe(dev, irq,
+				     "MAX16150: Failed to map GPIO to IRQ");
+
+	err = devm_request_irq(dev, irq, max16150_irq_handler,
+			       IRQF_TRIGGER_RISING | IRQF_TRIGGER_FALLING,
+			       "max16150_irq", max16150);
+	if (err)
+		return err;
+
+	return input_register_device(max16150->input);
+}
+
+static const struct of_device_id max16150_of_match[] = {
+	{ .compatible = "adi,max16150a", .data = &max16150_variant_a },
+	{ .compatible = "adi,max16150b", .data = &max16150_variant_b },
+	{ .compatible = "adi,max16169a", .data = &max16150_variant_a },
+	{ .compatible = "adi,max16169b", .data = &max16150_variant_b },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, max16150_of_match);
+
+static struct platform_driver max16150_driver = {
+	.probe  = max16150_probe,
+	.driver = {
+		.name = "max16150",
+		.of_match_table = max16150_of_match,
+	},
+};
+module_platform_driver(max16150_driver);
+
+MODULE_AUTHOR("Marc Paolo Sosa <marcpaolo.sosa@analog.com>");
+MODULE_DESCRIPTION("MAX16150/MAX16169 Pushbutton Driver");
+MODULE_LICENSE("GPL");

-- 
2.34.1

