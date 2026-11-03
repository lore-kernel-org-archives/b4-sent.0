From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Tue, 03 Nov 2026 18:37:08 +0800
Subject: [PATCH v3 3/6] arm64: dts: rockchip: Add devicetree for the
 FriendlyElec NanoPi R28S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-nanopi-r28s-v3-3-ae8664fd168f@proton.me>
References: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
In-Reply-To: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>, 
 Heiko Stuebner <heiko@sntech.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4996;
 i=HystericalDragons@proton.me; s=20261103; h=from:subject:message-id;
 bh=rvqwtn67AjiPqkBuMNlbFDfk3sVDXvEvh3arACU1s+s=;
 b=owGbwMvMwCU8Ldb53x4TtgLG02pJDFkvdwabVrGaTDYIFlffl/6Suaf+/f8zLjd9n7V03Eqed
 Xudqfe7jp0sDMJcDLJiiiyd0p8nfnl8YfrXm5OyYOawMoEMYeDiFICJGHoxcTJ+/XA4+/3F8Hy7
 Ai2ly6cKpnEmiJ+88TV2ValCy6WFi97H3KtSbGeNOz8j8BO/8Q1mD0Vn23POq3JS7U/lvPMzW2j
 g+x5oRuTJ1a2nb1l7O88LnnB98YuDMg7ZsS+Koha+dGecHeZqd2pPa8+ymjaZBeqpzXlLvuxLqN
 2UIrfiSsD2vZPt2R3vyDJPAQA=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=5A3AC293DCEEAA41A8A3266A910205A0AEB09D84
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/20261103 with auth_id=1393
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The NanoPi R28S is a dual gigabit Ethernet router board based on the
Rockchip RK3528 SoC, designed and developed by FriendlyElec. It shares
most of its design with the NanoPi Zero2, so it builds on the common
rk3528-nanopi.dtsi.

Specification:
- Rockchip RK3528
- 1GB RAM
- eMMC socket (optional)
- MicroSD slot
- 1x 1000Base-T (GMAC1, Realtek RTL8211F)
- 1x 1000Base-T (PCIe, Realtek RTL8111H)
- AICSemi AIC8800D80 SDIO WiFi + Bluetooth
- 3x LEDs (SYS, LAN, WAN)
- 1x USB 2.0 Type-C OTG, shared with the 5V power input
- User and MaskROM buttons
- Haoyu HYM8563 RTC
- 1x USB Type-C debug UART (onboard WCH CH340E)

The AIC8800D80 has no upstream driver yet, so only the SDIO and UART
controllers it hangs off are enabled, along with the WiFi and Bluetooth
wake and power pins taken from the schematics.

Assisted-by: LLM
Signed-off-by: 安容 <HystericalDragons@proton.me>
Link: https://patch.msgid.link/20260919-r28s-upstream-v7-3-e80a6f8ef521@proton.me
Signed-off-by: Heiko Stuebner <heiko@sntech.de>

[ upstream commit: c1e23f3425c49fe22e9598f8eea2fcf693950d50 ]

(cherry picked from commit d0f6e37c635be183ff10d8a0291f54afd1365f30)
---
 .../src/arm64/rockchip/rk3528-nanopi-r28s.dts      | 160 +++++++++++++++++++++
 1 file changed, 160 insertions(+)

