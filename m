From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 13:52:00 +0000
Subject: [PATCH BlueZ 06/10] build: remove .service files from DEPENDENCIES
 lists
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-autofoo-v1-6-626f6b54bd06@gmail.com>
References: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
In-Reply-To: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413116; l=2006;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=DuGow5VEhfCAdhkTLDcYWkDA2anwlvRVmTKY2spMLAs=;
 b=stau6M2z0zUkfJnG32fvib7RtUs/Yv5GMyHxHncOVRZfCsBmsh+ZWsHzw9RgzVOwzMXdNPUdO
 1HvJeDY9c4xChBWIW/Q/ihAfLhuhk+irWPPRMByJGQwYFJE3ZTS3cxz
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
index 564f1b935..2be214631 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -335,8 +335,7 @@ src_bluetoothd_LDFLAGS = $(AM_LDFLAGS) -Wl,--export-dynamic \
 
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

