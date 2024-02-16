From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 16 Feb 2024 23:11:06 +0000
Subject: [PATCH BlueZ v2 02/10] build: install obexd (dbus,systemd}
 services as needed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-hook-fixup-v2-2-a6b192d1a6ad@gmail.com>
References: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
In-Reply-To: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
To: linux-bluetooth@vger.kernel.org
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708125068; l=708;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=ydMrW4KQq1RxtsNE5Z3GD8gOdVpX/eInfAQOzvCNhPM=;
 b=IrYvb1KVOghrustydreRo3bmyf2og6elMhJBTvp+Y0TbzI7qTGuQPiB0b1hSXzDQHXXSxnBXQ
 K2QeywgpuavAtAGEmgRUGM7CedeeoFoKeaQl+LP4GwYSBJfYVcujLMP
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently we ship the service files, even when built with
--disable-obex.

Move the "if OBEX" guard few lines further up.
---
 Makefile.obexd | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/Makefile.obexd b/Makefile.obexd
index 0e8bc6de7..e8e4a6144 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -1,4 +1,6 @@
 # SPDX-License-Identifier: GPL-2.0
+if OBEX
+
 if SYSTEMD
 systemduserunitdir = $(SYSTEMD_USERUNITDIR)
 systemduserunit_DATA = obexd/src/obex.service
@@ -16,7 +18,6 @@ endif
 dbussessionbusdir = $(DBUS_SESSIONBUSDIR)
 dbussessionbus_DATA = obexd/src/org.bluez.obex.service
 
-if OBEX
 
 obex_plugindir = $(libdir)/obex/plugins
 

-- 
2.43.1

