From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:22:24 -0500
Subject: [PATCH net-next 1/2] dt-bindings: net: Add Siflower SF19A2890 GMAC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-gmac-v1-1-a15965a49574@telaak.dev>
References: <20261104-sf19a2890-gmac-v1-0-a15965a49574@telaak.dev>
In-Reply-To: <20261104-sf19a2890-gmac-v1-0-a15965a49574@telaak.dev>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Jose Abreu <joabreu@synopsys.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, linux-mips@vger.kernel.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776955; l=4305;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=XOuu0yKHxzyySINW5UI8L81RpxlJ/TBeyAQn1sO1t/Q=;
 b=fisEUu+QvicaWpO+KC4U+S4bZAlkUMjZ+KOJ4cxZYLaahaAsnH+U3P8OYszWrmpXkxZA9VQ8I
 ZyA4qvWinNvBKDhiFXJ1ry6q9QPeY6FdUTNdQjeTDSBshkVQbt/xD/R
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Siflower SF19A2890 has a DesignWare GMAC 3.73a whose interface
type and RGMII clock delays are set in a configuration block of their
own, next to its clock and reset manager. It takes a fourth clock, the
RGMII transmit reference.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 .../bindings/net/siflower,sf19a2890-gmac.yaml      | 110 +++++++++++++++++++++
 .../devicetree/bindings/net/snps,dwmac.yaml        |   1 +
 2 files changed, 111 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/siflower,sf19a2890-gmac.yaml b/Documentation/devicetree/bindings/net/siflower,sf19a2890-gmac.yaml
new file mode 100644
index 000000000..377f24a65
--- /dev/null
+++ b/Documentation/devicetree/bindings/net/siflower,sf19a2890-gmac.yaml
@@ -0,0 +1,110 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/net/siflower,sf19a2890-gmac.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Siflower SF19A2890 GMAC
+
+maintainers:
+  - Joseph Telaak <joseph@telaak.dev>
+
+description:
+  The Siflower SF19A2890 has a Synopsys DesignWare GMAC 3.73a. Its
+  interface type and RGMII clock delays are set in a configuration block
+  of their own. The MAC adds an RGMII delay only where the
+  rx-internal-delay-ps or tx-internal-delay-ps property says so.
+
+select:
+  properties:
+    compatible:
+      contains:
+        const: siflower,sf19a2890-gmac
+  required:
+    - compatible
+
+properties:
+  compatible:
+    items:
+      - const: siflower,sf19a2890-gmac
+      - const: snps,dwmac
+
+  reg:
+    items:
+      - description: MAC registers
+      - description: Interface configuration registers
+
+  interrupts:
+    maxItems: 3
+
+  interrupt-names:
+    items:
+      - const: macirq
+      - const: eth_wake_irq
+      - const: eth_lpi
+
+  clocks:
+    items:
+      - description: GMAC main clock
+      - description: Peripheral registers interface clock
+      - description: PTP reference clock
+      - description: RGMII transmit reference clock
+
+  clock-names:
+    items:
+      - const: stmmaceth
+      - const: pclk
+      - const: ptp_ref
+      - const: byp_ref
+
+  rx-internal-delay-ps:
+    description:
+      Applied in steps of about 55 ps, rounded to the nearest step.
+    maximum: 14025
+
+  tx-internal-delay-ps:
+    description:
+      Applied in steps of about 55 ps, rounded to the nearest step.
+    maximum: 14025
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - interrupt-names
+  - clocks
+  - clock-names
+  - resets
+  - reset-names
+
+allOf:
+  - $ref: snps,dwmac.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/interrupt-controller/mips-gic.h>
+
+    ethernet@10800000 {
+        compatible = "siflower,sf19a2890-gmac", "snps,dwmac";
+        reg = <0x10800000 0x200000>, <0x19e04440 0x10>;
+        interrupt-parent = <&gic>;
+        interrupts = <GIC_SHARED 32 IRQ_TYPE_LEVEL_HIGH>,
+                     <GIC_SHARED 34 IRQ_TYPE_LEVEL_HIGH>,
+                     <GIC_SHARED 33 IRQ_TYPE_LEVEL_HIGH>;
+        interrupt-names = "macirq", "eth_wake_irq", "eth_lpi";
+        clocks = <&gmac_crm 0>, <&gmac_crm 1>, <&gmac_crm 3>, <&gmac_crm 2>;
+        clock-names = "stmmaceth", "pclk", "ptp_ref", "byp_ref";
+        resets = <&gmac_crm 0>;
+        reset-names = "stmmaceth";
+        phy-mode = "rgmii-id";
+        rx-internal-delay-ps = <550>;
+        tx-internal-delay-ps = <935>;
+
+        fixed-link {
+            speed = <1000>;
+            full-duplex;
+        };
+    };
diff --git a/Documentation/devicetree/bindings/net/snps,dwmac.yaml b/Documentation/devicetree/bindings/net/snps,dwmac.yaml
index 2c4842404..c3d96d58a 100644
--- a/Documentation/devicetree/bindings/net/snps,dwmac.yaml
+++ b/Documentation/devicetree/bindings/net/snps,dwmac.yaml
@@ -98,6 +98,7 @@ properties:
         - rockchip,rk3588-gmac
         - rockchip,rv1108-gmac
         - rockchip,rv1126-gmac
+        - siflower,sf19a2890-gmac
         - snps,dwmac
         - snps,dwmac-3.40a
         - snps,dwmac-3.50a

-- 
Git-155)

