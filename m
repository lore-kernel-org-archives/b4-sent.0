From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 25 Nov 2026 15:24:53 -0500
Subject: [PATCH v6 6/6] reset: Add Siflower SF19A2890 peripheral reset
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-sf19a2890-sysm-v6-6-181875c10682@telaak.dev>
References: <20261125-sf19a2890-sysm-v6-0-181875c10682@telaak.dev>
In-Reply-To: <20261125-sf19a2890-sysm-v6-0-181875c10682@telaak.dev>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: Paul Burton <paulburton@kernel.org>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>, Chuanhong Guo <gch981213@gmail.com>, 
 Yao Zi <me@ziyao.cc>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-mips@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795638294; l=9822;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=erSumJvPtRKGfELrVfiKPo+Ic3ADjyGrMETiodgT1qU=;
 b=qUlvUzdyDHOLQWJ+uGjBvWpd4CpunDZhcJtgA9+34BTJV84uypyIphRqWYF3plQ0+cXkMUUdn
 iCT1S8iR+XmCtXRbWPcbNhUWtNDwN5D5c/Nm1hxIbjzUrAqsPctkUgF
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the resets of the Siflower SF19A2890 peripheral clock
and reset managers. It binds to the auxiliary device that their clock
driver creates and uses the registers that driver has mapped. Where an
IP has a reset line for each of its clock domains, as the PL011 UARTs
and the PL022 SPI controller do, one reset drives all of them, since
they have to be asserted together.

Based on the reset part of the driver in Chuanhong Guo's SF19A2890
branch.

Link: https://github.com/981213/linux/commit/37c81bebaf54
Co-developed-by: Chuanhong Guo <gch981213@gmail.com>
Signed-off-by: Chuanhong Guo <gch981213@gmail.com>
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 MAINTAINERS                               |   1 +
 drivers/reset/Kconfig                     |  12 ++
 drivers/reset/Makefile                    |   1 +
 drivers/reset/reset-sf19a2890-periphcrm.c | 195 ++++++++++++++++++++++++++++++
 4 files changed, 209 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 34ff7ec0b60e..ae47322d15dd 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25706,6 +25706,7 @@ F:	Documentation/devicetree/bindings/clock/siflower,sf19a2890-clk.yaml
 F:	Documentation/devicetree/bindings/clock/siflower,sf19a2890-periph-crm.yaml
 F:	drivers/clk/siflower/clk-sf19a2890-periphcrm.c
 F:	drivers/clk/siflower/clk-sf19a2890.c
+F:	drivers/reset/reset-sf19a2890-periphcrm.c
 F:	include/dt-bindings/clock/siflower,sf19a2890-clk.h
 F:	include/dt-bindings/clock/siflower,sf19a2890-periph-crm.h
 
diff --git a/drivers/reset/Kconfig b/drivers/reset/Kconfig
index eda9c698a95f..fe7beb2530b2 100644
--- a/drivers/reset/Kconfig
+++ b/drivers/reset/Kconfig
@@ -295,6 +295,18 @@ config RESET_SCMI
 	  This driver uses SCMI Message Protocol to interact with the
 	  firmware controlling all the reset signals.
 
+config RESET_SF19A2890_PERIPHCRM
+	tristate "Siflower SF19A2890 peripheral reset controller"
+	depends on MACH_SIFLOWER_MIPS || COMPILE_TEST
+	depends on OF
+	select AUXILIARY_BUS
+	default CLK_SF19A2890_PERIPHCRM
+	help
+	  Supports the resets of the peripheral clock and reset managers of
+	  the Siflower SF19A2890, one manager for each peripheral block.
+	  The driver binds to the auxiliary device that their clock driver
+	  creates, so it needs CLK_SF19A2890_PERIPHCRM to do anything.
+
 config RESET_SIMPLE
 	bool "Simple Reset Controller Driver" if COMPILE_TEST || EXPERT
 	default ARCH_ASPEED || ARCH_BCMBCA || ARCH_BITMAIN || ARCH_REALTEK || ARCH_SOPHGO || ARCH_STM32 || (ARCH_INTEL_SOCFPGA && ARM64) || ARCH_SUNXI || ARC
diff --git a/drivers/reset/Makefile b/drivers/reset/Makefile
index 489fafd6bbe3..d4b707505c3d 100644
--- a/drivers/reset/Makefile
+++ b/drivers/reset/Makefile
@@ -39,6 +39,7 @@ obj-$(CONFIG_RESET_RASPBERRYPI) += reset-raspberrypi.o
 obj-$(CONFIG_RESET_RZG2L_USBPHY_CTRL) += reset-rzg2l-usbphy-ctrl.o
 obj-$(CONFIG_RESET_RZV2H_USB2PHY) += reset-rzv2h-usb2phy.o
 obj-$(CONFIG_RESET_SCMI) += reset-scmi.o
