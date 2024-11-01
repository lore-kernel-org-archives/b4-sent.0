From: Janne Grunau <j@jannau.net>
Date: Fri, 01 Nov 2024 15:25:03 +0100
Subject: [PATCH v2 1/3] dt-bindings: spi: apple,spi: Add binding for Apple
 SPI controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241101-asahi-spi-v2-1-763a8a84d834@jannau.net>
References: <20241101-asahi-spi-v2-0-763a8a84d834@jannau.net>
In-Reply-To: <20241101-asahi-spi-v2-0-763a8a84d834@jannau.net>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2079; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=/RFcpEoBMNWg7lClrxLf6RcMZcKkYFii4Yno81onXTg=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnSVJ2eqaw7b7b0V2myXWnAmeqbrv0Ole50l0tc99d39a
 fOvw5FHOkpZGMS4GGTFFFmStF92MKyuUYypfRAGM4eVCWQIAxenAEwkTZ6RYYmA1bKPOavc2p1D
 22ub5t2c8n7uwlvXTDetrM3pU8yKeM3wh2fHlIV3lTyOyvrW/egU3rGE9cb2eyJLvm5+JMXjwvB
 Vmh0A
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

The Apple SPI controller is present in SoCs such as the M1 (t8103) and
M1 Pro/Max (t600x). This controller uses one IRQ and one clock, and
doesn't need any special properties, so the binding is trivial.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 .../devicetree/bindings/spi/apple,spi.yaml         | 62 ++++++++++++++++++++++
 1 file changed, 62 insertions(+)

diff --git a/Documentation/devicetree/bindings/spi/apple,spi.yaml b/Documentation/devicetree/bindings/spi/apple,spi.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..0f280370cca9d82ce7ce72da53a144b257f7bdc2
--- /dev/null
+++ b/Documentation/devicetree/bindings/spi/apple,spi.yaml
@@ -0,0 +1,62 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/spi/apple,spi.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple ARM SoC SPI controller
+
+allOf:
+  - $ref: "spi-controller.yaml#"
+
+maintainers:
+  - Hector Martin <marcan@marcan.st>
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - apple,t8103-spi
+          - apple,t8112-spi
+          - apple,t6000-spi
+      - const: apple,spi
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  power-domains:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - interrupts
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/apple-aic.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      spi: spi@39b104000 {
+        compatible = "apple,t6000-spi", "apple,spi";
+        reg = <0x3 0x9b104000 0x0 0x4000>;
+        interrupt-parent = <&aic>;
+        interrupts = <AIC_IRQ 0 1107 IRQ_TYPE_LEVEL_HIGH>;
+        #address-cells = <1>;
+        #size-cells = <0>;
+        clocks = <&clk>;
+      };
+    };

-- 
2.47.0

