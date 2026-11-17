From: yy-Local-LLM <yogo.0917.sabu@gmail.com>
Date: Tue, 17 Nov 2026 22:06:52 +0900
Subject: [PATCH RFC 2/6] irqchip: add the SiRF AT550 interrupt controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-at550-rfc-v1-v1-2-5879573cb825@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920817; l=5243;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=9f0nqZv4WQhgKV1VvrZgloZ85kHakrrDVLP2DGNKTf4=;
 b=m6zb8HTiPIox5b7xSvz+83eHXlrLwsdjRIptcxLk4j6673ysoDkYCiWcdc0fUQqBy0mqGhciz
 4utdk7k6o5uDMYJ5wLW5zRTjBmMg2r77oYpeU8rxeonbhVQaT3Zj1RH
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register the root controller through IRQCHIP_DECLARE and a linear
domain. Validate the chip ID before writes, mask both banks during setup
and route sources to IRQ. Keep dispatch bounded and leave the DSP mask
registers alone. The register operations derive from the 6.12.60
YPL514si bring-up. The device owner has now booted the 7.4-rc3 candidate
through JWM on this upstream initialization path.

Signed-off-by: yy-Local-LLM <yogo.0917.sabu@gmail.com>
---
 MAINTAINERS                 |   1 +
 drivers/irqchip/Kconfig     |   5 ++
 drivers/irqchip/Makefile    |   2 +
 drivers/irqchip/irq-at550.c | 110 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 118 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 6c3702cd8..acb6fde49 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25855,6 +25855,7 @@ F:	Documentation/devicetree/bindings/input/touchscreen/sirf,at550-ts.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
 F:	Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
 F:	Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
+F:	drivers/irqchip/irq-at550.c
 
 SIS 190 ETHERNET DRIVER
 M:	Francois Romieu <romieu@fr.zoreil.com>
diff --git a/drivers/irqchip/Kconfig b/drivers/irqchip/Kconfig
index 136bab41f..abf704110 100644
--- a/drivers/irqchip/Kconfig
+++ b/drivers/irqchip/Kconfig
@@ -852,4 +852,9 @@ config IRQCHIP_XILINX_SMMU_CSR
 	  ZynqMP-class platforms where a vendor CSR block mediates SMMU
 	  interrupts.
 
+config AT550_IRQ
+	bool
+	depends on ARM
+	select IRQ_DOMAIN
+
 endmenu
diff --git a/drivers/irqchip/Makefile b/drivers/irqchip/Makefile
index 16a5fd126..0aa36c7b8 100644
--- a/drivers/irqchip/Makefile
+++ b/drivers/irqchip/Makefile
@@ -136,3 +136,5 @@ obj-$(CONFIG_MCHP_EIC)			+= irq-mchp-eic.o
 obj-$(CONFIG_SOPHGO_SG2042_MSI)		+= irq-sg2042-msi.o
 obj-$(CONFIG_SUNPLUS_SP7021_INTC)	+= irq-sp7021-intc.o
 obj-$(CONFIG_IRQCHIP_XILINX_SMMU_CSR)	+= irq-xilinx-smmu-csr.o
+
+obj-$(CONFIG_AT550_IRQ) += irq-at550.o
diff --git a/drivers/irqchip/irq-at550.c b/drivers/irqchip/irq-at550.c
new file mode 100644
index 000000000..33eb18cd1
--- /dev/null
+++ b/drivers/irqchip/irq-at550.c
@@ -0,0 +1,110 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* SiRF AT550 interrupt controller. */
+#include <linux/io.h>
+#include <linux/irq.h>
+#include <linux/irqchip.h>
+#include <linux/irqdomain.h>
+#include <linux/of_address.h>
+#include <asm/exception.h>
+
+#define AT550_IRQ_COUNT	64
+#define AT550_MASK	0x18
+#define AT550_LEVEL	0x20
+#define AT550_CHIP_ID	0x34
+#define AT550_IRQ_ID	0x38
+
+static void __iomem *at550_intc;
+static struct irq_domain *at550_domain;
+
+static void at550_irq_mask(struct irq_data *data)
+{
+	void __iomem *reg = at550_intc + AT550_MASK + (data->hwirq / 32) * 4;
+
+	writel(readl(reg) & ~BIT(data->hwirq % 32), reg);
+}
+
+static void at550_irq_unmask(struct irq_data *data)
+{
+	void __iomem *reg = at550_intc + AT550_MASK + (data->hwirq / 32) * 4;
+
+	writel(readl(reg) | BIT(data->hwirq % 32), reg);
+}
+
+static struct irq_chip at550_chip = {
+	.name = "at550-intc",
+	.irq_mask = at550_irq_mask,
+	.irq_unmask = at550_irq_unmask,
+};
+
+static int at550_irq_map(struct irq_domain *domain, unsigned int irq,
+			irq_hw_number_t hwirq)
+{
+	if (hwirq >= AT550_IRQ_COUNT)
+		return -EINVAL;
+	irq_set_chip_and_handler(irq, &at550_chip, handle_level_irq);
+	irq_set_noprobe(irq);
+	return 0;
+}
+
+static const struct irq_domain_ops at550_domain_ops = {
+	.map = at550_irq_map,
+	.xlate = irq_domain_xlate_onecell,
+};
+
+static void __exception_irq_entry at550_handle_irq(struct pt_regs *regs)
+{
+	unsigned int count, hwirq;
+
+	for (count = 0; count < AT550_IRQ_COUNT; count++) {
+		hwirq = readl(at550_intc + AT550_IRQ_ID) & 0xff;
+		if (hwirq == 0xff)
+			return;
+		if (hwirq >= AT550_IRQ_COUNT) {
+			pr_err_ratelimited("at550-intc: invalid source %u\n", hwirq);
+			return;
+		}
+		if (generic_handle_domain_irq(at550_domain, hwirq))
+			return;
+	}
+}
+
+static int __init at550_irq_init(struct device_node *node,
+				struct device_node *parent)
+{
+	int ret;
+
+	if (parent || at550_intc)
+		return -EINVAL;
+	at550_intc = of_iomap(node, 0);
+	if (!at550_intc)
+		return -ENOMEM;
+	if ((readl(at550_intc + AT550_CHIP_ID) & 0xffff) != 0x1230) {
+		ret = -ENODEV;
+		goto unmap;
+	}
+	/* A set mask bit enables a source; clear level bits route it to IRQ. */
+	writel(0, at550_intc + AT550_MASK);
+	writel(0, at550_intc + AT550_MASK + 4);
+	writel(0, at550_intc + AT550_LEVEL);
+	writel(0, at550_intc + AT550_LEVEL + 4);
+	at550_domain = irq_domain_create_linear(of_fwnode_handle(node), AT550_IRQ_COUNT,
+					   &at550_domain_ops, NULL);
+	if (!at550_domain) {
+		ret = -ENOMEM;
+		goto unmap;
+	}
+	ret = set_handle_irq(at550_handle_irq);
+	if (ret)
+		goto remove_domain;
+	irq_set_default_domain(at550_domain);
+	return 0;
+
+remove_domain:
+	irq_domain_remove(at550_domain);
+	at550_domain = NULL;
+unmap:
+	iounmap(at550_intc);
+	at550_intc = NULL;
+	return ret;
+}
+IRQCHIP_DECLARE(at550, "sirf,at550-intc", at550_irq_init);

-- 
2.56.0

