From: Rudraksha Gupta <guptarud@gmail.com>
Date: Sat, 22 Nov 2025 22:44:44 -0800
Subject: [PATCH v3 3/5] ARM: dts: qcom: msm8960: expressatt: Add NFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251122-expressatt_nfc_accel_magn_light-v3-3-78d198632360@gmail.com>
References: <20251122-expressatt_nfc_accel_magn_light-v3-0-78d198632360@gmail.com>
In-Reply-To: <20251122-expressatt_nfc_accel_magn_light-v3-0-78d198632360@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763880283; l=1759;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=4tUA2e3lrT15JGSUIuN9jYYbDGE8RLLQOZp87biSr04=;
 b=elpCTggUpdmeSXJAxlNuwDwE/e5dQikpYtAJGqzgFOcunWcpmFVkWb98ncaB7NghUC21baW5B
 siLqByeP6BeBHtZ7nmbAkqXag2IOb4aYs2znqfWbiZHRRezZ/+cDm2N
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pn544 NFC chip

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 45 ++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 8d75ebd7976c..4f9b59db7bc3 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -182,6 +182,22 @@ touchscreen: touchscreen-int-state {
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
@@ -195,6 +211,14 @@ prox_sensor_int: prox-sensor-int-state {
 		input-enable;
 		bias-disable;
 	};
+
+	nfc_enable: nfc-enable-state {
+		pins = "gpio21";
+		function = "normal";
+		bias-disable;
+		qcom,drive-strength = <PMIC_GPIO_STRENGTH_LOW>;
+		power-source = <PM8921_GPIO_S4>;
+	};
 };
 
 &rpm {
@@ -442,3 +466,24 @@ &usb1 {
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
+		interrupts-extended = <&tlmm 106 IRQ_TYPE_EDGE_RISING>;
+		enable-gpios = <&pm8921_gpio 21 GPIO_ACTIVE_HIGH>;
+		firmware-gpios = <&tlmm 92 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-0 = <&nfc_default &nfc_enable>;
+		pinctrl-names = "default";
+	};
+};

-- 
2.52.0