+obj-$(CONFIG_RESET_SF19A2890_PERIPHCRM) += reset-sf19a2890-periphcrm.o
 obj-$(CONFIG_RESET_SIMPLE) += reset-simple.o
 obj-$(CONFIG_RESET_SKY1) += reset-sky1.o
 obj-$(CONFIG_RESET_SKY1_AUDSS) += reset-sky1-audss.o
diff --git a/drivers/reset/reset-sf19a2890-periphcrm.c b/drivers/reset/reset-sf19a2890-periphcrm.c
new file mode 100644
index 000000000000..17f24f773fac
--- /dev/null
+++ b/drivers/reset/reset-sf19a2890-periphcrm.c
@@ -0,0 +1,195 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Siflower SF19A2890 peripheral reset driver
+ *
+ * The peripheral clock and reset managers keep their resets in the first
+ * register of the block. Their clock driver creates an auxiliary device for
+ * them and passes the mapped registers in its platform data.
+ */
+
+#include <linux/auxiliary_bus.h>
+#include <linux/bits.h>
+#include <linux/device.h>
+#include <linux/io.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/reset-controller.h>
+#include <linux/spinlock.h>
+
+#include <dt-bindings/clock/siflower,sf19a2890-periph-crm.h>
+
+#define REG_RESET	0x0
+
+struct sf19a2890_periphrst_data {
+	/*
+	 * A reset mask that covers several bits drives the reset lines of all
+	 * the clock domains of one IP, which have to be asserted together.
+	 */
+	const u32 *masks;
+	unsigned int num_resets;
+};
+
+struct sf19a2890_periphrst {
+	struct reset_controller_dev rcdev;
+	void __iomem *base;
+	spinlock_t lock;	/* serializes reset register updates */
+	const u32 *masks;
+};
+
+static inline struct sf19a2890_periphrst *
+rcdev_to_periphrst(struct reset_controller_dev *rcdev)
+{
+	return container_of(rcdev, struct sf19a2890_periphrst, rcdev);
+}
+
+static int sf19a2890_periphrst_update(struct reset_controller_dev *rcdev,
+				      unsigned long id, bool assert)
+{
+	struct sf19a2890_periphrst *rst = rcdev_to_periphrst(rcdev);
+	u32 reg;
+
+	guard(spinlock_irqsave)(&rst->lock);
+	reg = readl(rst->base + REG_RESET);
+	if (assert)
+		reg |= rst->masks[id];
+	else
+		reg &= ~rst->masks[id];
+	writel(reg, rst->base + REG_RESET);
+
+	return 0;
+}
+
+static int sf19a2890_periphrst_assert(struct reset_controller_dev *rcdev,
+				      unsigned long id)
+{
+	return sf19a2890_periphrst_update(rcdev, id, true);
+}
+
+static int sf19a2890_periphrst_deassert(struct reset_controller_dev *rcdev,
+					unsigned long id)
+{
+	return sf19a2890_periphrst_update(rcdev, id, false);
+}
+
+static int sf19a2890_periphrst_status(struct reset_controller_dev *rcdev,
+				      unsigned long id)
+{
+	struct sf19a2890_periphrst *rst = rcdev_to_periphrst(rcdev);
+
+	return !!(readl(rst->base + REG_RESET) & rst->masks[id]);
+}
+
+static const struct reset_control_ops sf19a2890_periphrst_ops = {
+	.assert = sf19a2890_periphrst_assert,
+	.deassert = sf19a2890_periphrst_deassert,
+	.status = sf19a2890_periphrst_status,
+};
+
+#define RST_DATA(_name)							\
+	static const struct sf19a2890_periphrst_data sf19a2890_##_name##_rst = { \
+		.masks = sf19a2890_##_name##_masks,			\
+		.num_resets = ARRAY_SIZE(sf19a2890_##_name##_masks),	\
+	}
+
+static const u32 sf19a2890_single_masks[] = { BIT(0) };
+
+RST_DATA(single);
+
+/* The two sides of an asynchronous AXI bridge */
+static const u32 sf19a2890_gmac_masks[] = { [RST_GMAC] = GENMASK(1, 0) };
+
+RST_DATA(gmac);
+
+/* The AXI slave, AXI master and platform domains */
+static const u32 sf19a2890_wlan_masks[] = { GENMASK(2, 0) };
+
+RST_DATA(wlan);
+
+/* The DWC2 controller's clock domains, then the PHY's */
+static const u32 sf19a2890_usb_masks[] = {
+	[RST_USB] = GENMASK(2, 0),
+	[RST_USB_PHY_POR] = BIT(3),
+	[RST_USB_PHY] = BIT(4),
+};
+
+RST_DATA(usb);
+
+/* The PL022's PRESETn and nSSPRST */
+static const u32 sf19a2890_spi_masks[] = { [RST_SPI] = GENMASK(5, 4) };
+
+RST_DATA(spi);
+
+/* Each PL011's PRESETn and nUARTRST */
+static const u32 sf19a2890_uart_masks[] = {
+	[RST_UART0] = BIT(0) | BIT(4),
+	[RST_UART1] = BIT(1) | BIT(5),
+	[RST_UART2] = BIT(2) | BIT(6),
+};
+
+RST_DATA(uart);
+
+static const struct of_device_id sf19a2890_periphrst_ids[] = {
+	{ .compatible = "siflower,sf19a2890-gmac-crm", .data = &sf19a2890_gmac_rst },
+	{ .compatible = "siflower,sf19a2890-gpio-crm", .data = &sf19a2890_single_rst },
+	{ .compatible = "siflower,sf19a2890-i2c-crm", .data = &sf19a2890_single_rst },
+	{ .compatible = "siflower,sf19a2890-pwm-crm", .data = &sf19a2890_single_rst },
+	{ .compatible = "siflower,sf19a2890-rf-crm", .data = &sf19a2890_wlan_rst },
+	{ .compatible = "siflower,sf19a2890-spi-crm", .data = &sf19a2890_spi_rst },
+	{ .compatible = "siflower,sf19a2890-timer-crm", .data = &sf19a2890_single_rst },
+	{ .compatible = "siflower,sf19a2890-uart-crm", .data = &sf19a2890_uart_rst },
+	{ .compatible = "siflower,sf19a2890-usb-crm", .data = &sf19a2890_usb_rst },
+	{ .compatible = "siflower,sf19a2890-wdt-crm", .data = &sf19a2890_single_rst },
+	{ .compatible = "siflower,sf19a2890-wlan24-crm", .data = &sf19a2890_wlan_rst },
+	{ .compatible = "siflower,sf19a2890-wlan5-crm", .data = &sf19a2890_wlan_rst },
+	{ /* sentinel */ }
+};
+
+static int sf19a2890_periphrst_probe(struct auxiliary_device *adev,
+				     const struct auxiliary_device_id *id)
+{
+	const struct sf19a2890_periphrst_data *data;
+	struct device *dev = &adev->dev;
+	const struct of_device_id *match;
+	struct sf19a2890_periphrst *rst;
+
+	/* The OF node is the parent's, so device_get_match_data() cannot be used */
+	match = of_match_node(sf19a2890_periphrst_ids, dev->of_node);
+	if (!match)
+		return -ENODEV;
+	data = match->data;
+
+	rst = devm_kzalloc_obj(dev, *rst);
+	if (!rst)
+		return -ENOMEM;
+
+	rst->base = (void __iomem __force *)dev_get_platdata(dev);
+	if (!rst->base)
+		return -EINVAL;
+
+	spin_lock_init(&rst->lock);
+	rst->masks = data->masks;
+	rst->rcdev.owner = THIS_MODULE;
+	rst->rcdev.nr_resets = data->num_resets;
+	rst->rcdev.ops = &sf19a2890_periphrst_ops;
+	rst->rcdev.of_node = dev->of_node;
+	rst->rcdev.dev = dev;
+
+	return devm_reset_controller_register(dev, &rst->rcdev);
+}
+
+static const struct auxiliary_device_id sf19a2890_periphrst_aux_ids[] = {
+	{ .name = "clk_sf19a2890_periphcrm.reset" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(auxiliary, sf19a2890_periphrst_aux_ids);
+
+static struct auxiliary_driver sf19a2890_periphrst_driver = {
+	.probe = sf19a2890_periphrst_probe,
+	.id_table = sf19a2890_periphrst_aux_ids,
+};
+module_auxiliary_driver(sf19a2890_periphrst_driver);
+
+MODULE_AUTHOR("Chuanhong Guo <gch981213@gmail.com>");
+MODULE_AUTHOR("Joseph Telaak <joseph@telaak.dev>");
+MODULE_DESCRIPTION("Siflower SF19A2890 peripheral reset driver");
+MODULE_LICENSE("GPL");

-- 
Git-155)

