From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Fri, 20 Nov 2026 20:24:15 +0300
Subject: [PATCH v5 2/2] irqchip: Add Cortina Systems CS75xx peripheral
 interrupt controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-cs75xx-intc-v5-2-f2be75c5e97c@gmail.com>
References: <20261120-cs75xx-intc-v5-0-f2be75c5e97c@gmail.com>
In-Reply-To: <20261120-cs75xx-intc-v5-0-f2be75c5e97c@gmail.com>
To: Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795195470; l=5353;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=nlJ1ISew1ezebn+ulwSM+gYqPI61U7Zt8jVwTgz66XQ=;
 b=tcMMCzoGaymUUNfrebj6mGjQ3JnvK9hH/SSj93AzrUDRy8s+8/FXvEvdKgaj6R7YTik409P9f
 ZOr7nlD6gjfCXeBfDHCWH19jSr0A73NxpRNFaaDC6cTXRWCHpivyrcT
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The timers, GPIO banks, I2C, MDIO, SPI and a few other low speed
peripherals of the Cortina Systems CS75xx SoCs share a single GIC
interrupt. A status register shows the level of the 15 sources and an
enable register masks them; there is nothing to acknowledge, each source
is cleared in its peripheral.

Add a chained driver using a generic chip on a linear domain.
The driver depends on OF and HAS_IOMEM and can be enabled independently
of the CS75xx platform support.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/irqchip/Kconfig      |  12 +++++
 drivers/irqchip/Makefile     |   1 +
 drivers/irqchip/irq-cs75xx.c | 107 +++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 120 insertions(+)

diff --git a/drivers/irqchip/Kconfig b/drivers/irqchip/Kconfig
index 136bab41f..12bf87e8e 100644
--- a/drivers/irqchip/Kconfig
+++ b/drivers/irqchip/Kconfig
@@ -187,6 +187,18 @@ config BRCMSTB_L2_IRQ
 	select GENERIC_IRQ_CHIP
 	select IRQ_DOMAIN
 
+config CS75XX_INTC
+	bool "Cortina Systems CS75xx peripheral interrupt controller"
+	depends on OF
+	depends on HAS_IOMEM
+	select GENERIC_IRQ_CHIP
+	select IRQ_DOMAIN
+	help
+	  Support for the interrupt controller of the Cortina Systems
+	  CS75xx SoCs that combines the interrupts of the low speed
+	  peripherals (timers, GPIO banks, I2C, MDIO, SPI) into a single
+	  GIC interrupt. Say Y if you have a board with such an SoC.
+
 config DAVINCI_CP_INTC
 	bool
 	select GENERIC_IRQ_CHIP
diff --git a/drivers/irqchip/Makefile b/drivers/irqchip/Makefile
index 16a5fd126..7ed8f8b33 100644
--- a/drivers/irqchip/Makefile
+++ b/drivers/irqchip/Makefile
@@ -136,3 +136,4 @@ obj-$(CONFIG_MCHP_EIC)			+= irq-mchp-eic.o
 obj-$(CONFIG_SOPHGO_SG2042_MSI)		+= irq-sg2042-msi.o
 obj-$(CONFIG_SUNPLUS_SP7021_INTC)	+= irq-sp7021-intc.o
 obj-$(CONFIG_IRQCHIP_XILINX_SMMU_CSR)	+= irq-xilinx-smmu-csr.o
