From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 23 Feb 2024 21:28:20 +0800
Subject: [PATCH net-next v5 5/7] dt-bindings: net: add hisilicon,hisi-femac
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240223-net-v5-5-43b22d39c013@outlook.com>
References: <20240223-net-v5-0-43b22d39c013@outlook.com>
In-Reply-To: <20240223-net-v5-0-43b22d39c013@outlook.com>
To: Yisen Zhuang <yisen.zhuang@huawei.com>, 
 Salil Mehta <salil.mehta@huawei.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708694896; l=3843;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=s74McZo3tz0CRQGXU249Pq+NWVbKcQ+gU6lSPVvGiGw=;
 b=C/Jxx6VzW7in2k+7wNuuXLjxORu4pAhGuCV1heg8ZvhjlSKfoNpN1NqxEFFuKrjlYid4ThfUv
 YRVbuXlJLMUC+OE/YJ7R5G8kdX5rT31hneCmFoY4DjEHcDDxPT56CEo
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Compared to previous txt based binding doc, the following changes are
made according to the TRM:

- Remove unmaintained Hi3516 SoC, add Hi3798MV200
- add MDIO subnode, because MDIO bus is integrated
- add ahb bus clock, phy clock and reset

Also remove "hisi-femac-v1/2" binding.

The difference between versions is unknown and not documented anywhere.
Nor is it used in driver. Remove it until it's needed in the future.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/net/hisilicon,hisi-femac.yaml         | 116 +++++++++++++++++++++
 1 file changed, 116 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
new file mode 100644
index 000000000000..56d7c8a26d0c
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/hisilicon,hisi-femac.yaml
@@ -0,0 +1,116 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/hisilicon,hisi-femac.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Hisilicon Fast Ethernet MAC controller
+
+maintainers:
+  - Yang Xiwen <forbidden405@foxmail.com>
+
+allOf:
+  - $ref: ethernet-controller.yaml
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - hisilicon,hi3798mv200-femac
+      - const: hisilicon,hisi-femac
+
+  reg:
+    items:
+      - description: The first region is the MAC core register base and size.
+      - description: The second region is the global MAC control register.
+
+  ranges:
+    maxItems: 1
+
+  '#address-cells':
+    const: 1
+
+  '#size-cells':
+    const: 1
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    maxItems: 3
+
+  clock-names:
+    items:
+      - const: mac
+      - const: macif
+      - const: phy
+
+  resets:
+    maxItems: 2
+
+  reset-names:
+    items:
+      - const: mac
+      - const: phy
+
+  hisilicon,phy-reset-delays-us:
+    items:
+      - description: The 1st cell is reset pre-delay in micro seconds.
+      - description: The 2nd cell is reset pulse in micro seconds.
+      - description: The 3rd cell is reset post-delay in micro seconds.
+
+patternProperties:
+  '^mdio@[0-9a-f]+$':
+    $ref: hisilicon,hisi-femac-mdio.yaml#
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - clock-names
+  - resets
+  - reset-names
+  - phy-connection-type
+  - phy-handle
+  - hisilicon,phy-reset-delays-us
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    ethernet@9c30000 {
+        compatible = "hisilicon,hi3798mv200-femac", "hisilicon,hisi-femac";
+        reg = <0x9c30000 0x1000>, <0x9c31300 0x200>;
+        ranges = <0x0 0x9c30000 0x10000>;
+        #address-cells = <1>;
+        #size-cells = <1>;
+        interrupts = <GIC_SPI 72 IRQ_TYPE_LEVEL_HIGH>;
+        clocks = <&clk_femac>,
+                 <&clk_femacif>,
+                 <&clk_fephy>;
+        clock-names = "mac", "macif", "phy";
+        resets = <&crg 0xd0 3>, <&crg 0x388 4>;
+        reset-names = "mac", "phy";
+        phy-handle = <&fephy>;
+        phy-connection-type = "mii";
+        // To be filled by bootloader
+        mac-address = [00 00 00 00 00 00];
+        hisilicon,phy-reset-delays-us = <10000 10000 500000>;
+        status = "okay";
+
+        mdio@1100 {
+            compatible = "hisilicon,hisi-femac-mdio";
+            reg = <0x1100 0x20>;
+            #address-cells = <1>;
+            #size-cells = <0>;
+            status = "okay";
+
+            ethernet-phy@1 {
+                reg = <1>;
+                #phy-cells = <0>;
+            };
+        };
+    };

-- 
2.43.0

