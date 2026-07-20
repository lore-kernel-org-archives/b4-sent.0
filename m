From: David Heidelberg <david@ixit.cz>
Date: Mon, 20 Jul 2026 12:53:07 +0200
Subject: [PATCH v6 1/2] arm64: dts: qcom: sdm845-google: Add dual front
 IMX355 cameras
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-pixel3-camera-v6-1-afe419bef476@ixit.cz>
References: <20260720-pixel3-camera-v6-0-afe419bef476@ixit.cz>
In-Reply-To: <20260720-pixel3-camera-v6-0-afe419bef476@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=7003; i=david@ixit.cz;
 h=from:subject:message-id; bh=hzWUGR5NhX43CvM85RMopYnoPfom41Awfwk4CCKP0w4=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGpd/hSgzKMrx0msv0b+zwH8Afo9AALU7P9qzZTRJWlAHdQxW
 YkCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJqXf4UAAoJEGACP8TTSSByOE8QAJE5
 LdhB/zEdCk55VxvSObg6hHMVELMQqJeGuoLmvUXR7J7iy9QIrfi2pmQ97qe3JRqdf2jRgWPzqbV
 cddjayudsrz49l3OzRDun/dSMEfMfF0r3LrjqG/uiffZo1SJQfR75GP92ynu0aRKiAxfzztZ6+/
 RnwiHxgLj2zL5L+Ey36bxxAbucA4T4AV/F8MN2HC85cFeRf7VKtfHURf9mOECGD8nfq0EdqE74r
 7VJRir5v3YxOs0p2ZZdjyI5pmIAo/lFYqkXnYbiTbaM8E0FMgJqI38Fc26tImOUEmQhO503ypCn
 WwSmD3svPv3llqjB/kBFoeiR26QT4vW7bxlwkDgqkOC+i3wycNhLvmCFFaNLbz9A/TKv0ISbhK4
 qozV7x4pFaQadqfQCXAyIe0+DLZJd3LYqOZgT5jyffSzeyMei7Xel3GddynA//Tq5Qq1MzldRtg
 IHr0sYwM+yx8YNYrEJbSqLoJkWOiB6Q1HDtZCn58TeLXhVRSQ88yHwH82uBq+xtYngXYBvkP5yx
 COfymAJvpDze/sKIXWWtjbZkauLMwh4nqWec4yxYUfxtTshup75/OZ4UaDuNAjyZOo9nYaZHKGu
 EzLcYdc4pTxYCcexSbfxYTbwn/spvc8AIZaf/0edQ89vgaJvO6KIy6DoDAzqkNAPIGAFDuUdGlT
 fijOd
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Pixel 3 features two front-facing Sony IMX355 sensors with
different focal lengths (standard and wide-angle).

Sensors are connected via CSIPHY port 1 and 2 and controlled over CCI
I2C1, using MCLK2 as the clock source.

This enables support for the dual front camera configuration.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 171 ++++++++++++++++++++-
 1 file changed, 170 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 9368fd6b87515..267dcd6eddaee 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -1,16 +1,17 @@
 // SPDX-License-Identifier: GPL-2.0-only
 
 /dts-v1/;
 
 #include <dt-bindings/arm/qcom,ids.h>
 #include <dt-bindings/dma/qcom-gpi.h>
 #include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/media/video-interfaces.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 
 #include "sdm845.dtsi"
 #include "pm8998.dtsi"
 #include "pmi8998.dtsi"
 
 /delete-node/ &mpss_region;
 /delete-node/ &venus_mem;
@@ -127,16 +128,48 @@ vreg_s4a_1p8: regulator-vreg-s4a-1p8 {
 		regulator-min-microvolt = <1800000>;
 		regulator-max-microvolt = <1800000>;
 		regulator-always-on;
 		regulator-boot-on;
 
 		vin-supply = <&vph_pwr>;
 	};
 
+	camera_front_avdd: regulator-front-cam-avdd {
+		compatible = "regulator-fixed";
+		regulator-name = "front_cam_avdd";
+
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+
+		gpios = <&tlmm 8 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		pinctrl-0 = <&cam_front_avdd_default>;
+		pinctrl-names = "default";
+
+		vin-supply = <&vreg_bob>;
+	};
+
+	camera_front_aux_avdd: regulator-front-cam-aux-avdd {
+		compatible = "regulator-fixed";
+		regulator-name = "front_cam_aux_avdd";
+
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+
+		gpios = <&tlmm 14 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		pinctrl-0 = <&cam_front_aux_avdd_default>;
+		pinctrl-names = "default";
+
+		vin-supply = <&vreg_bob>;
+	};
+
 	wcn3990-pmu {
 		compatible = "qcom,wcn3990-pmu";
 
 		vddio-supply = <&vreg_s4a_1p8>;
 		vddxo-supply = <&vreg_l7a_1p8>;
 		vddrf-supply = <&vreg_l17a_1p3>;
 		vddch0-supply = <&vreg_l25a_3p3>;
 
@@ -314,16 +347,21 @@ vreg_l28a_3p0: ldo28 {
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_LPM>;
 			regulator-boot-on;
 			/*
 			 * We can't properly bring the panel back if it gets turned off
 			 * so keep it's regulators always on for now.
 			 */
 			regulator-always-on;
 		};
+
+		vreg_lvs1_1p8: lvs1 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
 	};
 
 	regulators-1 {
 		compatible = "qcom,pmi8998-rpmh-regulators";
 		qcom,pmic-id = "b";
 
 		vdd-bob-supply = <&vph_pwr>;
 
@@ -346,24 +384,127 @@ regulators-2 {
 
 		vreg_s3c_0p6: smps3 {
 			regulator-min-microvolt = <600000>;
 			regulator-max-microvolt = <600000>;
 		};
 	};
 };
 
