From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sun, 14 Apr 2024 20:01:21 +0300
Subject: [PATCH 1/4] ARM: dts: BCM5301X: use color and function on ASUS
 RT-AC3100 and RT-AC88U
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240414-for-soc-asus-rt-ac3100-improvements-v1-1-0e40caf1a70a@arinc9.com>
References: <20240414-for-soc-asus-rt-ac3100-improvements-v1-0-0e40caf1a70a@arinc9.com>
In-Reply-To: <20240414-for-soc-asus-rt-ac3100-improvements-v1-0-0e40caf1a70a@arinc9.com>
To: Florian Fainelli <florian.fainelli@broadcom.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, 
 =?utf-8?q?Rafa=C5=82_Mi=C5=82ecki?= <zajec5@gmail.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713114081; l=3138;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=j9b3dbJqMcoEoUpOpDrZC6RI+SBn+VmxLPPihPauC6w=;
 b=dD1ZOzdlA2FdEjfj/blWyiR/jrYHXQVbhcbLmo9OJWnsXb+SgNxhUE+jqYxsbp75APsfsTFYD
 922V+xD+gSLDMv/SkPO1LNq+RY91bN9YmtFsRBl6O0+HNN4cHsNgjYn
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As the label property for LEDs is deprecated, use the color and function
properties to describe the LEDs on the device tree file for ASUS RT-AC3100
and ASUS RT-AC88U. Reorder the LED and button nodes in alphabetical order.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 .../boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi | 54 +++++++++++++---------
 1 file changed, 32 insertions(+), 22 deletions(-)

diff --git a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi
index 09cefce27fb1..9271792a9e44 100644
--- a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi
+++ b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi
@@ -6,6 +6,8 @@
 #include "bcm47094.dtsi"
 #include "bcm5301x-nand-cs0-bch8.dtsi"
 
+#include <dt-bindings/leds/common.h>
+
 / {
 	chosen {
 		bootargs = "earlycon";
@@ -25,38 +27,46 @@ nvram@1c080000 {
 	leds {
 		compatible = "gpio-leds";
 
+		led-lan {
+			color = <LED_COLOR_ID_WHITE>;
+			function = LED_FUNCTION_LAN;
+			gpios = <&chipcommon 21 GPIO_ACTIVE_LOW>;
+		};
+
 		led-power {
-			label = "white:power";
+			color = <LED_COLOR_ID_WHITE>;
+			function = LED_FUNCTION_POWER;
 			gpios = <&chipcommon 3 GPIO_ACTIVE_LOW>;
 			linux,default-trigger = "default-on";
 		};
 
-		led-wan-red {
-			label = "red:wan";
-			gpios = <&chipcommon 5 GPIO_ACTIVE_HIGH>;
-		};
-
-		led-lan {
-			label = "white:lan";
-			gpios = <&chipcommon 21 GPIO_ACTIVE_LOW>;
-		};
-
 		led-usb2 {
-			label = "white:usb2";
+			color = <LED_COLOR_ID_WHITE>;
+			function = LED_FUNCTION_USB;
+			function-enumerator = <1>;
 			gpios = <&chipcommon 16 GPIO_ACTIVE_LOW>;
 			trigger-sources = <&ehci_port2>;
 			linux,default-trigger = "usbport";
 		};
 
 		led-usb3 {
-			label = "white:usb3";
+			color = <LED_COLOR_ID_WHITE>;
+			function = LED_FUNCTION_USB;
+			function-enumerator = <2>;
 			gpios = <&chipcommon 17 GPIO_ACTIVE_LOW>;
 			trigger-sources = <&ehci_port1>, <&xhci_port1>;
 			linux,default-trigger = "usbport";
 		};
 
+		led-wan-red {
+			color = <LED_COLOR_ID_RED>;
+			function = LED_FUNCTION_WAN;
+			gpios = <&chipcommon 5 GPIO_ACTIVE_HIGH>;
+		};
+
 		led-wps {
-			label = "white:wps";
+			color = <LED_COLOR_ID_WHITE>;
+			function = LED_FUNCTION_WPS;
 			gpios = <&chipcommon 19 GPIO_ACTIVE_LOW>;
 		};
 	};
@@ -64,10 +74,10 @@ led-wps {
 	gpio-keys {
 		compatible = "gpio-keys";
 
-		button-wps {
-			label = "WPS";
-			linux,code = <KEY_WPS_BUTTON>;
-			gpios = <&chipcommon 20 GPIO_ACTIVE_LOW>;
+		button-led {
+			label = "Backlight";
+			linux,code = <KEY_BRIGHTNESS_ZERO>;
+			gpios = <&chipcommon 4 GPIO_ACTIVE_LOW>;
 		};
 
 		button-reset {
@@ -82,10 +92,10 @@ button-wifi {
 			gpios = <&chipcommon 18 GPIO_ACTIVE_LOW>;
 		};
 
-		button-led {
-			label = "Backlight";
-			linux,code = <KEY_BRIGHTNESS_ZERO>;
-			gpios = <&chipcommon 4 GPIO_ACTIVE_LOW>;
+		button-wps {
+			label = "WPS";
+			linux,code = <KEY_WPS_BUTTON>;
+			gpios = <&chipcommon 20 GPIO_ACTIVE_LOW>;
 		};
 	};
 };

-- 
2.40.1

