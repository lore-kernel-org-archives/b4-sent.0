From: David Heidelberg <david@ixit.cz>
Date: Sun, 20 Sep 2026 13:05:48 +0200
Subject: [PATCH 05/11] drm/panel: s6e3ha8: Prepare for supporting multiple
 panels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-crosshatch-panel-v1-5-de6e9512da96@ixit.cz>
References: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
In-Reply-To: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=10546; i=david@ixit.cz;
 h=from:subject:message-id; bh=zeFP+joHP+5k+LadFbmnZIo2bqtEG343oPr8sOhGQEs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqr74ImBSM36wrIzTbh/vEu0MmXbWEg7lSCdHbz
 0Twa6cP8R+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaq++CAAKCRBgAj/E00kg
 coXoEACktVNgeOpp+bWjgAeuNsCpaeN6X1mEcE4D3sI6bZdN0pisvzBG4+vN2TrAj1qK2ZIAsDf
 YIPaU3eXXCf++KCeET9SEVHPpivE6hp2XPITRGLGzMXnbqdFwy4AKj2YrVKowexVq5i3QZDRBi8
 bb+OD6G4QmO/m4HTvu8jcnHhgyeBac8wN9DIPS0wTaNibSd0ADCoT7QW3PK/eG4i3wWL2JZ3pvM
 XlDLYL+KEQI54BYboH7up6QZGx0PEsY5bBAg9bsCKTx6s4h5xQ/uZ2epeg/dSOZKq+RA6EKpU+J
 oyqIuLB2+dN1qALtO1DKpHC27NlqqEPwjT9D63pCJ+V5Qinf32ftrb8wCPD8WgEawX9SE+dkcYN
 81xJtwCHCiV0PGCl8vE/jOtTvU7HkgbiCD6x3/kpbeSgceOFxBxK218NYL9dgSYnaZ1qGlpuGko
 hvaDdsgL30ATLqpdTPksumVLfvsLG1sAcr8fU7vqk2j+rnu5BeRyNeTu/Vv6EdMOter+PMOuwK3
 bi4l8jR9NukDl2ODucybdw7SP9mb9eyZMYOaCpLVB4bSyjKkdKXzQohM0NQpNkeYBhSFGqwy38u
 651cMt0bJIEmFG7YTtnCqpMkPow/K9eOOhjlOHeIREW8mFxTpjGEku4hSF1C9ek4bgnQQgHgS0e
 /biCeDm/L2QPEPw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The S6E3HA8 DDIC drives more panels than the Galaxy S9 (AMB577PX01)
one currently supported. Move the display mode, DSI mode flags,
regulator supplies and panel functions into a per-compatible descriptor
passed as OF match data, and rename the panel-specific symbols
accordingly.

No functional change.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c | 118 ++++++++++++++++----------
 1 file changed, 74 insertions(+), 44 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
index a0015ac0e2782..5e1e997b83b36 100644
--- a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
+++ b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
@@ -3,49 +3,73 @@
 // Generated with linux-mdss-dsi-panel-driver-generator from vendor device tree:
 //	Copyright (c) 2013, The Linux Foundation. All rights reserved.
 // Copyright (c) 2024 Dzmitry Sankouski <dsankouski@gmail.com>
 
 #include <linux/delay.h>
 #include <linux/gpio/consumer.h>
 #include <linux/module.h>
 #include <linux/of.h>
+#include <linux/property.h>
 #include <linux/regulator/consumer.h>
 
 #include <drm/display/drm_dsc.h>
 #include <drm/display/drm_dsc_helper.h>
 #include <drm/drm_mipi_dsi.h>
 #include <drm/drm_probe_helper.h>
 #include <drm/drm_panel.h>
 
 #include "panel-samsung-dsi.h"
 
+struct s6e3ha8_desc {
+	const struct drm_panel_funcs *funcs;
+	const struct drm_display_mode *mode;
+	unsigned long mode_flags;
+	const struct regulator_bulk_data *supplies;
+	unsigned int num_supplies;
+};
+
 struct s6e3ha8 {
 	struct drm_panel panel;
 	struct mipi_dsi_device *dsi;
+	const struct s6e3ha8_desc *desc;
 	struct drm_dsc_config dsc;
 	struct gpio_desc *reset_gpio;
 	struct regulator_bulk_data *supplies;
 };
 
