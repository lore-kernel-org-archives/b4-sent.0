From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 07 Jan 2023 19:26:26 +0100
Subject: 
 [PATCH 12/15] auxdisplay: ht16k33: Introduce backlight_get_brightness()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: 
 <20230107-sam-video-backlight-drop-fb_blank-v1-12-1bd9bafb351f@ravnborg.org>
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
 Sam Ravnborg <sam@ravnborg.org>, Geert Uytterhoeven <geert@linux-m68k.org>
X-Mailer: b4 0.11.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1673115978; l=1102;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=kjBoW0w8G4MLxd8tLQs7ggdCYZkvfjXTRMQ+r94GOdY=;
 b=0kWokjMYRuMZfLaCdD4imFEpA4wcUDa+Xj2qmv4HJ40saoFGwVXUtDMJ9OE5NEw8o8Fe16McI0pJ
 f+So/WcWDu7T91QYTw2iTMWidajyr5qNRhSvSdK9HUs9qckprcMR
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Introduce backlight_get_brightness() to simplify logic
and avoid direct access to backlight properties.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Robin van der Gracht <robin@protonic.nl>
Cc: Miguel Ojeda <ojeda@kernel.org>
Cc: Geert Uytterhoeven <geert@linux-m68k.org>
---
 drivers/auxdisplay/ht16k33.c | 7 +------
 1 file changed, 1 insertion(+), 6 deletions(-)

diff --git a/drivers/auxdisplay/ht16k33.c b/drivers/auxdisplay/ht16k33.c
index 02425991c159..15ab118c80f5 100644
--- a/drivers/auxdisplay/ht16k33.c
+++ b/drivers/auxdisplay/ht16k33.c
@@ -314,14 +314,9 @@ static int ht16k33_initialize(struct ht16k33_priv *priv)
 
 static int ht16k33_bl_update_status(struct backlight_device *bl)
 {
-	int brightness = bl->props.brightness;
+	int brightness = backlight_get_brightness(bl);
 	struct ht16k33_priv *priv = bl_get_data(bl);
 
-	if (bl->props.power != FB_BLANK_UNBLANK ||
-	    bl->props.fb_blank != FB_BLANK_UNBLANK ||
-	    bl->props.state & BL_CORE_FBBLANK)
-		brightness = 0;
-
 	return ht16k33_brightness_set(priv, brightness);
 }
 

-- 
2.34.1
