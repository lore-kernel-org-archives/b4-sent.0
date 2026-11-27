From: Murad Dadashev <llamapersonaltv@gmail.com>
Date: Fri, 27 Nov 2026 11:35:18 +0300
Subject: [PATCH 07/10] wifi: mt76: mt7603: skip PCIe specific setup on
 non-MMIO buses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-mt7603u-v1-7-369bee9846f8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795768526; l=6545;
 i=llamapersonaltv@gmail.com; s=20261127; h=from:subject:message-id;
 bh=7hNOZZrAbeMscPWoLKhgzZSs39hMPOTAK7zA0t6r4A8=;
 b=cqaYJ8vijeYtM89rdaLWTn+xndOIiN/bW6Iq6BMATMbRkjjh59pKKmR4sefTdcTfpl3uvDs9x
 nbOGmLzUyZrDVm8tF/y1k5yBJzHNmLF3mpamUjzjBzUG8U3gOm9ZWvp
X-Developer-Key: i=llamapersonaltv@gmail.com; a=ed25519;
 pk=CeMIX207ioWRbMAA6A2GYgT+DpeVlKHVn7I0KjfHeCg=
X-Endpoint-Received: by B4 Relay for llamapersonaltv@gmail.com/20261127 with auth_id=1664
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Prepare the shared code for MT7603U:

- do not touch the PCIe interrupt, WPDMA and PCIe remap registers
- skip the DMA watchdog and reset in mac_work, which rely on the WPDMA
  registers
- skip the LED callbacks, which run in atomic context
- start the MAC without DMA setup and do not reload the firmware if
  the bus driver already loaded it
- USB takes physical addresses, so mt7603_reg_map() passes them through
- the firmware download bypass queue is 8 on USB

No functional change for MT7603E and MT76x8.

Signed-off-by: Murad Dadashev <llamapersonaltv@gmail.com>
---
 drivers/net/wireless/mediatek/mt76/mt7603/core.c   |  3 +++
 drivers/net/wireless/mediatek/mt76/mt7603/init.c   | 30 ++++++++++++++--------
 drivers/net/wireless/mediatek/mt76/mt7603/mac.c    |  5 ++--
 drivers/net/wireless/mediatek/mt76/mt7603/mcu.c    |  4 ++-
 drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h |  6 +++--
 5 files changed, 32 insertions(+), 16 deletions(-)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/core.c b/drivers/net/wireless/mediatek/mt76/mt7603/core.c
index a99e4d3156eb94d580fe6b8c262b8f7c19368fb2..52f8f075c7e85a1f1238714f065e314bea1706d0 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/core.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/core.c
@@ -62,6 +62,9 @@ u32 mt7603_reg_map(struct mt7603_dev *dev, u32 addr)
 	u32 base = addr & MT_MCU_PCIE_REMAP_2_BASE;
 	u32 offset = addr & MT_MCU_PCIE_REMAP_2_OFFSET;
 
+	if (mt76_is_usb(&dev->mt76))
+		return addr;
+
 	dev->bus_ops->wr(&dev->mt76, MT_MCU_PCIE_REMAP_2, base);
 
 	return MT_PCIE_REMAP_BASE_2 + offset;
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/init.c b/drivers/net/wireless/mediatek/mt76/mt7603/init.c
index 66b65ec2add7ccdd4d205ee203d10b3d221cae7b..d1db7176c0fa9ed451ed8bfa45071ace36493f67 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/init.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/init.c
@@ -224,7 +224,8 @@ mt7603_mac_init(struct mt7603_dev *dev)
 		MT_DMA_TCFR_TXS_AGGR_COUNT | /* Maximum count */
 		MT_DMA_TCFR_TXS_BIT_MAP);
 
-	mt76_wr(dev, MT_MCU_PCIE_REMAP_1, MT_PSE_WTBL_2_PHYS_ADDR);
+	if (mt76_is_mmio(&dev->mt76))
+		mt76_wr(dev, MT_MCU_PCIE_REMAP_1, MT_PSE_WTBL_2_PHYS_ADDR);
 
 	for (i = 0; i < MT7603_WTBL_SIZE; i++)
 		mt7603_wtbl_clear(dev, i);
@@ -281,18 +282,23 @@ mt7603_init_hardware(struct mt7603_dev *dev)
 {
 	int i, ret;
 
-	mt76_wr(dev, MT_INT_SOURCE_CSR, ~0);
+	if (mt76_is_mmio(&dev->mt76))
+		mt76_wr(dev, MT_INT_SOURCE_CSR, ~0);
 
 	ret = mt7603_eeprom_init(dev);
 	if (ret < 0)
 		return ret;
 
-	ret = mt7603_dma_init(dev);
-	if (ret)
-		return ret;
+	if (mt76_is_mmio(&dev->mt76)) {
+		ret = mt7603_dma_init(dev);
+		if (ret)
+			return ret;
 
-	mt76_wr(dev, MT_WPDMA_GLO_CFG, 0x52000850);
-	mt7603_mac_dma_start(dev);
+		mt76_wr(dev, MT_WPDMA_GLO_CFG, 0x52000850);
+		mt7603_mac_dma_start(dev);
+	} else {
+		mt7603_mac_start(dev);
+	}
 	dev->rxfilter = mt76_rr(dev, MT_WF_RFCR);
 	set_bit(MT76_STATE_INITIALIZED, &dev->mphy.state);
 
@@ -302,9 +308,11 @@ mt7603_init_hardware(struct mt7603_dev *dev)
 		mt76_poll(dev, MT_PSE_RTA, MT_PSE_RTA_BUSY, 0, 5000);
 	}
 
