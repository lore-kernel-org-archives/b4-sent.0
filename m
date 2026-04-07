From: Satish Kharat <satishkh@cisco.com>
Date: Mon, 06 Apr 2026 17:37:02 -0700
Subject: [PATCH 04/10] enic: add admin CQ service with MSI-X interrupt and
 NAPI polling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260406-enic-sriov-v2-admin-channel-v2-v1-4-82cc47636a78@cisco.com>
References: <20260406-enic-sriov-v2-admin-channel-v2-v1-0-82cc47636a78@cisco.com>
In-Reply-To: <20260406-enic-sriov-v2-admin-channel-v2-v1-0-82cc47636a78@cisco.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com, 
 Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775522225; l=14030;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=3WUrNO7kGfpAIJkN06TsC/hhQmW3Yd+7+tJKYEj0r7U=;
 b=Q5LhSP9t5AOC9l+OycX1JkBiiczjdBQmqD8fE+DvTi6Jg0aKWoExG1OKNPaPSM0juRuiBhKCN
 Unmr5K12xQvDn/Byh8kP9Rncm8wU/vvrR95LGuui4VCP1BwBjKyPF/+
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add completion queue service for the admin channel WQ and RQ, driven
by an MSI-X interrupt and NAPI polling.

The receive pipeline is: MSI-X ISR -> NAPI poll -> RQ CQ service ->
message enqueue -> workqueue handler -> admin_rq_handler callback.
NAPI drains the RQ CQ in softirq context, copying each received
buffer into an enic_admin_msg and appending it to a spinlock-protected
list.  A system workqueue handler then processes each message in
process context where sleeping (mutex, GFP_KERNEL allocations) is
safe.

The WQ CQ service counts transmit completions and is called from the
synchronous MBOX send path.

RQ buffer allocation uses GFP_ATOMIC since enic_admin_rq_fill() is
called from NAPI context during CQ processing.

The admin channel open/close paths set up and tear down the MSI-X
interrupt, NAPI instance, and workqueue.  CQ init enables interrupt
delivery and sets the interrupt offset so completions trigger the
admin ISR.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic.h       |   7 +
 drivers/net/ethernet/cisco/enic/enic_admin.c | 295 +++++++++++++++++++++++++--
 drivers/net/ethernet/cisco/enic/enic_admin.h |  12 ++
 3 files changed, 292 insertions(+), 22 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index 08472420f3a1..9700fe14e51f 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -296,6 +296,13 @@ struct enic {
 	struct vnic_rq admin_rq;
 	struct vnic_cq admin_cq[2];
 	struct vnic_intr admin_intr;
+	struct napi_struct admin_napi;
+	unsigned int admin_intr_index;
+	struct work_struct admin_msg_work;
+	spinlock_t admin_msg_lock;	/* protects admin_msg_list */
+	struct list_head admin_msg_list;
+	u64 admin_msg_drop_cnt;
+	void (*admin_rq_handler)(struct enic *enic, void *buf, unsigned int len);
 };
 
 static inline struct net_device *vnic_get_netdev(struct vnic_dev *vdev)
diff --git a/drivers/net/ethernet/cisco/enic/enic_admin.c b/drivers/net/ethernet/cisco/enic/enic_admin.c
index a8fcd5f116d1..31f9f754941e 100644
--- a/drivers/net/ethernet/cisco/enic/enic_admin.c
+++ b/drivers/net/ethernet/cisco/enic/enic_admin.c
@@ -4,6 +4,7 @@
 #include <linux/kernel.h>
 #include <linux/netdevice.h>
 #include <linux/dma-mapping.h>
+#include <linux/interrupt.h>
 
 #include "vnic_dev.h"
 #include "vnic_wq.h"
@@ -15,6 +16,7 @@
 #include "enic.h"
 #include "enic_admin.h"
 #include "cq_desc.h"
+#include "cq_enet_desc.h"
 #include "wq_enet_desc.h"
 #include "rq_enet_desc.h"
 
