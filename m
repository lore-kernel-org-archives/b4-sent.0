From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH v3 0/4] ALSA: usb-audio: add module param
 device_quirk_flags
Date: Wed, 17 Sep 2025 20:46:39 +0800
Message-Id: <20250917-sound-v3-0-92ebe9472a0a@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK+tymgC/22NzQ7CIBAGX8XsWQxs/cOT72E80GWxHAQDLdE0f
 Xdpoxfjcb7szI6QOXnOcFqNkLj47GOo0KxXQJ0JNxbeVgaUuJNaSZHjEKwwWtFxTxpta6DePhI
 7/1w6l2vlzuc+pteSLWpevwX8FIoSUhBpclY7tFKdh1B/90zdhuId5krBvyZWUyo2jcWDdtv21
 5ym6Q1dSKVy2AAAAA==
X-Change-ID: 20250910-sound-a91c86c92dba
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758113201; l=1478;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=7MnLSLDqHSKYhr2jX7InTUROcDbNmLJmoidtzjDWx/Y=;
 b=bUZz6m0RyNBnrBWVKttV3rveS6EnR5uIcNuAeRDLbzShnesdSz83xo4+h794BdwW3KEfFZ/zB
 Nb9sfgD1EaeCCLsjV22bJrgO36xplueTaGSFIWQ3re/0Mv7pXtEhcMA
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As an implementation of what has been discussed previously[1].

1. https://lore.kernel.org/all/87h5xm5g7f.wl-tiwai@suse.de/

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
Changes in v3:
- Instead of a new param, improve the existed one.
- Link to v2: https://lore.kernel.org/r/20250912-sound-v2-0-01ea3d279f4b@uniontech.com

Changes in v2:
- Cleaned up some internal rebase confusion, sorry for that
- Link to v1: https://lore.kernel.org/r/20250912-sound-v1-0-cc9cfd9f2d01@uniontech.com

---
Cryolitia PukNgae (4):
      ALSA: usb-audio: add two-way convert between name and bit for QUIRK_FLAG_*
      param: export param_array related functions
      ALSA: usb-audio: add module param device_quirk_flags
      ALSA: doc: add docs about device_device_quirk_flags in snd-usb-audio

 Documentation/sound/alsa-configuration.rst | 112 ++++++++++++------
 include/linux/moduleparam.h                |   3 +
 kernel/params.c                            |   9 +-
 sound/usb/card.c                           | 177 +++++++++++++++++++++++++++--
 sound/usb/quirks.c                         | 123 +++++++++++++++++++-
 sound/usb/quirks.h                         |   5 +
 sound/usb/usbaudio.h                       |  15 +++
 7 files changed, 394 insertions(+), 50 deletions(-)
---
base-commit: 4c421c40c8b30ab7aae1edc7f7e294fcd33fc186
change-id: 20250910-sound-a91c86c92dba

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

