From: Murad Dadashev <llamapersonaltv@gmail.com>
Date: Fri, 27 Nov 2026 11:35:19 +0300
Subject: [PATCH 08/10] wifi: mt76: usb: add MT7603 queue mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-mt7603u-v1-8-369bee9846f8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795768526; l=1319;
 i=llamapersonaltv@gmail.com; s=20261127; h=from:subject:message-id;
 bh=5B3d4BCSyaO7bzzq/lINhmLDmquQjWLMFM3C15ts8zM=;
 b=Gau8whhKHdfBN/0NI+HmqoqDF/TluTxmq1bujturKXzB8PAWIFiwcqXQUQmuw/8tJN5qmDW2H
 fYxQcUIk8W0AkFludbk37pTarV/NMZ6UUgmfKp7xGZWHpuQ0AnRH+jP
X-Developer-Key: i=llamapersonaltv@gmail.com; a=ed25519;
 pk=CeMIX207ioWRbMAA6A2GYgT+DpeVlKHVn7I0KjfHeCg=
X-Endpoint-Received: by B4 Relay for llamapersonaltv@gmail.com/20261127 with auth_id=1664
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MT7603U uses hardware queues 0-3 for BK, BE, VI and VO, sent on the bulk
out endpoints following the inband command endpoint, and hardware queue
4 for management frames, sent on the inband command endpoint.

Signed-off-by: Murad Dadashev <llamapersonaltv@gmail.com>
---
 drivers/net/wireless/mediatek/mt76/usb.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/drivers/net/wireless/mediatek/mt76/usb.c b/drivers/net/wireless/mediatek/mt76/usb.c
index f6464315e3741c849f7a5ff13502abaae2150a37..317ef30a597caea21df4e88848f78191e9be4bb6 100644
--- a/drivers/net/wireless/mediatek/mt76/usb.c
+++ b/drivers/net/wireless/mediatek/mt76/usb.c
@@ -976,6 +976,23 @@ mt76u_ac_to_hwq(struct mt76_dev *dev, struct mt76_queue *q, u8 qid)
 	u8 ac = qid < IEEE80211_NUM_ACS ? qid : IEEE80211_AC_BE;
 
 	switch (mt76_chip(dev)) {
+	case 0x7603: {
+		static const u8 wmm_queue_map[] = {
+			[IEEE80211_AC_BK] = 0,
+			[IEEE80211_AC_BE] = 1,
+			[IEEE80211_AC_VI] = 2,
+			[IEEE80211_AC_VO] = 3,
+		};
+
+		if (qid == MT_TXQ_PSD) {
+			q->hw_idx = 4;
+			q->ep = MT_EP_OUT_INBAND_CMD;
+		} else {
+			q->hw_idx = wmm_queue_map[ac];
+			q->ep = q->hw_idx + 1;
+		}
+		break;
+	}
 	case 0x7663: {
 		static const u8 lmac_queue_map[] = {
 			/* ac to lmac mapping */

-- 
2.47.3

