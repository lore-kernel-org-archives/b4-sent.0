From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Thu, 23 Jul 2026 18:26:29 +0700
Subject: [PATCH 2/2] drm/panel: st7703: Add AYANEO Pocket DS Lower Panel
 Support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-st7703-pocketds-lower-v1-2-e3db246589f4@gmail.com>
References: <20260723-b4-st7703-pocketds-lower-v1-0-e3db246589f4@gmail.com>
In-Reply-To: <20260723-b4-st7703-pocketds-lower-v1-0-e3db246589f4@gmail.com>
To: =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Purism Kernel Team <kernel@puri.sm>, Ondrej Jirman <megi@xff.cz>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784805987; l=6713;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=D6WH87uV9HAlDohMFqrAFrLhQOOjQ9TG9czzjYKkajg=;
 b=QF6QCbzPLOgtAviXc7QzyfuWqUmwbol4V1Cu1W2dVzeCpbIuvkEamY75qJ//WYX/WWlkPIuDn
 54VdjRI6KtACZfmQ6BKCk/gtMIVxeaf6DsYVUU20jNFuuaDmVE9JrXv
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the lower (secondary) panel of the AYANEO Pocket DS, a
dual-screen QCS8550 (Snapdragon 8 Gen 2) handheld. It is a 5.0" 1024x768
4:3 IPS LCD driven by a Sitronix ST7703 DDIC: every command in the vendor
init sequence maps to an ST7703 manufacturer command (SETEXTC, SETMIPI,
SETRGBIF, SETSCR, SETPOWER, SETGAMMA, SETGIP1/2), and the SETMIPI and
SETRGBIF payloads are near-identical to the already-supported Powkiddy
RGB10MAX3.

The panel is mounted in portrait (768x1024) and rotated 270 degrees in
the device, expressed through the panel rotation property. The SETEXTC
unlock password ends in 0x87 rather than the canonical 0x83; this is the
value shipped by the vendor firmware and is kept verbatim.

Init sequence extracted from the AYANEO Pocket DS BSP kernel, via the
ROCKNIX SM8550 port.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 drivers/gpu/drm/panel/panel-sitronix-st7703.c | 96 +++++++++++++++++++++++++++
 1 file changed, 96 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-sitronix-st7703.c b/drivers/gpu/drm/panel/panel-sitronix-st7703.c
index 6c348fe28955..bfc03bdf3816 100644
--- a/drivers/gpu/drm/panel/panel-sitronix-st7703.c
+++ b/drivers/gpu/drm/panel/panel-sitronix-st7703.c
@@ -47,6 +47,7 @@
 #define ST7703_CMD_SETCABC	 0xC8
 #define ST7703_CMD_SETPANEL	 0xCC
 #define ST7703_CMD_SETGAMMA	 0xE0
+#define ST7703_CMD_UNKNOWN_E1	 0xE1
 #define ST7703_CMD_SETEQ	 0xE3
 #define ST7703_CMD_SETGIP1	 0xE9
 #define ST7703_CMD_SETGIP2	 0xEA
@@ -673,6 +674,100 @@ static const struct st7703_panel_desc gameforcechi_desc = {
 	.init_sequence = gameforcechi_init_sequence,
 };
 
