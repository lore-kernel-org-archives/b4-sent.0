From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 22 Jan 2025 11:25:59 +0800
Subject: [PATCH v4 1/5] dt-bindings: pinctrl: Add support for Amlogic SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250122-amlogic-pinctrl-v4-1-4677b2e18ff1@amlogic.com>
References: <20250122-amlogic-pinctrl-v4-0-4677b2e18ff1@amlogic.com>
In-Reply-To: <20250122-amlogic-pinctrl-v4-0-4677b2e18ff1@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737516363; l=5292;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=HdgH/AVc3E8C6N6sa1PmqNxStg/Z5uY8xSOuzrxAGuE=;
 b=JVjplooFTkPDAoieu317+HJT1AosOah0Eiqq9kk0yXkM2UEl226HBRzwpmNzuRVLvWutRQrHP
 I1Enjmx6/7iBfIBENHW7+Z4a3Sk9WnvNiMqOmMQ4vy074Tnm+FqBqdL
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the dt-bindings for Amlogic pin controller, and add a new
dt-binding header file which document the GPIO bank names of
all Amlogic subsequent SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       | 127 +++++++++++++++++++++
 include/dt-bindings/pinctrl/amlogic,pinctrl.h      |  46 ++++++++
 2 files changed, 173 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
new file mode 100644
index 000000000000..c4fdcd69bbf5
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
@@ -0,0 +1,127 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/amlogic,pinctrl-a4.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic pinmux controller
+
+maintainers:
+  - Xianwei Zhao <xianwei.zhao@amlogic.com>
+
+allOf:
+  - $ref: pinctrl.yaml#
+
+properties:
+  compatible:
+    const: amlogic,pinctrl-a4
+
+  "#address-cells":
+    const: 2
+
+  "#size-cells":
+    const: 2
+
+  ranges: true
+
+patternProperties:
+  "^gpio@[0-9a-f]+$":
+    type: object
+
+    properties:
+      reg:
+        minItems: 1
+        items:
+          - description: pin config register
+          - description: pin mux setting register (some special pin fixed function)
+          - description: pin drive strength register (optional)
+
+      reg-names:
+        minItems: 1
+        items:
+          - const: gpio
+          - const: mux
+          - const: ds
+
+      gpio-controller: true
+
+      "#gpio-cells":
+        const: 2
+
+      gpio-ranges:
+        maxItems: 1
+
+    required:
+      - reg
+      - reg-names
+      - gpio-controller
+      - "#gpio-cells"
+      - gpio-ranges
+
+    additionalProperties: false
+
+  "^func-[0-9a-z-]+$":
+    type: object
+    patternProperties:
+      "^group-[0-9a-z-]+$":
+        type: object
+        allOf:
+          - $ref: /schemas/pinctrl/pincfg-node.yaml
+          - $ref: /schemas/pinctrl/pinmux-node.yaml
+
+        required:
+          - pinmux
+    additionalProperties: false
+
+required:
+  - compatible
+  - "#address-cells"
+  - "#size-cells"
+  - ranges
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/pinctrl/amlogic,pinctrl.h>
+    apb {
+      #address-cells = <2>;
+      #size-cells = <2>;
+      periphs_pinctrl: pinctrl {
+        compatible = "amlogic,pinctrl-a4";
+        #address-cells = <2>;
+        #size-cells = <2>;
+        ranges;
+
+        gpio@14 {
+          reg = <0 0x14 0 0x10>, <0 0x14 0 0x10>;
+          reg-names = "gpio", "mux";
+          gpio-controller;
+          #gpio-cells = <2>;
+          gpio-ranges = <&periphs_pinctrl 0 8 10>;
+        };
+
+        func-uart-b {
+          group-default {
+            pinmux = <AML_PINMUX(AMLOGIC_GPIO_B, 1, 4)>;
+            bias-pull-up;
+            drive-strength-microamp = <4000>;
+          };
+
+          group-pins1 {
+            pinmux = <AML_PINMUX(AMLOGIC_GPIO_B, 5, 2)>;
+            bias-pull-up;
+            drive-strength-microamp = <4000>;
+          };
+        };
+
+        func-uart-c {
+          group-default {
+            pinmux = <AML_PINMUX(AMLOGIC_GPIO_B, 3, 1)>,
+                     <AML_PINMUX(AMLOGIC_GPIO_B, 2, 1)>;
+            bias-pull-up;
+            drive-strength-microamp = <4000>;
+          };
+        };
+      };
+    };
diff --git a/include/dt-bindings/pinctrl/amlogic,pinctrl.h b/include/dt-bindings/pinctrl/amlogic,pinctrl.h
new file mode 100644
index 000000000000..7d40aecc7147
--- /dev/null
+++ b/include/dt-bindings/pinctrl/amlogic,pinctrl.h
@@ -0,0 +1,46 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2024 Amlogic, Inc. All rights reserved.
+ * Author: Xianwei Zhao <xianwei.zhao@amlogic.com>
+ */
+
+#ifndef _DT_BINDINGS_AMLOGIC_PINCTRL_H
+#define _DT_BINDINGS_AMLOGIC_PINCTRL_H
+/* Normal PIN bank */
+#define AMLOGIC_GPIO_A		0
+#define AMLOGIC_GPIO_B		1
+#define AMLOGIC_GPIO_C		2
+#define AMLOGIC_GPIO_D		3
+#define AMLOGIC_GPIO_E		4
+#define AMLOGIC_GPIO_F		5
+#define AMLOGIC_GPIO_G		6
+#define AMLOGIC_GPIO_H		7
+#define AMLOGIC_GPIO_I		8
+#define AMLOGIC_GPIO_J		9
+#define AMLOGIC_GPIO_K		10
+#define AMLOGIC_GPIO_L		11
+#define AMLOGIC_GPIO_M		12
+#define AMLOGIC_GPIO_N		13
+#define AMLOGIC_GPIO_O		14
+#define AMLOGIC_GPIO_P		15
+#define AMLOGIC_GPIO_Q		16
+#define AMLOGIC_GPIO_R		17
+#define AMLOGIC_GPIO_S		18
+#define AMLOGIC_GPIO_T		19
+#define AMLOGIC_GPIO_U		20
+#define AMLOGIC_GPIO_V		21
+#define AMLOGIC_GPIO_W		22
+#define AMLOGIC_GPIO_X		23
+#define AMLOGIC_GPIO_Y		24
+#define AMLOGIC_GPIO_Z		25
+
+/* Special PIN bank */
+#define AMLOGIC_GPIO_DV		26
+#define AMLOGIC_GPIO_AO		27
+#define AMLOGIC_GPIO_CC		28
+#define AMLOGIC_GPIO_TEST_N	29
+#define AMLOGIC_GPIO_ANALOG	30
+
+#define AML_PINMUX(bank, offset, mode)	(((((bank) << 8) + (offset)) << 8) | (mode))
+
+#endif /* _DT_BINDINGS_AMLOGIC_PINCTRL_H */

-- 
2.37.1

