From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ v4 0/8] Remove support for external plugins
Date: Mon, 29 Jan 2024 14:44:14 +0000
Message-Id: <20240129-rm-ext-plugins-v4-0-bfd1e08c7f99@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL65t2UC/3XMSw6DIBSF4a0YxqW5XAFLR91H04EoKImvgDU2x
 r0XHZmaDs9Jvn8hwXhnArknC/FmcsH1XRz8kpCizrvKUFfGTRCQA2OS+paaeaRD865cF6jOQd8
 E5lyhJhEN3lg378HnK+7ahbH3n70/se39m5oYBSpRKbAaslSqR9XmrrkWfUu21IQHjvzEMXKBn
 CuQFoS1vzw9cnHiaeQl48xmtwy0lke+rusXo3zlNCoBAAA=
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706539455; l=1855;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=yeoFlTl9a/bqgLVxGb60Ke+4mr2ZgTSxsYBZYPeh9ZQ=;
 b=sPY/5c0BPa6VBrBUEtPGbDN87T622o2uippFPQTBrX4qFE2GvRhFWK1VMpoY1hJLwFoWrYR16
 +d6kX37R/sSDj1U/rNHpPEcPfnH2RCiGkKExQnrOTkkV2CTa7XOUpae
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello everyone,

With v4 we have moved from pre-processor to compilation checking for the
external plugins support.

Namely, as we build without one the dead-code elimination will discard
all the relevant code. Ultimately this means we compile check both paths
in order to catch mistakes. Thanks to Luiz for the suggestion.

Link to the previous revision can be found below.

Thanks
Emil

- Link to v3: https://lore.kernel.org/r/20240125-rm-ext-plugins-v3-0-d141f7870bb6@gmail.com

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
 Makefile.plugins         |   8 ++-
 README                   |  13 +++++
 android/Makefile.am      |   3 ++
 android/hal-audio.c      |   1 +
 android/hal-bluetooth.c  |   1 +
 android/hal-sco.c        |   1 +
 configure.ac             |  10 ++++
 obexd/src/obexd.h        |   2 +-
 obexd/src/plugin.c       |  89 ++++++++++++++++++++-----------
 obexd/src/plugin.h       |   4 ++
 plugins/external-dummy.c |  28 ----------
 src/btd.h                |   2 +-
 src/plugin.c             | 135 ++++++++++++++++++++++++++++-------------------
 src/plugin.h             |   4 ++
 16 files changed, 188 insertions(+), 132 deletions(-)
---
base-commit: 0de32f67f685b95c35a5c2f1206081af89bd88b6
change-id: 20240116-rm-ext-plugins-ba0b852a492b

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

