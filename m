From: Arturs Artamonovs <arturs.artamonovs@analog.com>
Date: Thu, 12 Sep 2024 19:24:54 +0100
Subject: [PATCH 09/21] gpio: add driver for ADI ADSP-SC5xx platform
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-test-v1-9-458fa57c8ccf@analog.com>
References: <20240912-test-v1-0-458fa57c8ccf@analog.com>
In-Reply-To: <20240912-test-v1-0-458fa57c8ccf@analog.com>
To: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Greg Malysa <greg.malysa@timesys.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Utsav Agarwal <Utsav.Agarwal@analog.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Thomas Gleixner <tglx@linutronix.de>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Olof Johansson <olof@lixom.net>, soc@kernel.org
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, adsp-linux@analog.com, 
 Arturs Artamonovs <Arturs.Artamonovs@analog.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726165513; l=6581;
 i=arturs.artamonovs@analog.com; s=20240909; h=from:subject:message-id;
 bh=sIIGNtLwPRf3aETR4KIKQxLT7TsNXZDYorDVrxz6kPU=;
 b=CuyIITaHzPiP638ncfNKDHNkpBfqHvmmcTvXrLK2YXfWUbPCGduwTVFTMgybu65hKq1KAP9Zl
 N73JQEXbShnCT5+hudPmH2qYIJ2d4MFvfvtIe3KNW39sM8vDeUDcuUV
X-Developer-Key: i=arturs.artamonovs@analog.com; a=ed25519;
 pk=UXODIid/MrmBXvqkX4PeEfetDaNAw9xKMINHIc5oZCk=
X-Endpoint-Received: by B4 Relay for arturs.artamonovs@analog.com/20240909 with auth_id=206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ADSP-SC5xx GPIO driver.
- Support all GPIO ports
- Each gpio support seperate PINT interrupt controller

Signed-off-by: Arturs Artamonovs <Arturs.Artamonovs@analog.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
---
 drivers/gpio/Kconfig              |   8 +++
 drivers/gpio/Makefile             |   1 +
 drivers/gpio/gpio-adi-adsp-port.c | 145 ++++++++++++++++++++++++++++++++++++++
 3 files changed, 154 insertions(+)

diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index 58f43bcced7c1f29fad5960771817f500ef67ce1..b02693f5b4cec95a59f19aa1bacf7ed72236865a 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -147,6 +147,14 @@ config GPIO_74XX_MMIO
 	    8 bits:	74244 (Input), 74273 (Output)
 	    16 bits:	741624 (Input), 7416374 (Output)
 
+config GPIO_ADI_ADSP_PORT
+	bool "ADI ADSP PORT GPIO driver"
+	depends on OF_GPIO
+	select GPIO_GENERIC
+	help
+	  Say Y to enable the ADSP PORT-based GPIO driver for Analog Devices
+	  ADSP chips.
+
 config GPIO_ALTERA
 	tristate "Altera GPIO"
 	depends on OF_GPIO
diff --git a/drivers/gpio/Makefile b/drivers/gpio/Makefile
index 64dd6d9d730d5a22564821df71375113e31fe057..fb02c7807a674c8a38d1128e6a25bb7c7f1f4aab 100644
--- a/drivers/gpio/Makefile
+++ b/drivers/gpio/Makefile
@@ -24,6 +24,7 @@ obj-$(CONFIG_GPIO_104_IDI_48)		+= gpio-104-idi-48.o
 obj-$(CONFIG_GPIO_104_IDIO_16)		+= gpio-104-idio-16.o
 obj-$(CONFIG_GPIO_74X164)		+= gpio-74x164.o
 obj-$(CONFIG_GPIO_74XX_MMIO)		+= gpio-74xx-mmio.o
+obj-$(CONFIG_GPIO_ADI_ADSP_PORT)	+= gpio-adi-adsp-port.o
 obj-$(CONFIG_GPIO_ADNP)			+= gpio-adnp.o
 obj-$(CONFIG_GPIO_ADP5520)		+= gpio-adp5520.o
 obj-$(CONFIG_GPIO_AGGREGATOR)		+= gpio-aggregator.o
