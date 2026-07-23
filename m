From: Pawel Laszczak <pawell@cadence.com>
Date: Thu, 23 Jul 2026 13:28:27 +0200
Subject: [PATCH] usb: cdnsp: fix wakeup from S3 after controller context
 loss
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-suspend_resume_fix-v1-1-c12a0e8eaffc@cadence.com>
X-B4-Tracking: v=1; b=H4sIANr6YWoC/yXMUQqDMBCE4avIPhuwK1bwKiISzdhuwVSyRgri3
 Rv18RuYfydFECg12U4Bm6h8fcIjz2h8W/+CEZdMXPCzqLk0GnWBd32Axhn9JD8zTK4quXYVW0v
 puASk+Yq23W2NwwfjepboOP5njUVrdgAAAA==
X-Change-ID: 20260723-suspend_resume_fix-bfd5327d52aa
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Peter Chen <peter.chen@nxp.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784806123; l=17774;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=XmqUDOUu7SPhLyEE4GeiiTiklv7xcaqDUT3p4vmdKoM=;
 b=1xBul1uKPnTBJiX7huMsSvMONUI/wrZjbIs+5Bg965r4rdRmFoufzzDcJRm/wcncNxQ2NEL4I
 sf2zYsojMTVDpcbI6hCp67isKVTwt9y+sFM0JzHuw9AZwfNoRdkPitv
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CDNSP controller loses its runtime register programming across S3
suspend/resume. After resume the operational and interrupter registers
may contain reset values, which prevents the gadget side from recovering
correctly and breaks wakeup from S3.

Fix this by reprogramming the controller state required for normal
operation after resume, including the command ring, DCBAA pointer,
doorbell base, event ring, ERST base/size and event ring dequeue
pointer.

Move the basic controller register programming out of the one-time memory
initialization path and make it reusable from the resume path. Also
separate ring allocation from ring initialization so that rings can be
reinitialized without reallocating DMA memory.

This fixes S3 resume on systems where the controller register context is
lost while keeping the existing DMA allocations intact.

Fixes: 3d82904559f4 ("usb: cdnsp: cdns3 Add main part of Cadence USBSSP DRD Driver")
Cc: stable@vger.kernel.org
Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
 drivers/usb/cdns3/cdnsp-gadget.c | 180 ++++++++++++++++++++++++++++++++++++++-
 drivers/usb/cdns3/cdnsp-gadget.h |  31 +++++++
 drivers/usb/cdns3/cdnsp-mem.c    |  98 ++++++++-------------
 drivers/usb/cdns3/cdnsp-ring.c   |   5 ++
 4 files changed, 248 insertions(+), 66 deletions(-)

diff --git a/drivers/usb/cdns3/cdnsp-gadget.c b/drivers/usb/cdns3/cdnsp-gadget.c
index a5275c2fb43b..aa75c628bebf 100644
--- a/drivers/usb/cdns3/cdnsp-gadget.c
+++ b/drivers/usb/cdns3/cdnsp-gadget.c
@@ -1338,7 +1338,6 @@ static int cdnsp_run(struct cdnsp_device *pdev,
 
 	cdnsp_gadget_ep0_desc.wMaxPacketSize = cpu_to_le16(512);
 
-
 	ret = cdnsp_start(pdev);
 	if (ret) {
 		ret = -ENODEV;
@@ -1837,6 +1836,82 @@ static void cdnsp_get_rev_cap(struct cdnsp_device *pdev)
 		 readl(&pdev->rev_cap->tx_buff_size));
 }
 
