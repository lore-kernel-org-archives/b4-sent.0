From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 01 Apr 2026 13:32:15 -0700
Subject: [PATCH v3 3/4] ARM: dts: qcom: msm8960: Add GSBI5 I2C controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-expressatt_fuel_guage-v3-3-9674cfc0b5a2@gmail.com>
References: <20260401-expressatt_fuel_guage-v3-0-9674cfc0b5a2@gmail.com>
In-Reply-To: <20260401-expressatt_fuel_guage-v3-0-9674cfc0b5a2@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775075533; l=1769;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=Gq2ZOsf1+PUrTIP7d32BgUfFC8VGna7SqX4ihp3Y+5c=;
 b=ENAUCLk3ske828CQibam5xXcn88ce3y2WOGib9+IkR+TeTg5FynzSB1m0mSPdAJDPaWv2aL/l
 qW1GKHys8LmCJOKqlekazU+8tExTTLH4/LHEU0fmp2odLLL26dMCfpa
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the I2C controller node for GSBI5 (gpio24/gpio25) alongside
its pinctrl default and sleep states.

Assisted-by: Claude:claude-opus-4.6
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi | 31 +++++++++++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
index 6069fb925672..a427f0f41cd1 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
@@ -173,6 +173,20 @@ i2c3_sleep_state: i2c3-sleep-state {
 				bias-bus-hold;
 			};
 
+			i2c5_default_state: i2c5-default-state {
+				pins = "gpio24", "gpio25";
+				function = "gsbi5";
+				drive-strength = <8>;
+				bias-disable;
+			};
+
+			i2c5_sleep_state: i2c5-sleep-state {
+				pins = "gpio24", "gpio25";
+				function = "gpio";
+				drive-strength = <2>;
+				bias-bus-hold;
+			};
+
 			i2c7_default_state: i2c7-default-state {
 				pins = "gpio32", "gpio33";
 				function = "gsbi7";
@@ -636,6 +650,23 @@ gsbi5_serial: serial@16440000 {
 
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

