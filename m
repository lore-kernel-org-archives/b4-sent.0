From: Sven Peter <sven@kernel.org>
Date: Sun, 09 Aug 2026 14:16:03 +0200
Subject: [PATCH 2/3] reset: Add Apple SoC CIO reset driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260809-b4-cio-reset-v1-2-4f33777d9b4b@kernel.org>
References: <20260809-b4-cio-reset-v1-0-4f33777d9b4b@kernel.org>
In-Reply-To: <20260809-b4-cio-reset-v1-0-4f33777d9b4b@kernel.org>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7782; i=sven@kernel.org;
 h=from:subject:message-id; bh=s0VuUVB5ruw7/XiIUSNF4+H9ehJ1hObbx+QlQJOTfhs=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1ZFfkdY/AmVNMlde1wLd34yLY7ks269ftA06uKJU2eTt
 S9sknDsKGVhEONikBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAEzkQx/DP9vufRkLil96XWfY
 2yY6zUwhMLzLQKZQc4HGiXVrOzcu0WP4w6m+v9a6y6Ff/7FiKCPH7x/3j4d+EpAJja8rPT49uTW
 OFQA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the reset of the CIO (USB4/Thunderbolt) blocks on
Apple Silicon SoCs which has to be deasserted before their
co-processor can be booted. On t8103 each port comes with a dedicated
register page while t600x uses a single register with one request bit
per port shared by all ports of a die inside the PMGR MMIO region.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 MAINTAINERS                     |   1 +
 drivers/reset/Kconfig           |  10 +++
 drivers/reset/Makefile          |   1 +
 drivers/reset/reset-apple-cio.c | 182 ++++++++++++++++++++++++++++++++++++++++
 4 files changed, 194 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 4b78528324c8..5425051c0f99 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2636,6 +2636,7 @@ F:	drivers/pinctrl/pinctrl-apple-gpio.c
 F:	drivers/power/reset/macsmc-reboot.c
 F:	drivers/power/supply/macsmc-power.c
 F:	drivers/pwm/pwm-apple.c
