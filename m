From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 27 Feb 2026 07:20:53 +0000
Subject: [PATCH v4 1/3] dt-bindings: dma: Add Amlogic A9 SoC DMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260227-amlogic-dma-v4-1-f25e4614e9b7@amlogic.com>
References: <20260227-amlogic-dma-v4-0-f25e4614e9b7@amlogic.com>
In-Reply-To: <20260227-amlogic-dma-v4-0-f25e4614e9b7@amlogic.com>
To: Vinod Koul <vkoul@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772176854; l=2714;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=kAPLFHoe2A7SVw2vXJTjrGauMsdYZiEvifE22xpjjBo=;
 b=yX2kd6NWfUScjoGpltvYYUcwtCcpiMw2C1VdfpjjA01frK3bCd9gn8zxl94ebazsSzxovYqDI
 O7D27TXGZDQD/gvIuHYER7G5LbLL77iE/qQ/bWuiZPfh81uQIjPKaa4
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation describing the Amlogic A9 SoC DMA. And add
the properties specific values defines into a new include file.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/dma/amlogic,a9-dma.yaml    | 65 ++++++++++++++++++++++
 include/dt-bindings/dma/amlogic-dma.h              |  8 +++
 2 files changed, 73 insertions(+)

diff --git a/Documentation/devicetree/bindings/dma/amlogic,a9-dma.yaml b/Documentation/devicetree/bindings/dma/amlogic,a9-dma.yaml
new file mode 100644
index 000000000000..efd7b2602c33
--- /dev/null
+++ b/Documentation/devicetree/bindings/dma/amlogic,a9-dma.yaml
@@ -0,0 +1,65 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/dma/amlogic,a9-dma.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic general DMA controller
+
+description:
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
+    const: amlogic,a9-dma
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
+    dma-controller@fe400000{
+        compatible = "amlogic,a9-dma";
+        reg = <0xfe400000 0x4000>;
+        interrupts = <GIC_SPI 35 IRQ_TYPE_EDGE_RISING>;
+        clocks = <&clkc 45>;
+        #dma-cells = <2>;
+        dma-channels = <28>;
+    };
diff --git a/include/dt-bindings/dma/amlogic-dma.h b/include/dt-bindings/dma/amlogic-dma.h
new file mode 100644
index 000000000000..025ecc42e395
--- /dev/null
+++ b/include/dt-bindings/dma/amlogic-dma.h
@@ -0,0 +1,8 @@
+/* SPDX-License-Identifier: (GPL-2.0 OR MIT) */
+
+#ifndef __DT_BINDINGS_DMA_AMLOGIC_DMA_H__
+#define __DT_BINDINGS_DMA_AMLOGIC_DMA_H__
+
+#define AML_DMA_TYPE_TX		0
+#define AML_DMA_TYPE_RX		1
+#endif /* __DT_BINDINGS_DMA_AMLOGIC_DMA_H__ */

-- 
2.52.0

