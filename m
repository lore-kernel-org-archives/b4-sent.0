From: David Heidelberg <david@ixit.cz>
Date: Sun, 20 Sep 2026 13:05:51 +0200
Subject: [PATCH 08/11] drm/panel: s6e3ha8: add Samsung AMB630QY01 (Google
 Pixel 3 XL) panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-crosshatch-panel-v1-8-de6e9512da96@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=10336; i=david@ixit.cz;
 h=from:subject:message-id; bh=lE2aNutv8i9DWJQD8Rm1+oupUbB8b9KVhavvt76t5Gg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqr74JkPuNohc3B6Pc/X1KpTsTto08XODGsIzAZ
 uypFoF4odaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaq++CQAKCRBgAj/E00kg
 cvS8D/9cMD+xI64wVSiO+sGkkN+ZvwP5I+elX5AkKYuO5YPs47b4JdL/KoK/Rh6NM5T2UMErO/Q
 Js4Kw6ERjHgLAkfhHxV/LGzpAGViJ+yg/XYmTgj8Yoo4ZmEtNmazgQ5IpsvomoGem/MWDDMGQHL
 70scJTOB89cHDXYXeExoPGqMGdjWwwmu6LCXfIDb5yokN6/j848uFxASCCdoy63apnKONcOeXpy
 HKpq7po+83gHSL8jyPIFZdPvTWKZPFIworkx2xL8ynmoDhEJSB5rIKmPyHAdN603eLErLVSIVoV
 ysLL3w5IWD2xAl+EN46Gc2SofBAMWpEeLuqK40+jjxrRyUDR1EvCvmFiJNLSUY0gW0RGkeJTN6e
 DZnDa26T+EL7nKRYZzyZEpDVuApOXREQ66G0YnS92GPv1Oaed2A8LaO/jP0GCcg2HvJKtEQTFO5
 c9JLzfCBhnYH/o/lC8Nu8hKw8DSVwLN29HZ4fFn2/5DHk5XDjbnr/FKAL2Aah1AOd6VtIssGSnp
 ge5G1ko6ztl9etqIt0nQFIuxxm41lLW0CDaGX7UKzzgo+Eji0NbU67gZPOXLdfcjJ1VSwhjKeXk
 DNCHweXbsvT5bRSyxz4wpJFb4bpiDxAHzTFA+FD2UcTLYqeWpWT0GySOJJ3lI5TjkyfxAcQBmq9
 Y29m3/M9MVV5CLg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Google Pixel 3 XL (crosshatch) uses a Samsung AMB630QY01 6.3"
1440x2960 flexible AMOLED panel, driven by the same S6E3HA8 DDIC as
the Galaxy S9 panel this driver already supports.

The init/teardown sequences and timings are taken from the downstream
dsi-panel-s6e3ha8-dsc-wqhd-cmd.dtsi (Google bluecross kernel). The
downstream DSI host neither appends EOT packets nor keeps the clock
lane in HS, so mirror that with the corresponding mode flags, and set
the RAM window explicitly since the kernel DSI host never sends the
column/page addresses the downstream one does.

Unlike the S9 panel, brightness is controlled with standard DCS
commands (10-bit), so register a backlight device for it. Brightness
readback is intentionally not implemented: DCS reads wedge the DSI
host command engine and take the display pipeline down with it.

Cosmtetics: update Copyright header and add myself.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c | 173 +++++++++++++++++++++++++-
 1 file changed, 168 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
index 2591b8c1a7753..e02f1d9f0dcd0 100644
--- a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
+++ b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
@@ -1,36 +1,42 @@
 // SPDX-License-Identifier: GPL-2.0-only
-//
-// Generated with linux-mdss-dsi-panel-driver-generator from vendor device tree:
-//	Copyright (c) 2013, The Linux Foundation. All rights reserved.
-// Copyright (c) 2024 Dzmitry Sankouski <dsankouski@gmail.com>
-
+/*
+ * Generated with linux-mdss-dsi-panel-driver-generator from vendor device tree:
+ *	Copyright (c) 2013, The Linux Foundation. All rights reserved.
+ * Copyright (c) 2024 Dzmitry Sankouski <dsankouski@gmail.com>
+ * Copyright David Heidelberg
+ */
+
+#include <linux/backlight.h>
 #include <linux/delay.h>
 #include <linux/gpio/consumer.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/property.h>
 #include <linux/regulator/consumer.h>
 
