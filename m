From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ v3 0/8] Remove support for external plugins
Date: Thu, 25 Jan 2024 00:07:25 +0000
Message-Id: <20240125-rm-ext-plugins-v3-0-d141f7870bb6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD2msWUC/3XMSw6CMBSF4a2Qjq25XEq1jtyHcdBiCzfhlRYbD
 GHvFkYkxuE5yfcvLFhPNrBbtjBvIwUa+jSKU8aqRve15fRKmyGggDyX3HfczhMf23dNfeBGg7m
 WqIVCwxIavXU078HHM+2GwjT4z96P+fb+TcWcA5eoFDgDl0Kqe91pas/V0LEtFfHAUfxwTLxEI
 RRIB6VzR76u6xfgaueE6wAAAA==
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706141247; l=1630;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=YPAuJR/p/8YBl67ki2/Jzj4r23FKOVbW0WP58ypVgAA=;
 b=HNArrLqxiC3iZPqkNKtXD9jGm1G0gvmackOIqOhzPqx/Jh3BHX0d+th3YagonYzGTfx8PSuGC
 K1hCQIhfwJNCt8+4x0bUabDVqb2hGvAx7JNaJ9ljYlqYh47vbFhkMiQ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello everyone,

Here's v3 fixing a small bug with the previous patches, which was
tripping the CI.

Link to the previous revision can be found below.

Thanks
Emil

- Link to v2: https://lore.kernel.org/r/20240124-rm-ext-plugins-v2-0-5244906f05ff@gmail.com

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
 src/plugin.c             | 140 +++++++++++++++++++++++++++++------------------
 src/plugin.h             |  16 ++++++
 16 files changed, 209 insertions(+), 132 deletions(-)
---
base-commit: a9d1f6f6a625607de6c3f5b7a40a3aac5f36c02b
change-id: 20240116-rm-ext-plugins-ba0b852a492b

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

