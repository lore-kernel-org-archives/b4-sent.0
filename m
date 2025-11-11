From: Ye He <ye.he@amlogic.com>
Date: Tue, 11 Nov 2025 17:23:07 +0800
Subject: [PATCH bluez] bearer: Implement Connect/Disconnect methods
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251111-bearer-impl-v1-1-f41585144218@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAHoAE2kC/x2MOwqAMBAFryJbGzB+0auIRdQXXfDHBkWU3N3gd
 FPMvOQgDEdN9JLgYsf7FkTHEQ2z2SYoHoNTmqSFDqgeRiCK12NRha2Q1aWucmMoFIfA8v3fWuq
 XEw913n8NcUxCZAAAAA==
X-Change-ID: 20251111-bearer-impl-5f7e396174aa
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762852990; l=14662;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=rhIgq2xsZL88Z2/EdnmF1TvqzpT/NLQVrty6zPntBnU=;
 b=SLOMiRc0Kct/k5gDFhSlfRfuOAAfYS5x43QUS5WBGL07p3vSPXwH6Cn8Hu7aCpyodzJ1tiS3T
 dPd9xY9HcMsAA0h/w8R6iktilYja+8olu/eefa62HtyDhYSWPPAWO+O
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch provides implementations for the Connect and Disconnect
methods of the org.bluez.Bearer.LE1 and org.bluez.Bearer.BREDR1
interfaces.

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 src/bearer.c |  52 +++++++++++-
 src/device.c | 265 ++++++++++++++++++++++++++++++++++++++++++++++++-----------
 src/device.h |   4 +
 3 files changed, 269 insertions(+), 52 deletions(-)

diff --git a/src/bearer.c b/src/bearer.c
index 9723b59e2e7b39b2974e258363aa0ace95862651..2ceea7abecebbd4a592111be96af1ce9daac827a 100644
--- a/src/bearer.c
+++ b/src/bearer.c
@@ -40,6 +40,8 @@ struct btd_bearer {
 	struct btd_device *device;
 	uint8_t type;
 	const char *path;
+	GSList *disconnects; /* disconnects message */
+	GSList *connects; /* connects message */
 };
 
 static void bearer_free(void *data)
@@ -52,14 +54,46 @@ static void bearer_free(void *data)
 static DBusMessage *bearer_connect(DBusConnection *conn, DBusMessage *msg,
 							void *user_data)
 {
-	/* TODO */
+	struct btd_bearer *bearer = user_data;
+
+	if (btd_device_bdaddr_type_connected(bearer->device, bearer->type)) {
+		if (msg)
+			return btd_error_already_connected(msg);
+		return NULL;
+	}
+
+	if (bearer->connects) {
+		if (msg)
+			return btd_error_in_progress(msg);
+		return NULL;
+	}
+
+	if (msg)
+		bearer->connects = g_slist_append(bearer->connects,
+						dbus_message_ref(msg));
+
+	device_request_connect_bearer(bearer->device, bearer->type, msg);
+
 	return NULL;
 }
 
 static DBusMessage *bearer_disconnect(DBusConnection *conn, DBusMessage *msg,
 							void *user_data)
 {
-	/* TODO */
+	struct btd_bearer *bearer = user_data;
+
+	if (!btd_device_bdaddr_type_connected(bearer->device, bearer->type)) {
+		if (msg)
+			return btd_error_not_connected(msg);
+		return NULL;
+	}
+
+	if (msg)
+		bearer->disconnects = g_slist_append(bearer->disconnects,
+						dbus_message_ref(msg));
+
+	device_request_disconnect_bearer(bearer->device, bearer->type, msg);
+
 	return NULL;
 }
 
@@ -203,6 +237,13 @@ void btd_bearer_connected(struct btd_bearer *bearer)
 	if (!bearer || !bearer->path)
 		return;
 
+	while (bearer->connects) {
+		DBusMessage *msg = bearer->connects->data;
+		g_dbus_send_reply(btd_get_dbus_connection(), msg, DBUS_TYPE_INVALID);
+		bearer->connects = g_slist_remove(bearer->connects, msg);
+		dbus_message_unref(msg);
+	}
+
 	g_dbus_emit_property_changed(btd_get_dbus_connection(), bearer->path,
 					bearer_interface(bearer->type),
 					"Connected");
