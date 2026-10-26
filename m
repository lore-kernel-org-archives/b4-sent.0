From: Ishu Brar <patches@brar.si>
Date: Mon, 26 Oct 2026 22:09:33 +0530
Subject: [PATCH v2 2/2] drm/panel: Add Samsung AMS644VK04 panel driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-panel-ams644vk04-v2-2-e88cafb3e577@brar.si>
References: <20261026-panel-ams644vk04-v2-0-e88cafb3e577@brar.si>
In-Reply-To: <20261026-panel-ams644vk04-v2-0-e88cafb3e577@brar.si>
To: Ishu Brar <patches@brar.si>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793032778; l=15260;
 i=patches@brar.si; h=from:subject:message-id;
 bh=t3mBNh6rIPjSdrFr6bSY+pSa1ef2kkMEoH1YpnI3XHA=;
 b=6ubxb1VSYFO4SDgVNp5JkHDq2U0foqLxY1RNXPSpKw4jG53Nr0/hHRIns6hsvnzgnnvjXKigh
 Ae1llZtCCGwDzdSUNrh+fKTxZ6AbNsO1k/1YSkKZBALjBs4q8h5b66U
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the Samsung AMS644VK04, a 1080x2400 DSI command mode
AMOLED panel with DSC found in the OnePlus Nord (SM7250). It uses four
lanes and DSC 1.1 at 8 bits per pixel.

The initialisation sequence comes from the downstream driver. The DSC
picture parameter set is built with drm_dsc_pps_payload_pack() from the
same drm_dsc_config the DSI host uses. Only the 90 Hz mode is described
for now.

Tested on a OnePlus Nord with the msm DSI host, including suspend and
resume.

Signed-off-by: Ishu Brar <patches@brar.si>
---
 MAINTAINERS                                      |   1 +
 drivers/gpu/drm/panel/Kconfig                    |  17 ++
 drivers/gpu/drm/panel/Makefile                   |   1 +
 drivers/gpu/drm/panel/panel-samsung-ams644vk04.c | 356 +++++++++++++++++++++++
 4 files changed, 375 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 19ec9f8b522f..b409a7f3985f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -8466,6 +8466,7 @@ DRM DRIVER FOR SAMSUNG AMS644VK04 PANEL
 M:	Ishu Brar <patches@brar.si>
 S:	Maintained
 F:	Documentation/devicetree/bindings/display/panel/samsung,ams644vk04.yaml
+F:	drivers/gpu/drm/panel/panel-samsung-ams644vk04.c
 
 DRM DRIVER FOR SAMSUNG DB7430 PANELS
 M:	Linus Walleij <linusw@kernel.org>
diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index 7a520b4d60fe..7cb0ff13c037 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -956,6 +956,23 @@ config DRM_PANEL_SAMSUNG_AMS639RQ08
 	  Say Y or M here if you want to enable support for the
 	  Samsung AMS639RQ08 FHD Plus (2340x1080@60Hz) CMD mode panel.
 
+config DRM_PANEL_SAMSUNG_AMS644VK04
+	tristate "Samsung AMS644VK04 panel"
+	depends on OF
+	depends on DRM_MIPI_DSI
+	depends on BACKLIGHT_CLASS_DEVICE
+	depends on GPIOLIB
+	depends on REGULATOR
+	select DRM_DISPLAY_DSC_HELPER
+	select DRM_DISPLAY_HELPER
+	help
+	  Say Y or M here if you want to enable support for the
+	  Samsung AMS644VK04 FHD Plus (1080x2400) DSC command mode AMOLED
+	  panel, found in the OnePlus Nord.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called panel-samsung-ams644vk04.
+
 config DRM_PANEL_SAMSUNG_S6E88A0_AMS427AP24
 	tristate "Samsung AMS427AP24 panel with S6E88A0 controller"
 	depends on GPIOLIB && OF && REGULATOR
diff --git a/drivers/gpu/drm/panel/Makefile b/drivers/gpu/drm/panel/Makefile
index da5175909d54..01c1ca740dac 100644
--- a/drivers/gpu/drm/panel/Makefile
+++ b/drivers/gpu/drm/panel/Makefile
@@ -92,6 +92,7 @@ obj-$(CONFIG_DRM_PANEL_RENESAS_R69328) += panel-renesas-r69328.o
 obj-$(CONFIG_DRM_PANEL_RONBO_RB070D30) += panel-ronbo-rb070d30.o
 obj-$(CONFIG_DRM_PANEL_SAMSUNG_AMS581VF01) += panel-samsung-ams581vf01.o
 obj-$(CONFIG_DRM_PANEL_SAMSUNG_AMS639RQ08) += panel-samsung-ams639rq08.o
