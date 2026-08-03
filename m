From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:02 +0200
Subject: [PATCH 04/28] arm64: dts: qcom: sdm845: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-4-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6478;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=mBGTc2+AZnjEfAn8jbUG8I9jasDyu2Eu0VcfvKAbU6g=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZihvHjxwaN2ifCtNmopIqN8OPzrexyTODfO
 sEIirJz3R6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2YgAKCRBVnxHm/pHO
 9cGAB/4qE/7i7/83O9mFTqDr5QFl0DJQ3NAr9v9eTSQ4rZjUy8UJAc195Q4BKYZbtqJC+vAv6lt
 Ew8Q1dpex3ZigY/5upNf+dPYNbzwwqNBkrb8c1CtMJteHJQyOzIfV/fSqWuV/ErSFjxqBvdWTsH
 wf4s3QJx/Z0GYpDc6BfObcbHxDd9HT3u1ZzPDWjNP86WkE59PttrYgnBZ8D1CBD9vEDWi/OOORj
 0WksqxH725MrIf3BHvhB4OHdXCd4nnYb6QyShraaeh/emA4Hs728zcTF8FEvrn84AAPgK6YLiuj
 mkUOxPdc/D0im0UKm+63rCfvY4RuKb2bUh4cuFHwbs85OcL8
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHYs on these boards, feeding 1.2V to vdda-phy and 0.88V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 3f72e2d3e682 ("arm64: dts: qcom: Add Dragonboard 845c")
Fixes: a678adbf2d22 ("arm64: dts: qcom: Add support for Pixel 3 and Pixel 3 XL")
Fixes: 28ae8aa3923c ("arm64: dts: qcom: add device tree for LG G7 and LG V35")
Fixes: cfe10d38aa1a ("arm64: dts: qcom: sdm845-mtp: Add nodes for USB")
Fixes: d711b22eee55 ("arm64: dts: qcom: starqltechn: add initial device tree for starqltechn")
Fixes: 45882459159d ("arm64: dts: qcom: sdm845: add device tree for SHIFT6mq")
Fixes: dd6459a0890a ("arm64: dts: qcom: split beryllium dts into common dtsi and tianma dts")
Fixes: be497abe19bf ("arm64: dts: qcom: Add support for Xiaomi Mi Mix2s")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sdm845-db845c.dts                   | 8 ++++----
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi           | 4 ++--
 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi               | 4 ++--
 arch/arm64/boot/dts/qcom/sdm845-mtp.dts                      | 8 ++++----
 arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts      | 4 ++--
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts            | 4 ++--
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 4 ++--
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts           | 4 ++--
 8 files changed, 20 insertions(+), 20 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-db845c.dts b/arch/arm64/boot/dts/qcom/sdm845-db845c.dts
index 02416812b6a7..846138149b2c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-db845c.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-db845c.dts
@@ -1121,8 +1121,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l26a_1p2>;
-	vdda-pll-supply = <&vreg_l1a_0p875>;
+	vdda-phy-supply = <&vreg_l1a_0p875>;
+	vdda-pll-supply = <&vreg_l26a_1p2>;
 };
 
 &usb_2 {
@@ -1147,8 +1147,8 @@ &usb_2_hsphy {
 &usb_2_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l26a_1p2>;
-	vdda-pll-supply = <&vreg_l1a_0p875>;
+	vdda-phy-supply = <&vreg_l1a_0p875>;
+	vdda-pll-supply = <&vreg_l26a_1p2>;
 };
 
 &ufs_mem_hc {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index b2dc0327dff8..ebeebbde6405 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -571,8 +571,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&vreg_l26a_1p2>;
-	vdda-pll-supply = <&vreg_l1a_0p875>;
+	vdda-phy-supply = <&vreg_l1a_0p875>;
+	vdda-pll-supply = <&vreg_l26a_1p2>;
 
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
index e0c3566761bf..c14b4b3d9a3c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
@@ -677,8 +677,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&vdda_usb1_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb1_ss_core>;
+	vdda-phy-supply = <&vdda_usb1_ss_core>;
+	vdda-pll-supply = <&vdda_usb1_ss_1p2>;
 
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/sdm845-mtp.dts b/arch/arm64/boot/dts/qcom/sdm845-mtp.dts
index 091568642faa..00ea30afc9f6 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-mtp.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-mtp.dts
@@ -729,8 +729,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vdda_usb1_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb1_ss_core>;
+	vdda-phy-supply = <&vdda_usb1_ss_core>;
+	vdda-pll-supply = <&vdda_usb1_ss_1p2>;
 };
 
 &usb_2 {
@@ -761,8 +761,8 @@ &usb_2_hsphy {
 &usb_2_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vdda_usb2_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb2_ss_core>;
+	vdda-phy-supply = <&vdda_usb2_ss_core>;
+	vdda-pll-supply = <&vdda_usb2_ss_1p2>;
 };
 
 &venus {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
index 0d915ecb0444..cd735417addd 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-samsung-starqltechn.dts
@@ -949,8 +949,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&vdda_usb1_ss_1p2>;
-	vdda-pll-supply = <&vdda_usb1_ss_core>;
+	vdda-phy-supply = <&vdda_usb1_ss_core>;
+	vdda-pll-supply = <&vdda_usb1_ss_1p2>;
 	status = "okay";
 };
 
diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index f21b914f22b5..ca503af9b832 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -876,8 +876,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l26a_1p2>;
-	vdda-pll-supply = <&vreg_l1a_0p875>;
+	vdda-phy-supply = <&vreg_l1a_0p875>;
+	vdda-pll-supply = <&vreg_l26a_1p2>;
 };
 
 &venus {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 54e58ca04693..710b296e4964 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -645,8 +645,8 @@ &usb_1_hsphy {
 &usb_1_qmpphy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l26a_1p2>;
-	vdda-pll-supply = <&vreg_l1a_0p875>;
+	vdda-phy-supply = <&vreg_l1a_0p875>;
+	vdda-pll-supply = <&vreg_l26a_1p2>;
 };
 
 &venus {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
index a44d6e776c82..cce7348e583a 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
@@ -668,8 +668,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-pll-supply = <&vreg_l1a_0p875>;
-	vdda-phy-supply = <&vreg_l26a_1p2>;
+	vdda-pll-supply = <&vreg_l26a_1p2>;
+	vdda-phy-supply = <&vreg_l1a_0p875>;
 	status = "okay";
 };
 

-- 
2.43.0

