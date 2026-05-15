From: Jia Wang <wangjia@ultrarisc.com>
Date: Fri, 15 May 2026 09:18:00 +0800
Subject: [PATCH 4/9] dt-bindings: pinctrl: Add UltraRISC DP1000 pinctrl
 bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260515-ultrarisc-pinctrl-v1-4-bf559589ea8a@ultrarisc.com>
References: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
In-Reply-To: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778807890; l=8595;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=Ryby9hZuN7SHyXVlBdmHsw3fGds+h05WBF/9u3gnjj8=;
 b=1ms6oJVaXPuFMoEnClPMUvo6AV+r6jTiIXQ9zEWR4VHGoOAViGCJib+EFlvbUc0a5qin/9UDG
 rWr1XkxHvIgB4wag7aLpzeY/ac3tDhqhHQfvxVByu2v+/YuefwPrFcp
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the pin controllers on the UltraRISC DP1000 RISC-V SoC.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 .../bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml | 168 +++++++++++++++++++++
 MAINTAINERS                                        |   7 +
 .../dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h |  65 ++++++++
 3 files changed, 240 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
new file mode 100644
index 000000000000..c7ed1f96382a
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
@@ -0,0 +1,168 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/ultrarisc,dp1000-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: UltraRISC DP1000 Pin Controller
+maintainers:
+  - Jia Wang <wangjia@ultrarisc.com>
+
+description: |
+  UltraRISC RISC-V SoC DP1000 pin controller.
+
+  The binding supports two child node styles under the same controller
+  compatible:
+
+  - legacy DP1000-specific nodes using phandle-array properties
+    `pinctrl-pins` and `pinconf-pins`
+  - generic pinctrl nodes using `pins`, `function` and generic pin
+    configuration properties
+
+properties:
+  compatible:
+    const: ultrarisc,dp1000-pinctrl
+
+  reg:
+    maxItems: 1
+
+  "#pinctrl-cells":
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+patternProperties:
+  '.*-pins$':
+    type: object
+    allOf:
+      - $ref: /schemas/pinctrl/pincfg-node.yaml#
+      - $ref: /schemas/pinctrl/pinmux-node.yaml#
+    additionalProperties: false
+    properties:
+      pinctrl-pins:
+        description: |
+          The list of pins and their mux settings that properties in the node
+          apply to. The format: `PORT  PIN  FUNCTION`.
+        $ref: /schemas/types.yaml#/definitions/uint32-array
+        minItems: 1
+        maxItems: 32
+      pinconf-pins:
+        description: |
+          The list of pins and their pad configuration that properties in the
+          node apply to. The format: `PORT  PIN  CONF`.
+          CONF is a DP1000-specific encoding of pull and drive strength as
+          defined in dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h.
+        $ref: /schemas/types.yaml#/definitions/uint32-array
+        minItems: 1
+        maxItems: 32
+      pins:
+        description: List of pins affected by this state node.
+        minItems: 1
+        uniqueItems: true
+        items:
+          type: string
+          pattern: '^(PA([0-9]|1[0-5])|P[BCD][0-7]|LPC([0-9]|1[0-2]))$'
+
+      function:
+        description: |
+          Mux function to select for the listed pins.
+          gpio maps to the hardware default mode. The default mode is
+          GPIO for PA/PB/PC/PD pins and LPC for LPC pins.
+          func1 is not supported on LPC pins.
+        enum:
+          - gpio
+          - func0
+          - func1
+
+      bias-disable: true
+      bias-high-impedance: true
+      bias-pull-up: true
+      bias-pull-down: true
+
+      drive-strength:
+        description: Output drive strength in mA.
+        enum: [20, 27, 33, 40]
+
+    oneOf:
+      - allOf:
+          - anyOf:
+              - required: [pinctrl-pins]
+              - required: [pinconf-pins]
+          - not:
+              required: [pins]
+      - allOf:
+          - required: [pins]
+          - not:
+              anyOf:
+                - required: [pinctrl-pins]
+                - required: [pinconf-pins]
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      pinmux@11081000 {
+        compatible = "ultrarisc,dp1000-pinctrl";
+        reg = <0x0 0x11081000  0x0 0x1000>;
+        #pinctrl-cells = <2>;
+
+        i2c0-pins {
+          pins = "PA12", "PA13";
+          function = "func0";
+          bias-pull-up;
+          drive-strength = <33>;
+        };
+
+        uart0-pins {
+          pins = "PA8", "PA9";
+          function = "func1";
+          bias-pull-up;
+          drive-strength = <33>;
+        };
+      };
+    };
+
+  - |
+    /* Legacy example */
+    #include <dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h>
+
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      pinmux@11081000 {
+        compatible = "ultrarisc,dp1000-pinctrl";
+        reg = <0x0 0x11081000  0x0 0x1000>;
+        #pinctrl-cells = <2>;
+
+        i2c0-pins {
+          pinctrl-pins = <
+            UR_DP1000_IOMUX_A  12  UR_DP1000_FUNC0
+            UR_DP1000_IOMUX_A  13  UR_DP1000_FUNC0
+          >;
+
+          pinconf-pins = <
+            UR_DP1000_IOMUX_A  12  UR_DP1000_BIAS(UR_DP1000_PULL_UP,
+                                                  UR_DP1000_DRIVE_DEF)
+            UR_DP1000_IOMUX_A  13  UR_DP1000_BIAS(UR_DP1000_PULL_UP,
+                                                  UR_DP1000_DRIVE_DEF)
+          >;
+        };
+
+        uart0-pins {
+          pinctrl-pins = <
+            UR_DP1000_IOMUX_A  8  UR_DP1000_FUNC1
+            UR_DP1000_IOMUX_A  9  UR_DP1000_FUNC1
+          >;
+
+          pinconf-pins = <
+            UR_DP1000_IOMUX_A  8   UR_DP1000_BIAS(UR_DP1000_PULL_UP,
+                                                  UR_DP1000_DRIVE_DEF)
+            UR_DP1000_IOMUX_A  9   UR_DP1000_BIAS(UR_DP1000_PULL_UP,
+                                                  UR_DP1000_DRIVE_DEF)
+          >;
+        };
+      };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 5bf971ff48b2..baaaa46b1a56 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -27358,6 +27358,13 @@ S:	Maintained
 F:	drivers/usb/common/ulpi.c
 F:	include/linux/ulpi/
 
