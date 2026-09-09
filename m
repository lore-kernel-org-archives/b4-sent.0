From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 09 Sep 2026 17:14:07 +0300
Subject: [PATCH 3/3] iommu/mediatek-v1: add mt6572 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-6572-iommu-v1-3-de261da09fb2@protonmail.com>
References: <20260909-6572-iommu-v1-0-de261da09fb2@protonmail.com>
In-Reply-To: <20260909-6572-iommu-v1-0-de261da09fb2@protonmail.com>
To: Yong Wu <yong.wu@mediatek.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: iommu@lists.linux.dev, linux-mediatek@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788963261; l=5880;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=Q9DENazAgwi3T2qykCPLy9Ktvy2jjfeMJUql9cSW4PY=;
 b=8+P8cpShisgwoJq0VZRjZTKZLtcBmRIMxKVIDut/OQ5H+DuS0IRCr8OkGmuFQBBntJL5u+eAM
 gSO9ctW66BlAB6sGh2wQRaETyPAsSTIhioXn1Gf/IaQj0ZaS0FCL5+k
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt6572 SoC utilizes an earlier version of the IOMMU, that shares the
same v1 architecture, but has minor hardware differences compared to
mt2701.

Introduce mtk_iommu_type to distinguish between mt2701 and mt6572
variant and apply the necessary logic.

Finally, add a platform data for the mt6572 SoC.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Based on my downstream findings, this change may also support mt6582 SoC,
but I don't have the hardware to test if it actually works.
---
 drivers/iommu/mtk_iommu_v1.c | 72 +++++++++++++++++++++++++++++++++-----------
 1 file changed, 55 insertions(+), 17 deletions(-)

diff --git a/drivers/iommu/mtk_iommu_v1.c b/drivers/iommu/mtk_iommu_v1.c
index 72355f41c36a..b6f547b100d1 100644
--- a/drivers/iommu/mtk_iommu_v1.c
+++ b/drivers/iommu/mtk_iommu_v1.c
@@ -7,6 +7,7 @@
  *
  * Based on driver/iommu/mtk_iommu.c
  */
+#include <linux/bitfield.h>
 #include <linux/bug.h>
 #include <linux/clk.h>
 #include <linux/component.h>
