From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 14 Aug 2026 13:17:18 -0500
Subject: [PATCH 4/4] drm/panel: visionox-vtdr6130: Add Retroid Pocket 6
 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-rp6-panel-v1-4-111c1aeccf0f@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786731444; l=5955;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=ScONlIwrZwNMIN+M+MGr8r32XLjgu4rOUqB4e+erUgM=;
 b=p9lT/EMgzOHfrzYKT9P7Pdttysxrovh1I7+q7zIQ9X2FyuG0ekb4kXgPVFrv3g2hWGRg6zNXb
 WgaXolNh38XCru0gvJoR5DLNz1+kx+nPy+Oen6YGukigzDwdeMuZuMH
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the 1080x1920 panel used in the Retroid Pocket 6.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpu/drm/panel/panel-visionox-vtdr6130.c | 114 ++++++++++++++++++++++++
 1 file changed, 114 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c b/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
index 805c9846c2a0b..5c826f95ec478 100644
--- a/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
+++ b/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
@@ -64,6 +64,82 @@ static void visionox_vtdr6130_reset(struct visionox_vtdr6130 *ctx)
 	usleep_range(10000, 11000);
 }
 
+static int retroidpocket_rp6_on(struct visionox_vtdr6130 *ctx)
+{
+	struct mipi_dsi_device *dsi = ctx->dsi;
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = dsi };
+	struct drm_dsc_picture_parameter_set pps;
+
+	dsi->mode_flags |= MIPI_DSI_MODE_LPM;
+
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x03, 0x01);
+	mipi_dsi_dcs_set_tear_on_multi(&dsi_ctx, MIPI_DSI_DCS_TEAR_MODE_VBLANK);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx,
+				     MIPI_DCS_WRITE_CONTROL_DISPLAY, 0x20);
+	mipi_dsi_dcs_set_display_brightness_multi(&dsi_ctx, 0xff07);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x6f, 0x02);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, MIPI_DCS_SET_ADDRESS_MODE, 0x02);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x59, 0x00);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x6c, 0x00);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x6d, 0x00);
+
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x70, 0x11, 0x00, 0x00, 0x89,
+				     0x30, 0x80, 0x07, 0x80, 0x04, 0x38, 0x00,
+				     0x14, 0x02, 0x1c, 0x02, 0x1c, 0x02, 0x00,
+				     0x02, 0x25, 0x00, 0x20, 0x01, 0xd5, 0x00,
+				     0x07, 0x00, 0x0d, 0x05, 0x7a, 0x05, 0x16,
+				     0x18, 0x00, 0x10, 0xf0, 0x03, 0x0c, 0x20,
+				     0x00, 0x06, 0x0b, 0x0b, 0x33, 0x0e, 0x1c,
+				     0x2a, 0x38, 0x46, 0x54, 0x62, 0x69, 0x70,
+				     0x77, 0x79, 0x7b, 0x7d, 0x7e, 0x01, 0x02,
+				     0x01, 0x00, 0x09, 0x40, 0x09, 0xbe, 0x19,
+				     0xfc, 0x19, 0xfa, 0x19, 0xf8, 0x1a, 0x38,
+				     0x1a, 0x78, 0x1a, 0xb6, 0x2a, 0xb6, 0x2a,
+				     0xf4, 0x2a, 0xf4, 0x4b, 0x34, 0x63, 0x74,
+				     0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
+
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0xaa, 0x10);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb1, 0x02, 0x15, 0x00, 0x14,
+				     0x00, 0x20, 0x00, 0x02, 0x16, 0x00, 0x14,
+				     0x07, 0xb4, 0x00, 0x02, 0x16, 0x00, 0x14,
+				     0x00, 0x10, 0x00);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0xaa, 0x14);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb2, 0x03, 0x33);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb4, 0x0a, 0x72, 0x00, 0x00,
+				     0x0a, 0x72, 0x00, 0x00, 0x0a, 0x72, 0x00,
+				     0x00);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb5, 0x00, 0x1e, 0x1e, 0x1e,
+				     0x1e, 0x1e, 0x1e, 0x06, 0x01);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xb9, 0x00, 0x00, 0x08, 0x1e,
+				     0x1e, 0x1e);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xbc, 0x10, 0x00, 0x00, 0x08,
+				     0x11, 0x1e, 0x7c, 0x1e, 0x7c, 0x1e, 0x7c);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xbe, 0x10, 0x10, 0x00, 0x0c,
+				     0x22, 0x1e, 0x62, 0x1e, 0x62, 0x1e, 0x62);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xff, 0x5a, 0x80);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x65, 0x13);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xfd, 0x01);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xff, 0x5a, 0x81);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf9, 0x00);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xff, 0x5a, 0x83);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x65, 0x04);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf8, 0x00);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xf0, 0xaa, 0x00);
+	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0xff, 0x5a, 0x00);
+
+	mipi_dsi_dcs_exit_sleep_mode_multi(&dsi_ctx);
+	mipi_dsi_msleep(&dsi_ctx, 150);
+
+	mipi_dsi_dcs_set_display_on_multi(&dsi_ctx);
+	mipi_dsi_msleep(&dsi_ctx, 50);
+
+	drm_dsc_pps_payload_pack(&pps, dsi->dsc);
+	mipi_dsi_picture_parameter_set_multi(&dsi_ctx, &pps);
+	mipi_dsi_compression_mode_multi(&dsi_ctx, true);
+
+	return dsi_ctx.accum_err;
+}
+
 static int visionox_vtdr6130_on(struct visionox_vtdr6130 *ctx)
 {
 	struct mipi_dsi_device *dsi = ctx->dsi;
@@ -204,6 +280,43 @@ static int visionox_vtdr6130_unprepare(struct drm_panel *panel)
 	return 0;
 }
 
