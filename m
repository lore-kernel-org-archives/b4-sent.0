From: Ye He <ye.he@amlogic.com>
Date: Fri, 21 Nov 2025 16:54:12 +0800
Subject: [PATCH bluez v4] bearer: Implement Connect/Disconnect methods
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251121-bearer-impl-v4-1-b52149dfd9a6@amlogic.com>
X-B4-Tracking: v=1; b=H4sIALMoIGkC/23NTQ6DIBAF4Ks0rEsjf0K76j2aLhBGJVEx0JK2x
 ruXsNLE2b2ZfG8WFCE4iOh2WlCA5KLzUw78fEKm11MH2NmcEa2oIHlwAzpAwG6cByxaCexaE8m
 1RlnMAVr3KW0P1Axv+KFnXvcuvnz4lh+JlONhXSKY4JYToQThnBJ11+PgO2cuxo+lKdGtZntNs
 zYMFBXG1FIcaLbVaq9Z1lZbY1VTGSnsXq/r+gfxIiCsKwEAAA==
X-Change-ID: 20251111-bearer-impl-5f7e396174aa
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763715253; l=29881;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=dVml1nCJXn8wV4LGM4XXS8igQZ9JejeUCBlmMyiveI4=;
 b=P+P8eeqv/MRWdLqRdgFEgtnMy9YWmt33AXZAI6+Dxs+BhI/O59Vkuyu+vv0ogCPjFF0uLr4B7
 09cWMS7EFmnDod0PDmA1/YTGph8cRZ6xK4fPtJ4eEZGpqhl3SL+6dL0
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch provides implementations for the Connect and Disconnect
methods of the org.bluez.Bearer.LE1 and org.bluez.Bearer.BREDR1
interfaces.

Signed-off-by: Ye He <ye.he@amlogic.com>
---
Changes in v4:
- Add a bearer field to btd_profile to indicate which bearer type the profile
- belongs to, thus we can distinct the services per bearer.
- Link to v3: https://patch.msgid.link/20251118-bearer-impl-v3-1-dadcd8b0c75d@amlogic.com

Changes in v3:
- Move the modification logic from the device to bearer, and add
- some helper functions to the device.
- Link to v2: https://patch.msgid.link/20251113-bearer-impl-v2-1-c3e825cc6758@amlogic.com

Changes in v2:
- Fix build error & warning.
- Link to v1: https://patch.msgid.link/20251111-bearer-impl-v1-1-f41585144218@amlogic.com
---
 profiles/audio/a2dp.c         |   2 +
 profiles/audio/asha.c         |   2 +
 profiles/audio/avrcp.c        |   2 +
 profiles/audio/bap.c          |   2 +
 profiles/audio/bass.c         |   1 +
 profiles/audio/ccp.c          |   1 +
 profiles/audio/csip.c         |   2 +
 profiles/audio/mcp.c          |   1 +
 profiles/audio/micp.c         |   1 +
 profiles/audio/vcp.c          |   1 +
 profiles/health/hdp_manager.c |   2 +
 profiles/input/hog.c          |   1 +
 profiles/input/manager.c      |   2 +
 profiles/midi/midi.c          |   1 +
 profiles/network/manager.c    |   3 +
 profiles/scanparam/scan.c     |   1 +
 src/bearer.c                  | 192 +++++++++++++++++++++++++++++++++++++++++-
 src/device.c                  | 158 +++++++++++++++++++++++++++++-----
 src/device.h                  |  17 ++++
 src/profile.h                 |  10 +++
 20 files changed, 380 insertions(+), 22 deletions(-)

