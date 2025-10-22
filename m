From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 22 Oct 2025 13:04:48 +0800
Subject: [PATCH v4] dts: arm64: amlogic: add a5 pinctrl node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251022-a5-pinctrl-node-v4-1-a71911852c4b@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAO9l+GgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyTHQUlJIzE
 vPSU3UzU4B8JSMDI1NDAyMj3URT3YLMvOSSohzdvPyUVF0LyxQzE/OkRCNLQzMloK6CotS0zAq
 widGxtbUABr6r+mEAAAA=
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761109488; l=3976;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=L4+dkNUItx+b/fyi3A8tosJY0LGL4pTf8lDMXXe1YgY=;
 b=KqEsemoMw7YudnhxpG8a8K0hlC5MigxSXpOLtE65kkqQNfDSatkjRHamxp/LTt8zeEV0aYLbL
 HJU3Pq1WekxAeaFZdDV4th4W9Q9/HSbWlW1Ql2LwPziS67L5L43YKK7
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl device to support Amlogic A5.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Add A5 pinctrl compatible string and device node.
---
Changes in v4:
- Rebase dts.
- Binding has already be accepted. This submission does not include this part.
- Link to v3: https://lore.kernel.org/all/20250403-a5-pinctrl-v3-0-a8c067e22295@amlogic.com

Changes in v3:
- Remain blank line.
- Link to v2: https://lore.kernel.org/r/20250401-a5-pinctrl-v2-0-a136c1058379@amlogic.com

Changes in v2:
- Modify bindings according to Conor's suggestion.
- Link to v1: https://lore.kernel.org/r/20250327-a5-pinctrl-v1-0-49320349c463@amlogic.com
---
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi | 90 +++++++++++++++++++++++++++++
 1 file changed, 90 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
index b1da8cbaa25a..2b12d8284594 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
@@ -5,6 +5,7 @@
 
 #include "amlogic-a4-common.dtsi"
 #include "amlogic-a5-reset.h"
+#include <dt-bindings/pinctrl/amlogic,pinctrl.h>
 #include <dt-bindings/power/amlogic,a5-pwrc.h>
 / {
 	cpus {
@@ -58,6 +59,95 @@ reset: reset-controller@2000 {
 		#reset-cells = <1>;
 	};
 
+	periphs_pinctrl: pinctrl@4000 {
+		compatible = "amlogic,pinctrl-a5",
+			     "amlogic,pinctrl-a4";
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges = <0x0 0x0 0x0 0x4000 0x0 0x300>;
+
+		gpioz: gpio@c0 {
+			reg = <0x0 0xc0 0x0 0x40>,
+			      <0x0 0x18 0x0 0x8>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_Z<<8) 16>;
+		};
+
+		gpiox: gpio@100 {
+			reg = <0x0 0x100 0x0 0x40>,
+			      <0x0 0xc   0x0 0xc>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_X<<8) 20>;
+		};
+
+		gpiot: gpio@140 {
+			reg = <0x0 0x140 0x0 0x40>,
+			      <0x0 0x2c  0x0 0x8>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_T<<8) 14>;
+		};
+
+		gpiod: gpio@180 {
+			reg = <0x0 0x180 0x0 0x40>,
+			      <0x0 0x40  0x0 0x8>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_D<<8) 16>;
+		};
+
+		gpioe: gpio@1c0 {
+			reg = <0x0 0x1c0 0x0 0x40>,
+			      <0x0 0x48  0x0 0x4>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_E<<8) 2>;
+		};
+
+		gpioc: gpio@200 {
+			reg = <0x0 0x200 0x0 0x40>,
+			      <0x0 0x24  0x0 0x8>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_C<<8) 11>;
+		};
+
+		gpiob: gpio@240 {
+			reg = <0x0 0x240 0x0 0x40>,
+			      <0x0 0x0   0x0 0x8>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_B<<8) 14>;
+		};
+
+		gpioh: gpio@280 {
+			reg = <0x0 0x280 0x0 0x40>,
+			      <0x0 0x4c  0x0 0x4>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_H<<8) 5>;
+		};
+
+		gpio_test_n: gpio@2c0 {
+			reg = <0x0 0x2c0 0x0 0x40>,
+			      <0x0 0x3c  0x0 0x4>;
+			reg-names = "gpio", "mux";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_TEST_N<<8) 1>;
+		};
+	};
+
 	gpio_intc: interrupt-controller@4080 {
 		compatible = "amlogic,a5-gpio-intc",
 			     "amlogic,meson-gpio-intc";

---
base-commit: ea528a07aae07a764babc0d92db55e2c0d68d414
change-id: 20251022-a5-pinctrl-node-89d647ba2916

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

