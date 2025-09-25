From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH v5 0/4] ALSA: usb-audio: improve module param quirk_flags
Date: Thu, 25 Sep 2025 17:25:15 +0800
Message-Id: <20250925-sound-v5-0-2593586ff350@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHsK1WgC/23NTQ6CMBCG4auQrq1ph9+68h7GRZlOpQvBtEA0h
 LtbiCTEsPwmfd5OLJB3FNglmZin0QXXtXHkp4Rho9sHcWfiZiAgF0oKHrqhNVwriVWBCkytWXz
 78mTde+3c7nE3LvSd/6zZUS7XrQC/wii54IgKrVEWjJDXoY1/94TNGbsnWyojHEqIUkjSqYFS2
 aw+kulelptMo1RANamsBC30kcz2stpkFmUFaCsJqSkk/st5nr8qO3phTAEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758792317; l=1719;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=bkKlHZmNTjjUsP6ve1IT1avPrLEGebrhKHvE0YNEjvg=;
 b=92hFTPzzesPsn3sM0AmGSKXyf6F3fuqpt+UgLL9Xpwd3NHiDliMeK7+obnumMbruKcp05D2Bz
 0tTDDBqf33YBQyoAaEhGJ8XGnlaQjP0UzK7UTiIUOTp3KuTglsUOIJY
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As an implementation of what has been discussed previously[1].

1. https://lore.kernel.org/all/87h5xm5g7f.wl-tiwai@suse.de/

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
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
      ALSA: doc: add docs about improved quirk_flags in snd-usb-audio

 Documentation/sound/alsa-configuration.rst | 108 +++++++++++------
 sound/usb/card.c                           |  66 +++++++++--
 sound/usb/quirks.c                         | 179 ++++++++++++++++++++++++++++-
 sound/usb/quirks.h                         |  11 +-
 sound/usb/usbaudio.h                       |  84 +++++++++-----
 5 files changed, 376 insertions(+), 72 deletions(-)
---
base-commit: 4c421c40c8b30ab7aae1edc7f7e294fcd33fc186
change-id: 20250910-sound-a91c86c92dba

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

