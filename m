From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 17 Aug 2026 15:27:59 -0500
Subject: [PATCH v6 6/8] scsi: ibmvfc: extend channel registration and
 deregistration for async subq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-ibmvfc-fpin-support-v6-6-62a2d525e70d@linux.ibm.com>
References: <20260817-ibmvfc-fpin-support-v6-0-62a2d525e70d@linux.ibm.com>
In-Reply-To: <20260817-ibmvfc-fpin-support-v6-0-62a2d525e70d@linux.ibm.com>
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-kernel@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, Brian King <brking@linux.ibm.com>, 
 Greg Joyce <gjoyce@linux.ibm.com>, Kyle Mahlkuch <kmahlkuc@linux.ibm.com>, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786998478; l=12073;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=eM/8MBGktPM7uSpS5NtgX4c9oHTmEq/tUy21KvC60sg=;
 b=VJ4dh2WXXVUEx/+J6axHGUGWNoSllzuFwXuaoF4au4SMFID4suym2n6jbj+qLL5nDSz/ayT3m
 RI/jE8BbtfeBxzV5pHm/9NjlmG0EnDC/M0egm32kr7+40kixLfMeJn9
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ibmvfc_register_channel() and ibmvfc_deregister_channel() previously only
handled indexed sub-CRQ channels drawn from the channels->scrqs[] array.
The async sub-CRQ (vhost->async_sub_crq) had no registration path through
these helpers, requiring separate handling.

Extend both functions to accept a negative index as a sentinel value
signalling that the async sub-CRQ should be operated on instead of an
indexed scrq entry. When index < 0, the queue pointer is set to
&vhost->async_sub_crq, the IRQ is named "ibmvfc-<addr>-async", and the
handler is set to ibmvfc_interrupt_async_subq rather than the per-protocol
ibmvfc_interrupt_mq handler. hwq_id assignment is skipped for the async
queue since it has no meaningful hardware queue index.

Error messages in both paths are updated to distinguish async sub-CRQ
failures from indexed sub-CRQ failures. Kernel-doc headers are added to
both functions documenting the negative-index convention.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c  | 102 ++++++++++++++++++++++++-----------
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c |  20 ++++---
 2 files changed, 85 insertions(+), 37 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 23c1a4cb40d9..da34b572518a 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -3501,7 +3501,7 @@ static void ibmvfc_process_async_work(struct work_struct *work)
 		subq = &aw->crq.subq;
 		scsi_id = 0;
 		wwpn = subq->wwpn;
-		node_name = subq->id.node_name;
+		node_name = (subq->flags & IBMVFC_ASYNC_ID_IS_ASSOC_ID) ? 0 : subq->id.node_name;
 	} else {
 		crq = &aw->crq.async_crq;
 		scsi_id = crq->scsi_id;
@@ -3574,7 +3574,7 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_async(void *crq,
 		link_state = subq->link_state;
 		scsi_id = 0;
 		wwpn = subq->wwpn;
-		node_name = subq->id.node_name;
+		node_name = subq->flags & IBMVFC_ASYNC_ID_IS_ASSOC_ID ? 0 : subq->id.node_name;
 	} else {
 		async_crq = crq;
 		event = be64_to_cpu(async_crq->event);
@@ -3677,13 +3677,6 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_async(void *crq,
 		dev_err(vhost->dev, "Unknown async event received: %llu\n", event);
 		break;
 	}
-
-	rmb();
-	if (is_sub_crq)
-		subq->valid = 0;
-	else
-		async_crq->valid = 0;
-	wmb();
 }
 EXPORT_SYMBOL_IF_KUNIT(ibmvfc_handle_async);
 
@@ -6728,13 +6721,29 @@ static int ibmvfc_init_crq(struct ibmvfc_host *vhost)
 	return retrc;
 }
 
+/**
+ * ibmvfc_register_channel - Register a sub-CRQ channel with the hypervisor
+ * @vhost:	ibmvfc host struct
+ * @channels:	ibmvfc channels struct containing the channel array and protocol
+ * @index:	index into the channels array for the queue to register, or
+ *		a negative value to register the async sub-CRQ
+ *
+ * Register a sub-CRQ with the hypervisor via h_reg_sub_crq, map its hardware
+ * IRQ to a Linux IRQ, and bind an interrupt handler to it. The handler is
+ * selected based on the channel protocol (SCSI or NVMe) for normal queues, or
+ * set to the async sub-CRQ handler when @index is negative.
+ *
+ * Return value:
+ *	0 on success / non-zero on failure
+ **/
 static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 				   struct ibmvfc_channels *channels,
 				   int index)
 {
 	struct device *dev = vhost->dev;
 	struct vio_dev *vdev = to_vio_dev(dev);
-	struct ibmvfc_queue *scrq = &channels->scrqs[index];
+	bool is_async = index < 0;
+	struct ibmvfc_queue *scrq = !is_async ? &channels->scrqs[index] : &vhost->async_sub_crq;
 	int rc = -ENOMEM;
 
 	ENTER;
@@ -6754,36 +6763,49 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 
 	if (!scrq->irq) {
 		rc = -EINVAL;
-		dev_err(dev, "Error mapping sub-crq[%d] irq\n", index);
+		if (!is_async)
+			dev_err(dev, "Error mapping sub-crq[%d] irq\n", index);
+		else
+			dev_err(dev, "Error mapping async sub-crq irq\n");
 		goto irq_failed;
 	}
 
-	switch (channels->protocol) {
-	case IBMVFC_PROTO_SCSI:
-		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-scsi%d",
-			 vdev->unit_address, index);
-		scrq->handler = ibmvfc_interrupt_mq;
-		break;
-	case IBMVFC_PROTO_NVME:
-		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-nvmf%d",
-			 vdev->unit_address, index);
-		scrq->handler = ibmvfc_interrupt_mq;
-		break;
-	default:
-		dev_err(dev, "Unknown channel protocol (%d)\n",
-			channels->protocol);
-		goto irq_failed;
+	if (!is_async) {
+		switch (channels->protocol) {
+		case IBMVFC_PROTO_SCSI:
+			snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-scsi%d",
+				 vdev->unit_address, index);
+			scrq->handler = ibmvfc_interrupt_mq;
+			break;
+		case IBMVFC_PROTO_NVME:
+			snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-nvmf%d",
+				 vdev->unit_address, index);
+			scrq->handler = ibmvfc_interrupt_mq;
+			break;
+		default:
+			dev_err(dev, "Unknown channel protocol (%d)\n",
+				channels->protocol);
+			goto irq_failed;
+		}
+	} else {
+		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-async",
+			 vdev->unit_address);
+		scrq->handler = ibmvfc_interrupt_async_subq;
 	}
 
 	rc = request_irq(scrq->irq, scrq->handler, 0, scrq->name, scrq);
 
 	if (rc) {
-		dev_err(dev, "Couldn't register sub-crq[%d] irq\n", index);
+		if (!is_async)
+			dev_err(dev, "Couldn't register sub-crq[%d] irq\n", index);
+		else
+			dev_err(dev, "Couldn't register async sub-crq irq\n");
 		irq_dispose_mapping(scrq->irq);
 		goto irq_failed;
 	}
 
