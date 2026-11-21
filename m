From: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
Date: Sat, 21 Nov 2026 21:43:18 +0900
Subject: [PATCH RFC v2 08/13] Input: add polled SiRF AT550 resistive
 touchscreen driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-at550-rfc-v1-v2-8-b0309d0789b2@gmail.com>
References: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
In-Reply-To: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795264991; l=6386;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=bivtc3/plagvrQfVaPp1BcvAjec0DAYE+T6XoIbkumg=;
 b=O25c64lOHEXcHQWeBbg/TxF78uySpBOdifo+5DW1dkaYB41YmMi2sTRCCi6TF45MFrhq252fE
 mBRIOWxnSNcAdFP3qnXWX810wqcN1nu3VVOfzBKxw0CorKPB0c695rp
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a polled input driver for the SiRF AT550 resistive touchscreen
controller reporting raw ABS_X, ABS_Y, and BTN_TOUCH events.

Preserve firmware settling configuration, explicitly stop acquisition on
close before clearing pending interrupts, reject streaming or AUX mode
at probe, and rely on standard touchscreen properties with affine
calibration handled in userspace.

Signed-off-by: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
---
 MAINTAINERS                          |   1 +
 drivers/input/touchscreen/Kconfig    |  10 +++
 drivers/input/touchscreen/Makefile   |   2 +
 drivers/input/touchscreen/at550-ts.c | 124 +++++++++++++++++++++++++++++++++++
 4 files changed, 137 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index e8e239c7e..df3d38c6b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25855,6 +25855,7 @@ F:	Documentation/devicetree/bindings/input/touchscreen/sirf,at550-ts.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
 F:	Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
 F:	drivers/clocksource/timer-at550.c
+F:	drivers/input/touchscreen/at550-ts.c
 F:	drivers/irqchip/irq-at550.c
 
 SIS 190 ETHERNET DRIVER
diff --git a/drivers/input/touchscreen/Kconfig b/drivers/input/touchscreen/Kconfig
index 9b9ae8ac3..e68af1dd6 100644
--- a/drivers/input/touchscreen/Kconfig
+++ b/drivers/input/touchscreen/Kconfig
@@ -1414,4 +1414,14 @@ config TOUCHSCREEN_HIMAX_HX83112B
 	  To compile this driver as a module, choose M here: the
 	  module will be called himax_hx83112b.
 
+config TOUCHSCREEN_AT550
+	tristate "SiRF AT550 resistive touchscreen"
+	depends on OF && HAS_IOMEM
+	help
+	  Say Y to enable polled coordinate acquisition on the AT550.
+	  Coordinates and pen state are exposed through the input subsystem.
+	  Firmware must initialize the touchscreen peripheral clock.
+	  Board-specific affine calibration belongs in userspace.
+	  To build as a module, choose M; it will be called at550-ts.
+
 endif
diff --git a/drivers/input/touchscreen/Makefile b/drivers/input/touchscreen/Makefile
index bfd9de833..6b8d09601 100644
--- a/drivers/input/touchscreen/Makefile
+++ b/drivers/input/touchscreen/Makefile
@@ -119,3 +119,5 @@ obj-$(CONFIG_TOUCHSCREEN_IQS5XX)	+= iqs5xx.o
 obj-$(CONFIG_TOUCHSCREEN_IQS7211)	+= iqs7211.o
 obj-$(CONFIG_TOUCHSCREEN_ZINITIX)	+= zinitix.o
 obj-$(CONFIG_TOUCHSCREEN_HIMAX_HX83112B)	+= himax_hx83112b.o
