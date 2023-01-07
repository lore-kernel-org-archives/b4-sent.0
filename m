From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 07 Jan 2023 19:26:21 +0100
Subject: 
 [PATCH 07/15] video: fbdev: mx3fb: Introduce backlight_get_brightness()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: 
 <20230107-sam-video-backlight-drop-fb_blank-v1-7-1bd9bafb351f@ravnborg.org>
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
 Sam Ravnborg <sam@ravnborg.org>, Kate Stewart <kstewart@linuxfoundation.org>,
 Thomas Gleixner <tglx@linutronix.de>,
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>,
 Arnd Bergmann <arnd@arndb.de>, Jani Nikula <jani.nikula@intel.com>
X-Mailer: b4 0.11.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1673115978; l=1512;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=drvkdW0PBheGrMYY3qAlAUiLqN5UfH4VOwcA/aXugg0=;
 b=8iTbagfWb1Lj07cocG5qMfP8Ayj4BAQY4d64KWfzkOktfkyCN7IXzBwcj/9U/iJWYWB0GCaKShTH
 0OiuscjyAkCEJdcJGgJQX9THB3GVRSWeiPGBowlxgEHvu9p/2eio
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Introduce backlight_get_brightness() to simplify logic
and avoid direct access to backlight properties.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Sam Ravnborg <sam@ravnborg.org>
Cc: Kate Stewart <kstewart@linuxfoundation.org>
Cc: Thomas Gleixner <tglx@linutronix.de>
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Arnd Bergmann <arnd@arndb.de>
Cc: Jani Nikula <jani.nikula@intel.com>
---
 drivers/video/fbdev/mx3fb.c | 8 +-------
 1 file changed, 1 insertion(+), 7 deletions(-)

diff --git a/drivers/video/fbdev/mx3fb.c b/drivers/video/fbdev/mx3fb.c
index b945b68984b9..bc35f664cbff 100644
--- a/drivers/video/fbdev/mx3fb.c
+++ b/drivers/video/fbdev/mx3fb.c
@@ -283,12 +283,7 @@ static int mx3fb_bl_get_brightness(struct backlight_device *bl)
 static int mx3fb_bl_update_status(struct backlight_device *bl)
 {
 	struct mx3fb_data *fbd = bl_get_data(bl);
-	int brightness = bl->props.brightness;
-
-	if (bl->props.power != FB_BLANK_UNBLANK)
-		brightness = 0;
-	if (bl->props.fb_blank != FB_BLANK_UNBLANK)
-		brightness = 0;
+	int brightness = backlight_get_brightness(bl);
 
 	fbd->backlight_level = (fbd->backlight_level & ~0xFF) | brightness;
 
@@ -325,7 +320,6 @@ static void mx3fb_init_backlight(struct mx3fb_data *fbd)
 
 	fbd->bl = bl;
 	bl->props.power = FB_BLANK_UNBLANK;
-	bl->props.fb_blank = FB_BLANK_UNBLANK;
 	bl->props.brightness = mx3fb_bl_get_brightness(bl);
 }
 

-- 
2.34.1
