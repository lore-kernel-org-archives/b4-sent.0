From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ 0/8] Remove support for external plugins
Date: Tue, 16 Jan 2024 14:18:52 +0000
Message-Id: <20240116-rm-ext-plugins-v1-0-62990fb07369@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEyQpmUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQ0Mz3aJc3dSKEt2CnNL0zLxi3aREgyQLU6NEE0ujJCWgpoKi1LTMCrC
 B0bG1tQC/918jYAAAAA==
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705414735; l=2389;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=ValMNeEzjaNVUq4zPdszRdqH2BBxxy2vm66NjDlh+I0=;
 b=XlxDf4fSBhWxhLEnpU3xJWnwkKGV+JzVZkh2mHVudXEAmepXHZr9q/KBKe9OLwi33Jp3Sujhj
 oDF1sfXtJCUBGOSDCEXUVsagukpsxpSr0SDIhY8UJ15pFp5V5ZQ+9ET
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Greetings one and all,

In this series, we prune support for external plugins and cleanup the
associated code. The inspiration here is multiple-fold:
 - the plugins are under linked - generally a bad idea
 - the plugins use undefined, unscoped, unversioned internal API
 - the main daemons expose their internal API increasing their size

So this series:
 - bluetoothd: removes the "dummy" external plugin
 - bluetoothd: converts the sixaxis plugin to builtin
 - bluetoothd, obexd: removes support for external plugins
 - bluetoothd, obexd: cleans the exported symbols by the daemons
 - android: (bonus) export only the required HMI plugin entrypoint

Please note:
 - expect minor conflicts wrt my earlier patches - happy to respin
 - there _might_ be third-party external plugins, that my distro search
   have missed

This concludes the paper cut patches. Expect some more around config
file handling in the upcoming days :-)

Thanks
Emil

---
Emil Velikov (8):
      obexd: remove support for external plugins
      build: don't export internal obexd API
      plugins: remove external-dummy
      plugins: convert external sixaxis plugin to builtin
      bluetoothd: remove support for external plugins
      bluetoothd: remove debug support for external plugins
      bluetoothd: don't export internal API
      android: export only (android) entrypoint from the modules

 Makefile.am              | 21 +-------------
 Makefile.obexd           |  8 ++----
 Makefile.plugins         |  8 ++----
 android/Makefile.am      |  3 ++
 android/hal-audio.c      |  1 +
 android/hal-bluetooth.c  |  1 +
 android/hal-sco.c        |  1 +
 obexd/src/obexd.h        |  2 +-
 obexd/src/plugin.c       | 73 ++++-------------------------------------------
 obexd/src/plugin.h       |  9 ------
 plugins/external-dummy.c | 28 ------------------
 src/bluetooth.ver        | 20 -------------
 src/btd.h                |  2 +-
 src/log.c                | 10 ++-----
 src/log.h                |  3 +-
 src/plugin.c             | 74 ++++--------------------------------------------
 src/plugin.h             | 16 -----------
 17 files changed, 30 insertions(+), 250 deletions(-)
---
base-commit: 770ad5614e7e8074133e6f563495ce4822f63fe4
change-id: 20240116-rm-ext-plugins-ba0b852a492b

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

