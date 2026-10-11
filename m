From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 11 Oct 2026 21:35:48 +0200
Subject: [PATCH v2 6/9] video: rockchip: dw_mipi_dsi: add a UCLASS_DISPLAY
 adapter for rk_vop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-b4-pinephone-pro-defconfig-v2-6-6b7be35fbee7@protonmail.com>
References: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
In-Reply-To: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Peter Robinson <pbrobinson@gmail.com>, David Heidelberg <david@ixit.cz>, 
 Ondrej Jirman <megi@xff.cz>, Tom Rini <trini@konsulko.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, Simon Glass <sjg@chromium.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Lukasz Majewski <lukma@denx.de>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791747347; l=3146;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=6hSnXMLgy2pp8V/d20bSewBWBcxQsq0mThDI41dm2aw=;
 b=bFem8m9wo0HAitsmp1zaKfmGH1CQnBQjssrtxBCb8e2tgAvNTRomhiw7WOwLnD6t4aMehnfdv
 z88ANes7MrnACqK3gC7Ze5gbdRSQx/N/ZlTAWHa3HNscDOu0xiFuSxy
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rk_vop.c only looks for its encoder in UCLASS_DISPLAY and knows
nothing about UCLASS_VIDEO_BRIDGE. Bind a thin display device on the
DSI node that forwards read_timing to the panel and enable to the
bridge. Enable goes through video_bridge_set_backlight() so that
dsi_host_enable() also runs and the controller leaves command mode.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/video/rockchip/dw_mipi_dsi_rockchip.c | 67 +++++++++++++++++++++++++++
 1 file changed, 67 insertions(+)

diff --git a/drivers/video/rockchip/dw_mipi_dsi_rockchip.c b/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
index 49835587aaf..9d0dda86726 100644
--- a/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
+++ b/drivers/video/rockchip/dw_mipi_dsi_rockchip.c
@@ -10,6 +10,7 @@
 #define LOG_CATEGORY UCLASS_VIDEO_BRIDGE
 
 #include <clk.h>
+#include <display.h>
 #include <dm.h>
 #include <div64.h>
 #include <dsi_host.h>
@@ -798,6 +799,18 @@ static int dw_mipi_dsi_rockchip_bind(struct udevice *dev)
 		return ret;
 	}
 
+	/*
+	 * Bind a thin UCLASS_DISPLAY adapter at the same node so legacy
+	 * rk_vop.c can drive this bridge without either side needing to
+	 * know about the other's op table.
+	 */
+	ret = device_bind_driver_to_node(dev, "dw-mipi-dsi-rockchip-display",
+					 "display", dev_ofnode(dev), NULL);
+	if (ret) {
+		dev_err(dev, "failed to bind display shim to node\n");
+		return ret;
+	}
+
 	return dm_scan_fdt_dev(dev);
 }
 
@@ -997,3 +1010,57 @@ U_BOOT_DRIVER(dw_mipi_dsi_rockchip) = {
 	.ops			= &dw_mipi_dsi_rockchip_ops,
 	.priv_auto		= sizeof(struct dw_rockchip_dsi_priv),
 };
+
+/*
+ * Forwards the two ops rk_vop.c actually calls (read_timing, enable) onto
+ * the real UCLASS_VIDEO_BRIDGE bridge and its UCLASS_PANEL child, which is
+ * where this hardware's own panel.c-based driver (e.g. himax-hx8394.c)
+ * already does the real work
+ */
+static int dw_mipi_dsi_rockchip_display_read_timing(struct udevice *dev,
+						    struct display_timing *timing)
+{
+	struct udevice *panel;
+	int ret;
+
+	ret = uclass_first_device_err(UCLASS_PANEL, &panel);
+	if (ret)
+		return ret;
+
+	ret = panel_get_display_timing(panel, timing);
+	if (ret)
+		ret = ofnode_decode_display_timing(dev_ofnode(panel), 0, timing);
+
+	return ret;
+}
+
+static int dw_mipi_dsi_rockchip_display_enable(struct udevice *dev,
+					       int panel_bpp,
+					       const struct display_timing *timing)
+{
+	struct udevice *bridge;
+	int ret;
+
+	ret = uclass_first_device_err(UCLASS_VIDEO_BRIDGE, &bridge);
+	if (ret)
+		return ret;
+
+	ret = video_bridge_attach(bridge);
+	if (ret)
+		return ret;
+
+	ret = video_bridge_set_backlight(bridge, 100);
+
+	return ret;
+}
+
+static const struct dm_display_ops dw_mipi_dsi_rockchip_display_ops = {
+	.read_timing	= dw_mipi_dsi_rockchip_display_read_timing,
+	.enable		= dw_mipi_dsi_rockchip_display_enable,
+};
+
+U_BOOT_DRIVER(dw_mipi_dsi_rockchip_display) = {
+	.name			= "dw-mipi-dsi-rockchip-display",
+	.id			= UCLASS_DISPLAY,
+	.ops			= &dw_mipi_dsi_rockchip_display_ops,
+};

-- 
2.55.0

