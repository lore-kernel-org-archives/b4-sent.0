From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:20:19 +0000
Subject: [PATCH] iommu/arm-smmu-v3: Don't leak the CMDQV device on a bad
 #iommu-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-smmu-cmdqv-leak-v1-1-7ea8e34277ea@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ5EMBCA4VeROe8kbQVZr7LZAzUYq5YOIhHvr
 jh+h//fQcgzCeTRDp5WFv4PAfoVgW2LoSHkKhiMMqnW2qA4t6B11bRiT8UPlYprk8VlQskbQjV
 6qnm7j5/vY1nKjux8beA4TrVEBzxzAAAA
X-Change-ID: 20261112-smmu-cmdqv-leak-003f273b5e59
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Ashish Mhetre <amhetre@nvidia.com>, 
 Jon Hunter <jonathanh@nvidia.com>, Nicolin Chen <nicolinc@nvidia.com>
Cc: linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 linux-kernel@vger.kernel.org, linux-tegra@vger.kernel.org, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471618; l=2672;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=JFxmFN3cIRJr2/Ra6ODT1qA+wurdLXBaqRClozZogq4=;
 b=71xTMvY1LLFHX7uxj1jX748drTLI3BNM2UqILmAnNnTNAEEWxNJAzSMLcLAeqggXptxOpstUx
 nCLe/jcbtjJDHddsDeK88Pvs/8aM7Mx5rzcpgzKi4qhVEDZA/Uyy7vm
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

arm_smmu_device_dt_probe() only logs a missing or invalid #iommu-cells
and carries on with ret = -EINVAL. For "nvidia,tegra264-smmu" it then
calls tegra_cmdqv_dt_probe(), which takes a reference on the CMDQV
platform device in smmu->impl_dev, and returns the error. That reference
is only dropped by tegra241_cmdqv_probe() via arm_smmu_impl_probe(),
which is never reached, so every failed probe leaks it.

Return the error as soon as #iommu-cells is found to be wrong, before
anything takes a reference.

Fixes: ea69dc4e207b ("iommu/arm-smmu-v3: Add device-tree support for CMDQV driver")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206486@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
The Sashiko AI review found this leak while reviewing my series
"iommu/arm-smmu-v3: Keep the clock of the RK3588 PCIe SMMU running"
[1]. It is not related to that series, so it is sent on its own.

Only compile-tested (arm64 allmodconfig, W=1): I have no Tegra264
hardware.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed it.

[1] https://lore.kernel.org/r/20261110-smmu-v3-pcie-pd-v1-0-628819ca44b9@gmail.com
---
 drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

diff --git a/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c b/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c
index 6d4520c47308..f685ed0c01b3 100644
--- a/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c
+++ b/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c
@@ -5661,14 +5661,15 @@ static int arm_smmu_device_dt_probe(struct platform_device *pdev,
 {
 	struct device *dev = &pdev->dev;
 	u32 cells;
-	int ret = -EINVAL;
 
-	if (of_property_read_u32(dev->of_node, "#iommu-cells", &cells))
+	if (of_property_read_u32(dev->of_node, "#iommu-cells", &cells)) {
 		dev_err(dev, "missing #iommu-cells property\n");
-	else if (cells != 1)
+		return -EINVAL;
+	}
+	if (cells != 1) {
 		dev_err(dev, "invalid #iommu-cells value (%d)\n", cells);
-	else
-		ret = 0;
+		return -EINVAL;
+	}
 
 	parse_driver_options(smmu);
 
@@ -5680,7 +5681,7 @@ static int arm_smmu_device_dt_probe(struct platform_device *pdev,
 		static_branch_enable(&arm_smmu_erratum_repeat_tlbi_cfgi_key);
 	}
 
-	return ret;
+	return 0;
 }
 
 static unsigned long arm_smmu_resource_size(struct arm_smmu_device *smmu)

---
base-commit: 2cf4be57b301ed2d7af82e70cff5dfd96894d8de
change-id: 20261112-smmu-cmdqv-leak-003f273b5e59

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

