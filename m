From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 04 Jun 2025 15:40:51 +0800
Subject: [PATCH 1/3] dt-bindings: spi: Add binding document of Amlogic
 SPISG controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250604-spisg-v1-1-5893dbe9d953@amlogic.com>
References: <20250604-spisg-v1-0-5893dbe9d953@amlogic.com>
In-Reply-To: <20250604-spisg-v1-0-5893dbe9d953@amlogic.com>
To: Sunny Luo <sunny.luo@amlogic.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749022851; l=1826;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=JpIA8EXgX4qGdcEsZY4R8K9pmoEKnmQU577yskBQ4WM=;
 b=WU0+PjqZQ/YG3zcsD8IQTOQXyB0iue0WTGEdFfz/pwvDZorVTn0IbaEYldYwpEZemlC5h/eNM
 FKk2xjt93mJBvihUKpic4zerxQ1YFa9LjXaqt/T1TFF4OxnjcAQBvKI
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sunny Luo <sunny.luo@amlogic.com>

The SPISG is a new communication oriented SPI controller of Amlogic, which
supports PIO, block DMA and scatter-gather DMA three operation modes.

Signed-off-by: Sunny Luo <sunny.luo@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/spi/amlogic,a4-spisg.yaml  | 55 ++++++++++++++++++++++
 1 file changed, 55 insertions(+)

diff --git a/Documentation/devicetree/bindings/spi/amlogic,a4-spisg.yaml b/Documentation/devicetree/bindings/spi/amlogic,a4-spisg.yaml
new file mode 100644
index 000000000000..8d4d4606ff48
--- /dev/null
+++ b/Documentation/devicetree/bindings/spi/amlogic,a4-spisg.yaml
@@ -0,0 +1,55 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2025 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/spi/amlogic,a4-spisg.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic SPI Scatter-Gather Controller
+
+maintainers:
+  - Xianwei Zhao <xianwei.zhao@amlogic.com>
+  - Sunny Luo <sunny.luo@amlogic.com>
+
+allOf:
+  - $ref: spi-controller.yaml#
+
+properties:
+  compatible:
+    const: amlogic,a4-spisg
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    minItems: 2
+
+  clock-names:
+    items:
+      - const: core
+      - const: pclk
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - clock-names
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    spi@50000 {
+        compatible = "amlogic,a4-spisg";
+        reg = <0x50000 0x38>;
+        interrupts = <0 183 4>;
+        clocks = <&clkc 37>,
+                 <&clkc 93>;
+        clock-names = "core", "pclk";
+        #address-cells = <1>;
+        #size-cells = <0>;
+    };

-- 
2.37.1

