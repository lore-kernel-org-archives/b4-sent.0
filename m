From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 02 Nov 2026 21:58:48 +0200
Subject: [PATCH 1/2] dt-bindings: leds: backlight: add Kinetic KTD3137
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-6768-ktd3137-v1-1-b5b4f903c56e@protonmail.com>
References: <20261102-6768-ktd3137-v1-0-b5b4f903c56e@protonmail.com>
In-Reply-To: <20261102-6768-ktd3137-v1-0-b5b4f903c56e@protonmail.com>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793649528; l=2713;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=W7KEav5RNE0IaBD4p6A6E+eItnSOsNWzD7VxYVWWyNg=;
 b=xn48T31sAqlYXbJ8B5hlz1LJUWEXZO0kFH9gw4yTlQ4Iqyo1F9rISUnAFUVP1HWPnPEhgkA0W
 7n/rHO8CUapD4zxZyrmsEcDNZMGMWMXVNBDF1vXbAi2VWpF2w4FbAST
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kinetic KTD3137 is an LED IC, used in various mobile devices for the
display backlight. Add devicetree bindings documentation for this chip.

Datasheet: https://www.kinet-ic.com/uploads/KTD3137-04a.pdf

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../bindings/leds/backlight/kinetic,ktd3137.yaml   | 64 ++++++++++++++++++++++
 MAINTAINERS                                        |  5 ++
 2 files changed, 69 insertions(+)

diff --git a/Documentation/devicetree/bindings/leds/backlight/kinetic,ktd3137.yaml b/Documentation/devicetree/bindings/leds/backlight/kinetic,ktd3137.yaml
new file mode 100644
index 000000000000..140615640a9a
--- /dev/null
+++ b/Documentation/devicetree/bindings/leds/backlight/kinetic,ktd3137.yaml
@@ -0,0 +1,64 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/leds/backlight/kinetic,ktd3137.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Kinetic Technologies KTD3137 LED Backlight
+
+maintainers:
+  - Roman Vivchar <rva333@protonmail.com>
+
+description:
+  The Kinetic Technologies KTD3137 is an I2C LED backlight driver for medium
+  to large size LCD panels.
+
+allOf:
+  - $ref: common.yaml#
+
+properties:
+  compatible:
+    const: kinetic,ktd3137
+
+  reg:
+    maxItems: 1
+
+  default-brightness:
+    maximum: 2047
+    default: 2047
+
+  enable-gpios:
+    maxItems: 1
+    description: GPIO connected to the HWEN pin.
+
+  led-max-microamp:
+    minimum: 5000
+    maximum: 29800
+    default: 20200
+
+  vin-supply: true
+
+required:
+  - compatible
+  - reg
+  - vin-supply
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        backlight@36 {
+            compatible = "kinetic,ktd3137";
+            reg = <0x36>;
+            enable-gpios = <&pio 160 GPIO_ACTIVE_HIGH>;
+            led-max-microamp = <20200>;
+            default-brightness = <2047>;
+            vin-supply = <&vsys>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 15c7dc516f7c..24dd5b43f167 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -14618,6 +14618,11 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/leds/backlight/kinetic,ktd2801.yaml
 F:	drivers/video/backlight/ktd2801-backlight.c
 
+KTD3137 BACKLIGHT DRIVER
+M:	Roman Vivchar <rva333@protonmail.com>
+S:	Maintained
+F:	Documentation/devicetree/bindings/leds/backlight/kinetic,ktd3137.yaml
+
 KTEST
 M:	Steven Rostedt <rostedt@goodmis.org>
 M:	John Hawley <warthog9@eaglescrag.net>

-- 
2.56.0

