From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 24 Jan 2024 16:20:11 +0000
Subject: [PATCH BlueZ v2 6/6] build: install dbus-org.bluez.obex.service
 symlink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240124-autofoo-v2-6-a210f20aa2f7@gmail.com>
References: <20240124-autofoo-v2-0-a210f20aa2f7@gmail.com>
In-Reply-To: <20240124-autofoo-v2-0-a210f20aa2f7@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706113208; l=1158;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=fbR9nv2+W1T7EdTJDnrPWv8eu5ZYYznbyAyGjdmqMMc=;
 b=7+IjkrXQNVb3h8u9JdTKomQWY65njHFNRhxiSfCXMEb9MH4lByR/ro5trZ7/qXHQNwobV8mgv
 whH7cqBNPwDD61XkF7Qbyi0W0r02hhgD0AdniwJZRExIP8P87EIhhZI
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

obex.service has an alias(dbus-org.bluez.obex.service) which is created
as it's enabled. At the same time, the dbus service references the alias
itself.

Thus the dbus socket activation can happen, only when the service is
already enabled/running... Which defeats the whole purpose.

Create/install the respective symlink/alias, so that any user looking
for the dbus will start it.

Note: we need a hook here instead of LN_S to create the in-tree file,
since `install' aggressively dereferences it.
---
 Makefile.obexd | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Makefile.obexd b/Makefile.obexd
index c2b5c6d7a..363295d0e 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -3,6 +3,12 @@ if SYSTEMD
 systemduserunitdir = $(SYSTEMD_USERUNITDIR)
 systemduserunit_DATA = obexd/src/obex.service
 
+install-data-hook:
+	$(LN_S) -f obex.service $(DESTDIR)$(SYSTEMD_USERUNITDIR)/dbus-org.bluez.obex.service
+
+uninstall-hook:
+	rm -f $(DESTDIR)$(SYSTEMD_USERUNITDIR)/dbus-org.bluez.obex.service
+
 dbussessionbusdir = $(DBUS_SESSIONBUSDIR)
 dbussessionbus_DATA = obexd/src/org.bluez.obex.service
 endif

-- 
2.43.0

