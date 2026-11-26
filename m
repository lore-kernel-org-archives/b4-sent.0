From: David Heidelberg <david@ixit.cz>
Date: Thu, 26 Nov 2026 20:57:06 +0100
Subject: [PATCH v2 1/2] drm/panel: visionox-rm69299: Move off/sleep DSI
 commands to disable()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261126-visionox-rm69299-enable-v2-1-d4aca6d50b05@ixit.cz>
References: <20261126-visionox-rm69299-enable-v2-0-d4aca6d50b05@ixit.cz>
In-Reply-To: <20261126-visionox-rm69299-enable-v2-0-d4aca6d50b05@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Douglas Anderson <dianders@chromium.org>
Cc: =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3368; i=david@ixit.cz;
 h=from:subject:message-id; bh=ODLUdVqqZDVzp6HxRo+ng6wE6lOMHsVBXAhA1NRhFC4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrCI8TSpYwR01X4M7UPRARbFl90OooBrcO5ojTS
 zNzwvs7IkaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawiPEwAKCRBgAj/E00kg
 clXiD/9WUyZWOQQomJwX71GUODDw1La2/wOuv7wOkBBXeSpFTfQ30X25XQeYvMl3u78N7LvhCvD
 YjWnm48ejDRgdPPs+aBDg9PmVNHIkzvkcTfhMXJ32sKlu82VPcf04L3RvqrDgA/2QH9wyWiiNCT
 bDk5WSnHWrH89nhAYHCbNOTjua54ZYLoHOASHxenyUwP66YQbkWePhfeSKfOLiyC42yzQFPZH87
 qi9hIQ+yk0m/0QtypsW6fMEoTKicJxSpBlvLjnt6MPqEgwjbeTiGtnzVboCGGPpdKuTAeVWFqSr
 yw6tWzzuyu0iVa9PaP0k5/1QUns8pS72RIZbnwokBLb4sc8lk5j8G5r+VsSuTjy4n5vTGh0cu1u
 3AlnizwH1J9fL8StZGJGdqqgJQfxHrhLnST9bVKt7hMw2YLhZShzxdRf44vKVtgZERKEJ6VpTlT
 z4DolX1QFS2MeRl5XipRiFP9O3B+3/6XaJJO2y23n0cnb0rw4sG1GC6+WITTqChhP5sLtDCJgKk
 l4/0K1lC9c+0CkhJ0ef+yiZIvfuDL2lHVE7OauRXv04A86DnLUSoPfpOJEY13rBGc6X0TgnUKGL
 bmk6oawTqqK33j6NC7yisVQWaVkz6boSoeIG459gkrxYapXkb5FozpKmvM8sROleZLorIakSvm7
 soyUF5l5SngwNqA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Guido Günther <agx@sigxcpu.org>

With prepare_prev_first set, DRM calls visionox_rm69299_unprepare()
after the display controller timing engine has been stopped and before
the DSI host bridge post_disable() resets the video engine. Sending the
display-off and enter-sleep DCS commands from unprepare() therefore
causes DSI timeouts on every screen blank/unblank on the SHIFT6mq:

dmesg:
  msm_dsi ae94000.dsi: [drm:dsi_cmds2buf_tx] *ERROR* wait for video done timed out
  dsi_cmds2buf_tx: cmd dma tx failed, type=0x5, data0=0x28, len=4, ret=-110
  panel-visionox-rm69299 ae94000.dsi.0: sending DCS SET_DISPLAY_OFF failed: -110

Move the display-off and enter-sleep DCS commands into a new disable()
callback so they execute while the DSI link is still active, while
keeping the power-on and initialization commands in prepare() where the
link is in LP11 before video starts.

Fixes: 4a92ef0c57df ("drm/panel: visionox-rm69299: Make use of prepare_prev_first")
Signed-off-by: Guido Günther <agx@sigxcpu.org>
[David: keep power-on and init commands in prepare() per v1 review]
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-visionox-rm69299.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-visionox-rm69299.c b/drivers/gpu/drm/panel/panel-visionox-rm69299.c
index 4309e04c35c4b..bca1004656e45 100644
--- a/drivers/gpu/drm/panel/panel-visionox-rm69299.c
+++ b/drivers/gpu/drm/panel/panel-visionox-rm69299.c
@@ -184,30 +184,37 @@ static int visionox_rm69299_power_on(struct visionox_rm69299 *ctx)
 static int visionox_rm69299_power_off(struct visionox_rm69299 *ctx)
 {
 	gpiod_set_value(ctx->reset_gpio, 0);
 
 	return regulator_bulk_disable(ARRAY_SIZE(visionox_rm69299_supplies),
 				      ctx->supplies);
 }
 
-static int visionox_rm69299_unprepare(struct drm_panel *panel)
+static int visionox_rm69299_disable(struct drm_panel *panel)
 {
 	struct visionox_rm69299 *ctx = panel_to_ctx(panel);
 	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
 
 	ctx->dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
 
 	mipi_dsi_dcs_set_display_off_multi(&dsi_ctx);
 
 	/* 120ms delay required here as per DCS spec */
 	mipi_dsi_msleep(&dsi_ctx, 120);
 
 	mipi_dsi_dcs_enter_sleep_mode_multi(&dsi_ctx);
 
+	return dsi_ctx.accum_err;
+}
+
+static int visionox_rm69299_unprepare(struct drm_panel *panel)
+{
+	struct visionox_rm69299 *ctx = panel_to_ctx(panel);
+
 	return visionox_rm69299_power_off(ctx);
 }
 
 static int visionox_rm69299_prepare(struct drm_panel *panel)
 {
 	struct visionox_rm69299 *ctx = panel_to_ctx(panel);
 	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
 	int ret, i;
@@ -277,16 +284,17 @@ static int visionox_rm69299_get_modes(struct drm_panel *panel,
 	connector->display_info.height_mm = 131;
 	mode->type = DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED;
 	drm_mode_probed_add(connector, mode);
 
 	return 1;
 }
 
 static const struct drm_panel_funcs visionox_rm69299_drm_funcs = {
+	.disable = visionox_rm69299_disable,
 	.unprepare = visionox_rm69299_unprepare,
 	.prepare = visionox_rm69299_prepare,
 	.get_modes = visionox_rm69299_get_modes,
 };
 
 static int visionox_rm69299_bl_get_brightness(struct backlight_device *bl)
 {
 	struct mipi_dsi_device *dsi = bl_get_data(bl);

-- 
2.55.0

