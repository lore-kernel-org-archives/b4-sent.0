From: Demeter Barna <me@fromdisposition.org>
Date: Mon, 12 Oct 2026 07:47:55 +0000
Subject: [PATCH] drm/panel: visionox-vtdr6130: Add 120, 90 and 60 Hz modes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-vtdr6130-refresh-rates-v1-1-f6053b328e2a@fromdisposition.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrDuQSSVCryIuNJnU6cKWmVQK4
 t2NdvnxeP8Gxips8Gg2UF7F5L1U0K2BOI/Lk1FSNXjnAznyuJakge4OlbOyzahjYUOKqfM5T9x
 2Aer5U2f5XeF++Nu+04tjOWuw7wc/Nd91egAAAA==
X-Change-ID: 20261012-vtdr6130-refresh-rates-1cd72ffbe476
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791791286; l=11768;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=UdzeIu9dT5hZaoSKST+cAWFNeHEnoRPZTbrecaVBh+o=;
 b=U7fKZazHB1UR9GbtkW97qfAMueI2M1E3d5/sY+hM3j3a31I16sPKA21sntp2PAqi2SOj+BAEN
 rt0NHVv+rCgBhNvODvRX1V+Eob+xnAhkPmWDAP/h7vSti/ebvJs7WLA
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The panel runs at 60, 90, 120 and 144 Hz, but the driver only exposes
144 Hz.

Add the lower refresh rates. They keep the pixel clock and the
horizontal timings of the 144 Hz mode and stretch the vertical front
porch. Each mode carries the values of registers 0x6c, 0xb1 and
0xce/0xd3 that the panel vendor programs for its rate, taken from the
panel configuration shipped with the Razer Edge; the power-on sequence
writes them where it wrote the 144 Hz values, so 144 Hz is programmed as
before. As in panel-novatek-nt35950, the mode is looked up in the CRTC
state at prepare time, so a rate change goes through a full modeset.

get_modes() now exposes every mode of the panel description, the first
one preferred; the Retroid Pocket 6 description has one.

Assisted-by: LLM
Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
This applies on top of Aaron Kling's Retroid Pocket 6 series in
drm-misc-next ("drm/panel: visionox-vtdr6130: Modularize panel config"),
whose per-panel description it extends.

Tested on a Razer Edge 5G, whose board support is not upstream yet:
switched through KDE, every one of the twelve transitions between 144,
120, 90 and 60 Hz lands on the requested mode at the expected frame
rate with no DPU underrun; panel off and on, and suspend and resume,
keep each rate. The Retroid Pocket 6 path is built but not tested.
---
 drivers/gpu/drm/panel/panel-visionox-vtdr6130.c | 204 +++++++++++++++++++-----
 1 file changed, 161 insertions(+), 43 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c b/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
index d0db128cda81..a1fd09548073 100644
--- a/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
+++ b/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
@@ -10,6 +10,7 @@
 
 #include <drm/display/drm_dsc.h>
 #include <drm/display/drm_dsc_helper.h>
+#include <drm/drm_crtc.h>
 #include <drm/drm_mipi_dsi.h>
 #include <drm/drm_of.h>
 #include <drm/drm_modes.h>
