From: Yang Li <yang.li@amlogic.com>
Date: Tue, 24 Jun 2025 13:20:44 +0800
Subject: [PATCH] Bluetooth: hci_event: Add support for handling LE BIG Sync
 Lost event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-handle_big_sync_lost_event-v1-1-c32ce37dd6a5@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAKs1WmgC/x3M0QpAMBSA4VfRubaaGeJVpMV2cEqjHYm0d7dcf
 v/F/wJjIGToshcCXsS0+4Qiz8Cuo19QkEsGJVUl60KJFN2GZqLF8OOt2XY+DV7oT6Ft42yty1a
 OCtLgCDjT/c/7IcYPVSYaKGwAAAA=
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750742454; l=2539;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=3xOWybT0hvFSOiNGPz4vVsSCR2isMoJtxxrE8KhFyic=;
 b=32qzfmyTCP2aM6DgE1emIRrsb577fcGy9Zd752E4k1VUKQgvSU5vECllJAWiESugLEAJre9dX
 db2PB9JhMGYB8NfmtCzmzs1PRBu1I5oMxPdATGC1snm6pvrCx1BJyRz
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the BIS source stops, the controller sends an LE BIG Sync Lost
event (subevent 0x1E). Currently, this event is not handled, causing
the BIS stream to remain active in BlueZ and preventing recovery.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 include/net/bluetooth/hci.h |  6 ++++++
 net/bluetooth/hci_event.c   | 23 +++++++++++++++++++++++
 2 files changed, 29 insertions(+)

diff --git a/include/net/bluetooth/hci.h b/include/net/bluetooth/hci.h
index 82cbd54443ac..48389a64accb 100644
--- a/include/net/bluetooth/hci.h
+++ b/include/net/bluetooth/hci.h
@@ -2849,6 +2849,12 @@ struct hci_evt_le_big_sync_estabilished {
 	__le16  bis[];
 } __packed;
 
+#define HCI_EVT_LE_BIG_SYNC_LOST 0x1e
+struct hci_evt_le_big_sync_lost {
+	__u8    handle;
+	__u8    reason;
+} __packed;
+
 #define HCI_EVT_LE_BIG_INFO_ADV_REPORT	0x22
 struct hci_evt_le_big_info_adv_report {
 	__le16  sync_handle;
diff --git a/net/bluetooth/hci_event.c b/net/bluetooth/hci_event.c
index 66052d6aaa1d..730deaf1851f 100644
--- a/net/bluetooth/hci_event.c
+++ b/net/bluetooth/hci_event.c
@@ -7026,6 +7026,24 @@ static void hci_le_big_sync_established_evt(struct hci_dev *hdev, void *data,
 	hci_dev_unlock(hdev);
 }
 
+static void hci_le_big_sync_lost_evt(struct hci_dev *hdev, void *data,
+					    struct sk_buff *skb)
+{
+	struct hci_evt_le_big_sync_lost *ev = data;
+	struct hci_conn *conn;
+
+	bt_dev_dbg(hdev, "BIG Sync Lost: big_handle 0x%2.2x", ev->handle);
+
+	hci_dev_lock(hdev);
+
+	list_for_each_entry(conn, &hdev->conn_hash.list, list) {
+		if (test_bit(HCI_CONN_BIG_SYNC, &conn->flags))
+			hci_disconn_cfm(conn, HCI_ERROR_REMOTE_USER_TERM);
+	}
+
+	hci_dev_unlock(hdev);
+}
+
 static void hci_le_big_info_adv_report_evt(struct hci_dev *hdev, void *data,
 					   struct sk_buff *skb)
 {
@@ -7149,6 +7167,11 @@ static const struct hci_le_ev {
 		     hci_le_big_sync_established_evt,
 		     sizeof(struct hci_evt_le_big_sync_estabilished),
 		     HCI_MAX_EVENT_SIZE),
+	/* [0x1e = HCI_EVT_LE_BIG_SYNC_LOST] */
+	HCI_LE_EV_VL(HCI_EVT_LE_BIG_SYNC_LOST,
+		     hci_le_big_sync_lost_evt,
+		     sizeof(struct hci_evt_le_big_sync_lost),
+		     HCI_MAX_EVENT_SIZE),
 	/* [0x22 = HCI_EVT_LE_BIG_INFO_ADV_REPORT] */
 	HCI_LE_EV_VL(HCI_EVT_LE_BIG_INFO_ADV_REPORT,
 		     hci_le_big_info_adv_report_evt,

---
base-commit: bd35cd12d915bc410c721ba28afcada16f0ebd16
change-id: 20250612-handle_big_sync_lost_event-4c7dc64390a2

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

