From: "Jeff C. Jensen" <kernel@nullptr.com>
Date: Thu, 22 Oct 2026 15:11:32 -0700
Subject: [PATCH 3/5] dmaengine: xilinx_dma: Allocate AXI DMA segments in
 ring order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-xilinx-dma-work-v1-3-20faea2e7a80@nullptr.com>
References: <20261022-xilinx-dma-work-v1-0-20faea2e7a80@nullptr.com>
In-Reply-To: <20261022-xilinx-dma-work-v1-0-20faea2e7a80@nullptr.com>
To: Vinod Koul <vkoul@kernel.org>, dmaengine@vger.kernel.org
Cc: Frank Li <Frank.Li@kernel.org>, Michal Simek <michal.simek@amd.com>, 
 Suraj Gupta <suraj.gupta2@amd.com>, 
 Radhey Shyam Pandey <radhey.shyam.pandey@amd.com>, 
 Alex Bereza <alex@bereza.email>, 
 Folker Schwesinger <dev@folker-schwesinger.de>, 
 Tomi Valkeinen <tomi.valkeinen@ideasonboard.com>, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 "Jeff C. Jensen" <kernel@nullptr.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=19100; i=kernel@nullptr.com;
 s=openpgp-2026; h=from:subject:message-id;
 bh=NsertI092Zo2bAaU2iNkZugwSLGIkR067k9+z/BXMVc=;
 b=owGbwMvMwCV2439B4wpuQQ7G02pJDFm3ugK+3lZ+oPp68cF5Nmf+Jqg+LuS8xstYtKnMZ22d/
 7Mnzy7Id5SyMIhxMciKKbIcPzZtZ76tf11R9f0qmDmsTCBDGLg4BWAirnMY/grLX+G9d+/7dUeV
 eTku9g2eV1cmTTkn1OywZk17u5DpxEBGhu/WskVPD97dIBLn0FS+JqA2Xea06nlWpr7/9xbMEVn
 1jB0A
X-Developer-Key: i=kernel@nullptr.com; a=openpgp;
 fpr=C7C696B96F3D4F7E727BDF7AD8FF7081A80B1108
X-Endpoint-Received: by B4 Relay for kernel@nullptr.com/openpgp-2026 with auth_id=1265
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AXI DMA driver builds a static ring of hardware descriptors
(segments) when the channel is allocated, each linked to the next in
pool order, and the engine follows those links.
xilinx_dma_prep_slave_sg() writes no next pointers within a descriptor,
and a descriptor appended while the engine is running is reached through
the next pointer of the previous tail. Segments are handed out from
free_seg_list, so this only works while the free list stays in pool
order.

