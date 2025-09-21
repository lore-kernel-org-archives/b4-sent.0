From: Max Shevchenko <wctrl@proton.me>
Date: Sun, 21 Sep 2025 14:03:41 +0300
Subject: [PATCH 2/3] dmaengine: mediatek: mtk-uart-apdma: support more than
 33 bits for DMA bitmask
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250921-uart-apdma-v1-2-107543c7102c@proton.me>
References: <20250921-uart-apdma-v1-0-107543c7102c@proton.me>
In-Reply-To: <20250921-uart-apdma-v1-0-107543c7102c@proton.me>
To: Sean Wang <sean.wang@mediatek.com>, Vinod Koul <vkoul@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Long Cheng <long.cheng@mediatek.com>
Cc: dmaengine@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Max Shevchenko <wctrl@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758452646; l=3836;
 i=wctrl@proton.me; s=20250603; h=from:subject:message-id;
 bh=UkczX1bFRaMGp10NOd3W6tGmV9gfRhg9tG4OjCZWL14=;
 b=yoy3rBto0yqvXKa2q7FupadhIQI8nEqoZjvnx8zEMbQXPCJAOktpJ8D7shhNd0fbp7vjXI4c/
 vPHxZcPP8B7A4ETjyPXHjVu6xtFMXg7Je3j5ekWJej3OjSJdyJiXg55
X-Developer-Key: i=wctrl@proton.me; a=ed25519;
 pk=JXUx3mL/OrnRvbK57HXgugBjEBKq4QgDKJqp7BALm74=
X-Endpoint-Received: by B4 Relay for wctrl@proton.me/20250603 with auth_id=421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop mediatek,dma-33bits property and introduce a platform data with
field representing DMA bitmask.

The reference SoCs were taken from the downstream kernel (6.6) for
the MT6991 SoC.

Signed-off-by: Max Shevchenko <wctrl@proton.me>
---
 drivers/dma/mediatek/mtk-uart-apdma.c | 47 +++++++++++++++++++++++++----------
 1 file changed, 34 insertions(+), 13 deletions(-)

diff --git a/drivers/dma/mediatek/mtk-uart-apdma.c b/drivers/dma/mediatek/mtk-uart-apdma.c
index 08e15177427b94246951d38a2a1d76875c1e452e..68dd3a4ee0d88fd508870a5de24ae67505023495 100644
--- a/drivers/dma/mediatek/mtk-uart-apdma.c
+++ b/drivers/dma/mediatek/mtk-uart-apdma.c
@@ -42,6 +42,7 @@
 #define VFF_EN_CLR_B		0
 #define VFF_INT_EN_CLR_B	0
 #define VFF_4G_SUPPORT_CLR_B	0
+#define VFF_ORI_ADDR_BITS_NUM	32
 
 /*
  * interrupt trigger level for tx
@@ -74,10 +75,14 @@
 #define VFF_DEBUG_STATUS	0x50
 #define VFF_4G_SUPPORT		0x54
 
+struct mtk_uart_apdma_data {
+	unsigned int dma_bits;
+};
+
 struct mtk_uart_apdmadev {
 	struct dma_device ddev;
 	struct clk *clk;
-	bool support_33bits;
+	unsigned int support_bits;
 	unsigned int dma_requests;
 };
 
@@ -148,7 +153,7 @@ static void mtk_uart_apdma_start_tx(struct mtk_chan *c)
 		mtk_uart_apdma_write(c, VFF_WPT, 0);
 		mtk_uart_apdma_write(c, VFF_INT_FLAG, VFF_TX_INT_CLR_B);
 
-		if (mtkd->support_33bits)
+		if (mtkd->support_bits > VFF_ORI_ADDR_BITS_NUM)
 			mtk_uart_apdma_write(c, VFF_4G_SUPPORT, VFF_4G_EN_B);
 	}
 
@@ -191,7 +196,7 @@ static void mtk_uart_apdma_start_rx(struct mtk_chan *c)
 		mtk_uart_apdma_write(c, VFF_RPT, 0);
 		mtk_uart_apdma_write(c, VFF_INT_FLAG, VFF_RX_INT_CLR_B);
 
-		if (mtkd->support_33bits)
+		if (mtkd->support_bits > VFF_ORI_ADDR_BITS_NUM)
 			mtk_uart_apdma_write(c, VFF_4G_SUPPORT, VFF_4G_EN_B);
 	}
 
@@ -297,7 +302,7 @@ static int mtk_uart_apdma_alloc_chan_resources(struct dma_chan *chan)
 		goto err_pm;
 	}
 
-	if (mtkd->support_33bits)
+	if (mtkd->support_bits > VFF_ORI_ADDR_BITS_NUM)
 		mtk_uart_apdma_write(c, VFF_4G_SUPPORT, VFF_4G_SUPPORT_CLR_B);
 
 err_pm:
@@ -467,8 +472,27 @@ static void mtk_uart_apdma_free(struct mtk_uart_apdmadev *mtkd)
 	}
 }
 
+static const struct mtk_uart_apdma_data mt6577_data = {
+	.dma_bits = 32
+};
+
+static const struct mtk_uart_apdma_data mt6795_data = {
+	.dma_bits = 33
+};
+
+static const struct mtk_uart_apdma_data mt6779_data = {
+	.dma_bits = 34
+};
+
+static const struct mtk_uart_apdma_data mt6985_data = {
+	.dma_bits = 35
+};
+
 static const struct of_device_id mtk_uart_apdma_match[] = {
-	{ .compatible = "mediatek,mt6577-uart-dma", },
+	{ .compatible = "mediatek,mt6577-uart-dma", .data = &mt6577_data },
+	{ .compatible = "mediatek,mt6795-uart-dma", .data = &mt6795_data },
+	{ .compatible = "mediatek,mt6779-uart-dma", .data = &mt6779_data },
+	{ .compatible = "mediatek,mt6985-uart-dma", .data = &mt6985_data },
 	{ /* sentinel */ },
 };
 MODULE_DEVICE_TABLE(of, mtk_uart_apdma_match);
@@ -477,7 +501,8 @@ static int mtk_uart_apdma_probe(struct platform_device *pdev)
 {
 	struct device_node *np = pdev->dev.of_node;
 	struct mtk_uart_apdmadev *mtkd;
-	int bit_mask = 32, rc;
+	const struct mtk_uart_apdma_data *data;
+	int rc;
 	struct mtk_chan *c;
 	unsigned int i;
 
@@ -492,13 +517,9 @@ static int mtk_uart_apdma_probe(struct platform_device *pdev)
 		return rc;
 	}
 
-	if (of_property_read_bool(np, "mediatek,dma-33bits"))
-		mtkd->support_33bits = true;
-
-	if (mtkd->support_33bits)
-		bit_mask = 33;
-
-	rc = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(bit_mask));
+	data = of_device_get_match_data(&pdev->dev);
+	mtkd->support_bits = data->dma_bits;
+	rc = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(data->dma_bits));
 	if (rc)
 		return rc;
 

-- 
2.51.0

