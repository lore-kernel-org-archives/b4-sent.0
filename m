From: Yang Li <yang.li@amlogic.com>
Date: Wed, 02 Jul 2025 09:18:42 +0800
Subject: [PATCH] Bluetooth: hci_core: lookup pa sync need check BIG sync
 state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250702-pa_sync-v1-1-7a96f5c2d012@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAPGIZGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwND3YLE+OLKvGRdo7Rk87RkyzRTS6NkJaDqgqLUtMwKsEnRsbW1AGv
 pFS1ZAAAA
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751419122; l=1160;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=GHF9U6GehkWVyzq0OzaU+JceT54aR44ovVM4Bx+2rpk=;
 b=eXovFOziL0YnMbRRQ5YVkV12C93VSCnu6TecapyGQ2OjfXYA8mgRc/OPiy0TVXdTOs0FztD/E
 qjG/4wvabekCKCj+qnJaf73QtkMQbVoB6oNjkiZn2XkfU256Ep1Eq37
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ignore the big sync connections, we are looking for the PA
sync connection that was created as a result of the PA sync
established event.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 include/net/bluetooth/hci_core.h | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/include/net/bluetooth/hci_core.h b/include/net/bluetooth/hci_core.h
index 3ce1fb6f5822..646b0c5fd7a5 100644
--- a/include/net/bluetooth/hci_core.h
+++ b/include/net/bluetooth/hci_core.h
@@ -1400,6 +1400,13 @@ hci_conn_hash_lookup_pa_sync_handle(struct hci_dev *hdev, __u16 sync_handle)
 		if (c->type != BIS_LINK)
 			continue;
 
+		/* Ignore the big sync connections, we are looking
+		 * for the PA sync connection that was created as
+		 * a result of the PA sync established event.
+		 */
+		if (test_bit(HCI_CONN_BIG_SYNC, &c->flags))
+			continue;
+
 		/* Ignore the listen hcon, we are looking
 		 * for the child hcon that was created as
 		 * a result of the PA sync established event.

---
base-commit: 3bc46213b81278f3a9df0324768e152de71eb9fe
change-id: 20250701-pa_sync-2fc7fc9f592c

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

