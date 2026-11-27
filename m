From: Murad Dadashev <llamapersonaltv@gmail.com>
Date: Fri, 27 Nov 2026 11:35:13 +0300
Subject: [PATCH 02/10] wifi: mt76: mt7603: make mcu message helpers usable
 by other buses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-mt7603u-v1-2-369bee9846f8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795768526; l=3594;
 i=llamapersonaltv@gmail.com; s=20261127; h=from:subject:message-id;
 bh=g4XUtnuymEQFvCt7ERD1/Ld0HSmrdfs2a5Zn8j72UIc=;
 b=7yGr8Rc1ykiw5mywD+Anw9WR0oSNt5gEclop42dkuG8NvN8OqjDkKfsLCic9jrFhIG4THeD/M
 BxV59VgExixBWtcXkOZ8a1WLfBNc0ohm+t8h+IgBfQXNHjD3++zhO4Z
X-Developer-Key: i=llamapersonaltv@gmail.com; a=ed25519;
 pk=CeMIX207ioWRbMAA6A2GYgT+DpeVlKHVn7I0KjfHeCg=
X-Endpoint-Received: by B4 Relay for llamapersonaltv@gmail.com/20261127 with auth_id=1664
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split filling in the MCU TXD out of mt7603_mcu_skb_send_msg() into
mt7603_mcu_fill_msg(), and make mt7603_mcu_parse_response() and
mt7603_load_firmware() non-static.

A USB driver needs to send the same MCU messages and download the same
firmware, but over a bulk endpoint instead of the MCU DMA ring.

No functional change.

Signed-off-by: Murad Dadashev <llamapersonaltv@gmail.com>
---
 drivers/net/wireless/mediatek/mt76/mt7603/mcu.c    | 23 ++++++++++++++--------
 drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h |  5 +++++
 2 files changed, 20 insertions(+), 8 deletions(-)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
index e432cce97640d631d91a088ec5a5a07721b03a94..bbc8402fc98e3c99a9073cc70c3c492e21b761cd 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
@@ -13,9 +13,8 @@ struct mt7603_fw_trailer {
 	__le32 dl_len;
 } __packed;
 
-static int
-mt7603_mcu_parse_response(struct mt76_dev *mdev, int cmd,
-			  struct sk_buff *skb, int seq)
+int mt7603_mcu_parse_response(struct mt76_dev *mdev, int cmd,
+			      struct sk_buff *skb, int seq)
 {
 	struct mt7603_dev *dev = container_of(mdev, struct mt7603_dev, mt76);
 	struct mt7603_mcu_rxd *rxd;
@@ -34,11 +33,10 @@ mt7603_mcu_parse_response(struct mt76_dev *mdev, int cmd,
 	return 0;
 }
 
-static int
-mt7603_mcu_skb_send_msg(struct mt76_dev *mdev, struct sk_buff *skb,
-			int cmd, int *wait_seq)
+void mt7603_mcu_fill_msg(struct mt7603_dev *dev, struct sk_buff *skb,
+			 int cmd, int *wait_seq)
 {
-	struct mt7603_dev *dev = container_of(mdev, struct mt7603_dev, mt76);
+	struct mt76_dev *mdev = &dev->mt76;
 	int hdrlen = dev->mcu_running ? sizeof(struct mt7603_mcu_txd) : 12;
 	struct mt7603_mcu_txd *txd;
 	u8 seq;
@@ -71,6 +69,15 @@ mt7603_mcu_skb_send_msg(struct mt76_dev *mdev, struct sk_buff *skb,
 
 	if (wait_seq)
 		*wait_seq = seq;
+}
+
+static int
+mt7603_mcu_skb_send_msg(struct mt76_dev *mdev, struct sk_buff *skb,
+			int cmd, int *wait_seq)
+{
+	struct mt7603_dev *dev = container_of(mdev, struct mt7603_dev, mt76);
+
+	mt7603_mcu_fill_msg(dev, skb, cmd, wait_seq);
 
 	return mt76_tx_queue_skb_raw(dev, mdev->q_mcu[MT_MCUQ_WM], skb, 0);
 }
@@ -113,7 +120,7 @@ mt7603_mcu_restart(struct mt76_dev *dev)
 	return mt76_mcu_send_msg(dev, -MCU_CMD_RESTART_DL_REQ, NULL, 0, true);
 }
 
-static int mt7603_load_firmware(struct mt7603_dev *dev)
+int mt7603_load_firmware(struct mt7603_dev *dev)
 {
 	const struct firmware *fw;
 	const struct mt7603_fw_trailer *hdr;
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h b/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h
index 5b0ecd01aad95a11f641ca41f8a9206882c54c28..f91968a63b6497460a26fed7d775f3745269bfa7 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h
@@ -186,6 +186,11 @@ int mt7603_eeprom_init(struct mt7603_dev *dev);
 int mt7603_dma_init(struct mt7603_dev *dev);
 void mt7603_dma_cleanup(struct mt7603_dev *dev);
 int mt7603_mcu_init(struct mt7603_dev *dev);
+int mt7603_load_firmware(struct mt7603_dev *dev);
+void mt7603_mcu_fill_msg(struct mt7603_dev *dev, struct sk_buff *skb,
+			 int cmd, int *wait_seq);
+int mt7603_mcu_parse_response(struct mt76_dev *mdev, int cmd,
+			      struct sk_buff *skb, int seq);
 void mt7603_init_debugfs(struct mt7603_dev *dev);
 
 static inline void mt7603_irq_enable(struct mt7603_dev *dev, u32 mask)

-- 
2.47.3

