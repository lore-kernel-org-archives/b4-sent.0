From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 17 Sep 2025 20:46:42 +0800
Subject: [PATCH v3 3/4] ALSA: usb-audio: add module param
 device_quirk_flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-sound-v3-3-92ebe9472a0a@uniontech.com>
References: <20250917-sound-v3-0-92ebe9472a0a@uniontech.com>
In-Reply-To: <20250917-sound-v3-0-92ebe9472a0a@uniontech.com>
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
 Cryolitia PukNgae <cryolitia@uniontech.com>, Takashi Iwai <tiwai@suse.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758113201; l=9508;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=/Z2DTz0F8Oc71Kb9EfIDDsfeAKHXwOPCabkVyFCDtuY=;
 b=VY0JsmOp90Ai7RzBnpH6c6n7l58BaGwbR7SCLHciQUzCyFH32yreslfuNCQg81sBkmlkoGMm/
 ytgr8o0KWIdBP2uIxAswHak9bxc1/hUiWeRm//zzOx4xcGMtddBubAe
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For apply and unapply quirk flags more flexibly though param and sysfs

Co-developed-by: Takashi Iwai <tiwai@suse.de>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/usb/card.c     | 177 ++++++++++++++++++++++++++++++++++++++++++++++++---
 sound/usb/quirks.c   |  41 ++++++++++++
 sound/usb/quirks.h   |   2 +
 sound/usb/usbaudio.h |  14 ++++
 4 files changed, 226 insertions(+), 8 deletions(-)

diff --git a/sound/usb/card.c b/sound/usb/card.c
index 0265206a8e8cf31133e8463c98fe0497d8ace89e..743aae910cfdf540c6677c6846061754f36a8c1b 100644
--- a/sound/usb/card.c
+++ b/sound/usb/card.c
@@ -73,8 +73,8 @@ static bool lowlatency = true;
 static char *quirk_alias[SNDRV_CARDS];
 static char *delayed_register[SNDRV_CARDS];
 static bool implicit_fb[SNDRV_CARDS];
-static unsigned int quirk_flags[SNDRV_CARDS];
 
+char *quirk_flags[SNDRV_CARDS];
 bool snd_usb_use_vmalloc = true;
 bool snd_usb_skip_validation;
 
@@ -103,13 +103,161 @@ module_param_array(delayed_register, charp, NULL, 0444);
 MODULE_PARM_DESC(delayed_register, "Quirk for delayed registration, given by id:iface, e.g. 0123abcd:4.");
 module_param_array(implicit_fb, bool, NULL, 0444);
 MODULE_PARM_DESC(implicit_fb, "Apply generic implicit feedback sync mode.");
-module_param_array(quirk_flags, uint, NULL, 0444);
-MODULE_PARM_DESC(quirk_flags, "Driver quirk bit flags.");
 module_param_named(use_vmalloc, snd_usb_use_vmalloc, bool, 0444);
 MODULE_PARM_DESC(use_vmalloc, "Use vmalloc for PCM intermediate buffers (default: yes).");
 module_param_named(skip_validation, snd_usb_skip_validation, bool, 0444);
 MODULE_PARM_DESC(skip_validation, "Skip unit descriptor validation (default: no).");
 
