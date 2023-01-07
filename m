From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 07 Jan 2023 19:26:22 +0100
Subject: 
 [PATCH 08/15] video: fbdev: omap2: Introduce backlight_get_brightness()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: 
 <20230107-sam-video-backlight-drop-fb_blank-v1-8-1bd9bafb351f@ravnborg.org>
References: 
 <20230107-sam-video-backlight-drop-fb_blank-v1-0-1bd9bafb351f@ravnborg.org>
In-Reply-To: 
 <20230107-sam-video-backlight-drop-fb_blank-v1-0-1bd9bafb351f@ravnborg.org>
To: Nicolas Ferre <nicolas.ferre@microchip.com>, Helge Deller <deller@gmx.de>,
 Alexandre Belloni <alexandre.belloni@bootlin.com>,
 Claudiu Beznea <claudiu.beznea@microchip.com>,
 Antonino Daplas <adaplas@gmail.com>,
 Benjamin Herrenschmidt <benh@kernel.crashing.org>,
 Paul Mackerras <paulus@samba.org>,
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>,
 Robin van der Gracht <robin@protonic.nl>, Miguel Ojeda <ojeda@kernel.org>,
 Lee Jones <lee@kernel.org>, Daniel Thompson <daniel.thompson@linaro.org>,
 Jingoo Han <jingoohan1@gmail.com>
Cc: linux-fbdev@vger.kernel.org, dri-devel@lists.freedesktop.org,
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org,
 linux-omap@vger.kernel.org, linux-staging@lists.linux.dev,
 linuxppc-dev@lists.ozlabs.org, Stephen Kitt <steve@sk2.org>,
 Sam Ravnborg <sam@ravnborg.org>, Allison Randal <allison@lohutok.net>,
 Kate Stewart <kstewart@linuxfoundation.org>,
 Thomas Gleixner <tglx@linutronix.de>, Enrico Weigelt <info@metux.net>,
 Alexios Zavras <alexios.zavras@intel.com>
X-Mailer: b4 0.11.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1673115978; l=3952;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=rBdlXn3SJoyXVGp9uzOjpAfLNvN20Ns2vzMuJ6kxYVQ=;
 b=Se0re9Bl1ixbeQqgTVCOFbfiMaV8wK5dyWiyyTDaZXRNHbQpUsMhAzYvPdOF7Fw51VxQ1DRCZitU
 +Z1PfROxCt3Qh2feioD4dKYYqFcvi1MHfgqxhL6GFEL5iOWFqHYg
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Introduce backlight_get_brightness() to simplify logic
and avoid direct access to backlight properties.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Allison Randal <allison@lohutok.net>
Cc: Sam Ravnborg <sam@ravnborg.org>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Kate Stewart <kstewart@linuxfoundation.org>
Cc: Thomas Gleixner <tglx@linutronix.de>
Cc: Enrico Weigelt <info@metux.net>
Cc: Alexios Zavras <alexios.zavras@intel.com>
---
 .../fbdev/omap2/omapfb/displays/panel-dsi-cm.c     | 19 +-----------------
 .../omap2/omapfb/displays/panel-sony-acx565akm.c   | 23 +++++++---------------
 2 files changed, 8 insertions(+), 34 deletions(-)

diff --git a/drivers/video/fbdev/omap2/omapfb/displays/panel-dsi-cm.c b/drivers/video/fbdev/omap2/omapfb/displays/panel-dsi-cm.c
index a2c7c5cb1523..bd73aa5328c9 100644
--- a/drivers/video/fbdev/omap2/omapfb/displays/panel-dsi-cm.c
+++ b/drivers/video/fbdev/omap2/omapfb/displays/panel-dsi-cm.c
@@ -330,14 +330,8 @@ static int dsicm_bl_update_status(struct backlight_device *dev)
 {
 	struct panel_drv_data *ddata = dev_get_drvdata(&dev->dev);
 	struct omap_dss_device *in = ddata->in;
+	int level = backlight_get_brightness(dev);
 	int r;
-	int level;
-
-	if (dev->props.fb_blank == FB_BLANK_UNBLANK &&
-			dev->props.power == FB_BLANK_UNBLANK)
-		level = dev->props.brightness;
-	else
-		level = 0;
 
 	dev_dbg(&ddata->pdev->dev, "update brightness to %d\n", level);
 
@@ -360,17 +354,7 @@ static int dsicm_bl_update_status(struct backlight_device *dev)
 	return r;
 }
 
-static int dsicm_bl_get_intensity(struct backlight_device *dev)
-{
-	if (dev->props.fb_blank == FB_BLANK_UNBLANK &&
-			dev->props.power == FB_BLANK_UNBLANK)
-		return dev->props.brightness;
-
-	return 0;
-}
-
 static const struct backlight_ops dsicm_bl_ops = {
-	.get_brightness = dsicm_bl_get_intensity,
 	.update_status  = dsicm_bl_update_status,
 };
 
@@ -1251,7 +1235,6 @@ static int dsicm_probe(struct platform_device *pdev)
 
 		ddata->bldev = bldev;
 
-		bldev->props.fb_blank = FB_BLANK_UNBLANK;
 		bldev->props.power = FB_BLANK_UNBLANK;
 		bldev->props.brightness = 255;
 
diff --git a/drivers/video/fbdev/omap2/omapfb/displays/panel-sony-acx565akm.c b/drivers/video/fbdev/omap2/omapfb/displays/panel-sony-acx565akm.c
index c0965bee12c5..c9c8f10e2e2f 100644
--- a/drivers/video/fbdev/omap2/omapfb/displays/panel-sony-acx565akm.c
+++ b/drivers/video/fbdev/omap2/omapfb/displays/panel-sony-acx565akm.c
@@ -337,16 +337,10 @@ static int acx565akm_get_actual_brightness(struct panel_drv_data *ddata)
 static int acx565akm_bl_update_status(struct backlight_device *dev)
 {
 	struct panel_drv_data *ddata = dev_get_drvdata(&dev->dev);
-	int level;
+	int level = backlight_get_brightness(dev);
 
 	dev_dbg(&ddata->spi->dev, "%s\n", __func__);
 
-	if (dev->props.fb_blank == FB_BLANK_UNBLANK &&
-			dev->props.power == FB_BLANK_UNBLANK)
-		level = dev->props.brightness;
-	else
-		level = 0;
-
 	if (ddata->has_bc)
 		acx565akm_set_brightness(ddata, level);
 	else
@@ -364,15 +358,13 @@ static int acx565akm_bl_get_intensity(struct backlight_device *dev)
 	if (!ddata->has_bc)
 		return -ENODEV;
 
-	if (dev->props.fb_blank == FB_BLANK_UNBLANK &&
-			dev->props.power == FB_BLANK_UNBLANK) {
-		if (ddata->has_bc)
-			return acx565akm_get_actual_brightness(ddata);
-		else
-			return dev->props.brightness;
-	}
+	if (backlight_is_blank(dev))
+		return 0;
 
-	return 0;
+	if (ddata->has_bc)
+		return acx565akm_get_actual_brightness(ddata);
+	else
+		return backlight_get_brightness(dev);
 }
 
 static int acx565akm_bl_update_status_locked(struct backlight_device *dev)
@@ -795,7 +787,6 @@ static int acx565akm_probe(struct spi_device *spi)
 	}
 
 	memset(&props, 0, sizeof(props));
-	props.fb_blank = FB_BLANK_UNBLANK;
 	props.power = FB_BLANK_UNBLANK;
 	props.type = BACKLIGHT_RAW;
 

-- 
2.34.1
