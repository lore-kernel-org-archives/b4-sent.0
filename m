From: Robert Eckelmann <longnoserob@gmail.com>
Date: Fri, 05 Dec 2025 22:00:05 +0900
Subject: [PATCH v2 2/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Adjust
 firmware paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251205-slpi-v2-2-dfe0b106cf1a@gmail.com>
References: <20251205-slpi-v2-0-dfe0b106cf1a@gmail.com>
In-Reply-To: <20251205-slpi-v2-0-dfe0b106cf1a@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, david@ixit.cz, 
 Robert Eckelmann <longnoserob@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1913; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=9gWceQNch+WtUQccnVFGua7dXEEd27z0WmImczxeGCw=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDKNrrd9FzkS+lv7/QbHWE5GmS8rHi64urVLSKG4WERjS
 YbCXVfmjlIWBjEuBlkxRZYdbsd0Ml2XRmzcvb8MZg4rE8gQBi5OAZiIiAHDf1ff/gP7w8xVNqm7
 pshKzWZjm7Ghf+tCo67vq1pLJzSbvGJkmKuas9khztirLpjnxryUH00uL596xUqWJ2x53fKT1c+
 KFwA=
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Firmware patht adjusted to include device maker "Xiaomi"

Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
---
 .../arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index cadddcf63ef6..8ce592cabd35 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -136,7 +136,7 @@ vreg_s4a_1p8: vreg-s4a-1p8 {
 
 &adsp_pas {
 	status = "okay";
-	firmware-name = "qcom/sdm845/beryllium/adsp.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/beryllium/adsp.mbn";
 };
 
 &apps_rsc {
@@ -229,7 +229,7 @@ vreg_l26a_1p2: ldo26 {
 
 &cdsp_pas {
 	status = "okay";
-	firmware-name = "qcom/sdm845/beryllium/cdsp.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/beryllium/cdsp.mbn";
 };
 
 &gcc {
@@ -249,7 +249,7 @@ &gpu {
 };
 
 &gpu_zap_shader {
-	firmware-name = "qcom/sdm845/beryllium/a630_zap.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/beryllium/a630_zap.mbn";
 };
 
 &ibb {
@@ -308,13 +308,14 @@ &mdss_dsi0_phy {
 
 &mss_pil {
 	status = "okay";
-	firmware-name = "qcom/sdm845/beryllium/mba.mbn", "qcom/sdm845/beryllium/modem.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/beryllium/mba.mbn",
+	"qcom/sdm845/Xiaomi/beryllium/modem.mbn";
 };
 
 &ipa {
 	qcom,gsi-loader = "self";
 	memory-region = <&ipa_fw_mem>;
-	firmware-name = "qcom/sdm845/beryllium/ipa_fws.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/beryllium/ipa_fws.mbn";
 	status = "okay";
 };
 
@@ -618,7 +619,7 @@ &usb_1_qmpphy {
 
 &venus {
 	status = "okay";
-	firmware-name = "qcom/sdm845/beryllium/venus.mbn";
+	firmware-name = "qcom/sdm845/Xiaomi/beryllium/venus.mbn";
 };
 
 &wcd9340 {

-- 
2.52.0

