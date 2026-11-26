From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Thu, 26 Nov 2026 15:45:27 +0300
Subject: [PATCH v4 1/3] dt-bindings: mtd: Add Cortina CS7542 NAND
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-b4-cs7542-nand-v4-1-38e488f6f8b1@gmail.com>
References: <20261126-b4-cs7542-nand-v4-0-38e488f6f8b1@gmail.com>
In-Reply-To: <20261126-b4-cs7542-nand-v4-0-38e488f6f8b1@gmail.com>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-mtd@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795697127; l=3294;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=0qXWSMESZjG+Rrjv+OyLzyU3xQh2VijD/dbwXnwp4EU=;
 b=6Xh007pP+0rd3BhzNs8CxzXOIzhKTw55L6h1HFjQJ0aVw7ilbZ7Np1dNQLfgAofC2AjR+7EE5
 l5OoepbX0OoBivjd1PnsGTKpS3LlBLJLZ6p9YXCGpzX8xNjZ8tn7CD7
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the flash controller registers, optional banked data aperture,
AXI bus clock, flash interrupt and shared flash reset. The controller has
two chip selects, 8/16-bit bus support and Hamming/BCH hardware, rather
than only the configuration supported by the initial driver.

Inherit the standard NAND chip ECC properties. The example explicitly
selects the ROM-compatible 256-byte Hamming layout used on Almond+.
Firmware initializes the NAND bus timing.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/mtd/cortina,cs7542-nand.yaml          | 90 ++++++++++++++++++++++
 1 file changed, 90 insertions(+)

diff --git a/Documentation/devicetree/bindings/mtd/cortina,cs7542-nand.yaml b/Documentation/devicetree/bindings/mtd/cortina,cs7542-nand.yaml
new file mode 100644
index 000000000..3b7fdf6ee
--- /dev/null
+++ b/Documentation/devicetree/bindings/mtd/cortina,cs7542-nand.yaml
@@ -0,0 +1,90 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mtd/cortina,cs7542-nand.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 NAND controller
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+description:
+  The flash controller has two NAND chip selects and supports 8-bit and
+  16-bit devices, programmed I/O, hardware Hamming ECC with 256-byte or
+  512-byte steps, and hardware BCH ECC. It is on the AXI peripheral bus.
+  The data aperture selects a bank through the controller registers.
+  The flash controller also has access to the shared SSP DMA engine;
+  the programmed-I/O interface does not require that DMA resource.
+  Firmware initializes the NAND bus timing.
+
+allOf:
+  - $ref: nand-controller.yaml#
+
+properties:
+  compatible:
+    const: cortina,cs7542-nand
+
+  reg:
+    minItems: 1
+    items:
+      - description: Flash controller registers
+      - description: Banked NAND data aperture
+
+  reg-names:
+    minItems: 1
+    items:
+      - const: regs
+      - const: data
+
+  clocks:
+    maxItems: 1
+    description: AXI bus clock
+
+  interrupts:
+    maxItems: 1
+    description: Flash controller interrupt
+
+  resets:
+    maxItems: 1
+    description: Shared flash controller reset
+
+patternProperties:
+  "^nand@[01]$":
+    type: object
+    $ref: raw-nand-chip.yaml#
+    properties:
+      reg:
+        minimum: 0
+        maximum: 1
+    unevaluatedProperties: false
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
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    nand-controller@f0050000 {
+        compatible = "cortina,cs7542-nand";
+        reg = <0xf0050000 0x300>, <0xe0000000 0x08000000>;
+        reg-names = "regs", "data";
+        clocks = <&axi_clk>;
+        interrupts = <GIC_SPI 18 IRQ_TYPE_LEVEL_HIGH>;
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        nand@0 {
+            reg = <0>;
+            nand-ecc-mode = "hw";
+            nand-ecc-algo = "hamming";
+            nand-ecc-step-size = <256>;
+            nand-ecc-strength = <1>;
+        };
+    };

-- 
2.53.0

