From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:14 +0200
Subject: [PATCH 16/28] arm64: dts: qcom: sc7280: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-16-5880630cde3e@oss.qualcomm.com>
References: <20260803-phy-supply-fix-v1-0-5880630cde3e@oss.qualcomm.com>
In-Reply-To: <20260803-phy-supply-fix-v1-0-5880630cde3e@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1766;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=I+mc1gmYR/W7IjdVctuuQ2GufrmtA1dU0l/JunQ3sQY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZm6+rDf3niwxWRD2wqFf9jqqtjC0bonLCjM
 Le1CCPhBPuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2ZgAKCRBVnxHm/pHO
 9cfEB/wKxyfuz5/aMmIETXHb2QhLRiQEPRGZtJ0zpLtksHinlaJW0/m3R4UIbB+ySsFpw6wlEDi
 8fwPNcHykRTAj8Kq1k72olMqgAzlM0DqL0Yh7X3MCRl6GU+iVd/mmXF/AVoL2SR8XAGtwCmHGTY
 6XviQPrbEGb0ioH1FC9buRDOYeNzMTm5ZSqPX4ve9XfejDI3QgxLIbKBDoBMvzV/VvSR+2yJYWZ
 zvDeoiks3vm+SraAwwnY1C+C+QE9jASS5ZOX/9OifaecjnQ24SlWORXU2fYR/Ha1yhXut/qDAAZ
 GvgPmYMJ0+KyI0tqbjJN7ZbkNMYXs4uZCsAS2VWucLypDDcH
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHYs on these boards, feeding 1.2V to vdda-phy and 0.9V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 97a5b73b7058 ("arm64: dts: qcom: sc7280-idp: Add device tree files for IDP2")
Fixes: 116f7cc43d28 ("arm64: dts: qcom: sc7280: Add herobrine-r1")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sc7280-idp.dtsi   | 4 ++--
 arch/arm64/boot/dts/qcom/sc7280-qcard.dtsi | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc7280-idp.dtsi b/arch/arm64/boot/dts/qcom/sc7280-idp.dtsi
index 8cac4ce9c851..23ced0621c99 100644
--- a/arch/arm64/boot/dts/qcom/sc7280-idp.dtsi
+++ b/arch/arm64/boot/dts/qcom/sc7280-idp.dtsi
@@ -542,8 +542,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l6b_1p2>;
-	vdda-pll-supply = <&vreg_l1b_0p8>;
+	vdda-phy-supply = <&vreg_l1b_0p8>;
+	vdda-pll-supply = <&vreg_l6b_1p2>;
 };
 
 &uart7 {
diff --git a/arch/arm64/boot/dts/qcom/sc7280-qcard.dtsi b/arch/arm64/boot/dts/qcom/sc7280-qcard.dtsi
index 9ae9af40f4d2..264029ff3f90 100644
--- a/arch/arm64/boot/dts/qcom/sc7280-qcard.dtsi
+++ b/arch/arm64/boot/dts/qcom/sc7280-qcard.dtsi
@@ -465,8 +465,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&vdd_a_usbssdp_0_1p2>;
-	vdda-pll-supply = <&vdd_a_usbssdp_0_core>;
+	vdda-phy-supply = <&vdd_a_usbssdp_0_core>;
+	vdda-pll-supply = <&vdd_a_usbssdp_0_1p2>;
 };
 
 &usb_2_hsphy {

-- 
2.43.0