@@ -85,6 +86,13 @@ struct dma_iommu_mapping {
 #define F_DESC_NONSEC				BIT(3)
 #define MT2701_M4U_TF_LARB(TF)			(6 - (((TF) >> 13) & 0x7))
 #define MT2701_M4U_TF_PORT(TF)			(((TF) >> 8) & 0xF)
+
+#define MT6572_MMU_INT_ID_PORT_ID		GENMASK(12, 8)
+#define MT6572_MMU_INT_ID_LARB_ID		GENMASK(14, 13)
+
+#define MT6572_M4U_TF_PORT(TF)			FIELD_GET(MT6572_MMU_INT_ID_PORT_ID, TF)
+#define MT6572_M4U_TF_LARB(TF)			(FIELD_GET(MT6572_MMU_INT_ID_LARB_ID, TF) - 1)
+
 /* MTK generation one iommu HW only support 4K size mapping */
 #define MT2701_IOMMU_PAGE_SHIFT			12
 #define MT2701_IOMMU_PAGE_SIZE			(1UL << MT2701_IOMMU_PAGE_SHIFT)
@@ -96,6 +104,11 @@ struct dma_iommu_mapping {
  */
 #define M2701_IOMMU_PGT_SIZE			SZ_4M
 
+enum mtk_iommu_type {
+	MTK_IOMMU_MT6572,
+	MTK_IOMMU_V1,
+};
+
 struct mtk_iommu_v1_suspend_reg {
 	u32			standard_axi_mode;
 	u32			dcm_dis;
@@ -116,6 +129,8 @@ struct mtk_iommu_v1_data {
 	struct mtk_smi_larb_iommu	larb_imu[MTK_LARB_NR_MAX];
 
 	struct mtk_iommu_v1_suspend_reg	reg;
+
+	enum mtk_iommu_type type;
 };
 
 struct mtk_iommu_v1_domain {
@@ -170,8 +185,12 @@ static inline int mt2701_m4u_to_port(int id)
 
 static void mtk_iommu_v1_tlb_flush_all(struct mtk_iommu_v1_data *data)
 {
-	writel_relaxed(F_INVLD_EN1 | F_INVLD_EN0,
-			data->base + REG_MMU_INV_SEL);
+	u32 val = F_INVLD_EN0;
+
+	if (data->type == MTK_IOMMU_V1)
+		val |= F_INVLD_EN1;
+
+	writel_relaxed(val, data->base + REG_MMU_INV_SEL);
 	writel_relaxed(F_ALL_INVLD, data->base + REG_MMU_INVALIDATE);
 	wmb(); /* Make sure the tlb flush all done */
 }
@@ -180,25 +199,33 @@ static void mtk_iommu_v1_tlb_flush_range(struct mtk_iommu_v1_data *data,
 					 unsigned long iova, size_t size)
 {
 	int ret;
-	u32 tmp;
+	u32 tmp, val = F_INVLD_EN0;
 
-	writel_relaxed(F_INVLD_EN1 | F_INVLD_EN0,
-		data->base + REG_MMU_INV_SEL);
+	if (data->type == MTK_IOMMU_V1)
+		val |= F_INVLD_EN1;
+
+	writel_relaxed(val, data->base + REG_MMU_INV_SEL);
 	writel_relaxed(iova & F_MMU_FAULT_VA_MSK,
 		data->base + REG_MMU_INVLD_START_A);
 	writel_relaxed((iova + size - 1) & F_MMU_FAULT_VA_MSK,
 		data->base + REG_MMU_INVLD_END_A);
 	writel_relaxed(F_MMU_INV_RANGE, data->base + REG_MMU_INVALIDATE);
 
-	ret = readl_poll_timeout_atomic(data->base + REG_MMU_CPE_DONE,
-				tmp, tmp != 0, 10, 100000);
-	if (ret) {
-		dev_warn(data->dev,
-			 "Partial TLB flush timed out, falling back to full flush\n");
-		mtk_iommu_v1_tlb_flush_all(data);
+	if (data->type == MTK_IOMMU_V1) {
+		ret = readl_poll_timeout_atomic(data->base + REG_MMU_CPE_DONE,
+						tmp, tmp != 0, 10, 100000);
+		if (ret) {
+			dev_warn(data->dev,
+				 "Partial TLB flush timed out, falling back to full flush\n");
+			mtk_iommu_v1_tlb_flush_all(data);
+		}
+
+		/* Clear the CPE status */
+		writel_relaxed(0, data->base + REG_MMU_CPE_DONE);
+	} else {
+		/* Make sure the TLB flush is done */
+		wmb();
 	}
-	/* Clear the CPE status */
-	writel_relaxed(0, data->base + REG_MMU_CPE_DONE);
 }
 
 static irqreturn_t mtk_iommu_v1_isr(int irq, void *dev_id)
@@ -215,8 +242,14 @@ static irqreturn_t mtk_iommu_v1_isr(int irq, void *dev_id)
 	fault_iova &= F_MMU_FAULT_VA_MSK;
 	fault_pa = readl_relaxed(data->base + REG_MMU_INVLD_PA);
 	regval = readl_relaxed(data->base + REG_MMU_INT_ID);
-	fault_larb = MT2701_M4U_TF_LARB(regval);
-	fault_port = MT2701_M4U_TF_PORT(regval);
+
+	if (data->type == MTK_IOMMU_V1) {
+		fault_larb = MT2701_M4U_TF_LARB(regval);
+		fault_port = MT2701_M4U_TF_PORT(regval);
+	} else {
+		fault_larb = MT6572_M4U_TF_LARB(regval);
+		fault_port = MT6572_M4U_TF_PORT(regval);
+	}
 
 	/*
 	 * MTK v1 iommu HW could not determine whether the fault is read or
@@ -539,7 +572,10 @@ static int mtk_iommu_v1_hw_init(const struct mtk_iommu_v1_data *data)
 		return ret;
 	}
 
-	regval = F_MMU_CTRL_COHERENT_EN | F_MMU_TF_PROTECT_SEL(2);
+	regval = F_MMU_TF_PROTECT_SEL(2);
+	if (data->type == MTK_IOMMU_V1)
+		regval |= F_MMU_CTRL_COHERENT_EN;
+
 	writel_relaxed(regval, data->base + REG_MMU_CTRL_REG);
 
 	regval = F_INT_TRANSLATION_FAULT |
@@ -588,7 +624,8 @@ static const struct iommu_ops mtk_iommu_v1_ops = {
 };
 
 static const struct of_device_id mtk_iommu_v1_of_ids[] = {
-	{ .compatible = "mediatek,mt2701-m4u", },
+	{ .compatible = "mediatek,mt2701-m4u", .data = (void *)MTK_IOMMU_V1 },
+	{ .compatible = "mediatek,mt6572-m4u", .data = (void *)MTK_IOMMU_MT6572 },
 	{}
 };
 MODULE_DEVICE_TABLE(of, mtk_iommu_v1_of_ids);
@@ -612,6 +649,7 @@ static int mtk_iommu_v1_probe(struct platform_device *pdev)
 		return -ENOMEM;
 
 	data->dev = dev;
+	data->type = (enum mtk_iommu_type)(uintptr_t)of_device_get_match_data(dev);
 
 	/* Protect memory. HW will access here while translation fault.*/
 	protect = devm_kcalloc(dev, 2, MTK_PROTECT_PA_ALIGN,

-- 
2.55.0

