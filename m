From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Thu, 18 Sep 2025 17:24:30 +0800
Subject: [PATCH v4 1/5] ALSA: usb-audio: add two-way convert between name
 and bit for QUIRK_FLAG_*
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250918-sound-v4-1-82cf8123d61c@uniontech.com>
References: <20250918-sound-v4-0-82cf8123d61c@uniontech.com>
In-Reply-To: <20250918-sound-v4-0-82cf8123d61c@uniontech.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>
Cc: linux-sound@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, qaqland <anguoli@uniontech.com>, 
 kernel@uniontech.com, linux-modules@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758187473; l=4063;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=/BXquMWJMNiFdz+nh5s6GogPhAqR6jecE2iPTQLfG8w=;
 b=NG/5R3jQX8kpdaMuykUIawwyLiNFHUTU0wCQTg5C2J+0eFQApormifbECybPieuDu+7oVQmNZ
 xItgiMQhCVhAdGaLUEtc7sRFrEn0rbeUlRsBWE6PlpIymkC1ay9La8P
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Also improve debug logs for applied quirks

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/usb/quirks.c   | 82 +++++++++++++++++++++++++++++++++++++++++++++++++---
 sound/usb/quirks.h   |  3 ++
 sound/usb/usbaudio.h |  1 +
 3 files changed, 82 insertions(+), 4 deletions(-)

diff --git a/sound/usb/quirks.c b/sound/usb/quirks.c
index d736a4750356597bfb0f9d5ab01cdaeaac0f907c..94854f352b1702b491e1bf3c8b769f7088e03976 100644
--- a/sound/usb/quirks.c
+++ b/sound/usb/quirks.c
@@ -2446,6 +2446,62 @@ static const struct usb_audio_quirk_flags_table quirk_flags_table[] = {
 	{} /* terminator */
 };
 
+static const char *const snd_usb_audio_quirk_flag_names[] = {
+	"get_sample_rate",
+	"share_media_device",
+	"align_transfer",
+	"tx_length",
+	"playback_first",
+	"skip_clock_selector",
+	"ignore_clock_source",
+	"itf_usb_dsd_dac",
+	"ctl_msg_delay",
+	"ctl_msg_delay_1m",
+	"ctl_msg_delay_5m",
+	"iface_delay",
+	"validate_rates",
+	"disable_autosuspend",
+	"ignore_ctl_error",
+	"dsd_raw",
+	"set_iface_first",
+	"generic_implicit_fb",
+	"skip_implicit_fb",
+	"iface_skip_close",
+	"force_iface_reset",
+	"fixed_rate",
+	"mic_res_16",
+	"mic_res_384",
+	"mixer_playback_min_mute",
+	"mixer_capture_min_mute",
+	NULL
+};
+
+const char *snd_usb_quirk_flag_find_name(unsigned long index)
+{
+	if (index >= ARRAY_SIZE(snd_usb_audio_quirk_flag_names))
+		return NULL;
+
+	return snd_usb_audio_quirk_flag_names[index];
+}
+
+u32 snd_usb_quirk_flags_from_name(char *name)
+{
+	u32 flag = 0;
+	u32 i;
+
+	if (!name || !*name)
+		return 0;
+
+	for (i = 0; snd_usb_audio_quirk_flag_names[i]; i++) {
+		if (strcmp(name, snd_usb_audio_quirk_flag_names[i]) == 0) {
+			flag = (1U << i);
+			break;
+		}
+	}
+
+	return flag;
+}
+
 void snd_usb_init_quirk_flags(struct snd_usb_audio *chip)
 {
 	const struct usb_audio_quirk_flags_table *p;
@@ -2454,10 +2510,28 @@ void snd_usb_init_quirk_flags(struct snd_usb_audio *chip)
 		if (chip->usb_id == p->id ||
 		    (!USB_ID_PRODUCT(p->id) &&
 		     USB_ID_VENDOR(chip->usb_id) == USB_ID_VENDOR(p->id))) {
-			usb_audio_dbg(chip,
-				      "Set quirk_flags 0x%x for device %04x:%04x\n",
-				      p->flags, USB_ID_VENDOR(chip->usb_id),
-				      USB_ID_PRODUCT(chip->usb_id));
+			unsigned long flags = p->flags;
+			unsigned long bit;
+
+			for_each_set_bit(bit, &flags,
+					 BYTES_TO_BITS(sizeof(p->flags))) {
+				const char *name =
+					snd_usb_audio_quirk_flag_names[bit];
+
+				if (name)
+					usb_audio_dbg(chip,
+						      "Set quirk flag %s for device %04x:%04x\n",
+						      name,
+						      USB_ID_VENDOR(chip->usb_id),
+						      USB_ID_PRODUCT(chip->usb_id));
+				else
+					usb_audio_warn(chip,
+						       "Set unknown quirk flag 0x%lx for device %04x:%04x\n",
+						       bit,
+						       USB_ID_VENDOR(chip->usb_id),
+						       USB_ID_PRODUCT(chip->usb_id));
+			}
+
 			chip->quirk_flags |= p->flags;
 			return;
 		}
diff --git a/sound/usb/quirks.h b/sound/usb/quirks.h
index f9bfd5ac7bab01717de3a76227482a128bf73165..bd5baf2b193a1985f3a0e52bf4a77ca741364769 100644
--- a/sound/usb/quirks.h
+++ b/sound/usb/quirks.h
@@ -50,4 +50,7 @@ void snd_usb_audioformat_attributes_quirk(struct snd_usb_audio *chip,
 
 void snd_usb_init_quirk_flags(struct snd_usb_audio *chip);
 
+const char *snd_usb_quirk_flag_find_name(unsigned long flag);
+u32 snd_usb_quirk_flags_from_name(char *name);
+
 #endif /* __USBAUDIO_QUIRKS_H */
diff --git a/sound/usb/usbaudio.h b/sound/usb/usbaudio.h
index 30b5102e3caed01eeb86d0075c41338104c58950..0a22cb4a02344b2dcf4009c560a759f2da25ca67 100644
--- a/sound/usb/usbaudio.h
+++ b/sound/usb/usbaudio.h
@@ -252,5 +252,6 @@ extern bool snd_usb_skip_validation;
 #define QUIRK_FLAG_MIC_RES_384		(1U << 23)
 #define QUIRK_FLAG_MIXER_PLAYBACK_MIN_MUTE	(1U << 24)
 #define QUIRK_FLAG_MIXER_CAPTURE_MIN_MUTE	(1U << 25)
+/* Please also edit snd_usb_audio_quirk_flag_names */
 
 #endif /* __USBAUDIO_H */

-- 
2.51.0

