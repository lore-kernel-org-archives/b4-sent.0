From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 20 Feb 2025 18:29:23 +0100
Subject: [PATCH 3/3] dt-bindings: net: Convert fsl,gianfar to YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250220-gianfar-yaml-v1-3-0ba97fd1ef92@posteo.net>
References: <20250220-gianfar-yaml-v1-0-0ba97fd1ef92@posteo.net>
In-Reply-To: <20250220-gianfar-yaml-v1-0-0ba97fd1ef92@posteo.net>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Claudiu Manoil <claudiu.manoil@nxp.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740072564; l=9350;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=ym26/SjLOnhoBKNuOxw8M0QAUvBoR1fxquz9fbgUWwo=;
 b=oII80F8Gqfj3/3k3n+VGpeb5MH8UMOldjMTHB1ZJQyqiGepcBv8S1vLOvE163s+of9aJNSUmB
 E1Hsw4DeYVDA3007Gja/rGavCosPRv9SEcS/Lq58o63P/VcdgGkNFfw
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a binding for the "Gianfar" ethernet controller, also known as
TSEC/eTSEC.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 .../devicetree/bindings/net/fsl,gianfar.yaml       | 242 +++++++++++++++++++++
 .../devicetree/bindings/net/fsl-tsec-phy.txt       |  39 +---
 2 files changed, 243 insertions(+), 38 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/fsl,gianfar.yaml b/Documentation/devicetree/bindings/net/fsl,gianfar.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..dc75ceb5dc6fdee8765bb17273f394d01cce0710
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/fsl,gianfar.yaml
@@ -0,0 +1,242 @@
+# SPDX-License-Identifier: GPL-2.0
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/fsl,gianfar.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale Three-Speed Ethernet Controller (TSEC), "Gianfar"
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+properties:
+  compatible:
+    enum:
+      - gianfar
+      - fsl,etsec2
+
+  device_type:
+    const: network
+
+  model:
+    enum:
+      - FEC
+      - TSEC
+      - eTSEC
+
+  reg:
+    maxItems: 1
+
+  ranges: true
+
+  "#address-cells": true
+
+  "#size-cells": true
+
+  cell-index:
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  interrupts:
+    maxItems: 3
+
+  dma-coherent:
+    type: boolean
+
+  fsl,magic-packet:
+    $ref: /schemas/types.yaml#/definitions/flag
+    description:
+      If present, indicates that the hardware supports waking up via magic packet.
+
+  fsl,wake-on-filer:
+    type: boolean
+    description:
+      If present, indicates that the hardware supports waking up by Filer
+      General Purpose Interrupt (FGPI) asserted on the Rx int line. This is
+      an advanced power management capability allowing certain packet types
+      (user) defined by filer rules to wake up the system.
+
+  bd-stash:
+    type: boolean
+    description:
+      If present, indicates that the hardware supports stashing buffer
+      descriptors in the L2.
+
+  rx-stash-len:
+    type: boolean
+    description:
+      Denotes the number of bytes of a received buffer to stash in the L2.
+
+  tx-stash-len:
+    type: boolean
+    description:
+      Denotes the index of the first byte from the received buffer to stash in
+      the L2.
+
+  fsl,num_rx_queues:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Number of receive queues
+
+  fsl,num_tx_queues:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Number of transmit queues
+
+  tbi-handle:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description: Reference (phandle) to the TBI node
+
+required:
+  - compatible
+  - model
+
+patternProperties:
+  "^mdio@[0-9a-f]+$":
+    type: object
+    # TODO: reference to gianfar MDIO binding
+
+allOf:
+  - $ref: ethernet-controller.yaml#
+
+  # compatible = "gianfar" requires device_type = "network"
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: gianfar
+    then:
+      required:
+        - device_type
+
+  # eTSEC2 controller nodes have "queue group" subnodes and don't need a "reg"
+  # property.
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: fsl,etsec2
+    then:
+      patternProperties:
+        "^queue-group@[0-9a-f]+$":
+          type: object
+
+          properties:
+            "#address-cells": true
+
+            "#size-cells": true
+
+            reg:
+              maxItems: 1
+
+            interrupts:
+              maxItems: 3
+
+          required:
+            - reg
+            - interrupts
+
+          additionalProperties: false
+    else:
+      required:
+        - reg
+
+  # TSEC and eTSEC devices require three interrupts
+  - if:
+      properties:
+        model:
+          contains:
+            enum: [ TSEC, eTSEC ]
+    then:
+      properties:
+        interrupts:
+          items:
+            - description: Transmit interrupt
+            - description: Receive interrupt
+            - description: Error interrupt
+
+
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    ethernet@24000 {
+        device_type = "network";
+        model = "TSEC";
+        compatible = "gianfar";
+        reg = <0x24000 0x1000>;
+        local-mac-address = [ 00 E0 0C 00 73 00 ];
+        interrupts = <29 2>, <30 2>, <34 2>;
+        interrupt-parent = <&mpic>;
+        phy-handle = <&phy0>;
+    };
+
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    soc1 {
+        #address-cells = <1>;
+        #size-cells = <1>;
+
+        ethernet@24000 {
+            compatible = "gianfar";
+            reg = <0x24000 0x1000>;
+            ranges = <0x0 0x24000 0x1000>;
+            #address-cells = <1>;
+            #size-cells = <1>;
+            cell-index = <0>;
+            device_type = "network";
+            model = "eTSEC";
+            local-mac-address = [ 00 00 00 00 00 00 ];
+            interrupts = <32 IRQ_TYPE_LEVEL_LOW>,
+                         <33 IRQ_TYPE_LEVEL_LOW>,
+                         <34 IRQ_TYPE_LEVEL_LOW>;
+            interrupt-parent = <&ipic>;
+
+            mdio@520 {
+                #address-cells = <1>;
+                #size-cells = <0>;
+                compatible = "fsl,gianfar-mdio";
+                reg = <0x520 0x20>;
+            };
+        };
+    };
+
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    soc2 {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        ethernet {
+            compatible = "fsl,etsec2";
+            ranges;
+            device_type = "network";
+            #address-cells = <2>;
+            #size-cells = <2>;
+            interrupt-parent = <&gic>;
+            model = "eTSEC";
+            fsl,magic-packet;
+            dma-coherent;
+
+            queue-group@2d10000 {
+                #address-cells = <2>;
+                #size-cells = <2>;
+                reg = <0x0 0x2d10000 0x0 0x1000>;
+                interrupts = <GIC_SPI 144 IRQ_TYPE_LEVEL_HIGH>,
+                             <GIC_SPI 145 IRQ_TYPE_LEVEL_HIGH>,
+                             <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>;
+            };
+
+            queue-group@2d14000  {
+                #address-cells = <2>;
+                #size-cells = <2>;
+                reg = <0x0 0x2d14000 0x0 0x1000>;
+                interrupts = <GIC_SPI 147 IRQ_TYPE_LEVEL_HIGH>,
+                             <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>,
+                             <GIC_SPI 149 IRQ_TYPE_LEVEL_HIGH>;
+            };
+        };
+    };
+
+...
diff --git a/Documentation/devicetree/bindings/net/fsl-tsec-phy.txt b/Documentation/devicetree/bindings/net/fsl-tsec-phy.txt
index 0e55e0af7d6f59cfb571dd3fcff704b7f4c140d2..b18bb4c997ea3a221e599f694d9a28692cbcaa7c 100644
--- a/Documentation/devicetree/bindings/net/fsl-tsec-phy.txt
+++ b/Documentation/devicetree/bindings/net/fsl-tsec-phy.txt
@@ -8,44 +8,7 @@ Refer to Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml
 
 * Gianfar-compatible ethernet nodes
 
