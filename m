From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Sun, 28 Sep 2025 11:08:00 +0800
Subject: [PATCH v6 2/4] ALSA: usb-audio: improve module param quirk_flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250928-sound-v6-2-7da6e5982432@uniontech.com>
References: <20250928-sound-v6-0-7da6e5982432@uniontech.com>
In-Reply-To: <20250928-sound-v6-0-7da6e5982432@uniontech.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, qaqland <anguoli@uniontech.com>, 
 kernel@uniontech.com, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia@uniontech.com>, Takashi Iwai <tiwai@suse.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759028886; l=6014;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=6cs94liQClaGAIzwtJgxPeNFLVMt00l3vEH6r+gRVa8=;
 b=exYXdhzlMgCLjiXGLRair8weI8gWAJn4PNfor/TvZUFgyA1uAXmRfmX58ACtxyTQfPlq1i5uE
 +NGWzvEI5+8DjXluF/jGSSTeKpOS52/h4JW7wko71V+4+zAMxSTz/AU
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It accepts strings like `VID:PID:quirk_flag_name1|quirk_flag_name2;...`
from now on, so that we can use it to debug USB audio devices more
intuitive and flexible. The compatibility of previous form is kept.

Co-developed-by: Takashi Iwai <tiwai@suse.de>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/usb/card.c   | 32 +++++++++++++++----
 sound/usb/quirks.c | 90 +++++++++++++++++++++++++++++++++++++++++++++++++++++-
 sound/usb/quirks.h |  4 ++-
 3 files changed, 118 insertions(+), 8 deletions(-)

diff --git a/sound/usb/card.c b/sound/usb/card.c
index 0265206a8e8cf31133e8463c98fe0497d8ace89e..66c6c92fa9e8d2d04cc297a3dc8de9c8a2e99465 100644
--- a/sound/usb/card.c
+++ b/sound/usb/card.c
@@ -73,7 +73,7 @@ static bool lowlatency = true;
 static char *quirk_alias[SNDRV_CARDS];
 static char *delayed_register[SNDRV_CARDS];
 static bool implicit_fb[SNDRV_CARDS];
-static unsigned int quirk_flags[SNDRV_CARDS];
+static char *quirk_flags[SNDRV_CARDS];
 
 bool snd_usb_use_vmalloc = true;
 bool snd_usb_skip_validation;
@@ -103,7 +103,7 @@ module_param_array(delayed_register, charp, NULL, 0444);
 MODULE_PARM_DESC(delayed_register, "Quirk for delayed registration, given by id:iface, e.g. 0123abcd:4.");
 module_param_array(implicit_fb, bool, NULL, 0444);
 MODULE_PARM_DESC(implicit_fb, "Apply generic implicit feedback sync mode.");
-module_param_array(quirk_flags, uint, NULL, 0444);
+module_param_array(quirk_flags, charp, NULL, 0444);
 MODULE_PARM_DESC(quirk_flags, "Driver quirk bit flags.");
 module_param_named(use_vmalloc, snd_usb_use_vmalloc, bool, 0444);
 MODULE_PARM_DESC(use_vmalloc, "Use vmalloc for PCM intermediate buffers (default: yes).");
@@ -692,6 +692,29 @@ static void usb_audio_make_longname(struct usb_device *dev,
 	}
 }
 
+static void snd_usb_init_quirk_flags(int idx, struct snd_usb_audio *chip)
+{
+	size_t i;
+
+	/* old style option found: the position-based integer value */
+	if (quirk_flags[idx] &&
+	    !kstrtou32(quirk_flags[idx], 0, &chip->quirk_flags)) {
+		snd_usb_apply_flag_dbg("module param", chip, chip->quirk_flags);
+		return;
+	}
+
+	/* take the default quirk from the quirk table */
+	snd_usb_init_quirk_flags_table(chip);
+
+	/* add or correct quirk bits from options */
+	for (i = 0; i < ARRAY_SIZE(quirk_flags); i++) {
+		if (!quirk_flags[i] || !*quirk_flags[i])
+			break;
+
+		snd_usb_init_quirk_flags_parse_string(chip, quirk_flags[i]);
+	}
+}
+
 /*
  * create a chip instance and set its names.
  */
