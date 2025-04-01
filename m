From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 01 Apr 2025 10:06:22 +0800
Subject: [PATCH v2 2/2] dts: arm64: amlogic: add a5 pinctrl node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250401-a5-pinctrl-v2-2-a136c1058379@amlogic.com>
References: <20250401-a5-pinctrl-v2-0-a136c1058379@amlogic.com>
In-Reply-To: <20250401-a5-pinctrl-v2-0-a136c1058379@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743473181; l=3211;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=zTXCd3mjrQB2UAQ+DUxS9Et3VYgrEbPO04Lv0RVd3Dc=;
 b=NexDqmE4GpUbjiTbbLNR2qLQAsmCioHre9r9chGGwjRm9ULldqqOwImf0F8J+gzlrHik+F1CA
 ERHpBOEyZRnBEQE5MIpElVYAw2cvS8U6Z1Z1icqyRl4iW7LJi2o5hdC
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl device to support Amlogic A5.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi | 90 +++++++++++++++++++++++++++++
 1 file changed, 90 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
index 32ed1776891b..844302db2133 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
@@ -4,6 +4,7 @@
  */
 
 #include "amlogic-a4-common.dtsi"
+#include <dt-bindings/pinctrl/amlogic,pinctrl.h>
 #include <dt-bindings/power/amlogic,a5-pwrc.h>
 / {
 	cpus {
@@ -50,6 +51,95 @@ pwrc: power-controller {
 };
 
 &apb {
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

-- 
2.37.1

