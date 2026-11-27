From: Murad Dadashev <llamapersonaltv@gmail.com>
Date: Fri, 27 Nov 2026 11:35:16 +0300
Subject: [PATCH 05/10] wifi: mt76: mt7603: allow configuring TX and RX
 antennas separately
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-mt7603u-v1-5-369bee9846f8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795768526; l=5149;
 i=llamapersonaltv@gmail.com; s=20261127; h=from:subject:message-id;
 bh=Y74MJP9ElQtXX28cMEHxNG9OMLyPAiUoKVMjMJdxzCY=;
 b=i9ttqsa4JnW0uDjs5F5uSWJ3DoWL5r2Efwf/TaN8rHBKjs8BzVEGJMvorbrxrN7dUxeO2L9g7
 ccunndeahLDDtGf2gSrrG4PoXEuNa7IUJVLCIfWIqUUGy5qKALg6fbn
X-Developer-Key: i=llamapersonaltv@gmail.com; a=ed25519;
 pk=CeMIX207ioWRbMAA6A2GYgT+DpeVlKHVn7I0KjfHeCg=
X-Endpoint-Received: by B4 Relay for llamapersonaltv@gmail.com/20261127 with auth_id=1664
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add set_antenna support with independent TX and RX chain masks. When
fewer TX than RX chains are used, keep the RX MCS set and advertise the
lower TX stream count through IEEE80211_HT_MCS_TX_RX_DIFF, so rate
control does not pick rates the hardware cannot send.

This is useful for devices where one TX chain is not usable, which
otherwise lose a large share of two-stream frames.

Signed-off-by: Murad Dadashev <llamapersonaltv@gmail.com>
---
 drivers/net/wireless/mediatek/mt76/mt7603/eeprom.c |  1 +
 drivers/net/wireless/mediatek/mt76/mt7603/main.c   | 56 +++++++++++++++++++++-
 drivers/net/wireless/mediatek/mt76/mt7603/mcu.c    |  3 +-
 drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h |  2 +
 4 files changed, 60 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/eeprom.c b/drivers/net/wireless/mediatek/mt76/mt7603/eeprom.c
index 05f7aaefaf89b455681bf9e7e9a2440864aff4b5..28fd818428e1ce6f69866e7e192f62a952c6a80d 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/eeprom.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/eeprom.c
@@ -183,6 +183,7 @@ int mt7603_eeprom_init(struct mt7603_dev *dev)
 		dev->mphy.antenna_mask = 1;
 
 	dev->mphy.chainmask = dev->mphy.antenna_mask;
+	dev->tx_ant = dev->mphy.antenna_mask;
 
 	return mt76_eeprom_override(&dev->mphy);
 }
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/main.c b/drivers/net/wireless/mediatek/mt76/mt7603/main.c
index be4da5023e439a9e0f3386d1e2140464efad4e94..80dafe89e2c54c1148611b89c7cd65885214463c 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/main.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/main.c
@@ -719,6 +719,59 @@ mt7603_sta_rate_tbl_update(struct ieee80211_hw *hw, struct ieee80211_vif *vif,
 	spin_unlock_bh(&dev->mt76.lock);
 }
 
+static int
+mt7603_set_antenna(struct ieee80211_hw *hw, int radio_idx, u32 tx_ant,
+		   u32 rx_ant)
+{
+	struct mt7603_dev *dev = hw->priv;
+	struct mt76_phy *mphy = &dev->mphy;
+	struct ieee80211_sta_ht_cap *ht_cap = &mphy->sband_2g.sband.ht_cap;
+	u32 avail = hw->wiphy->available_antennas_tx;
+	int n_tx = hweight8(tx_ant);
+
+	if (!tx_ant || !rx_ant || (tx_ant & ~rx_ant) || (rx_ant & ~avail))
+		return -EINVAL;
+
+	if (BIT(n_tx) - 1 != tx_ant || BIT(hweight8(rx_ant)) - 1 != rx_ant)
+		return -EINVAL;
+
+	mutex_lock(&dev->mt76.mutex);
+
+	mphy->antenna_mask = rx_ant;
+	mphy->chainmask = rx_ant;
+	dev->tx_ant = tx_ant;
+	mt76_set_stream_caps(mphy, false);
+
+	ht_cap->mcs.tx_params = IEEE80211_HT_MCS_TX_DEFINED;
+	if (tx_ant != rx_ant) {
+		ht_cap->cap &= ~IEEE80211_HT_CAP_TX_STBC;
+		ht_cap->mcs.tx_params |= IEEE80211_HT_MCS_TX_RX_DIFF |
+			FIELD_PREP(IEEE80211_HT_MCS_TX_MAX_STREAMS_MASK,
+				   n_tx - 1);
+	}
+
+	if (test_bit(MT76_STATE_RUNNING, &mphy->state))
+		mt7603_mcu_set_channel(dev);
+
+	mutex_unlock(&dev->mt76.mutex);
+
+	return 0;
+}
+
+static int
+mt7603_get_antenna(struct ieee80211_hw *hw, int radio_idx, u32 *tx_ant,
+		   u32 *rx_ant)
+{
+	struct mt7603_dev *dev = hw->priv;
+
+	mutex_lock(&dev->mt76.mutex);
+	*tx_ant = dev->tx_ant;
+	*rx_ant = dev->mphy.antenna_mask;
+	mutex_unlock(&dev->mt76.mutex);
+
+	return 0;
+}
+
 static void
 mt7603_set_coverage_class(struct ieee80211_hw *hw, int radio_idx,
 			  s16 coverage_class)
@@ -783,7 +836,8 @@ const struct ieee80211_ops mt7603_ops = {
 	.set_coverage_class = mt7603_set_coverage_class,
 	.set_tim = mt76_set_tim,
 	.get_survey = mt76_get_survey,
-	.get_antenna = mt76_get_antenna,
+	.get_antenna = mt7603_get_antenna,
+	.set_antenna = mt7603_set_antenna,
 	.set_sar_specs = mt7603_set_sar_specs,
 };
 EXPORT_SYMBOL_GPL(mt7603_ops);
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
index eb633f5d7171e99a0339a2f44fa0ab39379642f1..cf81fc2e252a37e1d40c1f297b1c9688c054ca40 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
@@ -397,6 +397,7 @@ int mt7603_mcu_set_channel(struct mt7603_dev *dev)
 	struct cfg80211_chan_def *chandef = &dev->mphy.chandef;
 	struct ieee80211_hw *hw = mt76_hw(dev);
 	int n_chains = hweight8(dev->mphy.antenna_mask);
+	int n_tx = hweight8(dev->tx_ant);
 	struct {
 		u8 control_chan;
 		u8 center_chan;
@@ -410,7 +411,7 @@ int mt7603_mcu_set_channel(struct mt7603_dev *dev)
 		.control_chan = chandef->chan->hw_value,
 		.center_chan = chandef->chan->hw_value,
 		.bw = MT_BW_20,
-		.tx_streams = n_chains,
+		.tx_streams = n_tx,
 		.rx_streams = n_chains,
 	};
 	s8 tx_power = hw->conf.power_level * 2;
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h b/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h
index f91968a63b6497460a26fed7d775f3745269bfa7..8559a1ee06cd79a00ec4e382065f24f5180a8a21 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h
@@ -108,6 +108,8 @@ struct mt7603_dev {
 
 	const struct mt76_bus_ops *bus_ops;
 
+	u8 tx_ant;
+
 	u32 rxfilter;
 
 	struct mt7603_sta global_sta;

-- 
2.47.3

