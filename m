From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 01 Apr 2026 13:32:13 -0700
Subject: [PATCH v3 1/4] ARM: dts: qcom: msm8960: expressatt: Sort node
 references and includes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-expressatt_fuel_guage-v3-1-9674cfc0b5a2@gmail.com>
References: <20260401-expressatt_fuel_guage-v3-0-9674cfc0b5a2@gmail.com>
In-Reply-To: <20260401-expressatt_fuel_guage-v3-0-9674cfc0b5a2@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775075533; l=12047;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=5nbF8uv4w0udRlmJ01uecytHbgghHrqiWUob940/otI=;
 b=YhGPyy4bFANR9YiWCi7ajd6ylcGqhquHLt8h5MIpQT2uYEMBd9sQSPmEqCsde4b6jy8VGH9mw
 Oq+n13F9En1ASe7soO1zsvnnNRA5pooxbY5li9bZQJR2bkICmQ4S97r
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reorganize the DTS file for consistency with other msm8960 board files.

Assisted-by: Claude:claude-opus-4.6
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 408 +++++++++++----------
 1 file changed, 207 insertions(+), 201 deletions(-)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 35514fd53e3d..0e6959f7af6f 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -1,13 +1,13 @@
 // SPDX-License-Identifier: GPL-2.0
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/input/gpio-keys.h>
 #include <dt-bindings/input/input.h>
 #include <dt-bindings/leds/common.h>
+#include <dt-bindings/pinctrl/qcom,pmic-gpio.h>
 #include <dt-bindings/reset/qcom,gcc-msm8960.h>
 
 #include "qcom-msm8960.dtsi"
 #include "pm8921.dtsi"