@@ -216,6 +257,13 @@ void btd_bearer_disconnected(struct btd_bearer *bearer, uint8_t reason)
 	if (!bearer || !bearer->path)
 		return;
 
+	while (bearer->disconnects) {
+		DBusMessage *msg = bearer->disconnects->data;
+		g_dbus_send_reply(btd_get_dbus_connection(), msg, DBUS_TYPE_INVALID);
+		bearer->disconnects = g_slist_remove(bearer->disconnects, msg);
+		dbus_message_unref(msg);
+	}
+
 	g_dbus_emit_property_changed(btd_get_dbus_connection(), bearer->path,
 					bearer_interface(bearer->type),
 					"Connected");
diff --git a/src/device.c b/src/device.c
index 91b6cc0c65eaae8058cd445c0942ffee57289f0d..4956e6f84df918c4ae7e7c9dd2f65652854f4f43 100644
--- a/src/device.c
+++ b/src/device.c
@@ -250,7 +250,8 @@ struct btd_device {
 	bool		temporary;
 	bool		connectable;
 	bool		cable_pairing;
-	unsigned int	disconn_timer;
+	unsigned int 	disconn_bredr_timer;
+	unsigned int 	disconn_le_timer;
 	unsigned int	discov_timer;
 	unsigned int	temporary_timer;	/* Temporary/disappear timer */
 	struct browse_req *browse;		/* service discover request */
@@ -315,8 +316,13 @@ static const uint16_t uuid_list[] = {
 	0
 };
 
+static bool disconnect_le(gpointer user_data);
+static bool disconnect_bredr(gpointer user_data);
 static int device_browse_gatt(struct btd_device *device, DBusMessage *msg);
 static int device_browse_sdp(struct btd_device *device, DBusMessage *msg);
+static void device_set_auto_connect(struct btd_device *device, gboolean enable);
+static DBusMessage *connect_profiles(struct btd_device *dev, uint8_t bdaddr_type,
+					DBusMessage *msg, const char *uuid);
 
 static struct bearer_state *get_state(struct btd_device *dev,
 							uint8_t bdaddr_type)
@@ -922,8 +928,11 @@ static void device_free(gpointer user_data)
 		sdp_list_free(device->tmp_records,
 					(sdp_free_func_t) sdp_record_free);
 
-	if (device->disconn_timer)
-		timeout_remove(device->disconn_timer);
+	if (device->disconn_bredr_timer)
+		timeout_remove(device->disconn_bredr_timer);
+
+	if (device->disconn_le_timer)
+		timeout_remove(device->disconn_le_timer);
 
 	if (device->discov_timer)
 		timeout_remove(device->discov_timer);
@@ -1903,23 +1912,6 @@ static gboolean dev_property_set_exists(const GDBusPropertyTable *property,
 	return !queue_isempty(device->sirks);
 }
 
-static bool disconnect_all(gpointer user_data)
-{
-	struct btd_device *device = user_data;
-
-	device->disconn_timer = 0;
-
-	if (device->bredr_state.connected)
-		btd_adapter_disconnect_device(device->adapter, &device->bdaddr,
-								BDADDR_BREDR);
-
-	if (device->le_state.connected)
-		btd_adapter_disconnect_device(device->adapter, &device->bdaddr,
-							device->bdaddr_type);
-
-	return FALSE;
-}
-
 int device_block(struct btd_device *device, gboolean update_only)
 {
 	int err = 0;
@@ -1927,10 +1919,15 @@ int device_block(struct btd_device *device, gboolean update_only)
 	if (device->blocked)
 		return 0;
 
-	if (device->disconn_timer > 0)
-		timeout_remove(device->disconn_timer);
+	if (device->disconn_le_timer > 0)
+		timeout_remove(device->disconn_le_timer);
+
+	if (device->disconn_bredr_timer > 0)
+		timeout_remove(device->disconn_bredr_timer);
 
-	disconnect_all(device);
+	disconnect_bredr(device);
+
+	disconnect_le(device);
 
 	while (device->services != NULL) {
 		struct btd_service *service = device->services->data;
@@ -2022,6 +2019,28 @@ static void dev_disconn_service(gpointer a, gpointer b)
 	btd_service_disconnect(a);
 }
 
+static void dev_disconnect_watches_notify(struct btd_device *device)
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
@@ -2055,7 +2074,7 @@ void device_request_disconnect(struct btd_device *device, DBusMessage *msg)
 		device->disconnects = g_slist_append(device->disconnects,
 						dbus_message_ref(msg));
 
-	if (device->disconn_timer)
+	if (device->disconn_bredr_timer && device->disconn_le_timer)
 		return;
 
 	g_slist_foreach(device->services, dev_disconn_service, NULL);
@@ -2063,21 +2082,7 @@ void device_request_disconnect(struct btd_device *device, DBusMessage *msg)
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
+	dev_disconnect_watches_notify(device);
 
 	if (!btd_device_is_connected(device)) {
 		if (msg)
@@ -2085,14 +2090,160 @@ void device_request_disconnect(struct btd_device *device, DBusMessage *msg)
 		return;
 	}
 
-	device->disconn_timer = timeout_add_seconds(DISCONNECT_TIMER,
-							disconnect_all,
+	if (!device->disconn_bredr_timer)
+		device->disconn_bredr_timer = timeout_add_seconds(DISCONNECT_TIMER,
+							disconnect_bredr,
+							device, NULL);
+
+	if (!device->disconn_le_timer)
+		device->disconn_le_timer = timeout_add_seconds(DISCONNECT_TIMER,
+							disconnect_le,
 							device, NULL);
 }
 
 bool device_is_disconnecting(struct btd_device *device)
 {
-	return device->disconn_timer > 0;
+	return (device->disconn_le_timer > 0) ||
+				(device->disconn_bredr_timer > 0);
+}
+
+static void dev_disconn_bearer_service(gpointer a, gpointer b)
+{
+	struct btd_service *service = a;
+	uint8_t type = *(uint8_t *)b;
+	struct btd_profile *profile;
+	bt_uuid_t uuid;
+
+	profile = btd_service_get_profile(service);
+	if (!profile)
+		return;
+
+	if (!profile->remote_uuid)
+		return;
+
+	if (bt_string_to_uuid(&uuid, profile->remote_uuid) != 0)
+		return;
+
+	uint16_t uuid16 = uuid.value.u16;
+
+	switch (type) {
+	case BDADDR_BREDR:
+		if (uuid16 < 0x1100 || uuid16 > 0x11FF)
+			return;
+		break;
+	case BDADDR_LE_PUBLIC:
+	case BDADDR_LE_RANDOM:
+		if (uuid16 < 0x1800 || uuid16 > 0x18FF)
+			return;
+		break;
+	default:
+		DBG("Unsupported bearer addr type: %u", type);
+		return;
+	}
+
+	DBG("Disconnecting profile %s (UUID 0x%04x) for bearer type %u",
+	    profile->name ?: "(unknown)", uuid16, type);
+
+	btd_service_disconnect(service);
+}
+
+static bool disconnect_bredr(gpointer user_data)
+{
+	struct btd_device *device = user_data;
+
+	device->disconn_bredr_timer = 0;
+
+	if (device->bredr_state.connected)
+		btd_adapter_disconnect_device(device->adapter, &device->bdaddr,
+								BDADDR_BREDR);
+
+	return FALSE;
+}
+
+static bool disconnect_le(gpointer user_data)
+{
+	struct btd_device *device = user_data;
+
+	device->disconn_le_timer = 0;
+
+	if (device->le_state.connected)
+		btd_adapter_disconnect_device(device->adapter, &device->bdaddr,
+							device->bdaddr_type);
+
+	return FALSE;
+}
+
+void device_request_disconnect_bearer(struct btd_device *device, uint8_t bdaddr_type, DBusMessage *msg)
+{
+	if (device->bonding)
+		bonding_request_cancel(device->bonding);
+
+	if (device->browse) {
+		if ((device->browse->type == BROWSE_SDP && bdaddr_type == BDADDR_BREDR) ||
+			(device->browse->type == BROWSE_GATT && bdaddr_type != BDADDR_BREDR))
+				browse_request_cancel(device->browse);
+	}
+
+	g_slist_foreach(device->services, dev_disconn_bearer_service, &bdaddr_type);
+
+	dev_disconnect_watches_notify(device);
+
+	if (bdaddr_type == BDADDR_BREDR) {
+		g_slist_free(device->pending);
+		device->pending = NULL;
+
+		if (device->disconn_bredr_timer)
+			return;
+
+		device->disconn_bredr_timer = timeout_add_seconds(DISCONNECT_TIMER,
+							disconnect_bredr,
+							device, NULL);
+	} else {
+		if (device->att_io) {
+			g_io_channel_shutdown(device->att_io, FALSE, NULL);
+			g_io_channel_unref(device->att_io);
+			device->att_io = NULL;
+		}
+
+		if (device->disconn_le_timer)
+			return;
+
+		device->disconn_le_timer = timeout_add_seconds(DISCONNECT_TIMER,
+							disconnect_le,
+							device, NULL);
+	}
+}
+
+void device_request_connect_bearer(struct btd_device *device, uint8_t bdaddr_type, DBusMessage *msg)
+{
+	int err;
+
+	if (device->bonding) {
+		g_dbus_send_message(dbus_conn, btd_error_in_progress(msg));
+		return;
+	}
+
+	if (bdaddr_type == BDADDR_BREDR)
+		connect_profiles(device, bdaddr_type, msg, NULL);
+	else {
+		if (device->le_state.connected) {
+			dbus_message_new_method_return(msg);
+			return;
+		}
+
+		btd_device_set_temporary(device, false);
+
+		if (device->disable_auto_connect) {
+			device->disable_auto_connect = FALSE;
+			device_set_auto_connect(device, TRUE);
+		}
+
+		err = device_connect_le(device);
+		if (err < 0) {
+			g_dbus_send_message(dbus_conn, btd_error_failed(msg, strerror(-err)));
+			return;
+		}
+	}
 }
 
 static void add_set(void *data, void *user_data)
@@ -3880,17 +4031,24 @@ void device_remove_connection(struct btd_device *device, uint8_t bdaddr_type,
 	if (!state->connected)
 		return;
 
+	if (bdaddr_type == BDADDR_BREDR) {
+		if (device->disconn_bredr_timer > 0) {
+			timeout_remove(device->disconn_bredr_timer);
+			device->disconn_bredr_timer = 0;
+		}
+	} else {
+		if (device->disconn_le_timer > 0) {
+			timeout_remove(device->disconn_le_timer);
+			device->disconn_le_timer = 0;
+		}
+	}
+
 	state->connected = false;
 	state->initiator = false;
 	device->general_connect = FALSE;
 
 	device_set_svc_refreshed(device, false);
 
-	if (device->disconn_timer > 0) {
-		timeout_remove(device->disconn_timer);
-		device->disconn_timer = 0;
-	}
-
 	/* This could be executed while the client is waiting for Connect() but
 	 * att_connect_cb has not been invoked.
 	 * In that case reply the client that the connection failed.
@@ -5359,9 +5517,16 @@ void device_remove(struct btd_device *device, gboolean remove_stored)
 	device->pending = NULL;
 
 	if (btd_device_is_connected(device)) {
-		if (device->disconn_timer > 0)
-			timeout_remove(device->disconn_timer);
-		disconnect_all(device);
+		if (device->disconn_bredr_timer > 0) {
+			timeout_remove(device->disconn_bredr_timer);
+			device->disconn_bredr_timer = 0;
+		}
+		if (device->disconn_le_timer > 0) {
+			timeout_remove(device->disconn_le_timer);
+			device->disconn_le_timer = 0;
+		}
+		disconnect_bredr(device);
+		disconnect_le(device);
 	}
 
 	clear_temporary_timer(device);
diff --git a/src/device.h b/src/device.h
index 6ed8affa0d4a9274d30cac9b48e8a6826edefd64..ebf30f551f4b9b6f559202c5454255b790b279d0 100644
--- a/src/device.h
+++ b/src/device.h
@@ -141,6 +141,10 @@ void device_remove_connection(struct btd_device *device, uint8_t bdaddr_type,
 							uint8_t reason);
 void device_request_disconnect(struct btd_device *device, DBusMessage *msg);
 bool device_is_disconnecting(struct btd_device *device);
+void device_request_disconnect_bearer(struct btd_device *device, uint8_t bdaddr_type,
+							DBusMessage *msg);
+void device_request_connect_bearer(struct btd_device *device, uint8_t bdaddr_type,
+							DBusMessage *msg);
 void device_set_ltk(struct btd_device *device, const uint8_t val[16],
 				bool central, uint8_t enc_size);
 bool btd_device_get_ltk(struct btd_device *device, uint8_t val[16],

---
base-commit: 5e41d1e1d361e7288964e4c2c5ed90736025662f
change-id: 20251111-bearer-impl-5f7e396174aa

Best regards,
-- 
Ye He <ye.he@amlogic.com>

