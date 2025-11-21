From: Rudraksha Gupta <guptarud@gmail.com>
Date: Fri, 21 Nov 2025 03:44:46 -0800
Subject: [PATCH v2 3/5] ARM: dts: qcom: msm8960: expressatt: Add NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251121-expressatt_nfc_accel_magn_light-v2-3-54ce493cc6cf@gmail.com>
References: <20251121-expressatt_nfc_accel_magn_light-v2-0-54ce493cc6cf@gmail.com>
In-Reply-To: <20251121-expressatt_nfc_accel_magn_light-v2-0-54ce493cc6cf@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763725484; l=1792;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=ywA6A/wAd3sgOXwQKxeyI+0SdP9uGLkdoUuFJZ9N9XQ=;
 b=KgdkXCFJyXfp+vFMttsgXJwr8IaSOs5WruELVVpegkVAEV36a+GeUuyq9HuMmrb6B2VJ/H1+x
 7y5Va4T2aCnDeQfLf0Mdxm/xuBwmTl2Zi2oOvUxHzrESZsUrUDJ3uDd
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pn544 NFC chip

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 47 ++++++++++++++++++++++
 1 file changed, 47 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index b68da548a985..0d6d38b57f00 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -183,6 +183,22 @@ touchscreen: touchscreen-int-state {
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
@@ -196,6 +212,15 @@ prox_sensor_int: prox-sensor-int-state {
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
@@ -443,3 +468,25 @@ &usb1 {
 	dr_mode = "otg";
 	status = "okay";
 };
+
+&gsbi7 {
+	qcom,mode = <GSBI_PROT_I2C>;
+
+	status = "okay";
+};
+
+&gsbi7_i2c {
+	status = "okay";
+
+	nfc@2b {
+		compatible = "nxp,pn544-i2c";
+		reg = <0x2b>;
+		interrupt-parent = <&tlmm>;
+		interrupts = <106 IRQ_TYPE_EDGE_RISING>;
+		enable-gpios = <&pm8921_gpio 21 GPIO_ACTIVE_HIGH>;
+		firmware-gpios = <&tlmm 92 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-names = "default";
+		pinctrl-0 = <&nfc_default &nfc_enable>;
+	};
+};

-- 
2.51.2