+static void ayaneo_pocket_ds_lower_init_sequence(struct mipi_dsi_multi_context *dsi_ctx)
+{
+	/* Init sequence extracted from the AYANEO Pocket DS BSP kernel. */
+
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETEXTC, 0xf1, 0x12,
+				     0x87);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETDISP, 0x00, 0x01,
+				     0x78);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETRGBIF, 0x10, 0x10,
+				     0x28, 0x28, 0x03, 0xff, 0x00, 0x00, 0x00,
+				     0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETCYC, 0x80);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETBGP, 0x0a, 0x0a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETVCOM, 0x90, 0x90);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETPOWER_EXT, 0x76,
+				     0x22, 0xf0, 0x13);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETMIPI, 0x33, 0x81,
+				     0x05, 0xf9, 0x0e, 0x0e, 0x20, 0x00, 0x00,
+				     0x00, 0x00, 0x00, 0x00, 0x00, 0x44, 0x25,
+				     0x00, 0x91, 0x0a, 0x00, 0x00, 0x01, 0x4f,
+				     0x01, 0x00, 0x00, 0x37);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETVDC, 0x47);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_UNKNOWN_BF, 0x02, 0x10,
+				     0x00, 0x80, 0x04);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETSCR, 0x73, 0x73,
+				     0x50, 0x50, 0x00, 0x00, 0x12, 0x73, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETPOWER, 0x55, 0x00,
+				     0x32, 0x32, 0x77, 0xf1, 0xf7, 0xf7, 0xcc,
+				     0xcc, 0x7f, 0x7f, 0x11, 0x11, 0x00, 0x00,
+				     0x32);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETIO, 0xb8, 0x00,
+				     0x0a, 0x10, 0x01, 0x09, 0x00, 0x00, 0xed,
+				     0xc5, 0x00, 0xa5);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETCABC, 0x10, 0x40,
+				     0x1e, 0x03);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETPANEL, 0x0b);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETGAMMA, 0x00, 0x00,
+				     0x00, 0x25, 0x31, 0x3f, 0x26, 0x29, 0x04,
+				     0x08, 0x0d, 0x0e, 0x12, 0x0f, 0x11, 0x12,
+				     0x18, 0x00, 0x00, 0x00, 0x25, 0x31, 0x3f,
+				     0x26, 0x29, 0x04, 0x08, 0x0d, 0x0e, 0x12,
+				     0x0f, 0x11, 0x12, 0x18);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_UNKNOWN_E1, 0x11, 0x11,
+				     0x91, 0x00, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETEQ, 0x07, 0x07,
+				     0x0b, 0x0b, 0x0b, 0x0b, 0x00, 0x00, 0x00,
+				     0x00, 0xff, 0x84, 0xc0, 0x10);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETGIP1, 0xc8, 0x10,
+				     0x04, 0x04, 0x02, 0x80, 0x81, 0x12, 0x31,
+				     0x23, 0x2f, 0x80, 0x80, 0x81, 0x27, 0x20,
+				     0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x00,
+				     0x00, 0x0f, 0x00, 0x00, 0x00, 0x44, 0x00,
+				     0x88, 0xff, 0x00, 0x22, 0x44, 0x66, 0x88,
+				     0x88, 0x88, 0x55, 0x11, 0x88, 0xff, 0x11,
+				     0x33, 0x55, 0x77, 0x88, 0x88, 0x88, 0x00,
+				     0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
+				     0x00, 0x00, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_SETGIP2, 0x00, 0x00,
+				     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+				     0x00, 0x00, 0x00, 0x11, 0x55, 0xff, 0x88,
+				     0x77, 0x55, 0x33, 0x11, 0x88, 0x88, 0x88,
+				     0x00, 0x44, 0xff, 0x88, 0x66, 0x44, 0x22,
+				     0x00, 0x88, 0x88, 0x88, 0x23, 0x00, 0x00,
+				     0x00, 0xec, 0x00, 0x00, 0x00, 0x00, 0x00,
+				     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+				     0x00, 0x00, 0x00, 0x20, 0x80, 0x81, 0x00,
+				     0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, ST7703_CMD_UNKNOWN_EF, 0xff, 0xff,
+				     0x01);
+}
+
+static const struct drm_display_mode ayaneo_pocket_ds_lower_mode = {
+	.hdisplay	= 768,
+	.hsync_start	= 768 + 110,
+	.hsync_end	= 768 + 110 + 45,
+	.htotal		= 768 + 110 + 45 + 110,
+	.vdisplay	= 1024,
+	.vsync_start	= 1024 + 18,
+	.vsync_end	= 1024 + 18 + 6,
+	.vtotal		= 1024 + 18 + 6 + 16,
+	.clock		= 65946,
+	.width_mm	= 76,
+	.height_mm	= 102,
+};
+
+static const struct st7703_panel_desc ayaneo_pocket_ds_lower_desc = {
+	.mode = &ayaneo_pocket_ds_lower_mode,
+	.lanes = 4,
+	.mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_BURST |
+		      MIPI_DSI_CLOCK_NON_CONTINUOUS | MIPI_DSI_MODE_LPM,
+	.format = MIPI_DSI_FMT_RGB888,
+	.init_sequence = ayaneo_pocket_ds_lower_init_sequence,
+};
+
 static int st7703_enable(struct drm_panel *panel)
 {
 	struct st7703 *ctx = panel_to_st7703(panel);
@@ -916,6 +1011,7 @@ static void st7703_remove(struct mipi_dsi_device *dsi)
 
 static const struct of_device_id st7703_of_match[] = {
 	{ .compatible = "anbernic,rg353v-panel-v2", .data = &rg353v2_desc },
+	{ .compatible = "ayaneo,pocket-ds-lower-panel", .data = &ayaneo_pocket_ds_lower_desc },
 	{ .compatible = "gameforce,chi-panel", .data = &gameforcechi_desc },
 	{ .compatible = "powkiddy,rgb10max3-panel", .data = &rgb10max3_panel_desc },
 	{ .compatible = "powkiddy,rgb30-panel", .data = &rgb30panel_desc },

-- 
2.55.0

