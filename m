From: Biswapriyo Nath <nathbappai@gmail.com>
Date: Mon, 19 Jan 2026 15:13:06 +0000
Subject: [PATCH 4/5] arm64: dts: qcom: sm6125: Add debug UART node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-xiaomi-ginkgo-features-v1-4-3c8fae984bda@gmail.com>
References: <20260119-xiaomi-ginkgo-features-v1-0-3c8fae984bda@gmail.com>
In-Reply-To: <20260119-xiaomi-ginkgo-features-v1-0-3c8fae984bda@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Biswapriyo Nath <nathbappai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768835583; l=1329;
 i=nathbappai@gmail.com; s=20260118; h=from:subject:message-id;
 bh=KVbPa/81u22X0TJfXKboPaS8uo5cWF/0FGi0WwZiud4=;
 b=8CS0UHk41J+yopC7u3ggV4qCUDLXebRujYHuB94+f/0iHUIwbQ2uv8MVaUsCWyG6WWZDfEiRj
 3J+7nsQ+7r5CCYcYnNJzNPESksVCuwf/7dWBfjHAOn0HdbUIqSlKj9b
X-Developer-Key: i=nathbappai@gmail.com; a=ed25519;
 pk=slmb/9yXbet+KTiT3EYLCp0p0MEOYa3EdjUXP+HXfjg=
X-Endpoint-Received: by B4 Relay for nathbappai@gmail.com/20260118 with auth_id=607
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qup0 on sm6125 has 6 SEs and SE4 is used as debug uart. The uart node
and the associated pinctrl are added here.

Signed-off-by: Biswapriyo Nath <nathbappai@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm6125.dtsi | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm6125.dtsi b/arch/arm64/boot/dts/qcom/sm6125.dtsi
index e60d4d74c..0540fb865 100644
--- a/arch/arm64/boot/dts/qcom/sm6125.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm6125.dtsi
@@ -661,6 +661,13 @@ qup_spi9_sleep: qup-spi9-sleep-state {
 				drive-strength = <6>;
 				bias-disable;
 			};
+
+			qup_uart4_default: qup-uart4-default-state {
+				pins = "gpio16", "gpio17";
+				function = "qup04";
+				drive-strength = <2>;
+				bias-disable;
+			};
 		};
 
 		gcc: clock-controller@1400000 {
@@ -985,6 +992,17 @@ i2c4: i2c@4a90000 {
 				#size-cells = <0>;
 				status = "disabled";
 			};
+
+			uart4: serial@4a90000 {
+				compatible = "qcom,geni-debug-uart";
+				reg = <0x04a90000 0x4000>;
+				clocks = <&gcc GCC_QUPV3_WRAP0_S4_CLK>;
+				clock-names = "se";
+				interrupts = <GIC_SPI 331 IRQ_TYPE_LEVEL_HIGH>;
+				pinctrl-0 = <&qup_uart4_default>;
+				pinctrl-names = "default";
+				status = "disabled";
+			};
 		};
 
 		gpi_dma1: dma-controller@4c00000 {

-- 
2.52.0

