From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 30 Jul 2026 13:55:56 +0200
Subject: [PATCH 15/22] arm64: dts: qcom: monaco: Fix the PCIe iommu-map
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-iommu-map-fix-v1-15-83405d37ba41@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1755;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=k03o/DS1gzxxMqcMNWsmm8XldTGkWT4c/LYXyFD6DBg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqazvacX7fBu7Dp8FgaxBtqrF48+y/FHU2KGWxm
 j/kZIbsQo+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCams72gAKCRBVnxHm/pHO
 9TIuB/40Hc/WPL/LIsB+ieGC14lj4t6B9+lpmjYc+E61l7z4kLYu5R+8AjN7cbUgPfzzcQnAvXZ
 hNgBSGOV7z/6oFzUm2SOExz6cuGhT673LUrX4pdk1rQ7OlotlD1pQ+cn7vFGIK+zuro4Ds6WyrW
 X0TEcMB28a8ocCl/gvf2PrMn2NV/QHTWLl3tg+FbKTSiPxEhYHAfHZB5LVqp68rx9lweBlCNPUw
 WaS2NXS23mnKduID5eo3t3UjCiry9a6tPfZDEXx5lZuQ4OOPuQtxaRNamStAJoADjdFyzEcUG+/
 +ZuznnrxI/9eyBPwTn2vuJbONS6OIxyQpuvreCnNTaWPIm3i
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IOMMU provider pcie_smmu uses '#iommu-cells = <2>', but the PCIe
iommu-map entries specify only one cell for the SID, omitting the SID
mask. This went unnoticed until the OF core started warning with commit
ccb2fd725d41 ("of: Respect #{iommu,msi}-cells in maps"):

  iommu-map has 1-cell entries targeting 2-cell #iommu-cells, treating as 1-cell output

So fix the entries to match the provider's '#iommu-cells' property.

Fixes: 46a7c01e7e9d ("arm64: dts: qcom: qcs8300: enable pcie0")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/monaco.dtsi | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/monaco.dtsi b/arch/arm64/boot/dts/qcom/monaco.dtsi
index e4c8466f941b..799d13d7558f 100644
--- a/arch/arm64/boot/dts/qcom/monaco.dtsi
+++ b/arch/arm64/boot/dts/qcom/monaco.dtsi
@@ -2349,8 +2349,8 @@ &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>,
 			interconnect-names = "pcie-mem",
 					     "cpu-pcie";
 
-			iommu-map = <0x0 &pcie_smmu 0x0000 0x1>,
-				    <0x100 &pcie_smmu 0x0001 0x1>;
+			iommu-map = <0x0 &pcie_smmu 0x0000 0x0 0x1>,
+				    <0x100 &pcie_smmu 0x0001 0x0 0x1>;
 
 			resets = <&gcc GCC_PCIE_0_BCR>,
 				 <&gcc GCC_PCIE_0_LINK_DOWN_BCR>;
@@ -2526,8 +2526,8 @@ &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>,
 					 &config_noc SLAVE_PCIE_1 QCOM_ICC_TAG_ACTIVE_ONLY>;
 			interconnect-names = "pcie-mem", "cpu-pcie";
 
-			iommu-map = <0x0 &pcie_smmu 0x0080 0x1>,
-				    <0x100 &pcie_smmu 0x0081 0x1>;
+			iommu-map = <0x0 &pcie_smmu 0x0080 0x0 0x1>,
+				    <0x100 &pcie_smmu 0x0081 0x0 0x1>;
 
 			resets = <&gcc GCC_PCIE_1_BCR>,
 				 <&gcc GCC_PCIE_1_LINK_DOWN_BCR>;

-- 
2.43.0

