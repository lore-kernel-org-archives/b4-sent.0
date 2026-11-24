From: Dennis Rijsdijk <hello@dennis.gg>
Date: Tue, 24 Nov 2026 22:20:43 +0100
Subject: [PATCH] ALSA: usb-audio: Add generic implicit feedback quirk for
 Elgato Wave:3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-implicit-fb-v1-1-99c0526a01f0@dennis.gg>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrE2iDYKriIW2U0b8pUUk4u6K5
 bd47wJPjslDFV3g6GDPyxwg4gh0384dIZtgkInMhZApqhR5WkfWvKFVaE3ZmqRQNjMEIVodWT6
 /Yd389rsaSG/vBe77AQvbFslyAAAA
X-Change-ID: 20261124-b4-implicit-fb-fd9ad08bf5de
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dennis Rijsdijk <hello@dennis.gg>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795555255; l=3251;
 i=hello@dennis.gg; s=20261124; h=from:subject:message-id;
 bh=CzYUiFQBTbT9Wdib/6UNKHXDgSKzREc3eNWxs3jvMew=;
 b=DbonznYWejqOtUOztk3MIPT4LAC+q7AltktqxAfi3MCSaeBL99sZx5Y9WcajOEkxaar4VC5fW
 qyPiAOczWkUAcVDc7cxy8SkrZJzjpTzhl10IF0SUlea4Cu4C3zCSIGh
X-Developer-Key: i=hello@dennis.gg; a=ed25519;
 pk=/uxm3Y6aevSpcZaCD38mlhmVoNlmJW2YgX3OS0SRGuM=
X-Endpoint-Received: by B4 Relay for hello@dennis.gg/20261124 with auth_id=1632
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Elgato Wave:3 (0fd9:0070) records digital silence from its
microphone when capture is started while playback to its headphone
jack is already running. Starting capture first works. With PipeWire
this makes the microphone go silent when an application starts
recording while audio is playing.

The Elgato XLR Dock had the same problem and was fixed by enforcing the
generic implicit feedback mode. The same flag fixes the Wave:3: with it,
capture returns audio in both start orders. One case remains at 96 kHz,
which the device advertises but Elgato's specifications do not list
(only 48 kHz): when playback starts first right after the device ran at
48 kHz, capture is still occasionally silent (2 of 10 tries, against
every try without the flag). At a steady rate, and at 48 kHz in all
cases tried, it did not happen.

Add a quirk entry for the device.

The patch and this description were prepared with an AI coding
assistant (Claude Code, Claude Opus 5.5); I reproduced the problem and
tested the fix on the device.

Link: https://lore.kernel.org/all/CAOUQ8cqoTYm-0xeh1jk6bPo7Qd81+rFBz+my-ByMudzZ_6E0wQ@mail.gmail.com/
Signed-off-by: Dennis Rijsdijk <hello@dennis.gg>
---
Tested on v7.4-rc4 with the stock driver and
quirk_flags=0fd9:0070:generic_implicit_fb (same effect as this entry),
Wave:3 firmware bcdDevice 1.24. Silence below means all-zero samples.

- aplay/arecord on hw: directly, playback started first:
  - 48 kHz: silent every time without the flag; with it, 0 silent in 60+
    starts, also right after the device ran at 96 kHz.
  - 96 kHz: silent without the flag; with it, 0 silent in 30 starts at a
    steady rate, but 2 of 10 silent when a 48 kHz stream ran just before
    (and 4 of 23 in runs where WirePlumber reopened the device at 48 kHz
    in between).
  - Capture-first, and stopping/restarting playback during capture, had
    audio throughout at both rates.
- PipeWire 1.6.10: capture started while music played had audio in 6/6
  tries at 48 kHz and 8/8 with the clock forced to 96 kHz (it was silent
  every time before), and after a WirePlumber restart.
- No audible glitches on the headphones during listening sessions.

Unrelated to this patch, also without the flag: at 96 kHz the first
~12 ms of a capture that starts the endpoint are full-scale noise; this
does not happen at 48 kHz.
---
 sound/usb/quirks.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/sound/usb/quirks.c b/sound/usb/quirks.c
index bcc93e50b..bd00db820 100644
--- a/sound/usb/quirks.c
+++ b/sound/usb/quirks.c
@@ -2684,6 +2684,8 @@ static const struct usb_audio_quirk_flags_table quirk_flags_table[] = {
 		   QUIRK_FLAG_FIXED_RATE),
 	DEVICE_FLG(0x0fd9, 0x0008, /* Hauppauge HVR-950Q */
 		   QUIRK_FLAG_SHARE_MEDIA_DEVICE | QUIRK_FLAG_ALIGN_TRANSFER),
+	DEVICE_FLG(0x0fd9, 0x0070, /* Elgato Wave:3 */
+		   QUIRK_FLAG_GENERIC_IMPLICIT_FB),
 	DEVICE_FLG(0x0fd9, 0x00a6, /* Elgato XLR Dock */
 		   QUIRK_FLAG_GENERIC_IMPLICIT_FB),
 	DEVICE_FLG(0x1038, 0x1294, /* SteelSeries Arctis Pro Wireless */

---
base-commit: c3c132d63840093a3ca4bd09e7434614c1bd07e3
change-id: 20261124-b4-implicit-fb-fd9ad08bf5de

Best regards,
--  
Dennis Rijsdijk <hello@dennis.gg>

