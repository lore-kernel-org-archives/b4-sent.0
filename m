From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 07 Jan 2023 19:26:17 +0100
Subject: 
 [PATCH 03/15] video: fbdev: nvidia: Introduce backlight_get_brightness()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: 
 <20230107-sam-video-backlight-drop-fb_blank-v1-3-1bd9bafb351f@ravnborg.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1673115978; l=1193;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=RQWprkm6DY1nK1XlfLALnIqlG+B5HpXX5nbpp2tYP5w=;
 b=6PTpxwIiFZKLU7iAjk5SURSyOARWGJhvy9t+pxCYjyWSnVB5zn7lmv5isPTykC0kqbBVYgHfNrQN
 OZnhe0MqCfAtmCpuzISqqz7yPrFGies9O1YR3IhYNqqN2c2yJA35
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Introduce backlight_get_brightness() to simplify logic
and avoid direct access to backlight properties.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Antonino Daplas <adaplas@gmail.com>
Cc: linux-fbdev@vger.kernel.org
---
 drivers/video/fbdev/nvidia/nv_backlight.c | 8 +-------
 1 file changed, 1 insertion(+), 7 deletions(-)

diff --git a/drivers/video/fbdev/nvidia/nv_backlight.c b/drivers/video/fbdev/nvidia/nv_backlight.c
index 2ce53529f636..503a7a683855 100644
--- a/drivers/video/fbdev/nvidia/nv_backlight.c
+++ b/drivers/video/fbdev/nvidia/nv_backlight.c
@@ -49,17 +49,11 @@ static int nvidia_bl_update_status(struct backlight_device *bd)
 {
 	struct nvidia_par *par = bl_get_data(bd);
 	u32 tmp_pcrt, tmp_pmc, fpcontrol;
-	int level;
+	int level = backlight_get_brightness(bd);
 
 	if (!par->FlatPanel)
 		return 0;
 
-	if (bd->props.power != FB_BLANK_UNBLANK ||
-	    bd->props.fb_blank != FB_BLANK_UNBLANK)
-		level = 0;
-	else
-		level = bd->props.brightness;
-
 	tmp_pmc = NV_RD32(par->PMC, 0x10F0) & 0x0000FFFF;
 	tmp_pcrt = NV_RD32(par->PCRTC0, 0x081C) & 0xFFFFFFFC;
 	fpcontrol = NV_RD32(par->PRAMDAC, 0x0848) & 0xCFFFFFCC;

-- 
2.34.1
