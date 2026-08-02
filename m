From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:23 +0200
Subject: [PATCH v3 07/15] usb: ehci: add Marvell EHCI host controller
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260802-rn102-rn104-series-v3-7-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=8439;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=PMKtRXfaGcd7T+RC96fzTds8pTTje8r1sML8k7YwexA=;
 b=fhLY2zxlwMUPUlSFadMKv+YEuWKdT6Zje/su3GuGtaTHKPIRifRs1LeTDtASdTPXWlxy2L+8X
 +0+nuejyVrwBp92b+59EEzKlKJRZV+USdAf58nGEaAD2xunx2qtYueT
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/usb/host/Kconfig        |   7 ++
 drivers/usb/host/Makefile       |  13 +--
 drivers/usb/host/ehci-marvell.c | 228 ++++++++++++++++++++++++++++++++++++++++
 3 files changed, 242 insertions(+), 6 deletions(-)

diff --git a/drivers/usb/host/Kconfig b/drivers/usb/host/Kconfig
index 58f276cdb4..8e46eca8a3 100644
--- a/drivers/usb/host/Kconfig
+++ b/drivers/usb/host/Kconfig
@@ -22,6 +22,13 @@ config USB_EHCI_ZYNQ
 	help
 	  Enable support for Zynq on-chip EHCI USB controller
 
+config USB_EHCI_MARVELL
+	bool "Marvell USB EHCI driver"
+	depends on ARCH_MVEBU
+	depends on USB_EHCI
+	help
+	  Enable support for Marvell USB EHCI controller
+
 config USB_OHCI
 	bool "OHCI driver"
 	depends on !MMU && HAS_DMA
diff --git a/drivers/usb/host/Makefile b/drivers/usb/host/Makefile
index cbddfbe923..5442d44e60 100644
--- a/drivers/usb/host/Makefile
+++ b/drivers/usb/host/Makefile
@@ -1,8 +1,9 @@
 # SPDX-License-Identifier: GPL-2.0-only
-obj-$(CONFIG_USB_EHCI)		+= ehci-hcd.o
-obj-$(CONFIG_USB_EHCI_OMAP)	+= ehci-omap.o
+obj-$(CONFIG_USB_EHCI)			+= ehci-hcd.o
+obj-$(CONFIG_USB_EHCI_OMAP)		+= ehci-omap.o
 obj-$(CONFIG_USB_EHCI_ATMEL)	+= ehci-atmel.o