diff --git a/dts/upstream/src/arm64/rockchip/rk3528-nanopi-r28s.dts b/dts/upstream/src/arm64/rockchip/rk3528-nanopi-r28s.dts
new file mode 100644
index 00000000000..294b66f60e4
--- /dev/null
+++ b/dts/upstream/src/arm64/rockchip/rk3528-nanopi-r28s.dts
@@ -0,0 +1,160 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+/*
+ * Copyright (c) 2022 Rockchip Electronics Co., Ltd.
+ * Copyright (c) 2026 FriendlyElec Computer Tech. Co., Ltd.
+ * Copyright (c) 2026 安容 <HystericalDragons@proton.me>
+ */
+
+/dts-v1/;
+
+#include "rk3528-nanopi.dtsi"
+
+/ {
+	model = "FriendlyElec NanoPi R28S";
+	compatible = "friendlyarm,nanopi-r28s", "rockchip,rk3528";
+
+	aliases {
+		mmc2 = &sdio0;
+		serial2 = &uart2;
+	};
+
+	gpio-keys {
+		compatible = "gpio-keys";
+		pinctrl-names = "default";
+		pinctrl-0 = <&gpio4_b2_usr_btn>;
+
+		button-user {
+			debounce-interval = <50>;
+			gpios = <&gpio4 RK_PB2 GPIO_ACTIVE_LOW>;
+			label = "USER";
+			linux,code = <BTN_1>;
+			wakeup-source;
+		};
+	};
+
+	sdio_pwrseq: sdio-pwrseq {
+		compatible = "mmc-pwrseq-simple";
+		pinctrl-names = "default";
+		pinctrl-0 = <&pwr_wf>;
+		post-power-on-delay-ms = <100>;
+		reset-gpios = <&gpio1 RK_PC2 GPIO_ACTIVE_LOW>;
+	};
+};
+
+&combphy {
+	status = "okay";
+};
+
+&led1 {
+	default-state = "off";
+	function = LED_FUNCTION_WAN;
+	linux,default-trigger = "netdev";
+};
+
+&leds {
+	pinctrl-names = "default";
+	pinctrl-0 = <&led_sys_pin>, <&led1_pin>, <&led2_pin>;
+
+	led-2 {
+		color = <LED_COLOR_ID_GREEN>;
+		default-state = "off";
+		function = LED_FUNCTION_LAN;
+		gpios = <&gpio4 RK_PB3 GPIO_ACTIVE_HIGH>;
+		linux,default-trigger = "netdev";
+	};
+};
+
+&pcie {
+	pinctrl-names = "default";
+	pinctrl-0 = <&pcie_eth_perstb>;
+	reset-gpios = <&gpio4 RK_PC0 GPIO_ACTIVE_HIGH>;
+	vpcie3v3-supply = <&vcc_3v3>;
+	status = "okay";
+};
+
+&pinctrl {
+	bluetooth {
+		bt_wake_host: bt-wake-host {
+			rockchip,pins = <1 RK_PB5 RK_FUNC_GPIO &pcfg_pull_down>;
+		};
+
+		host_wake_bt: host-wake-bt {
+			rockchip,pins = <1 RK_PB4 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+
+	gpio-keys {
+		gpio4_b2_usr_btn: gpio4-b2-usr-btn {
+			rockchip,pins = <4 RK_PB2 RK_FUNC_GPIO &pcfg_pull_up>;
+		};
+	};
+
+	leds {
+		led2_pin: led2-pin {
+			rockchip,pins = <4 RK_PB3 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+
+	pcie {
+		pcie_eth_perstb: pcie-eth-perstb {
+			rockchip,pins = <4 RK_PC0 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+	};
+
+	wifi {
+		host_wake_wl: host-wake-wl {
+			rockchip,pins = <1 RK_PA6 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		pwr_wf: pwr-wf {
+			rockchip,pins = <1 RK_PC2 RK_FUNC_GPIO &pcfg_pull_none>;
+		};
+
+		wl_wake_host: wl-wake-host {
+			rockchip,pins = <1 RK_PA7 RK_FUNC_GPIO &pcfg_pull_down>;
+		};
+	};
+};
+
+&sdio0 {
+	bus-width = <4>;
+	cap-sd-highspeed;
+	cap-sdio-irq;
+	keep-power-in-suspend;
+	mmc-pwrseq = <&sdio_pwrseq>;
+	no-mmc;
+	no-sd;
+	non-removable;
+	sd-uhs-sdr104;
+	vmmc-supply = <&vcc_3v3>;
+	vqmmc-supply = <&vcc_1v8>;
+	status = "okay";
+};
+
+&uart2 {
+	dma-names = "tx", "rx";
+	pinctrl-names = "default";
+	pinctrl-0 = <&uart2m1_xfer>, <&uart2m1_ctsn>, <&uart2m1_rtsn>;
+	uart-has-rtscts;
+	status = "okay";
+};
+
+&usb_host0_xhci {
+	/*
+	 * The Type-C port is also the 5V power input, so it comes up as a
+	 * device, but host mode works with an externally powered hub.
+	 */
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
2.56.0

