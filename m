From: Utsav Agarwal <utsav.agarwal@analog.com>
Date: Thu, 04 Jul 2024 15:26:32 +0100
Subject: [PATCH v8 3/3] dt-bindings: input: Update dtbinding for adp5588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240704-adp5588_gpio_support-v8-3-208cf5d4c2d6@analog.com>
References: <20240704-adp5588_gpio_support-v8-0-208cf5d4c2d6@analog.com>
In-Reply-To: <20240704-adp5588_gpio_support-v8-0-208cf5d4c2d6@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720103192; l=2556;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=Ra3/HCJMBQdCHapgLF9TJHngpmod+ZLUYz39Zx5T23w=;
 b=gctcYHlXbmcVtUQMIZy8b7CyfVJegJbSWAOh8ARG/WmcsFFdM04FPzu58rwSuYJEovK5yAiYR
 oFB38/kwgslBGqF7W+8e0TjAcpBWM10g8+KEdl10mQOHUQxN1D/I00x
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

However the above properties are required to be specified when
configuring the device as a keypad, dependencies have been added
such that specifying either one would require the remaining as well.

Note that interrupts are optional, but required when the device has been
configured in keypad mode.

Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
---
 .../devicetree/bindings/input/adi,adp5588.yaml     | 45 +++++++++++++++++++---
 1 file changed, 40 insertions(+), 5 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/adi,adp5588.yaml b/Documentation/devicetree/bindings/input/adi,adp5588.yaml
index 26ea66834ae2..ccb24b8b7566 100644
--- a/Documentation/devicetree/bindings/input/adi,adp5588.yaml
+++ b/Documentation/devicetree/bindings/input/adi,adp5588.yaml
@@ -49,7 +49,10 @@ properties:
   interrupt-controller:
     description:
       This property applies if either keypad,num-rows lower than 8 or
-      keypad,num-columns lower than 10.
+      keypad,num-columns lower than 10. This property is optional if
+      keypad,num-rows or keypad,num-columns are not specified since the
+      device then acts as gpio only, during which interrupts may or may
+      not be utilized.
 
   '#interrupt-cells':
     const: 2
@@ -65,13 +68,28 @@ properties:
     minItems: 1
     maxItems: 2
 
+
+dependencies:
+  keypad,num-rows:
+    - linux,keymap
+    - keypad,num-columns
+  keypad,num-columns:
+    - linux,keymap
+    - keypad,num-rows
+  linux,keymap:
+    - keypad,num-rows
+    - keypad,num-columns
+
+if:
+  required:
+    - linux,keymap
+then:
+  required:
+    - interrupts
+
 required:
   - compatible
   - reg
-  - interrupts
-  - keypad,num-rows
-  - keypad,num-columns
-  - linux,keymap
 
 unevaluatedProperties: false
 
@@ -108,4 +126,21 @@ examples:
             >;
         };
     };
+
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/input/input.h>
+    #include <dt-bindings/gpio/gpio.h>
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+        gpio@34 {
+            compatible = "adi,adp5588";
+            reg = <0x34>;
+
+            #gpio-cells = <2>;
+            gpio-controller;
+        };
+    };
+
 ...

-- 
2.34.1

