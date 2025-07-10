From: Yang Li <yang.li@amlogic.com>
Date: Thu, 10 Jul 2025 18:52:47 +0800
Subject: [PATCH] Bluetooth: Add PA_LINK to distinguish BIG sync and PA sync
 connections
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250710-pa_link-v1-1-88cac0c0b776@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAH6bb2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDc0MD3YLE+JzMvGxdS5NUI0ujVCNzM4tUJaDqgqLUtMwKsEnRsbW1AAZ
 IvH1ZAAAA
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752144769; l=14122;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=kQ4GbUtOkJ7tUT4OgPVDiJ1mrZufI2zvpG1vvRJz7ic=;
 b=KCiOiyexTPM61jBMhbDFbGMvzir6VcYizQgJ/TesjgqnKnTVPnX+gk1rqzAFzq5Xux8Tc7r12
 R3+6KIeZXmrCb+5ZG/p0DdFwRQweaDbOQjWrIioyPypEglrf/nxHgzt
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, BIS_LINK is used for both BIG sync and PA sync connections,
which makes it impossible to distinguish them when searching for a PA
sync connection.

Adding PA_LINK will make the distinction clearer and simplify future
extensions for PA-related features.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 include/net/bluetooth/hci.h      |  1 +
 include/net/bluetooth/hci_core.h | 10 +++++++---
 net/bluetooth/hci_conn.c         | 14 +++++++++-----
 net/bluetooth/hci_core.c         | 27 +++++++++++++++------------
 net/bluetooth/hci_event.c        |  7 ++++---
 net/bluetooth/hci_sync.c         | 10 +++++-----
 net/bluetooth/iso.c              |  6 ++++--
 net/bluetooth/mgmt.c             |  1 +
 8 files changed, 46 insertions(+), 30 deletions(-)

diff --git a/include/net/bluetooth/hci.h b/include/net/bluetooth/hci.h
index 19248d326cb2..50134b48b828 100644
--- a/include/net/bluetooth/hci.h
+++ b/include/net/bluetooth/hci.h
@@ -560,6 +560,7 @@ enum {
 #define LE_LINK		0x80
 #define CIS_LINK	0x82
 #define BIS_LINK	0x83
+#define PA_LINK		0x84
 #define INVALID_LINK	0xff
 
 /* LMP features */
diff --git a/include/net/bluetooth/hci_core.h b/include/net/bluetooth/hci_core.h
index 3ce1fb6f5822..2ebadd45fabb 100644
--- a/include/net/bluetooth/hci_core.h
+++ b/include/net/bluetooth/hci_core.h
@@ -1005,6 +1005,7 @@ static inline void hci_conn_hash_add(struct hci_dev *hdev, struct hci_conn *c)
 		break;
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 		h->iso_num++;
 		break;
 	}
@@ -1032,6 +1033,7 @@ static inline void hci_conn_hash_del(struct hci_dev *hdev, struct hci_conn *c)
 		break;
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 		h->iso_num--;
 		break;
 	}
@@ -1050,6 +1052,7 @@ static inline unsigned int hci_conn_num(struct hci_dev *hdev, __u8 type)
 		return h->sco_num;
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 		return h->iso_num;
 	default:
 		return 0;
