From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 24 Aug 2026 13:54:25 +0800
Subject: [PATCH 12/12] riscv: dts: ultrarisc: Add Milk-V Titan board device
 tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-ultrarisc-dts-v1-12-61ab7aebe9e5@ultrarisc.com>
References: <20260824-ultrarisc-dts-v1-0-61ab7aebe9e5@ultrarisc.com>
In-Reply-To: <20260824-ultrarisc-dts-v1-0-61ab7aebe9e5@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Anup Patel <anup@brainfault.org>, Mark Brown <broonie@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Jose Abreu <joabreu@synopsys.com>, 
 Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-spi@vger.kernel.org, 
 linux-i2c@vger.kernel.org, netdev@vger.kernel.org, 
 dmaengine@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787552108; l=7355;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=zBhtRfmKKWpJufh5JQfrWxerGCRdaDPbp3rtX+6ZO1c=;
 b=3jzES90pfxMiJBYWUQ6MSAJXJiiH4BhSUaV6y79VZz5pBaLoIzpUeePKM0sYg7t1D9FUKxt0+
 iVoJ+mii09BB7enwkirZz2y1AzNIJIH1c1zy6xwP5iEgeJTyo+k19RX
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Milk-V Titan is an ITX motherboard based on the UltraRISC DP1000 SoC.

Link: https://milkv.io/docs/titan/overview
Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 arch/riscv/boot/dts/ultrarisc/Makefile             |   1 +
 .../dts/ultrarisc/dp1000-milkv-titan-pinctrl.dtsi  | 108 +++++++++++
 .../boot/dts/ultrarisc/dp1000-milkv-titan.dts      | 203 +++++++++++++++++++++
 3 files changed, 312 insertions(+)

diff --git a/arch/riscv/boot/dts/ultrarisc/Makefile b/arch/riscv/boot/dts/ultrarisc/Makefile
index 454d849a6ce4..dfd15c064d07 100644
--- a/arch/riscv/boot/dts/ultrarisc/Makefile
+++ b/arch/riscv/boot/dts/ultrarisc/Makefile
@@ -1,2 +1,3 @@
 # SPDX-License-Identifier: GPL-2.0
+dtb-$(CONFIG_ARCH_ULTRARISC) += dp1000-milkv-titan.dtb
 dtb-$(CONFIG_ARCH_ULTRARISC) += dp1000-shenrongda-m0.dtb
