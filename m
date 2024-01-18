From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Thu, 18 Jan 2024 11:21:22 +0300
Subject: [PATCH v7 39/39] dma: cirrus: remove platform code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240118-ep93xx-v7-39-d953846ae771@maquefel.me>
References: <20240118-ep93xx-v7-0-d953846ae771@maquefel.me>
In-Reply-To: <20240118-ep93xx-v7-0-d953846ae771@maquefel.me>
To: Vinod Koul <vkoul@kernel.org>, 
 Nikita Shubin <nikita.shubin@maquefel.me>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
Cc: linux-kernel@vger.kernel.org, dmaengine@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705566176; l=6035;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=+yka+X+eKgqo9oTZdvdU7l3LYkjbt/uZxdAkM2+WkI8=;
 b=HzkxEG4zHMIBrSahZa3fa3xysomny3RAZoP9/clSFqjvHLTenc3MeZGD3qS+JIEo/G002ODIGQvd
 ezHJAZiRC1ci55ZmY877tnxj4d017JS8OeO8re6Mku/gTBQOOs29
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove DMA platform header, from now on we use device tree for DMA
clients.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/dma/ep93xx_dma.c                 |  48 ++++++++++++++-
 include/linux/platform_data/dma-ep93xx.h | 100 -------------------------------
 2 files changed, 46 insertions(+), 102 deletions(-)

diff --git a/drivers/dma/ep93xx_dma.c b/drivers/dma/ep93xx_dma.c
index a214680a837d..5c35ffc340d3 100644
--- a/drivers/dma/ep93xx_dma.c
+++ b/drivers/dma/ep93xx_dma.c
@@ -17,6 +17,7 @@
 #include <linux/clk.h>
 #include <linux/init.h>
 #include <linux/interrupt.h>
+#include <linux/dma-mapping.h>
 #include <linux/dmaengine.h>
 #include <linux/module.h>
 #include <linux/mod_devicetable.h>
@@ -25,8 +26,6 @@
 #include <linux/platform_device.h>
 #include <linux/slab.h>
 
-#include <linux/platform_data/dma-ep93xx.h>
-
 #include "dmaengine.h"
 
 /* M2P registers */
@@ -106,6 +105,26 @@
 #define DMA_MAX_CHAN_BYTES		0xffff
 #define DMA_MAX_CHAN_DESCRIPTORS	32
 
+/*
+ * M2P channels.
+ *
+ * Note that these values are also directly used for setting the PPALLOC
+ * register.
+ */
+#define EP93XX_DMA_I2S1			0
+#define EP93XX_DMA_I2S2			1
+#define EP93XX_DMA_AAC1			2
+#define EP93XX_DMA_AAC2			3
+#define EP93XX_DMA_AAC3			4
+#define EP93XX_DMA_I2S3			5
+#define EP93XX_DMA_UART1		6
+#define EP93XX_DMA_UART2		7
+#define EP93XX_DMA_UART3		8
+#define EP93XX_DMA_IRDA			9
+/* M2M channels */
+#define EP93XX_DMA_SSP			10
+#define EP93XX_DMA_IDE			11
+
 enum ep93xx_dma_type {
 	M2P_DMA,
 	M2M_DMA,
@@ -242,6 +261,31 @@ static struct ep93xx_dma_chan *to_ep93xx_dma_chan(struct dma_chan *chan)
 	return container_of(chan, struct ep93xx_dma_chan, chan);
 }
 
