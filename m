From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 23 Nov 2026 00:53:06 +0000
Subject: [PATCH 1/2] dmaengine: at_xdmac: Kill the channel tasklets in
 remove again
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-dma-chancnt-v1-1-f0eea0a4bb63@gmail.com>
References: <20261123-dma-chancnt-v1-0-f0eea0a4bb63@gmail.com>
In-Reply-To: <20261123-dma-chancnt-v1-0-f0eea0a4bb63@gmail.com>
To: vkoul@kernel.org, ludovic.desroches@microchip.com
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Frank.Li@kernel.org, allen.lkml@gmail.com, dave.jiang@intel.com, 
 dmaengine@vger.kernel.org, andriy.shevchenko@linux.intel.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795395185; l=1963;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=0bu2ZG6YjZNYO8i4NTeIpO5xmk3AyoVwzgyIl6x73y0=;
 b=GN+9Tcxa5FdlvNodTuggieGgo/+wwVABpHuK75TugVN8dd466Y8HGsvRXU0on8ZU1XQA21oCK
 S5A7eaMLqmhBmmnCBans7qbDW/+3QfKLdOgtOHH+EXq4UTwUItjv2Rz
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

at_xdmac_remove() kills the channel tasklets and frees the channel
resources in a loop after free_irq():

	for (i = 0; i < atxdmac->dma.chancnt; i++) {
		...
		tasklet_kill(&atchan->tasklet);
		at_xdmac_free_chan_resources(&atchan->chan);
	}

Since commit e81274cd6b52 ("dmaengine: add support to dynamic
register/unregister of channels"), dma_async_device_unregister()
unregisters each channel and decrements dma.chancnt for it, so the
count is 0 by the time the loop runs and the loop does nothing. A
tasklet scheduled by an interrupt can then run after atxdmac, which is
devm-allocated, has been freed.

Read the channel count before unregistering the device.

Found with a static analysis tool and checked by hand.

Fixes: e81274cd6b52 ("dmaengine: add support to dynamic register/unregister of channels")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 drivers/dma/at_xdmac.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/at_xdmac.c b/drivers/dma/at_xdmac.c
index ef0dfe9d37ba..ef4012c22573 100644
--- a/drivers/dma/at_xdmac.c
+++ b/drivers/dma/at_xdmac.c
@@ -2436,6 +2436,8 @@ static int at_xdmac_probe(struct platform_device *pdev)
 static void at_xdmac_remove(struct platform_device *pdev)
 {
 	struct at_xdmac	*atxdmac = (struct at_xdmac *)platform_get_drvdata(pdev);
+	/* dma_async_device_unregister() decrements dma.chancnt to 0 */
+	int		nr_channels = atxdmac->dma.chancnt;
 	int		i;
 
 	at_xdmac_off(atxdmac, true);
@@ -2448,7 +2450,7 @@ static void at_xdmac_remove(struct platform_device *pdev)
 
 	free_irq(atxdmac->irq, atxdmac);
 
-	for (i = 0; i < atxdmac->dma.chancnt; i++) {
+	for (i = 0; i < nr_channels; i++) {
 		struct at_xdmac_chan *atchan = &atxdmac->chan[i];
 
 		tasklet_kill(&atchan->tasklet);

-- 
2.34.1

