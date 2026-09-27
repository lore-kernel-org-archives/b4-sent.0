From: Daniel Drake <dan@reactivated.net>
Date: Sun, 27 Sep 2026 14:09:04 +0100
Subject: [PATCH v7 5/6] iommu: Add Broadcom BCM2712 IOMMU driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-bcm2712-iommu-submit-v7-5-dfa2b975cbc9@reactivated.net>
References: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
In-Reply-To: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Daniel Drake <dan@reactivated.net>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-rpi-kernel@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, nick.hollinghurst@raspberrypi.com, 
 james.quinlan@broadcom.com, Jason Gunthorpe <jgg@ziepe.ca>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=24058; i=dan@reactivated.net;
 h=from:subject:message-id; bh=Jnbl/XzcfRfkNN4vH5bvABW2ecsn36jX7MWS73GrFgA=;
 b=owEBbQKS/ZANAwAKAcPmj7FTFEe7AcsmYgBquRWFjGhKYMCLzAL1gCLG2iL146a+HKeetafZG
 jvSOJeBpTuJAjMEAAEKAB0WIQQ6Rf0sUP1iEhXfVfjD5o+xUxRHuwUCarkVhQAKCRDD5o+xUxRH
 u1I2D/wPRUl9d0kShvWKCXd1N7CEFvSVFEDoZogI4kGib5se810ruQyBdXSw5WQScUhhDRgwCvX
 5Ivi4r35OJuQIelTLqO/1DCeW0byZSDW0b1cv46zSQSdOViwD+HXWAESrCexGiv3w/yEKjrv0L9
 Zlg5609Eyyae5Uf5tQNwe9Hun3useTWsqEup4FbDPrD9Znsva78eQlfnYpdrebSmIKb9rIZJxr2
 reDT5JJvUETfxZL+4tTN501tfSp7HfxkIwMzzZmvatE50wOUziUDU0ONN4A7EmD8keAJJR61jcE
 sqwr90hL3i3WRQmxByRcg+ISqvWS6/4q+9L1KX3+kyqBal+ykL/kgMu5tgKlSKTD6rh3SMVJrX1
 Rim5Xo8TCLQMpqzH5nRabpe4Ifs84f5ib55im5HZ9jPTMPkJvQuMUOm3j0TSdWQTBgtYhAty/J0
 C9n+26iKqKYzVRs36enpRBcRS4toircGjEgbRxL94GBsF2rg9QYngl1g4ZTfI7/eJu1/Gtf0RuS
 5b7sxQpF/PV2WTFxhHy6lT3tATAgpCJm/2ffKPBklM5t5kJkUGGabFn2dkP7KvS7xZekrLHFA11
 2waMkcVDY3kkMDs069yHYub/uE0Y2Wwh6n2B8Bq0F+k9tSAUsluxI8n3MyX/hMFYSHWKGcBUr+P
 KTut1CpLrcx6hqw==
X-Developer-Key: i=dan@reactivated.net; a=openpgp;
 fpr=3A45FD2C50FD621215DF55F8C3E68FB1531447BB
X-Endpoint-Received: by B4 Relay for dan@reactivated.net/default with auth_id=1070
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This IOMMU translates memory access requests for the VC6 display
pipeline and various multimedia devices in the Broadcom BCM2712 SoC used
on Raspberry Pi 5.

The driver uses the generic_pt framework to manage the 2-level page
tables. It also provides support for the centralized L2 TLB (IOMMUC),
which is shared across the SoC's IOMMU instances and must be flushed
when modifying or unmapping page table entries.

Adapted from Raspberry Pi's downstream bcm2712-iommu driver
(original author Nick Hollinghurst).

Reviewed-by: Jason Gunthorpe <jgg@nvidia.com>
Signed-off-by: Daniel Drake <dan@reactivated.net>
---
 MAINTAINERS                         |  12 +
 drivers/iommu/Kconfig               |  15 +
 drivers/iommu/Makefile              |   1 +
 drivers/iommu/bcm2712-iommu-cache.c |  84 ++++++
 drivers/iommu/bcm2712-iommu-cache.h |   9 +
 drivers/iommu/bcm2712-iommu.c       | 550 ++++++++++++++++++++++++++++++++++++
 6 files changed, 671 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 6215fcb07770..032401692efb 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -5166,6 +5166,18 @@ N:	bcm2712
 N:	bcm283*
 N:	raspberrypi
 
