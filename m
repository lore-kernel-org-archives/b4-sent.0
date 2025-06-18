From: Ye He <ye.he@amlogic.com>
Date: Wed, 18 Jun 2025 10:39:52 +0800
Subject: [PATCH bluez] device: Add bearer info to Connected/Disconnected
 signals
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250618-device-bearer-level-conn-state-v1-1-dca5df09c0bd@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAPcmUmgC/x2NzQqDMBAGX0X23AVNUdK+ivSQn6+6EKJsVErFd
 2/ocWCYOalABYWezUmKQ4osuUJ3ayjMLk9giZXJtKZvh85yrFIAeziFcsKBxGHJmcvmNvAd5hH
 7wUdnLdXIqnjL5z8YyacdX3pd1w86B02AdwAAAA==
X-Change-ID: 20250618-device-bearer-level-conn-state-3e29d56bda88
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750214394; l=5408;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=5NJLCTJGyuiY5wQYw++2OOdOnlJ+lHfP9kxxF+ljbvU=;
 b=IpMRwyN717ur9af6m+i0N3mhR4xIgrG1AxKb5fzgSXW/iCaFmQ65sEpYsocX4dBXstZT5+HRv
 OtwoXizfR/BC/XFEX6y7+hOjRKfBgUGDCNhBYpxU62KolohNUe9EGpl
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch add a new Connected(string bearer) signal to indicate which transport
(LE or BR/EDR) has connected. Also extend the Disconnected signal to include
a bearer argument.

This allows applications to distinguish transport-specific connection
events in dual-mode scenarios.

Fixes: https://github.com/bluez/bluez/issues/1350

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 doc/org.bluez.Device.rst | 33 ++++++++++++++++++++++++++++++++-
 src/device.c             | 34 ++++++++++++++++++++++++++--------
 2 files changed, 58 insertions(+), 9 deletions(-)

diff --git a/doc/org.bluez.Device.rst b/doc/org.bluez.Device.rst
index 646e2c77ec2ddcbf7e6897336165d228c349fe00..1022402d95a1cd34dea88103ba66fb06f3007de7 100644
--- a/doc/org.bluez.Device.rst
+++ b/doc/org.bluez.Device.rst
@@ -157,7 +157,26 @@ Possible errors:
 Signals
 -------
 
-void Disconnected(string reason, string message)
+void Connected(string bearer)
+````````````````````````````````````````````````
+
+This signal is emitted when a device establishes a connection, indicating the
+bearer (transport type) over which the connection occurred.
+
+Client applications may use this signal to take actions such as stopping discovery
+or advertising, depending on their internal policy.
+
+Possible bearer:
+
+:"le":
+
+	LE transport is cconnected.
+
+:"bredr":
+
+	BR/EDR transport is connected.
+
+void Disconnected(string reason, string message, string bearer)
 ````````````````````````````````````````````````
 
 This signal is launched when a device is disconnected, with the reason of the
@@ -208,6 +227,18 @@ Possible reasons:
 
 	Connection terminated by local host for suspend.
 
+The additional 'bearer' field indicates which transport was disconnected.
+
+Possible bearer:
+
+:"le":
+
+	LE transport is disconnected.
+
+:"bredr":
+
+	BR/EDR transport is disconnected.
+
 Properties
 ----------
 
diff --git a/src/device.c b/src/device.c
index 902c4aa44d21eb89076eff3a47ffa727420967a8..ae6196eb2e5b6eca10a8e1c3360b85023dcddec2 100644
--- a/src/device.c
+++ b/src/device.c
@@ -3491,8 +3491,10 @@ static const GDBusMethodTable device_methods[] = {
 };
 
 static const GDBusSignalTable device_signals[] = {
+	{ GDBUS_SIGNAL("Connected",
+			GDBUS_ARGS({ "bearer", "s" })) },
 	{ GDBUS_SIGNAL("Disconnected",
-			GDBUS_ARGS({ "name", "s" }, { "message", "s" })) },
+			GDBUS_ARGS({ "name", "s" }, { "message", "s" }, { "bearer", "s" })) },
 	{ }
 };
 
@@ -3676,6 +3678,7 @@ void device_add_connection(struct btd_device *dev, uint8_t bdaddr_type,
 							uint32_t flags)
 {
 	struct bearer_state *state = get_state(dev, bdaddr_type);
+	const char *bearer;
 
 	device_update_last_seen(dev, bdaddr_type, true);
 	device_update_last_used(dev, bdaddr_type);
@@ -3691,14 +3694,22 @@ void device_add_connection(struct btd_device *dev, uint8_t bdaddr_type,
 	dev->conn_bdaddr_type = dev->bdaddr_type;
 
 	/* If this is the first connection over this bearer */
-	if (bdaddr_type == BDADDR_BREDR)
+	if (bdaddr_type == BDADDR_BREDR) {
 		device_set_bredr_support(dev);
-	else
+		bearer = "bredr";
+	} else {
 		device_set_le_support(dev, bdaddr_type);
+		bearer = "le";
+	}
 
 	state->connected = true;
 	state->initiator = flags & BIT(3);
 
+	g_dbus_emit_signal(dbus_conn, dev->path, DEVICE_INTERFACE,
+				"Connected",
+				DBUS_TYPE_STRING, &bearer,
+				DBUS_TYPE_INVALID);
+
 	if (dev->le_state.connected && dev->bredr_state.connected)
 		return;
 
@@ -3747,7 +3758,7 @@ static void set_temporary_timer(struct btd_device *dev, unsigned int timeout)
 								dev, NULL);
 }
 
-static void device_disconnected(struct btd_device *device, uint8_t reason)
+static void device_disconnected(struct btd_device *device, uint8_t reason, const char *bearer)
 {
 	const char *name;
 	const char *message;
@@ -3787,6 +3798,7 @@ static void device_disconnected(struct btd_device *device, uint8_t reason)
 						"Disconnected",
 						DBUS_TYPE_STRING, &name,
 						DBUS_TYPE_STRING, &message,
+						DBUS_TYPE_STRING, &bearer,
 						DBUS_TYPE_INVALID);
 }
 
@@ -3798,10 +3810,16 @@ void device_remove_connection(struct btd_device *device, uint8_t bdaddr_type,
 	DBusMessage *reply;
 	bool remove_device = false;
 	bool paired_status_updated = false;
+	const char *bearer;
 
 	if (!state->connected)
 		return;
 
+	if (bdaddr_type == BDADDR_BREDR)
+		bearer = "bredr";
+	else
+		bearer = "le";
+
 	state->connected = false;
 	state->initiator = false;
 	device->general_connect = FALSE;
@@ -3854,15 +3872,15 @@ void device_remove_connection(struct btd_device *device, uint8_t bdaddr_type,
 						DEVICE_INTERFACE,
 						"Paired");
 
-	if (device->bredr_state.connected || device->le_state.connected)
-		return;
-
 	device_update_last_seen(device, bdaddr_type, true);
 
 	g_slist_free_full(device->eir_uuids, g_free);
 	device->eir_uuids = NULL;
 
-	device_disconnected(device, reason);
+	device_disconnected(device, reason, bearer);
+
+	if (device->bredr_state.connected || device->le_state.connected)
+		return;
 
 	g_dbus_emit_property_changed(dbus_conn, device->path,
 						DEVICE_INTERFACE, "Connected");

---
base-commit: dc8db3601001de9a085da063e0c5e456074b8963
change-id: 20250618-device-bearer-level-conn-state-3e29d56bda88

Best regards,
-- 
Ye He <ye.he@amlogic.com>

