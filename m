From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:32 -0500
Subject: [PATCH 22/23] dmaengine: sdxi: MSI/MSI-X vector allocation and
 mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-22-1d184cb5c60a@amd.com>
References: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
In-Reply-To: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
To: Vinod Koul <vkoul@kernel.org>
Cc: Wei Huang <wei.huang2@amd.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Jonathan Cameron <jonathan.cameron@huawei.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, PradeepVineshReddy.Kodamati@amd.com, 
 John.Kariuki@amd.com, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dmaengine@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=6787;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=+70bvPsXLZ6JtPOvD5LtOSlAhOg3eN58vo6yDBNKJ0s=;
 b=gNZi96Bgh+vS0dBam9zeGmkSaV4mScK2225z7j07aiU5mBGt3DVyCo+TfF8XaM2eeVgWVSM+B
 HwfUKkollP0Bl/f+3MeMuQPwo6ZQeFLagjMRwVaEuCSeylMKU7fXm5o
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During PCI probe, allocate a vector per context supported by the
function as reported by the capability register, plus one for the
error log interrupt, which is always vector 0. The rest of the vector
range is available for use with interrupt-generating descriptors.

Introduce sdxi_alloc_vector() and sdxi_free_vector() which are thin
wrappers around the IDA that tracks the allocated vector range.

Introduce sdxi_vector_to_irq() which invokes a new get_irq() bus op to
translate the device-relative index to the Linux IRQ number for use
with request_irq() etc. For PCI this dispatches to pci_irq_vector().

Code such as the DMA engine provider that intends to submit interrupt
descriptors should prepare by using sdxi_alloc_vector() and
sdxi_vector_to_irq(), and clean up by using sdxi_free_vector().

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/device.c |  4 ++++
 drivers/dma/sdxi/pci.c    | 29 +++++++++++++++++++++++-
 drivers/dma/sdxi/sdxi.h   | 57 +++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 89 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index aaff6b15325a..8b11197c5781 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -10,6 +10,7 @@
 #include <linux/device.h>
 #include <linux/dma-mapping.h>
 #include <linux/dmapool.h>
+#include <linux/idr.h>
 #include <linux/log2.h>
 #include <linux/slab.h>
 #include <linux/xarray.h>
@@ -303,6 +304,7 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 
 	sdxi->dev = dev;
 	sdxi->bus_ops = ops;
+	ida_init(&sdxi->vectors);
 	xa_init_flags(&sdxi->client_cxts, XA_FLAGS_ALLOC1);
 	dev_set_drvdata(dev, sdxi);
 
@@ -323,5 +325,7 @@ void sdxi_unregister(struct device *dev)
 		sdxi_cxt_exit(cxt);
 	xa_destroy(&sdxi->client_cxts);
 
+	ida_destroy(&sdxi->vectors);
+
 	sdxi_dev_stop(sdxi);
 }
diff --git a/drivers/dma/sdxi/pci.c b/drivers/dma/sdxi/pci.c
index 8e4dfde078ff..99430eaa583d 100644
--- a/drivers/dma/sdxi/pci.c
+++ b/drivers/dma/sdxi/pci.c
@@ -5,6 +5,7 @@
  * Copyright Advanced Micro Devices, Inc.
  */
 
+#include <linux/bitfield.h>
 #include <linux/dev_printk.h>
 #include <linux/dma-mapping.h>
 #include <linux/err.h>
@@ -13,6 +14,7 @@
 #include <linux/module.h>
 #include <linux/pci.h>
 
+#include "mmio.h"
 #include "sdxi.h"
 
 enum sdxi_mmio_bars {
@@ -29,7 +31,8 @@ static int sdxi_pci_init(struct sdxi_dev *sdxi)
 {
 	struct pci_dev *pdev = sdxi_to_pci_dev(sdxi);
 	struct device *dev = &pdev->dev;
-	int ret;
+	unsigned int cap1_max_cxt;
+	int vecs, ret;
 
 	ret = pcim_enable_device(pdev);
 	if (ret)
@@ -53,12 +56,36 @@ static int sdxi_pci_init(struct sdxi_dev *sdxi)
 				     "failed to map doorbell region\n");
 	}
 
