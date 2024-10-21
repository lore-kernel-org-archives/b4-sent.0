From: Vasileios Bimpikas <vasileios.bimpikas@analog.com>
Date: Mon, 21 Oct 2024 14:54:32 +0100
Subject: [PATCH v2 01/11] pinctrl: Add support for ADI SC5XX-family pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241021-sc5xx-driver-series-v2-1-53e2472e11d0@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729518874; l=8220;
 i=vasileios.bimpikas@analog.com; s=20240927; h=from:subject:message-id;
 bh=jqOlPvCecGT6tLNrgCScoGZ62pKW4sKAoQWakGQoUz4=;
 b=GkmJpJNrEE4CjXgull1ots0Euz6CjmRkeuvDyyn2T0zUEgCqk1gLX8AYqAcc2rLQibwbkINYv
 b0ijdmxUewLB5CB9LmTlBYBaVVPbOxmJpeDI7jILqgg3NH0/b7TP8ve
X-Developer-Key: i=vasileios.bimpikas@analog.com; a=ed25519;
 pk=JkXh+NeXYCpTenwrB0gg5fMpKEnagLOXdsLFiUrqZRo=
X-Endpoint-Received: by B4 Relay for vasileios.bimpikas@analog.com/20240927 with auth_id=220
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Oliver Gaskell <Oliver.Gaskell@analog.com>

This adds support for pin configuration on the Analog Devices SC5XX SoC
family. This commit is largely a port of the Linux driver, which has not
yet been submitted upstream.

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
 MAINTAINERS                            |   1 +
 drivers/pinctrl/Kconfig                |   8 ++
 drivers/pinctrl/Makefile               |   1 +
 drivers/pinctrl/pinctrl-adi-adsp.c     | 156 +++++++++++++++++++++++++++++++++
 include/dt-bindings/pinctrl/adi-adsp.h |  21 +++++
 5 files changed, 187 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 573403734b29adc7a091eba93bb5ffab33bdf4d3..47dd18c6563fd3f98643a84cfc48af79e3e39f39 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -612,6 +612,7 @@ F:	doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml
 F:	doc/device-tree-bindings/clock/adi,sc5xx-clocks.yaml
 F:	doc/device-tree-bindings/timer/adi,sc5xx-gptimer.yaml
 F:	drivers/clk/adi/
+F:	drivers/pinctrl/pinctrl-adi-adsp.c
 F:	drivers/serial/serial_adi_uart4.c
 F:	drivers/timer/adi_sc5xx_timer.c
 F:	include/configs/sc5*
diff --git a/drivers/pinctrl/Kconfig b/drivers/pinctrl/Kconfig
index a1d53cfbdbed5ef1030fff04715e1436f167554b..a88a4442184b3e62b48b5af7616f2db98789cfeb 100644
--- a/drivers/pinctrl/Kconfig
+++ b/drivers/pinctrl/Kconfig
@@ -170,6 +170,14 @@ config PINCTRL_APPLE
 	  both the GPIO definitions and pin control functions for each
 	  available multiplex function.
 
+config PINCTRL_ADI
+	bool "ADI pinctrl driver"
+	depends on DM && ARCH_SC5XX
+	help
+	  This driver enables pinctrl support on SC5xx processors. This
+	  driver covers only the pin configuration functionality, and
+	  GPIO functionality is contained in the separate GPIO driver.
+
 config PINCTRL_AR933X
 	bool "QCA/Athores ar933x pin control driver"
 	depends on DM && SOC_AR933X
diff --git a/drivers/pinctrl/Makefile b/drivers/pinctrl/Makefile
index 634047a91f4c78ad7bd301870d9bba803e0bc659..e3a82b12c7838a7ec6d26411ef013cb9aa42452f 100644
--- a/drivers/pinctrl/Makefile
+++ b/drivers/pinctrl/Makefile
@@ -3,6 +3,7 @@
 obj-y					+= pinctrl-uclass.o
 obj-$(CONFIG_$(XPL_)PINCTRL_GENERIC)	+= pinctrl-generic.o
 
+obj-$(CONFIG_PINCTRL_ADI)		+= pinctrl-adi-adsp.o
 obj-$(CONFIG_PINCTRL_APPLE)		+= pinctrl-apple.o
 obj-$(CONFIG_PINCTRL_AT91)		+= pinctrl-at91.o
 obj-$(CONFIG_PINCTRL_AT91PIO4)		+= pinctrl-at91-pio4.o
