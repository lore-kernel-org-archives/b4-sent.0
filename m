From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 14 Aug 2026 13:17:17 -0500
Subject: [PATCH 3/4] drm/panel: visionox-vtdr6130: Modularize panel config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-rp6-panel-v1-3-111c1aeccf0f@gmail.com>
References: <20260814-rp6-panel-v1-0-111c1aeccf0f@gmail.com>
In-Reply-To: <20260814-rp6-panel-v1-0-111c1aeccf0f@gmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786731444; l=5467;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=DCitivrRVpNuYH4Jt4HFt8eBqH1HZ4CWSQVXa+YmjUU=;
 b=Z4WxlA+rHdTHwk1JjtkjjZrFN8y0j6keSVeVkhdu6FCpmSBUtSA2d5OWFy5gKaKHhPcPJzfyg
 2rRXcgU7y1uDi/INWgHUuKPdRG1DHwL5a65oO5rNshz3AC+cm12jaG3
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vtdr6130 is a DDIC, a common chip that is used by multiple panels.
Prepare the driver for more panels.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpu/drm/panel/panel-visionox-vtdr6130.c | 95 +++++++++++++++++--------
 1 file changed, 65 insertions(+), 30 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c b/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
index b66d6c7128c75..805c9846c2a0b 100644
--- a/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
+++ b/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
@@ -19,11 +19,28 @@
 
 struct visionox_vtdr6130 {
 	struct drm_panel panel;
-	struct drm_dsc_config dsc;
+	struct drm_connector *connector;
 	struct mipi_dsi_device *dsi;
 	struct gpio_desc *reset_gpio;
 	struct regulator_bulk_data *supplies;
 	enum drm_panel_orientation orientation;
+	struct visionox_vtdr6130_desc *desc;
+};
+
+struct visionox_vtdr6130_desc {
+	unsigned int width_mm;
+	unsigned int height_mm;
+
+	unsigned int bpc;
+	unsigned int lanes;
+	unsigned long mode_flags;
+	enum mipi_dsi_pixel_format format;
+
+	const struct drm_display_mode *modes;
+	unsigned int num_modes;
+	int (*init_sequence)(struct visionox_vtdr6130 *ctx);
+
+	struct drm_dsc_config dsc;
 };
 
 static const struct regulator_bulk_data visionox_vtdr6130_supplies[] = {
@@ -162,7 +179,7 @@ static int visionox_vtdr6130_prepare(struct drm_panel *panel)
 
 	visionox_vtdr6130_reset(ctx);
 
-	ret = visionox_vtdr6130_on(ctx);
+	ret = ctx->desc->init_sequence(ctx);
 	if (ret < 0) {
 		gpiod_set_value_cansleep(ctx->reset_gpio, 1);
 		regulator_bulk_disable(ARRAY_SIZE(visionox_vtdr6130_supplies),
@@ -187,34 +204,58 @@ static int visionox_vtdr6130_unprepare(struct drm_panel *panel)
 	return 0;
 }
 
-static const struct drm_display_mode visionox_vtdr6130_mode = {
-	.clock = (1080 + 20 + 2 + 20) * (2400 + 20 + 2 + 18) * 144 / 1000,
-	.hdisplay = 1080,
-	.hsync_start = 1080 + 20,
-	.hsync_end = 1080 + 20 + 2,
-	.htotal = 1080 + 20 + 2 + 20,
-	.vdisplay = 2400,
-	.vsync_start = 2400 + 20,
-	.vsync_end = 2400 + 20 + 2,
-	.vtotal = 2400 + 20 + 2 + 18,
+static const struct drm_display_mode visionox_vtdr6130_modes[] = {
+	{
+		.clock = (1080 + 20 + 2 + 20) * (2400 + 20 + 2 + 18) * 144 / 1000,
+		.hdisplay = 1080,
+		.hsync_start = 1080 + 20,
+		.hsync_end = 1080 + 20 + 2,
+		.htotal = 1080 + 20 + 2 + 20,
+		.vdisplay = 2400,
+		.vsync_start = 2400 + 20,
+		.vsync_end = 2400 + 20 + 2,
+		.vtotal = 2400 + 20 + 2 + 18,
+	},
+};
+
+static struct visionox_vtdr6130_desc visionox_vtdr6130_panel_desc = {
+	.modes = visionox_vtdr6130_modes,
+	.num_modes = ARRAY_SIZE(visionox_vtdr6130_modes),
 	.width_mm = 71,
 	.height_mm = 157,
+	.bpc = 8,
+	.lanes = 4,
+	.format = MIPI_DSI_FMT_RGB888,
+	.mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_NO_EOT_PACKET |
+		      MIPI_DSI_CLOCK_NON_CONTINUOUS,
+	.init_sequence = visionox_vtdr6130_on,
+	.dsc = {
+		.dsc_version_major = 0x1,
+		.dsc_version_minor = 0x2,
+		.slice_height = 40,
+		.slice_width = 540,
+		.slice_count = 2,
+		.bits_per_component = 8,
+		.bits_per_pixel = 8 << 4,
+		.block_pred_enable = true,
+	},
 };
 
 static int visionox_vtdr6130_get_modes(struct drm_panel *panel,
 				       struct drm_connector *connector)
 {
+	struct visionox_vtdr6130 *ctx = to_visionox_vtdr6130(panel);
 	struct drm_display_mode *mode;
 
-	mode = drm_mode_duplicate(connector->dev, &visionox_vtdr6130_mode);
+	mode = drm_mode_duplicate(connector->dev, ctx->desc->modes);
 	if (!mode)
 		return -ENOMEM;
 
 	drm_mode_set_name(mode);
 
 	mode->type = DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED;
-	connector->display_info.width_mm = mode->width_mm;
-	connector->display_info.height_mm = mode->height_mm;
+	connector->display_info.width_mm = ctx->desc->width_mm;
+	connector->display_info.height_mm = ctx->desc->height_mm;
 	drm_mode_probed_add(connector, mode);
 
 	return 1;
@@ -284,23 +325,17 @@ static int visionox_vtdr6130_probe(struct mipi_dsi_device *dsi)
 		return dev_err_probe(dev, PTR_ERR(ctx->reset_gpio),
 				     "Failed to get reset-gpios\n");
 
+	ctx->desc = (struct visionox_vtdr6130_desc *)of_device_get_match_data(dev);
+	if (!ctx->desc)
+		return -ENODEV;
+
 	ctx->dsi = dsi;
 	mipi_dsi_set_drvdata(dsi, ctx);
 
-	ctx->dsc.dsc_version_major = 0x1;
-	ctx->dsc.dsc_version_minor = 0x2;
-	ctx->dsc.slice_height = 40;
-	ctx->dsc.slice_width = 540;
-	ctx->dsc.slice_count = 2;
-	ctx->dsc.bits_per_component = 8;
-	ctx->dsc.bits_per_pixel = 8 << 4;
-	ctx->dsc.block_pred_enable = true;
-
-	dsi->dsc = &ctx->dsc;
-	dsi->lanes = 4;
-	dsi->format = MIPI_DSI_FMT_RGB888;
-	dsi->mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_NO_EOT_PACKET |
-			  MIPI_DSI_CLOCK_NON_CONTINUOUS;
+	dsi->dsc = &ctx->desc->dsc;
+	dsi->lanes = ctx->desc->lanes;
+	dsi->format = ctx->desc->format;
+	dsi->mode_flags = ctx->desc->mode_flags;
 	ctx->panel.prepare_prev_first = true;
 
 	ret = drm_of_get_panel_orientation(dev->of_node, &ctx->orientation);
@@ -322,7 +357,7 @@ static int visionox_vtdr6130_probe(struct mipi_dsi_device *dsi)
 }
 
 static const struct of_device_id visionox_vtdr6130_of_match[] = {
-	{ .compatible = "visionox,vtdr6130" },
+	{ .compatible = "visionox,vtdr6130", .data = &visionox_vtdr6130_panel_desc },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, visionox_vtdr6130_of_match);

-- 
2.54.0