+static void cdnsp_set_event_deq(struct cdnsp_device *pdev)
+{
+	dma_addr_t deq;
+	u64 temp;
+
+	deq = cdnsp_trb_virt_to_dma(pdev->event_ring->deq_seg,
+				    pdev->event_ring->dequeue);
+
+	/* Update controller event ring dequeue pointer */
+	temp = cdnsp_read_64(&pdev->ir_set->erst_dequeue);
+	temp &= ERST_PTR_MASK;
+
+	/*
+	 * Don't clear the EHB bit (which is RW1C) because
+	 * there might be more events to service.
+	 */
+	temp &= ~ERST_EHB;
+
+	cdnsp_write_64(((u64)deq & (u64)~ERST_PTR_MASK) | temp,
+		       &pdev->ir_set->erst_dequeue);
+}
+
+static void cdnsp_add_interrupter(struct cdnsp_device *pdev)
+{
+	u64 erst_base;
+	u32 erst_size;
+
+	/* Set ERST count with the number of entries in the segment table. */
+	erst_size = readl(&pdev->ir_set->erst_size);
+	erst_size &= ERST_SIZE_MASK;
+	erst_size |= ERST_NUM_SEGS;
+	writel(erst_size, &pdev->ir_set->erst_size);
+
+	/* Set the segment table base address. */
+	erst_base = cdnsp_read_64(&pdev->ir_set->erst_base);
+	erst_base &= ERST_PTR_MASK;
+	erst_base |= (pdev->erst.erst_dma_addr & (u64)~ERST_PTR_MASK);
+	cdnsp_write_64(erst_base, &pdev->ir_set->erst_base);
+
+	/* Set the event ring dequeue address. */
+	cdnsp_set_event_deq(pdev);
+}
+
+/* Set up basic CDNSP registers */
+static void cdnsp_init(struct cdnsp_device *pdev)
+{
+	unsigned int val;
+	u64 val_64;
+
+	val = readl(&pdev->op_regs->config_reg);
+	val |= ((val & ~MAX_DEVS) | CDNSP_DEV_MAX_SLOTS) | CONFIG_U3E;
+	writel(val, &pdev->op_regs->config_reg);
+
+	/* Initialize the Command ring */
+	cdnsp_ring_init(pdev, pdev->cmd_ring);
+
+	/* Set the address in the Command Ring Control register */
+	val_64 = cdnsp_read_64(&pdev->op_regs->cmd_ring);
+	val_64 = (val_64 & (u64)CMD_RING_RSVD_BITS) |
+		 (pdev->cmd_ring->first_seg->dma & (u64)~CMD_RING_RSVD_BITS) |
+		 pdev->cmd_ring->cycle_state;
+	cdnsp_write_64(val_64, &pdev->op_regs->cmd_ring);
+
+	/* Set Device Context Base Address Array pointer */
+	cdnsp_write_64(pdev->dcbaa->dma, &pdev->op_regs->dcbaa_ptr);
+
+	/* Set Doorbell array pointer */
+	val = readl(&pdev->cap_regs->db_off);
+	val &= DBOFF_MASK;
+	pdev->dba = (void __iomem *)pdev->cap_regs + val;
+
+	/* Initialize the Primary interrupter */
+	cdnsp_ring_init(pdev, pdev->event_ring);
+	cdnsp_add_interrupter(pdev);
+}
+
 static int cdnsp_gen_setup(struct cdnsp_device *pdev)
 {
 	int ret;
@@ -1902,6 +1977,8 @@ static int cdnsp_gen_setup(struct cdnsp_device *pdev)
 	if (ret)
 		return ret;
 
+	cdnsp_init(pdev);
+
 	/*
 	 * Software workaround for U1: after transition
 	 * to U1 the controller starts gating clock, and in some cases,
@@ -2026,10 +2103,42 @@ static void cdnsp_gadget_exit(struct cdns *cdns)
 	cdns_drd_gadget_off(cdns);
 }
 
+static void cdnsp_save_registers(struct cdnsp_device *pdev)
+{
+	struct cdnsp_s3_save *s3 = &pdev->s3;
+
+	s3->command = readl(&pdev->op_regs->command);
+	s3->dnctrl = readl(&pdev->op_regs->dnctrl);
+	s3->dcbaa_ptr = cdnsp_read_64(&pdev->op_regs->dcbaa_ptr);
+	s3->config_reg = readl(&pdev->op_regs->config_reg);
+	s3->s3_erst_size = readl(&pdev->ir_set->erst_size);
+	s3->s3_erst_base = cdnsp_read_64(&pdev->ir_set->erst_base);
+	s3->s3_erst_dequeue = cdnsp_read_64(&pdev->ir_set->erst_dequeue);
+	s3->s3_irq_pending = readl(&pdev->ir_set->irq_pending);
+	s3->s3_irq_control = readl(&pdev->ir_set->irq_control);
+}
+
+static void cdnsp_restore_registers(struct cdnsp_device *pdev)
+{
+	struct cdnsp_s3_save *s3 = &pdev->s3;
+
+	writel(s3->command, &pdev->op_regs->command);
+	writel(s3->dnctrl, &pdev->op_regs->dnctrl);
+	cdnsp_write_64(s3->dcbaa_ptr, &pdev->op_regs->dcbaa_ptr);
+	writel(s3->config_reg, &pdev->op_regs->config_reg);
+	writel(s3->s3_erst_size, &pdev->ir_set->erst_size);
+	cdnsp_write_64(s3->s3_erst_base, &pdev->ir_set->erst_base);
+	cdnsp_write_64(s3->s3_erst_dequeue, &pdev->ir_set->erst_dequeue);
+	writel(s3->s3_irq_pending, &pdev->ir_set->irq_pending);
+	writel(s3->s3_irq_control, &pdev->ir_set->irq_control);
+}
+
 static int cdnsp_gadget_suspend(struct cdns *cdns, bool do_wakeup)
 {
 	struct cdnsp_device *pdev = cdns->gadget_dev;
 	unsigned long flags;
+	u32 val;
+	int ret;
 
 	if (pdev->link_state == XDEV_U3)
 		return 0;
@@ -2037,9 +2146,22 @@ static int cdnsp_gadget_suspend(struct cdns *cdns, bool do_wakeup)
 	spin_lock_irqsave(&pdev->lock, flags);
 	cdnsp_disconnect_gadget(pdev);
 	cdnsp_stop(pdev);
+
+	cdnsp_save_registers(pdev);
+
+	val = readl(&pdev->op_regs->command);
+	val |= CMD_CSS;
+	writel(val, &pdev->op_regs->command);
+
+	ret = readl_poll_timeout_atomic(&pdev->op_regs->status, val,
+					!(val & STS_SSS), 1,
+					20 * 1000);
+	if (ret)
+		ret = -EIO;
+
 	spin_unlock_irqrestore(&pdev->lock, flags);
 
-	return 0;
+	return ret;
 }
 
 static int cdnsp_gadget_resume(struct cdns *cdns, bool lost_power)
@@ -2047,12 +2169,63 @@ static int cdnsp_gadget_resume(struct cdns *cdns, bool lost_power)
 	struct cdnsp_device *pdev = cdns->gadget_dev;
 	enum usb_device_speed max_speed;
 	unsigned long flags;
+	bool wakeup = false;
+	u32 val;
 	int ret;
 
 	if (!pdev->gadget_driver)
 		return 0;
 
 	spin_lock_irqsave(&pdev->lock, flags);
+	val = readl(&pdev->port3x_regs->mode_2);
+
+	if (val & CFG_3XPORT_U1_PIPE_CLK_GATE_EN || lost_power) {
+		cdnsp_halt(pdev);
+		cdnsp_set_apb_timeout_value(pdev);
+
+		/* Reset the internal controller memory state and registers. */
+		ret = cdnsp_reset(pdev);
+		if (ret)
+			goto unlock;
+
+		val = readl(&pdev->port3x_regs->mode_2);
+		val &= ~CFG_3XPORT_U1_PIPE_CLK_GATE_EN;
+		writel(val, &pdev->port3x_regs->mode_2);
+
+		cdnsp_clear_cmd_ring(pdev);
+
+		memset(pdev->event_ring->first_seg->trbs, 0,
+		       sizeof(union cdnsp_trb) * (TRBS_PER_SEGMENT));
+
+		cdnsp_init(pdev);
+	} else {
+		ret = readl_poll_timeout_atomic(&pdev->op_regs->status, val,
+						!(val & STS_CNR), 1,
+						10 * 1000 * 1000);
+		if (ret) {
+			dev_err(pdev->dev, "ERROR: Controller not ready to work\n");
+			spin_unlock_irqrestore(&pdev->lock, flags);
+			return ret;
+		}
+
+		cdnsp_restore_registers(pdev);
+
+		/* Initiate Controller Restore State (CRS) */
+		val = readl(&pdev->op_regs->command);
+		val |= CMD_CRS;
+		writel(val, &pdev->op_regs->command);
+
+		ret = readl_poll_timeout_atomic(&pdev->op_regs->status, val,
+						!(val & STS_RSS), 1, 100000);
+		if (ret) {
+			dev_err(pdev->dev, "Restore state did not complete (timeout)\n");
+			ret = -ETIMEDOUT;
+			goto unlock;
+		}
+
+		wakeup = true;
+	}
+
 	max_speed = pdev->gadget_driver->max_speed;
 
 	/* Limit speed if necessary. */
