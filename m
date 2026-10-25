From: Francesco Palmarini <palmarini@unive.it>
Date: Sun, 25 Oct 2026 12:32:31 +0000
Subject: [PATCH 1/2] wifi: mt76: mt7615: fix lost first mcu event on mt7622
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-mt7622-patch-sem-v1-1-e16e31c1face@unive.it>
References: <20261025-mt7622-patch-sem-v1-0-e16e31c1face@unive.it>
In-Reply-To: <20261025-mt7622-patch-sem-v1-0-e16e31c1face@unive.it>
To: Felix Fietkau <nbd@nbd.name>, Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>
Cc: Shayne Chen <shayne.chen@mediatek.com>, 
 Sean Wang <sean.wang@mediatek.com>, linux-wireless@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, 
 Francesco Palmarini <palmarini@unive.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792931550; l=2743;
 i=palmarini@unive.it; s=20261025; h=from:subject:message-id;
 bh=nZIy7Q+1c7rjrVYCS8D6XKjnp7Yxneq+NYbfLfBT9rU=;
 b=eYy0Di5u76izSd5zCNoHhDr+5xw58UCUHl2ekvy5zY2HCdSeR2zzqhqVNTholHq5BHZZwUXEF
 cDPakYsqenaAQkTKIxBb6pv9Sw9qDBXcvYC1RFjnyj1DXWvGzH8Qawt
X-Developer-Key: i=palmarini@unive.it; a=ed25519;
 pk=3OQ6zyqkl8a98pNobVtrSRWmLpTk0XEeKGtpd+/yK70=
X-Endpoint-Received: by B4 Relay for palmarini@unive.it/20261025 with auth_id=1317
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On MT7622 the 2.4 GHz wmac fails to initialize on most boots:

  mt7622-wmac 18000000.wmac: Message 00000010 (seq 1) timeout
  mt7622-wmac 18000000.wmac: Failed to get patch semaphore

The rom actually replies to the first PATCH_SEM_CONTROL command and
grants the semaphore, but the event shows up on the data ring with an
extra zero dword in front of it:

  00000000 e000001c 00000000 00000000
  00000000 e000000c 00000104 00000002

Since RXD0 is zero, mt7615_rx_check() handles it as tx status and the
event is dropped. The command times out and all the retries in
mt7615_pci_init_work() fail because the semaphore is already taken.

Detect the shifted event while the mcu is not running yet and strip the
extra dword.

Tested on Xiaomi AX3200 (same hw as Redmi AX6S).

Signed-off-by: Francesco Palmarini <palmarini@unive.it>
---
 drivers/net/wireless/mediatek/mt76/mt7615/mac.c | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7615/mac.c b/drivers/net/wireless/mediatek/mt76/mt7615/mac.c
index aad232c5a..54c70a427 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7615/mac.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7615/mac.c
@@ -1590,6 +1590,21 @@ static void mt7615_mac_tx_free(struct mt7615_dev *dev, void *data, int len)
 	mt76_worker_schedule(&dev->mt76.tx_worker);
 }
 
+static bool
+mt7615_mac_rx_shifted_event(struct mt7615_dev *dev, __le32 *rxd, int len)
+{
+	/* mt7622 rom can report the first mcu event on the data ring,
+	 * with an extra dword in front of it
+	 */
+	if (!is_mt7622(&dev->mt76) ||
+	    test_bit(MT76_STATE_MCU_RUNNING, &dev->mphy.state))
+		return false;
+
+	return len >= 8 && !rxd[0] &&
+	       le32_get_bits(rxd[1], MT_RXD0_PKT_TYPE) == PKT_TYPE_RX_EVENT &&
+	       le32_get_bits(rxd[1], MT_RXD0_LENGTH) == len - 4;
+}
+
 bool mt7615_rx_check(struct mt76_dev *mdev, void *data, int len)
 {
 	struct mt7615_dev *dev = container_of(mdev, struct mt7615_dev, mt76);
@@ -1597,6 +1612,9 @@ bool mt7615_rx_check(struct mt76_dev *mdev, void *data, int len)
 	__le32 *end = (__le32 *)&rxd[len / 4];
 	enum rx_pkt_type type;
 
+	if (mt7615_mac_rx_shifted_event(dev, rxd, len))
+		return true;
+
 	type = le32_get_bits(rxd[0], MT_RXD0_PKT_TYPE);
 
 	switch (type) {
@@ -1624,6 +1642,11 @@ void mt7615_queue_rx_skb(struct mt76_dev *mdev, enum mt76_rxq_id q,
 	enum rx_pkt_type type;
 	u16 flag;
 
+	if (mt7615_mac_rx_shifted_event(dev, rxd, skb->len)) {
+		skb_pull(skb, 4);
+		rxd = (__le32 *)skb->data;
+	}
+
 	type = le32_get_bits(rxd[0], MT_RXD0_PKT_TYPE);
 	flag = le32_get_bits(rxd[0], MT_RXD0_PKT_FLAG);
 	if (type == PKT_TYPE_RX_EVENT && flag == 0x1)

-- 
2.39.5

