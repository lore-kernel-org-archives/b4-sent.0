From: Jason Yang <jason98166@gmail.com>
Date: Fri, 21 Aug 2026 20:02:31 +0800
Subject: [PATCH v4 3/7] phy: rockchip-samsung-dcphy: Move block-level setup
 to runtime resume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-dcphy-rx-v1-v4-3-f1797634233d@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787313753; l=3359;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=9cE+hPPqnU1uNwu7u1p4tFRsUnlEvTN31ifREdpQhEw=;
 b=pRJsM6dhNU4gu7l7zH2IQd0AoIZwurcXFWhoqiNKF4pLdt1ohsazT6fp0n15sPeWciqx+WLeX
 S7iw+OFEnZpAk8N51/As+Fu3mz5Pq3EeEqj/6i/9enPUMu4mxkH+sFY
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The APB reset and the BIAS references have to be treated as block-level
[1]: both the transmitter and the receiver need them, and they only have
to be programmed once. They are programmed from the transmitter's
power-on path today. A later change registers one struct phy for each of
them, and a second consumer coming up would then reset the block
underneath a PHY that is already running.

Program them from runtime resume instead, where whichever of the two
comes up first brings the block up and a second one no longer resets it.
This puts the BIAS writes ahead of the per-PHY reset assert, where the
TRM's worked example has them after [1]. That is safe: neither M_RESETN
nor S_RESETN covers the BIAS registers, and the values written are those
registers' reset defaults.

The output level select in BIAS_CON4 stays on the power-on path: it
selects 400mV for D-PHY and 530mV for C-PHY, and the driver core resumes
a runtime-PM supplier before the consumer's probe runs, so runtime resume
cannot yet know which of the two applies.

[1] RK3588 TRM: sections 22.4.1 (address map), 22.4.2 (reset values),
    22.6.1.2 (reset) and 22.6.4.1 (D-PHY transmitter start-up)

Signed-off-by: Jason Yang <jason98166@gmail.com>
---
 drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c | 25 ++++++++++++-----------
 1 file changed, 13 insertions(+), 12 deletions(-)

diff --git a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
index 11e872cc6611..459ce882b369 100644
--- a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
+++ b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
@@ -980,13 +980,6 @@ static void samsung_mipi_dcphy_bias_block_enable(struct samsung_mipi_dcphy *sams
 						 I_LADDER_1_00V);
 	regmap_write(samsung->regmap, BIAS_CON2, REG_325M_325MV | REG_LP_400M_400MV |
 						 REG_400M_400MV | REG_645M_645MV);
-
-	/* default output voltage select:
-	 * dphy: 400mv
-	 * cphy: 530mv
-	 */
-	regmap_update_bits(samsung->regmap, BIAS_CON4,
-			   I_MUX_SEL_MASK, I_MUX_400MV);
 }
 
 static void samsung_mipi_dphy_lane_enable(struct samsung_mipi_dcphy *samsung)
@@ -1338,7 +1331,13 @@ static int samsung_mipi_dphy_power_on(struct samsung_mipi_dcphy *samsung)
 
 	reset_control_assert(samsung->m_phy_rst);
 
-	samsung_mipi_dcphy_bias_block_enable(samsung);
+	/* default output voltage select:
+	 * dphy: 400mv
+	 * cphy: 530mv
+	 */
+	regmap_update_bits(samsung->regmap, BIAS_CON4,
+			   I_MUX_SEL_MASK, I_MUX_400MV);
+
 	samsung_mipi_dcphy_pll_configure(samsung);
 	samsung_mipi_dphy_clk_lane_timing_init(samsung);
 	samsung_mipi_dphy_data_lane_timing_init(samsung);
@@ -1362,10 +1361,6 @@ static int samsung_mipi_dcphy_power_on(struct phy *phy)
 {
 	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
 
-	reset_control_assert(samsung->apb_rst);
-	udelay(1);
-	reset_control_deassert(samsung->apb_rst);
-
 	switch (samsung->type) {
 	case PHY_TYPE_DPHY:
 		return samsung_mipi_dphy_power_on(samsung);
@@ -1656,6 +1651,12 @@ static __maybe_unused int samsung_mipi_dcphy_runtime_resume(struct device *dev)
 		return ret;
 	}
 
+	reset_control_assert(samsung->apb_rst);
+	udelay(1);
+	reset_control_deassert(samsung->apb_rst);
+
+	samsung_mipi_dcphy_bias_block_enable(samsung);
+
 	return 0;
 }
 

-- 
2.43.0

