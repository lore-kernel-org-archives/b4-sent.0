From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Fri, 27 Nov 2026 23:59:30 +0300
Subject: [PATCH 2/3] ARM: dts: cortina: Enable Almond+ board peripherals
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-cs7542-peripherals-dts-v1-2-7ce24b842b3a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795813168; l=7952;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=Y8k2l9d3K1ZNV+7EeNdj9panZNgi90qabzAGt3bSRUM=;
 b=+0wn17TnKYyjVICowJreU1ia/zJewc3XUNg3aC0Q65dL7GMy9LROQqzW8CpltnmguyGwBq7QJ
 kHaoMpKilNkDe8BF69fszEIdkTDPjO9kOlV3Esq16W7n5OikU9PERnb
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the tested NAND geometry and stock-compatible partition layout,
factory MAC/calibration cells, QCA8337 switch wiring, PCIe radios and
xHCI endpoint, touchscreen and auxiliary UARTs. Select GPIO37 and
UART72-77 mux states and the shared PCIe reset GPIO92.

Connect the network engine to its reserved upper 64 MiB DDR region and
keep a separate ramoops reservation. Preserve the stock bootloader
console compatibility and describe the actual port labels. GPIO92 resets
both Wi-Fi endpoints, so runtime PCIe hotplug is not advertised.

The equivalent OpenWrt device tree has been booted on Almond+ with the
new PIO NAND, MDIO, PCIe and Ethernet drivers, with factory
MAC/calibration reads, Wi-Fi, USB, UDP/ICMP and jumbo/SG traffic.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../dts/cortina/cs7542-securifi-almondplus.dts     | 342 ++++++++++++++++++++-
 1 file changed, 339 insertions(+), 3 deletions(-)

