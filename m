From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH 0/3] ALSA: usb-audio: add module param device_quirk_flags
Date: Fri, 12 Sep 2025 14:22:34 +0800
Message-Id: <20250912-sound-v1-0-cc9cfd9f2d01@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACq8w2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDS0MD3eL80rwU3URLw2QLs2RLo5SkRCWg2oKi1LTMCrA50bG1tQAPszg
 5VwAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757658156; l=1620;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=20/cF58CH1PFpX46nEf1I3/pIu4rVHQWTarHqJ4eiNc=;
 b=nrMVuVYuy2JKA5q8gznNSh34wMvBgIboi/CsPkYTFjchFjjFmQRb4AOD9+WDNMvkBqiQoYDL5
 9Dzfq4OGDMnCK14AoamBBspsLB0tYkKKcXjKb3xdlwnedYGTQe7HOUM
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
Cryolitia PukNgae (3):
      ALSA: usb-audio: add two-way convert between name and bit for QUIRK_FLAG_*
      ALSA: usb-audio: add module param device_quirk_flags
      ALSA: doc: add docs about device_device_quirk_flags in snd-usb-audio

 Documentation/sound/alsa-configuration.rst | 105 ++++++++++++------
 sound/usb/card.c                           | 165 ++++++++++++++++++++++++++++-
 sound/usb/quirks.c                         | 135 ++++++++++++++++++++++-
 sound/usb/quirks.h                         |   6 ++
 sound/usb/usbaudio.h                       |  14 +++
 5 files changed, 388 insertions(+), 37 deletions(-)
---
base-commit: 74423aed9d7db520f788fc5dcdb0e0a035e0b28f
change-id: 20250910-sound-a91c86c92dba

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

