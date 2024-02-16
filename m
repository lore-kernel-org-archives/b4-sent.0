From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 16 Feb 2024 23:11:14 +0000
Subject: [PATCH BlueZ v2 10/10] build: move public headers to sub-folder
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-hook-fixup-v2-10-a6b192d1a6ad@gmail.com>
References: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
In-Reply-To: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708125069; l=112410;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=PPiZlL2lz7QA3teqHXww06Y7CQvNMWpg2OlOuBXY+SQ=;
 b=mrpy6WcXAeOmyDRCKJoTue1IBLN2sooRv17Cxi+UZfZIGUB4l316RsMchvNOrda8JcCpSGCz0
 0nRdSeW9kZVAQXRClMBBlyiTf/onz0nhaJgX9gOgjoCsNnb9aF9wyk8
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This allows us to remove the build-time hacks, while also being clearer
which headers are local and which are installed.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 .gitignore                       |  1 -
 Makefile.am                      | 28 ++++++++++++++--------------
 Makefile.mesh                    |  2 +-
 android/a2dp-sink.c              |  2 +-
 android/a2dp.c                   |  6 +++---
 android/avctp.c                  |  2 +-
 android/avdtp.c                  |  2 +-
 android/avdtptest.c              |  6 +++---
 android/avrcp-lib.c              |  2 +-
 android/avrcp.c                  |  6 +++---
 android/bluetooth.c              |  8 ++++----
 android/bluetoothd-snoop.c       |  4 ++--
 android/gatt.c                   |  4 ++--
 android/handsfree-client.c       |  6 +++---
 android/handsfree.c              |  6 +++---
 android/health.c                 |  8 ++++----
 android/hidhost.c                |  6 +++---
 android/ipc-tester.c             |  2 +-
 android/main.c                   |  4 ++--
 android/map-client.c             |  6 +++---
 android/pan.c                    |  8 ++++----
 android/sco.c                    |  2 +-
 android/socket.c                 |  6 +++---
 android/tester-a2dp.c            |  2 +-
 android/tester-avrcp.c           |  2 +-
 android/tester-gatt.c            |  2 +-
 android/tester-hdp.c             |  2 +-
 android/tester-hidhost.c         |  2 +-
 android/tester-main.c            |  2 +-
 android/tester-pan.c             |  2 +-
 attrib/att.c                     |  2 +-
 attrib/gatt.c                    |  4 ++--
 attrib/gattrib.c                 |  2 +-
 attrib/gatttool.c                |  8 ++++----
 attrib/interactive.c             |  4 ++--
 attrib/utils.c                   |  8 ++++----
 btio/btio.c                      |  8 ++++----
 client/mgmt.c                    | 10 +++++-----
 client/player.c                  |  2 +-
 emulator/amp.c                   |  4 ++--
 emulator/b1ee.c                  |  4 ++--
 emulator/btdev.c                 |  4 ++--
 emulator/bthost.c                |  2 +-
 emulator/bthost.h                |  2 +-
 emulator/hciemu.c                |  4 ++--
 emulator/le.c                    |  4 ++--
 emulator/serial.c                |  4 ++--
 emulator/server.c                |  4 ++--
 emulator/smp.c                   |  4 ++--
 emulator/vhci.c                  |  4 ++--
 lib/bluetooth.c                  |  4 ++--
 lib/{ => bluetooth}/bluetooth.h  |  0
 lib/{ => bluetooth}/bnep.h       |  0
 lib/{ => bluetooth}/cmtp.h       |  0
 lib/{ => bluetooth}/hci.h        |  0
 lib/{ => bluetooth}/hci_lib.h    |  0
 lib/{ => bluetooth}/hidp.h       |  0
 lib/{ => bluetooth}/l2cap.h      |  0
 lib/{ => bluetooth}/rfcomm.h     |  0
 lib/{ => bluetooth}/sco.h        |  0
 lib/{ => bluetooth}/sdp.h        |  0
 lib/{ => bluetooth}/sdp_lib.h    |  0
 lib/hci.c                        |  6 +++---
 lib/sdp.c                        | 12 ++++++------
 lib/uuid.c                       |  2 +-
 mesh/main.c                      |  2 +-
 mesh/mesh-io-generic.c           |  2 +-
 mesh/mesh-io-mgmt.c              |  4 ++--
 mesh/mesh-io.c                   |  2 +-
 mesh/mesh-mgmt.c                 |  2 +-
 monitor/a2dp.c                   |  2 +-
 monitor/analyze.c                |  2 +-
 monitor/att.c                    |  6 +++---
 monitor/avctp.c                  |  2 +-
 monitor/avdtp.c                  |  2 +-
 monitor/bnep.c                   |  2 +-
 monitor/control.c                |  4 ++--
 monitor/hcidump.c                |  6 +++---
 monitor/intel.c                  |  4 ++--
 monitor/l2cap.c                  |  2 +-
 monitor/msft.c                   |  2 +-
 monitor/packet.c                 |  6 +++---
 monitor/rfcomm.c                 |  2 +-
 monitor/sdp.c                    |  2 +-
 obexd/client/bluetooth.c         |  8 ++++----
 obexd/client/map.c               |  2 +-
 obexd/client/pbap.c              |  4 ++--
 obexd/plugins/bluetooth.c        |  2 +-
 obexd/plugins/syncevolution.c    |  2 +-
 peripheral/attach.c              |  6 +++---
 peripheral/gap.c                 |  2 +-
 peripheral/gatt.c                |  4 ++--
 plugins/admin.c                  |  2 +-
 plugins/autopair.c               |  4 ++--
 plugins/hostname.c               |  4 ++--
 plugins/neard.c                  |  6 +++---
 plugins/policy.c                 |  4 ++--
 plugins/sixaxis.c                |  4 ++--
 profiles/audio/a2dp.c            |  6 +++---
 profiles/audio/avctp.c           |  6 +++---
 profiles/audio/avdtp.c           |  6 +++---
 profiles/audio/bap.c             |  6 +++---
 profiles/audio/bass.c            |  2 +-
 profiles/audio/control.c         |  6 +++---
 profiles/audio/csip.c            |  6 +++---
 profiles/audio/mcp.c             |  6 +++---
 profiles/audio/media.c           |  4 ++--
 profiles/audio/micp.c            |  6 +++---
 profiles/audio/sink.c            |  4 ++--
 profiles/audio/source.c          |  4 ++--
 profiles/audio/transport.c       |  4 ++--
 profiles/audio/vcp.c             |  6 +++---
 profiles/battery/bas.c           |  4 ++--
 profiles/battery/battery.c       |  6 +++---
 profiles/cups/hcrp.c             |  8 ++++----
 profiles/cups/main.c             |  6 +++---
 profiles/cups/sdp.c              |  6 +++---
 profiles/cups/spp.c              |  8 ++++----
 profiles/deviceinfo/deviceinfo.c |  4 ++--
 profiles/deviceinfo/dis.c        |  4 ++--
 profiles/gap/gas.c               |  6 +++---
 profiles/health/hdp.c            |  6 +++---
 profiles/health/hdp_manager.c    |  4 ++--
 profiles/health/hdp_util.c       |  6 +++---
 profiles/health/mcap.c           |  2 +-
 profiles/input/device.c          |  8 ++++----
 profiles/input/hog-lib.c         |  4 ++--
 profiles/input/hog.c             |  4 ++--
 profiles/input/manager.c         |  6 +++---
 profiles/input/server.c          |  4 ++--
 profiles/midi/midi.c             |  4 ++--
 profiles/network/bnep.c          |  6 +++---
 profiles/network/connection.c    |  6 +++---
 profiles/network/manager.c       |  6 +++---
 profiles/network/server.c        |  8 ++++----
 profiles/sap/manager.c           |  4 ++--
 profiles/sap/server.c            |  4 ++--
 profiles/scanparam/scan.c        |  4 ++--
 profiles/scanparam/scpp.c        |  4 ++--
 src/adapter.h                    |  4 ++--
 src/adv_monitor.c                |  2 +-
 src/advertising.c                |  4 ++--
 src/agent.c                      |  4 ++--
 src/battery.c                    |  2 +-
 src/device.c                     |  6 +++---
 src/eir.c                        |  6 +++---
 src/eir.h                        |  2 +-
 src/gatt-client.c                |  4 ++--
 src/gatt-database.c              |  6 +++---
 src/log.c                        |  4 ++--
 src/main.c                       |  4 ++--
 src/oui.c                        |  2 +-
 src/plugin.c                     |  2 +-
 src/profile.c                    |  6 +++---
 src/rfkill.c                     |  4 ++--
 src/sdp-client.c                 |  6 +++---
 src/sdp-xml.c                    |  4 ++--
 src/sdpd-database.c              |  6 +++---
 src/sdpd-request.c               |  8 ++++----
 src/sdpd-server.c                |  8 ++++----
 src/sdpd-service.c               |  6 +++---
 src/service.c                    |  4 ++--
 src/settings.c                   |  2 +-
 src/shared/ad.c                  |  4 ++--
 src/shared/ad.h                  |  2 +-
 src/shared/att.c                 |  4 ++--
 src/shared/bap.c                 |  2 +-
 src/shared/bass.c                |  2 +-
 src/shared/btp.c                 |  2 +-
 src/shared/ccp.c                 |  4 ++--
 src/shared/csip.c                |  2 +-
 src/shared/gap.c                 |  2 +-
 src/shared/gatt-client.c         |  2 +-
 src/shared/gatt-db.c             |  2 +-
 src/shared/gatt-helpers.c        |  2 +-
 src/shared/gatt-server.c         |  2 +-
 src/shared/log.c                 |  4 ++--
 src/shared/mcp.c                 |  4 ++--
 src/shared/mgmt.c                |  4 ++--
 src/shared/micp.c                |  2 +-
 src/shared/tester.c              |  4 ++--
 src/shared/util.c                |  2 +-
 src/shared/vcp.c                 |  2 +-
 src/storage.c                    |  6 +++---
 src/uuid-helper.c                |  6 +++---
 tools/advtest.c                  |  2 +-
 tools/amptest.c                  |  6 +++---
 tools/avinfo.c                   |  8 ++++----
 tools/avtest.c                   | 10 +++++-----
 tools/bdaddr.c                   |  6 +++---
 tools/bluetooth-player.c         |  2 +-
 tools/bnep-tester.c              |  4 ++--
 tools/bneptest.c                 |  8 ++++----
 tools/btattach.c                 |  6 +++---
 tools/btgatt-client.c            |  8 ++++----
 tools/btgatt-server.c            |  8 ++++----
 tools/btiotest.c                 |  2 +-
 tools/btmon-logger.c             |  4 ++--
 tools/btpclient.c                |  2 +-
 tools/btpclientctl.c             |  2 +-
 tools/ciptool.c                  | 14 +++++++-------
 tools/cltest.c                   |  8 ++++----
 tools/hciattach.c                |  6 +++---
 tools/hciattach_ath3k.c          |  6 +++---
 tools/hciattach_bcm43xx.c        |  6 +++---
 tools/hciattach_intel.c          |  6 +++---
 tools/hciattach_qualcomm.c       |  6 +++---
 tools/hciattach_st.c             |  2 +-
 tools/hciattach_ti.c             |  6 +++---
 tools/hciattach_tialt.c          |  6 +++---
 tools/hciconfig.c                |  6 +++---
 tools/hcidump.c                  |  4 ++--
 tools/hcieventmask.c             |  6 +++---
 tools/hcisecfilter.c             |  6 +++---
 tools/hcitool.c                  |  6 +++---
 tools/hwdb.c                     |  2 +-
 tools/ioctl-tester.c             |  6 +++---
 tools/iso-tester.c               |  2 +-
 tools/isotest.c                  |  6 +++---
 tools/l2cap-tester.c             |  4 ++--
 tools/l2ping.c                   |  8 ++++----
 tools/l2test.c                   |  8 ++++----
 tools/mcaptest.c                 |  8 ++++----
 tools/mesh-gatt/gatt.c           |  2 +-
 tools/mesh-tester.c              |  8 ++++----
 tools/mesh/agent.c               |  2 +-
 tools/meshctl.c                  |  2 +-
 tools/mgmt-tester.c              |  8 ++++----
 tools/oobtest.c                  |  2 +-
 tools/parser/hci.c               |  4 ++--
 tools/parser/l2cap.c             |  2 +-
 tools/parser/lmp.c               |  4 ++--
 tools/parser/parser.h            |  2 +-
 tools/rctest.c                   | 12 ++++++------
 tools/rfcomm-tester.c            |  4 ++--
 tools/rfcomm.c                   |  8 ++++----
 tools/sco-tester.c               |  4 ++--
 tools/scotest.c                  |  4 ++--
 tools/sdptool.c                  | 10 +++++-----
 tools/smp-tester.c               |  4 ++--
 tools/test-runner.c              |  6 +++---
 tools/userchan-tester.c          |  4 ++--
 unit/test-avrcp.c                |  2 +-
 unit/test-bap.c                  |  2 +-
 unit/test-bass.c                 |  2 +-
 unit/test-eir.c                  |  6 +++---
 unit/test-gatt.c                 |  2 +-
 unit/test-gattrib.c              |  2 +-
 unit/test-hog.c                  |  2 +-
 unit/test-lib.c                  |  4 ++--
 unit/test-mgmt.c                 |  2 +-
 unit/test-micp.c                 |  2 +-
 unit/test-sdp.c                  |  6 +++---
 unit/test-uuid.c                 |  2 +-
 unit/test-vcp.c                  |  2 +-
 255 files changed, 546 insertions(+), 547 deletions(-)

