From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Fri, 11 Sep 2026 18:02:45 +0800
Subject: [PATCH v4 2/4] arm64: dts: rockchip: Split out the common NanoPi
 RK3528 parts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260911-r28s-upstream-v4-2-fb6c85f226d4@proton.me>
References: <20260911-r28s-upstream-v4-0-fb6c85f226d4@proton.me>
In-Reply-To: <20260911-r28s-upstream-v4-0-fb6c85f226d4@proton.me>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chukun Pan <amadeus@jmu.edu.cn>, Jonas Karlman <jonas@kwiboo.se>, 
 jensen <jensenhuang@friendlyarm.com>, 
 Andrey Korshunov <razor1702@gmail.com>, 
 Diederik de Haas <diederik@cknow-tech.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=14628;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=VQNKFK/7WLlIKiODmRr2dRbp9QoC8D3CcasFo2DcVuU=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqzFFy9W/pGYalH0tmH5jrLrRzf+Xv/VOyTfc+Jd244Dq
 9tvOjS87ihlYRDjYpAVU2SR3VQdKbQqemYRi9RxmDmsTCBDGLg4BWAiEzcy/M+I/SG99h2XwIZv
 Hpn9Vlvu3Z07oaFgzU6R8GOJCad2a0QwMrzjlDuxUH9FzOfZU0U1WEx+GTksOy6gOWf6h3qLOew
 TDFkB
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPi Zero2 and the NanoPi R28S share their power
tree, storage, RGMII Ethernet, RTC and debug console. Move those parts
into rk3528-nanopi.dtsi so the NanoPi R28S can reuse them, and leave
only the board specific nodes in the NanoPi Zero2 devicetree.

Suggested-by: Chukun Pan <amadeus@jmu.edu.cn>
Signed-off-by: 安容 <HystericalDragons@proton.me>
---
 .../boot/dts/rockchip/rk3528-nanopi-zero2.dts      | 271 +-------------------
 arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi    | 279 +++++++++++++++++++++
 2 files changed, 280 insertions(+), 270 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts b/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
index 97d85124d2..48e4273872 100644
--- a/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
@@ -2,41 +2,13 @@
 
 /dts-v1/;
 
-#include <dt-bindings/input/input.h>
 #include <dt-bindings/leds/common.h>
