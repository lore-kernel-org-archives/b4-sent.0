From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Mon, 11 May 2026 00:08:03 +0700
Subject: [PATCH 2/2] backlight: sy7758: add Silergy SY7758 backlight driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-sy7758-v1-2-999a33081304@gmail.com>
References: <20260511-sy7758-v1-0-999a33081304@gmail.com>
In-Reply-To: <20260511-sy7758-v1-0-999a33081304@gmail.com>
To: Philippe Simons <simons.philippe@gmail.com>, Lee Jones <lee@kernel.org>, 
 Daniel Thompson <danielt@kernel.org>, Jingoo Han <jingoohan1@gmail.com>, 
 Pavel Machek <pavel@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778432883; l=7264;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=9XCTIbMoV49y1xex8SxBrgLyf7GaS0QW2nGCwz+d0Fo=;
 b=w4H2miBquw/vmK2oBk/P8SIhaq7vtIOc/wuxLqy86jD5m7ltkZiQxcjgmCFBNgBFKnldsN/BO
 fcTis5LJoKpBXYppCZ6M53MTP2DNEAyOuwxpjFdBL2UR9TNFq50R97r
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the Silergy SY7758 I2C-controlled multi-channel LED
backlight controller. The chip drives the edge-lit LED strings of LCD
panels in handheld and embedded devices, and is for example present on
the Ayaneo Pocket DS handheld where it drives the panel backlight.

The driver registers a backlight class device with a 12-bit linear
brightness range. On the first non-zero update, the chip's mode and
current configuration registers are programmed; subsequent brightness
updates only rewrite the two brightness registers. A mutex serialises
concurrent updates against the deferred init path.

Co-developed-by: Philippe Simons <simons.philippe@gmail.com>
Signed-off-by: Philippe Simons <simons.philippe@gmail.com>
Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 drivers/video/backlight/Kconfig  |  14 ++++
 drivers/video/backlight/Makefile |   1 +
 drivers/video/backlight/sy7758.c | 169 +++++++++++++++++++++++++++++++++++++++
 3 files changed, 184 insertions(+)

diff --git a/drivers/video/backlight/Kconfig b/drivers/video/backlight/Kconfig
index a7a3fbaf7c29..c529d2861525 100644
--- a/drivers/video/backlight/Kconfig
+++ b/drivers/video/backlight/Kconfig
@@ -461,6 +461,20 @@ config BACKLIGHT_SKY81452
 	  To compile this driver as a module, choose M here: the module will
 	  be called sky81452-backlight
 
+config BACKLIGHT_SY7758
+	tristate "Backlight Driver for Silergy SY7758"
+	depends on I2C
+	select REGMAP_I2C
+	help
+	  This enables support for the Silergy SY7758 I2C-controlled
+	  multi-channel LED backlight driver, commonly used to drive the
+	  edge-lit LED strings of LCD panels in handheld and embedded
+	  devices. The driver exposes a 12-bit linear brightness control
+	  through the standard backlight class.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called sy7758.
+
 config BACKLIGHT_TPS65217
 	tristate "TPS65217 Backlight"
 	depends on MFD_TPS65217
diff --git a/drivers/video/backlight/Makefile b/drivers/video/backlight/Makefile
index 794820a98ed4..00d3e379b297 100644
--- a/drivers/video/backlight/Makefile
+++ b/drivers/video/backlight/Makefile
@@ -57,6 +57,7 @@ obj-$(CONFIG_BACKLIGHT_QCOM_WLED)	+= qcom-wled.o
 obj-$(CONFIG_BACKLIGHT_RT4831)		+= rt4831-backlight.o
 obj-$(CONFIG_BACKLIGHT_SAHARA)		+= kb3886_bl.o
 obj-$(CONFIG_BACKLIGHT_SKY81452)	+= sky81452-backlight.o
+obj-$(CONFIG_BACKLIGHT_SY7758)		+= sy7758.o
 obj-$(CONFIG_BACKLIGHT_TPS65217)	+= tps65217_bl.o
 obj-$(CONFIG_BACKLIGHT_WM831X)		+= wm831x_bl.o
 obj-$(CONFIG_BACKLIGHT_ARCXCNN) 	+= arcxcnn_bl.o
