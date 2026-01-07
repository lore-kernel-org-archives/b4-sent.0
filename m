From: Yang Li <yang.li@amlogic.com>
Date: Wed, 07 Jan 2026 16:51:36 +0800
Subject: [PATCH BlueZ bluez 1/2] adapter: add MGMT_EV_EXT_ADV_SID_CHANGED
 mgmt event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-mgmt_ext_adv_sid-v1-1-6832b40813fd@amlogic.com>
References: <20260107-mgmt_ext_adv_sid-v1-0-6832b40813fd@amlogic.com>
In-Reply-To: <20260107-mgmt_ext_adv_sid-v1-0-6832b40813fd@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767775901; l=5030;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=s9S/xcKkxqt1zVHUxTFusxppBE5BL2rzP7clSEle5l8=;
 b=wior3eFE/TuOU/s/TDu8t13dwyLFd+dcYiTN17A+5kXT0MmQa92JsD1VF3Jl00MwDaMDZCPF4
 /1haZ34rMBwDzc+Tpuo+0hGJvzoMNKQI5jBYKdsXmIT7si9J7OQjgPc
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the MGMT_EV_EXT_ADV_SID_CHANGED mgmt event to notify userspace
of SID updates for extended advertising.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 lib/bluetooth/mgmt.h |  7 +++++++
 src/adapter.c        | 39 +++++++++++++++++++++++++++++++++++++--
 src/device.c         | 22 ++++++++++++++++++++++
 src/device.h         |  2 ++
 4 files changed, 68 insertions(+), 2 deletions(-)

diff --git a/lib/bluetooth/mgmt.h b/lib/bluetooth/mgmt.h
index 1ad52529f..338d2a732 100644
--- a/lib/bluetooth/mgmt.h
+++ b/lib/bluetooth/mgmt.h
@@ -1107,6 +1107,12 @@ struct mgmt_ev_mesh_pkt_cmplt {
 	uint8_t	handle;
 } __packed;
 
