From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 23 Nov 2026 01:17:37 +0000
Subject: [PATCH v2 1/2] dmaengine: at_xdmac: Kill the channel tasklets
 before unregistering
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-dma-chancnt-v2-1-241b1672883e@gmail.com>
References: <20261123-dma-chancnt-v2-0-241b1672883e@gmail.com>
In-Reply-To: <20261123-dma-chancnt-v2-0-241b1672883e@gmail.com>
To: ludovic.desroches@microchip.com, vkoul@kernel.org
Cc: Frank.Li@kernel.org, dave.jiang@intel.com, linux-kernel@vger.kernel.org, 
 andriy.shevchenko@linux.intel.com, dmaengine@vger.kernel.org, 
 allen.lkml@gmail.com, linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795396657; l=2983;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=37CrXOmHngl8hduNk3ISIljXPc21J8blRcQ8FE7hl2Y=;
 b=xRJ6Jxg/MhAl8yKoKVPpMjDP/LVLwP5ZpBd/diE5bv3dkjKDbpzQCVIlWfz7HhwBjyX63FBkB
 /MZbutFOEfxCVN5Mx/JaIOV72KLvp6HbenUm+7kfvvRMGTQwAVNw7pH
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

at_xdmac_remove() unregisters the DMA device and disables the clock,
and only then frees the IRQ and kills the channel tasklets in a loop
over dma.chancnt:

	dma_async_device_unregister(&atxdmac->dma);
	...
	clk_disable_unprepare(atxdmac->clk);

	free_irq(atxdmac->irq, atxdmac);

	for (i = 0; i < atxdmac->dma.chancnt; i++) {
		...
		tasklet_kill(&atchan->tasklet);
		at_xdmac_free_chan_resources(&atchan->chan);
	}

Since commit e81274cd6b52 ("dmaengine: add support to dynamic
register/unregister of channels"), dma_async_device_unregister()
unregisters each channel and decrements dma.chancnt for it, so the
loop does nothing and a tasklet scheduled by an interrupt can run after
the devm-allocated atxdmac has been freed. Even when the loop ran,
tasklet_kill() let a pending tasklet run after the channel devices
were freed and the clock was disabled, and the tasklet reads the
channel registers and logs through the channel device.

Free the IRQ, kill the tasklets and free the channel resources right
after at_xdmac_off(), before the channels are unregistered and the
clock is disabled.

Found with a static analysis tool and checked by hand.

Fixes: e1f7c9eee707 ("dmaengine: at_xdmac: creation of the atmel eXtended DMA Controller driver")
Fixes: e81274cd6b52 ("dmaengine: add support to dynamic register/unregister of channels")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 drivers/dma/at_xdmac.c | 19 ++++++++++++-------
 1 file changed, 12 insertions(+), 7 deletions(-)

diff --git a/drivers/dma/at_xdmac.c b/drivers/dma/at_xdmac.c
index ef0dfe9d37ba..d5d60f3d3543 100644
--- a/drivers/dma/at_xdmac.c
+++ b/drivers/dma/at_xdmac.c
@@ -2439,21 +2439,26 @@ static void at_xdmac_remove(struct platform_device *pdev)
 	int		i;
 
 	at_xdmac_off(atxdmac, true);
-	of_dma_controller_free(pdev->dev.of_node);
-	dma_async_device_unregister(&atxdmac->dma);
-	pm_runtime_disable(atxdmac->dev);
-	pm_runtime_set_suspended(&pdev->dev);
-	pm_runtime_dont_use_autosuspend(&pdev->dev);
-	clk_disable_unprepare(atxdmac->clk);
-
 	free_irq(atxdmac->irq, atxdmac);
 
+	/*
+	 * Do this before dma_async_device_unregister(): it frees the channel
+	 * devices and decrements dma.chancnt, and the tasklets also need the
+	 * clock.
+	 */
 	for (i = 0; i < atxdmac->dma.chancnt; i++) {
 		struct at_xdmac_chan *atchan = &atxdmac->chan[i];
 
 		tasklet_kill(&atchan->tasklet);
 		at_xdmac_free_chan_resources(&atchan->chan);
 	}
+
+	of_dma_controller_free(pdev->dev.of_node);
+	dma_async_device_unregister(&atxdmac->dma);
+	pm_runtime_disable(atxdmac->dev);
+	pm_runtime_set_suspended(&pdev->dev);
+	pm_runtime_dont_use_autosuspend(&pdev->dev);
+	clk_disable_unprepare(atxdmac->clk);
 }
 
 static const struct dev_pm_ops __maybe_unused atmel_xdmac_dev_pm_ops = {

-- 
2.34.1

