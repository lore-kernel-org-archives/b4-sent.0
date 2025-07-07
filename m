From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 07 Jul 2025 21:54:26 +0200
Subject: [PATCH 2/2] Input: synaptics-rmi4 - add support for F1A
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250707-rmi4_f1a-v1-2-838d83c72e7f@apitzsch.eu>
References: <20250707-rmi4_f1a-v1-0-838d83c72e7f@apitzsch.eu>
In-Reply-To: <20250707-rmi4_f1a-v1-0-838d83c72e7f@apitzsch.eu>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751918097; l=6632;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=chU/vciUONShO2xp5FvxasPrlXeuFhwRzlTtqjnbeJY=;
 b=GyQWyIWwGSSKaOtjQ5lJQVkwHBGY0BBQ7joSKqZE6M+ROcV0M6j/jrSW1Xh6RRRxNBOsoUaai
 idbDBcZZUT4BwOMp/nbq6WLmO4XZK9yyQt/3R7jQ7AG8h/vtpX6NjX0
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RMI4 F1A implements capacitive keys. Add support for touch keys found in
some Synaptics touch controller configurations.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/input/rmi4/Kconfig      |   7 ++
 drivers/input/rmi4/Makefile     |   1 +
 drivers/input/rmi4/rmi_bus.c    |   3 +
 drivers/input/rmi4/rmi_driver.h |   1 +
 drivers/input/rmi4/rmi_f1a.c    | 145 ++++++++++++++++++++++++++++++++++++++++
 5 files changed, 157 insertions(+)

diff --git a/drivers/input/rmi4/Kconfig b/drivers/input/rmi4/Kconfig
index c0163b983ce698ff241eeb6303d0e29989e0fcb8..c5d18abd28c7c26a9491656608d65fae50e818a8 100644
--- a/drivers/input/rmi4/Kconfig
+++ b/drivers/input/rmi4/Kconfig
@@ -82,6 +82,13 @@ config RMI4_F12
 	  touchpads. For sensors that support relative pointing, F12 also
 	  provides mouse input.
 
+config RMI4_F1A
+	bool "RMI4 Function 1A (0D pointing)"
+	help
+	  Say Y here if you want to add support for RMI4 function 1A.
+
+	  Function 1A provides capacitive keys support for RMI4 devices.
+
 config RMI4_F30
 	bool "RMI4 Function 30 (GPIO LED)"
 	help
diff --git a/drivers/input/rmi4/Makefile b/drivers/input/rmi4/Makefile
index 02f14c84686189b45d6adbbc06e266f64efaa036..70f942196aa2efeeaa7bfd292bcc1b8445761011 100644
--- a/drivers/input/rmi4/Makefile
+++ b/drivers/input/rmi4/Makefile
@@ -8,6 +8,7 @@ rmi_core-$(CONFIG_RMI4_2D_SENSOR) += rmi_2d_sensor.o
 rmi_core-$(CONFIG_RMI4_F03) += rmi_f03.o
 rmi_core-$(CONFIG_RMI4_F11) += rmi_f11.o
 rmi_core-$(CONFIG_RMI4_F12) += rmi_f12.o
+rmi_core-$(CONFIG_RMI4_F1A) += rmi_f1a.o
 rmi_core-$(CONFIG_RMI4_F30) += rmi_f30.o
 rmi_core-$(CONFIG_RMI4_F34) += rmi_f34.o rmi_f34v7.o
 rmi_core-$(CONFIG_RMI4_F3A) += rmi_f3a.o
