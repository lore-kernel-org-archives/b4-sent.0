From: Yang Li <yang.li@amlogic.com>
Date: Tue, 19 Aug 2025 15:42:24 +0800
Subject: [PATCH] Bluetooth: hci_event: Disconnect device when BIG sync is
 lost
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250819-bis_dev_disconnect-v1-1-a87c540efc46@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAN8qpGgC/x3MTQqAIBBA4avErBPUiH6uEhHmTDUbCyckkO6et
 PwW72UQikwCY5UhUmLhMxSYugJ/uLCTYiwGq22rezOolWVBSguy+DME8rdqjEPrCG23eijhFWn
 j559O8/t+ujHoImQAAAA=
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755589361; l=1615;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=/vhHRnEjB+7Jmzi7phGDpbSSLMxQT6GFh7t8rujQBfY=;
 b=51iFZ4j+7dfQHrrvk+ZfzzZSwBLCVJ61HsQRjqSXJGCbY7lVHUWcHJA3kcrd34NnN4QaCnwKy
 2ztKhhkfCZoApBo2wjDYODktyOGETXYQ11f+ApiWfqIjBE9XWF8kJis
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a BIG sync is lost, the device should be set to "disconnected".
This ensures symmetry with the ISO path setup, where the device is
marked as "connected" once the path is established. Without this
change, the device state remains inconsistent and may lead to a
memory leak.

Fixes: b2a5f2e1c127 ("Bluetooth: hci_event: Add support for handling LE BIG Sync Lost event")
Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 net/bluetooth/hci_event.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/net/bluetooth/hci_event.c b/net/bluetooth/hci_event.c
index 1686680a38c8..59aae893e0ed 100644
--- a/net/bluetooth/hci_event.c
+++ b/net/bluetooth/hci_event.c
@@ -6998,6 +6998,7 @@ static void hci_le_big_sync_lost_evt(struct hci_dev *hdev, void *data,
 {
 	struct hci_evt_le_big_sync_lost *ev = data;
 	struct hci_conn *bis, *conn;
+	bool mgmt_conn;
 
 	bt_dev_dbg(hdev, "big handle 0x%2.2x", ev->handle);
 
@@ -7016,6 +7017,10 @@ static void hci_le_big_sync_lost_evt(struct hci_dev *hdev, void *data,
 	while ((bis = hci_conn_hash_lookup_big_state(hdev, ev->handle,
 						     BT_CONNECTED,
 						     HCI_ROLE_SLAVE))) {
+		mgmt_conn = test_and_clear_bit(HCI_CONN_MGMT_CONNECTED, &bis->flags);
+		mgmt_device_disconnected(hdev, &bis->dst, bis->type, bis->dst_type,
+					 ev->reason, mgmt_conn);
+
 		clear_bit(HCI_CONN_BIG_SYNC, &bis->flags);
 		hci_disconn_cfm(bis, ev->reason);
 		hci_conn_del(bis);

---
base-commit: c921e5d14590381e6db7e451488b7b9ddc67a32c
change-id: 20250819-bis_dev_disconnect-31ad2aed27bc

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

