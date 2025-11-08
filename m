From: Dang Huynh <dang.huynh@mainlining.org>
Date: Sat, 08 Nov 2025 12:38:00 +0700
Subject: [PATCH v6 04/12] video: rockchip: dw-mipi-dsi: Add
 get_display_timing support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251108-vop2-pt2-v6-4-d04c699262fb@mainlining.org>
References: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
In-Reply-To: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
To: u-boot@lists.denx.de
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Simon Glass <sjg@chromium.org>, Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Tom Rini <trini@konsulko.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, Alexander Graf <agraf@csgraf.de>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 Ion Agorria <ion@agorria.com>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 Dragan Simic <dsimic@manjaro.org>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Piotr Zalewski <pZ010001011111@proton.me>, 
 Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762580305; l=2654;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=iUQXySfSUyJ+Buba3j5JH3Z53jTKZsMqDkzdlnhApc8=;
 b=tDCCT/IsbMPUg3cCS6B6sD+4NX32AyEvaKk1U8g/wjW3ZrRPqre3o9sX44qFAHouGd20u5HZK
 eu+Fwir+i53B8k4R92g8j8Au4gP+8LVek4IFMeHLzE360GPR4BGxNtf
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This allows video drivers to obtain display timings from the video
bridge.

Reviewed-by: Svyatoslav Ryhel <clamor95@gmail.com>
Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 drivers/video/rockchip/dw_mipi_dsi_rockchip.c | 19 +++++++++++++++----
 1 file changed, 15 insertions(+), 4 deletions(-)

diff --git a/drivers/video/rockchip/dw_mipi_dsi_rockchip.c b/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
index 95e825eb3d6..d21ea7953a6 100644
--- a/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
+++ b/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
@@ -224,6 +224,7 @@ struct dw_rockchip_dsi_priv {
 	struct mipi_dsi_device device;
 	void __iomem *base;
 	struct udevice *panel;
+	struct display_timing timings;
 	void __iomem *grf;
 
 	/* Optional external dphy */
@@ -709,7 +710,7 @@ static int dw_mipi_dsi_rockchip_attach(struct udevice *dev)
 	struct dw_rockchip_dsi_priv *priv = dev_get_priv(dev);
 	struct mipi_dsi_device *device = &priv->device;
 	struct mipi_dsi_panel_plat *mplat;
-	struct display_timing timings;
+	struct display_timing *timings = &priv->timings;
 	int ret;
 
 	ret = uclass_first_device_err(UCLASS_PANEL, &priv->panel);
@@ -724,10 +725,10 @@ static int dw_mipi_dsi_rockchip_attach(struct udevice *dev)
 	device->format = mplat->format;
 	device->mode_flags = mplat->mode_flags;
 
-	ret = panel_get_display_timing(priv->panel, &timings);
+	ret = panel_get_display_timing(priv->panel, timings);
 	if (ret) {
 		ret = ofnode_decode_display_timing(dev_ofnode(priv->panel),
-						   0, &timings);
+						   0, timings);
 		if (ret) {
 			dev_err(dev, "decode display timing error %d\n", ret);
 			return ret;
@@ -740,7 +741,7 @@ static int dw_mipi_dsi_rockchip_attach(struct udevice *dev)
 		return ret;
 	}
 
-	ret = dsi_host_init(priv->dsi_host, device, &timings, 4,
+	ret = dsi_host_init(priv->dsi_host, device, timings, 4,
 			    &dsi_rockchip_phy_ops);
 	if (ret) {
 		dev_err(dev, "failed to initialize mipi dsi host\n");
@@ -902,9 +903,19 @@ static int dw_mipi_dsi_rockchip_probe(struct udevice *dev)
 	return 0;
 }
 
+static int dw_mipi_dsi_rockchip_get_dt(struct udevice *dev,
+				       struct display_timing *timings)
+{
+	struct dw_rockchip_dsi_priv *priv = dev_get_priv(dev);
+
+	memcpy(timings, &priv->timings, sizeof(*timings));
+	return 0;
+}
+
 struct video_bridge_ops dw_mipi_dsi_rockchip_ops = {
 	.attach = dw_mipi_dsi_rockchip_attach,
 	.set_backlight = dw_mipi_dsi_rockchip_set_bl,
+	.get_display_timing = dw_mipi_dsi_rockchip_get_dt,
 };
 
 static const struct rockchip_dw_dsi_chip_data rk3399_chip_data[] = {

-- 
2.51.2

