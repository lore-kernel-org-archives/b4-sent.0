From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Fri, 20 Nov 2026 01:22:16 -0600
Subject: [PATCH 4/4] arm64: dts: allwinner: a133: Add KickPi K5C
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-k5c-dt-v1-v1-4-d9681df67bc0@gmail.com>
References: <20261120-k5c-dt-v1-v1-0-d9681df67bc0@gmail.com>
In-Reply-To: <20261120-k5c-dt-v1-v1-0-d9681df67bc0@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Andre Przywara <andre.przywara@arm.com>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795159332; l=8414;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=cOXdIbM/pxnMp4m5in4E4b9UGDrGObP7s7gq1j9qWLU=;
 b=6ZlAFSKWhIIcH7bpVonXOW+g8iBc9q5PAmvbUt9xL5XN1on7IvKciJ3/UWFZaVxInuruQvOnP
 L5ZAbW7TBb5B1+WZ8CLvrth0ceqVsR1/AhCVkS8KJVhgYJ3ed1UHAF7
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The KickPi K5C is a single board computer with an Allwinner A133 SoC.
Mainline Linux has no support for it yet; its factory firmware runs a
vendor Linux 4.9 kernel. Add a device tree for PCB version V1.3, which
has:
- 2 GB DDR3 DRAM, 8-bit eMMC (HS200) and a micro SD card slot
- an X-Powers AXP707 PMIC, which drives VDD-CPU from DCDC2 and DCDC3
  in dual phase mode
- a HYM8563 RTC on I2C3 (PH12/PH13)
- power input through a 12 V DC jack or the USB-C port (5 V)
- two USB-A ports behind an on-board USB hub on USB1, whose power
  switch is enabled by PL8
- a blue status LED on PL10
- the debug UART on PB9/PB10

The regulator assignment and the pins come from the board schematic
(V1.3) and were checked against the vendor's device tree and on the
board. The pin bank supplies are the same as on the Baijie HelperBoard
A133. All tests were done with the board powered through the USB-C
port.

Mainline has no binding for the AXP707. Its chip ID register reads 0x51,
which U-Boot's AXP803 code accepts, it works with the AXP803 driver, and
the vendor device tree also describes it as an AXP803, so the PMIC node
uses the AXP803 compatible.

Not described yet:
- Ethernet: the board has a Maxio MAE0621A PHY, which needs a driver
  that is not in mainline yet
- the Wi-Fi/BT module (VS6621S40, Seekwave SWT6621S) on MMC1: there is
  no mainline driver for it, and in my tests its SDIO card did not come
  up after a cold boot, so the slot is left out until that is understood
- USB data on the USB-C port (USB0): the vendor's firmware uses it as
  a peripheral port, but I could not test that yet
- the RTC alarm interrupt on PB8: first tests pass, and it will follow
  in a separate patch after more testing
- display, camera, audio, the IR receiver, the fan header and the
  battery connector

The CPU uses the A100 OPP table, like the other A133 boards today.

Claude Code (Anthropic) drafted this device tree and its message from
the schematic, KickPi's documentation, the vendor device tree (as a
reference for values only) and my board measurements; I reviewed it
and tested it on a KickPi K5C.

Suggested-by: Andre Przywara <andre.przywara@arm.com>
Link: https://lore.kernel.org/all/d4d89cf9-884d-424b-927d-5b6692f50327@arm.com/
Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 arch/arm64/boot/dts/allwinner/Makefile             |   1 +
 .../boot/dts/allwinner/sun50i-a133-kickpi-k5c.dts  | 228 +++++++++++++++++++++
 2 files changed, 229 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/Makefile b/arch/arm64/boot/dts/allwinner/Makefile
