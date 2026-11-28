From: Silvio Unkovic <silvio.unkovic@pm.me>
Date: Sat, 28 Nov 2026 02:22:30 +0100
Subject: [PATCH] ALSA: usb-audio: Add quirks for Sony PlayStation Eye
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-pseye-audio-v1-1-b751d7911847@pm.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5EQBBG4atIrXWimkjHVSazQP8oC6SLyYi4u
 8byW7x3kCIIlKrkoICfqMxTBKcJtUM99TDio8lmtmS2ziyKHabevMzGOVuUyJi73FMsloBO/s/
 t832tWzOiXe8FnecFI2Qgg28AAAA=
X-Change-ID: 20261128-pseye-audio-88246e011f3d
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Silvio Unkovic <silvio.unkovic@pm.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795828965; l=3921;
 i=silvio.unkovic@pm.me; s=20261128; h=from:subject:message-id;
 bh=JrLnAEHr27j9SpqNizQ3trGT7b8Z6DBmJXWrIsAhv18=;
 b=PDxWC7aricQBhCiifOAYidPVGV3Hgzfp56TCkwXuwUR8T6pHIwgr19ZkDOIjmcEKE8ZH9N7di
 hjC7+Cvw6jMBH5X5A1ven+shB6IcgvYxZfFp4ABmGtcPlyJ11W7zHd+
X-Developer-Key: i=silvio.unkovic@pm.me; a=ed25519;
 pk=EnRsDjntfFouyIMyaboNgoB+wQ65iMW873YmPIjPiII=
X-Endpoint-Received: by B4 Relay for silvio.unkovic@pm.me/20261128 with auth_id=1673
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Sony PlayStation Eye camera (1415:2000) has a UAC1 four-microphone
array capture interface with a single 16 kHz rate.

Reading back the sampling frequency from its endpoint returns garbage
(e.g. 33186, 17004 or 2199316 instead of 16000), producing a "current
rate ... is different from the runtime rate" warning on every stream
start.  This was already reported in 2012 [1].  Set
QUIRK_FLAG_GET_SAMPLE_RATE to skip the read.

Its feature unit 3 advertises a per-channel volume control, but the
device answers GET_MIN, GET_MAX, GET_RES and GET_CUR with a single zero
byte instead of two bytes, so the driver logs "cannot get min/max
values" and creates a "Mic Capture Volume" control with a fallback 0..1
range that returns -EINVAL on read.  SET_CUR is accepted for any value,
but the capture level does not change: with a fixed range forced in the
driver, recordings stayed at the same level for every setting from
-80 dB to +60 dB.  Skip the control via a mixer map.

[1] "Usb audio - unsuported sampling rates", alsa-devel, 2012-07-10

Assisted-by: Claude:claude-fable-5-2
Signed-off-by: Silvio Unkovic <silvio.unkovic@pm.me>
---
Tested on a PlayStation Eye (1415:2000, bcdDevice 2.00, product string
"USB Camera-B4.09.24.1") on 7.3.4 with snd-usb-audio rebuilt with this
patch: no "current rate" or "cannot get min/max values" messages on
plug-in or stream start, the control is gone, and 4-channel 16 kHz
capture works as before.

The volume findings come from sending the FU 3 requests through usbfs
with the control interface unbound, and from a test build that gave the
control a fixed -80..+60 dB range and stepped it with amixer while
recording, in a quiet room and with music playing.

Tool use: an AI coding assistant (Claude Code) did the investigation of
the driver code, wrote the patch and the test scripts, and drafted this
changelog, working on my machine with the camera attached.  I ran the
tests on the hardware and reviewed the change and the results.
---
 sound/usb/mixer_maps.c | 16 ++++++++++++++++
 sound/usb/quirks.c     |  2 ++
 2 files changed, 18 insertions(+)

diff --git a/sound/usb/mixer_maps.c b/sound/usb/mixer_maps.c
index 9218ca631..26319ed0a 100644
--- a/sound/usb/mixer_maps.c
+++ b/sound/usb/mixer_maps.c
@@ -562,6 +562,17 @@ static const struct usbmix_name_map avermedia_gc553pro_map[] = {
 	{}
 };
 
+/*
+ * Sony PlayStation Eye: FU 3 advertises per-channel volume for the four
+ * microphones, but the device answers GET_MIN, GET_MAX and GET_CUR with a
+ * single zero byte, and SET_CUR is accepted without changing the capture
+ * level.  Skip the control.
+ */
+static const struct usbmix_name_map sony_ps_eye_map[] = {
+	{ 3, NULL, UAC_FU_VOLUME },
+	{}
+};
+
 /*
  * Control map entries
  */
@@ -640,6 +651,11 @@ static const struct usbmix_ctl_map usbmix_ctl_maps[] = {
 		.id = USB_ID(0x13e5, 0x0001),
 		.map = scratch_live_map,
 	},
+	{
+		/* Sony PlayStation Eye */
+		.id = USB_ID(0x1415, 0x2000),
+		.map = sony_ps_eye_map,
+	},
 	{
 		.id = USB_ID(0x200c, 0x1018),
 		.map = ebox44_map,
diff --git a/sound/usb/quirks.c b/sound/usb/quirks.c
index bd00db820..ff2bfe850 100644
--- a/sound/usb/quirks.c
+++ b/sound/usb/quirks.c
@@ -2713,6 +2713,8 @@ static const struct usb_audio_quirk_flags_table quirk_flags_table[] = {
 		   QUIRK_FLAG_PLAYBACK_FIRST | QUIRK_FLAG_GENERIC_IMPLICIT_FB),
 	DEVICE_FLG(0x13e5, 0x0001, /* Serato Phono */
 		   QUIRK_FLAG_IGNORE_CTL_ERROR),
+	DEVICE_FLG(0x1415, 0x2000, /* Sony PlayStation Eye */
+		   QUIRK_FLAG_GET_SAMPLE_RATE),
 	DEVICE_FLG(0x152a, 0x85dd, /* SMSL USB DAC */
 		   QUIRK_FLAG_DSD_RAW | QUIRK_FLAG_DISABLE_AUTOSUSPEND |
 		   QUIRK_FLAG_SKIP_IFACE_SETUP),

---
base-commit: e1aff4d4241057636394751508e633a92f1cbbab
change-id: 20261128-pseye-audio-88246e011f3d

Best regards,
--  
Silvio Unkovic <silvio.unkovic@pm.me>

