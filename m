From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 23:32:21 +0300
Subject: [PATCH v2 7/8] PCI: cs7542: Add CS7542 PCIe host support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-pcie-v2-7-f589a9cd0bef@gmail.com>
References: <20261123-b4-cs7542-pcie-v2-0-f589a9cd0bef@gmail.com>
In-Reply-To: <20261123-b4-cs7542-pcie-v2-0-f589a9cd0bef@gmail.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: Jingoo Han <jingoohan1@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 Krzysztof Wilczynski <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 linux-pci@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-clk@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795465935; l=19798;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=4tnkY8D2cQa5y4SVCgW9HZoSXE2lPJ9+rP8fC5MXPik=;
 b=/Ry2Kg78NNvNTVQ8iEIQxlnsoKYPdZrtT1d8YRpZ1ox0Z/sDjSywhM1cabdIi1yB0dtTwjO2F
 977/LgbHhmsAeloMgWOyfJ/9ae5lMbotz/QwvttQzYPcKCWEXFZu9FK
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DesignWare host glue consuming separate clock, reset and PHY
providers. Use live link status and stop previous training before
enumeration. Finish endpoint teardown before draining the shared IRQ and
freeing MSI domains. Dispatch enabled INTx/MSI sources through one
application interrupt and use its MSI target window.

Prevent root configuration accesses at and above 0x200, including direct
DesignWare DBI reads, while preserving the private CSR bank and separate
iATU callback base. Unwind power and IRQ domains on failure and removal.

Read live link/LTSSM state through the application wrapper. After link
loss, block configuration and DBI accesses until controller reset and
reprobe.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/pci/controller/dwc/Kconfig       |  12 +
 drivers/pci/controller/dwc/Makefile      |   2 +
 drivers/pci/controller/dwc/pcie-cs7542.c | 551 +++++++++++++++++++++++++++++++
 3 files changed, 565 insertions(+)

diff --git a/drivers/pci/controller/dwc/Kconfig b/drivers/pci/controller/dwc/Kconfig
index 0a0d56fcf..2ebaa8db1 100644
--- a/drivers/pci/controller/dwc/Kconfig
+++ b/drivers/pci/controller/dwc/Kconfig
@@ -577,4 +577,16 @@ config PCIE_ULTRARISC
 	  By default, this symbol is enabled when ARCH_ULTRARISC is active,
 	  requiring no further configuration on that platform.
 
+config PCIE_CS7542
+	tristate "Cortina Systems CS7542 PCIe controller"
+	depends on OF && HAS_IOMEM && PCI_MSI && COMMON_CLK
+	select PCIE_DW_HOST
+	select GENERIC_PHY
+	select RESET_CONTROLLER
+	help
+	  Enable the DesignWare PCIe host controllers on Cortina CS7542.
+	  The global clock/reset provider and a generic PHY are required.
+	  The application interrupt handles both legacy INTx and MSI.
+	  The module is called pcie-cs7542.
+
 endmenu
diff --git a/drivers/pci/controller/dwc/Makefile b/drivers/pci/controller/dwc/Makefile
index d4f88cfc6..4a6ae9037 100644
--- a/drivers/pci/controller/dwc/Makefile
+++ b/drivers/pci/controller/dwc/Makefile
@@ -61,3 +61,5 @@ obj-$(CONFIG_ARM64) += pcie-hisi.o
 obj-$(CONFIG_ARM64) += pcie-tegra194-acpi.o
 endif
 endif
