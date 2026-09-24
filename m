From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 16:01:34 +0200
Subject: [PATCH v2 06/11] drm/panel: s6e3ha8: Correct the polarity logic
 within
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-crosshatch-panel-v2-6-08d5c7bf72fc@ixit.cz>
References: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
In-Reply-To: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5082; i=david@ixit.cz;
 h=from:subject:message-id; bh=DLxgExC/ubt9DvOb6KNIBkLWqCpMn1GUMvkzxEC1Z0g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtS09Druyn9eas2TeVvjAHsO4zLdMlXs4CLflp
 7u5tZes5s+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUtPQAKCRBgAj/E00kg
 ctgVD/9ngi+OWzDYMDBpST/DNYZKtI5doaSsAgY9oHQnmXjPP7El7OzyvbgngFRNMZN6OQLMLqs
 lXvN2XI1DWDNogMgIldwR4dnJbBChvMGzacCWTOADz5Cvn1O0Ygm6NwqKifBnFZfDXI95ju2RB0
 BXiGOvblHtiw3APZDcvB627s0uXWo3ZqF/Jo1c32tqOVeHmZMfNmJrCKjBlACC9IU23jZsRWZ0Q
 /s16MGBaUS/2j0ZWdfbfxmi9qrE4jrmxre05s0c3pmwy4Xyb4wZwVZOS2EuQg00qT0r68m2PDgK
 fz1hHGFejG6ihuPx9d06wBxny9PA+Vget7+NerP/VWeQOjH0cRza8n60gtvihFjsmEBF1YEclz+
 3tmaKMm6DBWgCxRugzcE/Ikj74Ii6bU9Rl1QrTqu0/w3lHkJM+5ijJUWHbS6X/qy2UU6XxkZbFx
 pT50wcBI55WECC1v5y/avEhiS5Az4hgw36enLy7gxy3AGFttaootqfm/KwhFkkAT23uw0amo1t2
 Rffk6AD0ZJaDiFJEPESylv4bFG2d8a0dnN6ZYee0MrrpsHNBtQTppACEo1vrXcOCRsrFwfJW2sO
 HaHhffoE6tKhc4yKzTX1eGwJpt7g0+ixJEWW5QyMX3ca7P03k/aF/6nFIWGqkTuHLWKX/YD7Y+p
 QKgpcoVc/sMyo+g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reset was introduced with wrong polarity. Correct for the future
compatibles and keep current with reverted logic.

Old DTs keep GPIO_ACTIVE_HIGH and are fixed up via
gpiod_toggle_active_low() on the deprecated compatible.

Assisted-by: LLM
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c | 23 +++++++++++++++++++----
 1 file changed, 19 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
