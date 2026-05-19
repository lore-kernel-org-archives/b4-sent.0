From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 May 2026 13:41:20 +0530
Subject: [PATCH v2 1/4] PCI: Introduce an API to check if RC/platform can
 retain device context during suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-l1ss-fix-v2-1-b2c3a4bdeb15@oss.qualcomm.com>
References: <20260519-l1ss-fix-v2-0-b2c3a4bdeb15@oss.qualcomm.com>
In-Reply-To: <20260519-l1ss-fix-v2-0-b2c3a4bdeb15@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Keith Busch <kbusch@kernel.org>, 
 Jens Axboe <axboe@kernel.dk>, Christoph Hellwig <hch@lst.de>, 
 Sagi Grimberg <sagi@grimberg.me>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-nvme@lists.infradead.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3173;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=4Dttv4RJQFd7HvyHdhLrZ9fHK7lOnfb6oJIEtWxnp+c=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDBsuFVWnfdQVfhPVZySomdr2OjOwStn053I2Z
 V4Eo3R7/NGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwbLgAKCRBVnxHm/pHO
 9Z0GB/9iuKAuXAoMUZ/KkPcuOGdOcNzL1Y1aGn2iqt/VN50isEVX+qRKyeYF+1/+goyuFmH6K0+
 dFET7Yc3dQ0FfZ5KPJZM7N86HQIDiPIuDPyB9R5jyCBw+RlYdw4pmWmBbyXhUwt6bct1TbGvt6p
 zrcbhftJao2sBzyTROAZBoSf+zTJy0Tq0YTCr52wYMM2hW6+q9bvKpHu21xs7dRCih4wpI1hRVG
 iUE6TZHmn0Gp26LMSW6jXW91hURIHgqB+9g0sAqlTGO2mk9hfOLzJJzksiuXtxk4LETN555O9jI
 4BUrcusPE6A0t5RF+LnNd1++s1JxgcH9Kw6KWQ3eJQYYYS37
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the PCI endpoint drivers like NVMe checks whether the device
context will be retained or not during system suspend, with the help of
pm_suspend_via_firmware() API.

But it is possible that the device context might be lost due to some
platform limitation as well. Having those checks in the endpoint drivers
will not scale and will cause a lot of code duplication.

So introduce an API that acts as a sole point of truth that the endpoint
drivers can rely on to check whether they can expect the device context
to be retained or not.

If the API returns 'false', then the client drivers need to prepare for
context loss by performing actions such as resetting the device, saving
the context, shutting it down etc... If it returns 'true', then the drivers
do not need to perform any special action and can leave the device in
active state.

Right now, this API only incorporates the pm_suspend_via_firmware() check.
But will be extended in the future commits.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pci.c   | 23 +++++++++++++++++++++++
 include/linux/pci.h |  7 +++++++
 2 files changed, 30 insertions(+)

diff --git a/drivers/pci/pci.c b/drivers/pci/pci.c
index 8f7cfcc00090..38cc5172d259 100644
--- a/drivers/pci/pci.c
+++ b/drivers/pci/pci.c
@@ -33,6 +33,7 @@
 #include <asm/dma.h>
 #include <linux/aer.h>
 #include <linux/bitfield.h>
+#include <linux/suspend.h>
 #include "pci.h"
 
 DEFINE_MUTEX(pci_slot_mutex);
@@ -2899,6 +2900,28 @@ void pci_config_pm_runtime_put(struct pci_dev *pdev)
 		pm_runtime_put_sync(parent);
 }
 
+/**
+ * pci_suspend_retains_context - Check if the platform can retain the device
+ *				 context during system suspend
+ * @pdev: PCI device to check
+ *
+ * Returns true if the platform can guarantee to retain the device context,
+ * false otherwise.
+ */
+bool pci_suspend_retains_context(struct pci_dev *pdev)
+{
+	/*
+	 * If the platform firmware (like ACPI) is involved at the end of system
+	 * suspend, device context may not be retained.
+	 */
+	if (pm_suspend_via_firmware())
+		return false;
+
+	/* Assume that the context is retained by default */
+	return true;
+}
+EXPORT_SYMBOL_GPL(pci_suspend_retains_context);
+
 static const struct dmi_system_id bridge_d3_blacklist[] = {
 #ifdef CONFIG_X86
 	{
diff --git a/include/linux/pci.h b/include/linux/pci.h
index 2c4454583c11..f60f9e4e7b39 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -2086,6 +2086,8 @@ pci_release_mem_regions(struct pci_dev *pdev)
 			    pci_select_bars(pdev, IORESOURCE_MEM));
 }
 
+bool pci_suspend_retains_context(struct pci_dev *pdev);
+
 #else /* CONFIG_PCI is not enabled */
 
 static inline void pci_set_flags(int flags) { }
@@ -2244,6 +2246,11 @@ pci_alloc_irq_vectors(struct pci_dev *dev, unsigned int min_vecs,
 static inline void pci_free_irq_vectors(struct pci_dev *dev)
 {
 }
+
+static inline bool pci_suspend_retains_context(struct pci_dev *pdev)
+{
+	return true;
+}
 #endif /* CONFIG_PCI */
 
 /* Include architecture-dependent settings and functions */

-- 
2.48.1