+obj-$(CONFIG_DRM_PANEL_SAMSUNG_AMS644VK04) += panel-samsung-ams644vk04.o
 obj-$(CONFIG_DRM_PANEL_SAMSUNG_ATNA33XC20) += panel-samsung-atna33xc20.o
 obj-$(CONFIG_DRM_PANEL_SAMSUNG_DB7430) += panel-samsung-db7430.o
 obj-$(CONFIG_DRM_PANEL_SAMSUNG_LD9040) += panel-samsung-ld9040.o
diff --git a/drivers/gpu/drm/panel/panel-samsung-ams644vk04.c b/drivers/gpu/drm/panel/panel-samsung-ams644vk04.c
new file mode 100644
index 000000000000..3cbe1fd9aa01
--- /dev/null
+++ b/drivers/gpu/drm/panel/panel-samsung-ams644vk04.c
@@ -0,0 +1,356 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Samsung AMS644VK04 AMOLED DSI command mode panel driver (DSC)
+ *
+ * 1080x2400, 4 lanes, DSC 1.1 8 bpc -> 8 bpp, 90 Hz.
+ * Found in the OnePlus Nord (avicii).
+ *
+ * The initialisation sequences were generated from the downstream panel
+ * description ("samsung ams644vk04 fhd cmd mode dsc dsi panel").
+ */
+
+#include <linux/backlight.h>
+#include <linux/delay.h>
+#include <linux/gpio/consumer.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/regulator/consumer.h>
+
+#include <drm/display/drm_dsc.h>
+#include <drm/display/drm_dsc_helper.h>
+#include <drm/drm_mipi_dsi.h>
+#include <drm/drm_modes.h>
+#include <drm/drm_panel.h>
+#include <drm/drm_probe_helper.h>
+
+#define AMS644VK04_WIDTH		1080
+#define AMS644VK04_HEIGHT		2400
+
+#define AMS644VK04_MAX_BRIGHTNESS	0x7ff
+#define AMS644VK04_DEFAULT_BRIGHTNESS	0x140
+
+/* Power-on order and expected load as given by the downstream supply entries */
+static const struct regulator_bulk_data ams644vk04_supplies[] = {
+	{ .supply = "vddio", .init_load_uA = 62000 },
+	{ .supply = "vout", .init_load_uA = 857000 },
+	{ .supply = "vdd", .init_load_uA = 857000 },
+};
+
+struct ams644vk04 {
+	struct drm_panel panel;
+	struct mipi_dsi_device *dsi;
+	struct drm_dsc_config dsc;
+	struct gpio_desc *reset_gpio;
+	struct regulator_bulk_data *supplies;
+	bool prepared;
+};
+
+static inline struct ams644vk04 *to_ams644vk04(struct drm_panel *panel)
+{
+	return container_of(panel, struct ams644vk04, panel);
+}
+
+static void ams644vk04_send_on(struct mipi_dsi_multi_context *dsi_ctx,
+			       const struct drm_dsc_config *dsc)
+{
+	struct drm_dsc_picture_parameter_set pps;
+
+	drm_dsc_pps_payload_pack(&pps, dsc);
+
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0x5a, 0x5a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9d, 0x01);
+	mipi_dsi_picture_parameter_set_multi(dsi_ctx, &pps);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0xa5, 0xa5);
+	mipi_dsi_dcs_exit_sleep_mode_multi(dsi_ctx);
+	mipi_dsi_msleep(dsi_ctx, 20);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0x5a, 0x5a);
+	mipi_dsi_dcs_set_tear_on_multi(dsi_ctx, MIPI_DSI_DCS_TEAR_MODE_VBLANK);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0xa5, 0xa5);
+	mipi_dsi_dcs_set_column_address_multi(dsi_ctx, 0, AMS644VK04_WIDTH - 1);
+	mipi_dsi_dcs_set_page_address_multi(dsi_ctx, 0, AMS644VK04_HEIGHT - 1);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0x5a, 0x5a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf5, 0x85);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb0, 0x02);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf8, 0xc4);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb0, 0x04);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf8, 0x41, 0x47, 0x11, 0xb8, 0xb8);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb0, 0x02);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf8, 0xcc);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb0, 0x03);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf2, 0x82);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf5, 0x87);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0xa5, 0xa5);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0x5a, 0x5a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb0, 0x03);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xdd, 0x40);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0xa5, 0xa5);
+	mipi_dsi_msleep(dsi_ctx, 110);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0x5a, 0x5a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb0, 0x06);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb7, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb0, 0x05);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb7, 0x13);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb7, 0x01, 0x37);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0xa5, 0xa5);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x53, 0x20);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0x5a, 0x5a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x60, 0x10);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0xa5, 0xa5);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0x5a, 0x5a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x55, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0xa5, 0xa5);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0x5a, 0x5a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xbd, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0xa5, 0xa5);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0x5a, 0x5a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe6, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf0, 0xa5, 0xa5);
+	mipi_dsi_dcs_set_display_on_multi(dsi_ctx);
+}
+
+static void ams644vk04_send_off(struct mipi_dsi_multi_context *dsi_ctx)
+{
+	mipi_dsi_dcs_set_display_off_multi(dsi_ctx);
+	mipi_dsi_msleep(dsi_ctx, 10);
+	mipi_dsi_dcs_enter_sleep_mode_multi(dsi_ctx);
+	mipi_dsi_msleep(dsi_ctx, 120);
+}
+
+static void ams644vk04_reset(struct ams644vk04 *ctx)
+{
+	/* Same timing as downstream: 10 ms steps, the logical value 1 asserts reset */
+	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
+	usleep_range(10000, 10100);
+	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+	usleep_range(10000, 10100);
+	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
+	usleep_range(10000, 10100);
+}
+
+static void ams644vk04_supplies_disable(struct ams644vk04 *ctx, int first)
+{
+	int i;
+
+	for (i = first; i >= 0; i--)
+		regulator_disable(ctx->supplies[i].consumer);
+}
+
+static int ams644vk04_supplies_enable(struct ams644vk04 *ctx)
+{
+	struct device *dev = &ctx->dsi->dev;
+	int i, ret;
+
+	/* The rails come up one after the other, vddio and vout need time to settle */
+	for (i = 0; i < ARRAY_SIZE(ams644vk04_supplies); i++) {
+		ret = regulator_enable(ctx->supplies[i].consumer);
+		if (ret) {
+			dev_err(dev, "Failed to enable %s: %d\n",
+				ams644vk04_supplies[i].supply, ret);
+			ams644vk04_supplies_disable(ctx, i - 1);
+			return ret;
+		}
+
+		if (i < ARRAY_SIZE(ams644vk04_supplies) - 1)
+			msleep(20);
+	}
+
+	return 0;
+}
+
+static int ams644vk04_prepare(struct drm_panel *panel)
+{
+	struct ams644vk04 *ctx = to_ams644vk04(panel);
+	struct device *dev = &ctx->dsi->dev;
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
+	int ret;
+
+	ret = ams644vk04_supplies_enable(ctx);
+	if (ret)
+		return ret;
+
+	ams644vk04_reset(ctx);
+
+	ams644vk04_send_on(&dsi_ctx, &ctx->dsc);
+	if (dsi_ctx.accum_err) {
+		ret = dsi_ctx.accum_err;
+		dev_err(dev, "Failed to send on sequence: %d\n", ret);
+		goto err_power_down;
+	}
+
+	ctx->prepared = true;
+
+	return 0;
+
+err_power_down:
+	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+	ams644vk04_supplies_disable(ctx, ARRAY_SIZE(ams644vk04_supplies) - 1);
+
+	return ret;
+}
+
+static int ams644vk04_unprepare(struct drm_panel *panel)
+{
+	struct ams644vk04 *ctx = to_ams644vk04(panel);
+	struct device *dev = &ctx->dsi->dev;
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
+
+	ctx->prepared = false;
+
+	ams644vk04_send_off(&dsi_ctx);
+	if (dsi_ctx.accum_err)
+		dev_err(dev, "Failed to send off sequence: %d\n", dsi_ctx.accum_err);
+
+	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+	ams644vk04_supplies_disable(ctx, ARRAY_SIZE(ams644vk04_supplies) - 1);
+
+	return 0;
+}
+
+/*
+ * Timings are the downstream ones.  The clock is htotal * vtotal * refresh:
+ * the msm DSI host scales the pixel clock for DSC by itself, so the mode
+ * describes the uncompressed picture.
+ */
+static const struct drm_display_mode ams644vk04_mode = {
+	.clock = (1080 + 52 + 24 + 24) * (2400 + 4 + 4 + 8) * 90 / 1000,
+	.hdisplay = 1080,
+	.hsync_start = 1080 + 52,
+	.hsync_end = 1080 + 52 + 24,
+	.htotal = 1080 + 52 + 24 + 24,
+	.vdisplay = 2400,
+	.vsync_start = 2400 + 4,
+	.vsync_end = 2400 + 4 + 4,
+	.vtotal = 2400 + 4 + 4 + 8,
+	.width_mm = 67,
+	.height_mm = 149,
+	.type = DRM_MODE_TYPE_DRIVER,
+};
+
+static int ams644vk04_get_modes(struct drm_panel *panel,
+				struct drm_connector *connector)
+{
+	return drm_connector_helper_get_modes_fixed(connector, &ams644vk04_mode);
+}
+
+static const struct drm_panel_funcs ams644vk04_panel_funcs = {
+	.prepare = ams644vk04_prepare,
+	.unprepare = ams644vk04_unprepare,
+	.get_modes = ams644vk04_get_modes,
+};
+
+static int ams644vk04_bl_update_status(struct backlight_device *bl)
+{
+	struct ams644vk04 *ctx = bl_get_data(bl);
+
+	if (!ctx->prepared)
+		return 0;
+
+	/* The panel takes the 11 bit level most significant byte first */
+	return mipi_dsi_dcs_set_display_brightness_large(ctx->dsi,
+							 backlight_get_brightness(bl));
+}
+
+static const struct backlight_ops ams644vk04_bl_ops = {
+	.update_status = ams644vk04_bl_update_status,
+};
+
+static int ams644vk04_probe(struct mipi_dsi_device *dsi)
+{
+	struct device *dev = &dsi->dev;
+	const struct backlight_properties props = {
+		.type = BACKLIGHT_RAW,
+		.brightness = AMS644VK04_DEFAULT_BRIGHTNESS,
+		.max_brightness = AMS644VK04_MAX_BRIGHTNESS,
+	};
+	struct backlight_device *bl;
+	struct ams644vk04 *ctx;
+	int ret;
+
+	ctx = devm_drm_panel_alloc(dev, struct ams644vk04, panel,
+				   &ams644vk04_panel_funcs,
+				   DRM_MODE_CONNECTOR_DSI);
+	if (IS_ERR(ctx))
+		return PTR_ERR(ctx);
+
+	ret = devm_regulator_bulk_get_const(dev, ARRAY_SIZE(ams644vk04_supplies),
+					    ams644vk04_supplies, &ctx->supplies);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to get regulators\n");
+
+	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
+	if (IS_ERR(ctx->reset_gpio))
+		return dev_err_probe(dev, PTR_ERR(ctx->reset_gpio),
+				     "Failed to get reset-gpios\n");
+
+	ctx->dsi = dsi;
+	mipi_dsi_set_drvdata(dsi, ctx);
+
+	dsi->lanes = 4;
+	dsi->format = MIPI_DSI_FMT_RGB888;
+	dsi->mode_flags = MIPI_DSI_MODE_LPM | MIPI_DSI_CLOCK_NON_CONTINUOUS |
+			  MIPI_DSI_MODE_DSC_ALL_SLICES_IN_PKT;
+
+	/*
+	 * DSC 1.1, 8 bpc, 8 bpp (4 fractional bits), block prediction, two
+	 * 540x48 slices per line, both in the same packet.  The DSI host
+	 * derives the remaining rate control parameters from this.
+	 */
+	ctx->dsc.dsc_version_major = 1;
+	ctx->dsc.dsc_version_minor = 1;
+	ctx->dsc.slice_width = 540;
+	ctx->dsc.slice_height = 48;
+	ctx->dsc.slice_count = AMS644VK04_WIDTH / ctx->dsc.slice_width;
+	ctx->dsc.bits_per_component = 8;
+	ctx->dsc.bits_per_pixel = 8 << 4;
+	ctx->dsc.block_pred_enable = true;
+	dsi->dsc = &ctx->dsc;
+
+	ctx->panel.prepare_prev_first = true;
+
+	bl = devm_backlight_device_register(dev, dev_name(dev), dev, ctx,
+					    &ams644vk04_bl_ops, &props);
+	if (IS_ERR(bl))
+		return dev_err_probe(dev, PTR_ERR(bl), "Failed to register backlight\n");
+	ctx->panel.backlight = bl;
+
+	drm_panel_add(&ctx->panel);
+
+	ret = mipi_dsi_attach(dsi);
+	if (ret < 0) {
+		drm_panel_remove(&ctx->panel);
+		return dev_err_probe(dev, ret, "Failed to attach to DSI host\n");
+	}
+
+	return 0;
+}
+
+static void ams644vk04_remove(struct mipi_dsi_device *dsi)
+{
+	struct ams644vk04 *ctx = mipi_dsi_get_drvdata(dsi);
+	int ret;
+
+	ret = mipi_dsi_detach(dsi);
+	if (ret < 0)
+		dev_err(&dsi->dev, "Failed to detach from DSI host: %d\n", ret);
+
+	drm_panel_remove(&ctx->panel);
+}
+
+static const struct of_device_id ams644vk04_of_match[] = {
+	{ .compatible = "samsung,ams644vk04" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ams644vk04_of_match);
+
+static struct mipi_dsi_driver ams644vk04_driver = {
+	.probe = ams644vk04_probe,
+	.remove = ams644vk04_remove,
+	.driver = {
+		.name = "panel-samsung-ams644vk04",
+		.of_match_table = ams644vk04_of_match,
+	},
+};
+module_mipi_dsi_driver(ams644vk04_driver);
+
+MODULE_DESCRIPTION("Panel driver for the Samsung AMS644VK04 AMOLED DSI panel");
+MODULE_LICENSE("GPL");

-- 
2.56.0

