From: Dang Huynh <dang.huynh@mainlining.org>
Date: Sat, 08 Nov 2025 12:38:03 +0700
Subject: [PATCH v6 07/12] video: rockchip: vop2: Add video bridge support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251108-vop2-pt2-v6-7-d04c699262fb@mainlining.org>
References: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
In-Reply-To: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
To: u-boot@lists.denx.de
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Simon Glass <sjg@chromium.org>, Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Tom Rini <trini@konsulko.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, Alexander Graf <agraf@csgraf.de>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 Ion Agorria <ion@agorria.com>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 Dragan Simic <dsimic@manjaro.org>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Piotr Zalewski <pZ010001011111@proton.me>, 
 Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762580305; l=4191;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=RR/ibHpd7ymZ9sm6i+4d0pvcoswDlx9VYfmp0daWhuM=;
 b=h2K2YySJeZoBKRnlv/z2H/h714ra02QAt/NjFFmypjdShqRJ9XN3lyYPPMbCIg2PGUashu9Sg
 +jiu3GuRlnWBmAmkgiYlQ3tBz0xwAr02uhPzBr9NFbPoWnYcQJWRKDR
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for video bridge to VOP2 so we can use the MIPI DSI
bridge driver that we have.

Reviewed-by: Svyatoslav Ryhel <clamor95@gmail.com>
Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 drivers/video/rockchip/rk_vop2.c | 81 +++++++++++++++++++++++++++++-----------
 1 file changed, 59 insertions(+), 22 deletions(-)

diff --git a/drivers/video/rockchip/rk_vop2.c b/drivers/video/rockchip/rk_vop2.c
index 992f215d416..156daafa0c3 100644
--- a/drivers/video/rockchip/rk_vop2.c
+++ b/drivers/video/rockchip/rk_vop2.c
@@ -13,10 +13,12 @@
 #include <dm/device_compat.h>
 #include <edid.h>
 #include <log.h>
+#include <panel.h>
 #include <regmap.h>
 #include <reset.h>
 #include <syscon.h>
 #include <video.h>
+#include <video_bridge.h>
 #include <asm/global_data.h>
 #include <asm/gpio.h>
 #include <asm/io.h>
@@ -291,6 +293,7 @@ static int rk_display_init(struct udevice *dev, ulong fbbase, ofnode vp_node)
 	int vop_id, port_id, win_id;
 	struct display_timing timing;
 	struct udevice *disp;
+	struct udevice *bridge;
 	int ret;
 	u32 remote_phandle;
 	struct display_plat *disp_uc_plat;
@@ -357,8 +360,11 @@ static int rk_display_init(struct udevice *dev, ulong fbbase, ofnode vp_node)
 			return -EINVAL;
 		}
 
+		if (IS_ENABLED(CONFIG_VIDEO_BRIDGE))
+			uclass_find_device_by_ofnode(UCLASS_VIDEO_BRIDGE, remote, &bridge);
+
 		uclass_find_device_by_ofnode(UCLASS_DISPLAY, remote, &disp);
-		if (disp)
+		if (disp || bridge)
 			break;
 	};
 	compat = ofnode_get_property(remote, "compatible", NULL);
@@ -390,27 +396,49 @@ static int rk_display_init(struct udevice *dev, ulong fbbase, ofnode vp_node)
 	if (ret < 0)
 		return ret;
 
-	disp_uc_plat = dev_get_uclass_plat(disp);
-	debug("Found device '%s', disp_uc_priv=%p\n", disp->name, disp_uc_plat);
-	if (display_in_use(disp)) {
-		debug("   - device in use\n");
-		return -EBUSY;
-	}
+	if (bridge) {
+		/* video bridge detected, probe it */
+		ret = device_probe(bridge);
+		if (ret) {
+			dev_err(dev, "Failed to probe video bridge: %d\n", ret);
+			return ret;
+		}
 
-	disp_uc_plat->source_id = vop_id;
-	disp_uc_plat->src_dev = dev;
+		/* Attach the DSI controller and the display to the bridge. */
+		ret = video_bridge_attach(bridge);
+		if (ret) {
+			dev_err(dev, "Failed to attach video bridge: %d\n", ret);
+			return ret;
+		}
 
-	ret = device_probe(disp);
-	if (ret) {
-		debug("%s: device '%s' display won't probe (ret=%d)\n",
-		      __func__, dev->name, ret);
-		return ret;
-	}
+		ret = video_bridge_get_display_timing(bridge, &timing);
+		if (ret) {
+			dev_err(dev, "Failed to read timings: %d\n", ret);
+			return ret;
+		}
+	} else {
+		disp_uc_plat = dev_get_uclass_plat(disp);
+		debug("Found device '%s', disp_uc_priv=%p\n", disp->name, disp_uc_plat);
+		if (display_in_use(disp)) {
+			debug("   - device in use\n");
+			return -EBUSY;
+		}
 
-	ret = display_read_timing(disp, &timing);
-	if (ret) {
-		debug("%s: Failed to read timings\n", __func__);
-		return ret;
+		disp_uc_plat->source_id = vop_id;
+		disp_uc_plat->src_dev = dev;
+
+		ret = device_probe(disp);
+		if (ret) {
+			debug("%s: device '%s' display won't probe (ret=%d)\n",
+			      __func__, dev->name, ret);
+			return ret;
+		}
+
+		ret = display_read_timing(disp, &timing);
+		if (ret) {
+			debug("%s: Failed to read timings\n", __func__);
+			return ret;
+		}
 	}
 
 	/* Set clock rate on video port to display timings */
@@ -453,9 +481,18 @@ static int rk_display_init(struct udevice *dev, ulong fbbase, ofnode vp_node)
 
 	rkvop2_mode_set(dev, &timing, vop_id, port_id, platdata);
 
-	ret = display_enable(disp, 1 << l2bpp, &timing);
-	if (ret)
-		return ret;
+	if (bridge) {
+		/* Attach the DSI controller and the display to the bridge. */
+		ret = video_bridge_set_backlight(bridge, 60);
+		if (ret) {
+			dev_err(dev, "Failed to start the video bridge: %d\n", ret);
+			return ret;
+		}
+	} else {
+		ret = display_enable(disp, 1 << l2bpp, &timing);
+		if (ret)
+			return ret;
+	}
 
 	uc_priv->xsize = timing.hactive.typ;
 	uc_priv->ysize = timing.vactive.typ;

-- 
2.51.2

