From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:16:41 +0000
Subject: [PATCH] phy: rockchip: samsung-hdptx: Power down the lanes on
 phy_power_off()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hdptx-lanes-pwroff-v1-1-c2f85b7e06a4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBBA0V+RWTtgUnTRXyku8pjUKSWGjI+A+
 O+NdnkW9x4glJkEns0BmTYWnmOFahtwk4lvQvbVoDs9KKU6nHxaCn5NJMG05zkE7L13Az2CsVZ
 DDVOmwOWevsa/ZbUfcst1gvP8AVjUIdd2AAAA
X-Change-ID: 20261110-hdptx-lanes-pwroff-5ddc6e3fabb2
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Cristian Ciocaltea <cristian.ciocaltea@collabora.com>
Cc: linux-phy@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295001; l=4329;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=9zRGlMGjmoLlgrDvFR8/ToCDMVtXPZbT51yULKbcMq8=;
 b=6fx2PKWiYRVDjs7I0iNhOex9Fyzd6QVNJbps4tjjwXUS6cM3JvtMx1U8AaTN6EHtjQ6dKlxro
 ghkAys44cnwDqKkz5wDNuNDP16/vM5N5cK3WGXJV0vZ8bGKkCft4wAW
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the PHY became a clock provider, rk_hdptx_phy_power_off() does
nothing but drop the shared usage count, and the PHY is only really
disabled when that count reaches zero.  The count is also held by every
clock consumer of the PHY PLL, so with a clock reference outstanding
the lanes keep driving the link after the HDMI controller has asked for
the PHY to be powered off.

On RK3588 a clock reference is almost always outstanding: the VOP lists
the PHY clock among its clocks so it can source its DCLK from it, and
the Rockchip power domain driver puts every clock of a device under
pm_clk, which prepares the PHY clock (i.e. bumps the usage count)
whenever the VOP is runtime active.  As soon as any other video port is
in use, e.g. a DP output, switching the HDMI CRTC off therefore leaves
the HDMI lanes enabled and the TMDS clock on the cable, so the sink
never sees the link go away.  The lanes stay on until the whole VOP
goes to runtime suspend.

The lanes belong to the PHY consumer alone, whereas the PLL is shared
with the clock consumers.  Hence disable the lane output and hold the
lanes in reset in rk_hdptx_phy_power_off() regardless of the usage
count, and keep leaving the PLL to the count.  This is the state the
PHY is in between PLL and lane bring-up anyway, and the next
rk_hdptx_phy_power_on() restores the lanes through the regular
rk_hdptx_post_enable_lane() path, so no additional PLL re-init is
needed.  The vendor driver does the same: its power_off callback only
clears the lane enable bits, leaving the PLL to the clock refcount.

The DP mode is left untouched: its PLL is not exposed as a clock and
the lanes are torn down by rk_hdptx_dp_reset() from the usage count.

Fixes: c4b09c562086 ("phy: phy-rockchip-samsung-hdptx: Add clock provider support")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
The problem was found on an Orange Pi 5 (RK3588S): with the HDMI output
switched off, clk_summary still showed clk_hdmiphy_pixel0 at
prepare/enable count 1/1, held by the VOP through pm_clk, so
phy_power_off() never reached rk_hdptx_phy_disable() and the PHY lanes
stayed on across DPMS off. Rockchip's vendor kernel only clears the
lane enable register (LNTOP_REG0207) in its power_off callback too.

Tested on the same board: a trace of the PHY register writes shows each
HDMI CRTC ACTIVE=0 commit writing 0 to LNTOP_REG0207 from
rk_hdptx_phy_power_off(), the lanes staying off for the 3 s off window,
and power_on writing 0xf back with the picture returning. A run of 102
off/on transitions over a range of TMDS modes, checked with a camera on
the TV, gave a correct picture every time, no "Failed to get PHY lane
lock" message, and three suspend-to-idle cycles resumed normally. The
patch has been in the board's kernel since.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed and tested it
as described above.
---
 drivers/phy/rockchip/phy-rockchip-samsung-hdptx.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/phy/rockchip/phy-rockchip-samsung-hdptx.c b/drivers/phy/rockchip/phy-rockchip-samsung-hdptx.c
index 6879eecc5a9f..751bb503dcfe 100644
--- a/drivers/phy/rockchip/phy-rockchip-samsung-hdptx.c
+++ b/drivers/phy/rockchip/phy-rockchip-samsung-hdptx.c
@@ -1768,10 +1768,25 @@ static int rk_hdptx_phy_power_on(struct phy *phy)
 	return ret;
 }
 
+static void rk_hdptx_lane_disable(struct rk_hdptx_phy *hdptx)
+{
+	regmap_update_bits(hdptx->regmap, LNTOP_REG(0207), LANE_EN_MASK,
+			   FIELD_PREP(LANE_EN_MASK, 0));
+	reset_control_assert(hdptx->rsts[RST_LANE].rstc);
+}
+
 static int rk_hdptx_phy_power_off(struct phy *phy)
 {
 	struct rk_hdptx_phy *hdptx = phy_get_drvdata(phy);
 
+	/*
+	 * The lanes are owned by the PHY consumer alone, hence shut them
+	 * down right away.  The PLL is shared with the clock consumers, so
+	 * leave its fate to the usage count.
+	 */
+	if (phy_get_mode(phy) != PHY_MODE_DP)
+		rk_hdptx_lane_disable(hdptx);
+
 	return rk_hdptx_phy_consumer_put(hdptx, false);
 }
 

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-hdptx-lanes-pwroff-5ddc6e3fabb2

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

