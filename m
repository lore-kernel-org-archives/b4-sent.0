From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 16 Dec 2025 08:03:17 +0000
Subject: [PATCH 1/3] dt-bindings: dma: Add Amlogic general DMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251216-amlogic-dma-v1-1-e289e57e96a7@amlogic.com>
References: <20251216-amlogic-dma-v1-0-e289e57e96a7@amlogic.com>
In-Reply-To: <20251216-amlogic-dma-v1-0-e289e57e96a7@amlogic.com>
To: Vinod Koul <vkoul@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765872198; l=2309;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=YtNRhQ7yOxGHI4OflJLoTQNj1t3FJEpqV/TcNs/qfSA=;
 b=XpNQNJ5Pk6DQgEgq8PAeCMnzEndlKbIEJtJ9zf+fGqwPN8DH/boK5LsAvSrASIYm4jjkWFm+d
 sQSF4mpzF76Af5+idnocEoqsSblm27jw0/CW4/tWBOsIciDiUmgfmBQ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation describing the Amlogic general DMA.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/dma/amlogic,general-dma.yaml          | 70 ++++++++++++++++++++++
 1 file changed, 70 insertions(+)

diff --git a/Documentation/devicetree/bindings/dma/amlogic,general-dma.yaml b/Documentation/devicetree/bindings/dma/amlogic,general-dma.yaml
new file mode 100644
index 000000000000..8b9cec9b8da0
--- /dev/null
+++ b/Documentation/devicetree/bindings/dma/amlogic,general-dma.yaml
@@ -0,0 +1,70 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/dma/amlogic,general-dma.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic general DMA controller
+
+description: |
+  This is a general-purpose peripheral DMA controller. It currently supports
+  major peripherals including I2C, I3C, PIO, and CAN-BUS. Transmit and receive
+  for the same peripheral use two separate channels, controlled by different
+  register sets. I2C and I3C transfer data in 1-byte units, while PIO and
+  CAN-BUS transfer data in 4-byte units. From the controller’s perspective,
+  there is no significant difference.
+
+maintainers:
+  - Xianwei Zhao <xianwei.zhao@amlogic.com>
+
+properties:
+  compatible:
+    const: amlogic,general-dma
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+
+  clock-names:
+    const: sys
+
+  '#dma-cells':
+    const: 2
+
+  dma-channels:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    maximum: 64
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - '#dma-cells'
+  - dma-channels
+
+allOf:
+  - $ref: dma-controller.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    apb {
+        #address-cells = <2>;
+        #size-cells = <2>;
+        dma-controller@fe400000{
+            compatible = "amlogic,general-dma";
+            reg = <0x0 0xfe400000 0x0 0x4000>;
+            interrupts = <GIC_SPI 35 IRQ_TYPE_EDGE_RISING>;
+            clocks = <&clkc 45>;
+            #dma-cells = <2>;
+            dma-channels = <28>;
+        };
+    };

-- 
2.52.0

