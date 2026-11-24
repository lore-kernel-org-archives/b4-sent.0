From: Sai Sree Kartheek Adivi <s-adivi@ti.com>
Date: Tue, 24 Nov 2026 17:15:10 +0530
Subject: [PATCH v13 08/20] dmaengine: ti: k3-udma: move udma utility
 functions to k3-udma-common.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-dma-upstream-v13-v13-8-bd4251fdc6d4@ti.com>
References: <20261124-dma-upstream-v13-v13-0-bd4251fdc6d4@ti.com>
In-Reply-To: <20261124-dma-upstream-v13-v13-0-bd4251fdc6d4@ti.com>
To: Vignesh Raghavendra <vigneshr@ti.com>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, Peter Ujfalusi <peter.ujfalusi@ti.com>, 
 Nishanth Menon <nm@ti.com>, Santosh Shilimkar <ssantosh@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 sebin.francis@ti.com, Sai Sree Kartheek Adivi <s-adivi@ti.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795520723; l=37422;
 i=s-adivi@ti.com; s=20261124; h=from:subject:message-id;
 bh=/YW6EEhS8jN1IBDSfkByy4e6AH8jRs9IZZpamrneGtQ=;
 b=U9sRat7M3AesozsqpFEXd8JOgCAmoAvlBLVgDE/aEcMCjRCBvo2L8pHR4qKREiGz3r06S1BQG
 hqTim7SNxBuDULeE15d24M6RiG5u6IHQJb6knKdnLJlvpI61z9rpTTG
X-Developer-Key: i=s-adivi@ti.com; a=ed25519;
 pk=EtOwVxmXDuYMgw3DqFtPDBpf8ZvbO89w1fJm4w5yPI8=
X-Endpoint-Received: by B4 Relay for s-adivi@ti.com/20261124 with auth_id=1627
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Relocate udma utility functions from k3-udma.c to k3-udma-common.c file.

The implementation of these functions is largely shared between K3 UDMA
and K3 UDMA v2. This refactor improves code reuse and maintainability
across multiple variants.

No functional changes intended.

Signed-off-by: Sai Sree Kartheek Adivi <s-adivi@ti.com>
---
 drivers/dma/ti/k3-udma-common.c | 556 +++++++++++++++++++++++++++++++++++++++-
 drivers/dma/ti/k3-udma.c        | 531 --------------------------------------
 drivers/dma/ti/k3-udma.h        |  31 ++-
 3 files changed, 580 insertions(+), 538 deletions(-)

diff --git a/drivers/dma/ti/k3-udma-common.c b/drivers/dma/ti/k3-udma-common.c
index c9cbe93f2391d..54b95490a56a7 100644
--- a/drivers/dma/ti/k3-udma-common.c
+++ b/drivers/dma/ti/k3-udma-common.c
@@ -4,6 +4,7 @@
  *  Author: Peter Ujfalusi <peter.ujfalusi@ti.com>
  */
 
+#include <linux/delay.h>
 #include <linux/dmaengine.h>
 #include <linux/dma-mapping.h>
 #include <linux/dmapool.h>
@@ -54,6 +55,28 @@ struct udma_desc *udma_udma_desc_from_paddr(struct udma_chan *uc,
 }
 EXPORT_SYMBOL_GPL(udma_udma_desc_from_paddr);
 
