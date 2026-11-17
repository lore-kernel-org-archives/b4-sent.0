From: Cristian Filipescu <filipescu.cristian@gmail.com>
To: linux-leds@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Griffin Kroah-Hartman <griffin@kroah.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, linux-sunxi@lists.linux.dev
Subject: [PATCH RFC] leds: DT: migrating existing labels to function/color
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Date: Tue, 17 Nov 2026 05:10:16 +0000
Message-ID: <179489221679.1.1429296960451969532.led-label-policy-rfc@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794892216; l=3129;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=yDEyHZ0vBr1PYekgAZguFVDD5Tfxmd/H6LQWci3XaNg=;
 b=32idoKYdXJ1Ued9e/Rgjim6ANtMlStXIm10OgKqlPw2EMFMZ/SznqoucCcuTAOxOsu0hQZisi
 jDVVG9zh0wMAOikJzP57ueY4ADZfIgpij6bsK1fqzx34t2eJlqUtHpO
X-Developer-Key: i=filipescu.cristian@gmail.com; a=ed25519;
 pk=o7Ui0tU3x+X/6Pq6PZHmd2KFtOdPWttoPuNFOvdD8t0=
X-Endpoint-Received: by B4 Relay for filipescu.cristian@gmail.com/uboot-20261021 with auth_id=1255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

The common LED binding deprecates label in favour of function and color.
Is removing existing labels desirable when it changes established LED class
names, or should existing board descriptions retain them for compatibility?

For example, the Orange Pi H6 descriptions could replace their labels with
LED_FUNCTION_POWER/STATUS and LED_COLOR_ID_RED/GREEN. With gpio-leds, this
would change the names under /sys/class/leds:

  orangepi:red:power    -> red:power
  orangepi:green:status -> green:status

The example below changes two files and affects Orange Pi 3, 3 LTS, Lite2
and One Plus. GPIOs, polarity, pinctrl, defaults and triggers are unchanged.
All four DTBs compile before and after; comparison found only the intended
label/function/color changes. The renamed LEDs have not been tested on
hardware.

I was thinking of converting all the deprecated LED labels, but I wanted
to see if this was something maintainers wanted, since it would touch a lot
of files. Would you prefer retaining existing labels (potentially adding
function and color alongside them), or reviewing migrations with the name
changes explicitly documented?

This is a discussion example, not a patch for inclusion. Preparation and
static checks were assisted by OpenAI Codex.

Thanks,
Cristian

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi-3.dts b/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi-3.dts
index ce82aa265..8e4117057 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi-3.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi-3.dts
@@ -8,6 +8,7 @@
 #include "sun50i-h6-gpu-opp.dtsi"
 
 #include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/leds/common.h>
 
 / {
 	model = "OrangePi 3";
@@ -45,13 +46,15 @@ leds {
 		compatible = "gpio-leds";
 
 		led-0 {
-			label = "orangepi:red:power";
+			function = LED_FUNCTION_POWER;
+			color = <LED_COLOR_ID_RED>;
 			gpios = <&r_pio 0 4 GPIO_ACTIVE_HIGH>; /* PL4 */
 			default-state = "on";
 		};
 
 		led-1 {
-			label = "orangepi:green:status";
+			function = LED_FUNCTION_STATUS;
+			color = <LED_COLOR_ID_GREEN>;
 			gpios = <&r_pio 0 7 GPIO_ACTIVE_HIGH>; /* PL7 */
 		};
 	};
diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi.dtsi
index 57b137755..49f3d2fc8 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h6-orangepi.dtsi
@@ -9,6 +9,7 @@
 #include "sun50i-h6-gpu-opp.dtsi"
 
 #include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/leds/common.h>
 
 / {
 	model = "OrangePi One Plus";
@@ -45,13 +46,15 @@ leds {
 		compatible = "gpio-leds";
 
 		led-0 {
-			label = "orangepi:red:power";
+			function = LED_FUNCTION_POWER;
+			color = <LED_COLOR_ID_RED>;
 			gpios = <&r_pio 0 4 GPIO_ACTIVE_HIGH>; /* PL4 */
 			default-state = "on";
 		};
 
 		led-1 {
-			label = "orangepi:green:status";
+			function = LED_FUNCTION_STATUS;
+			color = <LED_COLOR_ID_GREEN>;
 			gpios = <&r_pio 0 7 GPIO_ACTIVE_HIGH>; /* PL7 */
 		};
 	};

