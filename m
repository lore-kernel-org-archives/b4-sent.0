From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH v4 0/5] ALSA: usb-audio: add module param
 device_quirk_flags
Date: Thu, 18 Sep 2025 17:24:29 +0800
Message-Id: <20250918-sound-v4-0-82cf8123d61c@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM3Py2gC/23NQQ7CIBCF4as0rMXAtFrHlfcwLigMloXUQEs0T
 e8ubWxiTJdvwvczskjBUWTnYmSBkouu83lUu4LpVvk7cWfyZiDgIFAKHrvBG65Q6tNRI5hGsfz
 2Gci619K53vJuXey78F6ySc7XtQDfQpJccK1RW4MWjJCXwee/e9LtXncPNlcSbErIUkhSpYEab
 dVsyfJX1qsss0SghrCqQQn1L6dp+gB1mO8YEgEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758187473; l=1700;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=LGd4NE5xucIBmY8TEZN2nv2o/wj6Qe3DoMkc6uy1Dow=;
 b=o2HzUJjj8jUfJ9woKChJmX3gWxj5JbpwyEU3iaRqY0FfnwX6uiBX0fHNdH+fF0E5nfcvHmLBS
 xu/wmAobUA0AZ7u5RdI2TJTlv9etPSjZ1pwL/8DdYCs3vLImHdcDw4m
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As an implementation of what has been discussed previously[1].

1. https://lore.kernel.org/all/87h5xm5g7f.wl-tiwai@suse.de/

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
Changes in v4:
- Split basic parse and dynamic change
- Drop usage of linked list
- Link to v3: https://lore.kernel.org/r/20250917-sound-v3-0-92ebe9472a0a@uniontech.com

Changes in v3:
- Instead of a new param, improve the existed one.
- Link to v2: https://lore.kernel.org/r/20250912-sound-v2-0-01ea3d279f4b@uniontech.com

Changes in v2:
- Cleaned up some internal rebase confusion, sorry for that
- Link to v1: https://lore.kernel.org/r/20250912-sound-v1-0-cc9cfd9f2d01@uniontech.com

---
Cryolitia PukNgae (5):
      ALSA: usb-audio: add two-way convert between name and bit for QUIRK_FLAG_*
      param: export param_array related functions
      ALSA: usb-audio: improve module param quirk_flags
      ALSA: usb-audio: make param quirk_flags change-able in runtime
      ALSA: doc: add docs about improved quirk_flags in snd-usb-audio

 Documentation/sound/alsa-configuration.rst | 108 ++++++++++-----
 include/linux/moduleparam.h                |   3 +
 kernel/params.c                            |   9 +-
 sound/usb/card.c                           |  63 ++++++++-
 sound/usb/quirks.c                         | 206 ++++++++++++++++++++++++++++-
 sound/usb/quirks.h                         |   6 +-
 sound/usb/usbaudio.h                       |   6 +
 7 files changed, 352 insertions(+), 49 deletions(-)
---
base-commit: 4c421c40c8b30ab7aae1edc7f7e294fcd33fc186
change-id: 20250910-sound-a91c86c92dba

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

