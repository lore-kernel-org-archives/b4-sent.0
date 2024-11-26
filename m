From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Tue, 26 Nov 2024 21:47:59 +0100
Subject: [PATCH 1/4] dt-bindings: input: touchscreen: Add Z2 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-z2-v1-1-c43c4cc6200d@gmail.com>
References: <20241126-z2-v1-0-c43c4cc6200d@gmail.com>
In-Reply-To: <20241126-z2-v1-0-c43c4cc6200d@gmail.com>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732654092; l=2804;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=UHvXgMi/23w7qON+PGUGo++6lr9MH2GBkiekDOSsTok=;
 b=v2an5Zj1C0uzlwCBhHF2ZQWwt6rSGPADVo45ZAjcVatoE2WRViXstwZvsJUf7P6F9MtmnBKza
 2GOjGYozUJwDVOHKJNJtRTlkyNCJtsYdABKic9dSMOvOWgu8iwJqldS
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for touchscreen controllers attached using the Z2 protocol.
Those are present in most Apple devices.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 .../input/touchscreen/apple,z2-multitouch.yaml     | 83 ++++++++++++++++++++++
 1 file changed, 83 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/apple,z2-multitouch.yaml b/Documentation/devicetree/bindings/input/touchscreen/apple,z2-multitouch.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..0387e2178b91d5658dfd60cb44099a8048dc97df
--- /dev/null
+++ b/Documentation/devicetree/bindings/input/touchscreen/apple,z2-multitouch.yaml
@@ -0,0 +1,83 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/input/touchscreen/apple,z2-multitouch.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple touchscreens attached using the Z2 protocol
+
+maintainers:
+  - Sasha Finkelstein <fnkl.kernel@gmail.com>
+
+description: A series of touschscreen controllers used in Apple products
+
+allOf:
+  - $ref: touchscreen.yaml#
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - apple,j293-touchbar
+          - apple,j493-touchbar
+      - const: apple,z2-touchbar
+      - const: apple,z2-multitouch
+
+  interrupts:
+    maxItems: 1
+
+  reset-gpios:
+    maxItems: 1
+
+  cs-gpios:
+    maxItems: 1
+    description: |
+      J293 has a hardware quirk where the CS line is unusable and has
+      to the be driven by a GPIO pin instead
+
+  firmware-name:
+    maxItems: 1
+
+  label:
+    maxItems: 1
+
+  touchscreen-size-x: true
+  touchscreen-size-y: true
+
+required:
+  - compatible
+  - interrupts
+  - reset-gpios
+  - firmware-name
+  - label
+  - touchscreen-size-x
+  - touchscreen-size-y
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        touchscreen@0 {
+            compatible = "apple,j293-touchbar", "apple,z2-touchbar",
+                         "apple,z2-multitouch";
+            reg = <0>;
+            spi-max-frequency = <11500000>;
+            reset-gpios = <&pinctrl_ap 139 0>;
+            cs-gpios = <&pinctrl_ap 109 0>;
+            interrupts-extended = <&pinctrl_ap 194 IRQ_TYPE_EDGE_FALLING>;
+            firmware-name = "apple/dfrmtfw-j293.bin";
+            touchscreen-size-x = <23045>;
+            touchscreen-size-y = <640>;
+            label = "MacBookPro17,1 Touch Bar";
+        };
+    };
+
+...

-- 
2.47.1

