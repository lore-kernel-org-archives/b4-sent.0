From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 13 Oct 2026 09:07:18 +0300
Subject: [PATCH v3 08/11] ARM: dts: cortina: cs7542: Add interrupt
 controller, GPIO and I2C
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-cs75xx-s2-v3-8-181bb0d23f4c@gmail.com>
References: <20261013-b4-cs75xx-s2-v3-0-181bb0d23f4c@gmail.com>
In-Reply-To: <20261013-b4-cs75xx-s2-v3-0-181bb0d23f4c@gmail.com>
To: Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-i2c@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791871630; l=2798;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=3Upc60FD1EM1O4fIft/ek4FPT0icYaZ8EOrDpkRXA2U=;
 b=1lfpKAPeHzSXG/MvuC+AiqhJX9yrGGPwUUcYkbJUkQFzFQ9xi47lyazZYLjMWjRTKGUxRPtsp
 NvLHYt3RgakCj+hAomp2xcdw/5r1ZiZ1y+I0hQLHwXg1IukbhWqht75
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the peripheral interrupt controller, the five GPIO banks and
the I2C controller of the CS7542.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 arch/arm/boot/dts/cortina/cs7542.dtsi | 75 +++++++++++++++++++++++++++++++++++
 1 file changed, 75 insertions(+)

diff --git a/arch/arm/boot/dts/cortina/cs7542.dtsi b/arch/arm/boot/dts/cortina/cs7542.dtsi
index 29b0b7da8..c88449c54 100644
--- a/arch/arm/boot/dts/cortina/cs7542.dtsi
+++ b/arch/arm/boot/dts/cortina/cs7542.dtsi
@@ -44,6 +44,26 @@ soc {
 		#address-cells = <1>;
 		#size-cells = <1>;
 
+		intc: interrupt-controller@f0070004 {
+			compatible = "cortina,cs7542-intc";
+			reg = <0xf0070004 0x8>;
+			interrupts = <GIC_SPI 3 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-controller;
+			#interrupt-cells = <1>;
+		};
+
+		i2c: i2c@f00700e8 {
+			compatible = "cortina,cs7542-i2c";
+			reg = <0xf00700e8 0x28>;
+			interrupt-parent = <&intc>;
+			interrupts = <11>;
+			clocks = <&apb_clk>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
 		uart0: serial@f0070110 {
 			compatible = "cortina,cs7542-uart";
 			reg = <0xf0070110 0x30>;
@@ -80,6 +100,61 @@ uart3: serial@f00701a0 {
 			status = "disabled";
 		};
 
+		gpio0: gpio@f00701d0 {
+			compatible = "cortina,cs7542-gpio";
+			reg = <0xf00701d0 0x20>, <0xf000001c 0x4>;
+			interrupt-parent = <&intc>;
+			interrupts = <6>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+		};
+
+		gpio1: gpio@f00701f0 {
+			compatible = "cortina,cs7542-gpio";
+			reg = <0xf00701f0 0x20>, <0xf0000020 0x4>;
+			interrupt-parent = <&intc>;
+			interrupts = <7>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+		};
+
+		gpio2: gpio@f0070210 {
+			compatible = "cortina,cs7542-gpio";
+			reg = <0xf0070210 0x20>, <0xf0000024 0x4>;
+			interrupt-parent = <&intc>;
+			interrupts = <8>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+		};
+
+		gpio3: gpio@f0070230 {
+			compatible = "cortina,cs7542-gpio";
+			reg = <0xf0070230 0x20>, <0xf0000028 0x4>;
+			interrupt-parent = <&intc>;
+			interrupts = <9>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+		};
+
+		gpio4: gpio@f0070250 {
+			compatible = "cortina,cs7542-gpio";
+			reg = <0xf0070250 0x20>, <0xf000002c 0x4>;
+			interrupt-parent = <&intc>;
+			interrupts = <10>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+		};
+
 		l2: cache-controller@f5010000 {
 			compatible = "arm,pl310-cache";
 			reg = <0xf5010000 0x1000>;

-- 
2.53.0