diff --git a/profiles/audio/a2dp.c b/profiles/audio/a2dp.c
index d8f24eaebc745a6d91a8207f6595f0b90d982c39..7f7917fc066b7b7e9176c6a99ee510ff8a3ac15c 100644
--- a/profiles/audio/a2dp.c
+++ b/profiles/audio/a2dp.c
@@ -3757,6 +3757,7 @@ static void media_server_remove(struct btd_adapter *adapter)
 static struct btd_profile a2dp_source_profile = {
 	.name		= "a2dp-source",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 
 	.remote_uuid	= A2DP_SOURCE_UUID,
 	.device_probe	= a2dp_source_probe,
@@ -3773,6 +3774,7 @@ static struct btd_profile a2dp_source_profile = {
 static struct btd_profile a2dp_sink_profile = {
 	.name		= "a2dp-sink",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 
 	.remote_uuid	= A2DP_SINK_UUID,
 	.device_probe	= a2dp_sink_probe,
diff --git a/profiles/audio/asha.c b/profiles/audio/asha.c
index e870ea06f03ac1c20e5b29fb158c815aa2ce756c..94414ea815215cf7e0825bd09dff5bdb106e6338 100644
--- a/profiles/audio/asha.c
+++ b/profiles/audio/asha.c
@@ -499,6 +499,8 @@ static int asha_source_disconnect(struct btd_service *service)
 static struct btd_profile asha_source_profile = {
 	.name		= "asha-source",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
+
 	.remote_uuid	= ASHA_PROFILE_UUID,
 	.experimental	= true,
 
diff --git a/profiles/audio/avrcp.c b/profiles/audio/avrcp.c
index 21bc80bbd095da49788a87357fd67c8e96ab779d..e6f7e1bfde9879ab6bf028e16384d474332fe805 100644
--- a/profiles/audio/avrcp.c
+++ b/profiles/audio/avrcp.c
@@ -4868,6 +4868,7 @@ done:
 
 static struct btd_profile avrcp_target_profile = {
 	.name		= "audio-avrcp-target",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 
 	.remote_uuid	= AVRCP_TARGET_UUID,
 	.device_probe	= avrcp_target_probe,
@@ -4951,6 +4952,7 @@ done:
 
 static struct btd_profile avrcp_controller_profile = {
 	.name		= "avrcp-controller",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 
 	.remote_uuid	= AVRCP_REMOTE_UUID,
 	.device_probe	= avrcp_controller_probe,
diff --git a/profiles/audio/bap.c b/profiles/audio/bap.c
index 85bba9543974e5bf2a1ff6380c36e518ebc095ac..a03a120ddaaed7e261d40ac06a8f9502c52772bc 100644
--- a/profiles/audio/bap.c
+++ b/profiles/audio/bap.c
@@ -3865,6 +3865,7 @@ static void bap_adapter_remove(struct btd_profile *p,
 static struct btd_profile bap_profile = {
 	.name		= "bap",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= PACS_UUID_STR,
 	.device_probe	= bap_probe,
 	.device_remove	= bap_remove,
@@ -3879,6 +3880,7 @@ static struct btd_profile bap_profile = {
 static struct btd_profile bap_bcast_profile = {
 	.name		= "bcaa",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= BCAAS_UUID_STR,
 	.device_probe	= bap_bcast_probe,
 	.device_remove	= bap_bcast_remove,
diff --git a/profiles/audio/bass.c b/profiles/audio/bass.c
index 9ace372376f9452050724360c2c28e7cdcf1391b..8886a27d99b63b37e2937d8d70f71dfeda3d9ef2 100644
--- a/profiles/audio/bass.c
+++ b/profiles/audio/bass.c
@@ -2172,6 +2172,7 @@ static void bass_server_remove(struct btd_profile *p,
 static struct btd_profile bass_service = {
 	.name		= "bass",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= BASS_UUID_STR,
 	.device_probe	= bass_probe,
 	.device_remove	= bass_remove,
diff --git a/profiles/audio/ccp.c b/profiles/audio/ccp.c
index 8aa537b044e13b6d6a773645b420161bedca13ef..fb85045bb8ba1ec47a33856af1129d0ef78bf500 100644
--- a/profiles/audio/ccp.c
+++ b/profiles/audio/ccp.c
@@ -208,6 +208,7 @@ ccp_server_remove(struct btd_profile *p,
 static struct btd_profile ccp_profile = {
 	.name		= "ccp",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= GTBS_UUID_STR,
 	.device_probe	= ccp_probe,
 	.device_remove	= ccp_remove,
diff --git a/profiles/audio/csip.c b/profiles/audio/csip.c
index b8f29ddf852231d89760d6fe7ca2cfd684236570..d766c3da951899d990aa59132b820737604b1b7c 100644
--- a/profiles/audio/csip.c
+++ b/profiles/audio/csip.c
@@ -303,6 +303,7 @@ static void csip_remove(struct btd_service *service)
 static struct btd_profile csip_profile = {
 	.name		= "csip",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= CSIS_UUID_STR,
 
 	.device_probe	= csip_probe,
@@ -442,6 +443,7 @@ static void csis_server_remove(struct btd_profile *p,
 static struct btd_profile csis_profile = {
 	.name		= "csis",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.local_uuid	= CSIS_UUID_STR,
 
 	.adapter_probe	= csis_server_probe,
diff --git a/profiles/audio/mcp.c b/profiles/audio/mcp.c
index 6651b0897e6f631906b1467f5a479737541da286..8d4eed64399195533ac13fd075d7196a35cf2113 100644
--- a/profiles/audio/mcp.c
+++ b/profiles/audio/mcp.c
@@ -383,6 +383,7 @@ static void media_control_server_remove(struct btd_profile *p,
 static struct btd_profile mcp_profile = {
 	.name			= "mcp",
 	.priority		= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= GMCS_UUID_STR,
 	.device_probe	= mcp_probe,
 	.device_remove	= mcp_remove,
diff --git a/profiles/audio/micp.c b/profiles/audio/micp.c
index f1fb133897320677225a1c8bee06b4a1214f14fa..475f32daf75c06dc28ca72420a80e30802e5a3e9 100644
--- a/profiles/audio/micp.c
+++ b/profiles/audio/micp.c
@@ -300,6 +300,7 @@ static void micp_server_remove(struct btd_profile *p,
 static struct btd_profile micp_profile = {
 	.name		= "micp",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= MICS_UUID_STR,
 
 	.device_probe	= micp_probe,
diff --git a/profiles/audio/vcp.c b/profiles/audio/vcp.c
index 8949c71858e53448ee01c5c4261082f3912a759c..471ad59250386941c377e2f81e911467d7023cce 100644
--- a/profiles/audio/vcp.c
+++ b/profiles/audio/vcp.c
@@ -328,6 +328,7 @@ static void vcp_server_remove(struct btd_profile *p,
 static struct btd_profile vcp_profile = {
 	.name		= "vcp",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= VCS_UUID_STR,
 
 	.device_probe	= vcp_probe,
diff --git a/profiles/health/hdp_manager.c b/profiles/health/hdp_manager.c
index d1e627a3382a01bdd5002bcc0da01da35e872da1..72b69428036df77e2cdb224f186fb13191f955ed 100644
--- a/profiles/health/hdp_manager.c
+++ b/profiles/health/hdp_manager.c
@@ -57,6 +57,7 @@ static void hdp_driver_remove(struct btd_service *service)
 
 static struct btd_profile hdp_source_profile = {
 	.name		= "hdp-source",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.remote_uuid	= HDP_SOURCE_UUID,
 
 	.device_probe	= hdp_driver_probe,
@@ -68,6 +69,7 @@ static struct btd_profile hdp_source_profile = {
 
 static struct btd_profile hdp_sink_profile = {
 	.name		= "hdp-sink",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.remote_uuid	= HDP_SINK_UUID,
 
 	.device_probe	= hdp_driver_probe,
diff --git a/profiles/input/hog.c b/profiles/input/hog.c
index 1f5b82b774353244067e460f49aaccd09e26dcc8..f50a0f217f7f732f82645e289419e51ee6412917 100644
--- a/profiles/input/hog.c
+++ b/profiles/input/hog.c
@@ -215,6 +215,7 @@ static int hog_disconnect(struct btd_service *service)
 
 static struct btd_profile hog_profile = {
 	.name		= "input-hog",
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= HOG_UUID,
 	.device_probe	= hog_probe,
 	.device_remove	= hog_remove,
diff --git a/profiles/input/manager.c b/profiles/input/manager.c
index b0e415f6706c54e7c96199d3bb5e483d0927153f..916849cbc02b047ad9cf83feb46c3ddadbe7f437 100644
--- a/profiles/input/manager.c
+++ b/profiles/input/manager.c
@@ -45,9 +45,11 @@ static void hid_server_remove(struct btd_profile *p,
 
 static struct btd_profile input_profile = {
 	.name		= "input-hid",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.local_uuid	= HID_UUID,
 	.remote_uuid	= HID_UUID,
 
+
 	.auto_connect	= true,
 	.connect	= input_device_connect,
 	.disconnect	= input_device_disconnect,
diff --git a/profiles/midi/midi.c b/profiles/midi/midi.c
index 90e00a5f58361f1da57a71f393e581da5128310c..d7e72420e0db9598169601f77e5bf366652cf09d 100644
--- a/profiles/midi/midi.c
+++ b/profiles/midi/midi.c
@@ -460,6 +460,7 @@ static struct btd_profile midi_profile = {
 	.name = "MIDI GATT Driver",
 	.remote_uuid = MIDI_UUID,
 	.priority = BTD_PROFILE_PRIORITY_HIGH,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.auto_connect = true,
 
 	.device_probe = midi_device_probe,
diff --git a/profiles/network/manager.c b/profiles/network/manager.c
index 51f382529df27600d1a4fd806cb656d7f1a682af..693547d45fbc5b2f227fed832b4efb8fb87c2d59 100644
--- a/profiles/network/manager.c
+++ b/profiles/network/manager.c
@@ -120,6 +120,7 @@ static void nap_server_remove(struct btd_profile *p,
 
 static struct btd_profile panu_profile = {
 	.name		= "network-panu",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.local_uuid	= NAP_UUID,
 	.remote_uuid	= PANU_UUID,
 	.device_probe	= connection_register,
@@ -132,6 +133,7 @@ static struct btd_profile panu_profile = {
 
 static struct btd_profile gn_profile = {
 	.name		= "network-gn",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.local_uuid	= PANU_UUID,
 	.remote_uuid	= GN_UUID,
 	.device_probe	= connection_register,
@@ -144,6 +146,7 @@ static struct btd_profile gn_profile = {
 
 static struct btd_profile nap_profile = {
 	.name		= "network-nap",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.local_uuid	= PANU_UUID,
 	.remote_uuid	= NAP_UUID,
 	.device_probe	= connection_register,
diff --git a/profiles/scanparam/scan.c b/profiles/scanparam/scan.c
index 1c531773740c847e970ac45b7fbda2c0c9501ded..1cc8ef0a60f107b6a225eb8f19cda6b8cc5a57df 100644
--- a/profiles/scanparam/scan.c
+++ b/profiles/scanparam/scan.c
@@ -259,6 +259,7 @@ static int scan_param_probe(struct btd_service *service)
 
 static struct btd_profile scan_profile = {
 	.name = "Scan Parameters Client Driver",
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid = SCAN_PARAMETERS_UUID,
 	.device_probe = scan_param_probe,
 	.device_remove = scan_param_remove,
diff --git a/src/bearer.c b/src/bearer.c
index 9723b59e2e7b39b2974e258363aa0ace95862651..9745c4acf8fcd907ca2841866ce8e3201871181a 100644
--- a/src/bearer.c
+++ b/src/bearer.c
@@ -25,23 +25,43 @@
 
 #include "bluetooth/bluetooth.h"
 #include "bluetooth/mgmt.h"
+#include "bluetooth/uuid.h"
 
 #include "gdbus/gdbus.h"
 #include "src/shared/util.h"
+#include "src/shared/queue.h"
+#include "src/shared/timeout.h"
 
 #include "log.h"
 #include "error.h"
 #include "adapter.h"
 #include "device.h"
+#include "profile.h"
+#include "service.h"
 #include "dbus-common.h"
 #include "bearer.h"
 
+#define DISCONNECT_TIMER	2
+
 struct btd_bearer {
 	struct btd_device *device;
 	uint8_t type;
 	const char *path;
+	unsigned int disconn_timer;
+	struct queue *disconnects; /* disconnects message */
+
+	/* Connect() is defined as a single in-flight operation. To preserve
+	 * the API semantics of org.bluez.Device1.Connect(), we do not queue
+	 * additional connect messages.
+	 */
+	DBusMessage *connect; /* connect message */
 };
 
+static void bearer_free_dbus_message(void *data)
+{
+    dbus_message_unref((DBusMessage *)data);
+}
+
 static void bearer_free(void *data)
 {
 	struct btd_bearer *bearer = data;
@@ -49,17 +69,153 @@ static void bearer_free(void *data)
 	free(bearer);
 }
 
+static void bearer_disconnect_service(struct btd_service *service, void *user_data)
+{
+	uint8_t bdaddr_type = *(uint8_t *)user_data;
+	struct btd_profile *profile = btd_service_get_profile(service);
+	struct btd_device *device = btd_service_get_device(service);
+	bool le_connected;
+
+	if (!profile || !device)
+		return;
+
+	le_connected =
+		btd_device_bdaddr_type_connected(device, BDADDR_LE_PUBLIC) ||
+		btd_device_bdaddr_type_connected(device, BDADDR_LE_RANDOM);
+
+	switch (bdaddr_type) {
+
+	case BDADDR_LE_PUBLIC:
+	case BDADDR_LE_RANDOM:
+		/* Disconnecting LE bearer: disconnect profiles marked as
+		 * BTD_PROFILE_BEARER_LE or BTD_PROFILE_BEARER_ANY.
+		 */
+		if (profile->bearer == BTD_PROFILE_BEARER_BREDR)
+			return;
+		break;
+
+	case BDADDR_BREDR:
+		if (le_connected) {
+			/* Disconnecting BREDR bearer but LE link exists:
+			 * only disconnect profiles marked as
+			 * BTD_PROFILE_BEARER_BREDR.
+			 */
+			if (profile->bearer != BTD_PROFILE_BEARER_BREDR)
+				return;
+		} else {
+			/* No LE link: disconnect profiles marked as
+			 * BTD_PROFILE_BEARER_BREDR or BTD_PROFILE_BEARER_ANY.
+			 */
+			if (profile->bearer == BTD_PROFILE_BEARER_LE)
+				return;
+		}
+		break;
+	}
+
+	DBG("Disconnecting profile %s for bearer addr type %u",
+	profile->name ?: "(unknown)", bdaddr_type);
+
+	btd_service_disconnect(service);
+}
+
+
+static bool bearer_disconnect_link(gpointer user_data)
+{
+	struct btd_bearer *bearer = user_data;
+	struct btd_device *device = bearer->device;
+
+	bearer->disconn_timer = 0;
+
+	if (btd_device_bdaddr_type_connected(device, bearer->type))
+		btd_adapter_disconnect_device(device_get_adapter(device),
+						device_get_address(device),
+						bearer->type);
+	return FALSE;
+}
+
 static DBusMessage *bearer_connect(DBusConnection *conn, DBusMessage *msg,
 							void *user_data)
 {
-	/* TODO */
+	struct btd_bearer *bearer = user_data;
+	struct btd_device *device = bearer->device;
+	int err;
+
+	if (btd_device_bdaddr_type_connected(device, bearer->type)) {
+		if (msg)
+			return btd_error_already_connected(msg);
+		return NULL;
+	}
+
+	if (device_is_bonding(device, NULL)) {
+		if (msg)
+			return btd_error_in_progress(msg);
+		return NULL;
+	}
+
+	if (device_is_connecting(device) ||
+		bearer->connect) {
+		if (msg)
+			return btd_error_in_progress(msg);
+		return NULL;
+	}
+
+	if (msg)
+		bearer->connect = dbus_message_ref(msg);
+
+	if (bearer->type == BDADDR_BREDR)
+		return device_connect_profiles(device, BDADDR_BREDR,
+								msg, NULL);
+	else {
+		btd_device_set_temporary(device, false);
+		err = device_connect_le(device);
+		if (err < 0)
+			return btd_error_failed(msg, strerror(-err));
+	}
+
 	return NULL;
 }
 
 static DBusMessage *bearer_disconnect(DBusConnection *conn, DBusMessage *msg,
 							void *user_data)
 {
-	/* TODO */
+	struct btd_bearer *bearer = user_data;
+	struct btd_device *device = bearer->device;
+
+	if (!btd_device_bdaddr_type_connected(device, bearer->type)) {
+		if (msg)
+			return btd_error_not_connected(msg);
+		return NULL;
+	}
+
+	/* org.bluez.Device1.Disconnect() is in progress. Since it tears down
+	 * both LE and BR/EDR bearers, it takes precedence over bearer-level
+	 * disconnects. Ignore any bearer-specific disconnect requests here.
+	 */
+	if (device_is_disconnecting(device)) {
+		if (msg)
+			return btd_error_in_progress(msg);
+		return NULL;
+	}
+
+	if (msg)
+		queue_push_tail(bearer->disconnects, dbus_message_ref(msg));
+
+	device_cancel_bonding(device, MGMT_STATUS_DISCONNECTED);
+
+	device_cancel_browse(device, bearer->type);
+
+	btd_device_foreach_service(device, bearer_disconnect_service,
+							&bearer->type);
+
+	device_remove_pending_services(device, bearer->type);
+
+	if (bearer->disconn_timer)
+		return NULL;
+
+	bearer->disconn_timer = timeout_add_seconds(DISCONNECT_TIMER,
+							bearer_disconnect_link,
+							bearer, NULL);
+
 	return NULL;
 }
 
@@ -151,6 +307,7 @@ struct btd_bearer *btd_bearer_new(struct btd_device *device, uint8_t type)
 	bearer->device = device;
 	bearer->type = type;
 	bearer->path = device_get_path(device);
+	bearer->disconnects = queue_new();
 
 	if (!g_dbus_register_interface(btd_get_dbus_connection(),
 					bearer->path, bearer_interface(type),
@@ -174,6 +331,16 @@ void btd_bearer_destroy(struct btd_bearer *bearer)
 		return;
 	}
 
+	if (bearer->disconnects) {
+		queue_destroy(bearer->disconnects, bearer_free_dbus_message);
+		bearer->disconnects = NULL;
+	}
+
+	if (bearer->connect) {
+		dbus_message_unref(bearer->connect);
+		bearer->connect = NULL;
+	}
+
 	g_dbus_unregister_interface(btd_get_dbus_connection(), bearer->path,
 					bearer_interface(bearer->type));
 }
@@ -203,6 +370,13 @@ void btd_bearer_connected(struct btd_bearer *bearer)
 	if (!bearer || !bearer->path)
 		return;
 
+	if (bearer->connect) {
+		g_dbus_send_reply(btd_get_dbus_connection(), bearer->connect,
+						DBUS_TYPE_INVALID);
+		dbus_message_unref(bearer->connect);
+		bearer->connect = NULL;
+	}
+
 	g_dbus_emit_property_changed(btd_get_dbus_connection(), bearer->path,
 					bearer_interface(bearer->type),
 					"Connected");
@@ -212,10 +386,24 @@ void btd_bearer_disconnected(struct btd_bearer *bearer, uint8_t reason)
 {
 	const char *name;
 	const char *message;
+	DBusMessage *msg;
+	const struct queue_entry *entry;
 
 	if (!bearer || !bearer->path)
 		return;
 
+	if (!btd_device_is_connected(bearer->device))
+		device_disconnect_watches_callback(bearer->device);
+
+	while (!queue_isempty(bearer->disconnects)) {
+		entry = queue_get_entries(bearer->disconnects);
+		msg = entry->data;
+		g_dbus_send_reply(btd_get_dbus_connection(), msg,
+						DBUS_TYPE_INVALID);
+		queue_remove(bearer->disconnects, msg);
+		dbus_message_unref(msg);
+	}
+
 	g_dbus_emit_property_changed(btd_get_dbus_connection(), bearer->path,
 					bearer_interface(bearer->type),
 					"Connected");
diff --git a/src/device.c b/src/device.c
index 91b6cc0c65eaae8058cd445c0942ffee57289f0d..1e82bd7a8b64bb3ff6ef599da47b594e14d254e4 100644
--- a/src/device.c
+++ b/src/device.c
@@ -2022,6 +2022,28 @@ static void dev_disconn_service(gpointer a, gpointer b)
 	btd_service_disconnect(a);
 }
 
+void device_disconnect_watches_callback(struct btd_device *device)
+{
+	if (!device || !device->watches)
+		return;
+
+	while (device->watches) {
+		struct btd_disconnect_data *data = device->watches->data;
+
+		if (data->watch)
+			/* temporary is set if device is going to be removed */
+			data->watch(device, device->temporary,
+							data->user_data);
+
+		/* Check if the watch has been removed by callback function */
+		if (!g_slist_find(device->watches, data))
+			continue;
+
+		device->watches = g_slist_remove(device->watches, data);
+		g_free(data);
+	}
+}
+
 void device_request_disconnect(struct btd_device *device, DBusMessage *msg)
 {
 	if (device->bonding)
@@ -2063,21 +2085,7 @@ void device_request_disconnect(struct btd_device *device, DBusMessage *msg)
 	g_slist_free(device->pending);
 	device->pending = NULL;
 
-	while (device->watches) {
-		struct btd_disconnect_data *data = device->watches->data;
-
-		if (data->watch)
-			/* temporary is set if device is going to be removed */
-			data->watch(device, device->temporary,
-							data->user_data);
-
-		/* Check if the watch has been removed by callback function */
-		if (!g_slist_find(device->watches, data))
-			continue;
-
-		device->watches = g_slist_remove(device->watches, data);
-		g_free(data);
-	}
+	device_disconnect_watches_callback(device);
 
 	if (!btd_device_is_connected(device)) {
 		if (msg)
@@ -2095,6 +2103,11 @@ bool device_is_disconnecting(struct btd_device *device)
 	return device->disconn_timer > 0;
 }
 
+bool device_is_connecting(struct btd_device *device)
+{
+	return device->connect != NULL;
+}
+
 static void add_set(void *data, void *user_data)
 {
 	struct sirk_info *sirk = data;
@@ -2712,8 +2725,8 @@ int btd_device_connect_services(struct btd_device *dev, GSList *services)
 	return connect_next(dev);
 }
 
-static DBusMessage *connect_profiles(struct btd_device *dev, uint8_t bdaddr_type,
-					DBusMessage *msg, const char *uuid)
+DBusMessage *device_connect_profiles(struct btd_device *dev,
+		uint8_t bdaddr_type, DBusMessage *msg, const char *uuid)
 {
 	struct bearer_state *state = get_state(dev, bdaddr_type);
 	int err;
@@ -2826,7 +2839,7 @@ static DBusMessage *dev_connect(DBusConnection *conn, DBusMessage *msg,
 		return NULL;
 	}
 
-	return connect_profiles(dev, bdaddr_type, msg, NULL);
+	return device_connect_profiles(dev, bdaddr_type, msg, NULL);
 }
 
 static DBusMessage *connect_profile(DBusConnection *conn, DBusMessage *msg,
@@ -2848,7 +2861,7 @@ static DBusMessage *connect_profile(DBusConnection *conn, DBusMessage *msg,
 		return btd_error_invalid_args_str(msg,
 					ERR_BREDR_CONN_INVALID_ARGUMENTS);
 
-	reply = connect_profiles(dev, BDADDR_BREDR, msg, uuid);
+	reply = device_connect_profiles(dev, BDADDR_BREDR, msg, uuid);
 	free(uuid);
 
 	return reply;
@@ -3421,7 +3434,7 @@ static DBusMessage *new_authentication_return(DBusMessage *msg, uint8_t status)
 	}
 }
 
-static void device_cancel_bonding(struct btd_device *device, uint8_t status)
+void device_cancel_bonding(struct btd_device *device, uint8_t status)
 {
 	struct bonding_req *bonding = device->bonding;
 	DBusMessage *reply;
@@ -6629,6 +6642,38 @@ static int device_browse_sdp(struct btd_device *device, DBusMessage *msg)
 	return err;
 }
 
+static gboolean device_is_browsing(struct btd_device *device, uint8_t bdaddr_type)
+{
+	if (!device->browse)
+		return FALSE;
+
+	if (bdaddr_type == BDADDR_BREDR && device->browse->type == BROWSE_SDP)
+		return TRUE;
+
+	if (bdaddr_type != BDADDR_BREDR && device->browse->type == BROWSE_GATT)
+		return TRUE;
+
+	return FALSE;
+}
+
+void device_cancel_browse(struct btd_device *device, uint8_t bdaddr_type)
+{
+	struct btd_adapter *adapter = device->adapter;
+
+	DBG("");
+
+	if (!device_is_browsing(device, bdaddr_type))
+		return;
+
+	if (bdaddr_type == BDADDR_BREDR)
+		bt_cancel_discovery(btd_adapter_get_address(adapter),
+							&device->bdaddr);
+	else
+		attio_cleanup(device);
+
+	browse_request_free(device->browse);
+}
+
 int device_discover_services(struct btd_device *device)
 {
 	int err;
@@ -8088,3 +8133,76 @@ void btd_device_foreach_service_data(struct btd_device *dev, bt_ad_func_t func,
 {
 	bt_ad_foreach_service_data(dev->ad, func, data);
 }
+
+
+void btd_device_foreach_service(struct btd_device *dev,
+				btd_device_service_func_t func,
+				void *user_data)
+{
+	GSList *l;
+
+	for (l = dev->services; l; l = l->next)
+		func(l->data, user_data);
+}
+
+void device_remove_pending_services(struct btd_device *dev,
+					uint8_t bdaddr_type)
+{
+	GSList *l = dev->pending;
+	GSList *next;
+	struct btd_service *service;
+	struct btd_profile *profile;
+	bool le_connected;
+
+	le_connected =
+		btd_device_bdaddr_type_connected(dev, BDADDR_LE_PUBLIC) ||
+		btd_device_bdaddr_type_connected(dev, BDADDR_LE_RANDOM);
+
+	while (l) {
+		next = l->next;
+		service = l->data;
+
+		profile = btd_service_get_profile(service);
+		if (!profile)
+			goto next;
+
+		switch (bdaddr_type) {
+
+		case BDADDR_LE_PUBLIC:
+		case BDADDR_LE_RANDOM:
+			/* Disconnecting LE bearer: disconnect profiles marked
+			 * as BTD_PROFILE_BEARER_LE or BTD_PROFILE_BEARER_ANY.
+			 */
+			if (profile->bearer == BTD_PROFILE_BEARER_BREDR)
+				goto next;
+			break;
+
+		case BDADDR_BREDR:
+			if (le_connected) {
+				/* Disconnecting BREDR bearer but LE link
+				 * exists:only disconnect profiles marked as
+				 * BTD_PROFILE_BEARER_BREDR.
+				 */
+				if (profile->bearer != BTD_PROFILE_BEARER_BREDR)
+					goto next;
+			} else {
+				/* No LE link: disconnect profiles marked as
+				 * BTD_PROFILE_BEARER_BREDR or
+				 * BTD_PROFILE_BEARER_ANY.
+				 */
+				if (profile->bearer == BTD_PROFILE_BEARER_LE)
+					goto next;
+			}
+			break;
+
+		default:
+			goto next;
+		}
+
+		/* Matched: remove from pending list */
+		dev->pending = g_slist_remove(dev->pending, service);
+
+	next:
+		l = next;
+	}
+}
diff --git a/src/device.h b/src/device.h
index 6ed8affa0d4a9274d30cac9b48e8a6826edefd64..fee1ad50dc9c7ae248acd819dae07762c783ac35 100644
--- a/src/device.h
+++ b/src/device.h
@@ -120,6 +120,7 @@ void device_bonding_complete(struct btd_device *device, uint8_t bdaddr_type,
 gboolean device_is_bonding(struct btd_device *device, const char *sender);
 void device_bonding_attempt_failed(struct btd_device *device, uint8_t status);
 void device_bonding_failed(struct btd_device *device, uint8_t status);
+void device_cancel_bonding(struct btd_device *device, uint8_t status);
 struct btd_adapter_pin_cb_iter *device_bonding_iter(struct btd_device *device);
 int device_bonding_attempt_retry(struct btd_device *device);
 long device_bonding_last_duration(struct btd_device *device);
@@ -134,6 +135,9 @@ int device_notify_pincode(struct btd_device *device, gboolean secure,
 							const char *pincode);
 void device_cancel_authentication(struct btd_device *device, gboolean aborted);
 gboolean device_is_authenticating(struct btd_device *device);
+
+void device_cancel_browse(struct btd_device *device, uint8_t bdaddr_type);
+
 void device_add_connection(struct btd_device *dev, uint8_t bdaddr_type,
 							uint32_t flags);
 void device_remove_connection(struct btd_device *device, uint8_t bdaddr_type,
@@ -141,6 +145,7 @@ void device_remove_connection(struct btd_device *device, uint8_t bdaddr_type,
 							uint8_t reason);
 void device_request_disconnect(struct btd_device *device, DBusMessage *msg);
 bool device_is_disconnecting(struct btd_device *device);
+bool device_is_connecting(struct btd_device *device);
 void device_set_ltk(struct btd_device *device, const uint8_t val[16],
 				bool central, uint8_t enc_size);
 bool btd_device_get_ltk(struct btd_device *device, uint8_t val[16],
@@ -170,6 +175,7 @@ guint device_add_disconnect_watch(struct btd_device *device,
 				disconnect_watch watch, void *user_data,
 				GDestroyNotify destroy);
 void device_remove_disconnect_watch(struct btd_device *device, guint id);
+void device_disconnect_watches_callback(struct btd_device *device);
 int device_get_appearance(struct btd_device *device, uint16_t *value);
 void device_set_appearance(struct btd_device *device, uint16_t value);
 
@@ -184,6 +190,9 @@ void btd_device_set_pnpid(struct btd_device *device, uint16_t source,
 
 int device_connect_le(struct btd_device *dev);
 
+DBusMessage *device_connect_profiles(struct btd_device *dev,
+		uint8_t bdaddr_type, DBusMessage *msg, const char *uuid);
+
 typedef void (*device_svc_cb_t) (struct btd_device *dev, int err,
 							void *user_data);
 
@@ -225,3 +234,11 @@ void btd_device_set_conn_param(struct btd_device *device, uint16_t min_interval,
 void btd_device_foreach_service_data(struct btd_device *dev,
 					bt_device_ad_func_t func,
 					void *data);
+
+typedef void (*btd_device_service_func_t)(struct btd_service *service,
+					void *user_data);
+void btd_device_foreach_service(struct btd_device *dev,
+				btd_device_service_func_t func,
+				void *user_data);
+void device_remove_pending_services(struct btd_device *dev,
+					uint8_t bdaddr_type);
\ No newline at end of file
diff --git a/src/profile.h b/src/profile.h
index 424ce55ad65748ead13b1a38d67fbad6beb2b828..16eeccb561b0bc9d6c7da20b6113f22ecc3f2c6b 100644
--- a/src/profile.h
+++ b/src/profile.h
@@ -12,12 +12,22 @@
 #define BTD_PROFILE_PRIORITY_MEDIUM	1
 #define BTD_PROFILE_PRIORITY_HIGH	2
 
+#define BTD_PROFILE_BEARER_ANY		0
+#define BTD_PROFILE_BEARER_LE		1
+#define BTD_PROFILE_BEARER_BREDR	2
+
 struct btd_service;
 
 struct btd_profile {
 	const char *name;
 	int priority;
 
+	/* Indicates which bearer type this profile belongs to. Some profiles
+	 * may exist in both BR/EDR and LE. So we need to declare them as
+	 * BTD_PROFILE_BEARER_ANY when registering profiles.
+	 */
+	int bearer;
+
 	const char *local_uuid;
 	const char *remote_uuid;
 

---
base-commit: 5e41d1e1d361e7288964e4c2c5ed90736025662f
change-id: 20251111-bearer-impl-5f7e396174aa

Best regards,
-- 
Ye He <ye.he@amlogic.com>

