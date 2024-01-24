From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 24 Jan 2024 16:20:07 +0000
Subject: [PATCH BlueZ v2 2/6] build: remove .service files from
 DEPENDENCIES lists
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240124-autofoo-v2-2-a210f20aa2f7@gmail.com>
References: <20240124-autofoo-v2-0-a210f20aa2f7@gmail.com>
In-Reply-To: <20240124-autofoo-v2-0-a210f20aa2f7@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706113208; l=2006;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=762dq8m5AI+SZ17OHCwzsFezHIwdX+iiIO34RX2fr1g=;
 b=QbQo9uv7Uea+Clh7WUkyIBen1bVqzha3q0ywR4wKCHPMWufsnwXG+5yG7ByVS6r36eyWk96nH
 zMvaoRzSukFASyXiM2dluABIG3MVG+yinOESxQhex/5T7yY2wPKhCs8
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

The DEPENDENCES lists are for binary objects, while the service files
are required by systemd (et al) after the install stage. The services
files are referenced by _DATA, so the service.in -> service conversion
can happen then.
---
 Makefile.am    | 3 +--
 Makefile.mesh  | 3 +--
 Makefile.tools | 3 +--
 3 files changed, 3 insertions(+), 6 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index a470e40cf..be8f74f13 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -341,8 +341,7 @@ src_bluetoothd_LDFLAGS = $(AM_LDFLAGS) -Wl,--export-dynamic \
 
 src_bluetoothd_DEPENDENCIES = lib/libbluetooth-internal.la \
 				gdbus/libgdbus-internal.la \
-				src/libshared-glib.la \
-				src/bluetooth.service
+				src/libshared-glib.la
 
 src_bluetoothd_CPPFLAGS = $(AM_CPPFLAGS) -DBLUETOOTH_PLUGIN_BUILTIN \
 					-DPLUGINDIR=\""$(build_plugindir)"\" \
diff --git a/Makefile.mesh b/Makefile.mesh
index 63f085de1..a66e47442 100644
--- a/Makefile.mesh
+++ b/Makefile.mesh
@@ -45,8 +45,7 @@ mesh/main.$(OBJEXT): src/builtin.h lib/bluetooth/bluetooth.h
 
 mesh_bluetooth_meshd_SOURCES = $(mesh_sources) mesh/main.c
 mesh_bluetooth_meshd_LDADD = src/libshared-ell.la $(ell_ldadd) -ljson-c
-mesh_bluetooth_meshd_DEPENDENCIES = $(ell_dependencies) src/libshared-ell.la \
-				mesh/bluetooth-mesh.service
+mesh_bluetooth_meshd_DEPENDENCIES = $(ell_dependencies) src/libshared-ell.la
 
 if MANPAGES
 man_MANS += mesh/bluetooth-meshd.8
diff --git a/Makefile.tools b/Makefile.tools
index e541084e9..6fda3f51d 100644
--- a/Makefile.tools
+++ b/Makefile.tools
@@ -71,8 +71,7 @@ pkglibexec_PROGRAMS += tools/btmon-logger
 
 tools_btmon_logger_SOURCES = tools/btmon-logger.c
 tools_btmon_logger_LDADD = src/libshared-mainloop.la
-tools_btmon_logger_DEPENDENCIES = src/libshared-mainloop.la \
-					tools/bluetooth-logger.service
+tools_btmon_logger_DEPENDENCIES = src/libshared-mainloop.la
 
 if SYSTEMD
 systemdsystemunit_DATA += tools/bluetooth-logger.service

-- 
2.43.0

