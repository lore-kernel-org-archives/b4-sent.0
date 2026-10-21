From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Date: Wed, 21 Oct 2026 19:56:23 +0000
Subject: [PATCH v2 1/2] dt-bindings: bus: Add Altera AXI Timeout Bridge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-feature-timeout-ip-v2-1-a037be089518@bruker.com>
References: <20261021-feature-timeout-ip-v2-0-a037be089518@bruker.com>
In-Reply-To: <20261021-feature-timeout-ip-v2-0-a037be089518@bruker.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792612593; l=2961;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=ngeh3x8lLAi1v/DII3EVjt3BSrPj52yBImEXu20kSEw=;
 b=HyOXa2GhxlJ2krK6XYIkhk/j5DYU723wAlA2JTIxbfnIig/htM2aMep77ChhfCq6VQPm4QTm2
 p6wimlVtQ5JDATHdfA7MQQqBq6xl6fXj2qf2GgeC/Y40cCHeoYUemh+
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Altera AXI Timeout Bridge is an FPGA IP core placed between an AXI
host, such as the HPS-to-FPGA bridge, and peripherals implemented in
the FPGA fabric. It forwards transactions unchanged and monitors each
one for completion. If a peripheral does not respond in time, the
bridge terminates the transaction with an error response so that the
host does not hang, raises an interrupt, and reports the address of
the timed-out transaction in its control and status registers.

Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
 .../bindings/bus/altr,axi-timeout-bridge-1.0.yaml  | 80 ++++++++++++++++++++++
 1 file changed, 80 insertions(+)

diff --git a/Documentation/devicetree/bindings/bus/altr,axi-timeout-bridge-1.0.yaml b/Documentation/devicetree/bindings/bus/altr,axi-timeout-bridge-1.0.yaml
new file mode 100644
index 000000000000..3512494442d4
--- /dev/null
+++ b/Documentation/devicetree/bindings/bus/altr,axi-timeout-bridge-1.0.yaml
@@ -0,0 +1,80 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/bus/altr,axi-timeout-bridge-1.0.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Altera AXI Timeout Bridge
+
+maintainers:
+  - Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
+
+description: |
+  The Altera AXI Timeout Bridge is an FPGA soft IP placed between an AXI
+  host, such as the HPS-to-FPGA bridge, and the downstream peripherals
+  implemented in the FPGA fabric. It forwards transactions unchanged and
+  monitors each one for completion.
+
+  If a downstream peripheral does not respond within a configured number
+  of clock cycles, the bridge terminates the outstanding transaction with
+  an error response so that the host does not hang,
+  and raises an interrupt.
+
+properties:
+  compatible:
+    const: altr,axi-timeout-bridge-1.0
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  ranges: true
+
+  "#address-cells":
+    const: 1
+
+  "#size-cells":
+    const: 1
+
+patternProperties:
+  "^[a-zA-Z][a-zA-Z0-9,+._-]*@[0-9a-f]+$":
+    type: object
+    description: |
+      Device connected to the timeout bridge.
+
+    required:
+      - compatible
+      - reg
+
+    additionalProperties: true
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - ranges
+  - "#address-cells"
+  - "#size-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    timeout-bridge@10000 {
+        compatible = "altr,axi-timeout-bridge-1.0";
+        #address-cells = <1>;
+        #size-cells = <1>;
+
+        reg = <0x10000 0x10>;
+        interrupts = <0 12 IRQ_TYPE_LEVEL_HIGH>;
+        ranges = <0x0 0x10010 0x1000>;
+
+        timeout-device@100 {
+            compatible = "timeout-device";
+            reg = <0x100 0x10>;
+        };
+    };

-- 
2.34.1

