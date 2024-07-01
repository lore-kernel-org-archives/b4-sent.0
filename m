From: Utsav Agarwal <utsav.agarwal@analog.com>
Date: Mon, 01 Jul 2024 16:04:51 +0100
Subject: [PATCH v4 2/2] dt-bindings: input: Update dtbinding for adp5588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240701-adp5588_gpio_support-v4-2-44bba0445e90@analog.com>
References: <20240701-adp5588_gpio_support-v4-0-44bba0445e90@analog.com>
In-Reply-To: <20240701-adp5588_gpio_support-v4-0-44bba0445e90@analog.com>
To: Utsav Agarwal <utsav.agarwal@analog.com>, 
 Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, 
 Vasileios Bimpikas <vasileios.bimpikas@analog.com>, 
 Oliver Gaskell <oliver.gaskell@analog.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719846302; l=1849;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=R/G0DKQvnInMMKOi2Ti6N/j7TpAXEYOccy0wLPhCRJc=;
 b=S6UwSAlomrXIllsnT//Gm6AItJFxmvZCHA+3ptH9mIbPrtpnFw7JXQXJ9x/7Jr0po8RxHyeuM
 6dkgupGl/TMDOhuKDMkWgSUzy6aTIovcjGi/JfjgJ3VdEW5OwibrtAq
X-Developer-Key: i=utsav.agarwal@analog.com; a=ed25519;
 pk=mIG5Dmd3TO5rcICwTsixl2MoUcf/i2u+jYqifd7+fmI=
X-Endpoint-Received: by B4 Relay for utsav.agarwal@analog.com/20240701 with auth_id=178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Updating dt bindings for adp5588. Following properties are now made
optional:
	- interrupts
	- keypad,num-rows
	- keypad,num-columns
	- linux,keymap
The proposed new property "gpio-only" has been added as an optional
property with an additional example.

Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
---
 .../devicetree/bindings/input/adi,adp5588.yaml     | 28 ++++++++++++++++++----
 1 file changed, 24 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/adi,adp5588.yaml b/Documentation/devicetree/bindings/input/adi,adp5588.yaml
index 26ea66834ae2..158fbf02cc16 100644
--- a/Documentation/devicetree/bindings/input/adi,adp5588.yaml
+++ b/Documentation/devicetree/bindings/input/adi,adp5588.yaml
@@ -46,6 +46,11 @@ properties:
   '#gpio-cells':
     const: 2
 
+  gpio-only:
+    description:
+      This property applies if keypad,num-rows, keypad,num-columns and
+      linux,keypad are not specified. All keys will be marked as gpio.
+
   interrupt-controller:
     description:
       This property applies if either keypad,num-rows lower than 8 or
@@ -68,10 +73,6 @@ properties:
 required:
   - compatible
   - reg
-  - interrupts
-  - keypad,num-rows
-  - keypad,num-columns
-  - linux,keymap
 
 unevaluatedProperties: false
 
@@ -108,4 +109,23 @@ examples:
             >;
         };
     };
+
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/input/input.h>
+    #include <dt-bindings/gpio/gpio.h>
+
+    i2c {
+      #address-cells = <1>;
+      #size-cells = <0>;
+        gpio@34 {
+            compatible = "adi,adp5588";
+            reg = <0x34>;
+
+            #gpio-cells = <2>;
+            gpio-controller;
+            gpio-only;
+            };
+        };
+
 ...

-- 
2.34.1

