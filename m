From: Joseph Telaak <joseph@telaak.dev>
Date: Thu, 12 Nov 2026 16:39:40 -0500
Subject: [PATCH net-next v3 1/2] dt-bindings: net: dsa: lantiq,gswip: add
 reset-gpios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-mxl-gsw1xx-reset-v3-1-863e82074893@telaak.dev>
References: <20261112-mxl-gsw1xx-reset-v3-0-863e82074893@telaak.dev>
In-Reply-To: <20261112-mxl-gsw1xx-reset-v3-0-863e82074893@telaak.dev>
To: Hauke Mehrtens <hauke@hauke-m.de>, Andrew Lunn <andrew@lunn.ch>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Daniel Golle <daniel@makrotopia.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794519588; l=2157;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=4FEhgpkbRSKonFfieQreIMKCdNlc7jHkKu3BjReGMyw=;
 b=b+7gb1Oc++Mwg6Q50MuJLkWAgy2Sx1MWTgsgyJaW+v7gIa39B1WPEdZ/AI527fgJvGKz2HhKB
 GxXCULKYkq4CjJp3VSdH8SEvWowcxUlHJAIrWKcmI61xkaNC6NbQRSc
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The standalone GSW1xx switches have a hardware reset input, and boards
wire it to a SoC GPIO. Allow describing it. The SoC-integrated GSWIP
variants have no such pin.

A reset through it returns the RGMII slew rates to their power-on
defaults, so say so where the slew-rate properties say that the
bootloader's configuration is otherwise preserved.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 Documentation/devicetree/bindings/net/dsa/lantiq,gswip.yaml | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/dsa/lantiq,gswip.yaml b/Documentation/devicetree/bindings/net/dsa/lantiq,gswip.yaml
index 49af5573e4..89f78a1bc1 100644
--- a/Documentation/devicetree/bindings/net/dsa/lantiq,gswip.yaml
+++ b/Documentation/devicetree/bindings/net/dsa/lantiq,gswip.yaml
@@ -40,6 +40,11 @@ properties:
       - const: mdio
       - const: mii
 
+  reset-gpios:
+    maxItems: 1
+    description:
+      GPIO connected to the hardware reset input of a standalone switch.
+
   mdio:
     $ref: /schemas/net/mdio.yaml#
     unevaluatedProperties: false
@@ -120,7 +125,8 @@ patternProperties:
                 1: Slow
 
               If not present, the configuration made by the switch bootloader is
-              preserved.
+              preserved, or the power-on default after a reset through
+              reset-gpios.
           maxlinear,slew-rate-txd:
             $ref: /schemas/types.yaml#/definitions/uint32
             enum: [0, 1]
@@ -131,7 +137,8 @@ patternProperties:
                 1: Slow
 
               If not present, the configuration made by the switch bootloader is
-              preserved.
+              preserved, or the power-on default after a reset through
+              reset-gpios.
           maxlinear,rmii-refclk-out:
             type: boolean
             description:
@@ -173,6 +180,7 @@ allOf:
         mdio:
           required:
             - compatible
+        reset-gpios: false
     else:
       properties:
         reg:

-- 
Git-155)

