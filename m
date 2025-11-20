From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 19 Nov 2025 23:14:43 -0800
Subject: [PATCH 2/4] ARM: dts: qcom: msm8960: expressatt: Add NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-expressatt_nfc_accel_magn_light-v1-2-636f16f05cf4@gmail.com>
References: <20251119-expressatt_nfc_accel_magn_light-v1-0-636f16f05cf4@gmail.com>
In-Reply-To: <20251119-expressatt_nfc_accel_magn_light-v1-0-636f16f05cf4@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763622884; l=1981;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=dhcYn18NjnrjN7FHJSqZT3TzBPkLXU1vzgXpjYyunrU=;
 b=zPt4+IsQkN5byXW7pHQhBS4whiJSKUQi6rLSi45YJogrIksS4H0sZyVYFOQcTa5G5HYb4JODs
 F3P+jp3pQ7pBhN3Xhi411EGaxsgZ8wANu4PjI9Wme/u5humWLQg6SUh
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pn544 NFC chip

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 46 ++++++++++++++++++++++
 1 file changed, 46 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 1e331a046e7b..81806d7ca001 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -77,6 +77,27 @@ light-sensor@39 {
 			pinctrl-0 = <&prox_sensor_int>;
 		};
 	};
+
+	i2c-gpio-nfc {
+		compatible = "i2c-gpio";
+		sda-gpios = <&tlmm 32 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		scl-gpios = <&tlmm 33 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		i2c-gpio,delay-us = <5>;
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		nfc@2b {
+			compatible = "nxp,pn544-i2c";
+			reg = <0x2b>;
+			interrupt-parent = <&tlmm>;
+			interrupts = <106 IRQ_TYPE_EDGE_RISING>;
+			enable-gpios = <&pm8921_gpio 21 GPIO_ACTIVE_HIGH>;
+			firmware-gpios = <&tlmm 92 GPIO_ACTIVE_HIGH>;
+
+			pinctrl-names = "default";
+			pinctrl-0 = <&nfc_default &nfc_enable>;
+		};
+	};
 };
 
 &gsbi5 {
@@ -182,6 +203,22 @@ touchscreen: touchscreen-int-state {
 		bias-disable;
 		drive-strength = <2>;
 	};
+
+	nfc_default: nfc-default-state {
+		irq-pins {
+			pins = "gpio106";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+
+		firmware-pins {
+			pins = "gpio92";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-disable;
+		};
+	};
 };
 
 &pm8921 {
@@ -195,6 +232,15 @@ prox_sensor_int: prox-sensor-int-state {
 		input-enable;
 		bias-disable;
 	};
+
+	nfc_enable: nfc-enable-state {
+		pins = "gpio21";
+		function = "normal";
+		output-low;
+		bias-disable;
+		qcom,drive-strength = <PMIC_GPIO_STRENGTH_LOW>;
+		power-source = <PM8921_GPIO_S4>;
+	};
 };
 
 &rpm {

-- 
2.51.2

