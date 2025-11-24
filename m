From: Rudraksha Gupta <guptarud@gmail.com>
Date: Mon, 24 Nov 2025 15:35:22 -0800
Subject: [PATCH v4 1/6] ARM: dts: qcom: msm8960: Add GSBI2 & GSBI7
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251124-expressatt_nfc_accel_magn_light-v4-1-9c5686ad67e2@gmail.com>
References: <20251124-expressatt_nfc_accel_magn_light-v4-0-9c5686ad67e2@gmail.com>
In-Reply-To: <20251124-expressatt_nfc_accel_magn_light-v4-0-9c5686ad67e2@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764027322; l=3530;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=2ICK00hH1Y/N2rJ/MOOdERF0k2Q1yj8a78xAIbTZBmM=;
 b=w+Q1wXcA+pl4cElR8vnSs1pzXal1tF9gtXfSuCZto/zgui52WO97NN00bbml9YgVx8n+jHXUS
 V4EHh0hKs/+BkwZZnv3VGVHfhs943XOMRp5jOk8+DLqAC2J0efq8Vf6
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the GSBI2 & GSBI7 Node, which is similar to the
other GSBI nodes in this file.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi | 96 ++++++++++++++++++++++++++++++++
 1 file changed, 96 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
index 38bd4fd8dda5..fd28401cebb5 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960.dtsi
@@ -149,6 +149,24 @@ i2c1-pins {
 				};
 			};
 
+			i2c2_default_state: i2c2-default-state {
+				i2c2-pins {
+					pins = "gpio12", "gpio13";
+					function = "gsbi2";
+					drive-strength = <8>;
+					bias-disable;
+				};
+			};
+
+			i2c2_sleep_state: i2c2-sleep-state {
+				i2c2-pins {
+					pins = "gpio12", "gpio13";
+					function = "gpio";
+					drive-strength = <2>;
+					bias-bus-hold;
+				};
+			};
+
 			i2c3_default_state: i2c3-default-state {
 				i2c3-pins {
 					pins = "gpio16", "gpio17";
@@ -167,6 +185,24 @@ i2c3-pins {
 				};
 			};
 
+			i2c7_default_state: i2c7-default-state {
+				i2c7-pins {
+					pins = "gpio32", "gpio33";
+					function = "gsbi7";
+					drive-strength = <8>;
+					bias-disable;
+				};
+			};
+
+			i2c7_sleep_state: i2c7-sleep-state {
+				i2c7-pins {
+					pins = "gpio32", "gpio33";
+					function = "gpio";
+					drive-strength = <2>;
+					bias-bus-hold;
+				};
+			};
+
 			i2c8_default_state: i2c8-default-state {
 				i2c8-pins {
 					pins = "gpio36", "gpio37";
@@ -543,6 +579,36 @@ gsbi1_spi: spi@16080000 {
 			};
 		};
 
+		gsbi2: gsbi@16100000 {
+			compatible = "qcom,gsbi-v1.0.0";
+			reg = <0x16100000 0x100>;
+			ranges;
+			cell-index = <2>;
+			clocks = <&gcc GSBI2_H_CLK>;
+			clock-names = "iface";
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			status = "disabled";
+
+			gsbi2_i2c: i2c@16180000 {
+				compatible = "qcom,i2c-qup-v1.1.1";
+				reg = <0x16180000 0x1000>;
+				pinctrl-0 = <&i2c2_default_state>;
+				pinctrl-1 = <&i2c2_sleep_state>;
+				pinctrl-names = "default", "sleep";
+				interrupts = <GIC_SPI 149 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&gcc GSBI2_QUP_CLK>,
+					 <&gcc GSBI2_H_CLK>;
+				clock-names = "core",
+					      "iface";
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				status = "disabled";
+			};
+		};
+
 		gsbi3: gsbi@16200000 {
 			compatible = "qcom,gsbi-v1.0.0";
 			reg = <0x16200000 0x100>;
@@ -600,6 +666,36 @@ gsbi5_serial: serial@16440000 {
 			};
 		};
 
+		gsbi7: gsbi@16600000 {
+			compatible = "qcom,gsbi-v1.0.0";
+			reg = <0x16600000 0x100>;
+			ranges;
+			cell-index = <7>;
+			clocks = <&gcc GSBI7_H_CLK>;
+			clock-names = "iface";
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			status = "disabled";
+
+			gsbi7_i2c: i2c@16680000 {
+				compatible = "qcom,i2c-qup-v1.1.1";
+				reg = <0x16680000 0x1000>;
+				pinctrl-0 = <&i2c7_default_state>;
+				pinctrl-1 = <&i2c7_sleep_state>;
+				pinctrl-names = "default", "sleep";
+				interrupts = <GIC_SPI 159 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&gcc GSBI7_QUP_CLK>,
+					 <&gcc GSBI7_H_CLK>;
+				clock-names = "core",
+					      "iface";
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				status = "disabled";
+			};
+		};
+
 		gsbi8: gsbi@1a000000 {
 			compatible = "qcom,gsbi-v1.0.0";
 			reg = <0x1a000000 0x100>;

-- 
2.52.0

