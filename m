From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Fri, 09 Aug 2024 18:30:58 +0800
Subject: [PATCH v12 1/2] dt-bindings: dma: Add Loongson-1 APB DMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240809-loongson1-dma-v12-1-d9469a4a6b85@gmail.com>
References: <20240809-loongson1-dma-v12-0-d9469a4a6b85@gmail.com>
In-Reply-To: <20240809-loongson1-dma-v12-0-d9469a4a6b85@gmail.com>
To: Keguang Zhang <keguang.zhang@gmail.com>, Vinod Koul <vkoul@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mips@vger.kernel.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723199495; l=2956;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=Qluc1iegek8oFl5BI6efzejkT7cwfkm/k1sNIM1vwVk=;
 b=j0LpAHtEhGJvjoDOlIzz0H2cWoMIncGIDOFguiLYp13a2aIaAFisy2/j/+I9KjPcSIQEF08eW
 P+dfNKRODgGCPrZfHTAUQrsnIJGBXojT24l9Kxd8EMhfzH2KQ7GOaVZ
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding document for Loongson-1 APB DMA.

Reviewed-by: Conor Dooley <conor.dooley@microchip.com>
Reviewed-by: Jiaxun Yang <jiaxun.yang@flygoat.com>
Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
Changes in v12:
- Delete superfluous blank lines in the examples section.

Changes in v11:
- None

Changes in v10:
- None

Changes in v9:
- None

Changes in v8:
- Change 'interrupts' property to an items list

Changes in v7:
- Change the comptible to 'loongson,ls1*-apbdma' (suggested by Huacai Chen)
- Update the title and description part accordingly
- Rename the file to loongson,ls1b-apbdma.yaml
- Add a compatible string for LS1A
- Delete minItems of 'interrupts'
- Change patterns of 'interrupt-names' to const

Changes in v6:
- Change the compatible to the fallback
- Some minor fixes

Changes in v5:
- A newly added patch
---
 .../bindings/dma/loongson,ls1b-apbdma.yaml         | 65 ++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/Documentation/devicetree/bindings/dma/loongson,ls1b-apbdma.yaml b/Documentation/devicetree/bindings/dma/loongson,ls1b-apbdma.yaml
new file mode 100644
index 000000000000..4c7d2fb7b292
--- /dev/null
+++ b/Documentation/devicetree/bindings/dma/loongson,ls1b-apbdma.yaml
@@ -0,0 +1,65 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/dma/loongson,ls1b-apbdma.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Loongson-1 APB DMA Controller
+
+maintainers:
+  - Keguang Zhang <keguang.zhang@gmail.com>
+
+description:
+  Loongson-1 APB DMA controller provides 3 independent channels for
+  peripherals such as NAND, audio playback and capture.
+
+properties:
+  compatible:
+    oneOf:
+      - const: loongson,ls1b-apbdma
+      - items:
+          - enum:
+              - loongson,ls1a-apbdma
+              - loongson,ls1c-apbdma
+          - const: loongson,ls1b-apbdma
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    items:
+      - description: NAND interrupt
+      - description: Audio playback interrupt
+      - description: Audio capture interrupt
+
+  interrupt-names:
+    items:
+      - const: ch0
+      - const: ch1
+      - const: ch2
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
+        compatible = "loongson,ls1b-apbdma";
+        reg = <0x1fd01160 0x4>;
+        interrupt-parent = <&intc0>;
+        interrupts = <13 IRQ_TYPE_EDGE_RISING>,
+                     <14 IRQ_TYPE_EDGE_RISING>,
+                     <15 IRQ_TYPE_EDGE_RISING>;
+        interrupt-names = "ch0", "ch1", "ch2";
+        #dma-cells = <1>;
+    };

-- 
2.43.0

