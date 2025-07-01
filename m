From: Yang Li <yang.li@amlogic.com>
Date: Tue, 01 Jul 2025 16:47:26 +0800
Subject: [PATCH] Bluetooth: Fix spelling mistakes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250701-fix_typos-v1-1-090f06fdfaea@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAJ2gY2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwND3bTMiviSyoL8Yl1LC2Mj00QTEzPzRFMloPqColSgJNis6NjaWgB
 oh1BFWwAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751359647; l=5289;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=VQIDv2I4hUGURzA15ufBv8DnkunpA/1+l0Qi7aaRxGw=;
 b=/K6FSfTrL0eD/O5Jjt0xg/7Swn27fMtrIeOCy5Inv13sPcG45X3L7zuicjdW2I/wiJWvn8PYd
 yPoJ3lrSEQQDlkYO6gTY1L1n6KBRq+F7T5KD5sarBJUatMilfRSdBwr
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Correct the misspelling of “estabilished” in the code.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 include/net/bluetooth/hci.h |  2 +-
 net/bluetooth/hci_event.c   | 12 ++++++------
 net/bluetooth/iso.c         |  8 ++++----
 3 files changed, 11 insertions(+), 11 deletions(-)

diff --git a/include/net/bluetooth/hci.h b/include/net/bluetooth/hci.h
index fe932ca3bc8c..887db7b4edd9 100644
--- a/include/net/bluetooth/hci.h
+++ b/include/net/bluetooth/hci.h
@@ -2767,7 +2767,7 @@ struct hci_evt_le_create_big_complete {
 } __packed;
 
 #define HCI_EVT_LE_BIG_SYNC_ESTABILISHED 0x1d
