From: Robert Eckelmann <longnoserob@gmail.com>
Date: Fri, 05 Dec 2025 22:00:06 +0900
Subject: [PATCH v2 3/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Add
 placeholders and sort
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251205-slpi-v2-3-dfe0b106cf1a@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1758; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=NKSrjVKl6hmHb40HZ/gBpdJQQYkkXd4Osh0NjPVYeDk=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDKNrrel/Z8mJPmG95tYyxzte84mbnz3TI4Fb3og4f3rX
 OxZpVc5HaUsDGJcDLJiiiw73I7pZLoujdi4e38ZzBxWJpAhDFycAjAR636GP9w3VXXeOR7udg6b
 zvys0H256rzZO3lfc7vtb40s/lZ9LIXhf9KeOoHZf9bzpnFFfX18lLl6l5ax7kWJjfGul8SCJKS
 7GQE=
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We know these devices are present, most of them are supported by
downstream and close to the mainline kernels.

This is very handy when rebasing the integration tree with the support.

No functional changes.

Reviewed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
---
 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 29 ++++++++++++++++------
 1 file changed, 22 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 8ce592cabd35..8df5311f4afd 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -227,6 +227,12 @@ vreg_l26a_1p2: ldo26 {
 	};
 };
 
+&cci_i2c0 {
+	status = "okay";
+
+	/* IMX363 @ 10 */
+};
+
 &cdsp_pas {
 	status = "okay";
 	firmware-name = "qcom/sdm845/Xiaomi/beryllium/cdsp.mbn";
@@ -261,6 +267,22 @@ &ibb {
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
@@ -312,13 +334,6 @@ &mss_pil {
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