diff --git a/drivers/gpio/gpio-adi-adsp-port.c b/drivers/gpio/gpio-adi-adsp-port.c
new file mode 100644
index 0000000000000000000000000000000000000000..a7a1867495bbdd121cda9b99991865a035dfa117
--- /dev/null
+++ b/drivers/gpio/gpio-adi-adsp-port.c
@@ -0,0 +1,145 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * ADSP PORT gpio driver
+ *
+ * (C) Copyright 2022-2024 - Analog Devices, Inc.
+ */
+
+#include <linux/device.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/soc/adi/adsp-gpio-port.h>
+#include "gpiolib.h"
+
+static int adsp_gpio_direction_input(struct gpio_chip *chip, unsigned int offset)
+{
+	struct adsp_gpio_port *port = to_adsp_gpio_port(chip);
+
+	__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_DIR_CLEAR);
+	__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_INEN_SET);
+	return 0;
+}
+
+static int adsp_gpio_direction_output(struct gpio_chip *chip, unsigned int offset,
+	int value)
+{
+	struct adsp_gpio_port *port = to_adsp_gpio_port(chip);
+
+	/*
+	 * For open drain ports, they've already been configured by pinctrl and
+	 * we should not modify their output characteristics
+	 */
+	if (port->open_drain & BIT(offset))
+		return 0;
+
+	__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_INEN_CLEAR);
+
+	if (value)
+		__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_DATA_SET);
+	else
+		__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_DATA_CLEAR);
+
+	__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_DIR_SET);
+	return 0;
+}
+
+static void adsp_gpio_set_value(struct gpio_chip *chip, unsigned int offset, int value)
+{
+	struct adsp_gpio_port *port = to_adsp_gpio_port(chip);
+
+	/*
+	 * For open drain ports, set as input if driving a 1, set as output
+	 * if driving a 0
+	 */
+	if (port->open_drain & BIT(offset)) {
+		if (value) {
+			__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_DIR_CLEAR);
+			__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_INEN_SET);
+		} else {
+			__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_INEN_CLEAR);
+			__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_DATA_CLEAR);
+			__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_DIR_SET);
+		}
+	} else {
+		if (value)
+			__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_DATA_SET);
+		else
+			__adsp_gpio_writew(port, BIT(offset), ADSP_PORT_REG_DATA_CLEAR);
+	}
+}
+
+static int adsp_gpio_get_value(struct gpio_chip *chip, unsigned int offset)
+{
+	struct adsp_gpio_port *port = to_adsp_gpio_port(chip);
+
+	return !!(__adsp_gpio_readw(port, ADSP_PORT_REG_DATA) & BIT(offset));
+}
+
+static int adsp_gpio_to_irq(struct gpio_chip *chip, unsigned int offset)
+{
+	struct adsp_gpio_port *port = to_adsp_gpio_port(chip);
+	irq_hw_number_t irq = offset + port->irq_offset;
+	int map = irq_find_mapping(port->irq_domain, irq);
+
+	if (map)
+		return map;
+
+	return irq_create_mapping(port->irq_domain, irq);
+}
+
+static int adsp_gpio_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct adsp_gpio_port *gpio;
+	int ret;
+
+	gpio = devm_kzalloc(dev, sizeof(*gpio), GFP_KERNEL);
+	if (!gpio)
+		return -ENOMEM;
+
+	gpio->regs = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(gpio->regs))
+		return PTR_ERR(gpio->regs);
+
+	gpio->dev = dev;
+
+	ret = adsp_attach_pint_to_gpio(gpio);
+	if  (ret)
+		dev_err_probe(gpio->dev, ret, "error attaching interupt to gpio pin\n");
+
+	spin_lock_init(&gpio->lock);
+
+	gpio->gpio.label = "adsp-gpio";
+	gpio->gpio.direction_input = adsp_gpio_direction_input;
+	gpio->gpio.direction_output = adsp_gpio_direction_output;
+	gpio->gpio.get = adsp_gpio_get_value;
+	gpio->gpio.set = adsp_gpio_set_value;
+	gpio->gpio.to_irq = adsp_gpio_to_irq;
+	gpio->gpio.request = gpiochip_generic_request;
+	gpio->gpio.free = gpiochip_generic_free;
+	gpio->gpio.ngpio = ADSP_PORT_NGPIO;
+	gpio->gpio.parent = dev;
+	gpio->gpio.base = -1;
+	return devm_gpiochip_add_data(dev, &gpio->gpio, gpio);
+}
+
+static const struct of_device_id adsp_gpio_of_match[] = {
+	{ .compatible = "adi,adsp-port-gpio", },
+	{ },
+};
+MODULE_DEVICE_TABLE(of, adsp_gpio_of_match);
+
+static struct platform_driver adsp_gpio_driver = {
+	.driver = {
+		.name = "adsp-port-gpio",
+		.of_match_table = adsp_gpio_of_match,
+	},
+	.probe = adsp_gpio_probe,
+};
+
+module_platform_driver(adsp_gpio_driver);
+
+MODULE_AUTHOR("Greg Malysa <greg.malysa@timesys.com>");
+MODULE_DESCRIPTION("Analog Devices GPIO driver");
+MODULE_LICENSE("GPL v2");
\ No newline at end of file

-- 
2.25.1

