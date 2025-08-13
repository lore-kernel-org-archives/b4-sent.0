From: Ye He <ye.he@amlogic.com>
Date: Wed, 13 Aug 2025 15:09:48 +0800
Subject: [PATCH bluez] As a BIS sink role, BlueZ currently defaults to
 synchronizing with the first broadcast source device discovered by the le
 discovery procedure. This behavior may not align with user expectations,
 as it removes control over the target device selection.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250813-adapter-sync-bcast-v1-1-4a739f99c156@amlogic.com>
X-B4-Tracking: v=1; b=H4sIADs6nGgC/x3MQQqDMBBA0avIrB1IoqL0KsXFJI7tQEklo6Uav
 LvB5Vv8n0E5CSs8qgyJf6LyjQW2riC8Kb4YZSoGZ1xnBtsgTbSsnFD3GNAH0hWH3s6+7UJvHEE
 Jl8Sz/O/pE/xn4wPG87wA3uyffWsAAAA=
X-Change-ID: 20250813-adapter-sync-bcast-871fb45c702a
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755068992; l=7082;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=q2SC32AafSEnETM59derQcFG0XRXIMhN77JsYS52bCw=;
 b=W7X6kRASot4+pW2kQYSKvMjRqE9X3esFCV5slysHjj6KAt5Nfyfj1fHIywl4n8Qm9yjC34lqS
 U9FZVgsEgo3ClcYghIz9YETOi9YjKFrkEE5mdvxqVFsyJW2qXGI2lxC
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch introduces a new SyncBroadcast method to the device1 interface,
allowing users to explicitly choose which broadcast source device to
synchronize with.

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 doc/org.bluez.Device.rst | 15 +++++++++++++++
 plugins/neard.c          |  2 +-
 src/adapter.c            |  4 ++--
 src/device.c             | 39 ++++++++++++++++++++++++++++++++++++---
 src/device.h             |  3 ++-
 5 files changed, 56 insertions(+), 7 deletions(-)

diff --git a/doc/org.bluez.Device.rst b/doc/org.bluez.Device.rst
index 61c394dd2d0b371fe10508b8e64087ed87a2e6e0..44d929e8850659cdfbcafa81f18dd44e4aa53d03 100644
--- a/doc/org.bluez.Device.rst
+++ b/doc/org.bluez.Device.rst
@@ -155,6 +155,21 @@ Possible errors:
 :org.bluez.Error.NotConnected:
 :org.bluez.Error.DoesNotExist:
 
