From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 29 Jan 2024 14:44:17 +0000
Subject: [PATCH BlueZ v4 3/8] bluetoothd: remove external-dummy plugin
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240129-rm-ext-plugins-v4-3-bfd1e08c7f99@gmail.com>
References: <20240129-rm-ext-plugins-v4-0-bfd1e08c7f99@gmail.com>
In-Reply-To: <20240129-rm-ext-plugins-v4-0-bfd1e08c7f99@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706539455; l=1499;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=Qkz58Z8cPMkE6Ps/NGmx2S8bmRGDQE2Anw+Id8KSNeI=;
 b=80WqH9lZJW+58Gc8dcVjtF+auOhXuPiXyTvdcxmGnkuuWl6QuaghsRHkdZ0Ph6AYI9i5Ey+0Z
 5JYEfcrBOAMALIC1hmXRR3m12ZZy2KeS9AyoWpk2N7gqoetO9I6izGG
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

The external plugins infra is getting deprecated and disabled by
default. Remove this dummy plugin.
---
 Makefile.am              |  8 --------
 plugins/external-dummy.c | 28 ----------------------------
 2 files changed, 36 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index 59603a0b7..9e35d7fd9 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -289,14 +289,6 @@ builtin_ldadd =
 
 include Makefile.plugins
 
-if MAINTAINER_MODE
-plugin_LTLIBRARIES += plugins/external-dummy.la
-plugins_external_dummy_la_SOURCES = plugins/external-dummy.c
-plugins_external_dummy_la_LDFLAGS = $(AM_LDFLAGS) -module -avoid-version \
-				    -no-undefined
-plugins_external_dummy_la_CFLAGS = $(AM_CFLAGS) -fvisibility=hidden
-endif
-
 pkglibexec_PROGRAMS += src/bluetoothd
 
 src_bluetoothd_SOURCES = $(builtin_sources) \
diff --git a/plugins/external-dummy.c b/plugins/external-dummy.c
deleted file mode 100644
index 1c209e8b7..000000000
--- a/plugins/external-dummy.c
+++ /dev/null
@@ -1,28 +0,0 @@
-// SPDX-License-Identifier: GPL-2.0-or-later
-/*
- *
- *  BlueZ - Bluetooth protocol stack for Linux
- *
- */
-
-#ifdef HAVE_CONFIG_H
-#include <config.h>
-#endif
-
-#include "src/plugin.h"
-#include "src/log.h"
-
-static int dummy_init(void)
-{
-	DBG("");
-
-	return 0;
-}
-
-static void dummy_exit(void)
-{
-	DBG("");
-}
-
-BLUETOOTH_PLUGIN_DEFINE(external_dummy, VERSION,
-		BLUETOOTH_PLUGIN_PRIORITY_LOW, dummy_init, dummy_exit)

-- 
2.43.0