+BROADCOM BCM2712 IOMMU DRIVER
+M:	Daniel Drake <dan@reactivated.net>
+M:	Florian Fainelli <florian.fainelli@broadcom.com>
+M:	Jim Quinlan <james.quinlan@broadcom.com>
+R:	Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>
+L:	iommu@lists.linux.dev
+L:	linux-rpi-kernel@lists.infradead.org (moderated for non-subscribers)
+S:	Maintained
+F:	Documentation/devicetree/bindings/iommu/brcm,bcm2712-iommu*
+F:	drivers/iommu/bcm2712-iommu*
+F:	drivers/iommu/generic_pt/fmt/*bcm2712*
+
 BROADCOM BCM281XX/BCM11XXX/BCM216XX ARM ARCHITECTURE
 M:	Florian Fainelli <florian.fainelli@broadcom.com>
 M:	Ray Jui <rjui@broadcom.com>
diff --git a/drivers/iommu/Kconfig b/drivers/iommu/Kconfig
index 6e07bd69467a..de85fba9c0a7 100644
--- a/drivers/iommu/Kconfig
+++ b/drivers/iommu/Kconfig
@@ -386,6 +386,21 @@ config VSI_IOMMU
 	  Say Y here if you want to use this IOMMU in front of these
 	  hardware blocks.
 
+config BCM2712_IOMMU
+	bool "BCM2712 IOMMU driver"
+	depends on (ARCH_BCM2835 && ARM64) || COMPILE_TEST
+	select IOMMU_API
+	select GENERIC_PT
+	select IOMMU_PT
+	select IOMMU_PT_BCM2712
+	help
+	  Support for IOMMU on BCM2712 SoC. This IOMMU can be used by the
+	  display controller and various multimedia devices to perform
+	  efficient memory management.
+
+	  Say Y here if you want to use this IOMMU in front of these
+	  hardware blocks.
+
 config IOMMU_DEBUG_PAGEALLOC
 	bool "Debug IOMMU mappings against page allocations"
 	depends on DEBUG_PAGEALLOC && IOMMU_API && PAGE_EXTENSION
diff --git a/drivers/iommu/Makefile b/drivers/iommu/Makefile
index 2f05725eaab1..29a26d2a3af1 100644
--- a/drivers/iommu/Makefile
+++ b/drivers/iommu/Makefile
@@ -37,4 +37,5 @@ obj-$(CONFIG_IOMMU_IOPF) += io-pgfault.o
 obj-$(CONFIG_SPRD_IOMMU) += sprd-iommu.o
 obj-$(CONFIG_APPLE_DART) += apple-dart.o
 obj-$(CONFIG_VSI_IOMMU) += vsi-iommu.o
+obj-$(CONFIG_BCM2712_IOMMU) += bcm2712-iommu.o bcm2712-iommu-cache.o
 obj-$(CONFIG_IOMMU_DEBUG_PAGEALLOC) += iommu-debug-pagealloc.o
diff --git a/drivers/iommu/bcm2712-iommu-cache.c b/drivers/iommu/bcm2712-iommu-cache.c
new file mode 100644
index 000000000000..8ed436943b83
--- /dev/null
+++ b/drivers/iommu/bcm2712-iommu-cache.c
@@ -0,0 +1,84 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * IOMMU driver for BCM2712 TLB cache
+ *
+ * Copyright (c) 2023 Raspberry Pi Ltd.
+ * Copyright (c) 2026 Daniel Drake
+ *
+ * The BCM2712 IOMMUC is a centralized TLB which accelerates address translation
+ * across the SoC's IOMMU devices. If an address mapping is not found in the
+ * IOMMU's local TLB cache, then this IOMMUC is consulted. The IOMMUC must be
+ * explicitly invalidated when modifying or unmapping IOMMU page tables.
+ */
+
+#include <linux/bits.h>
+#include <linux/cleanup.h>
+#include <linux/err.h>
+#include <linux/iopoll.h>
+#include <linux/of_platform.h>
+#include <linux/platform_device.h>
+#include <linux/spinlock.h>
+
+#include "bcm2712-iommu-cache.h"
+
+struct bcm2712_iommu_cache {
+	struct device *dev;
+	spinlock_t hw_lock;
+	void __iomem *reg_base;
+};
+
+#define MMUC_CONTROL_ENABLE   BIT(0)
+#define MMUC_CONTROL_FLUSH    BIT(1)
+#define MMUC_CONTROL_FLUSHING BIT(2)
+
+void bcm2712_iommu_cache_flush(struct bcm2712_iommu_cache *cache)
+{
+	u32 val;
+	int ret;
+
+	scoped_guard(spinlock_irqsave, &cache->hw_lock) {
+		writel(MMUC_CONTROL_ENABLE | MMUC_CONTROL_FLUSH,
+		       cache->reg_base);
+
+		ret = readl_poll_timeout_atomic(cache->reg_base, val,
+						!(val & MMUC_CONTROL_FLUSHING),
+						0, 50);
+	}
+
+	if (ret)
+		dev_err_ratelimited(cache->dev, "cache flush timed out\n");
+}
+
+static int bcm2712_iommu_cache_probe(struct platform_device *pdev)
+{
+	struct bcm2712_iommu_cache *cache;
+
+	cache = devm_kzalloc(&pdev->dev, sizeof(*cache), GFP_KERNEL);
+	if (!cache)
+		return -ENOMEM;
+
+	cache->dev = &pdev->dev;
+	spin_lock_init(&cache->hw_lock);
+
+	cache->reg_base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(cache->reg_base))
+		return PTR_ERR(cache->reg_base);
+
+	platform_set_drvdata(pdev, cache);
+	return 0;
+}
+
+static const struct of_device_id bcm2712_iommu_cache_of_match[] = {
+	{ .compatible = "brcm,bcm2712-iommuc" },
+	{ /* sentinel */ },
+};
+
+static struct platform_driver bcm2712_iommu_cache_driver = {
+	.probe = bcm2712_iommu_cache_probe,
+	.driver = {
+		.name = "bcm2712-iommu-cache",
+		.of_match_table = bcm2712_iommu_cache_of_match,
+		.suppress_bind_attrs = true,
+	},
+};
+builtin_platform_driver(bcm2712_iommu_cache_driver);
diff --git a/drivers/iommu/bcm2712-iommu-cache.h b/drivers/iommu/bcm2712-iommu-cache.h
new file mode 100644
index 000000000000..d2f7851831cc
--- /dev/null
+++ b/drivers/iommu/bcm2712-iommu-cache.h
@@ -0,0 +1,9 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+#ifndef _BCM2712_IOMMU_CACHE_H
+#define _BCM2712_IOMMU_CACHE_H
+
+struct bcm2712_iommu_cache;
+
+void bcm2712_iommu_cache_flush(struct bcm2712_iommu_cache *cache);
+
+#endif
diff --git a/drivers/iommu/bcm2712-iommu.c b/drivers/iommu/bcm2712-iommu.c
new file mode 100644
index 000000000000..301855475c88
--- /dev/null
+++ b/drivers/iommu/bcm2712-iommu.c
@@ -0,0 +1,550 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * IOMMU driver for Broadcom BCM2712
+ *
+ * Copyright (c) 2023-2025 Raspberry Pi Ltd.
+ * Copyright (c) 2026 Daniel Drake
+ *
+ * Each BCM2712 IOMMU has multiple devices hardwired into it, whose
+ * DMA transactions all route through the IOMMU. There is no stream ID tagging
+ * or any other kind of segmentation to differentiate between requests from
+ * different devices. It is also not possible to toggle a specific device
+ * between iommu-mapped and bypass modes.
+ *
+ * The hardware supports the simultaneous configuration of a bypass window
+ * (where memory accesses operate in identity mode) and a translation aperture
+ * (supporting page mapping). While combining these two would allow for
+ * GART-like operation, this driver's paging domain implementation configures
+ * only the translation aperture (starting at IOVA 0) offering a degree of
+ * memory protection.
+ *
+ * The page table format is a two-level format handled by generic_pt/bcm2712.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/cleanup.h>
+#include <linux/dma-mapping.h>
+#include <linux/err.h>
+#include <linux/iommu.h>
+#include <linux/iopoll.h>
+#include <linux/of_platform.h>
+#include <linux/platform_device.h>
+#include <linux/spinlock.h>
+#include <linux/sizes.h>
+#include <linux/generic_pt/iommu.h>
+
+#include "bcm2712-iommu-cache.h"
+#include "dma-iommu.h"
+#include "iommu-pages.h"
+
+/* BCM2712 IOMMU is organized around 4Kbyte pages */
+#define IOMMU_PAGE_SHIFT       12
+#define IOMMU_PAGE_SIZE        (1ul << IOMMU_PAGE_SHIFT)
+/* A PTE is 4 bytes */
+#define PTE_SIZE_SHIFT         2
+/* L1/L2 table sizing (IOMMU hardware pages): 1024 entries per page */
+#define PTES_PER_IOPG_SHIFT    (IOMMU_PAGE_SHIFT - PTE_SIZE_SHIFT)
+
+#define MMMU_CTRL_OFFSET                       0x00
+#define MMMU_CTRL_CAP_EXCEEDED                 BIT(27)
+#define MMMU_CTRL_CAP_EXCEEDED_ABORT_EN        BIT(26)
+#define MMMU_CTRL_CAP_EXCEEDED_INT_EN          BIT(25)
+#define MMMU_CTRL_CAP_EXCEEDED_EXCEPTION_EN    BIT(24)
+#define MMMU_CTRL_PT_INVALID                   BIT(20)
+#define MMMU_CTRL_PT_INVALID_ABORT_EN          BIT(19)
+#define MMMU_CTRL_PT_INVALID_INT_EN            BIT(18)
+#define MMMU_CTRL_PT_INVALID_EXCEPTION_EN      BIT(17)
+#define MMMU_CTRL_PT_INVALID_EN                BIT(16)
+#define MMMU_CTRL_WRITE_VIOLATION              BIT(12)
+#define MMMU_CTRL_WRITE_VIOLATION_ABORT_EN     BIT(11)
+#define MMMU_CTRL_WRITE_VIOLATION_INT_EN       BIT(10)
+#define MMMU_CTRL_WRITE_VIOLATION_EXCEPTION_EN BIT(9)
+#define MMMU_CTRL_BYPASS                       BIT(8)
+#define MMMU_CTRL_TLB_CLEARING                 BIT(7)
+#define MMMU_CTRL_STATS_CLEAR                  BIT(3)
+#define MMMU_CTRL_TLB_CLEAR                    BIT(2)
+#define MMMU_CTRL_STATS_ENABLE                 BIT(1)
+#define MMMU_CTRL_ENABLE                       BIT(0)
+
+#define MMMU_CTRL_OPERATING_FLAGS (\
+	MMMU_CTRL_CAP_EXCEEDED_ABORT_EN    | \
+	MMMU_CTRL_PT_INVALID_ABORT_EN      | \
+	MMMU_CTRL_PT_INVALID_EN            | \
+	MMMU_CTRL_WRITE_VIOLATION_ABORT_EN | \
+	MMMU_CTRL_STATS_ENABLE             | \
+	MMMU_CTRL_ENABLE)
+
+#define MMMU_PT_PA_BASE_OFFSET                 0x04
+
+#define MMMU_ADDR_CAP_OFFSET                   0x14
+#define MMMU_ADDR_CAP_ENABLE                   BIT(31)
+#define ADDR_CAP_SHIFT                         ilog2(SZ_256M)
+
+#define MMMU_SHOOT_DOWN_OFFSET                 0x18
+#define MMMU_SHOOT_DOWN_SHOOTING               BIT(31)
+#define MMMU_SHOOT_DOWN_SHOOT                  BIT(30)
+
+#define MMMU_BYPASS_START_OFFSET               0x1c
+#define MMMU_BYPASS_START_ENABLE               BIT(31)
+
+#define MMMU_BYPASS_END_OFFSET                 0x20
+#define MMMU_BYPASS_END_ENABLE                 BIT(31)
+
+#define MMMU_MISC_OFFSET                       0x24
+#define MMMU_MISC_SINGLE_TABLE                 BIT(31)
+
+#define MMMU_ILLEGAL_ADR_OFFSET                0x30
+#define MMMU_ILLEGAL_ADR_ENABLE                BIT(31)
+
+#define MMMU_DEBUG_INFO_OFFSET                 0x38
+#define MMMU_DEBUG_INFO_VERSION_MASK           0x0000000Fu
+#define MMMU_DEBUG_INFO_VA_WIDTH_MASK          0x000000F0u
+#define MMMU_DEBUG_INFO_PA_WIDTH_MASK          0x00000F00u
+#define MMMU_DEBUG_INFO_BIGPAGE_WIDTH_MASK     0x000FF000u
+#define MMMU_DEBUG_INFO_SUPERPAGE_WIDTH_MASK   0x0FF00000u
+#define MMMU_DEBUG_INFO_BYPASS_4M              BIT(28)
+#define MMMU_DEBUG_INFO_BYPASS                 BIT(29)
+
+struct bcm2712_iommu {
+	struct device *dev;
+	struct iommu_device iommu;
+	struct bcm2712_iommu_domain *domain;
+	struct bcm2712_iommu_cache *cache;
+	void __iomem *reg_base;
+	spinlock_t hw_lock;
+	size_t bigpage_size;
+	size_t superpage_size;
+};
+
+struct bcm2712_iommu_domain {
+	union {
+		struct iommu_domain base;
+		struct pt_iommu_bcm2712 pt;
+	};
+	struct bcm2712_iommu *mmu;
+	void *default_page;
+};
+
+static inline void bcm2712_iommu_writel(struct bcm2712_iommu *mmu,
+					unsigned int offset, u32 val)
+{
+	writel(val, mmu->reg_base + offset);
+}
+
+static inline u32 bcm2712_iommu_readl(struct bcm2712_iommu *mmu,
+				      unsigned int offset)
+{
+	return readl(mmu->reg_base + offset);
+}
+
+static struct bcm2712_iommu_domain *
+to_bcm2712_domain(struct iommu_domain *domain)
+{
+	return container_of(domain, struct bcm2712_iommu_domain, base);
+}
+
+static void bcm2712_iommu_init(struct bcm2712_iommu *mmu)
+{
+	unsigned int bigpage_width, superpage_width;
+	u32 u = bcm2712_iommu_readl(mmu, MMMU_DEBUG_INFO_OFFSET);
+	u32 pa_width = FIELD_GET(MMMU_DEBUG_INFO_PA_WIDTH_MASK, u);
+
+	dev_dbg(mmu->dev, "DEBUG_INFO = 0x%08x\n", u);
+	WARN_ON(FIELD_GET(MMMU_DEBUG_INFO_VERSION_MASK, u) < 4 ||
+		FIELD_GET(MMMU_DEBUG_INFO_VA_WIDTH_MASK, u) < 6 ||
+		pa_width < 6 || !(u & MMMU_DEBUG_INFO_BYPASS));
+
+	dma_set_mask_and_coherent(mmu->dev, DMA_BIT_MASK(pa_width + 30u));
+
+	bigpage_width = FIELD_GET(MMMU_DEBUG_INFO_BIGPAGE_WIDTH_MASK, u);
+	if (bigpage_width)
+		mmu->bigpage_size = IOMMU_PAGE_SIZE << bigpage_width;
+
+	superpage_width = FIELD_GET(MMMU_DEBUG_INFO_SUPERPAGE_WIDTH_MASK, u);
+	if (superpage_width)
+		mmu->superpage_size = IOMMU_PAGE_SIZE << superpage_width;
+
+	/* Disable MMU and clear sticky flags */
+	bcm2712_iommu_writel(mmu, MMMU_CTRL_OFFSET,
+			     MMMU_CTRL_CAP_EXCEEDED | MMMU_CTRL_PT_INVALID |
+			     MMMU_CTRL_WRITE_VIOLATION |
+			     MMMU_CTRL_STATS_CLEAR);
+
+	/* Put MMU into 2-level mode */
+	bcm2712_iommu_writel(mmu, MMMU_MISC_OFFSET,
+			     bcm2712_iommu_readl(mmu, MMMU_MISC_OFFSET) &
+				     ~MMMU_MISC_SINGLE_TABLE);
+}
+
+static int bcm2712_iommu_identity_attach(struct iommu_domain *identity_domain,
+					 struct device *dev,
+					 struct iommu_domain *old)
+{
+	struct bcm2712_iommu *mmu = dev_iommu_priv_get(dev);
+
+	guard(spinlock_irqsave)(&mmu->hw_lock);
+	bcm2712_iommu_writel(mmu, MMMU_CTRL_OFFSET, 0);
+	mmu->domain = NULL;
+
+	return 0;
+}
+
+static struct iommu_domain bcm2712_identity_domain = {
+	.type = IOMMU_DOMAIN_IDENTITY,
+	.ops = &(const struct iommu_domain_ops) {
+		.attach_dev = bcm2712_iommu_identity_attach,
+	},
+};
+
+static int bcm2712_iommu_clear_and_enable(struct bcm2712_iommu *mmu)
+	__must_hold(&mmu->hw_lock)
+{
+	u32 val;
+
+	bcm2712_iommu_cache_flush(mmu->cache);
+	bcm2712_iommu_writel(mmu, MMMU_CTRL_OFFSET,
+			     MMMU_CTRL_OPERATING_FLAGS | MMMU_CTRL_TLB_CLEAR);
+	return readl_poll_timeout_atomic(mmu->reg_base + MMMU_CTRL_OFFSET, val,
+					 !(val & MMMU_CTRL_TLB_CLEARING), 0,
+					 50);
+}
+
+
+static int bcm2712_iommu_attach_dev(struct iommu_domain *domain,
+				    struct device *dev,
+				    struct iommu_domain *old)
+{
+	struct bcm2712_iommu *mmu = dev_iommu_priv_get(dev);
+	struct bcm2712_iommu_domain *mydomain = to_bcm2712_domain(domain);
+	struct pt_iommu_bcm2712_hw_info info;
+	u32 default_page_pfn;
+	int ret = 0;
+
+	/* all attached devices must belong to the same IOMMU instance */
+	if (mydomain->mmu != mmu)
+		return -EINVAL;
+
+	scoped_guard(spinlock_irqsave, &mmu->hw_lock) {
+		if (mmu->domain == mydomain)
+			break;
+
+		/* Configure translation aperture */
+		bcm2712_iommu_writel(mmu, MMMU_ADDR_CAP_OFFSET,
+				     MMMU_ADDR_CAP_ENABLE |
+					     (domain->geometry.aperture_end >>
+					      ADDR_CAP_SHIFT));
+
+		/*
+		 * When the IOMMU handles a request, it adds the
+		 * PT_PA_BASE_OFFSET to (IOVA>>32) to calculate the PFN of the
+		 * corresponding L1 directory page.
+		 * IOVA bits [31:22] are then used to fetch the L1 descriptor
+		 * within (which in turn points to the L2 table).
+		 * This clever logic would allow for a L1 table larger than 4kb
+		 * (and hence a larger aperture).
+		 */
+		pt_iommu_bcm2712_hw_info(&mydomain->pt, &info);
+		bcm2712_iommu_writel(mmu, MMMU_PT_PA_BASE_OFFSET,
+				     info.pt_base >> IOMMU_PAGE_SHIFT);
+
+		/* Disable bypass window */
+		bcm2712_iommu_writel(mmu, MMMU_BYPASS_START_OFFSET, 0);
+		bcm2712_iommu_writel(mmu, MMMU_BYPASS_END_OFFSET, 0);
+
+		/*
+		 * A default (error) page is used to catch illegal reads/writes.
+		 */
+		default_page_pfn = virt_to_phys(mydomain->default_page) >>
+				   IOMMU_PAGE_SHIFT;
+		bcm2712_iommu_writel(mmu, MMMU_ILLEGAL_ADR_OFFSET,
+				     MMMU_ILLEGAL_ADR_ENABLE |
+					     default_page_pfn);
+
+		ret = bcm2712_iommu_clear_and_enable(mmu);
+		if (ret) {
+			bcm2712_iommu_writel(mmu, MMMU_CTRL_OFFSET, 0);
+			mmu->domain = NULL;
+			break;
+		}
+
+		mmu->domain = mydomain;
+	}
+
+	if (ret)
+		dev_err_ratelimited(mmu->dev,
+				    "TLB clear timed out during attach\n");
+
+	return ret;
+}
+
+static int bcm2712_iommu_shootdown_range(struct bcm2712_iommu *mmu,
+					 unsigned long iova, size_t size)
+	__must_hold(&mmu->hw_lock)
+{
+	unsigned long start_pfn = iova >> IOMMU_PAGE_SHIFT;
+	unsigned long end_pfn = (iova + size - 1) >> IOMMU_PAGE_SHIFT;
+	unsigned long pfn;
+	u32 val;
+	int ret;
+
+	/* Shootdown register deals with 4 pages at a time */
+	for (pfn = round_down(start_pfn, 4); pfn <= end_pfn; pfn += 4) {
+		bcm2712_iommu_writel(mmu, MMMU_SHOOT_DOWN_OFFSET,
+				     MMMU_SHOOT_DOWN_SHOOT | pfn);
+		ret = readl_poll_timeout_atomic(
+			mmu->reg_base + MMMU_SHOOT_DOWN_OFFSET, val,
+			!(val & MMMU_SHOOT_DOWN_SHOOTING), 0, 50);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int bcm2712_iommu_sync_range(struct iommu_domain *domain,
+				    unsigned long iova, size_t size)
+{
+	struct bcm2712_iommu_domain *mydomain = to_bcm2712_domain(domain);
+	struct bcm2712_iommu *mmu = mydomain->mmu;
+	int ret = 0;
+
+	if (!size)
+		return 0;
+
+	scoped_guard(spinlock_irqsave, &mmu->hw_lock) {
+		if (mmu->domain != mydomain)
+			return 0;
+
+		/* If invalidating more than 1MB, just do a full TLB clear */
+		if (size >= SZ_1M) {
+			ret = bcm2712_iommu_clear_and_enable(mmu);
+		} else {
+			bcm2712_iommu_cache_flush(mmu->cache);
+			ret = bcm2712_iommu_shootdown_range(mmu, iova, size);
+		}
+	}
+
+	if (ret)
+		dev_err_ratelimited(mmu->dev,
+				    "TLB sync timed out (size=%#zx)\n", size);
+
+	return ret;
+}
+
+static void bcm2712_iommu_sync(struct iommu_domain *domain,
+			       struct iommu_iotlb_gather *gather)
+{
+	bcm2712_iommu_sync_range(domain, gather->start,
+				 gather->end - gather->start + 1);
+	iommu_put_pages_list(&gather->freelist);
+}
+
+static int bcm2712_iommu_sync_map(struct iommu_domain *domain,
+				  unsigned long iova, size_t size)
+{
+	return bcm2712_iommu_sync_range(domain, iova, size);
+}
+
+static void bcm2712_iommu_sync_all(struct iommu_domain *domain)
+{
+	size_t aperture_size = domain->geometry.aperture_end -
+			       domain->geometry.aperture_start + 1;
+
+	bcm2712_iommu_sync_range(domain, domain->geometry.aperture_start,
+				 aperture_size);
+}
+
+static void bcm2712_iommu_domain_free(struct iommu_domain *domain)
+{
+	struct bcm2712_iommu_domain *mydomain = to_bcm2712_domain(domain);
+	struct bcm2712_iommu *mmu = mydomain->mmu;
+
+	scoped_guard(spinlock_irqsave, &mmu->hw_lock) {
+		if (mmu->domain == mydomain) {
+			bcm2712_iommu_writel(mmu, MMMU_CTRL_OFFSET, 0);
+			mmu->domain = NULL;
+		}
+	}
+
+	pt_iommu_deinit(&mydomain->pt.iommu);
+	if (mydomain->default_page)
+		iommu_free_pages(mydomain->default_page);
+	kfree(mydomain);
+}
+
+static const struct iommu_domain_ops bcm2712_paging_domain_ops = {
+	IOMMU_PT_DOMAIN_OPS(bcm2712),
+	.attach_dev	 = bcm2712_iommu_attach_dev,
+	.iotlb_sync      = bcm2712_iommu_sync,
+	.iotlb_sync_map  = bcm2712_iommu_sync_map,
+	.flush_iotlb_all = bcm2712_iommu_sync_all,
+	.free		 = bcm2712_iommu_domain_free,
+};
+
+static struct iommu_domain *bcm2712_iommu_domain_alloc(struct device *dev)
+{
+	struct bcm2712_iommu *mmu = dev_iommu_priv_get(dev);
+	struct bcm2712_iommu_domain *domain;
+	struct pt_iommu_bcm2712_cfg cfg = {};
+	int ret;
+
+	domain = kzalloc_obj(*domain);
+	if (!domain)
+		return NULL;
+
+	domain->mmu = mmu;
+	domain->pt.iommu.iommu_device = mmu->dev;
+	cfg.common.features = BIT(PT_FEAT_DMA_INCOHERENT);
+
+	/* Bigpage and superpage sizes are typically 64K and 1M, but may vary */
+	if (mmu->bigpage_size)
+		cfg.bigpage_lg2 = ilog2(mmu->bigpage_size);
+	if (mmu->superpage_size)
+		cfg.superpage_lg2 = ilog2(mmu->superpage_size);
+
+	/* 2-level format: 10-bit L1 + 10-bit L2 + 12-bit page offset */
+	cfg.common.hw_max_vasz_lg2 =
+		(2 * PTES_PER_IOPG_SHIFT) + IOMMU_PAGE_SHIFT;
+
+	/* PTEs encode a 25-bit output address PFN */
+	cfg.common.hw_max_oasz_lg2 = 25 + IOMMU_PAGE_SHIFT;
+
+	ret = pt_iommu_bcm2712_init(&domain->pt, &cfg, GFP_KERNEL);
+	if (ret)
+		goto err;
+
+	/* Set up a default (error) page used to catch illegal reads/writes */
+	domain->default_page = iommu_alloc_pages_sz(GFP_KERNEL, PAGE_SIZE);
+	if (!domain->default_page)
+		goto err;
+
+	domain->base.ops = &bcm2712_paging_domain_ops;
+	return &domain->base;
+
+err:
+	bcm2712_iommu_domain_free(&domain->base);
+	return NULL;
+}
+
+static struct bcm2712_iommu *
+bcm2712_iommu_get_by_fwnode(struct fwnode_handle *fwnode)
+{
+	struct device *dev __free(put_device) =
+		bus_find_device_by_fwnode(&platform_bus_type, fwnode);
+
+	return dev ? dev_get_drvdata(dev) : NULL;
+}
+
+static struct iommu_device *bcm2712_iommu_probe_device(struct device *dev)
+{
+	struct iommu_fwspec *fwspec = dev_iommu_fwspec_get(dev);
+	struct bcm2712_iommu *mmu;
+
+	if (!fwspec || !fwspec->iommu_fwnode)
+		return ERR_PTR(-ENODEV);
+
+	mmu = bcm2712_iommu_get_by_fwnode(fwspec->iommu_fwnode);
+	if (!mmu)
+		return ERR_PTR(-ENODEV);
+
+	dev_iommu_priv_set(dev, mmu);
+
+	return &mmu->iommu;
+}
+
+static int bcm2712_iommu_of_xlate(struct device *dev,
+				  const struct of_phandle_args *args)
+{
+	return iommu_fwspec_add_ids(dev, args->args, 0);
+}
+
+static const struct iommu_ops bcm2712_iommu_ops = {
+	.identity_domain     = &bcm2712_identity_domain,
+	.domain_alloc_paging = bcm2712_iommu_domain_alloc,
+	.probe_device        = bcm2712_iommu_probe_device,
+	.device_group        = generic_single_device_group,
+	.get_resv_regions    = iommu_dma_get_resv_regions,
+	.of_xlate            = bcm2712_iommu_of_xlate,
+};
+
+static const struct of_device_id bcm2712_iommu_of_match[] = {
+	{ .compatible = "brcm,bcm2712-iommu" },
+	{ /* sentinel */ }
+};
+
+static int bcm2712_iommu_init_cache(struct bcm2712_iommu *mmu,
+				    struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+
+	struct device_node *cache_np __free(device_node) =
+		of_parse_phandle(dev->of_node, "brcm,iommu-cache", 0);
+	if (!cache_np)
+		return dev_err_probe(dev, -ENOENT,
+				     "missing brcm,iommu-cache property\n");
+
+	struct platform_device *cache_pdev __free(platform_device_put) =
+		of_find_device_by_node(cache_np);
+	if (!cache_pdev)
+		return dev_err_probe(dev, -EPROBE_DEFER,
+				     "waiting for cache device\n");
+
+	mmu->cache = platform_get_drvdata(cache_pdev);
+	if (!mmu->cache)
+		return dev_err_probe(dev, -EPROBE_DEFER,
+				     "waiting for cache driver probe\n");
+
+	return 0;
+}
+
+static int bcm2712_iommu_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct bcm2712_iommu *mmu;
+	int ret;
+
+	mmu = devm_kzalloc(dev, sizeof(*mmu), GFP_KERNEL);
+	if (!mmu)
+		return -ENOMEM;
+
+	mmu->dev = dev;
+	spin_lock_init(&mmu->hw_lock);
+
+	mmu->reg_base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(mmu->reg_base))
+		return PTR_ERR(mmu->reg_base);
+
+	ret = bcm2712_iommu_init_cache(mmu, pdev);
+	if (ret)
+		return ret;
+
+	platform_set_drvdata(pdev, mmu);
+	bcm2712_iommu_init(mmu);
+
+	ret = iommu_device_sysfs_add(&mmu->iommu, dev, NULL, "%s",
+				     dev_name(dev));
+	if (ret)
+		return ret;
+
+	ret = iommu_device_register(&mmu->iommu, &bcm2712_iommu_ops, dev);
+	if (ret) {
+		iommu_device_sysfs_remove(&mmu->iommu);
+		return ret;
+	}
+
+	return 0;
+}
+
+static struct platform_driver bcm2712_iommu_driver = {
+	.driver	= {
+		.name		     = "bcm2712-iommu",
+		.of_match_table	     = bcm2712_iommu_of_match,
+		.suppress_bind_attrs = true,
+	},
+	.probe	= bcm2712_iommu_probe,
+};
+builtin_platform_driver(bcm2712_iommu_driver);
+
+MODULE_LICENSE("GPL");
+MODULE_AUTHOR("Daniel Drake <dan@reactivated.net>");
+MODULE_DESCRIPTION("Broadcom BCM2712 IOMMU driver");

-- 
2.55.0

