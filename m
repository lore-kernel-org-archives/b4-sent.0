From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:57 +0100
Subject: [PATCH 16/19] powerpc: dts: Add LANCOM NWAPP2 board devicetree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-16-86f78ba2a7af@posteo.net>
References: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
In-Reply-To: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Frank Li <Frank.Li@nxp.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=8029;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=ZKOoalO4wmhQEAwxw29HUheREeAXcDDs75lwK/wrODY=;
 b=+jeoW7i1ak3Bn5aA7D719CI2NoS8bUwteML/RwSvhKc9oJRv2rTcoj8oRl6e/El4TejDwyZd0
 rsXEKhiclnkCyPOhl1JFSi470/dXtl3IfQvBXXd5q5jqAFcPzaoAlvI
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

What works so far:
- serial port
- LEDs
- Ethernet
- PCIe (port 1 tested)
- Flash access

What doesn't work:
- Access of the YAFFS file system preinstalled by the original firmware
  (mainline Linux does not include the YAFFS file system)
- Writing NAND flash from Linux and reading the same from U-Boot
  (there is some issue related to ECC)

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

Note: This patch requires the following patchset as it defines bindings
used in lancom-nwapp2.dts:

  [PATCH v2 0/3] gpio: 74HC595 / 74x164 shift register improvements
---
 arch/powerpc/boot/dts/Makefile          |   1 +
 arch/powerpc/boot/dts/lancom-nwapp2.dts | 276 ++++++++++++++++++++++++++++++++
 2 files changed, 277 insertions(+)

