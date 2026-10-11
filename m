From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 11 Oct 2026 21:35:46 +0200
Subject: [PATCH v2 4/9] video: rockchip: dw_mipi_dsi: account for burst
 mode in the lane rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-b4-pinephone-pro-defconfig-v2-4-6b7be35fbee7@protonmail.com>
References: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
In-Reply-To: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Peter Robinson <pbrobinson@gmail.com>, David Heidelberg <david@ixit.cz>, 
 Ondrej Jirman <megi@xff.cz>, Tom Rini <trini@konsulko.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, Simon Glass <sjg@chromium.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Lukasz Majewski <lukma@denx.de>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791747347; l=2791;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=55ZJhhJdUuVFaftrDXmUm8u9CiuNcYH0bDSCxuumNx8=;
 b=0OEV/xHVr5A/TtG9XRI6wYEpVUrYfKusps1+DLSSDndhGSv5nLufx7uT16voEDwL2JC0S2rm+
 m/zzvjUE/gSD38n6kVbM26o21Xso7jYB73xTXowf6E0AaqI7LnncRjb
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Derive the lane rate from the pixel clock, bpp and lane count.
Add the 20% burst margin when the panel uses burst mode and fail with
-EINVAL instead of carrying on when the rate exceeds what the D-PHY
supports. Pass the computed rate to the external D-PHY helper
instead of a pixel clock based approximation.

Unlike the mainline Linux driver, which adds a flat 25% margin, this
only adds the margin that burst mode needs.

Based on megi's 0711c54e94c ("video: dw-mipi-dsi: Sync-up with
Linux driver"), https://codeberg.org/megi/u-boot

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/video/rockchip/dw_mipi_dsi_rockchip.c | 24 ++++++++++--------------
 1 file changed, 10 insertions(+), 14 deletions(-)

diff --git a/drivers/video/rockchip/dw_mipi_dsi_rockchip.c b/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
index fa512173510..c47992dfb13 100644
--- a/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
+++ b/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
@@ -526,8 +526,6 @@ dw_mipi_dsi_get_lane_mbps(void *priv_data, struct display_timing *timings,
 	struct udevice *dev = device->dev;
 	struct dw_rockchip_dsi_priv *dsi = dev_get_priv(dev);
 	int bpp;
-	unsigned long mpclk, tmp;
-	unsigned int target_mbps = 1000;
 	unsigned int max_mbps = dppa_map[ARRAY_SIZE(dppa_map) - 1].max_mbps;
 	unsigned long best_freq = 0;
 	unsigned long fvco_min, fvco_max, fin, fout;
@@ -544,30 +542,28 @@ dw_mipi_dsi_get_lane_mbps(void *priv_data, struct display_timing *timings,
 		return bpp;
 	}
 
-	mpclk = DIV_ROUND_UP(timings->pixelclock.typ, 1000);
-	if (mpclk) {
-		/* take 1 / 0.8, since mbps must big than bandwidth of RGB */
-		tmp = (mpclk * (bpp / lanes) * 10 / 8) / 1000;
-		if (tmp < max_mbps)
-			target_mbps = tmp;
-		else
-			dev_err(dsi->dsi_host,
-				"DPHY clock frequency is out of range\n");
+	fout = timings->pixelclock.typ / MSEC_PER_SEC * bpp / lanes;
+	if (device->mode_flags & MIPI_DSI_MODE_VIDEO_BURST)
+		fout = fout * 12 / 10;
+	fout *= MSEC_PER_SEC;
+
+	if (fout > max_mbps * USEC_PER_SEC) {
+		dev_err(dsi->dsi_host, "DPHY clock frequency is out of range\n");
+		return -EINVAL;
 	}
 
 	/* for external phy only the mipi_dphy_config is necessary */
 	if (generic_phy_valid(&dsi->phy)) {
-		phy_mipi_dphy_get_default_config(timings->pixelclock.typ  * 10 / 8,
+		phy_mipi_dphy_get_default_config(fout / bpp * lanes,
 						 bpp, lanes,
 						 &dsi->phy_opts);
-		dsi->lane_mbps = target_mbps;
+		dsi->lane_mbps = DIV_ROUND_UP(fout, USEC_PER_SEC);
 		*lane_mbps = dsi->lane_mbps;
 
 		return 0;
 	}
 
 	fin = clk_get_rate(dsi->ref);
-	fout = target_mbps * USEC_PER_SEC;
 
 	/* constraint: 5Mhz <= Fref / N <= 40MHz */
 	min_prediv = DIV_ROUND_UP(fin, 40 * USEC_PER_SEC);

-- 
2.55.0