+static inline bool ep93xx_dma_chan_is_m2p(struct dma_chan *chan)
+{
+	if (device_is_compatible(chan->device->dev, "cirrus,ep9301-dma-m2p"))
+		return true;
+
+	return !strcmp(dev_name(chan->device->dev), "ep93xx-dma-m2p");
+}
+
+/*
+ * ep93xx_dma_chan_direction - returns direction the channel can be used
+ *
+ * This function can be used in filter functions to find out whether the
+ * channel supports given DMA direction. Only M2P channels have such
+ * limitation, for M2M channels the direction is configurable.
+ */
+static inline enum dma_transfer_direction
+ep93xx_dma_chan_direction(struct dma_chan *chan)
+{
+	if (!ep93xx_dma_chan_is_m2p(chan))
+		return DMA_TRANS_NONE;
+
+	/* even channels are for TX, odd for RX */
+	return (chan->chan_id % 2 == 0) ? DMA_MEM_TO_DEV : DMA_DEV_TO_MEM;
+}
+
 /**
  * ep93xx_dma_set_active - set new active descriptor chain
  * @edmac: channel
diff --git a/include/linux/platform_data/dma-ep93xx.h b/include/linux/platform_data/dma-ep93xx.h
deleted file mode 100644
index 9ec5cdd5a1eb..000000000000
--- a/include/linux/platform_data/dma-ep93xx.h
+++ /dev/null
@@ -1,100 +0,0 @@
-/* SPDX-License-Identifier: GPL-2.0 */
-#ifndef __ASM_ARCH_DMA_H
-#define __ASM_ARCH_DMA_H
-
-#include <linux/types.h>
-#include <linux/device.h>
-#include <linux/dmaengine.h>
-#include <linux/dma-mapping.h>
-#include <linux/property.h>
-#include <linux/string.h>
-
-/*
- * M2P channels.
- *
- * Note that these values are also directly used for setting the PPALLOC
- * register.
- */
-#define EP93XX_DMA_I2S1		0
-#define EP93XX_DMA_I2S2		1
-#define EP93XX_DMA_AAC1		2
-#define EP93XX_DMA_AAC2		3
-#define EP93XX_DMA_AAC3		4
-#define EP93XX_DMA_I2S3		5
-#define EP93XX_DMA_UART1	6
-#define EP93XX_DMA_UART2	7
-#define EP93XX_DMA_UART3	8
-#define EP93XX_DMA_IRDA		9
-/* M2M channels */
-#define EP93XX_DMA_SSP		10
-#define EP93XX_DMA_IDE		11
-
-/**
- * struct ep93xx_dma_data - configuration data for the EP93xx dmaengine
- * @port: peripheral which is requesting the channel
- * @direction: TX/RX channel
- * @name: optional name for the channel, this is displayed in /proc/interrupts
- *
- * This information is passed as private channel parameter in a filter
- * function. Note that this is only needed for slave/cyclic channels.  For
- * memcpy channels %NULL data should be passed.
- */
-struct ep93xx_dma_data {
-	int				port;
-	enum dma_transfer_direction	direction;
-	const char			*name;
-};
-
-/**
- * struct ep93xx_dma_chan_data - platform specific data for a DMA channel
- * @name: name of the channel, used for getting the right clock for the channel
- * @base: mapped registers
- * @irq: interrupt number used by this channel
- */
-struct ep93xx_dma_chan_data {
-	const char			*name;
-	void __iomem			*base;
-	int				irq;
-};
-
-/**
- * struct ep93xx_dma_platform_data - platform data for the dmaengine driver
- * @channels: array of channels which are passed to the driver
- * @num_channels: number of channels in the array
- *
- * This structure is passed to the DMA engine driver via platform data. For
- * M2P channels, contract is that even channels are for TX and odd for RX.
- * There is no requirement for the M2M channels.
- */
-struct ep93xx_dma_platform_data {
-	struct ep93xx_dma_chan_data	*channels;
-	size_t				num_channels;
-};
-
-static inline bool ep93xx_dma_chan_is_m2p(struct dma_chan *chan)
-{
-	if (device_is_compatible(chan->device->dev, "cirrus,ep9301-dma-m2p"))
-		return true;
-
-	return !strcmp(dev_name(chan->device->dev), "ep93xx-dma-m2p");
-}
-
-/**
- * ep93xx_dma_chan_direction - returns direction the channel can be used
- * @chan: channel
- *
- * This function can be used in filter functions to find out whether the
- * channel supports given DMA direction. Only M2P channels have such
- * limitation, for M2M channels the direction is configurable.
- */
-static inline enum dma_transfer_direction
-ep93xx_dma_chan_direction(struct dma_chan *chan)
-{
-	if (!ep93xx_dma_chan_is_m2p(chan))
-		return DMA_TRANS_NONE;
-
-	/* even channels are for TX, odd for RX */
-	return (chan->chan_id % 2 == 0) ? DMA_MEM_TO_DEV : DMA_DEV_TO_MEM;
-}
-
-#endif /* __ASM_ARCH_DMA_H */

-- 
2.41.0

