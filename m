From: Yang Li <yang.li@amlogic.com>
Date: Mon, 27 Oct 2025 14:10:02 +0800
Subject: [PATCH v4] Bluetooth: iso: fix socket matching ambiguity between
 BIS and CIS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251027-bis_cis_coexist-v4-1-81c4e890fa6d@amlogic.com>
X-B4-Tracking: v=1; b=H4sIALkM/2gC/3XOyw6CMBAF0F8xXTumD2rFlf9hiCl9wCRCTUsaD
 OHfLWyMCxezuIs59y4kuYgukethIdFlTBjGEqrjgZhej50DtCUTTrmkSjBoMT3MdsHNmCZQTOm
 q4laaipPy9YrO47yL96ZkH8MAUx+d/jqS1oApQObAwGopWssuhtXipodn6NCcTBg2rC8NIb73d
 Vls5P8hWRSM+bq1Z+q8YvwHa9Z1/QAWhjGH7QAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761545415; l=2169;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=P7v3HOIQyUuNYvPT/4u/6kC7UJH3I86TvRUHKxEURak=;
 b=2eH6P+2UC+a61nkUhEGrcM/JDCJpYPDeuW9w1KPe4+iDMakQn3d/PMwjsPd/0f7QE90F8ZNPO
 1zg9zdUDP6KB1yX0jd1GRZnxnSwNRmQ3VCTndaFnH/0zDWPs4gjDEvJ
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When both BIS and CIS links exist, their sockets are in
the BT_LISTEN state.
dump sock:
  sk 000000001977ef51 state 6
  src 10:a5:62:31:05:cf dst 00:00:00:00:00:00
  sk 0000000031d28700 state 7
  src 10:a5:62:31:05:cf dst00:00:00:00:00:00
  sk 00000000613af00e state 4   # listen sock of bis
  src 10:a5:62:31:05:cf dst 54:00:00:d4:99:30
  sk 000000001710468c state 9
  src 10:a5:62:31:05:cf dst 54:00:00:d4:99:30
  sk 000000005d97dfde state 4   #listen sock of cis
  src 10:a5:62:31:05:cf dst 00:00:00:00:00:00

To locate the CIS socket correctly, check both the BT_LISTEN
state and whether dst addr is BDADDR_ANY.

Link: https://github.com/bluez/bluez/issues/1224

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v4:
- Rebase code.
- Link to v3: https://lore.kernel.org/r/20250731-bis_cis_coexist-v3-1-1f9bd60ef712@amlogic.com
---
 net/bluetooth/iso.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/net/bluetooth/iso.c b/net/bluetooth/iso.c
index aa63c8955a53..74ec7d125c88 100644
--- a/net/bluetooth/iso.c
+++ b/net/bluetooth/iso.c
@@ -2021,6 +2021,11 @@ static bool iso_match_pa_sync_flag(struct sock *sk, void *data)
 	return test_bit(BT_SK_PA_SYNC, &iso_pi(sk)->flags);
 }
 
+static bool iso_match_dst(struct sock *sk, void *data)
+{
+	return !bacmp(&iso_pi(sk)->dst, (bdaddr_t *)data);
+}
+
 static void iso_conn_ready(struct iso_conn *conn)
 {
 	struct sock *parent = NULL;
@@ -2105,7 +2110,7 @@ static void iso_conn_ready(struct iso_conn *conn)
 
 		if (!parent)
 			parent = iso_get_sock(hdev, &hcon->src, BDADDR_ANY,
-					      BT_LISTEN, NULL, NULL);
+					      BT_LISTEN, iso_match_dst, BDADDR_ANY);
 
 		if (!parent)
 			return;
@@ -2374,7 +2379,7 @@ int iso_connect_ind(struct hci_dev *hdev, bdaddr_t *bdaddr, __u8 *flags)
 		}
 	} else {
 		sk = iso_get_sock(hdev, &hdev->bdaddr, BDADDR_ANY,
-				  BT_LISTEN, NULL, NULL);
+				  BT_LISTEN, iso_match_dst, BDADDR_ANY);
 	}
 
 done:

---
base-commit: f63037a3f252522504774c98960282fb776ef3ca
change-id: 20250731-bis_cis_coexist-717a442d5c42

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