+void SyncBroadcast() [experimental]
+```````````````````````````````````
+
+Initiates synchronization with a broadcast source device that contains Broadcast
+Announcements UUID. This method can be used on devices that are capable of
+broadcast synchronization.
+
+If the device is not capable of broadcast synchronization, this method will
+fail with `org.bluez.Error.NotSupported`.
+
+Possible errors:
+
+:org.bluez.Error.Failed:
+:org.bluez.Error.NotSupported:
+
 Signals
 -------
 
diff --git a/plugins/neard.c b/plugins/neard.c
index c84934025cd8541bf604efe9520c1c3e9c83068f..8c231a8e84b0090b450f3b61e75cc4d4c6e4a14f 100644
--- a/plugins/neard.c
+++ b/plugins/neard.c
@@ -633,7 +633,7 @@ static void store_params(struct btd_adapter *adapter, struct btd_device *device,
 	}
 
 	if (params->services)
-		device_add_eir_uuids(device, params->services);
+		device_add_eir_uuids(device, params->services, true);
 
 	if (params->hash) {
 		btd_adapter_add_remote_oob_data(adapter, &params->address,
diff --git a/src/adapter.c b/src/adapter.c
index b771cf66ade30dcfe0a6fa41cd28f1ba46bed5a4..b12d75c815ee936aeaf3210f97831eee8ee945a2 100644
--- a/src/adapter.c
+++ b/src/adapter.c
@@ -1740,7 +1740,7 @@ static void discovery_cleanup(struct btd_adapter *adapter, int timeout)
 		next = g_slist_next(l);
 
 		if (device_is_temporary(dev) && !device_is_connectable(dev)
-			&& !btd_device_is_connected(dev))
+			&& !btd_device_is_connected(dev) && !btd_device_is_bcast_syncable(dev))
 			btd_adapter_remove_device(adapter, dev);
 	}
 }
@@ -7452,7 +7452,7 @@ void btd_adapter_device_found(struct btd_adapter *adapter,
 							eir_data.did_product,
 							eir_data.did_version);
 
-	device_add_eir_uuids(dev, eir_data.services);
+	device_add_eir_uuids(dev, eir_data.services, false);
 
 	if (adapter->discovery_list)
 		g_slist_foreach(adapter->discovery_list, filter_duplicate_data,
diff --git a/src/device.c b/src/device.c
index 0179c3dab603ece0faedfd122c87b99f35a2ca6e..410a051391529799d83102d3e8b041a264fd415a 100644
--- a/src/device.c
+++ b/src/device.c
@@ -78,6 +78,8 @@
 
 #define RSSI_THRESHOLD		8
 
+#define BCAAS_UUID_STR "00001852-0000-1000-8000-00805f9b34fb"
+
 static DBusConnection *dbus_conn = NULL;
 static unsigned service_state_cb_id;
 
@@ -2356,7 +2358,7 @@ done:
 	dev->connect = NULL;
 }
 
-void device_add_eir_uuids(struct btd_device *dev, GSList *uuids)
+void device_add_eir_uuids(struct btd_device *dev, GSList *uuids, bool probe)
 {
 	GSList *l;
 	GSList *added = NULL;
@@ -2372,7 +2374,8 @@ void device_add_eir_uuids(struct btd_device *dev, GSList *uuids)
 		dev->eir_uuids = g_slist_append(dev->eir_uuids, g_strdup(str));
 	}
 
-	device_probe_profiles(dev, added);
+	if (probe)
+		device_probe_profiles(dev, added);
 }
 
 static void add_manufacturer_data(void *data, void *user_data)
@@ -2411,7 +2414,7 @@ static void add_service_data(void *data, void *user_data)
 		return;
 
 	l = g_slist_append(NULL, sd->uuid);
-	device_add_eir_uuids(dev, l);
+	device_add_eir_uuids(dev, l, false);
 	g_slist_free(l);
 
 	g_dbus_emit_property_changed(dbus_conn, dev->path,
@@ -3488,6 +3491,21 @@ static DBusMessage *get_service_records(DBusConnection *conn, DBusMessage *msg,
 	return reply;
 }
 
+static DBusMessage *sync_broadcast_device(DBusConnection *conn, DBusMessage *msg,
+							void *user_data)
+{
+	struct btd_device *dev = user_data;
+
+	DBG("Sync with broadcast device %s", batostr(&dev->bdaddr));
+
+	if (!btd_device_is_bcast_syncable(dev))
+		return btd_error_not_supported(msg);
+
+	btd_device_add_uuid(dev, BCAAS_UUID_STR);
+
+	return dbus_message_new_method_return(msg);
+}
+
 static const GDBusMethodTable device_methods[] = {
 	{ GDBUS_ASYNC_METHOD("Disconnect", NULL, NULL, dev_disconnect) },
 	{ GDBUS_ASYNC_METHOD("Connect", NULL, NULL, dev_connect) },
@@ -3500,6 +3518,7 @@ static const GDBusMethodTable device_methods[] = {
 	{ GDBUS_EXPERIMENTAL_METHOD("GetServiceRecords", NULL,
 				    GDBUS_ARGS({ "Records", "aay" }),
 				    get_service_records) },
+	{ GDBUS_EXPERIMENTAL_ASYNC_METHOD("SyncBroadcast", NULL, NULL, sync_broadcast_device) },
 	{ }
 };
 
@@ -3654,6 +3673,20 @@ bool btd_device_bdaddr_type_connected(struct btd_device *dev, uint8_t type)
 	return dev->le_state.connected;
 }
 
+bool btd_device_is_bcast_syncable(struct btd_device *dev)
+{
+	if (dev->bredr_state.connected || dev->le_state.connected)
+		return false;
+
+	for (GSList *l = dev->eir_uuids; l != NULL; l = l->next) {
+		const char *str = l->data;
+		if (bt_uuid_strcmp(str, BCAAS_UUID_STR) == 0)
+			return true;
+	}
+
+	return false;
+}
+
 static void clear_temporary_timer(struct btd_device *dev)
 {
 	if (dev->temporary_timer) {
diff --git a/src/device.h b/src/device.h
index 9e7c30ad71864932d3da2211f30e3c7ffc4b02f7..70f4dc1a11a12bce4514fcfa362c713d4d2a5235 100644
--- a/src/device.h
+++ b/src/device.h
@@ -76,7 +76,7 @@ void btd_device_gatt_set_service_changed(struct btd_device *device,
 						uint16_t start, uint16_t end);
 bool device_attach_att(struct btd_device *dev, GIOChannel *io);
 void btd_device_add_uuid(struct btd_device *device, const char *uuid);
-void device_add_eir_uuids(struct btd_device *dev, GSList *uuids);
+void device_add_eir_uuids(struct btd_device *dev, GSList *uuids, bool probe);
 void device_set_manufacturer_data(struct btd_device *dev, GSList *list,
 							bool duplicate);
 void device_set_service_data(struct btd_device *dev, GSList *list,
@@ -110,6 +110,7 @@ void device_set_tx_power(struct btd_device *device, int8_t tx_power);
 void device_set_flags(struct btd_device *device, uint8_t flags);
 bool btd_device_is_connected(struct btd_device *dev);
 bool btd_device_bearer_is_connected(struct btd_device *dev);
+bool btd_device_is_bcast_syncable(struct btd_device *dev);
 bool btd_device_bdaddr_type_connected(struct btd_device *dev, uint8_t type);
 uint8_t btd_device_get_bdaddr_type(struct btd_device *dev);
 bool device_is_retrying(struct btd_device *device);

---
base-commit: 9cdbad590b7476b83e2ef240a486fd5159251be8
change-id: 20250813-adapter-sync-bcast-871fb45c702a

Best regards,
-- 
Ye He <ye.he@amlogic.com>

