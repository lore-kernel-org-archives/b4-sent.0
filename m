From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Fri, 27 Nov 2026 23:59:29 +0300
Subject: [PATCH 1/3] ARM: dts: cortina: Describe CS7542 peripheral
 controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-cs7542-peripherals-dts-v1-1-7ce24b842b3a@gmail.com>
References: <20261127-b4-cs7542-peripherals-dts-v1-0-7ce24b842b3a@gmail.com>
In-Reply-To: <20261127-b4-cs7542-peripherals-dts-v1-0-7ce24b842b3a@gmail.com>
To: Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795813168; l=12071;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=e2mylpsi+UNf0UKQ0a9a9Z12LfwJLBgmUI633+jZlAM=;
 b=4J2bGBFJQlH+YLwi3IS5R0MXXhl6H0581tJzKlYuEwvsUEPJJjo6JzseDk0LNqAdoY4t1+UEl
 Ez4FLRWoS2lB9mSz2O/oiTUmrV+YUci6POuYbHDMLkWUItrXKXq7GQG
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the shared global clock and pin controllers, peripheral
interrupt controller and GPIO banks, I2C, watchdog, RTC, TRNG, NAND PIO
controller, MDIO, network engine and three PCIe root ports.

Use the global syscon for clocks and resets, a separate PCIe PHY
provider and the complete exclusive Ethernet DMA/reset domain. Keep the
optional controllers disabled until the board supplies wiring, reserved
memory and endpoint descriptions. Replace the fixed APB assumption with
strap-selected clocks.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 arch/arm/boot/dts/cortina/cs7542.dtsi | 321 ++++++++++++++++++++++++++++++++--
 1 file changed, 311 insertions(+), 10 deletions(-)

diff --git a/arch/arm/boot/dts/cortina/cs7542.dtsi b/arch/arm/boot/dts/cortina/cs7542.dtsi
index 29b0b7da8..3d827502c 100644
--- a/arch/arm/boot/dts/cortina/cs7542.dtsi
+++ b/arch/arm/boot/dts/cortina/cs7542.dtsi
@@ -3,6 +3,8 @@
  * Device Tree Source for the Cortina Systems CS7542 SoC
  */
 
