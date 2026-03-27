From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 27 Mar 2026 16:58:41 +0000
Subject: [PATCH v2 4/4] dmaengine: dma-axi-dmac: Defer freeing DMA
 descriptors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260327-dma-dmac-handle-vunmap-v2-4-021f95f0e87b@analog.com>
References: <20260327-dma-dmac-handle-vunmap-v2-0-021f95f0e87b@analog.com>
In-Reply-To: <20260327-dma-dmac-handle-vunmap-v2-0-021f95f0e87b@analog.com>
To: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, Eliza Balas <eliza.balas@analog.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774630718; l=4336;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=iMbPiK/wOeXYmM5fOnDfGQN+n3bpnujjiiAlZriC4to=;
 b=ta7WMPtxj1EzNdcXn+Q4f3+NDIrTIPaL1n/IM6GuOTrYbw/cY9q/QRd8g71GNM1BDoEnmig7e
 2QWONkYu+2hC/3Aj+K0pwzvmqTwy/0+86nR3TGeyVpxNg4YsZC6xM3f
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Eliza Balas <eliza.balas@analog.com>

This IP core can be used in architectures (like Microblaze) where DMA
descriptors are allocated with vmalloc(). Hence, given that freeing the
descriptors happen in softirq context, vunmpap() will BUG().

To solve the above, we setup a work item during allocation of the
descriptors and schedule in softirq context. Hence, the actual freeing
happens in threaded context.

Also note that to account for the possible race where the struct axi_dmac
object is gone between scheduling the work and actually running it, we
now save and get a reference of struct device when allocating the
descriptor (given that's all we need in axi_dmac_free_desc()) and
release it in axi_dmac_free_desc().

Signed-off-by: Eliza Balas <eliza.balas@analog.com>
Co-developed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 50 ++++++++++++++++++++++++++++++++++------------
 1 file changed, 37 insertions(+), 13 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 70d3ad7e7d37..46f1ead0c7d7 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -25,6 +25,7 @@
 #include <linux/regmap.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
+#include <linux/workqueue.h>
 
 #include <dt-bindings/dma/axi-dmac.h>
 
@@ -133,6 +134,9 @@ struct axi_dmac_sg {
 struct axi_dmac_desc {
 	struct virt_dma_desc vdesc;
 	struct axi_dmac_chan *chan;
+	struct device *dev;
+
+	struct work_struct sched_work;
 
 	bool cyclic;
 	bool cyclic_eot;
@@ -666,6 +670,25 @@ static void axi_dmac_issue_pending(struct dma_chan *c)
 	spin_unlock_irqrestore(&chan->vchan.lock, flags);
 }
 
+static void axi_dmac_free_desc(struct axi_dmac_desc *desc)
+{
+	struct axi_dmac_hw_desc *hw = desc->sg[0].hw;
+	dma_addr_t hw_phys = desc->sg[0].hw_phys;
+
+	dma_free_coherent(desc->dev, PAGE_ALIGN(desc->num_sgs * sizeof(*hw)),
+			  hw, hw_phys);
+	put_device(desc->dev);
+	kfree(desc);
+}
+
+static void axi_dmac_free_desc_schedule_work(struct work_struct *work)
+{
+	struct axi_dmac_desc *desc = container_of(work, struct axi_dmac_desc,
+						  sched_work);
+
+	axi_dmac_free_desc(desc);
+}
+
 static struct axi_dmac_desc *
 axi_dmac_alloc_desc(struct axi_dmac_chan *chan, unsigned int num_sgs)
 {
@@ -681,6 +704,7 @@ axi_dmac_alloc_desc(struct axi_dmac_chan *chan, unsigned int num_sgs)
 		return NULL;
 	desc->num_sgs = num_sgs;
 	desc->chan = chan;
+	desc->dev = get_device(dmac->dma_dev.dev);
 
 	hws = dma_alloc_coherent(dev, PAGE_ALIGN(num_sgs * sizeof(*hws)),
 				&hw_phys, GFP_ATOMIC);
@@ -703,21 +727,18 @@ axi_dmac_alloc_desc(struct axi_dmac_chan *chan, unsigned int num_sgs)
 	/* The last hardware descriptor will trigger an interrupt */
 	desc->sg[num_sgs - 1].hw->flags = AXI_DMAC_HW_FLAG_LAST | AXI_DMAC_HW_FLAG_IRQ;
 
+	/*
+	 * We need to setup a work item because this IP can be used on archs
+	 * that rely on vmalloced memory for descriptors. And given that freeing
+	 * the descriptors happens in softirq context, vunmpap() will BUG().
+	 * Hence, setup the worker so that we can queue it and free the
+	 * descriptor in threaded context.
+	 */
+	INIT_WORK(&desc->sched_work, axi_dmac_free_desc_schedule_work);
+
 	return desc;
 }
 
-static void axi_dmac_free_desc(struct axi_dmac_desc *desc)
-{
-	struct axi_dmac *dmac = chan_to_axi_dmac(desc->chan);
-	struct device *dev = dmac->dma_dev.dev;
-	struct axi_dmac_hw_desc *hw = desc->sg[0].hw;
-	dma_addr_t hw_phys = desc->sg[0].hw_phys;
-
-	dma_free_coherent(dev, PAGE_ALIGN(desc->num_sgs * sizeof(*hw)),
-			  hw, hw_phys);
-	kfree(desc);
-}
-
 static struct axi_dmac_sg *axi_dmac_fill_linear_sg(struct axi_dmac_chan *chan,
 	enum dma_transfer_direction direction, dma_addr_t addr,
 	unsigned int num_periods, unsigned int period_len,
@@ -958,7 +979,10 @@ static void axi_dmac_free_chan_resources(struct dma_chan *c)
 
 static void axi_dmac_desc_free(struct virt_dma_desc *vdesc)
 {
-	axi_dmac_free_desc(to_axi_dmac_desc(vdesc));
+	struct axi_dmac_desc *desc = to_axi_dmac_desc(vdesc);
+
+	/* See the comment in axi_dmac_alloc_desc() for the why! */
+	schedule_work(&desc->sched_work);
 }
 
 static bool axi_dmac_regmap_rdwr(struct device *dev, unsigned int reg)

-- 
2.53.0

