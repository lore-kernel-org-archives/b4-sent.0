From: Robert Eckelmann <longnoserob@gmail.com>
Date: Wed, 26 Nov 2025 21:08:36 +0900
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-xiaomi-beryllium: Add
 placeholders and sort
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251126-slpi-v1-2-c101d08beaf2@gmail.com>
References: <20251126-slpi-v1-0-c101d08beaf2@gmail.com>
In-Reply-To: <20251126-slpi-v1-0-c101d08beaf2@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Eckelmann <longnoserob@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1659; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=jRDzXV0G0lUQ5KhhdMuc9FwHaZQADAKy3FthKzJhXWc=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDLV3p5/4hBrrR3x1jd2ict+xqUK5geOmU3LTjv1/PMaR
 c8o0SnSHaUsDGJcDLJiiiw73I7pZLoujdi4e38ZzBxWJpAhDFycAjAR5RiGf5r+ayczdkqeF48N
 vPn63kvxAxm7bKfyFMR5p9grvZ222Zrhr8QcplWZlaUPridv7juQWVx86rDKApG3OnHvQk/G/yy
 r5gMA
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We know these devices are present, most of them are supported by
downstream and close to the mainline kernels.

This is very handy when rebasing the integration tree with the support.

No functional changes.

Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
---
 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 23 +++++++++++++++-------
 1 file changed, 16 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 0fb1d7e724c4..0b219d0ff451 100644
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
 	firmware-name = "qcom/sdm845/beryllium/cdsp.mbn";
@@ -261,6 +265,18 @@ &ibb {
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
+	/* TAS2559 @ 4C */
+};
+
 &lab {
 	regulator-min-microvolt = <4600000>;
 	regulator-max-microvolt = <6000000>;
@@ -311,13 +327,6 @@ &mss_pil {
 	firmware-name = "qcom/sdm845/beryllium/mba.mbn", "qcom/sdm845/beryllium/modem.mbn";
 };
 
-&ipa {
-	qcom,gsi-loader = "self";
-	memory-region = <&ipa_fw_mem>;
-	firmware-name = "qcom/sdm845/beryllium/ipa_fws.mbn";
-	status = "okay";
-};
-
 &pm8998_gpios {
 	vol_up_pin_a: vol-up-active-state {
 		pins = "gpio6";

-- 
2.52.0

