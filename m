From: Zhiwen Zhou <zhiwen_zhou@seu.edu.cn>
Date: Sun, 19 Jul 2026 06:38:47 +0800
Subject: [PATCH] wifi: mt76: mt7996: validate UNI PS sync events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-fix-mt7996-ps-sync-tlv-validation-v1-1-bdd933c8ef63@seu.edu.cn>
X-B4-Tracking: v=1; b=H4sIAHYAXGoC/yWNwQ6CMBBEf4Xs2Y0UI6T+iuGwLSusgUK6lWgI/
 27R45vMm9lAOQor3IoNIq+iMocM5lSAHyj0jNJlhqqs6rIxFh/yxik11ta4KOoneEzjiiuN0lH
 KNl6oLq2rzNUbhryzRM7S7+Pe/llf7sk+HcNHw5EyukjBD0c0R+klnCfSxBH2/QsxDa+fpQAAA
 A==
X-Change-ID: 20260719-fix-mt7996-ps-sync-tlv-validation-3a609b215c1e
To: nbd@nbd.name
Cc: shayne.chen@mediatek.com, sean.wang@mediatek.com, 
 ryder.lee@mediatek.com, lorenzo@kernel.org, linux-wireless@vger.kernel.org, 
 Zhiwen Zhou <zhiwen_zhou@seu.edu.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784414327; l=3108;
 i=zhiwen_zhou@seu.edu.cn; s=20260719; h=from:subject:message-id;
 bh=B+gXo4Kvc3MH12YtMgUtG/m54rI7NMXqZaUxOXppjtU=;
 b=d+BkoZvxmOP0EFDu8a/aGYO7Y5yimlAcmTsVwfPclCRN9LvLYbUoxVIKCMpglTCCRDaCoaaE3
 jEB62PM6JeOAD4UvY4QDdE92cxqlx/Nd/CXf+AGurB+MB4grw6+0/fo
X-Developer-Key: i=zhiwen_zhou@seu.edu.cn; a=ed25519;
 pk=bzQfqm5EAGagF+NGVHoDGrj4i+yti9b1zdTaUky68Qk=
X-Endpoint-Received: by B4 Relay for zhiwen_zhou@seu.edu.cn/20260719 with auth_id=882
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The firmware may send a PS sync event with a zero-length TLV or
trailing padding. The parser only checks whether the TLV length
exceeds the remaining data. A zero-length TLV therefore leaves both
the skb and remaining length unchanged and loops forever in the
threaded NAPI poller.

On affected MT7996 devices, this pins napi/phy0-0 in
mt7996_mcu_rx_event(), starves the RCU grace-period kthread and
eventually makes all radios unresponsive.

Validate the event header and every TLV before accessing it. Also
validate the variable-length multi-client array against the TLV
length. Drop malformed events with a rate-limited warning instead of
stalling the CPU.

Fixes: b0af99f238f7 ("wifi: mt76: mt7996: handle UNI PS sync events")
Signed-off-by: Zhiwen Zhou <zhiwen_zhou@seu.edu.cn>
---
 mt7996/mcu.c | 36 ++++++++++++++++++++++++++++++------
 1 file changed, 30 insertions(+), 6 deletions(-)

diff --git a/mt7996/mcu.c b/mt7996/mcu.c
index 1bd32c0..ee85b20 100644
--- a/mt7996/mcu.c
+++ b/mt7996/mcu.c
@@ -843,24 +843,33 @@ mt7996_mcu_rx_ps_sync(struct mt7996_dev *dev, struct sk_buff *skb)
 {
 	struct mt7996_mcu_ps_sync_event *event = (void *)skb->data;
 	struct tlv *tlv;
+	u16 tag = 0, tag_len = 0;
 	int len;
 
+	if (skb->len < sizeof(*event)) {
+		dev_warn_ratelimited(dev->mt76.dev,
+				     "short PS sync event: %u bytes\n",
+				     skb->len);
+		return;
+	}
+
 	skb_pull(skb, sizeof(*event));
 
 	len = skb->len;
-	while (len > sizeof(*tlv)) {
-		u16 tag, tag_len;
-
+	while (len >= sizeof(*tlv)) {
 		tlv = (struct tlv *)skb->data;
 		tag = le16_to_cpu(tlv->tag);
 		tag_len = le16_to_cpu(tlv->len);
-		if (tag_len > len)
-			break;
+		if (tag_len < sizeof(*tlv) || tag_len > len)
+			goto invalid;
 
 		switch (tag) {
 		case UNI_PS_CLIENT_INFO: {
 			struct mt7996_mcu_ps_client_info *info = (void *)tlv;
 
+			if (tag_len < sizeof(*info))
+				goto invalid;
+
 			mt7996_mcu_ps_transition(dev,
 						 le16_to_cpu(info->wlan_idx),
 						 info->ps_bit);
@@ -868,9 +877,17 @@ mt7996_mcu_rx_ps_sync(struct mt7996_dev *dev, struct sk_buff *skb)
 		}
 		case UNI_PS_MULTI_CLIENT_INFO: {
 			struct mt7996_mcu_ps_multi_client_info *info = (void *)tlv;
-			u16 cnt = le16_to_cpu(info->sta_cnt);
+			u16 cnt;
 			int i;
 
+			if (tag_len < sizeof(*info))
+				goto invalid;
+
+			cnt = le16_to_cpu(info->sta_cnt);
+			if (cnt > (tag_len - sizeof(*info)) /
+				  sizeof(info->sta_ps_info[0]))
+				goto invalid;
+
 			for (i = 0; i < cnt; i++) {
 				u16 entry = le16_to_cpu(info->sta_ps_info[i]);
 
@@ -895,6 +912,13 @@ mt7996_mcu_rx_ps_sync(struct mt7996_dev *dev, struct sk_buff *skb)
 		skb_pull(skb, tag_len);
 		len -= tag_len;
 	}
+
+	return;
+
+invalid:
+	dev_warn_ratelimited(dev->mt76.dev,
+			     "invalid PS sync TLV: tag=%u len=%u remaining=%d\n",
+			     tag, tag_len, len);
 }
 
 static void

---
base-commit: 59676919ea408b0b13a9d23f2e2e1a1ab407fba1
change-id: 20260719-fix-mt7996-ps-sync-tlv-validation-3a609b215c1e

Best regards,
--  
Zhiwen Zhou <zhiwen_zhou@seu.edu.cn>

