From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:41:38 +0300
Subject: [PATCH 1/3] dt-bindings: mtd: Add Cortina CS7542 NAND controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-nand-v1-1-7ce179c011e2@gmail.com>
References: <20261123-b4-cs7542-nand-v1-0-7ce179c011e2@gmail.com>
In-Reply-To: <20261123-b4-cs7542-nand-v1-0-7ce179c011e2@gmail.com>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mtd@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459297; l=2237;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=R4f5+AZ20ZvVDHkrykvH4nwddcpdeFmF1zCSrzBHxh8=;
 b=bfHq8In5jdLo/dunT0UnO+Berlv962onqZZJnPFXMiVqyAFPk+hEUZm0R+b7I2/4SP/E82iWM
 kwSK+k2RImTANU86YaMZ/NEGC2VMQezGEuSDrVfrnttey2FTzaCx63W
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the flash register bank and the single 8-bit NAND target used
on CS7542. Specify the ROM-compatible Hamming ECC configuration and
allow standard NAND partition descriptions. Firmware supplies the bus
timing.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/mtd/cortina,cs7542-nand.yaml          | 66 ++++++++++++++++++++++
 1 file changed, 66 insertions(+)

diff --git a/Documentation/devicetree/bindings/mtd/cortina,cs7542-nand.yaml b/Documentation/devicetree/bindings/mtd/cortina,cs7542-nand.yaml
new file mode 100644
index 000000000..c9ab9d4d9
--- /dev/null
+++ b/Documentation/devicetree/bindings/mtd/cortina,cs7542-nand.yaml
@@ -0,0 +1,66 @@
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
+  The flash controller supports programmed I/O transfers and a hardware
+  Hamming ECC engine. Firmware initializes the NAND bus timing.
+
+allOf:
+  - $ref: nand-controller.yaml#
+
+properties:
+  compatible:
+    const: cortina,cs7542-nand
+
+  reg:
+    maxItems: 1
+
+patternProperties:
+  "^nand@[0-9a-f]$":
+    type: object
+    $ref: raw-nand-chip.yaml#
+    properties:
+      reg:
+        const: 0
+      nand-bus-width:
+        const: 8
+      nand-ecc-mode:
+        const: hw
+      nand-ecc-algo:
+        const: hamming
+      nand-ecc-step-size:
+        const: 256
+      nand-ecc-strength:
+        const: 1
+    unevaluatedProperties: false
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    nand-controller@f0050000 {
+        compatible = "cortina,cs7542-nand";
+        reg = <0xf0050000 0x300>;
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

