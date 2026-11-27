From: Murad Dadashev <llamapersonaltv@gmail.com>
Date: Fri, 27 Nov 2026 11:35:20 +0300
Subject: [PATCH 09/10] wifi: mt76: mt7603: add MT7603U USB support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-mt7603u-v1-9-369bee9846f8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795768526; l=16505;
 i=llamapersonaltv@gmail.com; s=20261127; h=from:subject:message-id;
 bh=FlAt7JR8N2EFxhnj7BKA0fb/eZmFPkPFLa76Hv7gx+Q=;
 b=01SnpH8HloBGy1GMk9CPKEaRMS3GxqxUZ63jbGda5eA3IOBOjGZWEqH0Nlzj01nz8ufLxdc7F
 g1QykoXC1AADM5GQVm/dpEHWgwXUQppmlAB5vBra+wlSxD9hS2D5mZS
X-Developer-Key: i=llamapersonaltv@gmail.com; a=ed25519;
 pk=CeMIX207ioWRbMAA6A2GYgT+DpeVlKHVn7I0KjfHeCg=
X-Endpoint-Received: by B4 Relay for llamapersonaltv@gmail.com/20261127 with auth_id=1664
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for MT7603U based USB 2.0 dongles (0e8d:7603) using the
shared mt7603 code.

Register access goes through the EXT vendor requests and needs the
logical register offsets used by the shared code translated to the
physical addresses of the chip. MCU commands and the firmware download
use the inband command bulk endpoint. UDMA RX aggregation is left
disabled since mt76-usb expects one frame per URB.

On TX, the TXD is placed in the skb headroom and the 802.11 header is
padded to a 4 byte boundary, as the USB DMA engine expects.

The device works with the existing mt7603_e2.bin firmware.

Tested in station mode with WPA2 on a 0e8d:7603 dongle.

Signed-off-by: Murad Dadashev <llamapersonaltv@gmail.com>
---
 drivers/net/wireless/mediatek/mt76/mt7603/Kconfig  |  14 +
 drivers/net/wireless/mediatek/mt76/mt7603/Makefile |   2 +
 drivers/net/wireless/mediatek/mt76/mt7603/dma.c    |   1 +
 drivers/net/wireless/mediatek/mt76/mt7603/mac.c    |   2 +
 drivers/net/wireless/mediatek/mt76/mt7603/main.c   |   5 +
 drivers/net/wireless/mediatek/mt76/mt7603/mcu.c    |   3 +
 drivers/net/wireless/mediatek/mt76/mt7603/usb.c    | 349 +++++++++++++++++++++
 7 files changed, 376 insertions(+)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/Kconfig b/drivers/net/wireless/mediatek/mt76/mt7603/Kconfig
index dfdd4da15bb0d03843f3d25958cb9391ec7cd54d..48b97e2e81625da0c65c14fca0725d6fc6efae03 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/Kconfig
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/Kconfig
@@ -14,3 +14,17 @@ config MT7603E
 	  to 300Mbps PHY rate
 
 	  To compile this driver as a module, choose M here.
+
+config MT7603U
+	tristate "MediaTek MT7603U (USB) support"
+	select MT76_USB
+	select MT7603_COMMON
+	depends on MAC80211
+	depends on USB
+	help
+	  This adds support for MT7603U-based USB 2.0 wireless devices.
+	  It shares the MAC, MCU and PHY code with the MT7603E driver and
+	  supports station and AP mode. This family supports IEEE 802.11n
+	  2x2 up to 300Mbps PHY rate.
+
+	  To compile this driver as a module, choose M here.
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/Makefile b/drivers/net/wireless/mediatek/mt76/mt7603/Makefile
index ad2ab9970d51c9a4a3e458dbbfa72379447f6051..ab69b16abc192556d30e9135013d8ddf54588f66 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/Makefile
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/Makefile
@@ -1,9 +1,11 @@
 # SPDX-License-Identifier: BSD-3-Clause-Clear
 obj-$(CONFIG_MT7603_COMMON) += mt7603-common.o
 obj-$(CONFIG_MT7603E) += mt7603e.o
