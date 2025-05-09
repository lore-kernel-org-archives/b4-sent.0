From: Yang Li <yang.li@amlogic.com>
Date: Fri, 09 May 2025 18:17:04 +0800
Subject: [PATCH v2] Bluetooth: fix socket matching ambiguity between BIS
 and CIS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-iso-v2-1-da53bd18c193@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAB/WHWgC/zWMyw6CMBBFf4XM2po+bFFX/gdhQcsAkwg1rWkwp
 P9ubeLy3NxzDogYCCPcmwMCJorktwLy1IBbhm1GRmNhkFxqrrlhFD0zWujrTVltrYLyfAWcaK+
 Vri+8UHz78KnRJH7r32+rnwQTzEyGj/KikKv2MaxPP5M7O79Cn3P+Ah83fIGYAAAA
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746785845; l=5072;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=VjVfZ4Q3GK4UA1LAAiFeOM2PfRNRZQCaap54bHro5Y0=;
 b=+duwP9MYf9CGYkQ3dquP8kyUihl8OoaF+YWsMEaJkbD4+niMYXCKvUIp+J79RNyDzSajNaMC8
 TcxAZ2TYNCPBvjqcxsaD93F/itBYSKzFzfG46ydodr2H29obmHEMgob
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the DUT acts as a sink device, and a BIS already exists,
creating a CIS connection can cause the kernel to incorrectly
reference the BIS socket. This occurs because the socket
lookup only checks for state == BT_LISTEN, without
distinguishing between BIS and CIS socket types.

To fix this, match the destination address (dst addr) during
ISO socket lookup to differentiate between BIS and CIS sockets
properly.

Link: https://github.com/bluez/bluez/issues/1224

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v2:
- Fix compilation errors
- Improved the problem description for clarity.
- Link to v1: https://lore.kernel.org/r/20250507-iso-v1-1-6f60d243e037@amlogic.com
---
 net/bluetooth/hci_event.c | 34 +++++++++++++++++++---------------
 net/bluetooth/iso.c       | 12 +++++++++---
 2 files changed, 28 insertions(+), 18 deletions(-)