index da39f02252d..0176de509fb 100644
--- a/arch/arm64/boot/dts/allwinner/Makefile
+++ b/arch/arm64/boot/dts/allwinner/Makefile
@@ -25,6 +25,7 @@ dtb-$(CONFIG_ARCH_SUNXI) += sun50i-a64-teres-i.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h64-remix-mini-pc.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-a100-allwinner-perf1.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-a133-helperboard.dtb
+dtb-$(CONFIG_ARCH_SUNXI) += sun50i-a133-kickpi-k5c.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-a133-liontron-h-a133l.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-a133-teclast-p80.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h5-bananapi-m2-plus.dtb
diff --git a/arch/arm64/boot/dts/allwinner/sun50i-a133-kickpi-k5c.dts b/arch/arm64/boot/dts/allwinner/sun50i-a133-kickpi-k5c.dts
new file mode 100644
index 00000000000..ce977e9edbd
--- /dev/null
+++ b/arch/arm64/boot/dts/allwinner/sun50i-a133-kickpi-k5c.dts
@@ -0,0 +1,228 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+/*
+ * Copyright (c) 2026 Rajan Yadav <rajanyadav0307@gmail.com>
+ */
+
+/dts-v1/;
+
+#include "sun50i-a100.dtsi"
+#include "sun50i-a100-cpu-opp.dtsi"
+
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/leds/common.h>
+
+/{
+	model = "KickPi K5C";
+	compatible = "kickpi,k5c", "allwinner,sun50i-a133";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+
+	leds {
+		compatible = "gpio-leds";
+
+		led {
+			function = LED_FUNCTION_STATUS;
+			color = <LED_COLOR_ID_BLUE>;
+			gpios = <&r_pio 0 10 GPIO_ACTIVE_HIGH>; /* PL10 */
+		};
+	};
+
+	reg_usb1_vbus: regulator-usb1-vbus {
+		/* USB-A port power switch, also powers the on-board USB hub */
+		compatible = "regulator-fixed";
+		enable-active-high;
+		gpio = <&r_pio 0 8 GPIO_ACTIVE_HIGH>; /* PL8 */
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+		regulator-name = "usb1-vbus";
+		vin-supply = <&reg_vcc5v>;
+	};
+
+	reg_vcc5v: regulator-vcc5v {
+		/* 5V rail, powered from the USB-C port or the 12V DC jack */
+		compatible = "regulator-fixed";
+		regulator-always-on;
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+		regulator-name = "vcc-5v";
+	};
+};
+
+&cpu0 {
+	cpu-supply = <&reg_dcdc2>;
+};
+
+&ehci1 {
+	status = "okay";
+};
+
+&i2c3 {
+	pinctrl-0 = <&i2c3_ph_pins>;
+	pinctrl-names = "default";
+
+	status = "okay";
+
+	rtc@51 {
+		compatible = "haoyu,hym8563";
+		reg = <0x51>;
+		#clock-cells = <0>;
+	};
+};
+
+&mmc0 {
+	bus-width = <4>;
+	cd-gpios = <&pio 5 6 GPIO_ACTIVE_LOW>; /* PF6 */
+	disable-wp;
+	vmmc-supply = <&reg_dcdc1>;
+
+	status = "okay";
+};
+
+&mmc2 {
+	bus-width = <8>;
+	cap-mmc-hw-reset;
+	mmc-ddr-1_8v;
+	mmc-hs200-1_8v;
+	non-removable;
+	vmmc-supply = <&reg_dcdc1>;
+	vqmmc-supply = <&reg_eldo1>;
+
+	status = "okay";
+};
+
+&ohci1 {
+	status = "okay";
+};
+
+&pio {
+	vcc-pb-supply = <&reg_dcdc1>;
+	vcc-pc-supply = <&reg_eldo1>;
+	vcc-pd-supply = <&reg_dcdc1>;
+	vcc-pe-supply = <&reg_dldo2>;
+	vcc-pf-supply = <&reg_dcdc1>;
+	vcc-pg-supply = <&reg_dldo1>;
+	vcc-ph-supply = <&reg_dcdc1>;
+};
+
+&r_i2c0 {
+	status = "okay";
+
+	axp803: pmic@34 {
+		compatible = "x-powers,axp803";
+		reg = <0x34>;
+		interrupt-parent = <&r_intc>;
+		interrupts = <0 IRQ_TYPE_LEVEL_LOW>;
+	};
+};
+
+#include "axp803.dtsi"
+
+&reg_aldo1 {
+	/* AVCC, PLL and DRAM 1.8V */
+	regulator-always-on;
+	regulator-min-microvolt = <1800000>;
+	regulator-max-microvolt = <1800000>;
+	regulator-name = "vcc-pll-avcc";
+};
+
+/* ALDO2 is for LPDDR and not used with the DDR3 on this board */
+
+&reg_aldo3 {
+	/*
+	 * Supply of the PL pin bank. It is not given to r_pio as
+	 * vcc-pl-supply: the PMIC is reached through PL0/PL1, so r_pio and
+	 * the PMIC would each wait for the other and the boot stops.
+	 */
+	regulator-always-on;
+	regulator-min-microvolt = <3300000>;
+	regulator-max-microvolt = <3300000>;
+	regulator-name = "vcc-pl";
+};
+
+&reg_dcdc1 {
+	/* SoC I/O, USB analog, eMMC and SD card */
+	regulator-always-on;
+	regulator-min-microvolt = <3300000>;
+	regulator-max-microvolt = <3300000>;
+	regulator-name = "vcc-3v3";
+};
+
+&reg_dcdc2 {
+	regulator-always-on;
+	regulator-min-microvolt = <810000>;
+	regulator-max-microvolt = <1200000>;
+	regulator-name = "vdd-cpux";
+};
+
+/* DCDC3 runs in dual phase with DCDC2 for VDD-CPUX and has no node */
+
+&reg_dcdc4 {
+	/* VDD-SYS, also used as VDD-USB */
+	regulator-always-on;
+	regulator-min-microvolt = <950000>;
+	regulator-max-microvolt = <950000>;
+	regulator-name = "vdd-sys";
+};
+
+&reg_dcdc5 {
+	/* DDR3 */
+	regulator-always-on;
+	regulator-min-microvolt = <1500000>;
+	regulator-max-microvolt = <1500000>;
+	regulator-name = "vcc-dram";
+};
+
+/* DCDC6 is not connected */
+&reg_dcdc6 {
+	status = "disabled";
+};
+
+&reg_dldo1 {
+	regulator-min-microvolt = <1800000>;
+	regulator-max-microvolt = <1800000>;
+	regulator-name = "vcc-pg";
+};
+
+&reg_dldo2 {
+	regulator-min-microvolt = <1800000>;
+	regulator-max-microvolt = <1800000>;
+	regulator-name = "vcc-pe";
+};
+
+&reg_eldo1 {
+	regulator-min-microvolt = <1800000>;
+	regulator-max-microvolt = <1800000>;
+	regulator-name = "vcc-pc";
+};
+
+&reg_fldo1 {
+	/* VDD-CPUS */
+	regulator-always-on;
+	regulator-min-microvolt = <900000>;
+	regulator-max-microvolt = <900000>;
+	regulator-name = "vdd-cpus";
+};
+
+&uart0 {
+	pinctrl-0 = <&uart0_pb_pins>;
+	pinctrl-names = "default";
+
+	status = "okay";
+};
+
+&usb_power_supply {
+	status = "okay";
+};
+
+&usbphy {
+	usb1_vbus-supply = <&reg_usb1_vbus>;
+
+	status = "okay";
+};

-- 
2.34.1

