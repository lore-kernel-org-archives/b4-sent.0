From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:50:06 -0600
Subject: [PATCH v4 25/25] dmaengine: sdxi: Add DMA engine provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-25-3668ccc7aab8@amd.com>
References: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
In-Reply-To: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Bjorn Helgaas <bhelgaas@google.com>, 
 David Rientjes <rientjes@google.com>, John.Kariuki@amd.com, 
 Jonathan Cameron <jic23@kernel.org>, Kinsey Ho <kinseyho@google.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 PradeepVineshReddy.Kodamati@amd.com, Shivank Garg <shivankg@amd.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Wei Huang <wei.huang2@amd.com>, Wei Xu <weixugc@google.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=18622;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=AqslvRIJqipXUigrtSUCawVvtsuLxqVBRVUFuCdd4cA=;
 b=f9GNTgpXoPYE1dXKWFwLEiIkP4Jg6wWBK4zUk3MKouyAnwPSM+IYoX6+P/h9E1O6gDlYHZaAK
 goqBC3hiE+7AE5mJeQ2fWl58jBcUiT68rbT5xMROV+4B221IdRy7JGA
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register a virt-dma memcpy provider with a configurable number of channels
per function. Publish transactions in cookie order, batching copies behind
fenced completion interrupts. Keep transactions pending when ring slots or
completion blocks are unavailable.

Published descriptors cannot be withdrawn. Termination frees submitted and
pending transactions and retains published transactions for reaping without
completing cookies or invoking callbacks.

Synchronize by polling and reaping transactions under the channel lock,
then flushing virt-dma callbacks. The wait is uninterruptible and bounded
to ten seconds. On timeout, suppress remaining callbacks and retain unreaped
status blocks until context teardown; this timeout path does not establish
hardware quiescence for client buffers.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/Kconfig  |   1 +
 drivers/dma/sdxi/Makefile |   1 +
 drivers/dma/sdxi/device.c |   2 +
 drivers/dma/sdxi/dma.c    | 509 ++++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/dma.h    |  11 +
 5 files changed, 524 insertions(+)

diff --git a/drivers/dma/sdxi/Kconfig b/drivers/dma/sdxi/Kconfig
index 314b3e725ccb..85e23608405c 100644
--- a/drivers/dma/sdxi/Kconfig
+++ b/drivers/dma/sdxi/Kconfig
@@ -4,6 +4,7 @@ config SDXI_CORE
 	# SDXI 1.0 9 MMIO Control Registers.
 	depends on 64BIT
 	select DMA_ENGINE
+	select DMA_VIRTUAL_CHANNELS
 	help
 	  Enable support for Smart Data Accelerator Interface (SDXI)
 	  Platform Data Mover devices. SDXI is a vendor-neutral
diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
index 1e261fb03225..3a1d36997b44 100644
--- a/drivers/dma/sdxi/Makefile
+++ b/drivers/dma/sdxi/Makefile
@@ -5,6 +5,7 @@ sdxi-core-y := \
 	context.o     \
 	descriptor.o  \
 	device.o      \
+	dma.o         \
 	ring.o
 
 obj-$(CONFIG_SDXI_PCI) += sdxi-pci.o
diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index 30c4e687cedf..265ebea1e350 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -23,6 +23,7 @@
 #include <linux/xarray.h>
 
 #include "context.h"
+#include "dma.h"
 #include "hw.h"
 #include "mmio.h"
 #include "sdxi.h"
@@ -424,6 +425,7 @@ static int sdxi_device_init(struct sdxi_dev *sdxi)
 	if (err)
 		return err;
 
+	sdxi_dma_register(sdxi);
 	return 0;
 }
 
