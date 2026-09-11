From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Fri, 11 Sep 2026 18:02:47 +0800
Subject: [PATCH v4 4/4] arm64: dts: rockchip: Follow the DTS coding style
 in the NanoPi RK3528 devicetrees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260911-r28s-upstream-v4-4-fb6c85f226d4@proton.me>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4850;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=ssKzAfVkZddHv0qc5wz7c3QaYBjTBYQe4UupIr5CUEY=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqzFFy9+KLo6+ZL4fqtvb74viDw+reyCmPCH2bs/v/AWP
 fWdTfX35Y5SFgYxLgZZMUUW2U3VkUKromcWsUgdh5nDygQyhIGLUwAmsqaLkWHDptofRaYf9yje
 k2+q6eeenPzs4Ba53wwrDv3eksZTXXOOkeG4wEO5KPFrLukawpxbZIW9ZrHKBd/j/TL/Qf6pZXt
 n32IHAA==
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The shared NanoPi RK3528 devicetree and the NanoPi Zero2 board devicetree
deviate from Documentation/devicetree/bindings/dts-coding-style.rst in two
places: "pinctrl-0" has to sort before "pinctrl-names", and "status" has to
be preceded by a blank line when the node has content before it.

Sort the properties and add the missing blank lines. No functional changes.

Suggested-by: Diederik de Haas <diederik@cknow-tech.com>
Signed-off-by: 安容 <HystericalDragons@proton.me>
---
 .../boot/dts/rockchip/rk3528-nanopi-zero2.dts      |  5 ++--
 arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi    | 28 +++++++++++++++-------
 2 files changed, 22 insertions(+), 11 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts b/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
index 48e4273872..96c537da6a 100644
--- a/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3528-nanopi-zero2.dts
@@ -25,8 +25,8 @@ button-recovery {
 
 	leds {
 		compatible = "gpio-leds";
-		pinctrl-names = "default";
 		pinctrl-0 = <&led1>, <&led_sys>;
+		pinctrl-names = "default";
 
 		led-0 {
 			color = <LED_COLOR_ID_RED>;
@@ -59,8 +59,8 @@ usb2_host_5v: regulator-5v0-usb2-host {
 		compatible = "regulator-fixed";
 		enable-active-high;
 		gpios = <&gpio4 RK_PB5 GPIO_ACTIVE_HIGH>;
-		pinctrl-names = "default";
 		pinctrl-0 = <&usb20_host1_pwren>;
+		pinctrl-names = "default";
 		regulator-name = "usb2_host_5v";
 		regulator-min-microvolt = <5000000>;
 		regulator-max-microvolt = <5000000>;
@@ -96,5 +96,6 @@ &usb_host0_ohci {
 
 &usb2phy_host {
 	phy-supply = <&usb2_host_5v>;
+
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi b/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi
index 8d9d0056a0..fa9df4d8f4 100644
--- a/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi
@@ -77,8 +77,8 @@ vcc_3v3: regulator-3v3-vcc {
 	vcc3v3_sd: regulator-3v3-vcc-sd {
 		compatible = "regulator-fixed";
 		gpios = <&gpio4 RK_PA1 GPIO_ACTIVE_LOW>;
-		pinctrl-names = "default";
 		pinctrl-0 = <&sdmmc_pwren_l>;
+		pinctrl-names = "default";
 		regulator-name = "vcc3v3_sd";
 		regulator-min-microvolt = <3300000>;
 		regulator-max-microvolt = <3300000>;
@@ -97,8 +97,8 @@ vcc5v0_sys: regulator-5v0-vcc-sys {
 	vccio_sd: regulator-vccio-sd {
 		compatible = "regulator-gpio";
 		gpios = <&gpio4 RK_PB6 GPIO_ACTIVE_HIGH>;
-		pinctrl-names = "default";
 		pinctrl-0 = <&sdmmc_vol_ctrl_h>;
+		pinctrl-names = "default";
 		regulator-name = "vccio_sd";
 		regulator-min-microvolt = <1800000>;
 		regulator-max-microvolt = <3300000>;
@@ -152,20 +152,23 @@ &gmac1 {
 	phy-handle = <&rgmii_phy>;
 	phy-mode = "rgmii-id";
 	phy-supply = <&vcc_3v3>;
-	pinctrl-names = "default";
 	pinctrl-0 = <&rgmii_miim>, <&rgmii_tx_bus2>, <&rgmii_rx_bus2>,
 		    <&rgmii_rgmii_clk>, <&rgmii_rgmii_bus>;
+	pinctrl-names = "default";
+
 	status = "okay";
 };
 
 &gpu {
 	mali-supply = <&vdd_logic>;
+
 	status = "okay";
 };
 
 &i2c1 {
-	pinctrl-names = "default";
 	pinctrl-0 = <&i2c1m0_xfer>;
+	pinctrl-names = "default";
+
 	status = "okay";
 
 	hym8563: rtc@51 {
@@ -174,8 +177,8 @@ hym8563: rtc@51 {
 		#clock-cells = <0>;
 		interrupt-parent = <&gpio4>;
 		interrupts = <RK_PC1 IRQ_TYPE_LEVEL_LOW>;
-		pinctrl-names = "default";
 		pinctrl-0 = <&rtc_int_l>;
+		pinctrl-names = "default";
 		wakeup-source;
 	};
 };
@@ -184,8 +187,8 @@ &mdio1 {
 	rgmii_phy: ethernet-phy@1 {
 		compatible = "ethernet-phy-ieee802.3-c22";
 		reg = <0x1>;
-		pinctrl-names = "default";
 		pinctrl-0 = <&gmac1_rstn_l>;
+		pinctrl-names = "default";
 		reset-assert-us = <20000>;
 		reset-deassert-us = <100000>;
 		reset-gpios = <&gpio4 RK_PC2 GPIO_ACTIVE_LOW>;
@@ -217,19 +220,22 @@ sdmmc_vol_ctrl_h: sdmmc-vol-ctrl-h {
 };
 
 &pwm1 {
-	pinctrl-names = "default";
 	pinctrl-0 = <&pwm1m0_pins>;
+	pinctrl-names = "default";
+
 	status = "okay";
 };
 
 &pwm2 {
-	pinctrl-names = "default";
 	pinctrl-0 = <&pwm2m0_pins>;
+	pinctrl-names = "default";
+
 	status = "okay";
 };
 
 &saradc {
 	vref-supply = <&vcc_1v8>;
+
 	status = "okay";
 };
 
@@ -242,6 +248,7 @@ &sdhci {
 	non-removable;
 	vmmc-supply = <&vcc_3v3>;
 	vqmmc-supply = <&vcc_1v8>;
+
 	status = "okay";
 };
 
@@ -253,12 +260,14 @@ &sdmmc {
 	sd-uhs-sdr104;
 	vmmc-supply = <&vcc3v3_sd>;
 	vqmmc-supply = <&vccio_sd>;
+
 	status = "okay";
 };
 
 &uart0 {
-	pinctrl-names = "default";
 	pinctrl-0 = <&uart0m0_xfer>;
+	pinctrl-names = "default";
+
 	status = "okay";
 };
 
@@ -267,6 +276,7 @@ &usb_host0_xhci {
 	maximum-speed = "high-speed";
 	phys = <&usb2phy_otg>;
 	phy-names = "usb2-phy";
+
 	status = "okay";
 };
 

-- 
2.55.0