+void udma_start_desc(struct udma_chan *uc)
+{
+	struct udma_chan_config *ucc = &uc->config;
+
+	if (uc->ud->match_data->type == DMA_TYPE_UDMA && ucc->pkt_mode &&
+	    (uc->cyclic || ucc->dir == DMA_DEV_TO_MEM)) {
+		int i;
+
+		/*
+		 * UDMA only: Push all descriptors to ring for packet mode
+		 * cyclic or RX
+		 * PKTDMA supports pre-linked descriptor and cyclic is not
+		 * supported
+		 */
+		for (i = 0; i < uc->desc->sglen; i++)
+			udma_push_to_ring(uc, i);
+	} else {
+		udma_push_to_ring(uc, 0);
+	}
+}
+EXPORT_SYMBOL_GPL(udma_start_desc);
+
 static void udma_free_hwdesc(struct udma_chan *uc, struct udma_desc *d)
 {
 	if (uc->use_dma_pool) {
@@ -1205,9 +1228,9 @@ udma_prep_dma_memcpy(struct dma_chan *chan, dma_addr_t dest, dma_addr_t src,
 }
 EXPORT_SYMBOL_GPL(udma_prep_dma_memcpy);
 
-void udma_desc_pre_callback(struct virt_dma_chan *vc,
-			    struct virt_dma_desc *vd,
-			    struct dmaengine_result *result)
+static void udma_desc_pre_callback(struct virt_dma_chan *vc,
+				   struct virt_dma_desc *vd,
+				   struct dmaengine_result *result)
 {
 	struct udma_chan *uc = to_udma_chan(&vc->chan);
 	struct udma_desc *d;
@@ -1244,7 +1267,6 @@ void udma_desc_pre_callback(struct virt_dma_chan *vc,
 		}
 	}
 }
-EXPORT_SYMBOL_GPL(udma_desc_pre_callback);
 
 int udma_push_to_ring(struct udma_chan *uc, int idx)
 {
@@ -1349,5 +1371,531 @@ void udma_reset_rings(struct udma_chan *uc)
 }
 EXPORT_SYMBOL_GPL(udma_reset_rings);
 
+u8 udma_get_chan_tpl_index(struct udma_tpl *tpl_map, int chan_id)
+{
+	int i;
+
+	for (i = 0; i < tpl_map->levels; i++) {
+		if (chan_id >= tpl_map->start_idx[i])
+			return i;
+	}
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(udma_get_chan_tpl_index);
+
+void k3_configure_chan_coherency(struct dma_chan *chan, u32 asel)
+{
+	struct device *chan_dev = dmaengine_chan_dev(chan);
+
+	if (asel == 0) {
+		/* No special handling for the channel */
+		chan->chan_dev->chan_dma_dev = false;
+
+		dev_clear_dma_coherent(chan_dev);
+		chan_dev->dma_parms = NULL;
+	} else if (asel == 14 || asel == 15) {
+		chan->chan_dev->chan_dma_dev = true;
+
+		dev_set_dma_coherent(chan_dev);
+		dma_coerce_mask_and_coherent(chan_dev, DMA_BIT_MASK(48));
+		chan_dev->dma_parms = chan_dev->parent->dma_parms;
+	} else {
+		dev_warn(chan->device->dev, "Invalid ASEL value: %u\n", asel);
+
+		dev_clear_dma_coherent(chan_dev);
+		chan_dev->dma_parms = NULL;
+	}
+}
+EXPORT_SYMBOL_GPL(k3_configure_chan_coherency);
+
+void udma_reset_uchan(struct udma_chan *uc)
+{
+	memset(&uc->config, 0, sizeof(uc->config));
+	uc->config.remote_thread_id = -1;
+	uc->config.mapped_channel_id = -1;
+	uc->config.default_flow_id = -1;
+	uc->state = UDMA_CHAN_IS_IDLE;
+}
+EXPORT_SYMBOL_GPL(udma_reset_uchan);
+
+void udma_dump_chan_stdata(struct udma_chan *uc)
+{
+	struct device *dev = uc->ud->dev;
+	u32 offset;
+	int i;
+
+	if (uc->config.dir == DMA_MEM_TO_DEV || uc->config.dir == DMA_MEM_TO_MEM) {
+		dev_dbg(dev, "TCHAN State data:\n");
+		for (i = 0; i < 32; i++) {
+			offset = UDMA_CHAN_RT_STDATA_REG + i * 4;
+			dev_dbg(dev, "TRT_STDATA[%02d]: 0x%08x\n", i,
+				udma_tchanrt_read(uc, offset));
+		}
+	}
+
+	if (uc->config.dir == DMA_DEV_TO_MEM || uc->config.dir == DMA_MEM_TO_MEM) {
+		dev_dbg(dev, "RCHAN State data:\n");
+		for (i = 0; i < 32; i++) {
+			offset = UDMA_CHAN_RT_STDATA_REG + i * 4;
+			dev_dbg(dev, "RRT_STDATA[%02d]: 0x%08x\n", i,
+				udma_rchanrt_read(uc, offset));
+		}
+	}
+}
+
+bool udma_is_chan_running(struct udma_chan *uc)
+{
+	u32 trt_ctl = 0;
+	u32 rrt_ctl = 0;
+
+	if (uc->tchan)
+		trt_ctl = udma_tchanrt_read(uc, UDMA_CHAN_RT_CTL_REG);
+	if (uc->rchan)
+		rrt_ctl = udma_rchanrt_read(uc, UDMA_CHAN_RT_CTL_REG);
+
+	if (trt_ctl & UDMA_CHAN_RT_CTL_EN || rrt_ctl & UDMA_CHAN_RT_CTL_EN)
+		return true;
+
+	return false;
+}
+EXPORT_SYMBOL_GPL(udma_is_chan_running);
+
+bool udma_chan_needs_reconfiguration(struct udma_chan *uc)
+{
+	/* Only PDMAs have staticTR */
+	if (uc->config.ep_type == PSIL_EP_NATIVE)
+		return false;
+
+	/* Check if the staticTR configuration has changed for TX */
+	if (memcmp(&uc->static_tr, &uc->desc->static_tr, sizeof(uc->static_tr)))
+		return true;
+
+	return false;
+}
+EXPORT_SYMBOL_GPL(udma_chan_needs_reconfiguration);
+
+void udma_cyclic_packet_elapsed(struct udma_chan *uc)
+{
+	struct udma_desc *d = uc->desc;
+	struct cppi5_host_desc_t *h_desc;
+
+	h_desc = d->hwdesc[d->desc_idx].cppi5_desc_vaddr;
+	cppi5_hdesc_reset_to_original(h_desc);
+	udma_push_to_ring(uc, d->desc_idx);
+	d->desc_idx = (d->desc_idx + 1) % d->sglen;
+}
+EXPORT_SYMBOL_GPL(udma_cyclic_packet_elapsed);
+
+void udma_check_tx_completion(struct work_struct *work)
+{
+	struct udma_chan *uc = container_of(work, typeof(*uc),
+					    tx_drain.work.work);
+	bool desc_done = true;
+	u32 residue_diff;
+	ktime_t time_diff;
+	unsigned long delay;
+	unsigned long flags;
+
+	while (1) {
+		spin_lock_irqsave(&uc->vc.lock, flags);
+
+		if (uc->desc) {
+			/* Get previous residue and time stamp */
+			residue_diff = uc->tx_drain.residue;
+			time_diff = uc->tx_drain.tstamp;
+			/*
+			 * Get current residue and time stamp or see if
+			 * transfer is complete
+			 */
+			desc_done = udma_is_desc_really_done(uc, uc->desc);
+		}
+
+		if (!desc_done) {
+			/*
+			 * Find the time delta and residue delta w.r.t
+			 * previous poll
+			 */
+			time_diff = ktime_sub(uc->tx_drain.tstamp,
+					      time_diff) + 1;
+			residue_diff -= uc->tx_drain.residue;
+			if (residue_diff) {
+				/*
+				 * Try to guess when we should check
+				 * next time by calculating rate at
+				 * which data is being drained at the
+				 * peer device
+				 */
+				delay = (time_diff / residue_diff) *
+					uc->tx_drain.residue;
+			} else {
+				/* No progress, check again in 1 second  */
+				schedule_delayed_work(&uc->tx_drain.work, HZ);
+				break;
+			}
+
+			spin_unlock_irqrestore(&uc->vc.lock, flags);
+
+			usleep_range(ktime_to_us(delay),
+				     ktime_to_us(delay) + 10);
+			continue;
+		}
+
+		if (uc->desc) {
+			struct udma_desc *d = uc->desc;
+
+			uc->ud->decrement_byte_counters(uc, d->residue);
+			uc->ud->start(uc);
+			vchan_cookie_complete(&d->vd);
+			break;
+		}
+
+		break;
+	}
+
+	spin_unlock_irqrestore(&uc->vc.lock, flags);
+}
+EXPORT_SYMBOL_GPL(udma_check_tx_completion);
+
+int udma_slave_config(struct dma_chan *chan,
+		      struct dma_slave_config *cfg)
+{
+	struct udma_chan *uc = to_udma_chan(chan);
+
+	memcpy(&uc->cfg, cfg, sizeof(uc->cfg));
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(udma_slave_config);
+
+void udma_issue_pending(struct dma_chan *chan)
+{
+	struct udma_chan *uc = to_udma_chan(chan);
+	unsigned long flags;
+
+	spin_lock_irqsave(&uc->vc.lock, flags);
+
+	/* If we have something pending and no active descriptor, then */
+	if (vchan_issue_pending(&uc->vc) && !uc->desc) {
+		/*
+		 * start a descriptor if the channel is NOT [marked as
+		 * terminating _and_ it is still running (teardown has not
+		 * completed yet)].
+		 */
+		if (!(uc->state == UDMA_CHAN_IS_TERMINATING &&
+		      udma_is_chan_running(uc)))
+			uc->ud->start(uc);
+	}
+
+	spin_unlock_irqrestore(&uc->vc.lock, flags);
+}
+EXPORT_SYMBOL_GPL(udma_issue_pending);
+
+int udma_terminate_all(struct dma_chan *chan)
+{
+	struct udma_chan *uc = to_udma_chan(chan);
+	unsigned long flags;
+	LIST_HEAD(head);
+
+	spin_lock_irqsave(&uc->vc.lock, flags);
+
+	if (udma_is_chan_running(uc))
+		uc->ud->stop(uc);
+
+	if (uc->desc) {
+		uc->terminated_desc = uc->desc;
+		uc->desc = NULL;
+		uc->terminated_desc->terminated = true;
+		cancel_delayed_work(&uc->tx_drain.work);
+	}
+
+	uc->paused = false;
+
+	vchan_get_all_descriptors(&uc->vc, &head);
+	spin_unlock_irqrestore(&uc->vc.lock, flags);
+	vchan_dma_desc_free_list(&uc->vc, &head);
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(udma_terminate_all);
+
+void udma_synchronize(struct dma_chan *chan)
+{
+	struct udma_chan *uc = to_udma_chan(chan);
+	unsigned long timeout = msecs_to_jiffies(1000);
+
+	vchan_synchronize(&uc->vc);
+
+	if (uc->state == UDMA_CHAN_IS_TERMINATING) {
+		timeout = wait_for_completion_timeout(&uc->teardown_completed,
+						      timeout);
+		if (!timeout) {
+			dev_warn(uc->ud->dev, "chan%d teardown timeout!\n",
+				 uc->id);
+			udma_dump_chan_stdata(uc);
+			uc->ud->reset_chan(uc, true);
+		}
+	}
+
+	uc->ud->reset_chan(uc, false);
+	if (udma_is_chan_running(uc))
+		dev_warn(uc->ud->dev, "chan%d refused to stop!\n", uc->id);
+
+	cancel_delayed_work_sync(&uc->tx_drain.work);
+	udma_reset_rings(uc);
+}
+EXPORT_SYMBOL_GPL(udma_synchronize);
+
+/*
+ * This tasklet handles the completion of a DMA descriptor by
+ * calling its callback and freeing it.
+ */
+void udma_vchan_complete(struct tasklet_struct *t)
+{
+	struct virt_dma_chan *vc = from_tasklet(vc, t, task);
+	struct virt_dma_desc *vd, *_vd;
+	struct dmaengine_desc_callback cb;
+	LIST_HEAD(head);
+
+	spin_lock_irq(&vc->lock);
+	list_splice_tail_init(&vc->desc_completed, &head);
+	vd = vc->cyclic;
+	if (vd) {
+		vc->cyclic = NULL;
+		dmaengine_desc_get_callback(&vd->tx, &cb);
+	} else {
+		memset(&cb, 0, sizeof(cb));
+	}
+	spin_unlock_irq(&vc->lock);
+
+	udma_desc_pre_callback(vc, vd, NULL);
+	dmaengine_desc_callback_invoke(&cb, NULL);
+
+	list_for_each_entry_safe(vd, _vd, &head, node) {
+		struct dmaengine_result result;
+
+		dmaengine_desc_get_callback(&vd->tx, &cb);
+
+		list_del(&vd->node);
+
+		udma_desc_pre_callback(vc, vd, &result);
+		dmaengine_desc_callback_invoke(&cb, &result);
+
+		vchan_vdesc_fini(vd);
+	}
+}
+EXPORT_SYMBOL_GPL(udma_vchan_complete);
+
+void udma_mark_resource_ranges(struct udma_dev *ud, unsigned long *map,
+			       struct ti_sci_resource_desc *rm_desc,
+			       char *name)
+{
+	bitmap_clear(map, rm_desc->start, rm_desc->num);
+	bitmap_clear(map, rm_desc->start_sec, rm_desc->num_sec);
+	dev_dbg(ud->dev, "ti_sci resource range for %s: %d:%d | %d:%d\n", name,
+		rm_desc->start, rm_desc->num, rm_desc->start_sec,
+		rm_desc->num_sec);
+}
+EXPORT_SYMBOL_GPL(udma_mark_resource_ranges);
+
+int udma_setup_rx_flush(struct udma_dev *ud)
+{
+	struct udma_rx_flush *rx_flush = &ud->rx_flush;
+	struct cppi5_desc_hdr_t *tr_desc;
+	struct cppi5_tr_type1_t *tr_req;
+	struct cppi5_host_desc_t *desc;
+	struct device *dev = ud->dev;
+	struct udma_hwdesc *hwdesc;
+	size_t tr_size;
+
+	/* Allocate 1K buffer for discarded data on RX channel teardown */
+	rx_flush->buffer_size = SZ_1K;
+	rx_flush->buffer_vaddr = devm_kzalloc(dev, rx_flush->buffer_size,
+					      GFP_KERNEL);
+	if (!rx_flush->buffer_vaddr)
+		return -ENOMEM;
+
+	rx_flush->buffer_paddr = dma_map_single(dev, rx_flush->buffer_vaddr,
+						rx_flush->buffer_size,
+						DMA_TO_DEVICE);
+	if (dma_mapping_error(dev, rx_flush->buffer_paddr))
+		return -ENOMEM;
+
+	/* Set up descriptor to be used for TR mode */
+	hwdesc = &rx_flush->hwdescs[0];
+	tr_size = sizeof(struct cppi5_tr_type1_t);
+	hwdesc->cppi5_desc_size = cppi5_trdesc_calc_size(tr_size, 1);
+	hwdesc->cppi5_desc_size = ALIGN(hwdesc->cppi5_desc_size,
+					ud->desc_align);
+
+	hwdesc->cppi5_desc_vaddr = devm_kzalloc(dev, hwdesc->cppi5_desc_size,
+						GFP_KERNEL);
+	if (!hwdesc->cppi5_desc_vaddr)
+		return -ENOMEM;
+
+	hwdesc->cppi5_desc_paddr = dma_map_single(dev, hwdesc->cppi5_desc_vaddr,
+						  hwdesc->cppi5_desc_size,
+						  DMA_TO_DEVICE);
+	if (dma_mapping_error(dev, hwdesc->cppi5_desc_paddr))
+		return -ENOMEM;
+
+	/* Start of the TR req records */
+	hwdesc->tr_req_base = hwdesc->cppi5_desc_vaddr + tr_size;
+	/* Start address of the TR response array */
+	hwdesc->tr_resp_base = hwdesc->tr_req_base + tr_size;
+
+	tr_desc = hwdesc->cppi5_desc_vaddr;
+	cppi5_trdesc_init(tr_desc, 1, tr_size, 0, 0);
+	cppi5_desc_set_pktids(tr_desc, 0, CPPI5_INFO1_DESC_FLOWID_DEFAULT);
+	cppi5_desc_set_retpolicy(tr_desc, 0, 0);
+
+	tr_req = hwdesc->tr_req_base;
+	cppi5_tr_init(&tr_req->flags, CPPI5_TR_TYPE1, false, false,
+		      CPPI5_TR_EVENT_SIZE_COMPLETION, 0);
+	cppi5_tr_csf_set(&tr_req->flags, CPPI5_TR_CSF_SUPR_EVT);
+
+	tr_req->addr = rx_flush->buffer_paddr;
+	tr_req->icnt0 = rx_flush->buffer_size;
+	tr_req->icnt1 = 1;
+
+	dma_sync_single_for_device(dev, hwdesc->cppi5_desc_paddr,
+				   hwdesc->cppi5_desc_size, DMA_TO_DEVICE);
+
+	/* Set up descriptor to be used for packet mode */
+	hwdesc = &rx_flush->hwdescs[1];
+	hwdesc->cppi5_desc_size = ALIGN(sizeof(struct cppi5_host_desc_t) +
+					CPPI5_INFO0_HDESC_EPIB_SIZE +
+					CPPI5_INFO0_HDESC_PSDATA_MAX_SIZE,
+					ud->desc_align);
+
+	hwdesc->cppi5_desc_vaddr = devm_kzalloc(dev, hwdesc->cppi5_desc_size,
+						GFP_KERNEL);
+	if (!hwdesc->cppi5_desc_vaddr)
+		return -ENOMEM;
+
+	hwdesc->cppi5_desc_paddr = dma_map_single(dev, hwdesc->cppi5_desc_vaddr,
+						  hwdesc->cppi5_desc_size,
+						  DMA_TO_DEVICE);
+	if (dma_mapping_error(dev, hwdesc->cppi5_desc_paddr))
+		return -ENOMEM;
+
+	desc = hwdesc->cppi5_desc_vaddr;
+	cppi5_hdesc_init(desc, 0, 0);
+	cppi5_desc_set_pktids(&desc->hdr, 0, CPPI5_INFO1_DESC_FLOWID_DEFAULT);
+	cppi5_desc_set_retpolicy(&desc->hdr, 0, 0);
+
+	cppi5_hdesc_attach_buf(desc,
+			       rx_flush->buffer_paddr, rx_flush->buffer_size,
+			       rx_flush->buffer_paddr, rx_flush->buffer_size);
+
+	dma_sync_single_for_device(dev, hwdesc->cppi5_desc_paddr,
+				   hwdesc->cppi5_desc_size, DMA_TO_DEVICE);
+	return 0;
+}
+EXPORT_SYMBOL_GPL(udma_setup_rx_flush);
+
+#ifdef CONFIG_DEBUG_FS
+void udma_dbg_summary_show_chan(struct seq_file *s,
+				struct dma_chan *chan)
+{
+	struct udma_chan *uc = to_udma_chan(chan);
+	struct udma_chan_config *ucc = &uc->config;
+
+	seq_printf(s, " %-13s| %s", dma_chan_name(chan),
+		   chan->dbg_client_name ?: "in-use");
+	if (ucc->tr_trigger_type)
+		seq_puts(s, " (triggered, ");
+	else
+		seq_printf(s, " (%s, ",
+			   dmaengine_get_direction_text(uc->config.dir));
+
+	switch (uc->config.dir) {
+	case DMA_MEM_TO_MEM:
+		if (uc->ud->match_data->type == DMA_TYPE_BCDMA) {
+			seq_printf(s, "bchan%d)\n", uc->bchan->id);
+			return;
+		}
+
+		seq_printf(s, "chan%d pair [0x%04x -> 0x%04x], ", uc->tchan->id,
+			   ucc->src_thread, ucc->dst_thread);
+		break;
+	case DMA_DEV_TO_MEM:
+		seq_printf(s, "rchan%d [0x%04x -> 0x%04x], ", uc->rchan->id,
+			   ucc->src_thread, ucc->dst_thread);
+		if (uc->ud->match_data->type == DMA_TYPE_PKTDMA)
+			seq_printf(s, "rflow%d, ", uc->rflow->id);
+		break;
+	case DMA_MEM_TO_DEV:
+		seq_printf(s, "tchan%d [0x%04x -> 0x%04x], ", uc->tchan->id,
+			   ucc->src_thread, ucc->dst_thread);
+		if (uc->ud->match_data->type == DMA_TYPE_PKTDMA)
+			seq_printf(s, "tflow%d, ", uc->tchan->tflow_id);
+		break;
+	default:
+		seq_printf(s, ")\n");
+		return;
+	}
+
+	if (ucc->ep_type == PSIL_EP_NATIVE) {
+		seq_printf(s, "PSI-L Native");
+		if (ucc->metadata_size) {
+			seq_printf(s, "[%s", ucc->needs_epib ? " EPIB" : "");
+			if (ucc->psd_size)
+				seq_printf(s, " PSDsize:%u", ucc->psd_size);
+			seq_printf(s, " ]");
+		}
+	} else {
+		seq_printf(s, "PDMA");
+		if (ucc->enable_acc32 || ucc->enable_burst)
+			seq_printf(s, "[%s%s ]",
+				   ucc->enable_acc32 ? " ACC32" : "",
+				   ucc->enable_burst ? " BURST" : "");
+	}
+
+	seq_printf(s, ", %s)\n", ucc->pkt_mode ? "Packet mode" : "TR mode");
+}
+
+void udma_dbg_summary_show(struct seq_file *s,
+			   struct dma_device *dma_dev)
+{
+	struct dma_chan *chan;
+
+	list_for_each_entry(chan, &dma_dev->channels, device_node) {
+		if (chan->client_count)
+			udma_dbg_summary_show_chan(s, chan);
+	}
+}
+EXPORT_SYMBOL_GPL(udma_dbg_summary_show);
+#endif /* CONFIG_DEBUG_FS */
+
+enum dmaengine_alignment udma_get_copy_align(struct udma_dev *ud)
+{
+	const struct udma_match_data *match_data = ud->match_data;
+	u8 tpl;
+
+	if (!match_data->enable_memcpy_support)
+		return DMAENGINE_ALIGN_8_BYTES;
+
+	/* Get the highest TPL level the device supports for memcpy */
+	if (ud->bchan_cnt)
+		tpl = udma_get_chan_tpl_index(&ud->bchan_tpl, 0);
+	else if (ud->tchan_cnt)
+		tpl = udma_get_chan_tpl_index(&ud->tchan_tpl, 0);
+	else
+		return DMAENGINE_ALIGN_8_BYTES;
+
+	switch (match_data->burst_size[tpl]) {
+	case TI_SCI_RM_UDMAP_CHAN_BURST_SIZE_256_BYTES:
+		return DMAENGINE_ALIGN_256_BYTES;
+	case TI_SCI_RM_UDMAP_CHAN_BURST_SIZE_128_BYTES:
+		return DMAENGINE_ALIGN_128_BYTES;
+	case TI_SCI_RM_UDMAP_CHAN_BURST_SIZE_64_BYTES:
+	fallthrough;
+	default:
+		return DMAENGINE_ALIGN_64_BYTES;
+	}
+}
+EXPORT_SYMBOL_GPL(udma_get_copy_align);
+
 MODULE_DESCRIPTION("Texas Instruments K3 UDMA Common Library");
 MODULE_LICENSE("GPL v2");
diff --git a/drivers/dma/ti/k3-udma.c b/drivers/dma/ti/k3-udma.c
index fbcf976d7a668..15a3de16f50f6 100644
--- a/drivers/dma/ti/k3-udma.c
+++ b/drivers/dma/ti/k3-udma.c
@@ -61,92 +61,6 @@ int navss_psil_unpair(struct udma_dev *ud, u32 src_thread,
 						src_thread, dst_thread);
 }
 
-static void k3_configure_chan_coherency(struct dma_chan *chan, u32 asel)
-{
-	struct device *chan_dev = dmaengine_chan_dev(chan);
-
-	if (asel == 0) {
-		/* No special handling for the channel */
-		chan->chan_dev->chan_dma_dev = false;
-
-		dev_clear_dma_coherent(chan_dev);
-		chan_dev->dma_parms = NULL;
-	} else if (asel == 14 || asel == 15) {
-		chan->chan_dev->chan_dma_dev = true;
-
-		dev_set_dma_coherent(chan_dev);
-		dma_coerce_mask_and_coherent(chan_dev, DMA_BIT_MASK(48));
-		chan_dev->dma_parms = chan_dev->parent->dma_parms;
-	} else {
-		dev_warn(chan->device->dev, "Invalid ASEL value: %u\n", asel);
-
-		dev_clear_dma_coherent(chan_dev);
-		chan_dev->dma_parms = NULL;
-	}
-}
-
-static u8 udma_get_chan_tpl_index(struct udma_tpl *tpl_map, int chan_id)
-{
-	int i;
-
-	for (i = 0; i < tpl_map->levels; i++) {
-		if (chan_id >= tpl_map->start_idx[i])
-			return i;
-	}
-
-	return 0;
-}
-
-static void udma_reset_uchan(struct udma_chan *uc)
-{
-	memset(&uc->config, 0, sizeof(uc->config));
-	uc->config.remote_thread_id = -1;
-	uc->config.mapped_channel_id = -1;
-	uc->config.default_flow_id = -1;
-	uc->state = UDMA_CHAN_IS_IDLE;
-}
-
-static void udma_dump_chan_stdata(struct udma_chan *uc)
-{
-	struct device *dev = uc->ud->dev;
-	u32 offset;
-	int i;
-
-	if (uc->config.dir == DMA_MEM_TO_DEV || uc->config.dir == DMA_MEM_TO_MEM) {
-		dev_dbg(dev, "TCHAN State data:\n");
-		for (i = 0; i < 32; i++) {
-			offset = UDMA_CHAN_RT_STDATA_REG + i * 4;
-			dev_dbg(dev, "TRT_STDATA[%02d]: 0x%08x\n", i,
-				udma_tchanrt_read(uc, offset));
-		}
-	}
-
-	if (uc->config.dir == DMA_DEV_TO_MEM || uc->config.dir == DMA_MEM_TO_MEM) {
-		dev_dbg(dev, "RCHAN State data:\n");
-		for (i = 0; i < 32; i++) {
-			offset = UDMA_CHAN_RT_STDATA_REG + i * 4;
-			dev_dbg(dev, "RRT_STDATA[%02d]: 0x%08x\n", i,
-				udma_rchanrt_read(uc, offset));
-		}
-	}
-}
-
-static bool udma_is_chan_running(struct udma_chan *uc)
-{
-	u32 trt_ctl = 0;
-	u32 rrt_ctl = 0;
-
-	if (uc->tchan)
-		trt_ctl = udma_tchanrt_read(uc, UDMA_CHAN_RT_CTL_REG);
-	if (uc->rchan)
-		rrt_ctl = udma_rchanrt_read(uc, UDMA_CHAN_RT_CTL_REG);
-
-	if (trt_ctl & UDMA_CHAN_RT_CTL_EN || rrt_ctl & UDMA_CHAN_RT_CTL_EN)
-		return true;
-
-	return false;
-}
-
 static bool udma_is_chan_paused(struct udma_chan *uc)
 {
 	u32 val, pause_mask;
@@ -275,40 +189,6 @@ static int udma_reset_chan(struct udma_chan *uc, bool hard)
 	return 0;
 }
 
-static void udma_start_desc(struct udma_chan *uc)
-{
-	struct udma_chan_config *ucc = &uc->config;
-
-	if (uc->ud->match_data->type == DMA_TYPE_UDMA && ucc->pkt_mode &&
-	    (uc->cyclic || ucc->dir == DMA_DEV_TO_MEM)) {
-		int i;
-
-		/*
-		 * UDMA only: Push all descriptors to ring for packet mode
-		 * cyclic or RX
-		 * PKTDMA supports pre-linked descriptor and cyclic is not
-		 * supported
-		 */
-		for (i = 0; i < uc->desc->sglen; i++)
-			udma_push_to_ring(uc, i);
-	} else {
-		udma_push_to_ring(uc, 0);
-	}
-}
-
-static bool udma_chan_needs_reconfiguration(struct udma_chan *uc)
-{
-	/* Only PDMAs have staticTR */
-	if (uc->config.ep_type == PSIL_EP_NATIVE)
-		return false;
-
-	/* Check if the staticTR configuration has changed for TX */
-	if (memcmp(&uc->static_tr, &uc->desc->static_tr, sizeof(uc->static_tr)))
-		return true;
-
-	return false;
-}
-
 static int udma_start(struct udma_chan *uc)
 {
 	struct virt_dma_desc *vd = vchan_next_desc(&uc->vc);
@@ -453,86 +333,6 @@ static int udma_stop(struct udma_chan *uc)
 	return 0;
 }
 
-static void udma_cyclic_packet_elapsed(struct udma_chan *uc)
-{
-	struct udma_desc *d = uc->desc;
-	struct cppi5_host_desc_t *h_desc;
-
-	h_desc = d->hwdesc[d->desc_idx].cppi5_desc_vaddr;
-	cppi5_hdesc_reset_to_original(h_desc);
-	udma_push_to_ring(uc, d->desc_idx);
-	d->desc_idx = (d->desc_idx + 1) % d->sglen;
-}
-
-static void udma_check_tx_completion(struct work_struct *work)
-{
-	struct udma_chan *uc = container_of(work, typeof(*uc),
-					    tx_drain.work.work);
-	bool desc_done = true;
-	u32 residue_diff;
-	ktime_t time_diff;
-	unsigned long delay;
-	unsigned long flags;
-
-	while (1) {
-		spin_lock_irqsave(&uc->vc.lock, flags);
-
-		if (uc->desc) {
-			/* Get previous residue and time stamp */
-			residue_diff = uc->tx_drain.residue;
-			time_diff = uc->tx_drain.tstamp;
-			/*
-			 * Get current residue and time stamp or see if
-			 * transfer is complete
-			 */
-			desc_done = udma_is_desc_really_done(uc, uc->desc);
-		}
-
-		if (!desc_done) {
-			/*
-			 * Find the time delta and residue delta w.r.t
-			 * previous poll
-			 */
-			time_diff = ktime_sub(uc->tx_drain.tstamp,
-					      time_diff) + 1;
-			residue_diff -= uc->tx_drain.residue;
-			if (residue_diff) {
-				/*
-				 * Try to guess when we should check
-				 * next time by calculating rate at
-				 * which data is being drained at the
-				 * peer device
-				 */
-				delay = (time_diff / residue_diff) *
-					uc->tx_drain.residue;
-			} else {
-				/* No progress, check again in 1 second  */
-				schedule_delayed_work(&uc->tx_drain.work, HZ);
-				break;
-			}
-
-			spin_unlock_irqrestore(&uc->vc.lock, flags);
-
-			usleep_range(ktime_to_us(delay),
-				     ktime_to_us(delay) + 10);
-			continue;
-		}
-
-		if (uc->desc) {
-			struct udma_desc *d = uc->desc;
-
-			uc->ud->decrement_byte_counters(uc, d->residue);
-			uc->ud->start(uc);
-			vchan_cookie_complete(&d->vd);
-			break;
-		}
-
-		break;
-	}
-
-	spin_unlock_irqrestore(&uc->vc.lock, flags);
-}
-
 static irqreturn_t udma_ring_irq_handler(int irq, void *data)
 {
 	struct udma_chan *uc = data;
@@ -2097,38 +1897,6 @@ static int pktdma_alloc_chan_resources(struct dma_chan *chan)
 	return ret;
 }
 
-static int udma_slave_config(struct dma_chan *chan,
-			     struct dma_slave_config *cfg)
-{
-	struct udma_chan *uc = to_udma_chan(chan);
-
-	memcpy(&uc->cfg, cfg, sizeof(uc->cfg));
-
-	return 0;
-}
-
-static void udma_issue_pending(struct dma_chan *chan)
-{
-	struct udma_chan *uc = to_udma_chan(chan);
-	unsigned long flags;
-
-	spin_lock_irqsave(&uc->vc.lock, flags);
-
-	/* If we have something pending and no active descriptor, then */
-	if (vchan_issue_pending(&uc->vc) && !uc->desc) {
-		/*
-		 * start a descriptor if the channel is NOT [marked as
-		 * terminating _and_ it is still running (teardown has not
-		 * completed yet)].
-		 */
-		if (!(uc->state == UDMA_CHAN_IS_TERMINATING &&
-		      udma_is_chan_running(uc)))
-			uc->ud->start(uc);
-	}
-
-	spin_unlock_irqrestore(&uc->vc.lock, flags);
-}
-
 static enum dma_status udma_tx_status(struct dma_chan *chan,
 				      dma_cookie_t cookie,
 				      struct dma_tx_state *txstate)
@@ -2256,98 +2024,6 @@ static int udma_resume(struct dma_chan *chan)
 	return 0;
 }
 
-static int udma_terminate_all(struct dma_chan *chan)
-{
-	struct udma_chan *uc = to_udma_chan(chan);
-	unsigned long flags;
-	LIST_HEAD(head);
-
-	spin_lock_irqsave(&uc->vc.lock, flags);
-
-	if (udma_is_chan_running(uc))
-		uc->ud->stop(uc);
-
-	if (uc->desc) {
-		uc->terminated_desc = uc->desc;
-		uc->desc = NULL;
-		uc->terminated_desc->terminated = true;
-		cancel_delayed_work(&uc->tx_drain.work);
-	}
-
-	uc->paused = false;
-
-	vchan_get_all_descriptors(&uc->vc, &head);
-	spin_unlock_irqrestore(&uc->vc.lock, flags);
-	vchan_dma_desc_free_list(&uc->vc, &head);
-
-	return 0;
-}
-
-static void udma_synchronize(struct dma_chan *chan)
-{
-	struct udma_chan *uc = to_udma_chan(chan);
-	unsigned long timeout = msecs_to_jiffies(1000);
-
-	vchan_synchronize(&uc->vc);
-
-	if (uc->state == UDMA_CHAN_IS_TERMINATING) {
-		timeout = wait_for_completion_timeout(&uc->teardown_completed,
-						      timeout);
-		if (!timeout) {
-			dev_warn(uc->ud->dev, "chan%d teardown timeout!\n",
-				 uc->id);
-			udma_dump_chan_stdata(uc);
-			uc->ud->reset_chan(uc, true);
-		}
-	}
-
-	uc->ud->reset_chan(uc, false);
-	if (udma_is_chan_running(uc))
-		dev_warn(uc->ud->dev, "chan%d refused to stop!\n", uc->id);
-
-	cancel_delayed_work_sync(&uc->tx_drain.work);
-	udma_reset_rings(uc);
-}
-
-/*
- * This tasklet handles the completion of a DMA descriptor by
- * calling its callback and freeing it.
- */
-static void udma_vchan_complete(struct tasklet_struct *t)
-{
-	struct virt_dma_chan *vc = from_tasklet(vc, t, task);
-	struct virt_dma_desc *vd, *_vd;
-	struct dmaengine_desc_callback cb;
-	LIST_HEAD(head);
-
-	spin_lock_irq(&vc->lock);
-	list_splice_tail_init(&vc->desc_completed, &head);
-	vd = vc->cyclic;
-	if (vd) {
-		vc->cyclic = NULL;
-		dmaengine_desc_get_callback(&vd->tx, &cb);
-	} else {
-		memset(&cb, 0, sizeof(cb));
-	}
-	spin_unlock_irq(&vc->lock);
-
-	udma_desc_pre_callback(vc, vd, NULL);
-	dmaengine_desc_callback_invoke(&cb, NULL);
-
-	list_for_each_entry_safe(vd, _vd, &head, node) {
-		struct dmaengine_result result;
-
-		dmaengine_desc_get_callback(&vd->tx, &cb);
-
-		list_del(&vd->node);
-
-		udma_desc_pre_callback(vc, vd, &result);
-		dmaengine_desc_callback_invoke(&cb, &result);
-
-		vchan_vdesc_fini(vd);
-	}
-}
-
 static void udma_free_chan_resources(struct dma_chan *chan)
 {
 	struct udma_chan *uc = to_udma_chan(chan);
@@ -2822,17 +2498,6 @@ static int udma_get_mmrs(struct platform_device *pdev, struct udma_dev *ud)
 	return 0;
 }
 
-static void udma_mark_resource_ranges(struct udma_dev *ud, unsigned long *map,
-				      struct ti_sci_resource_desc *rm_desc,
-				      char *name)
-{
-	bitmap_clear(map, rm_desc->start, rm_desc->num);
-	bitmap_clear(map, rm_desc->start_sec, rm_desc->num_sec);
-	dev_dbg(ud->dev, "ti_sci resource range for %s: %d:%d | %d:%d\n", name,
-		rm_desc->start, rm_desc->num, rm_desc->start_sec,
-		rm_desc->num_sec);
-}
-
 static const char * const range_names[] = {
 	[RM_RANGE_BCHAN] = "ti,sci-rm-range-bchan",
 	[RM_RANGE_TCHAN] = "ti,sci-rm-range-tchan",
@@ -3446,202 +3111,6 @@ static int setup_resources(struct udma_dev *ud)
 	return ch_count;
 }
 
-static int udma_setup_rx_flush(struct udma_dev *ud)
-{
-	struct udma_rx_flush *rx_flush = &ud->rx_flush;
-	struct cppi5_desc_hdr_t *tr_desc;
-	struct cppi5_tr_type1_t *tr_req;
-	struct cppi5_host_desc_t *desc;
-	struct device *dev = ud->dev;
-	struct udma_hwdesc *hwdesc;
-	size_t tr_size;
-
-	/* Allocate 1K buffer for discarded data on RX channel teardown */
-	rx_flush->buffer_size = SZ_1K;
-	rx_flush->buffer_vaddr = devm_kzalloc(dev, rx_flush->buffer_size,
-					      GFP_KERNEL);
-	if (!rx_flush->buffer_vaddr)
-		return -ENOMEM;
-
-	rx_flush->buffer_paddr = dma_map_single(dev, rx_flush->buffer_vaddr,
-						rx_flush->buffer_size,
-						DMA_TO_DEVICE);
-	if (dma_mapping_error(dev, rx_flush->buffer_paddr))
-		return -ENOMEM;
-
-	/* Set up descriptor to be used for TR mode */
-	hwdesc = &rx_flush->hwdescs[0];
-	tr_size = sizeof(struct cppi5_tr_type1_t);
-	hwdesc->cppi5_desc_size = cppi5_trdesc_calc_size(tr_size, 1);
-	hwdesc->cppi5_desc_size = ALIGN(hwdesc->cppi5_desc_size,
-					ud->desc_align);
-
-	hwdesc->cppi5_desc_vaddr = devm_kzalloc(dev, hwdesc->cppi5_desc_size,
-						GFP_KERNEL);
-	if (!hwdesc->cppi5_desc_vaddr)
-		return -ENOMEM;
-
-	hwdesc->cppi5_desc_paddr = dma_map_single(dev, hwdesc->cppi5_desc_vaddr,
-						  hwdesc->cppi5_desc_size,
-						  DMA_TO_DEVICE);
-	if (dma_mapping_error(dev, hwdesc->cppi5_desc_paddr))
-		return -ENOMEM;
-
-	/* Start of the TR req records */
-	hwdesc->tr_req_base = hwdesc->cppi5_desc_vaddr + tr_size;
-	/* Start address of the TR response array */
-	hwdesc->tr_resp_base = hwdesc->tr_req_base + tr_size;
-
-	tr_desc = hwdesc->cppi5_desc_vaddr;
-	cppi5_trdesc_init(tr_desc, 1, tr_size, 0, 0);
-	cppi5_desc_set_pktids(tr_desc, 0, CPPI5_INFO1_DESC_FLOWID_DEFAULT);
-	cppi5_desc_set_retpolicy(tr_desc, 0, 0);
-
-	tr_req = hwdesc->tr_req_base;
-	cppi5_tr_init(&tr_req->flags, CPPI5_TR_TYPE1, false, false,
-		      CPPI5_TR_EVENT_SIZE_COMPLETION, 0);
-	cppi5_tr_csf_set(&tr_req->flags, CPPI5_TR_CSF_SUPR_EVT);
-
-	tr_req->addr = rx_flush->buffer_paddr;
-	tr_req->icnt0 = rx_flush->buffer_size;
-	tr_req->icnt1 = 1;
-
-	dma_sync_single_for_device(dev, hwdesc->cppi5_desc_paddr,
-				   hwdesc->cppi5_desc_size, DMA_TO_DEVICE);
-
-	/* Set up descriptor to be used for packet mode */
-	hwdesc = &rx_flush->hwdescs[1];
-	hwdesc->cppi5_desc_size = ALIGN(sizeof(struct cppi5_host_desc_t) +
-					CPPI5_INFO0_HDESC_EPIB_SIZE +
-					CPPI5_INFO0_HDESC_PSDATA_MAX_SIZE,
-					ud->desc_align);
-
-	hwdesc->cppi5_desc_vaddr = devm_kzalloc(dev, hwdesc->cppi5_desc_size,
-						GFP_KERNEL);
-	if (!hwdesc->cppi5_desc_vaddr)
-		return -ENOMEM;
-
-	hwdesc->cppi5_desc_paddr = dma_map_single(dev, hwdesc->cppi5_desc_vaddr,
-						  hwdesc->cppi5_desc_size,
-						  DMA_TO_DEVICE);
-	if (dma_mapping_error(dev, hwdesc->cppi5_desc_paddr))
-		return -ENOMEM;
-
-	desc = hwdesc->cppi5_desc_vaddr;
-	cppi5_hdesc_init(desc, 0, 0);
-	cppi5_desc_set_pktids(&desc->hdr, 0, CPPI5_INFO1_DESC_FLOWID_DEFAULT);
-	cppi5_desc_set_retpolicy(&desc->hdr, 0, 0);
-
-	cppi5_hdesc_attach_buf(desc,
-			       rx_flush->buffer_paddr, rx_flush->buffer_size,
-			       rx_flush->buffer_paddr, rx_flush->buffer_size);
-
-	dma_sync_single_for_device(dev, hwdesc->cppi5_desc_paddr,
-				   hwdesc->cppi5_desc_size, DMA_TO_DEVICE);
-	return 0;
-}
-
-#ifdef CONFIG_DEBUG_FS
-static void udma_dbg_summary_show_chan(struct seq_file *s,
-				       struct dma_chan *chan)
-{
-	struct udma_chan *uc = to_udma_chan(chan);
-	struct udma_chan_config *ucc = &uc->config;
-
-	seq_printf(s, " %-13s| %s", dma_chan_name(chan),
-		   chan->dbg_client_name ?: "in-use");
-	if (ucc->tr_trigger_type)
-		seq_puts(s, " (triggered, ");
-	else
-		seq_printf(s, " (%s, ",
-			   dmaengine_get_direction_text(uc->config.dir));
-
-	switch (uc->config.dir) {
-	case DMA_MEM_TO_MEM:
-		if (uc->ud->match_data->type == DMA_TYPE_BCDMA) {
-			seq_printf(s, "bchan%d)\n", uc->bchan->id);
-			return;
-		}
-
-		seq_printf(s, "chan%d pair [0x%04x -> 0x%04x], ", uc->tchan->id,
-			   ucc->src_thread, ucc->dst_thread);
-		break;
-	case DMA_DEV_TO_MEM:
-		seq_printf(s, "rchan%d [0x%04x -> 0x%04x], ", uc->rchan->id,
-			   ucc->src_thread, ucc->dst_thread);
-		if (uc->ud->match_data->type == DMA_TYPE_PKTDMA)
-			seq_printf(s, "rflow%d, ", uc->rflow->id);
-		break;
-	case DMA_MEM_TO_DEV:
-		seq_printf(s, "tchan%d [0x%04x -> 0x%04x], ", uc->tchan->id,
-			   ucc->src_thread, ucc->dst_thread);
-		if (uc->ud->match_data->type == DMA_TYPE_PKTDMA)
-			seq_printf(s, "tflow%d, ", uc->tchan->tflow_id);
-		break;
-	default:
-		seq_printf(s, ")\n");
-		return;
-	}
-
-	if (ucc->ep_type == PSIL_EP_NATIVE) {
-		seq_printf(s, "PSI-L Native");
-		if (ucc->metadata_size) {
-			seq_printf(s, "[%s", ucc->needs_epib ? " EPIB" : "");
-			if (ucc->psd_size)
-				seq_printf(s, " PSDsize:%u", ucc->psd_size);
-			seq_printf(s, " ]");
-		}
-	} else {
-		seq_printf(s, "PDMA");
-		if (ucc->enable_acc32 || ucc->enable_burst)
-			seq_printf(s, "[%s%s ]",
-				   ucc->enable_acc32 ? " ACC32" : "",
-				   ucc->enable_burst ? " BURST" : "");
-	}
-
-	seq_printf(s, ", %s)\n", ucc->pkt_mode ? "Packet mode" : "TR mode");
-}
-
-static void udma_dbg_summary_show(struct seq_file *s,
-				  struct dma_device *dma_dev)
-{
-	struct dma_chan *chan;
-
-	list_for_each_entry(chan, &dma_dev->channels, device_node) {
-		if (chan->client_count)
-			udma_dbg_summary_show_chan(s, chan);
-	}
-}
-#endif /* CONFIG_DEBUG_FS */
-
-static enum dmaengine_alignment udma_get_copy_align(struct udma_dev *ud)
-{
-	const struct udma_match_data *match_data = ud->match_data;
-	u8 tpl;
-
-	if (!match_data->enable_memcpy_support)
-		return DMAENGINE_ALIGN_8_BYTES;
-
-	/* Get the highest TPL level the device supports for memcpy */
-	if (ud->bchan_cnt)
-		tpl = udma_get_chan_tpl_index(&ud->bchan_tpl, 0);
-	else if (ud->tchan_cnt)
-		tpl = udma_get_chan_tpl_index(&ud->tchan_tpl, 0);
-	else
-		return DMAENGINE_ALIGN_8_BYTES;
-
-	switch (match_data->burst_size[tpl]) {
-	case TI_SCI_RM_UDMAP_CHAN_BURST_SIZE_256_BYTES:
-		return DMAENGINE_ALIGN_256_BYTES;
-	case TI_SCI_RM_UDMAP_CHAN_BURST_SIZE_128_BYTES:
-		return DMAENGINE_ALIGN_128_BYTES;
-	case TI_SCI_RM_UDMAP_CHAN_BURST_SIZE_64_BYTES:
-	fallthrough;
-	default:
-		return DMAENGINE_ALIGN_64_BYTES;
-	}
-}
-
 static int udma_probe(struct platform_device *pdev)
 {
 	struct device_node *navss_node = pdev->dev.parent->of_node;
diff --git a/drivers/dma/ti/k3-udma.h b/drivers/dma/ti/k3-udma.h
index 59170714f53cc..a6d7aba83a09b 100644
--- a/drivers/dma/ti/k3-udma.h
+++ b/drivers/dma/ti/k3-udma.h
@@ -587,9 +587,6 @@ struct dma_async_tx_descriptor *udma_prep_dma_cyclic(struct dma_chan *chan, dma_
 struct dma_async_tx_descriptor *udma_prep_dma_memcpy(struct dma_chan *chan,
 						     dma_addr_t dest, dma_addr_t src,
 						     size_t len, unsigned long tx_flags);
-void udma_desc_pre_callback(struct virt_dma_chan *vc,
-			    struct virt_dma_desc *vd,
-			    struct dmaengine_result *result);
 
 int udma_push_to_ring(struct udma_chan *uc, int idx);
 int udma_pop_from_ring(struct udma_chan *uc, dma_addr_t *addr);
@@ -597,6 +594,34 @@ void udma_reset_rings(struct udma_chan *uc);
 
 int navss_psil_pair(struct udma_dev *ud, u32 src_thread, u32 dst_thread);
 int navss_psil_unpair(struct udma_dev *ud, u32 src_thread, u32 dst_thread);
+void udma_start_desc(struct udma_chan *uc);
+u8 udma_get_chan_tpl_index(struct udma_tpl *tpl_map, int chan_id);
+void k3_configure_chan_coherency(struct dma_chan *chan, u32 asel);
+void udma_reset_uchan(struct udma_chan *uc);
+void udma_dump_chan_stdata(struct udma_chan *uc);
+bool udma_is_chan_running(struct udma_chan *uc);
+
+bool udma_chan_needs_reconfiguration(struct udma_chan *uc);
+void udma_cyclic_packet_elapsed(struct udma_chan *uc);
+void udma_check_tx_completion(struct work_struct *work);
+int udma_slave_config(struct dma_chan *chan,
+		      struct dma_slave_config *cfg);
+void udma_issue_pending(struct dma_chan *chan);
+int udma_terminate_all(struct dma_chan *chan);
+void udma_synchronize(struct dma_chan *chan);
+void udma_vchan_complete(struct tasklet_struct *t);
+void udma_mark_resource_ranges(struct udma_dev *ud, unsigned long *map,
+			       struct ti_sci_resource_desc *rm_desc,
+			       char *name);
+int udma_setup_rx_flush(struct udma_dev *ud);
+enum dmaengine_alignment udma_get_copy_align(struct udma_dev *ud);
+
+#ifdef CONFIG_DEBUG_FS
+void udma_dbg_summary_show_chan(struct seq_file *s,
+				struct dma_chan *chan);
+void udma_dbg_summary_show(struct seq_file *s,
+			   struct dma_device *dma_dev);
+#endif /* CONFIG_DEBUG_FS */
 
 /* Direct access to UDMA low lever resources for the glue layer */
 int xudma_navss_psil_pair(struct udma_dev *ud, u32 src_thread, u32 dst_thread);

-- 
2.55.0

