From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 22:19:23 +0200
Subject: [PATCH 05/19] dt-bindings: thunderbolt: Add Apple USB4/Thunderbolt
 ACIO block
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-soc-tbt-v1-5-44bc9348683c@kernel.org>
References: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
In-Reply-To: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8972; i=sven@kernel.org;
 h=from:subject:message-id; bh=tjxsHzXTSsJGx+EfH2qJRLAdmYE7SAoNp4PmvauEOec=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aUCaF5yfpN3tqnmvafevRP/9rbFbrzO+UVxOYxLG6Zu
 OTvxdlGHaUsDGJcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJJE9mZHjHzWt0d/5Ua+vQ
 u9s+fYxumzlt+oU9Ez4smHTl+54EZvZfDP8DBAU2B3fbzu1f3+TQuMBgyfa/8yc9TtRVnJw69d5
 ly0pmAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each Type-C port with USB4/Thunderbolt support on Apple Silicon SoCs
comes with block called ACIO ("Apple Converged I/O"). It contains a
Cortex-M3 co-processor, the hardware blocks implementing the USB4 host
router, the Native Host Interface (NHI) and a DART IOMMU. The
co-processor exposes the NHI and its DART to the main SoC bus while it
is running.

ACIO can only be powered on after the Type-C PHY has been switched to
USB4/Thunderbolt mode. The Type-C controller provides the cable
information required to boot it through the thunderbolt-switch
connection.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 .../thunderbolt/apple,t8103-usb4-acio.yaml         | 218 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 219 insertions(+)