-obj-$(CONFIG_USB_EHCI_ZYNQ)	+= ehci-zynq.o
-obj-$(CONFIG_USB_OHCI)		+= ohci-hcd.o
-obj-$(CONFIG_USB_OHCI_AT91)	+= ohci-at91.o
-obj-$(CONFIG_USB_XHCI)		+= xhci.o xhci-mem.o xhci-ring.o
+obj-$(CONFIG_USB_EHCI_ZYNQ)		+= ehci-zynq.o
+obj-$(CONFIG_USB_EHCI_MARVELL)	+= ehci-marvell.o
+obj-$(CONFIG_USB_OHCI)			+= ohci-hcd.o
+obj-$(CONFIG_USB_OHCI_AT91)		+= ohci-at91.o
+obj-$(CONFIG_USB_XHCI)			+= xhci.o xhci-mem.o xhci-ring.o
diff --git a/drivers/usb/host/ehci-marvell.c b/drivers/usb/host/ehci-marvell.c
new file mode 100644
index 0000000000..97123558d1
--- /dev/null
+++ b/drivers/usb/host/ehci-marvell.c
@@ -0,0 +1,228 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Marvell Orion / Kirkwood / Armada EHCI host controller for barebox
+ *
+ * Ported from the modern U-Boot ehci-marvell.c implementation and
+ * adapted to the barebox ehci_register() model.
+ */
+
+/*#define DEBUG*/
+
+#include <common.h>
+#include <driver.h>
+#include <init.h>
+#include <io.h>
+#include <of.h>
+#include <linux/usb/usb.h>
+#include <linux/usb/ehci.h>
+#include <linux/mbus.h>
+
+#include "ehci.h"
+
+#define USB_WINDOW_CTRL(i)			(0x320 + ((i) << 4))
+#define USB_WINDOW_BASE(i)			(0x324 + ((i) << 4))
+#define USB_TARGET_DRAM				0x0
+
+#define USB2_SBUSCFG_OFF			0x90
+
+#define USB_SBUSCFG_BAWR_OFF		0x6
+#define USB_SBUSCFG_BARD_OFF		0x3
+#define USB_SBUSCFG_AHBBRST_OFF		0x0
+
+#define USB_SBUSCFG_BAWR_ALIGN_64B	0x4
+#define USB_SBUSCFG_BARD_ALIGN_64B	0x4
+#define USB_SBUSCFG_AHBBRST_INCR16	0x7
+
+/* AC5 special window mapping (taken from U-Boot) */
+#define USB_TO_DRAM_TARGET_ID		0x2
+#define USB_TO_DRAM_ATTR_ID			0x0
+#define USB_DRAM_BASE				0x00000000
+#define USB_DRAM_SIZE				0xfff	/* do not exceed the source address space */
+
+/*
+ * Private state for this Marvell EHCI instance.
+ * The driver only needs the pointer to struct ehci_host.
+ */
+struct marvell_ehci {
+	struct ehci_host *ehci;
+	void __iomem *base;
+	struct device *dev;
+	u32 dram_bus_base;
+};
+
+static void marvell_ehci_sbuscfg_fixup(void __iomem *base)
+{
+	/*
+	 * SBUSCFG: Control for the AMBA system bus interface:
+	 * BAWR = BARD = 4 : Align rd/wr bursts packets larger than 64 bytes
+	 * AHBBRST = 7	 : Align AHB burst for packets larger than 64 bytes
+	 */
+	writel((USB_SBUSCFG_BAWR_ALIGN_64B << USB_SBUSCFG_BAWR_OFF) |
+			(USB_SBUSCFG_BARD_ALIGN_64B << USB_SBUSCFG_BARD_OFF) |
+			(USB_SBUSCFG_AHBBRST_INCR16 << USB_SBUSCFG_AHBBRST_OFF),
+			base + USB2_SBUSCFG_OFF);
+}
+
+/*
+ * Program the USB → DRAM decoding windows using MBUS information.
+ * For AC5, replicate the special 0x0..USB_DRAM_SIZE mapping.
+ */
+static void marvell_usb_brg_adrdec_setup(struct marvell_ehci *priv)
+{
+	const struct mbus_dram_target_info *dram;
+	void __iomem *base = priv->base;
+	int i;
+
+	dev_info(priv->dev, "USB adrdec setup: ENTER\n");
+
+	dram = mvebu_mbus_dram_info();
+	if (!dram) {
+		dev_err(priv->dev, "no MBUS DRAM info\n");
+		return;
+	}
+
+	for (i = 0; i < 4; i++) {
+		writel(0, base + USB_WINDOW_CTRL(i));
+		writel(0, base + USB_WINDOW_BASE(i));
+	}
+
+	if (priv->dev->of_node &&
+		of_device_is_compatible(priv->dev->of_node, "marvell,ac5-ehci")) {
+		/* map DRAM as seen by USB at address 0x0 (as done in U-Boot) */
+		writel((USB_DRAM_SIZE << 16) |
+				(USB_TO_DRAM_ATTR_ID << 8) |
+				(USB_TO_DRAM_TARGET_ID << 4) | 1,
+				base + USB_WINDOW_CTRL(0));
+		writel(USB_DRAM_BASE, base + USB_WINDOW_BASE(0));
+
+		dev_dbg(priv->dev,
+			"AC5 decoding windows: ctrl=0x%08x base=0x%08x\n",
+			readl(base + USB_WINDOW_CTRL(0)),
+			readl(base + USB_WINDOW_BASE(0)));
+	} else {
+		/* generic mvebu case: one window per each DRAM chip-select */
+
+		for (i = 0; i < dram->num_cs; i++) {
+			const struct mbus_dram_window *cs = dram->cs + i;
+
+			/* Write size, attributes and target id to control register */
+			writel(((cs->size - 1) & 0xffff0000) |
+					(cs->mbus_attr << 8) |
+					(dram->mbus_dram_target_id << 4) | 1,
+					base + USB_WINDOW_CTRL(i));
+
+			/* Write base address to base register */
+			writel(cs->base, base + USB_WINDOW_BASE(i));
+		}
+	}
+
+	for (i = 0; i < 4; i++) {
+		u32 ctrl = readl(base + USB_WINDOW_CTRL(i));
+		u32 winb = readl(base + USB_WINDOW_BASE(i));
+		dev_info(priv->dev, "WIN%d: CTRL=0x%08x BASE=0x%08x\n", i, ctrl, winb);
+	}
+}
+
+/*
+ * Initialization hook called by ehci-hcd.c before starting the host.
+ * Only the bridge address decoding is performed here.
+ */
+static int marvell_ehci_init(void *drvdata)
+{
+	struct marvell_ehci *priv = drvdata;
+
+	marvell_usb_brg_adrdec_setup(priv);
+
+	writel((USB_SBUSCFG_BAWR_ALIGN_64B << USB_SBUSCFG_BAWR_OFF) |
+		(USB_SBUSCFG_BARD_ALIGN_64B << USB_SBUSCFG_BARD_OFF) |
+		(USB_SBUSCFG_AHBBRST_INCR16 << USB_SBUSCFG_AHBBRST_OFF),
+		priv->base + 0x100 + 0x90);
+	mdelay(50);
+
+	/*
+	* The SBUSCFG programming (BAWR/BARD/AHBBRST) in U-Boot is only
+	* required for SoCs without hlock (e.g. Armada3700).
+	* It is currently omitted; if needed in the future, a dedicated
+	* post_init or EHCI core hook can be added.
+	*/
+
+	dev_dbg(priv->dev, "marvell_ehci_init done\n");
+
+	return 0;
+}
+
+static int marvell_ehci_probe(struct device *dev)
+{
+	struct marvell_ehci *priv;
+	struct resource *iores;
+	struct ehci_data data = {};
+	void __iomem *base;
+	struct ehci_host *ehci;
+
+	priv = xzalloc(sizeof(*priv));
+	priv->dev = dev;
+	dev->priv = priv;
+
+	iores = dev_request_mem_resource(dev, 0);
+	if (IS_ERR(iores))
+		return PTR_ERR(iores);
+
+	base = IOMEM(iores->start);
+	priv->base = base;
+
+	/*
+	* On Marvell controllers the EHCI block starts at offset 0x100
+	* from the USB base address.
+	*/
+	data.hccr = base + 0x100;
+
+	u32 capbase = readl(data.hccr);			/* HC_CAPBASE */
+	u8 caplength = capbase & 0xff;			/* CAPLENGTH */
+
+	data.hcor = (void __iomem *)((u8 *)data.hccr + caplength);
+
+	dev_info(dev, "EHCI probe: base=%p hccr=%p hcor=%p\n",
+			base, data.hccr, data.hcor);
+
+	dev_info(dev, "EHCI CAPBASE=0x%08x CAPLENGTH=0x%02x\n",
+			capbase, caplength);
+
+	data.init = marvell_ehci_init;
+	data.drvdata = priv;
+
+	if (of_device_is_compatible(dev->of_node, "marvell,armada-3700-ehci"))
+		marvell_ehci_sbuscfg_fixup(base);
+
+	dev_dbg(dev, "marvell_ehci_probe: done\n");
+
+	ehci = ehci_register(dev, &data);
+	if (IS_ERR(ehci))
+		return PTR_ERR(ehci);
+
+	priv->ehci = ehci;
+
+	return 0;
+}
+
+static void marvell_ehci_remove(struct device *dev)
+{
+	struct marvell_ehci *priv = dev->priv;
+
+	if (priv && priv->ehci)
+		ehci_unregister(priv->ehci);
+}
+
+static const struct of_device_id marvell_ehci_dt_ids[] = {
+	{ .compatible = "marvell,orion-ehci" },
+	{ .compatible = "marvell,armada-3700-ehci" },
+	{ .compatible = "marvell,ac5-ehci" },
+	{ /* sentinel */ }
+};
+
+static struct driver marvell_ehci_driver = {
+	.name			= "marvell-ehci",
+	.probe			= marvell_ehci_probe,
+	.remove			= marvell_ehci_remove,
+	.of_compatible	= DRV_OF_COMPAT(marvell_ehci_dt_ids),
+};
+device_platform_driver(marvell_ehci_driver);

-- 
2.47.3

