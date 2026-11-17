From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 17 Nov 2026 23:29:23 +0300
Subject: [PATCH v4 1/2] dt-bindings: interrupt-controller: Add Cortina
 Systems CS7542 peripheral interrupt controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-cs75xx-intc-v4-1-0a678f35e5f3@gmail.com>
References: <20261117-cs75xx-intc-v4-0-0a678f35e5f3@gmail.com>
In-Reply-To: <20261117-cs75xx-intc-v4-0-0a678f35e5f3@gmail.com>
To: Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794947362; l=2389;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=m01hcJJ8xuXAEtFmd0R1Lw/ptpQwdip1II1Pbh1M174=;
 b=a08qu7Da3/pmTatk0TPaP2A+BvY8F15Gznd80NAfJMa45L2Mk6+ka5FIYIOj3kqn7jTlPElov
 gNuO2M2J1bCDD9hrbr2fpkVL3IB5MrOrq17a5YaQhPs0E0cXX6TkrFM
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The low speed peripherals of the Cortina Systems CS75xx SoCs share one
GIC interrupt. A small controller in the peripheral register block
reports which of its 15 sources are asserted and allows masking them.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../interrupt-controller/cortina,cs7542-intc.yaml  | 57 ++++++++++++++++++++++
 1 file changed, 57 insertions(+)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/cortina,cs7542-intc.yaml b/Documentation/devicetree/bindings/interrupt-controller/cortina,cs7542-intc.yaml
new file mode 100644
index 000000000..2963acaf7
--- /dev/null
+++ b/Documentation/devicetree/bindings/interrupt-controller/cortina,cs7542-intc.yaml
@@ -0,0 +1,57 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/interrupt-controller/cortina,cs7542-intc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 peripheral interrupt controller
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+description:
+  The low speed peripherals of the Cortina Systems CS75xx (Goldengate G2)
+  SoCs (two software interrupts, two timers, the AXI bridge, SPI, the five
+  GPIO banks, I2C, MDIO, SSP and the random number generator) share one GIC
+  interrupt. This controller has a status register showing the level of the
+  15 sources and an enable register to mask them. The sources are cleared in
+  the peripherals themselves.
+
+properties:
+  compatible:
+    const: cortina,cs7542-intc
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  interrupt-controller: true
+
+  "#interrupt-cells":
+    const: 1
+    description:
+      The number of the source, 0 to 14. All sources are active high level
+      interrupts.
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - interrupt-controller
+  - "#interrupt-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    interrupt-controller@f0070004 {
+        compatible = "cortina,cs7542-intc";
+        reg = <0xf0070004 0x8>;
+        interrupts = <GIC_SPI 3 IRQ_TYPE_LEVEL_HIGH>;
+        interrupt-controller;
+        #interrupt-cells = <1>;
+    };

-- 
2.53.0

