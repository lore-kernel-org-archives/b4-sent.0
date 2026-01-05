From: Robert Eckelmann <longnoserob@gmail.com>
Date: Mon, 05 Jan 2026 22:31:53 +0900
Subject: [PATCH v4 3/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Add
 placeholders and sort
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-slpi-v4-3-e6e0abfad3a4@gmail.com>
References: <20260105-slpi-v4-0-e6e0abfad3a4@gmail.com>
In-Reply-To: <20260105-slpi-v4-0-e6e0abfad3a4@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, david@ixit.cz, 
 Robert Eckelmann <longnoserob@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1802; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=EM/NFegAHroxA02lkzL/+IA7UF2v/eqwuF0ytn6UwBI=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDKj91ZNmL/v1YS+Bu0fPUnWh3yUb7Xy5kgbH3yZeidvS
 UiD5gqVjlIWBjEuBlkxRZYdbsd0Ml2XRmzcvb8MZg4rE8gQBi5OAZhIRQIjw2WfJ/LPevbUZplE
 lTqtVHV6GC3j9VxPrYFxBWfR4r8sxQx/hUN1f0zvu+/f6TxbkjWhrEbzw4q5q8/d0Gif0HveVeY
 3NwA=
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We know these devices are present, most of them are supported by
downstream and close to the mainline kernels.

This is very handy when rebasing the integration tree with the support.

No functional changes.

Reviewed-by: David Heidelberg <david@ixit.cz>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
---
 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 27 ++++++++++++++++------
 1 file changed, 20 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index ab450d44b3f6..6f1bff7a37cd 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -227,6 +227,10 @@ vreg_l26a_1p2: ldo26 {
 	};
 };
 
+&cci_i2c0 {
+	/* IMX363 @ 10 */
+};
+
 &cdsp_pas {
 	status = "okay";
 	firmware-name = "qcom/sdm845/Xiaomi/beryllium/cdsp.mbn";
@@ -261,6 +265,22 @@ &ibb {
 	qcom,discharge-resistor-kohms = <300>;
 };
 
+&ipa {
+	qcom,gsi-loader = "self";
+	memory-region = <&ipa_fw_mem>;
+	firmware-name = "qcom/sdm845/beryllium/ipa_fws.mbn";
+
+	status = "okay";
+};
+
+&i2c5 {
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	/* TAS2559 @ 4C */
+};
+
 &lab {
 	regulator-min-microvolt = <4600000>;
 	regulator-max-microvolt = <6000000>;
@@ -312,13 +332,6 @@ &mss_pil {
 	"qcom/sdm845/Xiaomi/beryllium/modem.mbn";
 };
 
-&ipa {
-	qcom,gsi-loader = "self";
-	memory-region = <&ipa_fw_mem>;
-	firmware-name = "qcom/sdm845/Xiaomi/beryllium/ipa_fws.mbn";
-	status = "okay";
-};
-
 &pm8998_gpios {
 	vol_up_pin_a: vol-up-active-state {
 		pins = "gpio6";

-- 
2.52.0

