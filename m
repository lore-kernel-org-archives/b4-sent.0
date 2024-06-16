From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 16 Jun 2024 16:15:45 +0200
Subject: [PATCH] ARM: dts: qcom: msm8926-motorola-peregrine: Add
 accelerometer, magnetometer, regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240616-peregrine-v1-1-85d14ae1a11a@apitzsch.eu>
X-B4-Tracking: v=1; b=H4sIAJDzbmYC/x3MQQqAIBBG4avIrBNU0kVXiRZlfzYbkxEikO6et
 Pzg8RpVCKPSpBoJbq585Q47KIrnmhM0793kjBtNsEEXCJJwhg6IHi5s1iNS74vg4Od/zcv7fu4
 y4albAAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718547355; l=4379;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=fAaRpnS34tfTExhh2XisZxapKdoWeOZI5ZaxJ4uIxC0=;
 b=TsGnsIqG+BESQgTILEz3JVRyswhIQ43+1QR+8irCA1StScDthFMgV6jNYbBp9qeaRMF/fZ7KY
 IDtHYY8zb7LC7S3Me07s09pIr/K1wONbrIB/dsmKDI4NmbAIyrfnTqL
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the accelerometer, magnetometer and regulator that are present on
the Motorola Moto G 4G (2013) device.

While at it, update framebuffer supplies and temperature sensor.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 .../dts/qcom/qcom-msm8926-motorola-peregrine.dts   | 121 +++++++++++++++++++++
 1 file changed, 121 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts b/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
index 0cbe2d2fbbb1..376a33125941 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
@@ -29,6 +29,10 @@ framebuffer0: framebuffer@3200000 {
 			height = <1280>;
 			stride = <(720 * 3)>;
 			format = "r8g8b8";
+			vsp-supply = <&reg_lcd_pos>;
+			vsn-supply = <&reg_lcd_neg>;
+			vdd-supply = <&pm8226_l28>;
+			vddio-supply = <&vddio_disp_vreg>;
 		};
 	};
 
@@ -51,6 +55,18 @@ key-volume-up {
 		};
 	};
 
+	vddio_disp_vreg: regulator-vddio-disp {
+		compatible = "regulator-fixed";
+		regulator-name = "vddio_disp";
+		gpio = <&tlmm 34 GPIO_ACTIVE_HIGH>;
+		startup-delay-us = <300>;
+		enable-active-high;
+		regulator-boot-on;
+		vin-supply = <&pm8226_l8>;
+		pinctrl-0 = <&disp_vddio_default>;
+		pinctrl-names = "default";
+	};
+
 	reserved-memory {
 		#address-cells = <1>;
 		#size-cells = <1>;
@@ -68,12 +84,67 @@ smem_region: smem@fa00000 {
 	};
 };
 
+&blsp1_i2c2 {
+	clock-frequency = <100000>;
+	status = "okay";
+
+	magnetometer@c {
+		compatible = "asahi-kasei,ak8963";
+		reg = <0xc>;
+		interrupts-extended = <&tlmm 38 IRQ_TYPE_EDGE_FALLING>;
+		reset-gpios = <&tlmm 62 GPIO_ACTIVE_LOW>;
+		vdd-supply = <&pm8226_l19>;
+		pinctrl-0 = <&mag_int_default &mag_reset_default>;
+		pinctrl-names = "default";
+	};
+
+	accelerometer@18 {
+		compatible = "st,lis3dh-accel";
+		reg = <0x18>;
+		interrupts-extended = <&tlmm 1 IRQ_TYPE_EDGE_FALLING>;
+		vdd-supply = <&pm8226_l19>;
+		pinctrl-0 = <&accel_int_default>;
+		pinctrl-names = "default";
+		st,drdy-int-pin = <1>;
+	};
+};
+
 &blsp1_i2c3 {
+	clock-frequency = <400000>;
 	status = "okay";
 
+	regulator@3e {
+		compatible = "ti,tps65132";
+		reg = <0x3e>;
+		pinctrl-0 = <&reg_lcd_default>;
+		pinctrl-names = "default";
+
+		reg_lcd_pos: outp {
+			regulator-name = "outp";
+			regulator-min-microvolt = <4000000>;
+			regulator-max-microvolt = <6000000>;
+			regulator-active-discharge = <1>;
+			regulator-boot-on;
+			enable-gpios = <&tlmm 31 GPIO_ACTIVE_HIGH>;
+		};
+
+		reg_lcd_neg: outn {
+			regulator-name = "outn";
+			regulator-min-microvolt = <4000000>;
+			regulator-max-microvolt = <6000000>;
+			regulator-active-discharge = <1>;
+			regulator-boot-on;
+			enable-gpios = <&tlmm 33 GPIO_ACTIVE_HIGH>;
+		};
+	};
+
 	sensor@48 {
 		compatible = "ti,tmp108";
 		reg = <0x48>;
+		interrupts-extended = <&tlmm 13 IRQ_TYPE_LEVEL_LOW>;
+		pinctrl-0 = <&temp_alert_default>;
+		pinctrl-names = "default";
+		#thermal-sensor-cells = <0>;
 	};
 };
 
@@ -278,6 +349,56 @@ &smbb {
 	status = "okay";
 };
 
+&tlmm {
+	accel_int_default: accel-int-default-state {
+		pins = "gpio1";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-disable;
+	};
+
+	disp_vddio_default: disp-vddio-default-state {
+		pins = "gpio34";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-high;
+	};
+
+	mag_int_default: mag-int-default-state {
+		pins = "gpio38";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-disable;
+	};
+
+	mag_reset_default: mag-reset-default-state {
+		pins = "gpio62";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-high;
+	};
+
+	reg_lcd_default: reg-lcd-default-state {
+		pins = "gpio31", "gpio33";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-high;
+	};
+
+	temp_alert_default: temp-alert-default-state {
+		pins = "gpio13";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-disable;
+	};
+};
+
 &usb {
 	extcon = <&smbb>;
 	dr_mode = "peripheral";

---
base-commit: c71189547381bb5f176c6b22a9edc3414f1837b9
change-id: 20240616-peregrine-6ec5e26b15ec

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