+#include <video/mipi_display.h>
+
 #include <drm/display/drm_dsc.h>
 #include <drm/display/drm_dsc_helper.h>
 #include <drm/drm_mipi_dsi.h>
 #include <drm/drm_probe_helper.h>
 #include <drm/drm_panel.h>
 
 #include "panel-samsung-dsi.h"
 
 struct s6e3ha8_desc {
 	const struct drm_panel_funcs *funcs;
 	const struct drm_display_mode *mode;
 	unsigned long mode_flags;
 	const struct regulator_bulk_data *supplies;
 	unsigned int num_supplies;
 	bool broken_reset_polarity;
+	bool has_backlight;
 };
 
 struct s6e3ha8 {
 	struct drm_panel panel;
 	struct mipi_dsi_device *dsi;
 	const struct s6e3ha8_desc *desc;
 	struct drm_dsc_config dsc;
 	struct gpio_desc *reset_gpio;
@@ -38,16 +44,23 @@ struct s6e3ha8 {
 };
 
 static const struct regulator_bulk_data s6e3ha8_vddr_supplies[] = {
 	{ .supply = "vdd3" },
 	{ .supply = "vci" },
 	{ .supply = "vddr" },
 };
 
+static const struct regulator_bulk_data s6e3ha8_boost_supplies[] = {
+	{ .supply = "vdd3" },
+	{ .supply = "vci" },
+	{ .supply = "vddpos" },
+	{ .supply = "vddneg" },
+};
+
 static inline struct s6e3ha8 *to_s6e3ha8(struct drm_panel *panel)
 {
 	return container_of(panel, struct s6e3ha8, panel);
 }
 
 #define s6e3ha8_afc_off(ctx) \
 	mipi_dsi_dcs_write_seq_multi(ctx, 0xe2, 0x00, 0x00)
 
@@ -72,16 +85,26 @@ static void s6e3ha8_amb577px01_wqhd_reset(struct s6e3ha8 *priv)
 	gpiod_set_value_cansleep(priv->reset_gpio, 0);
 	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(priv->reset_gpio, 1);
 	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(priv->reset_gpio, 0);
 	usleep_range(5000, 6000);
 }
 
