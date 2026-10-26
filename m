From: Cristian Filipescu <filipescu.cristian@gmail.com>
Date: Mon, 26 Oct 2026 23:31:01 +0000
Subject: [PATCH v3 2/2] arm64: dts: allwinner: h6: Add Orange Pi 3 LTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261026-sunxi-orangepi-3-lts-v3-2-98fef4f75184@gmail.com>
References: <20261026-sunxi-orangepi-3-lts-v3-0-98fef4f75184@gmail.com>
In-Reply-To: <20261026-sunxi-orangepi-3-lts-v3-0-98fef4f75184@gmail.com>
To: linux-sunxi@lists.linux.dev, devicetree@vger.kernel.org, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Andre Przywara <andre.przywara@arm.com>, linux-kernel@vger.kernel.org, 
 Cristian Filipescu <filipescu.cristian@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793057459; l=10265;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=89b9Q3vssf8Hae1kQQF/ieGo6dyXYZXgzbV98QuPS0Q=;
 b=QZxgrmTPak6o3xoO43tcb+GsOBw1YuR7R6WNA3pMuo5nbmFlE+/DOSDE+vuGrZW0BjKe3yomT
 oVEFsgS2kZbAqxdS3Y6wLBzw0XiFbNKdJawBjTzea8Uph9eVND0edli
X-Developer-Key: i=filipescu.cristian@gmail.com; a=ed25519;
 pk=o7Ui0tU3x+X/6Pq6PZHmd2KFtOdPWttoPuNFOvdD8t0=
X-Endpoint-Received: by B4 Relay for filipescu.cristian@gmail.com/uboot-20261021 with auth_id=1255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Jernej Skrabec <jernej.skrabec@gmail.com>

Add the board description for the Allwinner H6-based Orange Pi 3 LTS,
including its regulators, storage, Ethernet PHY, LEDs and USB ports.

Specify the Motorcomm YT8531C PHY ID to avoid early ID autodetection,
which failed on MAC driver rebind. Reset the sole PHY at MDIO bus
registration and keep reset outside interface detach so its configured
125 MHz clock output is retained. Use PHY-internal RGMII delays.

Select the weakest GPIO drive level for both LEDs. Enable 1.8 V eMMC
DDR52 and HS200 modes; retain the H6 maximum frequency of 150 MHz.

Link: https://lore.kernel.org/linux-sunxi/20250413134318.66681-3-jernej.skrabec@gmail.com/
Signed-off-by: Jernej Skrabec <jernej.skrabec@gmail.com>
Signed-off-by: Cristian Filipescu <filipescu.cristian@gmail.com>
---
 arch/arm64/boot/dts/allwinner/Makefile             |   1 +
 .../dts/allwinner/sun50i-h6-orangepi-3-lts.dts     | 379 +++++++++++++++++++++
 2 files changed, 380 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/Makefile b/arch/arm64/boot/dts/allwinner/Makefile
