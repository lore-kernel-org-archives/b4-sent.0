From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 16 Jul 2025 19:25:13 +0800
Subject: [PATCH v3 4/9] MIPS: dts: loongson: Add Smartloong-1C board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250716-loongson1-arch-v3-4-d160974d696b@gmail.com>
References: <20250716-loongson1-arch-v3-0-d160974d696b@gmail.com>
In-Reply-To: <20250716-loongson1-arch-v3-0-d160974d696b@gmail.com>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752665136; l=6198;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=8k4NI0ImdMzubiiidq5o64B1uZ6t3883T78WhKntQoM=;
 b=9pz1M1MZPhg//wLZGLTgnuvISVqBE2o4ua8T8UsjvfFDXOfjTxD0kBAeu9EStCkKaCQiPaMgk
 qreAQArdxfCApjSBk7zTls+9m4yDKqgFeyuFFe2rRM+AXVAqzvBE+0d
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree for Smartloong-1C board, supporting CPU, clock, INTC,
UART, Ethernet, GPIO, USB host, RTC, watchdog, DMA, and NAND.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 arch/mips/boot/dts/loongson/Makefile          |   1 +
 arch/mips/boot/dts/loongson/loongson1c.dtsi   | 141 ++++++++++++++++++++++++++
 arch/mips/boot/dts/loongson/smartloong-1c.dts | 110 ++++++++++++++++++++
 3 files changed, 252 insertions(+)

diff --git a/arch/mips/boot/dts/loongson/Makefile b/arch/mips/boot/dts/loongson/Makefile
index 1130efa12768..de4570380c3e 100644
--- a/arch/mips/boot/dts/loongson/Makefile
+++ b/arch/mips/boot/dts/loongson/Makefile
@@ -8,3 +8,4 @@ dtb-$(CONFIG_MACH_LOONGSON64)	+= loongson64v_4core_virtio.dtb
 
 dtb-$(CONFIG_MACH_LOONGSON32)	+= ls1b-demo.dtb
 dtb-$(CONFIG_MACH_LOONGSON32)	+= lsgz_1b_dev.dtb
