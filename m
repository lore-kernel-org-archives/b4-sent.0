From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 01 Apr 2024 23:23:55 +0200
Subject: [PATCH v2 1/3] dt-bindings: leds: Add Silergy SY7802 flash LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240401-sy7802-v2-1-1138190a7448@apitzsch.eu>
References: <20240401-sy7802-v2-0-1138190a7448@apitzsch.eu>
In-Reply-To: <20240401-sy7802-v2-0-1138190a7448@apitzsch.eu>
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <keescook@chromium.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712006653; l=2814;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=oNM0ya5oNykHINhTxOzzwyy/jcGSPZfyaMMYcdcGZWM=;
 b=/zydaTt+SHiXn+Dz5Npbr9hbi+pY9nvC43lHAbEZ0Se1tEy3tq9tO3IEqw7t0L0NlSLMPaDBH
 VR8GP458pcGA0DNm8DZSKO7NAs+3Ga5Z2m+bn0SUCYbI/+j1EZPYtEz
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document Silergy SY7802 flash LED driver devicetree bindings.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 .../devicetree/bindings/leds/silergy,sy7802.yaml   | 100 +++++++++++++++++++++
 1 file changed, 100 insertions(+)

diff --git a/Documentation/devicetree/bindings/leds/silergy,sy7802.yaml b/Documentation/devicetree/bindings/leds/silergy,sy7802.yaml
new file mode 100644
index 000000000000..46b8e5452b62
--- /dev/null
+++ b/Documentation/devicetree/bindings/leds/silergy,sy7802.yaml
@@ -0,0 +1,100 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/leds/silergy,sy7802.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Silergy SY7802 1800mA Boost Charge Pump LED Driver
+
+maintainers:
+  - André Apitzsch <git@apitzsch.eu>
+
+description: |
+  The SY7802 is a current-regulated charge pump which can regulate two current
+  levels for Flash and Torch modes.
+
+  The SY7802 is a high-current synchronous boost converter with 2-channel
+  high side current sources. Each channel is able to deliver 900mA current.
+
+properties:
+  compatible:
+    enum:
+      - silergy,sy7802
+
+  reg:
+    maxItems: 1
+
+  enable-gpios:
+    maxItems: 1
+    description: A connection to the 'EN' pin.
+
+  flash-gpios:
+    maxItems: 1
+    description: A connection to the 'FLEN' pin.
+
+  vin-supply:
+    description: Regulator providing power to the 'VIN' pin.
+
+  "#address-cells":
+    const: 1
+
+  "#size-cells":
+    const: 0
+
+patternProperties:
+  "^led@[0-1]$":
+    type: object
+    $ref: common.yaml#
+    unevaluatedProperties: false
+
+    properties:
+      reg:
+        description: Index of the LED.
+        minimum: 0
+        maximum: 1
+
+      led-sources:
+        minItems: 1
+        maxItems: 2
+        items:
+          minimum: 0
+          maximum: 1
+
+    required:
+      - reg
+      - led-sources
+
+required:
+  - compatible
+  - reg
+  - "#address-cells"
+  - "#size-cells"
+  - enable-gpios
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/leds/common.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        flash-led-controller@53 {
+            compatible = "silergy,sy7802";
+            reg = <0x53>;
+            #address-cells = <1>;
+            #size-cells = <0>;
+
+            enable-gpios = <&tlmm 16 GPIO_ACTIVE_HIGH>;
+
+            led@0 {
+                reg = <0>;
+                function = LED_FUNCTION_FLASH;
+                color = <LED_COLOR_ID_WHITE>;
+                led-sources = <0>, <1>;
+            };
+        };
+    };

-- 
2.44.0

