From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:05 +0200
Subject: [PATCH 07/28] arm64: dts: qcom: sm8250: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-7-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4466;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ur6aC7igXGhOXIX0eL9vKWIjwvCJqfvszUoT2v2OkNA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZj/Bs+uaqnq4t51x+RsfsLFsQxVhLJBH/H8
 uHDE3IeTZeJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2YwAKCRBVnxHm/pHO
 9SBTB/9J1T8AFBdjsYK2AJiu4Uq5mjF9Q+arsKs5xbD5bf2BLBi76FmuMmQHWeONmJmDN3zzCWR
 qewqSM5u18Yzd8NI88nGDsRV6eZbbqKmbeN2f5d5Cm/t/wpZXm8CrKMhV062NPyAbQL4NxBVesO
 cSWxrR0ba8Oo0Ot8Zwyy2hviEDk1/4TWdbZuwf2TeyPNWuO5ou6ACqZTeLueH1lMA6h2IIhm//i
 WdhFcwWfK6XCosHsfbT4kHGkE2xV2RaNpQVBqyvwXXt//Dszdc83AO+gYlHgI34fxfF4JniKM1j
 0JdrWwm463U4fpuYnoy7ch4yasOYM1OQCFCp5wC99vCq19GN
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHYs on these boards, feeding 1.2V to vdda-phy and 0.9V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 91ed0e90fc49 ("arm64: dts: qcom: add sm8250 hdk dts")
Fixes: 221f0ef37f55 ("arm64: dts: sm8250-mtp: enable USB host nodes")
Fixes: 69cdb97ef652 ("arm64: dts: qcom: sm8250: Add support for SONY Xperia 1 II / 5 II (Edo platform)")
Fixes: 264beb3cbd0d ("arm64: dts: qcom: sm8250-xiaomi-pipa: Add initial device tree")
Fixes: 52c90664f122 ("arm64: dts: qcom: qrb5165-rb5: Add USB support")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/qrb5165-rb5.dts             | 8 ++++----
 arch/arm64/boot/dts/qcom/sm8250-hdk.dts              | 8 ++++----
 arch/arm64/boot/dts/qcom/sm8250-mtp.dts              | 8 ++++----
 arch/arm64/boot/dts/qcom/sm8250-sony-xperia-edo.dtsi | 4 ++--
 arch/arm64/boot/dts/qcom/sm8250-xiaomi-pipa.dts      | 4 ++--
 5 files changed, 16 insertions(+), 16 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/qrb5165-rb5.dts b/arch/arm64/boot/dts/qcom/qrb5165-rb5.dts
index 690b484352ed..d6af679abe1a 100644
--- a/arch/arm64/boot/dts/qcom/qrb5165-rb5.dts
+++ b/arch/arm64/boot/dts/qcom/qrb5165-rb5.dts
@@ -1424,8 +1424,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l9a_1p2>;
-	vdda-pll-supply = <&vreg_l18a_0p92>;
+	vdda-phy-supply = <&vreg_l18a_0p92>;
+	vdda-pll-supply = <&vreg_l9a_1p2>;
 };
 
 &usb_1_qmpphy_out {
@@ -1451,8 +1451,8 @@ &usb_2_hsphy {
 &usb_2_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l9a_1p2>;
-	vdda-pll-supply = <&vreg_l18a_0p92>;
+	vdda-phy-supply = <&vreg_l18a_0p92>;
+	vdda-pll-supply = <&vreg_l9a_1p2>;
 };
 
 &vamacro {
diff --git a/arch/arm64/boot/dts/qcom/sm8250-hdk.dts b/arch/arm64/boot/dts/qcom/sm8250-hdk.dts
index 3ea9d2b1a7d5..c1c673086df5 100644
--- a/arch/arm64/boot/dts/qcom/sm8250-hdk.dts
+++ b/arch/arm64/boot/dts/qcom/sm8250-hdk.dts
@@ -438,14 +438,14 @@ &usb_2_hsphy {
 
 &usb_1_qmpphy {
 	status = "okay";
-	vdda-phy-supply = <&vreg_l9a_1p2>;
-	vdda-pll-supply = <&vreg_l18a_0p92>;
+	vdda-phy-supply = <&vreg_l18a_0p92>;
+	vdda-pll-supply = <&vreg_l9a_1p2>;
 };
 
 &usb_2_qmpphy {
 	status = "okay";
-	vdda-phy-supply = <&vreg_l9a_1p2>;
-	vdda-pll-supply = <&vreg_l18a_0p92>;
+	vdda-phy-supply = <&vreg_l18a_0p92>;
+	vdda-pll-supply = <&vreg_l9a_1p2>;
 };
 
 &usb_1 {
diff --git a/arch/arm64/boot/dts/qcom/sm8250-mtp.dts b/arch/arm64/boot/dts/qcom/sm8250-mtp.dts
index 51779b99176d..14c8ca602110 100644
--- a/arch/arm64/boot/dts/qcom/sm8250-mtp.dts
+++ b/arch/arm64/boot/dts/qcom/sm8250-mtp.dts
@@ -862,8 +862,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l9a_1p2>;
-	vdda-pll-supply = <&vreg_l18a_0p9>;
+	vdda-phy-supply = <&vreg_l18a_0p9>;
+	vdda-pll-supply = <&vreg_l9a_1p2>;
 };
 
 &usb_2 {
@@ -885,8 +885,8 @@ &usb_2_hsphy {
 &usb_2_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l9a_1p2>;
-	vdda-pll-supply = <&vreg_l18a_0p9>;
+	vdda-phy-supply = <&vreg_l18a_0p9>;
+	vdda-pll-supply = <&vreg_l9a_1p2>;
 };
 
 &venus {
diff --git a/arch/arm64/boot/dts/qcom/sm8250-sony-xperia-edo.dtsi b/arch/arm64/boot/dts/qcom/sm8250-sony-xperia-edo.dtsi
index d8289b2698f3..51c0caaf4ea1 100644
--- a/arch/arm64/boot/dts/qcom/sm8250-sony-xperia-edo.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8250-sony-xperia-edo.dtsi
@@ -715,8 +715,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l9a_1p2>;
-	vdda-pll-supply = <&vreg_l18a_0p9>;
+	vdda-phy-supply = <&vreg_l18a_0p9>;
+	vdda-pll-supply = <&vreg_l9a_1p2>;
 };
 
 &venus {
diff --git a/arch/arm64/boot/dts/qcom/sm8250-xiaomi-pipa.dts b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-pipa.dts
index 078ba13f8762..f11e4e244dff 100644
--- a/arch/arm64/boot/dts/qcom/sm8250-xiaomi-pipa.dts
+++ b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-pipa.dts
@@ -515,8 +515,8 @@ &usb_1_hsphy {
 
 &usb_1_qmpphy {
 	status = "okay";
-	vdda-phy-supply = <&vreg_l9a_1p2>;
-	vdda-pll-supply = <&vreg_l18a_0p9>;
+	vdda-phy-supply = <&vreg_l18a_0p9>;
+	vdda-pll-supply = <&vreg_l9a_1p2>;
 };
 
 &ufs_mem_hc {

-- 
2.43.0