diff --git a/arch/riscv/boot/dts/ultrarisc/dp1000-milkv-titan-pinctrl.dtsi b/arch/riscv/boot/dts/ultrarisc/dp1000-milkv-titan-pinctrl.dtsi
new file mode 100644
index 000000000000..7a812e40a249
--- /dev/null
+++ b/arch/riscv/boot/dts/ultrarisc/dp1000-milkv-titan-pinctrl.dtsi
@@ -0,0 +1,108 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright(C) 2026 UltraRISC Technology (Shanghai) Co., Ltd.
+ */
+
+#include "dp1000.dtsi"
+#include "dp1000-pinctrl.h"
+
+&pinctrl {
+	i2c0_pins: i2c0-pins {
+		pins = <PA12 PA13>;
+		function = "i2c";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	i2c1_pins: i2c1-pins {
+		pins = <PB6 PB7>;
+		function = "i2c";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	i2c2_pins: i2c2-pins {
+		pins = <PC0 PC1>;
+		function = "i2c";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	i2c3_pins: i2c3-pins {
+		pins = <PC2 PC3>;
+		function = "i2c";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	io_pins: io-pins {
+		pins = <PA10 PA15 PB0 PB1 PB2 PD6 PD7>;
+		function = "gpio";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	gpio_keys_pins: gpio-keys-pins {
+		pins = <PA4 PA11 PA14>;
+		function = "gpio";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	mux_dcdc_i2c_pins: mux-dcdc-i2c-pins {
+		pins = <PA5>;
+		function = "gpio";
+	};
+
+	mux_i2c3_pins: mux-i2c3-pins {
+		pins = <PA6>;
+		function = "gpio";
+	};
+
+	mux_uart0_pins: mux-uart0-pins {
+		pins = <PA7>;
+		function = "gpio";
+	};
+
+	spi0_pins: spi0-pins {
+		pins = <PD0 PD1 PD2 PD3 PD4 PD5>;
+		function = "spi";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	spi1_pins: spi1-pins {
+		pins = <PA0 PA1 PA2 PA3>;
+		function = "spi";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	uart0_pins: uart0-pins {
+		pins = <PA8 PA9>;
+		function = "uart";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	uart1_pins: uart1-pins {
+		pins = <PB4 PB5>;
+		function = "uart";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	uart2_pins: uart2-pins {
+		pins = <PC4 PC5>;
+		function = "uart";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	uart3_pins: uart3-pins {
+		pins = <PC6 PC7>;
+		function = "uart";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+};
diff --git a/arch/riscv/boot/dts/ultrarisc/dp1000-milkv-titan.dts b/arch/riscv/boot/dts/ultrarisc/dp1000-milkv-titan.dts
new file mode 100644
index 000000000000..f1a0efee3d74
--- /dev/null
+++ b/arch/riscv/boot/dts/ultrarisc/dp1000-milkv-titan.dts
@@ -0,0 +1,203 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright(C) 2026 UltraRISC Technology (Shanghai) Co., Ltd.
+ */
+
+#include "dp1000-milkv-titan-pinctrl.dtsi"
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/input/input.h>
+#include <dt-bindings/input/gpio-keys.h>
+#include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/leds/common.h>
+
+/ {
+	model = "Milk-V Titan";
+	compatible = "milkv,titan", "ultrarisc,dp1000";
+
+	aliases {
+		serial0 = &uart0;
+		serial1 = &uart1;
+		serial2 = &uart2;
+		serial3 = &uart3;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+
+	gpio-keys {
+		compatible = "gpio-keys";
+		pinctrl-names = "default";
+		pinctrl-0 = <&gpio_keys_pins>;
+
+		key-wakeup-0 {
+			label = "Wake-Up";
+			gpios = <&gpio_a 14 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_WAKEUP>;
+			linux,input-type = <EV_KEY>;
+			debounce-interval = <10>;
+			wakeup-source;
+			wakeup-event-action = <EV_ACT_ASSERTED>;
+		};
+
+		key-wakeup-1 {
+			label = "Power";
+			gpios = <&gpio_a 11 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_POWER>;
+			linux,input-type = <EV_KEY>;
+			debounce-interval = <10>;
+			wakeup-source;
+			wakeup-event-action = <EV_ACT_ASSERTED>;
+		};
+
+		key-wakeup-2 {
+			label = "Wake-Up-by-USB";
+			interrupts-extended = <&gpio_a 4 IRQ_TYPE_EDGE_FALLING>;
+			linux,code = <KEY_WAKEUP>;
+			linux,input-type = <EV_KEY>;
+			debounce-interval = <10>;
+			wakeup-source;
+		};
+	};
+};
+
+&i2c0 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&i2c0_pins>;
+};
+
+&i2c1 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&i2c1_pins>;
+};
+
+&i2c2 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&i2c2_pins>;
+
+	rtc@68 {
+		compatible = "st,m41t11";
+		reg = <0x68>;
+	};
+};
+
+&i2c3 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&i2c3_pins>;
+};
+
+&spi0 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&spi0_pins>;
+};
+
+&spi1 {
+	num-cs = <1>;
+
+	pinctrl-names = "default";
+	pinctrl-0 = <&spi1_pins>;
+};
+
+&uart0 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&uart0_pins>;
+};
+
+&uart1 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&uart1_pins>;
+};
+
+&uart2 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&uart2_pins>;
+};
+
+&uart3 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&uart3_pins>;
+};
+
+&pcie_x16 {
+	status = "okay";
+};
+
+&pcie_x4a {
+	status = "okay";
+};
+
+&pcie_x4b {
+	status = "okay";
+};
+
+&gpio {
+	pinctrl-names = "default";
+	pinctrl-0 = <&io_pins &mux_dcdc_i2c_pins &mux_i2c3_pins &mux_uart0_pins>;
+};
+
+&gpio_a {
+	dcdc-i2c-mux-hog {
+		gpio-hog;
+		gpios = <5 GPIO_ACTIVE_HIGH>;
+		output-low;
+		line-name = "dcdc-i2c-mux";
+	};
+
+	i2c3-mux-hog {
+		gpio-hog;
+		gpios = <6 GPIO_ACTIVE_HIGH>;
+		output-low;
+		line-name = "i2c3-mux";
+	};
+
+	uart0-mux-hog {
+		gpio-hog;
+		gpios = <7 GPIO_ACTIVE_HIGH>;
+		output-high;
+		line-name = "uart0-mux";
+	};
+};
+
+&ethernet {
+	phy-handle = <&phy0>;
+	/*
+	 * RTL8211F: board timing uses PHY strap delays; keep plain "rgmii".
+	 * Enabling PHY internal delays via "rgmii-id" breaks Ethernet traffic.
+	 */
+	phy-mode = "rgmii";
+
+	status = "okay";
+
+	mdio {
+		compatible = "snps,dwmac-mdio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		phy0: phy@0 {
+			reg = <0>;
+
+			leds {
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				led@1 {
+					label = "eth-link";
+					reg = <1>;
+					color = <LED_COLOR_ID_YELLOW>;
+					function = LED_FUNCTION_INDICATOR;
+					default-state = "keep";
+					linux,default-trigger = "netdev";
+				};
+
+				led@2 {
+					label = "eth-activity";
+					reg = <2>;
+					color = <LED_COLOR_ID_GREEN>;
+					function = LED_FUNCTION_ACTIVITY;
+					default-state = "keep";
+					linux,default-trigger = "netdev";
+				};
+			};
+		};
+	};
+};

-- 
2.34.1