@@ -19,6 +20,7 @@
 
 struct visionox_vtdr6130 {
 	struct drm_panel panel;
+	struct drm_connector *connector;
 	struct mipi_dsi_device *dsi;
 	struct gpio_desc *reset_gpio;
 	struct regulator_bulk_data *supplies;
@@ -26,13 +28,24 @@ struct visionox_vtdr6130 {
 	struct visionox_vtdr6130_desc *desc;
 };
 
+/*
+ * A mode and, for the VTDR6130's own power-on sequence, the 0x6c, 0xb1 and
+ * 0xce/0xd3 values the panel vendor programs for its refresh rate
+ */
+struct visionox_vtdr6130_mode {
+	struct drm_display_mode mode;
+	u8 rate;
+	u8 b1[22];
+	u8 tune[24];
+};
+
 struct visionox_vtdr6130_desc {
 	unsigned int bpc;
 	unsigned int lanes;
 	unsigned long mode_flags;
 	enum mipi_dsi_pixel_format format;
 
-	const struct drm_display_mode *modes;
+	const struct visionox_vtdr6130_mode *modes;
 	unsigned int num_modes;
 	int (*init_sequence)(struct visionox_vtdr6130 *ctx);
 
@@ -136,8 +149,30 @@ static int retroidpocket_rp6_on(struct visionox_vtdr6130 *ctx)
 	return dsi_ctx.accum_err;
 }
 
+static const struct visionox_vtdr6130_mode *
+visionox_vtdr6130_mode(struct visionox_vtdr6130 *ctx)
+{
+	const struct visionox_vtdr6130_desc *desc = ctx->desc;
+	struct drm_connector *connector = ctx->connector;
+	const struct drm_display_mode *mode;
+	unsigned int i;
+
+	if (!connector || !connector->state || !connector->state->crtc)
+		return &desc->modes[0];
+
+	mode = &connector->state->crtc->state->mode;
+
+	for (i = 0; i < desc->num_modes; i++)
+		if (drm_mode_match(mode, &desc->modes[i].mode,
+				   DRM_MODE_MATCH_TIMINGS | DRM_MODE_MATCH_CLOCK))
+			return &desc->modes[i];
+
+	return &desc->modes[0];
+}
+
 static int visionox_vtdr6130_on(struct visionox_vtdr6130 *ctx)
 {
+	const struct visionox_vtdr6130_mode *m = visionox_vtdr6130_mode(ctx);
 	struct mipi_dsi_device *dsi = ctx->dsi;
 	struct mipi_dsi_multi_context dsi_ctx = { .dsi = dsi };
 	struct drm_dsc_picture_parameter_set pps;
@@ -154,7 +189,7 @@ static int visionox_vtdr6130_on(struct visionox_vtdr6130 *ctx)
 				     MIPI_DCS_SET_DISPLAY_BRIGHTNESS, 0x00,
 				     0x00);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x59, 0x09);
-	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x6c, 0x01);
+	mipi_dsi_dcs_write_var_seq_multi(&dsi_ctx, 0x6c, m->rate);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x6d, 0x00);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x6f, 0x01);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x70, 0x12, 0x00, 0x00, 0xab,
@@ -172,15 +207,9 @@ static int visionox_vtdr6130_on(struct visionox_vtdr6130 *ctx)
 				     0xf4, 0x4b, 0xf4, 0x6c, 0x34, 0x84, 0x74,
 				     0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0xaa, 0x10);
-	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb1, 0x01, 0x38, 0x00, 0x14,
-				     0x00, 0x1c, 0x00, 0x01, 0x66, 0x00, 0x14,
-				     0x00, 0x14, 0x00, 0x01, 0x66, 0x00, 0x14,
-				     0x05, 0xcc, 0x00);
+	mipi_dsi_dcs_write_buffer_multi(&dsi_ctx, m->b1, sizeof(m->b1));
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0xaa, 0x13);
-	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xce, 0x09, 0x11, 0x09, 0x11,
-				     0x08, 0xc1, 0x07, 0xfa, 0x05, 0xa4, 0x00,
-				     0x3c, 0x00, 0x34, 0x00, 0x24, 0x00, 0x0c,
-				     0x00, 0x0c, 0x04, 0x00, 0x35);
+	mipi_dsi_dcs_write_buffer_multi(&dsi_ctx, m->tune, sizeof(m->tune));
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0xaa, 0x14);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb2, 0x03, 0x33);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb4, 0x00, 0x33, 0x00, 0x00,
@@ -276,19 +305,21 @@ static int visionox_vtdr6130_unprepare(struct drm_panel *panel)
 	return 0;
 }
 
-static const struct drm_display_mode retroidpocket_rp6_modes[] = {
+static const struct visionox_vtdr6130_mode retroidpocket_rp6_modes[] = {
 	{
-		.clock = (1080 + 22 + 2 + 16) * (1920 + 16 + 2 + 20) * 120 / 1000,
-		.hdisplay = 1080,
-		.hsync_start = 1080 + 22,
-		.hsync_end = 1080 + 22 + 2,
-		.htotal = 1080 + 22 + 2 + 16,
-		.vdisplay = 1920,
-		.vsync_start = 1920 + 16,
-		.vsync_end = 1920 + 16 + 2,
-		.vtotal = 1920 + 16 + 2 + 20,
-		.width_mm = 69,
-		.height_mm = 122,
+		.mode = {
+			.clock = (1080 + 22 + 2 + 16) * (1920 + 16 + 2 + 20) * 120 / 1000,
+			.hdisplay = 1080,
+			.hsync_start = 1080 + 22,
+			.hsync_end = 1080 + 22 + 2,
+			.htotal = 1080 + 22 + 2 + 16,
+			.vdisplay = 1920,
+			.vsync_start = 1920 + 16,
+			.vsync_end = 1920 + 16 + 2,
+			.vtotal = 1920 + 16 + 2 + 20,
+			.width_mm = 69,
+			.height_mm = 122,
+		},
 	},
 };
 
@@ -313,19 +344,98 @@ static struct visionox_vtdr6130_desc retroidpocket_rp6_panel_desc = {
 	},
 };
 
