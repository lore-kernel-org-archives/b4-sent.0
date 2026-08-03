From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:01 +0200
Subject: [PATCH 03/28] arm64: dts: qcom: sa8540p: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-3-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2564;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=0rmPt/07pX2g9KPGixObuTKoy95XHhWTdoHlGDnMQ2Y=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZih/NQ/ZW/PKYjWZcoI6S+gfSux15Gn2B8f
 OvNb/ioTu6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2YgAKCRBVnxHm/pHO
 9SGgB/0cMz974pUXxH9YfXYD5RH6A8QpehsE+epwZzc9/CZBNLkgehVbZMD4G568VgoDeV9e81Q
 oIr5qqiLHsCQ+vPs8Z5TovDoRD9By2krzh8cOkLtHTgMJXbjHXo5IC1VLJK4wyAlpcfabBknUKP
 y5iNYdKZAy6/FrFshNc/QIEFrr+oDApQejOR0qjv0UC9/3szjCG2ZLZL25kA0ZwaruQJH4g9Dyx
 4FTm0l2T7tSsGAYtY11HiYKbFiOOXZpmgN9wufRPkBF+M9U2LimIz8rzLImM9V5rAURzluTzMRm
 o5uBbse483ghLzx+DDfdCPCMAdw4er0UNpHRPenvoktXnHHk
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHYs on these boards, feeding 1.2V to vdda-phy and 0.9V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 519183af39b2 ("arm64: dts: qcom: add SA8540P and ADP")
Fixes: 6be310347c9c ("arm64: dts: qcom: add SA8540P ride(Qdrive-3)")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sa8295p-adp.dts  | 16 ++++++++--------
 arch/arm64/boot/dts/qcom/sa8540p-ride.dts |  8 ++++----
 2 files changed, 12 insertions(+), 12 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sa8295p-adp.dts b/arch/arm64/boot/dts/qcom/sa8295p-adp.dts
index d28d69162427..7178ae087038 100644
--- a/arch/arm64/boot/dts/qcom/sa8295p-adp.dts
+++ b/arch/arm64/boot/dts/qcom/sa8295p-adp.dts
@@ -604,8 +604,8 @@ &usb_0_hsphy {
 };
 
 &usb_0_qmpphy {
-	vdda-phy-supply = <&vreg_l3a>;
-	vdda-pll-supply = <&vreg_l5a>;
+	vdda-phy-supply = <&vreg_l5a>;
+	vdda-pll-supply = <&vreg_l3a>;
 
 	status = "okay";
 };
@@ -628,8 +628,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&vreg_l4c>;
-	vdda-pll-supply = <&vreg_l1c>;
+	vdda-phy-supply = <&vreg_l1c>;
+	vdda-pll-supply = <&vreg_l4c>;
 
 	status = "okay";
 };
@@ -671,15 +671,15 @@ &usb_2_hsphy3 {
 };
 
 &usb_2_qmpphy0 {
-	vdda-phy-supply = <&vreg_l3a>;
-	vdda-pll-supply = <&vreg_l5a>;
+	vdda-phy-supply = <&vreg_l5a>;
+	vdda-pll-supply = <&vreg_l3a>;
 
 	status = "okay";
 };
 
 &usb_2_qmpphy1 {
-	vdda-phy-supply = <&vreg_l3a>;
-	vdda-pll-supply = <&vreg_l5a>;
+	vdda-phy-supply = <&vreg_l5a>;
+	vdda-pll-supply = <&vreg_l3a>;
 
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/sa8540p-ride.dts b/arch/arm64/boot/dts/qcom/sa8540p-ride.dts
index 44177e9b64b5..df40c44c447e 100644
--- a/arch/arm64/boot/dts/qcom/sa8540p-ride.dts
+++ b/arch/arm64/boot/dts/qcom/sa8540p-ride.dts
@@ -478,8 +478,8 @@ &usb_0_hsphy {
 };
 
 &usb_0_qmpphy {
-	vdda-phy-supply = <&vreg_l3a>;
-	vdda-pll-supply = <&vreg_l5a>;
+	vdda-phy-supply = <&vreg_l5a>;
+	vdda-pll-supply = <&vreg_l3a>;
 
 	status = "okay";
 };
@@ -493,8 +493,8 @@ &usb_2_hsphy0 {
 };
 
 &usb_2_qmpphy0 {
-	vdda-phy-supply = <&vreg_l3a>;
-	vdda-pll-supply = <&vreg_l5a>;
+	vdda-phy-supply = <&vreg_l5a>;
+	vdda-pll-supply = <&vreg_l3a>;
 
 	status = "okay";
 };

-- 
2.43.0

