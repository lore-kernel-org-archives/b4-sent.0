From: yy-Local-LLM <yogo.0917.sabu@gmail.com>
Date: Tue, 17 Nov 2026 22:06:54 +0900
Subject: [PATCH RFC 4/6] Input: add polled SiRF AT550 resistive touch
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-at550-rfc-v1-v1-4-5879573cb825@gmail.com>
References: <20261117-at550-rfc-v1-v1-0-5879573cb825@gmail.com>
In-Reply-To: <20261117-at550-rfc-v1-v1-0-5879573cb825@gmail.com>
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Ulf Hansson <ulfh@kernel.org>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920817; l=6122;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=4S1aTi+unk74MXK+J63dLTnVcbz6m2tdAaKPHjtbsec=;
 b=ez1fyL3NeM0iCsiIeh4TpbfqIc7q0PKL8bu8dxVHuzeK9UKlDw5OD6PetT571k20Dcp1naRHN
 bHSjreB2/0WC+xK5JOGdlBzwToAFihkTCUni3KlOTSq2/lOzWQwLMDh
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Report raw ABS_X/ABS_Y and BTN_TOUCH using the input polling framework.
Preserve the firmware settling settings and reject streaming/AUX
ownership. Use standard touchscreen axis properties; keep affine
calibration in userspace. Polling is the initial supported acquisition
mode.

Signed-off-by: yy-Local-LLM <yogo.0917.sabu@gmail.com>
---
 MAINTAINERS                          |   1 +
 drivers/input/touchscreen/Kconfig    |  10 ++++
 drivers/input/touchscreen/Makefile   |   2 +
 drivers/input/touchscreen/at550-ts.c | 108 +++++++++++++++++++++++++++++++++++
 4 files changed, 121 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 3fea2160a..441492230 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25856,6 +25856,7 @@ F:	Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
 F:	Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
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
index 000000000..0a208f4a9
--- /dev/null
+++ b/drivers/input/touchscreen/at550-ts.c
@@ -0,0 +1,108 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* SiRF AT550 coordinate acquisition. Layout cross-checked with AT551 draft. */
+#include <linux/bitfield.h>
+#include <linux/input.h>
+#include <linux/input/touchscreen.h>
+#include <linux/io.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+#define AT550_CTRL1 0x00
+#define AT550_CTRL2 0x04
+#define AT550_INTR 0x08
+#define AT550_COORD 0x0c
+#define AT550_STREAM 0x44
+#define AT550_DOWN BIT(31)
+#define AT550_VALID (BIT(29) | BIT(30))
+struct at550_ts {
+	void __iomem *base;
+	struct touchscreen_properties prop;
+	u32 ctrl1;
+	u32 ctrl2;
+};
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
+static int at550_ts_open(struct input_dev *input)
+{
+	struct at550_ts *ts = input_get_drvdata(input);
+
+	/* Polling keeps the interrupt sources disabled. Preserve CE settling. */
+	writel(3, ts->base + AT550_INTR);
+	writel(ts->ctrl2 | GENMASK(15, 14), ts->base + AT550_CTRL2);
+	writel((ts->ctrl1 & GENMASK(7, 4)) | BIT(11) | BIT(10),
+	       ts->base + AT550_CTRL1);
+	return 0;
+}
+static void at550_ts_close(struct input_dev *input)
+{
+	struct at550_ts *ts = input_get_drvdata(input);
+
+	writel(3, ts->base + AT550_INTR);
+	writel(ts->ctrl1, ts->base + AT550_CTRL1);
+	writel(ts->ctrl2, ts->base + AT550_CTRL2);
+}
+static int at550_ts_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct at550_ts *ts;
+	struct input_dev *input;
+	int ret;
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
+	ret = input_setup_polling(input, at550_ts_poll);
+	if (ret)
+		return ret;
+	input_set_poll_interval(input, 10);
+	return input_register_device(input);
+}
+static const struct of_device_id at550_ts_of_match[] = {
+	{ .compatible = "sirf,at550-ts" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, at550_ts_of_match);
+static struct platform_driver at550_ts_driver = {
+	.probe = at550_ts_probe,
+	.driver = {
+		.name = "at550-ts",
+		.of_match_table = at550_ts_of_match,
+	},
+};
+module_platform_driver(at550_ts_driver);
+MODULE_DESCRIPTION("SiRF AT550 resistive touchscreen");
+MODULE_LICENSE("GPL");

-- 
2.56.0