-static const struct drm_display_mode visionox_vtdr6130_modes[] = {
+/*
+ * All modes share one pixel clock and the horizontal timings; the lower
+ * rates stretch the vertical front porch.
+ */
+static const struct visionox_vtdr6130_mode visionox_vtdr6130_modes[] = {
 	{
-		.clock = (1080 + 20 + 2 + 20) * (2400 + 20 + 2 + 18) * 144 / 1000,
-		.hdisplay = 1080,
-		.hsync_start = 1080 + 20,
-		.hsync_end = 1080 + 20 + 2,
-		.htotal = 1080 + 20 + 2 + 20,
-		.vdisplay = 2400,
-		.vsync_start = 2400 + 20,
-		.vsync_end = 2400 + 20 + 2,
-		.vtotal = 2400 + 20 + 2 + 18,
-		.width_mm = 71,
-		.height_mm = 157,
+		.mode = {
+			.clock = (1080 + 20 + 2 + 20) * (2400 + 20 + 2 + 18) * 144 / 1000,
+			.hdisplay = 1080,
+			.hsync_start = 1080 + 20,
+			.hsync_end = 1080 + 20 + 2,
+			.htotal = 1080 + 20 + 2 + 20,
+			.vdisplay = 2400,
+			.vsync_start = 2400 + 20,
+			.vsync_end = 2400 + 20 + 2,
+			.vtotal = 2400 + 20 + 2 + 18,
+			.width_mm = 71,
+			.height_mm = 157,
+		},
+		.rate = 0x01,
+		.b1 = { 0xb1, 0x01, 0x38, 0x00, 0x14, 0x00, 0x1c, 0x00, 0x01,
+			  0x66, 0x00, 0x14, 0x00, 0x14, 0x00, 0x01, 0x66, 0x00,
+			  0x14, 0x05, 0xcc, 0x00 },
+		.tune = { 0xce, 0x09, 0x11, 0x09, 0x11, 0x08, 0xc1, 0x07, 0xfa,
+			   0x05, 0xa4, 0x00, 0x3c, 0x00, 0x34, 0x00, 0x24, 0x00,
+			   0x0c, 0x00, 0x0c, 0x04, 0x00, 0x35 },
+	},
+	{
+		.mode = {
+			.clock = (1080 + 20 + 2 + 20) * (2400 + 508 + 2 + 18) * 120 / 1000,
+			.hdisplay = 1080,
+			.hsync_start = 1080 + 20,
+			.hsync_end = 1080 + 20 + 2,
+			.htotal = 1080 + 20 + 2 + 20,
+			.vdisplay = 2400,
+			.vsync_start = 2400 + 508,
+			.vsync_end = 2400 + 508 + 2,
+			.vtotal = 2400 + 508 + 2 + 18,
+			.width_mm = 71,
+			.height_mm = 157,
+		},
+		.rate = 0x01,
+		.b1 = { 0xb1, 0x01, 0x38, 0x00, 0x14, 0x00, 0x1c, 0x00, 0x01,
+			  0x66, 0x00, 0x14, 0x01, 0xfc, 0x00, 0x01, 0x66, 0x00,
+			  0x14, 0x0d, 0x6c, 0x00 },
+		.tune = { 0xce, 0x0a, 0xe1, 0x0a, 0xe1, 0x0a, 0x81, 0x09, 0x92,
+			   0x06, 0xc5, 0x00, 0x48, 0x00, 0x3e, 0x00, 0x2b, 0x00,
+			   0x0c, 0x00, 0x0c, 0x05, 0x00, 0x3f },
+	},
+	{
+		.mode = {
+			.clock = (1080 + 20 + 2 + 20) * (2400 + 1484 + 2 + 18) * 90 / 1000,
+			.hdisplay = 1080,
+			.hsync_start = 1080 + 20,
+			.hsync_end = 1080 + 20 + 2,
+			.htotal = 1080 + 20 + 2 + 20,
+			.vdisplay = 2400,
+			.vsync_start = 2400 + 1484,
+			.vsync_end = 2400 + 1484 + 2,
+			.vtotal = 2400 + 1484 + 2 + 18,
+			.width_mm = 71,
+			.height_mm = 157,
+		},
+		.rate = 0x02,
+		.b1 = { 0xb1, 0x01, 0x38, 0x00, 0x14, 0x00, 0x1c, 0x00, 0x01,
+			  0x66, 0x00, 0x14, 0x00, 0x14, 0x00, 0x01, 0x66, 0x00,
+			  0x14, 0x05, 0xcc, 0x00 },
+		.tune = { 0xd3, 0x0e, 0x81, 0x0e, 0x81, 0x0e, 0x01, 0x0c, 0xc3,
+			   0x09, 0x06, 0x00, 0x60, 0x00, 0x53, 0x00, 0x3a, 0x00,
+			   0x0c, 0x00, 0x0c, 0x07, 0x00, 0x54 },
+	},
+	{
+		.mode = {
+			.clock = (1080 + 20 + 2 + 20) * (2400 + 3436 + 2 + 18) * 60 / 1000,
+			.hdisplay = 1080,
+			.hsync_start = 1080 + 20,
+			.hsync_end = 1080 + 20 + 2,
+			.htotal = 1080 + 20 + 2 + 20,
+			.vdisplay = 2400,
+			.vsync_start = 2400 + 3436,
+			.vsync_end = 2400 + 3436 + 2,
+			.vtotal = 2400 + 3436 + 2 + 18,
+			.width_mm = 71,
+			.height_mm = 157,
+		},
+		.rate = 0x02,
+		.b1 = { 0xb1, 0x01, 0x38, 0x00, 0x14, 0x00, 0x1c, 0x00, 0x01,
+			  0x66, 0x00, 0x14, 0x01, 0xfc, 0x00, 0x01, 0x66, 0x00,
+			  0x14, 0x0d, 0x6c, 0x00 },
+		.tune = { 0xd3, 0x15, 0xc2, 0x15, 0xc2, 0x15, 0x02, 0x13, 0x25,
+			   0x0d, 0x8a, 0x00, 0x90, 0x00, 0x7d, 0x00, 0x57, 0x00,
+			   0x0c, 0x00, 0x0c, 0x0b, 0x00, 0x7e },
 	},
 };
 
@@ -354,20 +464,28 @@ static int visionox_vtdr6130_get_modes(struct drm_panel *panel,
 				       struct drm_connector *connector)
 {
 	struct visionox_vtdr6130 *ctx = to_visionox_vtdr6130(panel);
+	const struct visionox_vtdr6130_desc *desc = ctx->desc;
 	struct drm_display_mode *mode;
+	unsigned int i;
 
-	mode = drm_mode_duplicate(connector->dev, ctx->desc->modes);
-	if (!mode)
-		return -ENOMEM;
+	for (i = 0; i < desc->num_modes; i++) {
+		mode = drm_mode_duplicate(connector->dev, &desc->modes[i].mode);
+		if (!mode)
+			return -ENOMEM;
 
-	drm_mode_set_name(mode);
+		drm_mode_set_name(mode);
+
+		mode->type = DRM_MODE_TYPE_DRIVER;
+		if (i == 0)
+			mode->type |= DRM_MODE_TYPE_PREFERRED;
+		drm_mode_probed_add(connector, mode);
+	}
 
-	mode->type = DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED;
-	connector->display_info.width_mm = mode->width_mm;
-	connector->display_info.height_mm = mode->height_mm;
-	drm_mode_probed_add(connector, mode);
+	connector->display_info.width_mm = desc->modes[0].mode.width_mm;
+	connector->display_info.height_mm = desc->modes[0].mode.height_mm;
+	ctx->connector = connector;
 
-	return 1;
+	return desc->num_modes;
 }
 
 static enum drm_panel_orientation visionox_vtdr6130_get_orientation(struct drm_panel *panel)

---
base-commit: 73df79cceb8c01f311055a61794e229dc81546cb
change-id: 20261012-vtdr6130-refresh-rates-1cd72ffbe476

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

