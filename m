From: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Date: Mon, 21 Oct 2024 14:54:33 +0100
Subject: [PATCH v2 02/11] gpio: Add support for SC5XX-family processor GPIO
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241021-sc5xx-driver-series-v2-2-53e2472e11d0@analog.com>
References: <20241021-sc5xx-driver-series-v2-0-53e2472e11d0@analog.com>
In-Reply-To: <20241021-sc5xx-driver-series-v2-0-53e2472e11d0@analog.com>
To: Tom Rini <trini@konsulko.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>, 
 Greg Malysa <greg.malysa@timesys.com>, 
 Ian Roberts <ian.roberts@timesys.com>, 
 Vasileios Bimpikas <vasileios.bimpikas@analog.com>, 
 Utsav Agarwal <utsav.agarwal@analog.com>, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, 
 Marek Vasut <marex@denx.de>, Heiko Schocher <hs@denx.de>, 
 Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>, Stefan Roese <sr@denx.de>, 
 Jagan Teki <jagan@amarulasolutions.com>, Peng Fan <peng.fan@nxp.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>
Cc: u-boot@lists.denx.de, adsp-linux@analog.com, 
 Oliver Gaskell <Oliver.Gaskell@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729518874; l=7781;
 i=vasileios.bimpikas@analog.com; s=20240927; h=from:subject:message-id;
 bh=zDnOkVE+R6wznzVeXnMOb22YwikAbgaYqPVPmEsDVB4=;
 b=qoZ3fEpedlH9bhjJ3MrrJk9dWqaxTaQpdMIjX4OIjFDLSl00EuxNB+6eeInLAJc/0sNRUoh3k
 kpJvejlqTO7BQhYxDHZVWbhLNeSmkue/wkG3PeVGpwbz5ea3Vzpzygx
X-Developer-Key: i=vasileios.bimpikas@analog.com; a=ed25519;
 pk=JkXh+NeXYCpTenwrB0gg5fMpKEnagLOXdsLFiUrqZRo=
X-Endpoint-Received: by B4 Relay for vasileios.bimpikas@analog.com/20240927 with auth_id=220
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Oliver Gaskell <Oliver.Gaskell@analog.com>

This adds support for using the GPIO pins on the SC5XX family of SoCs
from Analog Devices.

Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
Signed-off-by: Arturs Artamonovs <arturs.artamonovs@analog.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 MAINTAINERS                  |   1 +
 drivers/gpio/Kconfig         |   9 +++
 drivers/gpio/Makefile        |   1 +
 drivers/gpio/gpio-adi-adsp.c | 179 +++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 190 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 47dd18c6563fd3f98643a84cfc48af79e3e39f39..c890f2570729606e947ca07d6f12ca202cf91908 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -612,6 +612,7 @@ F:	doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml
 F:	doc/device-tree-bindings/clock/adi,sc5xx-clocks.yaml
 F:	doc/device-tree-bindings/timer/adi,sc5xx-gptimer.yaml
 F:	drivers/clk/adi/
+F:	drivers/gpio/gpio-adi-adsp.c
 F:	drivers/pinctrl/pinctrl-adi-adsp.c
 F:	drivers/serial/serial_adi_uart4.c
 F:	drivers/timer/adi_sc5xx_timer.c
diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index 1e5711663eb8adc4109cb9793c49e679025e2ef6..f6f62274fb097f4eb956fa776cbfd76c468caf98 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -97,6 +97,15 @@ config SPL_DM_GPIO_LOOKUP_LABEL
 	  different gpios on different hardware versions
 	  for the same functionality in board code.
 
+config ADI_GPIO
+	bool "ADI GPIO driver"
+	depends on DM_GPIO && ARCH_SC5XX
+	help
+	  This driver supports GPIO banks on SC5xx processors. It
+	  supports inputs and outputs but does not support pin
+	  interrupt functionality (PINT) or other features in the
+	  Linux version of the driver.
+
 config ALTERA_PIO
 	bool "Altera PIO driver"
 	depends on DM_GPIO
