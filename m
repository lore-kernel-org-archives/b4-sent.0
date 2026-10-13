From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 13 Oct 2026 06:47:07 +0300
Subject: [PATCH v2 09/11] ARM: dts: cortina: almondplus: Add reset button
 and enable I2C
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-cs75xx-s2-v2-9-94f8c0a90cda@gmail.com>
References: <20261013-b4-cs75xx-s2-v2-0-94f8c0a90cda@gmail.com>
In-Reply-To: <20261013-b4-cs75xx-s2-v2-0-94f8c0a90cda@gmail.com>
To: Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-i2c@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791863218; l=1441;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=2Dx/b8/3JsG/5KBFCzsSYSUq7LHO1maolj27mYLmFbc=;
 b=NCZhojoHHDNDG3XNDmNssM8FdsHah1ATGHcI1qanJ/M9/p+ahGop8+fVJAwJYx6j7tdK1iRTh
 yxm/NFQhbfOBxY5fGdxo1PZuSCHumLV63eLgxipMwcjupcLIJABC2eG
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pinhole button on the back of the Almond+ is connected to GPIO 37
(bank 1, line 5), active low. The stock firmware uses it for restart
and factory reset.

Enable the I2C bus, which has the touchscreen controller on it; the
touchscreen itself will be added together with its driver changes.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../boot/dts/cortina/cs7542-securifi-almondplus.dts   | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/arch/arm/boot/dts/cortina/cs7542-securifi-almondplus.dts b/arch/arm/boot/dts/cortina/cs7542-securifi-almondplus.dts
index e2988c687..0619bd754 100644
--- a/arch/arm/boot/dts/cortina/cs7542-securifi-almondplus.dts
+++ b/arch/arm/boot/dts/cortina/cs7542-securifi-almondplus.dts
@@ -5,6 +5,9 @@
 
 /dts-v1/;
 
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/input/input.h>
+
 #include "cs7542.dtsi"
 
 / {
@@ -19,6 +22,16 @@ chosen {
 		stdout-path = "serial0:115200n8";
 	};
 
+	keys {
+		compatible = "gpio-keys";
+
+		button-reset {
+			label = "reset";
+			gpios = <&gpio1 5 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_RESTART>;
+		};
+	};
+
 	memory@0 {
 		device_type = "memory";
 		reg = <0x00000000 0x20000000>;
@@ -50,6 +63,12 @@ &apb_clk {
 	clock-frequency = <150000000>;
 };
 
+&i2c {
+	clock-frequency = <400000>;
+
+	status = "okay";
+};
+
 &uart0 {
 	status = "okay";
 };

-- 
2.53.0

