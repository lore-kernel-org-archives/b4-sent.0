From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH 0/4] ALSA: usb-audio: series of improvements to min_mute
Date: Wed, 03 Sep 2025 13:09:44 +0800
Message-Id: <20250903-sound-v1-0-d4ca777b8512@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJjNt2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSwMj3eL80rwUXVNjs0Qzy1Rzo0RLYyWg2oKi1LTMCrA50bG1tQByimc
 vVwAAAA==
X-Change-ID: 20250902-sound-536a69e72a93
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, Celeste Liu <uwu@coelacanthus.name>, 
 qaqland <anguoli@uniontech.com>, linux-doc@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756876185; l=908;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=u9cu7HB6ZKQ+UYVov00HqMXQZI5HNQmOImREMoKCVsY=;
 b=jUtYH3kvO6z2XVRsiRLHqkmWO/5NbLP1jz2uqcxBJyuYHw7amEwAOdh+Ahdp6mguSCly8YSxW
 c+QqF3s1hLPDfk4A9kRnC+Pg3HjdubmwOztGjpw6HypX47rSh78agEL
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
Cryolitia PukNgae (4):
      ALSA: usb-audio: rename QUIRK_FLAG_MIXER_MIN_MUTE to QUIRK_FLAG_MIXER_PLAYBACK_MIN_MUTE
      ALSA: usb-audio: add quirk QUIRK_FLAG_MIXER_CAPTURE_MIN_MUTE
      ALSA: usb-audio: apply "mixer_min_mute" quirks on some devices
      ALSA: usb-audio: apply quirk for MOONDROP Quark2

 Documentation/sound/alsa-configuration.rst |  1 +
 sound/usb/mixer.c                          |  7 +++++++
 sound/usb/mixer_quirks.c                   | 14 ++++++++++++--
 sound/usb/quirks.c                         | 24 ++++++++++++++----------
 sound/usb/usbaudio.h                       |  7 +++++--
 5 files changed, 39 insertions(+), 14 deletions(-)
---
base-commit: d414194eefc275bd17ad059baa23f2cd29c7d213
change-id: 20250902-sound-536a69e72a93

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

