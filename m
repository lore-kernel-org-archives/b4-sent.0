From: Junyi Zhao <junyi.zhao@amlogic.com>
Date: Mon, 19 Oct 2026 13:34:27 +0800
Subject: [PATCH 2/3] dt-bindings: i3c: Add Amlogic A9 I3C controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-a9_i3c-v1-2-329d819d621f@amlogic.com>
References: <20261019-a9_i3c-v1-0-329d819d621f@amlogic.com>
In-Reply-To: <20261019-a9_i3c-v1-0-329d819d621f@amlogic.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-i3c@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, imx@lists.linux.dev, 
 linux-hardening@vger.kernel.org, xianwei.zhao@amlogic.com, 
 Kelvin.Zhang@amlogic.com, Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792388075; l=2990;
 i=junyi.zhao@amlogic.com; s=20260924; h=from:subject:message-id;
 bh=TBTUobdGBphIyuXd0LiPQLPuirtquJsAagN7tB4GVFk=;
 b=FQzwECiEVC4Sh2/3SId2SPXHjsgKXTeAMF04+38WwljJbpDkzhX1U7JvEvgVR9VWQQ333MhDA
 6vKe+i6wcuRBUtietraOkYp97rgRhfCQbs2bCrVJD775Mf4MMGddFOp
X-Developer-Key: i=junyi.zhao@amlogic.com; a=ed25519;
 pk=hiL5PjGIksGFiWvEx9J3MhQqU/ro6vNbj72NIw4bbvA=
X-Endpoint-Received: by B4 Relay for junyi.zhao@amlogic.com/20260924 with auth_id=1054
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a devicetree binding schema for the A9 I3C controller.

The binding describes the controller instance and its bus-specific
properties required for driver probing.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
---
 .../devicetree/bindings/i3c/amlogic,i3c-a9.yaml    | 102 +++++++++++++++++++++
 1 file changed, 102 insertions(+)

diff --git a/Documentation/devicetree/bindings/i3c/amlogic,i3c-a9.yaml b/Documentation/devicetree/bindings/i3c/amlogic,i3c-a9.yaml
new file mode 100644
index 000000000..8e25122c6
--- /dev/null
+++ b/Documentation/devicetree/bindings/i3c/amlogic,i3c-a9.yaml
@@ -0,0 +1,102 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2026 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/i3c/amlogic,i3c-a9.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic A9 I3C master controller
+
+maintainers:
+  - Junyi Zhao <junyi.zhao@amlogic.com>
+
+description:
+  The Amlogic A9 SoC family embeds an I3C master controller based on the
+  Silvaco I3C Dual-Role Master IP, with Amlogic specific glue logic.
+
+allOf:
+  - $ref: /schemas/i3c/i3c.yaml#
+
+properties:
+  compatible:
+    enum:
+      - amlogic,i3c-a9
+      - amlogic,i3c-ao-a9
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    minItems: 1
+    maxItems: 2
+
+  clock-names:
+    minItems: 1
+    maxItems: 2
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - clock-names
+
+unevaluatedProperties: false
+
+if:
+  properties:
+    compatible:
+      const: amlogic,i3c-a9
+then:
+  properties:
+    clocks:
+      items:
+        - description: APB peripheral clock
+        - description: I3C fast clock
+    clock-names:
+      items:
+        - const: pclk
+        - const: fast_clk
+else:
+  properties:
+    clocks:
+      maxItems: 1
+    clock-names:
+      items:
+        - const: fast_clk
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    i3c@3a7000 {
+        compatible = "amlogic,i3c-a9";
+        reg = <0x3a7000 0x10000>;
+        interrupts = <GIC_SPI 153 IRQ_TYPE_LEVEL_HIGH>;
+        #address-cells = <3>;
+        #size-cells = <0>;
+        clocks = <&clkc 15>,
+                 <&clkc 16>;
+        clock-names = "pclk", "fast_clk";
+        status = "disabled";
+    };
+
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    i3c@22000 {
+        compatible = "amlogic,i3c-ao-a9";
+        reg = <0x22000 0x10000>;
+        interrupts = <GIC_SPI 72 IRQ_TYPE_LEVEL_HIGH>;
+        #address-cells = <3>;
+        #size-cells = <0>;
+        clocks = <&clkc 17>;
+        clock-names = "fast_clk";
+        status = "disabled";
+    };
+...

-- 
2.42.0

