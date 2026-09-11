From: =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
Date: Fri, 11 Sep 2026 11:51:01 +0300
Subject: [PATCH RFC 04/10] drm/panel: novatek-nt36672a: add Tianma FHD+
 video mode panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260911-ginkgo-submission-final-v1-4-0e68e63a18d4@gmail.com>
References: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
In-Reply-To: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, freedreno@lists.freedesktop.org, 
 =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789116671; l=8274;
 i=kavakliyigitcan@gmail.com; s=20260911; h=from:subject:message-id;
 bh=hZNePY1tgLgGDhJlBHE8AhCXwjmbp4/rJdgWSLDow9Q=;
 b=C+ciPbyMZVAEuncYYE2u1di4xZ9AFgGKCptzeBvt0TRacT655SrBowEZXKQ98r9WOyP65qB4j
 AqhdovXIjwFAHQXfvn9XxDAykUtKO+IkdmNhFKTvW82eb5kIvOUbkow
X-Developer-Key: i=kavakliyigitcan@gmail.com; a=ed25519;
 pk=W2GaxVotULs2vAjRMMLheaDtMMYs4037zO1LVVfFtPI=
X-Endpoint-Received: by B4 Relay for kavakliyigitcan@gmail.com/20260911 with auth_id=1024
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the 1080x2340 Tianma video mode panel with Novatek
NT36672A driver IC found in the Xiaomi Redmi Note 8 (ginkgo / SM6125).

Changes:
- Add 1080x2340 display mode timings (183.025 MHz pixel clock)
- Add verified DCS initialization sequences for pages 0x25, 0x20, 0x24,
  0x26, and user command page 0x10
- Add standard DRM panel .enable and .disable callbacks to coordinate
  display on/off commands with active DSI video stream
- Set prepare_prev_first = true for host controller synchronization
- Optimize power-on reset sequence to nominal 10ms timings

Signed-off-by: YİĞİTCAN KAVAKLI <kavakliyigitcan@gmail.com>
---
 drivers/gpu/drm/panel/panel-novatek-nt36672a.c | 141 ++++++++++++++++++++-----
 1 file changed, 117 insertions(+), 24 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-novatek-nt36672a.c b/drivers/gpu/drm/panel/panel-novatek-nt36672a.c
index 464d9ce47d87dc857c3a565a63156ac79ddeb30c..b69213790441f204016895a391b58f676762b1aa 100644
--- a/drivers/gpu/drm/panel/panel-novatek-nt36672a.c
+++ b/drivers/gpu/drm/panel/panel-novatek-nt36672a.c
@@ -34,7 +34,7 @@ static const char * const nt36672a_regulator_names[] = {
 	"vddneg",
 };
 
-static unsigned long const nt36672a_regulator_enable_loads[] = {
+static const unsigned long nt36672a_regulator_enable_loads[] = {
 	62000,
 	100000,
 	100000
@@ -92,18 +92,12 @@ static int nt36672a_panel_unprepare(struct drm_panel *panel)
 	if (pinfo->desc->send_deinit_cmds)
 		pinfo->desc->send_deinit_cmds(&dsi_ctx);
 
-	/* Reset error to continue with display off even if send_cmds failed */
+	/* Reset error to continue power-down even if send_cmds failed */
 	dsi_ctx.accum_err = 0;
-	mipi_dsi_dcs_set_display_off_multi(&dsi_ctx);
-	/* Reset error to continue power-down even if display off failed */
-	dsi_ctx.accum_err = 0;
-
-	/* 120ms delay required here as per DCS spec */
-	msleep(120);
 
 	mipi_dsi_dcs_enter_sleep_mode_multi(&dsi_ctx);
 
-	/* 0x3C = 60ms delay */
+	/* 60ms delay as per DCS spec */
 	msleep(60);
 
 	nt36672a_panel_power_off(panel);
@@ -120,15 +114,14 @@ static int nt36672a_panel_power_on(struct nt36672a_panel *pinfo)
 		return ret;
 
 	/*
-	 * As per downstream kernel, Reset sequence of Tianma FHD panel requires the panel to
-	 * be out of reset for 10ms, followed by being held in reset for 10ms. But for Android
-	 * AOSP, we needed to bump it upto 200ms otherwise we get white screen sometimes.
-	 * FIXME: Try to reduce this 200ms to a lesser value.
+	 * Reset sequence: 10ms out of reset, 10ms held in reset, 10ms out of reset.
 	 */
-	gpiod_set_value(pinfo->reset_gpio, 1);
-	msleep(200);
-	gpiod_set_value(pinfo->reset_gpio, 0);
-	msleep(200);
+	gpiod_set_value_cansleep(pinfo->reset_gpio, 0);
+	usleep_range(10000, 11000);
+	gpiod_set_value_cansleep(pinfo->reset_gpio, 1);
+	usleep_range(10000, 11000);
+	gpiod_set_value_cansleep(pinfo->reset_gpio, 0);
+	usleep_range(10000, 11000);
 
 	return 0;
 }
@@ -146,19 +139,41 @@ static int nt36672a_panel_prepare(struct drm_panel *panel)
 
 	mipi_dsi_dcs_exit_sleep_mode_multi(&dsi_ctx);
 
-	/* 0x46 = 70 ms delay */
-	mipi_dsi_msleep(&dsi_ctx, 70);
-
-	mipi_dsi_dcs_set_display_on_multi(&dsi_ctx);
+	/* 80 ms delay as per DCS spec / downstream timing */
+	msleep(80);
 
 	/* Send rest of the init cmds */
 	if (pinfo->desc->send_init_cmds_2)
 		pinfo->desc->send_init_cmds_2(&dsi_ctx);
 
-	mipi_dsi_msleep(&dsi_ctx, 120);
-
 	if (dsi_ctx.accum_err < 0)
-		gpiod_set_value(pinfo->reset_gpio, 0);
+		gpiod_set_value_cansleep(pinfo->reset_gpio, 0);
+
+	return dsi_ctx.accum_err;
+}
+
+static int nt36672a_panel_enable(struct drm_panel *panel)
+{
+	struct nt36672a_panel *pinfo = to_nt36672a_panel(panel);
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = pinfo->link };
+
+	mipi_dsi_dcs_set_display_on_multi(&dsi_ctx);
+
+	/* Frame settling delay */
+	msleep(20);
+
+	return dsi_ctx.accum_err;
+}
+
+static int nt36672a_panel_disable(struct drm_panel *panel)
+{
+	struct nt36672a_panel *pinfo = to_nt36672a_panel(panel);
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = pinfo->link };
+
+	mipi_dsi_dcs_set_display_off_multi(&dsi_ctx);
+
+	/* 120ms delay as per DCS spec */
+	msleep(120);
 
 	return dsi_ctx.accum_err;
 }
