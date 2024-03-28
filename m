From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 28 Mar 2024 14:58:51 +0100
Subject: [PATCH RESEND v3 2/2] dmaengine: axi-dmac: move to device managed
 probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-axi-dmac-devm-probe-v3-2-523c0176df70@analog.com>
References: <20240328-axi-dmac-devm-probe-v3-0-523c0176df70@analog.com>
In-Reply-To: <20240328-axi-dmac-devm-probe-v3-0-523c0176df70@analog.com>
To: dmaengine@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711634330; l=4386;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=rZMNbtxfIMUciFGjv9gWxN1PMrqZXwg7bE9MuSd/GkM=;
 b=ltYrL3ZDkQUalidIP0OLSy4lvmGWEI5JEb/6k2QeuCWc/j/fHJCHhjjvTb1JFOFKTRCfLtY53
 EJb2hWN3CS0D4S5Ey4jAERgh3Qe06xLG5mlI9dgQKW6NRN7YUd5ZmvN
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In axi_dmac_probe(), there's a mix in using device managed APIs and
explicitly cleaning things in the driver .remove() hook. Move to use
device managed APIs and thus drop the .remove() hook.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 78 ++++++++++++++++++++--------------------------
 1 file changed, 34 insertions(+), 44 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index d5a33e4a91b1..bdb752f11869 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -1002,6 +1002,16 @@ static int axi_dmac_detect_caps(struct axi_dmac *dmac, unsigned int version)
 	return 0;
 }
 
+static void axi_dmac_tasklet_kill(void *task)
+{
+	tasklet_kill(task);
+}
+
+static void axi_dmac_free_dma_controller(void *of_node)
+{
+	of_dma_controller_free(of_node);
+}
+
 static int axi_dmac_probe(struct platform_device *pdev)
 {
 	struct dma_device *dma_dev;
@@ -1025,14 +1035,10 @@ static int axi_dmac_probe(struct platform_device *pdev)
 	if (IS_ERR(dmac->base))
 		return PTR_ERR(dmac->base);
 
-	dmac->clk = devm_clk_get(&pdev->dev, NULL);
+	dmac->clk = devm_clk_get_enabled(&pdev->dev, NULL);
 	if (IS_ERR(dmac->clk))
 		return PTR_ERR(dmac->clk);
 
-	ret = clk_prepare_enable(dmac->clk);
-	if (ret < 0)
-		return ret;
-
 	version = axi_dmac_read(dmac, ADI_AXI_REG_VERSION);
 
 	if (version >= ADI_AXI_PCORE_VER(4, 3, 'a'))
@@ -1041,7 +1047,7 @@ static int axi_dmac_probe(struct platform_device *pdev)
 		ret = axi_dmac_parse_dt(&pdev->dev, dmac);
 
 	if (ret < 0)
-		goto err_clk_disable;
+		return ret;
 
 	INIT_LIST_HEAD(&dmac->chan.active_descs);
 
@@ -1072,7 +1078,7 @@ static int axi_dmac_probe(struct platform_device *pdev)
 
 	ret = axi_dmac_detect_caps(dmac, version);
 	if (ret)
-		goto err_clk_disable;
+		return ret;
 
 	dma_dev->copy_align = (dmac->chan.address_align_mask + 1);
 
@@ -1088,57 +1094,42 @@ static int axi_dmac_probe(struct platform_device *pdev)
 		    !AXI_DMAC_DST_COHERENT_GET(ret)) {
 			dev_err(dmac->dma_dev.dev,
 				"Coherent DMA not supported in hardware");
-			ret = -EINVAL;
-			goto err_clk_disable;
+			return -EINVAL;
 		}
 	}
 
-	ret = dma_async_device_register(dma_dev);
+	ret = dmaenginem_async_device_register(dma_dev);
 	if (ret)
-		goto err_clk_disable;
+		return ret;
+
+	/*
+	 * Put the action in here so it get's done before unregistering the DMA
+	 * device.
+	 */
+	ret = devm_add_action_or_reset(&pdev->dev, axi_dmac_tasklet_kill,
+				       &dmac->chan.vchan.task);
+	if (ret)
+		return ret;
 
 	ret = of_dma_controller_register(pdev->dev.of_node,
 		of_dma_xlate_by_chan_id, dma_dev);
 	if (ret)
-		goto err_unregister_device;
+		return ret;
 
-	ret = request_irq(dmac->irq, axi_dmac_interrupt_handler, IRQF_SHARED,
-		dev_name(&pdev->dev), dmac);
+	ret = devm_add_action_or_reset(&pdev->dev, axi_dmac_free_dma_controller,
+				       pdev->dev.of_node);
 	if (ret)
-		goto err_unregister_of;
+		return ret;
 
-	platform_set_drvdata(pdev, dmac);
+	ret = devm_request_irq(&pdev->dev, dmac->irq, axi_dmac_interrupt_handler,
+			       IRQF_SHARED, dev_name(&pdev->dev), dmac);
+	if (ret)
+		return ret;
 
 	regmap = devm_regmap_init_mmio(&pdev->dev, dmac->base,
 		 &axi_dmac_regmap_config);
-	if (IS_ERR(regmap)) {
-		ret = PTR_ERR(regmap);
-		goto err_free_irq;
-	}
 
-	return 0;
-
-err_free_irq:
-	free_irq(dmac->irq, dmac);
-err_unregister_of:
-	of_dma_controller_free(pdev->dev.of_node);
-err_unregister_device:
-	dma_async_device_unregister(&dmac->dma_dev);
-err_clk_disable:
-	clk_disable_unprepare(dmac->clk);
-
-	return ret;
-}
-
-static void axi_dmac_remove(struct platform_device *pdev)
-{
-	struct axi_dmac *dmac = platform_get_drvdata(pdev);
-
-	free_irq(dmac->irq, dmac);
-	of_dma_controller_free(pdev->dev.of_node);
-	tasklet_kill(&dmac->chan.vchan.task);
-	dma_async_device_unregister(&dmac->dma_dev);
-	clk_disable_unprepare(dmac->clk);
+	return PTR_ERR_OR_ZERO(regmap);
 }
 
 static const struct of_device_id axi_dmac_of_match_table[] = {
@@ -1153,7 +1144,6 @@ static struct platform_driver axi_dmac_driver = {
 		.of_match_table = axi_dmac_of_match_table,
 	},
 	.probe = axi_dmac_probe,
-	.remove_new = axi_dmac_remove,
 };
 module_platform_driver(axi_dmac_driver);
 

-- 
2.44.0

