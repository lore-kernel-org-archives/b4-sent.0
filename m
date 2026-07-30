From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 30 Jul 2026 13:55:53 +0200
Subject: [PATCH 12/22] arm64: dts: qcom: sm8750: Fix the PCIe iommu-map
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-iommu-map-fix-v1-12-83405d37ba41@oss.qualcomm.com>
References: <20260730-iommu-map-fix-v1-0-83405d37ba41@oss.qualcomm.com>
In-Reply-To: <20260730-iommu-map-fix-v1-0-83405d37ba41@oss.qualcomm.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1320;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=bDlJ1W/E9RTWqqhvmXPuCILAEdeBuN1fRRw++dnK6NE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqazvZMi0ZbLzhwMueE0aZtz37SKSR4lmlKlmNc
 Rt/2aP6FDSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCams72QAKCRBVnxHm/pHO
 9Q4aB/wOwKlUQqmhs+9bUWGTyIDJZAxyi3zlh1AR7pvBEJSo4JjcpuKy90YxHVtieVjHmniYW9U
 8kKrDZfNUZRXsLfpH2Kx3IOhmnEnq9TaUvFKt5a9wtppRcx3Nqf7Wpr0ZFzhen0XQPCHNnRX2of
 3Xuy57H+1AO0rY4UUcNkxGSyYEEvMqnQb4rJ4Xocb7IjFTFegyUhc0FXQO2rjJnEDaSWOt8LaCI
 Lx/u3C+1JGU5zyBA25tABypIC7pWbLrzOFaMB8FWi50JCPqHFRe2EG7eAVfxG/VCyFoxkIMnNUd
 Ato8kMlPvPKRMsOMsHlXtdgxKcjJJSyX6dHJnlSKLKNsk38i
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IOMMU provider apps_smmu uses '#iommu-cells = <2>', but the PCIe
iommu-map entries specify only one cell for the SID, omitting the SID
mask. This went unnoticed until the OF core started warning with commit
ccb2fd725d41 ("of: Respect #{iommu,msi}-cells in maps"):

  iommu-map has 1-cell entries targeting 2-cell #iommu-cells, treating as 1-cell output

So fix the entries to match the provider's '#iommu-cells' property.

Fixes: 19f1395333f8 ("arm64: dts: qcom: sm8750: Add PCIe PHY and controller node")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sm8750.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8750.dtsi b/arch/arm64/boot/dts/qcom/sm8750.dtsi
index fafed417c66f..a858b15f991a 100644
--- a/arch/arm64/boot/dts/qcom/sm8750.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8750.dtsi
@@ -5280,8 +5280,8 @@ &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>,
 			interconnect-names = "pcie-mem",
 					     "cpu-pcie";
 
-			iommu-map = <0x0   &apps_smmu 0x1400 0x1>,
-				    <0x100 &apps_smmu 0x1401 0x1>;
+			iommu-map = <0x0   &apps_smmu 0x1400 0x0 0x1>,
+				    <0x100 &apps_smmu 0x1401 0x0 0x1>;
 
 			resets = <&gcc GCC_PCIE_0_BCR>;
 			reset-names = "pci";

-- 
2.43.0

