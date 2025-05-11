From: Sven Peter <sven@svenpeter.dev>
Date: Sun, 11 May 2025 08:18:41 +0000
Subject: [PATCH v5 06/10] gpio: Add new gpio-macsmc driver for Apple Macs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250511-smc-6-15-v5-6-f5980bdb18bd@svenpeter.dev>
References: <20250511-smc-6-15-v5-0-f5980bdb18bd@svenpeter.dev>
In-Reply-To: <20250511-smc-6-15-v5-0-f5980bdb18bd@svenpeter.dev>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Hector Martin <marcan@marcan.st>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Lee Jones <lee@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=10903; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=cY0RS4QBs9Lhm5l43EQ+x1vENi1UVnu9dkHlYi/s2lU=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4ZCbNkXy+dbaiMCtzY2Xn9Vk2B/r4rxt/+fJymSF4o+3
 30kvVG0o5SFQYyDQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjARmyiGvxJvbI5UPOZ9GpoZ
 vWVl6iWHP/peLwMsb+xRu7HzE79lqjTDX5GmaP9Zcu9ZpladmVbposuzVOLso2s/s2f9OTn/TPd
 5J14A
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

This driver implements the GPIO service on top of the SMC framework
on Apple Mac machines. In particular, these are the GPIOs present in the
PMU IC which are used to control power to certain on-board devices.

Although the underlying hardware supports various pin config settings
(input/output, open drain, etc.), this driver does not implement that
functionality and leaves it up to the firmware to configure things
properly. We also don't yet support interrupts/events. This is
sufficient for device power control, which is the only thing we need to
support at this point. More features will be implemented when needed.

To our knowledge, only Apple Silicon Macs implement this SMC feature.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Bartosz Golaszewski <brgl@bgdev.pl>
Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
Reviewed-by: Sven Peter <sven@svenpeter.dev>
Signed-off-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 MAINTAINERS                |   1 +
 drivers/gpio/Kconfig       |  10 ++
 drivers/gpio/Makefile      |   1 +
 drivers/gpio/gpio-macsmc.c | 293 +++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 305 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index dfaca531600c22d487fb17a25294686611dd4513..fa3a5f9ee40446bcc725c9eac2a36651e6bc7553 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2291,6 +2291,7 @@ F:	drivers/bluetooth/hci_bcm4377.c
 F:	drivers/clk/clk-apple-nco.c
 F:	drivers/cpufreq/apple-soc-cpufreq.c
 F:	drivers/dma/apple-admac.c
+F:	drivers/gpio/gpio-macsmc.c
 F:	drivers/pmdomain/apple/
 F:	drivers/i2c/busses/i2c-pasemi-core.c
 F:	drivers/i2c/busses/i2c-pasemi-platform.c
diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index f2c39bbff83a33dcb12b2d32aa3ebc358a0dd949..f0e25105f8ebe7356344722987333a9fc244ea1f 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -1440,6 +1440,16 @@ config GPIO_LP87565
 	  This driver can also be built as a module. If so, the module will be
 	  called gpio-lp87565.
 
+config GPIO_MACSMC
+	tristate "Apple Mac SMC GPIO"
+	depends on MFD_MACSMC
+	help
+	  Support for GPIOs controlled by the SMC microcontroller on Apple Mac
+	  systems.
+
+	  This driver can also be built as a module. If so, the module will be
+	  called gpio-macsmc.
+
 config GPIO_MADERA
 	tristate "Cirrus Logic Madera class codecs"
 	depends on PINCTRL_MADERA
diff --git a/drivers/gpio/Makefile b/drivers/gpio/Makefile
index af130882ffeeef8b1d518867bfe1493ec4f21b5f..c2e47f356bfae73384ace8103074f246e49fb9d6 100644
--- a/drivers/gpio/Makefile
+++ b/drivers/gpio/Makefile
@@ -97,6 +97,7 @@ obj-$(CONFIG_GPIO_LP873X)		+= gpio-lp873x.o
 obj-$(CONFIG_GPIO_LP87565)		+= gpio-lp87565.o
 obj-$(CONFIG_GPIO_LPC18XX)		+= gpio-lpc18xx.o
 obj-$(CONFIG_GPIO_LPC32XX)		+= gpio-lpc32xx.o
