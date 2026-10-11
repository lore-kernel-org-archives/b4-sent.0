From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Sun, 11 Oct 2026 20:17:22 +0300
Subject: [PATCH 2/2] arm64: dts: meson-gxbb-odroidc2: use color and
 function for the status LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-odroidc2-dts-v1-2-f9f0e779af88@gmail.com>
References: <20261011-odroidc2-dts-v1-0-f9f0e779af88@gmail.com>
In-Reply-To: <20261011-odroidc2-dts-v1-0-f9f0e779af88@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791739040; l=1222;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=/X8gBi1JgR7x/35zsuv/f2r5evaENU8kz27T1XRV5c4=;
 b=ifRRKlIhKdzl/MOSg5AU5UAIBcV15SVmr7R7gl2lmCLrchc7kLLnZOKbgHL/YqIpNU+r37HAk
 MtCI9Mx7cZ5BuAcGL9sZRXhqAasl1ush8+pyf4HsIVFvMgv3PxAz9U0
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the legacy label on the blue status LED with the standard
color and function properties, following what the other Amlogic boards
already do.  The LED then shows up with a generic blue:status name
instead of the board-specific c2:blue:alive.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
index 639b97ad5..5f0cd2a71 100644
--- a/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts
@@ -9,6 +9,7 @@
 
 #include "meson-gxbb.dtsi"
 #include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/leds/common.h>
 #include <dt-bindings/sound/meson-aiu.h>
 
 / {
@@ -51,7 +52,8 @@ usb_otg_pwr: regulator-usb-pwrs {
 	leds {
 		compatible = "gpio-leds";
 		led-blue {
-			label = "c2:blue:alive";
+			color = <LED_COLOR_ID_BLUE>;
+			function = LED_FUNCTION_STATUS;
 			gpios = <&gpio_ao GPIOAO_13 GPIO_ACTIVE_LOW>;
 			linux,default-trigger = "heartbeat";
 			default-state = "off";

-- 
2.53.0

