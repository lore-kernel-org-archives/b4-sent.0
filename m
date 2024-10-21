From: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Date: Mon, 21 Oct 2024 14:54:34 +0100
Subject: [PATCH v2 03/11] gpio: Add support for ADI ADP5588 GPIO expander
 chips
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241021-sc5xx-driver-series-v2-3-53e2472e11d0@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729518874; l=8800;
 i=vasileios.bimpikas@analog.com; s=20240927; h=from:subject:message-id;
 bh=lrd41fShxZE0Lf12hl2O9ZxrQUTaXy0BPwtHb94bH6k=;
 b=m7exsZRt2+ednXoPBfwIZtgqJHN8E43VFxywFO2VniP4yT8aD5zEJUamGgjf6/uyZzYyVfQ40
 bah7hRkkohZCitTWYNElIJ/sTnvd1AIj1KU6xIPcYRJgvTWyI9MlOYC
X-Developer-Key: i=vasileios.bimpikas@analog.com; a=ed25519;
 pk=JkXh+NeXYCpTenwrB0gg5fMpKEnagLOXdsLFiUrqZRo=
X-Endpoint-Received: by B4 Relay for vasileios.bimpikas@analog.com/20240927 with auth_id=220
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Nathan Barrett-Morrison <nathan.morrison@timesys.com>

This adds support for the ADP588 GPIO expander from Analog Devices. It
is accessed over I2C and provides up to 18 pins. It is largely a port of
the Linux driver developed by Michael Hennerich
<michael.hennerich@analog.com>

Signed-off-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
Signed-off-by: Arturs Artamonovs <arturs.artamonovs@analog.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
---
 MAINTAINERS                 |   1 +
 drivers/gpio/Kconfig        |   8 ++
 drivers/gpio/Makefile       |   1 +
 drivers/gpio/adp5588_gpio.c | 208 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 218 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index c890f2570729606e947ca07d6f12ca202cf91908..981c41cb512684736c933b78a3547657b13e016b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -612,6 +612,7 @@ F:	doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml
 F:	doc/device-tree-bindings/clock/adi,sc5xx-clocks.yaml
 F:	doc/device-tree-bindings/timer/adi,sc5xx-gptimer.yaml
 F:	drivers/clk/adi/
+F:	drivers/gpio/adp5588_gpio.c
 F:	drivers/gpio/gpio-adi-adsp.c
 F:	drivers/pinctrl/pinctrl-adi-adsp.c
 F:	drivers/serial/serial_adi_uart4.c
diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index f6f62274fb097f4eb956fa776cbfd76c468caf98..8c70c96ae7cf3f2c45ab5977215e11b740830c7e 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -547,6 +547,14 @@ config DM_PCA953X
 	  Now, max 24 bits chips and PCA953X compatible chips are
 	  supported
 
+config ADP5588_GPIO
+	bool "ADP5588 GPIO expander driver"
+	depends on DM_GPIO && DM_I2C
+	help
+	  Say yes here to support GPIO functionality of ADI ADP5588 chips.
+
+	  The ADP5588 is an 18-port I2C GPIO expander and keypad controller.
+
 config SPL_DM_PCA953X
 	bool "PCA95[357]x, PCA9698, TCA64xx, and MAX7310 I/O ports in SPL"
 	depends on SPL_DM_GPIO
diff --git a/drivers/gpio/Makefile b/drivers/gpio/Makefile
index 882c3f544c7c8d9d84f6511a818ba4d2b83a9aa1..57b12107cfd6ea46f12479fa6f242fb97a711cb3 100644
--- a/drivers/gpio/Makefile
+++ b/drivers/gpio/Makefile
@@ -74,6 +74,7 @@ obj-$(CONFIG_NOMADIK_GPIO)	+= nmk_gpio.o
 obj-$(CONFIG_MAX7320_GPIO)	+= max7320_gpio.o
 obj-$(CONFIG_$(XPL_)MAX77663_GPIO)	+= max77663_gpio.o
 obj-$(CONFIG_SL28CPLD_GPIO)	+= sl28cpld-gpio.o
+obj-$(CONFIG_ADP5588_GPIO)	+= adp5588_gpio.o
 obj-$(CONFIG_ZYNQMP_GPIO_MODEPIN)	+= zynqmp_gpio_modepin.o
 obj-$(CONFIG_SLG7XL45106_I2C_GPO)	+= gpio_slg7xl45106.o
 obj-$(CONFIG_FTGPIO010)		+= ftgpio010.o