-static const struct regulator_bulk_data s6e3ha8_supplies[] = {
+static const struct regulator_bulk_data s6e3ha8_vddr_supplies[] = {
 	{ .supply = "vdd3" },
 	{ .supply = "vci" },
 	{ .supply = "vddr" },
 };
 
-static inline
-struct s6e3ha8 *to_s6e3ha8_amb577px01_wqhd(struct drm_panel *panel)
+static inline struct s6e3ha8 *to_s6e3ha8(struct drm_panel *panel)
 {
 	return container_of(panel, struct s6e3ha8, panel);
 }
 
 #define s6e3ha8_afc_off(ctx) \
 	mipi_dsi_dcs_write_seq_multi(ctx, 0xe2, 0x00, 0x00)
 
+static int s6e3ha8_get_modes(struct drm_panel *panel,
+			     struct drm_connector *connector)
+{
+	struct s6e3ha8 *priv = to_s6e3ha8(panel);
+
+	return drm_connector_helper_get_modes_fixed(connector, priv->desc->mode);
+}
+
+static int s6e3ha8_unprepare(struct drm_panel *panel)
+{
+	struct s6e3ha8 *priv = to_s6e3ha8(panel);
+
+	return regulator_bulk_disable(priv->desc->num_supplies, priv->supplies);
+}
+
 static void s6e3ha8_amb577px01_wqhd_reset(struct s6e3ha8 *priv)
 {
 	gpiod_set_value_cansleep(priv->reset_gpio, 1);
 	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(priv->reset_gpio, 0);
 	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(priv->reset_gpio, 1);
 	usleep_range(5000, 6000);
@@ -130,32 +154,32 @@ static int s6e3ha8_amb577px01_wqhd_on(struct s6e3ha8 *priv)
 	mipi_dsi_dcs_write_seq_multi(&ctx, 0xf7, 0x03); /* Gamma, LTPS(AID) update */
 	samsung_dsi_test_key_off_lvl2(&ctx);
 
 	samsung_dsi_test_key_off_lvl1(&ctx);
 
 	return ctx.accum_err;
 }
 
-static int s6e3ha8_enable(struct drm_panel *panel)
+static int s6e3ha8_amb577px01_wqhd_enable(struct drm_panel *panel)
 {
-	struct s6e3ha8 *priv = to_s6e3ha8_amb577px01_wqhd(panel);
+	struct s6e3ha8 *priv = to_s6e3ha8(panel);
 	struct mipi_dsi_device *dsi = priv->dsi;
 	struct mipi_dsi_multi_context ctx = { .dsi = dsi };
 
 	samsung_dsi_test_key_on_lvl1(&ctx);
 	mipi_dsi_dcs_set_display_on_multi(&ctx);
 	samsung_dsi_test_key_off_lvl1(&ctx);
 
 	return ctx.accum_err;
 }
 
-static int s6e3ha8_disable(struct drm_panel *panel)
+static int s6e3ha8_amb577px01_wqhd_disable(struct drm_panel *panel)
 {
-	struct s6e3ha8 *priv = to_s6e3ha8_amb577px01_wqhd(panel);
+	struct s6e3ha8 *priv = to_s6e3ha8(panel);
 	struct mipi_dsi_device *dsi = priv->dsi;
 	struct mipi_dsi_multi_context ctx = { .dsi = dsi };
 
 	samsung_dsi_test_key_on_lvl1(&ctx);
 	mipi_dsi_dcs_set_display_off_multi(&ctx);
 	samsung_dsi_test_key_off_lvl1(&ctx);
 	mipi_dsi_msleep(&ctx, 20);
 
@@ -165,23 +189,23 @@ static int s6e3ha8_disable(struct drm_panel *panel)
 
 	mipi_dsi_msleep(&ctx, 160);
 
 	return ctx.accum_err;
 }
 
 static int s6e3ha8_amb577px01_wqhd_prepare(struct drm_panel *panel)
 {
-	struct s6e3ha8 *priv = to_s6e3ha8_amb577px01_wqhd(panel);
+	struct s6e3ha8 *priv = to_s6e3ha8(panel);
 	struct mipi_dsi_device *dsi = priv->dsi;
 	struct mipi_dsi_multi_context ctx = { .dsi = dsi };
 	struct drm_dsc_picture_parameter_set pps;
 	int ret;
 
-	ret = regulator_bulk_enable(ARRAY_SIZE(s6e3ha8_supplies), priv->supplies);
+	ret = regulator_bulk_enable(priv->desc->num_supplies, priv->supplies);
 	if (ret < 0)
 		return ret;
 	mipi_dsi_msleep(&ctx, 120);
 	s6e3ha8_amb577px01_wqhd_reset(priv);
 
 	ret = s6e3ha8_amb577px01_wqhd_on(priv);
 	if (ret < 0) {
 		gpiod_set_value_cansleep(priv->reset_gpio, 0);
@@ -193,88 +217,88 @@ static int s6e3ha8_amb577px01_wqhd_prepare(struct drm_panel *panel)
 	samsung_dsi_test_key_on_lvl1(&ctx);
 	mipi_dsi_picture_parameter_set_multi(&ctx, &pps);
 	samsung_dsi_test_key_off_lvl1(&ctx);
 
 	mipi_dsi_msleep(&ctx, 28);
 
 	return ctx.accum_err;
 err:
-	regulator_bulk_disable(ARRAY_SIZE(s6e3ha8_supplies), priv->supplies);
+	regulator_bulk_disable(priv->desc->num_supplies, priv->supplies);
 	return ret;
 }
 
-static int s6e3ha8_amb577px01_wqhd_unprepare(struct drm_panel *panel)
-{
-	struct s6e3ha8 *priv = to_s6e3ha8_amb577px01_wqhd(panel);
-
-	return regulator_bulk_disable(ARRAY_SIZE(s6e3ha8_supplies), priv->supplies);
-}
-
 static const struct drm_display_mode s6e3ha8_amb577px01_wqhd_mode = {
 	.clock = (1440 + 116 + 44 + 120) * (2960 + 120 + 80 + 124) * 60 / 1000,
 	.hdisplay = 1440,
 	.hsync_start = 1440 + 116,
 	.hsync_end = 1440 + 116 + 44,
 	.htotal = 1440 + 116 + 44 + 120,
 	.vdisplay = 2960,
 	.vsync_start = 2960 + 120,
 	.vsync_end = 2960 + 120 + 80,
 	.vtotal = 2960 + 120 + 80 + 124,
 	.width_mm = 64,
 	.height_mm = 132,
 };
 
-static int s6e3ha8_amb577px01_wqhd_get_modes(struct drm_panel *panel,
-					     struct drm_connector *connector)
-{
-	return drm_connector_helper_get_modes_fixed(connector, &s6e3ha8_amb577px01_wqhd_mode);
-}
-
 static const struct drm_panel_funcs s6e3ha8_amb577px01_wqhd_panel_funcs = {
 	.prepare = s6e3ha8_amb577px01_wqhd_prepare,
-	.unprepare = s6e3ha8_amb577px01_wqhd_unprepare,
-	.get_modes = s6e3ha8_amb577px01_wqhd_get_modes,
-	.enable = s6e3ha8_enable,
-	.disable = s6e3ha8_disable,
+	.unprepare = s6e3ha8_unprepare,
+	.get_modes = s6e3ha8_get_modes,
+	.enable = s6e3ha8_amb577px01_wqhd_enable,
+	.disable = s6e3ha8_amb577px01_wqhd_disable,
+};
+
+static const struct s6e3ha8_desc s6e3ha8_amb577px01_wqhd_desc = {
+	.funcs = &s6e3ha8_amb577px01_wqhd_panel_funcs,
+	.mode = &s6e3ha8_amb577px01_wqhd_mode,
+	.mode_flags = MIPI_DSI_CLOCK_NON_CONTINUOUS |
+		MIPI_DSI_MODE_VIDEO_NO_HFP | MIPI_DSI_MODE_VIDEO_NO_HBP |
+		MIPI_DSI_MODE_VIDEO_NO_HSA | MIPI_DSI_MODE_NO_EOT_PACKET,
+	.supplies = s6e3ha8_vddr_supplies,
+	.num_supplies = ARRAY_SIZE(s6e3ha8_vddr_supplies),
 };
 
-static int s6e3ha8_amb577px01_wqhd_probe(struct mipi_dsi_device *dsi)
+static int s6e3ha8_probe(struct mipi_dsi_device *dsi)
 {
 	struct device *dev = &dsi->dev;
+	const struct s6e3ha8_desc *desc;
 	struct s6e3ha8 *priv;
 	int ret;
 
-	priv = devm_drm_panel_alloc(dev, struct s6e3ha8, panel,
-				    &s6e3ha8_amb577px01_wqhd_panel_funcs,
+	desc = device_get_match_data(dev);
+	if (!desc)
+		return -ENODEV;
+
+	priv = devm_drm_panel_alloc(dev, struct s6e3ha8, panel, desc->funcs,
 				    DRM_MODE_CONNECTOR_DSI);
 	if (IS_ERR(priv))
 		return PTR_ERR(priv);
 
-	ret = devm_regulator_bulk_get_const(dev, ARRAY_SIZE(s6e3ha8_supplies),
-				      s6e3ha8_supplies,
-				      &priv->supplies);
+	priv->desc = desc;
+
+	ret = devm_regulator_bulk_get_const(dev, desc->num_supplies,
+					    desc->supplies, &priv->supplies);
 	if (ret < 0) {
 		dev_err(dev, "failed to get regulators: %d\n", ret);
 		return ret;
 	}
 
 	priv->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
 	if (IS_ERR(priv->reset_gpio))
 		return dev_err_probe(dev, PTR_ERR(priv->reset_gpio),
 				     "Failed to get reset-gpios\n");
 
 	priv->dsi = dsi;
 	mipi_dsi_set_drvdata(dsi, priv);
 
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
-	dsi->mode_flags = MIPI_DSI_CLOCK_NON_CONTINUOUS |
-		MIPI_DSI_MODE_VIDEO_NO_HFP | MIPI_DSI_MODE_VIDEO_NO_HBP |
-		MIPI_DSI_MODE_VIDEO_NO_HSA | MIPI_DSI_MODE_NO_EOT_PACKET;
+	dsi->mode_flags = priv->desc->mode_flags;
 
 	priv->panel.prepare_prev_first = true;
 
 	ret = devm_drm_panel_add(dev, &priv->panel);
 	if (ret)
 		return ret;
 
 	/* This panel only supports DSC; unconditionally enable it */
@@ -295,27 +319,33 @@ static int s6e3ha8_amb577px01_wqhd_probe(struct mipi_dsi_device *dsi)
 	if (ret < 0) {
 		dev_err(dev, "Failed to attach to DSI host: %d\n", ret);
 		return ret;
 	}
 
 	return 0;
 }
 
-static const struct of_device_id s6e3ha8_amb577px01_wqhd_of_match[] = {
-	{ .compatible = "samsung,s6e3ha8" }, /* deprecated */
-	{ .compatible = "samsung,s6e3ha8-amb577px01" },
+static const struct of_device_id s6e3ha8_of_match[] = {
+	{
+		/* deprecated */
+		.compatible = "samsung,s6e3ha8",
+		.data = &s6e3ha8_amb577px01_wqhd_desc,
+	}, {
+		.compatible = "samsung,s6e3ha8-amb577px01",
+		.data = &s6e3ha8_amb577px01_wqhd_desc,
+	},
 	{ /* sentinel */ }
 };
-MODULE_DEVICE_TABLE(of, s6e3ha8_amb577px01_wqhd_of_match);
+MODULE_DEVICE_TABLE(of, s6e3ha8_of_match);
 
-static struct mipi_dsi_driver s6e3ha8_amb577px01_wqhd_driver = {
-	.probe = s6e3ha8_amb577px01_wqhd_probe,
+static struct mipi_dsi_driver s6e3ha8_driver = {
+	.probe = s6e3ha8_probe,
 	.driver = {
 		.name = "panel-s6e3ha8",
-		.of_match_table = s6e3ha8_amb577px01_wqhd_of_match,
+		.of_match_table = s6e3ha8_of_match,
 	},
 };
-module_mipi_dsi_driver(s6e3ha8_amb577px01_wqhd_driver);
+module_mipi_dsi_driver(s6e3ha8_driver);
 
 MODULE_AUTHOR("Dzmitry Sankouski <dsankouski@gmail.com>");
 MODULE_DESCRIPTION("DRM driver for S6E3HA8 panel");
 MODULE_LICENSE("GPL");

-- 
2.55.0

