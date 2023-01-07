From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 07 Jan 2023 19:26:29 +0100
Subject: 
 [PATCH 15/15] backlight: backlight: Drop the deprecated fb_blank property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: 
 <20230107-sam-video-backlight-drop-fb_blank-v1-15-1bd9bafb351f@ravnborg.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1673115978; l=3041;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=1rlDGBQ8dUJZwm2QXjSfjVEGh6r7tPSOztASIhko1ZA=;
 b=OWmPqlL1i8POCFlGwpKfdK0lpD04cBqvUemyqQ5rJT5jQQmDliYaJeqEzjRTaDdplBAFwN0P5fJy
 jwHOPNUKCeY0gAj2nPyPtvnKkGoHtq262p4+KBibi0oW4Iuegikn
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

With all users gone remove the deprecated fb_blank member in
backlight_properties.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Lee Jones <lee@kernel.org>
Cc: Daniel Thompson <daniel.thompson@linaro.org>
Cc: Jingoo Han <jingoohan1@gmail.com>
---
 drivers/video/backlight/backlight.c |  2 --
 include/linux/backlight.h           | 22 ----------------------
 2 files changed, 24 deletions(-)

diff --git a/drivers/video/backlight/backlight.c b/drivers/video/backlight/backlight.c
index b788ff3d0f45..9b0557d094c5 100644
--- a/drivers/video/backlight/backlight.c
+++ b/drivers/video/backlight/backlight.c
@@ -118,14 +118,12 @@ static int fb_notifier_callback(struct notifier_block *self,
 		bd->fb_bl_on[node] = true;
 		if (!bd->use_count++) {
 			bd->props.state &= ~BL_CORE_FBBLANK;
-			bd->props.fb_blank = FB_BLANK_UNBLANK;
 			backlight_update_status(bd);
 		}
 	} else if (fb_blank != FB_BLANK_UNBLANK && bd->fb_bl_on[node]) {
 		bd->fb_bl_on[node] = false;
 		if (!(--bd->use_count)) {
 			bd->props.state |= BL_CORE_FBBLANK;
-			bd->props.fb_blank = fb_blank;
 			backlight_update_status(bd);
 		}
 	}
diff --git a/include/linux/backlight.h b/include/linux/backlight.h
index 614653e07e3a..c8622d6cc8c5 100644
--- a/include/linux/backlight.h
+++ b/include/linux/backlight.h
@@ -218,25 +218,6 @@ struct backlight_properties {
 	 */
 	int power;
 
-	/**
-	 * @fb_blank: The power state from the FBIOBLANK ioctl.
-	 *
-	 * When the FBIOBLANK ioctl is called @fb_blank is set to the
-	 * blank parameter and the update_status() operation is called.
-	 *
-	 * When the backlight device is enabled @fb_blank is set
-	 * to FB_BLANK_UNBLANK. When the backlight device is disabled
-	 * @fb_blank is set to FB_BLANK_POWERDOWN.
-	 *
-	 * Backlight drivers should avoid using this property. It has been
-	 * replaced by state & BL_CORE_FBLANK (although most drivers should
-	 * use backlight_is_blank() as the preferred means to get the blank
-	 * state).
-	 *
-	 * fb_blank is deprecated and will be removed.
-	 */
-	int fb_blank;
-
 	/**
 	 * @type: The type of backlight supported.
 	 *
@@ -366,7 +347,6 @@ static inline int backlight_enable(struct backlight_device *bd)
 		return 0;
 
 	bd->props.power = FB_BLANK_UNBLANK;
-	bd->props.fb_blank = FB_BLANK_UNBLANK;
 	bd->props.state &= ~BL_CORE_FBBLANK;
 
 	return backlight_update_status(bd);
@@ -382,7 +362,6 @@ static inline int backlight_disable(struct backlight_device *bd)
 		return 0;
 
 	bd->props.power = FB_BLANK_POWERDOWN;
-	bd->props.fb_blank = FB_BLANK_POWERDOWN;
 	bd->props.state |= BL_CORE_FBBLANK;
 
 	return backlight_update_status(bd);
@@ -403,7 +382,6 @@ static inline int backlight_disable(struct backlight_device *bd)
 static inline bool backlight_is_blank(const struct backlight_device *bd)
 {
 	return bd->props.power != FB_BLANK_UNBLANK ||
-	       bd->props.fb_blank != FB_BLANK_UNBLANK ||
 	       bd->props.state & (BL_CORE_SUSPENDED | BL_CORE_FBBLANK);
 }
 

-- 
2.34.1