+F:	drivers/reset/reset-apple-cio.c
 F:	drivers/rtc/rtc-macsmc.c
 F:	drivers/soc/apple/*
 F:	drivers/spi/spi-apple.c
diff --git a/drivers/reset/Kconfig b/drivers/reset/Kconfig
index d009eb0849a3..1e83cb5c68ce 100644
--- a/drivers/reset/Kconfig
+++ b/drivers/reset/Kconfig
@@ -22,6 +22,16 @@ config RESET_A10SR
 	  This option enables support for the external reset functions for
 	  peripheral PHYs on the Altera Arria10 System Resource Chip.
 
+config RESET_APPLE_CIO
+	tristate "Apple SoC CIO block reset driver"
+	depends on ARCH_APPLE || COMPILE_TEST
+	select MFD_SYSCON
+	help
+	  This enables the reset driver for the CIO (USB4/Thunderbolt) blocks
+	  found on Apple Silicon SoCs. It is required to start the blocks
+	  before the USB4/Thunderbolt host routers inside them can be brought
+	  up by the thunderbolt driver.
+
 config RESET_ASPEED
 	tristate "ASPEED Reset Driver"
 	depends on ARCH_ASPEED || COMPILE_TEST
diff --git a/drivers/reset/Makefile b/drivers/reset/Makefile
index 3e52569bd276..6554649bc139 100644
--- a/drivers/reset/Makefile
+++ b/drivers/reset/Makefile
@@ -7,6 +7,7 @@ obj-y += starfive/
 obj-y += sti/
 obj-y += tegra/
 obj-$(CONFIG_RESET_A10SR) += reset-a10sr.o
+obj-$(CONFIG_RESET_APPLE_CIO) += reset-apple-cio.o
 obj-$(CONFIG_RESET_ASPEED) += reset-aspeed.o
 obj-$(CONFIG_RESET_ATH79) += reset-ath79.o
 obj-$(CONFIG_RESET_AXS10X) += reset-axs10x.o
diff --git a/drivers/reset/reset-apple-cio.c b/drivers/reset/reset-apple-cio.c
new file mode 100644
index 000000000000..951340455468
--- /dev/null
+++ b/drivers/reset/reset-apple-cio.c
@@ -0,0 +1,182 @@
+// SPDX-License-Identifier: GPL-2.0-only OR MIT
+/*
+ * Apple SoC CIO (USB4/Thunderbolt) block reset driver
+ *
+ * Copyright The Asahi Linux Contributors
+ *
+ * The CIO blocks have a reset inside the power manager (PMGR) that
+ * has to be deasserted before their co-processor can be booted. On
+ * t8103 each port comes with a dedicated register page while t600x
+ * uses a single register shared by all ports of a die inside the PMGR
+ * MMIO region.
+ */
+
+#include <linux/bits.h>
+#include <linux/mfd/syscon.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+#include <linux/reset-controller.h>
+
+#define APPLE_CIO_RESET_POLL_US 100
+#define APPLE_CIO_RESET_TIMEOUT_US 100000
+
+#define T8103_CIO_CTRL_STRIDE 0x4000
+#define T8103_CIO_CTRL_INIT_REQ BIT(0)
+#define T8103_CIO_CTRL_INIT_DONE BIT(2)
+
+#define T6000_CIO_CTRL_INIT_REQ(port) BIT(port)
+#define T6000_CIO_CTRL_INIT_BUSY(port) BIT(16 + (port))
+
+struct apple_cio_reset;
+
+struct apple_cio_reset_variant {
+	unsigned int nr_resets;
+	bool pmgr_child;
+	int (*deassert)(struct apple_cio_reset *priv, unsigned long id);
+};
+
+struct apple_cio_reset {
+	struct reset_controller_dev rcdev;
+	const struct apple_cio_reset_variant *variant;
+	struct regmap *regmap;
+	u32 offset;
+	struct mutex lock; /* serializes access to the shared t600x register */
+};
+
+static int t8103_cio_deassert(struct apple_cio_reset *priv, unsigned long id)
+{
+	u32 offset = priv->offset + id * T8103_CIO_CTRL_STRIDE;
+	u32 val;
+	int ret;
+
+	ret = regmap_write(priv->regmap, offset, T8103_CIO_CTRL_INIT_REQ);
+	if (ret)
+		return ret;
+
+	return regmap_read_poll_timeout(priv->regmap, offset, val,
+					val == T8103_CIO_CTRL_INIT_DONE,
+					APPLE_CIO_RESET_POLL_US,
+					APPLE_CIO_RESET_TIMEOUT_US);
+}
+
+static int t6000_cio_deassert(struct apple_cio_reset *priv, unsigned long id)
+{
+	u32 val;
+	int ret;
+
+	guard(mutex)(&priv->lock);
+
+	ret = regmap_write(priv->regmap, priv->offset, T6000_CIO_CTRL_INIT_REQ(id));
+	if (ret)
+		return ret;
+
+	return regmap_read_poll_timeout(priv->regmap, priv->offset, val,
+					!(val & T6000_CIO_CTRL_INIT_BUSY(id)),
+					APPLE_CIO_RESET_POLL_US,
+					APPLE_CIO_RESET_TIMEOUT_US);
+}
+
+static const struct apple_cio_reset_variant apple_t8103_cio_reset = {
+	.nr_resets = 2,
+	.deassert = t8103_cio_deassert,
+};
+
+static const struct apple_cio_reset_variant apple_t6000_cio_reset = {
+	.nr_resets = 4,
+	.pmgr_child = true,
+	.deassert = t6000_cio_deassert,
+};
+
+static int apple_cio_reset_deassert(struct reset_controller_dev *rcdev, unsigned long id)
+{
+	struct apple_cio_reset *priv =
+		container_of(rcdev, struct apple_cio_reset, rcdev);
+
+	return priv->variant->deassert(priv, id);
+}
+
+static const struct reset_control_ops apple_cio_reset_ops = {
+	.deassert = apple_cio_reset_deassert,
+};
+
+static const struct regmap_config apple_cio_reset_regmap_config = {
+	.reg_bits = 32,
+	.reg_stride = 4,
+	.val_bits = 32,
+};
+
+static int apple_cio_reset_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct apple_cio_reset *priv;
+	int ret;
+
+	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+
+	priv->variant = of_device_get_match_data(dev);
+
+	ret = devm_mutex_init(dev, &priv->lock);
+	if (ret)
+		return ret;
+
+	if (priv->variant->pmgr_child) {
+		priv->regmap = syscon_node_to_regmap(dev->of_node->parent);
+		if (IS_ERR(priv->regmap))
+			return dev_err_probe(dev, PTR_ERR(priv->regmap),
+					     "Failed to get parent regmap");
+
+		ret = of_property_read_u32(dev->of_node, "reg", &priv->offset);
+		if (ret)
+			return dev_err_probe(dev, ret, "Failed to read reg offset");
+	} else {
+		void __iomem *base;
+
+		base = devm_platform_ioremap_resource(pdev, 0);
+		if (IS_ERR(base))
+			return PTR_ERR(base);
+
+		priv->regmap = devm_regmap_init_mmio(dev, base,
+						     &apple_cio_reset_regmap_config);
+		if (IS_ERR(priv->regmap))
+			return dev_err_probe(dev, PTR_ERR(priv->regmap),
+					     "Failed to init MMIO regmap");
+	}
+
+	priv->rcdev.owner = THIS_MODULE;
+	priv->rcdev.ops = &apple_cio_reset_ops;
+	priv->rcdev.of_node = dev->of_node;
+	priv->rcdev.nr_resets = priv->variant->nr_resets;
+
+	return devm_reset_controller_register(dev, &priv->rcdev);
+}
+
+static const struct of_device_id apple_cio_reset_match[] = {
+	{
+		.compatible = "apple,t8103-cio-reset",
+		.data = &apple_t8103_cio_reset,
+	},
+	{
+		.compatible = "apple,t6000-cio-reset",
+		.data = &apple_t6000_cio_reset,
+	},
+	{},
+};
+MODULE_DEVICE_TABLE(of, apple_cio_reset_match);
+
+static struct platform_driver apple_cio_reset_driver = {
+	.driver = {
+		.name = "apple-cio-reset",
+		.of_match_table = apple_cio_reset_match,
+	},
+	.probe = apple_cio_reset_probe,
+};
+module_platform_driver(apple_cio_reset_driver);
+
+MODULE_AUTHOR("Sven Peter <sven@kernel.org>");
+MODULE_DESCRIPTION("Apple SoC CIO block reset driver");
+MODULE_LICENSE("Dual MIT/GPL");

-- 
2.55.0