@@ -189,6 +204,8 @@ static int nt36672a_panel_get_modes(struct drm_panel *panel,
 static const struct drm_panel_funcs panel_funcs = {
 	.unprepare = nt36672a_panel_unprepare,
 	.prepare = nt36672a_panel_prepare,
+	.enable = nt36672a_panel_enable,
+	.disable = nt36672a_panel_disable,
 	.get_modes = nt36672a_panel_get_modes,
 };
 
@@ -404,6 +421,79 @@ static const struct nt36672a_panel_desc tianma_fhd_video_panel_desc = {
 	.send_deinit_cmds = tianma_fhd_video_send_deinit_cmds,
 };
 
+static void tianma_ginkgo_send_init_cmds(struct mipi_dsi_multi_context *dsi_ctx)
+{
+	/* Page 0x25 init */
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x25);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xfb, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x18, 0x96);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x05, 0x04);
+
+	/* Page 0x20 init */
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x20);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xfb, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x78, 0x01);
+
+	/* Page 0x24 init */
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x24);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xfb, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x82, 0x13);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x84, 0x31);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x88, 0x13);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8a, 0x31);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8e, 0xe4);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8f, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x90, 0x80);
+
+	/* Page 0x26 init */
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x26);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xfb, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa9, 0x12);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xaa, 0x10);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xae, 0x8a);
+
+	/* Page 0x10 (User command page) */
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x10);
+}
+
+static void tianma_ginkgo_send_post_on_cmds(struct mipi_dsi_multi_context *dsi_ctx)
+{
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb0, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x35, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x68, 0x04, 0x03);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x51, 0xb8);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x53, 0x2c);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x55, 0x00);
+}
+
+static const struct drm_display_mode tianma_ginkgo_fhd_video_mode = {
+	.clock		= 183025,
+
+	.hdisplay	= 1080,
+	.hsync_start	= 1080 + 90,
+	.hsync_end	= 1080 + 90 + 2,
+	.htotal		= 1080 + 90 + 2 + 120,
+
+	.vdisplay	= 2340,
+	.vsync_start	= 2340 + 10,
+	.vsync_end	= 2340 + 10 + 3,
+	.vtotal		= 2340 + 10 + 3 + 8,
+
+	.type = DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED,
+};
+
+static const struct nt36672a_panel_desc tianma_ginkgo_fhd_video_panel_desc = {
+	.display_mode = &tianma_ginkgo_fhd_video_mode,
+	.panel_name = "tianma-ginkgo-fhd-video",
+	.width_mm = 67,
+	.height_mm = 145,
+	.mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_LPM,
+	.format = MIPI_DSI_FMT_RGB888,
+	.lanes = 4,
+	.send_init_cmds_1 = tianma_ginkgo_send_init_cmds,
+	.send_init_cmds_2 = tianma_ginkgo_send_post_on_cmds,
+};
+
 static int nt36672a_panel_add(struct nt36672a_panel *pinfo)
 {
 	struct device *dev = &pinfo->link->dev;
@@ -428,6 +518,8 @@ static int nt36672a_panel_add(struct nt36672a_panel *pinfo)
 	if (ret)
 		return dev_err_probe(dev, ret, "Failed to get backlight\n");
 
+	pinfo->base.prepare_prev_first = true;
+
 	drm_panel_add(&pinfo->base);
 
 	return 0;
@@ -481,6 +573,7 @@ static void nt36672a_panel_remove(struct mipi_dsi_device *dsi)
 
 static const struct of_device_id tianma_fhd_video_of_match[] = {
 	{ .compatible = "tianma,fhd-video", .data = &tianma_fhd_video_panel_desc },
+	{ .compatible = "tianma,fhd-video-ginkgo", .data = &tianma_ginkgo_fhd_video_panel_desc },
 	{ },
 };
 MODULE_DEVICE_TABLE(of, tianma_fhd_video_of_match);

-- 
2.47.3

