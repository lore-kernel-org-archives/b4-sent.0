From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:17 +0200
Subject: [PATCH 19/28] arm64: dts: qcom: purwa: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-19-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3882;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=JlD3N9GG/gNdoud/SFzh/MUc3Qdkcw5l2rQKOsDDRt8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZneSTF0Ms9WZcQGfMrqpZuUGKIrOXJJgIPH
 xkY8opmjS+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2ZwAKCRBVnxHm/pHO
 9XSxB/9GyzU5Sv9cfZP5zpmipWzwg0LRcHnj73DU8PPZhyTlffseB2hUAJU1kZ7x/lZkDXaUMv7
 FjLGkMIYL6Hn0SIpp5Pgbl6jcoqErQk/LqEpMx4xqe9qdBjDyhcrORo44k+1GvGv53xfCdsqcOo
 bOY8JyT8Y3jctXEcMtxTt864YyLWj5qFG2Yl1OkzVVL1q7kVGINk1NNCRmKR74XVFXs7HK8W//q
 1QA2bxpsFjwBbrFSxKecJS4WjCoRvOGf82IxWVG945MNxKPiAAHqt9lR9mwZxzrE1K20BExUV5L
 SxetPUqkC9LzjWrOILiCik1ksCQsFuVKRCf2f08uylxoo9VD
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHYs on these boards, feeding 1.2V to vdda-phy and 0.9V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 64a0277c9876 ("arm64: dts: qcom: Add PURWA-IOT-SOM platform")
Fixes: d3f600dc452d ("arm64: dts: qcom: Add Lenovo ThinkBook 16 G7 QOY device tree")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/purwa-iot-som.dtsi          | 20 ++++++++++----------
 .../boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts   | 20 ++++++++++----------
 2 files changed, 20 insertions(+), 20 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/purwa-iot-som.dtsi b/arch/arm64/boot/dts/qcom/purwa-iot-som.dtsi
index 394e65518ac5..50ea8a148ada 100644
--- a/arch/arm64/boot/dts/qcom/purwa-iot-som.dtsi
+++ b/arch/arm64/boot/dts/qcom/purwa-iot-som.dtsi
@@ -583,8 +583,8 @@ &usb_1_ss0_hsphy {
 };
 
 &usb_1_ss0_qmpphy {
-	vdda-phy-supply = <&vreg_l2j_1p2>;
-	vdda-pll-supply = <&vreg_l1j_0p8>;
+	vdda-phy-supply = <&vreg_l1j_0p8>;
+	vdda-pll-supply = <&vreg_l2j_1p2>;
 
 	status = "okay";
 };
@@ -604,8 +604,8 @@ &usb_1_ss1_hsphy {
 };
 
 &usb_1_ss1_qmpphy {
-	vdda-phy-supply = <&vreg_l2j_1p2>;
-	vdda-pll-supply = <&vreg_l2d_0p9>;
+	vdda-phy-supply = <&vreg_l2d_0p9>;
+	vdda-pll-supply = <&vreg_l2j_1p2>;
 
 	status = "okay";
 };
@@ -625,8 +625,8 @@ &usb_1_ss2_hsphy {
 };
 
 &usb_1_ss2_qmpphy {
-	vdda-phy-supply = <&vreg_l2j_1p2>;
-	vdda-pll-supply = <&vreg_l2d_0p9>;
+	vdda-phy-supply = <&vreg_l2d_0p9>;
+	vdda-pll-supply = <&vreg_l2j_1p2>;
 
 	status = "okay";
 };
@@ -663,15 +663,15 @@ &usb_mp_hsphy1 {
 };
 
 &usb_mp_qmpphy0 {
-	vdda-phy-supply = <&vreg_l3e_1p2>;
-	vdda-pll-supply = <&vreg_l3c_0p8>;
+	vdda-phy-supply = <&vreg_l3c_0p8>;
+	vdda-pll-supply = <&vreg_l3e_1p2>;
 
 	status = "okay";
 };
 
 &usb_mp_qmpphy1 {
-	vdda-phy-supply = <&vreg_l3e_1p2>;
-	vdda-pll-supply = <&vreg_l3c_0p8>;
+	vdda-phy-supply = <&vreg_l3c_0p8>;
+	vdda-pll-supply = <&vreg_l3e_1p2>;
 
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts b/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts
index 500809772097..913645bc3595 100644
--- a/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts
+++ b/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts
@@ -1561,8 +1561,8 @@ &usb_1_ss0_hsphy {
 };
 
 &usb_1_ss0_qmpphy {
-	vdda-phy-supply = <&vreg_l2j_1p2>;
-	vdda-pll-supply = <&vreg_l1j_0p8>;
+	vdda-phy-supply = <&vreg_l1j_0p8>;
+	vdda-pll-supply = <&vreg_l2j_1p2>;
 
 	status = "okay";
 };
@@ -1591,8 +1591,8 @@ &usb_1_ss1_hsphy {
 };
 
 &usb_1_ss1_qmpphy {
-	vdda-phy-supply = <&vreg_l2j_1p2>;
-	vdda-pll-supply = <&vreg_l2d_0p9>;
+	vdda-phy-supply = <&vreg_l2d_0p9>;
+	vdda-pll-supply = <&vreg_l2j_1p2>;
 
 	status = "okay";
 };
@@ -1631,8 +1631,8 @@ &usb_1_ss2_hsphy {
 };
 
 &usb_1_ss2_qmpphy {
-	vdda-phy-supply = <&vreg_l2j_1p2>;
-	vdda-pll-supply = <&vreg_l2d_0p9>;
+	vdda-phy-supply = <&vreg_l2d_0p9>;
+	vdda-pll-supply = <&vreg_l2j_1p2>;
 
 	/delete-property/ mode-switch;
 	/delete-property/ orientation-switch;
@@ -1685,8 +1685,8 @@ &usb_mp_hsphy0 {
 };
 
 &usb_mp_qmpphy0 {
-	vdda-phy-supply = <&vreg_l3e_1p2>;
-	vdda-pll-supply = <&vreg_l3c_0p8>;
+	vdda-phy-supply = <&vreg_l3c_0p8>;
+	vdda-pll-supply = <&vreg_l3e_1p2>;
 
 	status = "okay";
 };
@@ -1701,8 +1701,8 @@ &usb_mp_hsphy1 {
 };
 
 &usb_mp_qmpphy1 {
-	vdda-phy-supply = <&vreg_l3e_1p2>;
-	vdda-pll-supply = <&vreg_l3c_0p8>;
+	vdda-phy-supply = <&vreg_l3c_0p8>;
+	vdda-pll-supply = <&vreg_l3e_1p2>;
 
 	status = "okay";
 };

-- 
2.43.0

