From: Jason Yang <jason98166@gmail.com>
Date: Sun, 26 Jul 2026 22:55:44 +0800
Subject: [PATCH v2 1/4] dt-bindings: phy: rockchip,rk3588-mipi-dcphy:
 support per-direction phys
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260726-dcphy-rx-v1-v2-1-cf9cc34a412a@gmail.com>
References: <20260726-dcphy-rx-v1-v2-0-cf9cc34a412a@gmail.com>
In-Reply-To: <20260726-dcphy-rx-v1-v2-0-cf9cc34a412a@gmail.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Guochun Huang <hero.huang@rock-chips.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785077744; l=3309;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=/8pxm6N6mn/e4jHHtvTPJ658FO8+xd4pvisBdnA5CR4=;
 b=Cdtn9owk4gWGJGZLq0wuLQN6uXqC9XF5beS38OR6BJCSWMqUpVLl/Ll9O5hcROYZsGEm+7CHL
 2al2shtaJYeAni07PUWXgh23amReZcUsv9+wDLWoYLk9guNsUzL11rs
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung MIPI D-/C-PHY block on RK3588 drives a MIPI DSI transmitter
and, on the same PHY, can receive a MIPI CSI camera. Describing both as
independent consumers of one PHY requires the direction to be expressed
in the devicetree.

Allow "#phy-cells" to be 1 or 2. The existing single-cell form still
selects the PHY type and refers to the transmitter, so shipped DSI
device trees stay valid; bumping the cell count unconditionally would
invalidate them. A second cell adds the direction, letting a DSI (TX)
and a CSI (RX) reference the same PHY node as separate consumers.

Add include/dt-bindings/phy/rockchip,rk3588-mipi-dcphy.h for the
RK_DCPHY_DIR_TX and RK_DCPHY_DIR_RX direction constants.

Signed-off-by: Jason Yang <jason98166@gmail.com>
Assisted-by: Claude:claude-opus-4-8
---
 .../bindings/phy/rockchip,rk3588-mipi-dcphy.yaml   | 22 ++++++++++++++++------
 .../dt-bindings/phy/rockchip,rk3588-mipi-dcphy.h   | 13 +++++++++++++
 2 files changed, 29 insertions(+), 6 deletions(-)

diff --git a/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml b/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml
index c8ff5ba22a86..68a43db9c669 100644
--- a/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml
+++ b/Documentation/devicetree/bindings/phy/rockchip,rk3588-mipi-dcphy.yaml
@@ -20,12 +20,22 @@ properties:
     maxItems: 1
 
   "#phy-cells":
-    const: 1
+    enum: [1, 2]
     description: |
-      Argument is mode to operate in. Supported modes are:
-        - PHY_TYPE_DPHY
-        - PHY_TYPE_CPHY
-      See include/dt-bindings/phy/phy.h for constants.
+      A single cell selects the PHY type and always refers to the
+      transmitter (DSI) direction. It is kept for backwards compatibility
+      with existing device trees:
+        - <PHY_TYPE_DPHY>
+        - <PHY_TYPE_CPHY>
+
+      Two cells select the PHY type and the direction, so that the
+      transmitter (DSI) and the receiver (CSI) can be described as
+      independent consumers of the same PHY:
+        - <PHY_TYPE_DPHY RK_DCPHY_DIR_TX>
+        - <PHY_TYPE_DPHY RK_DCPHY_DIR_RX>
+
+      See include/dt-bindings/phy/phy.h and
+      include/dt-bindings/phy/rockchip,rk3588-mipi-dcphy.h for constants.
 
   clocks:
     maxItems: 2
@@ -82,6 +92,6 @@ examples:
                  <&cru SRST_S_MIPI_DCPHY0>;
         reset-names = "m_phy", "apb", "grf", "s_phy";
         rockchip,grf = <&mipidcphy0_grf>;
-        #phy-cells = <1>;
+        #phy-cells = <2>;
       };
     };
diff --git a/include/dt-bindings/phy/rockchip,rk3588-mipi-dcphy.h b/include/dt-bindings/phy/rockchip,rk3588-mipi-dcphy.h
new file mode 100644
index 000000000000..5029838fa275
--- /dev/null
+++ b/include/dt-bindings/phy/rockchip,rk3588-mipi-dcphy.h
@@ -0,0 +1,13 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (c) 2026 Jason Yang <jason98166@gmail.com>
+ */
+
+#ifndef _DT_BINDINGS_PHY_ROCKCHIP_RK3588_MIPI_DCPHY_H
+#define _DT_BINDINGS_PHY_ROCKCHIP_RK3588_MIPI_DCPHY_H
+
+/* Direction of a Rockchip Samsung MIPI D-/C-PHY combo block */
+#define RK_DCPHY_DIR_TX		0
+#define RK_DCPHY_DIR_RX		1
+
+#endif /* _DT_BINDINGS_PHY_ROCKCHIP_RK3588_MIPI_DCPHY_H */

-- 
2.43.0

