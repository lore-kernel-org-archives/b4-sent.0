From: Murad Dadashev <llamapersonaltv@gmail.com>
Date: Fri, 27 Nov 2026 11:35:12 +0300
Subject: [PATCH 01/10] wifi: mt76: mt7603: split core code into
 mt7603-common
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-mt7603u-v1-1-369bee9846f8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795768526; l=6183;
 i=llamapersonaltv@gmail.com; s=20261127; h=from:subject:message-id;
 bh=W2N+5ZLUXvTja8Y897hub4FOC2EwEVpLge1TCsyEDw4=;
 b=o5hEDXEAkl4Jw2g3aB4mVaTHQIOAWtfdirlsY0tTSQw1tRYShBCDvFAXOKyuUn6S5/E7DSerA
 tZH3Q1WKX7cDBDuB3K+HWl5IoRKAKemGZqPJg05OB0GTh9xDR/XbP1G
X-Developer-Key: i=llamapersonaltv@gmail.com; a=ed25519;
 pk=CeMIX207ioWRbMAA6A2GYgT+DpeVlKHVn7I0KjfHeCg=
X-Endpoint-Received: by B4 Relay for llamapersonaltv@gmail.com/20261127 with auth_id=1664
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move everything except the PCIe and SoC glue into a new mt7603-common
module and export the symbols the glue uses. The PCIe/SoC module init
moves from main.c to pci.c.

This prepares for adding a USB driver for MT7603U that shares the core
code, in the same way mt7615-common is shared by the mt7615 and mt7663
bus drivers.

No functional change for MT7603E and MT76x8.

Signed-off-by: Murad Dadashev <llamapersonaltv@gmail.com>
---
 drivers/net/wireless/mediatek/mt76/mt7603/Kconfig  |  6 ++++-
 drivers/net/wireless/mediatek/mt76/mt7603/Makefile | 10 +++++---
 drivers/net/wireless/mediatek/mt76/mt7603/core.c   |  1 +
 drivers/net/wireless/mediatek/mt76/mt7603/init.c   |  3 +++
 drivers/net/wireless/mediatek/mt76/mt7603/main.c   | 30 ++--------------------
 drivers/net/wireless/mediatek/mt76/mt7603/pci.c    | 28 ++++++++++++++++++++
 6 files changed, 45 insertions(+), 33 deletions(-)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/Kconfig b/drivers/net/wireless/mediatek/mt76/mt7603/Kconfig
index ae40a596e49c3e8bbc932bc9a893c293a0945518..dfdd4da15bb0d03843f3d25958cb9391ec7cd54d 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/Kconfig
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/Kconfig
@@ -1,7 +1,11 @@
 # SPDX-License-Identifier: BSD-3-Clause-Clear
+config MT7603_COMMON
+	tristate
+	select MT76_CORE
+
 config MT7603E
 	tristate "MediaTek MT7603E (PCIe) and MT76x8 WLAN support"
-	select MT76_CORE
+	select MT7603_COMMON
 	depends on MAC80211
 	depends on PCI
 	help
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/Makefile b/drivers/net/wireless/mediatek/mt76/mt7603/Makefile
index e954165ee13399cde435382c6e14fb6360818b27..ad2ab9970d51c9a4a3e458dbbfa72379447f6051 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/Makefile
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/Makefile
@@ -1,7 +1,9 @@
 # SPDX-License-Identifier: BSD-3-Clause-Clear
+obj-$(CONFIG_MT7603_COMMON) += mt7603-common.o
 obj-$(CONFIG_MT7603E) += mt7603e.o
 
-mt7603e-y := \
-	pci.o soc.o main.o init.o mcu.o \
-	core.o dma.o mac.o eeprom.o \
-	beacon.o debugfs.o
+mt7603-common-y := \
+	main.o init.o mcu.o core.o dma.o mac.o \
+	eeprom.o beacon.o debugfs.o
+
+mt7603e-y := pci.o soc.o
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/core.c b/drivers/net/wireless/mediatek/mt76/mt7603/core.c
index 9c2943fd904e4cf0a4754eec9d7d31330e96bd7a..a99e4d3156eb94d580fe6b8c262b8f7c19368fb2 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/core.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/core.c
@@ -55,6 +55,7 @@ irqreturn_t mt7603_irq_handler(int irq, void *dev_instance)
 
 	return IRQ_HANDLED;
 }