+&camss {
+	vdda-phy-supply = <&vreg_l1a_0p875>;
+	vdda-pll-supply = <&vreg_l26a_1p2>;
+
+	/*
+	 * MCLK2 (GPIO15) is shared between both front camera sensors.
+	 * The clock is generated by CAMCC, therefore the pin is
+	 * configured here rather than in individual sensor nodes.
+	 */
+	pinctrl-0 = <&cam_mclk2_default>;
+	pinctrl-1 = <&cam_mclk2_sleep>;
+	pinctrl-names = "default", "sleep";
+
+	status = "okay";
+
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@1 {
+			reg = <1>;
+
+			camss_endpoint1: endpoint {
+				bus-type = <MEDIA_BUS_TYPE_CSI2_DPHY>;
+				data-lanes = <0 1 2 3>;
+				remote-endpoint = <&cam_aux_front_endpoint>;
+			};
+		};
+
+		port@2 {
+			reg = <2>;
+
+			camss_endpoint2: endpoint {
+				bus-type = <MEDIA_BUS_TYPE_CSI2_DPHY>;
+				data-lanes = <0 1 2 3>;
+				remote-endpoint = <&cam_front_endpoint>;
+			};
+		};
+	};
+};
+
+&cci0_sleep {
+	/* bus has external pull-up */
+	/delete-property/ bias-pull-down;
+	bias-disable;
+};
+
 &cci {
 	status = "okay";
 };
 
 &cci_i2c1 {
 	/* actuator @0c */
 
-	/* front camera, imx355 @1a */
+	front_cam: camera@10 {
+		compatible = "sony,imx355";
+		reg = <0x10>;
+
+		clocks = <&clock_camcc CAM_CC_MCLK2_CLK>;
+		assigned-clocks = <&clock_camcc CAM_CC_MCLK2_CLK>;
+		assigned-clock-rates = <24000000>;
+
+		reset-gpios = <&tlmm 21 GPIO_ACTIVE_LOW>;
+
+		avdd-supply = <&camera_front_avdd>;
+		dvdd-supply = <&vreg_s3a_1p35>;
+		dovdd-supply = <&vreg_lvs1_1p8>;
+
+		pinctrl-0 = <&cam_front_reset_default>;
+		pinctrl-names = "default";
+
+		rotation = <270>;
+		orientation = <0>;
+
+		port {
+			cam_front_endpoint: endpoint {
+				data-lanes = <1 2 3 4>;
+				link-frequencies = /bits/ 64 <360000000>;
+				remote-endpoint = <&camss_endpoint2>;
+			};
+		};
+	};
+
+	front_aux_cam: camera@1a {
+		compatible = "sony,imx355";
+		reg = <0x1a>;
+
+		clocks = <&clock_camcc CAM_CC_MCLK2_CLK>;
+		assigned-clocks = <&clock_camcc CAM_CC_MCLK2_CLK>;
+		assigned-clock-rates = <24000000>;
+
+		reset-gpios = <&tlmm 9 GPIO_ACTIVE_LOW>;
+
+		avdd-supply = <&camera_front_aux_avdd>;
+		dvdd-supply = <&vreg_s3a_1p35>;
+		dovdd-supply = <&vreg_lvs1_1p8>;
+
+		pinctrl-0 = <&cam_front_aux_reset_default>;
+		pinctrl-names = "default";
+
+		rotation = <270>;
+		orientation = <0>;
+
+		port {
+			cam_aux_front_endpoint: endpoint {
+				data-lanes = <1 2 3 4>;
+				link-frequencies = /bits/ 64 <360000000>;
+				remote-endpoint = <&camss_endpoint1>;
+			};
+		};
+	};
 
 	/* eeprom @50, at24 driver says 8K */
 };
 
 &cdsp_pas {
 	firmware-name = "qcom/sdm845/Google/blueline/cdsp.mbn";
 
 	status = "okay";
@@ -485,16 +626,44 @@ nfc_int_default: nfc-int-default-state {
 
 	nfc_enable_default: nfc-enable-default-state {
 		pins = "gpio25", "gpio79";
 		function = "gpio";
 		drive-strength = <2>;
 		bias-pull-down;
 	};
 
+	cam_front_avdd_default: cam-avdd-default-state {
+		pins = "gpio8";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
+	cam_front_aux_reset_default: cam-front-aux-reset-default-state {
+		pins = "gpio9";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
+	cam_front_aux_avdd_default: cam-avdd-aux-default-state {
+		pins = "gpio14";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
+	cam_front_reset_default: cam-front-reset-default-state {
+		pins = "gpio21";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	touchscreen_reset: ts-reset-state {
 		pins = "gpio99";
 		function = "gpio";
 		drive-strength = <8>;
 		bias-pull-up;
 	};
 
 	touchscreen_pins: ts-pins-gpio-state {

-- 
2.53.0

