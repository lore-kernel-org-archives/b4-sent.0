From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 30 Jul 2026 13:55:44 +0200
Subject: [PATCH 03/22] arm64: dts: qcom: sar2130p: Fix the PCIe iommu-map
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-iommu-map-fix-v1-3-83405d37ba41@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1809;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=OKJZ0e+G90Y+zQDcl8eHT0LSI+I2/Hf10CAeBCTTqfo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqazvVsaqwzz42knT6ToDx28ZyNnigiB3ZOJIRK
 l/+LtbbBheJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCams71QAKCRBVnxHm/pHO
 9dpBB/90rbcpYP2ZgG2cEIDNsxPTEoaehxlJ+DNeiAscm3avkGxO5xdn/WahvpSBaLxd4oTVStv
 PKVZmsb4FJOo8SGaH9prPxLGkVMCLjcuIJuMUg1ItuIFm7mtHKM/ngzSTNru726W3s+jtWlifLh
 E91OHfM5xF6XIGs4hgxBiHiCTBl9ADYPuvNbM0y5UMm1/VZRD73zDkrPQViC1Ujke8qObGDJxGK
 H/YZ1a71pHttuujuPHCmWC+D/bSEExEYZsjfro5Izc3RKh6i3pVyzhrM7gbWNNk6LsB4UhCx1BF
 14i3CbtutBLue7l0GmUpjVieicltkt55xWV/mr5/HqsI/dr+
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

Fixes: be9115bfe5bf ("arm64: dts: qcom: sar2130p: add support for SAR2130P")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sar2130p.dtsi | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sar2130p.dtsi b/arch/arm64/boot/dts/qcom/sar2130p.dtsi
index 3c9529bb2f76..99002ddaf6f6 100644
--- a/arch/arm64/boot/dts/qcom/sar2130p.dtsi
+++ b/arch/arm64/boot/dts/qcom/sar2130p.dtsi
@@ -1329,8 +1329,8 @@ &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>,
 					 &config_noc SLAVE_PCIE_0 QCOM_ICC_TAG_ALWAYS>;
 			interconnect-names = "pcie-mem", "cpu-pcie";
 
-			iommu-map = <0x0   &apps_smmu 0x1c00 0x1>,
-				    <0x100 &apps_smmu 0x1c01 0x1>;
+			iommu-map = <0x0   &apps_smmu 0x1c00 0x0 0x1>,
+				    <0x100 &apps_smmu 0x1c01 0x0 0x1>;
 
 			resets = <&gcc GCC_PCIE_0_BCR>;
 			reset-names = "pci";
@@ -1455,8 +1455,8 @@ &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>,
 					 &config_noc SLAVE_PCIE_1 QCOM_ICC_TAG_ALWAYS>;
 			interconnect-names = "pcie-mem", "cpu-pcie";
 
-			iommu-map = <0x0   &apps_smmu 0x1e00 0x1>,
-				    <0x100 &apps_smmu 0x1e01 0x1>;
+			iommu-map = <0x0   &apps_smmu 0x1e00 0x0 0x1>,
+				    <0x100 &apps_smmu 0x1e01 0x0 0x1>;
 
 			resets = <&gcc GCC_PCIE_1_BCR>,
 				<&gcc GCC_PCIE_1_LINK_DOWN_BCR>;

-- 
2.43.0

