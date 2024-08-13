From: Utsav Agarwal <utsav.agarwal@analog.com>
Date: Tue, 13 Aug 2024 21:07:19 +0100
Subject: [PATCH v11 3/3] dt-bindings: input: pure gpio support for adp5588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240813-adp5588_gpio_support-v11-3-9ea490d6c41d@analog.com>
References: <20240813-adp5588_gpio_support-v11-0-9ea490d6c41d@analog.com>
In-Reply-To: <20240813-adp5588_gpio_support-v11-0-9ea490d6c41d@analog.com>
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
 Oliver Gaskell <oliver.gaskell@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723579648; l=2847;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=6COPIRO0bw4RfEE2lJUqSvRth5I5w5rGF5z/Z1lH4ik=;
 b=avdzCcIhKEgUqv4cRAAAVhMdtEs83/HdjZP15P01DzfYjUY6Jg9faU3gJq5D4ArjXKb+unyob
 OT2PUfUCgFpDqk4s7bEjK0CLmhZz4CvmBon06a1naoY3/wFD4cKXZrZ
X-Developer-Key: i=utsav.agarwal@analog.com; a=ed25519;
 pk=mIG5Dmd3TO5rcICwTsixl2MoUcf/i2u+jYqifd7+fmI=
X-Endpoint-Received: by B4 Relay for utsav.agarwal@analog.com/20240701 with auth_id=178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adding software support for enabling the pure gpio capability of the
device - which allows all I/O to be used as GPIO. Previously, I/O
configuration was limited by software to partial GPIO support only.

When working in a pure gpio mode, the device does not require the
certain properties and hence, the following are now made optional:
	- interrupts
	- keypad,num-rows
	- keypad,num-columns
	- linux,keymap

However, note that the above are required to be specified when
configuring the device as a keypad, for which dependencies have been added
such that specifying either one requires the remaining as well.

Also, note that interrupts are made optional, but required when the device
has either been configured in keypad mode or as an interrupt controller.
This has been done since they may not necessarily be used when leveraging
the device purely for GPIO.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
---
 .../devicetree/bindings/input/adi,adp5588.yaml     | 38 +++++++++++++++++++---
 1 file changed, 33 insertions(+), 5 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/adi,adp5588.yaml b/Documentation/devicetree/bindings/input/adi,adp5588.yaml
index 26ea66834ae2..336bc352579a 100644
--- a/Documentation/devicetree/bindings/input/adi,adp5588.yaml
+++ b/Documentation/devicetree/bindings/input/adi,adp5588.yaml
@@ -49,7 +49,10 @@ properties:
   interrupt-controller:
     description:
       This property applies if either keypad,num-rows lower than 8 or
-      keypad,num-columns lower than 10.
+      keypad,num-columns lower than 10. This property is optional if
+      keypad,num-rows or keypad,num-columns are not specified as the
+      device is then configured to be used purely for gpio during which
+      interrupts may or may not be utilized.
 
   '#interrupt-cells':
     const: 2
@@ -65,13 +68,23 @@ properties:
     minItems: 1
     maxItems: 2
 
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
+    - interrupts
+  interrupt-controller:
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
 
@@ -108,4 +121,19 @@ examples:
             >;
         };
     };
+
+  - |
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

