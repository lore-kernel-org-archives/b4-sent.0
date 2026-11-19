From: Brian Harring <ferringb@gmail.com>
Date: Thu, 19 Nov 2026 17:08:18 +0100
Subject: [PATCH v2 1/2] ALSA: usb-audio: Use ALC4080 mixer map for ASRock
 X870E Taichi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-alc4082-taichi-v2-1-03ad1352f807@gmail.com>
References: <20261119-alc4082-taichi-v2-0-03ad1352f807@gmail.com>
In-Reply-To: <20261119-alc4082-taichi-v2-0-03ad1352f807@gmail.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, Brian Harring <ferringb@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1902; i=ferringb@gmail.com;
 h=from:subject:message-id; bh=6SKhBAvpKYBOjZlHIYJz/Kb+Y8fYIv6xgNmQSYwBQ8M=;
 b=owGbwMvMwCW26vPpzMb96zwZT6slMWT9l2daWf5E9bThWZfLAUsOh/2Yo6HC1+qbqPOVq/g3/
 57UiadPdXxkYRDjYpgppsjy4EvOG4X4W99cjS65wMxhZQIZIi3SwAAELAx8uYl5pUY6Rnqm2oZ6
 hkCGjlE8RE6PQSOzuLg0tUg3raDIIS+/JLEkMz+vWC+/IDWvIL1ALy0zrSQjI7+oOBVohF5eaom
 rgZuJmbOrs5GBqZuLo5uZiamxkYuRiYmjo5uxs5OZpYWhk5ujq4klAxenAMw1t3kY/mmZC7qJft
 pbV3Fw5UxW7cVz5u/Tyj/00eX41g2TRd9/7fJhZHj4a5p3wULRTQWyc8/kCOxtN//gwWYz62xOs
 e83h2MfznMBAA==
X-Developer-Key: i=ferringb@gmail.com; a=openpgp;
 fpr=E9C121C8F3E4519A7E8E7E39C5068414B0C044B7
X-Endpoint-Received: by B4 Relay for ferringb@gmail.com/default with auth_id=1454
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASRock X870E Taichi / Taichi Lite onboard audio (26ce:0a0b, Realtek
ALC4082) has the same problem as the MSI ALC4080 boards already using
this map: all its playback feature units are named "PCM", so the UCM
profile pairs the headphone volume with the rear output's mute. Its
unit IDs match, so use the same map, renamed to alc408x_map now that
it's no longer MSI-only.

Signed-off-by: Brian Harring <ferringb@gmail.com>
---
 sound/usb/mixer_maps.c | 14 +++++++++-----
 1 file changed, 9 insertions(+), 5 deletions(-)

diff --git a/sound/usb/mixer_maps.c b/sound/usb/mixer_maps.c
index 9218ca6314ad..a0a93f9832b4 100644
--- a/sound/usb/mixer_maps.c
+++ b/sound/usb/mixer_maps.c
@@ -486,8 +486,8 @@ static const struct usbmix_name_map aorus_master_alc1220vb_map[] = {
 	{}
 };
 
-/* MSI MPG X570S Carbon Max Wifi with ALC4080  */
-static const struct usbmix_name_map msi_mpg_x570s_carbon_max_wifi_alc4080_map[] = {
+/* ALC4080/ALC4082 boards with this playback feature unit layout */
+static const struct usbmix_name_map alc408x_map[] = {
 	{ 29, "Speaker Playback" },
 	{ 30, "Front Headphone Playback" },
 	{ 32, "IEC958 Playback" },
@@ -770,15 +770,19 @@ static const struct usbmix_ctl_map usbmix_ctl_maps[] = {
 	},
 	{	/* MSI MPG X570S Carbon Max Wifi */
 		.id = USB_ID(0x0db0, 0x419c),
-		.map = msi_mpg_x570s_carbon_max_wifi_alc4080_map,
+		.map = alc408x_map,
 	},
 	{	/* MSI MAG X570S Torpedo Max */
 		.id = USB_ID(0x0db0, 0xa073),
-		.map = msi_mpg_x570s_carbon_max_wifi_alc4080_map,
+		.map = alc408x_map,
 	},
 	{	/* MSI MAG B850M MORTAR WIFI */
 		.id = USB_ID(0x0db0, 0xcc78),
-		.map = msi_mpg_x570s_carbon_max_wifi_alc4080_map,
+		.map = alc408x_map,
+	},
+	{	/* ASRock X870E Taichi (Lite) (ALC4082) */
+		.id = USB_ID(0x26ce, 0x0a0b),
+		.map = alc408x_map,
 	},
 	{	/* MSI TRX40 */
 		.id = USB_ID(0x0db0, 0x543d),

-- 
2.56.1

