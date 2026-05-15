From: Jia Wang <wangjia@ultrarisc.com>
Date: Fri, 15 May 2026 09:18:03 +0800
Subject: [PATCH 7/9] riscv: dts: ultrarisc: add Rongda M0 board device tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-ultrarisc-pinctrl-v1-7-bf559589ea8a@ultrarisc.com>
References: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
In-Reply-To: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778807890; l=5336;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=t/R0mLPTbNUZPAL58YRehEFOhBPdOUX92xeh2IinM2w=;
 b=bT1IuSu9q223icKQubL2BmVf3Yu/tWmMhB7XitawJ8tOZWGSfNzx/DGXFJHZ2lPy6MR+hq3Jp
 qnAT0mbxXslCKi23braHdfI83aXi4xEm+qG0hOSJAx3yGKwNTUuhFyb
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rongda M0 is an mATX motherboard based on the UltraRISC DP1000 SoC.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 arch/riscv/boot/dts/Makefile                       |   1 +
 arch/riscv/boot/dts/ultrarisc/Makefile             |   2 +
 .../dts/ultrarisc/dp1000-rongda-m0-pinctrl.dtsi    |  85 ++++++++++++++++
 arch/riscv/boot/dts/ultrarisc/dp1000-rongda-m0.dts | 111 +++++++++++++++++++++
 4 files changed, 199 insertions(+)

diff --git a/arch/riscv/boot/dts/Makefile b/arch/riscv/boot/dts/Makefile
index 69d8751fb17c..702882974251 100644
--- a/arch/riscv/boot/dts/Makefile
+++ b/arch/riscv/boot/dts/Makefile
@@ -12,3 +12,4 @@ subdir-y += spacemit
 subdir-y += starfive
 subdir-y += tenstorrent
 subdir-y += thead
+subdir-y += ultrarisc
diff --git a/arch/riscv/boot/dts/ultrarisc/Makefile b/arch/riscv/boot/dts/ultrarisc/Makefile
new file mode 100644
index 000000000000..d01a770d3cba
--- /dev/null
+++ b/arch/riscv/boot/dts/ultrarisc/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0
+dtb-$(CONFIG_ARCH_ULTRARISC) += dp1000-rongda-m0.dtb
diff --git a/arch/riscv/boot/dts/ultrarisc/dp1000-rongda-m0-pinctrl.dtsi b/arch/riscv/boot/dts/ultrarisc/dp1000-rongda-m0-pinctrl.dtsi
new file mode 100644
index 000000000000..101b416b1079
--- /dev/null
+++ b/arch/riscv/boot/dts/ultrarisc/dp1000-rongda-m0-pinctrl.dtsi
@@ -0,0 +1,85 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright(C) 2026 UltraRISC Technology (Shanghai) Co., Ltd.
+ */
+
+#include "dp1000.dtsi"
+
+&pmx0 {
+	i2c0_pins: i2c0-pins {
+		pins = "PA12", "PA13";
+		function = "func0";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	i2c1_pins: i2c1-pins {
+		pins = "PB6", "PB7";
+		function = "func0";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	i2c2_pins: i2c2-pins {
+		pins = "PC0", "PC1";
+		function = "func0";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	i2c3_pins: i2c3-pins {
+		pins = "PC2", "PC3";
+		function = "func0";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	pciex4a_link_pins: pciex4a-link-pins {
+		pins = "PC0";
+		function = "func1";
+		bias-pull-down;
+		drive-strength = <33>;
+	};
+
+	pciex4b_link_pins: pciex4b-link-pins {
+		pins = "PC1";
+		function = "func1";
+		bias-pull-down;
+		drive-strength = <33>;
+	};
+
+	spi0_pins: spi0-pins {
+		pins = "PD0", "PD1", "PD2", "PD3", "PD4", "PD5", "PD6", "PD7";
+		function = "func1";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	spi1_pins: spi1-pins {
+		pins = "PA0", "PA1", "PA2", "PA3";
+		function = "func0";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	uart0_pins: uart0-pins {
+		pins = "PA8", "PA9";
+		function = "func1";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	uart1_pins: uart1-pins {
+		pins = "PB4", "PB5";
+		function = "func0";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+
+	uart2_pins: uart2-pins {
+		pins = "PC4", "PC5";
+		function = "func0";
+		bias-pull-up;
+		drive-strength = <33>;
+	};
+};
diff --git a/arch/riscv/boot/dts/ultrarisc/dp1000-rongda-m0.dts b/arch/riscv/boot/dts/ultrarisc/dp1000-rongda-m0.dts
new file mode 100644
index 000000000000..6f72d60ad55e
--- /dev/null
+++ b/arch/riscv/boot/dts/ultrarisc/dp1000-rongda-m0.dts
@@ -0,0 +1,111 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright(C) 2026 UltraRISC Technology (Shanghai) Co., Ltd.
+ */
+
+#include "dp1000-rongda-m0-pinctrl.dtsi"
+#include <dt-bindings/gpio/gpio.h>
+
+/ {
+	model = "Rongda M0 Board";
+	compatible = "rongda,m0", "ultrarisc,dp1000";
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
+	gpio-poweroff {
+		compatible = "gpio-poweroff";
+		gpios = <&gpio_b 0 GPIO_ACTIVE_HIGH>;
+		active-delay-ms = <100>;
+
+		status = "disabled";
+	};
+
+	gpio-restart {
+		compatible = "gpio-restart";
+		gpios = <&gpio_b 1 GPIO_ACTIVE_HIGH>;
+		active-delay = <100>;
+
+		status = "disabled";
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
+	rtc@32 {
+		compatible = "whwave,sd3078";
+		reg = <0x32>;
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
+&ethernet {
+	phy-handle = <&phy0>;
+	/*
+	 * YT8531 RGMII timing on this board requires no PHY internal delays.
+	 * Using "rgmii-id" together with rx/tx-internal-delay-ps results in RX CRC
+	 * errors and no usable traffic, so keep plain "rgmii" here.
+	 */
+	phy-mode = "rgmii";
+
+	mdio {
+		compatible = "snps,dwmac-mdio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		phy0: phy@0 {
+			reg = <0x00>;
+		};
+	};
+};

-- 
2.34.1

