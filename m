From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 23 Oct 2026 08:50:56 +0000
Subject: [PATCH] dmaengine: amlogic: fix workqueque not free when probe
 failed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-fix-a9-dma-wq-v1-1-b414de837e6e@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAO8f22oC/x2MQQqAIBAAvxJ7bkGNivpKdLDcrT1kpVBB+Pek4
 8DMvBApCEXoixcCXRJl9xl0WcC8Wr8QissMRplGK1Mhy4O2Q7dZvE9sNRPXyjF3E+TmCJSF/ze
 MKX0oPnP1XwAAAA==
X-Change-ID: 20261023-fix-a9-dma-wq-71fef50dff9b
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792745469; l=1430;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=a34YHjJv3kRrPIxLkFWemJns1CaLpsW5MhyikgyybBs=;
 b=QCRqlQC2+0xlvnJkgx367+S7w90kOB7yOCm56pMEQxvQD0+gfGwAahN9MRoK2W7IlDKsEWWX/
 ZlkU+oToRVLB0nm+c2c/Or5rM4MP6aHEyzjfg3I8WJVozpPRuDZLaE/
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

when probe failed, workqueue not free. Convert the driver to use
devm_alloc_ordered_workqueue() for allocating the workqueue. This
ties the workqueue lifetime to the device and removes the need for
explicitly destroying it in the remove callback.

Fixes: b84b5197e344 ("dmaengine: amlogic: Add general DMA driver for A9")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Fix workqueque not free when probe failed.
---
 drivers/dma/amlogic-dma.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/dma/amlogic-dma.c b/drivers/dma/amlogic-dma.c
index 684121d13fca..791bd82743d3 100644
--- a/drivers/dma/amlogic-dma.c
+++ b/drivers/dma/amlogic-dma.c
@@ -620,7 +620,7 @@ static int aml_dma_probe(struct platform_device *pdev)
 	if (!aml_dma)
 		return -ENOMEM;
 
-	aml_dma->free_wq = alloc_ordered_workqueue("aml_dma_free", 0);
+	aml_dma->free_wq = devm_alloc_ordered_workqueue(&pdev->dev, "aml_dma_free", 0);
 	if (!aml_dma->free_wq)
 		return -ENOMEM;
 
@@ -712,7 +712,6 @@ static void aml_dma_remove(struct platform_device *pdev)
 		if (aml_chan)
 			tasklet_kill(&aml_chan->vchan.task);
 	}
-	destroy_workqueue(aml_dma->free_wq);
 }
 
 static const struct of_device_id aml_dma_ids[] = {

---
base-commit: aff5e6a77fc69a7c490246465940d18422d7c631
change-id: 20261023-fix-a9-dma-wq-71fef50dff9b

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

