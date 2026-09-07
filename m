From: David Heidelberg <david@ixit.cz>
Date: Mon, 07 Sep 2026 17:58:09 +0200
Subject: [PATCH v9 1/2] arm64: dts: qcom: sdm845-google: Add dual front
 IMX355 cameras
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260907-pixel3-camera-v9-1-b1981f2d3291@ixit.cz>
References: <20260907-pixel3-camera-v9-0-b1981f2d3291@ixit.cz>
In-Reply-To: <20260907-pixel3-camera-v9-0-b1981f2d3291@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7030; i=david@ixit.cz;
 h=from:subject:message-id; bh=R4ISCV1984zVBpQ0G4NYnhWXr1PI9aedSUvur/tKjJ0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnt8TOEHvDKBQ247R6AVr/qfKJzBAYS3jv43XD
 ascnVVI7MqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCap7fEwAKCRBgAj/E00kg
 cmiAD/9vq1kwpZqDOcdJcq8wn7cdAf2oV6agrplZehqJ8tAWhYx+i9M714ZOsqGxGPzDS7UPaJ+
 zxneYMg4hN/UV1xdgec07yEyxRHtZNFQOBR9mErtBaOiuR2+2GaCmHIsp7qDyJ/68n9iyPY8Dq8
 lDjy3ATNbelbHuHV/45s6cYOUQ8QOe1eXHFjOYlcQG/w8QWzoaVDjX9qACQ1rmm565dCPrPwmHo
 cZDuIiC9xqfIymcSIIzskqa2SUZ5mPsND+PYls2FjRYX2Dv4cVYvzrdmHITIs5JAcz+8T0szJyu
 mf8dqt0ErCEq69HuuI3bA7vlbhZGxd6UQbsr017E1kxE7Ec1eW8qEUoDXRR9o9COhEv+dHmLqO1
 MFWvw0R1/KABe1GK6EPT3x9NfU3uMppIjtszBT9ct57FqfZPK8RSna6KaMxm8sAQfz4853nPsSO
 7+M9XtvXU2d7Xubcxc4uIB6U2UoYnd9NaPUQFyE/Yp9F+2UXdOH7XXCqeuWdFEWhB4QBGG+mlH+
 K9s2ub1RKFDZm16B2OpJAEiZLtNYpRIvmyuen87+6dv9V1AF8FJPAR7gbvjd3cuBNNA7HxnWYLX
 WuattBtoT5+TqLIIbNUdNMKdaJRd0XqCQkjH7zbr5n02zBKwhNuLDOQO9Mgi/go3R227mdPEJBW
 Bas3krSI4gaSTlw==
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
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 172 ++++++++++++++++++++-
 1 file changed, 171 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index f1379857e2742..02a392fea7212 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -1,16 +1,18 @@
 // SPDX-License-Identifier: GPL-2.0-only
 
 /dts-v1/;
 
 #include <dt-bindings/arm/qcom,ids.h>
 #include <dt-bindings/dma/qcom-gpi.h>
 #include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/media/video-interface-devices.h>
+#include <dt-bindings/media/video-interfaces.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 
 #include "sdm845.dtsi"
 #include "pm8998.dtsi"
 #include "pmi8998.dtsi"
 
 /delete-node/ &mpss_region;
 /delete-node/ &venus_mem;
@@ -108,16 +110,48 @@ gpio-keys {
 		key-vol-up {
 			label = "Volume Up";
 			linux,code = <KEY_VOLUMEUP>;
 			gpios = <&pm8998_gpios 6 GPIO_ACTIVE_LOW>;
 			debounce-interval = <15>;
 		};
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
 	vph_pwr: regulator-vph-pwr {
 		compatible = "regulator-fixed";
 		regulator-name = "vph_pwr";
 		regulator-min-microvolt = <3700000>;
 		regulator-max-microvolt = <3700000>;
 	};
 
 	vreg_s4a_1p8: regulator-vreg-s4a-1p8 {
@@ -314,16 +348,21 @@ vreg_l28a_3p0: ldo28 {
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
 
@@ -346,24 +385,127 @@ regulators-2 {
 
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
+		orientation = <MEDIA_ORIENTATION_FRONT>;
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
+		orientation = <MEDIA_ORIENTATION_FRONT>;
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
@@ -497,16 +639,44 @@ firmware-pins {
 			pins = "gpio79";
 			function = "gpio";
 			drive-strength = <2>;
 			bias-pull-down;
 		};
 
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
2.55.0

