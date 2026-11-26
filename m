From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Thu, 26 Nov 2026 12:27:33 +0300
Subject: [PATCH net-next v3 1/3] dt-bindings: net: Add Cortina CS7542 MDIO
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-b4-cs7542-mdio-v3-1-35739a0f3225@gmail.com>
References: <20261126-b4-cs7542-mdio-v3-0-35739a0f3225@gmail.com>
In-Reply-To: <20261126-b4-cs7542-mdio-v3-0-35739a0f3225@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795685252; l=1644;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=EoXlxNX1iAJoWLeZjd6QvDar/Xp3T5I8RYbd+jCV5yE=;
 b=DwzDydADC9Fhf1svmIl6olWyyUHQGEfHbcXVXhOsxKwCftdbtEgR0ocHLrRMZBAQAFJZlS2x+
 RKN0og3nU/xBRk8H3TyRcFGtu2Nm+DlMoFI7lsADGmVvQortCVYnxqL
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the Clause 22 controller, its MDC prescaler and the devices
on its management bus.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/net/cortina,cs7542-mdio.yaml          | 52 ++++++++++++++++++++++
 1 file changed, 52 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/cortina,cs7542-mdio.yaml b/Documentation/devicetree/bindings/net/cortina,cs7542-mdio.yaml
new file mode 100644
index 000000000..66b5199c7
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/cortina,cs7542-mdio.yaml
@@ -0,0 +1,52 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/cortina,cs7542-mdio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 MDIO controller
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+description:
+  Clause 22 MDIO controller with a programmable 16-bit MDC prescaler.
+
+allOf:
+  - $ref: mdio.yaml#
+
+properties:
+  compatible:
+    const: cortina,cs7542-mdio
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+    description: APB input clock
+
+  suppress-preamble: false
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - "#address-cells"
+  - "#size-cells"
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    mdio@f00700a0 {
+        compatible = "cortina,cs7542-mdio";
+        reg = <0xf00700a0 0x14>;
+        clocks = <&apb_clk>;
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        ethernet-phy@0 {
+            reg = <0>;
+        };
+    };

-- 
2.53.0

