From: Jason Yang <jason98166@gmail.com>
Date: Mon, 10 Aug 2026 20:10:10 +0800
Subject: [PATCH v3 2/5] dt-bindings: phy: rockchip,rk3588-mipi-dcphy: allow
 DSI and CSI consumers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-dcphy-rx-v1-v3-2-a2d25c29adfc@gmail.com>
References: <20260810-dcphy-rx-v1-v3-0-a2d25c29adfc@gmail.com>
In-Reply-To: <20260810-dcphy-rx-v1-v3-0-a2d25c29adfc@gmail.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Guochun Huang <hero.huang@rock-chips.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Michael Riesch <michael.riesch@collabora.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786363808; l=1904;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=L0YFn/UorcpfoUu13dEjPV7h6qsLNW5q4tce+B7/JmY=;
 b=2pBufMxgPOxO3btd9FczwqemLe23DIEutco22KEz5ID7y3QW4jQ/bxM0oeyYGZqlsKxMMvIKo
 dJ0U+RwUZ62C2KJvvdxYPdF18H7iJdfnViN38Rwc1YIVucNEv2800w5
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung MIPI D-/C-PHY block on RK3588 drives a MIPI DSI
transmitter and, on the same PHY, can receive from a MIPI CSI camera.
Describing both as independent consumers of one PHY requires the
devicetree to tell them apart.

Let the existing single cell also take PHY_TYPE_DSI or PHY_TYPE_CSI,
selecting the PHY by the protocol the consumer speaks. PHY_TYPE_DPHY
stays accepted and equivalent to PHY_TYPE_DSI so shipped device trees
remain valid, and PHY_TYPE_CPHY keeps selecting a C-PHY transmitter.
The receiver support added by this series is D-PHY only.

Signed-off-by: Jason Yang <jason98166@gmail.com>
Assisted-by: Claude:claude-fable-5
---
 .../devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml   | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml b/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml
index c8ff5ba22a86..1f7c2e2ddfc1 100644
--- a/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml
+++ b/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml
@@ -22,9 +22,14 @@ properties:
   "#phy-cells":
     const: 1
     description: |
-      Argument is mode to operate in. Supported modes are:
-        - PHY_TYPE_DPHY
-        - PHY_TYPE_CPHY
+      The block contains a MIPI transmitter and a MIPI receiver, which
+      can be referenced independently. The argument selects one of
+      them:
+        - PHY_TYPE_DSI: the transmitter, for a MIPI DSI host
+        - PHY_TYPE_CSI: the receiver, for a MIPI CSI-2 host
+        - PHY_TYPE_DPHY: the transmitter in D-PHY mode; equivalent to
+          PHY_TYPE_DSI and kept for existing device trees
+        - PHY_TYPE_CPHY: the transmitter in C-PHY mode
       See include/dt-bindings/phy/phy.h for constants.
 
   clocks:

-- 
2.43.0

