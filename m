From: Jian Hu <jian.hu@amlogic.com>
Date: Mon, 11 May 2026 20:47:24 +0800
Subject: [PATCH 02/10] dt-bindings: clock: Add Amlogic A9 PLL clock
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-b4-a9_clk-v1-2-41cb4071b7c9@amlogic.com>
References: <20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com>
In-Reply-To: <20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778503655; l=4908;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=Dw8+4rmGWhvklI0IY1bbxEsDvxGe4eMGmJlQnz5m84Y=;
 b=ogxseIgSy3HtgVEp/52GBBk8CaS6blwg0OHeB60EnMhfT8H4FyIVBPtYGOCeE9i5zc3QM/Ial
 GukT4dDtT98C7/VQHgf+rAJoxoEiCh5jXrc+cR6SC3fMfn69d6baAVM
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PLL clock controller dt-bindings for the Amlogic A9 SoC family.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 .../bindings/clock/amlogic,a9-pll-clkc.yaml        | 110 +++++++++++++++++++++
 include/dt-bindings/clock/amlogic,a9-pll-clkc.h    |  55 +++++++++++
 2 files changed, 165 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,a9-pll-clkc.yaml b/Documentation/devicetree/bindings/clock/amlogic,a9-pll-clkc.yaml
new file mode 100644
index 000000000000..4ee6013ba1a1
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/amlogic,a9-pll-clkc.yaml
@@ -0,0 +1,110 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2026 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/amlogic,a9-pll-clkc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic A9 Series PLL Clock Controller
+
+maintainers:
+  - Neil Armstrong <neil.armstrong@linaro.org>
+  - Jerome Brunet <jbrunet@baylibre.com>
+  - Jian Hu <jian.hu@amlogic.com>
+  - Xianwei Zhao <xianwei.zhao@amlogic.com>
+
+properties:
+  compatible:
+    enum:
+      - amlogic,a9-gp0-pll
+      - amlogic,a9-hifi0-pll
+      - amlogic,a9-hifi1-pll
+      - amlogic,a9-mclk0-pll
+      - amlogic,a9-mclk1-pll
+
+  reg:
+    maxItems: 1
+
+  '#clock-cells':
+    const: 1
+
+  clocks:
+    items:
+      - description: pll input oscillator gate
+      - description: fixed input clock source for mclk_sel_0
+      - description: u3p2pll input clock source for mclk_sel_0 (optional)
+    minItems: 1
+
+  clock-names:
+    items:
+      - const: in0
+      - const: in1
+      - const: in2
+    minItems: 1
+
+required:
+  - compatible
+  - '#clock-cells'
+  - reg
+  - clocks
+  - clock-names
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - amlogic,a9-mclk0-pll
+              - amlogic,a9-mclk1-pll
+
+    then:
+      properties:
+        clocks:
+          maxItems: 3
+
+        clock-names:
+          maxItems: 3
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - amlogic,a9-gp0-pll
+              - amlogic,a9-hifi0-pll
+              - amlogic,a9-hifi1-pll
+
+    then:
+      properties:
+        clocks:
+          maxItems: 1
+
+        clock-names:
+          maxItems: 1
+
+additionalProperties: false
+
+examples:
+  - |
+    apb4 {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        clock-controller@8200 {
+            compatible = "amlogic,a9-gp0-pll";
+            reg = <0x0 0x8200 0x0 0x20>;
+            #clock-cells = <1>;
+            clocks = <&scmi_clk 0>;
+            clock-names = "in0";
+        };
+
+        clock-controller@8330 {
+            compatible = "amlogic,a9-mclk0-pll";
+            reg = <0x0 0x8330 0x0 0x14>;
+            #clock-cells = <1>;
+            clocks = <&scmi_clk 4>,
+                     <&scmi_clk 8>;
+            clock-names = "in0", "in1";
+        };
+    };
diff --git a/include/dt-bindings/clock/amlogic,a9-pll-clkc.h b/include/dt-bindings/clock/amlogic,a9-pll-clkc.h
new file mode 100644
index 000000000000..31edb0bc95e7
--- /dev/null
+++ b/include/dt-bindings/clock/amlogic,a9-pll-clkc.h
@@ -0,0 +1,55 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (C) 2026 Amlogic, Inc. All rights reserved.
+ */
+
+#ifndef __AMLOGIC_A9_PLL_CLKC_H
+#define __AMLOGIC_A9_PLL_CLKC_H
+
+/* GP0 */
+#define CLKID_GP0_IN_DIV2_DIV		0
+#define CLKID_GP0_IN_DIV2		1
+#define CLKID_GP0_PLL_DCO		2
+#define CLKID_GP0_PLL			3
+
+/* HIFI0 */
+#define CLKID_HIFI0_IN_DIV2_DIV		0
+#define CLKID_HIFI0_IN_DIV2		1
+#define CLKID_HIFI0_PLL_DCO		2
+#define CLKID_HIFI0_PLL			3
+
+/* HIFI1 */
+#define CLKID_HIFI1_IN_DIV2_DIV		0
+#define CLKID_HIFI1_IN_DIV2		1
+#define CLKID_HIFI1_PLL_DCO		2
+#define CLKID_HIFI1_PLL			3
+
+/* MCLK0 */
+#define CLKID_MCLK0_IN_DIV2		0
+#define CLKID_MCLK0_PLL_DCO		1
+#define CLKID_MCLK0_0_PLL		2
+#define CLKID_MCLK0_0_PRE		3
+#define CLKID_MCLK0_0_SEL		4
+#define CLKID_MCLK0_0_DIV		5
+#define CLKID_MCLK0_0			6
+#define CLKID_MCLK0_1_PLL		7
+#define CLKID_MCLK0_1_PRE		8
+#define CLKID_MCLK0_1_SEL		9
+#define CLKID_MCLK0_1_DIV		10
+#define CLKID_MCLK0_1			11
+
+/* MCLK1 */
+#define CLKID_MCLK1_IN_DIV2		0
+#define CLKID_MCLK1_PLL_DCO		1
+#define CLKID_MCLK1_0_PLL		2
+#define CLKID_MCLK1_0_PRE		3
+#define CLKID_MCLK1_0_SEL		4
+#define CLKID_MCLK1_0_DIV		5
+#define CLKID_MCLK1_0			6
+#define CLKID_MCLK1_1_PLL		7
+#define CLKID_MCLK1_1_PRE		8
+#define CLKID_MCLK1_1_SEL		9
+#define CLKID_MCLK1_1_DIV		10
+#define CLKID_MCLK1_1			11
+
+#endif  /* __AMLOGIC_A9_PLL_CLKC_H */

-- 
2.47.1