index 5e1e997b83b36..99290913de69a 100644
--- a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
+++ b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
@@ -20,16 +20,17 @@
 #include "panel-samsung-dsi.h"
 
 struct s6e3ha8_desc {
 	const struct drm_panel_funcs *funcs;
 	const struct drm_display_mode *mode;
 	unsigned long mode_flags;
 	const struct regulator_bulk_data *supplies;
 	unsigned int num_supplies;
+	bool broken_reset_polarity;
 };
 
 struct s6e3ha8 {
 	struct drm_panel panel;
 	struct mipi_dsi_device *dsi;
 	const struct s6e3ha8_desc *desc;
 	struct drm_dsc_config dsc;
 	struct gpio_desc *reset_gpio;
@@ -62,22 +63,22 @@ static int s6e3ha8_unprepare(struct drm_panel *panel)
 {
 	struct s6e3ha8 *priv = to_s6e3ha8(panel);
 
 	return regulator_bulk_disable(priv->desc->num_supplies, priv->supplies);
 }
 
 static void s6e3ha8_amb577px01_wqhd_reset(struct s6e3ha8 *priv)
 {
-	gpiod_set_value_cansleep(priv->reset_gpio, 1);
-	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(priv->reset_gpio, 0);
 	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(priv->reset_gpio, 1);
 	usleep_range(5000, 6000);
+	gpiod_set_value_cansleep(priv->reset_gpio, 0);
+	usleep_range(5000, 6000);
 }
 
 static int s6e3ha8_amb577px01_wqhd_on(struct s6e3ha8 *priv)
 {
 	struct mipi_dsi_device *dsi = priv->dsi;
 	struct mipi_dsi_multi_context ctx = { .dsi = dsi };
 
 	dsi->mode_flags |= MIPI_DSI_MODE_LPM;
@@ -203,17 +204,17 @@ static int s6e3ha8_amb577px01_wqhd_prepare(struct drm_panel *panel)
 	ret = regulator_bulk_enable(priv->desc->num_supplies, priv->supplies);
 	if (ret < 0)
 		return ret;
 	mipi_dsi_msleep(&ctx, 120);
 	s6e3ha8_amb577px01_wqhd_reset(priv);
 
 	ret = s6e3ha8_amb577px01_wqhd_on(priv);
 	if (ret < 0) {
-		gpiod_set_value_cansleep(priv->reset_gpio, 0);
+		gpiod_set_value_cansleep(priv->reset_gpio, 1);
 		goto err;
 	}
 
 	drm_dsc_pps_payload_pack(&pps, &priv->dsc);
 
 	samsung_dsi_test_key_on_lvl1(&ctx);
 	mipi_dsi_picture_parameter_set_multi(&ctx, &pps);
 	samsung_dsi_test_key_off_lvl1(&ctx);
@@ -243,16 +244,27 @@ static const struct drm_display_mode s6e3ha8_amb577px01_wqhd_mode = {
 static const struct drm_panel_funcs s6e3ha8_amb577px01_wqhd_panel_funcs = {
 	.prepare = s6e3ha8_amb577px01_wqhd_prepare,
 	.unprepare = s6e3ha8_unprepare,
 	.get_modes = s6e3ha8_get_modes,
 	.enable = s6e3ha8_amb577px01_wqhd_enable,
 	.disable = s6e3ha8_amb577px01_wqhd_disable,
 };
 
+static const struct s6e3ha8_desc s6e3ha8_amb577px01_wqhd_desc_legacy = {
+	.funcs = &s6e3ha8_amb577px01_wqhd_panel_funcs,
+	.mode = &s6e3ha8_amb577px01_wqhd_mode,
+	.mode_flags = MIPI_DSI_CLOCK_NON_CONTINUOUS |
+		MIPI_DSI_MODE_VIDEO_NO_HFP | MIPI_DSI_MODE_VIDEO_NO_HBP |
+		MIPI_DSI_MODE_VIDEO_NO_HSA | MIPI_DSI_MODE_NO_EOT_PACKET,
+	.supplies = s6e3ha8_vddr_supplies,
+	.num_supplies = ARRAY_SIZE(s6e3ha8_vddr_supplies),
+	.broken_reset_polarity = true,
+};
+
 static const struct s6e3ha8_desc s6e3ha8_amb577px01_wqhd_desc = {
 	.funcs = &s6e3ha8_amb577px01_wqhd_panel_funcs,
 	.mode = &s6e3ha8_amb577px01_wqhd_mode,
 	.mode_flags = MIPI_DSI_CLOCK_NON_CONTINUOUS |
 		MIPI_DSI_MODE_VIDEO_NO_HFP | MIPI_DSI_MODE_VIDEO_NO_HBP |
 		MIPI_DSI_MODE_VIDEO_NO_HSA | MIPI_DSI_MODE_NO_EOT_PACKET,
 	.supplies = s6e3ha8_vddr_supplies,
 	.num_supplies = ARRAY_SIZE(s6e3ha8_vddr_supplies),
@@ -283,16 +295,19 @@ static int s6e3ha8_probe(struct mipi_dsi_device *dsi)
 		return ret;
 	}
 
 	priv->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
 	if (IS_ERR(priv->reset_gpio))
 		return dev_err_probe(dev, PTR_ERR(priv->reset_gpio),
 				     "Failed to get reset-gpios\n");
 
+	if (priv->desc->broken_reset_polarity)
+		gpiod_toggle_active_low(priv->reset_gpio);
+
 	priv->dsi = dsi;
 	mipi_dsi_set_drvdata(dsi, priv);
 
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
 	dsi->mode_flags = priv->desc->mode_flags;
 
 	priv->panel.prepare_prev_first = true;
@@ -323,17 +338,17 @@ static int s6e3ha8_probe(struct mipi_dsi_device *dsi)
 
 	return 0;
 }
 
 static const struct of_device_id s6e3ha8_of_match[] = {
 	{
 		/* deprecated */
 		.compatible = "samsung,s6e3ha8",
-		.data = &s6e3ha8_amb577px01_wqhd_desc,
+		.data = &s6e3ha8_amb577px01_wqhd_desc_legacy,
 	}, {
 		.compatible = "samsung,s6e3ha8-amb577px01",
 		.data = &s6e3ha8_amb577px01_wqhd_desc,
 	},
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, s6e3ha8_of_match);
 

-- 
2.55.0

