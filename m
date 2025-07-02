From: Yang Li <yang.li@amlogic.com>
Date: Wed, 02 Jul 2025 11:12:12 +0800
Subject: [PATCH] Bluetooth: hci_event: Hold PA sync conn when BIG sync
 established
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250702-hold_pa_sync-v1-1-3cbdd2c29c41@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAIujZGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwMj3Yz8nJT4gsT44sq8ZF1Lw+RE80QLw8SUNAMloJaCotS0zAqwcdG
 xtbUAEHq1GF4AAAA=
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751425939; l=881;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=V8m462H5RbM/oJyz7gwSJlctSKUTcMZaUXIOO+asIqY=;
 b=riJZDjp3zgUR2fA0G+8xAl/LyGaVa3g9bI9F8QneD/Ww/NxnKDpw+LBf30rOisdEUp0vP+ZtP
 rdPSLdxZP/1CZR60+ROi7n4bxzniCxzLFsS7vO24Tbt9Z8qR53sXttI
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hold PA sync connection to prevent cleanup during hci_conn_timeout.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 net/bluetooth/hci_event.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/net/bluetooth/hci_event.c b/net/bluetooth/hci_event.c
index e817c4a77f97..85ae1608e028 100644
--- a/net/bluetooth/hci_event.c
+++ b/net/bluetooth/hci_event.c
@@ -6968,6 +6968,9 @@ static void hci_le_big_sync_established_evt(struct hci_dev *hdev, void *data,
 
 		if (!ev->status) {
 			conn->state = BT_CONNECTED;
+			/* Prevent cleanup in hci_conn_timeout. */
+			hci_conn_hold(conn);
+
 			set_bit(HCI_CONN_BIG_SYNC, &bis->flags);
 			hci_debugfs_create_conn(conn);
 			hci_conn_add_sysfs(conn);

---
base-commit: 3bc46213b81278f3a9df0324768e152de71eb9fe
change-id: 20250702-hold_pa_sync-91ca7a81adf0

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

