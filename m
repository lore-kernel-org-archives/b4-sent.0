From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 24 Jan 2024 16:20:08 +0000
Subject: [PATCH BlueZ v2 3/6] build: remove explicit DEPENDENCIES handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240124-autofoo-v2-3-a210f20aa2f7@gmail.com>
References: <20240124-autofoo-v2-0-a210f20aa2f7@gmail.com>
In-Reply-To: <20240124-autofoo-v2-0-a210f20aa2f7@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706113208; l=3025;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=JrsU9g6AXb7Bhq8yPPPYd9jsTdmPlc07IpOnB/yJWMM=;
 b=IrtjBrbiSLux8sKZ6n/4nwBPQXbLVvgZC+a4beFdcHcoKUAR2CQGVgayJXZ6OdbosaQa2zCso
 bN904k8oZ7KCbuOLpFpPwgqEjOyYLNEXXmzO5qc0KGEYf4yvQUKpxHJ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

We currently duplicate the DEPENDENCIES handling that autotools does for
us. We have two types of objects - libraries or generated headers.

Former are part of the LDADD, the latter in BUILT_SOURCES.
---
 Makefile.am    | 7 -------
 Makefile.mesh  | 1 -
 Makefile.tools | 2 --
 3 files changed, 10 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index be8f74f13..b913402b3 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -83,7 +83,6 @@ lib_LTLIBRARIES += lib/libbluetooth.la
 
 lib_libbluetooth_la_SOURCES = $(lib_headers) $(lib_sources)
 lib_libbluetooth_la_LDFLAGS = $(AM_LDFLAGS) -version-info 22:12:19
-lib_libbluetooth_la_DEPENDENCIES = $(local_headers)
 endif
 
 noinst_LTLIBRARIES += lib/libbluetooth-internal.la
@@ -100,12 +99,10 @@ gdbus_libgdbus_internal_la_SOURCES = gdbus/gdbus.h \
 if EXTERNAL_ELL
 ell_cflags = @ELL_CFLAGS@
 ell_ldadd = @ELL_LIBS@
-ell_dependencies =
 ell_built_sources = ell/shared
 else
 ell_cflags =
 ell_ldadd = ell/libell-internal.la
-ell_dependencies = $(ell_ldadd)
 ell_built_sources = ell/shared ell/internal ell/ell.h
 
 noinst_LTLIBRARIES += ell/libell-internal.la
@@ -339,10 +336,6 @@ src_bluetoothd_LDADD = lib/libbluetooth-internal.la \
 src_bluetoothd_LDFLAGS = $(AM_LDFLAGS) -Wl,--export-dynamic \
 				-Wl,--version-script=$(srcdir)/src/bluetooth.ver
 
-src_bluetoothd_DEPENDENCIES = lib/libbluetooth-internal.la \
-				gdbus/libgdbus-internal.la \
-				src/libshared-glib.la
-
 src_bluetoothd_CPPFLAGS = $(AM_CPPFLAGS) -DBLUETOOTH_PLUGIN_BUILTIN \
 					-DPLUGINDIR=\""$(build_plugindir)"\" \
 					$(BACKTRACE_CFLAGS) $(builtin_cppflags)
diff --git a/Makefile.mesh b/Makefile.mesh
index a66e47442..45fa90339 100644
--- a/Makefile.mesh
+++ b/Makefile.mesh
@@ -45,7 +45,6 @@ mesh/main.$(OBJEXT): src/builtin.h lib/bluetooth/bluetooth.h
 
 mesh_bluetooth_meshd_SOURCES = $(mesh_sources) mesh/main.c
 mesh_bluetooth_meshd_LDADD = src/libshared-ell.la $(ell_ldadd) -ljson-c
-mesh_bluetooth_meshd_DEPENDENCIES = $(ell_dependencies) src/libshared-ell.la
 
 if MANPAGES
 man_MANS += mesh/bluetooth-meshd.8
diff --git a/Makefile.tools b/Makefile.tools
index 6fda3f51d..1cde39f94 100644
--- a/Makefile.tools
+++ b/Makefile.tools
@@ -71,7 +71,6 @@ pkglibexec_PROGRAMS += tools/btmon-logger
 
 tools_btmon_logger_SOURCES = tools/btmon-logger.c
 tools_btmon_logger_LDADD = src/libshared-mainloop.la
-tools_btmon_logger_DEPENDENCIES = src/libshared-mainloop.la
 
 if SYSTEMD
 systemdsystemunit_DATA += tools/bluetooth-logger.service
@@ -577,7 +576,6 @@ noinst_PROGRAMS += tools/btpclient tools/btpclientctl
 tools_btpclient_SOURCES = tools/btpclient.c src/shared/btp.c src/shared/btp.h
 tools_btpclient_LDADD = lib/libbluetooth-internal.la \
 				src/libshared-ell.la $(ell_ldadd)
-tools_btpclient_DEPENDENCIES = lib/libbluetooth-internal.la $(ell_dependencies)
 tools/btpclient.$(OBJEXT): src/libshared-ell.la ell/internal
 
 tools_btpclientctl_SOURCES = tools/btpclientctl.c client/display.c

-- 
2.43.0

