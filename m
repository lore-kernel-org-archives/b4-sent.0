From: Junyi Zhao <junyi.zhao@amlogic.com>
Date: Fri, 06 Nov 2026 15:13:09 +0800
Subject: [PATCH v3 2/2] dt-bindings: i3c: silvaco,i3c-master: Add Amlogic
 A9 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-a9_i3c-v3-2-804b69b9095b@amlogic.com>
References: <20261106-a9_i3c-v3-0-804b69b9095b@amlogic.com>
In-Reply-To: <20261106-a9_i3c-v3-0-804b69b9095b@amlogic.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-i3c@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, imx@lists.linux.dev, 
 linux-hardening@vger.kernel.org, xianwei.zhao@amlogic.com, 
 Kelvin.Zhang@amlogic.com, Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793949192; l=3008;
 i=junyi.zhao@amlogic.com; s=20260924; h=from:subject:message-id;
 bh=EbBk034GgwE/lc2KD1CPaTtRovIqCoOmYzsKMI0uw94=;
 b=PL+f2g6aiQBoYwgwUjM03HWozXwwqI0y/oLp6OneE8FG5gPq4DZyr64D1ghA4gICEt8xHaQ1y
 9pNv4KLHqkuDz3THgyulcyimgZl9v3xIkMzMNoMEjC8oF7YiQIRy8Ft
X-Developer-Key: i=junyi.zhao@amlogic.com; a=ed25519;
 pk=hiL5PjGIksGFiWvEx9J3MhQqU/ro6vNbj72NIw4bbvA=
X-Endpoint-Received: by B4 Relay for junyi.zhao@amlogic.com/20260924 with auth_id=1054
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic A9 SoCs integrate the Silvaco I3C master IP in two domains:
the EE-domain instance (amlogic,a9-i3c) takes "pclk" and "fast_clk"
like the NXP integration, while the AO-domain instance
(amlogic,a9-ao-i3c) lives in the Always-On domain and generates its
bus clock from a divider inside the controller's own register space,
so there is no external fast clock and only "pclk" is exposed.

The two instances differ from the vanilla Silvaco/NXP integrations in
clock topology and required init, so the driver matches them by
dedicated compatibles instead of the "silvaco,i3c-master-v1"
fallback: a fallback would bind the generic driver data, which
neither programs the fast clock rate nor handles the AO internal
divider, and the variant would then fail to work.

Add both compatibles to the schema without the fallback, following
nuvoton,npcm845-i3c, and use per-compatible if/then conditionals to
enforce the clock counts: two clocks for the EE-domain instance and
one clock for the AO-domain instance.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
---
 .../bindings/i3c/silvaco,i3c-master.yaml           | 26 ++++++++++++++++++++--
 1 file changed, 24 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/i3c/silvaco,i3c-master.yaml b/Documentation/devicetree/bindings/i3c/silvaco,i3c-master.yaml
index 853092f75..d892d42be 100644
--- a/Documentation/devicetree/bindings/i3c/silvaco,i3c-master.yaml
+++ b/Documentation/devicetree/bindings/i3c/silvaco,i3c-master.yaml
@@ -13,6 +13,8 @@ properties:
   compatible:
     oneOf:
       - enum:
+          - amlogic,a9-i3c
+          - amlogic,a9-ao-i3c
           - nuvoton,npcm845-i3c
           - silvaco,i3c-master-v1
       - items:
@@ -28,14 +30,14 @@ properties:
     maxItems: 1
 
   clocks:
-    minItems: 2
+    minItems: 1
     items:
       - description: system clock
       - description: bus clock
       - description: other (slower) events clock
 
   clock-names:
-    minItems: 2
+    minItems: 1
     items:
       - const: pclk
       - const: fast_clk
@@ -70,15 +72,35 @@ allOf:
         compatible:
           contains:
             enum:
+              - amlogic,a9-i3c
               - nxp,imx94-i3c
               - nxp,imx95-i3c
     then:
       properties:
         clocks:
+          minItems: 2
           maxItems: 2
         clock-names:
+          minItems: 2
           maxItems: 2
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - amlogic,a9-ao-i3c
+    then:
+      properties:
+        clocks:
+          maxItems: 1
+          description:
+            The "ao" variant is the controller instance in the Always-On (AO)
+            domain, which has no separate bus clock and derives the
+            bus clock from an internal divider.
+        clock-names:
+          maxItems: 1
+
 unevaluatedProperties: false
 
 examples:

-- 
2.42.0