+obj-$(CONFIG_CS75XX_INTC)		+= irq-cs75xx.o
diff --git a/drivers/irqchip/irq-cs75xx.c b/drivers/irqchip/irq-cs75xx.c
new file mode 100644
index 000000000..18f10eb7e
--- /dev/null
+++ b/drivers/irqchip/irq-cs75xx.c
@@ -0,0 +1,107 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Cortina Systems CS75xx peripheral interrupt controller
+ *
+ * The low speed peripherals on the register bus (timers, GPIO banks, I2C,
+ * MDIO, SPI, ...) share a single GIC interrupt. A status register shows
+ * the level of the 15 sources and an enable register masks them; there is
+ * nothing to acknowledge, the sources are cleared in the peripherals.
+ */
+
+#include <linux/bitops.h>
+#include <linux/io.h>
+#include <linux/ioport.h>
+#include <linux/irq.h>
+#include <linux/irqchip.h>
+#include <linux/irqchip/chained_irq.h>
+#include <linux/irqdomain.h>
+#include <linux/of.h>
+#include <linux/of_address.h>
+#include <linux/of_irq.h>
+
+#define CS75XX_INTC_STATUS	0x00
+#define CS75XX_INTC_ENABLE	0x04
+
+#define CS75XX_INTC_NR_IRQS	15
+
+static void cs75xx_intc_handler(struct irq_desc *desc)
+{
+	struct irq_domain *domain = irq_desc_get_handler_data(desc);
+	struct irq_chip *chip = irq_desc_get_chip(desc);
+	struct irq_chip_generic *gc;
+	unsigned long pending;
+	unsigned int hwirq;
+
+	gc = irq_get_domain_generic_chip(domain, 0);
+	chained_irq_enter(chip, desc);
+
+	pending = readl(gc->reg_base + CS75XX_INTC_STATUS) & gc->mask_cache;
+	for_each_set_bit(hwirq, &pending, CS75XX_INTC_NR_IRQS)
+		generic_handle_domain_irq(domain, hwirq);
+
+	chained_irq_exit(chip, desc);
+}
+
+static int __init cs75xx_intc_init(struct device_node *np, struct device_node *parent)
+{
+	struct irq_chip_generic *gc;
+	struct irq_domain *domain;
+	struct resource res;
+	void __iomem *base;
+	int parent_irq;
+	int ret;
+
+	ret = of_address_to_resource(np, 0, &res);
+	if (ret)
+		return ret;
+
+	base = of_io_request_and_map(np, 0, of_node_full_name(np));
+	if (IS_ERR(base)) {
+		pr_err("%pOF: unable to map registers\n", np);
+		return PTR_ERR(base);
+	}
+
+	/* Mask everything before the chained handler is installed */
+	writel(0, base + CS75XX_INTC_ENABLE);
+
+	parent_irq = irq_of_parse_and_map(np, 0);
+	if (!parent_irq) {
+		pr_err("%pOF: unable to map parent interrupt\n", np);
+		ret = -EINVAL;
+		goto err_unmap;
+	}
+
+	domain = irq_domain_create_linear(of_fwnode_handle(np), CS75XX_INTC_NR_IRQS,
+					  &irq_generic_chip_ops, NULL);
+	if (!domain) {
+		ret = -ENOMEM;
+		goto err_dispose;
+	}
+
+	ret = irq_alloc_domain_generic_chips(domain, CS75XX_INTC_NR_IRQS, 1, "cs75xx-intc",
+					     handle_level_irq, IRQ_NOREQUEST,
+					     IRQ_LEVEL | IRQ_NOPROBE, IRQ_GC_INIT_MASK_CACHE);
+	if (ret)
+		goto err_domain;
+
+	gc = irq_get_domain_generic_chip(domain, 0);
+	gc->reg_base = base;
+	gc->chip_types[0].regs.mask = CS75XX_INTC_ENABLE;
+	gc->chip_types[0].chip.irq_mask = irq_gc_mask_clr_bit;
+	gc->chip_types[0].chip.irq_unmask = irq_gc_mask_set_bit;
+
+	irq_set_chained_handler_and_data(parent_irq, cs75xx_intc_handler, domain);
+
+	return 0;
+
+err_domain:
+	irq_domain_remove(domain);
+err_dispose:
+	irq_dispose_mapping(parent_irq);
+err_unmap:
+	iounmap(base);
+	release_mem_region(res.start, resource_size(&res));
+	return ret;
+}
+
+IRQCHIP_DECLARE(cs7542_intc, "cortina,cs7542-intc", cs75xx_intc_init);

-- 
2.53.0

