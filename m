From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ 0/9] Distribution inspired fixes
Date: Wed, 24 Jan 2024 23:43:54 +0000
Message-Id: <20240124-disto-patches-v1-0-97e0eb5625a3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALqgsWUC/x3MQQqAIBBA0avErBN0EIOuEi1Kx5yNhSMRhHdPW
 r7F/y8IFSaBeXih0M3CZ+4w4wA+bfkgxaEbUKPVBq0KLPVU11Z9IlEUg9sndE5jhN5chSI//29
 ZW/sAvKb5lV8AAAA=
To: linux-bluetooth@vger.kernel.org
Cc: Vicki Pfau <vi@endrift.com>, 
 Rachel Blackman <rachel.blackman@synapse.com>, 
 Sam Lantinga <slouken@libsdl.org>, Bastien Nocera <hadess@hadess.net>, 
 Emil Velikov <emil.velikov@collabora.com>, 
 Nobuhiro Iwamatsu <iwamatsu@debian.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706139864; l=3925;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=AOOg0dl+uZW4GfWAD/DTVkausWiBx0RPHyv4va2otSk=;
 b=QY8O+HQf+nEZmTZ6m0rsjlXngZgOwgKMRBsgdGQqPhofE2MMMcy5tWzYmfmSgV5LTGW01I87l
 Ua5BRs6/01EA3fLAMGloaIvU6DIARcS6jWnstIEqo6P9paiZhxj5wfn
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello team,

This series picks (directly where possible) distro shipped fixes, for
upstream inclusion.

In particular we have:
 - first two patches have been in SteamOS 3 for about 1 year
 - adapter: Remove experimental flag for PowerState - has been shipping
   in Gentoo and Fedora since Dec 2022, at least
 - use /usr/bin/env python3 sheband - Debian inspired
 - remove unused suspend-dummy.c - Debian inspired
 - remove three unused obex plugins/backends - inspired by ^^ removal
 - ship all conf files with --enable-datafiles - Arch, Gentoo, Fedora

Everything apart from the first two, should be dead trivial. I have
little knowledge about the SteamOS inspired fixes, so hopefully
maintainers won't have too many questions there ;-)

As the comment in the last commit says - there's one final batch
(planned) of patches. Allowing for more flexible conf management, akin
to `man sysctl.d`.

Although I will send those out, once most of the existing patches have
landed.

---
Bastien Nocera (1):
      adapter: Remove experimental flag for PowerState

Emil Velikov (6):
      test: consistently use /usr/bin/env python3 shebang
      profiles: remove unused suspend-dummy.c
      obex: remove unused syncevolution plugin
      obex: remove unused mas/messages-tracker impl
      obex: remove phonebook tracker backend
      build: ship all config files with --enable-datafiles

Sam Lantinga (1):
      Return at least the title attribute from player_list_metadata()

Vicki Pfau (1):
      Enable alternate Bluetooth connection modes

 Makefile.am                       |    8 +-
 Makefile.mesh                     |    1 +
 Makefile.obexd                    |    3 +-
 Makefile.plugins                  |    2 -
 configure.ac                      |    6 +-
 obexd/plugins/messages-tracker.c  |  332 --------
 obexd/plugins/phonebook-tracker.c | 1704 -------------------------------------
 obexd/plugins/syncevolution.c     |  470 ----------
 profiles/audio/avrcp.c            |    4 +
 profiles/input/suspend-dummy.c    |  149 ----
 src/adapter.c                     |   49 +-
 src/btd.h                         |    2 +
 src/main.c                        |   66 ++
 src/main.conf                     |    5 +
 test/agent.py                     |    2 +-
 test/example-adv-monitor          |    2 +-
 test/example-advertisement        |    2 +-
 test/example-endpoint             |    2 +-
 test/example-player               |    2 +-
 test/exchange-business-cards      |    2 +-
 test/ftp-client                   |    2 +-
 test/get-managed-objects          |    2 +-
 test/get-obex-capabilities        |    2 +-
 test/list-devices                 |    2 +-
 test/list-folders                 |    2 +-
 test/map-client                   |    2 +-
 test/monitor-bluetooth            |    2 +-
 test/opp-client                   |    2 +-
 test/pbap-client                  |    2 +-
 test/simple-agent                 |    2 +-
 test/simple-endpoint              |    2 +-
 test/simple-obex-agent            |    2 +-
 test/simple-player                |    2 +-
 test/test-adapter                 |    2 +-
 test/test-device                  |    2 +-
 test/test-discovery               |    2 +-
 test/test-gatt-profile            |    2 +-
 test/test-health                  |    2 +-
 test/test-health-sink             |    2 +-
 test/test-hfp                     |    2 +-
 test/test-manager                 |    2 +-
 test/test-nap                     |    2 +-
 test/test-network                 |    2 +-
 test/test-profile                 |    2 +-
 test/test-sap-server              |    2 +-
 45 files changed, 167 insertions(+), 2696 deletions(-)
---
base-commit: a9d1f6f6a625607de6c3f5b7a40a3aac5f36c02b
change-id: 20240124-disto-patches-efd6b726602f

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

