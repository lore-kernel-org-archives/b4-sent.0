From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Fri, 24 Feb 2023 11:20:06 +0100
Subject: [PATCH RFC 1/4] dt-bindings: input: touchscreen: Add Z2 controller
 bindings.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230223-z2-for-ml-v1-1-028f2b85dc15@gmail.com>
References: <20230223-z2-for-ml-v1-0-028f2b85dc15@gmail.com>
In-Reply-To: <20230223-z2-for-ml-v1-0-028f2b85dc15@gmail.com>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 - <asahi@lists.linux.dev>, Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677234010; l=2766;
 i=fnkl.kernel@gmail.com; s=20230213; h=from:subject:message-id;
 bh=TIFeuBdRxzykTftxnIb6paUfaCW7E97Qi1elJFdmf7U=;
 b=c+U5qTMzGRBHyc/3ErDETUt6IQ+mC5Oe26vWKbSJ6yB7qx9I7uJB8eFYGoWMwv0y49Wz6mwi5
 /qtg+m5apLKAs8MZnNIbISBEZ2l5ghoQt4wXe5W+3gnSSPYTI81yhhL
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=7LFSAJtxIWAs9LzCIyX0sSvCZy2wQTyEIu1zch6o804=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20230213 with auth_id=28
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for touchscreen controllers attached using the Z2 protocol.
Those are present in most Apple devices.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 .../input/touchscreen/apple,z2-touchscreen.yaml    | 81 ++++++++++++++++++++++
 1 file changed, 81 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/apple,z2-touchscreen.yaml b/Documentation/devicetree/bindings/input/touchscreen/apple,z2-touchscreen.yaml
new file mode 100644
index 000000000000..695594494b1e
--- /dev/null
+++ b/Documentation/devicetree/bindings/input/touchscreen/apple,z2-touchscreen.yaml
@@ -0,0 +1,81 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/input/touchscreen/apple,z2-touchscreen.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple touchscreens attached using the Z2 protocol.
+
+maintainers:
+  - asahi@lists.linux.dev
+  - Sasha Finkelstein <fnkl.kernel@gmail.com>
+
+description: A series of touschscreen controllers used in Apple products.
+
+allOf:
+  - $ref: touchscreen.yaml#
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+properties:
+  compatible:
+    const: apple,z2-touchscreen
+
+  reg:
+    maxItems: 1
+
+  interrupts-extended:
+    maxItems: 1
+
+  reset-gpios:
+    maxItems: 1
+
+  cs-gpios:
+    maxItems: 1
+
+  firmware-name:
+    maxItems: 1
+
+  apple,z2-device-name:
+    description: The name to be used for the input device
+    $ref: /schemas/types.yaml#/definitions/string
+
+  touchscreen-size-x: true
+  touchscreen-size-y: true
+  spi-max-frequency: true
+
+required:
+  - compatible
+  - interrupts-extended
+  - reset-gpios
+  - cs-gpios
+  - firmware-name
+  - apple,z2-device-name
+  - touchscreen-size-x
+  - touchscreen-size-y
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    spi {
+            #address-cells = <1>;
+            #size-cells = <0>;
+
+            touchscreen@0 {
+                    compatible = "apple,z2-touchscreen";
+                    reg = <0>;
+                    spi-max-frequency = <11500000>;
+                    reset-gpios = <&pinctrl_ap 139 0>;
+                    cs-gpios = <&pinctrl_ap 109 0>;
+                    interrupts-extended = <&pinctrl_ap 194 IRQ_TYPE_EDGE_FALLING>;
+                    firmware-name = "apple/dfrmtfw-j293.bin";
+                    touchscreen-size-x = <23045>;
+                    touchscreen-size-y = <640>;
+                    apple,z2-device-name = "MacBookPro17,1 Touch Bar";
+            };
+    };
+
+...

-- 
Git-137.1)

