From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Date: Sat, 03 Oct 2026 20:19:19 +0000
Subject: [PATCH 1/2] dt-bindings: bus: Add binding for Altera AXI Timeout
 Bridge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-feature-timeout-ip-v1-1-8837c311d571@bruker.com>
References: <20261003-feature-timeout-ip-v1-0-8837c311d571@bruker.com>
In-Reply-To: <20261003-feature-timeout-ip-v1-0-8837c311d571@bruker.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>, 
 Vyacheslav Yurkov <uvv.mail@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791058772; l=2392;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=hyHA3ZNQrL78Zg2YOSELcUPMZWCWSUYAq0Hsjp/nUOM=;
 b=cvf/Id9QP8pU/4/tX392HduDdEsbDnEUv5FyrtPGTdMHLSWTuRPvL3JOOLYMpFiGFVRipEEuM
 4K6X/pLNpSpD1M+Rp1vFE4gjZO4cLvJKxYfKpAf+mwg5DEJyCoyLJPP
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree binding for the Altera timeout bridge, which connects
an Avalon bus to the HPS and provides an address space for child
devices with a fall back to a simple bus.

Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
 .../bindings/bus/altera-timeout-bridge.yaml        | 82 ++++++++++++++++++++++
 1 file changed, 82 insertions(+)

diff --git a/Documentation/devicetree/bindings/bus/altera-timeout-bridge.yaml b/Documentation/devicetree/bindings/bus/altera-timeout-bridge.yaml
new file mode 100644
index 000000000000..b57a0966ba6e
--- /dev/null
+++ b/Documentation/devicetree/bindings/bus/altera-timeout-bridge.yaml
@@ -0,0 +1,82 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/bus/altera-timeout-bridge.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Altera Timeout Bridge
+
+maintainers:
+  - Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
+
+description: |
+  Altera timeout bridge bus.
+
+properties:
+  compatible:
+    items:
+      - const: altera-timeout-bridge
+      - const: simple-bus
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
+required:
+  - compatible
+  - reg
+  - interrupts
+  - interrupt-parent
+  - ranges
+  - "#address-cells"
+  - "#size-cells"
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
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    intc: interrupt-controller {
+        interrupt-controller;
+        #interrupt-cells = <3>;
+    };
+
+    timeout_bridge_hps@10000 {
+        compatible = "altera-timeout-bridge", "simple-bus";
+        #address-cells = <1>;
+        #size-cells = <1>;
+
+        reg = <0x10000 0xF>;
+
+        interrupts = <0 12 IRQ_TYPE_LEVEL_HIGH>;
+        interrupt-parent = <&intc>;
+
+        ranges = <0x0 0x10010 0x1000>;
+
+        timeout-device@100 {
+            compatible = "timeout-device";
+            reg = <0x100 0x10>;
+        };
+    };

-- 
2.34.1

