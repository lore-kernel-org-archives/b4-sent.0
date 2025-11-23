From: Rudraksha Gupta <guptarud@gmail.com>
Date: Sat, 22 Nov 2025 22:44:43 -0800
Subject: [PATCH v3 2/5] ARM: dts: qcom: msm8960: expressatt: Add
 Light/Proximity Sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251122-expressatt_nfc_accel_magn_light-v3-2-78d198632360@gmail.com>
References: <20251122-expressatt_nfc_accel_magn_light-v3-0-78d198632360@gmail.com>
In-Reply-To: <20251122-expressatt_nfc_accel_magn_light-v3-0-78d198632360@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763880283; l=1637;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=yZG1sZBCe3vOBZ7yKg0s6tW7F4POpCoTYx3Ig3XEUjI=;
 b=yUo/JTPB7nKxIOQKKayP3rdVh732xy1uVklwBjqYd0HFjnIvL8MGuIogHLxojduLRypDWMTGI
 EaOF5mKCynWDB5ZaqoQtVfvIQoRA7OPKvAUzUNmsR2fJwxq5fSVm8Yw
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the Proximity Sensor doesn't work, but light sensor does.
Left the proximity sensor as a TODO for later.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 34 ++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 5ee919dce75b..8d75ebd7976c 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -54,6 +54,31 @@ key-volume-down {
 	};
 };
 
+&gsbi2 {
+	qcom,mode = <GSBI_PROT_I2C>;
+
+	status = "okay";
+};
+
+&gsbi2_i2c {
+	status = "okay";
+
+	light-sensor@39 {
+		compatible = "amstaos,tmd2772";
+		reg = <0x39>;
+		interrupts-extended = <&pm8921_gpio 6 IRQ_TYPE_EDGE_FALLING>;
+		vdd-supply = <&pm8921_l9>;
+		vddio-supply = <&pm8921_lvs4>;
+
+		/* TODO: Proximity doesn't work */
+		amstaos,proximity-diodes = <0>;
+		led-max-microamp = <100000>;
+
+		pinctrl-0 = <&prox_sensor_int>;
+		pinctrl-names = "default";
+	};
+};
+
 &gsbi5 {
 	qcom,mode = <GSBI_PROT_I2C_UART>;
 	status = "okay";
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

-- 
2.52.0