-	scrq->hwq_id = index;
+	if (!is_async)
+		scrq->hwq_id = index;
 
 	LEAVE;
 	return 0;
@@ -6797,13 +6819,26 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 	return rc;
 }
 
+/**
+ * ibmvfc_deregister_channel - Deregister a sub-CRQ channel with the hypervisor
+ * @vhost:	ibmvfc host struct
+ * @channels:	ibmvfc channels struct containing the sub-CRQ array
+ * @index:	index into the sub-CRQ array, or -1 to deregister the
+ *		asynchronous sub-CRQ
+ *
+ * Frees the IRQ, disposes of the IRQ mapping, and calls H_FREE_SUB_CRQ to
+ * release the sub-CRQ with the hypervisor. On success the queue message
+ * buffer is zeroed and the current index is reset. If H_FREE_SUB_CRQ fails,
+ * an error is logged but the channel resources are cleaned up regardless.
+ */
 static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 				      struct ibmvfc_channels *channels,
 				      int index)
 {
 	struct device *dev = vhost->dev;
 	struct vio_dev *vdev = to_vio_dev(dev);
-	struct ibmvfc_queue *scrq = &channels->scrqs[index];
+	bool is_async = index < 0;
+	struct ibmvfc_queue *scrq = !is_async ? &channels->scrqs[index] : &vhost->async_sub_crq;
 	long rc;
 
 	ENTER;
@@ -6817,8 +6852,13 @@ static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 					scrq->cookie);
 	} while (rc == H_BUSY || H_IS_LONG_BUSY(rc));
 
-	if (rc)
-		dev_err(dev, "Failed to free sub-crq[%d]: rc=%ld\n", index, rc);
+	if (rc) {
+		if (!is_async)
+			dev_err(dev, "Failed to free sub-crq[%d]: rc=%ld\n",
+				index, rc);
+		else
+			dev_err(dev, "Failed to free async sub-crq: rc=%ld\n", rc);
+	}
 
 	/* Clean out the queue */
 	memset(scrq->msgs.crq, 0, PAGE_SIZE);
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index 0b29c1e6478b..444e6e6e1c39 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -59,11 +59,13 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 		crq[fs].wwpn = cpu_to_be64(tgt->wwpn);
 		crq[fs].node_name = cpu_to_be64(tgt->ids.node_name);
 		ibmvfc_handle_async(&crq[fs], vhost, false);
+		crq[fs].valid = 0;
+		wmb();
 		msleep(1U);
 	}
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
-	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
 	post[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
 	post[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
 	post[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
@@ -80,7 +82,7 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 			pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED]+1);
 
 	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
-	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
 	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
 	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
@@ -94,10 +96,12 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	crq[0].wwpn = cpu_to_be64(tgt->wwpn);
 	crq[0].node_name = cpu_to_be64(tgt->ids.node_name);
 	ibmvfc_handle_async(&crq[0], vhost, false);
+	crq[0].valid = 0;
+	wmb();
 	msleep(1U);
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
-	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
 	post[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
 	post[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
 	post[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
@@ -163,11 +167,13 @@ static void ibmvfc_full_fpin_test(struct kunit *test)
 		crq[fs].wwpn = cpu_to_be64(tgt->wwpn);
 		crq[fs].id.node_name = cpu_to_be64(tgt->ids.node_name);
 		ibmvfc_handle_async(&crq[fs], vhost, true);
+		crq[fs].valid = 0;
+		wmb();
 		msleep(1U);
 	}
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
-	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
 	post[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
 	post[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
 	post[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
@@ -184,7 +190,7 @@ static void ibmvfc_full_fpin_test(struct kunit *test)
 			pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED]+1);
 
 	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
-	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
 	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
 	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
@@ -197,10 +203,12 @@ static void ibmvfc_full_fpin_test(struct kunit *test)
 	crq[0].wwpn = cpu_to_be64(tgt->wwpn);
 	crq[0].id.node_name = cpu_to_be64(tgt->ids.node_name);
 	ibmvfc_handle_async(&crq[0], vhost, true);
+	crq[0].valid = 0;
+	wmb();
 	msleep(1U);
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
-	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
 	post[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
 	post[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
 	post[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);

-- 
2.55.0

