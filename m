From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH v6 0/4] ALSA: usb-audio: improve module param quirk_flags
Date: Sun, 28 Sep 2025 11:07:58 +0800
Message-Id: <20250928-sound-v6-0-7da6e5982432@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI6m2GgC/23NQW7DIBCF4atErEsFg7GZrnqPqgs8DDWL2pVJr
 ESR795JVEtW5eUb8f3cVeW5cFVvp7uaeSm1TKOM9uWkaIjjF+uSZCsw4A1ao+t0GZOOaCm0hJD
 6qOTtz8y5XJ+dj0/ZQ6nnab49s4t9XLcC/BUWq40mQsoJMyRj3y+j/H1mGl5p+laPygKHEkQay
 9El6DA3/ZF0e9lt0olE4J6x6SCaeCSbvQybbEQGoBwsuNRaOpJ+J8Fv0osEj86HNmfnzX+5rus
 voUA4s4YBAAA=
X-Change-ID: 20250910-sound-a91c86c92dba
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, qaqland <anguoli@uniontech.com>, 
 kernel@uniontech.com, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia@uniontech.com>, Takashi Iwai <tiwai@suse.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759028886; l=1883;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=wKUN1mRHjqGz0XUsYLWpranN7Hfr25FWo6FkieDmdnI=;
 b=bays/2BIc2nV3pXqz229vwQYkvkboS5Rue/4zaO4vne7hgghZY1CNhy9aIELuAE+V+sd1eMGC
 0wqQ1wsY54lAuX1EtIli2DrklyHXLUInWefC6HINhpuF08ymArghwBv
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As an implementation of what has been discussed previously[1].

1. https://lore.kernel.org/all/87h5xm5g7f.wl-tiwai@suse.de/

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
Changes in v6:
- Apply review commens, details corrected and wording revised
- Link to v5: https://lore.kernel.org/r/20250925-sound-v5-0-2593586ff350@uniontech.com

Changes in v5:
- Apply review comments. Thanks a lot, Takashi Iwai!
- Link to v4: https://lore.kernel.org/r/20250918-sound-v4-0-82cf8123d61c@uniontech.com

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
Cryolitia PukNgae (4):
      ALSA: usb-audio: add two-way convert between name and bit for QUIRK_FLAG_*
      ALSA: usb-audio: improve module param quirk_flags
      ALSA: usb-audio: make param quirk_flags change-able in runtime
      ALSA: doc: improved docs about quirk_flags in snd-usb-audio

 Documentation/sound/alsa-configuration.rst | 108 ++++++++++++------
 sound/usb/card.c                           |  55 +++++++--
 sound/usb/quirks.c                         | 173 ++++++++++++++++++++++++++++-
 sound/usb/quirks.h                         |  11 +-
 sound/usb/usbaudio.h                       |  84 +++++++++-----
 5 files changed, 359 insertions(+), 72 deletions(-)
---
base-commit: 4c421c40c8b30ab7aae1edc7f7e294fcd33fc186
change-id: 20250910-sound-a91c86c92dba

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

