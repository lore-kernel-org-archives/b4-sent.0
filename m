From: Vincent Jardin <vjardin@free.fr>
Date: Sun, 13 Sep 2026 14:35:25 +0200
Subject: [PATCH v6 2/3] dt-bindings: arm: fsl: add Free Mobile Nodebox v3
 CPU Module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-for-upstream-nbxv3-dts-v6-2-058566b93ba1@free.fr>
References: <20260913-for-upstream-nbxv3-dts-v6-0-058566b93ba1@free.fr>
In-Reply-To: <20260913-for-upstream-nbxv3-dts-v6-0-058566b93ba1@free.fr>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789302928; l=787;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=7+LCXEAC/QKsgFvm/oL05MEfz8uhqFfnGd3UM0Nw9co=;
 b=1oGd/d0ozcrFqT4OjRDcNgVf1Xl1q5HLGN3zuVQYhzfS+IvhVgh1h5VsfU03PzyZHtX+/QySr
 EBUclC7k4sRDnvlX+0o3pWdtPY1qKTR1CoQ4xgFio7uLUjsq/YyFikj
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DT compatible string for the Free Mobile Nodebox v3 CPU Module, an
NXP LX2160A based board.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/arm/fsl.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/fsl.yaml b/Documentation/devicetree/bindings/arm/fsl.yaml
index 656f2596e1d5..f8ea8d51b8bc 100644
--- a/Documentation/devicetree/bindings/arm/fsl.yaml
+++ b/Documentation/devicetree/bindings/arm/fsl.yaml
@@ -1930,6 +1930,7 @@ properties:
       - description: LX2160A based Boards
         items:
           - enum:
+              - freemobile,nbxv3
               - fsl,lx2160a-bluebox3
               - fsl,lx2160a-bluebox3-rev-a
               - fsl,lx2160a-qds

-- 
2.43.0