diff --git a/net/bluetooth/hci_event.c b/net/bluetooth/hci_event.c
index 66052d6aaa1d..6b26344ad69f 100644
--- a/net/bluetooth/hci_event.c
+++ b/net/bluetooth/hci_event.c
@@ -6413,6 +6413,8 @@ static void hci_le_pa_sync_estabilished_evt(struct hci_dev *hdev, void *data,
 
 	conn->sync_handle = le16_to_cpu(ev->handle);
 	conn->sid = HCI_SID_INVALID;
+	conn->dst = ev->bdaddr;
+	conn->dst_type = ev->bdaddr_type;
 
 	mask |= hci_proto_connect_ind(hdev, &ev->bdaddr, BIS_LINK,
 				      &flags);
@@ -6425,7 +6427,7 @@ static void hci_le_pa_sync_estabilished_evt(struct hci_dev *hdev, void *data,
 		goto unlock;
 
 	/* Add connection to indicate PA sync event */
-	pa_sync = hci_conn_add_unset(hdev, BIS_LINK, BDADDR_ANY,
+	pa_sync = hci_conn_add_unset(hdev, BIS_LINK, &ev->bdaddr,
 				     HCI_ROLE_SLAVE);
 
 	if (IS_ERR(pa_sync))
@@ -6456,13 +6458,6 @@ static void hci_le_per_adv_report_evt(struct hci_dev *hdev, void *data,
 
 	hci_dev_lock(hdev);
 
-	mask |= hci_proto_connect_ind(hdev, BDADDR_ANY, BIS_LINK, &flags);
-	if (!(mask & HCI_LM_ACCEPT))
-		goto unlock;
-
-	if (!(flags & HCI_PROTO_DEFER))
-		goto unlock;
-
 	pa_sync = hci_conn_hash_lookup_pa_sync_handle
 			(hdev,
 			le16_to_cpu(ev->sync_handle));
@@ -6470,6 +6465,13 @@ static void hci_le_per_adv_report_evt(struct hci_dev *hdev, void *data,
 	if (!pa_sync)
 		goto unlock;
 
+	mask |= hci_proto_connect_ind(hdev, &pa_sync->dst, BIS_LINK, &flags);
+	if (!(mask & HCI_LM_ACCEPT))
+		goto unlock;
+
+	if (!(flags & HCI_PROTO_DEFER))
+		goto unlock;
+
 	if (ev->data_status == LE_PA_DATA_COMPLETE &&
 	    !test_and_set_bit(HCI_CONN_PA_SYNC, &pa_sync->flags)) {
 		/* Notify iso layer */
@@ -6993,6 +6995,8 @@ static void hci_le_big_sync_established_evt(struct hci_dev *hdev, void *data,
 			set_bit(HCI_CONN_PA_SYNC, &bis->flags);
 
 		bis->sync_handle = conn->sync_handle;
+		bis->dst = conn->dst;
+		bis->dst_type = conn->dst_type;
 		bis->iso_qos.bcast.big = ev->handle;
 		memset(&interval, 0, sizeof(interval));
 		memcpy(&interval, ev->latency, sizeof(ev->latency));
@@ -7038,13 +7042,6 @@ static void hci_le_big_info_adv_report_evt(struct hci_dev *hdev, void *data,
 
 	hci_dev_lock(hdev);
 
-	mask |= hci_proto_connect_ind(hdev, BDADDR_ANY, BIS_LINK, &flags);
-	if (!(mask & HCI_LM_ACCEPT))
-		goto unlock;
-
-	if (!(flags & HCI_PROTO_DEFER))
-		goto unlock;
-
 	pa_sync = hci_conn_hash_lookup_pa_sync_handle
 			(hdev,
 			le16_to_cpu(ev->sync_handle));
@@ -7054,6 +7051,13 @@ static void hci_le_big_info_adv_report_evt(struct hci_dev *hdev, void *data,
 
 	pa_sync->iso_qos.bcast.encryption = ev->encryption;
 
+	mask |= hci_proto_connect_ind(hdev, &pa_sync->dst, BIS_LINK, &flags);
+	if (!(mask & HCI_LM_ACCEPT))
+		goto unlock;
+
+	if (!(flags & HCI_PROTO_DEFER))
+		goto unlock;
+
 	/* Notify iso layer */
 	hci_connect_cfm(pa_sync, 0);
 
diff --git a/net/bluetooth/iso.c b/net/bluetooth/iso.c
index 6e2c752aaa8f..1dc233f04dbe 100644
--- a/net/bluetooth/iso.c
+++ b/net/bluetooth/iso.c
@@ -641,11 +641,12 @@ static struct sock *iso_get_sock(bdaddr_t *src, bdaddr_t *dst,
 			continue;
 
 		/* Exact match. */
-		if (!bacmp(&iso_pi(sk)->src, src)) {
+		if (!bacmp(&iso_pi(sk)->src, src)
+		     && !bacmp(&iso_pi(sk)->dst, dst)
+			){
 			sock_hold(sk);
 			break;
 		}
-
 		/* Closest match */
 		if (!bacmp(&iso_pi(sk)->src, BDADDR_ANY)) {
 			if (sk1)
@@ -1962,7 +1963,7 @@ static void iso_conn_ready(struct iso_conn *conn)
 		}
 
 		if (!parent)
-			parent = iso_get_sock(&hcon->src, BDADDR_ANY,
+			parent = iso_get_sock(&hcon->src, &hcon->dst,
 					      BT_LISTEN, NULL, NULL);
 
 		if (!parent)
@@ -2203,6 +2204,11 @@ int iso_connect_ind(struct hci_dev *hdev, bdaddr_t *bdaddr, __u8 *flags)
 	} else {
 		sk = iso_get_sock(&hdev->bdaddr, BDADDR_ANY,
 				  BT_LISTEN, NULL, NULL);
+		if (!sk)
+			sk = iso_get_sock(&hdev->bdaddr, bdaddr,
+					  BT_LISTEN, NULL, NULL);
+		else
+			iso_pi(sk)->dst = *bdaddr;
 	}
 
 done:

---
base-commit: f3daca9b490154fbb0459848cc2ed61e8367bddc
change-id: 20250506-iso-6515893b5bb3

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

