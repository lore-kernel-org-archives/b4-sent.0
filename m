From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 02 Oct 2024 16:10:45 +0800
Subject: [PATCH v10 1/2] dt-bindings: mtd: Add Loongson-1 NAND Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241002-loongson1-nand-v10-1-17162eff80e2@gmail.com>
References: <20241002-loongson1-nand-v10-0-17162eff80e2@gmail.com>
In-Reply-To: <20241002-loongson1-nand-v10-0-17162eff80e2@gmail.com>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-media@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727856656; l=2914;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=ijmjreV0PHp6NKGPauLRqbwAJA1s+bytYg7cJBivIQE=;
 b=jUvDcnOrTZH8FMfischBNLDPJG79OGkwDGwzEV8b+WoE863Tqjjd/O2Oaz/gK1rEKNC2zhCU9
 jLBbcj8tWWbBlATbAfymyp63YgU6nnfGKhaDDiJyAbwZT2f4wEOIV41
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding document for Loongson-1 NAND controller.

Reviewed-by: Krzysztof Kozlowski <krzk@kernel.org>
Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
Changes in v10:
- None

Changes in v9:
- Change the compatible to 'loongson,ls1*-nand-controller'.
- Rename the file to loongson,ls1b-nand-controller.yaml
- Some minor adjustments.

Changes in v8:
- Add a description part.
- Adjust the compatible because the match data for ls1c-nfc differs from ls1b-nfc.
- Mark 'nand-use-soft-ecc-engine' and 'nand-ecc-algo' as mandatory.
- Delete the superfluous blank lines.

Changes in v7:
- rename the file to loongson,ls1b-nfc.yaml

Changes in v6:
- A newly added patch
---
 .../mtd/loongson,ls1b-nand-controller.yaml         | 75 ++++++++++++++++++++++
 1 file changed, 75 insertions(+)

diff --git a/Documentation/devicetree/bindings/mtd/loongson,ls1b-nand-controller.yaml b/Documentation/devicetree/bindings/mtd/loongson,ls1b-nand-controller.yaml
new file mode 100644
index 000000000000..308baf23221b
--- /dev/null
+++ b/Documentation/devicetree/bindings/mtd/loongson,ls1b-nand-controller.yaml
@@ -0,0 +1,75 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mtd/loongson,ls1b-nand-controller.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Loongson-1 NAND Controller
+
+maintainers:
+  - Keguang Zhang <keguang.zhang@gmail.com>
+
+description:
+  The Loongson-1 NAND controller abstracts all supported operations,
+  meaning it does not support low-level access to raw NAND flash chips.
+  Moreover, the controller is paired with the DMA engine to perform
+  READ and PROGRAM functions.
+
+allOf:
+  - $ref: nand-controller.yaml
+
+properties:
+  compatible:
+    oneOf:
+      - enum:
+          - loongson,ls1b-nand-controller
+          - loongson,ls1c-nand-controller
+      - items:
+          - enum:
+              - loongson,ls1a-nand-controller
+          - const: loongson,ls1b-nand-controller
+
+  reg:
+    maxItems: 1
+
+  dmas:
+    maxItems: 1
+
+  dma-names:
+    const: rxtx
+
+patternProperties:
+  "^nand@[0-3]$":
+    type: object
+    $ref: raw-nand-chip.yaml
+
+    required:
+      - nand-use-soft-ecc-engine
+      - nand-ecc-algo
+
+    unevaluatedProperties: false
+
+required:
+  - compatible
+  - reg
+  - dmas
+  - dma-names
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    nand-controller@1fe78000 {
+        compatible = "loongson,ls1b-nand-controller";
+        reg = <0x1fe78000 0x40>;
+        dmas = <&dma 0>;
+        dma-names = "rxtx";
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        nand@0 {
+            reg = <0>;
+            nand-use-soft-ecc-engine;
+            nand-ecc-algo = "hamming";
+        };
+    };

-- 
2.43.0

