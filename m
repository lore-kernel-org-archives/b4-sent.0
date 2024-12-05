From: Keke Li <keke.li@amlogic.com>
Date: Thu, 05 Dec 2024 17:04:31 +0800
Subject: [PATCH v4 05/10] dt-bindings: media: Add amlogic,c3-isp.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-c3isp-v4-5-cb1868be0105@amlogic.com>
References: <20241205-c3isp-v4-0-cb1868be0105@amlogic.com>
In-Reply-To: <20241205-c3isp-v4-0-cb1868be0105@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kieran.bingham@ideasonboard.com, 
 laurent.pinchart@ideasonboard.com, dan.scally@ideasonboard.com, 
 Keke Li <keke.li@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733389471; l=2483;
 i=keke.li@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=8AMy+HQGO+uT4cclhhk8EhjTI2Z7v3UJeGdqFbrhxkQ=;
 b=o/VVLm6AftQ8RVJT2qSJTY/9orQwalTFOfwZkLbFOg7sJaSRATSJs8lzPX2JrmPMoaPM56BZe
 Sc1se8MDuN8Aa80Uke7szLUlKJFXmov7T65y6uLFUtd56FvD2N2mm62
X-Developer-Key: i=keke.li@amlogic.com; a=ed25519;
 pk=XxNPTsQ0YqMJLLekV456eoKV5gbSlxnViB1k1DhfRmU=
X-Endpoint-Received: by B4 Relay for keke.li@amlogic.com/20240902 with auth_id=204
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

c3-isp is used to process raw image.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Keke Li <keke.li@amlogic.com>
---
 .../devicetree/bindings/media/amlogic,c3-isp.yaml  | 85 ++++++++++++++++++++++
 1 file changed, 85 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/amlogic,c3-isp.yaml b/Documentation/devicetree/bindings/media/amlogic,c3-isp.yaml
new file mode 100644
index 000000000000..64ae1946b99b
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/amlogic,c3-isp.yaml
@@ -0,0 +1,85 @@
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

-- 
2.47.0

