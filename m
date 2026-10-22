From: "Jeff C. Jensen" <kernel@nullptr.com>
Date: Thu, 22 Oct 2026 15:11:34 -0700
Subject: [PATCH 5/5] dmaengine: xilinx_dma: Recover a withheld AXI DMA
 channel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-xilinx-dma-work-v1-5-20faea2e7a80@nullptr.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=7679; i=kernel@nullptr.com;
 s=openpgp-2026; h=from:subject:message-id;
 bh=xlPzA8YaYP6zTl1aM/8+oHxlsSaaMtEj6m2Ol3kOyIY=;
 b=owGbwMvMwCV2439B4wpuQQ7G02pJDFm3ugIMRP8+vGK5f3+CzLZlXAemde4SdpLKvnGRSZcvS
 fDTms82HaUsDGJcDLJiiizHj03bmW/rX1dUfb8KZg4rE8gQBi5OAZhIow3Df2eHSf2qG1bKTWS2
 XTe/49xjn/3LNGSvF1XGCp9K+3X5rQAjw6qEH6L8b2e97bE+/spx4cycG96OzdNfHenQsnws+Gi
 NAgsA
X-Developer-Key: i=kernel@nullptr.com; a=openpgp;
 fpr=C7C696B96F3D4F7E727BDF7AD8FF7081A80B1108
X-Endpoint-Received: by B4 Relay for kernel@nullptr.com/openpgp-2026 with auth_id=1265
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A channel withheld by the previous patch keeps its descriptors, segment
reservations and descriptor memory for as long as it exists, because
nothing has shown that the engine stopped.

Recover it in the two steps the dmaengine API already separates. A
terminate halts and resets the channel, and a reset that completes is
taken as proof that the engine no longer fetches descriptors or writes
data. The withheld descriptors are freed later, from
xilinx_dma_synchronize() after the completion tasklet has been killed,
because a completion pass may be running a callback with the lock
dropped while the terminate runs, and a cyclic completion keeps its
descriptor on the list for the whole callback. Until then the channel
stays withheld and refuses new work.

The two steps have to stay apart because xilinx_dma_chan_reset() is not
purely a hardware operation: on success it clears chan->err, marks the
channel idle and enables interrupts. It is chan->quarantined, not
chan->err, that keeps every start path closed until synchronize,
including the one in the interrupt handler.

After synchronize the quarantine list is empty, the error and cyclic
state are cleared, the counters are zero and the channel is idle. The
ownership bitmap keeps only the reservations of descriptors that still
exist, and chan->seg_next keeps its position, since the engine fetches
next from wherever the last tail pointed. A client that terminates with
dmaengine_terminate_async() and never synchronizes leaves the channel
reset but still withheld.