diff --git a/drivers/input/rmi4/rmi_bus.c b/drivers/input/rmi4/rmi_bus.c
index 3aee0483720533050c60014d843418740cf04a2d..e04fd6e525dcf474d948380d493249251f83a864 100644
--- a/drivers/input/rmi4/rmi_bus.c
+++ b/drivers/input/rmi4/rmi_bus.c
@@ -360,6 +360,9 @@ static struct rmi_function_handler *fn_handlers[] = {
 #ifdef CONFIG_RMI4_F12
 	&rmi_f12_handler,
 #endif
+#ifdef CONFIG_RMI4_F1A
+	&rmi_f1a_handler,
+#endif
 #ifdef CONFIG_RMI4_F30
 	&rmi_f30_handler,
 #endif
diff --git a/drivers/input/rmi4/rmi_driver.h b/drivers/input/rmi4/rmi_driver.h
index 3bfe9013043ef3dff46249095a5b3116c8f7d9a6..aefe04008509b4363aa1aaf59d9119d95383e942 100644
--- a/drivers/input/rmi4/rmi_driver.h
+++ b/drivers/input/rmi4/rmi_driver.h
@@ -133,6 +133,7 @@ extern struct rmi_function_handler rmi_f01_handler;
 extern struct rmi_function_handler rmi_f03_handler;
 extern struct rmi_function_handler rmi_f11_handler;
 extern struct rmi_function_handler rmi_f12_handler;
+extern struct rmi_function_handler rmi_f1a_handler;
 extern struct rmi_function_handler rmi_f30_handler;
 extern struct rmi_function_handler rmi_f34_handler;
 extern struct rmi_function_handler rmi_f3a_handler;
diff --git a/drivers/input/rmi4/rmi_f1a.c b/drivers/input/rmi4/rmi_f1a.c
new file mode 100644
index 0000000000000000000000000000000000000000..107f52dd9e1468c2b7c0400bb24f5b0cf2928714
--- /dev/null
+++ b/drivers/input/rmi4/rmi_f1a.c
@@ -0,0 +1,145 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2025 André Apitzsch <git@apitzsch.eu>
+ */
+
+#include <linux/input.h>
+#include <linux/property.h>
+#include "rmi_driver.h"
+
+#define RMI_F1A_BUTTON_BITMASK_SIZE		1
+
+struct f1a_data {
+	u32 *keymap;
+	unsigned int num_keys;
+
+	struct input_dev *input;
+};
+
+static int rmi_f1a_parse_device_properties(struct rmi_function *fn, struct f1a_data *f1a)
+{
+	static const char buttons_property[] = "linux,keycodes";
+	struct device *dev = &fn->dev;
+	u32 *buttonmap;
+	int n_keys;
+	int ret;
+
+	if (!device_property_present(dev, buttons_property))
+		return 0;
+
+	n_keys = device_property_count_u32(dev, buttons_property);
+	if (n_keys <= 0) {
+		ret = n_keys < 0 ? n_keys : -EINVAL;
+		dev_err(dev, "Invalid/malformed '%s' property: %d\n",
+			buttons_property, ret);
+		return ret;
+	}
+
+	buttonmap = devm_kmalloc_array(dev, n_keys, sizeof(*buttonmap),
+				       GFP_KERNEL);
+	if (!buttonmap)
+		return -ENOMEM;
+
+	ret = device_property_read_u32_array(dev, buttons_property, buttonmap,
+					     n_keys);
+	if (ret) {
+		dev_err(dev, "Failed to parse '%s' property: %d\n",
+			buttons_property, ret);
+		return ret;
+	}
+
+	f1a->keymap = buttonmap;
+	f1a->num_keys = n_keys;
+
+	return 0;
+}
+
+static irqreturn_t rmi_f1a_attention(int irq, void *ctx)
+{
+	struct rmi_function *fn = ctx;
+	struct f1a_data *f1a = dev_get_drvdata(&fn->dev);
+	char button_bitmask;
+	int key;
+	int ret;
+
+	ret = rmi_read_block(fn->rmi_dev, fn->fd.data_base_addr,
+			     &button_bitmask, RMI_F1A_BUTTON_BITMASK_SIZE);
+	if (ret < 0) {
+		dev_err(&fn->dev, "Failed to read object data. Code: %d.\n",
+			ret);
+		return IRQ_RETVAL(ret);
+	}
+
+	for (key = 0; key < f1a->num_keys; key++)
+		input_report_key(f1a->input, f1a->keymap[key],
+				button_bitmask & BIT(key));
+
+	return IRQ_HANDLED;
+}
+
+static int rmi_f1a_config(struct rmi_function *fn)
+{
+	struct f1a_data *f1a = dev_get_drvdata(&fn->dev);
+	struct rmi_driver *drv = fn->rmi_dev->driver;
+
+	if (f1a->num_keys)
+		drv->set_irq_bits(fn->rmi_dev, fn->irq_mask);
+
+	return 0;
+}
+
+static int rmi_f1a_initialize(struct rmi_function *fn, struct f1a_data *f1a)
+{
+	int ret;
+	int i;
+
+	ret = rmi_f1a_parse_device_properties(fn, f1a);
+	if (ret)
+		return ret;
+
+	for (i = 0; i < f1a->num_keys; i++)
+		input_set_capability(f1a->input, EV_KEY, f1a->keymap[i]);
+
+	f1a->input->keycode = f1a->keymap;
+	f1a->input->keycodemax = f1a->num_keys;
+	f1a->input->keycodesize = sizeof(f1a->keymap[0]);
+
+	return 0;
+}
+
+static int rmi_f1a_probe(struct rmi_function *fn)
+{
+	struct rmi_device *rmi_dev = fn->rmi_dev;
+	struct rmi_driver_data *drv_data = dev_get_drvdata(&rmi_dev->dev);
+	struct f1a_data *f1a;
+	int ret;
+
+	if (!drv_data->input) {
+		dev_info(&fn->dev, "F1A: no input device found, ignoring\n");
+		return -ENXIO;
+	}
+
+	f1a = devm_kzalloc(&fn->dev, sizeof(*f1a), GFP_KERNEL);
+	if (!f1a)
+		return -ENOMEM;
+
+	f1a->input = drv_data->input;
+
+	ret = rmi_f1a_initialize(fn, f1a);
+	if (ret)
+		return ret;
+
+	dev_set_drvdata(&fn->dev, f1a);
+
+	return 0;
+}
+
+struct rmi_function_handler rmi_f1a_handler = {
+	.driver = {
+		.name = "rmi4_f1a",
+	},
+	.func = 0x1a,
+	.probe = rmi_f1a_probe,
+	.config = rmi_f1a_config,
+	.attention = rmi_f1a_attention,
+};

-- 
2.50.0