+
+obj-$(CONFIG_TOUCHSCREEN_AT550) += at550-ts.o
diff --git a/drivers/input/touchscreen/at550-ts.c b/drivers/input/touchscreen/at550-ts.c
new file mode 100644
index 000000000..89c2d2701
--- /dev/null
+++ b/drivers/input/touchscreen/at550-ts.c
@@ -0,0 +1,124 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* SiRF AT550 coordinate acquisition. Layout cross-checked with AT551 draft. */
+#include <linux/bits.h>
+#include <linux/input.h>
+#include <linux/input/touchscreen.h>
+#include <linux/io.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+
+#define AT550_CTRL1 0x00
+#define AT550_CTRL2 0x04
+#define AT550_INTR 0x08
+#define AT550_COORD 0x0c
+#define AT550_STREAM 0x44
+#define AT550_DOWN BIT(31)
+#define AT550_VALID (BIT(29) | BIT(30))
+
+struct at550_ts {
+	void __iomem *base;
+	struct touchscreen_properties prop;
+	u32 ctrl1;
+	u32 ctrl2;
+};
+
+static void at550_ts_poll(struct input_dev *input)
+{
+	struct at550_ts *ts = input_get_drvdata(input);
+	u32 data = readl(ts->base + AT550_COORD);
+
+	if (!(data & AT550_DOWN)) {
+		input_report_key(input, BTN_TOUCH, 0);
+		input_sync(input);
+		return;
+	}
+	if ((data & AT550_VALID) != AT550_VALID)
+		return;
+	touchscreen_report_pos(input, &ts->prop, data & GENMASK(11, 0),
+			       (data >> 12) & GENMASK(11, 0), false);
+	input_report_key(input, BTN_TOUCH, 1);
+	input_sync(input);
+}
+
+static int at550_ts_open(struct input_dev *input)
+{
+	struct at550_ts *ts = input_get_drvdata(input);
+
+	/* Polling keeps the interrupt sources disabled. Preserve CE settling. */
+	writel(ts->ctrl2 | GENMASK(15, 14), ts->base + AT550_CTRL2);
+	writel((ts->ctrl1 & GENMASK(7, 4)) | BIT(11) | BIT(10),
+	       ts->base + AT550_CTRL1);
+	writel(3, ts->base + AT550_INTR);
+
+	return 0;
+}
+
+static void at550_ts_close(struct input_dev *input)
+{
+	struct at550_ts *ts = input_get_drvdata(input);
+
+	writel(ts->ctrl1 & GENMASK(7, 4), ts->base + AT550_CTRL1);
+	writel(ts->ctrl2 & ~GENMASK(15, 14), ts->base + AT550_CTRL2);
+	writel(3, ts->base + AT550_INTR);
+}
+
+static int at550_ts_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct at550_ts *ts;
+	struct input_dev *input;
+	int error;
+
+	ts = devm_kzalloc(dev, sizeof(*ts), GFP_KERNEL);
+	if (!ts)
+		return -ENOMEM;
+	ts->base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(ts->base))
+		return PTR_ERR(ts->base);
+	ts->ctrl1 = readl(ts->base + AT550_CTRL1);
+	ts->ctrl2 = readl(ts->base + AT550_CTRL2);
+	if ((ts->ctrl1 & ~0xffffU) || (ts->ctrl2 & ~0xc2ffU) ||
+	    readl(ts->base + AT550_STREAM))
+		return dev_err_probe(dev, -ENODEV, "unexpected TSC state\n");
+	input = devm_input_allocate_device(dev);
+	if (!input)
+		return -ENOMEM;
+	input->name = "SiRF AT550 touchscreen";
+	input->id.bustype = BUS_HOST;
+	input->open = at550_ts_open;
+	input->close = at550_ts_close;
+	input_set_drvdata(input, ts);
+	input_set_capability(input, EV_KEY, BTN_TOUCH);
+	input_set_abs_params(input, ABS_X, 0, 4095, 2, 0);
+	input_set_abs_params(input, ABS_Y, 0, 4095, 2, 0);
+	touchscreen_parse_properties(input, false, &ts->prop);
+	error = input_setup_polling(input, at550_ts_poll);
+	if (error)
+		return error;
+	input_set_poll_interval(input, 10);
+
+	error = input_register_device(input);
+	if (error)
+		return error;
+
+	return 0;
+}
+
+static const struct of_device_id at550_ts_of_match[] = {
+	{ .compatible = "sirf,at550-ts" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, at550_ts_of_match);
+
+static struct platform_driver at550_ts_driver = {
+	.probe = at550_ts_probe,
+	.driver = {
+		.name = "at550-ts",
+		.of_match_table = at550_ts_of_match,
+	},
+};
+module_platform_driver(at550_ts_driver);
+
+MODULE_DESCRIPTION("SiRF AT550 resistive touchscreen");
+MODULE_LICENSE("GPL");

-- 
2.56.0

