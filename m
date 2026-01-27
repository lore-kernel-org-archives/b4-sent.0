From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 27 Jan 2026 14:28:26 +0000
Subject: [PATCH 5/5] dma: dma-axi-dmac: gracefully terminate HW cyclic
 transfers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260127-axi-dac-cyclic-support-v1-5-b32daca4b3c7@analog.com>
References: <20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com>
In-Reply-To: <20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com>
To: dmaengine@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769524107; l=7718;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=8CEZSa4VL7GZn2O+RmMjKDO10v/9d1ku83V4UCm+pKI=;
 b=R7nSjQ1Wc/JvnkwO8lnXbspuAu3UOpmCmDtnqd9OlHNjKI/aiSUyR2/vthLZ6s2AUWsfnUEPx
 fc57CS0VQcyAHHjoaju49Tx4UfBpFeeFGAZo6l9sRaB0FgHmqY9lilh
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for gracefully terminating hardware cyclic DMA transfers when
a new transfer is queued and is flagged with DMA_PREP_LOAD_EOT. Without
this, cyclic transfers would continue indefinitely until we brute force
it with .device_terminate_all().

When a new descriptor is queued while a cyclic transfer is active, mark
the cyclic transfer for termination. For hardware with scatter-gather
support, modify the last segment flags to trigger end-of-transfer. For
non-SG hardware, clear the CYCLIC flag to allow natural completion.

Older IP core versions (pre-4.6.a) can prefetch data when clearing the
CYCLIC flag, causing corruption in the next transfer. Work around this
by disabling and re-enabling the core to flush prefetched data.

The cyclic_eot flag tracks transfers marked for termination, preventing
new transfers from starting until the cyclic one completes. Non-EOT
transfers submitted after cyclic transfers are discarded with a warning.

Also note that for hardware cyclic transfers not using SG, we need to
make sure that chan->next_desc is also set to NULL (so we can look at
possible EOT transfers) and we also need to move the queue check to
after axi_dmac_get_next_desc() because with hardware based cyclic
transfers we might get the queue marked as full and hence we would not
be able to check for cyclic termination.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 104 +++++++++++++++++++++++++++++++++++++++------
 1 file changed, 91 insertions(+), 13 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 638625647152..731fa59dc3e7 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -134,6 +134,7 @@ struct axi_dmac_desc {
 	struct axi_dmac_chan *chan;
 
 	bool cyclic;
+	bool cyclic_eot;
 	bool have_partial_xfer;
 
 	unsigned int num_submitted;
@@ -162,6 +163,7 @@ struct axi_dmac_chan {
 	bool hw_cyclic;
 	bool hw_2d;
 	bool hw_sg;
+	bool hw_cyclic_hotfix;
 };
 
 struct axi_dmac {
@@ -227,11 +229,26 @@ static bool axi_dmac_check_addr(struct axi_dmac_chan *chan, dma_addr_t addr)
 	return true;
 }
 
+static struct axi_dmac_desc *axi_dmac_active_desc(struct axi_dmac_chan *chan)
+{
+	return list_first_entry_or_null(&chan->active_descs,
+					struct axi_dmac_desc, vdesc.node);
+}
+
 static struct axi_dmac_desc *axi_dmac_get_next_desc(struct axi_dmac *dmac,
 						    struct axi_dmac_chan *chan)
 {
+	struct axi_dmac_desc *active = axi_dmac_active_desc(chan);
 	struct virt_dma_desc *vdesc;
 	struct axi_dmac_desc *desc;
+	unsigned int val;
+
+	/*
+	 * Just play safe and ignore any SOF if we have an active cyclic transfer
+	 * flagged to end. We'll start it as soon as the current cyclic one ends.
+	 */
+	if (active && active->cyclic_eot)
+		return NULL;
 
 	/*
 	 * It means a SW cyclic transfer is in place so we should just return
@@ -245,11 +262,43 @@ static struct axi_dmac_desc *axi_dmac_get_next_desc(struct axi_dmac *dmac,
 	if (!vdesc)
 		return NULL;
 
+	if (active && active->cyclic && !(vdesc->tx.flags & DMA_PREP_LOAD_EOT)) {
+		struct device *dev = chan_to_axi_dmac(chan)->dma_dev.dev;
+
+		dev_warn(dev, "Discarding non EOT transfer after cyclic\n");
+		list_del(&vdesc->node);
+		return NULL;
+	}
+
 	list_move_tail(&vdesc->node, &chan->active_descs);
 	desc = to_axi_dmac_desc(vdesc);
 	chan->next_desc = desc;
 
-	return desc;
+	if (!active || !active->cyclic)
+		return desc;
+
+	active->cyclic_eot = true;
+
+	if (chan->hw_sg) {
+		unsigned long flags = AXI_DMAC_HW_FLAG_IRQ | AXI_DMAC_HW_FLAG_LAST;
+		/*
+		 * Let's then stop the current cyclic transfer by making sure we
+		 * get an EOT interrupt and to open the cyclic loop by marking
+		 * the last segment.
+		 */
+		active->sg[active->num_sgs - 1].hw->flags = flags;
+		return NULL;
+	}
+
+	/*
+	 * Clear the cyclic bit if there's no Scatter-Gather HW so that we get
+	 * at the end of the transfer.
+	 */
+	val = axi_dmac_read(dmac, AXI_DMAC_REG_FLAGS);
+	val &= ~AXI_DMAC_FLAG_CYCLIC;
+	axi_dmac_write(dmac, AXI_DMAC_REG_FLAGS, val);
+
+	return NULL;
 }
 
 static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
