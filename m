From: Ye He <ye.he@amlogic.com>
Subject: [PATCH bluez v8 0/3] Add implementation of bearer
 connect/disconnect
Date: Mon, 01 Dec 2025 16:28:46 +0800
Message-Id: <20251201-bearer-impl-v8-0-f944b6f9f201@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL5RLWkC/23OO27DMAwG4KsEmqvClEU9MvUeRQc9qESAEwd2a
 7QNfPcKnqTa3Eji+8knm2nKNLPz6ckmWvKcx3tpzMuJhau7X4jnWHomOoFQintyE0083x4Dx6S
 ptwq0dI4V8Zgo5e8t7Z354Yt+2UcZX/P8OU4/240FtuVh3AIceJKABkFKAebN3YbxksNrGG9b0
 iJq3bdaFB16MgJDUBoPdF9r0+q+6OhiiMZ3QWPca1lp8e9zWbRHAdLGFK1Te421xlYj73ggCIQ
 ugo12r1WtVatV0WT7FCUk6PzBbV1r3WpdtHXoOyWVsVa0el3XP+HYorwjAgAA
X-Change-ID: 20251111-bearer-impl-5f7e396174aa
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764577754; l=2960;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=gojczjdGg8Ba7aMMdmOkpYQORBRW0YZVYBH19D4Siso=;
 b=A0q0Kp307ZAWq4cpjF03s+Ff6rhHVrui62jlClIWNID5Rdjkc6Nunm3O6/QeIc8ig39tZ8qIr
 6uP5GGMsKV3BlOExh4FfGDKtSo7qGYRlVF1hvsvuxECT4FA9fK9vtb6
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Ye He <ye.he@amlogic.com>
---
Changes in v8:
- Add le & bredr as sub-menus.
- Link to v7: https://patch.msgid.link/20251127-bearer-impl-v7-0-9a5b06468992@amlogic.com

Changes in v7:
- Specify the bearer type explicitly in the shell command, instead of passing
- it as a parameter.
- Link to v6: https://patch.msgid.link/20251126-bearer-impl-v6-0-e93fd41f10b6@amlogic.com

Changes in v6:
- Fix coding style warnings.
- Link to v5: https://patch.msgid.link/20251125-bearer-impl-v5-0-ce1ce5ad19d9@amlogic.com

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

 client/bluetoothctl-bredr.rst    |  70 +++++++++
 client/bluetoothctl-le.rst       |  71 +++++++++
 client/bluetoothctl.rst          |  10 ++
 client/main.c                    | 324 +++++++++++++++++++++++++++++++++++++++
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
 src/bearer.c                     | 167 +++++++++++++++++++-
 src/device.c                     | 129 +++++++++++++---
 src/device.h                     |  17 ++
 src/profile.h                    |  10 ++
 27 files changed, 803 insertions(+), 24 deletions(-)
---
base-commit: 5e41d1e1d361e7288964e4c2c5ed90736025662f
change-id: 20251111-bearer-impl-5f7e396174aa

Best regards,
-- 
Ye He <ye.he@amlogic.com>