+
+obj-$(CONFIG_PCIE_CS7542) += pcie-cs7542.o
diff --git a/drivers/pci/controller/dwc/pcie-cs7542.c b/drivers/pci/controller/dwc/pcie-cs7542.c
new file mode 100644
index 000000000..5487e667d
--- /dev/null
+++ b/drivers/pci/controller/dwc/pcie-cs7542.c
@@ -0,0 +1,551 @@
+// SPDX-License-Identifier: GPL-2.0
+#include <linux/bitfield.h>
+#include <linux/clk.h>
+#include <linux/iopoll.h>
+#include <linux/phy/phy.h>
+#include <linux/reset.h>
+#include <linux/delay.h>
+#include <linux/gpio/consumer.h>
+#include <linux/interrupt.h>
+#include <linux/irqchip/chained_irq.h>
+#include <linux/irqdomain.h>
+#include <linux/kernel.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/of_irq.h>
+#include <linux/pci.h>
+#include <linux/platform_device.h>
+#include <linux/resource.h>
+
+#include "pcie-designware.h"
+
+#define APP_INT_STATUS		0x00
+#define APP_INT_ENABLE		0x04
+#define APP_CORE_CONFIG		0x1c
+#define APP_PM_STATUS		0x20
+#define APP_LINK_ACTIVE		BIT(18)
+#define APP_LTSSM_STATE		GENMASK(9, 4)
+#define APP_CFG_START		0x80
+#define APP_CFG_END		0x84
+
+#define INT_INTX_ASSERT(x)	BIT((x) * 2)
+#define INT_INTX_ASSERT_MASK	(BIT(0) | BIT(2) | BIT(4) | BIT(6))
+#define INT_MSI			BIT(8)
+#define INT_LINK_UP		BIT(9)
+#define INT_RADM_NONFATAL_ERR	BIT(12)
+#define INT_RADM_FATAL_ERR	BIT(13)
+#define INT_GM_COMPOSER_ERR	BIT(16)
+#define INT_RADMX_COMPOSER_ERR	BIT(17)
+#define INT_ELASTIC_OVF		BIT(18)
+#define INT_ELASTIC_UNF		BIT(19)
+#define INT_LINK_DOWN		BIT(22)
+#define INT_ERR_MASK		(INT_RADM_NONFATAL_ERR | INT_RADM_FATAL_ERR | \
+				 INT_GM_COMPOSER_ERR | INT_RADMX_COMPOSER_ERR | \
+				 INT_ELASTIC_OVF | INT_ELASTIC_UNF | INT_LINK_DOWN)
+
+#define CORE_CFG_LTSSM_EN	BIT(0)
+#define CORE_CFG_AXI_UR_MASK	BIT(5)
+
+#define APP_PORT_STRIDE		0x400
+#define APP_PHYS_BASE		0xF00A0000
+#define APP_CFG_WINDOW_LEN	0x1000
+#define APP_MSI_TARGET		0xC0
+#define RC_CFG_LIMIT		0x200
+
+struct cortina_pcie {
+	struct dw_pcie		pci;
+	void __iomem		*app;
+	struct clk		*clk;
+	struct phy		*phy;
+	struct reset_control	*reset;
+	struct gpio_desc	*perst;
+	int			irq;
+	bool			msi_ready;
+	bool			link_lost;
+	struct irq_domain	*intx_domain;
+	raw_spinlock_t		lock;
+	resource_size_t		dbi_phys;
+	resource_size_t		app_phys;
+	int			port;
+};
+
+#define to_cortina_pcie(x)	container_of((x), struct cortina_pcie, pci)
+
+static int cortina_pcie_port_init(struct cortina_pcie *cp)
+{
+	u32 value;
+	int ret;
+
+	writel(cp->dbi_phys, cp->app + APP_CFG_START);
+	writel(cp->dbi_phys + APP_CFG_WINDOW_LEN - 1, cp->app + APP_CFG_END);
+	ret = readl_poll_timeout(cp->app + APP_CFG_END, value,
+				 value == cp->dbi_phys + APP_CFG_WINDOW_LEN - 1, 10, 10000);
+	if (ret)
+		return ret;
+	writel(0, cp->app + APP_INT_ENABLE);
+	writel(readl(cp->app + APP_INT_STATUS), cp->app + APP_INT_STATUS);
+	return 0;
+}
+
+/* APP remains accessible after link loss, unlike the DBI port debug bank. */
+static bool cortina_pcie_link_up(struct dw_pcie *pci)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(pci);
+
+	return !READ_ONCE(cp->link_lost) &&
+	       !!(readl(cp->app + APP_PM_STATUS) & APP_LINK_ACTIVE);
+}
+
+static enum dw_pcie_ltssm cortina_pcie_get_ltssm(struct dw_pcie *pci)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(pci);
+
+	return FIELD_GET(APP_LTSSM_STATE, readl(cp->app + APP_PM_STATUS));
+}
+
+static int cortina_pcie_start_link(struct dw_pcie *pci)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(pci);
+	u32 v;
+
+	v = readl(cp->app + APP_CORE_CONFIG);
+	v |= CORE_CFG_LTSSM_EN | CORE_CFG_AXI_UR_MASK;
+	writel(v, cp->app + APP_CORE_CONFIG);
+	return 0;
+}
+
+static void cortina_pcie_stop_link(struct dw_pcie *pci)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(pci);
+	u32 value = readl(cp->app + APP_CORE_CONFIG);
+
+	writel(value & ~CORE_CFG_LTSSM_EN, cp->app + APP_CORE_CONFIG);
+}
+
+static void cortina_pcie_irq_handler(struct irq_desc *desc)
+{
+	struct cortina_pcie *cp = irq_desc_get_handler_data(desc);
+	struct irq_chip *chip = irq_desc_get_chip(desc);
+	u32 status, clear;
+	int i;
+
+	chained_irq_enter(chip, desc);
+
+	status = readl(cp->app + APP_INT_STATUS);
+	status &= readl(cp->app + APP_INT_ENABLE);
+	clear = status & ~INT_LINK_UP;
+	if (status & INT_LINK_DOWN)
+		clear |= INT_LINK_UP;
+	writel(clear, cp->app + APP_INT_STATUS);
+
+	if (status & INT_LINK_DOWN) {
+		/* The DBI interface needs a controller reset after link loss. */
+		raw_spin_lock(&cp->lock);
+		WRITE_ONCE(cp->link_lost, true);
+		writel(0, cp->app + APP_INT_ENABLE);
+		raw_spin_unlock(&cp->lock);
+		dev_warn_ratelimited(cp->pci.dev, "link lost; controller reprobe required\n");
+		goto out;
+	}
+
+	if (status & INT_ERR_MASK)
+		dev_err_ratelimited(cp->pci.dev, "port %d: PCIe error, status %#x\n",
+				    cp->port, status);
+
+	for (i = 0; i < PCI_NUM_INTX; i++)
+		if (status & INT_INTX_ASSERT(i))
+			generic_handle_domain_irq(cp->intx_domain, i);
+	if ((status & INT_MSI) && cp->msi_ready)
+		dw_handle_msi_irq(&cp->pci.pp);
+
+out:
+	chained_irq_exit(chip, desc);
+}
+
+static void cortina_intx_mask(struct irq_data *d)
+{
+	struct cortina_pcie *cp = irq_data_get_irq_chip_data(d);
+	u32 bit = INT_INTX_ASSERT(d->hwirq);
+	unsigned long flags;
+
+	raw_spin_lock_irqsave(&cp->lock, flags);
+	writel(readl(cp->app + APP_INT_ENABLE) & ~bit, cp->app + APP_INT_ENABLE);
+	raw_spin_unlock_irqrestore(&cp->lock, flags);
+}
+
+static void cortina_intx_unmask(struct irq_data *d)
+{
+	struct cortina_pcie *cp = irq_data_get_irq_chip_data(d);
+	u32 bit = INT_INTX_ASSERT(d->hwirq);
+	unsigned long flags;
+
+	raw_spin_lock_irqsave(&cp->lock, flags);
+	if (!READ_ONCE(cp->link_lost))
+		writel(readl(cp->app + APP_INT_ENABLE) | bit, cp->app + APP_INT_ENABLE);
+	raw_spin_unlock_irqrestore(&cp->lock, flags);
+}
+
+static struct irq_chip cortina_intx_chip = {
+	.name		= "cortina-INTx",
+	.irq_mask	= cortina_intx_mask,
+	.irq_unmask	= cortina_intx_unmask,
+};
+
+static int cortina_pcie_intx_map(struct irq_domain *domain, unsigned int irq,
+				 irq_hw_number_t hwirq)
+{
+	irq_set_chip_and_handler(irq, &cortina_intx_chip, handle_simple_irq);
+	irq_set_chip_data(irq, domain->host_data);
+	return 0;
+}
+
+static const struct irq_domain_ops cortina_intx_domain_ops = {
+	.map = cortina_pcie_intx_map,
+	.xlate = pci_irqd_intx_xlate,
+};
+
+static int cortina_pcie_init_irq_domain(struct cortina_pcie *cp)
+{
+	struct device *dev = cp->pci.dev;
+	struct device_node *intc;
+
+	intc = of_get_child_by_name(dev->of_node, "interrupt-controller");
+	if (!intc)
+		return dev_err_probe(dev, -ENODEV, "no interrupt-controller child\n");
+
+	cp->intx_domain = irq_domain_create_linear(of_fwnode_handle(intc), PCI_NUM_INTX,
+						   &cortina_intx_domain_ops, cp);
+	of_node_put(intc);
+	if (!cp->intx_domain)
+		return dev_err_probe(dev, -ENOMEM, "cannot create INTx domain\n");
+	return 0;
+}
+
+static int cortina_pcie_rd_own_conf(struct pci_bus *bus, unsigned int devfn,
+				    int where, int size, u32 *val)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(to_dw_pcie_from_pp(bus->sysdata));
+
+	unsigned long flags;
+	int ret;
+
+	*val = ~0U;
+	if (where < 0 || (size != 1 && size != 2 && size != 4) ||
+	    (where & (size - 1)))
+		return PCIBIOS_BAD_REGISTER_NUMBER;
+	if (READ_ONCE(cp->link_lost))
+		return PCIBIOS_DEVICE_NOT_FOUND;
+	if (where >= RC_CFG_LIMIT || size > RC_CFG_LIMIT - where) {
+		*val = 0;
+		return PCIBIOS_SUCCESSFUL;
+	}
+	raw_spin_lock_irqsave(&cp->lock, flags);
+	ret = cp->link_lost ? PCIBIOS_DEVICE_NOT_FOUND :
+	      pci_generic_config_read(bus, devfn, where, size, val);
+	raw_spin_unlock_irqrestore(&cp->lock, flags);
+	return ret;
+}
+
+static int cortina_pcie_wr_own_conf(struct pci_bus *bus, unsigned int devfn,
+				    int where, int size, u32 val)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(to_dw_pcie_from_pp(bus->sysdata));
+
+	unsigned long flags;
+	int ret;
+
+	if (where < 0 || (size != 1 && size != 2 && size != 4) ||
+	    (where & (size - 1)))
+		return PCIBIOS_BAD_REGISTER_NUMBER;
+	if (READ_ONCE(cp->link_lost))
+		return PCIBIOS_DEVICE_NOT_FOUND;
+	if (where >= RC_CFG_LIMIT || size > RC_CFG_LIMIT - where) {
+		dev_dbg(bus->dev.parent, "ignoring RC config write at %#x\n", where);
+		return PCIBIOS_SUCCESSFUL;
+	}
+	raw_spin_lock_irqsave(&cp->lock, flags);
+	ret = cp->link_lost ? PCIBIOS_DEVICE_NOT_FOUND :
+	      pci_generic_config_write(bus, devfn, where, size, val);
+	raw_spin_unlock_irqrestore(&cp->lock, flags);
+	return ret;
+}
+
+static struct pci_ops cortina_own_pci_ops = {
+	.map_bus	= dw_pcie_own_conf_map_bus,
+	.read		= cortina_pcie_rd_own_conf,
+	.write		= cortina_pcie_wr_own_conf,
+};
+
+static int cortina_pcie_host_init(struct dw_pcie_rp *pp)
+{
+	pp->bridge->ops = &cortina_own_pci_ops;
+	pp->keep_rp_msi_en = true;
+	return 0;
+}
+
+static void cortina_pcie_host_post_init(struct dw_pcie_rp *pp)
+{
+	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
+	u8 cap = dw_pcie_find_capability(pci, PCI_CAP_ID_MSI);
+	u16 flags;
+
+	/* PCI enumeration clears MSI enable while initializing capabilities. */
+	if (cap) {
+		flags = dw_pcie_readw_dbi(pci, cap + PCI_MSI_FLAGS);
+		dw_pcie_writew_dbi(pci, cap + PCI_MSI_FLAGS, flags | PCI_MSI_FLAGS_ENABLE);
+	}
+}
+
+static int cortina_pcie_msi_init(struct dw_pcie_rp *pp)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(to_dw_pcie_from_pp(pp));
+	u32 ctrl;
+	int ret;
+
+	/* The application IRQ multiplexes MSI and INTx, so do not chain it twice. */
+	pp->msi_irq[0] = -ENODEV;
+	ret = dw_pcie_msi_host_init(pp);
+	if (ret)
+		return ret;
+	/* CS7542 routes endpoint MSI writes through its application target. */
+	pp->msi_data = cp->app_phys + APP_MSI_TARGET;
+	/* A custom MSI hook owns setup and teardown of the multiplexed receiver. */
+	for (ctrl = 0; ctrl < pp->num_vectors / MAX_MSI_IRQS_PER_CTRL; ctrl++) {
+		dw_pcie_writel_dbi(&cp->pci, PCIE_MSI_INTR0_MASK + ctrl * MSI_REG_CTRL_BLOCK_SIZE,
+				   pp->irq_mask[ctrl]);
+		dw_pcie_writel_dbi(&cp->pci, PCIE_MSI_INTR0_ENABLE + ctrl * MSI_REG_CTRL_BLOCK_SIZE,
+				   ~0);
+	}
+	dw_pcie_writel_dbi(&cp->pci, PCIE_MSI_ADDR_LO, lower_32_bits(pp->msi_data));
+	dw_pcie_writel_dbi(&cp->pci, PCIE_MSI_ADDR_HI, upper_32_bits(pp->msi_data));
+	cp->msi_ready = true;
+	return 0;
+}
+
+static void cortina_pcie_quiesce(struct cortina_pcie *cp)
+{
+	unsigned long flags;
+
+	/* Serialize with config/DBI accesses and prevent interrupt re-enables. */
+	raw_spin_lock_irqsave(&cp->lock, flags);
+	WRITE_ONCE(cp->link_lost, true);
+	writel(0, cp->app + APP_INT_ENABLE);
+	readl(cp->app + APP_INT_ENABLE);
+	raw_spin_unlock_irqrestore(&cp->lock, flags);
+	synchronize_irq(cp->irq);
+}
+
+static void cortina_pcie_remove_irq_domain(struct cortina_pcie *cp)
+{
+	unsigned int i;
+
+	irq_set_chained_handler_and_data(cp->irq, NULL, NULL);
+	synchronize_irq(cp->irq);
+	for (i = 0; i < PCI_NUM_INTX; i++)
+		irq_dispose_mapping(irq_find_mapping(cp->intx_domain, i));
+	irq_domain_remove(cp->intx_domain);
+}
+
+static void cortina_pcie_host_deinit(struct dw_pcie_rp *pp)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(to_dw_pcie_from_pp(pp));
+
+	/* Endpoints have stopped; now drain the shared IRQ before freeing domains. */
+	cortina_pcie_quiesce(cp);
+	if (cp->msi_ready) {
+		cp->msi_ready = false;
+		dw_pcie_free_msi(pp);
+		pp->msi_irq_domain = NULL;
+	}
+}
+
+static const struct dw_pcie_host_ops cortina_pcie_host_ops = {
+	.init		= cortina_pcie_host_init,
+	.post_init	= cortina_pcie_host_post_init,
+	.deinit		= cortina_pcie_host_deinit,
+	.msi_init	= cortina_pcie_msi_init,
+};
+
+/* Standard RC configuration above 512 bytes wedges the CS7542 bus.
+ * The DesignWare private register bank at 0x700 and above remains accessible.
+ */
+static u32 cortina_pcie_read_dbi(struct dw_pcie *pci, void __iomem *base,
+				 u32 reg, size_t size)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(pci);
+	unsigned long flags;
+	u32 value = 0;
+
+	/* Zero also makes the iATU enable poll fail after link loss. */
+	raw_spin_lock_irqsave(&cp->lock, flags);
+	if (!cp->link_lost &&
+	    !(base == pci->dbi_base && reg < 0x700 && reg + size > RC_CFG_LIMIT))
+		dw_pcie_read(base + reg, size, &value);
+	raw_spin_unlock_irqrestore(&cp->lock, flags);
+	return value;
+}
+
+static void cortina_pcie_write_dbi(struct dw_pcie *pci, void __iomem *base,
+				   u32 reg, size_t size, u32 value)
+{
+	struct cortina_pcie *cp = to_cortina_pcie(pci);
+	unsigned long flags;
+
+	raw_spin_lock_irqsave(&cp->lock, flags);
+	if (!cp->link_lost &&
+	    !(base == pci->dbi_base && reg < 0x700 && reg + size > RC_CFG_LIMIT))
+		dw_pcie_write(base + reg, size, value);
+	raw_spin_unlock_irqrestore(&cp->lock, flags);
+}
+
+static const struct dw_pcie_ops cortina_dw_pcie_ops = {
+	.read_dbi = cortina_pcie_read_dbi,
+	.write_dbi = cortina_pcie_write_dbi,
+	.link_up = cortina_pcie_link_up,
+	.get_ltssm = cortina_pcie_get_ltssm,
+	.start_link = cortina_pcie_start_link,
+	.stop_link = cortina_pcie_stop_link,
+};
+
+static void cortina_pcie_power_off(struct cortina_pcie *cp)
+{
+	gpiod_set_value_cansleep(cp->perst, 1);
+	reset_control_assert(cp->reset);
+	phy_power_off(cp->phy);
+	phy_exit(cp->phy);
+	clk_disable_unprepare(cp->clk);
+}
+
+static int cortina_pcie_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct cortina_pcie *cp;
+	struct dw_pcie *pci;
+	struct resource *res;
+	int ret;
+
+	cp = devm_kzalloc(dev, sizeof(*cp), GFP_KERNEL);
+	if (!cp)
+		return -ENOMEM;
+	pci = &cp->pci;
+	pci->dev = dev;
+	pci->ops = &cortina_dw_pcie_ops;
+	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "dbi");
+	if (!res)
+		return -EINVAL;
+	cp->dbi_phys = res->start;
+	cp->app = devm_platform_ioremap_resource_byname(pdev, "app");
+	if (IS_ERR(cp->app))
+		return PTR_ERR(cp->app);
+	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "app");
+	cp->app_phys = res->start;
+	if (res->start < APP_PHYS_BASE ||
+	    (res->start - APP_PHYS_BASE) % APP_PORT_STRIDE ||
+	    (res->start - APP_PHYS_BASE) / APP_PORT_STRIDE >= 3)
+		return -EINVAL;
+	cp->port = (res->start - APP_PHYS_BASE) / APP_PORT_STRIDE;
+	raw_spin_lock_init(&cp->lock);
+	cp->clk = devm_clk_get(dev, NULL);
+	if (IS_ERR(cp->clk))
+		return dev_err_probe(dev, PTR_ERR(cp->clk), "controller clock\n");
+	cp->reset = devm_reset_control_get_exclusive(dev, NULL);
+	if (IS_ERR(cp->reset))
+		return dev_err_probe(dev, PTR_ERR(cp->reset), "controller reset\n");
+	cp->phy = devm_phy_get(dev, "pcie");
+	if (IS_ERR(cp->phy))
+		return dev_err_probe(dev, PTR_ERR(cp->phy), "SerDes\n");
+	cp->perst = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
+	if (IS_ERR(cp->perst))
+		return dev_err_probe(dev, PTR_ERR(cp->perst), "PERST# GPIO\n");
+	cp->irq = platform_get_irq(pdev, 0);
+	if (cp->irq < 0)
+		return cp->irq;
+
+	ret = clk_prepare_enable(cp->clk);
+	if (ret)
+		return ret;
+	ret = phy_init(cp->phy);
+	if (ret)
+		goto disable_clk;
+	ret = phy_set_mode(cp->phy, PHY_MODE_PCIE);
+	if (ret)
+		goto exit_phy;
+	ret = phy_power_on(cp->phy);
+	if (ret)
+		goto exit_phy;
+	ret = reset_control_reset(cp->reset);
+	if (ret)
+		goto power_off;
+	writel(0, cp->app + APP_INT_ENABLE);
+	cortina_pcie_stop_link(pci);
+	writel(readl(cp->app + APP_INT_STATUS), cp->app + APP_INT_STATUS);
+	gpiod_set_value_cansleep(cp->perst, 0);
+	msleep(100);
+	ret = cortina_pcie_port_init(cp);
+	if (ret)
+		goto power_off;
+	ret = cortina_pcie_init_irq_domain(cp);
+	if (ret)
+		goto power_off;
+	irq_set_chained_handler_and_data(cp->irq, cortina_pcie_irq_handler, cp);
+	writel(INT_MSI | INT_ERR_MASK, cp->app + APP_INT_ENABLE);
+	pci->pp.ops = &cortina_pcie_host_ops;
+	ret = dw_pcie_host_init(&pci->pp);
+	if (ret) {
+		cortina_pcie_quiesce(cp);
+		cortina_pcie_remove_irq_domain(cp);
+		goto power_off;
+	}
+	platform_set_drvdata(pdev, cp);
+	return 0;
+
+power_off:
+	gpiod_set_value_cansleep(cp->perst, 1);
+	reset_control_assert(cp->reset);
+	phy_power_off(cp->phy);
+exit_phy:
+	phy_exit(cp->phy);
+disable_clk:
+	reset_control_assert(cp->reset);
+	clk_disable_unprepare(cp->clk);
+	return dev_err_probe(dev, ret, "host initialization\n");
+}
+
+static void cortina_pcie_remove(struct platform_device *pdev)
+{
+	struct cortina_pcie *cp = platform_get_drvdata(pdev);
+
+	dw_pcie_host_deinit(&cp->pci.pp);
+	cortina_pcie_remove_irq_domain(cp);
+	cortina_pcie_power_off(cp);
+}
+
+static void cortina_pcie_shutdown(struct platform_device *pdev)
+{
+	struct cortina_pcie *cp = platform_get_drvdata(pdev);
+
+	cortina_pcie_quiesce(cp);
+	cortina_pcie_stop_link(&cp->pci);
+	gpiod_set_value_cansleep(cp->perst, 1);
+	reset_control_assert(cp->reset);
+}
+
+static const struct of_device_id cortina_pcie_of_match[] = {
+	{ .compatible = "cortina,cs7542-pcie" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, cortina_pcie_of_match);
+
+static struct platform_driver cortina_pcie_driver = {
+	.probe = cortina_pcie_probe,
+	.remove = cortina_pcie_remove,
+	.shutdown = cortina_pcie_shutdown,
+	.driver = {
+		.name = "cs7542-pcie",
+		.of_match_table = cortina_pcie_of_match,
+	},
+};
+module_platform_driver(cortina_pcie_driver);
+
+MODULE_DESCRIPTION("Cortina Systems CS7542 PCIe host controller");
+MODULE_LICENSE("GPL");

-- 
2.53.0