+DEFINE_MUTEX(device_quirk_mutex); /* protects quirk_flags && device_quirk_list */
+LIST_HEAD(device_quirk_list);
+
+static void free_device_quirk_list(void)
+{
+	struct device_quirk_entry *pos, *tmp;
+
+	list_for_each_entry_safe(pos, tmp, &device_quirk_list, list) {
+		list_del(&pos->list);
+		kfree(pos);
+	}
+}
+
+static int device_quirks_param_set(const char *value,
+				   const struct kernel_param *kp)
+{
+	u32 mask_flags, unmask_flags, bit;
+	struct device_quirk_entry *data;
+	char *val, *p, *field, *flag;
+	bool is_unmask;
+	u16 vid, pid;
+	int err = 0;
+	size_t i;
+
+	mutex_lock(&device_quirk_mutex);
+
+	memset(quirk_flags, 0, sizeof(quirk_flags));
+
+	err = param_array_set(value, kp);
+	if (err)
+		goto unlock;
+
+	free_device_quirk_list();
+
+	for (i = 0; i < ARRAY_SIZE(quirk_flags); i++) {
+		if (!quirk_flags[i] || !*quirk_flags[i])
+			break;
+
+		val = kstrdup(quirk_flags[i], GFP_KERNEL);
+
+		if (!val) {
+			err = -ENOMEM;
+			goto unlock;
+		}
+
+		for (p = val; p && *p;) {
+			/* Each entry consists of VID:PID:flags */
+			field = strsep(&p, ":");
+			if (!field)
+				break;
+
+			if (strcmp(field, "*") == 0)
+				vid = 0;
+			else if (kstrtou16(field, 16, &vid))
+				break;
+
+			field = strsep(&p, ":");
+			if (!field)
+				break;
+
+			if (strcmp(field, "*") == 0)
+				pid = 0;
+			else if (kstrtou16(field, 16, &pid))
+				break;
+
+			field = strsep(&p, ";");
+			if (!field || !*field)
+				break;
+
+			/* Collect the flags */
+			mask_flags = 0;
+			unmask_flags = 0;
+			while (field && *field) {
+				flag = strsep(&field, "|");
+
+				if (!flag)
+					break;
+
+				if (*flag == '!') {
+					is_unmask = true;
+					flag++;
+				} else {
+					is_unmask = false;
+				}
+
+				if (!kstrtou32(flag, 16, &bit)) {
+					if (is_unmask)
+						unmask_flags |= bit;
+					else
+						mask_flags |= bit;
+
+					break;
+				}
+
+				bit = snd_usb_quirk_flags_from_name(flag);
+
+				if (bit) {
+					if (is_unmask)
+						unmask_flags |= bit;
+					else
+						mask_flags |= bit;
+				} else {
+					pr_warn("snd_usb_audio: unknown flag %s while parsing param device_quirk_flags\n",
+						field);
+				}
+			}
+
+			data = kzalloc(sizeof(*data), GFP_KERNEL);
+
+			if (!data) {
+				kfree(val);
+				err = -ENOMEM;
+				goto unlock;
+			}
+
+			data->vid = vid;
+			data->pid = pid;
+			data->mask_flags = mask_flags;
+			data->unmask_flags = unmask_flags;
+
+			INIT_LIST_HEAD(&data->list);
+			list_add(&data->list, &device_quirk_list);
+		}
+
+		kfree(val);
+	}
+
+unlock:
+	mutex_unlock(&device_quirk_mutex);
+	return err;
+}
+
+static const struct kernel_param_ops quirk_flags_param_ops = {
+	.set = device_quirks_param_set,
+	.get = param_array_get,
+	.free = param_array_free,
+};
+
+static struct kparam_array quirk_flags_param_array = {
+	.max = SNDRV_CARDS,
+	.elemsize = sizeof(char *),
+	.num = NULL,
+	.ops = &param_ops_charp,
+	.elem = &quirk_flags,
+};
+
+device_param_cb(quirk_flags, &quirk_flags_param_ops, &quirk_flags_param_array,
+		0644);
+MODULE_PARM_DESC(quirk_flags, "Add/modify USB audio quirks");
+
 /*
  * we keep the snd_usb_audio_t instances by ourselves for merging
  * the all interfaces on the same card as one sound device.
@@ -750,10 +898,7 @@ static int snd_usb_audio_create(struct usb_interface *intf,
 	INIT_LIST_HEAD(&chip->midi_v2_list);
 	INIT_LIST_HEAD(&chip->mixer_list);
 
-	if (quirk_flags[idx])
-		chip->quirk_flags = quirk_flags[idx];
-	else
-		snd_usb_init_quirk_flags(chip);
+	snd_usb_init_dynamic_quirks(idx, chip);
 
 	card->private_free = snd_usb_audio_free;
 
@@ -1290,4 +1435,20 @@ static struct usb_driver usb_audio_driver = {
 	.supports_autosuspend = 1,
 };
 
-module_usb_driver(usb_audio_driver);
+static int __init usb_audio_init(void)
+{
+	return usb_register_driver(&usb_audio_driver, THIS_MODULE,
+				   KBUILD_MODNAME);
+}
+
+static void __exit usb_audio_exit(void)
+{
+	mutex_lock(&device_quirk_mutex);
+	free_device_quirk_list();
+	mutex_unlock(&device_quirk_mutex);
+
+	usb_deregister(&usb_audio_driver);
+}
+
+module_init(usb_audio_init);
+module_exit(usb_audio_exit);
diff --git a/sound/usb/quirks.c b/sound/usb/quirks.c
index 94854f352b1702b491e1bf3c8b769f7088e03976..ee531ffa5ab13ac8b24c670e6529d3811f927b46 100644
--- a/sound/usb/quirks.c
+++ b/sound/usb/quirks.c
@@ -2537,3 +2537,44 @@ void snd_usb_init_quirk_flags(struct snd_usb_audio *chip)
 		}
 	}
 }
+
+void snd_usb_init_dynamic_quirks(int idx, struct snd_usb_audio *chip)
+{
+	u16 vid = USB_ID_VENDOR(chip->usb_id);
+	u16 pid = USB_ID_PRODUCT(chip->usb_id);
+	struct device_quirk_entry *pos;
+
+	mutex_lock(&device_quirk_mutex);
+
+	/* old style option found: the position-based integer value */
+	if (quirk_flags[idx] &&
+	    !kstrtou32(quirk_flags[idx], 0, &chip->quirk_flags)) {
+		usb_audio_dbg(chip,
+			      "Set quirk flags 0x%x from param based on position %d for device %04x:%04x\n",
+			      chip->quirk_flags, idx,
+			      USB_ID_VENDOR(chip->usb_id),
+			      USB_ID_PRODUCT(chip->usb_id));
+
+		mutex_unlock(&device_quirk_mutex);
+		return;
+	}
+
+	/* take the default quirk from the quirk table */
+	snd_usb_init_quirk_flags(chip);
+
+	/* add or correct quirk bits from options */
+	list_for_each_entry(pos, &device_quirk_list, list) {
+		if (pos->vid == 0 || (vid == pos->vid && pos->pid == 0) ||
+		    (vid == pos->vid && pid == pos->pid)) {
+			chip->quirk_flags |= pos->mask_flags;
+			chip->quirk_flags &= ~pos->unmask_flags;
+			usb_audio_dbg(chip,
+				      "Set mask quirk flag 0x%x and unmask quirk flag 0x%x from param for device %04x:%04x\n",
+				      pos->mask_flags, pos->unmask_flags,
+				      USB_ID_VENDOR(chip->usb_id),
+				      USB_ID_PRODUCT(chip->usb_id));
+		}
+	}
+
+	mutex_unlock(&device_quirk_mutex);
+}
diff --git a/sound/usb/quirks.h b/sound/usb/quirks.h
index bd5baf2b193a1985f3a0e52bf4a77ca741364769..00c2852c4769d0790a9e2a31b92f3414767c9a98 100644
--- a/sound/usb/quirks.h
+++ b/sound/usb/quirks.h
@@ -53,4 +53,6 @@ void snd_usb_init_quirk_flags(struct snd_usb_audio *chip);
 const char *snd_usb_quirk_flag_find_name(unsigned long flag);
 u32 snd_usb_quirk_flags_from_name(char *name);
 
