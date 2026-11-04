From: Riley <riley.redeker@gmail.com>
Date: Wed, 04 Nov 2026 11:39:38 +1100
Subject: [PATCH] ALSA: usb-audio: Add quirk for Yamaha ZG02
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-yamaha-zg02-v1-1-3fd61b8c564f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwMT3crE3MSMRN2qdAMj3RRz00SL5LSUxMRkQyWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgCuY3tBbwAAAA==
X-Change-ID: 20261104-yamaha-zg02-d75a8cfdaac1
To: Takashi Iwai <tiwai@suse.com>, Jaroslav Kysela <perex@perex.cz>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Riley <riley.redeker@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793752778; l=3436;
 i=riley.redeker@gmail.com; s=20261104; h=from:subject:message-id;
 bh=QfAs+gUhXiKkL5wB51Zjd56vxHsgYEBg+Im4XPnvZHo=;
 b=REIeVRBrNFUpjO85xAq43voKcSvOApMyTOUHbvak5DKrYqtr9s3PFhA0CB3t7hjtpFJ1N+5PC
 pmdQ+FwIXqJBomg5u7X2T/T+yrNGr5qH7U28vXdfCg+jYGVwMW51bZD
X-Developer-Key: i=riley.redeker@gmail.com; a=ed25519;
 pk=wo/NEUhxXVG+kr+llQuIWhIFFvK0zNLuzLmkrUPQBR4=
X-Endpoint-Received: by B4 Relay for riley.redeker@gmail.com/20261104 with auth_id=1401
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Yamaha ZG02 game streaming mixer (0499:1516) exposes UAC2 audio
streaming interfaces with a vendor-specific interface class. Only its
MIDI interfaces get bound today: the Yamaha catch-all QUIRK_AUTODETECT
entry rejects the PCM interfaces because create_auto_pcm_quirk()
expects a UAC1-sized FORMAT_TYPE descriptor (bLength >= 8), while the
ZG02 has the 6-byte UAC2 one. As a result no PCM device is created.

The interface layout matches the Steinberg UR22 (0499:1509):

  0: UAC2 AudioControl (vendor class), clock source ID 1
  1: playback, 10ch S32_LE 48kHz, async isochronous OUT
  2: capture, 4ch, isochronous IN used as implicit feedback
  3: Yamaha MIDI
  4: vendor bulk interface

Add the same composite quirk and QUIRK_FLAG_GENERIC_IMPLICIT_FB for
it. The generic UAC2 implicit feedback detection does not apply here
because it requires USB_CLASS_AUDIO.

Tested on a 7.3 kernel with this patch applied (no quirk_alias): the
card registers as USB0499:1516, implicit feedback is set up from EP
0x81, and playback (voice chat and game buses) and capture (microphone)
work. The full channel mapping (playback 1-2 voice chat bus, 3-10 game
bus; capture 1-2 streaming mix, 3-4 microphone) was verified with
quirk_alias=04991516:04991509, which applies the same quirk and flag
entries.

Assisted-by: Claude Opus 5.5
Signed-off-by: Riley <riley.redeker@gmail.com>
---
Hi,

The Yamaha ZG02 currently shows up with MIDI only and no PCM device, so
it's unusable as a sound card on Linux.

I've been running the identical quirk via quirk_alias since 2026-11-03 in
daily use (including voice chat), and tested this patch itself on the
device: playback, capture and implicit feedback all work. Full lsusb -v
output for the device is available if useful.

A UCM profile that splits the streams into Game / Chat / Microphone /
Streaming Mix is going to alsa-ucm-conf separately.
---
 sound/usb/quirks-table.h | 14 ++++++++++++++
 sound/usb/quirks.c       |  2 ++
 2 files changed, 16 insertions(+)

diff --git a/sound/usb/quirks-table.h b/sound/usb/quirks-table.h
index 8b2316fe8..e85eeb536 100644
--- a/sound/usb/quirks-table.h
+++ b/sound/usb/quirks-table.h
@@ -404,6 +404,20 @@ YAMAHA_DEVICE(0x105d, NULL),
 		}
 	}
 },
+{
+	USB_DEVICE(0x0499, 0x1516),
+	QUIRK_DRIVER_INFO {
+		/* .vendor_name = "Yamaha", */
+		/* .product_name = "ZG02", */
+		QUIRK_DATA_COMPOSITE {
+			{ QUIRK_DATA_STANDARD_AUDIO(1) },
+			{ QUIRK_DATA_STANDARD_AUDIO(2) },
+			{ QUIRK_DATA_MIDI_YAMAHA(3) },
+			{ QUIRK_DATA_IGNORE(4) },
+			QUIRK_COMPOSITE_END
+		}
+	}
+},
 {
 	USB_DEVICE(0x0499, 0x1718),
 	QUIRK_DRIVER_INFO {
diff --git a/sound/usb/quirks.c b/sound/usb/quirks.c
index 05a9f6727..7c581e283 100644
--- a/sound/usb/quirks.c
+++ b/sound/usb/quirks.c
@@ -2556,6 +2556,8 @@ static const struct usb_audio_quirk_flags_table quirk_flags_table[] = {
 		   QUIRK_FLAG_GENERIC_IMPLICIT_FB),
 	DEVICE_FLG(0x0499, 0x1509, /* Steinberg UR22 */
 		   QUIRK_FLAG_GENERIC_IMPLICIT_FB),
+	DEVICE_FLG(0x0499, 0x1516, /* Yamaha ZG02 */
+		   QUIRK_FLAG_GENERIC_IMPLICIT_FB),
 	DEVICE_FLG(0x0499, 0x3108, /* Yamaha YIT-W12TX */
 		   QUIRK_FLAG_GET_SAMPLE_RATE),
 	DEVICE_FLG(0x04d8, 0xfeea, /* Benchmark DAC1 Pre */

---
base-commit: 3f2882212c558336d0bf3b1c03b8e1a6b348a6e0
change-id: 20261104-yamaha-zg02-d75a8cfdaac1

Best regards,
--  
Riley <riley.redeker@gmail.com>

