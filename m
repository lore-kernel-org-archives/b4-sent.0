From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 13:52:01 +0000
Subject: [PATCH BlueZ 07/10] build: remove explicit DEPENDENCIES handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-autofoo-v1-7-626f6b54bd06@gmail.com>
References: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
In-Reply-To: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413116; l=3024;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=gNLYCa6gQWMALTDx8zted1MgMRNVmkqOD1MZVczYw+8=;
 b=owCAWh6QAAMYL8ZcPObqTFrWy2kTp/oylq5lR8F/UIC2kNOB1RwhvFzRt8z3JrGIjtTtFcyGF
 YWLj5gEVEY7BbusNWW0ZJwyK/C9plSRVyiIUN4YlvTWw8EUueUNrck1
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
index 2be214631..6007f9eb7 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -77,7 +77,6 @@ lib_LTLIBRARIES += lib/libbluetooth.la
 
 lib_libbluetooth_la_SOURCES = $(lib_headers) $(lib_sources)
 lib_libbluetooth_la_LDFLAGS = $(AM_LDFLAGS) -version-info 22:12:19
-lib_libbluetooth_la_DEPENDENCIES = $(local_headers)
 endif
 
 noinst_LTLIBRARIES += lib/libbluetooth-internal.la
@@ -94,12 +93,10 @@ gdbus_libgdbus_internal_la_SOURCES = gdbus/gdbus.h \
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
@@ -333,10 +330,6 @@ src_bluetoothd_LDADD = lib/libbluetooth-internal.la \
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