+static void s6e3ha8_amb630qy01_reset(struct s6e3ha8 *priv)
+{
+	gpiod_set_value_cansleep(priv->reset_gpio, 0);
+	usleep_range(10000, 11000);
+	gpiod_set_value_cansleep(priv->reset_gpio, 1);
+	usleep_range(1000, 2000);
+	gpiod_set_value_cansleep(priv->reset_gpio, 0);
+	usleep_range(5000, 6000);
+}
+
 static int s6e3ha8_amb577px01_wqhd_on(struct s6e3ha8 *priv)
 {
 	struct mipi_dsi_device *dsi = priv->dsi;
 	struct mipi_dsi_multi_context ctx = { .dsi = dsi };
 
 	dsi->mode_flags |= MIPI_DSI_MODE_LPM;
 
 	samsung_dsi_test_key_on_lvl1(&ctx);
@@ -266,16 +289,146 @@ static const struct s6e3ha8_desc s6e3ha8_amb577px01_wqhd_desc = {
 	.mode = &s6e3ha8_amb577px01_wqhd_mode,
 	.mode_flags = MIPI_DSI_CLOCK_NON_CONTINUOUS |
 		MIPI_DSI_MODE_VIDEO_NO_HFP | MIPI_DSI_MODE_VIDEO_NO_HBP |
 		MIPI_DSI_MODE_VIDEO_NO_HSA | MIPI_DSI_MODE_NO_EOT_PACKET,
 	.supplies = s6e3ha8_vddr_supplies,
 	.num_supplies = ARRAY_SIZE(s6e3ha8_vddr_supplies),
 };
 
+static int s6e3ha8_amb630qy01_prepare(struct drm_panel *panel)
+{
+	struct s6e3ha8 *priv = to_s6e3ha8(panel);
+	struct mipi_dsi_multi_context ctx = { .dsi = priv->dsi };
+	struct drm_dsc_picture_parameter_set pps;
+	int ret;
+
+	ret = regulator_bulk_enable(priv->desc->num_supplies, priv->supplies);
+	if (ret < 0)
+		return ret;
+
+	s6e3ha8_amb630qy01_reset(priv);
+
+	mipi_dsi_compression_mode_multi(&ctx, true);
+
+	mipi_dsi_dcs_exit_sleep_mode_multi(&ctx);
+	mipi_dsi_msleep(&ctx, 120);
+
+	mipi_dsi_dcs_write_seq_multi(&ctx, MIPI_DCS_WRITE_CONTROL_DISPLAY, 0x20);
+	mipi_dsi_dcs_set_tear_on_multi(&ctx, MIPI_DSI_DCS_TEAR_MODE_VBLANK);
+
+	/*
+	 * Unlike the downstream DSI host, the kernel one never sends the
+	 * column/page addresses, so set the RAM window explicitly.
+	 */
+	mipi_dsi_dcs_set_column_address_multi(&ctx, 0, 1440 - 1);
+	mipi_dsi_dcs_set_page_address_multi(&ctx, 0, 2960 - 1);
+
+	samsung_dsi_test_key_on_lvl2(&ctx);
+	mipi_dsi_dcs_write_seq_multi(&ctx, 0xb9,
+				     0x01, 0xb0, 0x81, 0x09, 0x00, 0x00, 0x00,
+				     0x11, 0x03); /* TSP HSYNC Setting */
+	samsung_dsi_test_key_off_lvl2(&ctx);
+
+	drm_dsc_pps_payload_pack(&pps, &priv->dsc);
+	mipi_dsi_picture_parameter_set_multi(&ctx, &pps);
+
+	if (ctx.accum_err) {
+		gpiod_set_value_cansleep(priv->reset_gpio, 1);
+		regulator_bulk_disable(priv->desc->num_supplies, priv->supplies);
+	}
+
+	return ctx.accum_err;
+}
+
+static int s6e3ha8_amb630qy01_enable(struct drm_panel *panel)
+{
+	struct s6e3ha8 *priv = to_s6e3ha8(panel);
+	struct mipi_dsi_multi_context ctx = { .dsi = priv->dsi };
+
+	mipi_dsi_dcs_set_display_on_multi(&ctx);
+
+	return ctx.accum_err;
+}
+
+static int s6e3ha8_amb630qy01_disable(struct drm_panel *panel)
+{
+	struct s6e3ha8 *priv = to_s6e3ha8(panel);
+	struct mipi_dsi_multi_context ctx = { .dsi = priv->dsi };
+
+	mipi_dsi_dcs_set_display_off_multi(&ctx);
+	mipi_dsi_msleep(&ctx, 10);
+	mipi_dsi_dcs_enter_sleep_mode_multi(&ctx);
+	mipi_dsi_msleep(&ctx, 120);
+
+	return ctx.accum_err;
+}
+
+static const struct drm_display_mode s6e3ha8_amb630qy01_mode = {
+	.clock = (1440 + 116 + 44 + 116) * (2960 + 124 + 120 + 80) * 60 / 1000,
+	.hdisplay = 1440,
+	.hsync_start = 1440 + 116,
+	.hsync_end = 1440 + 116 + 44,
+	.htotal = 1440 + 116 + 44 + 116,
+	.vdisplay = 2960,
+	.vsync_start = 2960 + 124,
+	.vsync_end = 2960 + 124 + 120,
+	.vtotal = 2960 + 124 + 120 + 80,
+	.width_mm = 70,
+	.height_mm = 144,
+};
+
+static const struct drm_panel_funcs s6e3ha8_amb630qy01_panel_funcs = {
+	.prepare = s6e3ha8_amb630qy01_prepare,
+	.unprepare = s6e3ha8_unprepare,
+	.get_modes = s6e3ha8_get_modes,
+	.enable = s6e3ha8_amb630qy01_enable,
+	.disable = s6e3ha8_amb630qy01_disable,
+};
+
+static const struct s6e3ha8_desc s6e3ha8_amb630qy01_desc = {
+	.funcs = &s6e3ha8_amb630qy01_panel_funcs,
+	.mode = &s6e3ha8_amb630qy01_mode,
+	.mode_flags = MIPI_DSI_MODE_LPM | MIPI_DSI_CLOCK_NON_CONTINUOUS |
+		      MIPI_DSI_MODE_NO_EOT_PACKET,
+	.supplies = s6e3ha8_boost_supplies,
+	.num_supplies = ARRAY_SIZE(s6e3ha8_boost_supplies),
+	.has_backlight = true,
+};
+
+static int s6e3ha8_bl_update_status(struct backlight_device *bl)
+{
+	struct mipi_dsi_device *dsi = bl_get_data(bl);
+	u16 brightness = backlight_get_brightness(bl);
+
+	return mipi_dsi_dcs_set_display_brightness_large(dsi, brightness);
+}
+
+/*
+ * No .get_brightness: DCS reads wedge the DSI host command engine and
+ * take the whole display pipeline down with it.
+ */
+static const struct backlight_ops s6e3ha8_bl_ops = {
+	.update_status = s6e3ha8_bl_update_status,
+};
+
+static struct backlight_device *
+s6e3ha8_create_backlight(struct mipi_dsi_device *dsi)
+{
+	struct device *dev = &dsi->dev;
+	const struct backlight_properties props = {
+		.type = BACKLIGHT_RAW,
+		.brightness = 512,
+		.max_brightness = 1023,
+	};
+
+	return devm_backlight_device_register(dev, dev_name(dev), dev, dsi,
+					      &s6e3ha8_bl_ops, &props);
+}
+
 static int s6e3ha8_probe(struct mipi_dsi_device *dsi)
 {
 	struct device *dev = &dsi->dev;
 	const struct s6e3ha8_desc *desc;
 	struct s6e3ha8 *priv;
 	int ret;
 
 	desc = device_get_match_data(dev);
@@ -308,16 +461,23 @@ static int s6e3ha8_probe(struct mipi_dsi_device *dsi)
 	mipi_dsi_set_drvdata(dsi, priv);
 
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
 	dsi->mode_flags = priv->desc->mode_flags;
 
 	priv->panel.prepare_prev_first = true;
 
+	if (priv->desc->has_backlight) {
+		priv->panel.backlight = s6e3ha8_create_backlight(dsi);
+		if (IS_ERR(priv->panel.backlight))
+			return dev_err_probe(dev, PTR_ERR(priv->panel.backlight),
+					     "Failed to create backlight\n");
+	}
+
 	ret = devm_drm_panel_add(dev, &priv->panel);
 	if (ret)
 		return ret;
 
 	/* This panel only supports DSC; unconditionally enable it */
 	dsi->dsc = &priv->dsc;
 
 	priv->dsc.dsc_version_major = 1;
@@ -343,16 +503,19 @@ static int s6e3ha8_probe(struct mipi_dsi_device *dsi)
 static const struct of_device_id s6e3ha8_of_match[] = {
 	{
 		/* deprecated */
 		.compatible = "samsung,s6e3ha8",
 		.data = &s6e3ha8_amb577px01_wqhd_desc_legacy,
 	}, {
 		.compatible = "samsung,s6e3ha8-amb577px01",
 		.data = &s6e3ha8_amb577px01_wqhd_desc,
+	}, {
+		.compatible = "samsung,s6e3ha8-amb630qy01",
+		.data = &s6e3ha8_amb630qy01_desc,
 	},
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, s6e3ha8_of_match);
 
 static struct mipi_dsi_driver s6e3ha8_driver = {
 	.probe = s6e3ha8_probe,
 	.driver = {

-- 
2.55.0

