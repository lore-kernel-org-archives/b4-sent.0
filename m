From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 01 Apr 2026 01:28:49 -0700
Subject: [PATCH v2 2/3] ARM: dts: qcom: msm8960: Add GSBI5 I2C controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-expressatt_fuel_guage-v2-2-947922834df1@gmail.com>
References: <20260401-expressatt_fuel_guage-v2-0-947922834df1@gmail.com>
In-Reply-To: <20260401-expressatt_fuel_guage-v2-0-947922834df1@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775032128; l=1727;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=8/RzBwh/fES/8HrOxicZH3ECPDErdir+yKEmOkH4FcM=;
 b=8RY/XE8pPT2II/im619+VCBP8uFt53wYimEnOrLUp4SSUXalABE3APqROdSjgCrWwzafpO9rR
 lKqURR7o3zlAYZl6faRq4dyyPRBMkOPt35uxWs+Vc6dHHIDZVVyBQJo
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the I2C controller node for GSBI5 (gpio24/gpio25) alongside
its pinctrl default and sleep states.

Assisted-by: Claude:claude-opus-4.6
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi | 35 ++++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
index fd28401cebb5..2088baef6c30 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
@@ -185,6 +185,24 @@ i2c3-pins {
 				};
 			};
 
+			i2c5_default_state: i2c5-default-state {
+				i2c5-pins {
+					pins = "gpio24", "gpio25";
+					function = "gsbi5";
+					drive-strength = <8>;
+					bias-disable;
+				};
+			};
+
+			i2c5_sleep_state: i2c5-sleep-state {
+				i2c5-pins {
+					pins = "gpio24", "gpio25";
+					function = "gpio";
+					drive-strength = <2>;
+					bias-bus-hold;
+				};
+			};
+
 			i2c7_default_state: i2c7-default-state {
 				i2c7-pins {
 					pins = "gpio32", "gpio33";
@@ -664,6 +682,23 @@ gsbi5_serial: serial@16440000 {
 
 				status = "disabled";
 			};
+
+			gsbi5_i2c: i2c@16480000 {
+				compatible = "qcom,i2c-qup-v1.1.1";
+				reg = <0x16480000 0x1000>;
+				pinctrl-0 = <&i2c5_default_state>;
+				pinctrl-1 = <&i2c5_sleep_state>;
+				pinctrl-names = "default", "sleep";
+				interrupts = <GIC_SPI 155 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&gcc GSBI5_QUP_CLK>,
+					 <&gcc GSBI5_H_CLK>;
+				clock-names = "core",
+					      "iface";
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				status = "disabled";
+			};
 		};
 
 		gsbi7: gsbi@16600000 {

-- 
2.53.0

