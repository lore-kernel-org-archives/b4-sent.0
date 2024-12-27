From: Keke Li <keke.li@amlogic.com>
Date: Fri, 27 Dec 2024 15:09:10 +0800
Subject: [PATCH v5 01/10] dt-bindings: media: Add amlogic,c3-mipi-csi2.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241227-c3isp-v5-1-c7124e762ff6@amlogic.com>
References: <20241227-c3isp-v5-0-c7124e762ff6@amlogic.com>
In-Reply-To: <20241227-c3isp-v5-0-c7124e762ff6@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kieran.bingham@ideasonboard.com, 
 laurent.pinchart@ideasonboard.com, dan.scally@ideasonboard.com, 
 jacopo.mondi@ideasonboard.com, Keke Li <keke.li@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735283374; l=4546;
 i=keke.li@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=UR+F4DAIF45sMVWIQ9QMPW/rSAXK8QvBGZOSXJAHlgQ=;
 b=k1PCDLEiKFcfeVE4XytUwNcjRST8aX6Gt5ffLfVSlkVJnBav31xbrELEdb1vBxbHLGpsS49Ae
 AD7c4+ET1HpCpi4wgX4a7bQF3l0ziSmWEaAF95sle1YT6dLYf8qkWuz
X-Developer-Key: i=keke.li@amlogic.com; a=ed25519;
 pk=XxNPTsQ0YqMJLLekV456eoKV5gbSlxnViB1k1DhfRmU=
X-Endpoint-Received: by B4 Relay for keke.li@amlogic.com/20240902 with auth_id=204
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

c3-mipi-csi2 is used to receive mipi data from image sensor.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Keke Li <keke.li@amlogic.com>
---
 .../bindings/media/amlogic,c3-mipi-csi2.yaml       | 131 +++++++++++++++++++++
 MAINTAINERS                                        |   6 +
 2 files changed, 137 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/amlogic,c3-mipi-csi2.yaml b/Documentation/devicetree/bindings/media/amlogic,c3-mipi-csi2.yaml
new file mode 100644
index 000000000000..76b68d1e7316
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/amlogic,c3-mipi-csi2.yaml
@@ -0,0 +1,131 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/amlogic,c3-mipi-csi2.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic C3 MIPI CSI-2 receiver
+
+maintainers:
+  - Keke Li <keke.li@amlogic.com>
+
+description:
+  MIPI CSI-2 receiver contains CSI-2 RX PHY and host controller.
+  It receives the MIPI data from the image sensor and sends MIPI data
+  to MIPI adapter.
+
+properties:
+  compatible:
+    enum:
+      - amlogic,c3-mipi-csi2
+
+  reg:
+    maxItems: 3
+
+  reg-names:
+    items:
+      - const: aphy
+      - const: dphy
+      - const: host
+
+  power-domains:
+    maxItems: 1
+
+  clocks:
+    maxItems: 2
+
+  clock-names:
+    items:
+      - const: vapb
+      - const: phy0
+
+  assigned-clocks: true
+
+  assigned-clock-rates: true
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+
+    properties:
+      port@0:
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        unevaluatedProperties: false
+        description: input port node, connected to sensor.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+            properties:
+              data-lanes:
+                minItems: 1
+                maxItems: 4
+
+            required:
+              - data-lanes
+
+      port@1:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: output port node
+
+    required:
+      - port@0
+      - port@1
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - power-domains
+  - clocks
+  - clock-names
+  - ports
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/amlogic,c3-peripherals-clkc.h>
+    #include <dt-bindings/power/amlogic,c3-pwrc.h>
+
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        csi: csi@ff018000 {
+            compatible = "amlogic,c3-mipi-csi2";
+            reg = <0x0 0xff018000 0x0 0x400>,
+                  <0x0 0xff019000 0x0 0x300>,
+                  <0x0 0xff01a000 0x0 0x100>;
+            reg-names = "aphy", "dphy", "host";
+            power-domains = <&pwrc PWRC_C3_MIPI_ISP_WRAP_ID>;
+            clocks =  <&clkc_periphs CLKID_VAPB>,
+                      <&clkc_periphs CLKID_CSI_PHY0>;
+            clock-names = "vapb", "phy0";
+            assigned-clocks = <&clkc_periphs CLKID_VAPB>,
+                              <&clkc_periphs CLKID_CSI_PHY0>;
+            assigned-clock-rates = <0>, <200000000>;
+
+            ports {
+                #address-cells = <1>;
+                #size-cells = <0>;
+
+                port@0 {
+                    reg = <0>;
+                    c3_mipi_csi_in: endpoint {
+                        remote-endpoint = <&imx290_out>;
+                        data-lanes = <1 2 3 4>;
+                    };
+                };
+
+                port@1 {
+                    reg = <1>;
+                    c3_mipi_csi_out: endpoint {
+                        remote-endpoint = <&c3_adap_in>;
+                    };
+                };
+            };
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index d2ab799a0659..2b06962db506 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1243,6 +1243,12 @@ F:	Documentation/devicetree/bindings/perf/amlogic,g12-ddr-pmu.yaml
 F:	drivers/perf/amlogic/
 F:	include/soc/amlogic/
 
+AMLOGIC MIPI CSI2 DRIVER
+M:	Keke Li <keke.li@amlogic.com>
+L:	linux-media@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/media/amlogic,c3-mipi-csi2.yaml
+
 AMLOGIC RTC DRIVER
 M:	Yiting Deng <yiting.deng@amlogic.com>
 M:	Xianwei Zhao <xianwei.zhao@amlogic.com>

-- 
2.47.1

