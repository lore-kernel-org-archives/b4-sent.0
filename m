From: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
Date: Wed, 04 Dec 2024 16:05:27 +0000
Subject: [PATCH v5 4/6] arm64: dts: Add initial support for Blaize BLZP1600
 CB2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241204-blaize-blzp1600_init_board_support-v5-4-b642bcc49307@blaize.com>
References: <20241204-blaize-blzp1600_init_board_support-v5-0-b642bcc49307@blaize.com>
In-Reply-To: <20241204-blaize-blzp1600_init_board_support-v5-0-b642bcc49307@blaize.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 James Cowgill <james.cowgill@blaize.com>, 
 Matt Redfearn <matt.redfearn@blaize.com>, 
 Neil Jones <neil.jones@blaize.com>, 
 Niko Pasaloukos <nikolaos.pasaloukos@blaize.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, Olof Johansson <olof@lixom.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, soc@lists.linux.dev, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733328392; l=10584;
 i=nikolaos.pasaloukos@blaize.com; s=20241111; h=from:subject:message-id;
 bh=6lzlBswFiOwlEF4vgaE0qTkuZdK3yyZ0e7+ltOtkqIU=;
 b=mlK9PcIrKFLZ8MKCLSoT4YyrjVovNKeRVG70z3DYDFbqYXHkR6W0cY5k1LQJkv2TD8CwmfHT7
 EUScaxcohDjAE1jC5Ar6oxDJ1L6HSI6hyJxZQXAL3wfDnyJs/3NxxqN
X-Developer-Key: i=nikolaos.pasaloukos@blaize.com; a=ed25519;
 pk=gGEjGCXdSuvCJPIiu0p0UeiPcW5LC710Z6KGN/dzo3g=
X-Endpoint-Received: by B4 Relay for nikolaos.pasaloukos@blaize.com/20241111 with auth_id=274
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Blaize CB2 development board based on
the BLZP1600 SoC. This consists of a Carrier-Board-2 and a
System-on-Module.

Both BLZP1600 SoM and CB2 are available as products.
CB2 (Pathfinder) has multiple peripherals like UART, I2C,
SPI, GPIO, CSI (camera), DSI (display), USB-3.0 and Ethernet.

Enable support for the Cryptocell, UART and I2C which are
already fully supported by the drivers.

The blaize-blzp1600.dtsi is the common part for the SoC,
blaize-blzp1600-som.dtsi is the common part for the SoM and
blaize-blzp1600-cb2.dts is the board specific file.

Co-developed-by: James Cowgill <james.cowgill@blaize.com>
Signed-off-by: James Cowgill <james.cowgill@blaize.com>
Co-developed-by: Matt Redfearn <matt.redfearn@blaize.com>
Signed-off-by: Matt Redfearn <matt.redfearn@blaize.com>
Co-developed-by: Neil Jones <neil.jones@blaize.com>
Signed-off-by: Neil Jones <neil.jones@blaize.com>
Signed-off-by: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
---
 arch/arm64/boot/dts/Makefile                       |   1 +
 arch/arm64/boot/dts/blaize/Makefile                |   2 +
 arch/arm64/boot/dts/blaize/blaize-blzp1600-cb2.dts |  83 +++++++++
 .../arm64/boot/dts/blaize/blaize-blzp1600-som.dtsi |  23 +++
 arch/arm64/boot/dts/blaize/blaize-blzp1600.dtsi    | 205 +++++++++++++++++++++
 5 files changed, 314 insertions(+)

diff --git a/arch/arm64/boot/dts/Makefile b/arch/arm64/boot/dts/Makefile
index 21cd3a87f385309c3a655a67a3bee5f0abed7545..79b73a21ddc22b17308554e502f8207392935b45 100644
--- a/arch/arm64/boot/dts/Makefile
+++ b/arch/arm64/boot/dts/Makefile
@@ -10,6 +10,7 @@ subdir-y += apm
 subdir-y += apple
 subdir-y += arm
 subdir-y += bitmain
