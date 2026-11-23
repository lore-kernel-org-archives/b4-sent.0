From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 23:40:39 +0300
Subject: [PATCH net-next v2 2/3] net: mdio: Add Cortina CS7542 bus
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-mdio-v2-2-30465e831853@gmail.com>
References: <20261123-b4-cs7542-mdio-v2-0-30465e831853@gmail.com>
In-Reply-To: <20261123-b4-cs7542-mdio-v2-0-30465e831853@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795466438; l=5716;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=6ATNS7+tPBb6QEFt9TmWpqx8nPrTieIKTFRQzst34uI=;
 b=1+EBGKcUxgP7bdBk3dYPrWj/9fjDbaGmTNJXYiVx8EuWrjO2KNZVM0Z49+iPHc0AWlG7UHtR3
 3YQ7alPTz3FBDfAJR/tDoirNHzT9SxgzLreyg6wQb0USWywQJJUOYnu
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support Clause 22 reads and writes through the CS7542 management
interface. Retain the firmware-configured prescaler and unrelated
configuration bits while enabling manual operation.

Poll each transaction with microsecond delays and a bounded timeout.
Report timeout errors directly without tracking a pending transaction.
Use managed bus allocation and registration to cover probe failures
and removal.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/net/mdio/Kconfig       |  12 +++++
 drivers/net/mdio/Makefile      |   1 +
 drivers/net/mdio/mdio-cs75xx.c | 119 +++++++++++++++++++++++++++++++++++++++++
 3 files changed, 132 insertions(+)

diff --git a/drivers/net/mdio/Kconfig b/drivers/net/mdio/Kconfig
index d44278f26..6714c68ca 100644
--- a/drivers/net/mdio/Kconfig
+++ b/drivers/net/mdio/Kconfig
@@ -87,6 +87,18 @@ config MDIO_BCM_UNIMAC
 config MDIO_CAVIUM
 	tristate
 
+config MDIO_CS75XX
+	tristate "Cortina Systems CS7542 MDIO controller"
+	depends on OF_MDIO && HAS_IOMEM
+	help
+	  Support Clause 22 PHY register access through the CS7542 MDIO
+	  controller, retaining the prescaler configured by platform firmware.
+	  Transactions use bounded polling.
+	  Device Tree describes the PHYs sharing this management bus.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called mdio-cs75xx.
+
 config MDIO_GPIO
 	tristate "GPIO lib-based bitbanged MDIO buses"
 	depends on MDIO_BITBANG
diff --git a/drivers/net/mdio/Makefile b/drivers/net/mdio/Makefile
index 048586746..f0880c9f1 100644
--- a/drivers/net/mdio/Makefile
+++ b/drivers/net/mdio/Makefile
@@ -11,6 +11,7 @@ obj-$(CONFIG_MDIO_BCM_IPROC)		+= mdio-bcm-iproc.o
 obj-$(CONFIG_MDIO_BCM_UNIMAC)		+= mdio-bcm-unimac.o
 obj-$(CONFIG_MDIO_BITBANG)		+= mdio-bitbang.o
 obj-$(CONFIG_MDIO_CAVIUM)		+= mdio-cavium.o
+obj-$(CONFIG_MDIO_CS75XX)		+= mdio-cs75xx.o
 obj-$(CONFIG_MDIO_GPIO)			+= mdio-gpio.o
 obj-$(CONFIG_MDIO_HISI_FEMAC)		+= mdio-hisi-femac.o
 obj-$(CONFIG_MDIO_I2C)			+= mdio-i2c.o