+obj-$(CONFIG_GPIO_MACSMC)		+= gpio-macsmc.o
 obj-$(CONFIG_GPIO_MADERA)		+= gpio-madera.o
 obj-$(CONFIG_GPIO_MAX3191X)		+= gpio-max3191x.o
 obj-$(CONFIG_GPIO_MAX7300)		+= gpio-max7300.o
diff --git a/drivers/gpio/gpio-macsmc.c b/drivers/gpio/gpio-macsmc.c
new file mode 100644
index 0000000000000000000000000000000000000000..bb179c71a05e294c9ec68db332ad4c0dff118d1a
--- /dev/null
+++ b/drivers/gpio/gpio-macsmc.c
@@ -0,0 +1,293 @@
+// SPDX-License-Identifier: GPL-2.0-only OR MIT
+/*
+ * Apple SMC GPIO driver
+ * Copyright The Asahi Linux Contributors
+ *
+ * This driver implements basic SMC PMU GPIO support that can read inputs
+ * and write outputs. Mode changes and IRQ config are not yet implemented.
+ */
+
+#include <linux/bitmap.h>
+#include <linux/device.h>
+#include <linux/gpio/driver.h>
+#include <linux/mfd/core.h>
+#include <linux/mfd/macsmc.h>
+
+#define MAX_GPIO 64
+
+/*
+ * Commands 0-6 are, presumably, the intended API.
+ * Command 0xff lets you get/set the pin configuration in detail directly,
+ * but the bit meanings seem not to be stable between devices/PMU hardware
+ * versions.
+ *
+ * We're going to try to make do with the low commands for now.
+ * We don't implement pin mode changes at this time.
+ */
+
+#define CMD_ACTION	(0 << 24)
+#define CMD_OUTPUT	(1 << 24)
+#define CMD_INPUT	(2 << 24)
+#define CMD_PINMODE	(3 << 24)
+#define CMD_IRQ_ENABLE	(4 << 24)
+#define CMD_IRQ_ACK	(5 << 24)
+#define CMD_IRQ_MODE	(6 << 24)
+#define CMD_CONFIG	(0xff << 24)
+
+#define MODE_INPUT	0
+#define MODE_OUTPUT	1
+#define MODE_VALUE_0	0
+#define MODE_VALUE_1	2
+
+#define IRQ_MODE_HIGH		0
+#define IRQ_MODE_LOW		1
+#define IRQ_MODE_RISING		2
+#define IRQ_MODE_FALLING	3
+#define IRQ_MODE_BOTH		4
+
+#define CONFIG_MASK	GENMASK(23, 16)
+#define CONFIG_VAL	GENMASK(7, 0)
+
+#define CONFIG_OUTMODE	GENMASK(7, 6)
+#define CONFIG_IRQMODE	GENMASK(5, 3)
+#define CONFIG_PULLDOWN	BIT(2)
+#define CONFIG_PULLUP	BIT(1)
+#define CONFIG_OUTVAL	BIT(0)
+
+/*
+ * Output modes seem to differ depending on the PMU in use... ?
+ * j274 / M1 (Sera PMU):
+ *   0 = input
+ *   1 = output
+ *   2 = open drain
+ *   3 = disable
+ * j314 / M1Pro (Maverick PMU):
+ *   0 = input
+ *   1 = open drain
+ *   2 = output
+ *   3 = ?
+ */
+
+struct macsmc_gpio {
+	struct device *dev;
+	struct apple_smc *smc;
+	struct gpio_chip gc;
+
+	int first_index;
+};
+
+static int macsmc_gpio_nr(smc_key key)
+{
+	int low = hex_to_bin(key & 0xff);
+	int high = hex_to_bin((key >> 8) & 0xff);
+
+	if (low < 0 || high < 0)
+		return -1;
+
+	return low | (high << 4);
+}
+
+static int macsmc_gpio_key(unsigned int offset)
+{
+	return _SMC_KEY("gP\0\0") | hex_asc_hi(offset) << 8 | hex_asc_lo(offset);
+}
+
+static int macsmc_gpio_find_first_gpio_index(struct macsmc_gpio *smcgp)
+{
+	struct apple_smc *smc = smcgp->smc;
+	smc_key key = macsmc_gpio_key(0);
+	smc_key first_key, last_key;
+	int start, count, ret;
+
+	/* Return early if the key is out of bounds */
+	ret = apple_smc_get_key_by_index(smc, 0, &first_key);
+	if (ret)
+		return ret;
+	if (key <= first_key)
+		return -ENODEV;
+
+	ret = apple_smc_get_key_by_index(smc, smc->key_count - 1, &last_key);
+	if (ret)
+		return ret;
+	if (key > last_key)
+		return -ENODEV;
+
+	/* Binary search to find index of first SMC key bigger or equal to key */
+	start = 0;
+	count = smc->key_count;
+	while (count > 1) {
+		smc_key pkey;
+		int pivot = start + ((count - 1) >> 1);
+
+		ret = apple_smc_get_key_by_index(smc, pivot, &pkey);
+		if (ret < 0)
+			return ret;
+
+		if (pkey == key)
+			return pivot;
+
+		pivot++;
+
+		if (pkey < key) {
+			count -= pivot - start;
+			start = pivot;
+		} else {
+			count = pivot - start;
+		}
+	}
+
+	return start;
+}
+
+static int macsmc_gpio_get_direction(struct gpio_chip *gc, unsigned int offset)
+{
+	struct macsmc_gpio *smcgp = gpiochip_get_data(gc);
+	smc_key key = macsmc_gpio_key(offset);
+	u32 val;
+	int ret;
+
+	/* First try reading the explicit pin mode register */
+	ret = apple_smc_rw_u32(smcgp->smc, key, CMD_PINMODE, &val);
+	if (!ret)
+		return (val & MODE_OUTPUT) ? GPIO_LINE_DIRECTION_OUT : GPIO_LINE_DIRECTION_IN;
+
+	/*
+	 * Less common IRQ configs cause CMD_PINMODE to fail, and so does open drain mode.
+	 * Fall back to reading IRQ mode, which will only succeed for inputs.
+	 */
+	ret = apple_smc_rw_u32(smcgp->smc, key, CMD_IRQ_MODE, &val);
+	return ret ? GPIO_LINE_DIRECTION_OUT : GPIO_LINE_DIRECTION_IN;
+}
+
+static int macsmc_gpio_get(struct gpio_chip *gc, unsigned int offset)
+{
+	struct macsmc_gpio *smcgp = gpiochip_get_data(gc);
+	smc_key key = macsmc_gpio_key(offset);
+	u32 cmd, val;
+	int ret;
+
+	ret = macsmc_gpio_get_direction(gc, offset);
+	if (ret < 0)
+		return ret;
+
+	if (ret == GPIO_LINE_DIRECTION_OUT)
+		cmd = CMD_OUTPUT;
+	else
+		cmd = CMD_INPUT;
+
+	ret = apple_smc_rw_u32(smcgp->smc, key, cmd, &val);
+	if (ret < 0)
+		return ret;
+
+	return val ? 1 : 0;
+}
+
+static int macsmc_gpio_set(struct gpio_chip *gc, unsigned int offset, int value)
+{
+	struct macsmc_gpio *smcgp = gpiochip_get_data(gc);
+	smc_key key = macsmc_gpio_key(offset);
+	int ret;
+
+	value |= CMD_OUTPUT;
+	ret = apple_smc_write_u32(smcgp->smc, key, CMD_OUTPUT | value);
+	if (ret < 0)
+		dev_err(smcgp->dev, "GPIO set failed %p4ch = 0x%x\n",
+			&key, value);
+
+	return ret;
+}
+
+static int macsmc_gpio_init_valid_mask(struct gpio_chip *gc,
+				       unsigned long *valid_mask, unsigned int ngpios)
+{
+	struct macsmc_gpio *smcgp = gpiochip_get_data(gc);
+	int count;
+	int i;
+
+	count = min(smcgp->smc->key_count, MAX_GPIO);
+
+	bitmap_zero(valid_mask, ngpios);
+
+	for (i = 0; i < count; i++) {
+		int ret, gpio_nr;
+		smc_key key;
+
+		ret = apple_smc_get_key_by_index(smcgp->smc, smcgp->first_index + i, &key);
+		if (ret < 0)
+			return ret;
+
+		if (key > SMC_KEY(gPff))
+			break;
+
+		gpio_nr = macsmc_gpio_nr(key);
+		if (gpio_nr < 0 || gpio_nr > MAX_GPIO) {
+			dev_err(smcgp->dev, "Bad GPIO key %p4ch\n", &key);
+			continue;
+		}
+
+		set_bit(gpio_nr, valid_mask);
+	}
+
+	return 0;
+}
+
+static int macsmc_gpio_probe(struct platform_device *pdev)
+{
+	struct macsmc_gpio *smcgp;
+	struct apple_smc *smc = dev_get_drvdata(pdev->dev.parent);
+	smc_key key;
+	int ret;
+
+	smcgp = devm_kzalloc(&pdev->dev, sizeof(*smcgp), GFP_KERNEL);
+	if (!smcgp)
+		return -ENOMEM;
+
+	smcgp->dev = &pdev->dev;
+	smcgp->smc = smc;
+
+	smcgp->first_index = macsmc_gpio_find_first_gpio_index(smcgp);
+	if (smcgp->first_index < 0)
+		return smcgp->first_index;
+
+	ret = apple_smc_get_key_by_index(smc, smcgp->first_index, &key);
+	if (ret < 0)
+		return ret;
+
+	if (key > macsmc_gpio_key(MAX_GPIO - 1))
+		return -ENODEV;
+
+	dev_info(smcgp->dev, "First GPIO key: %p4ch\n", &key);
+
+	smcgp->gc.label = "macsmc-pmu-gpio";
+	smcgp->gc.owner = THIS_MODULE;
+	smcgp->gc.get = macsmc_gpio_get;
+	smcgp->gc.set_rv = macsmc_gpio_set;
+	smcgp->gc.get_direction = macsmc_gpio_get_direction;
+	smcgp->gc.init_valid_mask = macsmc_gpio_init_valid_mask;
+	smcgp->gc.can_sleep = true;
+	smcgp->gc.ngpio = MAX_GPIO;
+	smcgp->gc.base = -1;
+	smcgp->gc.parent = &pdev->dev;
+
+	return devm_gpiochip_add_data(&pdev->dev, &smcgp->gc, smcgp);
+}
+
+static const struct of_device_id macsmc_gpio_of_table[] = {
+	{ .compatible = "apple,smc-gpio", },
+	{}
+};
+MODULE_DEVICE_TABLE(of, macsmc_gpio_of_table);
+
+static struct platform_driver macsmc_gpio_driver = {
+	.driver = {
+		.name = "macsmc-gpio",
+		.of_match_table = macsmc_gpio_of_table,
+	},
+	.probe = macsmc_gpio_probe,
+};
+module_platform_driver(macsmc_gpio_driver);
+
+MODULE_AUTHOR("Hector Martin <marcan@marcan.st>");
+MODULE_LICENSE("Dual MIT/GPL");
+MODULE_DESCRIPTION("Apple SMC GPIO driver");
+MODULE_ALIAS("platform:macsmc-gpio");

-- 
2.34.1