diff --git a/.gitignore b/.gitignore
index a431304c3..a80a4b0e1 100644
--- a/.gitignore
+++ b/.gitignore
@@ -37,7 +37,6 @@ coverage
 ell
 
 lib/bluez.pc
-lib/bluetooth
 src/builtin.h
 src/bluetoothd
 tools/hid2hci.rules
diff --git a/Makefile.am b/Makefile.am
index 94df43869..5b0e80b7b 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -67,16 +67,23 @@ manual_pages =
 plugin_LTLIBRARIES =
 
 lib_sources = lib/bluetooth.c lib/hci.c lib/sdp.c
-lib_headers = lib/bluetooth.h lib/hci.h lib/hci_lib.h \
-		lib/sco.h lib/l2cap.h lib/sdp.h lib/sdp_lib.h \
-		lib/rfcomm.h lib/bnep.h lib/cmtp.h lib/hidp.h
+lib_headers = \
+	lib/bluetooth/bluetooth.h \
+	lib/bluetooth/bnep.h \
+	lib/bluetooth/cmtp.h \
+	lib/bluetooth/hci.h \
+	lib/bluetooth/hci_lib.h \
+	lib/bluetooth/hidp.h \
+	lib/bluetooth/l2cap.h \
+	lib/bluetooth/rfcomm.h \
+	lib/bluetooth/sco.h \
+	lib/bluetooth/sdp.h \
+	lib/bluetooth/sdp_lib.h
 
 extra_headers = lib/mgmt.h lib/uuid.h lib/a2mp.h lib/amp.h lib/iso.h
 extra_sources = lib/uuid.c
 
-local_headers = $(foreach file,$(lib_headers), lib/bluetooth/$(notdir $(file)))
-
-BUILT_SOURCES = $(local_headers) $(ell_built_sources) src/builtin.h
+BUILT_SOURCES = $(ell_built_sources) src/builtin.h
 
 if LIBRARY
 pkginclude_HEADERS += $(lib_headers)
@@ -490,7 +497,7 @@ EXTRA_DIST += doc/btsnoop.txt
 
 EXTRA_DIST += tools/magic.btsnoop
 
-AM_CPPFLAGS += $(DBUS_CFLAGS) $(GLIB_CFLAGS) -I$(builddir)/lib
+AM_CPPFLAGS += $(DBUS_CFLAGS) $(GLIB_CFLAGS)
 
 unit_tests += unit/test-tester
 
@@ -756,12 +763,6 @@ endif
 src/builtin.h: src/genbuiltin $(builtin_sources)
 	$(AM_V_GEN)$(srcdir)/src/genbuiltin $(builtin_modules) > $@
 
-$(lib_libbluetooth_la_OBJECTS): $(local_headers)
-
-lib/bluetooth/%.h: lib/%.h
-	$(AM_V_at)$(MKDIR_P) lib/bluetooth
-	$(AM_V_GEN)$(LN_S) -f $(abspath $<) $@
-
 ell/shared: Makefile
 	$(AM_V_at)$(MKDIR_P) ell
 	$(AM_V_GEN)for f in $(ell_shared) ; do \
@@ -802,4 +803,3 @@ endif
 clean-local: clean-coverage
 	-find $(top_builddir) -name "*.gcno" -delete
 	-find $(top_builddir) -name "*.gcda" -delete
-	$(RM) -r lib/bluetooth
diff --git a/Makefile.mesh b/Makefile.mesh
index e4c9fa6a3..fa34536ec 100644
--- a/Makefile.mesh
+++ b/Makefile.mesh
@@ -42,7 +42,7 @@ mesh_sources = mesh/mesh.h mesh/mesh.c \
 pkglibexec_PROGRAMS += mesh/bluetooth-meshd
 
 mesh/mesh.$(OBJEXT): ell/internal
-mesh/main.$(OBJEXT): src/builtin.h lib/bluetooth/bluetooth.h
+mesh/main.$(OBJEXT): src/builtin.h
 
 mesh_bluetooth_meshd_SOURCES = $(mesh_sources) mesh/main.c
 mesh_bluetooth_meshd_LDADD = src/libshared-ell.la $(ell_ldadd) -ljson-c
diff --git a/android/a2dp-sink.c b/android/a2dp-sink.c
index 0ecb5c392..86bd12607 100644
--- a/android/a2dp-sink.c
+++ b/android/a2dp-sink.c
@@ -15,7 +15,7 @@
 #include <stdbool.h>
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "src/log.h"
 #include "hal-msg.h"
 #include "ipc.h"
diff --git a/android/a2dp.c b/android/a2dp.c
index ee607a32d..4d565b135 100644
--- a/android/a2dp.c
+++ b/android/a2dp.c
@@ -21,9 +21,9 @@
 #include <glib.h>
 
 #include "btio/btio.h"
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "profiles/audio/a2dp-codecs.h"
 #include "src/shared/queue.h"
 #include "src/shared/util.h"
diff --git a/android/avctp.c b/android/avctp.c
index 37b4cec4f..f925107b8 100644
--- a/android/avctp.c
+++ b/android/avctp.c
@@ -30,7 +30,7 @@
 
 #include <glib.h>
 
-#include "lib/sdp.h"
+#include "lib/bluetooth/sdp.h"
 #include "src/shared/util.h"
 #include "src/log.h"
 #include "avctp.h"
diff --git a/android/avdtp.c b/android/avdtp.c
index a261a8e5f..5726e8693 100644
--- a/android/avdtp.c
+++ b/android/avdtp.c
@@ -26,7 +26,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "src/log.h"
 #include "src/shared/util.h"
 #include "src/shared/queue.h"
diff --git a/android/avdtptest.c b/android/avdtptest.c
index e6668bc3c..676ba68ba 100644
--- a/android/avdtptest.c
+++ b/android/avdtptest.c
@@ -22,9 +22,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "btio/btio.h"
 #include "src/shared/util.h"
diff --git a/android/avrcp-lib.c b/android/avrcp-lib.c
index b342692cb..e672268e7 100644
--- a/android/avrcp-lib.c
+++ b/android/avrcp-lib.c
@@ -18,7 +18,7 @@
 #include <errno.h>
 #include <string.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "src/shared/util.h"
 #include "src/log.h"
diff --git a/android/avrcp.c b/android/avrcp.c
index fe092f02d..184228db8 100644
--- a/android/avrcp.c
+++ b/android/avrcp.c
@@ -18,9 +18,9 @@
 #include <glib.h>
 
 #include "btio/btio.h"
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "src/sdp-client.h"
 #include "src/shared/util.h"
 #include "src/log.h"
diff --git a/android/bluetooth.c b/android/bluetooth.c
index fe956b5d4..c17270563 100644
--- a/android/bluetooth.c
+++ b/android/bluetooth.c
@@ -22,8 +22,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/mgmt.h"
 #include "lib/uuid.h"
 #include "src/shared/util.h"
@@ -31,8 +31,8 @@
 #include "src/shared/queue.h"
 #include "src/shared/ad.h"
 #include "src/eir.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "src/sdp-client.h"
 #include "src/sdpd.h"
 #include "src/log.h"
diff --git a/android/bluetoothd-snoop.c b/android/bluetoothd-snoop.c
index 0321e69bc..bebda0ecf 100644
--- a/android/bluetoothd-snoop.c
+++ b/android/bluetoothd-snoop.c
@@ -19,8 +19,8 @@
 #include <sys/capability.h>
 #endif
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 #include "lib/mgmt.h"
 
 #include "src/shared/mainloop.h"
diff --git a/android/gatt.c b/android/gatt.c
index 89fcdb114..57b5e82bc 100644
--- a/android/gatt.c
+++ b/android/gatt.c
@@ -21,8 +21,8 @@
 
 #include "ipc.h"
 #include "ipc-common.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 #include "bluetooth.h"
 #include "gatt.h"
diff --git a/android/handsfree-client.c b/android/handsfree-client.c
index c8f9e690e..14249d89c 100644
--- a/android/handsfree-client.c
+++ b/android/handsfree-client.c
@@ -18,9 +18,9 @@
 #include <unistd.h>
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "src/sdp-client.h"
 #include "src/shared/hfp.h"
 #include "src/shared/queue.h"
diff --git a/android/handsfree.c b/android/handsfree.c
index 2365356c2..b14f301dc 100644
--- a/android/handsfree.c
+++ b/android/handsfree.c
@@ -18,9 +18,9 @@
 #include <unistd.h>
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "src/sdp-client.h"
 #include "src/uuid-helper.h"
 #include "src/shared/hfp.h"
diff --git a/android/health.c b/android/health.c
index 9a29964b1..d51365e1e 100644
--- a/android/health.c
+++ b/android/health.c
@@ -21,11 +21,11 @@
 #include <glib.h>
 
 #include "btio/btio.h"
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/l2cap.h"
 #include "src/log.h"
 #include "src/shared/util.h"
 #include "src/shared/queue.h"
diff --git a/android/hidhost.c b/android/hidhost.c
index b4e5c527f..0a581c175 100644
--- a/android/hidhost.c
+++ b/android/hidhost.c
@@ -22,9 +22,9 @@
 #include <glib.h>
 
 #include "btio/btio.h"
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 #include "src/shared/mgmt.h"
 #include "src/shared/util.h"
diff --git a/android/ipc-tester.c b/android/ipc-tester.c
index 780e1dc4c..497edef35 100644
--- a/android/ipc-tester.c
+++ b/android/ipc-tester.c
@@ -25,7 +25,7 @@
 #include <libgen.h>
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 
 #include "src/shared/tester.h"
diff --git a/android/main.c b/android/main.c
index b85709a1d..2d43ea57c 100644
--- a/android/main.c
+++ b/android/main.c
@@ -31,8 +31,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "src/log.h"
 #include "src/sdpd.h"
diff --git a/android/map-client.c b/android/map-client.c
index 3360bcd38..f6eb61752 100644
--- a/android/map-client.c
+++ b/android/map-client.c
@@ -17,12 +17,12 @@
 #include <stdint.h>
 #include <glib.h>
 
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "src/sdp-client.h"
 
 #include "ipc.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "map-client.h"
 #include "src/log.h"
 #include "hal-msg.h"
diff --git a/android/pan.c b/android/pan.c
index ab4434710..23c012173 100644
--- a/android/pan.c
+++ b/android/pan.c
@@ -30,10 +30,10 @@
 #include <linux/if_bridge.h>
 
 #include "btio/btio.h"
-#include "lib/bluetooth.h"
-#include "lib/bnep.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/bnep.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "src/uuid-helper.h"
 #include "profiles/network/bnep.h"
 #include "src/log.h"
diff --git a/android/sco.c b/android/sco.c
index f3e03c605..6e2a7fc3d 100644
--- a/android/sco.c
+++ b/android/sco.c
@@ -17,7 +17,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "btio/btio.h"
 #include "src/log.h"
 #include "src/shared/util.h"
diff --git a/android/socket.c b/android/socket.c
index 74cbcf4ef..10e1e7af4 100644
--- a/android/socket.c
+++ b/android/socket.c
@@ -17,10 +17,10 @@
 #include <unistd.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "btio/btio.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "src/sdp-client.h"
 #include "src/sdpd.h"
 #include "src/log.h"