+#define MGMT_EV_EXT_ADV_SID_CHANGED		0x0033
+struct mgmt_ev_ext_adv_sid_changed {
+	struct mgmt_addr_info addr;
+	uint8_t	sid;
+} __packed;
+
 static const char *mgmt_op[] = {
 	"<0x0000>",
 	"Read Version",
@@ -1253,6 +1259,7 @@ static const char *mgmt_ev[] = {
 	"Advertisement Monitor Device Lost",
 	"Mesh Packet Found",
 	"Mesh Packet Complete",
+	"Extended Advertising SID Changed",
 	"PA Sync Established",
 	"BIG Sync Established",
 	"BIG Sync Lost",
diff --git a/src/adapter.c b/src/adapter.c
index a5de7cee1..ee6a1e711 100644
--- a/src/adapter.c
+++ b/src/adapter.c
@@ -84,6 +84,7 @@
 #define SCAN_TYPE_DUAL (SCAN_TYPE_BREDR | SCAN_TYPE_LE)
 
 #define HCI_RSSI_INVALID	127
+#define HCI_SID_INVALID		0xff
 #define DISTANCE_VAL_INVALID	0x7FFF
 #define PATHLOSS_MAX		137
 
@@ -7446,6 +7447,7 @@ void btd_adapter_device_found(struct btd_adapter *adapter,
 	}
 
 	device_set_legacy(dev, legacy);
+	device_set_sid(dev, HCI_SID_INVALID);
 
 	if (name_resolve_failed)
 		device_name_resolve_fail(dev);
@@ -7601,14 +7603,42 @@ static void device_found_callback(uint16_t index, uint16_t length,
 	flags = le32_to_cpu(ev->flags);
 
 	ba2str(&ev->addr.bdaddr, addr);
-	DBG("hci%u addr %s, rssi %d flags 0x%04x eir_len %u",
-			index, addr, ev->rssi, flags, eir_len);
+	DBG("hci%u addr %s type %u, rssi %d flags 0x%04x eir_len %u",
+			index, addr, ev->addr.type, ev->rssi, flags, eir_len);
 
 	btd_adapter_device_found(adapter, &ev->addr.bdaddr,
 					ev->addr.type, ev->rssi, flags,
 					eir, eir_len, false);
 }
 
+static void device_ext_adv_sid_changed_callback(uint16_t index, uint16_t length,
+					const void *param, void *user_data)
+{
+	const struct mgmt_ev_ext_adv_sid_changed *ev = param;
+	struct btd_adapter *adapter = user_data;
+	struct btd_device *dev;
+	char addr[18];
+
+	if (length < sizeof(*ev)) {
+		btd_error(adapter->dev_id,
+			"Too short ext adv sid changed event (%u bytes)",
+			length);
+		return;
+	}
+
+	ba2str(&ev->addr.bdaddr, addr);
+	DBG("hci%u addr %s type %u, sid %u", index, addr, ev->addr.type, ev->sid);
+
+	dev = btd_adapter_find_device(adapter, &ev->addr.bdaddr,
+							ev->addr.type);
+	if (!dev) {
+		DBG("No device found for ext adv sid change event");
+		return;
+	}
+
+	device_set_sid(dev, ev->sid);
+}
+
 struct agent *adapter_get_agent(struct btd_adapter *adapter)
 {
 	return agent_get(NULL);
@@ -10424,6 +10454,11 @@ static void read_info_complete(uint8_t status, uint16_t length,
 						device_found_callback,
 						adapter, NULL);
 
+	mgmt_register(adapter->mgmt, MGMT_EV_EXT_ADV_SID_CHANGED,
+						adapter->dev_id,
+						device_ext_adv_sid_changed_callback,
+						adapter, NULL);
+
 	mgmt_register(adapter->mgmt, MGMT_EV_DEVICE_DISCONNECTED,
 						adapter->dev_id,
 						disconnected_callback,
diff --git a/src/device.c b/src/device.c
index c8aaf042f..827b897ab 100644
--- a/src/device.c
+++ b/src/device.c
@@ -298,6 +298,7 @@ struct btd_device {
 	gboolean	general_connect;
 
 	bool		legacy;
+	uint8_t		sid;
 	int8_t		rssi;
 	int8_t		tx_power;
 
@@ -7106,6 +7107,27 @@ void device_set_rssi(struct btd_device *device, int8_t rssi)
 	device_set_rssi_with_delta(device, rssi, RSSI_THRESHOLD);
 }
 
+void device_set_sid(struct btd_device *device, uint8_t sid)
+{
+	if (!device)
+		return;
+
+	if (device->sid == sid)
+		return;
+
+	DBG("sid %d", sid);
+
+	device->sid = sid;
+}
+
+uint8_t device_get_sid(struct btd_device *device)
+{
+	if (!device)
+		return 0xFF;
+
+	return device->sid;
+}
+
 void device_set_tx_power(struct btd_device *device, int8_t tx_power)
 {
 	if (!device)
diff --git a/src/device.h b/src/device.h
index c7b8b2a16..82332001e 100644
--- a/src/device.h
+++ b/src/device.h
@@ -108,6 +108,8 @@ void device_set_cable_pairing(struct btd_device *device, bool cable_pairing);
 void device_set_rssi_with_delta(struct btd_device *device, int8_t rssi,
 							int8_t delta_threshold);
 void device_set_rssi(struct btd_device *device, int8_t rssi);
+void device_set_sid(struct btd_device *device, uint8_t sid);
+uint8_t device_get_sid(struct btd_device *device);
 void device_set_tx_power(struct btd_device *device, int8_t tx_power);
 void device_set_flags(struct btd_device *device, uint8_t flags);
 bool btd_device_is_connected(struct btd_device *dev);

-- 
2.42.0