+EXPORT_SYMBOL_GPL(mt7603_irq_handler);
 
 u32 mt7603_reg_map(struct mt7603_dev *dev, u32 addr)
 {
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/init.c b/drivers/net/wireless/mediatek/mt76/mt7603/init.c
index 218ec406d2a8788ec0d683903652c2cd947de936..d4d631958c56fc0ee54596c5fed7a983fcf0278b 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/init.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/init.c
@@ -20,6 +20,7 @@ const struct mt76_driver_ops mt7603_drv_ops = {
 	.update_survey = mt7603_update_channel,
 	.set_channel = mt7603_set_channel,
 };
+EXPORT_SYMBOL_GPL(mt7603_drv_ops);
 
 static void
 mt7603_set_tmac_template(struct mt7603_dev *dev)
@@ -561,6 +562,7 @@ int mt7603_register_device(struct mt7603_dev *dev)
 
 	return 0;
 }
+EXPORT_SYMBOL_GPL(mt7603_register_device);
 
 void mt7603_unregister_device(struct mt7603_dev *dev)
 {
@@ -570,3 +572,4 @@ void mt7603_unregister_device(struct mt7603_dev *dev)
 	mt7603_dma_cleanup(dev);
 	mt76_free_device(&dev->mt76);
 }
+EXPORT_SYMBOL_GPL(mt7603_unregister_device);
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/main.c b/drivers/net/wireless/mediatek/mt76/mt7603/main.c
index 757664e9e1f20afa8a9f95070b6d57806dc4cc19..be4da5023e439a9e0f3386d1e2140464efad4e94 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/main.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/main.c
@@ -786,33 +786,7 @@ const struct ieee80211_ops mt7603_ops = {
 	.get_antenna = mt76_get_antenna,
 	.set_sar_specs = mt7603_set_sar_specs,
 };
+EXPORT_SYMBOL_GPL(mt7603_ops);
 
-MODULE_DESCRIPTION("MediaTek MT7603E and MT76x8 wireless driver");
+MODULE_DESCRIPTION("MediaTek MT7603 wireless core driver");
 MODULE_LICENSE("Dual BSD/GPL");
-
-static int __init mt7603_init(void)
-{
-	int ret;
-
-	ret = platform_driver_register(&mt76_wmac_driver);
-	if (ret)
-		return ret;
-
-#ifdef CONFIG_PCI
-	ret = pci_register_driver(&mt7603_pci_driver);
-	if (ret)
-		platform_driver_unregister(&mt76_wmac_driver);
-#endif
-	return ret;
-}
-
-static void __exit mt7603_exit(void)
-{
-#ifdef CONFIG_PCI
-	pci_unregister_driver(&mt7603_pci_driver);
-#endif
-	platform_driver_unregister(&mt76_wmac_driver);
-}
-
-module_init(mt7603_init);
-module_exit(mt7603_exit);
diff --git a/drivers/net/wireless/mediatek/mt76/mt7603/pci.c b/drivers/net/wireless/mediatek/mt76/mt7603/pci.c
index 5fee610597a4d7025091391eb516d64a91c1b5ce..f4677586f09ccbcc09bb7817a1d39987ac58c0ca 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7603/pci.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7603/pci.c
@@ -3,6 +3,7 @@
 #include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/pci.h>
+#include <linux/platform_device.h>
 
 #include "mt7603.h"
 
@@ -81,3 +82,30 @@ struct pci_driver mt7603_pci_driver = {
 	.probe		= mt76pci_probe,
 	.remove		= mt76pci_remove,
 };
+
+static int __init mt7603_init(void)
+{
+	int ret;
+
+	ret = platform_driver_register(&mt76_wmac_driver);
+	if (ret)
+		return ret;
+
+	ret = pci_register_driver(&mt7603_pci_driver);
+	if (ret)
+		platform_driver_unregister(&mt76_wmac_driver);
+
+	return ret;
+}
+
+static void __exit mt7603_exit(void)
+{
+	pci_unregister_driver(&mt7603_pci_driver);
+	platform_driver_unregister(&mt76_wmac_driver);
+}
+
+module_init(mt7603_init);
+module_exit(mt7603_exit);
+
+MODULE_DESCRIPTION("MediaTek MT7603E and MT76x8 wireless driver");
+MODULE_LICENSE("Dual BSD/GPL");

-- 
2.47.3

