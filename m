From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Fri, 29 Aug 2025 13:10:59 +0800
Subject: [PATCH 1/2] ALSA: usb-audio: Add module param mixer_min_mute
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250829-sound-param-v1-1-3c2f67cd7c97@uniontech.com>
References: <20250829-sound-param-v1-0-3c2f67cd7c97@uniontech.com>
In-Reply-To: <20250829-sound-param-v1-0-3c2f67cd7c97@uniontech.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Wang Yuli <wangyuli@deepin.org>, Guan Wentao <guanwentao@uniontech.com>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Celeste Liu <CoelacanthusHex@gmail.com>, Guoli An <anguoli@uniontech.com>, 
 linux-doc@vger.kernel.org, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756444262; l=1950;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=+99QuTAVSYELP6NAKN8XeWv9qym77uQKo+/WgpeA+2g=;
 b=HnggGRou4PiMYDTU3AYipRu+GaNa/iVDrSJQhpBq+CYS0vzcYQIq78ibXM36rZyhm2bdKKlfz
 aRqIp2XWoxMCdotnsi9id0iyJ48QPRojXpF5ltHe0/IK5IIoJ4vdx3j
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As already discussed[1], a module parameter called mixer_min_mute is
added to make it easier for end users to debug the widespread problem
without recompiling the kernel, where USB audio devices are muted when
the volume is set to the minimum value.

1.
https://lore.kernel.org/all/20250827-sound-quirk-min-mute-v1-1-4717aa8a4f6a@uniontech.com/

Tested-by: Guoli An <anguoli@uniontech.com>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/usb/card.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/sound/usb/card.c b/sound/usb/card.c
index 0265206a8e8cf31133e8463c98fe0497d8ace89e..bf65727ad213f2897d735c1f3c55bfc3f85971cf 100644
--- a/sound/usb/card.c
+++ b/sound/usb/card.c
@@ -74,6 +74,7 @@ static char *quirk_alias[SNDRV_CARDS];
 static char *delayed_register[SNDRV_CARDS];
 static bool implicit_fb[SNDRV_CARDS];
 static unsigned int quirk_flags[SNDRV_CARDS];
+static bool mixer_min_mute;
 
 bool snd_usb_use_vmalloc = true;
 bool snd_usb_skip_validation;
@@ -109,6 +110,9 @@ module_param_named(use_vmalloc, snd_usb_use_vmalloc, bool, 0444);
 MODULE_PARM_DESC(use_vmalloc, "Use vmalloc for PCM intermediate buffers (default: yes).");
 module_param_named(skip_validation, snd_usb_skip_validation, bool, 0444);
 MODULE_PARM_DESC(skip_validation, "Skip unit descriptor validation (default: no).");
+module_param(mixer_min_mute, bool, 0444);
+MODULE_PARM_DESC(mixer_min_mute,
+		 "Set minimum volume control value as mute (default: no).");
 
 /*
  * we keep the snd_usb_audio_t instances by ourselves for merging
@@ -959,6 +963,9 @@ static int usb_audio_probe(struct usb_interface *intf,
 	if (ignore_ctl_error)
 		chip->quirk_flags |= QUIRK_FLAG_IGNORE_CTL_ERROR;
 
+	if (mixer_min_mute)
+		chip->quirk_flags |= QUIRK_FLAG_MIXER_MIN_MUTE;
+
 	if (chip->quirk_flags & QUIRK_FLAG_DISABLE_AUTOSUSPEND)
 		usb_disable_autosuspend(interface_to_usbdev(intf));
 

-- 
2.51.0