@@ -38,14 +40,14 @@ static void enic_admin_rq_buf_clean(struct vnic_rq *rq,
 	buf->os_buf = NULL;
 }
 
-static int enic_admin_rq_post_one(struct enic *enic)
+static int enic_admin_rq_post_one(struct enic *enic, gfp_t gfp)
 {
 	struct vnic_rq *rq = &enic->admin_rq;
 	struct rq_enet_desc *desc;
 	dma_addr_t dma_addr;
 	void *buf;
 
-	buf = kmalloc(ENIC_ADMIN_BUF_SIZE, GFP_KERNEL);
+	buf = kmalloc(ENIC_ADMIN_BUF_SIZE, gfp);
 	if (!buf)
 		return -ENOMEM;
 
@@ -64,13 +66,13 @@ static int enic_admin_rq_post_one(struct enic *enic)
 	return 0;
 }
 
-static int enic_admin_rq_fill(struct enic *enic)
+static int enic_admin_rq_fill(struct enic *enic, gfp_t gfp)
 {
 	struct vnic_rq *rq = &enic->admin_rq;
 	int err;
 
 	while (vnic_rq_desc_avail(rq) > 0) {
-		err = enic_admin_rq_post_one(enic);
+		err = enic_admin_rq_post_one(enic, gfp);
 		if (err)
 			return err;
 	}
@@ -83,6 +85,205 @@ static void enic_admin_rq_drain(struct enic *enic)
 	vnic_rq_clean(&enic->admin_rq, enic_admin_rq_buf_clean);
 }
 
