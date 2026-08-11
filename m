From: Ben Zong-You Xie <ben717@andestech.com>
Date: Tue, 11 Aug 2026 14:29:48 +0800
Subject: [PATCH v5 1/4] dt-bindings: i2c: add support for AE350 I2C
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-atciic100-v5-1-1d306c21dba3@andestech.com>
References: <20260811-atciic100-v5-0-1d306c21dba3@andestech.com>
In-Reply-To: <20260811-atciic100-v5-0-1d306c21dba3@andestech.com>
To: Andi Shyti <andi.shyti@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-i2c@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Ben Zong-You Xie <ben717@andestech.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15-dev-09770
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786429789; l=2147;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=bq3xzDJ/OIuUwfBkMViZX6pvpmLXUhLZ07QGmtn5ZDY=;
 b=jLQ0aV2x15w7MTRX/V+ERzbSHB3sC2BMYjnGoGn5kladTHrDAZW/eeYb/kKShILU4286x9sVH
 CWF2HlU6y4FAD3ercY0Q8wV70E6dKPeNlqeQjQI4vFtub8gJpQgiIcv
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document device tree bindings for the I2C controller on Andes AE350
platform.

The ATCIIC100 is a dedicated I2C controller IP developed by
Andes Technology. This IP block is a core component of the Andes
AE350 platform, which serves as a reference architecture for SoC
designs. The QiLai SoC also integrates this I2C controller.

The binding introduces the following compatible strings:
- "andestech,qilai-i2c": For the implementation integrated into the
  Andes QiLai SoC.
- "andestech,ae350-i2c": As a fallback compatible string representing
  the base IP design used across the AE350 platform architecture.

Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
---
 .../bindings/i2c/andestech,ae350-i2c.yaml          | 45 ++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/Documentation/devicetree/bindings/i2c/andestech,ae350-i2c.yaml b/Documentation/devicetree/bindings/i2c/andestech,ae350-i2c.yaml
new file mode 100644
index 000000000000..59a521fb249b
--- /dev/null
+++ b/Documentation/devicetree/bindings/i2c/andestech,ae350-i2c.yaml
@@ -0,0 +1,45 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/i2c/andestech,ae350-i2c.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Andes I2C controller on AE350 platform
+
+maintainers:
+  - Ben Zong-You Xie <ben717@andestech.com>
+
+allOf:
+  - $ref: /schemas/i2c/i2c-controller.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - andestech,qilai-i2c
+          - const: andestech,ae350-i2c
+      - const: andestech,ae350-i2c
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - interrupts
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c@f0a00000 {
+        compatible = "andestech,ae350-i2c";
+        reg = <0xf0a00000 0x100000>;
+        interrupts = <6 IRQ_TYPE_LEVEL_HIGH>;
+    };

-- 
2.34.1

