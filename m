From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 30 Jul 2026 13:55:51 +0200
Subject: [PATCH 10/22] arm64: dts: qcom: sm8550: Fix the PCIe iommu-map
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-iommu-map-fix-v1-10-83405d37ba41@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1756;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=9ObHrmTgy9auFRif7hmm/21tCC3Yej1+FVeyNLCSdIY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqazvYOuSFHpNxpoZ07rvC89A5aFvFol/zLf4Tk
 f+DsZih+7iJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCams72AAKCRBVnxHm/pHO
 9dDLCACmT0SNwuIedSqwmmn9dCKchBmWyCf2KS+CboupXUfpOHP7Ww6irpKnfg3+pEs9AA+k9z4
 1AHBBR7rylyX8zBUOHu40amxWP4nAPkBXIFrWNtU22ZdY80jDZCAYw9Y9fbXfa0NGWZyRf4qhsw
 yVpyTtbieEgUzwsO/lO1XHf52ebQ3wdsNqW54p8iY2KPMf/1tUgc0ZS3M4XUvo/8tkmL4hCEDBX
 crarNFDLkuAu/pjoBwLwvcFwE4ndh0p+MPtqX/egxY5g9dHcRCk3ZRpXHu3yUFLOvTase9QaMmp
 TGmRnuQfXIMMIor74eOW+unSd+tEkNILdP2UAhK1HPXpKSJO
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

Fixes: 7d1158c984d3 ("arm64: dts: qcom: sm8550: Add PCIe PHYs and controllers nodes")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index 396201905ef2..69babd26c678 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -2382,8 +2382,8 @@ &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>,
 
 			msi-map = <0x0 &gic_its 0x1400 0x1>,
 				  <0x100 &gic_its 0x1401 0x1>;
-			iommu-map = <0x0   &apps_smmu 0x1400 0x1>,
-				    <0x100 &apps_smmu 0x1401 0x1>;
+			iommu-map = <0x0   &apps_smmu 0x1400 0x0 0x1>,
+				    <0x100 &apps_smmu 0x1401 0x0 0x1>;
 
 			resets = <&gcc GCC_PCIE_0_BCR>;
 			reset-names = "pci";
@@ -2561,8 +2561,8 @@ &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>,
 
 			msi-map = <0x0 &gic_its 0x1480 0x1>,
 				  <0x100 &gic_its 0x1481 0x1>;
-			iommu-map = <0x0   &apps_smmu 0x1480 0x1>,
-				    <0x100 &apps_smmu 0x1481 0x1>;
+			iommu-map = <0x0   &apps_smmu 0x1480 0x0 0x1>,
+				    <0x100 &apps_smmu 0x1481 0x0 0x1>;
 
 			resets = <&gcc GCC_PCIE_1_BCR>,
 				<&gcc GCC_PCIE_1_LINK_DOWN_BCR>;

-- 
2.43.0

