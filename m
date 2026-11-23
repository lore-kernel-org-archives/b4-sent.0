From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 23:40:38 +0300
Subject: [PATCH net-next v2 1/3] dt-bindings: net: Add Cortina CS7542 MDIO
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-mdio-v2-1-30465e831853@gmail.com>
References: <20261123-b4-cs7542-mdio-v2-0-30465e831853@gmail.com>
In-Reply-To: <20261123-b4-cs7542-mdio-v2-0-30465e831853@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795466438; l=1747;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=wvzbW6/ViVc3D6Bi4MMZRceIJxjSfYxZh+iECcbGyQg=;
 b=vrKtd70aD4Gmbw1gSPlgcRvaDhYu62wZZSGdq/45x8bU+PbjhaJOpDNI8vkde5RGbKoi6dANS
 wh+aJ9kQkq0CqKfrtjR0XIWYrQLmpHYLSqmBdWXMI8uGqlHTMh6dfu5
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the CS7542 Clause 22 MDIO register bank and devices on its bus.
The firmware initializes the MDC prescaler, which this interface
preserves; clock-frequency and preamble suppression are not supported.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/net/cortina,cs7542-mdio.yaml          | 48 ++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/cortina,cs7542-mdio.yaml b/Documentation/devicetree/bindings/net/cortina,cs7542-mdio.yaml
new file mode 100644
index 000000000..77b5e2f09
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/cortina,cs7542-mdio.yaml
@@ -0,0 +1,48 @@
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
+  Clause 22 MDIO controller. Firmware configures the MDC prescaler before
+  the operating system starts; the driver retains this setting.
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
+  clock-frequency: false
+  suppress-preamble: false
+
+required:
+  - compatible
+  - reg
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
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        ethernet-phy@0 {
+            reg = <0>;
+        };
+    };

-- 
2.53.0

