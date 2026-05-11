From: Nathan Lynch <nathan.lynch@amd.com>
Date: Mon, 11 May 2026 14:16:15 -0500
Subject: [PATCH v2 03/23] dmaengine: sdxi: Add PCI initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-sdxi-base-v2-3-889cfed17e3f@amd.com>
References: <20260511-sdxi-base-v2-0-889cfed17e3f@amd.com>
In-Reply-To: <20260511-sdxi-base-v2-0-889cfed17e3f@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Bjorn Helgaas <bhelgaas@google.com>, 
 David Rientjes <rientjes@google.com>, John.Kariuki@amd.com, 
 Kinsey Ho <kinseyho@google.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 PradeepVineshReddy.Kodamati@amd.com, Shivank Garg <shivankg@amd.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, Wei Huang <wei.huang2@amd.com>, 
 Wei Xu <weixugc@google.com>, dmaengine@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778526994; l=6987;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=Jr/4QKf8JJOoYOpO1PMCwsIuwzKb0eqSFB9z91gGX0w=;
 b=iS7K0F3kxuiokKzkHZ+v2FPj9hh3Kvd4IKMybGZRuBR7yakUe4g98s8dXGUlMj4dpqEdlMXsQ
 +fpM3v3KHchDJnWnKatmiz/0n5Qce0OkyB/pns0ViBT/6/VaYxdLlVN
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add enough code to bind a SDXI device via the class code and map its
control registers and doorbell region. All device resources are
managed with devres at this point, so there is no explicit teardown
path.

While the SDXI specification includes a PCIe binding, the standard is
intended to be independent of the underlying I/O interconnect. So the
driver confines PCI-specific code to pci.c, and the rest (such as
device.c, introduced here) is bus-agnostic. Hence there is some
indirection: during probe, the bus code registers any matched device
with the generic SDXI core, supplying the device and a sdxi_bus_ops
vector. After the core associates a new sdxi_dev with the device,
bus-specific initialization proceeds via the sdxi_bus_ops->init()
callback.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/Kconfig       |  2 ++
 drivers/dma/Makefile      |  1 +
 drivers/dma/sdxi/Kconfig  |  8 +++++
 drivers/dma/sdxi/Makefile |  6 ++++
 drivers/dma/sdxi/device.c | 26 +++++++++++++++
 drivers/dma/sdxi/pci.c    | 83 +++++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/sdxi.h   | 38 ++++++++++++++++++++++
 7 files changed, 164 insertions(+)

diff --git a/drivers/dma/Kconfig b/drivers/dma/Kconfig
index ae6a682c9f76..3d89284e7cf8 100644
--- a/drivers/dma/Kconfig
+++ b/drivers/dma/Kconfig
@@ -762,6 +762,8 @@ source "drivers/dma/lgm/Kconfig"
 
 source "drivers/dma/loongson/Kconfig"
 
+source "drivers/dma/sdxi/Kconfig"
+
 source "drivers/dma/stm32/Kconfig"
 
 # clients
diff --git a/drivers/dma/Makefile b/drivers/dma/Makefile
index 14aa086629d5..371927615c4a 100644
--- a/drivers/dma/Makefile
+++ b/drivers/dma/Makefile
@@ -84,6 +84,7 @@ obj-$(CONFIG_XGENE_DMA) += xgene-dma.o
 obj-$(CONFIG_ST_FDMA) += st_fdma.o
 obj-$(CONFIG_FSL_DPAA2_QDMA) += fsl-dpaa2-qdma/
 obj-$(CONFIG_INTEL_LDMA) += lgm/
+obj-$(CONFIG_SDXI) += sdxi/
 
 obj-y += amd/
 obj-y += loongson/