+dtb-$(CONFIG_MACH_LOONGSON32)	+= smartloong-1c.dtb
diff --git a/arch/mips/boot/dts/loongson/loongson1c.dtsi b/arch/mips/boot/dts/loongson/loongson1c.dtsi
new file mode 100644
index 000000000000..5e80c6a657af
--- /dev/null
+++ b/arch/mips/boot/dts/loongson/loongson1c.dtsi
@@ -0,0 +1,141 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2023-2025 Keguang Zhang <keguang.zhang@gmail.com>
+ */
+
+/dts-v1/;
+#include "loongson1.dtsi"
+
+/ {
+	clkc: clock-controller@1fe78030 {
+		compatible = "loongson,ls1c-clk";
+		reg = <0x1fe78030 0x8>;
+		clocks = <&xtal>;
+		#clock-cells = <1>;
+	};
+};
+
+&soc {
+	syscon: syscon@420 {
+		compatible = "loongson,ls1c-syscon", "syscon";
+		reg = <0x420 0x8>;
+	};
+
+	intc4: interrupt-controller@10a0 {
+		compatible = "loongson,ls1x-intc";
+		reg = <0x10a0 0x18>;
+		interrupt-controller;
+		interrupt-parent = <&cpu_intc>;
+		interrupts = <6>;
+		#interrupt-cells = <2>;
+	};
+
+	gpio2: gpio@10c8 {
+		compatible = "loongson,ls1x-gpio";
+		reg = <0x10c8 0x4>;
+		gpio-controller;
+		ngpios = <32>;
+		#gpio-cells = <2>;
+	};
+
+	gpio3: gpio@10cc {
+		compatible = "loongson,ls1x-gpio";
+		reg = <0x10cc 0x4>;
+		gpio-controller;
+		ngpios = <32>;
+		#gpio-cells = <2>;
+	};
+
+	dma: dma-controller@1160 {
+		compatible = "loongson,ls1c-apbdma", "loongson,ls1b-apbdma";
+		reg = <0x1160 0x4>;
+		interrupt-parent = <&intc0>;
+		interrupts = <13 IRQ_TYPE_EDGE_RISING>,
+			     <14 IRQ_TYPE_EDGE_RISING>,
+			     <15 IRQ_TYPE_EDGE_RISING>;
+		interrupt-names = "ch0", "ch1", "ch2";
+		#dma-cells = <1>;
+	};
+
+	emac: ethernet@110000 {
+		compatible = "loongson,ls1c-emac", "snps,dwmac-3.50a";
+		reg = <0x110000 0x10000>;
+		clocks = <&clkc LS1X_CLKID_AHB>;
+		clock-names = "stmmaceth";
+		interrupt-parent = <&intc1>;
+		interrupts = <3 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "macirq";
+		loongson,ls1-syscon = <&syscon>;
+		snps,pbl = <1>;
+		status = "disabled";
+	};
+
+	ehci: usb@120000 {
+		compatible = "generic-ehci";
+		reg = <0x120000 0x100>;
+		interrupt-parent = <&intc1>;
+		interrupts = <0 IRQ_TYPE_LEVEL_HIGH>;
+		status = "disabled";
+	};
+
+	ohci: usb@128000 {
+		compatible = "generic-ohci";
+		reg = <0x128000 0x100>;
+		interrupt-parent = <&intc1>;
+		interrupts = <1 IRQ_TYPE_LEVEL_HIGH>;
+		status = "disabled";
+	};
+};
+
+&apb {
+	watchdog: watchdog@1c060 {
+		compatible = "loongson,ls1c-wdt";
+		reg = <0x1c060 0xc>;
+		clocks = <&clkc LS1X_CLKID_APB>;
+		status = "disabled";
+	};
+
+	rtc: rtc@24000 {
+		compatible = "loongson,ls1c-rtc";
+		reg = <0x24000 0x78>;
+		status = "disabled";
+	};
+
+	nand: nand-controller@38000 {
+		compatible = "loongson,ls1c-nand-controller";
+		reg = <0x38000 0x24>, <0x38040 0x4>;
+		reg-names = "nand", "nand-dma";
+		dmas = <&dma 0>;
+		dma-names = "rxtx";
+		#address-cells = <1>;
+		#size-cells = <0>;
+		status = "disabled";
+
+		nand@0 {
+			reg = <0>;
+			label = "ls1x-nand";
+			nand-use-soft-ecc-engine;
+			nand-ecc-algo = "hamming";
+		};
+	};
+};
+
+&gpio0 {
+	ngpios = <32>;
+};
+
+&gpio1 {
+	ngpios = <32>;
+};
+
+&uart1 {
+	interrupts = <4 IRQ_TYPE_LEVEL_HIGH>;
+};
+
+&uart2 {
+	interrupts = <5 IRQ_TYPE_LEVEL_HIGH>;
+};
+
+&uart3 {
+	interrupts = <29 IRQ_TYPE_LEVEL_HIGH>;
+};
diff --git a/arch/mips/boot/dts/loongson/smartloong-1c.dts b/arch/mips/boot/dts/loongson/smartloong-1c.dts
new file mode 100644
index 000000000000..e6c6c2f00c42
--- /dev/null
+++ b/arch/mips/boot/dts/loongson/smartloong-1c.dts
@@ -0,0 +1,110 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2023-2025 Keguang Zhang <keguang.zhang@gmail.com>
+ */
+
+/dts-v1/;
+
+#include <dt-bindings/gpio/gpio.h>
+
+#include "loongson1c.dtsi"
+
+/ {
+	compatible = "loongmasses,smartloong-1c", "loongson,ls1c";
+	model = "Smartloong-1C Board";
+
+	memory@0 {
+		device_type = "memory";
+		reg = <0x0 0x4000000>;
+	};
+
+	aliases {
+		gpio0 = &gpio0;
+		gpio1 = &gpio1;
+		gpio2 = &gpio2;
+		gpio3 = &gpio3;
+		serial0 = &uart2;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+
+	leds {
+		compatible = "gpio-leds";
+
+		led0 {
+			label = "led0";
+			gpios = <&gpio1 20 GPIO_ACTIVE_LOW>;
+			linux,default-trigger = "heartbeat";
+		};
+
+		led1 {
+			label = "led1";
+			gpios = <&gpio1 21 GPIO_ACTIVE_LOW>;
+			linux,default-trigger = "nand-disk";
+		};
+	};
+};
+
+&xtal {
+	clock-frequency = <24000000>;
+};
+
+&emac {
+	phy-handle = <&phy0>;
+	phy-mode = "rmii";
+	status = "okay";
+
+	mdio {
+		compatible = "snps,dwmac-mdio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		phy0: ethernet-phy@13 {
+			reg = <0x13>;
+		};
+	};
+};
+
+&nand {
+	status = "okay";
+
+	nand@0 {
+		partitions {
+			compatible = "fixed-partitions";
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			partition@0 {
+				label = "kernel";
+				reg = <0x0 0x1000000>;
+			};
+
+			partition@1000000 {
+				label = "rootfs";
+				reg = <0x1000000 0x7000000>;
+			};
+		};
+	};
+};
+
+&ehci {
+	status = "okay";
+};
+
+&ohci {
+	status = "okay";
+};
+
+&rtc {
+	status = "okay";
+};
+
+&uart2 {
+	status = "okay";
+};
+
+&watchdog {
+	status = "okay";
+};

-- 
2.43.0