-	ret = mt7603_mcu_init(dev);
-	if (ret)
-		return ret;
+	if (!dev->mcu_running) {
+		ret = mt7603_mcu_init(dev);
+		if (ret)
+			return ret;
+	}
 
 	mt7603_dma_sched_init(dev);
 	mt7603_mcu_set_eeprom(dev);
@@ -549,7 +557,7 @@ int mt7603_register_device(struct mt7603_dev *dev)
 	ieee80211_hw_set(hw, NEEDS_UNIQUE_STA_ADDR);
 
 	/* init led callbacks */
-	if (IS_ENABLED(CONFIG_MT76_LEDS)) {
+	if (IS_ENABLED(CONFIG_MT76_LEDS) && mt76_is_mmio(&dev->mt76)) {
 		dev->mphy.leds.cdev.brightness_set = mt7603_led_set_brightness;
 		dev->mphy.leds.cdev.blink_set = mt7603_led_set_blink;
 	}
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mac.c b/drivers/net/wireless/mediatek/mt76/mt7603/mac.c
index efe680d67e4af728dbef32290a55e4279926f532..3758d55c299b6f143ef87dc70e72e6250695a409 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mac.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mac.c
@@ -2033,7 +2033,8 @@ void mt7603_mac_work(struct work_struct *work)
 	if (dev->mphy.mac_work_count == 10)
 		mt7603_false_cca_check(dev);
 
-	if (mt7603_watchdog_check(dev, &dev->rx_pse_check,
+	if (mt76_is_mmio(&dev->mt76) &&
+	    (mt7603_watchdog_check(dev, &dev->rx_pse_check,
 				  RESET_CAUSE_RX_PSE_BUSY,
 				  mt7603_rx_pse_busy) ||
 	    mt7603_watchdog_check(dev, &dev->beacon_check,
@@ -2051,7 +2052,7 @@ void mt7603_mac_work(struct work_struct *work)
 	    mt7603_watchdog_check(dev, &dev->mcu_hang,
 				  RESET_CAUSE_MCU_HANG,
 				  NULL) ||
-	    dev->reset_cause[RESET_CAUSE_RESET_FAILED]) {
+	    dev->reset_cause[RESET_CAUSE_RESET_FAILED])) {
 		dev->beacon_check = 0;
 		dev->tx_dma_check = 0;
 		dev->tx_hang_check = 0;
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
index cf81fc2e252a37e1d40c1f297b1c9688c054ca40..dea48b85d0dd8b03f3b25e45598a0bfa3e19b57a 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
@@ -164,7 +164,9 @@ int mt7603_load_firmware(struct mt7603_dev *dev)
 
 	/* switch to bypass mode */
 	mt76_rmw(dev, MT_SCH_4, MT_SCH_4_FORCE_QID,
-		 MT_SCH_4_BYPASS | FIELD_PREP(MT_SCH_4_FORCE_QID, 5));
+		 MT_SCH_4_BYPASS |
+		 FIELD_PREP(MT_SCH_4_FORCE_QID,
+			    mt76_is_usb(&dev->mt76) ? 8 : 5));
 
 	val = mt76_rr(dev, MT_TOP_MISC2);
 	if (val & BIT(1)) {
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h b/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h
index 6c4836fbd2264288b99b0b6780f66b776a92e930..1b50c6b4bb8faf277e126f9c18fefbaa88150d41 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h
@@ -210,12 +210,14 @@ void mt7603_init_debugfs(struct mt7603_dev *dev);
 
 static inline void mt7603_irq_enable(struct mt7603_dev *dev, u32 mask)
 {
-	mt76_set_irq_mask(&dev->mt76, MT_INT_MASK_CSR, 0, mask);
+	if (mt76_is_mmio(&dev->mt76))
+		mt76_set_irq_mask(&dev->mt76, MT_INT_MASK_CSR, 0, mask);
 }
 
 static inline void mt7603_irq_disable(struct mt7603_dev *dev, u32 mask)
 {
-	mt76_set_irq_mask(&dev->mt76, MT_INT_MASK_CSR, mask, 0);
+	if (mt76_is_mmio(&dev->mt76))
+		mt76_set_irq_mask(&dev->mt76, MT_INT_MASK_CSR, mask, 0);
 }
 
 void mt7603_mac_reset_counters(struct mt7603_dev *dev);

-- 
2.47.3