diff --git a/arch/arm/boot/dts/cortina/cs7542-securifi-almondplus.dts b/arch/arm/boot/dts/cortina/cs7542-securifi-almondplus.dts
index e3152fd1d..32bab3f0b 100644
--- a/arch/arm/boot/dts/cortina/cs7542-securifi-almondplus.dts
+++ b/arch/arm/boot/dts/cortina/cs7542-securifi-almondplus.dts
@@ -5,6 +5,10 @@
 
 /dts-v1/;
 
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/input/input.h>
+#include <dt-bindings/interrupt-controller/irq.h>
+
 #include "cs7542.dtsi"
 
 / {
@@ -13,12 +17,26 @@
 
 	aliases {
 		serial0 = &uart0;
+		serial1 = &uart1;
+		serial2 = &uart2;
+		serial3 = &uart3;
 	};
 
 	chosen {
+		bootargs = "console=ttyCS0,115200";
 		stdout-path = "serial0:115200n8";
 	};
 
+	keys {
+		compatible = "gpio-keys";
+
+		button-reset {
+			label = "reset";
+			gpios = <&gpio1 5 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_RESTART>;
+		};
+	};
+
 	memory@0 {
 		device_type = "memory";
 		reg = <0x00000000 0x20000000>;
@@ -29,18 +47,336 @@
 		#address-cells = <1>;
 		#size-cells = <1>;
 
+		ramoops@1bf00000 {
+			compatible = "ramoops";
+			reg = <0x1bf00000 0x100000>;
+			record-size = <0x20000>;
+			console-size = <0x80000>;
+			ecc-size = <16>;
+			no-map;
+		};
+
 		/* Reserved for the packet engine queue manager */
-		qm-buffer@1c000000 {
+		qm_reserved: qm-buffer@1c000000 {
 			reg = <0x1c000000 0x4000000>;
 			no-map;
 		};
 	};
 };
 
-&apb_clk {
-	clock-frequency = <150000000>;
+&pinctrl {
+	pinctrl-names = "default";
+	pinctrl-0 = <&reset_pins &aux_uarts_pins>;
+
+	reset_pins: reset-pins {
+		function = "gpio";
+		pins = "gpio37";
+	};
+
+	aux_uarts_pins: aux-uarts-pins {
+		function = "uart";
+		pins = "gpio72", "gpio73", "gpio74", "gpio75", "gpio76", "gpio77";
+	};
+};
+
+&i2c {
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	touchscreen@48 {
+		compatible = "semtech,sx8650";
+		reg = <0x48>;
+		interrupt-parent = <&gpio4>;
+		interrupts = <28 IRQ_TYPE_LEVEL_LOW>;
+	};
 };
 
 &uart0 {
 	status = "okay";
 };
+
+&uart1 {
+	status = "okay";
+};
+
+&uart2 {
+	status = "okay";
+};
+
+&uart3 {
+	status = "okay";
+};
+
+&rtc0 {
+	status = "okay";
+};
+
+&trng {
+	status = "okay";
+};
+
+&nandc {
+	status = "okay";
+	nand@0 {
+		reg = <0>;
+		nand-ecc-mode = "hw";
+		nand-ecc-step-size = <256>;
+		nand-ecc-strength = <1>;
+
+		partitions {
+			compatible = "fixed-partitions";
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			partition@20000 {
+				label = "uboot0";
+				reg = <0x0020000 0x00e0000>;
+				read-only;
+			};
+
+			partition@100000 {
+				label = "uboot-env0";
+				reg = <0x0100000 0x0020000>;
+				read-only;
+
+				nvmem-layout {
+					compatible = "u-boot,env";
+
+					ethaddr: ethaddr {
+						#nvmem-cell-cells = <1>;
+					};
+				};
+			};
+
+			partition@200000 {
+				label = "uboot1";
+				reg = <0x0200000 0x0100000>;
+				read-only;
+			};
+
+			partition@300000 {
+				label = "uboot-env1";
+				reg = <0x0300000 0x0100000>;
+			};
+
+			partition@400000 {
+				label = "sb0";
+				reg = <0x0400000 0x0100000>;
+			};
+
+			partition@500000 {
+				label = "sb1";
+				reg = <0x0500000 0x0100000>;
+			};
+
+			partition@600000 {
+				label = "kernel_standby";
+				reg = <0x0600000 0x0600000>;
+			};
+
+			partition@c00000 {
+				label = "rootfs_standby";
+				reg = <0x0c00000 0x2e00000>;
+			};
+
+			partition@3a00000 {
+				label = "kernel";
+				reg = <0x3a00000 0x0600000>;
+			};
+
+			partition@4000000 {
+				label = "rootfs_stock";
+				reg = <0x4000000 0x2e00000>;
+			};
+
+			partition@6e00000 {
+				label = "stock_data";
+				reg = <0x6e00000 0x1000000>;
+			};
+
+			partition@7e00000 {
+				label = "log";
+				reg = <0x7e00000 0x0100000>;
+			};
+
+			partition@7f00000 {
+				label = "cal";
+				reg = <0x7f00000 0x0100000>;
+				read-only;
+
+				nvmem-layout {
+					compatible = "fixed-layout";
+					#address-cells = <1>;
+					#size-cells = <1>;
+
+					macaddr_ath9k: macaddr@1002 {
+						reg = <0x1002 0x6>;
+					};
+
+					cal_ath9k: cal@1000 {
+						reg = <0x1000 0x440>;
+					};
+
+					cal_ath10k: cal@5000 {
+						reg = <0x5000 0x844>;
+					};
+				};
+			};
+
+			partition@8000000 {
+				label = "man";
+				reg = <0x8000000 0x0100000>;
+				read-only;
+			};
+
+			partition@8100000 {
+				label = "almond_data";
+				reg = <0x8100000 0x0500000>;
+			};
+
+			partition@8600000 {
+				label = "ubi";
+				reg = <0x8600000 0x17a00000>;
+			};
+		};
+	};
+};
+
+&pcie0 {
+	status = "okay";
+	pinctrl-names = "default";
+	pinctrl-0 = <&pcie0_reset_pins>;
+};
+
+&pcie0_port {
+	/* GPIO92 resets both Wi-Fi endpoints; only this port owns it. */
+	reset-gpios = <&gpio2 28 GPIO_ACTIVE_LOW>;
+
+	wifi@0,0 {
+		compatible = "pci168c,003c";
+		reg = <0 0 0 0 0>;
+		nvmem-cells = <&cal_ath10k>;
+		nvmem-cell-names = "calibration";
+	};
+};
+
+&pcie1 {
+	status = "okay";
+};
+
+&pcie1_port {
+	wifi@0,0 {
+		compatible = "pci168c,0033";
+		reg = <0 0 0 0 0>;
+		nvmem-cells = <&macaddr_ath9k>, <&cal_ath9k>;
+		nvmem-cell-names = "mac-address", "calibration";
+	};
+};
+
+&pcie2 {
+	status = "okay";
+};
+
+&mdio0 {
+	status = "okay";
+
+	switch@10 {
+		compatible = "qca,qca8337";
+		reg = <0x10>;
+
+		ports {
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			port@0 {
+				reg = <0>;
+				label = "cpu";
+				ethernet = <&gmac1>;
+				phy-mode = "rgmii-id";
+
+				fixed-link {
+					speed = <1000>;
+					full-duplex;
+				};
+			};
+
+			port@1 {
+				reg = <1>;
+				label = "wan";
+				nvmem-cells = <&ethaddr 0>;
+				nvmem-cell-names = "mac-address";
+			};
+
+			port@2 {
+				reg = <2>;
+				label = "lan4";
+			};
+
+			port@3 {
+				reg = <3>;
+				label = "lan3";
+			};
+
+			port@4 {
+				reg = <4>;
+				label = "lan2";
+			};
+
+			port@5 {
+				reg = <5>;
+				label = "lan1";
+			};
+
+			port@6 {
+				reg = <6>;
+				label = "cpu";
+				ethernet = <&gmac0>;
+				phy-mode = "rgmii-id";
+
+				fixed-link {
+					speed = <1000>;
+					full-duplex;
+				};
+			};
+		};
+	};
+};
+
+&ethernet {
+	memory-region = <&qm_reserved>;
+	status = "okay";
+};
+
+&gmac0 {
+	status = "okay";
+	/* The QCA8337 CPU port supplies the internal RX and TX delays. */
+	phy-mode = "rgmii-id";
+	nvmem-cells = <&ethaddr 0>;
+	nvmem-cell-names = "mac-address";
+
+	fixed-link {
+		speed = <1000>;
+		full-duplex;
+	};
+};
+
+&gmac1 {
+	status = "okay";
+	/* The QCA8337 CPU port supplies the internal RX and TX delays. */
+	phy-mode = "rgmii-id";
+	nvmem-cells = <&ethaddr (-1)>;
+	nvmem-cell-names = "mac-address";
+
+	fixed-link {
+		speed = <1000>;
+		full-duplex;
+	};
+};
+
+&pinctrl {
+	pcie0_reset_pins: pcie0-reset-pins {
+		function = "gpio";
+		pins = "gpio92";
+	};
+};

-- 
2.53.0