index aa21f58a4..7ea136380 100644
--- a/arch/arm64/boot/dts/allwinner/Makefile
+++ b/arch/arm64/boot/dts/allwinner/Makefile
@@ -41,6 +41,7 @@ dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h5-orangepi-zero-plus.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h5-orangepi-zero-plus2.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h6-beelink-gs1.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h6-orangepi-3.dtb
+dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h6-orangepi-3-lts.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h6-orangepi-lite2.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h6-orangepi-one-plus.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h6-pine-h64.dtb
diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi-3-lts.dts b/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi-3-lts.dts
new file mode 100644
index 000000000..e2ca41b94
--- /dev/null
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi-3-lts.dts
@@ -0,0 +1,379 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+// Copyright (C) 2025 Jernej Skrabec <jernej.skrabec@gmail.com>
+// Based on sun50i-h6-orangepi-3.dts, which is:
+// Copyright (C) 2019 Ondřej Jirman <megous@megous.com>
+
+/dts-v1/;
+
+#include "sun50i-h6.dtsi"
+#include "sun50i-h6-cpu-opp.dtsi"
+#include "sun50i-h6-gpu-opp.dtsi"
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/leds/common.h>
+
+/ {
+	model = "OrangePi 3 LTS";
+	compatible = "xunlong,orangepi-3-lts", "allwinner,sun50i-h6";
+
+	aliases {
+		ethernet0 = &emac;
+		ethernet1 = &aw859a;
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+
+	connector {
+		compatible = "hdmi-connector";
+		ddc-en-gpios = <&pio 7 2 GPIO_ACTIVE_HIGH>; /* PH2 */
+		type = "a";
+
+		port {
+			hdmi_con_in: endpoint {
+				remote-endpoint = <&hdmi_out_con>;
+			};
+		};
+	};
+
+	ext_osc32k: ext-osc32k-clk {
+		#clock-cells = <0>;
+		compatible = "fixed-clock";
+		clock-frequency = <32768>;
+		clock-output-names = "ext-osc32k";
+	};
+
+	leds {
+		compatible = "gpio-leds";
+
+		led-0 {
+			function = LED_FUNCTION_STATUS;
+			color = <LED_COLOR_ID_RED>;
+			pinctrl-names = "default";
+			pinctrl-0 = <&led_red_pin>;
+			gpios = <&r_pio 0 4 GPIO_ACTIVE_HIGH>; /* PL4 */
+		};
+
+		led-1 {
+			function = LED_FUNCTION_POWER;
+			color = <LED_COLOR_ID_GREEN>;
+			pinctrl-names = "default";
+			pinctrl-0 = <&led_green_pin>;
+			gpios = <&r_pio 0 7 GPIO_ACTIVE_HIGH>; /* PL7 */
+			default-state = "on";
+		};
+	};
+
+	reg_gmac_3v3: gmac-3v3 {
+		compatible = "regulator-fixed";
+		regulator-name = "gmac-3v3";
+		vin-supply = <&reg_vcc5v>;
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		startup-delay-us = <150000>;
+		enable-active-high;
+		gpio = <&pio 3 6 GPIO_ACTIVE_HIGH>; /* PD6 */
+	};
+
+	reg_vcc5v: vcc5v {
+		/* board wide 5V supply directly from the DC jack */
+		compatible = "regulator-fixed";
+		regulator-name = "vcc-5v";
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+		regulator-always-on;
+	};
+
+	reg_wifi_3v3: wifi-3v3 {
+		/* 3.3V regulator for WiFi and BT */
+		compatible = "regulator-fixed";
+		regulator-name = "wifi-3v3";
+		vin-supply = <&reg_vcc5v>;
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		enable-active-high;
+		gpio = <&pio 7 7 GPIO_ACTIVE_HIGH>; /* PH7 */
+	};
+
+	wifi_pwrseq: wifi-pwrseq {
+		compatible = "mmc-pwrseq-simple";
+		clocks = <&rtc CLK_OSC32K_FANOUT>;
+		clock-names = "ext_clock";
+		reset-gpios = <&r_pio 1 3 GPIO_ACTIVE_LOW>; /* PM3 */
+		post-power-on-delay-ms = <200>;
+	};
+};
+
+&cpu0 {
+	cpu-supply = <&reg_dcdca>;
+};
+
+&de {
+	status = "okay";
+};
+
+&dwc3 {
+	status = "okay";
+};
+
+&ehci0 {
+	status = "okay";
+};
+
+&ehci3 {
+	status = "okay";
+};
+
+&emac {
+	pinctrl-names = "default";
+	pinctrl-0 = <&ext_rgmii_pins>;
+	phy-mode = "rgmii-id";
+	phy-handle = <&ext_rgmii_phy>;
+	phy-supply = <&reg_gmac_3v3>;
+	allwinner,rx-delay-ps = <0>;
+	allwinner,tx-delay-ps = <0>;
+	status = "okay";
+};
+
+&gpu {
+	mali-supply = <&reg_dcdcc>;
+	status = "okay";
+};
+
+&hdmi {
+	hvcc-supply = <&reg_bldo2>;
+	status = "okay";
+};
+
+&hdmi_out {
+	hdmi_out_con: endpoint {
+		remote-endpoint = <&hdmi_con_in>;
+	};
+};
+
+&mdio {
+	reset-gpios = <&pio 3 14 GPIO_ACTIVE_LOW>; /* PD14 */
+	reset-delay-us = <15000>;
+	reset-post-delay-us = <100000>;
+
+	ext_rgmii_phy: ethernet-phy@1 {
+		compatible = "ethernet-phy-id4f51.e91b";
+		reg = <1>;
+
+		motorcomm,clk-out-frequency-hz = <125000000>;
+		rx-internal-delay-ps = <1950>;
+		tx-internal-delay-ps = <1950>;
+	};
+};
+
+&mmc0 {
+	vmmc-supply = <&reg_cldo1>;
+	cd-gpios = <&pio 5 6 GPIO_ACTIVE_LOW>; /* PF6 */
+	disable-wp;
+	bus-width = <4>;
+	status = "okay";
+};
+
+&mmc1 {
+	vmmc-supply = <&reg_wifi_3v3>;
+	vqmmc-supply = <&reg_bldo3>;
+	mmc-pwrseq = <&wifi_pwrseq>;
+	bus-width = <4>;
+	non-removable;
+	status = "okay";
+
+	aw859a: wifi@1 {
+		reg = <1>;
+	};
+};
+
+&mmc2 {
+	vmmc-supply = <&reg_cldo1>;
+	vqmmc-supply = <&reg_bldo2>;
+	mmc-ddr-1_8v;
+	mmc-hs200-1_8v;
+	cap-mmc-hw-reset;
+	non-removable;
+	bus-width = <8>;
+	status = "okay";
+};
+
+&ohci0 {
+	status = "okay";
+};
+
+&ohci3 {
+	status = "okay";
+};
+
+&pio {
+	vcc-pc-supply = <&reg_bldo2>;
+	vcc-pd-supply = <&reg_cldo1>;
+	vcc-pg-supply = <&reg_bldo3>;
+};
+
+&r_ir {
+	status = "okay";
+};
+
+&r_pio {
+	vcc-pm-supply = <&reg_bldo3>;
+
+	led_green_pin: led-green-pin {
+		pins = "PL7";
+		function = "gpio_out";
+		drive-strength = <10>;
+	};
+
+	led_red_pin: led-red-pin {
+		pins = "PL4";
+		function = "gpio_out";
+		drive-strength = <10>;
+	};
+};
+
+&r_i2c {
+	status = "okay";
+
+	axp805: pmic@36 {
+		compatible = "x-powers,axp805", "x-powers,axp806";
+		reg = <0x36>;
+		interrupt-parent = <&r_intc>;
+		interrupts = <GIC_SPI 96 IRQ_TYPE_LEVEL_LOW>;
+		interrupt-controller;
+		#interrupt-cells = <1>;
+		x-powers,self-working-mode;
+		vina-supply = <&reg_vcc5v>;
+		vinb-supply = <&reg_vcc5v>;
+		vinc-supply = <&reg_vcc5v>;
+		vind-supply = <&reg_vcc5v>;
+		vine-supply = <&reg_vcc5v>;
+		aldoin-supply = <&reg_vcc5v>;
+		bldoin-supply = <&reg_vcc5v>;
+		cldoin-supply = <&reg_vcc5v>;
+
+		regulators {
+			reg_aldo1: aldo1 {
+				regulator-always-on;
+				regulator-min-microvolt = <3300000>;
+				regulator-max-microvolt = <3300000>;
+				regulator-name = "vcc-pl-led-ir";
+			};
+
+			reg_aldo2: aldo2 {
+				regulator-min-microvolt = <3300000>;
+				regulator-max-microvolt = <3300000>;
+				regulator-name = "vcc33-audio-tv-ephy-mac";
+			};
+
+			/* ALDO3 is shorted to CLDO1 */
+			reg_aldo3: aldo3 {
+				regulator-always-on;
+				regulator-min-microvolt = <3300000>;
+				regulator-max-microvolt = <3300000>;
+				regulator-name = "vcc33-io-pd-emmc-sd-usb-uart-1";
+			};
+
+			reg_bldo1: bldo1 {
+				regulator-always-on;
+				regulator-min-microvolt = <1800000>;
+				regulator-max-microvolt = <1800000>;
+				regulator-name = "vcc18-dram-bias-pll";
+			};
+
+			reg_bldo2: bldo2 {
+				regulator-min-microvolt = <1800000>;
+				regulator-max-microvolt = <1800000>;
+				regulator-name = "vcc-efuse-pcie-hdmi-pc";
+			};
+
+			reg_bldo3: bldo3 {
+				regulator-always-on;
+				regulator-min-microvolt = <1800000>;
+				regulator-max-microvolt = <1800000>;
+				regulator-name = "vcc-pm-pg-dcxoio-wifi";
+			};
+
+			bldo4 {
+				/* unused */
+			};
+
+			reg_cldo1: cldo1 {
+				regulator-always-on;
+				regulator-min-microvolt = <3300000>;
+				regulator-max-microvolt = <3300000>;
+				regulator-name = "vcc33-io-pd-emmc-sd-usb-uart-2";
+			};
+
+			cldo2 {
+				/* unused */
+			};
+
+			cldo3 {
+				/* unused */
+			};
+
+			/* DCDCB is polyphased with DCDCA. */
+			reg_dcdca: dcdca {
+				regulator-always-on;
+				regulator-min-microvolt = <800000>;
+				regulator-max-microvolt = <1160000>;
+				regulator-ramp-delay = <2500>;
+				regulator-name = "vdd-cpu";
+			};
+
+			reg_dcdcc: dcdcc {
+				regulator-enable-ramp-delay = <32000>;
+				regulator-min-microvolt = <810000>;
+				regulator-max-microvolt = <1080000>;
+				regulator-ramp-delay = <2500>;
+				regulator-name = "vdd-gpu";
+			};
+
+			reg_dcdcd: dcdcd {
+				regulator-always-on;
+				regulator-min-microvolt = <960000>;
+				regulator-max-microvolt = <960000>;
+				regulator-name = "vdd-sys";
+			};
+
+			reg_dcdce: dcdce {
+				regulator-always-on;
+				regulator-min-microvolt = <1200000>;
+				regulator-max-microvolt = <1200000>;
+				regulator-name = "vcc-dram";
+			};
+
+			sw {
+				/* unused */
+			};
+		};
+	};
+};
+
+&rtc {
+	clocks = <&ext_osc32k>;
+};
+
+&uart0 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&uart0_ph_pins>;
+	status = "okay";
+};
+
+&usb2otg {
+	dr_mode = "host";
+	status = "okay";
+};
+
+&usb2phy {
+	usb0_id_det-gpios = <&pio 2 15 GPIO_ACTIVE_HIGH>; /* PC15 */
+	usb0_vbus-supply = <&reg_vcc5v>;
+	usb3_vbus-supply = <&reg_vcc5v>;
+	status = "okay";
+};
+
+&usb3phy {
+	status = "okay";
+};

-- 
2.47.3

