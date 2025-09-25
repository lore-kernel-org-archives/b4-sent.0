From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Thu, 25 Sep 2025 17:25:16 +0800
Subject: [PATCH v5 1/4] ALSA: usb-audio: add two-way convert between name
 and bit for QUIRK_FLAG_*
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250925-sound-v5-1-2593586ff350@uniontech.com>
References: <20250925-sound-v5-0-2593586ff350@uniontech.com>
In-Reply-To: <20250925-sound-v5-0-2593586ff350@uniontech.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, qaqland <anguoli@uniontech.com>, 
 kernel@uniontech.com, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia@uniontech.com>, Takashi Iwai <tiwai@suse.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758792317; l=9129;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=EOOIX3vFC5h0FML3Pzb7ZpOvpNzPOvJajX3YFJk5MKc=;
 b=rkeplKBfL5AC4T2PmTTLdftZbYCebPLda8uW+Q1wWj10i9ybl+XLCHd6nQDegD9zW01nDgdY1
 wucwkn50dL0A6fzm19+zdckrsK39jfhKa5nWImkRzajKvln+2TmX2nX
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Also improve debug logs for applied quirks

Co-developed-by: Takashi Iwai <tiwai@suse.de>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/usb/quirks.c   | 95 +++++++++++++++++++++++++++++++++++++++++++++++++---
 sound/usb/quirks.h   |  7 ++++
 sound/usb/usbaudio.h | 84 ++++++++++++++++++++++++++++++++--------------
 3 files changed, 156 insertions(+), 30 deletions(-)

diff --git a/sound/usb/quirks.c b/sound/usb/quirks.c
index d736a4750356597bfb0f9d5ab01cdaeaac0f907c..db6d6e324d78c4da3fc3c676f6f076f01841204e 100644
--- a/sound/usb/quirks.c
+++ b/sound/usb/quirks.c
@@ -2446,6 +2446,96 @@ static const struct usb_audio_quirk_flags_table quirk_flags_table[] = {
 	{} /* terminator */
 };
 
