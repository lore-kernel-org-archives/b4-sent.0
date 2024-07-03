From: Utsav Agarwal <utsav.agarwal@analog.com>
Date: Wed, 03 Jul 2024 11:58:16 +0100
Subject: [PATCH v5 3/3] dt-bindings: input: Update dtbinding for adp5588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240703-adp5588_gpio_support-v5-3-49fcead0d390@analog.com>
References: <20240703-adp5588_gpio_support-v5-0-49fcead0d390@analog.com>
In-Reply-To: <20240703-adp5588_gpio_support-v5-0-49fcead0d390@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720004298; l=2319;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=tjToYmfL/IEyCDgaXOsMEe4jog3UMGcJT5HUGpTVFL0=;
 b=mHTnfZZzd4M7OG8aN82knWmCDe4h3Ye/4JzKymjrAuucTMwx+XDs9c9mL2A8SUgrfG2KkNFcg
 uVEgfOKNmsHAFmnWG41J0MPhCGXbio5m2/Sgq/p/A/AlrTG4X0XDDJ0
X-Developer-Key: i=utsav.agarwal@analog.com; a=ed25519;
 pk=mIG5Dmd3TO5rcICwTsixl2MoUcf/i2u+jYqifd7+fmI=
X-Endpoint-Received: by B4 Relay for utsav.agarwal@analog.com/20240701 with auth_id=178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Updating dt bindings for adp5588. Since the device can now function in a
purely gpio mode, the following keypad specific properties are now made
optional:
	- interrupts
	- keypad,num-rows
	- keypad,num-columns
	- linux,keymap

However since the above properties are required to be specified when
configuring the device as a keypad, dependencies have been added
such that specifying either one would require the remaining as well.

Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
---
 .../devicetree/bindings/input/adi,adp5588.yaml     | 33 ++++++++++++++++++----
 1 file changed, 28 insertions(+), 5 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/adi,adp5588.yaml b/Documentation/devicetree/bindings/input/adi,adp5588.yaml
index 26ea66834ae2..6c06464f822b 100644
--- a/Documentation/devicetree/bindings/input/adi,adp5588.yaml
+++ b/Documentation/devicetree/bindings/input/adi,adp5588.yaml
@@ -49,7 +49,10 @@ properties:
   interrupt-controller:
     description:
       This property applies if either keypad,num-rows lower than 8 or
-      keypad,num-columns lower than 10.
+      keypad,num-columns lower than 10. This property does not apply if
+      keypad,num-rows or keypad,num-columns are not specified since the
+      device then acts as gpio only, during which interrupts are not
+      utilized.
 
   '#interrupt-cells':
     const: 2
@@ -65,13 +68,15 @@ properties:
     minItems: 1
     maxItems: 2
 
+dependencies:
+  keypad,num-rows: ["keypad,num-columns"]
+  keypad,num-cols: ["keypad,num-rows"]
+  linux,keymap: ["keypad,num-rows"]
+  interrupts: ["linux,keymap"]
+
 required:
   - compatible
   - reg
-  - interrupts
-  - keypad,num-rows
-  - keypad,num-columns
-  - linux,keymap
 
 unevaluatedProperties: false
 
@@ -108,4 +113,22 @@ examples:
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
+            };
+        };
+
 ...

-- 
2.34.1

