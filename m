From: Yang Li <yang.li@amlogic.com>
Date: Fri, 04 Jul 2025 13:36:04 +0800
Subject: [PATCH v3] Bluetooth: ISO: Support SCM_TIMESTAMPING for ISO TS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250704-iso_ts-v3-1-2328bc602961@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAENoZ2gC/1WMWwrCMBQFt1LybSS56SP1y32ISExv2wu2kaQEp
 XTvpoUqfs7hzMwsoCcM7JTNzGOkQG5MoA4Zs70ZO+TUJGYgoBA5SE7B3abArQajhDBY6Zyl89N
 jS68tdLkm7ilMzr+3bpTruifqPREllxwLXbZKNFja+9kMD9eRPVo3sDUS4SdWAr4iJLEC1ci6t
 lqU+l9cluUDtrm4ztcAAAA=
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751607364; l=1653;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=C5WSe4xpxMywiJVuo177OZ9NkV8vydxLCuzzPLrDJ70=;
 b=BPvz/HGiu+RRd/d7DdT0qoLzNUl91lP8saypFLqpEV6DymwgKZT1fwShR0X0vedw8VkPV0hbt
 AsNh/CPpqm9BRqPmei3UxNyNxB7NtYKTfAimIss2qLjyLM4t+n2AXpV
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

User-space applications (e.g., PipeWire) depend on
ISO-formatted timestamps for precise audio sync.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v3:
- Change to use hwtimestamp
- Link to v2: https://lore.kernel.org/r/20250702-iso_ts-v2-1-723d199c8068@amlogic.com

Changes in v2:
- Support SOCK_RCVTSTAMPNS via CMSG for ISO sockets
- Link to v1: https://lore.kernel.org/r/20250429-iso_ts-v1-1-e586f30de6cb@amlogic.com
---
 net/bluetooth/iso.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/net/bluetooth/iso.c b/net/bluetooth/iso.c
index fc22782cbeeb..67ff355167d8 100644
--- a/net/bluetooth/iso.c
+++ b/net/bluetooth/iso.c
@@ -2301,13 +2301,21 @@ void iso_recv(struct hci_conn *hcon, struct sk_buff *skb, u16 flags)
 		if (ts) {
 			struct hci_iso_ts_data_hdr *hdr;
 
-			/* TODO: add timestamp to the packet? */
 			hdr = skb_pull_data(skb, HCI_ISO_TS_DATA_HDR_SIZE);
 			if (!hdr) {
 				BT_ERR("Frame is too short (len %d)", skb->len);
 				goto drop;
 			}
 
+			/* The ISO ts is based on the controller’s clock domain,
+			 * so hardware timestamping (hwtimestamp) must be used.
+			 * Ref: Documentation/networking/timestamping.rst,
+			 * chapter 3.1 Hardware Timestamping.
+ 			 */
+			struct skb_shared_hwtstamps *hwts = skb_hwtstamps(skb);
+			if (hwts)
+				hwts->hwtstamp = us_to_ktime(le32_to_cpu(hdr->ts));
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

