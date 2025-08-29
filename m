From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH 0/2] ALSA: usb-audio: Add module param mixer_min_mute
Date: Fri, 29 Aug 2025 13:10:58 +0800
Message-Id: <20250829-sound-param-v1-0-3c2f67cd7c97@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGM2sWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCyNz3eL80rwU3YLEosRc3TTjlOQ0k8S0lLREIyWgjoKi1LTMCrBp0bG
 1tQBEMqnDXQAAAA==
X-Change-ID: 20250827-sound-param-f3dcf4afdfa2
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Wang Yuli <wangyuli@deepin.org>, Guan Wentao <guanwentao@uniontech.com>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Celeste Liu <CoelacanthusHex@gmail.com>, Guoli An <anguoli@uniontech.com>, 
 linux-doc@vger.kernel.org, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756444262; l=581;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=p5ERxcDEGCnOK/ZpG59PS01c3gt2BiQFtvRT5CoGK6A=;
 b=UTqTk7z0Sozu+v9q38u71swxk1Vq2XZYmgZD1ovK4YN7WfK7RxrYNgfCDhW5aGbPtJRT6ksZ3
 r7fid+myJ/oBViZdfaKVvTriXfc5CywdggqoZprdm/hCHyIK7fXo0nt
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
Cryolitia PukNgae (2):
      ALSA: usb-audio: Add module param mixer_min_mute
      ALSA: docs: Add documents for recently changes in snd-usb-audio

 Documentation/sound/alsa-configuration.rst | 35 ++++++++++++++++++++++++++----
 sound/usb/card.c                           |  7 ++++++
 2 files changed, 38 insertions(+), 4 deletions(-)
---
base-commit: 0c77ec32c041fec76268d46a1ae2628bafaa6a2d
change-id: 20250827-sound-param-f3dcf4afdfa2

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

