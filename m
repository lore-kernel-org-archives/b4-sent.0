From: Michael Riesch <michael.riesch@collabora.com>
Date: Tue, 28 Apr 2026 09:27:23 +0200
Subject: [PATCH v5 1/2] media: dt-bindings: rockchip,rk3568-mipi-csi2: add
 rk3588 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260305-rk3588-csi2rx-v5-1-3b7061d043ea@collabora.com>
References: <20260305-rk3588-csi2rx-v5-0-3b7061d043ea@collabora.com>
In-Reply-To: <20260305-rk3588-csi2rx-v5-0-3b7061d043ea@collabora.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Frank Li <Frank.li@nxp.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Collabora Kernel Team <kernel@collabora.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777361244; l=1181;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=3TFnv9jZJHx3KielBqkTXBZA/OzvBwjOjzm/HycqX7Y=;
 b=LOfsEque3uFY0iPZ7ZEm7rPYYPcYNnE+Vx2+6d9h7128ksPQXRUj+QLjIX7yWCPq3qfLrG0gJ
 9iYL8AInDACCefoS9vFUprB073RWSMpEQq5ravShDKZb3PEhp5VDt3w
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 MIPI CSI-2 receivers are compatible to the ones found in the
RK3568. Introduce a list of compatible variants and add the RK3588 variant
to it.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 .../devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml  | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml b/Documentation/devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml
index 4ac4a3b6f406..fbcf28e9e1da 100644
--- a/Documentation/devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml
+++ b/Documentation/devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml
@@ -16,9 +16,14 @@ description:
 
 properties:
   compatible:
-    enum:
-      - fsl,imx93-mipi-csi2
-      - rockchip,rk3568-mipi-csi2
+    oneOf:
+      - enum:
+          - fsl,imx93-mipi-csi2
+          - rockchip,rk3568-mipi-csi2
+      - items:
+          - enum:
+              - rockchip,rk3588-mipi-csi2
+          - const: rockchip,rk3568-mipi-csi2
 
   reg:
     maxItems: 1

-- 
2.39.5