diff --git a/drivers/dma/sdxi/dma.c b/drivers/dma/sdxi/dma.c
new file mode 100644
index 000000000000..512855c83da2
--- /dev/null
+++ b/drivers/dma/sdxi/dma.c
@@ -0,0 +1,509 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SDXI dmaengine provider
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+
+#include <linux/cleanup.h>
+#include <linux/delay.h>
+#include <linux/dev_printk.h>
+#include <linux/container_of.h>
+#include <linux/dma-mapping.h>
+#include <linux/dmaengine.h>
+#include <linux/iopoll.h>
+#include <linux/list.h>
+#include <linux/lockdep.h>
+#include <linux/module.h>
+#include <linux/overflow.h>
+#include <linux/spinlock.h>
+
+#include "../dmaengine.h"
+#include "../virt-dma.h"
+#include "completion.h"
+#include "context.h"
+#include "descriptor.h"
+#include "dma.h"
+#include "ring.h"
+#include "sdxi.h"
+
+static unsigned short dma_channels = 1;
+module_param(dma_channels, ushort, 0644);
+MODULE_PARM_DESC(dma_channels, "DMA channels per function (default: 1)");
+
+/*
+ * Each channel owns an SDXI context. Transactions enter the ring in cookie
+ * order. Each transaction produces one copy descriptor with its own completion
+ * block, and batches end with a shared fenced interrupt descriptor. Each copy
+ * owns its completion block until reaped. Transactions awaiting capacity remain
+ * pending. Termination retains published transactions for reaping while
+ * suppressing their callbacks.
+ */
+
+struct sdxi_dma_chan {
+	struct virt_dma_chan vchan;
+	struct sdxi_cxt *cxt;
+	unsigned int vector;
+	unsigned int irq;
+	struct sdxi_akey_ent *akey;
+	/*
+	 * Transactions awaiting ring slots or completion blocks; protected by
+	 * vchan.lock.
+	 */
+	struct list_head pending;
+};
+
+struct sdxi_dma_txd {
+	struct virt_dma_desc vdesc;
+	struct sdxi_copy copy;	/* Copy operation parameters */
+	/* Completion ownership is acquired at issue and released after reaping. */
+	struct sdxi_completion completion;
+};
+
+static void sdxi_dma_reap_locked(struct sdxi_dma_chan *sdchan);
+
+struct sdxi_dma_dev {
+	struct dma_device dma_dev;
+	size_t nr_channels;
+	struct sdxi_dma_chan sdchan[] __counted_by(nr_channels);
+};
+
+static struct sdxi_dma_chan *to_sdxi_dma_chan(const struct dma_chan *dma_chan)
+{
+	const struct virt_dma_chan *vchan;
+
+	vchan = container_of_const(dma_chan, struct virt_dma_chan, chan);
+	return container_of(vchan, struct sdxi_dma_chan, vchan);
+}
+
+static struct sdxi_dma_txd *
+to_sdxi_dma_txd(const struct virt_dma_desc *vdesc)
+{
+	return container_of(vdesc, struct sdxi_dma_txd, vdesc);
+}
+
+static void sdxi_dma_txd_free(struct virt_dma_desc *vdesc)
+{
+	struct sdxi_dma_txd *txd = to_sdxi_dma_txd(vdesc);
+
+	kfree(txd);
+}
+
+static struct dma_async_tx_descriptor *
+sdxi_dma_prep_memcpy(struct dma_chan *dma_chan, dma_addr_t dst,
+		     dma_addr_t src, size_t len, unsigned long flags)
+{
+	struct sdxi_dma_chan *sdchan = to_sdxi_dma_chan(dma_chan);
+	struct sdxi_cxt *cxt = sdchan->cxt;
+	u16 akey_index = sdxi_akey_index(cxt, sdchan->akey);
+	struct sdxi_dma_txd *txd;
+	struct sdxi_copy copy = {
+		.src = src,
+		.dst = dst,
+		.src_akey = akey_index,
+		.dst_akey = akey_index,
+		.len = len,
+	};
+
+	/*
+	 * Validate now, with a throwaway encode onto the stack. The real
+	 * encode into the ring happens at issue.
+	 */
+	if (sdxi_encode_copy(&(struct sdxi_desc){}, &copy))
+		return NULL;
+
+	txd = kmalloc_obj(*txd, GFP_NOWAIT);
+	if (!txd)
+		return NULL;
+
+	*txd = (typeof(*txd)) {
+		.copy = copy,
+	};
+
+	return vchan_tx_prep(&sdchan->vchan, &txd->vdesc, flags);
+}
+
+static enum dma_status sdxi_tx_status(struct dma_chan *chan,
+				      dma_cookie_t cookie,
+				      struct dma_tx_state *state)
+{
+	struct sdxi_dma_chan *sdchan = to_sdxi_dma_chan(chan);
+	struct virt_dma_desc *vdesc;
+
+	/* Under the lock for a consistent cookie snapshot; the IRQ reaps. */
+	guard(spinlock_irqsave)(&sdchan->vchan.lock);
+
+	/* vchan_find_desc() only returns issued txds, which own a completion. */
+	vdesc = vchan_find_desc(&sdchan->vchan, cookie);
+	if (vdesc) {
+		struct sdxi_dma_txd *txd = to_sdxi_dma_txd(vdesc);
+
+		if (sdxi_cst_blk_check(txd->completion.cst_blk) == SDXI_COMPLETION_ERROR)
+			return DMA_ERROR;
+	}
+
+	return dma_cookie_status(chan, cookie, state);
+}
+
+/*
+ * Fill capacity with complete, fenced batches in cookie order. Return true
+ * if descriptors were published; the caller kicks once with the lock held.
+ */
+static bool sdxi_dma_drain_locked(struct sdxi_dma_chan *sdchan)
+{
+	struct sdxi_cxt *cxt = sdchan->cxt;
+	struct sdxi_ring_state *rs = cxt->ring_state;
+	bool pushed = false;
+
+	lockdep_assert_held(&sdchan->vchan.lock);
+
+	while (!list_empty(&sdchan->pending)) {
+		struct virt_dma_desc *vdesc;
+		struct sdxi_ring_resv resv;
+		struct sdxi_desc *desc;
+		size_t claimed = 0, copies, i = 0;
+
+		/* Claim a pending prefix, stopping at a flag boundary or capacity limit. */
+		list_for_each_entry(vdesc, &sdchan->pending, node) {
+			struct sdxi_dma_txd *txd = to_sdxi_dma_txd(vdesc);
+
+			if (!sdxi_cst_pool_get(cxt->cst_pool, &txd->completion))
+				break;
+			claimed++;
+			if (vdesc->tx.flags & (DMA_PREP_INTERRUPT | DMA_PREP_FENCE) ||
+			    claimed == rs->sq->count - 1)
+				break;
+		}
+		if (!claimed)
+			break;
+
+		/* Ring reservations cannot be undone; acquire completions first. */
+		copies = 0;
+		if (!sdxi_ring_try_reserve_range(rs, 2, claimed + 1, &resv))
+			copies = sdxi_ring_resv_count(&resv) - 1;
+
+		/* Return claims not covered by this (possibly failed) reservation. */
+		list_for_each_entry(vdesc, &sdchan->pending, node) {
+			struct sdxi_dma_txd *txd = to_sdxi_dma_txd(vdesc);
+
+			if (i == claimed)
+				break;
+			if (i++ < copies)
+				continue;
+			sdxi_cst_pool_put(cxt->cst_pool, txd->completion.cst_blk);
+			txd->completion = (struct sdxi_completion) {};
+		}
+		if (!copies)
+			break;
+		for (size_t i = 0; i < copies; i++) {
+			struct sdxi_dma_txd *txd;
+			struct sdxi_slot slot = sdxi_ring_resv_slot(&resv, i);
+
+			vdesc = list_first_entry(&sdchan->pending,
+						struct virt_dma_desc, node);
+			txd = to_sdxi_dma_txd(vdesc);
+			desc = sdxi_slot_desc(slot);
+			(void)sdxi_encode_copy(desc, &txd->copy); /* validated at prep */
+			sdxi_cxt_attach_cst(slot, &txd->completion);
+			sdxi_desc_make_valid(desc);
+			list_move_tail(&vdesc->node, &sdchan->vchan.desc_issued);
+		}
+
+		/*
+		 * FE waits for all copies before notifying and before parsing
+		 * subsequent copies (SDXI 1.0a 5.3, steps 7-9). One terminator
+		 * satisfies both flags and supplies internal completion IRQs.
+		 */
+		desc = sdxi_slot_desc(sdxi_ring_resv_slot(&resv, copies));
+		sdxi_encode_intr(desc, &(const struct sdxi_intr) {
+			.akey = sdxi_akey_index(cxt, sdchan->akey),
+		});
+		sdxi_desc_set_fence(desc);
+		sdxi_desc_make_valid(desc);
+		pushed = true;
+	}
+
+	return pushed;
+}
+
+static void sdxi_dma_issue_pending(struct dma_chan *dma_chan)
+{
+	struct sdxi_dma_chan *sdchan = to_sdxi_dma_chan(dma_chan);
+
+	guard(spinlock_irqsave)(&sdchan->vchan.lock);
+
+	list_splice_tail_init(&sdchan->vchan.desc_submitted, &sdchan->pending);
+	if (sdxi_dma_drain_locked(sdchan))
+		sdxi_cxt_kick(sdchan->cxt);
+}
+
+static int sdxi_dma_terminate_all(struct dma_chan *dma_chan)
+{
+	struct sdxi_dma_chan *sdchan = to_sdxi_dma_chan(dma_chan);
+	struct virt_dma_chan *vchan = &sdchan->vchan;
+	LIST_HEAD(head);
+
+	/*
+	 * Prepared descriptors remain caller-owned. Free submitted and pending
+	 * transactions, and move published transactions to desc_terminated in ring
+	 * order for callback-free reaping.
+	 */
+	scoped_guard(spinlock_irqsave, &vchan->lock) {
+		list_splice_tail_init(&sdchan->pending, &head);
+		list_splice_tail_init(&vchan->desc_submitted, &head);
+		list_splice_tail_init(&vchan->desc_issued, &vchan->desc_terminated);
+	}
+	vchan_dma_desc_free_list(vchan, &head);
+
+	return 0;
+}
+
+/* Bound the wait for issued and pending copies to complete. */
+#define SDXI_DMA_SYNC_TIMEOUT_US	(10 * USEC_PER_SEC)
+
+/*
+ * Reap without relying on the completion IRQ, and report whether the
+ * device is done with every txd that has been or may be placed in the
+ * ring. Pending txds count because dma_chan_put() synchronizes without
+ * terminating first.
+ */
+static bool sdxi_dma_idle(struct sdxi_dma_chan *sdchan)
+{
+	struct virt_dma_chan *vchan = &sdchan->vchan;
+
+	guard(spinlock_irqsave)(&vchan->lock);
+
+	sdxi_dma_reap_locked(sdchan);
+	if (sdxi_dma_drain_locked(sdchan))
+		sdxi_cxt_kick(sdchan->cxt);
+
+	return list_empty(&vchan->desc_terminated) &&
+	       list_empty(&vchan->desc_issued) &&
+	       list_empty(&sdchan->pending);
+}
+
+static void sdxi_dma_synchronize(struct dma_chan *dma_chan)
+{
+	struct sdxi_dma_chan *sdchan = to_sdxi_dma_chan(dma_chan);
+	struct virt_dma_chan *vchan = &sdchan->vchan;
+	LIST_HEAD(head);
+	bool idle;
+	int err;
+
+	/*
+	 * Callers cannot handle failure, so the wait is not interruptible.
+	 * Every completion was reaped under vchan.lock, so the tasklet that
+	 * runs its callback is already scheduled for vchan_synchronize().
+	 */
+	err = read_poll_timeout(sdxi_dma_idle, idle, idle, 100,
+				SDXI_DMA_SYNC_TIMEOUT_US, false, sdchan);
+	if (err) {
+		/*
+		 * Suppress callbacks for outstanding transactions. Completion blocks
+		 * not released by the reaper stay claimed until context teardown.
+		 */
+		scoped_guard(spinlock_irqsave, &vchan->lock) {
+			list_splice_tail_init(&vchan->desc_issued,
+					      &vchan->desc_terminated);
+			list_splice_tail_init(&sdchan->pending, &head);
+		}
+		vchan_dma_desc_free_list(vchan, &head);
+		dev_err(dma_chan->device->dev,
+			"timed out waiting for DMA channel %d to drain\n",
+			dma_chan->chan_id);
+	}
+
+	vchan_synchronize(vchan);
+}
+
+static void sdxi_dma_reap_locked(struct sdxi_dma_chan *sdchan)
+{
+	struct virt_dma_chan *vchan = &sdchan->vchan;
+	struct virt_dma_desc *vdesc, *tmp;
+
+	lockdep_assert_held(&vchan->lock);
+
+	/*
+	 * Terminated txds are still in the ring. Release them once the device
+	 * is done, without completing their cookies or invoking callbacks.
+	 */
+	list_for_each_entry_safe(vdesc, tmp, &vchan->desc_terminated, node) {
+		struct sdxi_dma_txd *txd = to_sdxi_dma_txd(vdesc);
+
+		if (sdxi_cst_blk_check(txd->completion.cst_blk) == SDXI_COMPLETION_PENDING)
+			break;
+
+		list_del(&vdesc->node);
+		sdxi_cst_pool_put(sdchan->cxt->cst_pool, txd->completion.cst_blk);
+		sdxi_dma_txd_free(vdesc);
+	}
+
+	/* Reap completed transactions in cookie order. */
+	while ((vdesc = vchan_next_desc(vchan))) {
+		struct sdxi_dma_txd *txd = to_sdxi_dma_txd(vdesc);
+		enum sdxi_completion_state state;
+
+		state = sdxi_cst_blk_check(txd->completion.cst_blk);
+		if (state == SDXI_COMPLETION_PENDING)
+			break;
+
+		if (state == SDXI_COMPLETION_ERROR)
+			txd->vdesc.tx_result.result = DMA_TRANS_ABORTED;
+
+		list_del(&vdesc->node);
+		sdxi_cst_pool_put(sdchan->cxt->cst_pool, txd->completion.cst_blk);
+		txd->completion = (struct sdxi_completion) {};
+		vchan_cookie_complete(&txd->vdesc);
+	}
+
+	sdxi_ring_wake_up(sdchan->cxt->ring_state);
+}
+
+static irqreturn_t sdxi_dma_cxt_irq(int irq, void *data)
+{
+	struct sdxi_dma_chan *sdchan = data;
+
+	guard(spinlock_irqsave)(&sdchan->vchan.lock);
+
+	sdxi_dma_reap_locked(sdchan);
+	/* Consumed completion blocks may let stalled pending txds proceed. */
+	if (sdxi_dma_drain_locked(sdchan))
+		sdxi_cxt_kick(sdchan->cxt);
+
+	return IRQ_HANDLED;
+}
+
+static int sdxi_dma_alloc_chan_resources(struct dma_chan *dma_chan)
+{
+	struct sdxi_dev *sdxi = dev_get_drvdata(dma_chan->device->dev);
+	struct sdxi_dma_chan *sdchan = to_sdxi_dma_chan(dma_chan);
+	int vector, irq, err;
+
+	sdchan->cxt = sdxi_cxt_new(sdxi);
+	if (!sdchan->cxt)
+		return -ENOMEM;
+	err = vector = sdxi_alloc_vector(sdxi);
+	if (vector < 0)
+		goto exit_cxt;
+
+	sdchan->vector = vector;
+
+	err = irq = sdxi_vector_to_irq(sdxi, vector);
+	if (irq < 0)
+		goto free_vector;
+
+	sdchan->irq = irq;
+
+	/*
+	 * Note this akey entry is used for both the completion
+	 * interrupt and source and destination access for copies.
+	 */
+	sdchan->akey = sdxi_alloc_akey(sdchan->cxt);
+	if (!sdchan->akey) {
+		err = -ENOMEM;
+		goto free_vector;
+	}
+
+	*sdchan->akey = (typeof(*sdchan->akey)) {
+		.intr_num = cpu_to_le16(FIELD_PREP(SDXI_AKEY_ENT_VL, 1) |
+					FIELD_PREP(SDXI_AKEY_ENT_IV, 1) |
+					FIELD_PREP(SDXI_AKEY_ENT_INTR_NUM,
+						   vector)),
+	};
+
+	err = request_irq(sdchan->irq, sdxi_dma_cxt_irq,
+			  IRQF_TRIGGER_NONE, "SDXI DMAengine", sdchan);
+	if (err)
+		goto free_akey;
+
+	err = sdxi_start_cxt(sdchan->cxt);
+	if (err)
+		goto free_irq;
+
+	return 0;
+free_irq:
+	free_irq(sdchan->irq, sdchan);
+free_akey:
+	sdxi_free_akey(sdchan->cxt, sdchan->akey);
+free_vector:
+	sdxi_free_vector(sdxi, vector);
+exit_cxt:
+	sdxi_cxt_exit(sdchan->cxt);
+	return err;
+}
+
+static void sdxi_dma_free_chan_resources(struct dma_chan *dma_chan)
+{
+	struct sdxi_dma_chan *sdchan = to_sdxi_dma_chan(dma_chan);
+	LIST_HEAD(head);
+
+	sdxi_stop_cxt(sdchan->cxt);
+	free_irq(sdchan->irq, sdchan);
+	sdxi_free_vector(sdchan->cxt->sdxi, sdchan->vector);
+	sdxi_free_akey(sdchan->cxt, sdchan->akey);
+	/* virt-dma does not know about the driver's pending list. */
+	scoped_guard(spinlock_irqsave, &sdchan->vchan.lock)
+		list_splice_tail_init(&sdchan->pending, &head);
+	vchan_dma_desc_free_list(&sdchan->vchan, &head);
+	vchan_free_chan_resources(to_virt_chan(dma_chan));
+	sdxi_cxt_exit(sdchan->cxt);
+}
+
+int sdxi_dma_register(struct sdxi_dev *sdxi)
+{
+	struct device *dev = sdxi->dev;
+	struct sdxi_dma_dev *sddev;
+	struct dma_device *dma_dev;
+	unsigned int nr_channels = dma_channels; /* writable module param; snapshot it */
+	int err;
+
+	if (!nr_channels)
+		return 0;
+	/*
+	 * TODO: Require IntrGrp support before registering the DMAengine provider
+	 * (SDXI 1.0a Table 6-1).
+	 */
+
+	sddev = devm_kzalloc(dev, struct_size(sddev, sdchan, nr_channels),
+			     GFP_KERNEL);
+	if (!sddev)
+		return -ENOMEM;
+
+	sddev->nr_channels = nr_channels;
+
+	dma_dev = &sddev->dma_dev;
+	*dma_dev = (typeof(*dma_dev)) {
+		.dev                 = dev,
+		.src_addr_widths     = DMA_SLAVE_BUSWIDTH_64_BYTES,
+		.dst_addr_widths     = DMA_SLAVE_BUSWIDTH_64_BYTES,
+		.directions          = BIT(DMA_MEM_TO_MEM),
+		.residue_granularity = DMA_RESIDUE_GRANULARITY_DESCRIPTOR,
+
+		.device_alloc_chan_resources = sdxi_dma_alloc_chan_resources,
+		.device_free_chan_resources  = sdxi_dma_free_chan_resources,
+
+		.device_prep_dma_memcpy = sdxi_dma_prep_memcpy,
+
+		.device_terminate_all = sdxi_dma_terminate_all,
+		.device_synchronize = sdxi_dma_synchronize,
+		.device_tx_status = sdxi_tx_status,
+		.device_issue_pending = sdxi_dma_issue_pending,
+	};
+
+	dma_cap_set(DMA_MEMCPY, dma_dev->cap_mask);
+	INIT_LIST_HEAD(&dma_dev->channels);
+
+	for (size_t i = 0; i < sddev->nr_channels; ++i) {
+		struct sdxi_dma_chan *sdchan = &sddev->sdchan[i];
+
+		sdchan->vchan.desc_free = sdxi_dma_txd_free;
+		vchan_init(&sdchan->vchan, &sddev->dma_dev);
+		INIT_LIST_HEAD(&sdchan->pending);
+	}
+
+	err = dmaenginem_async_device_register(dma_dev);
+	if (err)
+		return dev_warn_probe(dev, err, "failed to register dma device\n");
+
+	return 0;
+}
diff --git a/drivers/dma/sdxi/dma.h b/drivers/dma/sdxi/dma.h
new file mode 100644
index 000000000000..d38870ea7d91
--- /dev/null
+++ b/drivers/dma/sdxi/dma.h
@@ -0,0 +1,11 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/* Copyright Advanced Micro Devices, Inc. */
+
+#ifndef DMA_SDXI_DMA_H
+#define DMA_SDXI_DMA_H
+
+struct sdxi_dev;
+
+int sdxi_dma_register(struct sdxi_dev *sdxi);
+
+#endif /* DMA_SDXI_DMA_H */

-- 
2.56.0