diff --git a/drivers/dma/sdxi/Kconfig b/drivers/dma/sdxi/Kconfig
new file mode 100644
index 000000000000..a568284cd583
--- /dev/null
+++ b/drivers/dma/sdxi/Kconfig
@@ -0,0 +1,8 @@
+config SDXI
+	tristate "SDXI support"
+	select DMA_ENGINE
+	help
+	  Enable support for Smart Data Accelerator Interface (SDXI)
+	  Platform Data Mover devices. SDXI is a vendor-neutral
+	  standard for a memory-to-memory data mover and acceleration
+	  interface.
diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
new file mode 100644
index 000000000000..f84b87d53e27
--- /dev/null
+++ b/drivers/dma/sdxi/Makefile
@@ -0,0 +1,6 @@
+# SPDX-License-Identifier: GPL-2.0
+obj-$(CONFIG_SDXI) += sdxi.o
+
+sdxi-objs += device.o
+
+sdxi-$(CONFIG_PCI_MSI) += pci.o
diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
new file mode 100644
index 000000000000..b718ce04afa0
--- /dev/null
+++ b/drivers/dma/sdxi/device.c
@@ -0,0 +1,26 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SDXI hardware device driver
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+
+#include <linux/device.h>
+#include <linux/slab.h>
+
+#include "sdxi.h"
+
+int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
+{
+	struct sdxi_dev *sdxi;
+
+	sdxi = devm_kzalloc(dev, sizeof(*sdxi), GFP_KERNEL);
+	if (!sdxi)
+		return -ENOMEM;
+
+	sdxi->dev = dev;
+	sdxi->bus_ops = ops;
+	dev_set_drvdata(dev, sdxi);
+
+	return sdxi->bus_ops->init(sdxi);
+}
diff --git a/drivers/dma/sdxi/pci.c b/drivers/dma/sdxi/pci.c
new file mode 100644
index 000000000000..9ac94d6f8b96
--- /dev/null
+++ b/drivers/dma/sdxi/pci.c
@@ -0,0 +1,83 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SDXI PCI device code
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+
+#include <linux/dev_printk.h>
+#include <linux/dma-mapping.h>
+#include <linux/err.h>
+#include <linux/io.h>
+#include <linux/iomap.h>
+#include <linux/module.h>
+#include <linux/pci.h>
+
+#include "sdxi.h"
+
+enum sdxi_mmio_bars {
+	SDXI_PCI_BAR_CTL_REGS = 0,
+	SDXI_PCI_BAR_DOORBELL = 2,
+};
+
+static struct pci_dev *sdxi_to_pci_dev(const struct sdxi_dev *sdxi)
+{
+	return to_pci_dev(sdxi->dev);
+}
+
+static int sdxi_pci_init(struct sdxi_dev *sdxi)
+{
+	struct pci_dev *pdev = sdxi_to_pci_dev(sdxi);
+	struct device *dev = &pdev->dev;
+	int ret;
+
+	ret = pcim_enable_device(pdev);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to enable device\n");
+
+	dma_set_mask_and_coherent(dev, DMA_BIT_MASK(64));
+
+	sdxi->ctrl_regs = pcim_iomap_region(pdev, SDXI_PCI_BAR_CTL_REGS,
+					    KBUILD_MODNAME);
+	if (IS_ERR(sdxi->ctrl_regs))
+		return dev_err_probe(dev, PTR_ERR(sdxi->ctrl_regs),
+				     "failed to map control registers\n");
+
+	sdxi->dbs = pcim_iomap_region(pdev, SDXI_PCI_BAR_DOORBELL,
+				      KBUILD_MODNAME);
+	if (IS_ERR(sdxi->dbs))
+		return dev_err_probe(dev, PTR_ERR(sdxi->dbs),
+				     "failed to map doorbell region\n");
+
+	pci_set_master(pdev);
+	return 0;
+}
+
+static const struct sdxi_bus_ops sdxi_pci_ops = {
+	.init = sdxi_pci_init,
+};
+
+static int sdxi_pci_probe(struct pci_dev *pdev,
+			  const struct pci_device_id *id)
+{
+	return sdxi_register(&pdev->dev, &sdxi_pci_ops);
+}
+
+static const struct pci_device_id sdxi_id_table[] = {
+	{ PCI_DEVICE_CLASS(PCI_CLASS_ACCELERATOR_SDXI, 0xffffff) },
+	{ }
+};
+MODULE_DEVICE_TABLE(pci, sdxi_id_table);
+
+static struct pci_driver sdxi_driver = {
+	.name = "sdxi",
+	.id_table = sdxi_id_table,
+	.probe = sdxi_pci_probe,
+	.sriov_configure = pci_sriov_configure_simple,
+};
+
+MODULE_AUTHOR("Wei Huang");
+MODULE_AUTHOR("Nathan Lynch");
+MODULE_DESCRIPTION("SDXI PCIe interface driver");
+MODULE_LICENSE("GPL");
+module_pci_driver(sdxi_driver);
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
new file mode 100644
index 000000000000..d4c61ca2f875
--- /dev/null
+++ b/drivers/dma/sdxi/sdxi.h
@@ -0,0 +1,38 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/*
+ * SDXI device driver header
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+
+#ifndef DMA_SDXI_H
+#define DMA_SDXI_H
+
+#include <linux/compiler_types.h>
+#include <linux/types.h>
+
+struct sdxi_dev;
+
+/**
+ * struct sdxi_bus_ops - Bus-specific methods for SDXI devices.
+ */
+struct sdxi_bus_ops {
+	/**
+	 * @init: Map control registers and doorbell region, allocate
+	 *        IRQ ranges. Invoked before bus-agnostic SDXI
+	 *        function initialization.
+	 */
+	int (*init)(struct sdxi_dev *sdxi);
+};
+
+struct sdxi_dev {
+	struct device *dev;
+	void __iomem *ctrl_regs;	/* virt addr of ctrl registers */
+	void __iomem *dbs;		/* virt addr of doorbells */
+
+	const struct sdxi_bus_ops *bus_ops;
+};
+
+int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops);
+
+#endif /* DMA_SDXI_H */

-- 
2.54.0