diff --git a/drivers/gpio/Makefile b/drivers/gpio/Makefile
index fe81b6ba88b1adc815ebf04e6b65a164cda91bb8..882c3f544c7c8d9d84f6511a818ba4d2b83a9aa1 100644
--- a/drivers/gpio/Makefile
+++ b/drivers/gpio/Makefile
@@ -12,6 +12,7 @@ obj-$(CONFIG_$(PHASE_)DM_GPIO) += gpio-uclass.o
 
 obj-$(CONFIG_$(XPL_)DM_PCA953X)	+= pca953x_gpio.o
 
+obj-$(CONFIG_ADI_GPIO)		+= gpio-adi-adsp.o
 obj-$(CONFIG_ASPEED_GPIO)	+= gpio-aspeed.o
 obj-$(CONFIG_ASPEED_G7_GPIO)	+= gpio-aspeed-g7.o
 obj-$(CONFIG_AT91_GPIO)	+= at91_gpio.o
diff --git a/drivers/gpio/gpio-adi-adsp.c b/drivers/gpio/gpio-adi-adsp.c
new file mode 100644
index 0000000000000000000000000000000000000000..0ce00572e082003a250ba69a30bde963c654bb2c
--- /dev/null
+++ b/drivers/gpio/gpio-adi-adsp.c
@@ -0,0 +1,179 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2022 - Analog Devices, Inc.
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Author: Greg Malysa <greg.malysa@timesys.com>
+ * Additional Contact: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ */
+
+#include <dm.h>
+#include <asm-generic/gpio.h>
+#include <dm/device_compat.h>
+#include <linux/bitops.h>
+#include <linux/io.h>
+
+#define ADSP_PORT_MMIO_SIZE		0x80
+#define ADSP_PORT_PIN_SIZE		16
+
+#define ADSP_PORT_REG_FER			0x00
+#define ADSP_PORT_REG_FER_SET		0x04
+#define ADSP_PORT_REG_FER_CLEAR		0x08
+#define ADSP_PORT_REG_DATA			0x0c
+#define ADSP_PORT_REG_DATA_SET		0x10
+#define ADSP_PORT_REG_DATA_CLEAR	0x14
+#define ADSP_PORT_REG_DIR			0x18
+#define ADSP_PORT_REG_DIR_SET		0x1c
+#define ADSP_PORT_REG_DIR_CLEAR		0x20
+#define ADSP_PORT_REG_INEN			0x24
+#define ADSP_PORT_REG_INEN_SET		0x28
+#define ADSP_PORT_REG_INEN_CLEAR	0x2c
+#define ADSP_PORT_REG_PORT_MUX		0x30
+#define ADSP_PORT_REG_DATA_TGL		0x34
+#define ADSP_PORT_REG_POLAR			0x38
+#define ADSP_PORT_REG_POLAR_SET		0x3c
+#define ADSP_PORT_REG_POLAR_CLEAR	0x40
+#define ADSP_PORT_REG_LOCK			0x44
+#define ADSP_PORT_REG_TRIG_TGL		0x48
+
+struct adsp_gpio_priv {
+	void __iomem *base;
+	int ngpio;
+};
+
+static u32 get_port(unsigned int pin)
+{
+	return pin / ADSP_PORT_PIN_SIZE;
+}
+
+static u32 get_offset(unsigned int pin)
+{
+	return pin % ADSP_PORT_PIN_SIZE;
+}
+
+static int adsp_gpio_input(struct udevice *udev, unsigned int pin)
+{
+	struct adsp_gpio_priv *priv = dev_get_priv(udev);
+	u32 port, offset;
+	void __iomem *portbase;
+
+	if (pin < priv->ngpio) {
+		port = get_port(pin);
+		offset = get_offset(pin);
+		portbase = priv->base + port * ADSP_PORT_MMIO_SIZE;
+
+		iowrite16(BIT(offset), portbase + ADSP_PORT_REG_FER_CLEAR);
+		iowrite16(BIT(offset), portbase + ADSP_PORT_REG_DIR_CLEAR);
+		iowrite16(BIT(offset), portbase + ADSP_PORT_REG_INEN_SET);
+		return 0;
+	}
+
+	return -EINVAL;
+}
+
+static int adsp_gpio_output(struct udevice *udev, unsigned int pin, int value)
+{
+	struct adsp_gpio_priv *priv = dev_get_priv(udev);
+	u32 port, offset;
+	void __iomem *portbase;
+
+	if (pin < priv->ngpio) {
+		port = get_port(pin);
+		offset = get_offset(pin);
+		portbase = priv->base + port * ADSP_PORT_MMIO_SIZE;
+
+		iowrite16(BIT(offset), portbase + ADSP_PORT_REG_FER_CLEAR);
+
+		if (value)
+			iowrite16(BIT(offset), portbase + ADSP_PORT_REG_DATA_SET);
+		else
+			iowrite16(BIT(offset), portbase + ADSP_PORT_REG_DATA_CLEAR);
+
+		iowrite16(BIT(offset), portbase + ADSP_PORT_REG_DIR_SET);
+		iowrite16(BIT(offset), portbase + ADSP_PORT_REG_INEN_CLEAR);
+		return 0;
+	}
+
+	return -EINVAL;
+}
+
+static int adsp_gpio_get_value(struct udevice *udev, unsigned int pin)
+{
+	struct adsp_gpio_priv *priv = dev_get_priv(udev);
+	u32 port, offset;
+	u16 val;
+	void __iomem *portbase;
+
+	if (pin < priv->ngpio) {
+		port = get_port(pin);
+		offset = get_offset(pin);
+		portbase = priv->base + port * ADSP_PORT_MMIO_SIZE;
+
+		val = ioread16(portbase + ADSP_PORT_REG_DATA);
+		return !!(val & BIT(offset));
+	}
+
+	return 0;
+}
+
+static int adsp_gpio_set_value(struct udevice *udev, unsigned int pin, int value)
+{
+	struct adsp_gpio_priv *priv = dev_get_priv(udev);
+	u32 port, offset;
+	void __iomem *portbase;
+
+	if (pin < priv->ngpio) {
+		port = get_port(pin);
+		offset = get_offset(pin);
+		portbase = priv->base + port * ADSP_PORT_MMIO_SIZE;
+
+		if (value)
+			iowrite16(BIT(offset), portbase + ADSP_PORT_REG_DATA_SET);
+		else
+			iowrite16(BIT(offset), portbase + ADSP_PORT_REG_DATA_CLEAR);
+	}
+
+	return 0;
+}
+
+static const struct dm_gpio_ops adsp_gpio_ops = {
+	.direction_input = adsp_gpio_input,
+	.direction_output = adsp_gpio_output,
+	.get_value = adsp_gpio_get_value,
+	.set_value = adsp_gpio_set_value,
+};
+
+static int adsp_gpio_probe(struct udevice *udev)
+{
+	struct adsp_gpio_priv *priv = dev_get_priv(udev);
+	struct gpio_dev_priv *uc_priv = dev_get_uclass_priv(udev);
+
+	uc_priv->bank_name = "adsp gpio";
+	uc_priv->gpio_count = dev_read_u32_default(udev, "adi,ngpios", 0);
+
+	if (!uc_priv->gpio_count) {
+		dev_err(udev, "Missing adi,ngpios property!\n");
+		return -ENOENT;
+	}
+
+	priv->base = dev_read_addr_ptr(udev);
+	priv->ngpio = uc_priv->gpio_count;
+
+	return 0;
+}
+
+static const struct udevice_id adsp_gpio_match[] = {
+	{ .compatible = "adi,adsp-gpio" },
+	{ },
+};
+
+U_BOOT_DRIVER(adi_adsp_gpio) = {
+	.name	= "adi_adsp_gpio",
+	.id	= UCLASS_GPIO,
+	.ops	= &adsp_gpio_ops,
+	.probe	= adsp_gpio_probe,
+	.priv_auto = sizeof(struct adsp_gpio_priv),
+	.of_match = adsp_gpio_match,
+	.flags = DM_FLAG_PRE_RELOC,
+};

-- 
2.34.1

