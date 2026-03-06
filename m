From: Michael Riesch <michael.riesch@collabora.com>
Date: Fri, 06 Mar 2026 15:09:48 +0100
Subject: [PATCH 1/4] media: dt-bindings: rockchip,rk3568-mipi-csi2: add
 rk3588 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260305-rk3588-csi2rx-v1-1-0cd8d2bf28c0@collabora.com>
References: <20260305-rk3588-csi2rx-v1-0-0cd8d2bf28c0@collabora.com>
In-Reply-To: <20260305-rk3588-csi2rx-v1-0-0cd8d2bf28c0@collabora.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772806189; l=1008;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=Kp0wbOf5Lw+4im6z0zt2pWlcTxwzhXGm5bLIr9vHDBY=;
 b=IvoVSaSZKCGd8I9mLe+BRckb11QJtJQh6mZXr6kHlUp8MEvFfh4xyoK374HZ+mkPT79AEqMCa
 d+lZZZ5BvGMDSrlHctrNuihSjnNsk78FmUBvcCUY+QVh0SLMikvgcOh
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 MIPI CSI-2 receivers are compatible to the ones found in
the RK3568. However, their integration in the respective SoC may be
different when it comes to the (currently not implemented) split
DPHY feature. Therefore, add the RK3588 compatible to allow for
future differentiation.

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 Documentation/devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml b/Documentation/devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml
index 2c2bd87582eb..5f8014da31ca 100644
--- a/Documentation/devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml
+++ b/Documentation/devicetree/bindings/media/rockchip,rk3568-mipi-csi2.yaml
@@ -18,6 +18,7 @@ properties:
   compatible:
     enum:
       - rockchip,rk3568-mipi-csi2
+      - rockchip,rk3588-mipi-csi2
 
   reg:
     maxItems: 1

-- 
2.39.5

