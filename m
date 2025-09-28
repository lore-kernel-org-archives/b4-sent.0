From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Sun, 28 Sep 2025 11:08:01 +0800
Subject: [PATCH v6 3/4] ALSA: usb-audio: make param quirk_flags change-able
 in runtime
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250928-sound-v6-3-7da6e5982432@uniontech.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759028886; l=2371;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=5AZ8qoRZXO0BUCPWWDvotB46JtFmUotG234iZIRjw4Y=;
 b=hHxiRHqOCdray7vQeCQ6uIlfgLX91sBf7tAYsF6YdOccMiacn0u887MlaJtLN84f8/MHQlqKP
 BhR6AK4Lgt3Cd0D3jQqrgrdiCXj24P0aAMoFxPPM7nzMosMnVqOflX9
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change its permision from 0644 to 0444, and add runtime processing.

Developers now can change it during sysfs, without rebooting, for
debugging new buggy devices.

Co-developed-by: Takashi Iwai <tiwai@suse.de>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/usb/card.c | 25 +++++++++++++++++++++++--
 1 file changed, 23 insertions(+), 2 deletions(-)

diff --git a/sound/usb/card.c b/sound/usb/card.c
index 66c6c92fa9e8d2d04cc297a3dc8de9c8a2e99465..1d5a65eac9335028cfeabd2d80b389e364477387 100644
--- a/sound/usb/card.c
+++ b/sound/usb/card.c
@@ -103,13 +103,32 @@ module_param_array(delayed_register, charp, NULL, 0444);
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
+static DEFINE_MUTEX(quirk_flags_mutex);
+
+static int param_set_quirkp(const char *val,
+			    const struct kernel_param *kp)
+{
+	guard(mutex)(&quirk_flags_mutex);
+	return param_set_charp(val, kp);
+}
+
+static const struct kernel_param_ops param_ops_quirkp = {
+	.set = param_set_quirkp,
+	.get = param_get_charp,
+	.free = param_free_charp,
+};
+
+#define param_check_quirkp param_check_charp
+
+module_param_array(quirk_flags, quirkp, NULL, 0644);
+MODULE_PARM_DESC(quirk_flags, "Add/modify USB audio quirks");
+
 /*
  * we keep the snd_usb_audio_t instances by ourselves for merging
  * the all interfaces on the same card as one sound device.
@@ -696,6 +715,8 @@ static void snd_usb_init_quirk_flags(int idx, struct snd_usb_audio *chip)
 {
 	size_t i;
 
+	guard(mutex)(&quirk_flags_mutex);
+
 	/* old style option found: the position-based integer value */
 	if (quirk_flags[idx] &&
 	    !kstrtou32(quirk_flags[idx], 0, &chip->quirk_flags)) {

-- 
2.51.0

