From: Rudraksha Gupta <guptarud@gmail.com>
Date: Fri, 21 Nov 2025 03:44:45 -0800
Subject: [PATCH v2 2/5] ARM: dts: qcom: msm8960: expressatt: Add
 Light/Proximity Sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251121-expressatt_nfc_accel_magn_light-v2-2-54ce493cc6cf@gmail.com>
References: <20251121-expressatt_nfc_accel_magn_light-v2-0-54ce493cc6cf@gmail.com>
In-Reply-To: <20251121-expressatt_nfc_accel_magn_light-v2-0-54ce493cc6cf@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763725484; l=1593;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=fp56hpEySbYXEo/V+MxITO76io+YujyO0uohNV0UvEM=;
 b=oKWV+NBFp2+L0ZLUEwhhcyYdcaSafPzXFKeikVAe5qA0sDtTWMhijnwT3zaSww1V3zqSsZpoA
 IqaaZF3Cy2VDvalvGPtsC8YVZEQg5ldFv+qwNBuSPuQRL3p2xtm/ATe
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the Proximity Sensor doesn't work, but light sensor does.
Left the proximity sensor as a TODO for later.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 35 ++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 5ee919dce75b..b68da548a985 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -54,6 +54,32 @@ key-volume-down {
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
+		interrupt-parent = <&pm8921_gpio>;
+		interrupts = <6 IRQ_TYPE_EDGE_FALLING>;
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
@@ -163,6 +189,15 @@ &pm8921 {
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
2.51.2

