From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 20:02:40 +0000
Subject: [PATCH BlueZ v2 04/10] profiles: remove unused suspend-dummy.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-disto-patches-v2-4-8bab1bd08f4d@gmail.com>
References: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
In-Reply-To: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>, 
 Nobuhiro Iwamatsu <iwamatsu@debian.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707768157; l=4509;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=O5urzcyyiP0SFKs5VIgx4wp/q8Y+jAMqWGPzk079OjY=;
 b=Uru47TI0PMzfQvm0Ttb61J+M5i54qWShbtOynQf7AixSdF6TK/Gs8ZP3KxsTV8XSjdylWK0B2
 G4haOgSVxLmBZhC9T3KYvCT8EkUBRsRo2cpdk3YzfDKQx1gHev/MLiQ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

The file has been used for about 8 years now - see commit
fb55b7a6ab48c4f782b16030e051029bcfa93e07 ("profiles/hog: Use no suspend
support instead of the dummy FIFO").

Inspired by a Debian patch by Nobuhiro Iwamatsu, which was changing the
/tmp/hogsuspend socket patch to /run. Looking through the codebase we
have a few more sockets that could use a to /run fix, but that will
follow-up at another day.

Cc: Nobuhiro Iwamatsu <iwamatsu@debian.org>
---
 Makefile.plugins               |   2 -
 profiles/input/suspend-dummy.c | 149 -----------------------------------------
 2 files changed, 151 deletions(-)

diff --git a/Makefile.plugins b/Makefile.plugins
index 7cf66fd59..e960eedea 100644
--- a/Makefile.plugins
+++ b/Makefile.plugins
@@ -74,8 +74,6 @@ builtin_sources += profiles/input/hog.c \
 			profiles/battery/bas.c profiles/battery/bas.h \
 			profiles/scanparam/scpp.c profiles/scanparam/scpp.h \
 			profiles/input/suspend.h profiles/input/suspend-none.c
-
-EXTRA_DIST += profiles/input/suspend-dummy.c
 endif
 
 if HEALTH
diff --git a/profiles/input/suspend-dummy.c b/profiles/input/suspend-dummy.c
deleted file mode 100644
index ea1835e0f..000000000
--- a/profiles/input/suspend-dummy.c
+++ /dev/null
@@ -1,149 +0,0 @@
-// SPDX-License-Identifier: GPL-2.0-or-later
-/*
- *
- *  BlueZ - Bluetooth protocol stack for Linux
- *
- *  Copyright (C) 2012  Nordic Semiconductor Inc.
- *  Copyright (C) 2012  Instituto Nokia de Tecnologia - INdT
- *
- *
- */
-
-#ifdef HAVE_CONFIG_H
-#include <config.h>
-#endif
-
-#include <errno.h>
-#include <stdlib.h>
-#include <stdio.h>
-#include <string.h>
-#include <sys/types.h>
-#include <sys/stat.h>
-#include <fcntl.h>
-#include <unistd.h>
-
-#include <glib.h>
-
-#include "src/log.h"
-#include "suspend.h"
-
-#define HOG_SUSPEND_FIFO	"/tmp/hogsuspend"
-
-static suspend_event suspend_cb = NULL;
-static resume_event resume_cb = NULL;
-static guint watch = 0;
-
-static int fifo_open(void);
-
-static gboolean read_fifo(GIOChannel *io, GIOCondition cond, gpointer user_data)
-{
-	char buffer[12];
-	gsize offset, left, bread;
-	GIOStatus iostatus;
-
-	if (cond & (G_IO_ERR | G_IO_HUP)) {
-		/*
-		 * Both ends needs to be open simultaneously before proceeding
-		 * any input or output operation. When the remote closes the
-		 * channel, hup signal is received on this end.
-		 */
-		fifo_open();
-		return FALSE;
-	}
-
-	offset = 0;
-	left = sizeof(buffer) - 1;
-	memset(buffer, 0, sizeof(buffer));
-
-	do {
-		iostatus = g_io_channel_read_chars(io, &buffer[offset], left,
-								&bread, NULL);
-
-		offset += bread;
-		left -= bread;
-		if (left == 0)
-			break;
-	} while (iostatus == G_IO_STATUS_NORMAL);
-
-	if (g_ascii_strncasecmp("suspend", buffer, 7) == 0)
-		suspend_cb();
-	else if (g_ascii_strncasecmp("resume", buffer, 6) == 0)
-		resume_cb();
-
-	return TRUE;
-}
-
-static int fifo_open(void)
-{
-	GIOCondition condition = G_IO_IN | G_IO_ERR | G_IO_HUP;
-	GIOChannel *fifoio;
-	int fd;
-
-	fd = open(HOG_SUSPEND_FIFO, O_RDONLY | O_NONBLOCK);
-	if (fd < 0) {
-		int err = -errno;
-		error("Can't open FIFO (%s): %s(%d)", HOG_SUSPEND_FIFO,
-							strerror(-err), -err);
-		return err;
-	}
-
-	fifoio = g_io_channel_unix_new(fd);
-	g_io_channel_set_close_on_unref(fifoio, TRUE);
-
-	watch = g_io_add_watch(fifoio, condition, read_fifo, NULL);
-
-	g_io_channel_unref(fifoio);
-
-	return 0;
-}
-
-int suspend_init(suspend_event suspend, resume_event resume)
-{
-	struct stat st;
-	int ret;
-
-	DBG("");
-
-	suspend_cb = suspend;
-	resume_cb = resume;
-
-	if (stat(HOG_SUSPEND_FIFO, &st) == 0) {
-		if (!S_ISFIFO(st.st_mode)) {
-			error("Unexpected non-FIFO %s file", HOG_SUSPEND_FIFO);
-			return -EIO;
-		}
-
-		if (unlink(HOG_SUSPEND_FIFO) < 0) {
-			int err = -errno;
-			error("Failed to remove FIFO (%s): %s (%d)",
-				HOG_SUSPEND_FIFO, strerror(-err), -err);
-			return err;
-		}
-	}
-
-	if (mkfifo(HOG_SUSPEND_FIFO, 0600) < 0) {
-		int err = -errno;
-
-		error("Can't create FIFO (%s): %s (%d)", HOG_SUSPEND_FIFO,
-							strerror(-err), -err);
-		return err;
-	}
-
-	DBG("Created suspend-dummy FIFO on %s", HOG_SUSPEND_FIFO);
-
-	ret = fifo_open();
-	if (ret < 0)
-		unlink(HOG_SUSPEND_FIFO);
-
-	return ret;
-}
-
-void suspend_exit(void)
-{
-	if (watch > 0) {
-		g_source_remove(watch);
-		watch = 0;
-	}
-
-	unlink(HOG_SUSPEND_FIFO);
-}

-- 
2.43.0

