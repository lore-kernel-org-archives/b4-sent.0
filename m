From: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
Date: Wed, 26 Nov 2025 09:36:03 +0100
Subject: [PATCH v2 2/5] dma: mcf-edma: Add per-channel IRQ naming for
 debugging
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251126-dma-coldfire-v2-2-5b1e4544d609@yoseli.org>
References: <20251126-dma-coldfire-v2-0-5b1e4544d609@yoseli.org>
In-Reply-To: <20251126-dma-coldfire-v2-0-5b1e4544d609@yoseli.org>
To: Frank Li <Frank.Li@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Angelo Dureghello <angelo@sysam.it>
Cc: Greg Ungerer <gerg@linux-m68k.org>, imx@lists.linux.dev, 
 dmaengine@vger.kernel.org, linux-m68k@lists.linux-m68k.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764146162; l=2484;
 i=jeanmichel.hautbois@yoseli.org; s=20240925; h=from:subject:message-id;
 bh=TOkFpkS4T7DbH7y0xlolnOAKUy6LY9n/XPRytl2P/DM=;
 b=eXEURz7RQO0BH0cJTkHQf62CHI2X69oRsk8d+iX2tOt9SVdilKka5OtxkRGVOhFlVYbteVbXa
 fHPERnOPFXaDjLqwnSSABn7K2/lG265dpaDWM0d6p5epUVBuRLHSQ4/
X-Developer-Key: i=jeanmichel.hautbois@yoseli.org; a=ed25519;
 pk=MsMTVmoV69wLIlSkHlFoACIMVNQFyvJzvsJSQsn/kq4=
X-Endpoint-Received: by B4 Relay for jeanmichel.hautbois@yoseli.org/20240925 with auth_id=570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add dynamic per-channel IRQ naming to make DMA interrupt identification
easier in /proc/interrupts and debugging tools.

Instead of all channels showing "eDMA", they now show:
- "eDMA-0" through "eDMA-15" for channels 0-15
- "eDMA-16" through "eDMA-55" for channels 16-55
- "eDMA-tx-56" for the shared channel 56-63 interrupt
- "eDMA-err" for the error interrupt

This aids debugging DMA issues by making it clear which channel's
interrupt is being serviced.

Signed-off-by: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
---
 drivers/dma/mcf-edma-main.c | 26 ++++++++++++++++++--------
 1 file changed, 18 insertions(+), 8 deletions(-)

diff --git a/drivers/dma/mcf-edma-main.c b/drivers/dma/mcf-edma-main.c
index f95114829d80..6a7d88895501 100644
--- a/drivers/dma/mcf-edma-main.c
+++ b/drivers/dma/mcf-edma-main.c
@@ -81,8 +81,14 @@ static int mcf_edma_irq_init(struct platform_device *pdev,
 	if (!res)
 		return -1;
 
-	for (ret = 0, i = res->start; i <= res->end; ++i)
-		ret |= request_irq(i, mcf_edma_tx_handler, 0, "eDMA", mcf_edma);
+	for (ret = 0, i = res->start; i <= res->end; ++i) {
+		char *irq_name = devm_kasprintf(&pdev->dev, GFP_KERNEL,
+						"eDMA-%d", (int)(i - res->start));
+		if (!irq_name)
+			return -ENOMEM;
+
+		ret |= request_irq(i, mcf_edma_tx_handler, 0, irq_name, mcf_edma);
+	}
 	if (ret)
 		return ret;
 
@@ -91,23 +97,27 @@ static int mcf_edma_irq_init(struct platform_device *pdev,
 	if (!res)
 		return -1;
 
-	for (ret = 0, i = res->start; i <= res->end; ++i)
-		ret |= request_irq(i, mcf_edma_tx_handler, 0, "eDMA", mcf_edma);
+	for (ret = 0, i = res->start; i <= res->end; ++i) {
+		char *irq_name = devm_kasprintf(&pdev->dev, GFP_KERNEL,
+						"eDMA-%d", (int)(16 + i - res->start));
+		if (!irq_name)
+			return -ENOMEM;
+
+		ret |= request_irq(i, mcf_edma_tx_handler, 0, irq_name, mcf_edma);
+	}
 	if (ret)
 		return ret;
 
 	ret = platform_get_irq_byname(pdev, "edma-tx-56-63");
 	if (ret != -ENXIO) {
-		ret = request_irq(ret, mcf_edma_tx_handler,
-				  0, "eDMA", mcf_edma);
+		ret = request_irq(ret, mcf_edma_tx_handler, 0, "eDMA-tx-56", mcf_edma);
 		if (ret)
 			return ret;
 	}
 
 	ret = platform_get_irq_byname(pdev, "edma-err");
 	if (ret != -ENXIO) {
-		ret = request_irq(ret, mcf_edma_err_handler,
-				  0, "eDMA", mcf_edma);
+		ret = request_irq(ret, mcf_edma_err_handler, 0, "eDMA-err", mcf_edma);
 		if (ret)
 			return ret;
 	}

-- 
2.39.5