-#include <dt-bindings/gpio/gpio.h>
-#include <dt-bindings/pinctrl/qcom,pmic-gpio.h>
-#include <dt-bindings/input/gpio-keys.h>
 
 / {
 	model = "Samsung Galaxy Express SGH-I437";
@@ -27,8 +27,8 @@ chosen {
 	gpio-keys {
 		compatible = "gpio-keys";
 
-		pinctrl-names = "default";
 		pinctrl-0 = <&gpio_keys_pin_a>;
+		pinctrl-names = "default";
 
 		key-home {
 			label = "Home";
@@ -54,58 +54,25 @@ key-volume-down {
 		};
 	};
 
-	touchkey_enable: touchkey-enable {
-		compatible = "regulator-fixed";
-		regulator-name = "touchkey_enable";
-		gpio = <&tlmm 51 GPIO_ACTIVE_HIGH>;
-		enable-active-high;
-		regulator-boot-on;
-	};
-
-	vreg_flash: regulator-flash {
-		compatible = "regulator-fixed";
-		regulator-name = "VREG_FLASH_3P3";
-		regulator-min-microvolt = <3300000>;
-		regulator-max-microvolt = <3300000>;
-		gpio = <&pm8921_mpps 4 GPIO_ACTIVE_HIGH>;
-		enable-active-high;
-		pinctrl-0 = <&flash_led_unlock>;
-		pinctrl-names = "default";
-	};
-
-	led-controller {
-		compatible = "richtek,rt8515";
-		enf-gpios = <&tlmm 3 GPIO_ACTIVE_HIGH>;
-		vin-supply = <&vreg_flash>;
-		richtek,rfs-ohms = <16000>;
-		pinctrl-0 = <&cam_flash_en>;
-		pinctrl-names = "default";
-
-		led {
-			function = LED_FUNCTION_FLASH;
-			color = <LED_COLOR_ID_WHITE>;
-			flash-max-timeout-us = <250000>;
-		};
-	};
-
 	i2c-gpio-touchkey {
 		compatible = "i2c-gpio";
 		#address-cells = <1>;
 		#size-cells = <0>;
 		sda-gpios = <&tlmm 71 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
 		scl-gpios = <&tlmm 72 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
-		pinctrl-names = "default";
 		pinctrl-0 = <&touchkey_i2c_pins>;
-		status = "okay";
+		pinctrl-names = "default";
 		i2c-gpio,delay-us = <2>;
 
+		status = "okay";
+
 		touchkey@20 {
 			compatible = "coreriver,tc360-touchkey";
 			reg = <0x20>;
 
 			interrupts-extended = <&tlmm 52 IRQ_TYPE_EDGE_FALLING>;
-			pinctrl-names = "default";
 			pinctrl-0 = <&touchkey_irq_pin>;
+			pinctrl-names = "default";
 
 			vddio-supply = <&touchkey_enable>;
 			vdd-supply = <&pm8921_l29>;
@@ -114,6 +81,52 @@ touchkey@20 {
 			linux,keycodes = <KEY_MENU KEY_BACK>;
 		};
 	};
+
+	led-controller {
+		compatible = "richtek,rt8515";
+		enf-gpios = <&tlmm 3 GPIO_ACTIVE_HIGH>;
+		vin-supply = <&vreg_flash>;
+		richtek,rfs-ohms = <16000>;
+		pinctrl-0 = <&cam_flash_en>;
+		pinctrl-names = "default";
+
+		led {
+			function = LED_FUNCTION_FLASH;
+			color = <LED_COLOR_ID_WHITE>;
+			flash-max-timeout-us = <250000>;
+		};
+	};
+
+	vreg_flash: regulator-flash {
+		compatible = "regulator-fixed";
+		regulator-name = "VREG_FLASH_3P3";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		gpio = <&pm8921_mpps 4 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+		pinctrl-0 = <&flash_led_unlock>;
+		pinctrl-names = "default";
+	};
+
+	touchkey_enable: touchkey-enable {
+		compatible = "regulator-fixed";
+		regulator-name = "touchkey_enable";
+		gpio = <&tlmm 51 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+		regulator-boot-on;
+	};
+};
+
+&gsbi1 {
+	qcom,mode = <GSBI_PROT_SPI>;
+	pinctrl-0 = <&spi1_default>;
+	pinctrl-names = "default";
+
+	status = "okay";
+};
+
+&gsbi1_spi {
+	status = "okay";
 };
 
 &gsbi2 {
@@ -141,51 +154,16 @@ light-sensor@39 {
 	};
 };
 
-&gsbi5 {
-	qcom,mode = <GSBI_PROT_I2C_UART>;
-	status = "okay";
-};
-
-&gsbi5_serial {
-	status = "okay";
-};
-
-&sdcc1 {
-	vmmc-supply = <&pm8921_l5>;
-	status = "okay";
-};
-
-&sdcc3 {
-	vmmc-supply = <&pm8921_l6>;
-	vqmmc-supply = <&pm8921_l7>;
-
-	pinctrl-0 = <&sdcc3_default_state>;
-	pinctrl-1 = <&sdcc3_sleep_state>;
-	pinctrl-names = "default", "sleep";
-
-	status = "okay";
-};
-
-&gsbi1 {
-	qcom,mode = <GSBI_PROT_SPI>;
-	pinctrl-0 = <&spi1_default>;
-	pinctrl-names = "default";
-	status = "okay";
-};
-
-&gsbi1_spi {
-	status = "okay";
-};
-
 &gsbi3 {
 	qcom,mode = <GSBI_PROT_I2C>;
+
 	status = "okay";
 };
 
 &gsbi3_i2c {
 	status = "okay";
 
-	// Atmel mXT224S touchscreen
+	/* Atmel mXT224S touchscreen */
 	touchscreen@4a {
 		compatible = "atmel,maxtouch";
 		reg = <0x4a>;
@@ -193,93 +171,69 @@ touchscreen@4a {
 		interrupts = <11 IRQ_TYPE_EDGE_FALLING>;
 		vdda-supply = <&pm8921_lvs6>;
 		vdd-supply = <&pm8921_l17>;
-		pinctrl-names = "default";
 		pinctrl-0 = <&touchscreen>;
+		pinctrl-names = "default";
 	};
 };
 
-&tlmm {
-	cam_flash_en: cam-flash-en-state {
-		pins = "gpio3";
-		function = "gpio";
-		drive-strength = <16>;
-		bias-pull-down;
-	};
+&gsbi5 {
+	qcom,mode = <GSBI_PROT_I2C_UART>;
 
-	spi1_default: spi1-default-state {
-		mosi-pins {
-			pins = "gpio6";
-			function = "gsbi1";
-			drive-strength = <12>;
-			bias-disable;
-		};
+	status = "okay";
+};
 
-		miso-pins {
-			pins = "gpio7";
-			function = "gsbi1";
-			drive-strength = <12>;
-			bias-disable;
-		};
+&gsbi5_serial {
+	status = "okay";
+};
 
-		cs-pins {
-			pins = "gpio8";
-			function = "gsbi1";
-			drive-strength = <12>;
-			bias-disable;
-			output-low;
-		};
+&gsbi7 {
+	qcom,mode = <GSBI_PROT_I2C>;
 
-		clk-pins {
-			pins = "gpio9";
-			function = "gsbi1";
-			drive-strength = <12>;
-			bias-disable;
-		};
-	};
+	status = "okay";
+};
 
-	gpio_keys_pin_a: gpio-keys-active-state {
-		pins = "gpio40", "gpio50", "gpio81";
-		function = "gpio";
-		drive-strength = <8>;
-		bias-disable;
-	};
+&gsbi7_i2c {
+	status = "okay";
 
-	touchscreen: touchscreen-int-state {
-		pins = "gpio11";
-		function = "gpio";
-		output-enable;
-		bias-disable;
-		drive-strength = <2>;
+	nfc@2b {
+		compatible = "nxp,pn544-i2c";
+		reg = <0x2b>;
+		interrupts-extended = <&tlmm 106 IRQ_TYPE_EDGE_RISING>;
+		enable-gpios = <&pm8921_gpio 21 GPIO_ACTIVE_HIGH>;
+		firmware-gpios = <&tlmm 92 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-0 = <&nfc_default &nfc_enable>;
+		pinctrl-names = "default";
 	};
+};
 
-	nfc_default: nfc-default-state {
-		irq-pins {
-			pins = "gpio106";
-			function = "gpio";
-			drive-strength = <2>;
-			bias-pull-down;
-		};
+&gsbi12 {
+	qcom,mode = <GSBI_PROT_I2C>;
 
-		firmware-pins {
-			pins = "gpio92";
-			function = "gpio";
-			drive-strength = <2>;
-			bias-disable;
-		};
-	};
+	status = "okay";
+};
 
-	touchkey_i2c_pins: touchkey-i2c-state {
-		pins = "gpio71", "gpio72";
-		function = "gpio";
-		drive-strength = <2>;
-		bias-disable;
+&gsbi12_i2c {
+	status = "okay";
+
+	accelerometer@18 {
+		compatible = "bosch,bma254";
+		reg = <0x18>;
+		vdd-supply = <&pm8921_l9>;
+		vddio-supply = <&pm8921_lvs4>;
+
+		mount-matrix =  "-1", "0", "0",
+				"0",  "-1", "0",
+				"0",  "0", "1";
 	};
 
-	touchkey_irq_pin: touchkey-irq-state {
-		pins = "gpio52";
-		function = "gpio";
-		drive-strength = <2>;
-		bias-disable;
+	magnetometer@2e {
+		compatible = "yamaha,yas532";
+		reg = <0x2e>;
+		vdd-supply = <&pm8921_l9>;
+		iovdd-supply = <&pm8921_lvs4>;
+
+		/* TODO: Figure out Mount Matrix */
 	};
 };
 
@@ -288,18 +242,27 @@ &pm8921 {
 };
 
 &pm8921_gpio {
+	nfc_enable: nfc-enable-state {
+		pins = "gpio21";
+		function = "normal";
+		bias-disable;
+		qcom,drive-strength = <PMIC_GPIO_STRENGTH_LOW>;
+		power-source = <PM8921_GPIO_S4>;
+	};
+
 	prox_sensor_int: prox-sensor-int-state {
 		pins = "gpio6";
 		function = "normal";
 		input-enable;
 		bias-disable;
 	};
+};
 
-	nfc_enable: nfc-enable-state {
-		pins = "gpio21";
-		function = "normal";
-		bias-disable;
-		qcom,drive-strength = <PMIC_GPIO_STRENGTH_LOW>;
+&pm8921_mpps {
+	flash_led_unlock: flash-led-unlock-state {
+		pins = "mpp4";
+		function = "digital";
+		output-low;
 		power-source = <PM8921_GPIO_S4>;
 	};
 };
@@ -546,72 +509,115 @@ pm8921_ncp: ncp {
 	};
 };
 
-&usb_hs1_phy {
-	v3p3-supply = <&pm8921_l3>;
-	v1p8-supply = <&pm8921_l4>;
-};
+&sdcc1 {
+	vmmc-supply = <&pm8921_l5>;
 
-&usb1 {
-	dr_mode = "otg";
 	status = "okay";
 };
 
-&gsbi7 {
-	qcom,mode = <GSBI_PROT_I2C>;
+&sdcc3 {
+	vmmc-supply = <&pm8921_l6>;
+	vqmmc-supply = <&pm8921_l7>;
+
+	pinctrl-0 = <&sdcc3_default_state>;
+	pinctrl-1 = <&sdcc3_sleep_state>;
+	pinctrl-names = "default", "sleep";
 
 	status = "okay";
 };
 
-&gsbi7_i2c {
-	status = "okay";
+&tlmm {
+	cam_flash_en: cam-flash-en-state {
+		pins = "gpio3";
+		function = "gpio";
+		drive-strength = <16>;
+		bias-pull-down;
+	};
 
-	nfc@2b {
-		compatible = "nxp,pn544-i2c";
-		reg = <0x2b>;
-		interrupts-extended = <&tlmm 106 IRQ_TYPE_EDGE_RISING>;
-		enable-gpios = <&pm8921_gpio 21 GPIO_ACTIVE_HIGH>;
-		firmware-gpios = <&tlmm 92 GPIO_ACTIVE_HIGH>;
+	spi1_default: spi1-default-state {
+		mosi-pins {
+			pins = "gpio6";
+			function = "gsbi1";
+			drive-strength = <12>;
+			bias-disable;
+		};
 
-		pinctrl-0 = <&nfc_default &nfc_enable>;
-		pinctrl-names = "default";
-	};
-};
+		miso-pins {
+			pins = "gpio7";
+			function = "gsbi1";
+			drive-strength = <12>;
+			bias-disable;
+		};
 
-&gsbi12 {
-	qcom,mode = <GSBI_PROT_I2C>;
+		cs-pins {
+			pins = "gpio8";
+			function = "gsbi1";
+			drive-strength = <12>;
+			bias-disable;
+			output-low;
+		};
 
-	status = "okay";
-};
+		clk-pins {
+			pins = "gpio9";
+			function = "gsbi1";
+			drive-strength = <12>;
+			bias-disable;
+		};
+	};
 
-&gsbi12_i2c {
-	status = "okay";
+	touchscreen: touchscreen-int-state {
+		pins = "gpio11";
+		function = "gpio";
+		output-enable;
+		bias-disable;
+		drive-strength = <2>;
+	};
 
-	accelerometer@18 {
-		compatible = "bosch,bma254";
-		reg = <0x18>;
-		vdd-supply = <&pm8921_l9>;
-		vddio-supply = <&pm8921_lvs4>;
+	gpio_keys_pin_a: gpio-keys-active-state {
+		pins = "gpio40", "gpio50", "gpio81";
+		function = "gpio";
+		drive-strength = <8>;
+		bias-disable;
+	};
 
-		mount-matrix =  "-1", "0", "0",
-				"0",  "-1", "0",
-				"0",  "0", "1";
+	touchkey_irq_pin: touchkey-irq-state {
+		pins = "gpio52";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
 	};
 
-	magnetometer@2e {
-		compatible = "yamaha,yas532";
-		reg = <0x2e>;
-		vdd-supply = <&pm8921_l9>;
-		iovdd-supply = <&pm8921_lvs4>;
+	touchkey_i2c_pins: touchkey-i2c-state {
+		pins = "gpio71", "gpio72";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
 
-		/* TODO: Figure out Mount Matrix */
+	nfc_default: nfc-default-state {
+		firmware-pins {
+			pins = "gpio92";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-disable;
+		};
+
+		irq-pins {
+			pins = "gpio106";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
 	};
 };
 
-&pm8921_mpps {
-	flash_led_unlock: flash-led-unlock-state {
-		pins = "mpp4";
-		function = "digital";
-		output-low;
-		power-source = <PM8921_GPIO_S4>;
-	};
+&usb_hs1_phy {
+	v3p3-supply = <&pm8921_l3>;
+	v1p8-supply = <&pm8921_l4>;
+};
+
+&usb1 {
+	dr_mode = "otg";
+
+	status = "okay";
 };

-- 
2.53.0