+static unsigned int enic_admin_cq_color(void *cq_desc, unsigned int desc_size)
+{
+	u8 type_color = *((u8 *)cq_desc + desc_size - 1);
+
+	return (type_color >> CQ_DESC_COLOR_SHIFT) & CQ_DESC_COLOR_MASK;
+}
+
+unsigned int enic_admin_wq_cq_service(struct enic *enic)
+{
+	struct vnic_cq *cq = &enic->admin_cq[0];
+	unsigned int work = 0;
+	void *desc;
+
+	desc = vnic_cq_to_clean(cq);
+	while (enic_admin_cq_color(desc, cq->ring.desc_size) !=
+	       cq->last_color) {
+		/* Ensure color bit is read before descriptor fields */
+		rmb();
+		vnic_cq_inc_to_clean(cq);
+		work++;
+		desc = vnic_cq_to_clean(cq);
+	}
+
+	return work;
+}
+
+static void enic_admin_msg_enqueue(struct enic *enic, void *buf,
+				   unsigned int len)
+{
+	struct enic_admin_msg *msg;
+
+	msg = kmalloc(struct_size(msg, data, len), GFP_ATOMIC);
+	if (!msg) {
+		enic->admin_msg_drop_cnt++;
+		if (net_ratelimit())
+			netdev_warn(enic->netdev,
+				    "admin msg enqueue drop (len=%u drops=%llu)\n",
+				    len, enic->admin_msg_drop_cnt);
+		return;
+	}
+
+	msg->len = len;
+	memcpy(msg->data, buf, len);
+
+	spin_lock(&enic->admin_msg_lock);
+	list_add_tail(&msg->list, &enic->admin_msg_list);
+	spin_unlock(&enic->admin_msg_lock);
+}
+
+unsigned int enic_admin_rq_cq_service(struct enic *enic, unsigned int budget)
+{
+	struct vnic_cq *cq = &enic->admin_cq[1];
+	struct vnic_rq *rq = &enic->admin_rq;
+	struct vnic_rq_buf *buf;
+	unsigned int work = 0;
+	void *desc;
+
+	desc = vnic_cq_to_clean(cq);
+	while (work < budget &&
+	       enic_admin_cq_color(desc, cq->ring.desc_size) !=
+	       cq->last_color) {
+		/* Ensure CQ descriptor fields are read after the color/valid check */
+		rmb();
+		buf = rq->to_clean;
+
+		dma_sync_single_for_cpu(&enic->pdev->dev,
+					buf->dma_addr, buf->len,
+					DMA_FROM_DEVICE);
+
+		enic_admin_msg_enqueue(enic, buf->os_buf, buf->len);
+
+		enic_admin_rq_buf_clean(rq, rq->to_clean);
+		rq->to_clean = rq->to_clean->next;
+		rq->ring.desc_avail++;
+
+		vnic_cq_inc_to_clean(cq);
+		work++;
+		desc = vnic_cq_to_clean(cq);
+	}
+
+	enic_admin_rq_fill(enic, GFP_ATOMIC);
+
+	return work;
+}
+
+static irqreturn_t enic_admin_isr_msix(int irq, void *data)
+{
+	struct napi_struct *napi = data;
+
+	napi_schedule_irqoff(napi);
+
+	return IRQ_HANDLED;
+}
+
+static void enic_admin_msg_work_handler(struct work_struct *work)
+{
+	struct enic *enic = container_of(work, struct enic, admin_msg_work);
+	struct enic_admin_msg *msg, *tmp;
+	LIST_HEAD(local_list);
+
+	spin_lock_bh(&enic->admin_msg_lock);
+	list_splice_init(&enic->admin_msg_list, &local_list);
+	spin_unlock_bh(&enic->admin_msg_lock);
+
+	list_for_each_entry_safe(msg, tmp, &local_list, list) {
+		if (enic->admin_rq_handler)
+			enic->admin_rq_handler(enic, msg->data, msg->len);
+		list_del(&msg->list);
+		kfree(msg);
+	}
+}
+
+static int enic_admin_napi_poll(struct napi_struct *napi, int budget)
+{
+	struct enic *enic = container_of(napi, struct enic, admin_napi);
+	unsigned int credits;
+	unsigned int rq_work;
+
+	credits = vnic_intr_credits(&enic->admin_intr);
+
+	rq_work = enic_admin_rq_cq_service(enic, budget);
+
+	if (rq_work > 0)
+		schedule_work(&enic->admin_msg_work);
+
+	if (rq_work < budget && napi_complete_done(napi, rq_work)) {
+		if (credits)
+			vnic_intr_return_credits(&enic->admin_intr, credits,
+						 1 /* unmask */, 0);
+	} else {
+		if (credits)
+			vnic_intr_return_credits(&enic->admin_intr, credits,
+						 0 /* don't unmask */, 0);
+	}
+
+	return rq_work;
+}
+
+static int enic_admin_setup_intr(struct enic *enic)
+{
+	unsigned int intr_index = enic->intr_count;
+	int err;
+
+	if (vnic_dev_get_intr_mode(enic->vdev) != VNIC_DEV_INTR_MODE_MSIX ||
+	    intr_index >= enic->intr_avail)
+		return -ENODEV;
+
+	err = vnic_intr_alloc(enic->vdev, &enic->admin_intr, intr_index);
+	if (err) {
+		netdev_warn(enic->netdev,
+			    "Failed to alloc admin intr at index %u: %d\n",
+			    intr_index, err);
+		return err;
+	}
+
+	enic->admin_intr_index = intr_index;
+
+	snprintf(enic->msix[intr_index].devname,
+		 sizeof(enic->msix[intr_index].devname),
+		 "%s-admin", enic->netdev->name);
+	enic->msix[intr_index].isr = enic_admin_isr_msix;
+	enic->msix[intr_index].devid = &enic->admin_napi;
+
+	err = request_irq(enic->msix_entry[intr_index].vector,
+			  enic->msix[intr_index].isr, 0,
+			  enic->msix[intr_index].devname,
+			  enic->msix[intr_index].devid);
+	if (err) {
+		netdev_warn(enic->netdev,
+			    "Failed to request admin MSI-X irq: %d\n", err);
+		vnic_intr_free(&enic->admin_intr);
+		return err;
+	}
+
+	enic->msix[intr_index].requested = 1;
+
+	netif_napi_add(enic->netdev, &enic->admin_napi,
+		       enic_admin_napi_poll);
+	napi_enable(&enic->admin_napi);
+
+	netdev_dbg(enic->netdev,
+		   "admin channel using MSI-X interrupt (index %u)\n",
+		   intr_index);
+
+	return 0;
+}
+
+static void enic_admin_teardown_intr(struct enic *enic)
+{
+	unsigned int intr_index = enic->admin_intr_index;
+
+	napi_disable(&enic->admin_napi);
+	netif_napi_del(&enic->admin_napi);
+
+	free_irq(enic->msix_entry[intr_index].vector,
+		 enic->msix[intr_index].devid);
+	enic->msix[intr_index].requested = 0;
+}
+
 static int enic_admin_qp_type_set(struct enic *enic, u32 enable)
 {
 	u64 a0 = QP_TYPE_ADMIN, a1 = enable;
@@ -128,23 +329,8 @@ static int enic_admin_alloc_resources(struct enic *enic)
 	if (err)
 		goto free_cq0;
 
-	/* PFs have dedicated SRIOV_INTR resources for admin channel.
-	 * VFs lack SRIOV_INTR; use a regular INTR_CTRL slot instead.
-	 */
-	if (vnic_dev_get_res_count(enic->vdev, RES_TYPE_SRIOV_INTR) >= 1)
-		err = vnic_intr_alloc_with_type(enic->vdev,
-						&enic->admin_intr, 0,
-						RES_TYPE_SRIOV_INTR);
-	else
-		err = vnic_intr_alloc(enic->vdev, &enic->admin_intr,
-				      enic->intr_count);
-	if (err)
-		goto free_cq1;
-
 	return 0;
 
-free_cq1:
-	vnic_cq_free(&enic->admin_cq[1]);
 free_cq0:
 	vnic_cq_free(&enic->admin_cq[0]);
 free_rq:
@@ -165,10 +351,32 @@ static void enic_admin_free_resources(struct enic *enic)
 
 static void enic_admin_init_resources(struct enic *enic)
 {
+	unsigned int intr_offset = enic->admin_intr_index;
+
 	vnic_wq_init(&enic->admin_wq, 0, 0, 0);
 	vnic_rq_init(&enic->admin_rq, 1, 0, 0);
-	vnic_cq_init(&enic->admin_cq[0], 0, 1, 0, 0, 1, 0, 1, 0, 0, 0);
-	vnic_cq_init(&enic->admin_cq[1], 0, 1, 0, 0, 1, 0, 1, 0, 0, 0);
+	vnic_cq_init(&enic->admin_cq[0],
+		     0 /* flow_control_enable */,
+		     1 /* color_enable */,
+		     0 /* cq_head */,
+		     0 /* cq_tail */,
+		     1 /* cq_tail_color */,
+		     1 /* interrupt_enable */,
+		     1 /* cq_entry_enable */,
+		     0 /* cq_message_enable */,
+		     intr_offset,
+		     0 /* cq_message_addr */);
+	vnic_cq_init(&enic->admin_cq[1],
+		     0 /* flow_control_enable */,
+		     1 /* color_enable */,
+		     0 /* cq_head */,
+		     0 /* cq_tail */,
+		     1 /* cq_tail_color */,
+		     1 /* interrupt_enable */,
+		     1 /* cq_entry_enable */,
+		     0 /* cq_message_enable */,
+		     intr_offset,
+		     0 /* cq_message_addr */);
 	vnic_intr_init(&enic->admin_intr, 0, 0, 1);
 }
 
@@ -187,12 +395,24 @@ int enic_admin_channel_open(struct enic *enic)
 		return err;
 	}
 
