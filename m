From: =?utf-8?q?Neboj=C5=A1a_Cvetkovi=C4=87?= <nebkat@gmail.com>
Date: Sat, 14 Nov 2026 10:09:55 -0500
Subject: [PATCH bluez] gatt-client: Fix not emitting MTU on reconnection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261114-gatt-client-mtu-reconnect-v1-1-a86edc1eb208@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yWM0Q6CMAwAf4X02SZ06lB/xfgAs2INFrN1hEj4d
 6c+3iV3CySOwglO1QKRJ0kyagHaVBDurfaMci0MrnaeiHbYt2YYBmE1fFrGyGFU5WBIbr89UNP
 4o6+h9K/IN5l/7zN0Q+Y3XP465e5Riu8X1vUDfbjE2IQAAAA=
X-Change-ID: 20261114-gatt-client-mtu-reconnect-125381776960
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: =?utf-8?q?Neboj=C5=A1a_Cvetkovi=C4=87?= <nebkat@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794668995; l=2589;
 i=nebkat@gmail.com; s=20261114; h=from:subject:message-id;
 bh=7zEhQSfBbmmd9CGuGhNZp1WtJKQdpGgoQNgSKQa7HMc=;
 b=zZpPcw5ZkDN1Y0ya2iX6dBnnnwD3g4EDbbMbSPmP05utKTk6Zi0lol8uWGMcRJ9IK9JWpKpgY
 H+OKQXH1etGAVMCsOLAO2Uil9YCv3Bbioz79GguVWnwasEeDpcQBNdU
X-Developer-Key: i=nebkat@gmail.com; a=ed25519;
 pk=uig8l6j+LcM3b6EaVYnCVjReuerjQ7eZjriM64jfQzs=
X-Endpoint-Received: by B4 Relay for nebkat@gmail.com/20261114 with auth_id=1529
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Characteristics kept across a disconnection have their MTU exchange
callback registered on the bt_att of the connection they were created
on, so no PropertiesChanged is emitted for MTU on later connections. As
MTU is omitted while disconnected, a client that enumerated the objects
in between has no MTU for the whole connection, and one that kept them
has the value of the previous connection.

Register the callback on the bt_att of the new connection, and emit MTU
as it is no longer omitted.

Fixes: 3a6b5f5ec14c ("gatt: Emit PropertiesChanged("MTU") when MTU is exchanged")
Assisted-by: Claude:claude-opus-5-5
---
Signed-off-by: Nebojša Cvetković <nebkat@gmail.com>
---
 src/gatt-client.c | 29 +++++++++++++++++++++++++++++
 1 file changed, 29 insertions(+)

diff --git a/src/gatt-client.c b/src/gatt-client.c
index d94dc9d..2d58ee2 100644
--- a/src/gatt-client.c
+++ b/src/gatt-client.c
@@ -2414,9 +2414,29 @@ void btd_gatt_client_eatt_connect(struct btd_gatt_client *client)
 	}
 }
 
+static void characteristic_attach_att(void *data, void *user_data)
+{
+	struct characteristic *chrc = data;
+	struct bt_att *att = user_data;
+
+	chrc->exchange_id = bt_att_register_exchange(att, att_exchange, chrc,
+									NULL);
+
+	g_dbus_emit_property_changed(btd_get_dbus_connection(), chrc->path,
+					GATT_CHARACTERISTIC_IFACE, "MTU");
+}
+
+static void service_attach_att(void *data, void *user_data)
+{
+	struct service *service = data;
+
+	queue_foreach(service->chrcs, characteristic_attach_att, user_data);
+}
+
 void btd_gatt_client_connected(struct btd_gatt_client *client)
 {
 	struct bt_gatt_client *gatt;
+	struct bt_att *att;
 
 	gatt = btd_device_get_gatt_client(client->device);
 	if (!gatt) {
@@ -2429,6 +2449,15 @@ void btd_gatt_client_connected(struct btd_gatt_client *client)
 	bt_gatt_client_unref(client->gatt);
 	client->gatt = bt_gatt_client_clone(gatt);
 
+	/*
+	 * Characteristics kept from a previous connection have their exchange
+	 * callback registered on its bt_att, and MTU was omitted while
+	 * disconnected, so register them again and emit MTU.
+	 */
+	att = bt_gatt_client_get_att(client->gatt);
+	if (att)
+		queue_foreach(client->services, service_attach_att, att);
+
 	/*
 	 * Services have already been created before. Re-enable notifications
 	 * for any pre-registered notification sessions.

---
base-commit: 20ffd285b58facfd1f2478d159a5f941b09d5be1
change-id: 20261114-gatt-client-mtu-reconnect-125381776960

Best regards,
--  
Nebojša Cvetković <nebkat@gmail.com>

