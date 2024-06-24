From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 24 Jun 2024 23:25:12 +0200
Subject: [PATCH v5 1/3] dt-bindings: leds: Add Silergy SY7802 flash LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240624-sy7802-v5-1-7abc9d96bfa6@apitzsch.eu>
References: <20240624-sy7802-v5-0-7abc9d96bfa6@apitzsch.eu>
In-Reply-To: <20240624-sy7802-v5-0-7abc9d96bfa6@apitzsch.eu>
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>, 
 Trilok Soni <quic_tsoni@quicinc.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, Kees Cook <kees@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719264314; l=2858;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=422MAQ8Zc9rOtjrkcDNrU+gTouN3Oof9bf0EyTO505k=;
 b=kPJWmXeldK97qQkM+tolXro4Vm6iC38kA9MXEcTiypyoYjTBP0Kf1CjDn45WaBvs97fue9o37
 +btwCE0m8dYCixMUibGf1kv3NQ9jwu9ijIqvkoe51Yj+Ci/WBpbcLJQ
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document Silergy SY7802 flash LED driver devicetree bindings.

Reviewed-by: Rob Herring <robh@kernel.org>
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
2.45.2

