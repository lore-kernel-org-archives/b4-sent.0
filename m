From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:22 +0200
Subject: [PATCH 24/28] arm64: dts: qcom: glymur: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-24-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2102;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=JyJPDL1ZlHK9X+tyxrgwAOPJ/PXRxxJTbY4uRsNaOTU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZpGIipb7iCX6tCEttF5R2JcJGrIBiP1eUpG
 n3CtFDsQ1GJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2aQAKCRBVnxHm/pHO
 9TaQCACZWLruzY0czIqNpmBmgNPVDDgUTSey1DVfVh4t/cnftUv2K9mEaFYV14ahY7/m6psQ+Dt
 CtEVgndPQsGzQl5sDIw7LCL5n5bCmRrl0XZA1diQhwbC53cDIypDGJifoQma2sdgoLgj9cjD7er
 yH3IZe0onHu10UfWxcR1XTT7HluDM8NwDXAqDAAa8V3W7ZYnGeK3dvr5psIV9Nvw/sEOcXeduS8
 q86WX2zFTxFhDF95KbY9VPxsCKqCA1S1S4G3Wwyhki9SLNoB6RL8yyvHuQ030mPzAgiBvu42fco
 U+UUopcJVBNfVIxfNV1hiuWJ95GKEfaVuNhUlk8CXJUhUk4l
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be the lower voltage (~0.8V)
and the vdda-pll supply to be the higher voltage (~1.2V), as used by the
DisplayPort QMP PHY on this SoC. But these two supplies are swapped for
the USB QMP PHYs on this board, feeding 1.2V to vdda-phy and 0.72V/0.83V
to vdda-pll.

Fix it by swapping the two supplies back.

Fixes: c8b63029455b ("arm64: dts: qcom: glymur-crd: Enable USB support")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/glymur-crd.dts | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/glymur-crd.dts b/arch/arm64/boot/dts/qcom/glymur-crd.dts
index c98dfb3941fa..9d42bd858595 100644
--- a/arch/arm64/boot/dts/qcom/glymur-crd.dts
+++ b/arch/arm64/boot/dts/qcom/glymur-crd.dts
@@ -339,8 +339,8 @@ &usb_0_hsphy {
 };
 
 &usb_0_qmpphy {
-	vdda-phy-supply = <&vreg_l4h_e0_1p2>;
-	vdda-pll-supply = <&vreg_l3f_e0_0p72>;
+	vdda-phy-supply = <&vreg_l3f_e0_0p72>;
+	vdda-pll-supply = <&vreg_l4h_e0_1p2>;
 	refgen-supply = <&vreg_l2f_e0_0p82>;
 
 	status = "okay";
@@ -368,8 +368,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&vreg_l4h_e0_1p2>;
-	vdda-pll-supply = <&vreg_l1h_e0_0p89>;
+	vdda-phy-supply = <&vreg_l1h_e0_0p89>;
+	vdda-pll-supply = <&vreg_l4h_e0_1p2>;
 	refgen-supply = <&vreg_l2f_e0_0p82>;
 
 	status = "okay";
@@ -413,16 +413,16 @@ &usb_mp_hsphy1 {
 };
 
 &usb_mp_qmpphy0 {
-	vdda-phy-supply = <&vreg_l4h_e0_1p2>;
-	vdda-pll-supply = <&vreg_l2h_e0_0p72>;
+	vdda-phy-supply = <&vreg_l2h_e0_0p72>;
+	vdda-pll-supply = <&vreg_l4h_e0_1p2>;
 	refgen-supply = <&vreg_l4f_e1_1p08>;
 
 	status = "okay";
 };
 
 &usb_mp_qmpphy1 {
-	vdda-phy-supply = <&vreg_l4h_e0_1p2>;
-	vdda-pll-supply = <&vreg_l2h_e0_0p72>;
+	vdda-phy-supply = <&vreg_l2h_e0_0p72>;
+	vdda-pll-supply = <&vreg_l4h_e0_1p2>;
 	refgen-supply = <&vreg_l4f_e1_1p08>;
 
 	status = "okay";

-- 
2.43.0

