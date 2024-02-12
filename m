From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ v2 00/10] Distribution inspired fixes
Date: Mon, 12 Feb 2024 20:02:36 +0000
Message-Id: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFx5ymUC/3WMyw6DIBBFf8XMujQ4VUy76n80LhAGmaQ+Aoa0M
 fx70X2X5+aes0OkwBThUe0QKHHkZS6AlwqM1/NIgm1hQImNrLERluO2iFVvxlMU5KwaOlRKooP
 irIEcf87eqy/sj3f4nvlUH+u/UqqFFPeOJA2twlbfnuOk+X01ywR9zvkHmWKHO6oAAAA=
To: linux-bluetooth@vger.kernel.org
Cc: Sam Lantinga <slouken@libsdl.org>, Bastien Nocera <hadess@hadess.net>, 
 Emil Velikov <emil.velikov@collabora.com>, 
 Nobuhiro Iwamatsu <iwamatsu@debian.org>, 
 Giovanni Campagna <gcampagna-cNUdlRotFMnNLxjTenLetw@public.gmane.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707768157; l=4885;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=lzfrFProzoQf+DY+OgPnU7nG2ioiHDSOCOxKL0Ukrxg=;
 b=CrbWyQcw0dqUXwwAGoNZG3Ns2RpQDC1i6x9nffdSB8LcqKKnWHB2w+Rkf6J59h4k5fA+2jFCn
 ShCyL1u8+mDCKteKRUUJBR4PCxHyMz2k7Zm4DhCXwdaORoARqV6Ba+E
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello team,

This is v2 of the earlier upstreaming effort, aiming to reduce and in
some cases patches carried by distributions.

Changes in v2:
 - dropped the first patch - no longer applicable with newer kernels
 - fixed bug in phonebook/tracker patch
 - added use glib helper for obex file handling - Gentoo, Debian
 - added obex dbus service w/o systemd - Gentoo, Debian, OpenWRT

In summary, as this series is merged here's the status across distros:
 - Arch - zero patches or hacks needed \o/
 - Gentoo - one hid2hci.rules patch outstanding
 - Fedora - zero patches \o/
 - Debian - some good (hid2hci.rules, typos) patches and some outdated
   (potential infinite loop, gatt PIN segfault) - @iwamatsu can you
   verify which patches are still applicable and send them upstream?
 - OpenWRT - handful of patches

Above said, Gentoo, Fedora, Debian and SteamOS will need more elaborate
config infra, as mentioned before. Patches for that will be sent out
soon (tm).

If you're curious about v1, please follow the link below.
- Link to v1: https://lore.kernel.org/r/20240124-disto-patches-v1-0-97e0eb5625a3@gmail.com

As always feedback is greatly appreciated o/

Thanks
Emil

---
Bastien Nocera (2):
      adapter: Remove experimental flag for PowerState
      obex: Use GLib helper function to manipulate paths

Emil Velikov (6):
      test: consistently use /usr/bin/env python3 shebang
      profiles: remove unused suspend-dummy.c
      obex: remove unused syncevolution plugin
      obex: remove unused mas/messages-tracker impl
      obex: remove phonebook tracker backend
      build: ship all config files with --enable-datafiles

Giovanni Campagna (1):
      Allow using obexd without systemd in the user session

Sam Lantinga (1):
      Return at least the title attribute from player_list_metadata()

 Makefile.am                                        |    8 +-
 Makefile.mesh                                      |    1 +
 Makefile.obexd                                     |    7 +-
 Makefile.plugins                                   |    2 -
 configure.ac                                       |    7 +-
 obexd/plugins/messages-tracker.c                   |  332 ----
 obexd/plugins/phonebook-tracker.c                  | 1704 --------------------
 obexd/plugins/syncevolution.c                      |  470 ------
 obexd/src/manager.c                                |   15 +-
 ...luez.obex.service => org.bluez.obex.service.in} |    2 +-
 profiles/audio/avrcp.c                             |    4 +
 profiles/input/suspend-dummy.c                     |  149 --
 src/adapter.c                                      |    3 +-
 test/agent.py                                      |    2 +-
 test/example-adv-monitor                           |    2 +-
 test/example-advertisement                         |    2 +-
 test/example-endpoint                              |    2 +-
 test/example-player                                |    2 +-
 test/exchange-business-cards                       |    2 +-
 test/ftp-client                                    |    2 +-
 test/get-managed-objects                           |    2 +-
 test/get-obex-capabilities                         |    2 +-
 test/list-devices                                  |    2 +-
 test/list-folders                                  |    2 +-
 test/map-client                                    |    2 +-
 test/monitor-bluetooth                             |    2 +-
 test/opp-client                                    |    2 +-
 test/pbap-client                                   |    2 +-
 test/simple-agent                                  |    2 +-
 test/simple-endpoint                               |    2 +-
 test/simple-obex-agent                             |    2 +-
 test/simple-player                                 |    2 +-
 test/test-adapter                                  |    2 +-
 test/test-device                                   |    2 +-
 test/test-discovery                                |    2 +-
 test/test-gatt-profile                             |    2 +-
 test/test-health                                   |    2 +-
 test/test-health-sink                              |    2 +-
 test/test-hfp                                      |    2 +-
 test/test-manager                                  |    2 +-
 test/test-nap                                      |    2 +-
 test/test-network                                  |    2 +-
 test/test-profile                                  |    2 +-
 test/test-sap-server                               |    2 +-
 44 files changed, 56 insertions(+), 2710 deletions(-)
---
base-commit: c1851987ca2c6e41d1e0e166e959b754e369c254
change-id: 20240124-disto-patches-efd6b726602f

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

