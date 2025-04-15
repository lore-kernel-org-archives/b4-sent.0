From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 15 Apr 2025 15:49:25 +0100
Subject: [PATCH v2 09/17] dt-bindings: mfd: adp5585: add properties for
 input events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250415-dev-adp5589-fw-v2-9-3a799c3ed812@analog.com>
References: <20250415-dev-adp5589-fw-v2-0-3a799c3ed812@analog.com>
In-Reply-To: <20250415-dev-adp5589-fw-v2-0-3a799c3ed812@analog.com>
To: linux-gpio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-input@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Liu Ying <victor.liu@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744728560; l=7557;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=wZPkN6bBdwPKsrZQsSG3Z3mtT9FTrmStnj7qxfR7VFE=;
 b=AG4LmyZeOXKrkI/oOYvDKB0RLfH3XzWMnPSQwmkadp+l97Jd119gVTv7EY5nGC8S5OMvg2Zvb
 fdgQGQjgDKcBOz0hEF3Eigz8SU19aV2E3mKZ/kt3mwmg5ecoDnjIGUH
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add properties related to input events. These devices can act as
keyboards and can support events either via a keymap Matrix or through
GPIs. Note that the device needs to be an interrupt controller for GPIs
based events.

We specifically need a property specifying the pins used by the keymap
matrix since these devices have no requirement for rows and columns to be
contiguous without holes which is enforced by the standard input
properties.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 .../devicetree/bindings/mfd/adi,adp5585.yaml       | 188 ++++++++++++++++++++-
 1 file changed, 186 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/mfd/adi,adp5585.yaml b/Documentation/devicetree/bindings/mfd/adi,adp5585.yaml
index d690a411b3a4307f6dd5f4a432a357e89fefabb0..b7c36e2d4bfc4e75c856a0b8b9c842627bf3b1b2 100644
--- a/Documentation/devicetree/bindings/mfd/adi,adp5585.yaml
+++ b/Documentation/devicetree/bindings/mfd/adi,adp5585.yaml
@@ -49,6 +49,84 @@ properties:
   "#pwm-cells":
     const: 3
 
+  interrupt-controller: true
+
+  '#interrupt-cells':
+    const: 2
+
+  poll-interval:
+    enum: [10, 20, 30, 40]
+    default: 10
+
+  adi,keypad-pins:
+    description: Specifies the pins used for the keypad matrix.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+
+  adi,unlock-keys:
+    description:
+      Specifies a maximum of 2 keys that can be used to unlock the keypad.
+      If this property is set, the keyboard will be locked and only unlocked
+      after these keys are pressed. The value 127 serves as a wildcard which
+      means any key can be used for unlocking.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 1
+    maxItems: 2
+    items:
+      anyOf:
+        - minimum: 1
+          maximum: 88
+        - minimum: 97
+          maximum: 115
+        - const: 127
+
+  adi,unlock-trigger-sec:
+    description:
+      Defines the time in which the second unlock event must occur after the
+      first unlock event has occurred.
+    maximum: 7
+    default: 0
+
+  adi,reset1-keys:
+    description:
+      Defines the trigger events (key presses) that can generate reset
+      conditions one the reset1 block.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 1
+    maxItems: 3
+
+  adi,reset2-keys:
+    description:
+      Defines the trigger events (key presses) that can generate reset
+      conditions one the reset2 block.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 1
+    maxItems: 2
+
+  adi,reset1-active-high:
+    description: Sets the reset1 signal as active high.
+    type: boolean
+
+  adi,reset2-active-high:
+    description: Sets the reset2 signal as active high.
+    type: boolean
+
+  adi,rst-passtrough-enable:
+    description: Allows the RST pin to override (OR with) the reset1 signal.
+    type: boolean
+
+  adi,reset-trigger-ms:
+    description:
+      Defines the length of time that the reset events must be active before a
+      reset signal is generated. All events must be active at the same time for
+      the same duration.
+    enum: [0, 1000, 1500, 2000, 2500, 3000, 3500, 4000]
+    default: 0
+
+  adi,reset-pulse-width-us:
+    description: Defines the pulse width of the reset signals.
+    enum: [500, 1000, 2000, 10000]
+    default: 500
+
 patternProperties:
   "-hog(-[0-9]+)?$":
     type: object
@@ -56,11 +134,28 @@ patternProperties:
     required:
       - gpio-hog
 
