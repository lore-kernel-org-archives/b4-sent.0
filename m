From: Paul Adam <adamp@posteo.de>
Date: Sat, 21 Feb 2026 21:55:41 +0100
Subject: [PATCH v2 3/3] arm64: dts: qcom: msm8916-wiko-chuppito: add
 initial devicetree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260221-wiko-chuppito-v2-3-6336b1b12389@posteo.de>
References: <20260221-wiko-chuppito-v2-0-6336b1b12389@posteo.de>
In-Reply-To: <20260221-wiko-chuppito-v2-0-6336b1b12389@posteo.de>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, Paul Adam <adamp@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771707381; l=9047;
 i=adamp@posteo.de; s=20260215; h=from:subject:message-id;
 bh=fHaZvFc2F+Zdqx6b/XG/AUiKvbzgj0C5HF9r+F7ZYnY=;
 b=UhA4ybSYO8iUlp9wzy+caPfINnbDYZ5tR7rQHvUPP9sfX21TOhPoIvdQwMy0lWQlBPNrSLxfX
 hd9pwhRnEd+CHTINWRRcM8tP2f880dzjrc56I2C92onQZHIvpb5+fj+
X-Developer-Key: i=adamp@posteo.de; a=ed25519;
 pk=mtrPhSn7htywc4S5zrKNrWM6laAdfnaJzIs0BDiCyAs=
X-Endpoint-Received: by B4 Relay for adamp@posteo.de/20260215 with auth_id=640
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an initial device tree for Wiko PULP 4G.
Includes support for:
- UART
- USB (no OTG)
- Internal storage
- MicroSD
- Volume keys + Power button
- Touchscreen
- Backlight
- Accelerometer: Invensense MPU6880
- Magnetometer: Asahi Kasei AK09911
- Hall sensor: Rohm BU52021HFV
- Proximity sensor
- Vibrator
- Earpiece
- Microphone 1
- Headphones
- Wifi
- Bluetooth
- GPU

Signed-off-by: Paul Adam <adamp@posteo.de>
---
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 arch/arm64/boot/dts/qcom/msm8916-wiko-chuppito.dts | 361 +++++++++++++++++++++
 2 files changed, 362 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index f80b5d9cf1e8..5a3a9a823503 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -75,6 +75,7 @@ dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-samsung-rossa.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-samsung-serranove.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-thwc-uf896.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-thwc-ufi001c.dtb
+dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-wiko-chuppito.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-wingtech-wt86518.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-wingtech-wt86528.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-wingtech-wt88047.dtb
diff --git a/arch/arm64/boot/dts/qcom/msm8916-wiko-chuppito.dts b/arch/arm64/boot/dts/qcom/msm8916-wiko-chuppito.dts
new file mode 100644
index 000000000000..7f3a48e3bcb9
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/msm8916-wiko-chuppito.dts
@@ -0,0 +1,361 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+/dts-v1/;
+
+#include "msm8916-pm8916.dtsi"
+#include "msm8916-modem-qdsp6.dtsi"
+
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/input/input.h>
+#include <dt-bindings/pinctrl/qcom,pmic-mpp.h>
+
+/ {
+	model = "Wiko Pulp 4G";
+	compatible = "wiko,chuppito", "qcom,msm8916";
+	chassis-type = "handset";
+
+	aliases {
+		mmc0 = &sdhc_1; /* eMMC */
+		mmc1 = &sdhc_2; /* SD card */
+		serial0 = &blsp_uart2;
+	};
+
+	chosen {
+		stdout-path = "serial0";
+	};
+
+	backlight: backlight {
+		compatible = "pwm-backlight";
+		pwms = <&pm8916_pwm 0 100000>;
+		brightness-levels = <0 255>;
+		num-interpolated-steps = <255>;
+		default-brightness-level = <255>;
+		enable-gpios = <&tlmm 119 GPIO_ACTIVE_HIGH>;
+		pinctrl-0 = <&button_backlight_default>;
+		pinctrl-1 = <&button_backlight_off>;
+		pinctrl-names = "default", "off";
+	};
+
+	keys {
+		compatible = "gpio-keys";
+		pinctrl-0 = <&keys_default>;
+		pinctrl-names = "default";
+		label = "GPIO Buttons";
+
+		button-volume-up {
+			label = "Volume up";
+			gpios = <&tlmm 107 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_VOLUMEUP>;
+		};
+	};
+
+	hall-sensor {
+		compatible = "gpio-keys";
+		pinctrl-0 = <&hall_sensor_default>;
+		pinctrl-names = "default";
+		label = "GPIO Hall Effect Sensor";
+
+		event-hall-sensor {
+			label = "Hall Effect Sensor";
+			gpios = <&tlmm 117 GPIO_ACTIVE_LOW>;
+			linux,input-type = <EV_SW>;
+			linux,code = <SW_LID>;
+			linux,can-disable;
+		};
+	};
+
+	usb_id: usb-id {
+		compatible = "linux,extcon-usb-gpio";
+		id-gpios = <&tlmm 110 GPIO_ACTIVE_HIGH>;
+		pinctrl-0 = <&usb_id_default>;
+		pinctrl-names = "default";
+	};
+};
+
+&blsp_uart2 {
+	status = "okay";
+};
+
+&blsp_i2c2 {
+	status = "okay";
+
+	magnetometer@c {
+		compatible = "asahi-kasei,ak09911";
+		reg = <0x0c>;
+		vdd-supply = <&pm8916_l17>;
+		vid-supply = <&pm8916_l6>;
+		reset-gpios = <&tlmm 120 GPIO_ACTIVE_LOW>;
+		pinctrl-0 = <&mag_reset_default>;
+		pinctrl-1 = <&mag_reset_suspend>;
+		pinctrl-names = "default", "suspend";
+		mount-matrix = "1",  "0", "0",
+			       "0", "1", "0",
+			       "0",  "0", "1";
+	};
+
+	proximity@48 {
+		compatible = "sensortek,stk3310";
+		reg = <0x48>;
+		interrupts-extended = <&tlmm 113 IRQ_TYPE_EDGE_FALLING>;
+		pinctrl-0 = <&proximity_int_default>;
+		pinctrl-1 = <&proximity_int_suspend>;
+		pinctrl-names = "default", "suspend";
+	};
+
+	imu@68 {
+		compatible = "invensense,mpu6880";
+		reg = <0x68>;
+		interrupts-extended = <&tlmm 115 IRQ_TYPE_EDGE_FALLING>;
+		vdd-supply = <&pm8916_l17>;
+		vddio-supply = <&pm8916_l6>;
+		pinctrl-0 = <&imu_int_default>;
+		pinctrl-1 = <&imu_int_suspend>;
+		pinctrl-names = "default", "suspend";
+		mount-matrix = "0",  "-1", "0",
+			       "-1", "0", "0",
+			       "0",  "0", "-1";
+	};
+};
+
+&blsp_i2c5 {
+	status = "okay";
+
+	rmi4@39 {
+		compatible = "syna,rmi4-i2c";
+		reg = <0x39>;
+		interrupts-extended = <&tlmm 13 IRQ_TYPE_EDGE_FALLING>;
+		vdd-supply = <&pm8916_l17>;
+		vio-supply = <&pm8916_l6>;
+		pinctrl-0 = <&touchscreen_default>;
+		pinctrl-1 = <&touchscreen_suspend>;
+		pinctrl-names = "default", "suspend";
+		#address-cells = <1>;
+		#size-cells = <0>;
+		syna,startup-delay-ms = <100>;
+		syna,reset-delay-ms = <160>;
+
+		rmi4-f01@1 {
+			reg = <0x1>;
+			syna,nosleep-mode = <1>;
+		};
+
+		rmi4-f11@11 {
+			reg = <0x11>;
+			syna,sensor-type = <1>;
+		};
+	};
+};
+
+&gpu {
+	status = "okay";
+};
+
+&mdss {
+	status = "okay";
+};
+
+&mpss_mem {
+	reg = <0x0 0x86800000 0x0 0x5600000>;
+};
+
+&pm8916_pwm {
+	pinctrl-0 = <&pwm_out>;
+	pinctrl-names = "default";
+	status = "okay";
+};
+
+&pm8916_resin {
+	linux,code = <KEY_VOLUMEDOWN>;
+	status = "okay";
+};
+
+&pm8916_rpm_regulators {
+	pm8916_l17: l17 {
+		regulator-min-microvolt = <2850000>;
+		regulator-max-microvolt = <2850000>;
+		regulator-always-on;
+	};
+};
+
+&pm8916_vib {
+	status = "okay";
+};
+
+&sdhc_1 {
+	status = "okay";
+};
+
+&sdhc_2 {
+	pinctrl-0 = <&sdc2_default>, <&sdc2_cd_default>;
+	pinctrl-1 = <&sdc2_sleep>, <&sdc2_cd_default>;
+	pinctrl-names = "default", "sleep";
+	cd-gpios = <&tlmm 38 GPIO_ACTIVE_HIGH>;
+	status = "okay";
+};
+
+&sound {
+	audio-routing = "AMIC1", "MIC BIAS Internal1",
+		"AMIC2", "MIC BIAS Internal2",
+		"AMIC3", "MIC BIAS Internal1";
+};
+
+&usb {
+	extcon = <&usb_id>, <&usb_id>;
+	status = "okay";
+};
+
+&usb_hs_phy {
+	extcon = <&usb_id>;
+};
+
+&venus {
+	status = "okay";
+};
+
+&venus_mem {
+	status = "okay";
+};
+
+&wcnss {
+	status = "okay";
+};
+
+&wcnss_iris {
+	compatible = "qcom,wcn3620";
+};
+
+&wcnss_mem {
+	status = "okay";
+};
+
+&tlmm {
+	button_backlight_default: button-backlight-default-state {
+		pins = "gpio119";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
+	button_backlight_off: button-backlight-off-state {
+	     pins = "gpio119";
+	     function = "gpio";
+	     drive-strength = <2>;
+	     bias-disable;
+	     output-low;
+	};
+
+	keys_default: keys-default-state {
+		pins = "gpio107";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-up;
+	};
+
+	hall_sensor_default: hall-sensor-default-state {
+		pins = "gpio117";
+		function = "gpio";
+		drive-strength = <6>;
+		bias-pull-up;
+	};
+
+	imu_int_default: imu-int-default-state {
+		pins = "gpio115";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
+	imu_int_suspend: imu-int-suspend-state {
+		pins = "gpio115";
+		function = "gpio";
+		drive-strength = <2>;
+	};
+
+	mag_reset_default: mag-reset-default-state {
+		pins = "gpio120";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
+	mag_reset_suspend: mag-reset-suspend-state {
+		pins = "gpio120";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-down;
+	};
+
+	proximity_int_default: proximity-int-default-state {
+		pins = "gpio113";
+		function = "gpio";
+		drive-strength = <6>;
+		bias-pull-up;
+	};
+
+	proximity_int_suspend: proximity-int-suspend-state {
+		pins = "gpio113";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-down;
+	};
+
+	sdc2_cd_default: sdc2-cd-default-state {
+		pins = "gpio38";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
+	touchscreen_default: touchscreen-default-state {
+		touchscreen-pins {
+			pins = "gpio13";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-up;
+		};
+
+		reset-pins {
+			pins = "gpio12";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-disable;
+		};
+	};
+
+	touchscreen_suspend: touchscreen-suspend-state {
+		touchscreen-pins {
+			pins = "gpio13";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+
+		reset-pins {
+			pins = "gpio12";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+	};
+
+	usb_id_default: usb-id-default-state {
+		pins = "gpio110";
+		function = "gpio";
+		drive-strength = <8>;
+		bias-pull-up;
+	};
+};
+
+&pm8916_codec {
+	qcom,hphl-jack-type-normally-open;
+};
+
+&pm8916_mpps {
+	pwm_out: mpp4-state {
+		pins = "mpp4";
+		function = "digital";
+		power-source = <PM8916_MPP_VPH>;
+		output-low;
+		qcom,dtest = <1>;
+	};
+};

-- 
2.53.0

