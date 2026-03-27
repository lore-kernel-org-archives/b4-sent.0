From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 27 Mar 2026 16:58:40 +0000
Subject: [PATCH v2 3/4] dmaengine: dma-axi-dmac: fix use-after-free on
 unbind
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260327-dma-dmac-handle-vunmap-v2-3-021f95f0e87b@analog.com>
References: <20260327-dma-dmac-handle-vunmap-v2-0-021f95f0e87b@analog.com>
In-Reply-To: <20260327-dma-dmac-handle-vunmap-v2-0-021f95f0e87b@analog.com>
To: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774630718; l=6083;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=wNR0oMrw1rZtsi8jCBNE5cHKX8fscvXjfWhQBVv80wM=;
 b=SKBxoXgda0GYVlhNewidU0+iQyqeuYD43xtQpNKW0k1sukH/ROqnRR76dXCn/DVTduLPpPA4f
 pR1KTZu6VhyCV/5BU7SWgWMUklipVMh4imabMsvPGScJy+mxNaXTQhR
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DMA device lifetime can extend beyond the platform driver unbind if
DMA channels are still referenced by client drivers. This leads to
use-after-free when the devm-managed memory is freed on unbind but the
DMA device callbacks still access it.

Fix this by:
 - Allocating axi_dmac with kzalloc_obj() instead of devm_kzalloc() so
its lifetime is not tied to the platform device.
 - Implementing the device_release callback that so that we can free
the object when reference count gets to 0 (no users).
 - Adding an 'unbound' flag protected by the vchan lock that is set
during driver removal, preventing MMIO accesses after the device has been
unbound.

While at it, explicitly include spinlock.h given it was missing.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 70 +++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 60 insertions(+), 10 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 127c3cf80a0e..70d3ad7e7d37 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -24,6 +24,7 @@
 #include <linux/platform_device.h>
 #include <linux/regmap.h>
 #include <linux/slab.h>
+#include <linux/spinlock.h>
 
 #include <dt-bindings/dma/axi-dmac.h>
 
@@ -174,6 +175,8 @@ struct axi_dmac {
 
 	struct dma_device dma_dev;
 	struct axi_dmac_chan chan;
+
+	bool unbound;
 };
 
 static struct axi_dmac *chan_to_axi_dmac(struct axi_dmac_chan *chan)
@@ -182,6 +185,11 @@ static struct axi_dmac *chan_to_axi_dmac(struct axi_dmac_chan *chan)
 		dma_dev);
 }
 
+static struct axi_dmac *dev_to_axi_dmac(struct dma_device *dev)
+{
+	return container_of(dev, struct axi_dmac, dma_dev);
+}
+
 static struct axi_dmac_chan *to_axi_dmac_chan(struct dma_chan *c)
 {
 	return container_of(c, struct axi_dmac_chan, vchan.chan);
@@ -614,7 +622,12 @@ static int axi_dmac_terminate_all(struct dma_chan *c)
 	LIST_HEAD(head);
 
 	spin_lock_irqsave(&chan->vchan.lock, flags);
-	axi_dmac_write(dmac, AXI_DMAC_REG_CTRL, 0);
+	/*
+	 * Only allow the MMIO access if the device is live. Otherwise still
+	 * go for freeing the descriptors.
+	 */
+	if (!dmac->unbound)
+		axi_dmac_write(dmac, AXI_DMAC_REG_CTRL, 0);
 	chan->next_desc = NULL;
 	vchan_get_all_descriptors(&chan->vchan, &head);
 	list_splice_tail_init(&chan->active_descs, &head);
@@ -642,9 +655,12 @@ static void axi_dmac_issue_pending(struct dma_chan *c)
 	if (chan->hw_sg)
 		ctrl |= AXI_DMAC_CTRL_ENABLE_SG;
 
-	axi_dmac_write(dmac, AXI_DMAC_REG_CTRL, ctrl);
-
 	spin_lock_irqsave(&chan->vchan.lock, flags);
+	if (dmac->unbound) {
+		spin_unlock_irqrestore(&chan->vchan.lock, flags);
+		return;
+	}
+	axi_dmac_write(dmac, AXI_DMAC_REG_CTRL, ctrl);
 	if (vchan_issue_pending(&chan->vchan))
 		axi_dmac_start_transfer(chan);
 	spin_unlock_irqrestore(&chan->vchan.lock, flags);
@@ -1184,6 +1200,14 @@ static int axi_dmac_detect_caps(struct axi_dmac *dmac, unsigned int version)
 	return 0;
 }
 
