From: Ye He <ye.he@amlogic.com>
Subject: [PATCH bluez v5 0/3] EDITME: cover title for bearer-impl
Date: Tue, 25 Nov 2025 15:01:13 +0800
Message-Id: <20251125-bearer-impl-v5-0-ce1ce5ad19d9@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADlUJWkC/23OwQ6CMAwG4FcxOztDtxWGJ9/DeBhb0SXgyFCiE
 t7dhRMovbXN97cj6yl66tlxN7JIg+99uKcG9ztmb+Z+Je5d6pnIBEIqXpGJFLlvu4ZjXZAscyi
 UMSyJLlLtX3PamVXNkz7sksY33z9CfM83BpiXm3EDcOC1AtQISgnQJ9M24ertwYZ2ThrEUsu1F
 klbSVqgtXmBG1outV5rmbQzzjpdZbZA96/VQoufz1XSFQpQpatdafK1nqbpC5gsW1BpAQAA
X-Change-ID: 20251111-bearer-impl-5f7e396174aa
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764054092; l=2404;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=miEgGWZRDPhsPzkLHZ09UzDGtpVtzx+bCzb1bszgPuc=;
 b=1qT9tdfMYtI/X+wO47eLOpy8YkM/8wE34DSHoCBU1dQCRirhQXRoRl6MSNuK6+Y339I8oSP8b
 wY4PHSFoVSfCSWsYOSRTmTnPrbGq10MF0nTpDXaGRhP9n7JsqTgCMCt
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Ye He <ye.he@amlogic.com>
---
Changes in v5:
- Split adding bearer field to btd_profile into a standalone patch.
- Link to v4: https://patch.msgid.link/20251121-bearer-impl-v4-1-b52149dfd9a6@amlogic.com

Changes in v4:
- Add a bearer field to btd_profile to indicate which bearer type the profile
- belongs to, thus we can distinct the services per bearer.
- Link to v3: https://patch.msgid.link/20251118-bearer-impl-v3-1-dadcd8b0c75d@amlogic.com

Changes in v3:
- Move the modification logic from the device to bearer, and add
- some helper functions to the device.
- Link to v2: https://patch.msgid.link/20251113-bearer-impl-v2-1-c3e825cc6758@amlogic.com

Changes in v2:
- Fix build error & warning.
- Link to v1: https://patch.msgid.link/20251111-bearer-impl-v1-1-f41585144218@amlogic.com

---
Ye He (3):
      profiles: Add bearer field to btd_profile
      bearer: Implement Connect/Disconnect methods
      client: Add shell cmd for bearer connect/disconnect

 client/bluetoothctl.rst          |  34 ++++++++
 client/main.c                    | 141 +++++++++++++++++++++++++++++++++
 profiles/audio/a2dp.c            |   5 +-
 profiles/audio/asha.c            |   1 +
 profiles/audio/avrcp.c           |   2 +
 profiles/audio/bap.c             |   2 +
 profiles/audio/bass.c            |   1 +
 profiles/audio/ccp.c             |   1 +
 profiles/audio/csip.c            |   2 +
 profiles/audio/mcp.c             |   1 +
 profiles/audio/micp.c            |   1 +
 profiles/audio/vcp.c             |   1 +
 profiles/battery/battery.c       |   1 +
 profiles/deviceinfo/deviceinfo.c |   1 +
 profiles/gap/gas.c               |   1 +
 profiles/health/hdp_manager.c    |   2 +
 profiles/input/hog.c             |   1 +
 profiles/input/manager.c         |   1 +
 profiles/midi/midi.c             |   1 +
 profiles/network/manager.c       |   3 +
 profiles/scanparam/scan.c        |   1 +
 src/bearer.c                     | 166 ++++++++++++++++++++++++++++++++++++++-
 src/device.c                     | 128 +++++++++++++++++++++++++-----
 src/device.h                     |  17 ++++
 src/profile.h                    |  10 +++
 25 files changed, 501 insertions(+), 24 deletions(-)
---
base-commit: 5e41d1e1d361e7288964e4c2c5ed90736025662f
change-id: 20251111-bearer-impl-5f7e396174aa

Best regards,
-- 
Ye He <ye.he@amlogic.com>

