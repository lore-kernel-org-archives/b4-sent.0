From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH v2 0/3] ALSA: usb-audio: add module param
 device_quirk_flags
Date: Fri, 12 Sep 2025 14:48:57 +0800
Message-Id: <20250912-sound-v2-0-01ea3d279f4b@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFnCw2gC/zXNwQ7CIAzG8VdZehYDTTTiyfcwO2DppAfBwEY0C
 +8uLnr8f2l+XaFwFi5wHlbIXKVIij1wNwAFF++sxPcG1HjQ1mhV0hK9ctbQ6UgW/c1Bv31mnuS
 1Odexd5Ayp/ze2Gq+61/An1CN0orI0uTthF6byxL775kp7Ck9YGytfQDyM5rMngAAAA==
X-Change-ID: 20250910-sound-a91c86c92dba
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-sound@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, qaqland <anguoli@uniontech.com>, 
 kernel@uniontech.com, Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757659749; l=1787;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=jpa6rq+2V3zYCzSXmZnw1ZVzdo6cU0uu6N1P0LBv+cE=;
 b=dj/zGxlegARGAtOG6O5oa3GsH/z4iu8jDMZJrIn6DCVT9L6Z8PMg9UAzoH73Y3dug0FcBe1/y
 r3dxT4h7H8iCdvrzgpFAFBu+0aAOPXwDT7xVlz8FyYMmhDjUB7DYOEd
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As an implementation of what has been discussed previously[1].

> An open question is whether we may want yet a new module option or
> rather extend the existing quirk option to accept the strings
> instead.  Basically, when the given argument has a colon, it's a new
> syntax.  If it's only a number, it's an old syntax, and parse like
> before.  But, I'm open for either way (a new option or extend the
> existing one).

I would like to add a new param. The existed param
`static unsigned int quirk_flags[SNDRV_CARDS]` seems to related to
some sequence the card probed. To be honest, I havn't fully understood
it. And it seems hard to improve it while keeping compatibility.

1. https://lore.kernel.org/all/87h5xm5g7f.wl-tiwai@suse.de/

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
Changes in v2:
- Cleaned up some internal rebase confusion, sorry for that
- Link to v1: https://lore.kernel.org/r/20250912-sound-v1-0-cc9cfd9f2d01@uniontech.com

---
Cryolitia PukNgae (3):
      ALSA: usb-audio: add two-way convert between name and bit for QUIRK_FLAG_*
      ALSA: usb-audio: add module param device_quirk_flags
      ALSA: doc: add docs about device_device_quirk_flags in snd-usb-audio

 Documentation/sound/alsa-configuration.rst | 105 ++++++++++++------
 sound/usb/card.c                           | 165 ++++++++++++++++++++++++++++-
 sound/usb/quirks.c                         | 110 ++++++++++++++++++-
 sound/usb/quirks.h                         |   5 +
 sound/usb/usbaudio.h                       |  14 +++
 5 files changed, 362 insertions(+), 37 deletions(-)
---
base-commit: 82ad508a85dc64cb4bd648edec5a4ce741648426
change-id: 20250910-sound-a91c86c92dba

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