@@ -1132,7 +1135,7 @@ hci_conn_hash_lookup_create_pa_sync(struct hci_dev *hdev)
 	rcu_read_lock();
 
 	list_for_each_entry_rcu(c, &h->list, list) {
-		if (c->type != BIS_LINK)
+		if (c->type != PA_LINK)
 			continue;
 
 		if (!test_bit(HCI_CONN_CREATE_PA_SYNC, &c->flags))
@@ -1327,7 +1330,7 @@ hci_conn_hash_lookup_big_sync_pend(struct hci_dev *hdev,
 	rcu_read_lock();
 
 	list_for_each_entry_rcu(c, &h->list, list) {
-		if (c->type != BIS_LINK)
+		if (c->type != PA_LINK)
 			continue;
 
 		if (handle == c->iso_qos.bcast.big && num_bis == c->num_bis) {
@@ -1397,7 +1400,7 @@ hci_conn_hash_lookup_pa_sync_handle(struct hci_dev *hdev, __u16 sync_handle)
 	rcu_read_lock();
 
 	list_for_each_entry_rcu(c, &h->list, list) {
-		if (c->type != BIS_LINK)
+		if (c->type != PA_LINK)
 			continue;
 
 		/* Ignore the listen hcon, we are looking
@@ -1996,6 +1999,7 @@ static inline int hci_proto_connect_ind(struct hci_dev *hdev, bdaddr_t *bdaddr,
 
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 		return iso_connect_ind(hdev, bdaddr, flags);
 
 	default:
diff --git a/net/bluetooth/hci_conn.c b/net/bluetooth/hci_conn.c
index f5cd935490ad..4042e75c33a6 100644
--- a/net/bluetooth/hci_conn.c
+++ b/net/bluetooth/hci_conn.c
@@ -785,7 +785,7 @@ static int hci_le_big_terminate(struct hci_dev *hdev, u8 big, struct hci_conn *c
 	d->sync_handle = conn->sync_handle;
 
 	if (test_and_clear_bit(HCI_CONN_PA_SYNC, &conn->flags)) {
-		hci_conn_hash_list_flag(hdev, find_bis, BIS_LINK,
+		hci_conn_hash_list_flag(hdev, find_bis, PA_LINK,
 					HCI_CONN_PA_SYNC, d);
 
 		if (!d->count)
@@ -914,6 +914,7 @@ static struct hci_conn *__hci_conn_add(struct hci_dev *hdev, int type, bdaddr_t
 		break;
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 		if (hdev->iso_mtu)
 			/* Dedicated ISO Buffer exists */
 			break;
@@ -979,6 +980,7 @@ static struct hci_conn *__hci_conn_add(struct hci_dev *hdev, int type, bdaddr_t
 		break;
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 		/* conn->src should reflect the local identity address */
 		hci_copy_identity_address(hdev, &conn->src, &conn->src_type);
 
@@ -1033,7 +1035,6 @@ static struct hci_conn *__hci_conn_add(struct hci_dev *hdev, int type, bdaddr_t
 	}
 
 	hci_conn_init_sysfs(conn);
-
 	return conn;
 }
 
@@ -1077,6 +1078,7 @@ static void hci_conn_cleanup_child(struct hci_conn *conn, u8 reason)
 		break;
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 		if ((conn->state != BT_CONNECTED &&
 		    !test_bit(HCI_CONN_CREATE_CIS, &conn->flags)) ||
 		    test_bit(HCI_CONN_BIG_CREATED, &conn->flags))
@@ -1152,7 +1154,8 @@ void hci_conn_del(struct hci_conn *conn)
 	} else {
 		/* Unacked ISO frames */
 		if (conn->type == CIS_LINK ||
-		    conn->type == BIS_LINK) {
+		    conn->type == BIS_LINK ||
+		    conn->type == PA_LINK) {
 			if (hdev->iso_pkts)
 				hdev->iso_cnt += conn->sent;
 			else if (hdev->le_pkts)
@@ -2081,7 +2084,7 @@ struct hci_conn *hci_pa_create_sync(struct hci_dev *hdev, bdaddr_t *dst,
 
 	bt_dev_dbg(hdev, "dst %pMR type %d sid %d", dst, dst_type, sid);
 
-	conn = hci_conn_add_unset(hdev, BIS_LINK, dst, HCI_ROLE_SLAVE);
+	conn = hci_conn_add_unset(hdev, PA_LINK, dst, HCI_ROLE_SLAVE);
 	if (IS_ERR(conn))
 		return conn;
 
@@ -2246,7 +2249,7 @@ struct hci_conn *hci_connect_bis(struct hci_dev *hdev, bdaddr_t *dst,
 	 * the start periodic advertising and create BIG commands have
 	 * been queued
 	 */
-	hci_conn_hash_list_state(hdev, bis_mark_per_adv, BIS_LINK,
+	hci_conn_hash_list_state(hdev, bis_mark_per_adv, PA_LINK,
 				 BT_BOUND, &data);
 
 	/* Queue start periodic advertising and create BIG */
@@ -2980,6 +2983,7 @@ void hci_conn_tx_queue(struct hci_conn *conn, struct sk_buff *skb)
 	switch (conn->type) {
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 	case ACL_LINK:
 	case LE_LINK:
 		break;
diff --git a/net/bluetooth/hci_core.c b/net/bluetooth/hci_core.c
index 42f597cb0941..d1c7becb0953 100644
--- a/net/bluetooth/hci_core.c
+++ b/net/bluetooth/hci_core.c
@@ -2936,12 +2936,14 @@ int hci_recv_frame(struct hci_dev *hdev, struct sk_buff *skb)
 	case HCI_ACLDATA_PKT:
 		/* Detect if ISO packet has been sent as ACL */
 		if (hci_conn_num(hdev, CIS_LINK) ||
-		    hci_conn_num(hdev, BIS_LINK)) {
+		    hci_conn_num(hdev, BIS_LINK) ||
+			hci_conn_num(hdev, PA_LINK)) {
 			__u16 handle = __le16_to_cpu(hci_acl_hdr(skb)->handle);
 			__u8 type;
 
 			type = hci_conn_lookup_type(hdev, hci_handle(handle));
-			if (type == CIS_LINK || type == BIS_LINK)
+			if (type == CIS_LINK || type == BIS_LINK ||
+			    type == PA_LINK)
 				hci_skb_pkt_type(skb) = HCI_ISODATA_PKT;
 		}
 		break;
@@ -3396,6 +3398,7 @@ static inline void hci_quote_sent(struct hci_conn *conn, int num, int *quote)
 		break;
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 		cnt = hdev->iso_mtu ? hdev->iso_cnt :
 			hdev->le_mtu ? hdev->le_cnt : hdev->acl_cnt;
 		break;
@@ -3409,7 +3412,7 @@ static inline void hci_quote_sent(struct hci_conn *conn, int num, int *quote)
 }
 
 static struct hci_conn *hci_low_sent(struct hci_dev *hdev, __u8 type,
-				     __u8 type2, int *quote)
+				     int *quote)
 {
 	struct hci_conn_hash *h = &hdev->conn_hash;
 	struct hci_conn *conn = NULL, *c;
@@ -3421,7 +3424,7 @@ static struct hci_conn *hci_low_sent(struct hci_dev *hdev, __u8 type,
 	rcu_read_lock();
 
 	list_for_each_entry_rcu(c, &h->list, list) {
-		if ((c->type != type && c->type != type2) ||
+		if (c->type != type ||
 		    skb_queue_empty(&c->data_q))
 			continue;
 
@@ -3625,7 +3628,7 @@ static void hci_sched_sco(struct hci_dev *hdev, __u8 type)
 	else
 		cnt = &hdev->sco_cnt;
 
-	while (*cnt && (conn = hci_low_sent(hdev, type, type, &quote))) {
+	while (*cnt && (conn = hci_low_sent(hdev, type, &quote))) {
 		while (quote-- && (skb = skb_dequeue(&conn->data_q))) {
 			BT_DBG("skb %p len %d", skb, skb->len);
 			hci_send_conn_frame(hdev, conn, skb);
@@ -3744,8 +3747,8 @@ static void hci_sched_le(struct hci_dev *hdev)
 		hci_prio_recalculate(hdev, LE_LINK);
 }
 
-/* Schedule CIS */
-static void hci_sched_iso(struct hci_dev *hdev)
+/* Schedule iso */
+static void hci_sched_iso(struct hci_dev *hdev, __u8 type)
 {
 	struct hci_conn *conn;
 	struct sk_buff *skb;
@@ -3753,14 +3756,12 @@ static void hci_sched_iso(struct hci_dev *hdev)
 
 	BT_DBG("%s", hdev->name);
 
-	if (!hci_conn_num(hdev, CIS_LINK) &&
-	    !hci_conn_num(hdev, BIS_LINK))
+	if (!hci_conn_num(hdev, type))
 		return;
 
 	cnt = hdev->iso_pkts ? &hdev->iso_cnt :
 		hdev->le_pkts ? &hdev->le_cnt : &hdev->acl_cnt;
-	while (*cnt && (conn = hci_low_sent(hdev, CIS_LINK, BIS_LINK,
-					    &quote))) {
+	while (*cnt && (conn = hci_low_sent(hdev, type, &quote))) {
 		while (quote-- && (skb = skb_dequeue(&conn->data_q))) {
 			BT_DBG("skb %p len %d", skb, skb->len);
 			hci_send_conn_frame(hdev, conn, skb);
@@ -3785,7 +3786,9 @@ static void hci_tx_work(struct work_struct *work)
 		/* Schedule queues and send stuff to HCI driver */
 		hci_sched_sco(hdev, SCO_LINK);
 		hci_sched_sco(hdev, ESCO_LINK);
-		hci_sched_iso(hdev);
+		hci_sched_iso(hdev, CIS_LINK);
+		hci_sched_iso(hdev, BIS_LINK);
+		hci_sched_iso(hdev, PA_LINK);
 		hci_sched_acl(hdev);
 		hci_sched_le(hdev);
 	}
diff --git a/net/bluetooth/hci_event.c b/net/bluetooth/hci_event.c
index 2c14e9daa199..d1e77dfe9edf 100644
--- a/net/bluetooth/hci_event.c
+++ b/net/bluetooth/hci_event.c
@@ -4433,6 +4433,7 @@ static void hci_num_comp_pkts_evt(struct hci_dev *hdev, void *data,
 
 		case CIS_LINK:
 		case BIS_LINK:
+		case PA_LINK:
 			if (hdev->iso_pkts) {
 				hdev->iso_cnt += count;
 				if (hdev->iso_cnt > hdev->iso_pkts)
@@ -6378,7 +6379,7 @@ static void hci_le_pa_sync_established_evt(struct hci_dev *hdev, void *data,
 	conn->sync_handle = le16_to_cpu(ev->handle);
 	conn->sid = HCI_SID_INVALID;
 
-	mask |= hci_proto_connect_ind(hdev, &ev->bdaddr, BIS_LINK,
+	mask |= hci_proto_connect_ind(hdev, &ev->bdaddr, PA_LINK,
 				      &flags);
 	if (!(mask & HCI_LM_ACCEPT)) {
 		hci_le_pa_term_sync(hdev, ev->handle);
@@ -6389,7 +6390,7 @@ static void hci_le_pa_sync_established_evt(struct hci_dev *hdev, void *data,
 		goto unlock;
 
 	/* Add connection to indicate PA sync event */
-	pa_sync = hci_conn_add_unset(hdev, BIS_LINK, BDADDR_ANY,
+	pa_sync = hci_conn_add_unset(hdev, PA_LINK, BDADDR_ANY,
 				     HCI_ROLE_SLAVE);
 
 	if (IS_ERR(pa_sync))
@@ -6420,7 +6421,7 @@ static void hci_le_per_adv_report_evt(struct hci_dev *hdev, void *data,
 
 	hci_dev_lock(hdev);
 
-	mask |= hci_proto_connect_ind(hdev, BDADDR_ANY, BIS_LINK, &flags);
+	mask |= hci_proto_connect_ind(hdev, BDADDR_ANY, PA_LINK, &flags);
 	if (!(mask & HCI_LM_ACCEPT))
 		goto unlock;
 
diff --git a/net/bluetooth/hci_sync.c b/net/bluetooth/hci_sync.c
index 4ea172a26ccc..d9bb543063fa 100644
--- a/net/bluetooth/hci_sync.c
+++ b/net/bluetooth/hci_sync.c
@@ -2929,7 +2929,7 @@ static int hci_le_set_ext_scan_param_sync(struct hci_dev *hdev, u8 type,
 		if (sent) {
 			struct hci_conn *conn;
 
-			conn = hci_conn_hash_lookup_ba(hdev, BIS_LINK,
+			conn = hci_conn_hash_lookup_ba(hdev, PA_LINK,
 						       &sent->bdaddr);
 			if (conn) {
 				struct bt_iso_qos *qos = &conn->iso_qos;
@@ -5493,7 +5493,7 @@ static int hci_disconnect_sync(struct hci_dev *hdev, struct hci_conn *conn,
 {
 	struct hci_cp_disconnect cp;
 
-	if (conn->type == BIS_LINK) {
+	if (conn->type == BIS_LINK || conn->type == PA_LINK) {
 		/* This is a BIS connection, hci_conn_del will
 		 * do the necessary cleanup.
 		 */
@@ -5562,7 +5562,7 @@ static int hci_connect_cancel_sync(struct hci_dev *hdev, struct hci_conn *conn,
 		return HCI_ERROR_LOCAL_HOST_TERM;
 	}
 
-	if (conn->type == BIS_LINK) {
+	if (conn->type == BIS_LINK || conn->type == PA_LINK) {
 		/* There is no way to cancel a BIS without terminating the BIG
 		 * which is done later on connection cleanup.
 		 */
@@ -5627,7 +5627,7 @@ static int hci_reject_conn_sync(struct hci_dev *hdev, struct hci_conn *conn,
 	if (conn->type == CIS_LINK)
 		return hci_le_reject_cis_sync(hdev, conn, reason);
 
-	if (conn->type == BIS_LINK)
+	if (conn->type == BIS_LINK || conn->type == PA_LINK)
 		return -EINVAL;
 
 	if (conn->type == SCO_LINK || conn->type == ESCO_LINK)
@@ -6995,7 +6995,7 @@ static void create_pa_complete(struct hci_dev *hdev, void *data, int err)
 		goto unlock;
 
 	/* Add connection to indicate PA sync error */
-	pa_sync = hci_conn_add_unset(hdev, BIS_LINK, BDADDR_ANY,
+	pa_sync = hci_conn_add_unset(hdev, PA_LINK, BDADDR_ANY,
 				     HCI_ROLE_SLAVE);
 
 	if (IS_ERR(pa_sync))
diff --git a/net/bluetooth/iso.c b/net/bluetooth/iso.c
index fc22782cbeeb..dff99de98042 100644
--- a/net/bluetooth/iso.c
+++ b/net/bluetooth/iso.c
@@ -2226,7 +2226,8 @@ int iso_connect_ind(struct hci_dev *hdev, bdaddr_t *bdaddr, __u8 *flags)
 
 static void iso_connect_cfm(struct hci_conn *hcon, __u8 status)
 {
-	if (hcon->type != CIS_LINK && hcon->type != BIS_LINK) {
+	if (hcon->type != CIS_LINK && hcon->type != BIS_LINK &&
+	    hcon->type != PA_LINK) {
 		if (hcon->type != LE_LINK)
 			return;
 
@@ -2267,7 +2268,8 @@ static void iso_connect_cfm(struct hci_conn *hcon, __u8 status)
 
 static void iso_disconn_cfm(struct hci_conn *hcon, __u8 reason)
 {
-	if (hcon->type != CIS_LINK && hcon->type != BIS_LINK)
+	if (hcon->type != CIS_LINK && hcon->type !=  BIS_LINK &&
+	    hcon->type != PA_LINK)
 		return;
 
 	BT_DBG("hcon %p reason %d", hcon, reason);
diff --git a/net/bluetooth/mgmt.c b/net/bluetooth/mgmt.c
index 1485b455ade4..f90c53f7885b 100644
--- a/net/bluetooth/mgmt.c
+++ b/net/bluetooth/mgmt.c
@@ -3239,6 +3239,7 @@ static u8 link_to_bdaddr(u8 link_type, u8 addr_type)
 	switch (link_type) {
 	case CIS_LINK:
 	case BIS_LINK:
+	case PA_LINK:
 	case LE_LINK:
 		switch (addr_type) {
 		case ADDR_LE_DEV_PUBLIC:

---
base-commit: 98b3f8ecdd57baff41dceccf4cba5edff3b9c010
change-id: 20250710-pa_link-94e292e2768e

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

