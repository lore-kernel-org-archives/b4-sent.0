From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 14 Aug 2026 13:17:16 -0500
Subject: [PATCH 2/4] drm/panel: visionox-vtdr6130: Add panel orientation
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-rp6-panel-v1-2-111c1aeccf0f@gmail.com>
References: <20260814-rp6-panel-v1-0-111c1aeccf0f@gmail.com>
In-Reply-To: <20260814-rp6-panel-v1-0-111c1aeccf0f@gmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786731444; l=2151;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=4JX6sGMnacRMev7Y2NB1fqlDR3ay0oZY4tGf8LDcUXo=;
 b=6/+fhseOqGwuzVTrK8mjJIk6IAvTfvSSDevDcYlE1IDi9uaZS7uCpilQC+CPlK7cCfl6sbb+N
 N4OQ1jIWz4eAZiG+Tbtne8i+mM4rorRL50C7rVSj4vfqtJFVmrukTq0
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fetch orientation from the device tree if provided.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpu/drm/panel/panel-visionox-vtdr6130.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c b/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
index 6733e0e1d0612..b66d6c7128c75 100644
--- a/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
+++ b/drivers/gpu/drm/panel/panel-visionox-vtdr6130.c
@@ -11,6 +11,7 @@
 #include <drm/display/drm_dsc.h>
 #include <drm/display/drm_dsc_helper.h>
 #include <drm/drm_mipi_dsi.h>
+#include <drm/drm_of.h>
 #include <drm/drm_modes.h>
 #include <drm/drm_panel.h>
 
@@ -22,6 +23,7 @@ struct visionox_vtdr6130 {
 	struct mipi_dsi_device *dsi;
 	struct gpio_desc *reset_gpio;
 	struct regulator_bulk_data *supplies;
+	enum drm_panel_orientation orientation;
 };
 
 static const struct regulator_bulk_data visionox_vtdr6130_supplies[] = {
@@ -218,10 +220,18 @@ static int visionox_vtdr6130_get_modes(struct drm_panel *panel,
 	return 1;
 }
 
+static enum drm_panel_orientation visionox_vtdr6130_get_orientation(struct drm_panel *panel)
+{
+	struct visionox_vtdr6130 *ctx = to_visionox_vtdr6130(panel);
+
+	return ctx->orientation;
+}
+
 static const struct drm_panel_funcs visionox_vtdr6130_panel_funcs = {
 	.prepare = visionox_vtdr6130_prepare,
 	.unprepare = visionox_vtdr6130_unprepare,
 	.get_modes = visionox_vtdr6130_get_modes,
+	.get_orientation = visionox_vtdr6130_get_orientation,
 };
 
 static int visionox_vtdr6130_bl_update_status(struct backlight_device *bl)
@@ -293,6 +303,12 @@ static int visionox_vtdr6130_probe(struct mipi_dsi_device *dsi)
 			  MIPI_DSI_CLOCK_NON_CONTINUOUS;
 	ctx->panel.prepare_prev_first = true;
 
+	ret = drm_of_get_panel_orientation(dev->of_node, &ctx->orientation);
+	if (ret < 0) {
+		dev_err(dev, "Failed to get orientation %d\n", ret);
+		return ret;
+	}
+
 	ctx->panel.backlight = visionox_vtdr6130_create_backlight(dsi);
 	if (IS_ERR(ctx->panel.backlight))
 		return dev_err_probe(dev, PTR_ERR(ctx->panel.backlight),

-- 
2.54.0