diff --git a/android/tester-a2dp.c b/android/tester-a2dp.c
index c25809245..0b824ad9a 100644
--- a/android/tester-a2dp.c
+++ b/android/tester-a2dp.c
@@ -11,7 +11,7 @@
 #include "src/shared/util.h"
 #include "src/shared/tester.h"
 #include "src/shared/queue.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "android/utils.h"
 #include "tester-main.h"
 
diff --git a/android/tester-avrcp.c b/android/tester-avrcp.c
index f2292d4e4..88627a584 100644
--- a/android/tester-avrcp.c
+++ b/android/tester-avrcp.c
@@ -11,7 +11,7 @@
 #include "src/shared/util.h"
 #include "src/shared/tester.h"
 #include "src/shared/queue.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "android/utils.h"
 #include "tester-main.h"
 
diff --git a/android/tester-gatt.c b/android/tester-gatt.c
index 30db7684d..54c20865b 100644
--- a/android/tester-gatt.c
+++ b/android/tester-gatt.c
@@ -8,7 +8,7 @@
 #include <stdbool.h>
 
 #include "emulator/bthost.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "src/shared/util.h"
 #include "src/shared/tester.h"
 #include "src/shared/queue.h"
diff --git a/android/tester-hdp.c b/android/tester-hdp.c
index 0cc805eac..3fc4cf1ed 100644
--- a/android/tester-hdp.c
+++ b/android/tester-hdp.c
@@ -9,7 +9,7 @@
 #include <stdbool.h>
 
 #include "emulator/bthost.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "android/utils.h"
 #include "src/shared/tester.h"
 #include "src/shared/queue.h"
diff --git a/android/tester-hidhost.c b/android/tester-hidhost.c
index f9daf5590..b0326747f 100644
--- a/android/tester-hidhost.c
+++ b/android/tester-hidhost.c
@@ -10,7 +10,7 @@
 #include "emulator/bthost.h"
 #include "src/shared/tester.h"
 #include "src/shared/queue.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "android/utils.h"
 #include "tester-main.h"
 
diff --git a/android/tester-main.c b/android/tester-main.c
index 317c1de06..cbeebcba8 100644
--- a/android/tester-main.c
+++ b/android/tester-main.c
@@ -13,7 +13,7 @@
 #include <sys/wait.h>
 #include <sys/signalfd.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 #include "src/shared/util.h"
 #include "src/shared/tester.h"
diff --git a/android/tester-pan.c b/android/tester-pan.c
index f70ab95b8..1f20f0d62 100644
--- a/android/tester-pan.c
+++ b/android/tester-pan.c
@@ -8,7 +8,7 @@
 #include <stdbool.h>
 
 #include "emulator/bthost.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "android/utils.h"
 #include "src/shared/tester.h"
 #include "src/shared/queue.h"
diff --git a/attrib/att.c b/attrib/att.c
index fa53c90aa..c21a56356 100644
--- a/attrib/att.c
+++ b/attrib/att.c
@@ -19,7 +19,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/attrib/gatt.c b/attrib/gatt.c
index b496dd1eb..a18484cb1 100644
--- a/attrib/gatt.c
+++ b/attrib/gatt.c
@@ -18,8 +18,8 @@
 
 #include <glib.h>
 
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/attrib/gattrib.c b/attrib/gattrib.c
index 997af3699..ecc8a8f54 100644
--- a/attrib/gattrib.c
+++ b/attrib/gattrib.c
@@ -20,7 +20,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "btio/btio.h"
diff --git a/attrib/gatttool.c b/attrib/gatttool.c
index 4309d20b1..caf495066 100644
--- a/attrib/gatttool.c
+++ b/attrib/gatttool.c
@@ -19,10 +19,10 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/attrib/interactive.c b/attrib/interactive.c
index c0262e87c..d0a8497e9 100644
--- a/attrib/interactive.c
+++ b/attrib/interactive.c
@@ -26,8 +26,8 @@
 #include <readline/readline.h>
 #include <readline/history.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/attrib/utils.c b/attrib/utils.c
index 317331b4b..2d6fc5b2d 100644
--- a/attrib/utils.c
+++ b/attrib/utils.c
@@ -16,10 +16,10 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "btio/btio.h"
diff --git a/btio/btio.c b/btio/btio.c
index d30cfcac7..e8faeb34e 100644
--- a/btio/btio.c
+++ b/btio/btio.c
@@ -25,10 +25,10 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/l2cap.h"
-#include "lib/rfcomm.h"
-#include "lib/sco.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/l2cap.h"
+#include "lib/bluetooth/rfcomm.h"
+#include "lib/bluetooth/sco.h"
 #include "lib/iso.h"
 
 #include "btio.h"
diff --git a/client/mgmt.c b/client/mgmt.c
index 44bf4d201..833d7793f 100644
--- a/client/mgmt.c
+++ b/client/mgmt.c
@@ -28,11 +28,11 @@
 #include <wordexp.h>
 #include <ctype.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "src/uuid-helper.h"
diff --git a/client/player.c b/client/player.c
index a40bf66e3..377cea62a 100644
--- a/client/player.c
+++ b/client/player.c
@@ -32,7 +32,7 @@
 
 #include "gdbus/gdbus.h"
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "profiles/audio/a2dp-codecs.h"
diff --git a/emulator/amp.c b/emulator/amp.c
index 49d2df7b3..eb35f3c0c 100644
--- a/emulator/amp.c
+++ b/emulator/amp.c
@@ -21,8 +21,8 @@
 #include <sys/socket.h>
 #include <sys/un.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/util.h"
 #include "src/shared/mainloop.h"
diff --git a/emulator/b1ee.c b/emulator/b1ee.c
index 53b85f221..ad5093c96 100644
--- a/emulator/b1ee.c
+++ b/emulator/b1ee.c
@@ -26,8 +26,8 @@
 #include <netdb.h>
 #include <arpa/inet.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/mainloop.h"
 
diff --git a/emulator/btdev.c b/emulator/btdev.c
index 4c9f5d181..534913b96 100644
--- a/emulator/btdev.c
+++ b/emulator/btdev.c
@@ -25,8 +25,8 @@
 #include <fcntl.h>
 #include <unistd.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/util.h"
 #include "src/shared/timeout.h"
diff --git a/emulator/bthost.c b/emulator/bthost.c
index 8c40fce90..c8e7c41a8 100644
--- a/emulator/bthost.c
+++ b/emulator/bthost.c
@@ -22,7 +22,7 @@
 #include <endian.h>
 #include <stdbool.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "src/shared/util.h"
 #include "src/shared/tester.h"
diff --git a/emulator/bthost.h b/emulator/bthost.h
index 46781365b..f8e1f0565 100644
--- a/emulator/bthost.h
+++ b/emulator/bthost.h
@@ -13,7 +13,7 @@
 #include <stdint.h>
 #include <sys/uio.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 typedef void (*bthost_send_func) (const struct iovec *iov, int iovlen,
 							void *user_data);
diff --git a/emulator/hciemu.c b/emulator/hciemu.c
index f13b4bda1..99c836a16 100644
--- a/emulator/hciemu.c
+++ b/emulator/hciemu.c
@@ -25,8 +25,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "monitor/bt.h"
 #include "emulator/vhci.h"
diff --git a/emulator/le.c b/emulator/le.c
index 7656a657c..2f7176a3f 100644
--- a/emulator/le.c
+++ b/emulator/le.c
@@ -22,8 +22,8 @@
 #include <sys/uio.h>
 #include <time.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/util.h"
 #include "src/shared/crypto.h"
diff --git a/emulator/serial.c b/emulator/serial.c
index c9e6d7cd6..79057a40f 100644
--- a/emulator/serial.c
+++ b/emulator/serial.c
@@ -25,8 +25,8 @@
 #include <sys/epoll.h>
 #include <sys/uio.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/mainloop.h"
 #include "btdev.h"
diff --git a/emulator/server.c b/emulator/server.c
index ceb417a40..ada6b34a1 100644
--- a/emulator/server.c
+++ b/emulator/server.c
@@ -26,8 +26,8 @@
 #include <netinet/in.h>
 #include <arpa/inet.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/mainloop.h"
 #include "btdev.h"
diff --git a/emulator/smp.c b/emulator/smp.c
index 2a36437a0..d4d3aff65 100644
--- a/emulator/smp.c
+++ b/emulator/smp.c
@@ -22,8 +22,8 @@
 #include <stdbool.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/util.h"
 #include "src/shared/crypto.h"
diff --git a/emulator/vhci.c b/emulator/vhci.c
index 355ab6389..b6b92b4d5 100644
--- a/emulator/vhci.c
+++ b/emulator/vhci.c
@@ -24,8 +24,8 @@
 #include <unistd.h>
 #include <dirent.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/io.h"
 #include "monitor/bt.h"
diff --git a/lib/bluetooth.c b/lib/bluetooth.c
index 84e40c819..9b1aaa3b4 100644
--- a/lib/bluetooth.c
+++ b/lib/bluetooth.c
@@ -23,8 +23,8 @@
 #include <string.h>
 #include <sys/socket.h>
 