-#include <dt-bindings/pwm/pwm.h>
-#include "rk3528.dtsi"
+#include "rk3528-nanopi.dtsi"
 
 / {
 	model = "FriendlyElec NanoPi Zero2";
 	compatible = "friendlyarm,nanopi-zero2", "rockchip,rk3528";
 
-	aliases {
-		ethernet0 = &gmac1;
-		i2c1 = &i2c1;
-		mmc0 = &sdhci;
-		mmc1 = &sdmmc;
-		serial0 = &uart0;
-	};
-
-	chosen {
-		stdout-path = "serial0:1500000n8";
-	};
-
-	adc-keys-0 {
-		compatible = "adc-keys";
-		io-channels = <&saradc 0>;
-		io-channel-names = "buttons";
-		keyup-threshold-microvolt = <1800000>;
-		poll-interval = <100>;
-
-		button-maskrom {
-			label = "MASK";
-			linux,code = <KEY_SETUP>;
-			press-threshold-microvolt = <0>;
-		};
-	};
-
 	adc-keys-1 {
 		compatible = "adc-keys";
 		io-channels = <&saradc 1>;
@@ -83,66 +55,6 @@ vcc0v6_ddr: regulator-0v6-vcc-ddr {
 		vin-supply = <&vcc5v0_sys>;
 	};
 
-	vdd_0v9: regulator-0v9-vdd {
-		compatible = "regulator-fixed";
-		regulator-name = "vdd_0v9";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <900000>;
-		regulator-max-microvolt = <900000>;
-		vin-supply = <&vcc5v0_sys>;
-	};
-
-	vcc_ddr: regulator-1v1-vcc-ddr {
-		compatible = "regulator-fixed";
-		regulator-name = "vcc_ddr";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <1100000>;
-		regulator-max-microvolt = <1100000>;
-		vin-supply = <&vcc5v0_sys>;
-	};
-
-	vcc_1v8: regulator-1v8-vcc {
-		compatible = "regulator-fixed";
-		regulator-name = "vcc_1v8";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <1800000>;
-		regulator-max-microvolt = <1800000>;
-		vin-supply = <&vcc_3v3>;
-	};
-
-	vcc_3v3: regulator-3v3-vcc {
-		compatible = "regulator-fixed";
-		regulator-name = "vcc_3v3";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <3300000>;
-		regulator-max-microvolt = <3300000>;
-		vin-supply = <&vcc5v0_sys>;
-	};
-
-	vcc3v3_sd: regulator-3v3-vcc-sd {
-		compatible = "regulator-fixed";
-		gpios = <&gpio4 RK_PA1 GPIO_ACTIVE_LOW>;
-		pinctrl-names = "default";
-		pinctrl-0 = <&sdmmc_pwren_l>;
-		regulator-name = "vcc3v3_sd";
-		regulator-min-microvolt = <3300000>;
-		regulator-max-microvolt = <3300000>;
-		vin-supply = <&vcc_3v3>;
-	};
-
-	vcc5v0_sys: regulator-5v0-vcc-sys {
-		compatible = "regulator-fixed";
-		regulator-name = "vcc5v0_sys";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <5000000>;
-		regulator-max-microvolt = <5000000>;
-	};
-
 	usb2_host_5v: regulator-5v0-usb2-host {
 		compatible = "regulator-fixed";
 		enable-active-high;
@@ -154,112 +66,9 @@ usb2_host_5v: regulator-5v0-usb2-host {
 		regulator-max-microvolt = <5000000>;
 		vin-supply = <&vcc5v0_sys>;
 	};
-
-	vccio_sd: regulator-vccio-sd {
-		compatible = "regulator-gpio";
-		gpios = <&gpio4 RK_PB6 GPIO_ACTIVE_HIGH>;
-		pinctrl-names = "default";
-		pinctrl-0 = <&sdmmc_vol_ctrl_h>;
-		regulator-name = "vccio_sd";
-		regulator-min-microvolt = <1800000>;
-		regulator-max-microvolt = <3300000>;
-		states = <1800000 0x0>, <3300000 0x1>;
-		vin-supply = <&vcc5v0_sys>;
-	};
-
-	vdd_arm: regulator-vdd-arm {
-		compatible = "pwm-regulator";
-		pwms = <&pwm1 0 5000 PWM_POLARITY_INVERTED>;
-		pwm-supply = <&vcc5v0_sys>;
-		regulator-name = "vdd_arm";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <746000>;
-		regulator-max-microvolt = <1201000>;
-		regulator-settling-time-up-us = <250>;
-	};
-
-	vdd_logic: regulator-vdd-logic {
-		compatible = "pwm-regulator";
-		pwms = <&pwm2 0 5000 PWM_POLARITY_INVERTED>;
-		pwm-supply = <&vcc5v0_sys>;
-		regulator-name = "vdd_logic";
-		regulator-always-on;
-		regulator-boot-on;
-		regulator-min-microvolt = <705000>;
-		regulator-max-microvolt = <1006000>;
-		regulator-settling-time-up-us = <250>;
-	};
-};
-
-&cpu0 {
-	cpu-supply = <&vdd_arm>;
-};
-
-&cpu1 {
-	cpu-supply = <&vdd_arm>;
-};
-
-&cpu2 {
-	cpu-supply = <&vdd_arm>;
-};
-
-&cpu3 {
-	cpu-supply = <&vdd_arm>;
-};
-
-&gmac1 {
-	clock_in_out = "output";
-	phy-handle = <&rgmii_phy>;
-	phy-mode = "rgmii-id";
-	phy-supply = <&vcc_3v3>;
-	pinctrl-names = "default";
-	pinctrl-0 = <&rgmii_miim>, <&rgmii_tx_bus2>, <&rgmii_rx_bus2>,
-		    <&rgmii_rgmii_clk>, <&rgmii_rgmii_bus>;
-	status = "okay";
-};
-
-&gpu {
-	mali-supply = <&vdd_logic>;
-	status = "okay";
-};
-
-&i2c1 {
-	pinctrl-names = "default";
-	pinctrl-0 = <&i2c1m0_xfer>;
-	status = "okay";
-
-	hym8563: rtc@51 {
-		compatible = "haoyu,hym8563";
-		reg = <0x51>;
-		#clock-cells = <0>;
-		interrupt-parent = <&gpio4>;
-		interrupts = <RK_PC1 IRQ_TYPE_LEVEL_LOW>;
-		pinctrl-names = "default";
-		pinctrl-0 = <&rtc_int_l>;
-		wakeup-source;
-	};
-};
-
-&mdio1 {
-	rgmii_phy: ethernet-phy@1 {
-		compatible = "ethernet-phy-ieee802.3-c22";
-		reg = <0x1>;
-		pinctrl-names = "default";
-		pinctrl-0 = <&gmac1_rstn_l>;
-		reset-assert-us = <20000>;
-		reset-deassert-us = <100000>;
-		reset-gpios = <&gpio4 RK_PC2 GPIO_ACTIVE_LOW>;
-	};
 };
 
 &pinctrl {
-	ethernet {
-		gmac1_rstn_l: gmac1-rstn-l {
-			rockchip,pins = <4 RK_PC2 RK_FUNC_GPIO &pcfg_pull_none>;
-		};
-	};
-
 	leds {
 		led1: led1 {
 			rockchip,pins = <4 RK_PB1 RK_FUNC_GPIO &pcfg_pull_none>;
@@ -270,22 +79,6 @@ led_sys: led-sys {
 		};
 	};
 
-	rtc {
-		rtc_int_l: rtc-int-l {
-			rockchip,pins = <4 RK_PC1 RK_FUNC_GPIO &pcfg_pull_up>;
-		};
-	};
-
-	sdmmc {
-		sdmmc_vol_ctrl_h: sdmmc-vol-ctrl-h {
-			rockchip,pins = <4 RK_PB6 RK_FUNC_GPIO &pcfg_pull_none>;
-		};
-
-		sdmmc_pwren_l: sdmmc-pwren-l {
-			rockchip,pins = <4 RK_PA1 RK_FUNC_GPIO &pcfg_pull_none>;
-		};
-	};
-
 	usb {
 		usb20_host1_pwren: usb20-host1-pwren {
 			rockchip,pins = <4 RK_PB5 RK_FUNC_GPIO &pcfg_pull_none>;
@@ -293,52 +86,6 @@ usb20_host1_pwren: usb20-host1-pwren {
 	};
 };
 
-&pwm1 {
-	pinctrl-names = "default";
-	pinctrl-0 = <&pwm1m0_pins>;
-	status = "okay";
-};
-
-&pwm2 {
-	pinctrl-names = "default";
-	pinctrl-0 = <&pwm2m0_pins>;
-	status = "okay";
-};
-
-&saradc {
-	vref-supply = <&vcc_1v8>;
-	status = "okay";
-};
-
-&sdhci {
-	bus-width = <8>;
-	cap-mmc-highspeed;
-	mmc-hs200-1_8v;
-	no-sd;
-	no-sdio;
-	non-removable;
-	vmmc-supply = <&vcc_3v3>;
-	vqmmc-supply = <&vcc_1v8>;
-	status = "okay";
-};
-
-&sdmmc {
-	bus-width = <4>;
-	cap-mmc-highspeed;
-	cap-sd-highspeed;
-	disable-wp;
-	sd-uhs-sdr104;
-	vmmc-supply = <&vcc3v3_sd>;
-	vqmmc-supply = <&vccio_sd>;
-	status = "okay";
-};
-
-&uart0 {
-	pinctrl-names = "default";
-	pinctrl-0 = <&uart0m0_xfer>;
-	status = "okay";
-};
-
 &usb_host0_ehci {
 	status = "okay";
 };
@@ -347,23 +94,7 @@ &usb_host0_ohci {
 	status = "okay";
 };
 
-&usb_host0_xhci {
-	extcon = <&usb2phy>;
-	maximum-speed = "high-speed";
-	phys = <&usb2phy_otg>;
-	phy-names = "usb2-phy";
-	status = "okay";
-};
-
-&usb2phy {
-	status = "okay";
-};
-
 &usb2phy_host {
 	phy-supply = <&usb2_host_5v>;
 	status = "okay";
 };
-
-&usb2phy_otg {
-	status = "okay";
-};
diff --git a/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi b/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi
new file mode 100644
index 0000000000..8d9d0056a0
--- /dev/null
+++ b/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi
@@ -0,0 +1,279 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+/*
+ * Common parts of the FriendlyElec RK3528 boards: NanoPi Zero2 and NanoPi R28S.
+ */
+
+#include <dt-bindings/input/input.h>
+#include <dt-bindings/pwm/pwm.h>
+#include "rk3528.dtsi"
+
+/ {
+	aliases {
+		ethernet0 = &gmac1;
+		i2c1 = &i2c1;
+		mmc0 = &sdhci;
+		mmc1 = &sdmmc;
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:1500000n8";
+	};
+
+	adc-keys-0 {
+		compatible = "adc-keys";
+		io-channels = <&saradc 0>;
+		io-channel-names = "buttons";
+		keyup-threshold-microvolt = <1800000>;
+		poll-interval = <100>;
+
+		button-maskrom {
+			label = "MASK";
+			linux,code = <KEY_SETUP>;
+			press-threshold-microvolt = <0>;
+		};
+	};
+
+	vdd_0v9: regulator-0v9-vdd {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_0v9";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <900000>;
+		regulator-max-microvolt = <900000>;
+		vin-supply = <&vcc5v0_sys>;
+	};
+
+	vcc_ddr: regulator-1v1-vcc-ddr {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc_ddr";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <1100000>;
+		regulator-max-microvolt = <1100000>;
+		vin-supply = <&vcc5v0_sys>;
+	};
+
+	vcc_1v8: regulator-1v8-vcc {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc_1v8";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+		vin-supply = <&vcc_3v3>;
+	};
+
+	vcc_3v3: regulator-3v3-vcc {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc_3v3";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		vin-supply = <&vcc5v0_sys>;
+	};
+
+	vcc3v3_sd: regulator-3v3-vcc-sd {
+		compatible = "regulator-fixed";
+		gpios = <&gpio4 RK_PA1 GPIO_ACTIVE_LOW>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&sdmmc_pwren_l>;
+		regulator-name = "vcc3v3_sd";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		vin-supply = <&vcc_3v3>;
+	};
+
+	vcc5v0_sys: regulator-5v0-vcc-sys {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc5v0_sys";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+	};
+
+	vccio_sd: regulator-vccio-sd {
+		compatible = "regulator-gpio";
+		gpios = <&gpio4 RK_PB6 GPIO_ACTIVE_HIGH>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&sdmmc_vol_ctrl_h>;
+		regulator-name = "vccio_sd";
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <3300000>;
+		states = <1800000 0x0>, <3300000 0x1>;
+		vin-supply = <&vcc5v0_sys>;
+	};
+
+	vdd_arm: regulator-vdd-arm {
+		compatible = "pwm-regulator";
+		pwms = <&pwm1 0 5000 PWM_POLARITY_INVERTED>;
+		pwm-supply = <&vcc5v0_sys>;
+		regulator-name = "vdd_arm";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <746000>;
+		regulator-max-microvolt = <1201000>;
+		regulator-settling-time-up-us = <250>;
+	};
+
+	vdd_logic: regulator-vdd-logic {
+		compatible = "pwm-regulator";
+		pwms = <&pwm2 0 5000 PWM_POLARITY_INVERTED>;
+		pwm-supply = <&vcc5v0_sys>;
+		regulator-name = "vdd_logic";
+		regulator-always-on;
+		regulator-boot-on;
+		regulator-min-microvolt = <705000>;
+		regulator-max-microvolt = <1006000>;
+		regulator-settling-time-up-us = <250>;
+	};
+};
+
+&cpu0 {
+	cpu-supply = <&vdd_arm>;
+};
+
+&cpu1 {
+	cpu-supply = <&vdd_arm>;
+};
+
+&cpu2 {
+	cpu-supply = <&vdd_arm>;
+};
+
+&cpu3 {
+	cpu-supply = <&vdd_arm>;
+};
+
+&gmac1 {
+	clock_in_out = "output";
+	phy-handle = <&rgmii_phy>;
+	phy-mode = "rgmii-id";
+	phy-supply = <&vcc_3v3>;
+	pinctrl-names = "default";
+	pinctrl-0 = <&rgmii_miim>, <&rgmii_tx_bus2>, <&rgmii_rx_bus2>,
+		    <&rgmii_rgmii_clk>, <&rgmii_rgmii_bus>;
+	status = "okay";
+};
+
+&gpu {
+	mali-supply = <&vdd_logic>;
+	status = "okay";
+};
+
+&i2c1 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&i2c1m0_xfer>;
+	status = "okay";
+
+	hym8563: rtc@51 {
+		compatible = "haoyu,hym8563";
+		reg = <0x51>;
+		#clock-cells = <0>;
+		interrupt-parent = <&gpio4>;
+		interrupts = <RK_PC1 IRQ_TYPE_LEVEL_LOW>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&rtc_int_l>;
+		wakeup-source;
+	};
+};
+
+&mdio1 {
+	rgmii_phy: ethernet-phy@1 {
+		compatible = "ethernet-phy-ieee802.3-c22";
+		reg = <0x1>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&gmac1_rstn_l>;
+		reset-assert-us = <20000>;
+		reset-deassert-us = <100000>;
+		reset-gpios = <&gpio4 RK_PC2 GPIO_ACTIVE_LOW>;
+	};
+};
+
+&pinctrl {
+	ethernet {
+		gmac1_rstn_l: gmac1-rstn-l {
+			rockchip,pins = <4 RK_PC2 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+
+	rtc {
+		rtc_int_l: rtc-int-l {
+			rockchip,pins = <4 RK_PC1 RK_FUNC_GPIO &pcfg_pull_up>;
+		};
+	};
+
+	sdmmc {
+		sdmmc_pwren_l: sdmmc-pwren-l {
+			rockchip,pins = <4 RK_PA1 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		sdmmc_vol_ctrl_h: sdmmc-vol-ctrl-h {
+			rockchip,pins = <4 RK_PB6 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+};
+
+&pwm1 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&pwm1m0_pins>;
+	status = "okay";
+};
+
+&pwm2 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&pwm2m0_pins>;
+	status = "okay";
+};
+
+&saradc {
+	vref-supply = <&vcc_1v8>;
+	status = "okay";
+};
+
+&sdhci {
+	bus-width = <8>;
+	cap-mmc-highspeed;
+	mmc-hs200-1_8v;
+	no-sd;
+	no-sdio;
+	non-removable;
+	vmmc-supply = <&vcc_3v3>;
+	vqmmc-supply = <&vcc_1v8>;
+	status = "okay";
+};
+
+&sdmmc {
+	bus-width = <4>;
+	cap-mmc-highspeed;
+	cap-sd-highspeed;
+	disable-wp;
+	sd-uhs-sdr104;
+	vmmc-supply = <&vcc3v3_sd>;
+	vqmmc-supply = <&vccio_sd>;
+	status = "okay";
+};
+
+&uart0 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&uart0m0_xfer>;
+	status = "okay";
+};
+
+&usb_host0_xhci {
+	extcon = <&usb2phy>;
+	maximum-speed = "high-speed";
+	phys = <&usb2phy_otg>;
+	phy-names = "usb2-phy";
+	status = "okay";
+};
+
+&usb2phy {
+	status = "okay";
+};
+
+&usb2phy_otg {
+	status = "okay";
+};

-- 
2.55.0

