From: Trevor Vorhees <vorhees-work@proton.me>
Date: Tue, 11 Aug 2026 20:44:10 -0400
Subject: [PATCH] ALSA: usb-audio: Fix sample rates for PreSonus AudioBox
 USB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-audiobox-usb-fix-v1-1-13c8b7f071ea@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwqEMBBF0a1IjbsgibS/rTQOEi21HBhJGRHEv
 Rvb4Xnw7glCgUmgyU4ItLOwXxL0J4NusstIyH0yGGUKVWmNNvbsnT8wisOBDzTKDvW3zolMCem
 2BkrzP/lrX0t0M3Xb04HrugE6d+HYdAAAAA==
X-Change-ID: 20260811-audiobox-usb-fix-20af9593ee27
To: Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, Jaroslav Kysela <perex@perex.cz>, 
 Abhinav Mahadevan <abhi220204@gmail.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786495455; l=2050;
 i=vorhees-work@proton.me; s=audiobox; h=from:subject:message-id;
 bh=l8HNN0FiikEfBKzUrr9nL6yHOYFf/Ri6waOiekc5h3E=;
 b=sqW0ZUmJEBAU7wkM6OyXVmUTi81pbBw+VZk352fbWQqspQYOORCA24A0RwobB+ef6P2/rw0fe
 w2oca1x3jrRC2V4AieDyd7tzbEZ8uE/nucwzpXkt/wiLBONWUFmrkPL
X-Developer-Key: i=vorhees-work@proton.me; a=ed25519;
 pk=TmdvK8GsvZOb51T6DVhj7yKhGOofzmPnu20FNaeLwLg=
X-Endpoint-Received: by B4 Relay for vorhees-work@proton.me/audiobox with auth_id=940
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fixed audio formats for the PreSonus AudioBox USB specify a discrete
rate mask but leave nr_rates at zero and rate_table unset.  find_format()
therefore rejects every requested rate, preventing the playback and
capture streams from being opened.

Add the advertised 44100 and 48000 Hz rates to both streams and report
their 24 significant bits.

Fixes: 34fe4a9df247 ("ALSA: usb-audio: Add quirk for PreSonus AudioBox USB")
Cc: stable@vger.kernel.org
Signed-off-by: Trevor Vorhees <vorhees-work@proton.me>
---
Tested with a PreSonus AudioBox USB (194f:0301) on Linux
7.1.8-zen1-3-zen. Playback and capture streams opened successfully at
both 44100 and 48000 Hz after applying the patch.
---
 sound/usb/quirks-table.h | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/sound/usb/quirks-table.h b/sound/usb/quirks-table.h
index 71444c28..9a28d7c6 100644
--- a/sound/usb/quirks-table.h
+++ b/sound/usb/quirks-table.h
@@ -2692,6 +2692,7 @@ YAMAHA_DEVICE(0x7010, "UB99"),
 			{
 				QUIRK_DATA_AUDIOFORMAT(2) {
 					.formats = SNDRV_PCM_FMTBIT_S24_3LE,
+					.fmt_bits = 24,
 					.channels = 2,
 					.iface = 2,
 					.altsetting = 1,
@@ -2703,11 +2704,16 @@ YAMAHA_DEVICE(0x7010, "UB99"),
 						 SNDRV_PCM_RATE_48000,
 					.rate_min = 44100,
 					.rate_max = 48000,
+					.nr_rates = 2,
+					.rate_table = (unsigned int[]) {
+						44100, 48000
+					},
 				}
 			},
 			{
 				QUIRK_DATA_AUDIOFORMAT(3) {
 					.formats = SNDRV_PCM_FMTBIT_S24_3LE,
+					.fmt_bits = 24,
 					.channels = 2,
 					.iface = 3,
 					.altsetting = 1,
@@ -2719,6 +2725,10 @@ YAMAHA_DEVICE(0x7010, "UB99"),
 						 SNDRV_PCM_RATE_48000,
 					.rate_min = 44100,
 					.rate_max = 48000,
+					.nr_rates = 2,
+					.rate_table = (unsigned int[]) {
+						44100, 48000
+					},
 				}
 			},
 			QUIRK_COMPOSITE_END

---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260811-audiobox-usb-fix-20af9593ee27

Best regards,
--  
Trevor Vorhees <vorhees-work@proton.me>