+obj-$(CONFIG_MT7603U) += mt7603u.o
 
 mt7603-common-y := \
 	main.o init.o mcu.o core.o dma.o mac.o \
 	eeprom.o beacon.o debugfs.o
 
 mt7603e-y := pci.o soc.o
+mt7603u-y := usb.o
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/dma.c b/drivers/net/wireless/mediatek/mt76/mt7603/dma.c
index 491c8c937031a73d5a70c490b6c8f8a38fb6575b..a61c4ab2bf7bc30e5e06124e162d39d0fe463c89 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/dma.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/dma.c
@@ -146,6 +146,7 @@ void mt7603_queue_rx_skb(struct mt76_dev *mdev, enum mt76_rxq_id q,
 		break;
 	}
 }
+EXPORT_SYMBOL_GPL(mt7603_queue_rx_skb);
 
 static int
 mt7603_init_rx_queue(struct mt7603_dev *dev, struct mt76_queue *q,
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mac.c b/drivers/net/wireless/mediatek/mt76/mt7603/mac.c
index 3758d55c299b6f143ef87dc70e72e6250695a409..3236d70a26a845d94f8ca955dca8aba7ae166ddf 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mac.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mac.c
@@ -1239,6 +1239,7 @@ int mt7603_tx_prepare_skb(struct mt76_dev *mdev, void *txwi_ptr,
 
 	return 0;
 }
+EXPORT_SYMBOL_GPL(mt7603_tx_prepare_skb);
 
 static bool
 mt7603_fill_txs(struct mt7603_dev *dev, struct mt7603_sta *sta,
@@ -1772,6 +1773,7 @@ void mt7603_update_channel(struct mt76_phy *mphy)
 	state = mphy->chan_state;
 	state->cc_busy += mt76_rr(dev, MT_MIB_STAT_CCA);
 }
+EXPORT_SYMBOL_GPL(mt7603_update_channel);
 
 void
 mt7603_edcca_set_strict(struct mt7603_dev *dev, bool val)
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/main.c b/drivers/net/wireless/mediatek/mt76/mt7603/main.c
index ca4f66bde33a668d9f4cff85512a082407eaaf44..2c22ccdaaa2626454be6a7453d3cee630f1fbbeb 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/main.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/main.c
@@ -197,6 +197,7 @@ int mt7603_set_channel(struct mt76_phy *mphy)
 
 	return ret;
 }
+EXPORT_SYMBOL_GPL(mt7603_set_channel);
 
 static int mt7603_set_sar_specs(struct ieee80211_hw *hw,
 				const struct cfg80211_sar_specs *sar)
@@ -352,6 +353,7 @@ mt7603_sta_add(struct mt76_dev *mdev, struct ieee80211_vif *vif,
 
 	return ret;
 }
