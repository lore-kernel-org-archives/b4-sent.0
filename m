From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 14 Feb 2024 22:01:25 +0000
Subject: [PATCH BlueZ 2/4] build: install obexd (dbus,systemd} services as
 needed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240214-hook-fixup-v1-2-0e158ffea140@gmail.com>
References: <20240214-hook-fixup-v1-0-0e158ffea140@gmail.com>
In-Reply-To: <20240214-hook-fixup-v1-0-0e158ffea140@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707948093; l=762;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=jk17tdzYCWPHANqvkVpH7To2uT5/ZyxPCpp1GyD4nKY=;
 b=pZTvANMpFnLl1VDWjSpTeH29E7c+oRJXeKsTUg4BsrVrOag1TFNLZQKHQ3vQIm6r4q+AKWa/R
 BKVMx4PZN1pDNpibQgtGNV9PuDjWHgzWbVazPO1YXc7sCYlFNeykiE7
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently we ship the service files, even when built with
--disable-obex.

Move the if OBEX guard few lines further up.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 Makefile.obexd | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/Makefile.obexd b/Makefile.obexd
index b91ca6644..4a89e0335 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -1,4 +1,6 @@
 # SPDX-License-Identifier: GPL-2.0
+if OBEX
+
 if SYSTEMD
 systemduserunitdir = $(SYSTEMD_USERUNITDIR)
 systemduserunit_DATA = obexd/src/obex.service
@@ -7,7 +9,6 @@ endif
 dbussessionbusdir = $(DBUS_SESSIONBUSDIR)
 dbussessionbus_DATA = obexd/src/org.bluez.obex.service
 
-if OBEX
 
 obex_plugindir = $(libdir)/obex/plugins
 

-- 
2.43.1

