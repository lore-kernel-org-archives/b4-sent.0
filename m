From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 30 Jul 2026 13:55:55 +0200
Subject: [PATCH 14/22] arm64: dts: qcom: lemans: Fix the PCIe iommu-map
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-iommu-map-fix-v1-14-83405d37ba41@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1788;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=WUGl85XwKyUnHkHJbCy8Ez4R/q9SpowAjvVun1e0zOs=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqazvZHOQW0N9cydQNtTFCcU/bN8g0nIrk4LW6k
 NxgU7+aRNWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCams72QAKCRBVnxHm/pHO
 9bnSB/9SZ8sAauAp9GICmfZ7GwQgSeDOc7hnMnSCmmwoSrtiXyIrwJQsaGsyj5FqY4AV/pYVWqP
 S5/CPbi2rPE7OgTWoFqt5aIUSKuCFwYhWqSY/ENhlrfxGf6q54iek2yIkro9LYP9ESKAmshUWec
 +i9HqDFWXAYP7en4RqvsPL0gf0ov2+RGbchss1H6cFN9ZtjMCmi7+0/qWPKjQytXf5Ol8BgEIPE
 gc5Bwt/KqQoTNMLNEgIm7wUvW5w6cW1r7EdfJZu69LEuSsgSaD0zq8u90ZBf8vMbrTsvKk1E7lS
 9AQzuEXBnciLR7aRuEWlvKfbIycT3P6hiS5v3BGAaGtKarJ+
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

Fixes: 489f14be0e0a ("arm64: dts: qcom: sa8775p: Add pcie0 and pcie1 nodes")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/lemans.dtsi | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/lemans.dtsi b/arch/arm64/boot/dts/qcom/lemans.dtsi
index 353a6e6fd3ac..47d26dd832f7 100644
--- a/arch/arm64/boot/dts/qcom/lemans.dtsi
+++ b/arch/arm64/boot/dts/qcom/lemans.dtsi
@@ -2760,8 +2760,8 @@ pcie0: pcie@1c00000 {
 					<&gem_noc MASTER_APPSS_PROC 0 &config_noc SLAVE_PCIE_0 0>;
 			interconnect-names = "pcie-mem", "cpu-pcie";
 
-			iommu-map = <0x0 &pcie_smmu 0x0000 0x1>,
-				    <0x100 &pcie_smmu 0x0001 0x1>;
+			iommu-map = <0x0 &pcie_smmu 0x0000 0x0 0x1>,
+				    <0x100 &pcie_smmu 0x0001 0x0 0x1>;
 
 			resets = <&gcc GCC_PCIE_0_BCR>,
 				 <&gcc GCC_PCIE_0_LINK_DOWN_BCR>;
@@ -2933,8 +2933,8 @@ pcie1: pcie@1c10000 {
 					<&gem_noc MASTER_APPSS_PROC 0 &config_noc SLAVE_PCIE_1 0>;
 			interconnect-names = "pcie-mem", "cpu-pcie";
 
-			iommu-map = <0x0 &pcie_smmu 0x0080 0x1>,
-				    <0x100 &pcie_smmu 0x0081 0x1>;
+			iommu-map = <0x0 &pcie_smmu 0x0080 0x0 0x1>,
+				    <0x100 &pcie_smmu 0x0081 0x0 0x1>;
 
 			resets = <&gcc GCC_PCIE_1_BCR>,
 				 <&gcc GCC_PCIE_1_LINK_DOWN_BCR>;

-- 
2.43.0

