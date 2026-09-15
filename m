From: Long Zhao <longzhao@ambarella.com>
Date: Tue, 15 Sep 2026 19:15:44 +0800
Subject: [PATCH v7 14/15] arm64: ambarella: add ARCH_AMBARELLA and CV75 EVK
 DT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-cv75-v5-v7-14-3297d3fbc9c0@ambarella.com>
References: <20260915-cv75-v5-v7-0-3297d3fbc9c0@ambarella.com>
In-Reply-To: <20260915-cv75-v5-v7-0-3297d3fbc9c0@ambarella.com>
To: Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, soc@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Long Zhao <longzhao@ambarella.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Jerome Brunet <jbrunet@baylibre.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Long Zhao <zl020895@163.com>, Lee Jones <lee@kernel.org>, 
 mfd@lists.linux.dev, devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789470938; l=8107;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=DEAMc2vofaBUV896UxD87q9HiCotMrVdpC7L4SePgqQ=;
 b=aoTbaYYYCiah6FyPZv/A02JDmlnDyUBlmt2OCSkNsQU5Q402lHzn7g4kmFAQji+j2/inH7WkC
 9d5DRaHdNqRAirs66FAQjoxBA1sjpFwOugwSqeeNIrRAjgP3YCAT6F3
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable ARCH_AMBARELLA and add a minimal CV75 SoC / EVK device tree for
console bring-up with the RCT clocks, UART, pinctrl and GPIO banks.

Reviewed-by: Linus Walleij <linusw@kernel.org>
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 arch/arm64/Kconfig.platforms               |   6 +
 arch/arm64/boot/dts/Makefile               |   1 +
 arch/arm64/boot/dts/ambarella/Makefile     |   3 +
 arch/arm64/boot/dts/ambarella/cv75-evk.dts |  30 +++++
 arch/arm64/boot/dts/ambarella/cv75.dtsi    | 177 +++++++++++++++++++++++++++++
 arch/arm64/configs/defconfig               |   1 +
 6 files changed, 218 insertions(+)

diff --git a/arch/arm64/Kconfig.platforms b/arch/arm64/Kconfig.platforms
index d2acfac73003..16d7e3a4c2d6 100644
--- a/arch/arm64/Kconfig.platforms
+++ b/arch/arm64/Kconfig.platforms
@@ -26,6 +26,12 @@ config ARCH_SUNXI
 	help
 	  This enables support for Allwinner sunxi based SoCs like the A64.
 
+config ARCH_AMBARELLA
+	bool "Ambarella SoC family"
+	select PINCTRL
+	help
+	  This enables support for the ARM64 based Ambarella SoCs like CV75.
+
 config ARCH_ALPINE
 	bool "Annapurna Labs Alpine platform"
 	select ALPINE_MSI if PCI
diff --git a/arch/arm64/boot/dts/Makefile b/arch/arm64/boot/dts/Makefile
index fc726b215f12..f1709eb5d915 100644
--- a/arch/arm64/boot/dts/Makefile
+++ b/arch/arm64/boot/dts/Makefile
@@ -4,6 +4,7 @@ subdir-y += airoha
 subdir-y += allwinner
 subdir-y += altera
 subdir-y += amazon
+subdir-y += ambarella
 subdir-y += amd
 subdir-y += amlogic
 subdir-y += apm
