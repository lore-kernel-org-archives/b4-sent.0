From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 14:08:15 +0100
Subject: [PATCH v3 4/5] drm/panel: lg-sw43408: keep VPNL paired with VDDI
 and reset deasserted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-fix-blueline-panel-v3-4-914b4a30b73e@ixit.cz>
References: <20261125-fix-blueline-panel-v3-0-914b4a30b73e@ixit.cz>
In-Reply-To: <20261125-fix-blueline-panel-v3-0-914b4a30b73e@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Airlie <airlied@gmail.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, Jessica Zhang <jesszhan0024@gmail.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maxime Ripard <mripard@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Simona Vetter <simona@ffwll.ch>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Thomas Zimmermann <tzimmermann@suse.de>, Vinod Koul <vkoul@kernel.org>
Cc: devicetree@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=8066; i=david@ixit.cz;
 h=from:subject:message-id; bh=sliVBym4W+p+eKezwMWh4+aHLg0af9CH5oOSuZc9UKg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBt3BRdZXFt13fHS1TxcxEIppnpPbnn1jWBWC6
 Phcx/3vFW+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawbdwQAKCRBgAj/E00kg
 cjWjD/0QzW4NVdUcwDOxfSmNIJrdH2xBMVnAt+FLwlGVtgbXKzXmEahtrsfvMzAkIw3PepZZWs5
 n0x2UEjSue3tDPUw4u2YthasaMnc+tbnlfWPBbSDEvx+W+c0tLXG1uZEZJNjf1RW8ugK07p1FJ0
 zieTgm4BbaEZ3UbVid/UeMWj2ILgC3Lk7gvJj++Lftk+m/q5zqS72KtaOuwldb8p+nrVPAA1QfJ
 pSK5hp19ILqtK5a+ysH9ai9F8qXJ9P442sxbRKwhPLCExWqW0aU2T22wHDwl77ukG4hNqkmAKDc
 WXTvbxMf2RxAZUH92IGj5S6/PVYrkBiBMUOoZWVzWPyCvjbSpUFzbHi3NOtMMO5991959PXYzL/
 Ayx9JHBKsPrBBTUIYPDzbHUHGdBcskSEc6EWIXvXcdt5uOnq+WbQBjeyridHfe9HrNxLsCM8hwc
 RG41IDamC86Ywo0rjDDMfitXg06Z1UJCo/tPxwpj2JdGX2FLx9FOXifU7Uxe/HDlUUn3Pqr/p2Z
 LSp5NG+e2M9prwZVrvh4n2tmnZn9LtfjwBhkmc8ggRVDNTjOHwqXxLqRktfmemMhjJ1CqJd7mpW
 BSFss6Nop8Ngcmpe6nZg05JPQcqkJXUYEvdW4C/q9R+dugytL8j2mWjsznbQTML6kRzH+RO64ta
 d+m/k+ggLnlP6/w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Google Pixel 3, VDDI (1.8 V) is shared with the STM FTS5 touchscreen
and remains powered while the system is awake or when double-tap wakeup
is armed, whereas VPNL (3.0 V) is exclusive to the panel.

Hardware testing on Pixel 3 shows the SW43408 DDIC only recovers cleanly
across unprepare/prepare when VDDI and VPNL stay paired and reset is not
held asserted while VDDI is powered:
- VDDI ON, VPNL ON, reset HIGH (Sleep-In): recovers cleanly.
- VDDI OFF, VPNL OFF, reset HIGH (cold POR): recovers cleanly.
- VDDI ON, VPNL OFF (with reset either HIGH or LOW): panel stays black
  on the next prepare even though DCS commands, TE, and LAB/IBB report
  normal status, until a full VDDI power cycle occurs.
- VDDI ON, VPNL ON, reset LOW: panel stays black on the next prepare.

Stop asserting reset_gpio in sw43408_unprepare() and sw43408_prepare()'s
poweroff error path, and disable VDDI first in sw43408_power_off(). Only
disable VPNL once VDDI actually powered down, checking both immediately
in sw43408_power_off() and from a late system sleep callback in case
a shared consumer drops VDDI later during system suspend.

Track whether the driver still holds VPNL enabled so sw43408_prepare()
balances the enable count without glitching VPNL, and register a devm
cleanup action to release VPNL if the driver is removed while
unprepared.

