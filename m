From: Ben Grisdale <bengris32@protonmail.ch>
Date: Mon, 19 Oct 2026 01:40:03 +0100
Subject: [PATCH 7/8] arm64: dts: mediatek: Add basic support for MT8163 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-7-f2462b2d2437@protonmail.ch>
References: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
In-Reply-To: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792370441; l=6537;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=14rHWBooScrYpq6ceUihMici2wAk5TROgmMtstlnlWA=;
 b=O/LvnHeIwaBISkVpf3b2vuHO9KT7c+PAwIFrHTDsGNzferf+r+Bb9ZE2A8EzOVZuV1Sahwk32
 xXAMJwZJnB1BZ1/7nQ3ojNRvPF6m/MgxkQfo3c0RoYDZ+qq0zXox+Nb
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a basic dtsi for the MediaTek MT8163 SoC, describing the CPUs and
caches, PSCI, interrupt controllers, timers, PMU, watchdog and UARTs.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 arch/arm64/boot/dts/mediatek/mt8163.dtsi | 243 +++++++++++++++++++++++++++++++
 1 file changed, 243 insertions(+)

diff --git a/arch/arm64/boot/dts/mediatek/mt8163.dtsi b/arch/arm64/boot/dts/mediatek/mt8163.dtsi
new file mode 100644
index 000000000000..645f4e15587b
--- /dev/null
+++ b/arch/arm64/boot/dts/mediatek/mt8163.dtsi
@@ -0,0 +1,243 @@
+// SPDX-License-Identifier: GPL-2.0-only OR MIT
+/*
+ * Copyright (c) 2026 Ben Grisdale <bengris32@protonmail.ch>
+ */
+
+#include <dt-bindings/interrupt-controller/arm-gic.h>
+
+/ {
+	compatible = "mediatek,mt8163";
+	interrupt-parent = <&sysirq>;
+	#address-cells = <2>;
+	#size-cells = <2>;
+
+	clk32k: clock-32768 {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <32768>;
+		clock-output-names = "clk32k";
+	};
+
+	clk13m: clock-13000000 {
+		compatible = "fixed-factor-clock";
+		#clock-cells = <0>;
+		clocks = <&clk26m>;
+		clock-div = <2>;
+		clock-mult = <1>;
+		clock-output-names = "clk13m";
+	};
+
+	clk26m: clock-26000000 {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <26000000>;
+		clock-output-names = "clk26m";
+	};
+
+	cpus {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		cpu0: cpu@0 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x0>;
+			enable-method = "psci";
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2>;
+		};
+
+		cpu1: cpu@1 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x1>;
+			enable-method = "psci";
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2>;
+		};
+
+		cpu2: cpu@2 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x2>;
+			enable-method = "psci";
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2>;
+		};
+
+		cpu3: cpu@3 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a53";
+			reg = <0x3>;
+			enable-method = "psci";
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2>;
+		};
+
+		cpu-map {
+			cluster0 {
+				core0 {
+					cpu = <&cpu0>;
+				};
+
+				core1 {
+					cpu = <&cpu1>;
+				};
+
+				core2 {
+					cpu = <&cpu2>;
+				};
+
+				core3 {
+					cpu = <&cpu3>;
+				};
+			};
+		};
+
+		l2: l2-cache {
+			compatible = "cache";
+			cache-level = <2>;
+			cache-size = <524288>;
+			cache-line-size = <64>;
+			cache-sets = <512>;
+			cache-unified;
+		};
+	};
+
+	pmu {
+		compatible = "arm,cortex-a53-pmu";
+		interrupts = <GIC_SPI 8 IRQ_TYPE_LEVEL_LOW>,
+			     <GIC_SPI 9 IRQ_TYPE_LEVEL_LOW>,
+			     <GIC_SPI 10 IRQ_TYPE_LEVEL_LOW>,
+			     <GIC_SPI 11 IRQ_TYPE_LEVEL_LOW>;
+		interrupt-affinity = <&cpu0>, <&cpu1>, <&cpu2>, <&cpu3>;
+	};
+
+	psci {
+		compatible = "arm,psci-1.0";
+		method = "smc";
+	};
+
+	soc {
+		compatible = "simple-bus";
+		ranges;
+		#address-cells = <2>;
+		#size-cells = <2>;
+
+		watchdog: watchdog@10007000 {
+			compatible = "mediatek,mt8163-wdt";
+			reg = <0 0x10007000 0 0x1000>;
+			interrupts = <GIC_SPI 128 IRQ_TYPE_EDGE_FALLING>;
+			#reset-cells = <1>;
+		};
+
+		timer: timer@10008000 {
+			compatible = "mediatek,mt8163-timer",
+				     "mediatek,mt6577-timer";
+			reg = <0 0x10008000 0 0x1000>;
+			interrupts = <GIC_SPI 152 IRQ_TYPE_LEVEL_LOW>;
+			clocks = <&clk13m>, <&clk32k>;
+			clock-names = "system-clk", "rtc-clk";
+		};
+
+		sysirq: interrupt-controller@10200620 {
+			compatible = "mediatek,mt8163-sysirq",
+				     "mediatek,mt6577-sysirq";
+			reg = <0 0x10200620 0 0x20>;
+			#interrupt-cells = <3>;
+			interrupt-parent = <&gic>;
+			interrupt-controller;
+		};
+
+		gic: interrupt-controller@10221000 {
+			compatible = "arm,gic-400";
+			reg = <0 0x10221000 0 0x1000>,
+			      <0 0x10222000 0 0x2000>,
+			      <0 0x10224000 0 0x2000>,
+			      <0 0x10226000 0 0x2000>;
+			interrupt-controller;
+			#interrupt-cells = <3>;
+			interrupt-parent = <&gic>;
+			interrupts = <GIC_PPI 9 (GIC_CPU_MASK_SIMPLE(4) |
+				      IRQ_TYPE_LEVEL_HIGH)>;
+		};
+
+		uart0: serial@11002000 {
+			compatible = "mediatek,mt8163-uart",
+				     "mediatek,mt6577-uart";
+			reg = <0 0x11002000 0 0x400>;
+			interrupts = <GIC_SPI 91 IRQ_TYPE_LEVEL_LOW>;
+			clocks = <&clk26m>, <&clk26m>;
+			clock-names = "baud", "bus";
+
+			status = "disabled";
+		};
+
+		uart1: serial@11003000 {
+			compatible = "mediatek,mt8163-uart",
+				     "mediatek,mt6577-uart";
+			reg = <0 0x11003000 0 0x400>;
+			interrupts = <GIC_SPI 92 IRQ_TYPE_LEVEL_LOW>;
+			clocks = <&clk26m>, <&clk26m>;
+			clock-names = "baud", "bus";
+
+			status = "disabled";
+		};
+
+		uart2: serial@11004000 {
+			compatible = "mediatek,mt8163-uart",
+				     "mediatek,mt6577-uart";
+			reg = <0 0x11004000 0 0x400>;
+			interrupts = <GIC_SPI 93 IRQ_TYPE_LEVEL_LOW>;
+			clocks = <&clk26m>, <&clk26m>;
+			clock-names = "baud", "bus";
+
+			status = "disabled";
+		};
+
+		uart3: serial@11005000 {
+			compatible = "mediatek,mt8163-uart",
+				     "mediatek,mt6577-uart";
+			reg = <0 0x11005000 0 0x400>;
+			interrupts = <GIC_SPI 94 IRQ_TYPE_LEVEL_LOW>;
+			clocks = <&clk26m>, <&clk26m>;
+			clock-names = "baud", "bus";
+
+			status = "disabled";
+		};
+	};
+
+	timer {
+		compatible = "arm,armv8-timer";
+		interrupt-parent = <&gic>;
+		interrupts = <GIC_PPI 13
+			      (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 14
+			      (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 11
+			      (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 10
+			      (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>;
+		arm,no-tick-in-suspend;
+	};
+};

-- 
2.56.0

