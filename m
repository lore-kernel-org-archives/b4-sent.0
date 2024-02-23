From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 24 Feb 2024 05:43:12 +0800
Subject: [PATCH v2 1/2] dt-bindings: usb: add hisilicon,hi3798mv200-dwc3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240224-dwc3-v2-1-8e4fcd757175@outlook.com>
References: <20240224-dwc3-v2-0-8e4fcd757175@outlook.com>
In-Reply-To: <20240224-dwc3-v2-0-8e4fcd757175@outlook.com>
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Yang Xiwen <forbidden405@foxmail.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708724592; l=3287;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=rL7ggdfkzgLl7HD8zLKVvIZ6BF4Gsjs6h7u7dfg1NOA=;
 b=fIUhTl/a+yP8sRgMXvR8ghG2OF5PEG5WLuu3h1YrqoaaddGF1ygaFfVBffAGOmHMZR5MtWP0e
 mlF7MO9hxuVDvBvq0kdEKhYisN90w44La89aCns1R1qxhCCCi6hhsYo
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the DWC3 controller used by Hi3798MV200.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/usb/hisilicon,hi3798mv200-dwc3.yaml   | 103 +++++++++++++++++++++
 1 file changed, 103 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/hisilicon,hi3798mv200-dwc3.yaml b/Documentation/devicetree/bindings/usb/hisilicon,hi3798mv200-dwc3.yaml
new file mode 100644
index 000000000000..2a93d659414d
--- /dev/null
+++ b/Documentation/devicetree/bindings/usb/hisilicon,hi3798mv200-dwc3.yaml
@@ -0,0 +1,103 @@
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
+  reg: true
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
+  '^usb@[0-9a-z]+$':
+    $ref: snps,dwc3.yaml#
+
+additionalProperties: false
+
+required:
+  - compatible
+  - '#address-cells'
+  - '#size-cells'
+  - ranges
+  - reg
+  - clocks
+  - clock-names
+  - resets
+  - reset-names
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    usb@98a0000 {
+            compatible = "hisilicon,hi3798mv200-dwc3";
+            #address-cells = <1>;
+            #size-cells = <1>;
+            reg = <0x98a0000 0x10000>;
+            ranges;
+            clocks = <&clk_bus>,
+                     <&clk_suspend>,
+                     <&clk_ref>,
+                     <&clk_gm>,
+                     <&clk_gs>,
+                     <&clk_utmi>,
+                     <&clk_pipe>;
+            clock-names = "bus", "suspend", "ref", "gm", "gs", "utmi", "pipe";
+            resets = <&crg 0xb0 12>;
+            reset-names = "soft";
+
+            usb@98a0000 {
+                    compatible = "snps,dwc3";
+                    reg = <0x98a0000 0x10000>;
+                    interrupts = <GIC_SPI 69 IRQ_TYPE_LEVEL_HIGH>;
+                    clocks = <&clk_bus>,
+                             <&clk_suspend>,
+                             <&clk_ref>;
+                    clock-names = "bus_early", "suspend", "ref";
+                    phys = <&usb2_phy1_port2>, <&combphy0 0>;
+                    phy-names = "usb2-phy", "usb3-phy";
+                    maximum-speed = "super-speed";
+                    dr_mode = "host";
+            };
+    };

-- 
2.43.0