@@ -750,10 +773,7 @@ static int snd_usb_audio_create(struct usb_interface *intf,
 	INIT_LIST_HEAD(&chip->midi_v2_list);
 	INIT_LIST_HEAD(&chip->mixer_list);
 
-	if (quirk_flags[idx])
-		chip->quirk_flags = quirk_flags[idx];
-	else
-		snd_usb_init_quirk_flags(chip);
+	snd_usb_init_quirk_flags(idx, chip);
 
 	card->private_free = snd_usb_audio_free;
 
diff --git a/sound/usb/quirks.c b/sound/usb/quirks.c
index def1573f65df91ae26a988a45a10267ffba18739..e7ba25f3df9ec2837744ca6d6fa33791e7893842 100644
--- a/sound/usb/quirks.c
+++ b/sound/usb/quirks.c
@@ -2524,7 +2524,7 @@ void snd_usb_apply_flag_dbg(const char *reason,
 	}
 }
 
-void snd_usb_init_quirk_flags(struct snd_usb_audio *chip)
+void snd_usb_init_quirk_flags_table(struct snd_usb_audio *chip)
 {
 	const struct usb_audio_quirk_flags_table *p;
 
@@ -2538,3 +2538,91 @@ void snd_usb_init_quirk_flags(struct snd_usb_audio *chip)
 		}
 	}
 }
+
+void snd_usb_init_quirk_flags_parse_string(struct snd_usb_audio *chip,
+					   const char *str)
+{
+	u16 chip_vid = USB_ID_VENDOR(chip->usb_id);
+	u16 chip_pid = USB_ID_PRODUCT(chip->usb_id);
+	u32 mask_flags, unmask_flags, bit;
+	char *p, *field, *flag;
+	bool is_unmask;
+	u16 vid, pid;
+
+	char *val __free(kfree) = kstrdup(str, GFP_KERNEL);
+
+	if (!val)
+		return;
+
+	for (p = val; p && *p;) {
+		/* Each entry consists of VID:PID:flags */
+		field = strsep(&p, ":");
+		if (!field)
+			break;
+
+		if (strcmp(field, "*") == 0)
+			vid = 0;
+		else if (kstrtou16(field, 16, &vid))
+			break;
+
+		field = strsep(&p, ":");
+		if (!field)
+			break;
+
+		if (strcmp(field, "*") == 0)
+			pid = 0;
+		else if (kstrtou16(field, 16, &pid))
+			break;
+
+		field = strsep(&p, ";");
+		if (!field || !*field)
+			break;
+
+		if ((vid != 0 && vid != chip_vid) ||
+		    (pid != 0 && pid != chip_pid))
+			continue;
+
+		/* Collect the flags */
+		mask_flags = 0;
+		unmask_flags = 0;
+		while (field && *field) {
+			flag = strsep(&field, "|");
+
+			if (!flag)
+				break;
+
+			if (*flag == '!') {
+				is_unmask = true;
+				flag++;
+			} else {
+				is_unmask = false;
+			}
+
+			if (!kstrtou32(flag, 16, &bit)) {
+				if (is_unmask)
+					unmask_flags |= bit;
+				else
+					mask_flags |= bit;
+
+				break;
+			}
+
+			bit = snd_usb_quirk_flags_from_name(flag);
+
+			if (bit) {
+				if (is_unmask)
+					unmask_flags |= bit;
+				else
+					mask_flags |= bit;
+			} else {
+				pr_warn("snd_usb_audio: unknown flag %s while parsing param quirk_flags\n",
+					flag);
+			}
+		}
+
+		chip->quirk_flags &= ~unmask_flags;
+		chip->quirk_flags |= mask_flags;
+		snd_usb_apply_flag_dbg("module param", chip,
+				       chip->quirk_flags);
+	}
+}
diff --git a/sound/usb/quirks.h b/sound/usb/quirks.h
index 1b727d3c35c7033b85b56ce43d66fd76c8f2d4ef..f24d6a5a197a641dac36eb3c6eca5dbf5076b495 100644
--- a/sound/usb/quirks.h
+++ b/sound/usb/quirks.h
@@ -52,7 +52,9 @@ void snd_usb_apply_flag_dbg(const char *reason,
 			    struct snd_usb_audio *chip,
 			    unsigned long flag);
 
-void snd_usb_init_quirk_flags(struct snd_usb_audio *chip);
+void snd_usb_init_quirk_flags_table(struct snd_usb_audio *chip);
+void snd_usb_init_quirk_flags_parse_string(struct snd_usb_audio *chip,
+					   const char *str);
 
 const char *snd_usb_quirk_flag_find_name(unsigned long flag);
 u32 snd_usb_quirk_flags_from_name(const char *name);

-- 
2.51.0

