From: Michael Riesch <michael.riesch@collabora.com>
Date: Fri, 13 Mar 2026 16:20:44 +0100
Subject: [PATCH 2/9] media: dt-bindings: add rockchip rk3588 vicap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250430-rk3588-vicap-v1-2-b3bddf749914@collabora.com>
References: <20250430-rk3588-vicap-v1-0-b3bddf749914@collabora.com>
In-Reply-To: <20250430-rk3588-vicap-v1-0-b3bddf749914@collabora.com>
To: Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Jagan Teki <jagan@amarulasolutions.com>, 
 =?utf-8?q?=D0=9A=D1=83=D0=B7=D0=BD=D0=B5=D1=86=D0=BE=D0=B2_=D0=9C=D0=B8=D1=85=D0=B0=D0=B8=D0=BB?= <mai.kuznetsov.misha@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773415244; l=8828;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=QZfdNyyxojOVMMCiozE4Aa5gT9bbyrZl6q2VqHgX7Js=;
 b=Sn/glaNOToJVEuZR+fndHjje9col/5WJIc8D7ydESUJBRhP0C8DfPMA4g+SC3hlg87I6PKgpe
 /RTgxYHjkWGD4nqhac1VIZzMmSvprjAtloIt9UB3AKaj2YQQEY6aZ3J
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for the Rockchip RK3588 Video Capture (VICAP) unit.

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 .../bindings/media/rockchip,rk3588-vicap.yaml      | 256 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 257 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/rockchip,rk3588-vicap.yaml b/Documentation/devicetree/bindings/media/rockchip,rk3588-vicap.yaml
new file mode 100644
index 000000000000..7fd4214921cb
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/rockchip,rk3588-vicap.yaml
@@ -0,0 +1,256 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/rockchip,rk3588-vicap.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Rockchip RK3588 Video Capture (VICAP)
+
+maintainers:
+  - Michael Riesch <michael.riesch@collabora.com>
+
+description:
+  The Rockchip RK3588 Video Capture (VICAP) block features a digital video
+  port (DVP, a parallel video interface) and six MIPI CSI-2 ports. It receives
+  the data from camera sensors, video decoders, or other companion ICs and
+  transfers it into system main memory by AXI bus and/or passes it to the image
+  signal processing (ISP) blocks.
+
+properties:
+  compatible:
+    enum:
+      - rockchip,rk3588-vicap
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: ACLK
+      - description: HCLK
+      - description: DCLK
+      - description: ICLK0
+      - description: ICLK1
+
+  clock-names:
+    items:
+      - const: aclk
+      - const: hclk
+      - const: dclk
+      - const: iclk_host0
+      - const: iclk_host1
+
+  iommus:
+    maxItems: 1
+
+  resets:
+    maxItems: 9
+
+  rockchip,grf:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description: Phandle to general register file used for video input block control.
+
+  power-domains:
+    maxItems: 1
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+
+    properties:
+      port@0:
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        unevaluatedProperties: false
+        description: The digital video port (DVP, a parallel video interface).
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+            properties:
+              bus-type:
+                enum:
+                  - 5 # MEDIA_BUS_TYPE_PARALLEL
+                  - 6 # MEDIA_BUS_TYPE_BT656
+
+            required:
+              - bus-type
+
+      port@1:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Port connected to the MIPI CSI-2 receiver 0 output.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+      port@2:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Port connected to the MIPI CSI-2 receiver 1 output.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+      port@3:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Port connected to the MIPI CSI-2 receiver 2 output.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+      port@4:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Port connected to the MIPI CSI-2 receiver 3 output.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+      port@5:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Port connected to the MIPI CSI-2 receiver 4 output.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+      port@6:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Port connected to the MIPI CSI-2 receiver 5 output.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+      port@10:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Port connected to the ISP0 input.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+      port@11:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Port connected to the ISP1 input.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - ports
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/rockchip,rk3588-cru.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/media/video-interfaces.h>
+    #include <dt-bindings/power/rk3588-power.h>
+    #include <dt-bindings/reset/rockchip,rk3588-cru.h>
+
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        vicap: video-capture@fdce0000 {
+            compatible = "rockchip,rk3588-vicap";
+            reg = <0x0 0xfdce0000 0x0 0x800>;
+            interrupts = <GIC_SPI 155 IRQ_TYPE_LEVEL_HIGH 0>;
+            clocks = <&cru ACLK_VICAP>, <&cru HCLK_VICAP>,
+                     <&cru DCLK_VICAP>, <&cru ICLK_CSIHOST0>,
+                     <&cru ICLK_CSIHOST1>;
+            clock-names = "aclk", "hclk", "dclk", "iclk_host0", "iclk_host1";
+            iommus = <&vicap_mmu>;
+            power-domains = <&power RK3588_PD_VI>;
+            resets = <&cru SRST_A_VICAP>, <&cru SRST_H_VICAP>,
+                     <&cru SRST_D_VICAP>, <&cru SRST_CSIHOST0_VICAP>,
+                     <&cru SRST_CSIHOST1_VICAP>, <&cru SRST_CSIHOST2_VICAP>,
+                     <&cru SRST_CSIHOST3_VICAP>, <&cru SRST_CSIHOST4_VICAP>,
+                     <&cru SRST_CSIHOST5_VICAP>;
+
+            ports {
+                #address-cells = <1>;
+                #size-cells = <0>;
+
+                vicap_dvp: port@0 {
+                    reg = <0>;
+
+                    vicap_dvp_input: endpoint {
+                        bus-type = <MEDIA_BUS_TYPE_BT656>;
+                        bus-width = <16>;
+                        pclk-sample = <MEDIA_PCLK_SAMPLE_DUAL_EDGE>;
+                        remote-endpoint = <&it6801_output>;
+                    };
+                };
+
+                vicap_mipi0: port@1 {
+                    reg = <1>;
+
+                    vicap_mipi0_input: endpoint {
+                        remote-endpoint = <&csi0_output>;
+                    };
+                };
+
+                vicap_mipi1: port@2 {
+                    reg = <2>;
+
+                    vicap_mipi1_input: endpoint {
+                        remote-endpoint = <&csi1_output>;
+                    };
+                };
+
+                vicap_mipi2: port@3 {
+                    reg = <3>;
+
+                    vicap_mipi2_input: endpoint {
+                        remote-endpoint = <&csi2_output>;
+                    };
+                };
+
+                vicap_mipi3: port@4 {
+                    reg = <4>;
+
+                    vicap_mipi3_input: endpoint {
+                        remote-endpoint = <&csi3_output>;
+                    };
+                };
+
+                vicap_mipi4: port@5 {
+                    reg = <5>;
+
+                    vicap_mipi4_input: endpoint {
+                        remote-endpoint = <&csi4_output>;
+                    };
+                };
+
+                vicap_mipi5: port@6 {
+                    reg = <6>;
+
+                    vicap_mipi5_input: endpoint {
+                        remote-endpoint = <&csi5_output>;
+                    };
+                };
+            };
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 237397f18f07..a972cd38c13d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -22874,6 +22874,7 @@ S:	Maintained
 F:	Documentation/admin-guide/media/rkcif*
 F:	Documentation/devicetree/bindings/media/rockchip,px30-vip.yaml
 F:	Documentation/devicetree/bindings/media/rockchip,rk3568-vicap.yaml
+F:	Documentation/devicetree/bindings/media/rockchip,rk3588-vicap.yaml
 F:	drivers/media/platform/rockchip/rkcif/
 
 ROCKCHIP CRYPTO DRIVERS

-- 
2.39.5

