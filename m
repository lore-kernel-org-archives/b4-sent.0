From: Murad Dadashev <llamapersonaltv@gmail.com>
Date: Fri, 27 Nov 2026 11:35:15 +0300
Subject: [PATCH 04/10] wifi: mt76: mt7603: only enable TSSI with valid
 calibration data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-mt7603u-v1-4-369bee9846f8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795768526; l=2004;
 i=llamapersonaltv@gmail.com; s=20261127; h=from:subject:message-id;
 bh=4IaYHcBwvZmnHbxpYxkpmJhCguuy/P3jyF640wHXuhU=;
 b=TD/sl2l8Yn93BERqGpE3rvqWAWN5TlvzE1SQ69ag8aaE9rypjhi15EaN1QD9nxXYaM2geuQz7
 8Mw2sFFkCFYDVuP/p7cX30XWsTLUzqUSWX/vEVWzIwAiXzeRQJLCFV4
X-Developer-Key: i=llamapersonaltv@gmail.com; a=ed25519;
 pk=CeMIX207ioWRbMAA6A2GYgT+DpeVlKHVn7I0KjfHeCg=
X-Endpoint-Received: by B4 Relay for llamapersonaltv@gmail.com/20261127 with auth_id=1664
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TSSI enable flag in NIC_CONF_1 is passed to the firmware as is in
the TX power control command. Some devices set the flag without any
TSSI calibration in the eFuse; one MT7603U dongle has NIC_CONF_1 set to
0x2000 with a TSSI slope of 0.

With TSSI enabled on such a device the firmware stops transmitting
shortly after the first frames are sent in AP mode, and the device has
to be power cycled.

Only keep TSSI enabled when a TSSI slope is programmed.

Signed-off-by: Murad Dadashev <llamapersonaltv@gmail.com>
---
 drivers/net/wireless/mediatek/mt76/mt7603/eeprom.h | 2 ++
 drivers/net/wireless/mediatek/mt76/mt7603/mcu.c    | 4 ++++
 2 files changed, 6 insertions(+)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/eeprom.h b/drivers/net/wireless/mediatek/mt76/mt7603/eeprom.h
index b6b746d1e56f9442aa12ab48bb211085798d89e8..6003d9233c12aa0e3e0517a380cb9d89cc596d59 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/eeprom.h
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/eeprom.h
@@ -88,4 +88,6 @@ enum mt7603_eeprom_source {
 #define MT_EE_NIC_CONF_0_RX_PATH		GENMASK(3, 0)
 #define MT_EE_NIC_CONF_0_TX_PATH		GENMASK(7, 4)
 
+#define MT_EE_NIC_CONF_1_TSSI_EN		BIT(5)
+
 #endif
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
index bbc8402fc98e3c99a9073cc70c3c492e21b761cd..eb633f5d7171e99a0339a2f44fa0ab39379642f1 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
@@ -384,6 +384,10 @@ static int mt7603_mcu_set_tx_power(struct mt7603_dev *dev)
 	memcpy(req.temp_comp_power, eep + MT_EE_STEP_NUM_NEG_6_7,
 	       sizeof(req.temp_comp_power));
 
+	if (!eep[MT_EE_TX_POWER_0_GRP4_TSSI_SLOPE] ||
+	    eep[MT_EE_TX_POWER_0_GRP4_TSSI_SLOPE] == 0xff)
+		req.tssi &= ~MT_EE_NIC_CONF_1_TSSI_EN;
+
 	return mt76_mcu_send_msg(&dev->mt76, MCU_EXT_CMD_SET_TX_POWER_CTRL,
 				 &req, sizeof(req), true);
 }

-- 
2.47.3

