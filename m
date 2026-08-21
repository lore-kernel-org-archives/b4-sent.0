From: Jason Yang <jason98166@gmail.com>
Date: Fri, 21 Aug 2026 20:02:30 +0800
Subject: [PATCH v4 2/7] dt-bindings: phy: rockchip,rk3588-mipi-dcphy: Allow
 DSI and CSI consumers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-dcphy-rx-v1-v4-2-f1797634233d@gmail.com>
References: <20260821-dcphy-rx-v1-v4-0-f1797634233d@gmail.com>
In-Reply-To: <20260821-dcphy-rx-v1-v4-0-f1797634233d@gmail.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Guochun Huang <hero.huang@rock-chips.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Michael Riesch <michael.riesch@collabora.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787313753; l=2834;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=0WXE/NlokgeSzl3fI3FkObkaA99tQXSoViMQEwXn3Mg=;
 b=3fWLRGuGuybNGBytIyM/G6LIROaQhrm/OnU6jbpr61L/vqpD0BxsqQjQbLKj7ESlidWA1ofMj
 WHjKv6jee5gBN9kUaAFSAyTOjjemDaF2a8QehcS5jjweyzVlkUv3vrs
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung MIPI D-/C-PHY block on RK3588 and RK3576 has a transmitter
(DSI) and a receiver (CSI) on the same PHY, and two drivers can use them
at the same time. The single cell this binding has selects the mode, so
it cannot tell whether a consumer wants the transmitter or the receiver.

Allow a second cell that selects the transmitter or the receiver. With
D-PHY:

	/* the MIPI DSI host, driving the transmitter */
	phys = <&mipidcphy0 PHY_TYPE_DPHY PHY_TYPE_DSI>;

	/* the MIPI CSI-2 host, driving the receiver */
	phys = <&mipidcphy0 PHY_TYPE_DPHY PHY_TYPE_CSI>;

and with C-PHY:

	phys = <&mipidcphy0 PHY_TYPE_CPHY PHY_TYPE_DSI>;
	phys = <&mipidcphy0 PHY_TYPE_CPHY PHY_TYPE_CSI>;

The transmitter and the receiver cannot operate in different modes [1],
so the first cell must match in both consumers.

A board that wires up both sets '#phy-cells = <2>'. A board that only
wires up the transmitter keeps '#phy-cells = <1>', so existing device
trees are unaffected.

[1] RK3588 TRM: section 22.1 (overview): "The TX and RX only support
    operate in the same PHY mode."

Signed-off-by: Jason Yang <jason98166@gmail.com>
---
 .../bindings/phy/rockchip,rk3588-mipi-dcphy.yaml     | 20 +++++++++++++++++---
 1 file changed, 17 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml b/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml
index c8ff5ba22a86..595a71a51ee6 100644
--- a/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml
+++ b/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml
@@ -20,11 +20,25 @@ properties:
     maxItems: 1
 
   "#phy-cells":
-    const: 1
+    enum: [1, 2]
     description: |
-      Argument is mode to operate in. Supported modes are:
+      A single cell selects the mode to operate in and refers to the
+      transmitter:
         - PHY_TYPE_DPHY
         - PHY_TYPE_CPHY
+
+      Two cells select the mode and then the transmitter (DSI) or the
+      receiver (CSI), so that both can be described as independent
+      consumers of the same PHY:
+        - PHY_TYPE_DPHY PHY_TYPE_DSI
+        - PHY_TYPE_DPHY PHY_TYPE_CSI
+        - PHY_TYPE_CPHY PHY_TYPE_DSI
+        - PHY_TYPE_CPHY PHY_TYPE_CSI
+
+      The transmitter (DSI) and the receiver (CSI) cannot operate in
+      different modes, so when both are described, the first cell must
+      match in both consumers.
+
       See include/dt-bindings/phy/phy.h for constants.
 
   clocks:
@@ -82,6 +96,6 @@ examples:
                  <&cru SRST_S_MIPI_DCPHY0>;
         reset-names = "m_phy", "apb", "grf", "s_phy";
         rockchip,grf = <&mipidcphy0_grf>;
-        #phy-cells = <1>;
+        #phy-cells = <2>;
       };
     };

-- 
2.43.0

