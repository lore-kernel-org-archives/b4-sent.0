From: Markuss Broks <markuss.broks@gmail.com>
Date: Thu, 20 Aug 2026 22:12:06 +0300
Subject: [PATCH 2/4] iommu/exynos: fix the enable sequence for no-block
 SysMMUs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-exynos-iommu-fixes-v1-2-6bbcd673bb15@gmail.com>
References: <20260820-exynos-iommu-fixes-v1-0-6bbcd673bb15@gmail.com>
In-Reply-To: <20260820-exynos-iommu-fixes-v1-0-6bbcd673bb15@gmail.com>
To: Marek Szyprowski <m.szyprowski@samsung.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Markuss Broks <markuss.broks@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787253126; l=1548;
 i=markuss.broks@gmail.com; s=20260803; h=from:subject:message-id;
 bh=K4btCYT7ezjlx6H4fapioD7ShFs/jWpvk5zQdk+w7+8=;
 b=eWfEM667DBzpg9cwP+89xFePRCc5Xqc6CdWKOSqJyauS4P76wUs+9H76z2L5zWlaTjSRxLcuD
 8bTDvt94nd4AEmQKh38tilyh8prRWFXzKOGzlp4YWDUx7VO7+47Egjo
X-Developer-Key: i=markuss.broks@gmail.com; a=ed25519;
 pk=oKzGUTm30BCDqinRMpiHQqByOx1mp2mwmhg80Mv7Zg4=
X-Endpoint-Received: by B4 Relay for markuss.broks@gmail.com/20260803 with auth_id=911
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__sysmmu_enable() writes CTRL_BLOCK before programming CFG, the page
table base and the VM registers. CTRL_BLOCK has the enable bit set,
so on hardware without BLOCK mode this write immediately starts
translation with whatever FLPT base the registers hold: reset values
on the first enable, a stale page table on re-enable. A master that
is already emitting traffic at that point gets its transactions
translated through that garbage.

Keep the MMU disabled while it is being programmed on such hardware;
the final CTRL_ENABLE write then brings it up with a consistent
configuration in one step, which is also the same as the vendor driver
sequence.

Signed-off-by: Markuss Broks <markuss.broks@gmail.com>
---
 drivers/iommu/exynos-iommu.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/iommu/exynos-iommu.c b/drivers/iommu/exynos-iommu.c
index 0319da9fd831..a3a59d8a4cf1 100644
--- a/drivers/iommu/exynos-iommu.c
+++ b/drivers/iommu/exynos-iommu.c
@@ -655,7 +655,12 @@ static void __sysmmu_enable(struct sysmmu_drvdata *data)
 	__sysmmu_enable_clocks(data);
 
 	spin_lock_irqsave(&data->lock, flags);
-	writel(CTRL_BLOCK, data->sfrbase + REG_MMU_CTRL);
+	/*
+	 * On no-block hardware CTRL_BLOCK acts as a plain enable; keep the
+	 * MMU disabled until it is fully programmed.
+	 */
+	if (!data->no_block)
+		writel(CTRL_BLOCK, data->sfrbase + REG_MMU_CTRL);
 	__sysmmu_init_config(data);
 	__sysmmu_set_ptbase(data, data->pgtable);
 	__sysmmu_enable_vid(data);

-- 
2.55.0

