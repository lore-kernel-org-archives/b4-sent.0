From: Brian Harring <ferringb@gmail.com>
Date: Sun, 08 Nov 2026 19:58:37 +0100
Subject: [PATCH 1/2] ALSA: usb-audio: Use ALC4080 mixer map for ASRock
 X870E Taichi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-alc4082-taichi-v1-1-942558088157@gmail.com>
References: <20261108-alc4082-taichi-v1-0-942558088157@gmail.com>
In-Reply-To: <20261108-alc4082-taichi-v1-0-942558088157@gmail.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, Brian Harring <ferringb@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1909; i=ferringb@gmail.com;
 h=from:subject:message-id; bh=YFJDQUD6ho4yYhVd2+xptui1yDzMTqZ5XF6AawOmfYI=;
 b=owGbwMvMwCW26vPpzMb96zwZT6slMWR9OJb4TGHG8xOXVG9x3T/v/uXhi+nZ9WG5l2tPfa0Jv
 +23aPuTwI6PLAxiXAwzxRRZHnzJeaMQf+ubq9ElF5g5rEwgQ6RFGhiAgIWBLzcxr9RIx0jPVNtQ
 zxDI0DGKh8jpMWhkFheXphbpphUUOeTllySWZObnFevlF6TmFaQX6KVlppVkZOQXFacCjdDLSy1
 xNXAzMXN2dTYyMHVzcXQzMzE1NnIxMjFxdHQzdnYys7QwdHJzdDWxZODiFIC55rMnw/8o2/hc7o
 C4n8vd7rOwh/TZZrofDtqTMldXUHpz0kLNdesZGY68ffNmcdK0n63mVkf8Kg9kT/zmKKc/7WpX9
 o65UTMt/fgB
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
index 9218ca6314ad..15065ee3f363 100644
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
+	{	/* ASRock X870E Taichi / Taichi Lite (ALC4082) */
+		.id = USB_ID(0x26ce, 0x0a0b),
+		.map = alc408x_map,
 	},
 	{	/* MSI TRX40 */
 		.id = USB_ID(0x0db0, 0x543d),

-- 
2.56.0