diff --git a/drivers/pinctrl/pinctrl-adi-adsp.c b/drivers/pinctrl/pinctrl-adi-adsp.c
new file mode 100644
index 0000000000000000000000000000000000000000..717ac8e0056bcab6609878b2290508fdfb9f6d07
--- /dev/null
+++ b/drivers/pinctrl/pinctrl-adi-adsp.c
@@ -0,0 +1,156 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2022 - Analog Devices, Inc.
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Author: Greg Malysa <greg.malysa@timesys.com>
+ * Additional Contact: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ *
+ * dm pinctrl implementation for ADI ADSP SoCs
+ *
+ */
+
+#include <dm.h>
+#include <dm/pinctrl.h>
+#include <dm/device_compat.h>
+#include <linux/bitops.h>
+#include <linux/io.h>
+
+#define ADSP_PORT_MMIO_SIZE		0x80
+#define ADSP_PORT_PIN_SIZE		16
+
+#define ADSP_PORT_PORT_MUX_BITS		2
+#define ADSP_PORT_PORT_MUX_MASK		0x03
+#define ADSP_PINCTRL_FUNCTION_COUNT 4
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
+struct adsp_pinctrl_priv {
+	void __iomem *base;
+	int npins;
+	char pinbuf[16];
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
+static int adsp_pinctrl_pinmux_set(struct udevice *udev, unsigned int pin, unsigned int func)
+{
+	struct adsp_pinctrl_priv *priv = dev_get_priv(udev);
+	void __iomem *portbase;
+	u32 port, offset;
+	u32 val;
+
+	if (pin >= priv->npins)
+		return -ENODEV;
+
+	if (func >= ADSP_PINCTRL_FUNCTION_COUNT)
+		return -EINVAL;
+
+	port = get_port(pin);
+	offset = get_offset(pin);
+	portbase = priv->base + port * ADSP_PORT_MMIO_SIZE;
+
+	val = ioread32(portbase + ADSP_PORT_REG_PORT_MUX);
+	val &= ~(ADSP_PORT_PORT_MUX_MASK << (ADSP_PORT_PORT_MUX_BITS * offset));
+	val |= func << (ADSP_PORT_PORT_MUX_BITS * offset);
+	iowrite32(val, portbase + ADSP_PORT_REG_PORT_MUX);
+
+	iowrite32(BIT(offset), portbase + ADSP_PORT_REG_FER_SET);
+	return 0;
+}
+
+static int adsp_pinctrl_set_state(struct udevice *udev, struct udevice *config)
+{
+	const struct fdt_property *pinlist;
+	int length = 0;
+	int ret, i;
+	u32 pin, function;
+
+	pinlist = dev_read_prop(config, "adi,pins", &length);
+	if (!pinlist) {
+		dev_err(udev, "missing adi,pins property in pinctrl config node\n");
+		return -EINVAL;
+	}
+
+	if (length % (sizeof(uint32_t) * 2)) {
+		dev_err(udev, "adi,pins property must be a multiple of two uint32_ts\n");
+		return -EINVAL;
+	}
+
+	for (i = 0; i < length / sizeof(uint32_t); i += 2) {
+		ret = dev_read_u32_index(config, "adi,pins", i, &pin);
+		if (ret)
+			return ret;
+
+		ret = dev_read_u32_index(config, "adi,pins", i + 1, &function);
+		if (ret)
+			return ret;
+
+		ret = adsp_pinctrl_pinmux_set(udev, pin, function);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+const struct pinctrl_ops adsp_pinctrl_ops = {
+	.set_state = adsp_pinctrl_set_state,
+};
+
+static int adsp_pinctrl_probe(struct udevice *udev)
+{
+	struct adsp_pinctrl_priv *priv = dev_get_priv(udev);
+
+	priv->base = dev_read_addr_ptr(udev);
+	priv->npins = dev_read_u32_default(udev, "adi,npins", 0);
+
+	if (!priv->npins) {
+		dev_err(udev, "Missing adi,npins property!\n");
+		return -ENOENT;
+	}
+
+	return 0;
+}
+
+static const struct udevice_id adsp_pinctrl_match[] = {
+	{ .compatible = "adi,adsp-pinctrl" },
+	{ },
+};
+
+U_BOOT_DRIVER(adi_adsp_pinctrl) = {
+	.name = "adi_adsp_pinctrl",
+	.id = UCLASS_PINCTRL,
+	.of_match = adsp_pinctrl_match,
+	.probe = adsp_pinctrl_probe,
+	.priv_auto = sizeof(struct adsp_pinctrl_priv),
+	.ops = &adsp_pinctrl_ops,
+	.flags = DM_FLAG_PRE_RELOC,
+};
diff --git a/include/dt-bindings/pinctrl/adi-adsp.h b/include/dt-bindings/pinctrl/adi-adsp.h
new file mode 100644
index 0000000000000000000000000000000000000000..7dc8a1ef5c4a34faa76d11cc5bf909531b28fed9
--- /dev/null
+++ b/include/dt-bindings/pinctrl/adi-adsp.h
@@ -0,0 +1,21 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * (C) Copyright 2022 - Analog Devices, Inc.
+ *
+ * Written and/or maintained by Timesys Corporation
+ *
+ * Contact: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
+ * Contact: Greg Malysa <greg.malysa@timesys.com>
+ *
+ */
+
+#ifndef DT_BINDINGS_PINCTRL_ADI_ADSP
+#define DT_BINDINGS_PINCTRL_ADI_ADSP
+
+#define ADI_ADSP_PIN(port, pin) (16 * ((port) - 'A') + (pin))
+#define ADI_ADSP_PINFUNC_ALT0 0
+#define ADI_ADSP_PINFUNC_ALT1 1
+#define ADI_ADSP_PINFUNC_ALT2 2
+#define ADI_ADSP_PINFUNC_ALT3 3
+
+#endif

-- 
2.34.1