+ULTRARISC DP1000 PINCTRL DRIVER
+M:	Jia Wang <wangjia@ultrarisc.com>
+L:	linux-gpio@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
+F:	include/dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h
+
 ULTRATRONIK BOARD SUPPORT
 M:	Goran Rađenović <goran.radni@gmail.com>
 M:	Börge Strümpfel <boerge.struempfel@gmail.com>
diff --git a/include/dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h b/include/dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h
new file mode 100644
index 000000000000..bef28115898d
--- /dev/null
+++ b/include/dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h
@@ -0,0 +1,65 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * UltraRISC DP1000 pinctrl header.
+ *
+ * Copyright (C) 2026 UltraRISC Technology (Shanghai) Co., Ltd.
+ */
+
+#ifndef _DT_BINDINGS_PINCTRL_ULTRARISC_DP1000_PINCTRL_H
+#define _DT_BINDINGS_PINCTRL_ULTRARISC_DP1000_PINCTRL_H
+
+/**
+ * UltraRISC DP1000 IO pad configuration
+ * port: A, B, C, D, LPC
+ *     Pin in the port
+ * pin:
+ *     PA: 0 - 15
+ *     PB-PD: 0 - 7
+ *     LPC: 0 - 12
+ * func:
+ *     UR_DP1000_FUNC_DEF: default
+ *     UR_DP1000_FUNC0: func0
+ *     UR_DP1000_FUNC1: func1
+ */
+#define UR_DP1000_IOMUX_A		0x0
+#define UR_DP1000_IOMUX_B		0x1
+#define UR_DP1000_IOMUX_C		0x2
+#define UR_DP1000_IOMUX_D		0x3
+#define UR_DP1000_IOMUX_LPC		0x4
+
+#define UR_DP1000_FUNC_DEF		0
+#define UR_DP1000_FUNC0			1
+#define UR_DP1000_FUNC1			0x10000
+
+/**
+ * Configure pull up/down resistor of the IO pin
+ * UR_DP1000_PULL_DIS: disable pull-up and pull-down
+ * UR_DP1000_PULL_UP: enable pull-up
+ * UR_DP1000_PULL_DOWN: enable pull-down
+ */
+#define UR_DP1000_PULL_DIS	0
+#define UR_DP1000_PULL_UP	1
+#define UR_DP1000_PULL_DOWN	2
+/**
+ * Configure drive strength of the IO pin
+ * UR_DP1000_DRIVE_DEF: default value, reset value is 2
+ * UR_DP1000_DRIVE_0: 20mA
+ * UR_DP1000_DRIVE_1: 27mA
+ * UR_DP1000_DRIVE_2: 33mA
+ * UR_DP1000_DRIVE_3: 40mA
+ */
+#define UR_DP1000_DRIVE_DEF	2
+#define UR_DP1000_DRIVE_0	0
+#define UR_DP1000_DRIVE_1	1
+#define UR_DP1000_DRIVE_2	2
+#define UR_DP1000_DRIVE_3	3
+
+/**
+ * Combine the pull-up/down resistor and drive strength
+ * pull: UR_DP1000_PULL_DIS, UR_DP1000_PULL_UP, UR_DP1000_PULL_DOWN
+ * drive: UR_DP1000_DRIVE_DEF, UR_DP1000_DRIVE_0, UR_DP1000_DRIVE_1,
+ *        UR_DP1000_DRIVE_2, UR_DP1000_DRIVE_3
+ */
+#define UR_DP1000_BIAS(pull, drive)		(((pull) << 2) | (drive))
+
+#endif /* _DT_BINDINGS_PINCTRL_ULTRARISC_DP1000_PINCTRL_H */

-- 
2.34.1

