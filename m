From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 20:02:46 +0000
Subject: [PATCH BlueZ v2 10/10] Allow using obexd without systemd in the
 user session
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-disto-patches-v2-10-8bab1bd08f4d@gmail.com>
References: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
In-Reply-To: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Giovanni Campagna <gcampagna-cNUdlRotFMnNLxjTenLetw@public.gmane.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707768157; l=2136;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=qcOLWrp/zFE+VyNJF7l0mQSwvOHD0sHm7hQeD6mJ4p0=;
 b=rYipQQQoYBBKWJFCC4K7udhkanjCpN2+07thPENzUcgBhRU5BUTR/5vfKrY1ar12U8rlU3nhq
 z6nLK6nxg1eBkKbfhKMUWhe+JJOP/fGUr426X5ynFZJBomzeWigKJaD
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Giovanni Campagna <gcampagna-cNUdlRotFMnNLxjTenLetw@public.gmane.org>

Not all sessions run systemd --user and in some cases one may be missing
systemd all together.

Provide the correct path instead of /bin/false, allowing dbus to start
the service in such cases.

DBUS implementations can ignore the Exec line all together when run in
systemd aware mode - at least the OG dbus does that. So ultimately this
change is a no-op for the systemd --user case.

On my system, this is literally the only non-system service which uses
/bin/false.

[Emil Velikov]
Port to AC_CONFIG_FILES() .in files handling. Reword commit message.
---
 Makefile.obexd                                                  | 4 +---
 configure.ac                                                    | 1 +
 obexd/src/{org.bluez.obex.service => org.bluez.obex.service.in} | 2 +-
 3 files changed, 3 insertions(+), 4 deletions(-)

diff --git a/Makefile.obexd b/Makefile.obexd
index 1d37a1bd4..d88708e66 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -8,12 +8,10 @@ install-data-hook:
 
 uninstall-hook:
 	rm -f $(DESTDIR)$(SYSTEMD_USERUNITDIR)/dbus-org.bluez.obex.service
+endif
 
 dbussessionbusdir = $(DBUS_SESSIONBUSDIR)
 dbussessionbus_DATA = obexd/src/org.bluez.obex.service
-endif
-
-EXTRA_DIST += obexd/src/org.bluez.obex.service
 
 if OBEX
 
diff --git a/configure.ac b/configure.ac
index 387db8c7d..c66991a3d 100644
--- a/configure.ac
+++ b/configure.ac
@@ -457,6 +457,7 @@ AC_CONFIG_FILES(
 	mesh/bluetooth-meshd.rst
 	mesh/bluetooth-mesh.service
 	obexd/src/obex.service
+	obexd/src/org.bluez.obex.service
 	src/bluetoothd.rst
 	src/bluetooth.service
 	tools/bluetooth-logger.service
diff --git a/obexd/src/org.bluez.obex.service b/obexd/src/org.bluez.obex.service.in
similarity index 69%
rename from obexd/src/org.bluez.obex.service
rename to obexd/src/org.bluez.obex.service.in
index a53808884..14c16d3e3 100644
--- a/obexd/src/org.bluez.obex.service
+++ b/obexd/src/org.bluez.obex.service.in
@@ -1,4 +1,4 @@
 [D-BUS Service]
 Name=org.bluez.obex
-Exec=/bin/false
+Exec=@exec_prefix@/bluetooth/obexd
 SystemdService=dbus-org.bluez.obex.service

-- 
2.43.0

