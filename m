From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Fri, 29 Mar 2024 19:26:57 +0800
Subject: [PATCH v7 1/2] dt-bindings: dma: Add Loongson-1 APB DMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240329-loongson1-dma-v7-1-37db58608de5@gmail.com>
References: <20240329-loongson1-dma-v7-0-37db58608de5@gmail.com>
In-Reply-To: <20240329-loongson1-dma-v7-0-37db58608de5@gmail.com>
To: Keguang Zhang <keguang.zhang@gmail.com>, Vinod Koul <vkoul@kernel.org>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Huacai Chen <chenhuacai@kernel.org>
Cc: linux-mips@vger.kernel.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711711676; l=2565;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=ds4wTZorT6jaeeqOkLe7QSlyOemDGAMPint8d9K/rWA=;
 b=q+CsL+tMdnTSWeaHeNWmgWjCfvAW5THz6sQKOfdzuxpuhjiYucwPLUqSrDi159SZwrcUn4ADD
 7MGf/pWDMpSCGKVMJ2MRcDgy1hP67+ZTIzfg9Bh3a0k/PslY5V5RmTu
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding document for Loongson-1 APB DMA.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
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
index 000000000000..449da9fc2de1
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
+    description: Each channel has a dedicated interrupt line.
+    maxItems: 3
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