diff --git a/drivers/gpio/adp5588_gpio.c b/drivers/gpio/adp5588_gpio.c
new file mode 100644
index 0000000000000000000000000000000000000000..d081e16989713b7dfbd0d4fdadea8dab6e243583
--- /dev/null
+++ b/drivers/gpio/adp5588_gpio.c
@@ -0,0 +1,208 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * GPIO Chip driver for Analog Devices
+ * ADP5588/ADP5587 I/O Expander and QWERTY Keypad Controller
+ *
+ * (C) Copyright 2022 - Analog Devices, Inc.
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Contact: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ * Contact: Greg Malysa <greg.malysa@timesys.com>
+ *
+ * Based on Michael Hennerich's Linux driver:
+ * Michael Hennerich <michael.hennerich@analog.com>
+ *
+ */
+
+#include <dm.h>
+#include <i2c.h>
+#include <asm-generic/gpio.h>
+
+#define ADP5588_MAXGPIO     18
+#define ADP5588_BANK(offs)  ((offs) >> 3)
+#define ADP5588_BIT(offs)   (1u << ((offs) & 0x7))
+
+#define DEV_ID          0x00    /* Device ID */
+#define GPIO_DAT_STAT1  0x14    /* GPIO Data Status, Read twice to clear */
+#define GPIO_DAT_STAT2  0x15    /* GPIO Data Status, Read twice to clear */
+#define GPIO_DAT_STAT3  0x16    /* GPIO Data Status, Read twice to clear */
+#define GPIO_DAT_OUT1   0x17    /* GPIO DATA OUT */
+#define GPIO_DAT_OUT2   0x18    /* GPIO DATA OUT */
+#define GPIO_DAT_OUT3   0x19    /* GPIO DATA OUT */
+#define GPIO_INT_EN1    0x1A    /* GPIO Interrupt Enable */
+#define GPIO_INT_EN2    0x1B    /* GPIO Interrupt Enable */
+#define GPIO_INT_EN3    0x1C    /* GPIO Interrupt Enable */
+#define KP_GPIO1        0x1D    /* Keypad or GPIO Selection */
+#define KP_GPIO2        0x1E    /* Keypad or GPIO Selection */
+#define KP_GPIO3        0x1F    /* Keypad or GPIO Selection */
+#define GPIO_DIR1       0x23    /* GPIO Data Direction */
+#define GPIO_DIR2       0x24    /* GPIO Data Direction */
+#define GPIO_DIR3       0x25	/* GPIO Data Direction */
+#define GPIO_PULL1      0x2C    /* GPIO Pull Disable */
+#define GPIO_PULL2      0x2D    /* GPIO Pull Disable */
+#define GPIO_PULL3      0x2E    /* GPIO Pull Disable */
+#define ID_MASK	        0x0F
+
+struct adp5588_gpio {
+	u8 dat_out[3];
+	u8 dir[3];
+};
+
+static int adp5588_gpio_read(struct udevice *dev, u8 reg)
+{
+	int ret;
+	u8 val;
+
+	ret = dm_i2c_read(dev, reg, &val, 1);
+
+	if (ret < 0) {
+		pr_err("%s: read error\n", __func__);
+		return ret;
+	}
+
+	return val;
+}
+
+static int adp5588_gpio_write(struct udevice *dev, u8 reg, u8 val)
+{
+	int ret;
+
+	ret = dm_i2c_write(dev, reg, &val, 1);
+	if (ret < 0) {
+		pr_err("%s: write error\n", __func__);
+		return ret;
+	}
+
+	return 0;
+}
+
+static int adp5588_get_value(struct udevice *dev, u32 offset)
+{
+	struct adp5588_gpio *plat = dev_get_plat(dev);
+	unsigned int bank = ADP5588_BANK(offset);
+	unsigned int bit = ADP5588_BIT(offset);
+	int val;
+
+	if (plat->dir[bank] & bit)
+		val = plat->dat_out[bank];
+	else
+		val = adp5588_gpio_read(dev, GPIO_DAT_STAT1 + bank);
+
+	return !!(val & bit);
+}
+
+static int adp5588_set_value(struct udevice *dev, u32 offset,
+			     int32_t value)
+{
+	unsigned int bank, bit;
+	int ret;
+	struct adp5588_gpio *plat = dev_get_plat(dev);
+
+	bank = ADP5588_BANK(offset);
+	bit = ADP5588_BIT(offset);
+
+	if (value)
+		plat->dat_out[bank] |= bit;
+	else
+		plat->dat_out[bank] &= ~bit;
+
+	ret = adp5588_gpio_write(dev, GPIO_DAT_OUT1 + bank,
+				 plat->dat_out[bank]);
+
+	return ret;
+}
+
+static int adp5588_direction_input(struct udevice *dev, u32 offset)
+{
+	int ret;
+	unsigned int bank;
+	struct adp5588_gpio *plat = dev_get_plat(dev);
+
+	bank = ADP5588_BANK(offset);
+
+	plat->dir[bank] &= ~ADP5588_BIT(offset);
+	ret = adp5588_gpio_write(dev, GPIO_DIR1 + bank, plat->dir[bank]);
+
+	return ret;
+}
+
+static int adp5588_direction_output(struct udevice *dev,
+				    u32 offset, int value)
+{
+	int ret;
+	unsigned int bank, bit;
+	struct adp5588_gpio *plat = dev_get_plat(dev);
+
+	bank = ADP5588_BANK(offset);
+	bit = ADP5588_BIT(offset);
+
+	plat->dir[bank] |= bit;
+
+	if (value)
+		plat->dat_out[bank] |= bit;
+	else
+		plat->dat_out[bank] &= ~bit;
+
+	ret = adp5588_gpio_write(dev, GPIO_DAT_OUT1 + bank,
+				 plat->dat_out[bank]);
+	ret |= adp5588_gpio_write(dev, GPIO_DIR1 + bank,
+				 plat->dir[bank]);
+
+	return ret;
+}
+
+static int adp5588_ofdata_platdata(struct udevice *dev)
+{
+	struct adp5588_gpio *plat = dev_get_plat(dev);
+	struct gpio_dev_priv *priv = dev_get_uclass_priv(dev);
+	int node = dev_of_offset(dev);
+	int ret, i, revid;
+
+	priv->gpio_count = ADP5588_MAXGPIO;
+	priv->bank_name = fdt_get_name(gd->fdt_blob, node, NULL);
+
+	ret = adp5588_gpio_read(dev, DEV_ID);
+	if (ret < 0)
+		return ret;
+
+	revid = ret & ID_MASK;
+
+	printf("ADP5588 Detected: Rev %x, Rev ID %x\n", ret, revid);
+
+	for (i = 0, ret = 0; i <= ADP5588_BANK(ADP5588_MAXGPIO); i++) {
+		plat->dat_out[i] = adp5588_gpio_read(dev, GPIO_DAT_OUT1 + i);
+		plat->dir[i] = adp5588_gpio_read(dev, GPIO_DIR1 + i);
+		ret |= adp5588_gpio_write(dev, KP_GPIO1 + i, 0);
+		ret |= adp5588_gpio_write(dev, GPIO_PULL1 + i, 0);
+		ret |= adp5588_gpio_write(dev, GPIO_INT_EN1 + i, 0);
+		if (ret) {
+			pr_err("%s: Initialization error\n", __func__);
+			return ret;
+		}
+	}
+
+	return 0;
+}
+
+static const struct dm_gpio_ops adp5588_ops = {
+	.direction_input  = adp5588_direction_input,
+	.direction_output = adp5588_direction_output,
+	.get_value		  = adp5588_get_value,
+	.set_value		  = adp5588_set_value,
+};
+
+static const struct udevice_id adp5588_of_match_list[] = {
+	{ .compatible = "adi,adp5588"},
+	{ /* sentinel */ }
+};
+
+U_BOOT_DRIVER(gpio_adp5588) = {
+	.name					  = "gpio_adp5588",
+	.id						  = UCLASS_GPIO,
+	.ops					  = &adp5588_ops,
+	.of_match				  = adp5588_of_match_list,
+	.of_to_plat		  = adp5588_ofdata_platdata,
+	.plat_auto = sizeof(struct adp5588_gpio),
+	.flags					  = DM_FLAG_PRE_RELOC,
+};

-- 
2.34.1

