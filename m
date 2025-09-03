From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 03 Sep 2025 13:09:46 +0800
Subject: [PATCH 2/4] ALSA: usb-audio: add quirk
 QUIRK_FLAG_MIXER_CAPTURE_MIN_MUTE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250903-sound-v1-2-d4ca777b8512@uniontech.com>
References: <20250903-sound-v1-0-d4ca777b8512@uniontech.com>
In-Reply-To: <20250903-sound-v1-0-d4ca777b8512@uniontech.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, Celeste Liu <uwu@coelacanthus.name>, 
 qaqland <anguoli@uniontech.com>, linux-doc@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756876185; l=2954;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=96cffDbepRmoALzdF1FSb7F0QqJtNTtbDzVfX1s6B4Y=;
 b=1xID+OM09wKkCbq4mYuoUra031C0SMSRp8IgO3DkOilYh3ENGuVTBAiaX+EO+Dw97X+ppHjUq
 YtTR8KYtbsjDh6ng8vs2NO1XUY5BZ4hp+w3cVLHqQIicPRqRd+MvXwc
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The same hardware problem to QUIRK_FLAG_MIXER_PLAYBACK_MIN_MUTE also
occurs on the capture streams on some USB devices. Add a new flag for
processing the quirk.

Link: https://lore.kernel.org/all/C22C1A172EBB9BD9+eccc2e4a-d21e-4a7d-848c-bbf3982feb94@uniontech.com/
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 Documentation/sound/alsa-configuration.rst | 1 +
 sound/usb/mixer_quirks.c                   | 7 +++++++
 sound/usb/usbaudio.h                       | 3 +++
 3 files changed, 11 insertions(+)

diff --git a/Documentation/sound/alsa-configuration.rst b/Documentation/sound/alsa-configuration.rst
index 062b86522e4d9cc7ec19e978e0efc934dae9ab1b..bf45df1558bbc361ca165abaf9c5d83bfe3188e2 100644
--- a/Documentation/sound/alsa-configuration.rst
+++ b/Documentation/sound/alsa-configuration.rst
@@ -2329,6 +2329,7 @@ quirk_flags
         * bit 24: Set minimum volume control value as mute for devices
           where the lowest playback value represents muted state instead
           of minimum audible volume
+        * bit 25: Be similar to bit 24 but for capture streams
 
 This module supports multiple devices, autoprobe and hotplugging.
 
diff --git a/sound/usb/mixer_quirks.c b/sound/usb/mixer_quirks.c
index 2a1abc24dbfc0c6b69d64529eda01bc25f1a6dd1..828af3095b86ee0aa8f2d248d8e714b5d3ae20eb 100644
--- a/sound/usb/mixer_quirks.c
+++ b/sound/usb/mixer_quirks.c
@@ -4550,6 +4550,13 @@ void snd_usb_mixer_fu_apply_quirk(struct usb_mixer_interface *mixer,
 			cval->min_mute = 1;
 		}
 
+	/* lowest capture value is muted on some devices */
+	if (mixer->chip->quirk_flags & QUIRK_FLAG_MIXER_CAPTURE_MIN_MUTE)
+		if (strstr(kctl->id.name, "Capture")) {
+			usb_audio_info(mixer->chip,
+				       "applying capture min mute quirk\n");
+			cval->min_mute = 1;
+		}
 	/* ALSA-ify some Plantronics headset control names */
 	if (USB_ID_VENDOR(mixer->chip->usb_id) == 0x047f &&
 	    (cval->control == UAC_FU_MUTE || cval->control == UAC_FU_VOLUME))
diff --git a/sound/usb/usbaudio.h b/sound/usb/usbaudio.h
index 707b3037b1b3a3d2997157154cf78d71455bfe4b..30b5102e3caed01eeb86d0075c41338104c58950 100644
--- a/sound/usb/usbaudio.h
+++ b/sound/usb/usbaudio.h
@@ -222,6 +222,8 @@ extern bool snd_usb_skip_validation;
  * QUIRK_FLAG_MIXER_PLAYBACK_MIN_MUTE
  *  Set minimum volume control value as mute for devices where the lowest
  *  playback value represents muted state instead of minimum audible volume
+ * QUIRK_FLAG_MIXER_CAPTURE_MIN_MUTE
+ *  Similar to QUIRK_FLAG_MIXER_PLAYBACK_MIN_MUTE, but for capture streams
  */
 
 #define QUIRK_FLAG_GET_SAMPLE_RATE	(1U << 0)
@@ -249,5 +251,6 @@ extern bool snd_usb_skip_validation;
 #define QUIRK_FLAG_MIC_RES_16		(1U << 22)
 #define QUIRK_FLAG_MIC_RES_384		(1U << 23)
 #define QUIRK_FLAG_MIXER_PLAYBACK_MIN_MUTE	(1U << 24)
+#define QUIRK_FLAG_MIXER_CAPTURE_MIN_MUTE	(1U << 25)
 
 #endif /* __USBAUDIO_H */

-- 
2.51.0

