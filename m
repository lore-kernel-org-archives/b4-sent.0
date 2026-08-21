From: Jason Yang <jason98166@gmail.com>
Date: Fri, 21 Aug 2026 20:02:33 +0800
Subject: [PATCH v4 5/7] phy: rockchip-samsung-dcphy: Factor the transmitter
 teardown into a helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-dcphy-rx-v1-v4-5-f1797634233d@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787313753; l=2267;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=H9C3dBUKHCEqAqQXc3SD6EcAQzNiujpzdtKGk2VKgQE=;
 b=8OIV6ztcFUOG7ZAoX7MY1eISvfkc4VkrqMa6/7vGpV8pyY1fPXRP+0w9sUvq3clP/0n8GrXdG
 gtvDeMyM04IBjhrl25Y471zayq7Zy61zpJBQZYAB+Si2HHJHvA6nygk
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The transmitter's power-on path is in samsung_mipi_dphy_tx_power_on(),
but the power_off callback still does the teardown itself.

Move the teardown into samsung_mipi_dphy_tx_power_off(), so that
power-on and power-off are a matching pair. Both callbacks then have a
type switch whose arms are plain returns. Turn each into an early guard
for the not yet supported C-PHY and drop the unreachable trailing
return.

No functional change intended.

Signed-off-by: Jason Yang <jason98166@gmail.com>
---
 drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c | 31 ++++++++++-------------
 1 file changed, 14 insertions(+), 17 deletions(-)

diff --git a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
index f58907dec733..5d9d44a1d6a2 100644
--- a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
+++ b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
@@ -1361,37 +1361,34 @@ static int samsung_mipi_dphy_tx_power_on(struct samsung_mipi_dcphy *samsung)
 	return 0;
 }
 
+static int samsung_mipi_dphy_tx_power_off(struct samsung_mipi_dcphy *samsung)
+{
+	samsung_mipi_dphy_tx_lane_disable(samsung);
+	samsung_mipi_dcphy_pll_disable(samsung);
+
+	return 0;
+}
+
 static int samsung_mipi_dcphy_tx_power_on(struct phy *phy)
 {
 	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
 
-	switch (samsung->type) {
-	case PHY_TYPE_DPHY:
-		return samsung_mipi_dphy_tx_power_on(samsung);
-	default:
-		/* CPHY part to be implemented later */
+	/* CPHY part to be implemented later */
+	if (samsung->type != PHY_TYPE_DPHY)
 		return -EOPNOTSUPP;
-	}
 
-	return 0;
+	return samsung_mipi_dphy_tx_power_on(samsung);
 }
 
 static int samsung_mipi_dcphy_tx_power_off(struct phy *phy)
 {
 	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
 
-	switch (samsung->type) {
-	case PHY_TYPE_DPHY:
-		samsung_mipi_dphy_tx_lane_disable(samsung);
-		break;
-	default:
-		/* CPHY part to be implemented later */
+	/* CPHY part to be implemented later */
+	if (samsung->type != PHY_TYPE_DPHY)
 		return -EOPNOTSUPP;
-	}
 
-	samsung_mipi_dcphy_pll_disable(samsung);
-
-	return 0;
+	return samsung_mipi_dphy_tx_power_off(samsung);
 }
 
 static int

-- 
2.43.0