Fixes: 069a6c0e94f9 ("drm: panel: Add LG sw43408 panel driver")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 119 +++++++++++++++++++++++++++----
 1 file changed, 107 insertions(+), 12 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index 7123ad18744cf..6854292bd99ca 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -15,28 +15,38 @@
 #include <video/mipi_display.h>
 
 #include <drm/drm_mipi_dsi.h>
 #include <drm/drm_panel.h>
 #include <drm/drm_probe_helper.h>
 #include <drm/display/drm_dsc.h>
 #include <drm/display/drm_dsc_helper.h>
 
+enum {
+	SW43408_SUPPLY_VDDI,
+	SW43408_SUPPLY_VPNL,
+};
+
 static const struct regulator_bulk_data sw43408_supplies[] = {
-	{ .supply = "vddi", /* 1.8 V */
-	  .init_load_uA = 62000 },
-	{ .supply = "vpnl", /* 3.0 V */
-	  .init_load_uA = 857000 },
+	[SW43408_SUPPLY_VDDI] = {
+		.supply = "vddi", /* 1.8 V */
+		.init_load_uA = 62000,
+	},
+	[SW43408_SUPPLY_VPNL] = {
+		.supply = "vpnl", /* 3.0 V */
+		.init_load_uA = 857000,
+	},
 };
 
 struct sw43408_panel {
 	struct drm_panel base;
 	struct mipi_dsi_device *link;
 
 	struct regulator_bulk_data *supplies;
+	bool vpnl_enabled;
 
 	struct gpio_desc *reset_gpio;
 
 	struct drm_dsc_config dsc;
 };
 
 static inline struct sw43408_panel *to_panel_info(struct drm_panel *panel)
 {
@@ -52,24 +62,90 @@ static int sw43408_disable(struct drm_panel *panel)
 
 	mipi_dsi_dcs_enter_sleep_mode_multi(&ctx);
 
 	mipi_dsi_msleep(&ctx, 100);
 
 	return ctx.accum_err;
 }
 