Recovery is refused when this driver instance also manages the other
channel of the engine. An AXI DMA soft reset acts on the whole engine,
so it would reset that channel too and clear its interrupt enables,
which the driver does not coordinate, as
commit a17ce4bc6f4f ("dmaengine: xilinx_dma: Fix reset related timeout
with two-channel AXIDMA") describes. This patch handles single-channel
controllers; a withheld two-channel controller stays withheld.

A failed halt before a reset that completes is ignored, since the reset
is what stops the engine. If the reset fails again, the channel stays
withheld with all its reservations.

Assisted-by: Claude:claude-fable-5-1
Signed-off-by: Jeff C. Jensen <kernel@nullptr.com>
---
 drivers/dma/xilinx/xilinx_dma.c | 106 +++++++++++++++++++++++++++++++++++++++-
 1 file changed, 105 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/xilinx/xilinx_dma.c b/drivers/dma/xilinx/xilinx_dma.c
index 0316c6e7881f..c72c0fc985c5 100644
--- a/drivers/dma/xilinx/xilinx_dma.c
+++ b/drivers/dma/xilinx/xilinx_dma.c
@@ -394,6 +394,8 @@ struct xilinx_dma_tx_descriptor {
  * @quarantine_list: Descriptors withheld after a reset that did not complete
  * @quarantined: The reset did not complete; the channel is withheld and takes
  *	no work
+ * @quiesced: The engine completed a reset while the channel was withheld;
+ *	xilinx_dma_synchronize() reclaims the descriptors
  * @free_seg_list: Free AXI MCDMA descriptors
  * @seg_used: AXI DMA segments in use, indexed by ring position
  * @seg_next: Ring position the next AXI DMA reservation starts at
@@ -437,6 +439,7 @@ struct xilinx_dma_chan {
 	struct list_head done_list;
 	struct list_head quarantine_list;
 	bool quarantined;
+	bool quiesced;
 	struct list_head free_seg_list;
 	DECLARE_BITMAP(seg_used, XILINX_DMA_NUM_DESCS);
 	u32 seg_next;
@@ -2917,12 +2920,109 @@ xilinx_mcdma_prep_slave_sg(struct dma_chan *dchan, struct scatterlist *sgl,
 	return NULL;
 }
 
+/**
+ * xilinx_dma_reset_is_isolated - Report whether a reset disturbs only this channel
+ * @chan: Driver specific DMA channel
+ *
+ * An AXI DMA soft reset acts on the whole engine, so resetting one channel of a
+ * two-channel controller also resets the other and clears its interrupt enables.
+ *
+ * Return: true when this driver instance manages no other channel of the
+ * engine.
+ */
+static bool xilinx_dma_reset_is_isolated(struct xilinx_dma_chan *chan)
+{
+	struct xilinx_dma_device *xdev = chan->xdev;
+	int i;
+
+	for (i = 0; i < xdev->dma_config->max_channels; i++) {
+		if (xdev->chan[i] && xdev->chan[i] != chan)
+			return false;
+	}
+
+	return true;
+}
+
+/**
+ * xilinx_dma_reset_withheld_channel - Stop the engine behind a withheld channel
+ * @chan: Driver specific DMA channel
+ *
+ * A completed reset shows that the engine no longer fetches descriptors or
+ * writes payload. The channel stays withheld until xilinx_dma_recover_channel()
+ * reclaims its descriptors. A failure leaves the channel withheld with its
+ * reservations intact.
+ *
+ * Return: 0 when the reset completed, negative otherwise.
+ */
+static int xilinx_dma_reset_withheld_channel(struct xilinx_dma_chan *chan)
+{
+	unsigned long flags;
+	int err;
+
+	if (!xilinx_dma_reset_is_isolated(chan)) {
+		dev_err(chan->dev,
+			"channel %p stays withheld: a reset would disturb the other channel\n",
+			chan);
+		return -EBUSY;
+	}
+
+	err = chan->stop_transfer(chan);
+	if (err)
+		dev_dbg(chan->dev, "channel %p did not halt before its reset\n", chan);
+
+	err = xilinx_dma_chan_reset(chan);
+	if (err) {
+		dev_err(chan->dev, "channel %p stays withheld: reset failed again\n", chan);
+		return err;
+	}
+
+	spin_lock_irqsave(&chan->lock, flags);
+	chan->quiesced = true;
+	spin_unlock_irqrestore(&chan->lock, flags);
+
+	return 0;
+}
+
+/**
+ * xilinx_dma_recover_channel - Return a withheld channel to service
+ * @chan: Driver specific DMA channel
+ *
+ * Must run after the completion tasklet has been killed, so that no completion
+ * pass holds a withheld descriptor. Frees the withheld descriptors, which
+ * restores their segment links and releases their reservations, and returns
+ * the channel to idle with no error, so it takes work again. Does nothing
+ * unless the engine was reset after the channel was withheld.
+ */
+static void xilinx_dma_recover_channel(struct xilinx_dma_chan *chan)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&chan->lock, flags);
+	if (!chan->quarantined || !chan->quiesced) {
+		spin_unlock_irqrestore(&chan->lock, flags);
+		return;
+	}
+	xilinx_dma_free_desc_list(chan, &chan->quarantine_list);
+	chan->quarantined = false;
+	chan->quiesced = false;
+	chan->cyclic = false;
+	chan->err = false;
+	chan->idle = true;
+	chan->desc_pendingcount = 0;
+	chan->desc_submitcount = 0;
+	spin_unlock_irqrestore(&chan->lock, flags);
+
+	dev_info(chan->dev, "channel %p recovered\n", chan);
+}
+
 /**
  * xilinx_dma_terminate_all - Halt the channel and free descriptors
  * @dchan: Driver specific DMA Channel pointer
  *
  * Return: 0, or the reset error when an AXI DMA reset does not complete, in
- * which case every channel of the engine is withheld with its descriptors.
+ * which case every channel of the engine is withheld with its descriptors. On
+ * a channel that is already withheld, the result of resetting the engine;
+ * xilinx_dma_synchronize() then reclaims the descriptors.
  */
 static int xilinx_dma_terminate_all(struct dma_chan *dchan)
 {
@@ -2930,6 +3030,9 @@ static int xilinx_dma_terminate_all(struct dma_chan *dchan)
 	u32 reg;
 	int err;
 
+	if (xilinx_dma_chan_quarantined(chan))
+		return xilinx_dma_reset_withheld_channel(chan);
+
 	if (!chan->cyclic) {
 		err = chan->stop_transfer(chan);
 		if (err) {
@@ -2970,6 +3073,7 @@ static void xilinx_dma_synchronize(struct dma_chan *dchan)
 	struct xilinx_dma_chan *chan = to_xilinx_chan(dchan);
 
 	tasklet_kill(&chan->tasklet);
+	xilinx_dma_recover_channel(chan);
 }
 
 /**

-- 
2.43.0

