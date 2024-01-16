From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ 00/10] Autotools papercuts, linker GC, symlink
 dbus-org.bluez.obex.service
Date: Tue, 16 Jan 2024 13:51:54 +0000
Message-Id: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPqJpmUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQ0Mz3cTSkvy0/HzdlCSjtFSjZHMDS1NDJaDqgqLUtMwKsEnRsbW1AOo
 5nHxZAAAA
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413116; l=2083;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=qMVrXkmg4Fgyp38JOJtFMNb6rJOsPj4pytAyiNylZ1o=;
 b=aPKfZIFRlWYuJQ804uFLlrxAfw6vtk+x4XgsaCJpxgCpJSlGb+6hrynUdQRU5ebgKvqj9f077
 MOcg01vDz7ODWjwOKYgjEkahKYylR2XZBx6nH+b4gKxlF3mE8zJCtsK
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello everyone,

While looking at our bluez package for the SteamDeck a handful of
paper cuts stood out. Here we tackle the build related ones - a couple
more series will be incoming shortly.

In a gist we have the following:
 - remove manual tracking of .services.in, DEPENDENCIES
 - remove unused variables
 - polish PKG_CHECK_MODULES handling
 - enable linker garbage collection
 - create a symlink to dbus-org.bluez.obex.service

The last change is slightly out of topic here, although since there's
a high chance of merge conflicts, I've added it here. Let me know if
you'd like it send out as separate series.

This is my first time diving into bluez, so any comments and input is
greatly appreciated.

Thanks
Emil

---
Emil Velikov (10):
      build: remove unused AM_CONDITIONAL
      build: tweak PKG_CHECK_MODULES calls
      build: require libudev 196, circa 2012
      build: remove dummy {conf,state}{dir,_DATA}
      build: remove unused variable builtin_nodist
      build: remove .service files from DEPENDENCIES lists
      build: remove explicit DEPENDENCIES handling
      build: manage .service.in files via configure.ac
      build: enable gc/dead code removal
      build: install dbus-org.bluez.obex.service symlink

 Makefile.am                       | 31 ++--------------
 Makefile.mesh                     |  7 +---
 Makefile.obexd                    | 10 ++++--
 Makefile.tools                    |  6 ----
 acinclude.m4                      |  2 ++
 configure.ac                      | 75 ++++++++++++---------------------------
 mesh/bluetooth-mesh.service.in    |  2 +-
 monitor/hwdb.c                    |  2 +-
 obexd/src/obex.service.in         |  2 +-
 src/bluetooth.service.in          |  2 +-
 src/oui.c                         |  2 +-
 tools/bluetooth-logger.service.in |  2 +-
 12 files changed, 43 insertions(+), 100 deletions(-)
---
base-commit: 770ad5614e7e8074133e6f563495ce4822f63fe4
change-id: 20240116-autofoo-db2fe2c70951

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