-static int sw43408_unprepare(struct drm_panel *panel)
+static int sw43408_maybe_disable_vpnl(struct sw43408_panel *ctx)
 {
-	struct sw43408_panel *sw43408 = to_panel_info(panel);
+	struct regulator *vddi = ctx->supplies[SW43408_SUPPLY_VDDI].consumer;
+	struct regulator *vpnl = ctx->supplies[SW43408_SUPPLY_VPNL].consumer;
+
+	/*
+	 * On Pixel 3, vddi is shared with the touchscreen and remains
+	 * powered while awake or when touch wakeup is armed. Dropping vpnl
+	 * (3.0 V) or asserting reset while vddi (1.8 V) stays powered leaves
+	 * the DDIC in a state no init sequence recovers from (until a full
+	 * vddi power cycle): it answers DCS commands and reports display-on,
+	 * but never lights up again.
+	 */
+	if (ctx->vpnl_enabled && regulator_is_enabled(vddi) == 0) {
+		int ret = regulator_disable(vpnl);
 
-	gpiod_set_value(sw43408->reset_gpio, 1);
+		if (ret < 0)
+			return ret;
+
+		ctx->vpnl_enabled = false;
+	}
 
-	return regulator_bulk_disable(ARRAY_SIZE(sw43408_supplies),
-				      sw43408->supplies);
+	return 0;
+}
+
+static int sw43408_power_off(struct sw43408_panel *ctx)
+{
+	struct regulator *vddi = ctx->supplies[SW43408_SUPPLY_VDDI].consumer;
+	int ret;
+
+	ret = regulator_disable(vddi);
+	if (ret)
+		return ret;
+
+	ret = sw43408_maybe_disable_vpnl(ctx);
+	if (ret)
+		goto recover_vddi;
+
+	return 0;
+
+recover_vddi:
+	/* vpnl disable failed, thus we need to re-enable vddi */
+	(void)regulator_enable(vddi);
+	return ret;
+}
+
+static int sw43408_suspend_late(struct device *dev)
+{
+	struct sw43408_panel *ctx = dev_get_drvdata(dev);
+	int ret;
+
+	if (ctx->base.prepared)
+		return 0;
+
+	ret = sw43408_maybe_disable_vpnl(ctx);
+	if (ret)
+		return ret;
+
+	return 0;
+}
+
+static void sw43408_cleanup_vpnl(void *data)
+{
+	struct sw43408_panel *ctx = data;
+
+	if (ctx->vpnl_enabled) {
+		regulator_disable(ctx->supplies[SW43408_SUPPLY_VPNL].consumer);
+		ctx->vpnl_enabled = false;
+	}
+}
+
+static int sw43408_unprepare(struct drm_panel *panel)
+{
+	return sw43408_power_off(to_panel_info(panel));
 }
 
 static int sw43408_program(struct drm_panel *panel)
 {
 	struct sw43408_panel *sw43408 = to_panel_info(panel);
 	struct mipi_dsi_multi_context ctx = { .dsi = sw43408->link };
 	struct drm_dsc_picture_parameter_set pps;
 
@@ -144,35 +220,45 @@ static void sw43408_reset(struct sw43408_panel *ctx)
 	usleep_range(1000, 2000);
 	gpiod_set_value(ctx->reset_gpio, 0);
 	usleep_range(9000, 10000);
 }
 
 static int sw43408_prepare(struct drm_panel *panel)
 {
 	struct sw43408_panel *ctx = to_panel_info(panel);
+	struct regulator *vddi = ctx->supplies[SW43408_SUPPLY_VDDI].consumer;
+	struct regulator *vpnl = ctx->supplies[SW43408_SUPPLY_VPNL].consumer;
 	int ret;
 
-	ret = regulator_bulk_enable(ARRAY_SIZE(sw43408_supplies), ctx->supplies);
+	ret = regulator_enable(vddi);
 	if (ret < 0)
 		return ret;
 
+	if (!ctx->vpnl_enabled) {
+		ret = regulator_enable(vpnl);
+		if (ret < 0) {
+			regulator_disable(vddi);
+			return ret;
+		}
+		ctx->vpnl_enabled = true;
+	}
+
 	usleep_range(5000, 6000);
 
 	sw43408_reset(ctx);
 
 	ret = sw43408_program(panel);
 	if (ret)
 		goto poweroff;
 
 	return 0;
 
 poweroff:
-	gpiod_set_value(ctx->reset_gpio, 1);
-	regulator_bulk_disable(ARRAY_SIZE(sw43408_supplies), ctx->supplies);
+	sw43408_power_off(ctx);
 	return ret;
 }
 
 static const struct drm_display_mode lh546wf1_ed01_mode = {
 	.clock = (1080 + 20 + 32 + 20) * (2160 + 20 + 4 + 20) * 60 / 1000,
 
 	.hdisplay = 1080,
 	.hsync_start = 1080 + 20,
@@ -255,16 +341,20 @@ static int sw43408_add(struct sw43408_panel *ctx)
 
 	ret = devm_regulator_bulk_get_const(dev,
 					    ARRAY_SIZE(sw43408_supplies),
 					    sw43408_supplies,
 					    &ctx->supplies);
 	if (ret < 0)
 		return ret;
 
+	ret = devm_add_action_or_reset(dev, sw43408_cleanup_vpnl, ctx);
+	if (ret < 0)
+		return ret;
+
 	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
 	if (IS_ERR(ctx->reset_gpio)) {
 		return dev_err_probe(dev, PTR_ERR(ctx->reset_gpio),
 				     "Failed to get reset-gpios\n");
 	}
 
 	ret = sw43408_backlight_init(ctx);
 	if (ret < 0)
@@ -313,20 +403,25 @@ static int sw43408_probe(struct mipi_dsi_device *dsi)
 	ctx->dsc.bits_per_pixel = 8 << 4;
 	ctx->dsc.block_pred_enable = true;
 
 	dsi->dsc = &ctx->dsc;
 
 	return devm_mipi_dsi_attach(&dsi->dev, dsi);
 }
 
+static const struct dev_pm_ops sw43408_pm_ops = {
+	LATE_SYSTEM_SLEEP_PM_OPS(sw43408_suspend_late, NULL)
+};
+
 static struct mipi_dsi_driver sw43408_driver = {
 	.driver = {
 		.name = "panel-lg-sw43408",
 		.of_match_table = sw43408_of_match,
+		.pm = pm_sleep_ptr(&sw43408_pm_ops),
 	},
 	.probe = sw43408_probe,
 };
 module_mipi_dsi_driver(sw43408_driver);
 
 MODULE_AUTHOR("Sumit Semwal <sumit.semwal@linaro.org>");
 MODULE_DESCRIPTION("LG SW436408 MIPI-DSI LED panel");
 MODULE_LICENSE("GPL");

-- 
2.55.0

