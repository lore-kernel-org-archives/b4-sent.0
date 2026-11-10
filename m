From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:03 +0000
Subject: [PATCH 2/5] iommu/rockchip: Rate-limit the page fault reports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-iommu-rockchip-faults-v1-2-b1dda574dbb8@gmail.com>
References: <20261110-iommu-rockchip-faults-v1-0-b1dda574dbb8@gmail.com>
In-Reply-To: <20261110-iommu-rockchip-faults-v1-0-b1dda574dbb8@gmail.com>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Heiko Stuebner <heiko@sntech.de>, 
 Jeffy Chen <jeffy.chen@rock-chips.com>, Tomasz Figa <tfiga@chromium.org>
Cc: iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294661; l=4219;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Mh9yYDG5bU5JM98WHSJZQsM8WG0/aD2uijwgqmqZNAQ=;
 b=hvRoaQcV/e2QkSmbd5XIjnuU5jTIsV8joll+zB/7lLnUC4EgLhCL//AZveTkRCYTL/aG+IjfQ
 yKDQwU5454GC9FcA5kvpFHC4OYoIFqgd4AnAOhpwWaMfFJYB4N0O+lc
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rk_iommu_irq() prints three lines for every page fault (the fault, and
log_iova()'s two lines with the page table walk) from the hard interrupt
handler. A master that keeps accessing unmapped memory faults again as
soon as the fault is acknowledged, and on a board with a serial console
the handler then spends its time waiting for the console.

On an Orange Pi 5 (RK3588S, 115200 baud console), a VEPU121 JPEG encoder
core given an unmapped input address took 149 faults during its 2 s
timeout; the irq_handler_entry/exit trace events put 2.02 s of that in
rk_iommu_irq(), up to 17 ms for one call, and single faults took 18 to
27 ms each. The core's own timeout work could run only between faults.

Print at most DEFAULT_RATELIMIT_BURST reports per
DEFAULT_RATELIMIT_INTERVAL and IOMMU. report_iommu_fault() is still
called for every fault, so its io_page_fault trace event keeps the full
record.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/rockchip-iommu.c | 31 ++++++++++++++++++++++++-------
 1 file changed, 24 insertions(+), 7 deletions(-)

diff --git a/drivers/iommu/rockchip-iommu.c b/drivers/iommu/rockchip-iommu.c
index d40e2a26b7be..c3c3502db27d 100644
--- a/drivers/iommu/rockchip-iommu.c
+++ b/drivers/iommu/rockchip-iommu.c
@@ -23,6 +23,7 @@
 #include <linux/of_platform.h>
 #include <linux/platform_device.h>
 #include <linux/pm_runtime.h>
+#include <linux/ratelimit.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
 #include <linux/string_choices.h>
@@ -116,6 +117,7 @@ struct rk_iommu {
 	struct list_head node; /* entry in rk_iommu_domain.iommus */
 	struct iommu_domain *domain; /* domain to which iommu is attached */
 	const struct rk_iommu_ops *rk_ops;
+	struct ratelimit_state fault_rs; /* for the fault reports */
 };
 
 struct rk_iommudata {
@@ -608,6 +610,7 @@ static irqreturn_t rk_iommu_irq(int irq, void *dev_id)
 	u32 int_status;
 	dma_addr_t iova;
 	irqreturn_t ret = IRQ_NONE;
+	bool print;
 	int i, err;
 
 	err = pm_runtime_get_if_in_use(iommu->dev);
@@ -632,11 +635,22 @@ static irqreturn_t rk_iommu_irq(int irq, void *dev_id)
 			flags = (status & RK_MMU_STATUS_PAGE_FAULT_IS_WRITE) ?
 					IOMMU_FAULT_WRITE : IOMMU_FAULT_READ;
 
-			dev_err(iommu->dev, "Page fault at %pad of type %s\n",
-				&iova,
-				str_write_read(flags == IOMMU_FAULT_WRITE));
-
-			log_iova(iommu, i, iova);
+			/*
+			 * PAGE_FAULT_DONE below lets the master go on, and a
+			 * master that keeps accessing unmapped addresses faults
+			 * again at once, until its own driver stops it. Printing
+			 * every one of those faults from this handler keeps the
+			 * CPU in hard interrupt context for as long as the
+			 * console takes to print them. The trace event of
+			 * report_iommu_fault() still records every fault.
+			 */
+			print = __ratelimit(&iommu->fault_rs);
+			if (print) {
+				dev_err(iommu->dev, "Page fault at %pad of type %s\n",
+					&iova,
+					str_write_read(flags == IOMMU_FAULT_WRITE));
+				log_iova(iommu, i, iova);
+			}
 
 			/*
 			 * Report page fault to any installed handlers.
@@ -646,14 +660,15 @@ static irqreturn_t rk_iommu_irq(int irq, void *dev_id)
 			if (iommu->domain != &rk_identity_domain)
 				report_iommu_fault(iommu->domain, iommu->dev, iova,
 						   flags);
-			else
+			else if (print)
 				dev_err(iommu->dev, "Page fault while iommu not attached to domain?\n");
 
 			rk_iommu_base_command(iommu->bases[i], RK_MMU_CMD_ZAP_CACHE);
 			rk_iommu_base_command(iommu->bases[i], RK_MMU_CMD_PAGE_FAULT_DONE);
 		}
 
-		if (int_status & RK_MMU_IRQ_BUS_ERROR)
+		if ((int_status & RK_MMU_IRQ_BUS_ERROR) &&
+		    __ratelimit(&iommu->fault_rs))
 			dev_err(iommu->dev, "BUS_ERROR occurred at %pad\n", &iova);
 
 		if (int_status & ~RK_MMU_IRQ_MASK)
@@ -1270,6 +1285,8 @@ static int rk_iommu_probe(struct platform_device *pdev)
 
 	iommu->reset_disabled = device_property_read_bool(dev,
 					"rockchip,disable-mmu-reset");
+	ratelimit_state_init(&iommu->fault_rs, DEFAULT_RATELIMIT_INTERVAL,
+			     DEFAULT_RATELIMIT_BURST);
 
 	/*
 	 * Take every clock the devicetree provides.  Most IOMMU instances

-- 
2.55.0

