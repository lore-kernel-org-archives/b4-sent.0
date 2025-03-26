From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 26 Mar 2025 13:17:16 +0800
Subject: [PATCH] arm64: dts: amlogic: a4: add pinctrl node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250326-pinctrl-node-a4-v1-1-8c30639480f6@amlogic.com>
X-B4-Tracking: v=1; b=H4sIANuN42cC/x2MQQqAIBAAvxJ7TjBLi74SHUy3WggVjQjEvyfBX
 OYwkyFhJEwwNxkiPpTIuypd24A5tTuQka0OggvJeyFZIGfueDHnLTI9VJQarUQzmQ1qFSLu9P7
 HZS3lA03gC7thAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742966241; l=5053;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=71qIP+ef+rZamoMp2uHsnRGLP/3xxQGVfKdovCE34Gg=;
 b=VtxrAX3CV74cDeafGJLPn8y7m2o7qUtmyDz70JtDk8R1Zwv5Kpd1CE8gJAHcAZ8ZRpSSIPEkb
 CTZNM18bRQcDo6ArOAFQk1qsKOX7m1daledgaQMtNgWGbZK92ilb2VF
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl device to support Amlogic A4 and add uart pinconf.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
This commit is based on the Neil's suggestion, rebase the commit on top of
https://web.git.kernel.org/pub/scm/linux/kernel/git/soc/soc.git/log/?h=for-next 
which merges this commit:
https://lore.kernel.org/all/20250212-amlogic-pinctrl-v5-4-282bc2516804@amlogic.com/
with another one:
https://lore.kernel.org/all/20250321-fix-a4-pinctrl-node-v1-1-5719f9f09932@amlogic.com/
---
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi | 125 ++++++++++++++++++++++++++++
 1 file changed, 125 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
index a06838552f21..c02fa5ee9fd2 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
@@ -5,6 +5,7 @@
 
 #include "amlogic-a4-common.dtsi"
 #include <dt-bindings/power/amlogic,a4-pwrc.h>
+#include <dt-bindings/pinctrl/amlogic,pinctrl.h>
 / {
 	cpus {
 		#address-cells = <2>;
@@ -50,6 +51,107 @@ pwrc: power-controller {
 };
 
 &apb {
+	periphs_pinctrl: pinctrl@4000 {
+		compatible = "amlogic,pinctrl-a4";
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges = <0x0 0x0 0x0 0x4000 0x0 0x280>;
+
+		gpiox: gpio@100 {
+			reg = <0 0x100 0 0x40>, <0 0xc 0 0xc>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_X<<8) 18>;
+		};
+
+		gpiot: gpio@140 {
+			reg = <0 0x140 0 0x40>, <0 0x2c 0 0xc>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_T<<8) 23>;
+		};
+
+		gpiod: gpio@180 {
+			reg = <0 0x180 0 0x40>, <0 0x40 0 0x8>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_D<<8) 16>;
+		};
+
+		gpioe: gpio@1c0 {
+			reg = <0 0x1c0 0 0x40>, <0 0x48 0 0x4>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_E<<8) 2>;
+		};
+
+		gpiob: gpio@240 {
+			reg = <0 0x240 0 0x40>, <0 0 0 0x8>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_B<<8) 14>;
+		};
+
+		func-uart-a {
+			uart_a_default: group-uart-a-pins1 {
+				pinmux = <AML_PINMUX(AMLOGIC_GPIO_X, 11, 1)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_X, 12, 1)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_X, 13, 1)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_X, 14, 1)>;
+			};
+
+			group-uart-a-pins2 {
+				pinmux = <AML_PINMUX(AMLOGIC_GPIO_D, 2, 3)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_D, 3, 3)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+		};
+
+		func-uart-b {
+			uart_b_default: group-uart-b-pins {
+				pinmux = <AML_PINMUX(AMLOGIC_GPIO_E, 0, 3)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_E, 1, 3)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+		};
+
+		func-uart-d {
+			uart_d_default: group-uart-d-pins1 {
+				pinmux = <AML_PINMUX(AMLOGIC_GPIO_T, 18, 4)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_T, 19, 4)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+
+			group-uart-d-pins2 {
+				pinmux = <AML_PINMUX(AMLOGIC_GPIO_T, 7, 2)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_T, 8, 2)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_T, 9, 2)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_T, 10, 2)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+		};
+
+		func-uart-e {
+			uart_e_default: group-uart-e-pins {
+				pinmux = <AML_PINMUX(AMLOGIC_GPIO_T, 14, 3)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_T, 15, 3)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_T, 16, 3)>,
+					 <AML_PINMUX(AMLOGIC_GPIO_T, 17, 3)>;
+				bias-pull-up;
+				drive-strength-microamp = <4000>;
+			};
+		};
+	};
+
 	gpio_intc: interrupt-controller@4080 {
 		compatible = "amlogic,a4-gpio-intc",
 			     "amlogic,meson-gpio-intc";
@@ -60,6 +162,29 @@ gpio_intc: interrupt-controller@4080 {
 			<10 11 12 13 14 15 16 17 18 19 20 21>;
 	};
 
+	ao_pinctrl: pinctrl@8e700 {
+		compatible = "amlogic,pinctrl-a4";
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges = <0x0 0x0 0x0 0x8e700 0x0 0x80>;
+
+		gpioao: gpio@4 {
+			reg = <0 0x4 0 0x16>, <0 0 0 0x4>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_AO<<8) 7>;
+		};
+
+		test_n: gpio@44 {
+			reg = <0 0x44 0 0x20>;
+			reg-names = "gpio";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_TEST_N<<8) 1>;
+		};
+	};
+
 	gpio_ao_intc: interrupt-controller@8e72c {
 		compatible = "amlogic,a4-gpio-ao-intc",
 			     "amlogic,meson-gpio-intc";

---
base-commit: 23a708916ec7ab21c8c81d61bdb7cb933f6867d5
change-id: 20250325-pinctrl-node-a4-a4667d5ec8cb

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