+	err = enic_admin_setup_intr(enic);
+	if (err) {
+		netdev_err(enic->netdev,
+			   "Admin channel requires MSI-X, SR-IOV unavailable: %d\n",
+			   err);
+		goto free_resources;
+	}
+
+	spin_lock_init(&enic->admin_msg_lock);
+	INIT_LIST_HEAD(&enic->admin_msg_list);
+	INIT_WORK(&enic->admin_msg_work, enic_admin_msg_work_handler);
+
 	enic_admin_init_resources(enic);
 
 	vnic_wq_enable(&enic->admin_wq);
 	vnic_rq_enable(&enic->admin_rq);
 
-	err = enic_admin_rq_fill(enic);
+	err = enic_admin_rq_fill(enic, GFP_KERNEL);
 	if (err) {
 		netdev_err(enic->netdev,
 			   "Failed to fill admin RQ buffers: %d\n", err);
@@ -206,22 +426,53 @@ int enic_admin_channel_open(struct enic *enic)
 		goto disable_queues;
 	}
 
+	vnic_intr_unmask(&enic->admin_intr);
+
+	netdev_dbg(enic->netdev,
+		   "admin channel open: intr=%u wq_avail=%u rq_avail=%u cq0_color=%u cq1_color=%u\n",
+		   enic->admin_intr_index,
+		   vnic_wq_desc_avail(&enic->admin_wq),
+		   vnic_rq_desc_avail(&enic->admin_rq),
+		   enic->admin_cq[0].last_color,
+		   enic->admin_cq[1].last_color);
+
 	return 0;
 
 disable_queues:
+	enic_admin_teardown_intr(enic);
 	vnic_wq_disable(&enic->admin_wq);
 	vnic_rq_disable(&enic->admin_rq);
 	enic_admin_qp_type_set(enic, 0);
 	enic_admin_rq_drain(enic);
+free_resources:
 	enic_admin_free_resources(enic);
 	return err;
 }
 
+static void enic_admin_msg_drain(struct enic *enic)
+{
+	struct enic_admin_msg *msg, *tmp;
+
+	spin_lock_bh(&enic->admin_msg_lock);
+	list_for_each_entry_safe(msg, tmp, &enic->admin_msg_list, list) {
+		list_del(&msg->list);
+		kfree(msg);
+	}
+	spin_unlock_bh(&enic->admin_msg_lock);
+}
+
 void enic_admin_channel_close(struct enic *enic)
 {
 	if (!enic->has_admin_channel)
 		return;
 
+	netdev_dbg(enic->netdev, "admin channel close\n");
+
+	vnic_intr_mask(&enic->admin_intr);
+	enic_admin_teardown_intr(enic);
+	cancel_work_sync(&enic->admin_msg_work);
+	enic_admin_msg_drain(enic);
+
 	vnic_wq_disable(&enic->admin_wq);
 	vnic_rq_disable(&enic->admin_rq);
 
diff --git a/drivers/net/ethernet/cisco/enic/enic_admin.h b/drivers/net/ethernet/cisco/enic/enic_admin.h
index 569aadeb9312..73cdd3dac7ec 100644
--- a/drivers/net/ethernet/cisco/enic/enic_admin.h
+++ b/drivers/net/ethernet/cisco/enic/enic_admin.h
@@ -9,7 +9,19 @@
 
 struct enic;
 
+/* Wrapper for received admin messages queued for deferred processing.
+ * NAPI enqueues these; a workqueue handler processes them in process context
+ * where sleeping (mutex, GFP_KERNEL) is safe.
+ */
+struct enic_admin_msg {
+	struct list_head list;
+	unsigned int len;
+	u8 data[];
+};
+
 int enic_admin_channel_open(struct enic *enic);
 void enic_admin_channel_close(struct enic *enic);
+unsigned int enic_admin_wq_cq_service(struct enic *enic);
+unsigned int enic_admin_rq_cq_service(struct enic *enic, unsigned int budget);
 
 #endif /* _ENIC_ADMIN_H_ */

-- 
2.43.0