diff --git a/drivers/video/backlight/sy7758.c b/drivers/video/backlight/sy7758.c
new file mode 100644
index 000000000000..6a318bd62030
--- /dev/null
+++ b/drivers/video/backlight/sy7758.c
@@ -0,0 +1,169 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Backlight driver for the Silergy sy7758
+ *
+ * Copyright (C) 2025 Kancy Joe <kancy2333@outlook.com>
+ */
+
+#include <linux/backlight.h>
+#include <linux/err.h>
+#include <linux/gpio/consumer.h>
+#include <linux/i2c.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/regmap.h>
+
+#define DEFAULT_BRIGHTNESS 1500
+#define MAX_BRIGHTNESS 4080
+#define REG_MAX 0xa9
+
+#define BL_BRT_L 0x10
+#define BL_BRT_H 0x11
+
+static DEFINE_MUTEX(sy7758_update_backlight_mutex);
+
+struct sy7758 {
+	struct i2c_client *client;
+	struct regmap *regmap;
+	bool led_on;
+};
+
+static void sy7758_init(struct sy7758 *sydev);
+
+static const struct regmap_config sy7758_regmap_config = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = REG_MAX,
+};
+
+static int sy7758_write(struct sy7758 *sydev, unsigned int reg,
+			 unsigned int val)
+{
+	return regmap_write(sydev->regmap, reg, val);
+}
+
+static int sy7758_backlight_update_status(struct backlight_device *backlight_dev)
+{
+	struct sy7758 *sydev = bl_get_data(backlight_dev);
+	unsigned int brightness = backlight_get_brightness(backlight_dev);
+
+	mutex_lock(&sy7758_update_backlight_mutex);
+
+	if (!sydev->led_on && brightness > 0) {
+		sy7758_init(sydev);
+		sydev->led_on = true;
+	} else if (brightness == 0) {
+		sydev->led_on = false;
+	}
+
+	sy7758_write(sydev, BL_BRT_L, brightness & 0xf0);
+
+	sy7758_write(sydev, BL_BRT_H, (brightness >> 8) & 0xf);
+
+	mutex_unlock(&sy7758_update_backlight_mutex);
+	return 0;
+}
+
+static const struct backlight_ops sy7758_backlight_ops = {
+	.options = BL_CORE_SUSPENDRESUME,
+	.update_status = sy7758_backlight_update_status,
+};
+
+static void sy7758_init(struct sy7758 *sydev)
+{
+	sy7758_write(sydev, 0x01, 0x85);
+	sy7758_write(sydev, 0x10, 0x00);
+	sy7758_write(sydev, 0x11, 0x00);
+	sy7758_write(sydev, 0xa5, 0x64);
+	sy7758_write(sydev, 0xa0, 0x55);
+	sy7758_write(sydev, 0xa1, 0x9a);
+	sy7758_write(sydev, 0xa9, 0x80);
+	sy7758_write(sydev, 0xa2, 0x28);
+
+	usleep_range(10000, 11000);
+
+	sy7758_write(sydev, 0x10, 0x40);
+	sy7758_write(sydev, 0x11, 0x01);
+	// Max brightness
+	// 0x10: 0xf0 Low
+	// 0x11: 0x0f High
+
+	// Min brightness
+	// 0x10: 0x10  Low
+	// 0x11: 0x00  High
+	sydev->led_on = true;
+}
+
+static int sy7758_probe(struct i2c_client *client)
+{
+	struct backlight_device *backlight_dev;
+	struct backlight_properties props;
+	struct sy7758 *sydev;
+
+	sydev = devm_kzalloc(&client->dev, sizeof(*sydev), GFP_KERNEL);
+	if (!sydev)
+		return -ENOMEM;
+
+	sydev->client = client;
+	sydev->regmap = devm_regmap_init_i2c(client, &sy7758_regmap_config);
+	if (IS_ERR(sydev->regmap))
+		return dev_err_probe(&client->dev, PTR_ERR(sydev->regmap),
+			"failed to init regmap\n");
+
+	memset(&props, 0, sizeof(props));
+	props.type = BACKLIGHT_RAW;
+	props.max_brightness = MAX_BRIGHTNESS;
+	props.brightness = DEFAULT_BRIGHTNESS;
+	props.scale = BACKLIGHT_SCALE_LINEAR;
+
+	backlight_dev = devm_backlight_device_register(&client->dev, "sy7758-backlight",
+					&client->dev, sydev, &sy7758_backlight_ops, &props);
+	if (IS_ERR(backlight_dev))
+		return dev_err_probe(&client->dev, PTR_ERR(backlight_dev),
+				"failed to register backlight device\n");
+
+	sy7758_init(sydev);
+
+	i2c_set_clientdata(client, backlight_dev);
+	backlight_update_status(backlight_dev);
+
+	return 0;
+}
+
+static void sy7758_remove(struct i2c_client *client)
+{
+	struct backlight_device *backlight_dev = i2c_get_clientdata(client);
+
+	backlight_dev->props.brightness = 0;
+	backlight_update_status(backlight_dev);
+}
+
+static const struct i2c_device_id sy7758_ids[] = {
+	{ "sy7758" },
+	{}
+};
+MODULE_DEVICE_TABLE(i2c, sy7758_ids);
+
+static const struct of_device_id sy7758_match_table[] = {
+	{
+		.compatible = "silergy,sy7758",
+	},
+	{},
+};
+MODULE_DEVICE_TABLE(of, sy7758_match_table);
+
+static struct i2c_driver sy7758_driver = {
+	.driver = {
+		.name = "sy7758",
+		.of_match_table = sy7758_match_table,
+	},
+	.probe = sy7758_probe,
+	.remove = sy7758_remove,
+	.id_table = sy7758_ids,
+};
+
+module_i2c_driver(sy7758_driver);
+
+MODULE_DESCRIPTION("Silergy sy7758 Backlight Driver");
+MODULE_AUTHOR("Kancy Joe <kancy2333@outlook.com>");
+MODULE_LICENSE("GPL");

-- 
2.54.0