-Properties:
-
-  - device_type : Should be "network"
-  - model : Model of the device.  Can be "TSEC", "eTSEC", or "FEC"
-  - compatible : Should be "gianfar"
-  - reg : Offset and length of the register set for the device
-  - interrupts : For FEC devices, the first interrupt is the device's
-    interrupt.  For TSEC and eTSEC devices, the first interrupt is
-    transmit, the second is receive, and the third is error.
-  - phy-handle : See ethernet.txt file in the same directory.
-  - fixed-link : See fixed-link.txt in the same directory.
-  - phy-connection-type : See ethernet.txt file in the same directory.
-    This property is only really needed if the connection is of type
-    "rgmii-id", as all other connection types are detected by hardware.
-  - fsl,magic-packet : If present, indicates that the hardware supports
-    waking up via magic packet.
-  - fsl,wake-on-filer : If present, indicates that the hardware supports
-    waking up by Filer General Purpose Interrupt (FGPI) asserted on the
-    Rx int line.  This is an advanced power management capability allowing
-    certain packet types (user) defined by filer rules to wake up the system.
-  - bd-stash : If present, indicates that the hardware supports stashing
-    buffer descriptors in the L2.
-  - rx-stash-len : Denotes the number of bytes of a received buffer to stash
-    in the L2.
-  - rx-stash-idx : Denotes the index of the first byte from the received
-    buffer to stash in the L2.
-
-Example:
-	ethernet@24000 {
-		device_type = "network";
-		model = "TSEC";
-		compatible = "gianfar";
-		reg = <0x24000 0x1000>;
-		local-mac-address = [ 00 E0 0C 00 73 00 ];
-		interrupts = <29 2 30 2 34 2>;
-		interrupt-parent = <&mpic>;
-		phy-handle = <&phy0>
-	};
+Refer to Documentation/devicetree/bindings/net/fsl,gianfar.yaml
 
 * Gianfar PTP clock nodes
 

-- 
2.48.0.rc1.219.gb6b6757d772

