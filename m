From: Yang Li <yang.li@amlogic.com>
Date: Thu, 31 Jul 2025 15:59:48 +0800
Subject: [PATCH v3] Bluetooth: iso: fix socket matching ambiguity between
 BIS and CIS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250731-bis_cis_coexist-v3-1-1f9bd60ef712@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAHMii2gC/0XMywrCMBCF4Vcps3YkV2Jd+R4ikibTdsA2kpRSK
 H13oxsXZ/Etzr9DocxU4NrskGnlwmmu0KcGwujngZBjNSihrHBaYsflGb5LtHFZ0EnnjVHRBqO
 gvt6Zet5+xfujus9pwmXM5P8dK1rkknBVKDF6q7soL0G2+uanVxo4nEOa4Dg+siMdaZ4AAAA=
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753948799; l=2024;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=+Emn1CseXuQvh2qlK9A1nweKtqNCFRhwr83xHhi4y1I=;
 b=YjKHMd0TaKuzpNAD7T0TbF4kgTx5P7oXIlhOZ6UqkTzFLqUilmcEyvVlUHgc9kBxisD+wBqGe
 881mMK2N52RDLiB3litZzn+2cUo3+SEEakmVlJtyBFvHdMlWWWbkDwp
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
 net/bluetooth/iso.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/net/bluetooth/iso.c b/net/bluetooth/iso.c
index eaffd25570e3..9a4dea03af8c 100644
--- a/net/bluetooth/iso.c
+++ b/net/bluetooth/iso.c
@@ -1919,6 +1919,11 @@ static bool iso_match_pa_sync_flag(struct sock *sk, void *data)
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
@@ -1981,7 +1986,7 @@ static void iso_conn_ready(struct iso_conn *conn)
 
 		if (!parent)
 			parent = iso_get_sock(&hcon->src, BDADDR_ANY,
-					      BT_LISTEN, NULL, NULL);
+					      BT_LISTEN, iso_match_dst, BDADDR_ANY);
 
 		if (!parent)
 			return;
@@ -2220,7 +2225,7 @@ int iso_connect_ind(struct hci_dev *hdev, bdaddr_t *bdaddr, __u8 *flags)
 		}
 	} else {
 		sk = iso_get_sock(&hdev->bdaddr, BDADDR_ANY,
-				  BT_LISTEN, NULL, NULL);
+				  BT_LISTEN, iso_match_dst, BDADDR_ANY);
 	}
 
 done:

---
base-commit: 9c533991fe15be60ad9f9a7629c25dbc5b09788d
change-id: 20250731-bis_cis_coexist-717a442d5c42

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

