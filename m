From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 09 Feb 2026 13:48:48 +0800
Subject: [PATCH 02/13] dt-bindings: clock: Add Amlogic A9 PLL controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-a9_clock_driver-v1-2-a9198dc03d2a@amlogic.com>
References: <20260209-a9_clock_driver-v1-0-a9198dc03d2a@amlogic.com>
In-Reply-To: <20260209-a9_clock_driver-v1-0-a9198dc03d2a@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770616142; l=5717;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=LyZ6UBT9Q6k7Fn7bjq6bnz37qzqmph54nv7OuWBpCck=;
 b=E1k8Q3OfqeBhGrzZfdznUd4MgKjLxFwgQJabHnnj2VIppvftGQ3dgu/guCoIoj6/G7cr+J5Dh
 7+ocHR9fbibAqs4W++QyVU3wQHBA/zfIMByCSAL2MooWJS8sllZozlK
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add dt-binding documentation for PLL controllers used in A9 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 .../devicetree/bindings/clock/amlogic,a9-pll.yaml  | 134 +++++++++++++++++++++
 1 file changed, 134 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,a9-pll.yaml b/Documentation/devicetree/bindings/clock/amlogic,a9-pll.yaml
new file mode 100644
index 000000000000..26655716f040
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/amlogic,a9-pll.yaml
@@ -0,0 +1,134 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2026 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/amlogic,a9-pll.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic A9 Family PLL Controllers
+
+maintainers:
+  - Chuan Liu <chuan.liu@amlogic.com>
+
+description: |
+  PLLs generate high-frequency clocks by frequency multiplication, feeding them
+  into the clock tree where they can be configured as operational clocks for
+  various system modules.
+
+  A diagram of the A9 PLL is as follows:
+         +------------------------------------------------------+
+         |      +-------+      +-----+                          |
+    osc-------->| div N |----->|     |   +-----+                |
+         |      +-------+      |     |   |     |                |
+         |                     |     |   | VCO |   +--------+   |
+         |                     |     |-->|  /  |-->| div OD |------>pll_out
+         |                     |     |   | DCO |   +--------+   |
+         |      +----------+   |     |   |     |                |
+         |  +-->| M & frac |-->|     |   +-----+                |
+         |  |   +----------+   +-----+      |                   |
+         |  |                               |                   |
+         |  +-------------------------------+                   |
+         +------------------------------------------------------+
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - const: amlogic,a9-int-pll
+        description: Integer multiplier PLL
+      - items:
+          - const: amlogic,a9-frac-pll
+        description: Fractional multiplier PLL
+      - items:
+          - const: amlogic,a9-frac-step-pll
+        description: Fractional PLL with integer step granularity
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+    description: input clock of pll
+
+  clock-output-names:
+    maxItems: 1
+
+  '#clock-cells':
+    const: 0
+
+  amlogic,clock-max-frequency:
+    description: |
+      Each clock's maximum output frequency is constrained during hardware
+      design to ensure proper timing requirements for the clock network. If the
+      clock frequency configured exceeds this design limit, it can lead to
+      abnormal behavior in modules relying on that clock and may even cause
+      cross-talk that affects other modules.
+
+      In the driver, this property is parsed, and interface functions from the
+      CCF are called to enforce the clock's maximum frequency, preventing
+      potential issues caused by excessive clock frequency configurations.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+
+  amlogic,clock-init-regs:
+    description:
+      Certain CCUs and PLLs require initialization through dedicated registers
+      before becoming operational. This initialization configures internal clock
+      drive characteristics, divider parameters, and PLL internal circuitry.
+    $ref: /schemas/types.yaml#/definitions/uint32-matrix
+    items:
+      items:
+        - description: The register offset address
+        - description: The value to be written to the register
+        - description: The delay after the register write (unit is us)
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-output-names
+  - "#clock-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    apb {
+        #address-cells = <2>;
+        #size-cells = <2>;
+        clock-mclk_pll@8330 {
+            compatible = "amlogic,a9-int-pll";
+            reg = <0x0 0x8330 0x0 0xc>;
+            #clock-cells = <0>;
+            amlogic,clock-init-regs = <0x4  0x00402000 0>,
+                                      <0x8  0x60000100 0>;
+            amlogic,clock-max-frequency = <2800000000>;
+            clock-output-names = "mclk_pll";
+            clocks = <&xtal_24m>;
+        };
+
+        clock-gp0_pll@8200 {
+            compatible = "amlogic,a9-frac-pll";
+            reg = <0x0 0x8200 0x0 0x10>;
+            #clock-cells = <0>;
+            amlogic,clock-init-regs = <0x0  0x08010000 0>,
+                                      <0x4  0x11480000 0>,
+                                      <0x8  0x1219b010 0>,
+                                      <0xc  0x00008010 0>;
+            amlogic,clock-max-frequency = <2800000000>;
+            clock-output-names = "gp0_pll";
+            clocks = <&xtal_24m>;
+        };
+
+        clock-hifi_pll@8280 {
+            compatible = "amlogic,a9-frac-step-pll";
+            reg = <0x0 0x8280 0x0 0x10>;
+            #clock-cells = <0>;
+            amlogic,clock-init-regs = <0x0  0x08010000 0>,
+                                      <0x4  0x11480000 0>,
+                                      <0x8  0x1219b010 0>,
+                                      <0xc  0x00008010 0>;
+            amlogic,clock-max-frequency = <2800000000>;
+            clock-output-names = "hifi_pll";
+            clocks = <&xtal_24m>;
+        };
+    };

-- 
2.42.0