+subdir-y += blaize
 subdir-y += broadcom
 subdir-y += cavium
 subdir-y += exynos
diff --git a/arch/arm64/boot/dts/blaize/Makefile b/arch/arm64/boot/dts/blaize/Makefile
new file mode 100644
index 0000000000000000000000000000000000000000..7e10b3199e6c73b64c826fef1aa4058c7b3e898b
--- /dev/null
+++ b/arch/arm64/boot/dts/blaize/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0+
+dtb-$(CONFIG_ARCH_BLAIZE) += blaize-blzp1600-cb2.dtb
diff --git a/arch/arm64/boot/dts/blaize/blaize-blzp1600-cb2.dts b/arch/arm64/boot/dts/blaize/blaize-blzp1600-cb2.dts
new file mode 100644
index 0000000000000000000000000000000000000000..7e3cef2ed3522e202487e799b2021cd45398e006
--- /dev/null
+++ b/arch/arm64/boot/dts/blaize/blaize-blzp1600-cb2.dts
@@ -0,0 +1,83 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (c) 2024 Blaize, Inc. All rights reserved.
+ */
+
+/dts-v1/;
+
+#include "blaize-blzp1600-som.dtsi"
+
+/ {
+	model = "Blaize BLZP1600 SoM1600P CB2 Development Board";
+
+	compatible = "blaize,blzp1600-cb2", "blaize,blzp1600";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200";
+	};
+};
+
+&i2c0 {
+	clock-frequency = <100000>;
+	status = "okay";
+};
+
+&i2c1 {
+	clock-frequency = <100000>;
+	status = "okay";
+};
+
+&i2c3 {
+	clock-frequency = <100000>;
+	status = "okay";
+
+	gpio_expander: gpio@74 {
+		compatible = "ti,tca9539";
+		reg = <0x74>;
+		gpio-controller;
+		#gpio-cells = <2>;
+		gpio-line-names = "RSP_PIN_7",	/* GPIO_0 */
+				  "RSP_PIN_11",	/* GPIO_1 */
+				  "RSP_PIN_13",	/* GPIO_2 */
+				  "RSP_PIN_15",	/* GPIO_3 */
+				  "RSP_PIN_27",	/* GPIO_4 */
+				  "RSP_PIN_29",	/* GPIO_5 */
+				  "RSP_PIN_31",	/* GPIO_6 */
+				  "RSP_PIN_33",	/* GPIO_7 */
+				  "RSP_PIN_37",	/* GPIO_8 */
+				  "RSP_PIN_16",	/* GPIO_9 */
+				  "RSP_PIN_18",	/* GPIO_10 */
+				  "RSP_PIN_22",	/* GPIO_11 */
+				  "RSP_PIN_28",	/* GPIO_12 */
+				  "RSP_PIN_32",	/* GPIO_13 */
+				  "RSP_PIN_36",	/* GPIO_14 */
+				  "TP31";	/* GPIO_15 */
+	};
+
+	gpio_expander_m2: gpio@75 {
+		compatible = "ti,tca9539";
+		reg = <0x75>;
+		gpio-controller;
+		#gpio-cells = <2>;
+		gpio-line-names = "M2_W_DIS1_N",	/* GPIO_0 */
+				  "M2_W_DIS2_N",	/* GPIO_1 */
+				  "M2_UART_WAKE_N",	/* GPIO_2 */
+				  "M2_COEX3",		/* GPIO_3 */
+				  "M2_COEX_RXD",	/* GPIO_4 */
+				  "M2_COEX_TXD",	/* GPIO_5 */
+				  "M2_VENDOR_PIN40",	/* GPIO_6 */
+				  "M2_VENDOR_PIN42",	/* GPIO_7 */
+				  "M2_VENDOR_PIN38",	/* GPIO_8 */
+				  "M2_SDIO_RST_N",	/* GPIO_9 */
+				  "M2_SDIO_WAKE_N",	/* GPIO_10 */
+				  "M2_PETN1",		/* GPIO_11 */
+				  "M2_PERP1",		/* GPIO_12 */
+				  "M2_PERN1",		/* GPIO_13 */
+				  "UIM_SWP",		/* GPIO_14 */
+				  "UART1_TO_RSP";	/* GPIO_15 */
+	};
+};
diff --git a/arch/arm64/boot/dts/blaize/blaize-blzp1600-som.dtsi b/arch/arm64/boot/dts/blaize/blaize-blzp1600-som.dtsi
new file mode 100644
index 0000000000000000000000000000000000000000..bfdff5953edd95341440aa98569a019adcc0425d
--- /dev/null
+++ b/arch/arm64/boot/dts/blaize/blaize-blzp1600-som.dtsi
@@ -0,0 +1,23 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (c) 2024 Blaize, Inc. All rights reserved.
+ */
+
+#include "blaize-blzp1600.dtsi"
+
+/ {
+	memory@0 {
+		device_type = "memory";
+		reg = <0x0 0x0 0x1 0x0>;
+	};
+};
+
+/* i2c4 bus is available only on the SoM, not on the board */
+&i2c4 {
+	clock-frequency = <100000>;
+	status = "okay";
+};
+
+&uart0 {
+	status = "okay";
+};
diff --git a/arch/arm64/boot/dts/blaize/blaize-blzp1600.dtsi b/arch/arm64/boot/dts/blaize/blaize-blzp1600.dtsi
new file mode 100644
index 0000000000000000000000000000000000000000..7d399e6a532f5b24385dd837be965be771c7d24c
--- /dev/null
+++ b/arch/arm64/boot/dts/blaize/blaize-blzp1600.dtsi
@@ -0,0 +1,205 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (c) 2024 Blaize, Inc. All rights reserved.
+ */
+
+/dts-v1/;
+
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/interrupt-controller/arm-gic.h>
+
+/ {
+	interrupt-parent = <&gic>;
+	#address-cells = <2>;
+	#size-cells = <2>;
+
+	cpus {
+		#address-cells = <2>;
+		#size-cells = <0>;
+
+		cpu0: cpu@0 {
+			compatible = "arm,cortex-a53";
+			reg = <0x0 0x0>;
+			device_type = "cpu";
+			enable-method = "psci";
+			next-level-cache = <&l2>;
+		};
+
+		cpu1: cpu@1 {
+			compatible = "arm,cortex-a53";
+			reg = <0x0 0x1>;
+			device_type = "cpu";
+			enable-method = "psci";
+			next-level-cache = <&l2>;
+		};
+
+		l2: l2-cache0 {
+			compatible = "cache";
+			cache-level = <2>;
+			cache-unified;
+		};
+	};
+
+	firmware {
+		scmi {
+			compatible = "arm,scmi-smc";
+			arm,smc-id = <0x82002000>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			shmem = <&scmi0_shm>;
+
+			scmi_clk: protocol@14 {
+				reg = <0x14>;
+				#clock-cells = <1>;
+			};
+
+			scmi_rst: protocol@16 {
+				reg = <0x16>;
+				#reset-cells = <1>;
+			};
+		};
+	};
+
+	pmu {
+		compatible = "arm,cortex-a53-pmu";
+		interrupts = <GIC_SPI 76 IRQ_TYPE_LEVEL_HIGH>,
+			     <GIC_SPI 77 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-affinity = <&cpu0>, <&cpu1>;
+	};
+
+	psci {
+		compatible = "arm,psci-1.0", "arm,psci-0.2";
+		method = "smc";
+	};
+
+	reserved-memory {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		/* SCMI reserved buffer space on DDR space */
+		scmi0_shm: scmi-shmem@800 {
+			compatible = "arm,scmi-shmem";
+			reg = <0x0 0x800 0x0 0x80>;
+		};
+	};
+
+	timer {
+		compatible = "arm,armv8-timer";
+		interrupts = /* Physical Secure PPI */
+			     <GIC_PPI 13 (GIC_CPU_MASK_RAW(0x3) |
+					  IRQ_TYPE_LEVEL_LOW)>,
+			     /* Physical Non-Secure PPI */
+			     <GIC_PPI 14 (GIC_CPU_MASK_RAW(0x3) |
+					  IRQ_TYPE_LEVEL_LOW)>,
+			     /* Hypervisor PPI */
+			     <GIC_PPI 10 (GIC_CPU_MASK_RAW(0x3) |
+					  IRQ_TYPE_LEVEL_LOW)>,
+			     /* Virtual PPI */
+			     <GIC_PPI 11 (GIC_CPU_MASK_RAW(0x3) |
+					  IRQ_TYPE_LEVEL_LOW)>;
+	};
+
+	soc@200000000 {
+		compatible = "simple-bus";
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges = <0x0 0x2 0x0 0x850000>;
+
+		gic: interrupt-controller@410000 {
+			compatible = "arm,gic-400";
+			reg = <0x410000 0x20000>,
+			      <0x420000 0x20000>,
+			      <0x440000 0x20000>,
+			      <0x460000 0x20000>;
+			#interrupt-cells = <3>;
+			#address-cells = <0>;
+			interrupt-controller;
+			interrupts = <GIC_PPI 9 (GIC_CPU_MASK_RAW(0x3) |
+						 IRQ_TYPE_LEVEL_LOW)>;
+		};
+
+		uart0: serial@4d0000 {
+			compatible = "ns16550a";
+			reg = <0x4d0000 0x1000>;
+			clocks = <&scmi_clk 59>;
+			resets = <&scmi_rst 59>;
+			reg-shift = <2>;
+			interrupts = <GIC_SPI 4 IRQ_TYPE_LEVEL_HIGH>;
+			status = "disabled";
+		};
+
+		uart1: serial@4e0000 {
+			compatible = "ns16550a";
+			reg = <0x4e0000 0x1000>;
+			clocks = <&scmi_clk 60>;
+			resets = <&scmi_rst 60>;
+			reg-shift = <2>;
+			interrupts = <GIC_SPI 5 IRQ_TYPE_LEVEL_HIGH>;
+			status = "disabled";
+		};
+
+		i2c0: i2c@4f0000 {
+			compatible = "snps,designware-i2c";
+			reg = <0x4f0000 0x1000>;
+			interrupts = <GIC_SPI 6 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&scmi_clk 54>;
+			resets = <&scmi_rst 54>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
+		i2c1: i2c@500000 {
+			compatible = "snps,designware-i2c";
+			reg = <0x500000 0x1000>;
+			interrupts = <GIC_SPI 7 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&scmi_clk 55>;
+			resets = <&scmi_rst 55>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
+		i2c2: i2c@510000 {
+			compatible = "snps,designware-i2c";
+			reg = <0x510000 0x1000>;
+			interrupts = <GIC_SPI 8 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&scmi_clk 56>;
+			resets = <&scmi_rst 56>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
+		i2c3: i2c@520000 {
+			compatible = "snps,designware-i2c";
+			reg = <0x520000 0x1000>;
+			interrupts = <GIC_SPI 9 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&scmi_clk 57>;
+			resets = <&scmi_rst 57>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
+		i2c4: i2c@530000 {
+			compatible = "snps,designware-i2c";
+			reg = <0x530000 0x1000>;
+			interrupts = <GIC_SPI 10 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&scmi_clk 58>;
+			resets = <&scmi_rst 58>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
+		arm_cc712: crypto@550000 {
+			compatible = "arm,cryptocell-712-ree";
+			reg = <0x550000 0x1000>;
+			interrupts = <GIC_SPI 67 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&scmi_clk 7>;
+		};
+	};
+};

-- 
2.43.0