+EXPORT_SYMBOL_GPL(mt7603_sta_add);
 
 int
 mt7603_sta_event(struct mt76_dev *mdev, struct ieee80211_vif *vif,
@@ -367,6 +369,7 @@ mt7603_sta_event(struct mt76_dev *mdev, struct ieee80211_vif *vif,
 
 	return 0;
 }
+EXPORT_SYMBOL_GPL(mt7603_sta_event);
 
 void
 mt7603_sta_remove(struct mt76_dev *mdev, struct ieee80211_vif *vif,
@@ -393,6 +396,7 @@ mt7603_sta_remove(struct mt76_dev *mdev, struct ieee80211_vif *vif,
 
 	mt7603_wtbl_clear(dev, wcid->idx);
 }
+EXPORT_SYMBOL_GPL(mt7603_sta_remove);
 
 static void
 mt7603_ps_tx_list(struct mt7603_dev *dev, struct sk_buff_head *list)
@@ -426,6 +430,7 @@ mt7603_sta_ps(struct mt76_dev *mdev, struct ieee80211_sta *sta, bool ps)
 
 	mt7603_ps_tx_list(dev, &list);
 }
+EXPORT_SYMBOL_GPL(mt7603_sta_ps);
 
 static struct ieee80211_hdr *
 mt7603_ps_skb_hdr(struct sk_buff *skb)
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
index dea48b85d0dd8b03f3b25e45598a0bfa3e19b57a..68332093426bb041a5b4c790e6fa5c35410a71c4 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/mcu.c
@@ -32,6 +32,7 @@ int mt7603_mcu_parse_response(struct mt76_dev *mdev, int cmd,
 
 	return 0;
 }
+EXPORT_SYMBOL_GPL(mt7603_mcu_parse_response);
 
 void mt7603_mcu_fill_msg(struct mt7603_dev *dev, struct sk_buff *skb,
 			 int cmd, int *wait_seq)
@@ -70,6 +71,7 @@ void mt7603_mcu_fill_msg(struct mt7603_dev *dev, struct sk_buff *skb,
 	if (wait_seq)
 		*wait_seq = seq;
 }
+EXPORT_SYMBOL_GPL(mt7603_mcu_fill_msg);
 
 static int
 mt7603_mcu_skb_send_msg(struct mt76_dev *mdev, struct sk_buff *skb,
@@ -223,6 +225,7 @@ int mt7603_load_firmware(struct mt7603_dev *dev)
 
 	return ret;
 }
+EXPORT_SYMBOL_GPL(mt7603_load_firmware);
 
 int mt7603_mcu_init(struct mt7603_dev *dev)
 {
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/usb.c b/drivers/net/wireless/mediatek/mt76/mt7603/usb.c
new file mode 100644
index 0000000000000000000000000000000000000000..9fbfb2a7cd00674bb1dbf9015ba22b149b73f4e9
--- /dev/null
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/usb.c
@@ -0,0 +1,349 @@
+// SPDX-License-Identifier: BSD-3-Clause-Clear
+
+#include <linux/kernel.h>
+#include <linux/module.h>
+#include <linux/usb.h>
+
+#include "mt7603.h"
+#include "mac.h"
+#include "mcu.h"
+
+#define MT_UDMA_WLCFG_0			0x50029018
+#define MT_UDMA_WLCFG_0_TX_EN		BIT(23)
+#define MT_UDMA_WLCFG_0_RX_EN		BIT(22)
+#define MT_UDMA_WLCFG_0_RX_AGG_EN	BIT(21)
+#define MT_UDMA_WLCFG_0_RX_MPSZ_PAD0	BIT(18)
+#define MT_UDMA_WLCFG_0_RX_AGG_LMT	GENMASK(15, 8)
+#define MT_UDMA_WLCFG_0_RX_AGG_TO	GENMASK(7, 0)
+
+static const struct usb_device_id mt7603u_device_table[] = {
+	{ USB_DEVICE_AND_INTERFACE_INFO(0x0e8d, 0x7603, 0xff, 0xff, 0xff) },
+	{ },
+};
+
+static const struct {
+	u32 phys;
+	u32 start;
+	u32 size;
+} mt7603u_mac_map[] = {
+	{ 0x60000000, 0x20000, 0x200 },
+	{ 0x60100000, 0x21000, 0x200 },
+	{ 0x60110000, 0x21200, 0x200 },
+	{ 0x60120000, 0x21400, 0x200 },
+	{ 0x60130000, 0x21600, 0x200 },
+	{ 0x60140000, 0x21800, 0x200 },
+	{ 0x60150000, 0x21a00, 0x200 },
+	{ 0x60160000, 0x21c00, 0x200 },
+	{ 0x60170000, 0x21e00, 0x200 },
+	{ 0x60180000, 0x22000, 0x1000 },
+	{ 0x60190000, 0x23000, 0x200 },
+	{ 0x601a0000, 0x23200, 0x200 },
+	{ 0x60300000, 0x24000, 0x400 },
+	{ 0x60310000, 0x24400, 0x200 },
+	{ 0x60320000, 0x28000, 0x4000 },
+	{ 0x60330000, 0x2c000, 0x200 },
+	{ 0x60400000, 0x2d000, 0x200 },
+};
+
+static u32 mt7603u_addr(u32 addr)
+{
+	int i;
+
+	if (addr < 0x2000)
+		return 0x80020000 + addr;
+	if (addr < 0x4000)
+		return 0x80000000 + addr - 0x2000;
+	if (addr < 0x8000)
+		return 0x50000000 + addr - 0x4000;
+	if (addr < 0x10000)
+		return 0xa0000000 + addr - 0x8000;
+	if (addr < 0x20000)
+		return 0x60200000 + addr - 0x10000;
+	if (addr < 0x40000) {
+		for (i = 0; i < ARRAY_SIZE(mt7603u_mac_map); i++) {
+			u32 start = mt7603u_mac_map[i].start;
+
+			if (addr >= start && addr < start + mt7603u_mac_map[i].size)
+				return mt7603u_mac_map[i].phys + addr - start;
+		}
+		return addr;
+	}
+	if (addr < 0x80000)
+		return 0xa5000000 + addr - 0x40000;
+	if (addr >= 0xc0000 && addr < 0xc0100)
+		return 0x800c0000 + addr - 0xc0000;
+
+	return addr;
+}
+
+static u32 mt7603u_rr(struct mt76_dev *dev, u32 addr)
+{
+	u32 ret;
+
+	mutex_lock(&dev->usb.usb_ctrl_mtx);
+	ret = ___mt76u_rr(dev, MT_VEND_READ_EXT, USB_DIR_IN | USB_TYPE_VENDOR,
+			  mt7603u_addr(addr));
+	mutex_unlock(&dev->usb.usb_ctrl_mtx);
+
+	return ret;
+}
+
+static void mt7603u_wr(struct mt76_dev *dev, u32 addr, u32 val)
+{
+	mutex_lock(&dev->usb.usb_ctrl_mtx);
+	___mt76u_wr(dev, MT_VEND_WRITE_EXT, USB_DIR_OUT | USB_TYPE_VENDOR,
+		    mt7603u_addr(addr), val);
+	mutex_unlock(&dev->usb.usb_ctrl_mtx);
+}
+
+static u32 mt7603u_rmw(struct mt76_dev *dev, u32 addr, u32 mask, u32 val)
+{
+	u32 phys = mt7603u_addr(addr);
+
+	mutex_lock(&dev->usb.usb_ctrl_mtx);
+	val |= ___mt76u_rr(dev, MT_VEND_READ_EXT,
+			   USB_DIR_IN | USB_TYPE_VENDOR, phys) & ~mask;
+	___mt76u_wr(dev, MT_VEND_WRITE_EXT, USB_DIR_OUT | USB_TYPE_VENDOR,
+		    phys, val);
+	mutex_unlock(&dev->usb.usb_ctrl_mtx);
+
+	return val;
+}
+
+static void mt7603u_write_copy(struct mt76_dev *dev, u32 offset,
+			       const void *data, int len)
+{
+	const u32 *val = data;
+	int i;
+
+	for (i = 0; i < len / 4; i++)
+		mt7603u_wr(dev, offset + i * 4, val[i]);
+}
+
+static void mt7603u_read_copy(struct mt76_dev *dev, u32 offset,
+			      void *data, int len)
+{
+	u32 *val = data;
+	int i;
+
+	for (i = 0; i < len / 4; i++)
+		val[i] = mt7603u_rr(dev, offset + i * 4);
+}
+
+static int mt7603u_enable_udma(struct mt7603_dev *dev)
+{
+	u32 val;
+
+	val = mt76_rr(dev, MT_UDMA_WLCFG_0);
+	val &= ~(MT_UDMA_WLCFG_0_RX_AGG_EN | MT_UDMA_WLCFG_0_RX_AGG_LMT |
+		 MT_UDMA_WLCFG_0_RX_AGG_TO);
+	val |= MT_UDMA_WLCFG_0_TX_EN | MT_UDMA_WLCFG_0_RX_EN |
+	       MT_UDMA_WLCFG_0_RX_MPSZ_PAD0 |
+	       FIELD_PREP(MT_UDMA_WLCFG_0_RX_AGG_LMT, 0x15) |
+	       FIELD_PREP(MT_UDMA_WLCFG_0_RX_AGG_TO, 0x80);
+	mt76_wr(dev, MT_UDMA_WLCFG_0, val);
+
+	return 0;
+}
+
+static int mt7603u_mcu_send_msg(struct mt76_dev *mdev, struct sk_buff *skb,
+				int cmd, int *seq)
+{
+	struct mt7603_dev *dev = container_of(mdev, struct mt7603_dev, mt76);
+	int ret, pad;
+
+	mt7603_mcu_fill_msg(dev, skb, cmd, seq);
+
+	pad = round_up(skb->len, 4) + 4 - skb->len;
+	ret = mt76_skb_adjust_pad(skb, pad);
+	if (ret < 0)
+		goto out;
+
+	ret = mt76u_bulk_msg(mdev, skb->data, skb->len, NULL, 1000,
+			     MT_EP_OUT_INBAND_CMD);
+out:
+	dev_kfree_skb(skb);
+
+	return ret;
+}
+
+static int mt7603u_mcu_init(struct mt7603_dev *dev)
+{
+	static const struct mt76_mcu_ops mt7603u_mcu_ops = {
+		.headroom = sizeof(struct mt7603_mcu_txd),
+		.tailroom = 8,
+		.mcu_skb_send_msg = mt7603u_mcu_send_msg,
+		.mcu_parse_response = mt7603_mcu_parse_response,
+	};
+
+	dev->mt76.mcu_ops = &mt7603u_mcu_ops;
+
+	return mt7603_load_firmware(dev);
+}
+
+static int
+mt7603u_tx_prepare_skb(struct mt76_dev *mdev, void *txwi_ptr,
+		       enum mt76_txq_id qid, struct mt76_wcid *wcid,
+		       struct ieee80211_sta *sta,
+		       struct mt76_tx_info *tx_info)
+{
+	struct sk_buff *skb = tx_info->skb;
+	__le32 *txwi;
+	int ret, len, pad;
+
+	ret = skb_cow_head(skb, MT_TXD_SIZE + 2);
+	if (ret)
+		return ret;
+
+	pad = ieee80211_get_hdrlen_from_skb(skb) % 4 ? 2 : 0;
+	mt76_insert_hdr_pad(skb);
+	txwi = (__le32 *)(skb->data - MT_TXD_SIZE);
+	memset(txwi, 0, MT_TXD_SIZE);
+	ret = mt7603_tx_prepare_skb(mdev, txwi, qid, wcid, sta, tx_info);
+	if (ret)
+		return ret;
+
+	le32p_replace_bits(&txwi[1], pad, MT_TXD1_HDR_PAD);
+	skb_push(skb, MT_TXD_SIZE);
+	len = round_up(skb->len, 4);
+	le32p_replace_bits(&txwi[0], len, MT_TXD0_TX_BYTES);
+
+	return mt76_skb_adjust_pad(skb, len + 4 - skb->len);
+}
+
+static void mt7603u_tx_complete_skb(struct mt76_dev *mdev,
+				    struct mt76_queue_entry *e)
+{
+	struct sk_buff *skb = e->skb;
+	int hdr_len;
+
+	skb_pull(skb, MT_TXD_SIZE);
+	hdr_len = ieee80211_get_hdrlen_from_skb(skb);
+	if (hdr_len % 4) {
+		memmove(skb->data + 2, skb->data, hdr_len);
+		skb_pull(skb, 2);
+	}
+	mt76_tx_complete_skb(mdev, e->wcid, skb);
+}
+
+static int mt7603u_probe(struct usb_interface *usb_intf,
+			 const struct usb_device_id *id)
+{
+	static const struct mt76_driver_ops drv_ops = {
+		.txwi_size = MT_TXD_SIZE,
+		.drv_flags = MT_DRV_RX_DMA_HDR | MT_DRV_HW_MGMT_TXQ |
+			     MT_DRV_SW_RX_AIRTIME,
+		.survey_flags = SURVEY_INFO_TIME_TX,
+		.tx_prepare_skb = mt7603u_tx_prepare_skb,
+		.tx_complete_skb = mt7603u_tx_complete_skb,
+		.rx_skb = mt7603_queue_rx_skb,
+		.sta_ps = mt7603_sta_ps,
+		.sta_add = mt7603_sta_add,
+		.sta_event = mt7603_sta_event,
+		.sta_remove = mt7603_sta_remove,
+		.update_survey = mt7603_update_channel,
+		.set_channel = mt7603_set_channel,
+	};
+	static struct mt76_bus_ops bus_ops = {
+		.rr = mt7603u_rr,
+		.wr = mt7603u_wr,
+		.rmw = mt7603u_rmw,
+		.read_copy = mt7603u_read_copy,
+		.write_copy = mt7603u_write_copy,
+		.type = MT76_BUS_USB,
+	};
+	struct usb_device *udev = interface_to_usbdev(usb_intf);
+	struct mt7603_dev *dev;
+	struct mt76_dev *mdev;
+	int ret;
+
+	mdev = mt76_alloc_device(&usb_intf->dev, sizeof(*dev), &mt7603_ops,
+				 &drv_ops);
+	if (!mdev)
+		return -ENOMEM;
+
+	dev = container_of(mdev, struct mt7603_dev, mt76);
+	udev = usb_get_dev(udev);
+	usb_reset_device(udev);
+
+	usb_set_intfdata(usb_intf, dev);
+
+	ret = __mt76u_init(mdev, usb_intf, &bus_ops);
+	if (ret < 0)
+		goto error;
+
+	mdev->rev = (mt76_rr(dev, MT_HW_CHIPID) << 16) |
+		    (mt76_rr(dev, MT_HW_REV) & 0xff);
+	dev_info(mdev->dev, "ASIC revision: %08x\n", mdev->rev);
+
+	ret = mt7603u_enable_udma(dev);
+	if (ret)
+		goto error;
+
+	ret = mt76u_alloc_mcu_queue(mdev);
+	if (ret)
+		goto error;
+
+	ret = mt76u_alloc_queues(mdev);
+	if (ret)
+		goto error;
+
+	set_bit(MT76_STATE_INITIALIZED, &dev->mphy.state);
+
+	ret = mt7603u_mcu_init(dev);
+	if (ret)
+		goto error;
+
+	mt76_hw(dev)->extra_tx_headroom = MT_TXD_SIZE + 2;
+
+	ret = mt7603_register_device(dev);
+	if (ret)
+		goto error;
+
+	return 0;
+
+error:
+	clear_bit(MT76_STATE_INITIALIZED, &dev->mphy.state);
+	mt76u_queues_deinit(mdev);
+	usb_set_intfdata(usb_intf, NULL);
+	usb_put_dev(interface_to_usbdev(usb_intf));
+	mt76_free_device(mdev);
+
+	return ret;
+}
+
+static void mt7603u_disconnect(struct usb_interface *usb_intf)
+{
+	struct mt7603_dev *dev = usb_get_intfdata(usb_intf);
+
+	if (!dev)
+		return;
+
+	if (test_bit(MT76_STATE_REGISTERED, &dev->mphy.state)) {
+		mt76_unregister_device(&dev->mt76);
+		cancel_work_sync(&dev->rate_work);
+		cancel_work_sync(&dev->ps_work);
+	}
+
+	clear_bit(MT76_STATE_INITIALIZED, &dev->mphy.state);
+	mt76u_queues_deinit(&dev->mt76);
+	usb_set_intfdata(usb_intf, NULL);
+	usb_put_dev(interface_to_usbdev(usb_intf));
+	mt76_free_device(&dev->mt76);
+}
+
+MODULE_DEVICE_TABLE(usb, mt7603u_device_table);
+MODULE_FIRMWARE(MT7603_FIRMWARE_E2);
+
+static struct usb_driver mt7603u_driver = {
+	.name		= KBUILD_MODNAME,
+	.id_table	= mt7603u_device_table,
+	.probe		= mt7603u_probe,
+	.disconnect	= mt7603u_disconnect,
+	.soft_unbind	= 1,
+	.disable_hub_initiated_lpm = 1,
+};
+module_usb_driver(mt7603u_driver);
+
+MODULE_DESCRIPTION("MediaTek MT7603U (USB) wireless driver");
+MODULE_LICENSE("Dual BSD/GPL");

-- 
2.47.3

