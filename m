From: Long Zhao <longzhao@ambarella.com>
Date: Thu, 06 Aug 2026 17:34:17 +0800
Subject: [PATCH v2 09/10] arm64: ambarella: add ARCH_AMBARELLA and CV75 EVK
 DT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-longzhao-upstream-cv75-v2-v2-9-6b09707c5fe9@ambarella.com>
References: <20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com>
In-Reply-To: <20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-serial@vger.kernel.org, 
 soc@lists.linux.dev, Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786008863; l=7996;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=6vJ94VlfBvvZA0fx7qMQy5vR9YqyghJ/Vg2eYaSwrT0=;
 b=afzO8MptAlCtg3qKNK2CZh4dztk4jr5TNbqA9ZLgdFbIW1HtIDsh8R/CvpypbD7NwrXTQef2V
 73JbV2916x8DHOqbxIxzv4/ZctQ26wEXQmVMc26v8uUruEGxedd2Nt2
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the Ambarella ARMv8 platform Kconfig, add the CV75 SoC and
EVK device trees, and select the Ambarella UART in the arm64
defconfig for console bring-up.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 arch/arm64/Kconfig.platforms               |   9 ++
 arch/arm64/boot/dts/Makefile               |   1 +
 arch/arm64/boot/dts/ambarella/Makefile     |   3 +
 arch/arm64/boot/dts/ambarella/cv75-evk.dts |  30 ++++++
 arch/arm64/boot/dts/ambarella/cv75.dtsi    | 166 +++++++++++++++++++++++++++++
 arch/arm64/configs/defconfig               |   3 +
 6 files changed, 212 insertions(+)

diff --git a/arch/arm64/Kconfig.platforms b/arch/arm64/Kconfig.platforms
index d2acfac73003..166430ddb3c9 100644
--- a/arch/arm64/Kconfig.platforms
+++ b/arch/arm64/Kconfig.platforms
@@ -26,6 +26,15 @@ config ARCH_SUNXI
 	help
 	  This enables support for Allwinner sunxi based SoCs like the A64.
 
