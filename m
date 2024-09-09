From: Keke Li <keke.li@amlogic.com>
Date: Mon, 09 Sep 2024 15:24:13 +0800
Subject: [PATCH v2 3/9] dt-bindings: media: Add
 amlogic,c3-mipi-adapter.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240909-c3isp-v2-3-3c866a1cea56@amlogic.com>
References: <20240909-c3isp-v2-0-3c866a1cea56@amlogic.com>
In-Reply-To: <20240909-c3isp-v2-0-3c866a1cea56@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kieran.bingham@ideasonboard.com, 
 laurent.pinchart@ideasonboard.com, dan.scally@ideasonboard.com, 
 Keke Li <keke.li@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725866660; l=3150;
 i=keke.li@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=ijC2cwZ5UkAT/WB+A9DxxF8sasBO/hzhGYgM1ZgmtNg=;
 b=bFZl0VuZSsT0BLHsNd29tSLe0RIFbGXG8t+LO2We2ghCWwqUsabEduBtC2J8i+6/8NaKUXMcB
 6ry1FmM+O99BNPCH8ZkwFd2/XwD7uWb3um9F55P/ZmKFGmsJdG8nNDA
X-Developer-Key: i=keke.li@amlogic.com; a=ed25519;
 pk=XxNPTsQ0YqMJLLekV456eoKV5gbSlxnViB1k1DhfRmU=
X-Endpoint-Received: by B4 Relay for keke.li@amlogic.com/20240902 with auth_id=204
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

c3-mipi-adapter is used to organize mipi data and
send raw data to ISP module.

Signed-off-by: Keke Li <keke.li@amlogic.com>
---
 .../bindings/media/amlogic,c3-mipi-adapter.yaml    | 108 +++++++++++++++++++++
 1 file changed, 108 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/amlogic,c3-mipi-adapter.yaml b/Documentation/devicetree/bindings/media/amlogic,c3-mipi-adapter.yaml
new file mode 100644
index 000000000000..d900ff9df61b
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/amlogic,c3-mipi-adapter.yaml
@@ -0,0 +1,108 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/amlogic,c3-mipi-adapter.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic C3 MIPI adapter receiver
+
+maintainers:
+  - Keke Li <keke.li@amlogic.com>
+
+description:
+  MIPI adapter is used to convert the MIPI CSI-2 data
+  into an ISP supported data format.
+
+properties:
+  compatible:
+    enum:
+      - amlogic,c3-mipi-adapter
+
+  reg:
+    maxItems: 3
+
+  reg-names:
+    items:
+      - const: top
+      - const: fd
+      - const: rd
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
+      - const: isp0
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+
+    properties:
+      port@0:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: input port node.
+
+      port@1:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: output port node.
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
+        adap: adap@ff010000 {
+            compatible = "amlogic,c3-mipi-adapter";
+            reg = <0x0 0xff010000 0x0 0x100>,
+                  <0x0 0xff01b000 0x0 0x100>,
+                  <0x0 0xff01d000 0x0 0x200>;
+            reg-names = "top", "fd", "rd";
+            power-domains = <&pwrc PWRC_C3_ISP_TOP_ID>;
+            clocks = <&clkc_periphs CLKID_VAPB>,
+                     <&clkc_periphs CLKID_ISP0>;
+            clock-names = "vapb", "isp0";
+
+            ports {
+                #address-cells = <1>;
+                #size-cells = <0>;
+
+                port@0 {
+                    reg = <0>;
+                    c3_adap_in: endpoint {
+                        remote-endpoint = <&c3_mipi_csi_out>;
+                    };
+                };
+
+                port@1 {
+                    reg = <1>;
+                    c3_adap_out: endpoint {
+                        remote-endpoint = <&c3_isp_in>;
+                    };
+                };
+            };
+        };
+    };
+...

-- 
2.46.0

