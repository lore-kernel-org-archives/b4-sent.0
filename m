From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:07 +0200
Subject: [PATCH 09/28] arm64: dts: qcom: sm8450: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-9-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2445;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=4KIaQYGqCM05ODIzG+nPhnfQPQd1XZvJPvLxCOb29Vg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZkgBA3QZHpypfGo2+CnYqG4oGaGnl8UAjet
 zHo8HCtO+uJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2ZAAKCRBVnxHm/pHO
 9VBsB/0UeL/C6SWlMvm3YM6iqxGTcve6OI4neFcNJBlitER7zdxVLbuTIvpC4qnAY77MozVPkiu
 gG1xWw8Y+srbeE3BNB9C0QDb+CX2BjCfeCiLlZusq1oyW+o9iO1VSL1Sfo965LYlxfbEtv4OYPk
 G4ArE+ufYbN96otuSgALRolIx9ZKyujNYsX2INppNccf6WC7edGLTMTOgg1uJYClgywZarh45dQ
 3Kr9ry5+b5aVxMCkDU08hx83TqPyacxxg/k1xFjRHWOzGM3aO9fs/B3hR2kjjaDyp/bE0jPbKS0
 1Ph5obRhuO7gdYmI22F9rgvPYjRhGRL2D//nSoDwBDZnK8tn
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHYs on these boards, feeding 1.2V to vdda-phy and 0.91V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 067b2b3616cd ("arm64: dts: qcom: Add SM8450 HDK DTS")
Fixes: 27a0d0b846d9 ("arm64: dts: qcom: sm8450-qrd: Enable USB nodes")
Fixes: 1620676b85f1 ("arm64: dts: qcom: sm8450-nagara: Separate out Nagara platform dtsi")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sm8450-hdk.dts                 | 4 ++--
 arch/arm64/boot/dts/qcom/sm8450-qrd.dts                 | 4 ++--
 arch/arm64/boot/dts/qcom/sm8450-sony-xperia-nagara.dtsi | 4 ++--
 3 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8450-hdk.dts b/arch/arm64/boot/dts/qcom/sm8450-hdk.dts
index b37998cd9a2c..4ade28f40cae 100644
--- a/arch/arm64/boot/dts/qcom/sm8450-hdk.dts
+++ b/arch/arm64/boot/dts/qcom/sm8450-hdk.dts
@@ -1214,8 +1214,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l6b_1p2>;
-	vdda-pll-supply = <&vreg_l1b_0p91>;
+	vdda-phy-supply = <&vreg_l1b_0p91>;
+	vdda-pll-supply = <&vreg_l6b_1p2>;
 };
 
 &usb_1_qmpphy_out {
diff --git a/arch/arm64/boot/dts/qcom/sm8450-qrd.dts b/arch/arm64/boot/dts/qcom/sm8450-qrd.dts
index 56db5f79f59d..4993059483e9 100644
--- a/arch/arm64/boot/dts/qcom/sm8450-qrd.dts
+++ b/arch/arm64/boot/dts/qcom/sm8450-qrd.dts
@@ -527,8 +527,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l6b_1p2>;
-	vdda-pll-supply = <&vreg_l1b_0p91>;
+	vdda-phy-supply = <&vreg_l1b_0p91>;
+	vdda-pll-supply = <&vreg_l6b_1p2>;
 };
 
 &usb_1_qmpphy_out {
diff --git a/arch/arm64/boot/dts/qcom/sm8450-sony-xperia-nagara.dtsi b/arch/arm64/boot/dts/qcom/sm8450-sony-xperia-nagara.dtsi
index 6bd315e10992..4fb5627d8126 100644
--- a/arch/arm64/boot/dts/qcom/sm8450-sony-xperia-nagara.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8450-sony-xperia-nagara.dtsi
@@ -793,7 +793,7 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&pm8350_l6>;
-	vdda-pll-supply = <&pm8350_l1>;
+	vdda-phy-supply = <&pm8350_l1>;
+	vdda-pll-supply = <&pm8350_l6>;
 	status = "okay";
 };

-- 
2.43.0

