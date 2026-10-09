From: Igor Velkov <iav@iav.lv>
Date: Fri, 09 Oct 2026 03:40:48 +0300
Subject: [PATCH] arm64: dts: rockchip: Add the front panel LEDs to Kobol
 Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-helios64-leds-v1-1-6c58a66bf0c6@iav.lv>
X-B4-Tracking: v=1; b=H4sIAA84yGoC/x3MQQqAIBBA0avErBNUUqqrRAvJKQdEw4EIxLsnL
 d/i/wqMhZBhHSoUfIgppw41DnAEly4U5LtBS22VlIsIGCmznUREz8JqMxvnDEqroTd3wZPe/7f
 trX1dI/j4XwAAAA==
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4250; i=iav@iav.lv;
 h=from:subject:message-id; bh=llv6HX0uCXXdfUD/WPDPaPRAv2BcF+iTEvDdVmnTS6Q=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFknLASb34RJzE5PU/V3Ob7jnGXD7KyG4+tuCU9I14/yX
 afoPm9XRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZhIihcjw/cYHUsmx6CEKTcr
 T+m4qRd2bGryqU9L+mxZuCnKue5ZBsN/9z//Htzb8z9z0yLv+7kzReoeuV76x/DQpY9TUfWD7J1
 WHgA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Besides the system LEDs, the front panel of Helios64 has a network, a
USB and five SATA error LEDs. Each is switched by a MOSFET from a GPIO,
active high: NETW_ACT_LED_ON on GPIO0_A4, USB3_ACT_LED_ON on GPIO0_B3
and SATA_ERR0 to SATA_ERR4 on GPIO2_A2 to GPIO2_A6. The Kobol wiki
gives the colours: activity LEDs are blue, error LEDs are red.

Describe them next to the system LEDs. The panel labels the disks
HDD 1 to HDD 5, so the error LEDs are numbered from 1.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Schematic, sheets 29, 30 and 35:
https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf
Front panel LED colours:
https://wiki.kobol.io/helios64/front-panel/
---
 .../boot/dts/rockchip/rk3399-kobol-helios64.dts    | 78 +++++++++++++++++++++-
 1 file changed, 77 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index d146e5075b4f..25f0ba5a47ac 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -12,6 +12,7 @@
 
 /dts-v1/;
 #include <dt-bindings/input/input.h>
+#include <dt-bindings/leds/common.h>
 #include "rk3399.dtsi"
 
 / {
@@ -107,7 +108,8 @@ button-user1 {
 	leds {
 		compatible = "gpio-leds";
 		pinctrl-names = "default";
-		pinctrl-0 = <&sys_grn_led_on &sys_red_led_on>;
+		pinctrl-0 = <&sys_grn_led_on &sys_red_led_on &netw_act_led_on
+			     &usb3_act_led_on &sata_err_led_on &sata_act_led>;
 
 		led-0 {
 			label = "helios64:green:status";
@@ -120,6 +122,60 @@ led-1 {
 			gpios = <&gpio0 RK_PB5 GPIO_ACTIVE_HIGH>;
 			default-state = "keep";
 		};
+
+		led-2 {
+			color = <LED_COLOR_ID_BLUE>;
+			function = LED_FUNCTION_LAN;
+			gpios = <&gpio0 RK_PA4 GPIO_ACTIVE_HIGH>;
+		};
+
+		led-3 {
+			color = <LED_COLOR_ID_BLUE>;
+			function = LED_FUNCTION_USB;
+			gpios = <&gpio0 RK_PB3 GPIO_ACTIVE_HIGH>;
+		};
+
+		led-4 {
+			color = <LED_COLOR_ID_RED>;
+			function = LED_FUNCTION_DISK_ERR;
+			function-enumerator = <1>;
+			gpios = <&gpio2 RK_PA2 GPIO_ACTIVE_HIGH>;
+		};
+
+		led-5 {
+			color = <LED_COLOR_ID_RED>;
+			function = LED_FUNCTION_DISK_ERR;
+			function-enumerator = <2>;
+			gpios = <&gpio2 RK_PA3 GPIO_ACTIVE_HIGH>;
+		};
+
+		led-6 {
+			color = <LED_COLOR_ID_RED>;
+			function = LED_FUNCTION_DISK_ERR;
+			function-enumerator = <3>;
+			gpios = <&gpio2 RK_PA4 GPIO_ACTIVE_HIGH>;
+		};
+
+		led-7 {
+			color = <LED_COLOR_ID_RED>;
+			function = LED_FUNCTION_DISK_ERR;
+			function-enumerator = <4>;
+			gpios = <&gpio2 RK_PA5 GPIO_ACTIVE_HIGH>;
+		};
+
+		led-8 {
+			color = <LED_COLOR_ID_RED>;
+			function = LED_FUNCTION_DISK_ERR;
+			function-enumerator = <5>;
+			gpios = <&gpio2 RK_PA6 GPIO_ACTIVE_HIGH>;
+		};
+
+		led-9 {
+			color = <LED_COLOR_ID_BLUE>;
+			function = LED_FUNCTION_DISK_ACTIVITY;
+			gpios = <&gpio4 RK_PD4 GPIO_ACTIVE_HIGH>;
+			default-state = "on";
+		};
 	};
 
 	hdd_a_power: regulator-hdd-a-power {
@@ -500,6 +556,22 @@ gphy_reset: gphy-reset {
 	};
 
 	leds {
+		netw_act_led_on: netw-act-led-on {
+			rockchip,pins = <0 RK_PA4 RK_FUNC_GPIO &pcfg_pull_down>;
+		};
+
+		sata_act_led: sata-act-led {
+			rockchip,pins = <4 RK_PD4 RK_FUNC_GPIO &pcfg_pull_down>;
+		};
+
+		sata_err_led_on: sata-err-led-on {
+			rockchip,pins = <2 RK_PA2 RK_FUNC_GPIO &pcfg_pull_down>,
+					<2 RK_PA3 RK_FUNC_GPIO &pcfg_pull_down>,
+					<2 RK_PA4 RK_FUNC_GPIO &pcfg_pull_down>,
+					<2 RK_PA5 RK_FUNC_GPIO &pcfg_pull_down>,
+					<2 RK_PA6 RK_FUNC_GPIO &pcfg_pull_down>;
+		};
+
 		sys_grn_led_on: sys-grn-led-on {
 			rockchip,pins = <0 RK_PB4 RK_FUNC_GPIO &pcfg_pull_down>;
 		};
@@ -507,6 +579,10 @@ sys_grn_led_on: sys-grn-led-on {
 		sys_red_led_on: sys-red-led-on {
 			rockchip,pins = <0 RK_PB5 RK_FUNC_GPIO &pcfg_pull_down>;
 		};
+
+		usb3_act_led_on: usb3-act-led-on {
+			rockchip,pins = <0 RK_PB3 RK_FUNC_GPIO &pcfg_pull_down>;
+		};
 	};
 
 	pcie {

---
base-commit: 36b190eca882ecd39b5354f7ee995f939dc6d885
change-id: 20261009-helios64-leds-62585aa5e062

Best regards,
-- 
Igor Velkov <iav@iav.lv>

