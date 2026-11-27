From: Murad Dadashev <llamapersonaltv@gmail.com>
Date: Fri, 27 Nov 2026 11:35:14 +0300
Subject: [PATCH 03/10] wifi: mt76: mt7603: set beacon and CAB queue index
 in the TXD directly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-mt7603u-v1-3-369bee9846f8@gmail.com>
References: <20261127-mt7603u-v1-0-369bee9846f8@gmail.com>
In-Reply-To: <20261127-mt7603u-v1-0-369bee9846f8@gmail.com>
To: Felix Fietkau <nbd@nbd.name>, Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>, Shayne Chen <shayne.chen@mediatek.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Murad Dadashev <llamapersonaltv@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795768526; l=2103;
 i=llamapersonaltv@gmail.com; s=20261127; h=from:subject:message-id;
 bh=1xCPoMQGae2Iwtm6u84oOfPkwqg+d/7HUejZdUysg1c=;
 b=yI671h+opbGqW13jJxa79LBJalQPoozFQcqNMDJW21JZTFumsn22W3KWMU5tzRkyVh9uOpAIk
 ekcSZmlwS4HBc37dHclxdalvnFa0ASxCp7fu9+SqMiQGHd3SNkIWoau
X-Developer-Key: i=llamapersonaltv@gmail.com; a=ed25519;
 pk=CeMIX207ioWRbMAA6A2GYgT+DpeVlKHVn7I0KjfHeCg=
X-Endpoint-Received: by B4 Relay for llamapersonaltv@gmail.com/20261127 with auth_id=1664
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt7603_mac_write_txwi() looks up the TX queue to get the hardware queue
index for the TXD. Beacon and CAB frames always go to the BCN and BMC
hardware queues, so use those indices directly for MT_TXQ_BEACON and
MT_TXQ_CAB.

This lets a bus without dedicated beacon and CAB rings queue those
frames on another ring while still targeting the right hardware queue.

No functional change for MT7603E and MT76x8.

Signed-off-by: Murad Dadashev <llamapersonaltv@gmail.com>
---
 drivers/net/wireless/mediatek/mt76/mt7603/mac.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mac.c b/drivers/net/wireless/mediatek/mt76/mt7603/mac.c
index fa0bf9a201ce2d43b48981aab75b70ff21ff5c51..fb5e06d04e5a943a4536676fdf7676e6789db6df 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mac.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mac.c
@@ -949,8 +949,8 @@ mt7603_mac_write_txwi(struct mt7603_dev *dev, __le32 *txwi,
 	struct ieee80211_hdr *hdr = (struct ieee80211_hdr *)skb->data;
 	struct ieee80211_bar *bar = (struct ieee80211_bar *)skb->data;
 	struct ieee80211_vif *vif = info->control.vif;
-	struct mt76_queue *q = dev->mphy.q_tx[qid];
 	struct mt7603_vif *mvif;
+	u8 q_idx;
 	int wlan_idx;
 	int hdr_len = ieee80211_get_hdrlen_from_skb(skb);
 	int tx_count = 8;
@@ -961,6 +961,13 @@ mt7603_mac_write_txwi(struct mt7603_dev *dev, __le32 *txwi,
 	u32 val;
 	u8 bw;
 
+	if (qid == MT_TXQ_BEACON)
+		q_idx = MT_TX_HW_QUEUE_BCN;
+	else if (qid == MT_TXQ_CAB)
+		q_idx = MT_TX_HW_QUEUE_BMC;
+	else
+		q_idx = dev->mphy.q_tx[qid]->hw_idx;
+
 	if (vif) {
 		mvif = (struct mt7603_vif *)vif->drv_priv;
 		vif_idx = mvif->idx;
@@ -983,7 +990,7 @@ mt7603_mac_write_txwi(struct mt7603_dev *dev, __le32 *txwi,
 	frame_subtype = (fc & IEEE80211_FCTL_STYPE) >> 4;
 
 	val = FIELD_PREP(MT_TXD0_TX_BYTES, skb->len + MT_TXD_SIZE) |
-	      FIELD_PREP(MT_TXD0_Q_IDX, q->hw_idx);
+	      FIELD_PREP(MT_TXD0_Q_IDX, q_idx);
 	txwi[0] = cpu_to_le32(val);
 
 	val = MT_TXD1_LONG_FORMAT |

-- 
2.47.3