+static void axi_dmac_release(struct dma_device *dma_dev)
+{
+	struct axi_dmac *dmac = dev_to_axi_dmac(dma_dev);
+
+	put_device(dma_dev->dev);
+	kfree(dmac);
+}
+
 static void axi_dmac_tasklet_kill(void *task)
 {
 	tasklet_kill(task);
@@ -1194,16 +1218,27 @@ static void axi_dmac_free_dma_controller(void *of_node)
 	of_dma_controller_free(of_node);
 }
 
+static void axi_dmac_disable(void *__dmac)
+{
+	struct axi_dmac *dmac = __dmac;
+	unsigned long flags;
+
+	spin_lock_irqsave(&dmac->chan.vchan.lock, flags);
+	dmac->unbound = true;
+	spin_unlock_irqrestore(&dmac->chan.vchan.lock, flags);
+	axi_dmac_write(dmac, AXI_DMAC_REG_CTRL, 0);
+}
+
 static int axi_dmac_probe(struct platform_device *pdev)
 {
 	struct dma_device *dma_dev;
-	struct axi_dmac *dmac;
+	struct axi_dmac *__dmac;
 	struct regmap *regmap;
 	unsigned int version;
 	u32 irq_mask = 0;
 	int ret;
 
-	dmac = devm_kzalloc(&pdev->dev, sizeof(*dmac), GFP_KERNEL);
+	struct axi_dmac *dmac __free(kfree) = kzalloc_obj(struct axi_dmac);
 	if (!dmac)
 		return -ENOMEM;
 
@@ -1251,6 +1286,7 @@ static int axi_dmac_probe(struct platform_device *pdev)
 	dma_dev->dev = &pdev->dev;
 	dma_dev->src_addr_widths = BIT(dmac->chan.src_width);
 	dma_dev->dst_addr_widths = BIT(dmac->chan.dest_width);
+	dma_dev->device_release = axi_dmac_release;
 	dma_dev->directions = BIT(dmac->chan.direction);
 	dma_dev->residue_granularity = DMA_RESIDUE_GRANULARITY_DESCRIPTOR;
 	dma_dev->max_sg_burst = 31; /* 31 SGs maximum in one burst */
@@ -1285,12 +1321,21 @@ static int axi_dmac_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
+	/*
+	 * From this point on, our dmac object has it's lifetime bounded with
+	 * dma_dev. Will be freed when dma_dev refcount goes to 0. That means,
+	 * no more automatic kfree(). Also note that dmac is now NULL so we
+	 * need __dmac.
+	 */
+	__dmac = no_free_ptr(dmac);
+	get_device(&pdev->dev);
+
 	/*
 	 * Put the action in here so it get's done before unregistering the DMA
 	 * device.
 	 */
 	ret = devm_add_action_or_reset(&pdev->dev, axi_dmac_tasklet_kill,
-				       &dmac->chan.vchan.task);
+				       &__dmac->chan.vchan.task);
 	if (ret)
 		return ret;
 
@@ -1304,13 +1349,18 @@ static int axi_dmac_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	ret = devm_request_irq(&pdev->dev, dmac->irq, axi_dmac_interrupt_handler,
-			       IRQF_SHARED, dev_name(&pdev->dev), dmac);
+	/* So that we can mark the device as unbound and disable it */
+	ret = devm_add_action_or_reset(&pdev->dev, axi_dmac_disable, __dmac);
 	if (ret)
 		return ret;
 
-	regmap = devm_regmap_init_mmio(&pdev->dev, dmac->base,
-		 &axi_dmac_regmap_config);
+	ret = devm_request_irq(&pdev->dev, __dmac->irq, axi_dmac_interrupt_handler,
+			       IRQF_SHARED, dev_name(&pdev->dev), __dmac);
+	if (ret)
+		return ret;
+
+	regmap = devm_regmap_init_mmio(&pdev->dev, __dmac->base,
+				       &axi_dmac_regmap_config);
 
 	return PTR_ERR_OR_ZERO(regmap);
 }

-- 
2.53.0

