From: Sven Peter <sven@kernel.org>
Date: Sun, 14 Dec 2025 11:51:35 +0000
Subject: [PATCH v3 2/3] dt-bindings: phy: Add Apple Type-C PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251214-b4-atcphy-v3-2-ba82b20e9459@kernel.org>
References: <20251214-b4-atcphy-v3-0-ba82b20e9459@kernel.org>
In-Reply-To: <20251214-b4-atcphy-v3-0-ba82b20e9459@kernel.org>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-hardening@vger.kernel.org, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8195; i=sven@kernel.org;
 h=from:subject:message-id; bh=B8pn83D7Yy67lmNF8MQiKBTy4XDuUoCznztEvqwwgV4=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ6bdkmvvY79c0nGeVs61OP6Vv9pZW73uxi3XLAqz1P60/
 IrPiP/bUcrCIMbBICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZiI6HGG/yX8Lw4ttfwgM/lE
 ybGibMZTBzwj72w0t3a0tdx9e8Psxb8Z/ntW36lrO83ENCldi98k2jSMo2PZxamW07d/LeU1PGS
 zhhsA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple's Type-C PHY (ATCPHY) is a PHY for USB 2.0, USB 3.x,
USB4/Thunderbolt, and DisplayPort connectivity found in Apple Silicon
SoCs.

The PHY handles muxing between these different protocols and also provides
the reset controller for the attached dwc3 USB controller.

