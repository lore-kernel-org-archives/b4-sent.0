From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 29 Jan 2024 14:44:20 +0000
Subject: [PATCH BlueZ v4 6/8] bluetoothd: don't export internal API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240129-rm-ext-plugins-v4-6-bfd1e08c7f99@gmail.com>
References: <20240129-rm-ext-plugins-v4-0-bfd1e08c7f99@gmail.com>
In-Reply-To: <20240129-rm-ext-plugins-v4-0-bfd1e08c7f99@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706539455; l=1054;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=IzZa7BlZN0VGepZt+klnK6SKKS7pzNjz9SN5DmTUpUs=;
 b=FkuQqYebrVC3b9/ftLnlmF9PMnQDHOMAKSIc87QoJM2RED78ClpGc+9WOTf1J3hgEvSBTs2FN
 l42ytNeTFhJBhAonQLcyM3MPlHnqgUP+OB2hBhw0ZzwHJbz4WKooeYZ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

... when building without external plugins.
---
 Makefile.am | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Makefile.am b/Makefile.am
index 2d5650ced..2b1b9acdf 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -289,7 +289,6 @@ pkglibexec_PROGRAMS += src/bluetoothd
 
 src_bluetoothd_SOURCES = $(builtin_sources) \
 			$(attrib_sources) $(btio_sources) \
-			src/bluetooth.ver \
 			src/main.c src/log.h src/log.c \
 			src/backtrace.h src/backtrace.c \
 			src/rfkill.c src/btd.h src/sdpd.h \
@@ -321,8 +320,12 @@ src_bluetoothd_LDADD = lib/libbluetooth-internal.la \
 			src/libshared-glib.la \
 			$(BACKTRACE_LIBS) $(GLIB_LIBS) $(DBUS_LIBS) -ldl -lrt \
 			$(builtin_ldadd)
+
+if EXTERNAL_PLUGINS
+src_bluetoothd_SOURCES += src/bluetooth.ver
 src_bluetoothd_LDFLAGS = $(AM_LDFLAGS) -Wl,--export-dynamic \
 				-Wl,--version-script=$(srcdir)/src/bluetooth.ver
+endif
 
 src_bluetoothd_CPPFLAGS = $(AM_CPPFLAGS) -DBLUETOOTH_PLUGIN_BUILTIN \
 					-DPLUGINDIR=\""$(build_plugindir)"\" \

-- 
2.43.0