+#define QUIRK_STRING_ENTRY(x) \
+	[QUIRK_TYPE_ ## x] = __stringify(x)
+
+static const char *const snd_usb_audio_quirk_flag_names[] = {
+	QUIRK_STRING_ENTRY(GET_SAMPLE_RATE),
+	QUIRK_STRING_ENTRY(SHARE_MEDIA_DEVICE),
+	QUIRK_STRING_ENTRY(ALIGN_TRANSFER),
+	QUIRK_STRING_ENTRY(TX_LENGTH),
+	QUIRK_STRING_ENTRY(PLAYBACK_FIRST),
+	QUIRK_STRING_ENTRY(SKIP_CLOCK_SELECTOR),
+	QUIRK_STRING_ENTRY(IGNORE_CLOCK_SOURCE),
+	QUIRK_STRING_ENTRY(ITF_USB_DSD_DAC),
+	QUIRK_STRING_ENTRY(CTL_MSG_DELAY),
+	QUIRK_STRING_ENTRY(CTL_MSG_DELAY_1M),
+	QUIRK_STRING_ENTRY(CTL_MSG_DELAY_5M),
+	QUIRK_STRING_ENTRY(IFACE_DELAY),
+	QUIRK_STRING_ENTRY(VALIDATE_RATES),
+	QUIRK_STRING_ENTRY(DISABLE_AUTOSUSPEND),
+	QUIRK_STRING_ENTRY(IGNORE_CTL_ERROR),
+	QUIRK_STRING_ENTRY(DSD_RAW),
+	QUIRK_STRING_ENTRY(SET_IFACE_FIRST),
+	QUIRK_STRING_ENTRY(GENERIC_IMPLICIT_FB),
+	QUIRK_STRING_ENTRY(SKIP_IMPLICIT_FB),
+	QUIRK_STRING_ENTRY(IFACE_SKIP_CLOSE),
+	QUIRK_STRING_ENTRY(FORCE_IFACE_RESET),
+	QUIRK_STRING_ENTRY(FIXED_RATE),
+	QUIRK_STRING_ENTRY(MIC_RES_16),
+	QUIRK_STRING_ENTRY(MIC_RES_384),
+	QUIRK_STRING_ENTRY(MIXER_PLAYBACK_MIN_MUTE),
+	QUIRK_STRING_ENTRY(MIXER_CAPTURE_MIN_MUTE),
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
+u32 snd_usb_quirk_flags_from_name(const char *name)
+{
+	char *upper;
+	int i;
+
+	upper = kstrdup(name, GFP_KERNEL);
+
+	if (!upper)
+		return 0;
+
+	string_upper(upper, upper);
+
+	if (!name || !*name)
+		return 0;
+
+	for (i = 0; snd_usb_audio_quirk_flag_names[i]; i++) {
+		if (strcmp(name, snd_usb_audio_quirk_flag_names[i]) == 0 ||
+		    strcmp(upper, snd_usb_audio_quirk_flag_names[i]) == 0) {
+			kfree(upper);
+			return BIT_U32(i);
+		}
+	}
+
+	kfree(upper);
+	return 0;
+}
+
+void snd_usb_apply_flag_dbg(const char *reason,
+			    struct snd_usb_audio *chip,
+			    unsigned long flag)
+{
+	unsigned long bit;
+
+	for_each_set_bit(bit, &flag, BYTES_TO_BITS(sizeof(flag))) {
+		const char *name = snd_usb_audio_quirk_flag_names[bit];
+
+		if (name)
+			usb_audio_dbg(chip,
+				      "From %s apply quirk flag %s for device %04x:%04x\n",
+				      reason, name, USB_ID_VENDOR(chip->usb_id),
+				      USB_ID_PRODUCT(chip->usb_id));
+		else
+			usb_audio_warn(chip,
+				       "From %s apply unknown quirk flag 0x%lx for device %04x:%04x\n",
+				       reason, bit, USB_ID_VENDOR(chip->usb_id),
+				       USB_ID_PRODUCT(chip->usb_id));
+	}
+}
+
 void snd_usb_init_quirk_flags(struct snd_usb_audio *chip)
 {
 	const struct usb_audio_quirk_flags_table *p;
@@ -2454,10 +2544,7 @@ void snd_usb_init_quirk_flags(struct snd_usb_audio *chip)
 		if (chip->usb_id == p->id ||
 		    (!USB_ID_PRODUCT(p->id) &&
 		     USB_ID_VENDOR(chip->usb_id) == USB_ID_VENDOR(p->id))) {
-			usb_audio_dbg(chip,
-				      "Set quirk_flags 0x%x for device %04x:%04x\n",
-				      p->flags, USB_ID_VENDOR(chip->usb_id),
-				      USB_ID_PRODUCT(chip->usb_id));
+			snd_usb_apply_flag_dbg("builtin table", chip, p->flags);
 			chip->quirk_flags |= p->flags;
 			return;
 		}
diff --git a/sound/usb/quirks.h b/sound/usb/quirks.h
index f9bfd5ac7bab01717de3a76227482a128bf73165..1b727d3c35c7033b85b56ce43d66fd76c8f2d4ef 100644
--- a/sound/usb/quirks.h
+++ b/sound/usb/quirks.h
@@ -48,6 +48,13 @@ void snd_usb_audioformat_attributes_quirk(struct snd_usb_audio *chip,
 					  struct audioformat *fp,
 					  int stream);
 
+void snd_usb_apply_flag_dbg(const char *reason,
+			    struct snd_usb_audio *chip,
+			    unsigned long flag);
+
 void snd_usb_init_quirk_flags(struct snd_usb_audio *chip);
 
+const char *snd_usb_quirk_flag_find_name(unsigned long flag);
+u32 snd_usb_quirk_flags_from_name(const char *name);
+
 #endif /* __USBAUDIO_QUIRKS_H */
diff --git a/sound/usb/usbaudio.h b/sound/usb/usbaudio.h
index 30b5102e3caed01eeb86d0075c41338104c58950..79978cae9799cd14da2c7d2391df104df40fa672 100644
--- a/sound/usb/usbaudio.h
+++ b/sound/usb/usbaudio.h
@@ -226,31 +226,63 @@ extern bool snd_usb_skip_validation;
  *  Similar to QUIRK_FLAG_MIXER_PLAYBACK_MIN_MUTE, but for capture streams
  */
 
-#define QUIRK_FLAG_GET_SAMPLE_RATE	(1U << 0)
-#define QUIRK_FLAG_SHARE_MEDIA_DEVICE	(1U << 1)
-#define QUIRK_FLAG_ALIGN_TRANSFER	(1U << 2)
-#define QUIRK_FLAG_TX_LENGTH		(1U << 3)
-#define QUIRK_FLAG_PLAYBACK_FIRST	(1U << 4)
-#define QUIRK_FLAG_SKIP_CLOCK_SELECTOR	(1U << 5)
-#define QUIRK_FLAG_IGNORE_CLOCK_SOURCE	(1U << 6)
-#define QUIRK_FLAG_ITF_USB_DSD_DAC	(1U << 7)
-#define QUIRK_FLAG_CTL_MSG_DELAY	(1U << 8)
-#define QUIRK_FLAG_CTL_MSG_DELAY_1M	(1U << 9)
-#define QUIRK_FLAG_CTL_MSG_DELAY_5M	(1U << 10)
-#define QUIRK_FLAG_IFACE_DELAY		(1U << 11)
-#define QUIRK_FLAG_VALIDATE_RATES	(1U << 12)
-#define QUIRK_FLAG_DISABLE_AUTOSUSPEND	(1U << 13)
-#define QUIRK_FLAG_IGNORE_CTL_ERROR	(1U << 14)
-#define QUIRK_FLAG_DSD_RAW		(1U << 15)
-#define QUIRK_FLAG_SET_IFACE_FIRST	(1U << 16)
-#define QUIRK_FLAG_GENERIC_IMPLICIT_FB	(1U << 17)
-#define QUIRK_FLAG_SKIP_IMPLICIT_FB	(1U << 18)
-#define QUIRK_FLAG_IFACE_SKIP_CLOSE	(1U << 19)
-#define QUIRK_FLAG_FORCE_IFACE_RESET	(1U << 20)
-#define QUIRK_FLAG_FIXED_RATE		(1U << 21)
-#define QUIRK_FLAG_MIC_RES_16		(1U << 22)
-#define QUIRK_FLAG_MIC_RES_384		(1U << 23)
-#define QUIRK_FLAG_MIXER_PLAYBACK_MIN_MUTE	(1U << 24)
-#define QUIRK_FLAG_MIXER_CAPTURE_MIN_MUTE	(1U << 25)
+enum {
+	QUIRK_TYPE_GET_SAMPLE_RATE		= 0,
+	QUIRK_TYPE_SHARE_MEDIA_DEVICE		= 1,
+	QUIRK_TYPE_ALIGN_TRANSFER		= 2,
+	QUIRK_TYPE_TX_LENGTH			= 3,
+	QUIRK_TYPE_PLAYBACK_FIRST		= 4,
+	QUIRK_TYPE_SKIP_CLOCK_SELECTOR		= 5,
+	QUIRK_TYPE_IGNORE_CLOCK_SOURCE		= 6,
+	QUIRK_TYPE_ITF_USB_DSD_DAC		= 7,
+	QUIRK_TYPE_CTL_MSG_DELAY		= 8,
+	QUIRK_TYPE_CTL_MSG_DELAY_1M		= 9,
+	QUIRK_TYPE_CTL_MSG_DELAY_5M		= 10,
+	QUIRK_TYPE_IFACE_DELAY			= 11,
+	QUIRK_TYPE_VALIDATE_RATES		= 12,
+	QUIRK_TYPE_DISABLE_AUTOSUSPEND		= 13,
+	QUIRK_TYPE_IGNORE_CTL_ERROR		= 14,
+	QUIRK_TYPE_DSD_RAW			= 15,
+	QUIRK_TYPE_SET_IFACE_FIRST		= 16,
+	QUIRK_TYPE_GENERIC_IMPLICIT_FB		= 17,
+	QUIRK_TYPE_SKIP_IMPLICIT_FB		= 18,
+	QUIRK_TYPE_IFACE_SKIP_CLOSE		= 19,
+	QUIRK_TYPE_FORCE_IFACE_RESET		= 20,
+	QUIRK_TYPE_FIXED_RATE			= 21,
+	QUIRK_TYPE_MIC_RES_16			= 22,
+	QUIRK_TYPE_MIC_RES_384			= 23,
+	QUIRK_TYPE_MIXER_PLAYBACK_MIN_MUTE	= 24,
+	QUIRK_TYPE_MIXER_CAPTURE_MIN_MUTE	= 25,
+/* Please also edit snd_usb_audio_quirk_flag_names */
+};
+
+#define QUIRK_FLAG(x)	BIT_U32(QUIRK_TYPE_ ## x)
+
+#define QUIRK_FLAG_GET_SAMPLE_RATE		QUIRK_FLAG(GET_SAMPLE_RATE)
+#define QUIRK_FLAG_SHARE_MEDIA_DEVICE		QUIRK_FLAG(SHARE_MEDIA_DEVICE)
+#define QUIRK_FLAG_ALIGN_TRANSFER		QUIRK_FLAG(ALIGN_TRANSFER)
+#define QUIRK_FLAG_TX_LENGTH			QUIRK_FLAG(TX_LENGTH)
+#define QUIRK_FLAG_PLAYBACK_FIRST		QUIRK_FLAG(PLAYBACK_FIRST)
+#define QUIRK_FLAG_SKIP_CLOCK_SELECTOR		QUIRK_FLAG(SKIP_CLOCK_SELECTOR)
+#define QUIRK_FLAG_IGNORE_CLOCK_SOURCE		QUIRK_FLAG(IGNORE_CLOCK_SOURCE)
+#define QUIRK_FLAG_ITF_USB_DSD_DAC		QUIRK_FLAG(ITF_USB_DSD_DAC)
+#define QUIRK_FLAG_CTL_MSG_DELAY		QUIRK_FLAG(CTL_MSG_DELAY)
+#define QUIRK_FLAG_CTL_MSG_DELAY_1M		QUIRK_FLAG(CTL_MSG_DELAY_1M)
+#define QUIRK_FLAG_CTL_MSG_DELAY_5M		QUIRK_FLAG(CTL_MSG_DELAY_5M)
+#define QUIRK_FLAG_IFACE_DELAY			QUIRK_FLAG(IFACE_DELAY)
+#define QUIRK_FLAG_VALIDATE_RATES		QUIRK_FLAG(VALIDATE_RATES)
+#define QUIRK_FLAG_DISABLE_AUTOSUSPEND		QUIRK_FLAG(DISABLE_AUTOSUSPEND)
+#define QUIRK_FLAG_IGNORE_CTL_ERROR		QUIRK_FLAG(IGNORE_CTL_ERROR)
+#define QUIRK_FLAG_DSD_RAW			QUIRK_FLAG(DSD_RAW)
+#define QUIRK_FLAG_SET_IFACE_FIRST		QUIRK_FLAG(SET_IFACE_FIRST)
+#define QUIRK_FLAG_GENERIC_IMPLICIT_FB		QUIRK_FLAG(GENERIC_IMPLICIT_FB)
+#define QUIRK_FLAG_SKIP_IMPLICIT_FB		QUIRK_FLAG(SKIP_IMPLICIT_FB)
+#define QUIRK_FLAG_IFACE_SKIP_CLOSE		QUIRK_FLAG(IFACE_SKIP_CLOSE)
+#define QUIRK_FLAG_FORCE_IFACE_RESET		QUIRK_FLAG(FORCE_IFACE_RESET)
+#define QUIRK_FLAG_FIXED_RATE			QUIRK_FLAG(FIXED_RATE)
+#define QUIRK_FLAG_MIC_RES_16			QUIRK_FLAG(MIC_RES_16)
+#define QUIRK_FLAG_MIC_RES_384			QUIRK_FLAG(MIC_RES_384)
+#define QUIRK_FLAG_MIXER_PLAYBACK_MIN_MUTE	QUIRK_FLAG(MIXER_PLAYBACK_MIN_MUTE)
+#define QUIRK_FLAG_MIXER_CAPTURE_MIN_MUTE	QUIRK_FLAG(MIXER_CAPTURE_MIN_MUTE)
 
 #endif /* __USBAUDIO_H */

-- 
2.51.0