+void snd_usb_init_dynamic_quirks(int idx, struct snd_usb_audio *chip);
+
 #endif /* __USBAUDIO_QUIRKS_H */
diff --git a/sound/usb/usbaudio.h b/sound/usb/usbaudio.h
index 0a22cb4a02344b2dcf4009c560a759f2da25ca67..3d09d4b7950d884a2076fa48f2180a5e7c87cb3a 100644
--- a/sound/usb/usbaudio.h
+++ b/sound/usb/usbaudio.h
@@ -7,6 +7,8 @@
  *   Copyright (c) 2002 by Takashi Iwai <tiwai@suse.de>
  */
 
+ #include <sound/core.h>
+
 /* handling of USB vendor/product ID pairs as 32-bit numbers */
 #define USB_ID(vendor, product) (((unsigned int)(vendor) << 16) | (product))
 #define USB_ID_VENDOR(id) ((id) >> 16)
@@ -162,9 +164,13 @@ DEFINE_CLASS(snd_usb_lock, struct __snd_usb_lock,
 	     __snd_usb_unlock_shutdown(&(_T)), __snd_usb_lock_shutdown(chip),
 	     struct snd_usb_audio *chip)
 
+extern char *quirk_flags[SNDRV_CARDS];
 extern bool snd_usb_use_vmalloc;
 extern bool snd_usb_skip_validation;
 
+extern struct mutex device_quirk_mutex;
+extern struct list_head device_quirk_list;
+
 /*
  * Driver behavior quirk flags, stored in chip->quirk_flags
  *
@@ -254,4 +260,12 @@ extern bool snd_usb_skip_validation;
 #define QUIRK_FLAG_MIXER_CAPTURE_MIN_MUTE	(1U << 25)
 /* Please also edit snd_usb_audio_quirk_flag_names */
 
+struct device_quirk_entry {
+	struct list_head list;
+	u16 vid;
+	u16 pid;
+	u32 mask_flags;
+	u32 unmask_flags;
+};
+
 #endif /* __USBAUDIO_H */

-- 
2.51.0

