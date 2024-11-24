From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Sun, 24 Nov 2024 23:29:26 +0100
Subject: [PATCH 3/5] gpu: drm: adp: Add a backlight driver for the Summit
 LCD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241124-adpdrm-v1-3-3191d8e6e49a@gmail.com>
References: <20241124-adpdrm-v1-0-3191d8e6e49a@gmail.com>
In-Reply-To: <20241124-adpdrm-v1-0-3191d8e6e49a@gmail.com>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, asahi@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Nick Chan <towinchenmi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732487379; l=3305;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=sbnezbuFoF7i74RnvJBF1A8kSZMpFbcSuRY+EtYx+3c=;
 b=KmisXylwekMJhnG7GXCtk2uDcahe4QtLnC0hSFYM513rcUB/5aCzcquaCqlsygHwAwnzaTmyY
 f9xDvEydidsBO5WmK4DLmXuK0gRPNzgfqDNWb/xb/M94MTHeYrSgoE8
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the display panel used for the touchbar on laptops that have it.

Co-developed-by: Nick Chan <towinchenmi@gmail.com>
Signed-off-by: Nick Chan <towinchenmi@gmail.com>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/gpu/drm/adp/panel-summit.c | 108 +++++++++++++++++++++++++++++++++++++
 1 file changed, 108 insertions(+)

diff --git a/drivers/gpu/drm/adp/panel-summit.c b/drivers/gpu/drm/adp/panel-summit.c
new file mode 100644
index 0000000000000000000000000000000000000000..2dcbddd925ce3863742aa60164369ba9db0bbfff
--- /dev/null
+++ b/drivers/gpu/drm/adp/panel-summit.c
@@ -0,0 +1,108 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <linux/backlight.h>
+#include <drm/drm_mipi_dsi.h>
+#include <video/mipi_display.h>
+
+struct summit_data {
+	struct mipi_dsi_device *dsi;
+	struct backlight_device *bl;
+};
+
+static int summit_set_brightness(struct device *dev)
+{
+	struct summit_data *panel = dev_get_drvdata(dev);
+	int level = backlight_get_brightness(panel->bl);
+	int err = mipi_dsi_dcs_set_display_brightness(panel->dsi, level);
+
+	if (err < 0)
+		return err;
+	return 0;
+}
+
+static int summit_bl_update_status(struct backlight_device *dev)
+{
+	return summit_set_brightness(&dev->dev);
+}
+
+static int summit_bl_get_brightness(struct backlight_device *dev)
+{
+	return backlight_get_brightness(dev);
+}
+
+static const struct backlight_ops summit_bl_ops = {
+	.get_brightness = summit_bl_get_brightness,
+	.update_status	= summit_bl_update_status,
+};
+
+static int summit_probe(struct mipi_dsi_device *dsi)
+{
+	struct backlight_properties props = { 0 };
+	struct device *dev = &dsi->dev;
+	struct summit_data *panel;
+
+	panel = devm_kzalloc(dev, sizeof(*panel), GFP_KERNEL);
+	if (!panel)
+		return -ENOMEM;
+
+	mipi_dsi_set_drvdata(dsi, panel);
+	panel->dsi = dsi;
+
+	int ret = device_property_read_u32(dev, "max-brightness", &props.max_brightness);
+
+	if (ret)
+		props.max_brightness = 255;
+	props.type = BACKLIGHT_RAW;
+
+	panel->bl = devm_backlight_device_register(dev, dev_name(dev),
+						   dev, panel, &summit_bl_ops, &props);
+	if (IS_ERR(panel->bl))
+		return PTR_ERR(panel->bl);
+
+	return mipi_dsi_attach(dsi);
+}
+
+static void summit_remove(struct mipi_dsi_device *dsi)
+{
+	mipi_dsi_detach(dsi);
+}
+
+static int summit_resume(struct device *dev)
+{
+	return summit_set_brightness(dev);
+}
+
+static int summit_suspend(struct device *dev)
+{
+	struct summit_data *panel = dev_get_drvdata(dev);
+
+	int err = mipi_dsi_dcs_set_display_brightness(panel->dsi, 0);
+
+	if (err < 0)
+		return err;
+	return 0;
+}
+
+static DEFINE_SIMPLE_DEV_PM_OPS(summit_pm_ops, summit_suspend,
+				summit_resume);
+
+static const struct of_device_id summit_of_match[] = {
+	{ .compatible = "apple,summit" },
+	{},
+};
+
+MODULE_DEVICE_TABLE(of, summit_of_match);
+
+static struct mipi_dsi_driver summit_driver = {
+	.probe = summit_probe,
+	.remove = summit_remove,
+	.driver = {
+		.name = "panel-summit",
+		.of_match_table = summit_of_match,
+		.pm = pm_sleep_ptr(&summit_pm_ops),
+	},
+};
+module_mipi_dsi_driver(summit_driver);
+
+MODULE_DESCRIPTION("Summit Display Panel Driver");
+MODULE_LICENSE("GPL");

-- 
2.47.0

