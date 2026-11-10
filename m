From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:02 +0000
Subject: [PATCH 1/5] iommu/rockchip: Don't walk a page table that a reset
 took away
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-iommu-rockchip-faults-v1-1-b1dda574dbb8@gmail.com>
References: <20261110-iommu-rockchip-faults-v1-0-b1dda574dbb8@gmail.com>
In-Reply-To: <20261110-iommu-rockchip-faults-v1-0-b1dda574dbb8@gmail.com>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Heiko Stuebner <heiko@sntech.de>, 
 Jeffy Chen <jeffy.chen@rock-chips.com>, Tomasz Figa <tfiga@chromium.org>
Cc: iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294661; l=2142;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ToGf1ObH2yGo1OMq0C57Okydv2han7Kmp00MrNYUTIY=;
 b=vqEYjTZrW9gc7C8emgS8qlnnnYJOcO/kFRASz5eG+NVNvNmDn9iyaZcTnYLO1wAW6NxEhyFRS
 44usyRyEK44ADSHnskRvuD6Y5MDdVSpbvtbO18Lq7pWquTbkZBnC2+D
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a page fault is reported, log_iova() reads the directory address
back from the MMU_DTE_ADDR register of the IOMMU and dereferences it
through phys_to_virt() to log the page table entries of the faulting
IOVA. The IOMMU of an RK3588 video decoder core is reset with the core:
by the core's own soft reset, which the hardware also does by itself
when a job times out, and by the core's AXI reset line. A fault taken
just before such a reset is handled with MMU_DTE_ADDR reading 0, and
log_iova() dereferences the physical address 4 * dte_index:

rk_iommu fdc38700.iommu: Page fault at 0x0000000013400200 of type read
Unable to handle kernel paging request at virtual address ffff600000000026
KASAN: probably wild-memory-access in range [...0130-...0137]
...
rk_iommu_irq+0x490/0x758

Only walk the directory if the register holds the address of memory, and
say that the page table was lost to a reset otherwise. The fault is
still acknowledged (zap, PAGE_FAULT_DONE, INT_CLEAR) as before.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/rockchip-iommu.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/iommu/rockchip-iommu.c b/drivers/iommu/rockchip-iommu.c
index 21af2f621c76..d40e2a26b7be 100644
--- a/drivers/iommu/rockchip-iommu.c
+++ b/drivers/iommu/rockchip-iommu.c
@@ -564,6 +564,17 @@ static void log_iova(struct rk_iommu *iommu, int index, dma_addr_t iova)
 	mmu_dte_addr = rk_iommu_read(base, RK_MMU_DTE_ADDR);
 	mmu_dte_addr_phys = iommu->rk_ops->pt_address(mmu_dte_addr);
 
+	/*
+	 * A reset of the master can reset its IOMMU too, between the fault and
+	 * this handler: DTE_ADDR then reads 0. Don't walk a directory that
+	 * isn't in memory; the caller still acknowledges the fault.
+	 */
+	if (!mmu_dte_addr || !pfn_valid(PHYS_PFN(mmu_dte_addr_phys))) {
+		dev_err(iommu->dev, "iova = %pad: fault while page table lost to reset (MMU_DTE_ADDR %#08x)\n",
+			&iova, mmu_dte_addr);
+		return;
+	}
+
 	dte_addr_phys = mmu_dte_addr_phys + (4 * dte_index);
 	dte_addr = phys_to_virt(dte_addr_phys);
 	dte = *dte_addr;

-- 
2.55.0

