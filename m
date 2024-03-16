From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Sat, 16 Mar 2024 19:33:53 +0800
Subject: [PATCH v6 1/2] dt-bindings: dma: Add Loongson-1 DMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240316-loongson1-dma-v6-1-90de2c3cc928@gmail.com>
References: <20240316-loongson1-dma-v6-0-90de2c3cc928@gmail.com>
In-Reply-To: <20240316-loongson1-dma-v6-0-90de2c3cc928@gmail.com>
To: Keguang Zhang <keguang.zhang@gmail.com>, Vinod Koul <vkoul@kernel.org>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mips@vger.kernel.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710588849; l=2188;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=zE5CW4nW1JlxiVUlqwg3Ou+NzTgOjpf36TPsPJRMfcc=;
 b=6IHnL5oJofud1sZyiuybqQC/60Ow/y2P3LA6puHgIMw1fu2XcfQm9jX28FIMNmWzIjpRuQ6Xa
 Y4b9qZglbJkAQoK/4sQca6gkTSLSVZ7XIHHyHCvZeOoll6xTbEPODgL
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding document for Loongson-1 DMA.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
V5 -> V6:
   Change the compatible to the fallback
   Some minor fixes
V4 -> V5:
   A newly added patch
---
 .../devicetree/bindings/dma/loongson,ls1x-dma.yaml | 66 ++++++++++++++++++++++
 1 file changed, 66 insertions(+)

diff --git a/Documentation/devicetree/bindings/dma/loongson,ls1x-dma.yaml b/Documentation/devicetree/bindings/dma/loongson,ls1x-dma.yaml
new file mode 100644
index 000000000000..06358df725c6
--- /dev/null
+++ b/Documentation/devicetree/bindings/dma/loongson,ls1x-dma.yaml
@@ -0,0 +1,66 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/dma/loongson,ls1x-dma.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Loongson-1 DMA Controller
+
+maintainers:
+  - Keguang Zhang <keguang.zhang@gmail.com>
+
+description:
+  Loongson-1 DMA controller provides 3 independent channels for
+  peripherals such as NAND and AC97.
+
+properties:
+  compatible:
+    oneOf:
+      - const: loongson,ls1b-dma
+      - items:
+          - enum:
+              - loongson,ls1c-dma
+          - const: loongson,ls1b-dma
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    description: Each channel has a dedicated interrupt line.
+    minItems: 1
+    maxItems: 3
+
+  interrupt-names:
+    minItems: 1
+    items:
+      - pattern: ch0
+      - pattern: ch1
+      - pattern: ch2
+
+  '#dma-cells':
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - interrupt-names
+  - '#dma-cells'
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    dma-controller@1fd01160 {
+        compatible = "loongson,ls1b-dma";
+        reg = <0x1fd01160 0x4>;
+
+        interrupt-parent = <&intc0>;
+        interrupts = <13 IRQ_TYPE_EDGE_RISING>,
+                     <14 IRQ_TYPE_EDGE_RISING>,
+                     <15 IRQ_TYPE_EDGE_RISING>;
+        interrupt-names = "ch0", "ch1", "ch2";
+
+        #dma-cells = <1>;
+    };

-- 
2.40.1

