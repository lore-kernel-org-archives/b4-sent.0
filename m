From: Vincent Jardin <vjardin@free.fr>
Date: Tue, 03 Nov 2026 19:12:10 +0100
Subject: [PATCH v2 2/5] dt-bindings: soc: fsl: layerscape-dcfg: add the
 LX2160A pad-mux child
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-for-upstream-lx2160a-rcw-pinmux-v1-v2-2-3aad0860b984@free.fr>
References: <20261103-for-upstream-lx2160a-rcw-pinmux-v1-v2-0-3aad0860b984@free.fr>
In-Reply-To: <20261103-for-upstream-lx2160a-rcw-pinmux-v1-v2-0-3aad0860b984@free.fr>
To: Dong Aisheng <aisheng.dong@nxp.com>, Fabio Estevam <festevam@gmail.com>, 
 Frank Li <Frank.Li@nxp.com>, Jacky Bai <ping.bai@nxp.com>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 NXP S32 Linux Team <s32@nxp.com>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-arm-kernel@lists.infradead.org, imx@lists.linux.dev, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793729572; l=1598;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=YA2Jv1p1SkYZyf+rDzE5uX5RrqHER8WNy18Uw1BptA0=;
 b=BuYXFKVa7bzqfQNlLlL/JpWV4nMUvbYRC0qmNKHkyzhAszW8PB0bokvLsaF+vQSiSGNzvmZlg
 89PcYFMXPqgAHrg/pg8G5LGavtJrFyt3QTheTm3eXX5Oq0SPWpZKSH2
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the LX2160A the DCFG node holds the pad mux, overridden through its
DCSR view. Allow fsl,lx2160a-dcfg with simple-mfd, so that the child is
populated, and the pinctrl child, on the LX2160A only.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 .../bindings/soc/fsl/fsl,layerscape-dcfg.yaml          | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/fsl/fsl,layerscape-dcfg.yaml b/Documentation/devicetree/bindings/soc/fsl/fsl,layerscape-dcfg.yaml
index fc14fd0bf84b..dd6a00ba04eb 100644
--- a/Documentation/devicetree/bindings/soc/fsl/fsl,layerscape-dcfg.yaml
+++ b/Documentation/devicetree/bindings/soc/fsl/fsl,layerscape-dcfg.yaml
@@ -32,6 +32,7 @@ properties:
       - items:
           - enum:
               - fsl,ls1028a-dcfg
+              - fsl,lx2160a-dcfg
           - const: syscon
           - const: simple-mfd
 
@@ -62,6 +63,12 @@ properties:
 
   ranges: true
 
+  pinctrl:
+    $ref: /schemas/pinctrl/fsl,lx2160a-rcw-pinmux.yaml#
+    description:
+      The pad muxes of the RCW on the LX2160A, overridden through the DCSR
+      view of this block.
+
 patternProperties:
   "^clock-controller@[0-9a-f]+$":
     $ref: /schemas/clock/fsl,flexspi-clock.yaml#
@@ -70,6 +77,17 @@ required:
   - compatible
   - reg
 
+allOf:
+  - if:
+      not:
+        properties:
+          compatible:
+            contains:
+              const: fsl,lx2160a-dcfg
+    then:
+      properties:
+        pinctrl: false
+
 additionalProperties: false
 
 examples:

-- 
2.43.0