+config ARCH_AMBARELLA
+	bool "Ambarella SoC family"
+	select ARM_PSCI
+	select HAVE_ARM_ARCH_TIMER
+	select PINCTRL
+	select PINCTRL_AMB
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
index 000000000000..825b773f052f
--- /dev/null
+++ b/arch/arm64/boot/dts/ambarella/cv75.dtsi
@@ -0,0 +1,166 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Ambarella CV75 SoC
+ *
+ * Boot peripheral: UART0 console.
+ * Clocks: a single ambarella,cv75-rct provider.
+ */
+
+#include <dt-bindings/clock/ambarella,cv75-clock.h>
+#include <dt-bindings/interrupt-controller/arm-gic.h>
+
+/ {
+	compatible = "ambarella,cv75";
+	interrupt-parent = <&gic>;
+	#address-cells = <2>;
+	#size-cells = <2>;
+
+	osc: oscillator {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-output-names = "osc";
+		clock-frequency = <24000000>;
+	};
+
+	psci {
+		compatible = "arm,psci-0.2";
+		method = "smc";
+	};
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
+	gic: interrupt-controller@fff0101000 {
+		compatible = "arm,gic-400";
+		#interrupt-cells = <3>;
+		#address-cells = <0>;
+		#size-cells = <1>;
+		interrupt-controller;
+		reg = <0xff 0xf0101000 0x0 0x1000>,
+		      <0xff 0xf0102000 0x0 0x2000>,
+		      <0xff 0xf0104000 0x0 0x2000>,
+		      <0xff 0xf0106000 0x0 0x2000>;
+		interrupts = <GIC_PPI 9 (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_LEVEL_HIGH)>;
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
+
+	soc {
+		compatible = "simple-bus";
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		/* Clock provider and shared system registers. */
+		rct: clock-controller@ffed080000 {
+			compatible = "ambarella,cv75-rct", "syscon";
+			reg = <0xff 0xed080000 0x0 0x1000>;
+			clocks = <&osc>;
+			clock-names = "osc";
+			#clock-cells = <1>;
+
+			assigned-clocks = <&rct CV75_GCLK_UART0>;
+			assigned-clock-parents = <&osc>;
+			assigned-clock-rates = <24000000>;
+		};
+
+		apb@ffe4000000 {
+			compatible = "simple-bus";
+			#address-cells = <1>;
+			#size-cells = <1>;
+			reg = <0xff 0xe4000000 0x0 0x01000000>;
+			ranges = <0xe4000000 0xff 0xe4000000 0x01000000>;
+
+			uart0: serial@e4000000 {
+				compatible = "ambarella,cv75-uart";
+				reg = <0xe4000000 0x1000>;
+				interrupts = <GIC_SPI 170 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&rct CV75_GCLK_UART0>;
+				pinctrl-names = "default";
+				pinctrl-0 = <&uart0_pins>;
+				status = "disabled";
+			};
+
+			pinctrl: pinctrl@e4010000 {
+				compatible = "ambarella,cv75-pinctrl";
+				#address-cells = <1>;
+				#size-cells = <1>;
+				reg = <0xe4010000 0x1000>;
+				ranges;
+				ambarella,drive-strength-syscon = <&rct>;
+				ambarella,pull-syscon = <&s_scratchpad_syscon>;
+
+				gpio0: gpio@e4013000 {
+					reg = <0xe4013000 0x1000>;
+					interrupts = <GIC_SPI 163 IRQ_TYPE_LEVEL_HIGH>;
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&pinctrl 0 0 32>;
+					interrupt-controller;
+					#interrupt-cells = <2>;
+				};
+
+				gpio1: gpio@e4014000 {
+					reg = <0xe4014000 0x1000>;
+					interrupts = <GIC_SPI 164 IRQ_TYPE_LEVEL_HIGH>;
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&pinctrl 0 32 32>;
+					interrupt-controller;
+					#interrupt-cells = <2>;
+				};
+
+				gpio2: gpio@e4015000 {
+					reg = <0xe4015000 0x1000>;
+					interrupts = <GIC_SPI 165 IRQ_TYPE_LEVEL_HIGH>;
+					gpio-controller;
+					#gpio-cells = <2>;
+					gpio-ranges = <&pinctrl 0 64 32>;
+					interrupt-controller;
+					#interrupt-cells = <2>;
+				};
+
+				uart0_pins: uart0-pins {
+					function = "uart0";
+					groups = "uart0tx", "uart0rx";
+				};
+			};
+		};
+
+		ahb@ffe0000000 {
+			compatible = "simple-bus";
+			#address-cells = <1>;
+			#size-cells = <1>;
+			reg = <0xff 0xe0000000 0x0 0x01000000>;
+			ranges = <0xe0000000 0xff 0xe0000000 0x01000000>;
+
+			s_scratchpad_syscon: scratchpad@e002e000 {
+				compatible = "ambarella,cv75-sec-scratchpad", "syscon";
+				reg = <0xe002e000 0x1000>;
+			};
+		};
+	};
+};
diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index ad3bd3d9507b..64e8fbe43d27 100644
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
@@ -567,6 +568,8 @@ CONFIG_SERIAL_8250_OMAP=y
 CONFIG_SERIAL_8250_MT6577=y
 CONFIG_SERIAL_8250_UNIPHIER=y
 CONFIG_SERIAL_OF_PLATFORM=y
+CONFIG_SERIAL_AMBARELLA=y
+CONFIG_SERIAL_AMBARELLA_CONSOLE=y
 CONFIG_SERIAL_AMBA_PL011=y
 CONFIG_SERIAL_AMBA_PL011_CONSOLE=y
 CONFIG_SERIAL_MESON=y

-- 
2.34.1

