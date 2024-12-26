From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 26 Dec 2024 15:57:44 +0800
Subject: [PATCH v2 4/5] arm64: dts: amlogic: a4: add pinctrl node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241226-amlogic-pinctrl-v2-4-cdae42a67b76@amlogic.com>
References: <20241226-amlogic-pinctrl-v2-0-cdae42a67b76@amlogic.com>
In-Reply-To: <20241226-amlogic-pinctrl-v2-0-cdae42a67b76@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735199863; l=3914;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=wy3fQdz+SJH1zG7wVrB8eckpXy2HYaam9eL+Y9nbl3s=;
 b=kN7IwVc5y6ThjsD6DpFOEsjMxPyDZk3Ga4AWF+wOeiasE2uqnoKO82fg8hJzz7/kREdI3ITBG
 Mbw5goH9A1eBdwf7V8KCG+dtfLEVuTtWpxGKQDVQmjSO6uzohTLQRhJ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl device to support Amlogic A4 and add uart pinconf.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi | 133 ++++++++++++++++++++++++++++
 1 file changed, 133 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
index de10e7aebf21..90ef74b015bd 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
@@ -5,6 +5,7 @@
 
 #include "amlogic-a4-common.dtsi"
 #include <dt-bindings/power/amlogic,a4-pwrc.h>
+#include <dt-bindings/pinctrl/amlogic,pinctrl.h>
 / {
 	cpus {
 		#address-cells = <2>;
@@ -48,3 +49,135 @@ pwrc: power-controller {
 		};
 	};
 };
+
+&apb {
+	periphs_pinctrl: pinctrl@4000 {
+		compatible = "amlogic,pinctrl-a4";
+		reg = <0x0 0x4000 0x0 0x0050>,
+		      <0x0 0x40c0 0x0 0x0220>;
+		reg-names = "mux", "gpio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		gpiox: gpio@10 {
+			reg = <0x10>, <0x3>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			ngpios = <18>;
+			identity = <AMLOGIC_GPIO_X>;
+		};
+
+		gpiot: gpio@20 {
+			reg = <0x20>, <0xb>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			ngpios = <23>;
+			identity =  <AMLOGIC_GPIO_T>;
+		};
+
+		gpiod: gpio@30 {
+			reg = <0x30>, <0x10>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			ngpios = <16>;
+			identity = <AMLOGIC_GPIO_D>;
+		};
+
+		gpioe: gpio@40 {
+			reg = <0x40>, <0x12>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			ngpios = <2>;
+			identity = <AMLOGIC_GPIO_E>;
+		};
+
+		gpiob: gpio@60 {
+			reg = <0x60>, <0x0>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			ngpios = <14>;
+			identity = <AMLOGIC_GPIO_B>;
+		};
+
+		func-uart-a {
+			uart_a_default: uart-a-pins1 {
+				pinmux= <AML_PINMUX(AMLOGIC_GPIO_X, 11, AF1)>,
+					<AML_PINMUX(AMLOGIC_GPIO_X, 12, AF1)>,
+					<AML_PINMUX(AMLOGIC_GPIO_X, 13, AF1)>,
+					<AML_PINMUX(AMLOGIC_GPIO_X, 14, AF1)>;
+			};
+
+			uart-a-pins2 {
+				pinmux= <AML_PINMUX(AMLOGIC_GPIO_D, 2, AF3)>,
+					<AML_PINMUX(AMLOGIC_GPIO_D, 3, AF3)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+		};
+
+		func-uart-b {
+			uart_b_default: uart-b-pins {
+				pinmux= <AML_PINMUX(AMLOGIC_GPIO_E, 0, AF3)>,
+					<AML_PINMUX(AMLOGIC_GPIO_E, 1, AF3)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+		};
+
+		func-uart-d {
+			uart_d_default: uart-d-pins1 {
+				pinmux= <AML_PINMUX(AMLOGIC_GPIO_T, 18, AF4)>,
+					<AML_PINMUX(AMLOGIC_GPIO_T, 19, AF4)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+
+			uart-d-pins2 {
+				pinmux= <AML_PINMUX(AMLOGIC_GPIO_T, 7, AF2)>,
+					<AML_PINMUX(AMLOGIC_GPIO_T, 8, AF2)>,
+					<AML_PINMUX(AMLOGIC_GPIO_T, 9, AF2)>,
+					<AML_PINMUX(AMLOGIC_GPIO_T, 10, AF2)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+		};
+
+		func-uart-e {
+			uart_e_default: uart-e-pins {
+				pinmux= <AML_PINMUX(AMLOGIC_GPIO_T, 14, AF3)>,
+					<AML_PINMUX(AMLOGIC_GPIO_T, 15, AF3)>,
+					<AML_PINMUX(AMLOGIC_GPIO_T, 16, AF3)>,
+					<AML_PINMUX(AMLOGIC_GPIO_T, 17, AF3)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+		};
+	};
+
+	aobus_pinctrl: pinctrl@8e700 {
+		compatible = "amlogic,pinctrl-a4";
+		reg = <0x0 0x8e700 0x0 0x04>,
+		      <0x0 0x8e704 0x0 0x60>;
+		reg-names = "mux", "gpio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		gpioao: gpio@0 {
+			reg = <0x0>, <0x0>;
+			mask = <0xfffffff>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			ngpios = <7>;
+			identity = <AMLOGIC_GPIO_AO>;
+		};
+
+		test_n: gpio@10 {
+			reg = <0x10>, <0x0>;
+			mask = <0xf0000000>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			ngpios = <1>;
+			identity = <AMLOGIC_GPIO_TEST_N>;
+		};
+	};
+};

-- 
2.37.1

