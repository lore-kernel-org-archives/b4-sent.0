From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:03 +0200
Subject: [PATCH 05/28] arm64: dts: qcom: sdm850: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-5-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3412;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=nismIA24fRKl8EPFbT1HEX6ReLKE9mLrsjmrxiEtSfQ=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZi1TZBoMZDsJBX3iArhjdoWrIAqlrYYrRtb
 u0S0K6WK8+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2YgAKCRBVnxHm/pHO
 9X7aCACqSotDK+2F91lYPnIMELqETBqdHCoGBSyate4CVR5GZF9ta0QZRWFc2V0OoBkyRlHQATh
 VK7sTmTMIygUuNmMFBPq/rm93OVDe+WIh9cS8lC5XxYmTttqKA8ELnJVFBcHLcZPq15yUBkxHw1
 M8Ir8cGXJcgbIo5EJ98R06zoBraESNypmKvc6JmHX+WRgurGknjlJU1cCCnNEa/cwZAylhz6pCj
 QHBk98VPxBk3wg6MCGvzD5m1B4YzzRsU5si3Zaop9ik/sV+YSPqV7+6XwKkNnq1JFOtENTXlT4R
 agq98Ltwr9JS1dI40JQq0/oLdaATx68ECvRHpiyGLN16g/Rm
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHYs on these boards, feeding 1.2V to vdda-phy and 0.88V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: aab69794b55d ("arm64: dts: qcom: Add support for Huawei MateBook E 2019")
Fixes: 44acee207844 ("arm64: dts: qcom: Add Lenovo Yoga C630")
Fixes: d4b341269efb ("arm64: dts: qcom: Add support for Samsung Galaxy Book2")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sdm850-huawei-matebook-e-2019.dts | 8 ++++----
 arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts       | 8 ++++----
 arch/arm64/boot/dts/qcom/sdm850-samsung-w737.dts           | 8 ++++----
 3 files changed, 12 insertions(+), 12 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm850-huawei-matebook-e-2019.dts b/arch/arm64/boot/dts/qcom/sdm850-huawei-matebook-e-2019.dts
index f04865381870..a4339b562b60 100644
--- a/arch/arm64/boot/dts/qcom/sdm850-huawei-matebook-e-2019.dts
+++ b/arch/arm64/boot/dts/qcom/sdm850-huawei-matebook-e-2019.dts
@@ -872,8 +872,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&vdda_usb1_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb1_ss_core>;
+	vdda-phy-supply = <&vdda_usb1_ss_core>;
+	vdda-pll-supply = <&vdda_usb1_ss_1p2>;
 
 	status = "okay";
 };
@@ -898,8 +898,8 @@ &usb_2_hsphy {
 };
 
 &usb_2_qmpphy {
-	vdda-phy-supply = <&vdda_usb2_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb2_ss_core>;
+	vdda-phy-supply = <&vdda_usb2_ss_core>;
+	vdda-pll-supply = <&vdda_usb2_ss_1p2>;
 
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts b/arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts
index e41200839dbe..d8cb3e5d8d07 100644
--- a/arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts
+++ b/arch/arm64/boot/dts/qcom/sdm850-lenovo-yoga-c630.dts
@@ -860,8 +860,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vdda_usb1_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb1_ss_core>;
+	vdda-phy-supply = <&vdda_usb1_ss_core>;
+	vdda-pll-supply = <&vdda_usb1_ss_1p2>;
 };
 
 &usb_1_qmpphy_out {
@@ -953,8 +953,8 @@ &usb_2_hsphy {
 &usb_2_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vdda_usb2_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb2_ss_core>;
+	vdda-phy-supply = <&vdda_usb2_ss_core>;
+	vdda-pll-supply = <&vdda_usb2_ss_1p2>;
 };
 
 &venus {
diff --git a/arch/arm64/boot/dts/qcom/sdm850-samsung-w737.dts b/arch/arm64/boot/dts/qcom/sdm850-samsung-w737.dts
index a676d3ea01b9..b7a1e2317fc2 100644
--- a/arch/arm64/boot/dts/qcom/sdm850-samsung-w737.dts
+++ b/arch/arm64/boot/dts/qcom/sdm850-samsung-w737.dts
@@ -609,8 +609,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vdda_usb1_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb1_ss_core>;
+	vdda-phy-supply = <&vdda_usb1_ss_core>;
+	vdda-pll-supply = <&vdda_usb1_ss_1p2>;
 };
 
 &usb_2 {
@@ -635,8 +635,8 @@ &usb_2_hsphy {
 &usb_2_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vdda_usb2_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb2_ss_core>;
+	vdda-phy-supply = <&vdda_usb2_ss_core>;
+	vdda-pll-supply = <&vdda_usb2_ss_1p2>;
 };
 
 &venus {

-- 
2.43.0