-#include "bluetooth.h"
-#include "hci.h"
+#include "bluetooth/bluetooth.h"
+#include "bluetooth/hci.h"
 
 void baswap(bdaddr_t *dst, const bdaddr_t *src)
 {
diff --git a/lib/bluetooth.h b/lib/bluetooth/bluetooth.h
similarity index 100%
rename from lib/bluetooth.h
rename to lib/bluetooth/bluetooth.h
diff --git a/lib/bnep.h b/lib/bluetooth/bnep.h
similarity index 100%
rename from lib/bnep.h
rename to lib/bluetooth/bnep.h
diff --git a/lib/cmtp.h b/lib/bluetooth/cmtp.h
similarity index 100%
rename from lib/cmtp.h
rename to lib/bluetooth/cmtp.h
diff --git a/lib/hci.h b/lib/bluetooth/hci.h
similarity index 100%
rename from lib/hci.h
rename to lib/bluetooth/hci.h
diff --git a/lib/hci_lib.h b/lib/bluetooth/hci_lib.h
similarity index 100%
rename from lib/hci_lib.h
rename to lib/bluetooth/hci_lib.h
diff --git a/lib/hidp.h b/lib/bluetooth/hidp.h
similarity index 100%
rename from lib/hidp.h
rename to lib/bluetooth/hidp.h
diff --git a/lib/l2cap.h b/lib/bluetooth/l2cap.h
similarity index 100%
rename from lib/l2cap.h
rename to lib/bluetooth/l2cap.h
diff --git a/lib/rfcomm.h b/lib/bluetooth/rfcomm.h
similarity index 100%
rename from lib/rfcomm.h
rename to lib/bluetooth/rfcomm.h
diff --git a/lib/sco.h b/lib/bluetooth/sco.h
similarity index 100%
rename from lib/sco.h
rename to lib/bluetooth/sco.h
diff --git a/lib/sdp.h b/lib/bluetooth/sdp.h
similarity index 100%
rename from lib/sdp.h
rename to lib/bluetooth/sdp.h
diff --git a/lib/sdp_lib.h b/lib/bluetooth/sdp_lib.h
similarity index 100%
rename from lib/sdp_lib.h
rename to lib/bluetooth/sdp_lib.h
diff --git a/lib/hci.c b/lib/hci.c
index 937e65d48..24654e01c 100644
--- a/lib/hci.c
+++ b/lib/hci.c
@@ -29,9 +29,9 @@
 #include <sys/ioctl.h>
 #include <sys/socket.h>
 
-#include "bluetooth.h"
-#include "hci.h"
-#include "hci_lib.h"
+#include "bluetooth/bluetooth.h"
+#include "bluetooth/hci.h"
+#include "bluetooth/hci_lib.h"
 
 #ifndef MIN
 #define MIN(x, y) ((x) < (y) ? (x) : (y))
diff --git a/lib/sdp.c b/lib/sdp.c
index 34b0dbb94..85e8be871 100644
--- a/lib/sdp.c
+++ b/lib/sdp.c
@@ -29,12 +29,12 @@
 #include <sys/un.h>
 #include <netinet/in.h>
 
-#include "bluetooth.h"
-#include "hci.h"
-#include "hci_lib.h"
-#include "l2cap.h"
-#include "sdp.h"
-#include "sdp_lib.h"
+#include "bluetooth/bluetooth.h"
+#include "bluetooth/hci.h"
+#include "bluetooth/hci_lib.h"
+#include "bluetooth/l2cap.h"
+#include "bluetooth/sdp.h"
+#include "bluetooth/sdp_lib.h"
 
 #define SDPINF(fmt, arg...) syslog(LOG_INFO, fmt "\n", ## arg)
 #define SDPERR(fmt, arg...) syslog(LOG_ERR, "%s: " fmt "\n", __func__ , ## arg)
diff --git a/lib/uuid.c b/lib/uuid.c
index 9a216e7ce..bd8d5c6b4 100644
--- a/lib/uuid.c
+++ b/lib/uuid.c
@@ -17,7 +17,7 @@
 #include <stdlib.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "bluetooth/bluetooth.h"
 #include "uuid.h"
 
 static uint128_t bluetooth_base_uuid = {
diff --git a/mesh/main.c b/mesh/main.c
index 145bcfa98..115b9718a 100644
--- a/mesh/main.c
+++ b/mesh/main.c
@@ -23,7 +23,7 @@
 #include <sys/stat.h>
 #include <ell/ell.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 
 #include "mesh/mesh.h"
diff --git a/mesh/mesh-io-generic.c b/mesh/mesh-io-generic.c
index 13a863b48..1b0c2f4ec 100644
--- a/mesh/mesh-io-generic.c
+++ b/mesh/mesh-io-generic.c
@@ -20,7 +20,7 @@
 #include "monitor/bt.h"
 #include "src/shared/hci.h"
 #include "src/shared/mgmt.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 
 #include "mesh/mesh-defs.h"
diff --git a/mesh/mesh-io-mgmt.c b/mesh/mesh-io-mgmt.c
index 5f0eb206b..2bf0f9e44 100644
--- a/mesh/mesh-io-mgmt.c
+++ b/mesh/mesh-io-mgmt.c
@@ -19,8 +19,8 @@
 #include <ell/ell.h>
 
 #include "monitor/bt.h"
-#include "lib/bluetooth.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 #include "src/shared/mgmt.h"
 
diff --git a/mesh/mesh-io.c b/mesh/mesh-io.c
index b953bf4cf..6cdee1fbb 100644
--- a/mesh/mesh-io.c
+++ b/mesh/mesh-io.c
@@ -14,7 +14,7 @@
 
 #include <ell/ell.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 #include "src/shared/mgmt.h"
 
diff --git a/mesh/mesh-mgmt.c b/mesh/mesh-mgmt.c
index fd21a168a..a41b9c231 100644
--- a/mesh/mesh-mgmt.c
+++ b/mesh/mesh-mgmt.c
@@ -14,7 +14,7 @@
 
 #include <ell/ell.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 #include "src/shared/mgmt.h"
 
diff --git a/monitor/a2dp.c b/monitor/a2dp.c
index ae88f565e..6d16621fa 100644
--- a/monitor/a2dp.c
+++ b/monitor/a2dp.c
@@ -18,7 +18,7 @@
 #include <stdlib.h>
 #include <string.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "src/shared/util.h"
 #include "bt.h"
diff --git a/monitor/analyze.c b/monitor/analyze.c
index 3cc482cd9..7f125cda7 100644
--- a/monitor/analyze.c
+++ b/monitor/analyze.c
@@ -19,7 +19,7 @@
 #include <sys/time.h>
 #include <unistd.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "src/shared/util.h"
 #include "src/shared/queue.h"
diff --git a/monitor/att.c b/monitor/att.c
index 4628db44b..e89637284 100644
--- a/monitor/att.c
+++ b/monitor/att.c
@@ -27,10 +27,10 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "src/shared/util.h"
 #include "src/shared/queue.h"
diff --git a/monitor/avctp.c b/monitor/avctp.c
index c59e93b20..9e624cb6e 100644
--- a/monitor/avctp.c
+++ b/monitor/avctp.c
@@ -20,7 +20,7 @@
 #include <ctype.h>
 #include <inttypes.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/monitor/avdtp.c b/monitor/avdtp.c
index 1393d1286..0551540d5 100644
--- a/monitor/avdtp.c
+++ b/monitor/avdtp.c
@@ -17,7 +17,7 @@
 #include <stdlib.h>
 #include <string.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "src/shared/util.h"
 #include "bt.h"
diff --git a/monitor/bnep.c b/monitor/bnep.c
index 3b8b284a9..eba5c512e 100644
--- a/monitor/bnep.c
+++ b/monitor/bnep.c
@@ -20,7 +20,7 @@
 #include <ctype.h>
 #include <inttypes.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/monitor/control.c b/monitor/control.c
index 009cf1520..bdcd46ff6 100644
--- a/monitor/control.c
+++ b/monitor/control.c
@@ -30,8 +30,8 @@
 #include <fcntl.h>
 #include <linux/filter.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 #include "lib/mgmt.h"
 
 #include "src/shared/util.h"
diff --git a/monitor/hcidump.c b/monitor/hcidump.c
index fac9c8a08..f1246d608 100644
--- a/monitor/hcidump.c
+++ b/monitor/hcidump.c
@@ -22,9 +22,9 @@
 #include <sys/ioctl.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "src/shared/mainloop.h"
 
diff --git a/monitor/intel.c b/monitor/intel.c
index 0de864d8a..538d89726 100644
--- a/monitor/intel.c
+++ b/monitor/intel.c
@@ -17,8 +17,8 @@
 #include <stdio.h>
 #include <inttypes.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/util.h"
 #include "display.h"
diff --git a/monitor/l2cap.c b/monitor/l2cap.c
index dff183bd0..972e81d5b 100644
--- a/monitor/l2cap.c
+++ b/monitor/l2cap.c
@@ -19,7 +19,7 @@
 #include <string.h>
 #include <inttypes.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/monitor/msft.c b/monitor/msft.c
index 096fedd59..efba52640 100644
--- a/monitor/msft.c
+++ b/monitor/msft.c
@@ -30,7 +30,7 @@
 #include <stdio.h>
 #include <inttypes.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/monitor/packet.c b/monitor/packet.c
index 3c32735b7..b8c88a434 100644
--- a/monitor/packet.c
+++ b/monitor/packet.c
@@ -27,10 +27,10 @@
 #include <sys/time.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "src/shared/util.h"
 #include "src/shared/btsnoop.h"
diff --git a/monitor/rfcomm.c b/monitor/rfcomm.c
index a855152c6..fba6b6f6a 100644
--- a/monitor/rfcomm.c
+++ b/monitor/rfcomm.c
@@ -20,7 +20,7 @@
 #include <ctype.h>
 #include <inttypes.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/monitor/sdp.c b/monitor/sdp.c
index 5fe4f2979..1d77f88cc 100644
--- a/monitor/sdp.c
+++ b/monitor/sdp.c
@@ -19,7 +19,7 @@
 #include <string.h>
 #include <inttypes.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/obexd/client/bluetooth.c b/obexd/client/bluetooth.c
index ca2c023fb..584876ca0 100644
--- a/obexd/client/bluetooth.c
+++ b/obexd/client/bluetooth.c
@@ -18,10 +18,10 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/rfcomm.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/rfcomm.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "gdbus/gdbus.h"
 #include "btio/btio.h"
diff --git a/obexd/client/map.c b/obexd/client/map.c
index 513dcaf14..ea9ea5b40 100644
--- a/obexd/client/map.c
+++ b/obexd/client/map.c
@@ -21,7 +21,7 @@
 
 #include <glib.h>
 
-#include "lib/sdp.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gobex/gobex-apparam.h"
 #include "gdbus/gdbus.h"
diff --git a/obexd/client/pbap.c b/obexd/client/pbap.c
index 2d2aa9508..606db6c55 100644
--- a/obexd/client/pbap.c
+++ b/obexd/client/pbap.c
@@ -20,8 +20,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gobex/gobex-apparam.h"
 #include "gdbus/gdbus.h"
diff --git a/obexd/plugins/bluetooth.c b/obexd/plugins/bluetooth.c
index 51afdc9d0..78c85f228 100644
--- a/obexd/plugins/bluetooth.c
+++ b/obexd/plugins/bluetooth.c
@@ -22,7 +22,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/obexd/plugins/syncevolution.c b/obexd/plugins/syncevolution.c
index ae3dc48c4..be69d2b8c 100644
--- a/obexd/plugins/syncevolution.c
+++ b/obexd/plugins/syncevolution.c
@@ -21,7 +21,7 @@
 #include <glib.h>
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "gdbus/gdbus.h"
 
diff --git a/peripheral/attach.c b/peripheral/attach.c
index f7dc7ecea..1ad3dd043 100644
--- a/peripheral/attach.c
+++ b/peripheral/attach.c
@@ -17,9 +17,9 @@
 #include <unistd.h>
 #include <sys/ioctl.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 #include "tools/hciattach.h"
 #include "peripheral/attach.h"
 
diff --git a/peripheral/gap.c b/peripheral/gap.c
index b12e08b3d..5d9ada610 100644
--- a/peripheral/gap.c
+++ b/peripheral/gap.c
@@ -15,7 +15,7 @@
 #include <stdio.h>
 #include <string.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 #include "src/shared/util.h"
 #include "src/shared/mgmt.h"
diff --git a/peripheral/gatt.c b/peripheral/gatt.c
index ff1354cb4..2bae9f06f 100644
--- a/peripheral/gatt.c
+++ b/peripheral/gatt.c
@@ -18,8 +18,8 @@
 #include <string.h>
 #include <sys/epoll.h>
 
-#include "lib/bluetooth.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/l2cap.h"
 #include "lib/uuid.h"
 #include "src/shared/mainloop.h"
 #include "src/shared/util.h"
diff --git a/plugins/admin.c b/plugins/admin.c
index 16b74cfbf..0a9312f0e 100644
--- a/plugins/admin.c
+++ b/plugins/admin.c
@@ -19,7 +19,7 @@
 #include <sys/stat.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/adapter.h"
diff --git a/plugins/autopair.c b/plugins/autopair.c
index 0b09e893f..8dc116f40 100644
--- a/plugins/autopair.c
+++ b/plugins/autopair.c
@@ -20,8 +20,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "src/plugin.h"
 #include "src/adapter.h"
diff --git a/plugins/hostname.c b/plugins/hostname.c
index 51707f07d..338bdb8d4 100644
--- a/plugins/hostname.c
+++ b/plugins/hostname.c
@@ -19,8 +19,8 @@
 #include <fcntl.h>
 #include <sys/utsname.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gdbus/gdbus.h"
 
diff --git a/plugins/neard.c b/plugins/neard.c
index 99762482c..3bdc1264d 100644
--- a/plugins/neard.c
+++ b/plugins/neard.c
@@ -16,9 +16,9 @@
 #include <stdlib.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gdbus/gdbus.h"
 
diff --git a/plugins/policy.c b/plugins/policy.c
index 0bbdbfc88..8907b479b 100644
--- a/plugins/policy.c
+++ b/plugins/policy.c
@@ -19,8 +19,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 #include "lib/mgmt.h"
 
diff --git a/plugins/sixaxis.c b/plugins/sixaxis.c
index 544ab399a..ab9ba96ec 100644
--- a/plugins/sixaxis.c
+++ b/plugins/sixaxis.c
@@ -26,8 +26,8 @@
 #include <glib.h>
 #include <libudev.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/adapter.h"
diff --git a/profiles/audio/a2dp.c b/profiles/audio/a2dp.c
index b43161a13..1b3302c1a 100644
--- a/profiles/audio/a2dp.c
+++ b/profiles/audio/a2dp.c
@@ -23,9 +23,9 @@
 #include <dbus/dbus.h>
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/profiles/audio/avctp.c b/profiles/audio/avctp.c
index 8ad146df1..e3e064e1b 100644
--- a/profiles/audio/avctp.c
+++ b/profiles/audio/avctp.c
@@ -29,9 +29,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/l2cap.h"
 #include "lib/uuid.h"
 
 #include "btio/btio.h"
diff --git a/profiles/audio/avdtp.c b/profiles/audio/avdtp.c
index 3667e0840..352ff78ed 100644
--- a/profiles/audio/avdtp.c
+++ b/profiles/audio/avdtp.c
@@ -23,9 +23,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "btio/btio.h"
diff --git a/profiles/audio/bap.c b/profiles/audio/bap.c
index 88c93127b..f53324e20 100644
--- a/profiles/audio/bap.c
+++ b/profiles/audio/bap.c
@@ -30,9 +30,9 @@
 
 #include "gdbus/gdbus.h"
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 #include "lib/iso.h"
 
diff --git a/profiles/audio/bass.c b/profiles/audio/bass.c
index 7952105c5..c1b20e109 100644
--- a/profiles/audio/bass.c
+++ b/profiles/audio/bass.c
@@ -27,7 +27,7 @@
 
 #include "gdbus/gdbus.h"
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/dbus-common.h"
diff --git a/profiles/audio/control.c b/profiles/audio/control.c
index 619afc13d..d5a09c489 100644
--- a/profiles/audio/control.c
+++ b/profiles/audio/control.c
@@ -27,9 +27,9 @@
 #include <glib.h>
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/profiles/audio/csip.c b/profiles/audio/csip.c
index a697ebdfb..9313998ea 100644
--- a/profiles/audio/csip.c
+++ b/profiles/audio/csip.c
@@ -27,9 +27,9 @@
 
 #include "gdbus/gdbus.h"
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/dbus-common.h"
diff --git a/profiles/audio/mcp.c b/profiles/audio/mcp.c
index b410b3d2a..ff1eebeb7 100644
--- a/profiles/audio/mcp.c
+++ b/profiles/audio/mcp.c
@@ -27,9 +27,9 @@
 
 #include "gdbus/gdbus.h"
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/dbus-common.h"
diff --git a/profiles/audio/media.c b/profiles/audio/media.c
index edaff7867..0144d4adb 100644
--- a/profiles/audio/media.c
+++ b/profiles/audio/media.c
@@ -20,8 +20,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 #include "lib/mgmt.h"
 
diff --git a/profiles/audio/micp.c b/profiles/audio/micp.c
index 452027c75..9f13ddee2 100644
--- a/profiles/audio/micp.c
+++ b/profiles/audio/micp.c
@@ -27,9 +27,9 @@
 
 #include "gdbus/gdbus.h"
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/dbus-common.h"
diff --git a/profiles/audio/sink.c b/profiles/audio/sink.c
index a547dcb41..f22e6b8db 100644
--- a/profiles/audio/sink.c
+++ b/profiles/audio/sink.c
@@ -20,8 +20,8 @@
 #include <glib.h>
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gdbus/gdbus.h"
 
diff --git a/profiles/audio/source.c b/profiles/audio/source.c
index 9fac352c8..9d724543a 100644
--- a/profiles/audio/source.c
+++ b/profiles/audio/source.c
@@ -21,8 +21,8 @@
 #include <glib.h>
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gdbus/gdbus.h"
 
diff --git a/profiles/audio/transport.c b/profiles/audio/transport.c
index 159fbd575..fa0640a9f 100644
--- a/profiles/audio/transport.c
+++ b/profiles/audio/transport.c
@@ -19,8 +19,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/profiles/audio/vcp.c b/profiles/audio/vcp.c
index 175275f2e..7dc42ddf1 100644
--- a/profiles/audio/vcp.c
+++ b/profiles/audio/vcp.c
@@ -27,9 +27,9 @@
 
 #include "gdbus/gdbus.h"
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/dbus-common.h"
diff --git a/profiles/battery/bas.c b/profiles/battery/bas.c
index 16ff22e19..b408d0b6c 100644
--- a/profiles/battery/bas.c
+++ b/profiles/battery/bas.c
@@ -19,8 +19,8 @@
 
 #include "src/log.h"
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/profiles/battery/battery.c b/profiles/battery/battery.c
index 02d024d92..f731eda62 100644
--- a/profiles/battery/battery.c
+++ b/profiles/battery/battery.c
@@ -23,9 +23,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/profiles/cups/hcrp.c b/profiles/cups/hcrp.c
index 3038fe2f8..22ad3b45a 100644
--- a/profiles/cups/hcrp.c
+++ b/profiles/cups/hcrp.c
@@ -20,10 +20,10 @@
 #include <sys/socket.h>
 #include <netinet/in.h>
 
-#include "lib/bluetooth.h"
-#include "lib/l2cap.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/l2cap.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "cups.h"
 
diff --git a/profiles/cups/main.c b/profiles/cups/main.c
index 144a0fd78..bb3919ace 100644
--- a/profiles/cups/main.c
+++ b/profiles/cups/main.c
@@ -25,9 +25,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "gdbus/gdbus.h"
 
diff --git a/profiles/cups/sdp.c b/profiles/cups/sdp.c
index 81a26281c..ded5fafa1 100644
--- a/profiles/cups/sdp.c
+++ b/profiles/cups/sdp.c
@@ -18,9 +18,9 @@
 #include <signal.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "cups.h"
 
diff --git a/profiles/cups/spp.c b/profiles/cups/spp.c
index 6e910a722..79c207ef6 100644
--- a/profiles/cups/spp.c
+++ b/profiles/cups/spp.c
@@ -18,10 +18,10 @@
 #include <signal.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/rfcomm.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/rfcomm.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "cups.h"
 
diff --git a/profiles/deviceinfo/deviceinfo.c b/profiles/deviceinfo/deviceinfo.c
index b6dc0ab2e..187616e88 100644
--- a/profiles/deviceinfo/deviceinfo.c
+++ b/profiles/deviceinfo/deviceinfo.c
@@ -17,8 +17,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/plugin.h"
diff --git a/profiles/deviceinfo/dis.c b/profiles/deviceinfo/dis.c
index f660179ed..5c43e9c23 100644
--- a/profiles/deviceinfo/dis.c
+++ b/profiles/deviceinfo/dis.c
@@ -18,8 +18,8 @@
 
 #include "src/log.h"
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/profiles/gap/gas.c b/profiles/gap/gas.c
index 400818d67..d4b6206ff 100644
--- a/profiles/gap/gas.c
+++ b/profiles/gap/gas.c
@@ -23,9 +23,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/profiles/health/hdp.c b/profiles/health/hdp.c
index b6590cd3a..10e3bc208 100644
--- a/profiles/health/hdp.c
+++ b/profiles/health/hdp.c
@@ -19,9 +19,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/l2cap.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/l2cap.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gdbus/gdbus.h"
 
diff --git a/profiles/health/hdp_manager.c b/profiles/health/hdp_manager.c
index 23c6a4926..a497a17c8 100644
--- a/profiles/health/hdp_manager.c
+++ b/profiles/health/hdp_manager.c
@@ -13,8 +13,8 @@
 
 #include <stdbool.h>
 
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "btio/btio.h"
diff --git a/profiles/health/hdp_util.c b/profiles/health/hdp_util.c
index ad3702f01..77be8b40e 100644
--- a/profiles/health/hdp_util.c
+++ b/profiles/health/hdp_util.c
@@ -17,9 +17,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/profiles/health/mcap.c b/profiles/health/mcap.c
index 5d2bac3d9..a65cf247b 100644
--- a/profiles/health/mcap.c
+++ b/profiles/health/mcap.c
@@ -22,7 +22,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "bluetooth/l2cap.h"
 #include "btio/btio.h"
 #include "src/log.h"
diff --git a/profiles/input/device.c b/profiles/input/device.c
index 6c64ff1c1..0f991d16f 100644
--- a/profiles/input/device.c
+++ b/profiles/input/device.c
@@ -22,10 +22,10 @@
 #include <sys/ioctl.h>
 #include <sys/uio.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hidp.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hidp.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/profiles/input/hog-lib.c b/profiles/input/hog-lib.c
index 7ff1ede3d..833085e40 100644
--- a/profiles/input/hog-lib.c
+++ b/profiles/input/hog-lib.c
@@ -27,8 +27,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/profiles/input/hog.c b/profiles/input/hog.c
index d50b82321..b9f5a6d7a 100644
--- a/profiles/input/hog.c
+++ b/profiles/input/hog.c
@@ -24,8 +24,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/log.h"
diff --git a/profiles/input/manager.c b/profiles/input/manager.c
index 92789a003..248edb46f 100644
--- a/profiles/input/manager.c
+++ b/profiles/input/manager.c
@@ -15,9 +15,9 @@
 #include <errno.h>
 #include <stdbool.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "src/log.h"
diff --git a/profiles/input/server.c b/profiles/input/server.c
index 79cf08a66..2b9c6e5cb 100644
--- a/profiles/input/server.c
+++ b/profiles/input/server.c
@@ -19,8 +19,8 @@
 #include <glib.h>
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/log.h"
diff --git a/profiles/midi/midi.c b/profiles/midi/midi.c
index bab309bca..996bbd2a4 100644
--- a/profiles/midi/midi.c
+++ b/profiles/midi/midi.c
@@ -15,8 +15,8 @@
 #include <errno.h>
 #include <alsa/asoundlib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/plugin.h"
diff --git a/profiles/network/bnep.c b/profiles/network/bnep.c
index 54b950058..37223fc87 100644
--- a/profiles/network/bnep.c
+++ b/profiles/network/bnep.c
@@ -26,9 +26,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/l2cap.h"
-#include "lib/bnep.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/l2cap.h"
+#include "lib/bluetooth/bnep.h"
 #include "lib/uuid.h"
 
 #include "src/log.h"
diff --git a/profiles/network/connection.c b/profiles/network/connection.c
index 74d9d8944..2a771a6ec 100644
--- a/profiles/network/connection.c
+++ b/profiles/network/connection.c
@@ -21,9 +21,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/bnep.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/bnep.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gdbus/gdbus.h"
 
diff --git a/profiles/network/manager.c b/profiles/network/manager.c
index a2650d6f0..26aab8b2f 100644
--- a/profiles/network/manager.c
+++ b/profiles/network/manager.c
@@ -17,9 +17,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/bnep.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/bnep.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/log.h"
diff --git a/profiles/network/server.c b/profiles/network/server.c
index 96738f26c..a03e01284 100644
--- a/profiles/network/server.c
+++ b/profiles/network/server.c
@@ -21,10 +21,10 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/bnep.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/bnep.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/profiles/sap/manager.c b/profiles/sap/manager.c
index 6670f397c..e113406e1 100644
--- a/profiles/sap/manager.c
+++ b/profiles/sap/manager.c
@@ -12,8 +12,8 @@
 
 #include <stdbool.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "src/log.h"
 #include "src/adapter.h"
diff --git a/profiles/sap/server.c b/profiles/sap/server.c
index e6f3024ea..606f6464b 100644
--- a/profiles/sap/server.c
+++ b/profiles/sap/server.c
@@ -19,8 +19,8 @@
 #include <errno.h>
 #include <glib.h>
 
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/profiles/scanparam/scan.c b/profiles/scanparam/scan.c
index 739a9a46d..f66176504 100644
--- a/profiles/scanparam/scan.c
+++ b/profiles/scanparam/scan.c
@@ -16,8 +16,8 @@
 #include <stdbool.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/log.h"
diff --git a/profiles/scanparam/scpp.c b/profiles/scanparam/scpp.c
index 4be8b26cc..501e0db30 100644
--- a/profiles/scanparam/scpp.c
+++ b/profiles/scanparam/scpp.c
@@ -20,8 +20,8 @@
 
 #include "src/log.h"
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/src/adapter.h b/src/adapter.h
index ca96c1f65..67ad10d2a 100644
--- a/src/adapter.h
+++ b/src/adapter.h
@@ -13,8 +13,8 @@
 #include <dbus/dbus.h>
 #include <glib.h>
 
-#include <lib/bluetooth.h>
-#include <lib/sdp.h>
+#include <lib/bluetooth/bluetooth.h>
+#include <lib/bluetooth/sdp.h>
 
 #define ADAPTER_INTERFACE	"org.bluez.Adapter1"
 
diff --git a/src/adv_monitor.c b/src/adv_monitor.c
index cb38916fc..059f7e971 100644
--- a/src/adv_monitor.c
+++ b/src/adv_monitor.c
@@ -21,7 +21,7 @@
 #include <dbus/dbus.h>
 #include <gdbus/gdbus.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 
 #include "adapter.h"
diff --git a/src/advertising.c b/src/advertising.c
index 2c9a5a443..e4149ec67 100644
--- a/src/advertising.c
+++ b/src/advertising.c
@@ -20,9 +20,9 @@
 #include <dbus/dbus.h>
 #include <gdbus/gdbus.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "adapter.h"
 #include "dbus-common.h"
diff --git a/src/agent.c b/src/agent.c
index 7d66cf50d..120e4a075 100644
--- a/src/agent.c
+++ b/src/agent.c
@@ -23,8 +23,8 @@
 #include <glib.h>
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gdbus/gdbus.h"
 
diff --git a/src/battery.c b/src/battery.c
index 59e4fc570..42e32ae01 100644
--- a/src/battery.c
+++ b/src/battery.c
@@ -18,7 +18,7 @@
 #include <glib.h>
 
 #include "gdbus/gdbus.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "src/shared/queue.h"
 #include "src/shared/util.h"
 #include "battery.h"
diff --git a/src/device.c b/src/device.c
index 1db96d9a6..29ec563dd 100644
--- a/src/device.c
+++ b/src/device.c
@@ -27,9 +27,9 @@
 #include <glib.h>
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/src/eir.c b/src/eir.c
index 3e3ee2863..f324c50f6 100644
--- a/src/eir.c
+++ b/src/eir.c
@@ -21,9 +21,9 @@
 #include <stdbool.h>
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "src/shared/util.h"
 #include "uuid-helper.h"
diff --git a/src/eir.h b/src/eir.h
index f34291952..a61d525f3 100644
--- a/src/eir.h
+++ b/src/eir.h
@@ -11,7 +11,7 @@
 
 #include <glib.h>
 
-#include "lib/sdp.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #define EIR_FLAGS                   0x01  /* flags */
diff --git a/src/gatt-client.c b/src/gatt-client.c
index 60a21e3f6..23cd9856c 100644
--- a/src/gatt-client.c
+++ b/src/gatt-client.c
@@ -21,8 +21,8 @@
 
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/src/gatt-database.c b/src/gatt-database.c
index 7221ffc87..623821f95 100644
--- a/src/gatt-database.c
+++ b/src/gatt-database.c
@@ -17,9 +17,9 @@
 #include <errno.h>
 #include <unistd.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 #include "btio/btio.h"
 #include "gdbus/gdbus.h"
diff --git a/src/log.c b/src/log.c
index ca8ae2d0e..1ab79711c 100644
--- a/src/log.c
+++ b/src/log.c
@@ -25,8 +25,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/util.h"
 #include "src/shared/log.h"
diff --git a/src/main.c b/src/main.c
index b1339c230..7ca112203 100644
--- a/src/main.c
+++ b/src/main.c
@@ -30,8 +30,8 @@
 
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "gdbus/gdbus.h"
 #include "btio/btio.h"
diff --git a/src/oui.c b/src/oui.c
index 7b3040fb0..806fc5501 100644
--- a/src/oui.c
+++ b/src/oui.c
@@ -13,7 +13,7 @@
 #endif
 
 #define _GNU_SOURCE
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "oui.h"
 
 #ifdef HAVE_UDEV
diff --git a/src/plugin.c b/src/plugin.c
index e6d05be4c..4d20ca5c2 100644
--- a/src/plugin.c
+++ b/src/plugin.c
@@ -19,7 +19,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "btio/btio.h"
 #include "src/plugin.h"
diff --git a/src/profile.c b/src/profile.c
index ea188f36b..292faf5c0 100644
--- a/src/profile.c
+++ b/src/profile.c
@@ -21,9 +21,9 @@
 #include <glib.h>
 #include <dbus/dbus.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "gdbus/gdbus.h"
diff --git a/src/rfkill.c b/src/rfkill.c
index a0a50d9e4..edb07ff9a 100644
--- a/src/rfkill.c
+++ b/src/rfkill.c
@@ -23,8 +23,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "log.h"
 #include "adapter.h"
diff --git a/src/sdp-client.c b/src/sdp-client.c
index 71d3d9e95..bafcc025b 100644
--- a/src/sdp-client.c
+++ b/src/sdp-client.c
@@ -16,9 +16,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "btio/btio.h"
 #include "shared/timeout.h"
diff --git a/src/sdp-xml.c b/src/sdp-xml.c
index 5efa62ab8..727ecc22e 100644
--- a/src/sdp-xml.c
+++ b/src/sdp-xml.c
@@ -22,8 +22,8 @@
 
 #include <glib.h>
 
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "sdp-xml.h"
 
diff --git a/src/sdpd-database.c b/src/sdpd-database.c
index 35617abec..e34086909 100644
--- a/src/sdpd-database.c
+++ b/src/sdpd-database.c
@@ -18,9 +18,9 @@
 #include <stdlib.h>
 #include <stdbool.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "sdpd.h"
 #include "log.h"
diff --git a/src/sdpd-request.c b/src/sdpd-request.c
index c8f5a2c72..50bb2323f 100644
--- a/src/sdpd-request.c
+++ b/src/sdpd-request.c
@@ -20,10 +20,10 @@
 #include <limits.h>
 #include <stdbool.h>
 
-#include "lib/bluetooth.h"
-#include "lib/l2cap.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/l2cap.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "src/shared/util.h"
 
diff --git a/src/sdpd-server.c b/src/sdpd-server.c
index 748cbeb61..4c46af01b 100644
--- a/src/sdpd-server.c
+++ b/src/sdpd-server.c
@@ -25,10 +25,10 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/l2cap.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/l2cap.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "log.h"
 #include "sdpd.h"
diff --git a/src/sdpd-service.c b/src/sdpd-service.c
index 012438558..91fa7fd6f 100644
--- a/src/sdpd-service.c
+++ b/src/sdpd-service.c
@@ -23,9 +23,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "src/shared/util.h"
 #include "sdpd.h"
diff --git a/src/service.c b/src/service.c
index 7c4dc8fe0..82f95c647 100644
--- a/src/service.c
+++ b/src/service.c
@@ -23,8 +23,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
 
 #include "log.h"
 #include "backtrace.h"
diff --git a/src/settings.c b/src/settings.c
index 85534f2c7..e51f4146c 100644
--- a/src/settings.c
+++ b/src/settings.c
@@ -16,7 +16,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "log.h"
diff --git a/src/shared/ad.c b/src/shared/ad.c
index 2d6fc628e..c3dff8ef8 100644
--- a/src/shared/ad.c
+++ b/src/shared/ad.c
@@ -16,8 +16,8 @@
 
 #include <ctype.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/ad.h"
 
diff --git a/src/shared/ad.h b/src/shared/ad.h
index 87b3401a3..7e690655c 100644
--- a/src/shared/ad.h
+++ b/src/shared/ad.h
@@ -11,7 +11,7 @@
 #include <inttypes.h>
 #include <stdbool.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #define BT_AD_MAX_DATA_LEN		31
diff --git a/src/shared/att.c b/src/shared/att.c
index 485ef071b..ac43cfd71 100644
--- a/src/shared/att.c
+++ b/src/shared/att.c
@@ -20,8 +20,8 @@
 #include "src/shared/queue.h"
 #include "src/shared/util.h"
 #include "src/shared/timeout.h"
-#include "lib/bluetooth.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/l2cap.h"
 #include "lib/uuid.h"
 #include "src/shared/att.h"
 #include "src/shared/crypto.h"
diff --git a/src/shared/bap.c b/src/shared/bap.c
index e26dbf944..b33d22898 100644
--- a/src/shared/bap.c
+++ b/src/shared/bap.c
@@ -16,7 +16,7 @@
 #include <unistd.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/io.h"
diff --git a/src/shared/bass.c b/src/shared/bass.c
index 3f5bf307c..82b80f435 100644
--- a/src/shared/bass.c
+++ b/src/shared/bass.c
@@ -16,7 +16,7 @@
 #include <errno.h>
 #include <poll.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "lib/iso.h"
 
diff --git a/src/shared/btp.c b/src/shared/btp.c
index e54eb830f..aa5ddeb23 100644
--- a/src/shared/btp.c
+++ b/src/shared/btp.c
@@ -15,7 +15,7 @@
 
 #include <ell/ell.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "src/shared/btp.h"
 
 #define BTP_MTU 512
diff --git a/src/shared/ccp.c b/src/shared/ccp.c
index 8e1b0b58f..a744382ed 100644
--- a/src/shared/ccp.c
+++ b/src/shared/ccp.c
@@ -15,9 +15,9 @@
 #include <unistd.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/queue.h"
 #include "src/shared/util.h"
diff --git a/src/shared/csip.c b/src/shared/csip.c
index e13efb6ce..af1bf43f3 100644
--- a/src/shared/csip.c
+++ b/src/shared/csip.c
@@ -17,7 +17,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/queue.h"
diff --git a/src/shared/gap.c b/src/shared/gap.c
index 6fb1b7b69..796fcfd11 100644
--- a/src/shared/gap.c
+++ b/src/shared/gap.c
@@ -15,7 +15,7 @@
 #include <stdio.h>
 #include <stdlib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 
 #include "src/shared/util.h"
diff --git a/src/shared/gatt-client.c b/src/shared/gatt-client.c
index 6340bcd85..8f239e269 100644
--- a/src/shared/gatt-client.c
+++ b/src/shared/gatt-client.c
@@ -13,7 +13,7 @@
 #endif
 
 #include "src/shared/att.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/gatt-helpers.h"
 #include "src/shared/util.h"
diff --git a/src/shared/gatt-db.c b/src/shared/gatt-db.c
index 9559583d1..836adf83d 100644
--- a/src/shared/gatt-db.c
+++ b/src/shared/gatt-db.c
@@ -15,7 +15,7 @@
 #include <stdbool.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/util.h"
 #include "src/shared/queue.h"
diff --git a/src/shared/gatt-helpers.c b/src/shared/gatt-helpers.c
index 50fcb269b..8732ca34d 100644
--- a/src/shared/gatt-helpers.c
+++ b/src/shared/gatt-helpers.c
@@ -15,7 +15,7 @@
 
 #include "src/shared/queue.h"
 #include "src/shared/att.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/gatt-helpers.h"
 #include "src/shared/util.h"
diff --git a/src/shared/gatt-server.c b/src/shared/gatt-server.c
index c7ce3ec1f..3a3036ef2 100644
--- a/src/shared/gatt-server.c
+++ b/src/shared/gatt-server.c
@@ -17,7 +17,7 @@
 #include <errno.h>
 
 #include "src/shared/att.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/queue.h"
 #include "src/shared/gatt-db.h"
diff --git a/src/shared/log.c b/src/shared/log.c
index 22b9850f6..439bbd66e 100644
--- a/src/shared/log.c
+++ b/src/shared/log.c
@@ -23,8 +23,8 @@
 #include <signal.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/util.h"
 #include "src/shared/log.h"
diff --git a/src/shared/mcp.c b/src/shared/mcp.c
index b3726ebae..ae4e61712 100644
--- a/src/shared/mcp.c
+++ b/src/shared/mcp.c
@@ -15,9 +15,9 @@
 #include <unistd.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/queue.h"
 #include "src/shared/util.h"
diff --git a/src/shared/mgmt.c b/src/shared/mgmt.c
index 4d7b64f2b..6c3beeb96 100644
--- a/src/shared/mgmt.c
+++ b/src/shared/mgmt.c
@@ -17,9 +17,9 @@
 #include <string.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/io.h"
 #include "src/shared/queue.h"
diff --git a/src/shared/micp.c b/src/shared/micp.c
index b82bd92de..0c5311232 100644
--- a/src/shared/micp.c
+++ b/src/shared/micp.c
@@ -14,7 +14,7 @@
 #include <unistd.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/queue.h"
diff --git a/src/shared/tester.c b/src/shared/tester.c
index a1ee5b687..0269297be 100644
--- a/src/shared/tester.c
+++ b/src/shared/tester.c
@@ -25,8 +25,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #ifdef HAVE_VALGRIND_MEMCHECK_H
 #include <valgrind/memcheck.h>
diff --git a/src/shared/util.c b/src/shared/util.c
index c0c2c4a17..c7b715839 100644
--- a/src/shared/util.c
+++ b/src/shared/util.c
@@ -29,7 +29,7 @@
 #include <sys/random.h>
 #endif
 
-#include <lib/bluetooth.h>
+#include <lib/bluetooth/bluetooth.h>
 
 /* define MAX_INPUT for musl */
 #ifndef MAX_INPUT
diff --git a/src/shared/vcp.c b/src/shared/vcp.c
index 7ba54e64a..2d06bbf58 100644
--- a/src/shared/vcp.c
+++ b/src/shared/vcp.c
@@ -15,7 +15,7 @@
 #include <unistd.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/queue.h"
diff --git a/src/storage.c b/src/storage.c
index 6e69be978..084fc249e 100644
--- a/src/storage.c
+++ b/src/storage.c
@@ -26,9 +26,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 #include "lib/uuid.h"
 
 #include "textfile.h"
diff --git a/src/uuid-helper.c b/src/uuid-helper.c
index b62b1af82..151fb8afc 100644
--- a/src/uuid-helper.c
+++ b/src/uuid-helper.c
@@ -19,9 +19,9 @@
 #include <errno.h>
 #include <arpa/inet.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "uuid-helper.h"
 
diff --git a/tools/advtest.c b/tools/advtest.c
index 9ef69ed51..286c3a787 100644
--- a/tools/advtest.c
+++ b/tools/advtest.c
@@ -22,7 +22,7 @@
 
 #include <getopt.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 
 #include "monitor/bt.h"
diff --git a/tools/amptest.c b/tools/amptest.c
index 193cadd25..0ce431857 100644
--- a/tools/amptest.c
+++ b/tools/amptest.c
@@ -23,9 +23,9 @@
 #include <sys/ioctl.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 static int activate_amp_controller(int dev_id)
 {
diff --git a/tools/avinfo.c b/tools/avinfo.c
index 2f68f53e7..e2dd707f1 100644
--- a/tools/avinfo.c
+++ b/tools/avinfo.c
@@ -27,10 +27,10 @@
 #include <sys/ioctl.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/l2cap.h"
 
 #include "profiles/audio/a2dp-codecs.h"
 
diff --git a/tools/avtest.c b/tools/avtest.c
index 5ac3418aa..75a2a1dee 100644
--- a/tools/avtest.c
+++ b/tools/avtest.c
@@ -22,11 +22,11 @@
 #include <sys/socket.h>
 #include <netinet/in.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/l2cap.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/l2cap.h"
+#include "lib/bluetooth/sdp.h"
 
 #define AVDTP_PKT_TYPE_SINGLE		0x00
 #define AVDTP_PKT_TYPE_START		0x01
diff --git a/tools/bdaddr.c b/tools/bdaddr.c
index bc0478d46..e7d9e0462 100644
--- a/tools/bdaddr.c
+++ b/tools/bdaddr.c
@@ -20,9 +20,9 @@
 #include <sys/ioctl.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "src/oui.h"
 
diff --git a/tools/bluetooth-player.c b/tools/bluetooth-player.c
index eba104d09..342e727c1 100644
--- a/tools/bluetooth-player.c
+++ b/tools/bluetooth-player.c
@@ -26,7 +26,7 @@
 #include <glib.h>
 
 #include "gdbus/gdbus.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/tools/bnep-tester.c b/tools/bnep-tester.c
index 5e4d7fb6d..246bdaa1b 100644
--- a/tools/bnep-tester.c
+++ b/tools/bnep-tester.c
@@ -20,8 +20,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/bnep.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/bnep.h"
 #include "lib/mgmt.h"
 
 #include "monitor/bt.h"
diff --git a/tools/bneptest.c b/tools/bneptest.c
index 76ec1cfcd..c39c013e2 100644
--- a/tools/bneptest.c
+++ b/tools/bneptest.c
@@ -28,14 +28,14 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "src/log.h"
 #include "src/shared/util.h"
 #include "btio/btio.h"
-#include "lib/bnep.h"
+#include "lib/bluetooth/bnep.h"
 #include "profiles/network/bnep.h"
 
 enum {
diff --git a/tools/btattach.c b/tools/btattach.c
index 4ce1be78d..afcfedecf 100644
--- a/tools/btattach.c
+++ b/tools/btattach.c
@@ -25,9 +25,9 @@
 #include <sys/ioctl.h>
 #include <poll.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "hciattach.h"
 #include "monitor/bt.h"
diff --git a/tools/btgatt-client.c b/tools/btgatt-client.c
index b47914da3..633eec4d2 100644
--- a/tools/btgatt-client.c
+++ b/tools/btgatt-client.c
@@ -21,10 +21,10 @@
 #include <limits.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/l2cap.h"
 #include "lib/uuid.h"
 
 #include "src/shared/mainloop.h"
diff --git a/tools/btgatt-server.c b/tools/btgatt-server.c
index 90a6c9b0a..8a56c78c4 100644
--- a/tools/btgatt-server.c
+++ b/tools/btgatt-server.c
@@ -21,10 +21,10 @@
 #include <unistd.h>
 #include <errno.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/l2cap.h"
 #include "lib/uuid.h"
 
 #include "src/shared/mainloop.h"
diff --git a/tools/btiotest.c b/tools/btiotest.c
index 75af90543..db37f75f0 100644
--- a/tools/btiotest.c
+++ b/tools/btiotest.c
@@ -23,7 +23,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "btio/btio.h"
 
diff --git a/tools/btmon-logger.c b/tools/btmon-logger.c
index a770ad575..191f7337f 100644
--- a/tools/btmon-logger.c
+++ b/tools/btmon-logger.c
@@ -29,8 +29,8 @@
 
 #include <linux/capability.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 
 #include "src/shared/util.h"
 #include "src/shared/mainloop.h"
diff --git a/tools/btpclient.c b/tools/btpclient.c
index bdfff5df8..b32ed89a6 100644
--- a/tools/btpclient.c
+++ b/tools/btpclient.c
@@ -20,7 +20,7 @@
 
 #include <ell/ell.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "src/shared/btp.h"
 
 #define AD_PATH "/org/bluez/advertising"
diff --git a/tools/btpclientctl.c b/tools/btpclientctl.c
index c30d5bd4e..b7649d0c7 100644
--- a/tools/btpclientctl.c
+++ b/tools/btpclientctl.c
@@ -22,7 +22,7 @@
 #include <fcntl.h>
 #include <poll.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "src/shared/ad.h"
 #include "src/shared/btp.h"
diff --git a/tools/ciptool.c b/tools/ciptool.c
index 0d6272da9..3b91422e0 100644
--- a/tools/ciptool.c
+++ b/tools/ciptool.c
@@ -24,13 +24,13 @@
 #include <sys/ioctl.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/l2cap.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
-#include "lib/cmtp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/l2cap.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
+#include "lib/bluetooth/cmtp.h"
 
 static volatile sig_atomic_t __io_canceled = 0;
 
diff --git a/tools/cltest.c b/tools/cltest.c
index 250c93cc7..5d2733f38 100644
--- a/tools/cltest.c
+++ b/tools/cltest.c
@@ -23,10 +23,10 @@
 #include <sys/ioctl.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/l2cap.h"
 
 #include "src/shared/mainloop.h"
 
diff --git a/tools/hciattach.c b/tools/hciattach.c
index 276a4e56e..4c9a6fb5b 100644
--- a/tools/hciattach.c
+++ b/tools/hciattach.c
@@ -30,9 +30,9 @@
 #include <sys/param.h>
 #include <sys/ioctl.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "src/shared/tty.h"
 
diff --git a/tools/hciattach_ath3k.c b/tools/hciattach_ath3k.c
index d119155bb..967399510 100644
--- a/tools/hciattach_ath3k.c
+++ b/tools/hciattach_ath3k.c
@@ -22,9 +22,9 @@
 #include <sys/param.h>
 #include <sys/ioctl.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "hciattach.h"
 
diff --git a/tools/hciattach_bcm43xx.c b/tools/hciattach_bcm43xx.c
index b89fc1b50..b381e1767 100644
--- a/tools/hciattach_bcm43xx.c
+++ b/tools/hciattach_bcm43xx.c
@@ -24,9 +24,9 @@
 #include <time.h>
 #include <limits.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "hciattach.h"
 
diff --git a/tools/hciattach_intel.c b/tools/hciattach_intel.c
index e243b3d07..7a857ebef 100644
--- a/tools/hciattach_intel.c
+++ b/tools/hciattach_intel.c
@@ -23,9 +23,9 @@
 #include <sys/ioctl.h>
 #include <time.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "hciattach.h"
 
diff --git a/tools/hciattach_qualcomm.c b/tools/hciattach_qualcomm.c
index d751f42b1..fd57361f7 100644
--- a/tools/hciattach_qualcomm.c
+++ b/tools/hciattach_qualcomm.c
@@ -30,9 +30,9 @@
 #include <sys/ioctl.h>
 #include <sys/uio.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "hciattach.h"
 
diff --git a/tools/hciattach_st.c b/tools/hciattach_st.c
index 4a7186aa6..3cb3a46ac 100644
--- a/tools/hciattach_st.c
+++ b/tools/hciattach_st.c
@@ -22,7 +22,7 @@
 #include <dirent.h>
 #include <sys/param.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "hciattach.h"
 
diff --git a/tools/hciattach_ti.c b/tools/hciattach_ti.c
index 24efceaa1..c2b3046ed 100644
--- a/tools/hciattach_ti.c
+++ b/tools/hciattach_ti.c
@@ -25,9 +25,9 @@
 #include <sys/param.h>
 #include <sys/ioctl.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "hciattach.h"
 
diff --git a/tools/hciattach_tialt.c b/tools/hciattach_tialt.c
index bf6e84923..109b5a646 100644
--- a/tools/hciattach_tialt.c
+++ b/tools/hciattach_tialt.c
@@ -29,9 +29,9 @@
 #include <sys/ioctl.h>
 #include <sys/uio.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "hciattach.h"
 
diff --git a/tools/hciconfig.c b/tools/hciconfig.c
index a1c615bfa..7a63a370e 100644
--- a/tools/hciconfig.c
+++ b/tools/hciconfig.c
@@ -27,9 +27,9 @@
 #include <sys/socket.h>
 #include <sys/stat.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "src/textfile.h"
 #include "src/shared/util.h"
diff --git a/tools/hcidump.c b/tools/hcidump.c
index d517031dc..fa9491554 100644
--- a/tools/hcidump.c
+++ b/tools/hcidump.c
@@ -30,8 +30,8 @@
 #include "parser/parser.h"
 #include "parser/sdp.h"
 
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #define SNAP_LEN	HCI_MAX_FRAME_SIZE
 
diff --git a/tools/hcieventmask.c b/tools/hcieventmask.c
index 0e7fe5fd7..bb057542e 100644
--- a/tools/hcieventmask.c
+++ b/tools/hcieventmask.c
@@ -18,9 +18,9 @@
 #include <getopt.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 static struct option main_options[] = {
 	{ "device",	1, 0, 'i' },
diff --git a/tools/hcisecfilter.c b/tools/hcisecfilter.c
index 46cdbf381..8acdb9928 100644
--- a/tools/hcisecfilter.c
+++ b/tools/hcisecfilter.c
@@ -16,9 +16,9 @@
 #include <stdio.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 int main(int argc, char *argv[])
 {
diff --git a/tools/hcitool.c b/tools/hcitool.c
index 639ee6a51..163dc7b1d 100644
--- a/tools/hcitool.c
+++ b/tools/hcitool.c
@@ -28,9 +28,9 @@
 #include <sys/socket.h>
 #include <signal.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "src/oui.h"
 
diff --git a/tools/hwdb.c b/tools/hwdb.c
index 4b37c753d..409135224 100644
--- a/tools/hwdb.c
+++ b/tools/hwdb.c
@@ -14,7 +14,7 @@
 
 #include <stdio.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 static const struct {
 	uint16_t vendor;
diff --git a/tools/ioctl-tester.c b/tools/ioctl-tester.c
index 098b58608..246449386 100644
--- a/tools/ioctl-tester.c
+++ b/tools/ioctl-tester.c
@@ -22,10 +22,10 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "monitor/bt.h"
 #include "emulator/bthost.h"
diff --git a/tools/iso-tester.c b/tools/iso-tester.c
index d1f0be180..6b5582903 100644
--- a/tools/iso-tester.c
+++ b/tools/iso-tester.c
@@ -20,7 +20,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/iso.h"
 #include "lib/mgmt.h"
 
diff --git a/tools/isotest.c b/tools/isotest.c
index 7e875fa58..11fcaf2ba 100644
--- a/tools/isotest.c
+++ b/tools/isotest.c
@@ -35,9 +35,9 @@
 #include <sys/wait.h>
 #include <poll.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 #include "lib/mgmt.h"
 #include "lib/iso.h"
 
diff --git a/tools/l2cap-tester.c b/tools/l2cap-tester.c
index 461f2c27c..de0c0419f 100644
--- a/tools/l2cap-tester.c
+++ b/tools/l2cap-tester.c
@@ -20,8 +20,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/l2cap.h"
 #include "lib/mgmt.h"
 
 #include "monitor/bt.h"
diff --git a/tools/l2ping.c b/tools/l2ping.c
index c44ce872f..ae45da5ac 100644
--- a/tools/l2ping.c
+++ b/tools/l2ping.c
@@ -26,10 +26,10 @@
 #include <poll.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/l2cap.h"
 
 /* Defaults */
 static bdaddr_t bdaddr;
diff --git a/tools/l2test.c b/tools/l2test.c
index 011a68c37..c3fcfa716 100644
--- a/tools/l2test.c
+++ b/tools/l2test.c
@@ -30,10 +30,10 @@
 #include <sys/ioctl.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/l2cap.h"
 
 #include "src/shared/util.h"
 #include "monitor/display.h"
diff --git a/tools/mcaptest.c b/tools/mcaptest.c
index dcef0b908..f57754e68 100644
--- a/tools/mcaptest.c
+++ b/tools/mcaptest.c
@@ -20,12 +20,12 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #include "btio/btio.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/l2cap.h"
 #include "profiles/health/mcap.h"
 
 enum {
diff --git a/tools/mesh-gatt/gatt.c b/tools/mesh-gatt/gatt.c
index ab9743cd1..4c7b0aa52 100644
--- a/tools/mesh-gatt/gatt.c
+++ b/tools/mesh-gatt/gatt.c
@@ -26,7 +26,7 @@
 #include "src/shared/shell.h"
 #include "src/shared/util.h"
 #include "gdbus/gdbus.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "tools/mesh-gatt/node.h"
diff --git a/tools/mesh-tester.c b/tools/mesh-tester.c
index d7b3b6f9b..61eb9be63 100644
--- a/tools/mesh-tester.c
+++ b/tools/mesh-tester.c
@@ -23,11 +23,11 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 #include "lib/mgmt.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/l2cap.h"
 
 #include "monitor/bt.h"
 #include "emulator/vhci.h"
diff --git a/tools/mesh/agent.c b/tools/mesh/agent.c
index ee0fade24..b79b04737 100644
--- a/tools/mesh/agent.c
+++ b/tools/mesh/agent.c
@@ -17,7 +17,7 @@
 #include <stdbool.h>
 #include <inttypes.h>
 
-#include <lib/bluetooth.h>
+#include <lib/bluetooth/bluetooth.h>
 
 #include "src/shared/shell.h"
 #include "tools/mesh/agent.h"
diff --git a/tools/meshctl.c b/tools/meshctl.c
index 38ffd35f3..2455298e4 100644
--- a/tools/meshctl.c
+++ b/tools/meshctl.c
@@ -29,7 +29,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/shell.h"
 #include "src/shared/util.h"
diff --git a/tools/mgmt-tester.c b/tools/mgmt-tester.c
index e85fbacda..be85e13c1 100644
--- a/tools/mgmt-tester.c
+++ b/tools/mgmt-tester.c
@@ -24,11 +24,11 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 #include "lib/mgmt.h"
-#include "lib/l2cap.h"
+#include "lib/bluetooth/l2cap.h"
 
 #include "monitor/bt.h"
 #include "emulator/vhci.h"
diff --git a/tools/oobtest.c b/tools/oobtest.c
index eed765af0..4ed067c72 100644
--- a/tools/oobtest.c
+++ b/tools/oobtest.c
@@ -15,7 +15,7 @@
 
 #include <getopt.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 
 #include "src/shared/mainloop.h"
diff --git a/tools/parser/hci.c b/tools/parser/hci.c
index db7d32c01..a9cb536e2 100644
--- a/tools/parser/hci.c
+++ b/tools/parser/hci.c
@@ -22,8 +22,8 @@
 #include <string.h>
 
 #include "parser.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 #include "lib/amp.h"
 
 static uint16_t manufacturer = DEFAULT_COMPID;
diff --git a/tools/parser/l2cap.c b/tools/parser/l2cap.c
index 562093ad0..45e92a666 100644
--- a/tools/parser/l2cap.c
+++ b/tools/parser/l2cap.c
@@ -24,7 +24,7 @@
 #include "parser.h"
 #include "sdp.h"
 #include "l2cap.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/hci.h"
 #include "lib/a2mp.h"
 #include "lib/amp.h"
 
diff --git a/tools/parser/lmp.c b/tools/parser/lmp.c
index 94b642896..abdaddbf1 100644
--- a/tools/parser/lmp.c
+++ b/tools/parser/lmp.c
@@ -19,8 +19,8 @@
 #include <sys/socket.h>
 
 #include "parser.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 
 #define LMP_U8(frm)  (p_get_u8(frm))
 #define LMP_U16(frm) (btohs(htons(p_get_u16(frm))))
diff --git a/tools/parser/parser.h b/tools/parser/parser.h
index 5f65f1689..45ef912a7 100644
--- a/tools/parser/parser.h
+++ b/tools/parser/parser.h
@@ -16,7 +16,7 @@
 #include <sys/time.h>
 #include <netinet/in.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "src/shared/util.h"
 
 struct frame {
diff --git a/tools/rctest.c b/tools/rctest.c
index d31180880..bf60dd94b 100644
--- a/tools/rctest.c
+++ b/tools/rctest.c
@@ -28,12 +28,12 @@
 #include <sys/socket.h>
 #include <sys/stat.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/rfcomm.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/rfcomm.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "src/shared/util.h"
 
diff --git a/tools/rfcomm-tester.c b/tools/rfcomm-tester.c
index a9adf7f0f..efff2053f 100644
--- a/tools/rfcomm-tester.c
+++ b/tools/rfcomm-tester.c
@@ -20,8 +20,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/rfcomm.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/rfcomm.h"
 #include "lib/mgmt.h"
 
 #include "monitor/bt.h"
diff --git a/tools/rfcomm.c b/tools/rfcomm.c
index e013ff588..866b4656c 100644
--- a/tools/rfcomm.c
+++ b/tools/rfcomm.c
@@ -28,10 +28,10 @@
 #include <sys/socket.h>
 #include <sys/wait.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/rfcomm.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/rfcomm.h"
 
 static int rfcomm_raw_tty = 0;
 static int auth = 0;
diff --git a/tools/sco-tester.c b/tools/sco-tester.c
index ecc65e092..402eada17 100644
--- a/tools/sco-tester.c
+++ b/tools/sco-tester.c
@@ -19,8 +19,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sco.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sco.h"
 #include "lib/mgmt.h"
 
 #include "monitor/bt.h"
diff --git a/tools/scotest.c b/tools/scotest.c
index e6a88770f..41c20645d 100644
--- a/tools/scotest.c
+++ b/tools/scotest.c
@@ -25,8 +25,8 @@
 #include <sys/time.h>
 #include <sys/socket.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sco.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sco.h"
 
 #include "src/shared/util.h"
 
diff --git a/tools/sdptool.c b/tools/sdptool.c
index 686d28362..2517b2e84 100644
--- a/tools/sdptool.c
+++ b/tools/sdptool.c
@@ -26,11 +26,11 @@
 #include <sys/socket.h>
 #include <netinet/in.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "src/sdp-xml.h"
 
diff --git a/tools/smp-tester.c b/tools/smp-tester.c
index 16fe0dfd7..edd06cdf4 100644
--- a/tools/smp-tester.c
+++ b/tools/smp-tester.c
@@ -20,8 +20,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 #include "lib/mgmt.h"
 
 #include "monitor/bt.h"
diff --git a/tools/test-runner.c b/tools/test-runner.c
index 243eab468..83e0d5599 100644
--- a/tools/test-runner.c
+++ b/tools/test-runner.c
@@ -30,9 +30,9 @@
 #include <sys/param.h>
 #include <sys/reboot.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/hci_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/hci_lib.h"
 #include "tools/hciattach.h"
 
 #ifndef WAIT_ANY
diff --git a/tools/userchan-tester.c b/tools/userchan-tester.c
index 095ef2689..e6ba15738 100644
--- a/tools/userchan-tester.c
+++ b/tools/userchan-tester.c
@@ -20,8 +20,8 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
 #include "lib/mgmt.h"
 
 #include "monitor/bt.h"
diff --git a/unit/test-avrcp.c b/unit/test-avrcp.c
index b637a8a1b..89c2cee1e 100644
--- a/unit/test-avrcp.c
+++ b/unit/test-avrcp.c
@@ -26,7 +26,7 @@
 #include "src/shared/util.h"
 #include "src/shared/tester.h"
 #include "src/log.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 
 #include "android/avctp.h"
 #include "android/avrcp-lib.h"
diff --git a/unit/test-bap.c b/unit/test-bap.c
index ecd5e2897..0e51ac303 100644
--- a/unit/test-bap.c
+++ b/unit/test-bap.c
@@ -20,7 +20,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/util.h"
 #include "src/shared/io.h"
diff --git a/unit/test-bass.c b/unit/test-bass.c
index ace47d9ed..5859a6255 100644
--- a/unit/test-bass.c
+++ b/unit/test-bass.c
@@ -20,7 +20,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/util.h"
 #include "src/shared/io.h"
diff --git a/unit/test-eir.c b/unit/test-eir.c
index 49ce65f24..9fd13f46f 100644
--- a/unit/test-eir.c
+++ b/unit/test-eir.c
@@ -16,9 +16,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/hci.h"
-#include "lib/sdp.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/hci.h"
+#include "lib/bluetooth/sdp.h"
 #include "src/shared/tester.h"
 #include "src/shared/util.h"
 #include "src/shared/ad.h"
diff --git a/unit/test-gatt.c b/unit/test-gatt.c
index 5e06d4ed4..32f9874a3 100644
--- a/unit/test-gatt.c
+++ b/unit/test-gatt.c
@@ -22,7 +22,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/util.h"
 #include "src/shared/att.h"
diff --git a/unit/test-gattrib.c b/unit/test-gattrib.c
index 9c7dea094..f56192998 100644
--- a/unit/test-gattrib.c
+++ b/unit/test-gattrib.c
@@ -23,7 +23,7 @@
 #include <glib.h>
 
 #include "src/shared/util.h"
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "attrib/att.h"
 #include "attrib/gattrib.h"
diff --git a/unit/test-hog.c b/unit/test-hog.c
index 067497de4..9af50a140 100644
--- a/unit/test-hog.c
+++ b/unit/test-hog.c
@@ -20,7 +20,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 
 #include "src/shared/util.h"
diff --git a/unit/test-lib.c b/unit/test-lib.c
index 8395c2a73..aefe6f996 100644
--- a/unit/test-lib.c
+++ b/unit/test-lib.c
@@ -21,8 +21,8 @@
 #include "src/shared/util.h"
 #include "src/shared/tester.h"
 
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 static void test_ntoh64(const void *data)
 {
diff --git a/unit/test-mgmt.c b/unit/test-mgmt.c
index 1b71e562f..2d7eaa886 100644
--- a/unit/test-mgmt.c
+++ b/unit/test-mgmt.c
@@ -18,7 +18,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/mgmt.h"
 
 #include "src/shared/mgmt.h"
diff --git a/unit/test-micp.c b/unit/test-micp.c
index a7fc7fb32..896547f57 100644
--- a/unit/test-micp.c
+++ b/unit/test-micp.c
@@ -20,7 +20,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/util.h"
 #include "src/shared/tester.h"
diff --git a/unit/test-sdp.c b/unit/test-sdp.c
index 5c04a71eb..0c1d08b9b 100644
--- a/unit/test-sdp.c
+++ b/unit/test-sdp.c
@@ -20,9 +20,9 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
-#include "lib/sdp.h"
-#include "lib/sdp_lib.h"
+#include "lib/bluetooth/bluetooth.h"
+#include "lib/bluetooth/sdp.h"
+#include "lib/bluetooth/sdp_lib.h"
 
 #include "src/shared/util.h"
 #include "src/shared/tester.h"
diff --git a/unit/test-uuid.c b/unit/test-uuid.c
index 0889630cf..b0721084c 100644
--- a/unit/test-uuid.c
+++ b/unit/test-uuid.c
@@ -14,7 +14,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/tester.h"
 
diff --git a/unit/test-vcp.c b/unit/test-vcp.c
index 6a61ea2c4..a8f230b35 100644
--- a/unit/test-vcp.c
+++ b/unit/test-vcp.c
@@ -20,7 +20,7 @@
 
 #include <glib.h>
 
-#include "lib/bluetooth.h"
+#include "lib/bluetooth/bluetooth.h"
 #include "lib/uuid.h"
 #include "src/shared/util.h"
 #include "src/shared/tester.h"

-- 
2.43.1