+dependencies:
+  linux,keymap:
+    - adi,keypad-pins
+    - interrupts
+  interrupt-controller:
+    - interrupts
+  adi,unlock-trigger-sec:
+    - adi,unlock-keys
+  adi,reset1-active-high:
+    - adi,reset1-keys
+  adi,rst-passtrough-enable:
+    - adi,reset1-keys
+  adi,reset2-active-high:
+    - adi,reset2-keys
+
 required:
   - compatible
   - reg
 
 allOf:
+  - $ref: /schemas/input/matrix-keymap.yaml#
+  - $ref: /schemas/input/input.yaml#
   - if:
       properties:
         compatible:
@@ -68,8 +163,29 @@ allOf:
             const: adi,adp5585-01
     then:
       properties:
+        adi,unlock-keys: false
+        adi,unlock-trigger-sec: false
         gpio-reserved-ranges: false
-
+        adi,keypad-pins:
+          minItems: 2
+          maxItems: 11
+          items:
+            minimum: 0
+            maximum: 10
+        adi,reset1-keys:
+          items:
+            anyOf:
+              - minimum: 1
+                maximum: 30
+              - minimum: 37
+                maximum: 47
+        adi,reset2-keys:
+          items:
+            anyOf:
+              - minimum: 1
+                maximum: 30
+              - minimum: 37
+                maximum: 47
   - if:
       properties:
         compatible:
@@ -81,6 +197,25 @@ allOf:
               - adi,adp5585-02
     then:
       properties:
+        adi,unlock-keys: false
+        adi,unlock-trigger-sec: false
+        adi,keypad-pins:
+          minItems: 2
+          maxItems: 10
+          items:
+            enum: [0, 1, 2, 3, 4, 6, 7, 8, 9, 10]
+        adi,reset1-keys:
+          items:
+            anyOf:
+              - minimum: 1
+                maximum: 25
+              - enum: [37, 38, 39, 40, 41, 43, 44, 45, 46, 47]
+        adi,reset2-keys:
+          items:
+            anyOf:
+              - minimum: 1
+                maximum: 25
+              - enum: [37, 38, 39, 40, 41, 43, 44, 45, 46, 47]
         gpio-reserved-ranges:
           maxItems: 1
           items:
@@ -99,11 +234,33 @@ allOf:
     then:
       properties:
         gpio-reserved-ranges: false
+        adi,keypad-pins:
+          minItems: 2
+          maxItems: 19
+          items:
+            minimum: 0
+            maximum: 18
+        adi,reset1-keys:
+          items:
+            anyOf:
+              - minimum: 1
+                maximum: 88
+              - minimum: 97
+                maximum: 115
+        adi,reset2-keys:
+          items:
+            anyOf:
+              - minimum: 1
+                maximum: 88
+              - minimum: 97
+                maximum: 115
 
-additionalProperties: false
+unevaluatedProperties: false
 
 examples:
   - |
+    #include <dt-bindings/input/input.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
     i2c {
         #address-cells = <1>;
         #size-cells = <0>;
@@ -119,6 +276,33 @@ examples:
             gpio-reserved-ranges = <5 1>;
 
             #pwm-cells = <3>;
+
+            interrupts = <16 IRQ_TYPE_EDGE_FALLING>;
+            interrupt-parent = <&gpio>;
+
+            adi,reset1-keys = <1 43>;
+            adi,reset2-keys = <2 3>;
+            adi,reset-trigger-ms = <2000>;
+
+            /*
+             * col0, col1, col2
+             * row0, row1, row2
+             */
+            adi,keypad-pins = <0 1 2 6 7 8>;
+
+            linux,keymap = <
+                MATRIX_KEY(0x00, 0x00, KEY_1)
+                MATRIX_KEY(0x00, 0x01, KEY_2)
+                MATRIX_KEY(0x00, 0x02, KEY_3)
+
+                MATRIX_KEY(0x01, 0x00, KEY_A)
+                MATRIX_KEY(0x01, 0x01, KEY_B)
+                MATRIX_KEY(0x01, 0x02, KEY_C)
+
+                MATRIX_KEY(0x02, 0x00, BTN_1)
+                MATRIX_KEY(0x02, 0x01, BTN_2)
+                MATRIX_KEY(0x02, 0x02, BTN_3)
+            >;
         };
     };
 

-- 
2.49.0

