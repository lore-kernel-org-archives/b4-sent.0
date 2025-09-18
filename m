From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Thu, 18 Sep 2025 17:24:33 +0800
Subject: [PATCH v4 4/5] ALSA: usb-audio: make param quirk_flags change-able
 in runtime
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250918-sound-v4-4-82cf8123d61c@uniontech.com>
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
 Cryolitia PukNgae <cryolitia@uniontech.com>, Takashi Iwai <tiwai@suse.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758187473; l=4510;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=STeoGU+UtGOLSx8KmIDY0kU8k2ZAF7sipS6bLUIP9L4=;
 b=csi4J0NfBu9l3xWhCmiJYM3fyuFHZKpjb/whezESt9l9YSV6By4OYlEFKPQjoO9H6gFDpXdoe
 ngZikcAmm6PDBh29OexAfHPwugVCpd5xT9LBq2egvILVec5rjLaUUU/
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Developers now can change it during sysfs, without rebooting, for
debugging new buggy devices.

Co-developed-by: Takashi Iwai <tiwai@suse.de>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/usb/card.c     | 56 ++++++++++++++++++++++++++++++++++++++++++++++++++--
 sound/usb/quirks.c   |  9 +++++++--
 sound/usb/usbaudio.h |  2 ++
 3 files changed, 63 insertions(+), 4 deletions(-)

diff --git a/sound/usb/card.c b/sound/usb/card.c
index 5837677effa1787ef9d7d02714c3ae43b1a8bc79..fd99df5949df826d97b3d2bc6d3137923ab4295d 100644
--- a/sound/usb/card.c
+++ b/sound/usb/card.c
@@ -103,13 +103,65 @@ module_param_array(delayed_register, charp, NULL, 0444);
 MODULE_PARM_DESC(delayed_register, "Quirk for delayed registration, given by id:iface, e.g. 0123abcd:4.");
 module_param_array(implicit_fb, bool, NULL, 0444);
 MODULE_PARM_DESC(implicit_fb, "Apply generic implicit feedback sync mode.");
-module_param_array(quirk_flags, charp, NULL, 0444);
-MODULE_PARM_DESC(quirk_flags, "Driver quirk bit flags.");
 module_param_named(use_vmalloc, snd_usb_use_vmalloc, bool, 0444);
 MODULE_PARM_DESC(use_vmalloc, "Use vmalloc for PCM intermediate buffers (default: yes).");
 module_param_named(skip_validation, snd_usb_skip_validation, bool, 0444);
 MODULE_PARM_DESC(skip_validation, "Skip unit descriptor validation (default: no).");
 
+/* protects quirk_flags */
+DEFINE_MUTEX(quirk_flags_mutex);
+
+static int quirk_flags_param_set(const char *value,
+				 const struct kernel_param *kp)
+{
+	int err;
+
+	mutex_lock(&quirk_flags_mutex);
+
+	memset(quirk_flags, 0, sizeof(quirk_flags));
+	err = param_array_set(value, kp);
+
+	mutex_unlock(&quirk_flags_mutex);
+
+	return err;
+}
+
+static int quirk_flags_param_get(char *buffer, const struct kernel_param *kp)
+{
+	int err;
+
+	mutex_lock(&quirk_flags_mutex);
+	err = param_array_get(buffer, kp);
+	mutex_unlock(&quirk_flags_mutex);
+
+	return err;
+}
+
+static void quirk_flags_param_free(void *arg)
+{
+	mutex_lock(&quirk_flags_mutex);
+	param_array_free(arg);
+	mutex_unlock(&quirk_flags_mutex);
+}
+
+static const struct kernel_param_ops quirk_flags_param_ops = {
+	.set = quirk_flags_param_set,
+	.get = quirk_flags_param_get,
+	.free = quirk_flags_param_free,
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
diff --git a/sound/usb/quirks.c b/sound/usb/quirks.c
index 4dc2464133e934e48b1fa613884a8a0ebdaff91d..ba9ea94399e5a6e7e1711b2a9148c90f991f05cd 100644
--- a/sound/usb/quirks.c
+++ b/sound/usb/quirks.c
@@ -2548,6 +2548,8 @@ void snd_usb_init_quirk_flags(int idx, struct snd_usb_audio *chip)
 	u16 vid, pid;
 	size_t i;
 
+	mutex_lock(&quirk_flags_mutex);
+
 	/* old style option found: the position-based integer value */
 	if (quirk_flags[idx] &&
 	    !kstrtou32(quirk_flags[idx], 0, &chip->quirk_flags)) {
@@ -2556,7 +2558,7 @@ void snd_usb_init_quirk_flags(int idx, struct snd_usb_audio *chip)
 			      chip->quirk_flags, idx,
 			      USB_ID_VENDOR(chip->usb_id),
 			      USB_ID_PRODUCT(chip->usb_id));
-		return;
+		goto unlock;
 	}
 
 	/* take the default quirk from the quirk table */
@@ -2571,7 +2573,7 @@ void snd_usb_init_quirk_flags(int idx, struct snd_usb_audio *chip)
 
 		if (!val) {
 			pr_err("snd_usb_audio: Error allocating memory while parsing quirk_flags\n");
-			return;
+			goto unlock;
 		}
 
 		for (p = val; p && *p;) {
@@ -2653,4 +2655,7 @@ void snd_usb_init_quirk_flags(int idx, struct snd_usb_audio *chip)
 
 		kfree(val);
 	}
+
+unlock:
+	mutex_unlock(&quirk_flags_mutex);
 }
diff --git a/sound/usb/usbaudio.h b/sound/usb/usbaudio.h
index 73564cd68ebf101291440d0171eb81c220c6f5e2..40551946c20df8c17d306fddd8295ca3a2bfa702 100644
--- a/sound/usb/usbaudio.h
+++ b/sound/usb/usbaudio.h
@@ -168,6 +168,8 @@ extern char *quirk_flags[SNDRV_CARDS];
 extern bool snd_usb_use_vmalloc;
 extern bool snd_usb_skip_validation;
 
+extern struct mutex quirk_flags_mutex;
+
 /*
  * Driver behavior quirk flags, stored in chip->quirk_flags
  *

-- 
2.51.0

