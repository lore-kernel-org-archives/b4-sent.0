From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:42 +0800
Subject: [PATCH 16/19] riscv: dts: allwinner: add the Allwinner V861 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-16-eb71ec3ee523@iscas.ac.cn>
References: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
In-Reply-To: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guo Ren <guoren@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Han Gao <gaohan@iscas.ac.cn>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Maxime Ripard <mripard@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-csky@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=10397;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=I8wnVF/DxQ+OwPzKUk/zbleMxuzgspwkeJdPCkKcyAI=;
 b=XbE5JqKc/+xicVaxMpURs2OAsP30uKgCVuEGNLvpjV1/qMGyJEQsGJqL5Vkjv64UiYtdMrdQk
 kfuyEydjd9YB+W+cJRNAlUu2rx9g6dTgHRTPm2wELTS4q3j4Bl+DDc0
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the V861 SoC with its two C907 harts, PLIC, CLINT, clock
controllers, RTC, pin controllers and UART0.

The cache geometry and PMU events come from the V861 and C907 manuals.
Zcb, Zbkc and Zvfh were also checked to work on the hardware.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/boot/dts/allwinner/sun252i-v861.dtsi | 272 ++++++++++++++++++++++++
 1 file changed, 272 insertions(+)

diff --git a/arch/riscv/boot/dts/allwinner/sun252i-v861.dtsi b/arch/riscv/boot/dts/allwinner/sun252i-v861.dtsi
new file mode 100644
index 000000000000..7a18b973ee32
--- /dev/null
+++ b/arch/riscv/boot/dts/allwinner/sun252i-v861.dtsi
@@ -0,0 +1,272 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/* Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn> */
+
+#include <dt-bindings/clock/sun252i-v861-ccu.h>
+#include <dt-bindings/clock/sun252i-v861-r-ccu.h>
+#include <dt-bindings/clock/sun6i-rtc.h>
+#include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/reset/sun252i-v861-ccu.h>
+#include <dt-bindings/reset/sun252i-v861-r-ccu.h>
+
+/ {
+	#address-cells = <2>;
+	#size-cells = <2>;
+
+	cpus {
+		#address-cells = <1>;
+		#size-cells = <0>;
+		timebase-frequency = <24000000>;
+
+		cpu0: cpu@0 {
+			compatible = "csky,c907", "riscv";
+			device_type = "cpu";
+			reg = <0>;
+			d-cache-block-size = <64>;
+			d-cache-sets = <64>;
+			d-cache-size = <16384>;
+			i-cache-block-size = <64>;
+			i-cache-sets = <64>;
+			i-cache-size = <16384>;
+			mmu-type = "riscv,sv39";
+			next-level-cache = <&l2_cache>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c", "b", "v",
+				"zicbom", "zicbop", "zicboz", "zicntr", "zicond",
+				"zicsr", "zifencei", "zihintntl", "zihintpause",
+				"zihpm", "zawrs", "zfa", "zfbfmin", "zfh",
+				"zca", "zcb", "zcd", "zba", "zbb", "zbc", "zbkc",
+				"zbs", "zkt", "zvfbfmin", "zvfbfwma", "zvfh",
+				"sscofpmf", "sstc", "svinval", "svnapot", "svpbmt";
+			riscv,cbom-block-size = <64>;
+			riscv,cbop-block-size = <64>;
+			riscv,cboz-block-size = <64>;
+
+			cpu0_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+
+		cpu1: cpu@1 {
+			compatible = "csky,c907", "riscv";
+			device_type = "cpu";
+			reg = <1>;
+			d-cache-block-size = <64>;
+			d-cache-sets = <64>;
+			d-cache-size = <16384>;
+			i-cache-block-size = <64>;
+			i-cache-sets = <64>;
+			i-cache-size = <16384>;
+			mmu-type = "riscv,sv39";
+			next-level-cache = <&l2_cache>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c", "b", "v",
+				"zicbom", "zicbop", "zicboz", "zicntr", "zicond",
+				"zicsr", "zifencei", "zihintntl", "zihintpause",
+				"zihpm", "zawrs", "zfa", "zfbfmin", "zfh",
+				"zca", "zcb", "zcd", "zba", "zbb", "zbc", "zbkc",
+				"zbs", "zkt", "zvfbfmin", "zvfbfwma", "zvfh",
+				"sscofpmf", "sstc", "svinval", "svnapot", "svpbmt";
+			riscv,cbom-block-size = <64>;
+			riscv,cbop-block-size = <64>;
+			riscv,cboz-block-size = <64>;
+
+			cpu1_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+
+		l2_cache: l2-cache {
+			compatible = "cache";
+			cache-block-size = <64>;
+			cache-level = <2>;
+			cache-sets = <128>;
+			cache-size = <131072>;
+			cache-unified;
+		};
+	};
+
+	osc24M: osc24M-clk {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <24000000>;
+		clock-output-names = "osc24M";
+	};
+
+	pmu {
+		compatible = "riscv,pmu";
+		riscv,event-to-mhpmcounters =
+			<0x00003 0x00006 0x0007fff8>,
+			<0x00008 0x00009 0x0007fff8>,
+			<0x10000 0x10003 0x0007fff8>,
+			<0x10008 0x10009 0x0007fff8>,
+			<0x10019 0x10019 0x0007fff8>,
+			<0x1001b 0x1001b 0x0007fff8>,
+			<0x10021 0x10021 0x0007fff8>,
+			<0x10028 0x10029 0x0007fff8>;
+		riscv,event-to-mhpmevent =
+			<0x00003 0x00000000 0x000000a5>,
+			<0x00004 0x00000000 0x000000a6>,
+			<0x00005 0x00000000 0x00000036>,
+			<0x00006 0x00000000 0x00000038>,
+			<0x00008 0x00000000 0x00000027>,
+			<0x00009 0x00000000 0x00000028>,
+			<0x10000 0x00000000 0x0000000c>,
+			<0x10001 0x00000000 0x0000000d>,
+			<0x10002 0x00000000 0x0000000e>,
+			<0x10003 0x00000000 0x0000000f>,
+			<0x10008 0x00000000 0x00000001>,
+			<0x10009 0x00000000 0x00000002>,
+			<0x10019 0x00000000 0x000000a4>,
+			<0x1001b 0x00000000 0x000000a3>,
+			<0x10021 0x00000000 0x00000003>,
+			<0x10028 0x00000000 0x00000036>,
+			<0x10029 0x00000000 0x00000038>;
+		riscv,raw-event-to-mhpmcounters =
+			<0x00000000 0x00000001 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000002 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000003 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000005 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000006 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000007 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000008 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000009 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000000b 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000000c 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000000d 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000000e 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000000f 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000016 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000001b 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000001c 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000001d 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000001f 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000020 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000021 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000023 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000025 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000027 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000028 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000029 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000002a 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000030 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000036 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x00000038 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000009b 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000009c 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x0000009e 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x000000a3 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x000000a4 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x000000a5 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x000000a6 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x000000a7 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x000000a8 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x000000a9 0xffffffff 0xffffffff 0x0007fff8>,
+			<0x00000000 0x000000aa 0xffffffff 0xffffffff 0x0007fff8>;
+	};
+
+	soc {
+		compatible = "simple-bus";
+		#address-cells = <2>;
+		#size-cells = <2>;
+		interrupt-parent = <&plic>;
+		ranges;
+		dma-noncoherent;
+
+		pio: pinctrl@2000000 {
+			compatible = "allwinner,sun252i-v861-pinctrl";
+			reg = <0 0x02000000 0 0x400>;
+			interrupts = <67 IRQ_TYPE_LEVEL_HIGH>, <71 IRQ_TYPE_LEVEL_HIGH>,
+				     <73 IRQ_TYPE_LEVEL_HIGH>, <75 IRQ_TYPE_LEVEL_HIGH>,
+				     <77 IRQ_TYPE_LEVEL_HIGH>, <79 IRQ_TYPE_LEVEL_HIGH>,
+				     <81 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&ccu CLK_APB0>, <&osc24M>, <&rtc CLK_OSC32K>;
+			clock-names = "apb", "hosc", "losc";
+			gpio-controller;
+			#gpio-cells = <3>;
+			interrupt-controller;
+			#interrupt-cells = <3>;
+
+			uart0_ph_pins: uart0-ph-pins {
+				pins = "PH9", "PH10";
+				function = "uart0";
+				allwinner,pinmux = <5>;
+				bias-pull-up;
+			};
+		};
+
+		r_pio: pinctrl@2000540 {
+			compatible = "allwinner,sun252i-v861-r-pinctrl";
+			reg = <0 0x02000540 0 0x60>;
+			interrupts = <85 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&ccu CLK_APB0>, <&osc24M>, <&rtc CLK_OSC32K>;
+			clock-names = "apb", "hosc", "losc";
+			gpio-controller;
+			#gpio-cells = <3>;
+			interrupt-controller;
+			#interrupt-cells = <3>;
+		};
+
+		ccu: clock-controller@2001000 {
+			compatible = "allwinner,sun252i-v861-ccu";
+			reg = <0 0x02001000 0 0x1000>;
+			clocks = <&osc24M>, <&rtc CLK_OSC32K>, <&rtc CLK_IOSC>;
+			clock-names = "hosc", "losc", "iosc";
+			#clock-cells = <1>;
+			#reset-cells = <1>;
+		};
+
+		uart0: serial@2500000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0 0x02500000 0 0x400>;
+			interrupts = <2 IRQ_TYPE_LEVEL_HIGH>;
+			reg-shift = <2>;
+			reg-io-width = <4>;
+			clocks = <&ccu CLK_BUS_UART0>;
+			resets = <&ccu RST_BUS_UART0>;
+			status = "disabled";
+		};
+
+		r_ccu: clock-controller@7010000 {
+			compatible = "allwinner,sun252i-v861-r-ccu";
+			reg = <0 0x07010000 0 0x400>;
+			clocks = <&osc24M>, <&rtc CLK_OSC32K>, <&rtc CLK_IOSC>,
+				 <&ccu CLK_PLL_PERIPH0_200M>;
+			clock-names = "hosc", "losc", "iosc", "pll-periph";
+			#clock-cells = <1>;
+			#reset-cells = <1>;
+		};
+
+		rtc: rtc@7090000 {
+			compatible = "allwinner,sun252i-v861-rtc",
+				     "allwinner,sun50i-r329-rtc";
+			reg = <0 0x07090000 0 0x400>;
+			interrupts = <138 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&r_ccu CLK_BUS_R_RTC>, <&osc24M>,
+				 <&r_ccu CLK_R_AHB>;
+			clock-names = "bus", "hosc", "ahb";
+			#clock-cells = <1>;
+		};
+
+		plic: interrupt-controller@30000000 {
+			compatible = "allwinner,sun252i-v861-plic", "thead,c900-plic";
+			reg = <0 0x30000000 0 0x4000000>;
+			interrupts-extended = <&cpu0_intc 11>, <&cpu0_intc 9>,
+					      <&cpu1_intc 11>, <&cpu1_intc 9>;
+			riscv,ndev = <150>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+			#address-cells = <0>;
+		};
+
+		clint: timer@34000000 {
+			compatible = "allwinner,sun252i-v861-clint", "thead,c900-clint";
+			reg = <0 0x34000000 0 0x10000>;
+			interrupts-extended = <&cpu0_intc 3>, <&cpu0_intc 7>,
+					      <&cpu1_intc 3>, <&cpu1_intc 7>;
+		};
+	};
+};

-- 
2.55.0

