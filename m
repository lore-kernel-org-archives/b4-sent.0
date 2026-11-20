From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Fri, 20 Nov 2026 21:23:13 +0530
Subject: [PATCH v3 2/2] drm/panel: Add Ilitek ILI97680A DSC command mode
 panel driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-vantage-panel-v3-2-00b306146240@yahoo.com>
References: <20261120-vantage-panel-v3-0-00b306146240@yahoo.com>
In-Reply-To: <20261120-vantage-panel-v3-0-00b306146240@yahoo.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795189991; l=24567;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=+IiSTMEQw7JyywmTawVmO55WG2gIOy3ut7tXRs0Fmp0=;
 b=dtB30s0EJfaboF7Ie817o9+I2/8iJ2ttzx4JxTa+gFnNHOZzxzsiL5dYgU7z7NSJhrNx24UDo
 IkDY+5JtmpCAtFr8henTHzjVmR7+tBJEF+h7cN2lCYimR6r++STOA5M
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the 1264x2780 BOE AMOLED panel driven by an Ilitek
ILI97680A, found in the Motorola Signature. The panel runs in DSI
command mode on four lanes with DSC 1.2 at 10 bits per component and
8 bits per pixel, two 632x20 slices per line.

The picture parameter set is not taken from the standard DSC PPS packet
but written to a vendor register on command page 7. Brightness is
controlled through DCS with a range of 0 to 16180.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 drivers/gpu/drm/panel/Kconfig                  |  16 +
 drivers/gpu/drm/panel/Makefile                 |   1 +
 drivers/gpu/drm/panel/panel-ilitek-ili97680a.c | 495 +++++++++++++++++++++++++
 3 files changed, 512 insertions(+)

diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index 26ffa2378f55..070f152f01e2 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -353,6 +353,22 @@ config DRM_PANEL_ILITEK_ILI9488
 	  Say Y if you want to enable support for panels based on the
 	  Ilitek ILI9488 controller.
 
+config DRM_PANEL_ILITEK_ILI97680A
+	tristate "Ilitek ILI97680A-based DSC command mode panels"
+	depends on OF
+	depends on DRM_MIPI_DSI
+	depends on BACKLIGHT_CLASS_DEVICE
+	select DRM_DISPLAY_DSC_HELPER
+	select DRM_DISPLAY_HELPER
+	help
+	  Say Y here if you want to enable support for Ilitek ILI97680A-based
+	  DSI command mode panels with DSC, such as the 1264x2780 BOE panel in
+	  the Motorola Signature. The panel is driven in command mode with
+	  Display Stream Compression and its brightness is controlled over DCS.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called panel-ilitek-ili97680a.
+
 config DRM_PANEL_ILITEK_ILI9805
 	tristate "Ilitek ILI9805-based panels"
 	depends on OF
diff --git a/drivers/gpu/drm/panel/Makefile b/drivers/gpu/drm/panel/Makefile
index 365f2e73f6b4..3ac5685662e3 100644
--- a/drivers/gpu/drm/panel/Makefile
+++ b/drivers/gpu/drm/panel/Makefile
@@ -34,6 +34,7 @@ obj-$(CONFIG_DRM_PANEL_ILITEK_ILI7836A) += panel-ilitek-ili7836a.o
 obj-$(CONFIG_DRM_PANEL_ILITEK_IL9322) += panel-ilitek-ili9322.o
 obj-$(CONFIG_DRM_PANEL_ILITEK_ILI9341) += panel-ilitek-ili9341.o
 obj-$(CONFIG_DRM_PANEL_ILITEK_ILI9488) += panel-ilitek-ili9488.o
+obj-$(CONFIG_DRM_PANEL_ILITEK_ILI97680A) += panel-ilitek-ili97680a.o
 obj-$(CONFIG_DRM_PANEL_ILITEK_ILI9805) += panel-ilitek-ili9805.o
 obj-$(CONFIG_DRM_PANEL_ILITEK_ILI9806E_CORE) += panel-ilitek-ili9806e-core.o
 obj-$(CONFIG_DRM_PANEL_ILITEK_ILI9806E_DSI) += panel-ilitek-ili9806e-dsi.o
