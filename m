From: Ye He <ye.he@amlogic.com>
Date: Wed, 26 Nov 2025 13:21:09 +0800
Subject: [PATCH bluez v6 2/3] bearer: Implement Connect/Disconnect methods
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251126-bearer-impl-v6-2-e93fd41f10b6@amlogic.com>
References: <20251126-bearer-impl-v6-0-e93fd41f10b6@amlogic.com>
In-Reply-To: <20251126-bearer-impl-v6-0-e93fd41f10b6@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764134468; l=15850;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=Ql1iYZQDAquyvvzVOraVFz3TJcxtkhbyrGqxqtWk5BY=;
 b=Irt64nKWk0jDkF5TinO+/Sf3T0iLNbY7T53BVSN8BcYtGMJijjB/jeCksCD9vrDIw963wNyFX
 jPyifmustxmChwmld7d3NPq0h2diXB1lVaITyvwEB8LNro0/CNpM+DY
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch provides implementations for the Connect and Disconnect
methods of the org.bluez.Bearer.LE1 and org.bluez.Bearer.BREDR1
interfaces.

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 src/bearer.c | 167 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-
 src/device.c | 129 ++++++++++++++++++++++++++++++++++++++-------
 src/device.h |  17 ++++++
 3 files changed, 291 insertions(+), 22 deletions(-)

diff --git a/src/bearer.c b/src/bearer.c
index 9723b59e2e7b39b2974e258363aa0ace95862651..784c9536dea5cd5aedccac05b5042927a59df8ba 100644
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
+	dbus_message_unref((DBusMessage *)data);
+}
+
 static void bearer_free(void *data)
 {
 	struct btd_bearer *bearer = data;
@@ -49,17 +69,128 @@ static void bearer_free(void *data)
 	free(bearer);
 }
 
+static void bearer_disconnect_service(struct btd_service *service,
+						void *user_data)
+{
+	uint8_t bdaddr_type = *(uint8_t *)user_data;
+	struct btd_profile *profile = btd_service_get_profile(service);
+	struct btd_device *device = btd_service_get_device(service);
+
+	if (!profile || !device)
+		return;
+
+	if (bdaddr_type == BDADDR_BREDR) {
+		if (profile->bearer == BTD_PROFILE_BEARER_LE)
+			return;
+	} else {
+		if (profile->bearer == BTD_PROFILE_BEARER_BREDR)
+			return;
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
 
@@ -151,6 +282,7 @@ struct btd_bearer *btd_bearer_new(struct btd_device *device, uint8_t type)
 	bearer->device = device;
 	bearer->type = type;
 	bearer->path = device_get_path(device);
+	bearer->disconnects = queue_new();
 
 	if (!g_dbus_register_interface(btd_get_dbus_connection(),
 					bearer->path, bearer_interface(type),
@@ -174,6 +306,16 @@ void btd_bearer_destroy(struct btd_bearer *bearer)
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
@@ -203,6 +345,13 @@ void btd_bearer_connected(struct btd_bearer *bearer)
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
@@ -212,10 +361,24 @@ void btd_bearer_disconnected(struct btd_bearer *bearer, uint8_t reason)
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
index 91b6cc0c65eaae8058cd445c0942ffee57289f0d..145004cea9bf06d9fb811f971f1786ddcefd8e7a 100644
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
@@ -6629,6 +6642,39 @@ static int device_browse_sdp(struct btd_device *device, DBusMessage *msg)
 	return err;
 }
 
+static gboolean device_is_browsing(struct btd_device *device,
+					uint8_t bdaddr_type)
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
@@ -8088,3 +8134,46 @@ void btd_device_foreach_service_data(struct btd_device *dev, bt_ad_func_t func,
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
+
+	while (l) {
+		next = l->next;
+		service = l->data;
+
+		profile = btd_service_get_profile(service);
+		if (!profile)
+			goto next;
+
+		if (bdaddr_type == BDADDR_BREDR) {
+			if (profile->bearer == BTD_PROFILE_BEARER_LE)
+				goto next;
+		} else {
+			if (profile->bearer == BTD_PROFILE_BEARER_BREDR)
+				goto next;
+		}
+
+		/* Matched: remove from pending list */
+		dev->pending = g_slist_remove(dev->pending, service);
+
+next:
+		l = next;
+	}
+}
diff --git a/src/device.h b/src/device.h
index 6ed8affa0d4a9274d30cac9b48e8a6826edefd64..c7b8b2a16eb993758afc85b291cea31ef46f2d8f 100644
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

-- 
2.42.0

