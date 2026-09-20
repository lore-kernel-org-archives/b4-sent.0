From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Sun, 20 Sep 2026 08:13:30 +0000
Subject: [PATCH 3/3] arm64: dts: amlogic: add T7 peripheral nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-t7-node-new-v1-3-e6e0840c1b0b@amlogic.com>
References: <20260920-t7-node-new-v1-0-e6e0840c1b0b@amlogic.com>
In-Reply-To: <20260920-t7-node-new-v1-0-e6e0840c1b0b@amlogic.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789892012; l=19364;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=peXhY/ZNiPmcRjcD24HE5BTTBtQP+wUOUxDOh1ytvjo=;
 b=Pc+tYHHWKbHpkoUfeRkZWTSVEitJy1ZultVqF4HVjK9j1xLmnP/P4YI3uvP8/HoN3HQg3ilkk
 cTCVGBGF51sD2Y73KDCNbdoHKJd3z+Mhzosu12OqdOOXJt4+FGMW/7B
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree descriptions for the peripherals on the Amlogic T7
SoC and the T7 A311D2 AN400 board.

Add support for the T7 Ethernet controller, SPI controllers, I2C
controllers, UARTs, pinctrl groups, regulators, and reserved memory.
Also enable the Ethernet controller on the AN400 board.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../boot/dts/amlogic/amlogic-t7-a311d2-an400.dts   | 155 +++++++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        | 452 +++++++++++++++++++++
 2 files changed, 607 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7-a311d2-an400.dts b/arch/arm64/boot/dts/amlogic/amlogic-t7-a311d2-an400.dts
index ca7536f772ff..dfd82148179b 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7-a311d2-an400.dts
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7-a311d2-an400.dts
@@ -24,12 +24,161 @@ memory@0 {
 			0x00000001 0x00000000 0x00000000 0x20000000>;
 	};
 
+	reserved-memory {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		/* 3 MiB reserved for ARM Trusted Firmware (BL31) */
+		secmon_reserved: secmon@5000000 {
+			reg = <0x0 0x05000000 0x0 0x300000>;
+			no-map;
+		};
+
+		/* 32 MiB reserved for ARM Trusted Firmware (BL32) */
+		secmon_reserved_bl32: secmon@5300000 {
+			reg = <0x0 0x05300000 0x0 0x2000000>;
+			no-map;
+		};
+	};
+
 	xtal: xtal-clk {
 		compatible = "fixed-clock";
 		clock-frequency = <24000000>;
 		clock-output-names = "xtal";
 		#clock-cells = <0>;
 	};