diff --git a/drivers/gpu/drm/panel/panel-ilitek-ili97680a.c b/drivers/gpu/drm/panel/panel-ilitek-ili97680a.c
new file mode 100644
index 000000000000..ce2cf24bcf09
--- /dev/null
+++ b/drivers/gpu/drm/panel/panel-ilitek-ili97680a.c
@@ -0,0 +1,495 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Ilitek ILI97680A based DSI command mode panel with DSC, as found in the
+ * Motorola Signature (BOE 1264x2780).
+ *
+ * Copyright (c) 2026 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+ */
+
+#include <linux/backlight.h>
+#include <linux/delay.h>
+#include <linux/gpio/consumer.h>
+#include <linux/module.h>
+#include <linux/regulator/consumer.h>
+
+#include <drm/display/drm_dsc.h>
+#include <drm/display/drm_dsc_helper.h>
+#include <drm/drm_mipi_dsi.h>
+#include <drm/drm_modes.h>
+#include <drm/drm_panel.h>
+#include <drm/drm_probe_helper.h>
+
+#define ILI97680A_SWITCH_PAGE		0xff
+#define ILI97680A_PPS			0x81
+/*
+ * The panel takes the PPS through a vendor register, as five zero bytes
+ * followed by the first 94 bytes of the PPS.
+ */
+#define ILI97680A_PPS_LEN		94
+
+struct ili97680a {
+	struct drm_panel panel;
+	struct mipi_dsi_device *dsi;
+	struct drm_dsc_config dsc;
+	struct gpio_desc *reset_gpio;
+	struct regulator_bulk_data *supplies;
+};
+
+/* In power-on order */
+static const struct regulator_bulk_data ili97680a_supplies[] = {
+	{ .supply = "vddio", .init_load_uA = 300000 },
+	{ .supply = "vdd", .init_load_uA = 300000 },
+	{ .supply = "vci", .init_load_uA = 100000 },
+};
+
+static inline struct ili97680a *to_ili97680a(struct drm_panel *panel)
+{
+	return container_of(panel, struct ili97680a, panel);
+}
+
+#define ili97680a_switch_page(dsi_ctx, page) \
+	mipi_dsi_dcs_write_seq_multi((dsi_ctx), ILI97680A_SWITCH_PAGE, \
+				     0x5a, 0xa5, (page))
+
+static void ili97680a_reset(struct ili97680a *ctx)
+{
+	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+	usleep_range(3000, 4000);
+	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
+	usleep_range(1000, 2000);
+	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+	usleep_range(1000, 2000);
+	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
+	msleep(20);
+}
+
+static void ili97680a_send_pps(struct mipi_dsi_multi_context *dsi_ctx,
+			       const struct drm_dsc_config *dsc)
+{
+	struct drm_dsc_picture_parameter_set pps;
+	u8 buf[1 + 5 + ILI97680A_PPS_LEN] = { ILI97680A_PPS };
+
+	drm_dsc_pps_payload_pack(&pps, dsc);
+	memcpy(&buf[6], &pps, ILI97680A_PPS_LEN);
+	mipi_dsi_dcs_write_buffer_multi(dsi_ctx, buf, sizeof(buf));
+}
+
+static void ili97680a_on(struct ili97680a *ctx,
+			 struct mipi_dsi_multi_context *dsi_ctx)
+{
+	dsi_ctx->dsi->mode_flags |= MIPI_DSI_MODE_LPM;
+
+	ili97680a_switch_page(dsi_ctx, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x4d, 0x01);
+	ili97680a_switch_page(dsi_ctx, 0x4f);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa1, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa2, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa3, 0xa4);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa4, 0x0a);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa5, 0x48);
+	ili97680a_switch_page(dsi_ctx, 0x71);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x85, 0x00, 0x80, 0x0a, 0xf3, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x86, 0x00, 0x66, 0x09, 0x8f, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x87, 0x00, 0x60, 0x09, 0x36, 0x14, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x88, 0x00, 0x53, 0x08, 0x84, 0x24, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x89, 0x00, 0x46, 0x07, 0xd2, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8a, 0x00, 0x80, 0x18, 0xb3, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8b, 0x00, 0x66, 0x17, 0xc2, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8c, 0x00, 0x60, 0x17, 0x86, 0x14, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8d, 0x00, 0x53, 0x17, 0x0e, 0x24, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8e, 0x00, 0x46, 0x16, 0x95, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8f, 0x00, 0x80, 0x26, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x90, 0x00, 0x66, 0x25, 0x99, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x91, 0x00, 0x60, 0x25, 0x80, 0x14, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x92, 0x00, 0x53, 0x25, 0x4c, 0x24, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x93, 0x00, 0x46, 0x25, 0x19, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x94, 0x00, 0x80, 0x04, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x95, 0x00, 0x66, 0x04, 0x00, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x96, 0x00, 0x60, 0x04, 0x00, 0x14, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x97, 0x00, 0x53, 0x04, 0x00, 0x24, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x98, 0x00, 0x46, 0x04, 0x00, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x99, 0x0c, 0x19, 0x00, 0x80, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9a, 0x0a, 0x7b, 0x00, 0x66, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9b, 0x0a, 0x13, 0x00, 0x60, 0x14, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9c, 0x09, 0x43, 0x00, 0x53, 0x24, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9d, 0x08, 0x74, 0x00, 0x46, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9e, 0x04, 0x00, 0x0a, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa3, 0x04, 0x00, 0x16, 0x80, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa4, 0x04, 0x00, 0x16, 0x00, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb2, 0x19, 0xec, 0x00, 0x80, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb3, 0x18, 0xbd, 0x00, 0x66, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb4, 0x18, 0x71, 0x00, 0x60, 0x14, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb5, 0x17, 0xda, 0x00, 0x53, 0x24, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xb6, 0x17, 0x42, 0x00, 0x46, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcb, 0x25, 0xb9, 0x00, 0x80, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcc, 0x25, 0x61, 0x00, 0x66, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcd, 0x25, 0x4b, 0x00, 0x60, 0x14, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xce, 0x25, 0x1f, 0x00, 0x53, 0x24, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcf, 0x24, 0xf2, 0x00, 0x46, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe4, 0x04, 0x00, 0x00, 0x80, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe5, 0x04, 0x00, 0x00, 0x66, 0x04, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe6, 0x04, 0x00, 0x00, 0x60, 0x14, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe7, 0x04, 0x00, 0x00, 0x53, 0x24, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe8, 0x04, 0x00, 0x00, 0x46, 0x04, 0x00);
+	ili97680a_switch_page(dsi_ctx, 0x49);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe0, 0x01);
+	ili97680a_switch_page(dsi_ctx, 0x5b);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xc8, 0x03, 0x06, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xc9, 0x04, 0x07, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xca, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcb, 0x06, 0x07, 0x03);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcc, 0x01, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcd, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xce, 0x09, 0x09, 0x07);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcf, 0x03, 0x02, 0x02);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd0, 0x02, 0x01, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd1, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd2, 0x16, 0x12, 0x13);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd3, 0x09, 0x07, 0x07);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd4, 0x07, 0x06, 0x06);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd5, 0x03, 0x03, 0x02);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd6, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd7, 0x19, 0x15, 0x16);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd8, 0x0b, 0x08, 0x08);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd9, 0x09, 0x07, 0x07);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xda, 0x04, 0x04, 0x03);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xdb, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xdc, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xdd, 0x24, 0x21, 0x1f);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xde, 0x13, 0x10, 0x0d);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xdf, 0x10, 0x0e, 0x0c);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe0, 0x09, 0x09, 0x06);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe1, 0x01, 0x02, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe2, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe3, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe4, 0x2e, 0x2b, 0x26);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe5, 0x1b, 0x17, 0x12);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe6, 0x18, 0x15, 0x10);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe7, 0x0e, 0x0f, 0x09);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe8, 0x04, 0x04, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe9, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xea, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xeb, 0x00, 0x00, 0x00);
+	ili97680a_switch_page(dsi_ctx, 0x5c);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x80, 0x02, 0x02, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x81, 0x02, 0x02, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x82, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x83, 0x04, 0x04, 0x02);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x84, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x85, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x86, 0x08, 0x07, 0x07);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x87, 0x02, 0x02, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x88, 0x01, 0x01, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x89, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8a, 0x13, 0x11, 0x10);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8b, 0x07, 0x07, 0x05);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8c, 0x06, 0x06, 0x04);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8d, 0x01, 0x02, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8e, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8f, 0x16, 0x14, 0x12);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x90, 0x09, 0x08, 0x06);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x91, 0x07, 0x07, 0x04);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x92, 0x02, 0x02, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x93, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x94, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x95, 0x30, 0x2c, 0x18);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x96, 0x0e, 0x0d, 0x08);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x97, 0x0b, 0x0b, 0x06);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x98, 0x05, 0x05, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x99, 0x01, 0x01, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9a, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9b, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9c, 0x45, 0x33, 0x1d);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9d, 0x12, 0x11, 0x09);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9e, 0x0f, 0x0f, 0x07);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x9f, 0x07, 0x08, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa0, 0x01, 0x01, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa1, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa2, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa3, 0x00, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xce, 0x10, 0x18, 0x10);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcf, 0x10, 0x18, 0x10);
+	ili97680a_switch_page(dsi_ctx, 0x06);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xc6, 0x01);
+	ili97680a_switch_page(dsi_ctx, 0x08);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd2, 0x05);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xed, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x45, 0xff);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xee, 0xff, 0xfd, 0xff, 0xfd, 0xf9, 0xfa, 0xbe, 0x76);
+	ili97680a_switch_page(dsi_ctx, 0x00);
+	ili97680a_switch_page(dsi_ctx, 0x03);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x90, 0x01, 0x80, 0x23);
+	ili97680a_switch_page(dsi_ctx, 0x08);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe0, 0x22);
+	ili97680a_switch_page(dsi_ctx, 0x09);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa1, 0x03);
+	ili97680a_switch_page(dsi_ctx, 0x1e);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xc1, 0x70);
+	ili97680a_switch_page(dsi_ctx, 0x05);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x83, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x84, 0x01);
+	ili97680a_switch_page(dsi_ctx, 0x1c);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe1,
+				     0x10, 0x80, 0x9a, 0x65, 0x59, 0x54, 0x69, 0x95,
+				     0x56, 0x6a, 0x55, 0x99, 0x9a, 0x55, 0x55, 0x25,
+				     0x58, 0x55, 0x66, 0xa2);
+	ili97680a_switch_page(dsi_ctx, 0x20);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd5, 0x10);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xbc, 0x06);
+	ili97680a_switch_page(dsi_ctx, 0x02);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xab, 0xaf, 0x86);
+	ili97680a_switch_page(dsi_ctx, 0x4b);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xee, 0x10);
+	ili97680a_switch_page(dsi_ctx, 0x03);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xbd, 0xd1);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xbb, 0x29);
+	ili97680a_switch_page(dsi_ctx, 0x1c);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xd3, 0x43);
+	ili97680a_switch_page(dsi_ctx, 0x08);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xc8, 0x62);
+	ili97680a_switch_page(dsi_ctx, 0x21);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa4, 0x38);
+	ili97680a_switch_page(dsi_ctx, 0x23);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x85, 0x15);
+	ili97680a_switch_page(dsi_ctx, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xfb, 0x08);
+	ili97680a_switch_page(dsi_ctx, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x5e, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x60, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x61, 0x08);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x35);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x53, 0x20);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x51, 0x00, 0x00);
+	ili97680a_switch_page(dsi_ctx, 0x24);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x85, 0x31);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x89, 0x31);
+	ili97680a_switch_page(dsi_ctx, 0x2d);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xce, 0x55);
+	ili97680a_switch_page(dsi_ctx, 0x24);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x86, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8a, 0x00);
+	ili97680a_switch_page(dsi_ctx, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x53, 0x20);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x60, 0x00);
+	ili97680a_switch_page(dsi_ctx, 0x2d);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x98, 0x01, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xcd, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x83, 0x01, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xf2, 0x01);
+	ili97680a_switch_page(dsi_ctx, 0x07);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8a, 0x01);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x8b, 0x21, 0xe0);
+	ili97680a_send_pps(dsi_ctx, &ctx->dsc);
+	ili97680a_switch_page(dsi_ctx, 0x00);
+	mipi_dsi_dcs_exit_sleep_mode_multi(dsi_ctx);
+	mipi_dsi_msleep(dsi_ctx, 120);
+	ili97680a_switch_page(dsi_ctx, 0x53);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x86, 0x3d);
+	ili97680a_switch_page(dsi_ctx, 0x51);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa1, 0xac, 0xac, 0xac, 0xac, 0x22, 0x22);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa2, 0xac, 0xa5, 0xa5, 0xa5, 0x22, 0x22);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xa3, 0xa5, 0x98, 0x98, 0x98, 0x22, 0x22);
+	ili97680a_switch_page(dsi_ctx, 0x52);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x81, 0xe2, 0x94, 0x77, 0x77, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x82, 0x77, 0x76, 0x76, 0x76, 0x00, 0x00);
+	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x83, 0x76, 0x6e, 0x6e, 0x6e, 0x00, 0x00);
+	ili97680a_switch_page(dsi_ctx, 0x00);
+	mipi_dsi_dcs_set_display_on_multi(dsi_ctx);
+	mipi_dsi_msleep(dsi_ctx, 20);
+}
+
+static int ili97680a_off(struct ili97680a *ctx)
+{
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
+
+	ctx->dsi->mode_flags |= MIPI_DSI_MODE_LPM;
+
+	ili97680a_switch_page(&dsi_ctx, 0x00);
+	mipi_dsi_dcs_set_display_off_multi(&dsi_ctx);
+	mipi_dsi_msleep(&dsi_ctx, 20);
+	mipi_dsi_dcs_enter_sleep_mode_multi(&dsi_ctx);
+	mipi_dsi_msleep(&dsi_ctx, 190);
+
+	return dsi_ctx.accum_err;
+}
+
+static int ili97680a_prepare(struct drm_panel *panel)
+{
+	struct ili97680a *ctx = to_ili97680a(panel);
+	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
+	int ret;
+
+	ret = regulator_bulk_enable(ARRAY_SIZE(ili97680a_supplies), ctx->supplies);
+	if (ret < 0)
+		return ret;
+
+	ili97680a_reset(ctx);
+	ili97680a_on(ctx, &dsi_ctx);
+	if (dsi_ctx.accum_err) {
+		gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+		regulator_bulk_disable(ARRAY_SIZE(ili97680a_supplies), ctx->supplies);
+		return dsi_ctx.accum_err;
+	}
+
+	return 0;
+}
+
+static int ili97680a_unprepare(struct drm_panel *panel)
+{
+	struct ili97680a *ctx = to_ili97680a(panel);
+	int ret;
+
+	ret = ili97680a_off(ctx);
+	if (ret < 0)
+		dev_err(&ctx->dsi->dev, "Failed to un-initialize panel: %d\n", ret);
+
+	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+	regulator_bulk_disable(ARRAY_SIZE(ili97680a_supplies), ctx->supplies);
+
+	return 0;
+}
+
+static const struct drm_display_mode ili97680a_mode = {
+	.clock = (1264 + 31 + 16 + 32) * (2780 + 58 + 2 + 42) * 60 / 1000,
+	.hdisplay = 1264,
+	.hsync_start = 1264 + 31,
+	.hsync_end = 1264 + 31 + 16,
+	.htotal = 1264 + 31 + 16 + 32,
+	.vdisplay = 2780,
+	.vsync_start = 2780 + 58,
+	.vsync_end = 2780 + 58 + 2,
+	.vtotal = 2780 + 58 + 2 + 42,
+	.width_mm = 72,
+	.height_mm = 157,
+	.type = DRM_MODE_TYPE_DRIVER,
+};
+
+static int ili97680a_get_modes(struct drm_panel *panel,
+			       struct drm_connector *connector)
+{
+	return drm_connector_helper_get_modes_fixed(connector, &ili97680a_mode);
+}
+
+static const struct drm_panel_funcs ili97680a_panel_funcs = {
+	.prepare = ili97680a_prepare,
+	.unprepare = ili97680a_unprepare,
+	.get_modes = ili97680a_get_modes,
+};
+
+static int ili97680a_bl_update_status(struct backlight_device *bl)
+{
+	struct mipi_dsi_device *dsi = bl_get_data(bl);
+	u16 brightness = backlight_get_brightness(bl);
+	int ret;
+
+	dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
+
+	ret = mipi_dsi_dcs_set_display_brightness_large(dsi, brightness);
+
+	dsi->mode_flags |= MIPI_DSI_MODE_LPM;
+
+	return ret;
+}
+
+static const struct backlight_ops ili97680a_bl_ops = {
+	.update_status = ili97680a_bl_update_status,
+};
+
+static struct backlight_device *ili97680a_create_backlight(struct mipi_dsi_device *dsi)
+{
+	struct device *dev = &dsi->dev;
+	const struct backlight_properties props = {
+		.type = BACKLIGHT_RAW,
+		.brightness = 7001,
+		.max_brightness = 16180,
+	};
+
+	return devm_backlight_device_register(dev, dev_name(dev), dev, dsi,
+					      &ili97680a_bl_ops, &props);
+}
+
+static int ili97680a_probe(struct mipi_dsi_device *dsi)
+{
+	struct device *dev = &dsi->dev;
+	struct ili97680a *ctx;
+	int ret;
+
+	ctx = devm_drm_panel_alloc(dev, struct ili97680a, panel,
+				   &ili97680a_panel_funcs, DRM_MODE_CONNECTOR_DSI);
+	if (IS_ERR(ctx))
+		return PTR_ERR(ctx);
+
+	ret = devm_regulator_bulk_get_const(dev, ARRAY_SIZE(ili97680a_supplies),
+					    ili97680a_supplies, &ctx->supplies);
+	if (ret < 0)
+		return ret;
+
+	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
+	if (IS_ERR(ctx->reset_gpio))
+		return dev_err_probe(dev, PTR_ERR(ctx->reset_gpio),
+				     "Failed to get reset-gpios\n");
+
+	ctx->dsi = dsi;
+	mipi_dsi_set_drvdata(dsi, ctx);
+
+	dsi->lanes = 4;
+	dsi->format = MIPI_DSI_FMT_RGB101010;
+	dsi->mode_flags = MIPI_DSI_CLOCK_NON_CONTINUOUS;
+
+	ctx->panel.prepare_prev_first = true;
+	ctx->panel.backlight = ili97680a_create_backlight(dsi);
+	if (IS_ERR(ctx->panel.backlight))
+		return dev_err_probe(dev, PTR_ERR(ctx->panel.backlight),
+				     "Failed to create backlight\n");
+
+	/* This panel only works with DSC */
+	dsi->dsc = &ctx->dsc;
+	ctx->dsc.dsc_version_major = 1;
+	ctx->dsc.dsc_version_minor = 2;
+	ctx->dsc.slice_height = 20;
+	ctx->dsc.slice_width = 632;
+	ctx->dsc.slice_count = 1264 / ctx->dsc.slice_width;
+	ctx->dsc.bits_per_component = 10;
+	ctx->dsc.bits_per_pixel = 8 << 4; /* 4 fractional bits */
+	ctx->dsc.block_pred_enable = true;
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
+static void ili97680a_remove(struct mipi_dsi_device *dsi)
+{
+	struct ili97680a *ctx = mipi_dsi_get_drvdata(dsi);
+	int ret;
+
+	ret = mipi_dsi_detach(dsi);
+	if (ret < 0)
+		dev_err(&dsi->dev, "Failed to detach from DSI host: %d\n", ret);
+
+	drm_panel_remove(&ctx->panel);
+}
+
+static const struct of_device_id ili97680a_of_match[] = {
+	{ .compatible = "motorola,vantage-boe-ili97680a" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ili97680a_of_match);
+
+static struct mipi_dsi_driver ili97680a_driver = {
+	.probe = ili97680a_probe,
+	.remove = ili97680a_remove,
+	.driver = {
+		.name = "panel-ilitek-ili97680a",
+		.of_match_table = ili97680a_of_match,
+	},
+};
+module_mipi_dsi_driver(ili97680a_driver);
+
+MODULE_DESCRIPTION("DRM driver for Ilitek ILI97680A based DSC command mode panels");
+MODULE_LICENSE("GPL");

-- 
2.56.1