-struct hci_evt_le_big_sync_estabilished {
+struct hci_evt_le_big_sync_established {
 	__u8    status;
 	__u8    handle;
 	__u8    latency[3];
diff --git a/net/bluetooth/hci_event.c b/net/bluetooth/hci_event.c
index a487f9df8145..3f939a3cdb86 100644
--- a/net/bluetooth/hci_event.c
+++ b/net/bluetooth/hci_event.c
@@ -6335,7 +6335,7 @@ static int hci_le_pa_term_sync(struct hci_dev *hdev, __le16 handle)
 	return hci_send_cmd(hdev, HCI_OP_LE_PA_TERM_SYNC, sizeof(cp), &cp);
 }
 
-static void hci_le_pa_sync_estabilished_evt(struct hci_dev *hdev, void *data,
+static void hci_le_pa_sync_established_evt(struct hci_dev *hdev, void *data,
 					    struct sk_buff *skb)
 {
 	struct hci_ev_le_pa_sync_established *ev = data;
@@ -6652,7 +6652,7 @@ static void hci_le_phy_update_evt(struct hci_dev *hdev, void *data,
 	hci_dev_unlock(hdev);
 }
 
-static void hci_le_cis_estabilished_evt(struct hci_dev *hdev, void *data,
+static void hci_le_cis_established_evt(struct hci_dev *hdev, void *data,
 					struct sk_buff *skb)
 {
 	struct hci_evt_le_cis_established *ev = data;
@@ -6875,7 +6875,7 @@ static void hci_le_create_big_complete_evt(struct hci_dev *hdev, void *data,
 static void hci_le_big_sync_established_evt(struct hci_dev *hdev, void *data,
 					    struct sk_buff *skb)
 {
-	struct hci_evt_le_big_sync_estabilished *ev = data;
+	struct hci_evt_le_big_sync_established *ev = data;
 	struct hci_conn *bis;
 	int i;
 
@@ -7030,7 +7030,7 @@ static const struct hci_le_ev {
 		     HCI_MAX_EVENT_SIZE),
 	/* [0x0e = HCI_EV_LE_PA_SYNC_ESTABLISHED] */
 	HCI_LE_EV(HCI_EV_LE_PA_SYNC_ESTABLISHED,
-		  hci_le_pa_sync_estabilished_evt,
+		  hci_le_pa_sync_established_evt,
 		  sizeof(struct hci_ev_le_pa_sync_established)),
 	/* [0x0f = HCI_EV_LE_PER_ADV_REPORT] */
 	HCI_LE_EV_VL(HCI_EV_LE_PER_ADV_REPORT,
@@ -7041,7 +7041,7 @@ static const struct hci_le_ev {
 	HCI_LE_EV(HCI_EV_LE_EXT_ADV_SET_TERM, hci_le_ext_adv_term_evt,
 		  sizeof(struct hci_evt_le_ext_adv_set_term)),
 	/* [0x19 = HCI_EVT_LE_CIS_ESTABLISHED] */
-	HCI_LE_EV(HCI_EVT_LE_CIS_ESTABLISHED, hci_le_cis_estabilished_evt,
+	HCI_LE_EV(HCI_EVT_LE_CIS_ESTABLISHED, hci_le_cis_established_evt,
 		  sizeof(struct hci_evt_le_cis_established)),
 	/* [0x1a = HCI_EVT_LE_CIS_REQ] */
 	HCI_LE_EV(HCI_EVT_LE_CIS_REQ, hci_le_cis_req_evt,
@@ -7054,7 +7054,7 @@ static const struct hci_le_ev {
 	/* [0x1d = HCI_EV_LE_BIG_SYNC_ESTABILISHED] */
 	HCI_LE_EV_VL(HCI_EVT_LE_BIG_SYNC_ESTABILISHED,
 		     hci_le_big_sync_established_evt,
-		     sizeof(struct hci_evt_le_big_sync_estabilished),
+		     sizeof(struct hci_evt_le_big_sync_established),
 		     HCI_MAX_EVENT_SIZE),
 	/* [0x22 = HCI_EVT_LE_BIG_INFO_ADV_REPORT] */
 	HCI_LE_EV_VL(HCI_EVT_LE_BIG_INFO_ADV_REPORT,
diff --git a/net/bluetooth/iso.c b/net/bluetooth/iso.c
index cc055b952ce6..706a47357363 100644
--- a/net/bluetooth/iso.c
+++ b/net/bluetooth/iso.c
@@ -1728,7 +1728,7 @@ struct iso_list_data {
 
 static bool iso_match_big(struct sock *sk, void *data)
 {
-	struct hci_evt_le_big_sync_estabilished *ev = data;
+	struct hci_evt_le_big_sync_established *ev = data;
 
 	return ev->handle == iso_pi(sk)->qos.bcast.big;
 }
@@ -1742,7 +1742,7 @@ static void iso_conn_ready(struct iso_conn *conn)
 {
 	struct sock *parent = NULL;
 	struct sock *sk = conn->sk;
-	struct hci_ev_le_big_sync_estabilished *ev = NULL;
+	struct hci_ev_le_big_sync_established *ev = NULL;
 	struct hci_ev_le_pa_sync_established *ev2 = NULL;
 	struct hci_ev_le_per_adv_report *ev3 = NULL;
 	struct hci_conn *hcon;
@@ -1844,7 +1844,7 @@ static void iso_conn_ready(struct iso_conn *conn)
 		hci_conn_hold(hcon);
 		iso_chan_add(conn, sk, parent);
 
-		if ((ev && ((struct hci_evt_le_big_sync_estabilished *)ev)->status) ||
+		if ((ev && ((struct hci_evt_le_big_sync_established *)ev)->status) ||
 		    (ev2 && ev2->status)) {
 			/* Trigger error signal on child socket */
 			sk->sk_err = ECONNREFUSED;
@@ -1900,7 +1900,7 @@ int iso_connect_ind(struct hci_dev *hdev, bdaddr_t *bdaddr, __u8 *flags)
 	 * proceed to establishing a BIG sync:
 	 *
 	 * 1. HCI_EV_LE_PA_SYNC_ESTABLISHED: The socket may specify a specific
-	 * SID to listen to and once sync is estabilished its handle needs to
+	 * SID to listen to and once sync is established its handle needs to
 	 * be stored in iso_pi(sk)->sync_handle so it can be matched once
 	 * receiving the BIG Info.
 	 * 2. HCI_EVT_LE_BIG_INFO_ADV_REPORT: When connect_ind is triggered by a

---
base-commit: df8c0b8a03e871431587a13a6765cb4c601e1573
change-id: 20250701-fix_typos-98325a4467a5

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

