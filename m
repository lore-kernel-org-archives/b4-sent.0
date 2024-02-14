From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 14 Feb 2024 22:01:24 +0000
Subject: [PATCH BlueZ 1/4] build: fold separate install-data-hooks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240214-hook-fixup-v1-1-0e158ffea140@gmail.com>
References: <20240214-hook-fixup-v1-0-0e158ffea140@gmail.com>
In-Reply-To: <20240214-hook-fixup-v1-0-0e158ffea140@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707948093; l=1454;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=dtWLnKx4leNFwGkNegEX6jHOWak1uw7hhMJRp7odx88=;
 b=a15wcEhZlDXS2x+YnXiC6jYEavgqJFnrZQDLJJZaNx2A1aQgVDE21B6mzOsaAxBBERGk/zRTF
 xr2E1X5IsRQBzrWABWapgjToDBoLNY6FqtzU8AfQidxy0sFSnqhULTX
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Autoconfigure throws a useful error, that I've missed previously. As-is
with two identical hooks `make install` will fail.

Just fold them into single place - not particularly pretty but works.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 Makefile.am    | 9 +++++++++
 Makefile.obexd | 6 ------
 2 files changed, 9 insertions(+), 6 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index 5207c172b..e67551761 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -34,6 +34,15 @@ statedir = $(localstatedir)/lib/bluetooth
 install-data-hook:
 	install -dm555 $(DESTDIR)$(confdir)
 	install -dm700 $(DESTDIR)$(statedir)
+if OBEX
+if SYSTEMD
+	$(LN_S) -f obex.service $(DESTDIR)$(SYSTEMD_USERUNITDIR)/dbus-org.bluez.obex.service
+
+uninstall-hook:
+	rm -f $(DESTDIR)$(SYSTEMD_USERUNITDIR)/dbus-org.bluez.obex.service
+endif
+endif
+
 
 if DATAFILES
 dbusdir = $(DBUS_CONFDIR)/dbus-1/system.d
diff --git a/Makefile.obexd b/Makefile.obexd
index 81456544d..b91ca6644 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -2,12 +2,6 @@
 if SYSTEMD
 systemduserunitdir = $(SYSTEMD_USERUNITDIR)
 systemduserunit_DATA = obexd/src/obex.service
-
-install-data-hook:
-	$(LN_S) -f obex.service $(DESTDIR)$(SYSTEMD_USERUNITDIR)/dbus-org.bluez.obex.service
-
-uninstall-hook:
-	rm -f $(DESTDIR)$(SYSTEMD_USERUNITDIR)/dbus-org.bluez.obex.service
 endif
 
 dbussessionbusdir = $(DBUS_SESSIONBUSDIR)

-- 
2.43.1

