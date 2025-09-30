From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 30 Sep 2025 17:37:15 +0800
Subject: [PATCH 02/19] dt-bindings: clock: Add Amlogic A4 PLL clock
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250930-a4_a5_add_clock_driver-v1-2-a9acf7951589@amlogic.com>
References: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
In-Reply-To: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759225047; l=2798;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=Ft6yNqo0TZ3QMKb3Jm5Wur9+935/1unmm660KRVPRPE=;
 b=2dpRYtAPCMjQbgEd7EMDfUTMrfRTEis8Y4GdAn4NjLc4KD01/8j89KXgL4Txe0Cy3rKTBvv3o
 eLsPuSQ6X+GBUiNTGLkXxVH9r6bIYzfxMxgIszPdqOkuCly5YWFwrHs
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PLL clock controller dt-bindings for Amlogic A4 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 .../bindings/clock/amlogic,a4-pll-clkc.yaml        | 61 ++++++++++++++++++++++
 include/dt-bindings/clock/amlogic,a4-pll-clkc.h    | 15 ++++++
 2 files changed, 76 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,a4-pll-clkc.yaml b/Documentation/devicetree/bindings/clock/amlogic,a4-pll-clkc.yaml
new file mode 100644
index 000000000000..dafad7bd4407
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/amlogic,a4-pll-clkc.yaml
@@ -0,0 +1,61 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2025 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/amlogic,a4-pll-clkc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic A4 series PLL Clock Controller
+
+maintainers:
+  - Neil Armstrong <neil.armstrong@linaro.org>
+  - Jerome Brunet <jbrunet@baylibre.com>
+  - Chuan Liu <chuan.liu@amlogic.com>
+  - Xianwei Zhao <xianwei.zhao@amlogic.com>
+
+properties:
+  compatible:
+    const: amlogic,a4-pll-clkc
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: input oscillator
+      - description: input fix pll
+
+  clock-names:
+    items:
+      - const: xtal
+      - const: fix
+
+  "#clock-cells":
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - "#clock-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/amlogic,a4-scmi-clkc.h>
+    apb {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        clock-controller@8000 {
+            compatible = "amlogic,a4-pll-clkc";
+            reg = <0x0 0x8000 0x0 0x110>;
+            clocks = <&xtal>,
+                     <&scmi_clk CLKID_FIXED_PLL>;
+            clock-names = "xtal",
+                          "fix";
+            #clock-cells = <1>;
+        };
+    };
diff --git a/include/dt-bindings/clock/amlogic,a4-pll-clkc.h b/include/dt-bindings/clock/amlogic,a4-pll-clkc.h
new file mode 100644
index 000000000000..0950dcd68e0a
--- /dev/null
+++ b/include/dt-bindings/clock/amlogic,a4-pll-clkc.h
@@ -0,0 +1,15 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2025 Amlogic, Inc. All rights reserved.
+ * Author: Chuan Liu <chuan.liu@amlogic.com>
+ */
+
+#ifndef _DT_BINDINGS_CLOCK_AMLOGIC_A4_PLL_CLKC_H
+#define _DT_BINDINGS_CLOCK_AMLOGIC_A4_PLL_CLKC_H
+
+#define CLKID_GP0_PLL_DCO			0
+#define CLKID_GP0_PLL				1
+#define CLKID_HIFI_PLL_DCO			2
+#define CLKID_HIFI_PLL				3
+
+#endif  /* _DT_BINDINGS_CLOCK_AMLOGIC_A4_PLL_CLKC_H */

-- 
2.42.0

