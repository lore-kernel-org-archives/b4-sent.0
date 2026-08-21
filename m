From: Jason Yang <jason98166@gmail.com>
Date: Fri, 21 Aug 2026 20:02:29 +0800
Subject: [PATCH v4 1/7] dt-bindings: phy: Add PHY_TYPE_DSI and PHY_TYPE_CSI
 definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-dcphy-rx-v1-v4-1-f1797634233d@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787313753; l=1230;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=QW75aipJ7r+1l1HjnUlKV1E5sUZRB/BcBCVtuuiQvtA=;
 b=bz+eOdVuKzA1nXEkvtCyvOk8VSkT+16IY2otvOlUYef0QPyiVMe96H9WbD/KJDy79VrmZVK/z
 DDmmxdPuGQiDWSGcCqly3/fUJ/0N7C73PqqhpJQwbhtO+Kb5DaGPaRK
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A MIPI D-PHY or C-PHY can be a transmitter (DSI) or a receiver (CSI),
and in some PHY blocks both work at the same time. The existing
PHY_TYPE_DPHY and PHY_TYPE_CPHY cannot tell whether a consumer wants
the transmitter or the receiver.

Add PHY_TYPE_DSI and PHY_TYPE_CSI, so that a binding can select both
D-PHY or C-PHY and transmitter or receiver. They do not replace
PHY_TYPE_DPHY/PHY_TYPE_CPHY, which remain the right choice where a cell
selects the mode. The first user is the Rockchip RK3588 MIPI DC-PHY
binding.

Suggested-by: Michael Riesch <michael.riesch@collabora.com>
Link: https://lore.kernel.org/r/82da3622-9c3a-454c-87bc-fb4ec7adb68d@collabora.com
Signed-off-by: Jason Yang <jason98166@gmail.com>
---
 include/dt-bindings/phy/phy.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/include/dt-bindings/phy/phy.h b/include/dt-bindings/phy/phy.h
index 979b5dfd8353..8ee3f88e6d80 100644
--- a/include/dt-bindings/phy/phy.h
+++ b/include/dt-bindings/phy/phy.h
@@ -24,6 +24,8 @@
 #define PHY_TYPE_CPHY		11
 #define PHY_TYPE_USXGMII	12
 #define PHY_TYPE_XAUI		13
+#define PHY_TYPE_DSI		14
+#define PHY_TYPE_CSI		15
 
 #define PHY_POL_NORMAL		0
 #define PHY_POL_INVERT		1

-- 
2.43.0

