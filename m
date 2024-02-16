From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 16 Feb 2024 23:11:05 +0000
Subject: [PATCH BlueZ v2 01/10] build: rework {install-data,uninstall}-hook
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-hook-fixup-v2-1-a6b192d1a6ad@gmail.com>
References: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
In-Reply-To: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
To: linux-bluetooth@vger.kernel.org
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708125068; l=1944;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=2q2yJxfalsDM6IrAcp4cLj0XyQOzx84+xaZIWSPUpFo=;
 b=KIs0MYGpSZVZxqgp91M5Co68Xw66l/7yynsCkaB+9ik+QIZ6FafSLMQODc9deDgDUxvFX8XH2
 WOU3MgISlLZBIVLbg1FTDd12pjI47lCdi2wRWKFurEoPgAJ8s3767Gs
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently autoconfigure throws a useful error, about a duplicate
install-data-hook.

Address that by making the two target specific and pulling them as
dependencies.

We have to create empty ones otherwise dependency tracking and
resolution will fail.
---
 Makefile.am    |  5 ++++-
 Makefile.obexd | 10 ++++++++--
 2 files changed, 12 insertions(+), 3 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index 5207c172b..450e931c6 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -31,7 +31,7 @@ AM_LDFLAGS = $(MISC_LDFLAGS)
 confdir = $(sysconfdir)/bluetooth
 statedir = $(localstatedir)/lib/bluetooth
 
-install-data-hook:
+bluetoothd-fix-permissions:
 	install -dm555 $(DESTDIR)$(confdir)
 	install -dm700 $(DESTDIR)$(statedir)
 
@@ -422,6 +422,9 @@ include Makefile.obexd
 include android/Makefile.am
 include Makefile.mesh
 
+install-data-hook: bluetoothd-fix-permissions obexd-add-service-symlink
+uninstall-hook: obexd-remove-service-symlink
+
 if HID2HCI
 rulesdir = $(UDEV_DIR)/rules.d
 
diff --git a/Makefile.obexd b/Makefile.obexd
index 81456544d..0e8bc6de7 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -3,11 +3,14 @@ if SYSTEMD
 systemduserunitdir = $(SYSTEMD_USERUNITDIR)
 systemduserunit_DATA = obexd/src/obex.service
 
-install-data-hook:
+obexd-add-service-symlink:
 	$(LN_S) -f obex.service $(DESTDIR)$(SYSTEMD_USERUNITDIR)/dbus-org.bluez.obex.service
 
-uninstall-hook:
+obexd-remove-service-symlink:
 	rm -f $(DESTDIR)$(SYSTEMD_USERUNITDIR)/dbus-org.bluez.obex.service
+else
+obexd-add-service-symlink:
+obexd-remove-service-symlink:
 endif
 
 dbussessionbusdir = $(DBUS_SESSIONBUSDIR)
@@ -102,6 +105,9 @@ obexd_src_obexd_CPPFLAGS = $(AM_CPPFLAGS) $(GLIB_CFLAGS) $(DBUS_CFLAGS) \
 
 obexd_src_obexd_CFLAGS = $(AM_CFLAGS) -fPIC
 
+else
+obexd-add-service-symlink:
+obexd-remove-service-symlink:
 endif
 
 obexd_src_obexd_SHORTNAME = obexd

-- 
2.43.1

