From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 17 Mar 2026 00:23:08 -0500
Subject: [PATCH v2 2/2] drm/panel: Add panel driver for ChipWealth CH13726A
 based panels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260317-ch13726a-v2-2-28aa46bcd6d0@gmail.com>
References: <20260317-ch13726a-v2-0-28aa46bcd6d0@gmail.com>
In-Reply-To: <20260317-ch13726a-v2-0-28aa46bcd6d0@gmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Teguh Sobirin <teguh@sobir.in>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773725020; l=11523;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=PGS1htHub0KITyss9Eg2gXWt15DqDviEDfgDHc/FXP4=;
 b=enWXU+7dQxRS2OCu1hfzr2hpQYJKiHviwO6D7ob0pHgGTSnDpKpb4kNixwwAHVx14MXN60WSz
 i+JsxNeDAUwALz2NILNUzpyj24n6K1bJYoeEQxsBnYydiG/bRBBUMG+
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

This is used by the AYN Thor for the bottom panel.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Co-developed-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpu/drm/panel/Kconfig                     |  11 +
 drivers/gpu/drm/panel/Makefile                    |   1 +
 drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c | 339 ++++++++++++++++++++++
 3 files changed, 351 insertions(+)

diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index a99f2e2a49fe66a09c6f2d503f570b05a5e228b1..e953b61a819082866b93d0a453ee750a76d70c18 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -105,6 +105,17 @@ config DRM_PANEL_BOE_TV101WUM_LL2
 	  Say Y here if you want to support for BOE TV101WUM-LL2
 	  WUXGA PANEL DSI Video Mode panel
 
+config DRM_PANEL_CHIPWEALTH_CH13726A
+	tristate "CHIPWEALTH CH13726A-based DSI panel"
+	depends on OF
+	depends on DRM_MIPI_DSI
+	depends on BACKLIGHT_CLASS_DEVICE
+	select DRM_DISPLAY_DP_HELPER
+	select DRM_DISPLAY_HELPER
+	help
+	  Say Y here if you want to enable support for ChipWealth
+	  CH13726A-based display panels.
+
 config DRM_PANEL_EBBG_FT8719
 	tristate "EBBG FT8719 panel driver"
 	depends on OF
diff --git a/drivers/gpu/drm/panel/Makefile b/drivers/gpu/drm/panel/Makefile
index 3336a2c0cd86419b6a22f74dcde6df966a311da9..85da2eb5a5c664d4302837f52e7e10ec11da8966 100644
--- a/drivers/gpu/drm/panel/Makefile
+++ b/drivers/gpu/drm/panel/Makefile
@@ -9,6 +9,7 @@ obj-$(CONFIG_DRM_PANEL_BOE_TD4320) += panel-boe-td4320.o
 obj-$(CONFIG_DRM_PANEL_BOE_TH101MB31UIG002_28A) += panel-boe-th101mb31ig002-28a.o
 obj-$(CONFIG_DRM_PANEL_BOE_TV101WUM_LL2) += panel-boe-tv101wum-ll2.o
 obj-$(CONFIG_DRM_PANEL_BOE_TV101WUM_NL6) += panel-boe-tv101wum-nl6.o
+obj-$(CONFIG_DRM_PANEL_CHIPWEALTH_CH13726A) += panel-chipwealth-ch13726a.o
 obj-$(CONFIG_DRM_PANEL_DSI_CM) += panel-dsi-cm.o
 obj-$(CONFIG_DRM_PANEL_LVDS) += panel-lvds.o
 obj-$(CONFIG_DRM_PANEL_SIMPLE) += panel-simple.o
