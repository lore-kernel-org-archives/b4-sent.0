From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 13 Mar 2025 14:19:22 +0000
Subject: [PATCH 05/18] dt-bindings: mfd: adp5585: document adp5589 I/O
 expander
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250313-dev-adp5589-fw-v1-5-20e80d4bd4ea@analog.com>
References: <20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com>
In-Reply-To: <20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741875561; l=3546;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=rrvfmHEXd0tTkBviDQann7NZgieOZ479PPjxFhfnUAI=;
 b=0uqWM3h49M4V7Pzhax4lfh3//ckEIRqpyBwLyN1l8NQd6sY4WeVMEaInpstcHCyJ0LfiMnPiL
 Zx5S8OSzv/KCsS3i9uCFOkB7Gp8qdsJQgRbNO8SM+yxjgoLiOIWdEPO
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADP5589 is a 19 I/O port expander with built-in keypad matrix decoder,
programmable logic, reset generator, and PWM generator.

We can't really have adp5589 devices fallback to adp5585 (which have
less pins) because there are some significant differences in the register
map.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 .../devicetree/bindings/mfd/adi,adp5585.yaml       | 48 +++++++++++++++-------
 .../devicetree/bindings/trivial-devices.yaml       |  2 -
 2 files changed, 34 insertions(+), 16 deletions(-)

diff --git a/Documentation/devicetree/bindings/mfd/adi,adp5585.yaml b/Documentation/devicetree/bindings/mfd/adi,adp5585.yaml
index e30e22f964f78519b2ec207e9415e4897db5c702..87256a37b5f4b6a019f581b164c276d8805d2e52 100644
--- a/Documentation/devicetree/bindings/mfd/adi,adp5585.yaml
+++ b/Documentation/devicetree/bindings/mfd/adi,adp5585.yaml
@@ -15,14 +15,21 @@ description:
 
 properties:
   compatible:
-    items:
-      - enum:
-          - adi,adp5585-00  # Default
-          - adi,adp5585-01  # 11 GPIOs
-          - adi,adp5585-02  # No pull-up resistors by default on special pins
-          - adi,adp5585-03  # Alternate I2C address
-          - adi,adp5585-04  # Pull-down resistors on all pins by default
-      - const: adi,adp5585
+    oneOf:
+      - items:
+          - enum:
+              - adi,adp5585-00  # Default
+              - adi,adp5585-01  # 11 GPIOs
+              - adi,adp5585-02  # No pull-up resistors by default on special pins
+              - adi,adp5585-03  # Alternate I2C address
+              - adi,adp5585-04  # Pull-down resistors on all pins by default
+          - const: adi,adp5585
+      - items:
+          - enum:
+              - adi,adp5589-00  # Default
+              - adi,adp5589-01  # R4 defaulted to RESET1 output
+              - adi,adp5589-02  # Pull-down resistors by default on special pins
+          - const: adi,adp5589
 
   reg:
     maxItems: 1
@@ -63,13 +70,26 @@ allOf:
       properties:
         gpio-reserved-ranges: false
     else:
-      properties:
-        gpio-reserved-ranges:
-          maxItems: 1
-          items:
+      if:
+        properties:
+          compatible:
+            contains:
+              enum:
+                - adi,adp5585-00
+                - adi,adp5585-02
+                - adi,adp5585-03
+                - adi,adp5585-04
+      then:
+        properties:
+          gpio-reserved-ranges:
+            maxItems: 1
             items:
-              - const: 5
-              - const: 1
+              items:
+                - const: 5
+                - const: 1
+      else:
+        properties:
+          gpio-reserved-ranges: false
 
 additionalProperties: false
 
diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index fadbd3c041c8c39faedfe62874d4eba25a0bf30e..bdf0afb9301181b3f95fb7125302304834bdee94 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -39,8 +39,6 @@ properties:
           - ad,adm9240
             # AD5110 - Nonvolatile Digital Potentiometer
           - adi,ad5110
-            # Analog Devices ADP5589 Keypad Decoder and I/O Expansion
-          - adi,adp5589
             # Analog Devices LT7182S Dual Channel 6A, 20V PolyPhase Step-Down Silent Switcher
           - adi,lt7182s
             # AMS iAQ-Core VOC Sensor

-- 
2.48.1