+#include <dt-bindings/clock/cortina,cs7542-clock.h>
+#include <dt-bindings/reset/cortina,cs7542-reset.h>
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 
 / {
@@ -10,11 +12,10 @@
 	#size-cells = <1>;
 	interrupt-parent = <&gic>;
 
-	/* Rate is selected by the boot strap pins, set by the board */
-	apb_clk: clock-apb {
+	ref24: clock-24mhz {
 		compatible = "fixed-clock";
 		#clock-cells = <0>;
-		clock-output-names = "apb";
+		clock-frequency = <24000000>;
 	};
 
 	cpus {
@@ -26,6 +27,7 @@
 			compatible = "arm,cortex-a9";
 			reg = <0>;
 			next-level-cache = <&l2>;
+			clocks = <&global CS7542_CLK_CPU>;
 		};
 
 		cpu@1 {
@@ -35,6 +37,7 @@
 			enable-method = "cortina,cs7542-smp";
 			cpu-release-addr = <0 0xf00000b8>;
 			next-level-cache = <&l2>;
+			clocks = <&global CS7542_CLK_CPU>;
 		};
 	};
 
@@ -44,11 +47,227 @@
 		#address-cells = <1>;
 		#size-cells = <1>;
 
+		pcie0: pcie@80000000 {
+			compatible = "cortina,cs7542-pcie";
+			reg = <0x80000000 0x1000>, <0x80001000 0x1000>, <0xf00a0000 0x100>;
+			reg-names = "dbi", "config", "app";
+			#address-cells = <3>;
+			#size-cells = <2>;
+			device_type = "pci";
+			linux,pci-domain = <0>;
+			bus-range = <0 0xff>;
+			num-lanes = <1>;
+			ranges = <0x82000000 0 0x80200000 0x80200000 0 0x1fe00000>;
+			interrupts = <GIC_SPI 33 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "msi";
+			clocks = <&global CS7542_CLK_PCIE0>;
+			resets = <&global CS7542_RESET_PCIE0>;
+			phys = <&serdes 0>;
+			phy-names = "pcie";
+			#interrupt-cells = <1>;
+			interrupt-map-mask = <0 0 0 7>;
+			interrupt-map = <0 0 0 1 &pcie0_intc 1>,
+					<0 0 0 2 &pcie0_intc 2>,
+					<0 0 0 3 &pcie0_intc 3>,
+					<0 0 0 4 &pcie0_intc 4>;
+			status = "disabled";
+
+			pcie0_port: pcie@0,0 {
+				compatible = "pciclass,0604";
+				reg = <0 0 0 0 0>;
+				device_type = "pci";
+				#address-cells = <3>;
+				#size-cells = <2>;
+				ranges;
+			};
+
+			pcie0_intc: interrupt-controller {
+				#address-cells = <0>;
+				#interrupt-cells = <1>;
+				interrupt-controller;
+			};
+		};
+
+		pcie1: pcie@a0000000 {
+			compatible = "cortina,cs7542-pcie";
+			reg = <0xa0000000 0x1000>, <0xa0001000 0x1000>, <0xf00a0400 0x100>;
+			reg-names = "dbi", "config", "app";
+			#address-cells = <3>;
+			#size-cells = <2>;
+			device_type = "pci";
+			linux,pci-domain = <1>;
+			bus-range = <0 0xff>;
+			num-lanes = <1>;
+			ranges = <0x82000000 0 0xa0200000 0xa0200000 0 0x1fe00000>;
+			interrupts = <GIC_SPI 34 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "msi";
+			clocks = <&global CS7542_CLK_PCIE1>;
+			resets = <&global CS7542_RESET_PCIE1>;
+			phys = <&serdes 1>;
+			phy-names = "pcie";
+			#interrupt-cells = <1>;
+			interrupt-map-mask = <0 0 0 7>;
+			interrupt-map = <0 0 0 1 &pcie1_intc 1>,
+					<0 0 0 2 &pcie1_intc 2>,
+					<0 0 0 3 &pcie1_intc 3>,
+					<0 0 0 4 &pcie1_intc 4>;
+			status = "disabled";
+
+			pcie1_port: pcie@0,0 {
+				compatible = "pciclass,0604";
+				reg = <0 0 0 0 0>;
+				device_type = "pci";
+				#address-cells = <3>;
+				#size-cells = <2>;
+				ranges;
+			};
+
+			pcie1_intc: interrupt-controller {
+				#address-cells = <0>;
+				#interrupt-cells = <1>;
+				interrupt-controller;
+			};
+		};
+
+		pcie2: pcie@c0000000 {
+			compatible = "cortina,cs7542-pcie";
+			reg = <0xc0000000 0x1000>, <0xc0001000 0x1000>, <0xf00a0800 0x100>;
+			reg-names = "dbi", "config", "app";
+			#address-cells = <3>;
+			#size-cells = <2>;
+			device_type = "pci";
+			linux,pci-domain = <2>;
+			bus-range = <0 0xff>;
+			num-lanes = <1>;
+			ranges = <0x82000000 0 0xc0200000 0xc0200000 0 0x1fe00000>;
+			interrupts = <GIC_SPI 35 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "msi";
+			clocks = <&global CS7542_CLK_PCIE2>;
+			resets = <&global CS7542_RESET_PCIE2>;
+			phys = <&serdes 2>;
+			phy-names = "pcie";
+			#interrupt-cells = <1>;
+			interrupt-map-mask = <0 0 0 7>;
+			interrupt-map = <0 0 0 1 &pcie2_intc 1>,
+					<0 0 0 2 &pcie2_intc 2>,
+					<0 0 0 3 &pcie2_intc 3>,
+					<0 0 0 4 &pcie2_intc 4>;
+			status = "disabled";
+
+			pcie2_port: pcie@0,0 {
+				compatible = "pciclass,0604";
+				reg = <0 0 0 0 0>;
+				device_type = "pci";
+				#address-cells = <3>;
+				#size-cells = <2>;
+				ranges;
+			};
+
+			pcie2_intc: interrupt-controller {
+				#address-cells = <0>;
+				#interrupt-cells = <1>;
+				interrupt-controller;
+			};
+		};
+
+		global: syscon@f0000000 {
+			compatible = "cortina,cs7542-syscon", "syscon", "simple-mfd";
+			reg = <0xf0000000 0x100>;
+			#clock-cells = <1>;
+			#reset-cells = <1>;
+
+			pinctrl: pinctrl {
+				compatible = "cortina,cs7542-pinctrl";
+			};
+		};
+
+		ethernet: ethernet@f0010000 {
+			compatible = "cortina,cs7542-ethernet";
+			reg = <0xf0010000 0x500>,
+			      <0xf0090000 0x800>, <0xf0020000 0x4000>,
+			      <0xf0030000 0x400>, <0xf0040000 0x800>,
+			      <0xf0060000 0x100>, <0xf0400000 0x100000>;
+			reg-names = "ni", "dma", "fe", "qm", "tm",
+				    "sch", "xram";
+			interrupts = <GIC_SPI 37 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 38 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 39 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "eth0", "eth1", "eth2";
+			resets = <&global CS7542_RESET_NI>,
+				 <&global CS7542_RESET_FE>,
+				 <&global CS7542_RESET_TM>,
+				 <&global CS7542_RESET_SCH>,
+				 <&global CS7542_RESET_QM>,
+				 <&global CS7542_RESET_DMA>,
+				 <&global CS7542_RESET_NI_XRAM>;
+			reset-names = "ni", "fe", "tm", "sch", "qm", "dma", "xram";
+			#address-cells = <1>;
+			#size-cells = <0>;
+			cortina,global-syscon = <&global>;
+			status = "disabled";
+
+			gmac0: ethernet-port@0 {
+				reg = <0>;
+				status = "disabled";
+			};
+
+			gmac1: ethernet-port@1 {
+				reg = <1>;
+				status = "disabled";
+			};
+
+			gmac2: ethernet-port@2 {
+				reg = <2>;
+				status = "disabled";
+			};
+		};
+
+		nandc: nand-controller@f0050000 {
+			compatible = "cortina,cs7542-nand";
+			reg = <0xf0050000 0x300>, <0xe0000000 0x08000000>;
+			reg-names = "regs", "data";
+			interrupts = <GIC_SPI 18 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&global CS7542_CLK_AXI>;
+			resets = <&global CS7542_RESET_FLASH>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
+		intc: interrupt-controller@f0070004 {
+			compatible = "cortina,cs7542-intc";
+			reg = <0xf0070004 0x8>;
+			interrupts = <GIC_SPI 3 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-controller;
+			#interrupt-cells = <1>;
+		};
+
+		mdio0: mdio@f00700a0 {
+			compatible = "cortina,cs7542-mdio";
+			reg = <0xf00700a0 0x14>;
+			clocks = <&global CS7542_CLK_APB>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
+		i2c: i2c@f00700e8 {
+			compatible = "cortina,cs7542-i2c";
+			reg = <0xf00700e8 0x28>;
+			interrupt-parent = <&intc>;
+			interrupts = <11>;
+			clocks = <&global CS7542_CLK_APB>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			status = "disabled";
+		};
+
 		uart0: serial@f0070110 {
 			compatible = "cortina,cs7542-uart";
 			reg = <0xf0070110 0x30>;
 			interrupts = <GIC_SPI 6 IRQ_TYPE_LEVEL_HIGH>;
-			clocks = <&apb_clk>;
+			clocks = <&global CS7542_CLK_APB>;
 
 			status = "disabled";
 		};
@@ -57,7 +276,7 @@
 			compatible = "cortina,cs7542-uart";
 			reg = <0xf0070140 0x30>;
 			interrupts = <GIC_SPI 7 IRQ_TYPE_LEVEL_HIGH>;
-			clocks = <&apb_clk>;
+			clocks = <&global CS7542_CLK_APB>;
 
 			status = "disabled";
 		};
@@ -66,7 +285,7 @@
 			compatible = "cortina,cs7542-uart";
 			reg = <0xf0070170 0x30>;
 			interrupts = <GIC_SPI 8 IRQ_TYPE_LEVEL_HIGH>;
-			clocks = <&apb_clk>;
+			clocks = <&global CS7542_CLK_APB>;
 
 			status = "disabled";
 		};
@@ -75,8 +294,90 @@
 			compatible = "cortina,cs7542-uart";
 			reg = <0xf00701a0 0x30>;
 			interrupts = <GIC_SPI 9 IRQ_TYPE_LEVEL_HIGH>;
-			clocks = <&apb_clk>;
+			clocks = <&global CS7542_CLK_APB>;
+
+			status = "disabled";
+		};
+
+		gpio0: gpio@f00701d0 {
+			compatible = "cortina,cs7542-gpio";
+			reg = <0xf00701d0 0x20>;
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
+			reg = <0xf00701f0 0x20>;
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
+			reg = <0xf0070210 0x20>;
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
+			reg = <0xf0070230 0x20>;
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
+			reg = <0xf0070250 0x20>;
+			interrupt-parent = <&intc>;
+			interrupts = <10>;
+			gpio-controller;
+			#gpio-cells = <2>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+		};
+
+		serdes: phy@f00a1000 {
+			compatible = "cortina,cs7542-pcie-phy";
+			reg = <0xf00a1000 0x400>, <0xf00a5000 0x400>,
+			      <0xf00a9000 0x400>, <0xf00a0e00 0x180>;
+			reg-names = "phy0", "phy1", "phy2", "status";
+			clocks = <&ref24>;
+			cortina,global-syscon = <&global>;
+			#phy-cells = <1>;
+		};
+
+		trng: rng@f0600000 {
+			compatible = "cortina,cs7542-trng";
+			reg = <0xf0600000 0x20>;
+			cortina,syscon = <&global>;
+			status = "disabled";
+		};
 
+		rtc0: rtc@f4920000 {
+			compatible = "cortina,cs7542-rtc";
+			reg = <0xf4920000 0x50>;
+			interrupt-names = "alarm", "periodic";
+			interrupt-parent = <&gic>;
+			interrupts = <GIC_SPI 10 IRQ_TYPE_LEVEL_HIGH>,
+					<GIC_SPI 11 IRQ_TYPE_LEVEL_HIGH>;
 			status = "disabled";
 		};
 
@@ -99,21 +400,21 @@
 			compatible = "arm,cortex-a9-global-timer";
 			reg = <0xf8000200 0x20>;
 			interrupts = <GIC_PPI 11 (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_EDGE_RISING)>;
-			clocks = <&apb_clk>;
+			clocks = <&global CS7542_CLK_APB>;
 		};
 
 		timer@f8000600 {
 			compatible = "arm,cortex-a9-twd-timer";
 			reg = <0xf8000600 0x20>;
 			interrupts = <GIC_PPI 13 (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_EDGE_RISING)>;
-			clocks = <&apb_clk>;
+			clocks = <&global CS7542_CLK_APB>;
 		};
 
 		watchdog@f8000620 {
 			compatible = "arm,cortex-a9-twd-wdt";
 			reg = <0xf8000620 0x20>;
 			interrupts = <GIC_PPI 14 (GIC_CPU_MASK_SIMPLE(2) | IRQ_TYPE_EDGE_RISING)>;
-			clocks = <&apb_clk>;
+			clocks = <&global CS7542_CLK_APB>;
 		};
 
 		gic: interrupt-controller@f8001000 {

-- 
2.53.0

