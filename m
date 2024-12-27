From: Keke Li <keke.li@amlogic.com>
Date: Fri, 27 Dec 2024 15:09:14 +0800
Subject: [PATCH v5 05/10] dt-bindings: media: Add amlogic,c3-isp.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241227-c3isp-v5-5-c7124e762ff6@amlogic.com>
References: <20241227-c3isp-v5-0-c7124e762ff6@amlogic.com>
In-Reply-To: <20241227-c3isp-v5-0-c7124e762ff6@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kieran.bingham@ideasonboard.com, 
 laurent.pinchart@ideasonboard.com, dan.scally@ideasonboard.com, 
 jacopo.mondi@ideasonboard.com, Keke Li <keke.li@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735283374; l=3320;
 i=keke.li@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=2D4MMs+teJbgYEczXUrF7n2IOGGJmdnvrDImmAbZybo=;
 b=MUWJoveP5laDJ6CvNhJUdoIrFCPdeIORTTvVXA8b10rxpgjv8jA+0j/KfBNm+4RkA7pEEjq7Z
 2gUL6UhojaoAeJ9J8UxgSv58sVHMZLi7ufKvPpHMTlYv9xQiaGr9TVs
X-Developer-Key: i=keke.li@amlogic.com; a=ed25519;
 pk=XxNPTsQ0YqMJLLekV456eoKV5gbSlxnViB1k1DhfRmU=
X-Endpoint-Received: by B4 Relay for keke.li@amlogic.com/20240902 with auth_id=204
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

c3-isp is used to process raw image.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Keke Li <keke.li@amlogic.com>
---
 .../devicetree/bindings/media/amlogic,c3-isp.yaml  | 92 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 ++
 2 files changed, 98 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/amlogic,c3-isp.yaml b/Documentation/devicetree/bindings/media/amlogic,c3-isp.yaml
new file mode 100644
index 000000000000..a33060ac47cb
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/amlogic,c3-isp.yaml
@@ -0,0 +1,92 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/amlogic,c3-isp.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic C3 Image Signal Processing Unit
+
+maintainers:
+  - Keke Li <keke.li@amlogic.com>
+
+description:
+  Amlogic ISP is the RAW image processing module
+  and supports three channels image output.
+
+properties:
+  compatible:
+    enum:
+      - amlogic,c3-isp
+
+  reg:
+    maxItems: 1
+
+  reg-names:
+    items:
+      - const: isp
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
+  assigned-clocks: true
+
+  assigned-clock-rates: true
+
+  interrupts:
+    maxItems: 1
+
+  port:
+    $ref: /schemas/graph.yaml#/properties/port
+    description: input port node.
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - power-domains
+  - clocks
+  - clock-names
+  - interrupts
+  - port
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/clock/amlogic,c3-peripherals-clkc.h>
+    #include <dt-bindings/power/amlogic,c3-pwrc.h>
+
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        isp: isp@ff000000 {
+            compatible = "amlogic,c3-isp";
+            reg = <0x0 0xff000000 0x0 0xf000>;
+            reg-names = "isp";
+            power-domains = <&pwrc PWRC_C3_ISP_TOP_ID>;
+            clocks = <&clkc_periphs CLKID_VAPB>,
+                     <&clkc_periphs CLKID_ISP0>;
+            clock-names = "vapb", "isp0";
+            assigned-clocks = <&clkc_periphs CLKID_VAPB>,
+                              <&clkc_periphs CLKID_ISP0>;
+            assigned-clock-rates = <0>, <400000000>;
+            interrupts = <GIC_SPI 145 IRQ_TYPE_EDGE_RISING>;
+
+            port {
+                c3_isp_in: endpoint {
+                    remote-endpoint = <&c3_adap_out>;
+                };
+            };
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 2ef79d99e088..bdf8b24c773f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1243,6 +1243,12 @@ F:	Documentation/devicetree/bindings/perf/amlogic,g12-ddr-pmu.yaml
 F:	drivers/perf/amlogic/
 F:	include/soc/amlogic/
 
+AMLOGIC ISP DRIVER
+M:	Keke Li <keke.li@amlogic.com>
+L:	linux-media@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/media/amlogic,c3-isp.yaml
+
 AMLOGIC MIPI ADAPTER DRIVER
 M:	Keke Li <keke.li@amlogic.com>
 L:	linux-media@vger.kernel.org

-- 
2.47.1

