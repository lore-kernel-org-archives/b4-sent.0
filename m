From: Alexandre Marquet <tb@a-marquet.fr>
Date: Tue, 27 Oct 2026 13:01:42 +0100
Subject: [PATCH 1/3] drm/bridge: analogix_dp: deassert DP_PHY_PD on
 power-on for exynos
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-drm-misc-next-manta-auxbus-v1-1-3a45c3cf531d@a-marquet.fr>
References: <20261027-drm-misc-next-manta-auxbus-v1-0-3a45c3cf531d@a-marquet.fr>
In-Reply-To: <20261027-drm-misc-next-manta-auxbus-v1-0-3a45c3cf531d@a-marquet.fr>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jingoo Han <jingoohan1@gmail.com>, Inki Dae <inki.dae@samsung.com>, 
 Seung-Woo Kim <sw0312.kim@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Douglas Anderson <dianders@chromium.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Lukas Timmermann <linux@timmermann.space>, 
 Henrik Grimler <henrik@grimler.se>, Hendrik Noack <hendrik-noack@gmx.de>, 
 Alexandre Marquet <tb@a-marquet.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793102508; l=3293;
 i=tb@a-marquet.fr; s=20261023; h=from:subject:message-id;
 bh=nz55NJx/Uu4x8f9w96Y5Aa8FlPatjRYi6gKldhgQyRY=;
 b=BDjAFMaKETqfYfJDRQJpBK7xZFOxJgEGoGMJlMGVBvYhrnwcpZ9mpeTxzvfsuuFikzLLrsANn
 tOK2NDejgz7ArsLISEgxDV35PlcTAfDn3TCjdD1oERf5G+PMKd04fCS
X-Developer-Key: i=tb@a-marquet.fr; a=ed25519;
 pk=zVRSO6FDK46rqmeA2GuzAhM24eFlUq1QpmXi9/KCFyk=
X-Endpoint-Received: by B4 Relay for tb@a-marquet.fr/20261023 with auth_id=1334
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On exynos platforms at least, calling
analogix_dp_set_analog_power_down() to power on (with enable=false) CH0
to CH3 or the AUX bus currently produces no effect, unless the function
is first called to power on everything (by setting block to POWER_ALL or
ANALOG_TOTAL). The reason for this is that DP_PHY_PD being asserted
(which is its default state) renders every other register bit
ineffective.

This is particularly an issue for AUX bus initialization, that tends to
happen before anything else (e.g., to request EDID), and thus, before
anything has any chance to request a power on of the whole analog
section of the chip.

This commit allows analogix_dp_set_analog_power_down() to power on any
block, by deasserting DP_PHY_PD if needed.

Signed-off-by: Alexandre Marquet <tb@a-marquet.fr>
---
 drivers/gpu/drm/bridge/analogix/analogix_dp_reg.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/bridge/analogix/analogix_dp_reg.c b/drivers/gpu/drm/bridge/analogix/analogix_dp_reg.c
index c1344a3f013a..9f634d4e4793 100644
--- a/drivers/gpu/drm/bridge/analogix/analogix_dp_reg.c
+++ b/drivers/gpu/drm/bridge/analogix/analogix_dp_reg.c
@@ -256,6 +256,19 @@ void analogix_dp_set_analog_power_down(struct analogix_dp_device *dp,
 	if (dp->plat_data && analogix_dp_is_rockchip(dp->plat_data->dev_type))
 		phy_pd_addr = ANALOGIX_DP_PD;
 
+	reg = readl(dp->reg_base + phy_pd_addr);
+
+	if (dp->plat_data && (dp->plat_data->dev_type == EXYNOS_DP)) {
+		/* On exynos, register AUX_PD and CH[0-3]_PD have no effect if
+		 * DP_PHY_PD is asserted. So, when powering any of them up, we
+		 * need to deassert DP_PHY_PD first.
+		 */
+		if (!enable && (reg & DP_PHY_PD)) {
+			reg &= ~DP_PHY_PD;
+			reg |= AUX_PD | CH0_PD | CH1_PD | CH2_PD | CH3_PD;
+		}
+	}
+
 	switch (block) {
 	case AUX_BLOCK:
 		if (dp->plat_data && analogix_dp_is_rockchip(dp->plat_data->dev_type))
@@ -263,7 +276,6 @@ void analogix_dp_set_analog_power_down(struct analogix_dp_device *dp,
 		else
 			mask = AUX_PD;
 
-		reg = readl(dp->reg_base + phy_pd_addr);
 		if (enable)
 			reg |= mask;
 		else
@@ -272,7 +284,6 @@ void analogix_dp_set_analog_power_down(struct analogix_dp_device *dp,
 		break;
 	case CH0_BLOCK:
 		mask = CH0_PD;
-		reg = readl(dp->reg_base + phy_pd_addr);
 
 		if (enable)
 			reg |= mask;
@@ -282,7 +293,6 @@ void analogix_dp_set_analog_power_down(struct analogix_dp_device *dp,
 		break;
 	case CH1_BLOCK:
 		mask = CH1_PD;
-		reg = readl(dp->reg_base + phy_pd_addr);
 
 		if (enable)
 			reg |= mask;
@@ -292,7 +302,6 @@ void analogix_dp_set_analog_power_down(struct analogix_dp_device *dp,
 		break;
 	case CH2_BLOCK:
 		mask = CH2_PD;
-		reg = readl(dp->reg_base + phy_pd_addr);
 
 		if (enable)
 			reg |= mask;
@@ -302,7 +311,6 @@ void analogix_dp_set_analog_power_down(struct analogix_dp_device *dp,
 		break;
 	case CH3_BLOCK:
 		mask = CH3_PD;
-		reg = readl(dp->reg_base + phy_pd_addr);
 
 		if (enable)
 			reg |= mask;
@@ -321,7 +329,6 @@ void analogix_dp_set_analog_power_down(struct analogix_dp_device *dp,
 		else
 			mask = DP_PHY_PD;
 
-		reg = readl(dp->reg_base + phy_pd_addr);
 		if (enable)
 			reg |= mask;
 		else

-- 
2.43.0