Reviewed-by: Neal Gompa <neal@gompa.dev>
Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 .../devicetree/bindings/phy/apple,atcphy.yaml      | 222 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 223 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/apple,atcphy.yaml b/Documentation/devicetree/bindings/phy/apple,atcphy.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..0acac7e3ee67ef2f03ffe1e04b0ac0fb414af362
--- /dev/null
+++ b/Documentation/devicetree/bindings/phy/apple,atcphy.yaml
@@ -0,0 +1,222 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/phy/apple,atcphy.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple Type-C PHY (ATCPHY)
+
+maintainers:
+  - Sven Peter <sven@kernel.org>
+
+description: >
+  The Apple Type-C PHY (ATCPHY) is a combined PHY for USB 2.0, USB 3.x,
+  USB4/Thunderbolt, and DisplayPort connectivity via Type-C ports found in
+  Apple Silicon SoCs.
+
+  The PHY handles muxing between these different protocols and also provides the
+  reset controller for the attached DWC3 USB controller.
+
+  It is designed for USB4 operation and does not handle individual differential
+  pairs as distinct DisplayPort lanes. Any reference to lane in this binding
+  hence refers to two differential pairs (RX and TX) as used in USB terminology.
+
+  In order to correctly setup these lanes for the various modes calibration
+  values copied from Apple's firmware and converted to the format described
+  below by our bootloader m1n1 are required. Without these only USB2 operation
+  is possible.
+
+allOf:
+  - $ref: /schemas/usb/usb-switch.yaml#
+
+$defs:
+  apple,tunable:
+    $ref: /schemas/types.yaml#/definitions/uint32-matrix
+    items:
+      items:
+        - description: Register offset
+        - description: Mask to be applied to the register value
+        - description: Bits to be set after applying the mask
+    description: >
+      List of (register offset, mask, value) tuples copied from Apple's Device
+      Tree by our bootloader m1n1 and used to configure the PHY. These values
+      even vary for a single product/device and likely contain calibration
+      values determined by Apple at manufacturing time.
+      Unless otherwise noted these tunables are always applied to the core
+      register region.
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - apple,t6000-atcphy
+              - apple,t6020-atcphy
+              - apple,t8112-atcphy
+          - const: apple,t8103-atcphy
+      - const: apple,t8103-atcphy
+
+  reg:
+    items:
+      - description: Common controls for all PHYs (USB2/3/4, DisplayPort, TBT)
+      - description: DisplayPort Alternate Mode PHY specific controls
+      - description: Type-C PHY AXI to Apple Fabric interconnect controls
+      - description: USB2 PHY specific controls
+      - description: USB3 PIPE interface controls
+
+  reg-names:
+    items:
+      - const: core
+      - const: lpdptx
+      - const: axi2af
+      - const: usb2phy
+      - const: pipehandler
+
+  "#phy-cells":
+    const: 1
+
+  "#reset-cells":
+    const: 0
+
+  mode-switch: true
+  orientation-switch: true
+
+  power-domains:
+    maxItems: 1
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+    properties:
+      port@0:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Outgoing connection to the SS port of the Type-C connector.
+
+      port@1:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Incoming endpoint from the USB3 controller.
+
+      port@2:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Incoming endpoint from the DisplayPort controller.
+
+      port@3:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Incoming endpoint from the USB4/Thunderbolt controller.
+
+  apple,tunable-common-a:
+    $ref: "#/$defs/apple,tunable"
+    description: >
+      Common tunables required for all modes, applied before tunable-axi2af.
+
+  apple,tunable-axi2af:
+    $ref: "#/$defs/apple,tunable"
+    description: >
+      AXI to Apple Fabric tunables, required for all modes. Unlike all other
+      tunables these are applied to the axi2af region.
+
+  apple,tunable-common-b:
+    $ref: "#/$defs/apple,tunable"
+    description: >
+      Common tunables required for all modes, applied after tunable-axi2af.
+
+  apple,tunable-lane0-usb:
+    $ref: "#/$defs/apple,tunable"
+    description: USB3 tunables for lane 0.
+
+  apple,tunable-lane1-usb:
+    $ref: "#/$defs/apple,tunable"
+    description: USB3 tunables for lane 1.
+
+  apple,tunable-lane0-cio:
+    $ref: "#/$defs/apple,tunable"
+    description: USB4/Thunderbolt ("Converged IO") tunables for lane 0.
+
+  apple,tunable-lane1-cio:
+    $ref: "#/$defs/apple,tunable"
+    description: USB4/Thunderbolt ("Converged IO") tunables for lane 1.
+
+  apple,tunable-lane0-dp:
+    $ref: "#/$defs/apple,tunable"
+    description: >
+      DisplayPort tunables for lane 0.
+
+      Note that lane here refers to a USB RX and TX pair re-used for DisplayPort
+      and not to an individual DisplayPort differential lane.
+
+  apple,tunable-lane1-dp:
+    $ref: "#/$defs/apple,tunable"
+    description: >
+      DisplayPort tunables for lane 1.
+
+      Note that lane here refers to a USB RX and TX pair re-used for DisplayPort
+      and not to an individual DisplayPort differential lane.
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - "#phy-cells"
+  - "#reset-cells"
+  - orientation-switch
+  - mode-switch
+  - power-domains
+  - ports
+
+additionalProperties: false
+
+examples:
+  - |
+    phy@83000000 {
+      compatible = "apple,t8103-atcphy";
+      reg = <0x83000000 0x4c000>,
+            <0x83050000 0x8000>,
+            <0x80000000 0x4000>,
+            <0x82a90000 0x4000>,
+            <0x82a84000 0x4000>;
+      reg-names = "core", "lpdptx", "axi2af", "usb2phy",
+                  "pipehandler";
+
+      #phy-cells = <1>;
+      #reset-cells = <0>;
+
+      orientation-switch;
+      mode-switch;
+      power-domains = <&ps_atc0_usb>;
+
+      ports {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        port@0 {
+          reg = <0>;
+
+          endpoint {
+            remote-endpoint = <&typec_connector_ss>;
+          };
+        };
+
+        port@1 {
+          reg = <1>;
+
+          endpoint {
+            remote-endpoint = <&dwc3_ss_out>;
+          };
+        };
+
+        port@2 {
+          reg = <2>;
+
+          endpoint {
+            remote-endpoint = <&dcp_dp_out>;
+          };
+        };
+
+        port@3 {
+          reg = <3>;
+
+          endpoint {
+            remote-endpoint = <&acio_tbt_out>;
+          };
+        };
+      };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 5b11839cba9de1e9e43f63787578edd8c429ca39..5c68ab187d406d5fd6d042672848197c1b6957a1 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2471,6 +2471,7 @@ F:	Documentation/devicetree/bindings/nvme/apple,nvme-ans.yaml
 F:	Documentation/devicetree/bindings/nvmem/apple,efuses.yaml
 F:	Documentation/devicetree/bindings/nvmem/apple,spmi-nvmem.yaml
 F:	Documentation/devicetree/bindings/pci/apple,pcie.yaml
+F:	Documentation/devicetree/bindings/phy/apple,atcphy.yaml
 F:	Documentation/devicetree/bindings/pinctrl/apple,pinctrl.yaml
 F:	Documentation/devicetree/bindings/power/apple*
 F:	Documentation/devicetree/bindings/power/reset/apple,smc-reboot.yaml

-- 
2.34.1

