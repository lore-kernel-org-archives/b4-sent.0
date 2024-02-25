From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 25 Feb 2024 20:03:48 +0800
Subject: [PATCH v4 1/2] dt-bindings: usb: add hisilicon,hi3798mv200-dwc3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240225-dwc3-v4-1-8c1fd6c6f615@outlook.com>
References: <20240225-dwc3-v4-0-8c1fd6c6f615@outlook.com>
In-Reply-To: <20240225-dwc3-v4-0-8c1fd6c6f615@outlook.com>
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708862628; l=3124;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=TbIIsLb8wqVTCtqqeG/liaxRoSs/eRWYcg7QPbnIgSo=;
 b=tVwGmT7az1FU3fbwJTBcEWSw9tsPGkJZ+u6uN1rLKxH6Ie+oZJ42eYFoB68jNUI+cvIaRbx38
 11Qz04FPRFKBwLk57nRugFHWTewUrNoftNUIWUrecM72qd1H+Bwnu50
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the DWC3 controller used by Hi3798MV200.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/usb/hisilicon,hi3798mv200-dwc3.yaml   | 99 ++++++++++++++++++++++
 1 file changed, 99 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/hisilicon,hi3798mv200-dwc3.yaml b/Documentation/devicetree/bindings/usb/hisilicon,hi3798mv200-dwc3.yaml
new file mode 100644
index 000000000000..f3011694393d
--- /dev/null
+++ b/Documentation/devicetree/bindings/usb/hisilicon,hi3798mv200-dwc3.yaml
@@ -0,0 +1,99 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/usb/hisilicon,hi3798mv200-dwc3.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: HiSilicon Hi3798MV200 DWC3 USB SoC controller
+
+maintainers:
+  - Yang Xiwen <forbidden405@foxmail.com>
+
+properties:
+  compatible:
+    const: hisilicon,hi3798mv200-dwc3
+
+  '#address-cells':
+    const: 1
+
+  '#size-cells':
+    const: 1
+
+  ranges: true
+
+  clocks:
+    items:
+      - description: Controller bus clock
+      - description: Controller suspend clock
+      - description: Controller reference clock
+      - description: Controller gm clock
+      - description: Controller gs clock
+      - description: Controller utmi clock
+      - description: Controller pipe clock
+
+  clock-names:
+    items:
+      - const: bus
+      - const: suspend
+      - const: ref
+      - const: gm
+      - const: gs
+      - const: utmi
+      - const: pipe
+
+  resets:
+    maxItems: 1
+
+  reset-names:
+    const: soft
+
+patternProperties:
+  '^usb@[0-9a-f]+$':
+    $ref: snps,dwc3.yaml#
+
+required:
+  - compatible
+  - ranges
+  - '#address-cells'
+  - '#size-cells'
+  - clocks
+  - clock-names
+  - resets
+  - reset-names
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    usb {
+        compatible = "hisilicon,hi3798mv200-dwc3";
+        ranges;
+        #address-cells = <1>;
+        #size-cells = <1>;
+        clocks = <&clk_bus>,
+                 <&clk_suspend>,
+                 <&clk_ref>,
+                 <&clk_gm>,
+                 <&clk_gs>,
+                 <&clk_utmi>,
+                 <&clk_pipe>;
+        clock-names = "bus", "suspend", "ref", "gm", "gs", "utmi", "pipe";
+        resets = <&crg 0xb0 12>;
+        reset-names = "soft";
+
+        usb@98a0000 {
+            compatible = "snps,dwc3";
+            reg = <0x98a0000 0x10000>;
+            interrupts = <GIC_SPI 69 IRQ_TYPE_LEVEL_HIGH>;
+            clocks = <&clk_bus>,
+                     <&clk_suspend>,
+                     <&clk_ref>;
+            clock-names = "bus_early", "suspend", "ref";
+            phys = <&usb2_phy1_port2>, <&combphy0 0>;
+            phy-names = "usb2-phy", "usb3-phy";
+            maximum-speed = "super-speed";
+            dr_mode = "host";
+        };
+    };

-- 
2.43.0