@@ -260,14 +309,14 @@ static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
 	unsigned int flags = 0;
 	unsigned int val;
 
-	val = axi_dmac_read(dmac, AXI_DMAC_REG_START_TRANSFER);
-	if (val) /* Queue is full, wait for the next SOT IRQ */
-		return;
-
 	desc = axi_dmac_get_next_desc(dmac, chan);
 	if (!desc)
 		return;
 
+	val = axi_dmac_read(dmac, AXI_DMAC_REG_START_TRANSFER);
+	if (val) /* Queue is full, wait for the next SOT IRQ */
+		return;
+
 	sg = &desc->sg[desc->num_submitted];
 
 	/* Already queued in cyclic mode. Wait for it to finish */
@@ -309,10 +358,12 @@ static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
 	 * call, enable hw cyclic mode to avoid unnecessary interrupts.
 	 */
 	if (chan->hw_cyclic && desc->cyclic && !desc->vdesc.tx.callback) {
-		if (chan->hw_sg)
+		if (chan->hw_sg) {
 			desc->sg[desc->num_sgs - 1].hw->flags &= ~AXI_DMAC_HW_FLAG_IRQ;
-		else if (desc->num_sgs == 1)
+		} else if (desc->num_sgs == 1) {
+			chan->next_desc = NULL;
 			flags |= AXI_DMAC_FLAG_CYCLIC;
+		}
 	}
 
 	if (chan->hw_partial_xfer)
@@ -330,12 +381,6 @@ static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
 	axi_dmac_write(dmac, AXI_DMAC_REG_START_TRANSFER, 1);
 }
 
-static struct axi_dmac_desc *axi_dmac_active_desc(struct axi_dmac_chan *chan)
-{
-	return list_first_entry_or_null(&chan->active_descs,
-		struct axi_dmac_desc, vdesc.node);
-}
-
 static inline unsigned int axi_dmac_total_sg_bytes(struct axi_dmac_chan *chan,
 	struct axi_dmac_sg *sg)
 {
@@ -425,6 +470,35 @@ static bool axi_dmac_handle_cyclic_eot(struct axi_dmac_chan *chan,
 	/* wrap around */
 	active->num_completed = 0;
 
+	if (active->cyclic_eot) {
+		/*
+		 * It means an HW cyclic transfer was marked to stop. And we
+		 * know we have something to schedule, so start the next
+		 * transfer now the cyclic one is done.
+		 */
+		list_del(&active->vdesc.node);
+		vchan_cookie_complete(&active->vdesc);
+
+		if (chan->hw_cyclic_hotfix) {
+			struct axi_dmac *dmac = chan_to_axi_dmac(chan);
+			/*
+			 * In older IP cores, ending a cyclic transfer by clearing
+			 * the CYCLIC flag does not guarantee a graceful end.
+			 * It can happen that some data (of the next frame) is
+			 * already prefetched and will be wrongly visible in the
+			 * next transfer. To workaround this, we need to reenable
+			 * the core so everything is flushed. Newer cores handles
+			 * this correctly and do not require this "hotfix". The
+			 * SG IP also does not require this.
+			 */
+			dev_dbg(dev, "HW cyclic hotfix\n");
+			axi_dmac_write(dmac, AXI_DMAC_REG_CTRL, 0);
+			axi_dmac_write(dmac, AXI_DMAC_REG_CTRL, AXI_DMAC_CTRL_ENABLE);
+		}
+
+		return true;
+	}
+
 	vdesc = vchan_next_desc(&chan->vchan);
 	if (!vdesc)
 		return false;
@@ -460,6 +534,7 @@ static bool axi_dmac_transfer_done(struct axi_dmac_chan *chan,
 	if (chan->hw_sg) {
 		if (active->cyclic) {
 			vchan_cyclic_callback(&active->vdesc);
+			start_next = axi_dmac_handle_cyclic_eot(chan, active);
 		} else {
 			list_del(&active->vdesc.node);
 			vchan_cookie_complete(&active->vdesc);
@@ -1103,6 +1178,9 @@ static int axi_dmac_detect_caps(struct axi_dmac *dmac, unsigned int version)
 		chan->length_align_mask = chan->address_align_mask;
 	}
 
+	if (version < ADI_AXI_PCORE_VER(4, 6, 'a') && !chan->hw_sg)
+		chan->hw_cyclic_hotfix = true;
+
 	return 0;
 }
 

-- 
2.52.0

