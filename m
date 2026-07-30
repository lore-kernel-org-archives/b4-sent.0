From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 30 Jul 2026 15:23:12 +0100
Subject: [PATCH 5/9] dmaengine: stm32-dma3: Use bus width capability
 helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260730-dmaengine-support-wider-dma-masks-v1-5-3732f1f9d9ca@analog.com>
References: <20260730-dmaengine-support-wider-dma-masks-v1-0-3732f1f9d9ca@analog.com>
In-Reply-To: <20260730-dmaengine-support-wider-dma-masks-v1-0-3732f1f9d9ca@analog.com>
To: dmaengine@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785421644; l=3022;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=SrN6pXKgJjq+fgxX4MgjxgcirodN9CnJGtz7jAOK/OY=;
 b=v7caWRFl4Ub8kTpVPnVN/3TThYbAzokjyKWpzDqQCyK7xAwJjpqxiGaiKfESL94wMGOw/18kz
 O9qO6GDTCiSAwD6hXFdCOLS0DvJfa3womydBE4ZQOEoGPHQ0agwD24u
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Advertise the controller-wide bus width capabilities through the new
dma_set_src_bus_widths() and dma_set_dst_bus_widths() helpers.

Also update the per-channel capability callback to clear unsupported
widths through the dma_slave_caps helpers so the bitmap and
transitional legacy fields stay in sync.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/stm32/stm32-dma3.c | 32 ++++++++++++++++++++------------
 1 file changed, 20 insertions(+), 12 deletions(-)

diff --git a/drivers/dma/stm32/stm32-dma3.c b/drivers/dma/stm32/stm32-dma3.c
index 4724e7fa0008..b0365a5b341d 100644
--- a/drivers/dma/stm32/stm32-dma3.c
+++ b/drivers/dma/stm32/stm32-dma3.c
@@ -1469,14 +1469,14 @@ static void stm32_dma3_caps(struct dma_chan *c, struct dma_slave_caps *caps)
 
 	if (!chan->fifo_size) {
 		caps->max_burst = 0;
-		caps->src_addr_widths &= ~BIT(DMA_SLAVE_BUSWIDTH_8_BYTES);
-		caps->dst_addr_widths &= ~BIT(DMA_SLAVE_BUSWIDTH_8_BYTES);
+		dma_slave_caps_clear_src_width(caps, DMA_SLAVE_BUSWIDTH_8_BYTES);
+		dma_slave_caps_clear_dst_width(caps, DMA_SLAVE_BUSWIDTH_8_BYTES);
 	} else {
 		/* Burst transfer should not exceed half of the fifo size */
 		caps->max_burst = chan->max_burst;
 		if (caps->max_burst < DMA_SLAVE_BUSWIDTH_8_BYTES) {
-			caps->src_addr_widths &= ~BIT(DMA_SLAVE_BUSWIDTH_8_BYTES);
-			caps->dst_addr_widths &= ~BIT(DMA_SLAVE_BUSWIDTH_8_BYTES);
+			dma_slave_caps_clear_src_width(caps, DMA_SLAVE_BUSWIDTH_8_BYTES);
+			dma_slave_caps_clear_dst_width(caps, DMA_SLAVE_BUSWIDTH_8_BYTES);
 		}
 	}
 }
@@ -1737,6 +1737,12 @@ static int stm32_dma3_probe(struct platform_device *pdev)
 	u32 master_ports, chan_reserved, i, verr;
 	u64 hwcfgr;
 	int ret;
+	enum dma_slave_buswidth stm32_dma3_buswidths[] = {
+		DMA_SLAVE_BUSWIDTH_1_BYTE,
+		DMA_SLAVE_BUSWIDTH_2_BYTES,
+		DMA_SLAVE_BUSWIDTH_4_BYTES,
+		DMA_SLAVE_BUSWIDTH_8_BYTES,
+	};
 
 	ddata = devm_kzalloc(&pdev->dev, sizeof(*ddata), GFP_KERNEL);
 	if (!ddata)
@@ -1775,14 +1781,16 @@ static int stm32_dma3_probe(struct platform_device *pdev)
 	 * channel, and can only access address at even boundaries, multiple of the buswidth.
 	 */
 	dma_dev->copy_align = DMAENGINE_ALIGN_8_BYTES;
-	dma_dev->src_addr_widths = BIT(DMA_SLAVE_BUSWIDTH_1_BYTE) |
-				   BIT(DMA_SLAVE_BUSWIDTH_2_BYTES) |
-				   BIT(DMA_SLAVE_BUSWIDTH_4_BYTES) |
-				   BIT(DMA_SLAVE_BUSWIDTH_8_BYTES);
-	dma_dev->dst_addr_widths = BIT(DMA_SLAVE_BUSWIDTH_1_BYTE) |
-				   BIT(DMA_SLAVE_BUSWIDTH_2_BYTES) |
-				   BIT(DMA_SLAVE_BUSWIDTH_4_BYTES) |
-				   BIT(DMA_SLAVE_BUSWIDTH_8_BYTES);
+	ret = dma_set_src_bus_widths(dma_dev, stm32_dma3_buswidths,
+				     ARRAY_SIZE(stm32_dma3_buswidths));
+	if (ret)
+		return ret;
+
+	ret = dma_set_dst_bus_widths(dma_dev, stm32_dma3_buswidths,
+				     ARRAY_SIZE(stm32_dma3_buswidths));
+	if (ret)
+		return ret;
+
 	dma_dev->directions = BIT(DMA_DEV_TO_MEM) | BIT(DMA_MEM_TO_DEV) | BIT(DMA_MEM_TO_MEM);
 
 	dma_dev->descriptor_reuse = true;

-- 
2.55.0