+static const struct drm_display_mode retroidpocket_rp6_modes[] = {
+	{
+		.clock = (1080 + 22 + 2 + 16) * (1920 + 16 + 2 + 20) * 120 / 1000,
+		.hdisplay = 1080,
+		.hsync_start = 1080 + 22,
+		.hsync_end = 1080 + 22 + 2,
+		.htotal = 1080 + 22 + 2 + 16,
+		.vdisplay = 1920,
+		.vsync_start = 1920 + 16,
+		.vsync_end = 1920 + 16 + 2,
+		.vtotal = 1920 + 16 + 2 + 20,
+	},
+};
+
+static struct visionox_vtdr6130_desc retroidpocket_rp6_panel_desc = {
+	.modes = retroidpocket_rp6_modes,
+	.num_modes = ARRAY_SIZE(retroidpocket_rp6_modes),
+	.width_mm = 69,
+	.height_mm = 122,
+	.bpc = 8,
+	.lanes = 4,
+	.format = MIPI_DSI_FMT_RGB888,
+	.mode_flags = MIPI_DSI_MODE_NO_EOT_PACKET |
+		      MIPI_DSI_CLOCK_NON_CONTINUOUS,
+	.init_sequence = retroidpocket_rp6_on,
+	.dsc = {
+		.dsc_version_major = 0x1,
+		.dsc_version_minor = 0x1,
+		.slice_height = 12,
+		.slice_width = 540,
+		.slice_count = 2,
+		.bits_per_component = 8,
+		.bits_per_pixel = 8 << 4,
+		.block_pred_enable = true,
+	},
+};
+
 static const struct drm_display_mode visionox_vtdr6130_modes[] = {
 	{
 		.clock = (1080 + 20 + 2 + 20) * (2400 + 20 + 2 + 18) * 144 / 1000,
@@ -357,6 +470,7 @@ static int visionox_vtdr6130_probe(struct mipi_dsi_device *dsi)
 }
 
 static const struct of_device_id visionox_vtdr6130_of_match[] = {
+	{ .compatible = "retroidpocket,rp6-panel", .data = &retroidpocket_rp6_panel_desc },
 	{ .compatible = "visionox,vtdr6130", .data = &visionox_vtdr6130_panel_desc },
 	{ /* sentinel */ }
 };

-- 
2.54.0

