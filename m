From: David Heidelberg <david@ixit.cz>
Date: Tue, 08 Sep 2026 14:45:04 +0200
Subject: [PATCH v2 3/3] drm/panel: ebbg-ft8719: Split initialization into
 enable/disable fn
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-ebbg-ft8719-fixups-v2-3-5454ae1f5581@ixit.cz>
References: <20260908-ebbg-ft8719-fixups-v2-0-5454ae1f5581@ixit.cz>
In-Reply-To: <20260908-ebbg-ft8719-fixups-v2-0-5454ae1f5581@ixit.cz>
To: Joel Selvaraj <foss@joelselvaraj.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sam Ravnborg <sam@ravnborg.org>, Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Linus Walleij <linusw@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3584; i=david@ixit.cz;
 h=from:subject:message-id; bh=p59FHt+W5RxJxYzBAZ41gjyX0PrqfPnJroW1P4JaiHQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqoANO4JeodgFDo3sfvRALM9dtf/AW0QxG/TDpk
 O4JX5PpurCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqADTgAKCRBgAj/E00kg
 ch4ED/kBbl106wXrSg1G9m+3LB2P1WbofO4pTJc0f7pF03qbU8bV5HoUip4tdyriX4T1FWPfwc4
 4/1ea49TeJgoshYNKq/uMUbEaVkuAZSfGxeZBZWR+KSQgzcrMmcBaY95/xJgCW0ECsTShqHOc2o
 388J4TMMQbYfl4Ypl+WEaFVjBt672e+nn7j69kVd5CA842LBbPfXAC443DwrbuAhs+0wm1N+aFS
 9qdcQOR14Pt8+NGUTRu6/FwAULpScQybwZwCsAtf4uFiCBzK3QMyhNxGoYSHBYmfCtRmiHAHJLC
 NgvO0OP1+BLK3Qk+Jgh9YQNmO/SCExw08LCQVjcfzrfiT+fcDhWORgnFEPYOXzi4+LYb8AxdZlJ
 zr4zklkzAPm6z4qb0A4YxMxisu2PwTc66YJIw73BGbvUnBFo07erFs+SGkUuoE5LPpn0ENZWMSM
 C1eBUWjQfNqL0GfXO2mrjp4/MXES1gWAzwUseRUN0fCfLih7t5ueCX4OOgpuqQDuQSqZCNnt4uU
 iQp+RSFAQENJgeO8tqZXBcRXl+MuSUO3sxz6un2OISH3D0EtXOTkeGllE+6ZYGndpBFUw51C3MQ
 uoKGPWSxkEXxO7RR4pLRuseOa2dprp7nP9y5MpqWmCPpaaIab+X43y9q5TMbA98b705ytD4jWAq
 YyhTn26GWCJXBbg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the MIPI commands into enable/disable callbacks since they
are called between prepare/unprepare callbacks.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-ebbg-ft8719.c | 19 ++++++++-----------
 1 file changed, 8 insertions(+), 11 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-ebbg-ft8719.c b/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
index 14982263a94f1..1652de70900f1 100644
--- a/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
+++ b/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
@@ -49,74 +49,69 @@ static void ebbg_ft8719_reset(struct ebbg_ft8719 *ctx)
 	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
 	usleep_range(4000, 5000);
 	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
 	usleep_range(1000, 2000);
 	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
 	usleep_range(15000, 16000);
 }
 
-static int ebbg_ft8719_on(struct ebbg_ft8719 *ctx)
+static int ebbg_ft8719_enable(struct drm_panel *panel)
 {
+	struct ebbg_ft8719 *ctx = to_ebbg_ft8719(panel);
 	struct mipi_dsi_device *dsi = ctx->dsi;
 	struct mipi_dsi_multi_context dsi_ctx = { .dsi = dsi };
 
 	dsi->mode_flags |= MIPI_DSI_MODE_LPM;
 
 	mipi_dsi_dcs_set_display_brightness_multi(&dsi_ctx, 0x00ff);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, MIPI_DCS_WRITE_CONTROL_DISPLAY, 0x24);
 	mipi_dsi_dcs_write_seq_multi(&dsi_ctx, MIPI_DCS_WRITE_POWER_SAVE, 0x00);
 
 	mipi_dsi_dcs_exit_sleep_mode_multi(&dsi_ctx);
 	mipi_dsi_msleep(&dsi_ctx, 90);
 	mipi_dsi_dcs_set_display_on_multi(&dsi_ctx);
 
 	return dsi_ctx.accum_err;
 }
 
-static int ebbg_ft8719_off(struct ebbg_ft8719 *ctx)
+static int ebbg_ft8719_disable(struct drm_panel *panel)
 {
+	struct ebbg_ft8719 *ctx = to_ebbg_ft8719(panel);
 	struct mipi_dsi_device *dsi = ctx->dsi;
 	struct mipi_dsi_multi_context dsi_ctx = { .dsi = dsi };
 
-	dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
+	ctx->dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
 
 	mipi_dsi_dcs_set_display_off_multi(&dsi_ctx);
 	mipi_dsi_usleep_range(&dsi_ctx, 10000, 11000);
 	mipi_dsi_dcs_enter_sleep_mode_multi(&dsi_ctx);
 	mipi_dsi_msleep(&dsi_ctx, 90);
 
-	return dsi_ctx.accum_err;
+	return 0;
 }
 
 static int ebbg_ft8719_prepare(struct drm_panel *panel)
 {
 	struct ebbg_ft8719 *ctx = to_ebbg_ft8719(panel);
 	int ret;
 
 	ret = regulator_bulk_enable(ARRAY_SIZE(ctx->supplies), ctx->supplies);
 	if (ret < 0)
 		return ret;
 
 	ebbg_ft8719_reset(ctx);
 
-	ret = ebbg_ft8719_on(ctx);
-	if (ret < 0) {
-		gpiod_set_value_cansleep(ctx->reset_gpio, 1);
-		return ret;
-	}
-
 	return 0;
 }
 
 static int ebbg_ft8719_unprepare(struct drm_panel *panel)
 {
 	struct ebbg_ft8719 *ctx = to_ebbg_ft8719(panel);
 
-	ebbg_ft8719_off(ctx);
 	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
 	regulator_bulk_disable(ARRAY_SIZE(ctx->supplies), ctx->supplies);
 
 	return 0;
 }
 
 static const struct drm_display_mode ebbg_ft8719_mode = {
 	.clock = (1080 + 28 + 4 + 16) * (2246 + 120 + 4 + 12) * 60 / 1000,
@@ -148,16 +143,18 @@ static int ebbg_ft8719_get_modes(struct drm_panel *panel,
 	connector->display_info.height_mm = mode->height_mm;
 	drm_mode_probed_add(connector, mode);
 
 	return 1;
 }
 
 static const struct drm_panel_funcs ebbg_ft8719_panel_funcs = {
 	.prepare = ebbg_ft8719_prepare,
+	.enable = ebbg_ft8719_enable,
+	.disable = ebbg_ft8719_disable,
 	.unprepare = ebbg_ft8719_unprepare,
 	.get_modes = ebbg_ft8719_get_modes,
 };
 
 static int ebbg_ft8719_probe(struct mipi_dsi_device *dsi)
 {
 	struct device *dev = &dsi->dev;
 	struct ebbg_ft8719 *ctx;

-- 
2.55.0