diff --git a/drivers/net/mdio/mdio-cs75xx.c b/drivers/net/mdio/mdio-cs75xx.c
new file mode 100644
index 000000000..33e1a48bf
--- /dev/null
+++ b/drivers/net/mdio/mdio-cs75xx.c
@@ -0,0 +1,119 @@
+// SPDX-License-Identifier: GPL-2.0
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/io.h>
+#include <linux/iopoll.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/of_mdio.h>
+#include <linux/phy.h>
+#include <linux/platform_device.h>
+
+#define PER_MDIO_CFG			0x00
+#define   MDIO_CFG_MANUAL		BIT(0)
+#define PER_MDIO_ADDR			0x04
+#define   MDIO_ADDR_PHY			GENMASK(4, 0)
+#define   MDIO_ADDR_REG			GENMASK(12, 8)
+#define   MDIO_ADDR_READ		BIT(15)
+#define PER_MDIO_WRDATA			0x08
+#define PER_MDIO_RDDATA			0x0c
+#define PER_MDIO_CTRL			0x10
+#define   MDIO_CTRL_DONE		BIT(0)
+#define   MDIO_CTRL_START		BIT(7)
+
+#define CS75XX_MDIO_TIMEOUT_US		10000
+
+struct cs75xx_mdio {
+	void __iomem *base;
+	struct mii_bus *bus;
+};
+
+static int cs75xx_mdio_wait(struct cs75xx_mdio *priv)
+{
+	u32 val;
+	int ret;
+
+	ret = readl_poll_timeout_atomic(priv->base + PER_MDIO_CTRL, val,
+					val & MDIO_CTRL_DONE, 1,
+				       CS75XX_MDIO_TIMEOUT_US);
+	if (!ret)
+		writel(MDIO_CTRL_DONE, priv->base + PER_MDIO_CTRL);
+	return ret;
+}
+
+static int cs75xx_mdio_read(struct mii_bus *bus, int phy, int reg)
+{
+	struct cs75xx_mdio *priv = bus->priv;
+	int ret;
+
+	writel(MDIO_CTRL_DONE, priv->base + PER_MDIO_CTRL);
+	writel(MDIO_ADDR_READ | FIELD_PREP(MDIO_ADDR_REG, reg) |
+	       FIELD_PREP(MDIO_ADDR_PHY, phy), priv->base + PER_MDIO_ADDR);
+	writel(MDIO_CTRL_START, priv->base + PER_MDIO_CTRL);
+	ret = cs75xx_mdio_wait(priv);
+	if (ret)
+		return ret;
+	return readl(priv->base + PER_MDIO_RDDATA) & 0xffff;
+}
+
+static int cs75xx_mdio_write(struct mii_bus *bus, int phy, int reg, u16 val)
+{
+	struct cs75xx_mdio *priv = bus->priv;
+
+	writel(MDIO_CTRL_DONE, priv->base + PER_MDIO_CTRL);
+	writel(FIELD_PREP(MDIO_ADDR_REG, reg) | FIELD_PREP(MDIO_ADDR_PHY, phy),
+	       priv->base + PER_MDIO_ADDR);
+	writel(val, priv->base + PER_MDIO_WRDATA);
+	writel(MDIO_CTRL_START, priv->base + PER_MDIO_CTRL);
+	return cs75xx_mdio_wait(priv);
+}
+
+static int cs75xx_mdio_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct cs75xx_mdio *priv;
+	struct mii_bus *bus;
+	u32 cfg;
+
+	bus = devm_mdiobus_alloc_size(dev, sizeof(*priv));
+	if (!bus)
+		return -ENOMEM;
+
+	priv = bus->priv;
+	priv->bus = bus;
+	priv->base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(priv->base))
+		return PTR_ERR(priv->base);
+
+	cfg = readl(priv->base + PER_MDIO_CFG);
+	/* The firmware configures the MDC rate; retain its prescaler. */
+	cfg |= MDIO_CFG_MANUAL;
+	writel(cfg, priv->base + PER_MDIO_CFG);
+	writel(MDIO_CTRL_DONE, priv->base + PER_MDIO_CTRL);
+
+	bus->name = "cs75xx-mdio";
+	bus->read = cs75xx_mdio_read;
+	bus->write = cs75xx_mdio_write;
+	bus->parent = dev;
+	snprintf(bus->id, MII_BUS_ID_SIZE, "%s", dev_name(dev));
+
+	return devm_of_mdiobus_register(dev, bus, dev->of_node);
+}
+
+static const struct of_device_id cs75xx_mdio_of_match[] = {
+	{ .compatible = "cortina,cs7542-mdio" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, cs75xx_mdio_of_match);
+
+static struct platform_driver cs75xx_mdio_driver = {
+	.probe = cs75xx_mdio_probe,
+	.driver = {
+		.name = "cs75xx-mdio",
+		.of_match_table = cs75xx_mdio_of_match,
+	},
+};
+module_platform_driver(cs75xx_mdio_driver);
+
+MODULE_DESCRIPTION("Cortina CS75xx MDIO bus driver");
+MODULE_LICENSE("GPL");

-- 
2.53.0

