From: Joseph Telaak <joseph@telaak.dev>
Date: Sun, 08 Nov 2026 17:59:50 -0500
Subject: [PATCH net-next v2 1/2] dt-bindings: net: dsa: lantiq,gswip: add
 reset-gpios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-mxl-gsw1xx-reset-v2-1-46c1da093893@telaak.dev>
References: <20261108-mxl-gsw1xx-reset-v2-0-46c1da093893@telaak.dev>
In-Reply-To: <20261108-mxl-gsw1xx-reset-v2-0-46c1da093893@telaak.dev>
To: Hauke Mehrtens <hauke@hauke-m.de>, Andrew Lunn <andrew@lunn.ch>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Daniel Golle <daniel@makrotopia.org>, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794178811; l=1167;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=MOeFTVQJmsY5ws6zpmzjMuMLHXSYlILvnKcfHNWsxQY=;
 b=osGDcodit8YnTIe+0oCSL5ZBtLGrWLIaOrFzSIWFxkG7qnv2ShbSz72NP0596qN6ZkCXGbzLL
 TVqSLDl7euRDqyBhIKae7YPOdJbw+Mvm9HCkIMWsMSywrge1UVVTZLp
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The standalone GSW1xx switches have a hardware reset input, and boards
wire it to a SoC GPIO. Allow describing it. The SoC-integrated GSWIP
variants have no such pin.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 Documentation/devicetree/bindings/net/dsa/lantiq,gswip.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/dsa/lantiq,gswip.yaml b/Documentation/devicetree/bindings/net/dsa/lantiq,gswip.yaml
index 49af5573e4..9a74ea2a6d 100644
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
@@ -173,6 +178,7 @@ allOf:
         mdio:
           required:
             - compatible
+        reset-gpios: false
     else:
       properties:
         reg:

-- 
Git-155)