+	/*
+	 * Allocate the minimum required set of vectors plus one for
+	 * each client context supported by the function.
+	 */
+	cap1_max_cxt = FIELD_GET(SDXI_MMIO_CAP1_MAX_CXT,
+				 sdxi_read64(sdxi, SDXI_MMIO_CAP1));
+	vecs = pci_alloc_irq_vectors(pdev, SDXI_MIN_VECTORS,
+				     SDXI_MIN_VECTORS + cap1_max_cxt,
+				     PCI_IRQ_MSI | PCI_IRQ_MSIX);
+	if (vecs < 0) {
+		return dev_err_probe(dev, vecs,
+				     "failed to allocate MSIs (max_cxt=%u)\n",
+				     cap1_max_cxt);
+	}
+
+	sdxi->nr_vectors = vecs;
+	sdxi_dbg(sdxi, "allocated %u vectors\n", sdxi->nr_vectors);
+
 	pci_set_master(pdev);
 	return 0;
 }
 
+static int sdxi_pci_get_irq(struct sdxi_dev *sdxi, unsigned int nr)
+{
+	return pci_irq_vector(sdxi_to_pci_dev(sdxi), nr);
+}
+
 static const struct sdxi_bus_ops sdxi_pci_ops = {
 	.init = sdxi_pci_init,
+	.get_irq = sdxi_pci_get_irq,
 };
 
 static int sdxi_pci_probe(struct pci_dev *pdev,
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index da33719735ab..d4e1236a775e 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -8,8 +8,10 @@
 #ifndef DMA_SDXI_H
 #define DMA_SDXI_H
 
+#include <linux/bug.h>
 #include <linux/compiler_types.h>
 #include <linux/dev_printk.h>
+#include <linux/idr.h>
 #include <linux/io-64-nonatomic-lo-hi.h>
 #include <linux/types.h>
 #include <linux/xarray.h>
@@ -27,6 +29,21 @@
 #define L1_CXT_CTRL_PTR_SHIFT		6
 #define L1_CXT_AKEY_PTR_SHIFT		12
 
+enum {
+	/*
+	 * Per SDXI 1.0 3.4 Error Log, the error log interrupt is
+	 * always vector 0.
+	 */
+	SDXI_ERROR_VECTOR = 0,
+
+	/*
+	 * Request at least one vector to account for the error log
+	 * interrupt. Increment this if the driver gains more
+	 * dedicated interrupts (e.g. one for the admin context).
+	 */
+	SDXI_MIN_VECTORS = 1,
+};
+
 struct sdxi_dev;
 
 /**
@@ -39,6 +56,10 @@ struct sdxi_bus_ops {
 	 *        function initialization.
 	 */
 	int (*init)(struct sdxi_dev *sdxi);
+	/**
+	 * @get_irq: Map device interrupt index to Linux IRQ number.
+	 */
+	int (*get_irq)(struct sdxi_dev *sdxi, unsigned int index);
 };
 
 struct sdxi_dev {
@@ -61,6 +82,9 @@ struct sdxi_dev {
 	struct dma_pool *cxt_ctl_pool;
 	struct dma_pool *cst_blk_pool;
 
+	unsigned int nr_vectors;
+	struct ida vectors;
+
 	struct sdxi_cxt *admin_cxt;
 	struct xarray client_cxts; /* context id -> (struct sdxi_cxt *) */
 
@@ -76,6 +100,39 @@ static inline struct device *sdxi_to_dev(const struct sdxi_dev *sdxi)
 #define sdxi_info(s, fmt, ...) dev_info(sdxi_to_dev(s), fmt, ## __VA_ARGS__)
 #define sdxi_err(s, fmt, ...) dev_err(sdxi_to_dev(s), fmt, ## __VA_ARGS__)
 
+/**
+ * sdxi_alloc_vector() - Allocate an interrupt vector.
+ *
+ * A vector that will have the same lifetime as the device does not
+ * need to be released explicitly. Otherwise the vector must be
+ * released with sdxi_free_vector().
+ */
+static inline int sdxi_alloc_vector(struct sdxi_dev *sdxi)
+{
+	return ida_alloc_max(&sdxi->vectors, sdxi->nr_vectors - 1,
+			     GFP_KERNEL);
+}
+
+/**
+ * sdxi_free_vector() - Release a previously allocated index.
+ */
+static inline void sdxi_free_vector(struct sdxi_dev *sdxi, unsigned int nr)
+{
+	ida_free(&sdxi->vectors, nr);
+}
+
+/**
+ * sdxi_vector_to_irq() - Translate an allocated interrupt vector to
+ *                        Linux IRQ number suitable for passing to
+ *                        request_irq() et al.
+ */
+static inline int sdxi_vector_to_irq(struct sdxi_dev *sdxi, unsigned int nr)
+{
+	/* Moan if the index isn't currently allocated. */
+	WARN_ON_ONCE(!ida_exists(&sdxi->vectors, nr));
+	return sdxi->bus_ops->get_irq(sdxi, nr);
+}
+
 int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops);
 void sdxi_unregister(struct device *dev);
 

-- 
2.53.0