Commit cee9c863ee68 ("dmaengine: xilinx_dma: Fix hardware buffer
descriptor reuse order") fixed one way the free list falls out of that
order. As the Sashiko review of that patch pointed out [1], others
remain:

 - xilinx_dma_chan_desc_cleanup() drops chan->lock while it runs a
   completion callback, and frees the descriptor afterwards. If the
   channel is terminated in that window, the newer segments are returned
   first and the oldest descriptor's segments end up at the tail of the
   free list.

 - A preparation that runs out of segments returns its partial
   allocation to the tail of the free list, possibly after a completion
   on another CPU has freed newer ones. It does so without taking
   chan->lock, so it can also corrupt the list.

 - A submission rejected because a cyclic transfer is running frees its
   segments while older ones are still in use.

Once the free list and the ring disagree, a later descriptor gets
segments that are not adjacent in the ring, and the engine follows a
next pointer into a cleaned segment with a zero length field. With a
delay added to widen the first window, a receive stream fails right
after a terminate:

  xilinx-vdma 40400000.dma: Channel 7a90d35b has errors 10, cdr 3f053780 tdr 3f059a00

Rather than keeping the free list in order on every path, allocate by
ring position. Count the segments a transaction needs, then reserve that
many consecutive positions, starting at a cursor, under chan->lock: all
of them or none. A bitmap tracks the positions in use. Allocation no
longer depends on the order in which segments are freed, so neither the
terminate path nor the completion path can disturb it. The count uses
xilinx_dma_calc_copysize(), like the preparation loops, so the two
always agree.

The slave-sg, cyclic and dma_vec paths all count and reserve before
building a descriptor, so a failed preparation leaves the channel
unchanged. A submission rejected on a busy cyclic channel cancels its
reservation and rewinds the cursor under the same lock.

This relies on commit 7ed1e3070c9b ("dmaengine: xilinx_dma: Fix hardware
buffer descriptor chain after cyclic DMA") to restore the segment links
after a cyclic transfer. The AXI MCDMA pool keeps its free list and is
not changed.

Link: https://lore.kernel.org/all/20260817094004.A74621F000E9@smtp.kernel.org/ [1]
Fixes: 23059408b6a3 ("dmaengine: xilinx_dma: Fix race condition in the driver for multiple descriptor scenario")
Fixes: c0bba3a99f07 ("dmaengine: vdma: Add Support for Xilinx AXI Direct Memory Access Engine")
Fixes: 92d794dfb699 ("dmaengine: vdma: Add support for cyclic dma mode")
Assisted-by: Claude:claude-fable-5-1
Signed-off-by: Jeff C. Jensen <kernel@nullptr.com>
---
 drivers/dma/xilinx/xilinx_dma.c | 279 ++++++++++++++++++++++++++++++++--------
 1 file changed, 224 insertions(+), 55 deletions(-)

diff --git a/drivers/dma/xilinx/xilinx_dma.c b/drivers/dma/xilinx/xilinx_dma.c
index aa714effd10d..805cd3e2bc27 100644
--- a/drivers/dma/xilinx/xilinx_dma.c
+++ b/drivers/dma/xilinx/xilinx_dma.c
@@ -33,6 +33,7 @@
  *
  */
 
+#include <linux/bitmap.h>
 #include <linux/bitops.h>
 #include <linux/dmapool.h>
 #include <linux/dma/xilinx_dma.h>
@@ -390,7 +391,9 @@ struct xilinx_dma_tx_descriptor {
  * @pending_list: Descriptors waiting
  * @active_list: Descriptors ready to submit
  * @done_list: Complete descriptors
- * @free_seg_list: Free descriptors
+ * @free_seg_list: Free AXI MCDMA descriptors
+ * @seg_used: AXI DMA segments in use, indexed by ring position
+ * @seg_next: Ring position the next AXI DMA reservation starts at
  * @common: DMA common channel
  * @desc_pool: Descriptors pool
  * @dev: The dma device
@@ -430,6 +433,8 @@ struct xilinx_dma_chan {
 	struct list_head active_list;
 	struct list_head done_list;
 	struct list_head free_seg_list;
+	DECLARE_BITMAP(seg_used, XILINX_DMA_NUM_DESCS);
+	u32 seg_next;
 	struct dma_chan common;
 	struct dma_pool *desc_pool;
 	struct device *dev;
@@ -706,30 +711,53 @@ xilinx_cdma_alloc_tx_segment(struct xilinx_dma_chan *chan)
 }
 
 /**
- * xilinx_axidma_alloc_tx_segment - Allocate transaction segment
+ * xilinx_axidma_reserve_segments - Reserve a run of AXI DMA segments
  * @chan: Driver specific DMA channel
+ * @count: Segments needed, at most XILINX_DMA_NUM_DESCS
+ * @start: Ring position of the first reserved segment, set on success
  *
- * Return: The allocated segment on success and NULL on failure.
+ * Reserves @count consecutive ring positions starting at @chan->seg_next,
+ * wrapping at the pool end. The engine fetches descriptors in ring order, so
+ * the run cannot be placed anywhere else.
+ *
+ * Return: 0 on success, -ENOMEM when the run is not free. A failure leaves the
+ * ownership bitmap and @chan->seg_next unchanged.
  */
-static struct xilinx_axidma_tx_segment *
-xilinx_axidma_alloc_tx_segment(struct xilinx_dma_chan *chan)
+static int xilinx_axidma_reserve_segments(struct xilinx_dma_chan *chan,
+					  u32 count, u32 *start)
 {
-	struct xilinx_axidma_tx_segment *segment = NULL;
 	unsigned long flags;
+	int ret = -ENOMEM;
+	u32 i;
 
 	spin_lock_irqsave(&chan->lock, flags);
-	if (!list_empty(&chan->free_seg_list)) {
-		segment = list_first_entry(&chan->free_seg_list,
-					   struct xilinx_axidma_tx_segment,
-					   node);
-		list_del(&segment->node);
+
+	for (i = 0; i < count; i++) {
+		if (test_bit((chan->seg_next + i) % XILINX_DMA_NUM_DESCS,
+			     chan->seg_used))
+			goto out;
 	}
+
+	*start = chan->seg_next;
+	for (i = 0; i < count; i++)
+		__set_bit((chan->seg_next + i) % XILINX_DMA_NUM_DESCS,
+			  chan->seg_used);
+	chan->seg_next = (chan->seg_next + count) % XILINX_DMA_NUM_DESCS;
+	ret = 0;
+
+out:
 	spin_unlock_irqrestore(&chan->lock, flags);
 
-	if (!segment)
-		dev_dbg(chan->dev, "Could not find free tx segment\n");
+	if (ret)
+		dev_dbg(chan->dev, "no run of %u free tx segments\n", count);
 
-	return segment;
+	return ret;
+}
+
+static struct xilinx_axidma_tx_segment *
+xilinx_axidma_run_segment(struct xilinx_dma_chan *chan, u32 start, u32 i)
+{
+	return &chan->seg_v[(start + i) % XILINX_DMA_NUM_DESCS];
 }
 
 /**
@@ -792,13 +820,18 @@ static void xilinx_mcdma_clean_hw_desc(struct xilinx_aximcdma_desc_hw *hw)
  * xilinx_dma_free_tx_segment - Free transaction segment
  * @chan: Driver specific DMA channel
  * @segment: DMA transaction segment
+ *
+ * Called with chan->lock held, so no reservation sees the segment between its
+ * links being restored and its ownership being released.
  */
 static void xilinx_dma_free_tx_segment(struct xilinx_dma_chan *chan,
 				struct xilinx_axidma_tx_segment *segment)
 {
+	lockdep_assert_held(&chan->lock);
+
 	xilinx_dma_clean_hw_desc(chan, segment);
 
-	list_add_tail(&segment->node, &chan->free_seg_list);
+	__clear_bit(segment - chan->seg_v, chan->seg_used);
 }
 
 /**
@@ -902,6 +935,34 @@ xilinx_dma_free_tx_descriptor(struct xilinx_dma_chan *chan,
 	kfree(desc);
 }
 
+/**
+ * xilinx_dma_cancel_tx_descriptor - Discard a descriptor before submission
+ * @chan: Driver specific DMA channel
+ * @desc: Prepared descriptor
+ *
+ * Called with chan->lock held. On an AXI DMA channel, releases the reservation
+ * of @desc and rewinds @chan->seg_next to its first segment, so that no
+ * cleaned segment is left between two live descriptors. @desc must hold the
+ * most recent reservation on the channel.
+ */
+static void xilinx_dma_cancel_tx_descriptor(struct xilinx_dma_chan *chan,
+					    struct xilinx_dma_tx_descriptor *desc)
+{
+	struct xilinx_axidma_tx_segment *first;
+
+	lockdep_assert_held(&chan->lock);
+
+	if (chan->xdev->dma_config->dmatype == XDMA_TYPE_AXIDMA) {
+		first = list_first_entry_or_null(&desc->segments,
+						 struct xilinx_axidma_tx_segment,
+						 node);
+		if (first)
+			chan->seg_next = first - chan->seg_v;
+	}
+
+	xilinx_dma_free_tx_descriptor(chan, desc);
+}
+
 /* Required functions */
 
 /**
@@ -951,10 +1012,6 @@ static void xilinx_dma_free_chan_resources(struct dma_chan *dchan)
 	xilinx_dma_free_descriptors(chan);
 
 	if (chan->xdev->dma_config->dmatype == XDMA_TYPE_AXIDMA) {
-		spin_lock_irqsave(&chan->lock, flags);
-		INIT_LIST_HEAD(&chan->free_seg_list);
-		spin_unlock_irqrestore(&chan->lock, flags);
-
 		/* Free memory that is allocated for BD */
 		dma_free_coherent(chan->dev, sizeof(*chan->seg_v) *
 				  XILINX_DMA_NUM_DESCS, chan->seg_v,
@@ -1195,9 +1252,9 @@ static int xilinx_dma_alloc_chan_resources(struct dma_chan *dchan)
 				((i + 1) % XILINX_DMA_NUM_DESCS));
 			chan->seg_v[i].phys = chan->seg_p +
 				sizeof(*chan->seg_v) * i;
-			list_add_tail(&chan->seg_v[i].node,
-				      &chan->free_seg_list);
 		}
+		bitmap_zero(chan->seg_used, XILINX_DMA_NUM_DESCS);
+		chan->seg_next = 0;
 	} else if (chan->xdev->dma_config->dmatype == XDMA_TYPE_AXIMCDMA) {
 		/* Allocate the buffer descriptors. */
 		chan->seg_mv = dma_alloc_coherent(chan->dev,
@@ -1282,6 +1339,98 @@ static int xilinx_dma_calc_copysize(struct xilinx_dma_chan *chan,
 	return copy;
 }
 
+/**
+ * xilinx_axidma_count_split - Count the descriptors a length splits into
+ * @chan: Driver specific DMA channel
+ * @len: Length in bytes
+ *
+ * Splits @len with xilinx_dma_calc_copysize(), so the count equals the number
+ * of segments a preparation builds for @len. Intermediate chunks are rounded
+ * down for alignment, so the count depends on the channel alignment as well as
+ * on @len.
+ *
+ * Return: The descriptor count, which is zero for a zero length, or -EINVAL if
+ * a split makes no progress or @len needs more descriptors than the pool holds.
+ */
+static int xilinx_axidma_count_split(struct xilinx_dma_chan *chan, size_t len)
+{
+	size_t used = 0;
+	int count = 0;
+
+	while (used < len) {
+		size_t copy = xilinx_dma_calc_copysize(chan, len, used);
+
+		if (!copy || count == XILINX_DMA_NUM_DESCS)
+			return -EINVAL;
+
+		used += copy;
+		count++;
+	}
+
+	return count;
+}
+
+/**
+ * xilinx_axidma_count_sg - Count the descriptors a mapped scatterlist needs
+ * @chan: Driver specific DMA channel
+ * @sgl: Mapped scatterlist
+ * @sg_len: Number of mapped entries in @sgl
+ *
+ * Return: The descriptor count, or -EINVAL if the list splits into no
+ * descriptors at all or into more than the pool holds.
+ */
+static int xilinx_axidma_count_sg(struct xilinx_dma_chan *chan,
+				  struct scatterlist *sgl, unsigned int sg_len)
+{
+	struct scatterlist *sg;
+	unsigned int i;
+	int total = 0;
+
+	for_each_sg(sgl, sg, sg_len, i) {
+		int count = xilinx_axidma_count_split(chan, sg_dma_len(sg));
+
+		if (count < 0 || count > XILINX_DMA_NUM_DESCS - total)
+			return -EINVAL;
+
+		total += count;
+	}
+
+	if (!total)
+		return -EINVAL;
+
+	return total;
+}
+
+/**
+ * xilinx_axidma_count_vecs - Count the descriptors an array of DMA vectors needs
+ * @chan: Driver specific DMA channel
+ * @vecs: DMA vectors
+ * @nb: Entry count
+ *
+ * Return: The descriptor count, or -EINVAL if the vectors split into no
+ * descriptors at all or into more than the pool holds.
+ */
+static int xilinx_axidma_count_vecs(struct xilinx_dma_chan *chan,
+				    const struct dma_vec *vecs, size_t nb)
+{
+	size_t i;
+	int total = 0;
+
+	for (i = 0; i < nb; i++) {
+		int count = xilinx_axidma_count_split(chan, vecs[i].len);
+
+		if (count < 0 || count > XILINX_DMA_NUM_DESCS - total)
+			return -EINVAL;
+
+		total += count;
+	}
+
+	if (!total)
+		return -EINVAL;
+
+	return total;
+}
+
 /**
  * xilinx_dma_tx_status - Get DMA transaction status
  * @dchan: DMA channel
@@ -2050,6 +2199,10 @@ static void append_desc_queue(struct xilinx_dma_chan *chan,
  * xilinx_dma_tx_submit - Submit DMA transaction
  * @tx: Async transaction descriptor
  *
+ * An AXI DMA channel reserves segment runs in ring order, so a transaction must
+ * be submitted, or its rejection handled, before the next one is prepared on
+ * the same channel.
+ *
  * Return: cookie value on success and failure value on error
  */
 static dma_cookie_t xilinx_dma_tx_submit(struct dma_async_tx_descriptor *tx)
@@ -2060,8 +2213,11 @@ static dma_cookie_t xilinx_dma_tx_submit(struct dma_async_tx_descriptor *tx)
 	unsigned long flags;
 	int err;
 
+	spin_lock_irqsave(&chan->lock, flags);
+
 	if (chan->cyclic) {
-		xilinx_dma_free_tx_descriptor(chan, desc);
+		xilinx_dma_cancel_tx_descriptor(chan, desc);
+		spin_unlock_irqrestore(&chan->lock, flags);
 		return -EBUSY;
 	}
 
@@ -2070,13 +2226,13 @@ static dma_cookie_t xilinx_dma_tx_submit(struct dma_async_tx_descriptor *tx)
 		 * If reset fails, need to hard reset the system.
 		 * Channel is no longer functional
 		 */
+		spin_unlock_irqrestore(&chan->lock, flags);
 		err = xilinx_dma_chan_reset(chan);
 		if (err < 0)
 			return err;
+		spin_lock_irqsave(&chan->lock, flags);
 	}
 
-	spin_lock_irqsave(&chan->lock, flags);
-
 	cookie = dma_cookie_assign(tx);
 
 	/* Put this transaction onto the tail of the pending queue */
@@ -2254,15 +2410,26 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_peripheral_dma_vec(
 	struct xilinx_axidma_tx_segment *segment, *head, *prev = NULL;
 	size_t copy;
 	size_t sg_used;
+	u32 start = 0, taken = 0;
 	unsigned int i;
+	int needed;
 
 	if (!is_slave_direction(direction) || direction != chan->direction)
 		return NULL;
 
+	needed = xilinx_axidma_count_vecs(chan, vecs, nb);
+	if (needed < 0)
+		return NULL;
+
 	desc = xilinx_dma_alloc_tx_descriptor(chan);
 	if (!desc)
 		return NULL;
 
+	if (xilinx_axidma_reserve_segments(chan, needed, &start)) {
+		xilinx_dma_free_tx_descriptor(chan, desc);
+		return NULL;
+	}
+
 	dma_async_tx_descriptor_init(&desc->async_tx, &chan->common);
 	desc->async_tx.tx_submit = xilinx_dma_tx_submit;
 
@@ -2274,10 +2441,8 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_peripheral_dma_vec(
 		while (sg_used < vecs[i].len) {
 			struct xilinx_axidma_desc_hw *hw;
 
-			/* Get a free segment */
-			segment = xilinx_axidma_alloc_tx_segment(chan);
-			if (!segment)
-				goto error;
+			segment = xilinx_axidma_run_segment(chan, start,
+							    taken++);
 
 			/*
 			 * Calculate the maximum number of bytes to transfer,
@@ -2305,9 +2470,6 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_peripheral_dma_vec(
 		}
 	}
 
-	if (list_empty(&desc->segments))
-		goto error;
-
 	head = list_first_entry(&desc->segments, struct xilinx_axidma_tx_segment, node);
 	desc->async_tx.phys = head->phys;
 
@@ -2324,10 +2486,6 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_peripheral_dma_vec(
 		desc->async_tx.metadata_ops = &xilinx_dma_metadata_ops;
 
 	return &desc->async_tx;
-
-error:
-	xilinx_dma_free_tx_descriptor(chan, desc);
-	return NULL;
 }
 
 /**
@@ -2353,16 +2511,28 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_slave_sg(
 	struct scatterlist *sg;
 	size_t copy;
 	size_t sg_used;
+	u32 start = 0, taken = 0;
 	unsigned int i;
+	int needed;
 
 	if (!is_slave_direction(direction))
 		return NULL;
 
+	/* reserve exactly the segments the loop below builds */
+	needed = xilinx_axidma_count_sg(chan, sgl, sg_len);
+	if (needed < 0)
+		return NULL;
+
 	/* Allocate a transaction descriptor. */
 	desc = xilinx_dma_alloc_tx_descriptor(chan);
 	if (!desc)
 		return NULL;
 
+	if (xilinx_axidma_reserve_segments(chan, needed, &start)) {
+		xilinx_dma_free_tx_descriptor(chan, desc);
+		return NULL;
+	}
+
 	dma_async_tx_descriptor_init(&desc->async_tx, &chan->common);
 	desc->async_tx.tx_submit = xilinx_dma_tx_submit;
 
@@ -2374,10 +2544,8 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_slave_sg(
 		while (sg_used < sg_dma_len(sg)) {
 			struct xilinx_axidma_desc_hw *hw;
 
-			/* Get a free segment */
-			segment = xilinx_axidma_alloc_tx_segment(chan);
-			if (!segment)
-				goto error;
+			segment = xilinx_axidma_run_segment(chan, start,
+							    taken++);
 
 			/*
 			 * Calculate the maximum number of bytes to transfer,
@@ -2409,9 +2577,6 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_slave_sg(
 		}
 	}
 
-	if (list_empty(&desc->segments))
-		goto error;
-
 	segment = list_first_entry(&desc->segments,
 				   struct xilinx_axidma_tx_segment, node);
 	desc->async_tx.phys = segment->phys;
@@ -2429,10 +2594,6 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_slave_sg(
 		desc->async_tx.metadata_ops = &xilinx_dma_metadata_ops;
 
 	return &desc->async_tx;
-
-error:
-	xilinx_dma_free_tx_descriptor(chan, desc);
-	return NULL;
 }
 
 /**
@@ -2456,7 +2617,8 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_dma_cyclic(
 	struct xilinx_axidma_tx_segment *segment, *head_segment, *prev = NULL;
 	size_t copy, sg_used, periods;
 	unsigned int num_periods;
-	int i;
+	u32 start = 0, taken = 0;
+	int i, per_period;
 	u32 reg;
 
 	if (!period_len)
@@ -2471,11 +2633,24 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_dma_cyclic(
 	if (!is_slave_direction(direction))
 		return NULL;
 
+	/* the division bounds per_period * num_periods without overflow */
+	per_period = xilinx_axidma_count_split(chan, period_len);
+	if (per_period <= 0)
+		return NULL;
+	if ((u32)per_period > XILINX_DMA_NUM_DESCS / num_periods)
+		return NULL;
+
 	/* Allocate a transaction descriptor. */
 	desc = xilinx_dma_alloc_tx_descriptor(chan);
 	if (!desc)
 		return NULL;
 
+	if (xilinx_axidma_reserve_segments(chan, per_period * num_periods,
+					   &start)) {
+		xilinx_dma_free_tx_descriptor(chan, desc);
+		return NULL;
+	}
+
 	chan->direction = direction;
 	dma_async_tx_descriptor_init(&desc->async_tx, &chan->common);
 	desc->async_tx.tx_submit = xilinx_dma_tx_submit;
@@ -2486,10 +2661,8 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_dma_cyclic(
 		while (sg_used < period_len) {
 			struct xilinx_axidma_desc_hw *hw;
 
-			/* Get a free segment */
-			segment = xilinx_axidma_alloc_tx_segment(chan);
-			if (!segment)
-				goto error;
+			segment = xilinx_axidma_run_segment(chan, start,
+							    taken++);
 
 			/*
 			 * Calculate the maximum number of bytes to transfer,
@@ -2537,10 +2710,6 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_dma_cyclic(
 	}
 
 	return &desc->async_tx;
-
-error:
-	xilinx_dma_free_tx_descriptor(chan, desc);
-	return NULL;
 }
 
 /**

-- 
2.43.0

