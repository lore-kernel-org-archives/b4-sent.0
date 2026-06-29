From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 29 Jun 2026 06:41:51 +0000
Subject: [PATCH] arm64: dts: amlogic: add some device nodes for A9
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-a9-node-v1-1-42ff6a0c16ab@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAK4TQmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMyNL3URL3bz8lFRd41SztOTUpETzZEsDJaDqgqLUtMwKsEnRsbW1AAQ
 6oYpZAAAA
X-Change-ID: 20260629-a9-node-3e6fceba7c90
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782715311; l=5289;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=qsqMagQntUJk2+7nKd+Qfbf+tdW0g4n8khbu2y9iCho=;
 b=38v+7CfaRd6EV/UMT6fu9MuQbrcIgyUeFJuxl0LYqrsoLtV/DjAjF56OEhN2PtvvEdaM63/yi
 3MKG7QMdJmpCYpV+E+ESfxUHLwaUcsBc5eB1zbSfnP3aa6ESTdb85vf
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl and irqchip-gpio device nodes for A9 SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Add pinctrl and irqchip-gpio device node for A9.
---
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi | 140 ++++++++++++++++++++++++++++
 1 file changed, 140 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
index 660c8556a864..cdc57b685cc3 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
@@ -6,6 +6,7 @@
 #include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/pinctrl/amlogic,pinctrl.h>
 
 / {
 	interrupt-parent = <&gic>;
@@ -97,6 +98,95 @@ soc {
 		#size-cells = <2>;
 		ranges;
 
+		apb: bus@fe000000 {
+			compatible = "simple-bus";
+			reg = <0x0 0xfe000000 0x0 0x480000>;
+			#address-cells = <2>;
+			#size-cells = <2>;
+			ranges = <0x0 0x0 0x0 0xfe000000 0x0 0x480000>;
+
+			periphs_pinctrl: pinctrl@4000 {
+				compatible = "amlogic,pinctrl-a9";
+				#address-cells = <2>;
+				#size-cells = <2>;
+				ranges = <0x0 0x0 0x0 0x4000 0x0 0x340>;
+
+				gpioz: gpio@c0 {
+					reg = <0 0xc0 0 0x20>, <0 0x18 0 0x8>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_Z<<8) 16>;
+				};
+
+				gpiox: gpio@100 {
+					reg = <0 0x100 0 0x24>, <0 0xc 0 0x8>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_X<<8) 18>;
+				};
+
+				gpioh: gpio@140 {
+					reg = <0 0x140 0 0x20>, <0 0x2c 0 0x4>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_H<<8) 8>;
+				};
+
+				gpiom: gpio@1a0 {
+					reg = <0 0x1a0 0 0x20>, <0 0x20 0 0x4>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_M<<8) 8>;
+				};
+
+				gpiob: gpio@240 {
+					reg = <0 0x240 0 0x20>, <0 0x0 0 0x8>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_B<<8) 14>;
+				};
+
+				gpioa: gpio@280 {
+					reg = <0 0x280 0 0x24>, <0 0x40 0 0xc>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_A<<8) 20>;
+				};
+
+				gpioy: gpio@2c0 {
+					reg = <0 0x2c0 0 0x20>, <0 0x30 0 0x8>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_Y<<8) 10>;
+				};
+
+				gpiocc: gpio@300 {
+					reg = <0 0x300 0 0x20>, <0 0x14 0 0x4>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_CC<<8) 2>;
+				};
+			};
+
+			gpio_intc: interrupt-controller@4080 {
+				compatible = "amlogic,a9-gpio-intc",
+					     "amlogic,meson-gpio-intc";
+				reg = <0x0 0x4080 0x0 0x20>;
+				interrupt-controller;
+				#interrupt-cells = <2>;
+				amlogic,channel-interrupts =
+					<10 11 12 13 14 15 16 17 18 19 20 21>;
+			};
+		};
+
 		gic: interrupt-controller@ff800000 {
 			compatible = "arm,gic-v3";
 			#interrupt-cells = <3>;
@@ -123,6 +213,56 @@ uart_b: serial@1e000 {
 				clock-names = "xtal", "pclk", "baud";
 				status = "disabled";
 			};
+
+			aobus_pinctrl: pinctrl@4000 {
+				compatible = "amlogic,pinctrl-a9";
+				#address-cells = <2>;
+				#size-cells = <2>;
+				ranges = <0x0 0x0 0x0 0x4000 0x0 0x0e0>;
+
+				gpioao: gpio@1c {
+					reg = <0 0x1c 0 0x20>, <0 0x0 0 0x8>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&aobus_pinctrl 0 (AMLOGIC_GPIO_AO<<8) 13>;
+				};
+
+				gpioc: gpio@3c {
+					reg = <0 0x3c 0 0x20>, <0 0x10 0 0x4>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&aobus_pinctrl 0 (AMLOGIC_GPIO_C<<8) 7>;
+				};
+
+				gpiod: gpio@5c {
+					reg = <0 0x5c 0 0x24>, <0 0x8 0 0x8>;
+					reg-names = "gpio", "mux";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&aobus_pinctrl 0 (AMLOGIC_GPIO_D<<8) 18>;
+				};
+
+				test_n: gpio@c0 {
+					reg = <0 0xc0 0 0x20>;
+					reg-names = "gpio";
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&aobus_pinctrl 0 (AMLOGIC_GPIO_TEST_N<<8) 1>;
+				};
+			};
+
+			gpio_ao_intc: interrupt-controller@4080 {
+				compatible = "amlogic,a9-gpio-ao-intc",
+					     "amlogic,meson-gpio-intc";
+				reg = <0x0 0x4080 0x0 0x34>;
+				interrupt-controller;
+				#interrupt-cells = <2>;
+				amlogic,channel-interrupts =
+					<384 385 386 387 388 389 390 391 392 393
+					394 395 396 397 398 399 400 401 402 403>;
+			};
 		};
 	};
 };

---
base-commit: 3d5670d672ae08b8c534b7beed6f57c8b44e7b43
change-id: 20260629-a9-node-3e6fceba7c90

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

