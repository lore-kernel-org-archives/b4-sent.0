From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Thu, 19 Nov 2026 09:57:46 -0800
Subject: [PATCH 4/6] dt-bindings: net: pcs: renesas,rzn1-miic: Document
 rzn1 resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-rzn1-miic-resets-v1-4-feee2bb28bb4@reliablecontrols.com>
References: <20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com>
In-Reply-To: <20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com>
To: Geert Uytterhoeven <geert+renesas@glider.be>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Magnus Damm <magnus.damm@gmail.com>, 
 Fabrizio Castro <fabrizio.castro.jz@renesas.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-renesas-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795111097; l=2616;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=PAIui0Aho2AWZzvhSSgY1N1LI3WhMjZNRuY98EDHUQ4=;
 b=WEFqo0naEx9FThy7uJU731dKz7sgG0WjVv0r2Z4aaycc41QLjtWsjBAHfOKZHPQiY1XbGzSZR
 8oO0O7SU9f3BgjXoogxK/wWJ9QETBTUqqU9tWke0s14XxqsKutEFRiZ
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the rzn1, there are two resets for the miic. Add documentation for them.

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 .../bindings/net/pcs/renesas,rzn1-miic.yaml        | 36 +++++++++++++++-------
 1 file changed, 25 insertions(+), 11 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/pcs/renesas,rzn1-miic.yaml b/Documentation/devicetree/bindings/net/pcs/renesas,rzn1-miic.yaml
index f9d39114e667..d0d820f86da6 100644
--- a/Documentation/devicetree/bindings/net/pcs/renesas,rzn1-miic.yaml
+++ b/Documentation/devicetree/bindings/net/pcs/renesas,rzn1-miic.yaml
@@ -51,14 +51,12 @@ properties:
       - const: hclk
 
   resets:
-    items:
-      - description: Converter register reset
-      - description: Converter reset
+    minItems: 2
+    maxItems: 2
 
   reset-names:
-    items:
-      - const: rst
-      - const: crst
+    minItems: 2
+    maxItems: 2
 
   renesas,miic-switch-portin:
     description: MII Switch PORTIN configuration. This value should use one of
@@ -109,8 +107,14 @@ allOf:
       properties:
         renesas,miic-switch-portin:
           enum: [1, 2]
-        resets: false
-        reset-names: false
+        resets:
+          items:
+            - description: Timestamp selector reset
+            - description: Converter reset
+        reset-names:
+          items:
+            - const: rst_ts
+            - const: rst_miic
       patternProperties:
         "^mii-conv@[0-5]$":
           properties:
@@ -161,9 +165,14 @@ allOf:
       properties:
         renesas,miic-switch-portin:
           const: 0
-      required:
-        - resets
-        - reset-names
+        resets:
+          items:
+            - description: Converter register reset
+            - description: Converter reset
+        reset-names:
+          items:
+            - const: rst
+            - const: crst
       patternProperties:
         "^mii-conv@[0-5]$":
           properties:
@@ -210,6 +219,8 @@ required:
   - reg
   - clocks
   - clock-names
+  - resets
+  - reset-names
   - power-domains
 
 additionalProperties: false
@@ -229,6 +240,9 @@ examples:
               <&sysctrl R9A06G032_CLK_RMII_REF>,
               <&sysctrl R9A06G032_HCLK_SWITCH_RG>;
       clock-names = "mii_ref", "rgmii_ref", "rmii_ref", "hclk";
+      resets = <&sysctrl R9A06G032_RST_TS>,
+              <&sysctrl R9A06G032_RST_MIIC>;
+      reset-names = "rst_ts", "rst_miic";
       renesas,miic-switch-portin = <MIIC_GMAC2_PORT>;
       power-domains = <&sysctrl>;
 

-- 
2.53.0

