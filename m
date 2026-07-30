From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 30 Jul 2026 13:56:03 +0200
Subject: [PATCH 22/22] arm64: dts: qcom:
 qcs6490-rb3gen2-industrial-mezzanine: Fix the PCIe iommu-map entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-iommu-map-fix-v1-22-83405d37ba41@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3442;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=yyugXvaIDoOF39T2alzVy57BkmdKy2KLxfP4F34+35I=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqazvc9oeRxc6EHNug6KybI3uvprlcwu5WMrESI
 3NwxLEwEA2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCams73AAKCRBVnxHm/pHO
 9bk9B/40Z/wq27mw062+nDWjMiyzSpkU7+lvZp9ayYj6qQKZNHu8C9jtoAdqVzXUCM8KAfs7191
 hpLMgEl7N6ipl5925ANEIrKDCzpvOYCQWQlOfhoOCm4gtpkN6XDLeqB1P4tXM6bvUq1cXg1s5Ik
 1qJAB9EYS5L4HYKvoU1QTgmUYnNbVuYxy42pELAXPzsqaHF2GNQ2l3TfHys8SKbEyJNckiZLTb0
 O+b+VGz5hjZWuM+pfIvnUCPtZz2qfJLw3lt+Obd+7C4PKI9vrMwp29V6CF5cCY54k7ws5VNf9F7
 Zxiq8DBZMtoN19eaHRn3S39sfaU2iOGlAWdYNUUdibC7Prrk
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

Fixes: 4559b435f741 ("arm64: dts: qcom: qcs6490-rb3gen2-industrial-mezzanine: Add TC9563 PCIe switch node for PCIe0")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 .../qcom/qcs6490-rb3gen2-industrial-mezzanine.dtso | 50 +++++++++++-----------
 1 file changed, 25 insertions(+), 25 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/qcs6490-rb3gen2-industrial-mezzanine.dtso b/arch/arm64/boot/dts/qcom/qcs6490-rb3gen2-industrial-mezzanine.dtso
index 83908db335af..14c64439ae1e 100644
--- a/arch/arm64/boot/dts/qcom/qcs6490-rb3gen2-industrial-mezzanine.dtso
+++ b/arch/arm64/boot/dts/qcom/qcs6490-rb3gen2-industrial-mezzanine.dtso
@@ -54,15 +54,15 @@ &pcie0 {
 	pinctrl-0 = <&pcie0_reset_n>, <&pcie0_wake_n>, <&pcie0_clkreq_n>;
 	pinctrl-names = "default";
 
-	iommu-map = <0x0 &apps_smmu 0x1c00 0x1>,
-		    <0x100 &apps_smmu 0x1c01 0x1>,
-		    <0x208 &apps_smmu 0x1c04 0x1>,
-		    <0x210 &apps_smmu 0x1c05 0x1>,
-		    <0x218 &apps_smmu 0x1c06 0x1>,
-		    <0x300 &apps_smmu 0x1c07 0x1>,
-		    <0x400 &apps_smmu 0x1c08 0x1>,
-		    <0x500 &apps_smmu 0x1c09 0x1>,
-		    <0x501 &apps_smmu 0x1c10 0x1>;
+	iommu-map = <0x0 &apps_smmu 0x1c00 0x0 0x1>,
+		    <0x100 &apps_smmu 0x1c01 0x0 0x1>,
+		    <0x208 &apps_smmu 0x1c04 0x0 0x1>,
+		    <0x210 &apps_smmu 0x1c05 0x0 0x1>,
+		    <0x218 &apps_smmu 0x1c06 0x0 0x1>,
+		    <0x300 &apps_smmu 0x1c07 0x0 0x1>,
+		    <0x400 &apps_smmu 0x1c08 0x0 0x1>,
+		    <0x500 &apps_smmu 0x1c09 0x0 0x1>,
+		    <0x501 &apps_smmu 0x1c10 0x0 0x1>;
 
 	status = "okay";
 };
@@ -151,22 +151,22 @@ pci@0,1 {
 };
 
 &pcie1 {
-	iommu-map = <0x0 &apps_smmu 0x1c80 0x1>,
-		    <0x100 &apps_smmu 0x1c81 0x1>,
-		    <0x208 &apps_smmu 0x1c84 0x1>,
-		    <0x210 &apps_smmu 0x1c85 0x1>,
-		    <0x218 &apps_smmu 0x1c86 0x1>,
-		    <0x300 &apps_smmu 0x1c87 0x1>,
-		    <0x408 &apps_smmu 0x1c90 0x1>,
-		    <0x410 &apps_smmu 0x1c91 0x1>,
-		    <0x418 &apps_smmu 0x1c92 0x1>,
-		    <0x500 &apps_smmu 0x1c93 0x1>,
-		    <0x600 &apps_smmu 0x1c94 0x1>,
-		    <0x700 &apps_smmu 0x1c95 0x1>,
-		    <0x701 &apps_smmu 0x1c96 0x1>,
-		    <0x800 &apps_smmu 0x1c97 0x1>,
-		    <0x900 &apps_smmu 0x1c98 0x1>,
-		    <0x901 &apps_smmu 0x1c99 0x1>;
+	iommu-map = <0x0 &apps_smmu 0x1c80 0x0 0x1>,
+		    <0x100 &apps_smmu 0x1c81 0x0 0x1>,
+		    <0x208 &apps_smmu 0x1c84 0x0 0x1>,
+		    <0x210 &apps_smmu 0x1c85 0x0 0x1>,
+		    <0x218 &apps_smmu 0x1c86 0x0 0x1>,
+		    <0x300 &apps_smmu 0x1c87 0x0 0x1>,
+		    <0x408 &apps_smmu 0x1c90 0x0 0x1>,
+		    <0x410 &apps_smmu 0x1c91 0x0 0x1>,
+		    <0x418 &apps_smmu 0x1c92 0x0 0x1>,
+		    <0x500 &apps_smmu 0x1c93 0x0 0x1>,
+		    <0x600 &apps_smmu 0x1c94 0x0 0x1>,
+		    <0x700 &apps_smmu 0x1c95 0x0 0x1>,
+		    <0x701 &apps_smmu 0x1c96 0x0 0x1>,
+		    <0x800 &apps_smmu 0x1c97 0x0 0x1>,
+		    <0x900 &apps_smmu 0x1c98 0x0 0x1>,
+		    <0x901 &apps_smmu 0x1c99 0x0 0x1>;
 };
 
 &pcie1_switch0_dsp1 {

-- 
2.43.0

