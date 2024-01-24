From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ v2 0/8] Remove support for external plugins
Date: Wed, 24 Jan 2024 16:07:56 +0000
Message-Id: <20240124-rm-ext-plugins-v2-0-5244906f05ff@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANw1sWUC/3XMQQ6CMBCF4auQWTumHREtK+9hWLRYYBKgpMUGQ
 3p3K3uX/0vet0Ownm2AutjB28iB3ZyDTgW0g557i/zKDSSoFFJW6Ce024rL+O55Dmi0MPcr6VK
 RgXxavO14O8Bnk3vgsDr/Ofwof+tfKkoUWJFSojPidqnUo580j+fWTdCklL6bZ16lrAAAAA==
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706112482; l=1947;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=R3HFcVBoJszTJuASrnzBJqv6UFv6WlatH6rNlebl+0Y=;
 b=+sNzy8QaySNon+vpbiLaXjePBK3GYevtafRdkPxnZ6ZklOjHpWz3++HIfJ7dDv4Ca4wWwwKpc
 BJHZTBqI6wWDTh+4e53BB5TTaMwlzUIYWPK390ZWMVidwIFP6VtF3GF
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Greetings one and all,

This is v2 of my earlier series.

In v1 support for external plugins was completely removed, while now it
is preserved but compiled out by default.

An extra --enable-external-plugins is introduced alongside a note in the
README and a one-off runtime warning. The latter two pointing people
towards integrating their plugin into the upstream BlueZ repo.

For more details, see the link below to the original v1 cover letter and
patches.

Thanks
Emil

- Link to v1: https://lore.kernel.org/r/20240116-rm-ext-plugins-v1-0-62990fb07369@gmail.com

---
Emil Velikov (8):
      configure, README: introduce --enable-external-plugins
      obexd: factor out external plugin support
      bluetoothd: remove external-dummy plugin
      bluetoothd: convert external sixaxis plugin to builtin
      bluetoothd: factor out external plugin support
      bluetoothd: don't export internal API
      bluetoothd: change plugin loading alike obexd
      android: export only (android) entrypoint from the modules

 Makefile.am              |  17 ++----
 Makefile.obexd           |   2 +
 Makefile.plugins         |   8 +--
 README                   |  13 +++++
 android/Makefile.am      |   3 +
 android/hal-audio.c      |   1 +
 android/hal-bluetooth.c  |   1 +
 android/hal-sco.c        |   1 +
 configure.ac             |  10 ++++
 obexd/src/obexd.h        |   2 +-
 obexd/src/plugin.c       |  93 +++++++++++++++++++++----------
 obexd/src/plugin.h       |   4 ++
 plugins/external-dummy.c |  28 ----------
 src/btd.h                |   2 +-
 src/plugin.c             | 139 +++++++++++++++++++++++++++++------------------
 src/plugin.h             |  16 ++++++
 16 files changed, 208 insertions(+), 132 deletions(-)
---
base-commit: a9d1f6f6a625607de6c3f5b7a40a3aac5f36c02b
change-id: 20240116-rm-ext-plugins-ba0b852a492b

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

