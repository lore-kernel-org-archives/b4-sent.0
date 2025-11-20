From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 19 Nov 2025 23:14:42 -0800
Subject: [PATCH 1/4] ARM: dts: qcom: msm8960: expressatt: Add
 Light/Proximity Sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-expressatt_nfc_accel_magn_light-v1-1-636f16f05cf4@gmail.com>
References: <20251119-expressatt_nfc_accel_magn_light-v1-0-636f16f05cf4@gmail.com>
In-Reply-To: <20251119-expressatt_nfc_accel_magn_light-v1-0-636f16f05cf4@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763622884; l=2089;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=3y/PevugngpXnTyFIerATqp8HygnxRp+u1TfLII58QU=;
 b=LagrKQ+BSjYyxXq0usvsRwsh+wEO+8m2HP/0WG/GjT0hVI/WolqnLCIkdtwbUcrMQIT3cnjO+
 IBWkE9OOAA7DRAFNROgjj8gjJUbfv0N7XDg5uWtF7JCgVGmNz7N8EoO
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the Proximity Sensor doesn't work, but light sensor does.
Left the proximity sensor as a TODO for later.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 36 ++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 5ee919dce75b..1e331a046e7b 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -52,6 +52,31 @@ key-volume-down {
 			linux,code = <KEY_VOLUMEDOWN>;
 		};
 	};
+
+	i2c-gpio-sensors {
+		compatible = "i2c-gpio";
+		sda-gpios = <&tlmm 12 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		scl-gpios = <&tlmm 13 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		i2c-gpio,delay-us = <5>;
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		light-sensor@39 {
+			compatible = "amstaos,tmd2772";
+			reg = <0x39>;
+			interrupt-parent = <&pm8921_gpio>;
+			interrupts = <6 IRQ_TYPE_EDGE_FALLING>;
+			vdd-supply = <&pm8921_l9>;
+			vddio-supply = <&pm8921_lvs4>;
+
+			// TODO: Proximity doesn't work
+			amstaos,proximity-diodes = <0>;
+			led-max-microamp = <100000>;
+
+			pinctrl-names = "default";
+			pinctrl-0 = <&prox_sensor_int>;
+		};
+	};
 };
 
 &gsbi5 {
@@ -163,6 +188,15 @@ &pm8921 {
 	interrupts-extended = <&tlmm 104 IRQ_TYPE_LEVEL_LOW>;
 };
 
+&pm8921_gpio {
+	prox_sensor_int: prox-sensor-int-state {
+		pins = "gpio6";
+		function = "normal";
+		input-enable;
+		bias-disable;
+	};
+};
+
 &rpm {
 	regulators {
 		compatible = "qcom,rpm-pm8921-regulators";
@@ -280,6 +314,7 @@ pm8921_l9: l9 {
 			regulator-min-microvolt = <2850000>;
 			regulator-max-microvolt = <2850000>;
 			bias-pull-down;
+			regulator-always-on;
 		};
 
 		pm8921_l10: l10 {
@@ -377,6 +412,7 @@ pm8921_lvs3: lvs3 {
 
 		pm8921_lvs4: lvs4 {
 			bias-pull-down;
+			regulator-always-on;
 		};
 
 		pm8921_lvs5: lvs5 {

-- 
2.51.2

