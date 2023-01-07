From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 07 Jan 2023 19:26:27 +0100
Subject: [PATCH 13/15] backlight: omap1: Use backlight helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: 
 <20230107-sam-video-backlight-drop-fb_blank-v1-13-1bd9bafb351f@ravnborg.org>
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
 Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.11.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1673115978; l=3774;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=srCckeZD3FDZipiWT3z6Jx0O9ZavywUIgE9g9CQnkT4=;
 b=ZnBn79WC7Jd07w2kvEoUqNXOLxMXiRR81z3KD4hu/AuT4FkBWuhIb8mnv9JkUKSSwMaj8t3RWh8T
 8DR2+MBwD0MvdIdeiVcdPN0SSEF+zFiSKPHpLxPwqkw+xml8oExD
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Rework backlight handling to avoid access to the deprecated
backlight_properties.fb_blank member.

The rework includes removal of get_brightness() operation,
because there was no read back from HW so no use for it.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Lee Jones <lee@kernel.org>
Cc: Daniel Thompson <daniel.thompson@linaro.org>
Cc: Jingoo Han <jingoohan1@gmail.com>
---
 drivers/video/backlight/omap1_bl.c | 67 +++++---------------------------------
 1 file changed, 9 insertions(+), 58 deletions(-)

diff --git a/drivers/video/backlight/omap1_bl.c b/drivers/video/backlight/omap1_bl.c
index 69a49384b3de..49f37da857e7 100644
--- a/drivers/video/backlight/omap1_bl.c
+++ b/drivers/video/backlight/omap1_bl.c
@@ -20,9 +20,6 @@
 #define OMAPBL_MAX_INTENSITY		0xff
 
 struct omap_backlight {
-	int powermode;
-	int current_intensity;
-
 	struct device *dev;
 	struct omap_backlight_config *pdata;
 };
@@ -37,82 +34,40 @@ static inline void omapbl_send_enable(int enable)
 	omap_writeb(enable, OMAP_PWL_CLK_ENABLE);
 }
 
-static void omapbl_blank(struct omap_backlight *bl, int mode)
-{
-	if (bl->pdata->set_power)
-		bl->pdata->set_power(bl->dev, mode);
-
-	switch (mode) {
-	case FB_BLANK_NORMAL:
-	case FB_BLANK_VSYNC_SUSPEND:
-	case FB_BLANK_HSYNC_SUSPEND:
-	case FB_BLANK_POWERDOWN:
-		omapbl_send_intensity(0);
-		omapbl_send_enable(0);
-		break;
-
-	case FB_BLANK_UNBLANK:
-		omapbl_send_intensity(bl->current_intensity);
-		omapbl_send_enable(1);
-		break;
-	}
-}
-
 #ifdef CONFIG_PM_SLEEP
 static int omapbl_suspend(struct device *dev)
 {
 	struct backlight_device *bl_dev = dev_get_drvdata(dev);
-	struct omap_backlight *bl = bl_get_data(bl_dev);
 
-	omapbl_blank(bl, FB_BLANK_POWERDOWN);
+	backlight_disable(bl_dev);
 	return 0;
 }
 
 static int omapbl_resume(struct device *dev)
 {
 	struct backlight_device *bl_dev = dev_get_drvdata(dev);
-	struct omap_backlight *bl = bl_get_data(bl_dev);
 
-	omapbl_blank(bl, bl->powermode);
+	backlight_enable(bl_dev);
 	return 0;
 }
 #endif
 
-static int omapbl_set_power(struct backlight_device *dev, int state)
-{
-	struct omap_backlight *bl = bl_get_data(dev);
-
-	omapbl_blank(bl, state);
-	bl->powermode = state;
-
-	return 0;
-}
-
 static int omapbl_update_status(struct backlight_device *dev)
 {
-	struct omap_backlight *bl = bl_get_data(dev);
+	int brightness = backlight_get_brightness(dev);
 
-	if (bl->current_intensity != dev->props.brightness) {
-		if (bl->powermode == FB_BLANK_UNBLANK)
-			omapbl_send_intensity(dev->props.brightness);
-		bl->current_intensity = dev->props.brightness;
+	if (brightness > 0) {
+		omapbl_send_intensity(dev->props.brightness);
+		omapbl_send_enable(1);
+	} else {
+		omapbl_send_intensity(0);
+		omapbl_send_enable(0);
 	}
 
-	if (dev->props.fb_blank != bl->powermode)
-		omapbl_set_power(dev, dev->props.fb_blank);
-
 	return 0;
 }
 
-static int omapbl_get_intensity(struct backlight_device *dev)
-{
-	struct omap_backlight *bl = bl_get_data(dev);
-
-	return bl->current_intensity;
-}
-
 static const struct backlight_ops omapbl_ops = {
-	.get_brightness = omapbl_get_intensity,
 	.update_status  = omapbl_update_status,
 };
 
@@ -139,9 +94,6 @@ static int omapbl_probe(struct platform_device *pdev)
 	if (IS_ERR(dev))
 		return PTR_ERR(dev);
 
-	bl->powermode = FB_BLANK_POWERDOWN;
-	bl->current_intensity = 0;
-
 	bl->pdata = pdata;
 	bl->dev = &pdev->dev;
 
@@ -149,7 +101,6 @@ static int omapbl_probe(struct platform_device *pdev)
 
 	omap_cfg_reg(PWL);	/* Conflicts with UART3 */
 
-	dev->props.fb_blank = FB_BLANK_UNBLANK;
 	dev->props.brightness = pdata->default_intensity;
 	omapbl_update_status(dev);
 

-- 
2.34.1
