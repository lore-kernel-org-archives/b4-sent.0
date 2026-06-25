From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 25 Jun 2026 07:10:27 -0500
Subject: [PATCH 2/2] wifi: mt76: mt7996: bound the device EEPROM address
 before the EFUSE copy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-b4-disp-16f99062-v1-2-aee52ecf61b9@proton.me>
References: <20260625-b4-disp-16f99062-v1-0-aee52ecf61b9@proton.me>
In-Reply-To: <20260625-b4-disp-16f99062-v1-0-aee52ecf61b9@proton.me>
To: Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>, Felix Fietkau <nbd@nbd.name>
Cc: Sean Wang <sean.wang@mediatek.com>, linux-mediatek@lists.infradead.org, 
 Shayne Chen <shayne.chen@mediatek.com>, linux-wireless@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782389425; l=1841;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=5P3fKrvZnuhhzy5SyS2bn1gs3Kjjy/aad3X2rpiBcW8=;
 b=TzCsJWAssrI7MlgIxRUv7fUA8WIpBL8zgXK9SEJ+kpD7XCKVFah0X2W0VMmAPNTcyBz8sGKgd
 EwFEZjQZrSUA/ZEhUDno/MD/fCtQkyxLt0J5Z8GlzaSOiITTVCGO6/4
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt7996_mcu_get_eeprom() derives the destination of the EFUSE/EXT block
copy from the address reported by the MCU response (event->addr, a
device-controlled __le32) and clamps only the copy length, never the
destination offset into dev->mt76.eeprom.data. A malicious or
malfunctioning device can report an arbitrary address and drive an
out-of-bounds write of up to MT7996_EXT_EEPROM_BLOCK_SIZE bytes past
eeprom.data.

Reject a response whose address would place the copy outside eeprom.data
before deriving the destination pointer. Devices that echo the requested
in-bounds offset are unaffected.

Fixes: 98686cd21624 ("wifi: mt76: mt7996: add driver for MediaTek Wi-Fi 7 (802.11be) devices")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/net/wireless/mediatek/mt76/mt7996/mcu.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7996/mcu.c b/drivers/net/wireless/mediatek/mt76/mt7996/mcu.c
index f119f023bcd5..01c9adbca68b 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7996/mcu.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7996/mcu.c
@@ -4345,11 +4345,18 @@ int mt7996_mcu_get_eeprom(struct mt7996_dev *dev, u32 offset, u8 *buf, u32 buf_l
 	event = (struct mt7996_mcu_eeprom_access_event *)skb->data;
 	if (event->valid) {
 		u32 ret_len = le32_to_cpu(event->eeprom.ext_eeprom.data_len);
+		u32 block = mode == EEPROM_MODE_EXT ? MT7996_EXT_EEPROM_BLOCK_SIZE :
+						      MT7996_EEPROM_BLOCK_SIZE;
 
 		addr = le32_to_cpu(event->addr);
 
-		if (!buf)
+		if (!buf) {
+			if (addr > dev->mt76.eeprom.size - block) {
+				dev_kfree_skb(skb);
+				return -EINVAL;
+			}
 			buf = (u8 *)dev->mt76.eeprom.data + addr;
+		}
 
 		switch (mode) {
 		case EEPROM_MODE_EFUSE:

-- 
2.43.0