diff --git a/arch/powerpc/boot/dts/Makefile b/arch/powerpc/boot/dts/Makefile
index 6aee895d5baaa2c978d4b1c82a6d198d9e166ea2..43e20d8b776b1716a91e6ec8e135c0a45c8e8c77 100644
--- a/arch/powerpc/boot/dts/Makefile
+++ b/arch/powerpc/boot/dts/Makefile
@@ -6,5 +6,6 @@ dtb-$(CONFIG_OF_ALL_DTBS) := $(patsubst $(src)/%.dts,%.dtb, $(wildcard $(src)/*.
 
 dtb-$(CONFIG_MPC831x) += \
 	kmeter1.dtb \
+	lancom-nwapp2.dtb \
 	mpc8313erdb.dtb \
 	mpc8315erdb.dtb
diff --git a/arch/powerpc/boot/dts/lancom-nwapp2.dts b/arch/powerpc/boot/dts/lancom-nwapp2.dts
new file mode 100644
index 0000000000000000000000000000000000000000..d46d94c27ecb91db32c8acb4136cb6e8d0df52f5
--- /dev/null
+++ b/arch/powerpc/boot/dts/lancom-nwapp2.dts
@@ -0,0 +1,276 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+// Copyright 2024 J. Neuschäfer
+//
+// LANCOM NWAPP2, marketed as:
+// - LANCOM L-321agn Wireless (R2)
+// - LANCOM L-322agn dual Wireless (R2)
+// - LANCOM L-322E Wireless
+#include "mpc8314e.dtsi"
+
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/leds/common.h>
+#include <dt-bindings/input/input.h>
+
+/ {
+	compatible = "lancom,nwapp2", "fsl,mpc8314e";
+	model = "LANCOM NWAPP2";
+
+	memory {
+		reg = <0x00000000 0x08000000>;	// 128MB at 0
+	};
+
+	aliases {
+		serial0 = &serial0;
+		pci1 = &pci1;
+		pci2 = &pci2;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+
+	gpio-watchdog {
+		compatible = "linux,wdt-gpio";
+		gpios = <&gpio 18 GPIO_ACTIVE_LOW>;
+		hw_algo = "toggle";
+		hw_margin_ms = <1000>;
+		always-running;
+	};
+
+	gpio-restart {
+		compatible = "gpio-restart";
+		gpios = <&gpio 10 GPIO_ACTIVE_HIGH>;
+	};
+
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		reset-button {
+			label = "Reset Button";
+			linux,code = <KEY_SETUP>;
+			gpios = <&gpio 1 GPIO_ACTIVE_LOW>;
+		};
+	};
+
+	gpio-leds {
+		compatible = "gpio-leds";
+
+		led_power_red: led-0 {
+			label = "red:power";
+			gpios = <&expander 0 GPIO_ACTIVE_HIGH>;
+			color = <LED_COLOR_ID_RED>;
+		};
+
+		led_power_green: led-1 {
+			label = "green:power";
+			gpios = <&expander 1 GPIO_ACTIVE_HIGH>;
+			color = <LED_COLOR_ID_GREEN>;
+		};
+
+		led_wlan_link_red: led-2 {
+			label = "red:wlan-link";
+			gpios = <&expander 2 GPIO_ACTIVE_LOW>;
+			color = <LED_COLOR_ID_RED>;
+		};
+
+		led_wlan_link_green: led-3 {
+			label = "green:wlan-link";
+			gpios = <&expander 3 GPIO_ACTIVE_LOW>;
+			color = <LED_COLOR_ID_GREEN>;
+		};
+
+		led_wlan_data_red: led-4 {
+			label = "red:wlan-data";
+			gpios = <&expander 4 GPIO_ACTIVE_HIGH>;
+			color = <LED_COLOR_ID_RED>;
+		};
+
+		led_eth_red: led-10 {
+			label = "red:eth";
+			gpios = <&expander 10 GPIO_ACTIVE_HIGH>;
+			color = <LED_COLOR_ID_RED>;
+		};
+
+		led_power_top_red: led-12 {
+			label = "red:power-top";
+			gpios = <&expander 12 GPIO_ACTIVE_LOW>;
+			color = <LED_COLOR_ID_RED>;
+		};
+
+		led_power_top_green: led-13 {
+			label = "green:power-top";
+			gpios = <&expander 13 GPIO_ACTIVE_LOW>;
+			color = <LED_COLOR_ID_GREEN>;
+		};
+
+		led_wlan_top_red: led-14 {
+			label = "red:wlan-top";
+			gpios = <&expander 14 GPIO_ACTIVE_LOW>;
+			color = <LED_COLOR_ID_RED>;
+		};
+
+		led_wlan_top_green: led-15 {
+			label = "green:wlan-top";
+			gpios = <&expander 15 GPIO_ACTIVE_LOW>;
+			color = <LED_COLOR_ID_GREEN>;
+		};
+	};
+
+	led-power {
+		label = "multicolor:power";
+		compatible = "leds-group-multicolor";
+		color = <LED_COLOR_ID_MULTI>;
+		function = LED_FUNCTION_POWER;
+		leds = <&led_power_red>, <&led_power_green>;
+	};
+
+	led-wlan-link {
+		label = "multicolor:wlan-link";
+		compatible = "leds-group-multicolor";
+		color = <LED_COLOR_ID_MULTI>;
+		function = LED_FUNCTION_WLAN;
+		leds = <&led_wlan_link_red>, <&led_wlan_link_green>;
+	};
+
+	led-wlan-data {
+		label = "multicolor:wlan-data";
+		compatible = "leds-group-multicolor";
+		color = <LED_COLOR_ID_MULTI>;
+		leds = <&led_wlan_data_red>;
+	};
+
+	led-eth {
+		label = "multicolor:eth";
+		compatible = "leds-group-multicolor";
+		color = <LED_COLOR_ID_MULTI>;
+		leds = <&led_eth_red>;
+	};
+
+	led-power-top {
+		label = "multicolor:power-top";
+		compatible = "leds-group-multicolor";
+		color = <LED_COLOR_ID_MULTI>;
+		function = LED_FUNCTION_POWER;
+		leds = <&led_power_top_red>, <&led_power_top_green>;
+	};
+
+	led-wlan-top {
+		label = "multicolor:wlan-top";
+		compatible = "leds-group-multicolor";
+		color = <LED_COLOR_ID_MULTI>;
+		leds = <&led_wlan_top_red>, <&led_wlan_top_green>;
+	};
+};
+
+&gpio {
+	gpio-line-names =
+		/*  0 -  7 */ "DEBUG#", "RESET_BTN#", "", "EXP_LATCH", "", "", "", "PCIE_RST#",
+		/*  8 - 15 */ "", "", "BOARD_RST", "", "", "", "", "",
+		/* 16 - 23 */ "", "", "WDT_TOGGLE", "", "", "", "PHY_RST#", "",
+		/* 24 - 31 */ "", "", "", "", "", "", "", "";
+};
+
+&localbus {
+	status = "okay";
+	ranges = <0x0 0x0 0xfe000000 0x00008000>;
+
+	nand@0,0 {
+		#address-cells = <1>;
+		#size-cells = <1>;
+		compatible = "fsl,mpc8315-fcm-nand",
+			     "fsl,elbc-fcm-nand";
+		reg = <0x0 0x0 0x2000>;
+
+		partitions {
+			compatible = "fixed-partitions";
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			partition@0 {
+				label = "loader1";
+				reg = <0x0 0x8000>;
+				read-only;
+			};
+
+			partition@8000 {
+				label = "loader2";
+				reg = <0x8000 0x78000>;
+				read-only;
+			};
+
+			// 0x80000:0xf80000 is designated "loader spare" by
+			// vendor firmware, but we re-use it for our purposes.
+
+			partition@80000 {
+				label = "u-boot-env";
+				reg = <0x80000 0x80000>;
+			};
+
+			partition@100000 {
+				label = "loader-spare";
+				reg = <0x100000 0xf00000>;
+			};
+
+			partition@1000000 {
+				label = "fs";
+				reg = <0x1000000 0xf000000>;
+				/* YAFFS2 filesystem */
+			};
+		};
+	};
+};
+
+&enet0 {
+	status = "okay";
+	phy-handle = <&phy>;
+	phy-mode = "rgmii-id";
+};
+
+&mdio0 {
+	status = "okay";
+	compatible = "fsl,gianfar-mdio";
+
+	phy: ethernet-phy@1 {
+		/* Atheros AR8032 */
+		reg = <1>;
+		compatible = "ethernet-phy-ieee802.3-c22";
+		reset-gpios = <&gpio 22 GPIO_ACTIVE_LOW>;
+	};
+};
+
+&pci1 {
+	status = "okay";
+	ranges = <0x02000000 0 0x88000000 0x88000000 0 0x02000000>,
+		 <0x01000000 0 0x00000000 0xc9080000 0 0x00800000>;
+};
+
+&pci2 {
+	status = "okay";
+	ranges = <0x02000000 0 0x88000000 0x8c000000 0 0x02000000>,
+		 <0x01000000 0 0x00000000 0xc9900000 0 0x00800000>;
+};
+
+&serial0 {
+	status = "okay";
+};
+
+&spi {
+	status = "okay";
+	/*
+	 * The GPIO expander doesn't really use a chip select.
+	 * Instead pin 3 is connected to the latch clock input, which triggers
+	 * the transfer of bits from the shift register to the output pins on
+	 * rising edges. Specifying it as a active-low chip select works
+	 * because the CS# is driven high after the serial transfer is done.
+	 */
+	cs-gpios = <&gpio 3 GPIO_ACTIVE_LOW>;
+
+	expander: gpio-controller@0 {
+		reg = <0>;
+		compatible = "onnn,74hc595a";
+		spi-max-frequency = <5000000>;
+		gpio-controller;
+		#gpio-cells = <2>;
+		registers-number = <2>;
+	};
+};

-- 
2.45.2