diff --git a/arch/arm64/boot/dts/ambarella/Makefile b/arch/arm64/boot/dts/ambarella/Makefile
new file mode 100644
index 000000000000..ddca3d7b18cc
--- /dev/null
+++ b/arch/arm64/boot/dts/ambarella/Makefile
@@ -0,0 +1,3 @@
+# SPDX-License-Identifier: GPL-2.0
+
+dtb-$(CONFIG_ARCH_AMBARELLA) += cv75-evk.dtb
diff --git a/arch/arm64/boot/dts/ambarella/cv75-evk.dts b/arch/arm64/boot/dts/ambarella/cv75-evk.dts
new file mode 100644
index 000000000000..42a0fe24b83b
--- /dev/null
+++ b/arch/arm64/boot/dts/ambarella/cv75-evk.dts
@@ -0,0 +1,30 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Ambarella CV75 EVK board
+ */
+
+/dts-v1/;
+
+#include "cv75.dtsi"
+
+/ {
+	model = "Ambarella CV75 EVK Board";
+	compatible = "ambarella,cv75-evk", "ambarella,cv75";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = &uart0;
+	};
+
+	memory@200000 {
+		device_type = "memory";
+		reg = <0x0 0x00200000 0x0 0x07e00000>;
+	};
+};
+
+&uart0 {
+	status = "okay";
+};
diff --git a/arch/arm64/boot/dts/ambarella/cv75.dtsi b/arch/arm64/boot/dts/ambarella/cv75.dtsi
new file mode 100644
index 000000000000..c36b6af48237
--- /dev/null
+++ b/arch/arm64/boot/dts/ambarella/cv75.dtsi
@@ -0,0 +1,177 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Ambarella CV75 SoC
+ *
+ * Boot peripheral: UART0 console.
+ * Clocks: a single ambarella,cv75-rct provider.
+ */
+
+#include <dt-bindings/clock/ambarella,cv75-rct.h>
+#include <dt-bindings/interrupt-controller/arm-gic.h>
+
+/ {
+	compatible = "ambarella,cv75";
+	interrupt-parent = <&gic>;
+	#address-cells = <2>;
+	#size-cells = <2>;
+
+	cpus {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		cpu@0 {
+			compatible = "arm,cortex-a76";
+			device_type = "cpu";
+			reg = <0x000>;
+			enable-method = "psci";
+		};
+
+		cpu@1 {
+			compatible = "arm,cortex-a76";
+			device_type = "cpu";
+			reg = <0x100>;
+			enable-method = "psci";
+		};
+	};
+
+	osc: oscillator {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <24000000>;
+		clock-output-names = "osc";
+	};
+
+	psci {
+		compatible = "arm,psci-0.2";
+		method = "smc";
+	};
+
+	soc {
+		compatible = "simple-bus";
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		ahb@ffe0000000 {
+			compatible = "simple-bus";
+			reg = <0xff 0xe0000000 0x0 0x01000000>;
+			ranges = <0xe0000000 0xff 0xe0000000 0x01000000>;
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			s_scratchpad_syscon: scratchpad@e002e000 {
+				compatible = "ambarella,cv75-sec-scratchpad", "syscon";
+				reg = <0xe002e000 0x1000>;
+			};
+		};
+
+		apb@ffe4000000 {
+			compatible = "simple-bus";
+			reg = <0xff 0xe4000000 0x0 0x01000000>;
+			ranges = <0xe4000000 0xff 0xe4000000 0x01000000>;
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			uart0: serial@e4000000 {
+				compatible = "ambarella,cv75-uart", "snps,dw-apb-uart";
+				reg = <0xe4000000 0x1000>;
+				clocks = <&rct CV75_GCLK_UART0>;
+				interrupts = <GIC_SPI 170 IRQ_TYPE_LEVEL_HIGH>;
+				reg-shift = <2>;
+				reg-io-width = <4>;
+				pinctrl-names = "default";
+				pinctrl-0 = <&uart0_pins>;
+
+				status = "disabled";
+			};
+
+			pinctrl: pinctrl@e4010000 {
+				compatible = "ambarella,cv75-pinctrl";
+				reg = <0xe4010000 0x1000>;
+				ambarella,drive-strength-syscon = <&rct>;
+				ambarella,pull-syscon = <&s_scratchpad_syscon>;
+
+				uart0_pins: uart0-pins {
+					function = "uart0";
+					groups = "uart0";
+				};
+			};
+
+			gpio0: gpio@e4013000 {
+				compatible = "ambarella,cv75-gpio", "arm,primecell";
+				reg = <0xe4013000 0x1000>;
+				clocks = <&rct CV75_GCLK_APB>;
+				clock-names = "apb_pclk";
+				interrupts = <GIC_SPI 163 IRQ_TYPE_LEVEL_HIGH>;
+				gpio-controller;
+				#gpio-cells = <2>;
+				gpio-ranges = <&pinctrl 0 0 32>;
+				interrupt-controller;
+				#interrupt-cells = <2>;
+				arm,primecell-periphid = <0x000e8061>;
+			};
+
+			gpio1: gpio@e4014000 {
+				compatible = "ambarella,cv75-gpio", "arm,primecell";
+				reg = <0xe4014000 0x1000>;
+				clocks = <&rct CV75_GCLK_APB>;
+				clock-names = "apb_pclk";
+				interrupts = <GIC_SPI 164 IRQ_TYPE_LEVEL_HIGH>;
+				gpio-controller;
+				#gpio-cells = <2>;
+				gpio-ranges = <&pinctrl 0 32 32>;
+				interrupt-controller;
+				#interrupt-cells = <2>;
+				arm,primecell-periphid = <0x000e8061>;
+			};
+
+			gpio2: gpio@e4015000 {
+				compatible = "ambarella,cv75-gpio", "arm,primecell";
+				reg = <0xe4015000 0x1000>;
+				clocks = <&rct CV75_GCLK_APB>;
+				clock-names = "apb_pclk";
+				interrupts = <GIC_SPI 165 IRQ_TYPE_LEVEL_HIGH>;
+				gpio-controller;
+				#gpio-cells = <2>;
+				gpio-ranges = <&pinctrl 0 64 32>;
+				interrupt-controller;
+				#interrupt-cells = <2>;
+				arm,primecell-periphid = <0x000e8061>;
+			};
+		};
+
+		rct: clock-controller@ffed080000 {
+			compatible = "ambarella,cv75-rct", "syscon";
+			reg = <0xff 0xed080000 0x0 0x1000>;
+			clocks = <&osc>;
+			clock-names = "osc";
+			#clock-cells = <1>;
+			#reset-cells = <1>;
+			assigned-clocks = <&rct CV75_GCLK_UART0>;
+			assigned-clock-parents = <&osc>;
+			assigned-clock-rates = <24000000>;
+		};
+
+		gic: interrupt-controller@fff0101000 {
+			compatible = "arm,gic-400";
+			reg = <0xff 0xf0101000 0x0 0x1000>,
+			      <0xff 0xf0102000 0x0 0x2000>,
+			      <0xff 0xf0104000 0x0 0x2000>,
+			      <0xff 0xf0106000 0x0 0x2000>;
+			interrupt-controller;
+			#interrupt-cells = <3>;
+			#address-cells = <0>;
+			interrupts = <GIC_PPI 9
+				      (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_LEVEL_HIGH)>;
+		};
+	};
+
+	timer {
+		compatible = "arm,armv8-timer";
+		interrupts = <GIC_PPI 13 (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 14 (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 11 (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 10 (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 12 (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_LEVEL_LOW)>;
+	};
+};
diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index ad3bd3d9507b..454f07a6a6a6 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -36,6 +36,7 @@ CONFIG_CRASH_DUMP=y
 CONFIG_ARCH_ACTIONS=y
 CONFIG_ARCH_AIROHA=y
 CONFIG_ARCH_SUNXI=y
+CONFIG_ARCH_AMBARELLA=y
 CONFIG_ARCH_ALPINE=y
 CONFIG_ARCH_APPLE=y
 CONFIG_ARCH_ARTPEC=y

-- 
2.34.1