diff --git a/Documentation/devicetree/bindings/thunderbolt/apple,t8103-usb4-acio.yaml b/Documentation/devicetree/bindings/thunderbolt/apple,t8103-usb4-acio.yaml
new file mode 100644
index 000000000000..38496ce31d20
--- /dev/null
+++ b/Documentation/devicetree/bindings/thunderbolt/apple,t8103-usb4-acio.yaml
@@ -0,0 +1,218 @@
+# SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/thunderbolt/apple,t8103-usb4-acio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple Silicon USB4/Thunderbolt Host Router (ACIO)
+
+maintainers:
+  - Sven Peter <sven@kernel.org>
+
+description: |
+  Each Type-C port with USB4/Thunderbolt support on Apple Silicon SoCs has a
+  host router complex called ACIO (Apple Converged I/O). It contains a
+  Cortex-M3 co-processor, the hardware blocks implementing the USB4 router
+  and its PCIe, USB3 and DisplayPort adapters.
+
+  The co-processor exposes the Native Host Interface (NHI) and its DART IOMMU
+  to the main SoC bus once it is running. They are therefore represented as
+  child nodes. All child registers are located in a single 16 MiB MMIO window
+  and use addresses relative to this window.
+
+  ACIO can only be powered on after the Type-C PHY has been switched to
+  USB4/Thunderbolt mode. Before the connection to the remote device can be
+  established the Type-C PD controller has to pass the cable information
+  through the thunderbolt-switch connection.
+
+properties:
+  compatible:
+    oneOf:
+      - const: apple,t8103-usb4-acio
+      - items:
+          - enum:
+              - apple,t6000-usb4-acio
+              - apple,t6020-usb4-acio
+              - apple,t6030-usb4-acio
+              - apple,t6031-usb4-acio
+              - apple,t8112-usb4-acio
+              - apple,t8122-usb4-acio
+          - const: apple,t8103-usb4-acio
+
+  reg:
+    items:
+      - description: Root complex and co-processor control registers
+      - description: SRAM used for communication with the co-processor
+
+  reg-names:
+    items:
+      - const: rc
+      - const: sram
+
+  mboxes:
+    maxItems: 1
+    description: Mailbox used for RTKit communication with the co-processor
+
+  resets:
+    maxItems: 1
+    description: Reset used to start the ACIO block before booting the
+      co-processor
+
+  power-domains:
+    maxItems: 3
+
+  thunderbolt-switch: true
+
+  apple,tunable-rc:
+    $ref: /schemas/types.yaml#/definitions/uint32-matrix
+    items:
+      items:
+        - description: Register offset
+        - description: Mask of bits to clear
+        - description: Bits to set
+    description: |
+      List of (register offset, mask, value) tuples copied from Apple's Device
+      Tree, converted by the bootloader and used to configure the root complex
+      after the co-processor has booted.
+
+  '#address-cells':
+    const: 1
+
+  '#size-cells':
+    const: 1
+
+  ranges:
+    maxItems: 1
+    description: Single 16 MiB MMIO window containing all child registers
+
+  nonposted-mmio: true
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+    description:
+      OF graph ports for the USB4 router. The port numbers correspond to the
+      USB4 router adapter numbers.
+    properties:
+      port@1:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: USB4 port connected to the USB Type-C connector
+
+      # port@2 is the second, unused USB4 port of the host router
+
+      port@3:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: PCIe adapter
+
+      port@4:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: USB3 adapter
+
+      port@5:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: First DP IN adapter
+
+      port@6:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Second DP IN adapter
+
+    required:
+      - port@1
+
+  iommu@a80000:
+    $ref: /schemas/iommu/apple,dart.yaml#
+    description: DART IOMMU exposed by ACIO and used for DMA from the NHI
+
+  nhi@f00000:
+    $ref: /schemas/thunderbolt/apple,t8103-usb4-nhi.yaml#
+    description: Native Host Interface exposed by ACIO
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - mboxes
+  - power-domains
+  - resets
+  - thunderbolt-switch
+  - '#address-cells'
+  - '#size-cells'
+  - ranges
+  - nonposted-mmio
+  - ports
+  - iommu@a80000
+  - nhi@f00000
+
+allOf:
+  - $ref: /schemas/usb/usb-switch.yaml#
+
+additionalProperties: false
+
+examples:
+  - |
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        cio@501ac0000 {
+            compatible = "apple,t8103-usb4-acio";
+            reg = <0x5 0x01ac0000 0x0 0xc000>,
+                  <0x5 0x01080000 0x0 0x20000>;
+            reg-names = "rc", "sram";
+            ranges = <0x0 0x5 0x01000000 0x1000000>;
+            #address-cells = <1>;
+            mboxes = <&usb4_1_mbox>;
+            nonposted-mmio;
+            pinctrl-0 = <&acio1_pins>;
+            pinctrl-names = "default";
+            power-domains = <&ps_atc1_cio>,
+                            <&ps_atc1_cio_pcie>,
+                            <&ps_atc1_cio_usb>;
+            resets = <&cio_reset 1>;
+            #size-cells = <1>;
+            thunderbolt-switch;
+
+            ports {
+                #address-cells = <1>;
+                #size-cells = <0>;
+
+                port@1 {
+                    reg = <1>;
+
+                    endpoint {
+                        remote-endpoint = <&typec1_con_tbt>;
+                    };
+                };
+            };
+
+            usb4_1_dart: iommu@a80000 {
+                compatible = "apple,t8103-dart";
+                reg = <0xa80000 0x4000>;
+                interrupt-parent = <&aic>;
+                interrupts = <1 890 4>;
+                #iommu-cells = <1>;
+            };
+
+            nhi@f00000 {
+                compatible = "apple,t8103-usb4-nhi";
+                reg = <0xf00000 0x100000>,
+                      <0xdb0000 0x30004>;
+                reg-names = "nhi", "pdf";
+                interrupt-parent = <&aic>;
+                interrupts = <1 863 4>, <1 864 4>, <1 865 4>, <1 866 4>,
+                             <1 867 4>, <1 868 4>, <1 869 4>, <1 870 4>,
+                             <1 871 4>, <1 872 4>, <1 873 4>, <1 874 4>,
+                             <1 875 4>, <1 876 4>, <1 877 4>, <1 878 4>,
+                             <1 879 4>, <1 880 4>, <1 881 4>, <1 882 4>,
+                             <1 883 4>, <1 884 4>, <1 885 4>, <1 886 4>;
+                interrupt-names = "txring0", "txring1", "txring2", "txring3",
+                                  "txring4", "txring5", "txring6", "txring7",
+                                  "txring8", "txring9", "txring10", "txring11",
+                                  "rxring0", "rxring1", "rxring2", "rxring3",
+                                  "rxring4", "rxring5", "rxring6", "rxring7",
+                                  "rxring8", "rxring9", "rxring10", "rxring11";
+                iommus = <&usb4_1_dart 1>;
+                /* To be filled by the loader */
+                apple,thunderbolt-drom = [00];
+            };
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index bb26036a043f..c2c6e4541da7 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2658,6 +2658,7 @@ F:	Documentation/devicetree/bindings/rtc/apple,smc-rtc.yaml
 F:	Documentation/devicetree/bindings/soc/apple/apple,t6000-pmgr-misc.yaml
 F:	Documentation/devicetree/bindings/spi/apple,spi.yaml
 F:	Documentation/devicetree/bindings/spmi/apple,spmi.yaml
+F:	Documentation/devicetree/bindings/thunderbolt/apple,t8103-usb4-acio.yaml
 F:	Documentation/devicetree/bindings/thunderbolt/apple,t8103-usb4-nhi.yaml
 F:	Documentation/devicetree/bindings/usb/apple,dwc3.yaml
 F:	Documentation/devicetree/bindings/watchdog/apple,wdt.yaml

-- 
2.55.0