diff --git a/drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c b/drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c
new file mode 100644
index 0000000000000000000000000000000000000000..48a5e20e07c48748e073f8bb9147036c18c51caa
--- /dev/null
+++ b/drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c
@@ -0,0 +1,339 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * ChipWealth CH13726A MIPI-DSI panel driver
+ * Copyright (c) 2024, Teguh Sobirin <teguh@sobir.in>.
+ */
+
+#include <linux/backlight.h>
+#include <linux/delay.h>
+#include <linux/gpio/consumer.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/regulator/consumer.h>
+
+#include <drm/drm_mipi_dsi.h>
+#include <drm/drm_modes.h>
+#include <drm/drm_panel.h>
+
+#include <video/mipi_display.h>
+
+struct ch13726a_panel {
+	struct drm_panel panel;
+	struct mipi_dsi_device *dsi;
+	struct regulator_bulk_data supplies[4];
+	struct gpio_desc *reset_gpio;
+	struct ch13726a_desc *desc;
+	enum drm_panel_orientation orientation;
+	bool prepared;
+};
+
+struct ch13726a_desc {
+	unsigned int width_mm;
+	unsigned int height_mm;
+	unsigned int bpc;
+
+	const struct drm_display_mode *modes;
+	unsigned int num_modes;
+};
+
+static inline struct ch13726a_panel *to_ch13726a_panel(struct drm_panel *panel)
+{
+	return container_of(panel, struct ch13726a_panel, panel);
+}
+
+static void ch13726a_reset(struct ch13726a_panel *ctx)
+{
+	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+	usleep_range(10000, 11000);
+	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
+	usleep_range(10000, 11000);
+	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+	usleep_range(10000, 11000);
+}
+
+static int ch13726a_on(struct ch13726a_panel *ctx)
+{
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
+
+	ctx->dsi->mode_flags |= MIPI_DSI_MODE_LPM;
+
+	mipi_dsi_generic_write_seq_multi(&dsi_ctx, 0xf0, 0x50);
+	mipi_dsi_generic_write_seq_multi(&dsi_ctx, 0xb9, 0x00);
+
+	mipi_dsi_dcs_exit_sleep_mode_multi(&dsi_ctx);
+
+	mipi_dsi_dcs_set_display_on_multi(&dsi_ctx);
+
+	return dsi_ctx.accum_err;
+}
+
+static int ch13726a_disable(struct drm_panel *panel)
+{
+	struct ch13726a_panel *ctx = to_ch13726a_panel(panel);
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
+
+	ctx->dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
+
+	mipi_dsi_dcs_set_display_off_multi(&dsi_ctx);
+	mipi_dsi_msleep(&dsi_ctx, 50);
+	mipi_dsi_dcs_enter_sleep_mode_multi(&dsi_ctx);
+
+	return dsi_ctx.accum_err;
+}
+
+static int ch13726a_prepare(struct drm_panel *panel)
+{
+	struct ch13726a_panel *ctx = to_ch13726a_panel(panel);
+	struct device *dev = &ctx->dsi->dev;
+	int ret;
+
+	if (ctx->prepared)
+		return 0;
+
+	ret = regulator_bulk_enable(ARRAY_SIZE(ctx->supplies), ctx->supplies);
+	if (ret < 0) {
+		dev_err(dev, "Failed to enable regulators: %d\n", ret);
+		return ret;
+	}
+
+	ch13726a_reset(ctx);
+
+	ret = ch13726a_on(ctx);
+	if (ret < 0) {
+		dev_err(dev, "Failed to initialize panel: %d\n", ret);
+		gpiod_set_value_cansleep(ctx->reset_gpio, 0);
+		regulator_bulk_disable(ARRAY_SIZE(ctx->supplies), ctx->supplies);
+		return ret;
+	}
+
+	msleep(28);
+
+	ctx->prepared = true;
+
+	return 0;
+}
+
+static int ch13726a_unprepare(struct drm_panel *panel)
+{
+	struct ch13726a_panel *ctx = to_ch13726a_panel(panel);
+
+	if (!ctx->prepared)
+		return 0;
+
+	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
+	regulator_bulk_disable(ARRAY_SIZE(ctx->supplies), ctx->supplies);
+
+	ctx->prepared = false;
+	return 0;
+}
+
+static const struct drm_display_mode thor_bottom_modes[] = {
+	{
+		/* 120Hz */
+		.clock = (1080 + 28 + 4 + 36) * (1240 + 16 + 4 + 8) * 120 / 1000,
+		.hdisplay = 1080,
+		.hsync_start = 1080 + 28,
+		.hsync_end = 1080 + 28 + 4,
+		.htotal = 1080 + 28 + 4 + 36,
+		.vdisplay = 1240,
+		.vsync_start = 1240 + 16,
+		.vsync_end = 1240 + 16 + 4,
+		.vtotal = 1240 + 16 + 4 + 8,
+	},
+	{
+		/* 60Hz */
+		.clock = (1080 + 28 + 4 + 36) * (1240 + 16 + 4 + 8) * 60 / 1000,
+		.hdisplay = 1080,
+		.hsync_start = 1080 + 28,
+		.hsync_end = 1080 + 28 + 4,
+		.htotal = 1080 + 28 + 4 + 36,
+		.vdisplay = 1240,
+		.vsync_start = 1240 + 16,
+		.vsync_end = 1240 + 16 + 4,
+		.vtotal = 1240 + 16 + 4 + 8,
+	}
+};
+
+static struct ch13726a_desc thor_bottom_desc = {
+	.modes = thor_bottom_modes,
+	.num_modes = ARRAY_SIZE(thor_bottom_modes),
+	.width_mm = 65,
+	.height_mm = 75,
+	.bpc = 8,
+};
+
+static int ch13726a_get_modes(struct drm_panel *panel,
+					struct drm_connector *connector)
+{
+	struct ch13726a_panel *ctx = to_ch13726a_panel(panel);
+
+	for (uint8_t i = 0; i < ctx->desc->num_modes; i++) {
+		const struct drm_display_mode *m = &ctx->desc->modes[i];
+		struct drm_display_mode *mode;
+
+		mode = drm_mode_duplicate(connector->dev, m);
+		if (!mode) {
+			dev_err(&ctx->dsi->dev, "failed to add mode %ux%u@%u\n",
+				m->hdisplay, m->vdisplay, drm_mode_vrefresh(m));
+			return -ENOMEM;
+		}
+
+		mode->type = DRM_MODE_TYPE_DRIVER;
+		if (i == 0)
+			mode->type |= DRM_MODE_TYPE_PREFERRED;
+
+		drm_mode_set_name(mode);
+		drm_mode_probed_add(connector, mode);
+	}
+
+	connector->display_info.width_mm = ctx->desc->width_mm;
+	connector->display_info.height_mm = ctx->desc->height_mm;
+	connector->display_info.bpc = ctx->desc->bpc;
+
+	return ctx->desc->num_modes;
+}
+
+static enum drm_panel_orientation ch13726a_get_orientation(struct drm_panel *panel)
+{
+	struct ch13726a_panel *ctx = to_ch13726a_panel(panel);
+
+	return ctx->orientation;
+}
+
+static const struct drm_panel_funcs ch13726a_panel_funcs = {
+	.prepare = ch13726a_prepare,
+	.unprepare = ch13726a_unprepare,
+	.disable = ch13726a_disable,
+	.get_modes = ch13726a_get_modes,
+	.get_orientation = ch13726a_get_orientation,
+};
+
+static int ch13726a_bl_update_status(struct backlight_device *bl)
+{
+	struct mipi_dsi_device *dsi = bl_get_data(bl);
+	u16 brightness = backlight_get_brightness(bl);
+	int ret;
+
+	dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
+
+	ret = mipi_dsi_dcs_set_display_brightness(dsi, brightness);
+	if (ret < 0)
+		return ret;
+
+	dsi->mode_flags |= MIPI_DSI_MODE_LPM;
+
+	return 0;
+}
+
+static const struct backlight_ops ch13726a_bl_ops = {
+	.update_status = ch13726a_bl_update_status,
+};
+
+static struct backlight_device *
+ch13726a_create_backlight(struct mipi_dsi_device *dsi)
+{
+	struct device *dev = &dsi->dev;
+	const struct backlight_properties props = {
+		.type = BACKLIGHT_RAW,
+		.brightness = 255,
+		.max_brightness = 255,
+	};
+
+	return devm_backlight_device_register(dev, dev_name(dev), dev, dsi,
+					      &ch13726a_bl_ops, &props);
+}
+
+static int ch13726a_probe(struct mipi_dsi_device *dsi)
+{
+	struct device *dev = &dsi->dev;
+	struct ch13726a_panel *ctx;
+	int ret;
+
+	ctx = devm_kzalloc(dev, sizeof(*ctx), GFP_KERNEL);
+	if (!ctx)
+		return -ENOMEM;
+
+	ctx->desc = (struct ch13726a_desc *)of_device_get_match_data(dev);
+	if (!ctx->desc)
+		return -ENODEV;
+
+	ctx->supplies[0].supply = "vdd1v2";
+	ctx->supplies[1].supply = "vddio";
+	ctx->supplies[2].supply = "vdd";
+	ctx->supplies[3].supply = "avdd";
+
+	ret = devm_regulator_bulk_get(dev, ARRAY_SIZE(ctx->supplies),
+				      ctx->supplies);
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "Failed to get regulators\n");
+
+	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
+	if (IS_ERR(ctx->reset_gpio))
+		return dev_err_probe(dev, PTR_ERR(ctx->reset_gpio),
+				     "Failed to get reset-gpios\n");
+
+	ret = of_drm_get_panel_orientation(dev->of_node, &ctx->orientation);
+	if (ret < 0) {
+		dev_err(dev, "%pOF: failed to get orientation %d\n", dev->of_node, ret);
+		return ret;
+	}
+
+	ctx->dsi = dsi;
+	mipi_dsi_set_drvdata(dsi, ctx);
+
+	dsi->lanes = 4;
+	dsi->format = MIPI_DSI_FMT_RGB888;
+	dsi->mode_flags = MIPI_DSI_MODE_VIDEO |
+			  MIPI_DSI_CLOCK_NON_CONTINUOUS;
+
+	drm_panel_init(&ctx->panel, dev, &ch13726a_panel_funcs,
+		       DRM_MODE_CONNECTOR_DSI);
+	ctx->panel.prepare_prev_first = true;
+
+	ctx->panel.backlight = ch13726a_create_backlight(dsi);
+	if (IS_ERR(ctx->panel.backlight))
+		return dev_err_probe(dev, PTR_ERR(ctx->panel.backlight),
+				     "Failed to create backlight\n");
+
+	drm_panel_add(&ctx->panel);
+
+	ret = mipi_dsi_attach(dsi);
+	if (ret < 0) {
+		dev_err(dev, "Failed to attach to DSI host: %d\n", ret);
+		drm_panel_remove(&ctx->panel);
+		return ret;
+	}
+
+	return 0;
+}
+
+static void ch13726a_remove(struct mipi_dsi_device *dsi)
+{
+	struct ch13726a_panel *ctx = mipi_dsi_get_drvdata(dsi);
+	int ret;
+
+	ret = mipi_dsi_detach(dsi);
+	if (ret < 0)
+		dev_err(&dsi->dev, "Failed to detach from DSI host: %d\n", ret);
+
+	drm_panel_remove(&ctx->panel);
+}
+
+static const struct of_device_id ch13726a_of_match[] = {
+	{ .compatible = "ayntec,thor-panel-bottom", .data = &thor_bottom_desc },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ch13726a_of_match);
+
+static struct mipi_dsi_driver ch13726a_driver = {
+	.probe = ch13726a_probe,
+	.remove = ch13726a_remove,
+	.driver = {
+		.name = "panel-ch13726a-amoled",
+		.of_match_table = ch13726a_of_match,
+	},
+};
+module_mipi_dsi_driver(ch13726a_driver);
+
+MODULE_DESCRIPTION("DRM driver for CH13726A DSI panels");
+MODULE_LICENSE("GPL");

-- 
2.53.0

