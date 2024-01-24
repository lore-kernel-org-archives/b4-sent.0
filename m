From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 24 Jan 2024 16:08:02 +0000
Subject: [PATCH BlueZ v2 6/8] bluetoothd: don't export internal API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240124-rm-ext-plugins-v2-6-5244906f05ff@gmail.com>
References: <20240124-rm-ext-plugins-v2-0-5244906f05ff@gmail.com>
In-Reply-To: <20240124-rm-ext-plugins-v2-0-5244906f05ff@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706112482; l=1034;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=oJMu/7JQ1+IQo+7iiJJvhOj5+NWG/IUCz9D6MPY+H5E=;
 b=fi+Ga2uBjswJhuLcwfqrNXKN4gTb6++ttuRLheLaIspBr3aooFyjWU9kCOzqEwtQoP8WX8ZYE
 +arFE/3cOj+ChkzgiGgPFjFvRZHWCAAZSk3f93RUlEYlkAbVP17v3Cf
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
index 1b82e8551..b98519e84 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -293,7 +293,6 @@ pkglibexec_PROGRAMS += src/bluetoothd
 
 src_bluetoothd_SOURCES = $(builtin_sources) \
 			$(attrib_sources) $(btio_sources) \
-			src/bluetooth.ver \
 			src/main.c src/log.h src/log.c \
 			src/backtrace.h src/backtrace.c \
 			src/rfkill.c src/btd.h src/sdpd.h \
@@ -325,8 +324,12 @@ src_bluetoothd_LDADD = lib/libbluetooth-internal.la \
 			src/libshared-glib.la \
 			$(BACKTRACE_LIBS) $(GLIB_LIBS) $(DBUS_LIBS) -ldl -lrt \
 			$(builtin_ldadd)
+
+if EXTERNAL_PLUGINS
+src_bluetoothd_SOURCES += src/bluetooth.ver
 src_bluetoothd_LDFLAGS = $(AM_LDFLAGS) -Wl,--export-dynamic \
 				-Wl,--version-script=$(srcdir)/src/bluetooth.ver
+endif
 
 src_bluetoothd_DEPENDENCIES = lib/libbluetooth-internal.la \
 				gdbus/libgdbus-internal.la \

-- 
2.43.0

