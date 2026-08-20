From: Markuss Broks <markuss.broks@gmail.com>
Date: Thu, 20 Aug 2026 22:12:05 +0300
Subject: [PATCH 1/4] iommu/exynos: detect SysMMUs without BLOCK mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-exynos-iommu-fixes-v1-1-6bbcd673bb15@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787253126; l=1479;
 i=markuss.broks@gmail.com; s=20260803; h=from:subject:message-id;
 bh=mOr89jBc1c/3DemuQ56Wmn7lSeAvv7DoZx+sJdo6D2U=;
 b=6nEHQ0bpJYt2EXU7sB+pTrh8uM4qqZlYciy0rMZ3uIIw056/blzZCqnEYUw/BlDczramgZk8s
 D+ueRGcYxxyB9FQi32Q0zQlCTS+8SQDf1EHZSuOANkujC0hVsTMRojF
X-Developer-Key: i=markuss.broks@gmail.com; a=ed25519;
 pk=oKzGUTm30BCDqinRMpiHQqByOx1mp2mwmhg80Mv7Zg4=
X-Endpoint-Received: by B4 Relay for markuss.broks@gmail.com/20260803 with auth_id=911
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Newer SysMMU instances may not implement BLOCK mode: writing CTRL_BLOCK
does not stop translation, and MMU_STATUS never reports a blocked
state.  The hardware advertises this in CAPA1 bit 15, which the vendor
driver reads as MMU_CAPA1_NO_BLOCK_MODE; the SysMMUs on Exynos8835
are such instances.

Signed-off-by: Markuss Broks <markuss.broks@gmail.com>
---
 drivers/iommu/exynos-iommu.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/iommu/exynos-iommu.c b/drivers/iommu/exynos-iommu.c
index 874d05f4b396..0319da9fd831 100644
--- a/drivers/iommu/exynos-iommu.c
+++ b/drivers/iommu/exynos-iommu.c
@@ -143,6 +143,7 @@ static u32 lv2ent_offset(sysmmu_iova_t iova)
 #define CTRL_VM_FAULT_MODE_STALL	BIT(3)
 #define CAPA0_CAPA1_EXIST		BIT(11)
 #define CAPA1_VCR_ENABLED		BIT(14)
+#define CAPA1_NO_BLOCK_MODE		BIT(15)
 
 /* common registers */
 #define REG_MMU_CTRL		0x000
@@ -306,6 +307,7 @@ struct sysmmu_drvdata {
 
 	/* v7 fields */
 	bool has_vcr;			/* virtual machine control register */
+	bool no_block;			/* BLOCK mode not implemented */
 };
 
 #define SYSMMU_REG(data, reg) ((data)->sfrbase + (data)->variant->reg)
@@ -511,6 +513,7 @@ static void __sysmmu_get_vcr(struct sysmmu_drvdata *data)
 	u32 capa1 = readl(data->sfrbase + REG_V7_CAPA1);
 
 	data->has_vcr = capa1 & CAPA1_VCR_ENABLED;
+	data->no_block = capa1 & CAPA1_NO_BLOCK_MODE;
 }
 
 static void __sysmmu_get_version(struct sysmmu_drvdata *data)

-- 
2.55.0