@@ -2060,9 +2233,10 @@ static int cdnsp_gadget_resume(struct cdns *cdns, bool lost_power)
 
 	ret = cdnsp_run(pdev, max_speed);
 
-	if (pdev->link_state == XDEV_U3)
+	if (pdev->link_state == XDEV_U3 && wakeup)
 		__cdnsp_gadget_wakeup(pdev);
 
+unlock:
 	spin_unlock_irqrestore(&pdev->lock, flags);
 
 	return ret;
diff --git a/drivers/usb/cdns3/cdnsp-gadget.h b/drivers/usb/cdns3/cdnsp-gadget.h
index c44bca348a41..6c45fd3e4a9d 100644
--- a/drivers/usb/cdns3/cdnsp-gadget.h
+++ b/drivers/usb/cdns3/cdnsp-gadget.h
@@ -1353,6 +1353,34 @@ struct cdnsp_port {
 #define CDNSP_EXT_PORT_OFF(x)		((x) & 0xff)
 #define CDNSP_EXT_PORT_COUNT(x)		(((x) >> 8) & 0xff)
 
+/**
+ * struct cdnsp_s3_save - register context saved before S3 suspend.
+ * @command: Saved USB command register value.
+ * @dnctrl: Saved device notification control register value.
+ * @dcbaa_ptr: Saved Device Context Base Address Array pointer.
+ * @config_reg: Saved configuration register value.
+ * @s3_irq_pending: Saved interrupter pending register value.
+ * @s3_irq_control: Saved interrupter control register value.
+ * @s3_erst_size: Saved Event Ring Segment Table size.
+ * @s3_erst_base: Saved Event Ring Segment Table base address.
+ * @s3_erst_dequeue: Saved Event Ring Dequeue Pointer.
+ *
+ * Stores the controller register state that may be lost across S3
+ * suspend/resume. The saved values are used to restore the CDNSP
+ * operational and interrupter register programming after resume.
+ */
+struct cdnsp_s3_save {
+	u32	command;
+	u32	dnctrl;
+	u64	dcbaa_ptr;
+	u32	config_reg;
+	u32	s3_irq_pending;
+	u32	s3_irq_control;
+	u32	s3_erst_size;
+	u64	s3_erst_base;
+	u64	s3_erst_dequeue;
+};
+
 /**
  * struct cdnsp_device - represent USB device.
  * @dev: Pointer to device structure associated whit this controller.
@@ -1388,6 +1416,7 @@ struct cdnsp_port {
  * @cmd: Represent all what is needed to issue command on Command Ring.
  * @event_ring: Event ring.
  * @erst: Event Ring Segment table
+ * @s3:  Register values saved before entering S3.
  * @slot_id: Current Slot ID. Should be 0 or 1.
  * @out_ctx: Output context.
  * @in_ctx: Input context.
@@ -1447,6 +1476,7 @@ struct cdnsp_device {
 	struct cdnsp_command cmd;
 	struct cdnsp_ring *event_ring;
 	struct cdnsp_erst erst;
+	struct cdnsp_s3_save s3;
 	int slot_id;
 
 	/*
@@ -1510,6 +1540,7 @@ int cdnsp_endpoint_init(struct cdnsp_device *pdev,
 int cdnsp_ring_expansion(struct cdnsp_device *pdev,
 			 struct cdnsp_ring *ring,
 			 unsigned int num_trbs, gfp_t flags);
+void cdnsp_ring_init(struct cdnsp_device *pdev, struct cdnsp_ring *ring);
 struct cdnsp_ring *cdnsp_dma_to_transfer_ring(struct cdnsp_ep *ep, u64 address);
 int cdnsp_alloc_stream_info(struct cdnsp_device *pdev,
 			    struct cdnsp_ep *pep,
diff --git a/drivers/usb/cdns3/cdnsp-mem.c b/drivers/usb/cdns3/cdnsp-mem.c
index 5d8cdc91927d..0be917f52bbb 100644
--- a/drivers/usb/cdns3/cdnsp-mem.c
+++ b/drivers/usb/cdns3/cdnsp-mem.c
@@ -394,13 +394,6 @@ static struct cdnsp_ring *cdnsp_ring_alloc(struct cdnsp_device *pdev,
 	if (ret)
 		goto fail;
 
-	/* Only event ring does not use link TRB. */
-	if (type != TYPE_EVENT)
-		ring->last_seg->trbs[TRBS_PER_SEGMENT - 1].link.control |=
-			cpu_to_le32(LINK_TOGGLE);
-
-	cdnsp_initialize_ring_info(ring);
-	trace_cdnsp_ring_alloc(ring);
 	return ring;
 fail:
 	kfree(ring);
@@ -603,6 +596,7 @@ int cdnsp_alloc_stream_info(struct cdnsp_device *pdev,
 		if (!cur_ring)
 			goto cleanup_rings;
 
+		cdnsp_ring_init(pdev, cur_ring);
 		cur_ring->stream_id = cur_stream;
 		cur_ring->trb_address_map = &stream_info->trb_address_map;
 
@@ -696,6 +690,8 @@ static int cdnsp_alloc_priv_device(struct cdnsp_device *pdev)
 	if (!pdev->eps[0].ring)
 		goto fail;
 
+	cdnsp_ring_init(pdev, pdev->eps[0].ring);
+
 	/* Point to output device context in dcbaa. */
 	pdev->dcbaa->dev_context_ptrs[1] = cpu_to_le64(pdev->out_ctx.dma);
 	pdev->cmd.in_ctx = &pdev->in_ctx;
@@ -989,6 +985,8 @@ int cdnsp_endpoint_init(struct cdnsp_device *pdev,
 	if (!pep->ring)
 		return -ENOMEM;
 
+	cdnsp_ring_init(pdev, pep->ring);
+
 	pep->skip = false;
 
 	/* Fill the endpoint context */
@@ -1094,28 +1092,6 @@ void cdnsp_mem_cleanup(struct cdnsp_device *pdev)
 	pdev->active_port = NULL;
 }
 
-static void cdnsp_set_event_deq(struct cdnsp_device *pdev)
-{
-	dma_addr_t deq;
-	u64 temp;
-
-	deq = cdnsp_trb_virt_to_dma(pdev->event_ring->deq_seg,
-				    pdev->event_ring->dequeue);
-
-	/* Update controller event ring dequeue pointer */
-	temp = cdnsp_read_64(&pdev->ir_set->erst_dequeue);
-	temp &= ERST_PTR_MASK;
-
-	/*
-	 * Don't clear the EHB bit (which is RW1C) because
-	 * there might be more events to service.
-	 */
-	temp &= ~ERST_EHB;
-
-	cdnsp_write_64(((u64)deq & (u64)~ERST_PTR_MASK) | temp,
-		       &pdev->ir_set->erst_dequeue);
-}
-
 static void cdnsp_add_in_port(struct cdnsp_device *pdev,
 			      struct cdnsp_port *port,
 			      __le32 __iomem *addr)
@@ -1224,6 +1200,36 @@ static int cdnsp_setup_port_arrays(struct cdnsp_device *pdev)
 	return 0;
 }
 
+static void cdnsp_initialize_ring_segments(struct cdnsp_device *pdev, struct cdnsp_ring *ring)
+{
+	struct cdnsp_segment *seg;
+
+	/* Only event ring does not use link TRB. */
+	if (ring->type == TYPE_EVENT)
+		return;
+
+	seg = ring->first_seg;
+
+	while (seg) {
+		struct cdnsp_segment *next = seg->next;
+
+		cdnsp_link_segments(pdev, seg, next, ring->type);
+		if (next == ring->first_seg)
+			break;
+
+		seg = next;
+	}
+
+	ring->last_seg->trbs[TRBS_PER_SEGMENT - 1].link.control |= cpu_to_le32(LINK_TOGGLE);
+}
+
+void cdnsp_ring_init(struct cdnsp_device *pdev, struct cdnsp_ring *ring)
+{
+	cdnsp_initialize_ring_segments(pdev, ring);
+	cdnsp_initialize_ring_info(ring);
+	trace_cdnsp_ring_alloc(ring);
+}
+
 /*
  * Initialize memory for CDNSP (one-time init).
  *
@@ -1235,10 +1241,8 @@ int cdnsp_mem_init(struct cdnsp_device *pdev)
 {
 	struct device *dev = pdev->dev;
 	int ret = -ENOMEM;
-	unsigned int val;
 	dma_addr_t dma;
 	u32 page_size;
-	u64 val_64;
 
 	/*
 	 * Use 4K pages, since that's common and the minimum the
@@ -1246,10 +1250,6 @@ int cdnsp_mem_init(struct cdnsp_device *pdev)
 	 */
 	page_size = 1 << 12;
 
-	val = readl(&pdev->op_regs->config_reg);
-	val |= ((val & ~MAX_DEVS) | CDNSP_DEV_MAX_SLOTS) | CONFIG_U3E;
-	writel(val, &pdev->op_regs->config_reg);
-
 	/*
 	 * Doorbell array must be physically contiguous
 	 * and 64-byte (cache line) aligned.
@@ -1261,8 +1261,6 @@ int cdnsp_mem_init(struct cdnsp_device *pdev)
 
 	pdev->dcbaa->dma = dma;
 
-	cdnsp_write_64(dma, &pdev->op_regs->dcbaa_ptr);
-
 	/*
 	 * Initialize the ring segment pool.  The ring must be a contiguous
 	 * structure comprised of TRBs. The TRBs must be 16 byte aligned,
@@ -1288,17 +1286,6 @@ int cdnsp_mem_init(struct cdnsp_device *pdev)
 	if (!pdev->cmd_ring)
 		goto destroy_device_pool;
 
-	/* Set the address in the Command Ring Control register */
-	val_64 = cdnsp_read_64(&pdev->op_regs->cmd_ring);
-	val_64 = (val_64 & (u64)CMD_RING_RSVD_BITS) |
-		 (pdev->cmd_ring->first_seg->dma & (u64)~CMD_RING_RSVD_BITS) |
-		 pdev->cmd_ring->cycle_state;
-	cdnsp_write_64(val_64, &pdev->op_regs->cmd_ring);
-
-	val = readl(&pdev->cap_regs->db_off);
-	val &= DBOFF_MASK;
-	pdev->dba = (void __iomem *)pdev->cap_regs + val;
-
 	/* Set ir_set to interrupt register set 0 */
 	pdev->ir_set = &pdev->run_regs->ir_set[0];
 
@@ -1315,21 +1302,6 @@ int cdnsp_mem_init(struct cdnsp_device *pdev)
 	if (ret)
 		goto free_event_ring;
 
-	/* Set ERST count with the number of entries in the segment table. */
-	val = readl(&pdev->ir_set->erst_size);
-	val &= ERST_SIZE_MASK;
-	val |= ERST_NUM_SEGS;
-	writel(val, &pdev->ir_set->erst_size);
-
-	/* Set the segment table base address. */
-	val_64 = cdnsp_read_64(&pdev->ir_set->erst_base);
-	val_64 &= ERST_PTR_MASK;
-	val_64 |= (pdev->erst.erst_dma_addr & (u64)~ERST_PTR_MASK);
-	cdnsp_write_64(val_64, &pdev->ir_set->erst_base);
-
-	/* Set the event ring dequeue address. */
-	cdnsp_set_event_deq(pdev);
-
 	ret = cdnsp_setup_port_arrays(pdev);
 	if (ret)
 		goto free_erst;
diff --git a/drivers/usb/cdns3/cdnsp-ring.c b/drivers/usb/cdns3/cdnsp-ring.c
index 715658c981ff..66efb5dad58b 100644
--- a/drivers/usb/cdns3/cdnsp-ring.c
+++ b/drivers/usb/cdns3/cdnsp-ring.c
@@ -61,6 +61,7 @@
 #include <linux/slab.h>
 #include <linux/irq.h>
 
+#include "core.h"
 #include "cdnsp-trace.h"
 #include "cdnsp-gadget.h"
 
@@ -1575,9 +1576,13 @@ irqreturn_t cdnsp_thread_irq_handler(int irq, void *data)
 irqreturn_t cdnsp_irq_handler(int irq, void *priv)
 {
 	struct cdnsp_device *pdev = (struct cdnsp_device *)priv;
+	struct cdns *cdns = dev_get_drvdata(pdev->dev);
 	u32 irq_pending;
 	u32 status;
 
+	if (cdns->in_lpm)
+		return IRQ_NONE;
+
 	status = readl(&pdev->op_regs->status);
 
 	if (status == ~(u32)0) {

---
base-commit: abe651837cb394f76d738a7a747322fca3bf17ba
change-id: 20260723-suspend_resume_fix-bfd5327d52aa

Best regards,
--  
Pawel Laszczak <pawell@cadence.com>

