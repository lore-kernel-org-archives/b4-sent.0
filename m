From: Yang Li <yang.li@amlogic.com>
Date: Wed, 02 Jul 2025 19:35:48 +0800
Subject: [PATCH v2] Bluetooth: ISO: Support SOCK_RCVTSTAMP via CMSG for ISO
 sockets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250702-iso_ts-v2-1-723d199c8068@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAJMZZWgC/zXMywrCMBCF4VcpszaSpBdjV76HFInptB2wjWRKU
 Ere3Vjo8j8cvg0YAyFDW2wQMBKTX3LoUwFussuIgvrcoKWuZaWVIPaPlYUz2pZSWryYCvL5HXC
 gzw7du9wT8erDd3ej+q8HcT2IqIQSWJtmKGWPjXve7PzyI7mz8zN0KaUfJqRCPZ4AAAA=
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751456149; l=982;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=KHMGQKsMq1ealL3OXyoBth/L4LOJjuWSriffKLAfOLM=;
 b=/XSCa4bHVCWY+eq/QxDxP2198DpIAxIIYl+i0/OLzyiR//vXWJO4ymOsMxYq+VWerTZC7XiS5
 fr079bqjNMVCLDw9rVIMzKlGfuxrsKYSwq4LMm4pJjo7jybc0sEvAE+
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

User-space applications (e.g., PipeWire) depend on
ISO-formatted timestamps for precise audio sync.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v2:
- Support SOCK_RCVTSTAMPNS via CMSG for ISO sockets
- Link to v1: https://lore.kernel.org/r/20250429-iso_ts-v1-1-e586f30de6cb@amlogic.com
---
 net/bluetooth/iso.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/net/bluetooth/iso.c b/net/bluetooth/iso.c
index fc22782cbeeb..6927c593a1d6 100644
--- a/net/bluetooth/iso.c
+++ b/net/bluetooth/iso.c
@@ -2308,6 +2308,9 @@ void iso_recv(struct hci_conn *hcon, struct sk_buff *skb, u16 flags)
 				goto drop;
 			}
 
+			/* Record the timestamp to skb*/
+			skb->skb_mstamp_ns = le32_to_cpu(hdr->ts);
+
 			len = __le16_to_cpu(hdr->slen);
 		} else {
 			struct hci_iso_data_hdr *hdr;

---
base-commit: 3bc46213b81278f3a9df0324768e152de71eb9fe
change-id: 20250421-iso_ts-c82a300ae784

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

