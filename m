From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 06:05:17 +0000
Subject: [PATCH 1/2] iommu/sun50i: Don't report TLB prefetches of unmapped
 pages as faults
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-sun50i-iommu-prefetch-v1-1-43428e792ef6@gmail.com>
References: <20261110-sun50i-iommu-prefetch-v1-0-43428e792ef6@gmail.com>
In-Reply-To: <20261110-sun50i-iommu-prefetch-v1-0-43428e792ef6@gmail.com>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794290717; l=3445;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=yLoe2znns7P0Nlmxz+qhOed7bJSPIV/igjF81whNh8k=;
 b=7OZXIY/FUo+0ssrRcC5PVK4pgBVfPVCGENntFR4oujOO4H4aYnqjXuNlSiLoiimQAbHlN1eXl
 lGGYmF9UU/zDufC7H+GTKls3rXhjGA1bAxCCLdmCvb20Mn2ibWiwLtH
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With a display scanning out, the driver reports

  sun50i-iommu 30f0000.iommu: Page fault for 0x00000000fff00000 (master -1, dir rd)

on an H616 once when fbcon takes over the framebuffer (the first
scanout frame), and again, vsync-spaced, after TLB flushes while a video
decoder frees its buffers (every unmap flushes the whole TLB and PTW
cache in this driver). No device accesses that address: with the IOVA
allocator handing out addresses from the top down and size-aligned, the
3 MiB fbcon framebuffer of a 1024x768 mode is the first allocation and
lands at 0xffc00000-0xffefffff, and the top 1 MiB of the IOVA space
above it is never mapped. 0xfff00000 is the page after the end of the
framebuffer.

The walk that fails is the TLB prefetcher's, for the page after the one
the master is reading. The H616 user manual (3.12.6.50, 3.12.6.51) gives
the L1/L2 page table interrupt registers a bit 31 next to the per-master
bits for walks that no master started, and Allwinner's sunxi-iommu
driver treats a page table interrupt with bit 31 set as a prefetch of an
unmapped page ("It's OK to prefetch an invalid pagetable") and does not
report it. This driver masks the register to the master bits, gets no
bit, and reports ilog2(0) = -1 as the master.

Return early for a page table interrupt with the prefetch bit set and no
master bit: no master read anything and nothing is stalled, so there is
nothing to report, reset or zap. Print such walks with dev_dbg so they
can still be counted.

Fixes: 4100b8c229b3 ("iommu: Add Allwinner H6 IOMMU driver")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/sun50i-iommu.c | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/drivers/iommu/sun50i-iommu.c b/drivers/iommu/sun50i-iommu.c
index be3f1ce696ba..1b7a7f0d9b62 100644
--- a/drivers/iommu/sun50i-iommu.c
+++ b/drivers/iommu/sun50i-iommu.c
@@ -73,6 +73,15 @@
 #define IOMMU_INT_ERR_DATA_REG(i)	(0x150 + (i) * 4)
 #define IOMMU_L1PG_INT_REG		0x0180
 #define IOMMU_L2PG_INT_REG		0x0184
+/*
+ * Besides one bit per master, the L1/L2 page table interrupt registers
+ * have a bit for a page table walk that no master started: the TLB
+ * prefetcher's walk for the page after the one being accessed (H616 user
+ * manual 3.12.6.50 and 3.12.6.51, bit 31, "debug mode"; the vendor's
+ * sunxi-iommu treats a page table fault with this bit as a prefetch of an
+ * unmapped page and does not report it).
+ */
+#define IOMMU_PG_INT_PREFETCH			BIT(31)
 
 #define IOMMU_INT_INVALID_L2PG			BIT(17)
 #define IOMMU_INT_INVALID_L1PG			BIT(16)
@@ -891,6 +900,20 @@ static phys_addr_t sun50i_iommu_handle_pt_irq(struct sun50i_iommu *iommu,
 
 	iova = iommu_read(iommu, addr_reg);
 	blame = iommu_read(iommu, blame_reg);
+
+	/*
+	 * A walk the TLB prefetcher started for the page after the one a
+	 * master is reading fails whenever that next page is not mapped,
+	 * e.g. for the display engine scanning out a framebuffer that ends
+	 * at an unmapped IOVA. No master accessed the page and nothing is
+	 * stalled or cached, so there is nothing to report, reset or zap.
+	 */
+	if ((blame & IOMMU_PG_INT_PREFETCH) && !(blame & IOMMU_INT_MASTER_MASK)) {
+		dev_dbg_ratelimited(iommu->dev, "page table prefetch of unmapped %pad\n",
+				    &iova);
+		return iova;
+	}
+
 	master = ilog2(blame & IOMMU_INT_MASTER_MASK);
 
 	/*

-- 
2.55.0