+
+	dc_in: regulator-dc-in {
+		compatible = "regulator-fixed";
+		regulator-name = "12V";
+		regulator-min-microvolt = <12000000>;
+		regulator-max-microvolt = <12000000>;
+		regulator-boot-on;
+		regulator-always-on;
+	};
+
+	vcc_5v: regulator-vcc-5v {
+		compatible = "regulator-fixed";
+		vin-supply = <&dc_in>;
+		regulator-name = "VCC5V";
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+		gpio = <&gpio GPIOH_1 GPIO_ACTIVE_HIGH>;
+		startup-delay-us = <70000>;
+		enable-active-high;
+		regulator-boot-on;
+		regulator-always-on;
+	};
+
+	vddao_3v3: regulator-vddao-3v3 {
+		vin-supply = <&dc_in>;
+		compatible = "regulator-fixed";
+		regulator-name = "VDDAO_3V3";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		startup-delay-us = <70000>;
+		enable-active-high;
+		regulator-boot-on;
+		regulator-always-on;
+	};
+
+	vdd1v8_reg: regulator-vdd-1v8 {
+		vin-supply = <&dc_in>;
+		compatible = "regulator-fixed";
+		regulator-name = "VDDIO_1V8";
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+		startup-delay-us = <70000>;
+		enable-active-high;
+		regulator-boot-on;
+		regulator-always-on;
+	};
+
+	vddao_1v8: regulator-vddao-1v8 {
+		compatible = "regulator-fixed";
+		vin-supply = <&vddao_3v3>;
+		regulator-name = "VDDAO_1V8";
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+		regulator-boot-on;
+		regulator-always-on;
+	};
+
+	vddio_3v3: regulator-vddio-3v3 {
+		compatible = "regulator-fixed";
+		vin-supply = <&vddao_3v3>;
+		regulator-name = "VDDIO_3V3";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		gpio = <&gpio GPIO_TEST_N GPIO_ACTIVE_HIGH>;
+		startup-delay-us = <70000>;
+		enable-active-high;
+		regulator-boot-on;
+		regulator-always-on;
+	};
+
+	sd_3v3: regulator-sd-3v3 {
+		compatible = "regulator-fixed";
+		regulator-name = "SD_3V3: SD/TF";
+		vin-supply = <&vddao_3v3>;
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		gpio = <&gpio GPIOD_11 GPIO_ACTIVE_LOW>;  /* 0R */
+		regulator-boot-on;
+		regulator-always-on;
+	};
+
+	vddio_c: regulator-sd-1v8-3v3 {
+		compatible = "regulator-gpio";
+		vin-supply = <&vddio_3v3>;
+		regulator-name = "VDDIO_C: SD/TF.";
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <3300000>;
+		gpios = <&gpio GPIOE_2 GPIO_ACTIVE_HIGH>;
+		gpios-states = <1>;
+
+		/* Based on P200 schematics, signal CARD_1.8V/3.3V_CTR */
+		states = <1800000 1
+			  3300000 0>;
+	};
+
+	vddq_1v1: regulator-vddq-1v1 {
+		compatible = "regulator-fixed";
+		vin-supply = <&dc_in>;
+		regulator-name = "VDDQ_1V1";
+		regulator-min-microvolt = <1100000>;
+		regulator-max-microvolt = <1100000>;
+		gpio = <&gpio GPIOD_10 GPIO_ACTIVE_HIGH>;
+		startup-delay-us = <70000>;
+		enable-active-high;
+		regulator-boot-on;
+		regulator-always-on;
+	};
+
+	vddqlp_0v6: regulator-vddqlp-0v6 {
+		vin-supply = <&dc_in>;
+		compatible = "regulator-fixed";
+		regulator-name = "VDDQLP_0V6";
+		regulator-min-microvolt = <600000>;
+		regulator-max-microvolt = <600000>;
+		startup-delay-us = <70000>;
+		enable-active-high;
+		regulator-boot-on;
+		regulator-always-on;
+	};
+
+	vdd_ddr: regulator-vdd-ddr {
+		vin-supply = <&dc_in>;
+		compatible = "regulator-fixed";
+		regulator-name = "VDD_DDR";
+		regulator-min-microvolt = <800000>;
+		regulator-max-microvolt = <800000>;
+		startup-delay-us = <70000>;
+		enable-active-high;
+		regulator-boot-on;
+		regulator-always-on;
+	};
 };
 
 &uart_a {
@@ -37,3 +186,9 @@ &uart_a {
 	clock-names = "xtal", "pclk", "baud";
 	status = "okay";
 };
+
+&ethmac {
+	status = "okay";
+	phy-handle = <&internal_ephy>;
+	phy-mode = "rmii";
+};
diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
index 8f3f1c0579a0..a4ca3be35842 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
@@ -5,10 +5,12 @@
 
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/power/amlogic,t7-pwrc.h>
+#include <dt-bindings/gpio/gpio.h>
 #include "amlogic-t7-reset.h"
 #include <dt-bindings/clock/amlogic,t7-scmi.h>
 #include <dt-bindings/clock/amlogic,t7-pll-clkc.h>
 #include <dt-bindings/clock/amlogic,t7-peripherals-clkc.h>
+#include <dt-bindings/gpio/amlogic,t7-periphs-pinctrl.h>
 
 / {
 	interrupt-parent = <&gic>;
@@ -238,6 +240,30 @@ soc {
 		#size-cells = <2>;
 		ranges;
 
+		ethmac: ethernet@fdc00000 {
+			compatible = "amlogic,t7-dwmac",
+				     "amlogic,meson-axg-dwmac",
+				     "snps,dwmac-4.00";
+			reg = <0x0 0xfdc00000 0x0 0x10000>,
+			      <0x0 0xfe024000 0x0 0x8>;
+			interrupts = <GIC_SPI 74 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "macirq";
+			power-domains = <&pwrc PWRC_T7_ETH_ID>;
+			clocks = <&clkc_periphs CLKID_SYS_ETH>,
+				 <&scmi_clk CLKID_FCLK_DIV2>,
+				 <&scmi_clk CLKID_FCLK_50M>;
+			clock-names = "stmmaceth", "clkin0", "clkin1";
+			rx-fifo-depth = <4096>;
+			tx-fifo-depth = <2048>;
+			status = "disabled";
+
+			mdio0: mdio {
+				compatible = "snps,dwmac-mdio";
+				#address-cells = <1>;
+				#size-cells = <0>;
+			};
+		};
+
 		gic: interrupt-controller@fff01000 {
 			compatible = "arm,gic-400";
 			#interrupt-cells = <3>;
@@ -386,6 +412,206 @@ mux {
 					};
 				};
 
+				i2c0_ao_pins2: i2c0-ao-pins2 {
+					mux {
+						groups = "i2c0_ao_sda_e",
+							"i2c0_ao_sck_e";
+						function = "i2c0_ao";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c1_ao_pins: i2c1-ao-pins {
+					mux {
+						groups = "i2c1_ao_sda",
+							"i2c1_ao_sck";
+						function = "i2c1_ao";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c0_pins1: i2c0-pins1 {
+					mux {
+						groups = "i2c0_sda_t",
+							"i2c0_sck_t";
+						function = "i2c0";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c0_pins2: i2c0-pins2 {
+					mux {
+						groups = "i2c0_sda_h",
+							"i2c0_sck_h";
+						function = "i2c0";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c1_pins1: i2c1-pins1 {
+					mux {
+						groups = "i2c1_sda",
+							"i2c1_sck";
+						function = "i2c1";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c2_pins1: i2c2-pins1 {
+					mux {
+						groups = "i2c2_sda_x",
+							"i2c2_sck_x";
+						function = "i2c2";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c2_pins2: i2c2-pins2 {
+					mux {
+						groups = "i2c2_sda_t",
+							"i2c2_sck_t";
+						function = "i2c2";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c2_pins3: i2c2-pins3 {
+					mux {
+						groups = "i2c2_sda_m",
+							"i2c2_sck_m";
+						function = "i2c2";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c3_pins1: i2c3-pins1 {
+					mux {
+						groups = "i2c3_sda_m",
+							"i2c3_sck_m";
+						function = "i2c3";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c3_pins2: i2c3-pins2 {
+					mux {
+						groups = "i2c3_sda_h",
+							"i2c3_sck_h";
+						function = "i2c3";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c4_pins1: i2c4-pins1 {
+					mux {
+						groups = "i2c4_sda_y",
+							"i2c4_sck_y";
+						function = "i2c4";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c4_pins2: i2c4-pins2 {
+					mux {
+						groups = "i2c4_sda_h",
+							"i2c4_sck_h";
+						function = "i2c4";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				i2c5_pins1: i2c5-pins1 {
+					mux {
+						groups = "i2c5_sda",
+							"i2c5_sck";
+						function = "i2c5";
+						drive-strength-microamp = <3000>;
+						bias-disable;
+					};
+				};
+
+				spicc0_pins: spicc0-pins {
+					mux {
+						groups = "spi0_mosi",
+							 "spi0_miso",
+							 "spi0_sclk";
+						function = "spi0";
+						drive-strength-microamp = <2000>;
+					};
+				};
+
+				spicc1_pins1: spicc1-pins1 {
+					mux {
+						groups = "spi1_mosi_c",
+							 "spi1_miso_c",
+							 "spi1_sclk_c";
+						function = "spi1";
+						drive-strength-microamp = <2000>;
+					};
+				};
+
+				spicc1_pins2: spicc1-pins2 {
+					mux {
+						groups = "spi1_mosi_m",
+							 "spi1_miso_m",
+							 "spi1_sclk_m";
+						function = "spi1";
+						drive-strength-microamp = <2000>;
+					};
+				};
+
+				spicc2_pins: spicc2-pins {
+					mux {
+						groups = "spi2_mosi",
+							 "spi2_miso",
+							 "spi2_sclk";
+						function = "spi2";
+						drive-strength-microamp = <2000>;
+					};
+				};
+
+				spicc3_pins: spicc3-pins {
+					mux {
+						groups = "spi3_mosi",
+							 "spi3_miso",
+							 "spi3_sclk";
+						function = "spi3";
+						drive-strength-microamp = <2000>;
+					};
+				};
+
+				spicc4_pins: spicc4-pins {
+					mux {
+						groups = "spi4_mosi",
+							 "spi4_miso",
+							 "spi4_sclk";
+						function = "spi4";
+						drive-strength-microamp = <2000>;
+					};
+				};
+
+				spicc5_pins: spicc5-pins {
+					mux {
+						groups = "spi5_mosi",
+							 "spi5_miso",
+							 "spi5_sclk";
+						function = "spi5";
+						drive-strength-microamp = <2000>;
+					};
+				};
+
 				pwm_a_pins: pwm-a {
 					mux {
 						groups = "pwm_a";
@@ -622,6 +848,41 @@ uart_a: serial@78000 {
 				status = "disabled";
 			};
 
+			uart_b: serial@7a000 {
+				compatible = "amlogic,t7-uart", "amlogic,meson-s4-uart";
+				reg = <0x0 0x7a000 0x0 0x18>;
+				interrupts = <GIC_SPI 169 IRQ_TYPE_EDGE_RISING>;
+				status = "disabled";
+			};
+
+			uart_c: serial@7c000 {
+				compatible = "amlogic,t7-uart", "amlogic,meson-s4-uart";
+				reg = <0x0 0x7c000 0x0 0x18>;
+				interrupts = <GIC_SPI 170 IRQ_TYPE_EDGE_RISING>;
+				status = "disabled";
+			};
+
+			uart_d: serial@7e000 {
+				compatible = "amlogic,t7-uart", "amlogic,meson-s4-uart";
+				reg = <0x0 0x7e000 0x0 0x18>;
+				interrupts = <GIC_SPI 171 IRQ_TYPE_EDGE_RISING>;
+				status = "disabled";
+			};
+
+			uart_e: serial@80000 {
+				compatible = "amlogic,t7-uart", "amlogic,meson-s4-uart";
+				reg = <0x0 0x80000 0x0 0x18>;
+				interrupts = <GIC_SPI 172 IRQ_TYPE_EDGE_RISING>;
+				status = "disabled";
+			};
+
+			uart_f: serial@82000 {
+				compatible = "amlogic,t7-uart", "amlogic,meson-s4-uart";
+				reg = <0x0 0x82000 0x0 0x18>;
+				interrupts = <GIC_SPI 173 IRQ_TYPE_EDGE_RISING>;
+				status = "disabled";
+			};
+
 			gp0: clock-controller@8080 {
 				compatible = "amlogic,t7-gp0-pll";
 				reg = <0x0 0x8080 0x0 0x20>;
@@ -688,6 +949,39 @@ sec_ao: ao-secure@10220 {
 				amlogic,has-chip-id;
 			};
 
+			eth_phy: mdio-multiplexer@28000 {
+				compatible = "amlogic,g12a-mdio-mux";
+				reg = <0x0 0x28000 0x0 0xa4>;
+
+				clocks = <&clkc_periphs CLKID_SYS_ETHPHY>,
+					 <&xtal>,
+					 <&scmi_clk CLKID_FCLK_50M>;
+				clock-names = "pclk", "clkin0", "clkin1";
+				mdio-parent-bus = <&mdio0>;
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				ext_mdio: mdio@0 {
+					reg = <0>;
+					#address-cells = <1>;
+					#size-cells = <0>;
+				};
+
+				int_mdio: mdio@1 {
+					reg = <1>;
+					#address-cells = <1>;
+					#size-cells = <0>;
+
+					internal_ephy: ethernet_phy@8 {
+						compatible = "ethernet-phy-id0180.3301",
+							     "ethernet-phy-ieee802.3-c22";
+						interrupts = <GIC_SPI 340 IRQ_TYPE_LEVEL_HIGH>;
+						reg = <8>;
+						max-speed = <100>;
+					};
+				};
+			};
+
 			pwm_ao_ef: pwm@30000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x30000 0x0 0x24>;
@@ -711,6 +1005,84 @@ clock-measurer@48000 {
 				reg = <0x0 0x48000 0x0 0x1c>;
 			};
 
+			spicc3: spi@4a000 {
+				compatible = "amlogic,t7-spicc", "amlogic,meson-g12a-spicc";
+				reg = <0x0 0x4a000 0x0 0x44>;
+				power-domains = <&pwrc PWRC_T7_SPICC3_ID>;
+				interrupts = <GIC_SPI 189 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_SPICC3>,
+					 <&clkc_periphs CLKID_SPICC3>;
+				clock-names = "core", "pclk";
+				#address-cells = <1>;
+				#size-cells = <0>;
+				status = "disabled";
+			};
+
+			spicc4: spi@4c000 {
+				compatible = "amlogic,t7-spicc", "amlogic,meson-g12a-spicc";
+				reg = <0x0 0x4c000 0x0 0x44>;
+				power-domains = <&pwrc PWRC_T7_SPICC4_ID>;
+				interrupts = <GIC_SPI 190 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_SPICC4>,
+					 <&clkc_periphs CLKID_SPICC4>;
+				clock-names = "core", "pclk";
+				#address-cells = <1>;
+				#size-cells = <0>;
+				status = "disabled";
+			};
+
+			spicc5: spi@4e000 {
+				compatible = "amlogic,t7-spicc", "amlogic,meson-g12a-spicc";
+				reg = <0x0 0x4e000 0x0 0x44>;
+				power-domains = <&pwrc PWRC_T7_SPICC5_ID>;
+				interrupts = <GIC_SPI 191 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_SPICC5>,
+					 <&clkc_periphs CLKID_SPICC5>;
+				clock-names = "core", "pclk";
+				#address-cells = <1>;
+				#size-cells = <0>;
+				status = "disabled";
+			};
+
+			spicc0: spi@50000 {
+				compatible = "amlogic,t7-spicc", "amlogic,meson-g12a-spicc";
+				reg = <0x0 0x50000 0x0 0x44>;
+				power-domains = <&pwrc PWRC_T7_SPICC0_ID>;
+				interrupts = <GIC_SPI 183 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_SPICC0>,
+					 <&clkc_periphs CLKID_SPICC0>;
+				clock-names = "core", "pclk";
+				#address-cells = <1>;
+				#size-cells = <0>;
+				status = "disabled";
+			};
+
+			spicc1: spi@52000 {
+				compatible = "amlogic,t7-spicc", "amlogic,meson-g12a-spicc";
+				reg = <0x0 0x52000 0x0 0x44>;
+				power-domains = <&pwrc PWRC_T7_SPICC1_ID>;
+				interrupts = <GIC_SPI 184 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_SPICC1>,
+					 <&clkc_periphs CLKID_SPICC1>;
+				clock-names = "core", "pclk";
+				#address-cells = <1>;
+				#size-cells = <0>;
+				status = "disabled";
+			};
+
+			spicc2: spi@54000 {
+				compatible = "amlogic,t7-spicc", "amlogic,meson-g12a-spicc";
+				reg = <0x0 0x54000 0x0 0x44>;
+				power-domains = <&pwrc PWRC_T7_SPICC2_ID>;
+				interrupts = <GIC_SPI 167 IRQ_TYPE_LEVEL_HIGH>;
+				clocks = <&clkc_periphs CLKID_SYS_SPICC2>,
+					 <&clkc_periphs CLKID_SPICC2>;
+				clock-names = "core", "pclk";
+				#address-cells = <1>;
+				#size-cells = <0>;
+				status = "disabled";
+			};
+
 			pwm_ab: pwm@58000 {
 				compatible = "amlogic,t7-pwm", "amlogic,meson-s4-pwm";
 				reg = <0x0 0x58000 0x0 0x24>;
@@ -756,6 +1128,86 @@ pwm_ao_cd: pwm@60000 {
 				status = "disabled";
 			};
 
+			i2c0: i2c@66000 {
+				compatible = "amlogic,t7-i2c", "amlogic,meson-axg-i2c";
+				reg = <0x0 0x66000 0x0 0x48>;
+				interrupts = <GIC_SPI 160 IRQ_TYPE_EDGE_RISING>;
+				#address-cells = <1>;
+				#size-cells = <0>;
+				clocks = <&clkc_periphs CLKID_SYS_I2C_M_A>;
+				status = "disabled";
+			};
+
+			i2c1: i2c@68000 {
+				compatible = "amlogic,t7-i2c", "amlogic,meson-axg-i2c";
+				reg = <0x0 0x68000 0x0 0x48>;
+				interrupts = <GIC_SPI 161 IRQ_TYPE_EDGE_RISING>;
+				#address-cells = <1>;
+				#size-cells = <0>;
+				clocks = <&clkc_periphs CLKID_SYS_I2C_M_B>;
+				status = "disabled";
+			};
+
+			i2c2: i2c@6a000 {
+				compatible = "amlogic,t7-i2c", "amlogic,meson-axg-i2c";
+				reg = <0x0 0x6a000 0x0 0x48>;
+				interrupts = <GIC_SPI 162 IRQ_TYPE_EDGE_RISING>;
+				#address-cells = <1>;
+				#size-cells = <0>;
+				clocks = <&clkc_periphs CLKID_SYS_I2C_M_C>;
+				status = "okay";
+			};
+
+			i2c3: i2c@6c000 {
+				compatible = "amlogic,t7-i2c", "amlogic,meson-axg-i2c";
+				reg = <0x0 0x6c000 0x0 0x48>;
+				interrupts = <GIC_SPI 163 IRQ_TYPE_EDGE_RISING>;
+				#address-cells = <1>;
+				#size-cells = <0>;
+				clocks = <&clkc_periphs CLKID_SYS_I2C_M_D>;
+				status = "disabled";
+			};
+
+			i2c4: i2c@6e000 {
+				compatible = "amlogic,t7-i2c", "amlogic,meson-axg-i2c";
+				reg = <0x0 0x6e000 0x0 0x48>;
+				interrupts = <GIC_SPI 164 IRQ_TYPE_EDGE_RISING>;
+				#address-cells = <1>;
+				#size-cells = <0>;
+				clocks = <&clkc_periphs CLKID_SYS_I2C_M_E>;
+				status = "disabled";
+			};
+
+			i2c5: i2c@70000 {
+				compatible = "amlogic,t7-i2c", "amlogic,meson-axg-i2c";
+				reg = <0x0 0x070000 0x0 0x48>;
+				interrupts = <GIC_SPI 165 IRQ_TYPE_EDGE_RISING>;
+				#address-cells = <1>;
+				#size-cells = <0>;
+				clocks = <&clkc_periphs CLKID_SYS_I2C_M_F>;
+				status = "disabled";
+			};
+
+			i2c_ao_a: i2c@76000 {
+				compatible = "amlogic,t7-i2c", "amlogic,meson-axg-i2c";
+				reg = <0x0 0x076000 0x0 0x48>;
+				interrupts = <GIC_SPI 330 IRQ_TYPE_EDGE_RISING>;
+				#address-cells = <1>;
+				#size-cells = <0>;
+				clocks = <&clkc_periphs CLKID_SYS_I2C_AO_A>;
+				status = "disabled";
+			};
+
+			i2c_ao_b: i2c@86000 {
+				compatible = "amlogic,t7-i2c", "amlogic,meson-axg-i2c";
+				reg = <0x0 0x086000 0x0 0x48>;
+				interrupts = <GIC_SPI 331 IRQ_TYPE_EDGE_RISING>;
+				#address-cells = <1>;
+				#size-cells = <0>;
+				clocks = <&clkc_periphs CLKID_SYS_I2C_AO_B>;
+				status = "disabled";
+			};
+
 			sd_emmc_a: mmc@88000 {
 				compatible = "amlogic,t7-mmc", "amlogic,meson-axg-mmc";
 				reg = <0x0 0x88000 0x0 0x800>;

-- 
2.52.0

