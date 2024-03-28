From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 28 Mar 2024 14:58:50 +0100
Subject: [PATCH RESEND v3 1/2] dmaengine: axi-dmac: fix possible race in
 remove()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-axi-dmac-devm-probe-v3-1-523c0176df70@analog.com>
References: <20240328-axi-dmac-devm-probe-v3-0-523c0176df70@analog.com>
In-Reply-To: <20240328-axi-dmac-devm-probe-v3-0-523c0176df70@analog.com>
To: dmaengine@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 stable@kernel.org, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711634330; l=1009;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=m/nVB/GHu63PsHeHmrvMcm3xYLKhYW2M+gPJ1lkwwxc=;
 b=fUST6TEWfOIHe8oSkiiusWOFv1fApQMemIL6ukXrAQcXQsFt82KSWhj6wsbAZ80FBz5XbhuZm
 hZT5QIXkHknBGq6M9zrn/8kz3CCFt2Ett72qdWRdzkcCpoieoGq9kVA
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We need to first free the IRQ before calling of_dma_controller_free().
Otherwise we could get an interrupt and schedule a tasklet while
removing the DMA controller.

Fixes: 0e3b67b348b8 ("dmaengine: Add support for the Analog Devices AXI-DMAC DMA controller")
Cc: stable@kernel.org
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 4e339c04fc1e..d5a33e4a91b1 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -1134,8 +1134,8 @@ static void axi_dmac_remove(struct platform_device *pdev)
 {
 	struct axi_dmac *dmac = platform_get_drvdata(pdev);
 
-	of_dma_controller_free(pdev->dev.of_node);
 	free_irq(dmac->irq, dmac);
+	of_dma_controller_free(pdev->dev.of_node);
 	tasklet_kill(&dmac->chan.vchan.task);
 	dma_async_device_unregister(&dmac->dma_dev);
 	clk_disable_unprepare(dmac->clk);

-- 
2.44.0

