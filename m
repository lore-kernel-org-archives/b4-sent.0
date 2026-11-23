From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 23 Nov 2026 00:53:07 +0000
Subject: [PATCH 2/2] dmaengine: idma64: Kill the channel tasklets in remove
 again
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-dma-chancnt-v1-2-f0eea0a4bb63@gmail.com>
References: <20261123-dma-chancnt-v1-0-f0eea0a4bb63@gmail.com>
In-Reply-To: <20261123-dma-chancnt-v1-0-f0eea0a4bb63@gmail.com>
To: vkoul@kernel.org, ludovic.desroches@microchip.com
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Frank.Li@kernel.org, allen.lkml@gmail.com, dave.jiang@intel.com, 
 dmaengine@vger.kernel.org, andriy.shevchenko@linux.intel.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795395185; l=1951;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=GQuussW5tcaY3AFLXhEILE+dApPEjArrisGtHmyiqFk=;
 b=ji9WRcuHGobYS9nt8jrwgQQ3y9toNeTxMkJ70wG2ign/Yyl02TFW/2ibsbLp6r13W6629PLua
 fsVOoXzy6TrDFRy9TrznW54l/IaQlKsFPoPFz+2vE2QOmQMhZSihUx0
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

idma64_remove() frees the IRQ and then kills the channel tasklets, as
the comment there says, so that no tasklet scheduled by the interrupt
runs after removal:

	for (i = 0; i < idma64->dma.chancnt; i++) {
		...
		tasklet_kill(&idma64c->vchan.task);
	}

Since commit e81274cd6b52 ("dmaengine: add support to dynamic
register/unregister of channels"), dma_async_device_unregister()
unregisters each channel and decrements dma.chancnt for it, so the
count is 0 when this loop runs and no tasklet is killed. A tasklet
scheduled by an interrupt can then run after the devm-allocated idma64
and its channels have been freed.

Read the channel count before unregistering the device.

Found with a static analysis tool and checked by hand.

Fixes: e81274cd6b52 ("dmaengine: add support to dynamic register/unregister of channels")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 drivers/dma/idma64.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/idma64.c b/drivers/dma/idma64.c
index e3db213e564b..5d0df1defb14 100644
--- a/drivers/dma/idma64.c
+++ b/drivers/dma/idma64.c
@@ -604,6 +604,8 @@ static int idma64_probe(struct idma64_chip *chip)
 static void idma64_remove(struct idma64_chip *chip)
 {
 	struct idma64 *idma64 = chip->idma64;
+	/* dma_async_device_unregister() decrements dma.chancnt to 0 */
+	unsigned short nr_chan = idma64->dma.chancnt;
 	unsigned short i;
 
 	dma_async_device_unregister(&idma64->dma);
@@ -614,7 +616,7 @@ static void idma64_remove(struct idma64_chip *chip)
 	 */
 	devm_free_irq(chip->dev, chip->irq, idma64);
 
-	for (i = 0; i < idma64->dma.chancnt; i++) {
+	for (i = 0; i < nr_chan; i++) {
 		struct idma64_chan *idma64c = &idma64->chan[i];
 
 		tasklet_kill(&idma64c->vchan.task);

-- 
2.34.1

