From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Fri, 10 Jul 2026 14:16:47 -0500
Subject: [PATCH v4 7/8] ibmvfc: register and use asynchronous sub-queue for
 events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-ibmvfc-fpin-support-v4-7-ef031ac19520@linux.ibm.com>
References: <20260710-ibmvfc-fpin-support-v4-0-ef031ac19520@linux.ibm.com>
In-Reply-To: <20260710-ibmvfc-fpin-support-v4-0-ef031ac19520@linux.ibm.com>
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783711016; l=8570;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=F+5kh6fFm7s8bT5nsWjaPZ1sWtnj5CE0r34/4rUN4f8=;
 b=Xcpir/Lzq/zbADFE0sOxxRheC4EDNQ3rbHEDRVi0Bb9ngtI+D3W9HsJFNzf6eX/MDl1kTkzXk
 fJ4JHFCjJ1WDpdUhQUtYIpb1H041mOgEPkYIgx7e8HBxKaolgiophOp
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Complete async sub-queue integration by setting up interrupt handling,
registering the queue as a channel, and enabling its use during NPIV
login.

Add ibmvfc_interrupt_async_subq() interrupt handler and
ibmvfc_drain_async_subq() to process events from the async sub-queue.
Refactor ibmvfc_register_channel() into ibmvfc_register_channel_common()
to support both regular sub-CRQs and the async sub-queue with different
interrupt handlers.

Update ibmvfc_set_login_info() to set IBMVFC_CAN_USE_CHANNELS,
IBMVFC_YES_SCSI, IBMVFC_USE_ASYNC_SUBQ, and IBMVFC_CAN_HANDLE_FPIN
capability bits when channels are enabled, informing VIOS that the client
supports async sub-queue and FPIN handling.

Register async_scrq during channel initialization and unregister during
cleanup.
---
 drivers/scsi/ibmvscsi/ibmvfc.c | 146 ++++++++++++++++++++++++++++++++++-------
 1 file changed, 124 insertions(+), 22 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc.c b/drivers/scsi/ibmvscsi/ibmvfc.c
index ee56f13f1a97..eb786ac24274 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc.c
@@ -1517,7 +1517,9 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 			    IBMVFC_CAN_USE_NOOP_CMD);
 
 	if (vhost->mq_enabled || vhost->using_channels)
-		login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_USE_CHANNELS);
+		login_info->capabilities |=
+			cpu_to_be64(IBMVFC_CAN_USE_CHANNELS | IBMVFC_YES_SCSI |
+				    IBMVFC_USE_ASYNC_SUBQ | IBMVFC_CAN_HANDLE_FPIN);
 
 	login_info->async.va = cpu_to_be64(vhost->async_crq.msg_token);
 	login_info->async.len = cpu_to_be32(async_crq->size *
@@ -4243,6 +4245,52 @@ static struct ibmvfc_crq *ibmvfc_next_scrq(struct ibmvfc_queue *scrq)
 	return crq;
 }
 
+static void ibmvfc_drain_async_subq(struct ibmvfc_queue *scrq)
+{
+	struct ibmvfc_host *vhost = scrq->vhost;
+	struct ibmvfc_crq *crq;
+	unsigned long flags;
+	int done = 0;
+
+	spin_lock_irqsave(vhost->host->host_lock, flags);
+	spin_lock(scrq->q_lock);
+	while (!done) {
+		while ((crq = ibmvfc_next_scrq(scrq)) != NULL) {
+			ibmvfc_handle_async(crq, scrq->vhost, true);
+			crq->valid = 0;
+			wmb();	/* complete write */
+		}
+
+		ibmvfc_toggle_scrq_irq(scrq, 1);
+		crq = ibmvfc_next_scrq(scrq);
+		if (crq != NULL) {
+			ibmvfc_toggle_scrq_irq(scrq, 0);
+			ibmvfc_handle_async(crq, scrq->vhost, true);
+			crq->valid = 0;
+			wmb();	/* complete write */
+		} else
+			done = 1;
+	}
+	spin_unlock(scrq->q_lock);
+	spin_unlock_irqrestore(vhost->host->host_lock, flags);
+}
+
+/**
+ * ibmvfc_interrupt_asyncq - Handle an async event from the adapter
+ * @irq:           interrupt request
+ * @scrq_instance: async subq
+ *
+ **/
+static irqreturn_t ibmvfc_interrupt_async_subq(int irq, void *scrq_instance)
+{
+	struct ibmvfc_queue *scrq = (struct ibmvfc_queue *)scrq_instance;
+
+	ibmvfc_toggle_scrq_irq(scrq, 0);
+	ibmvfc_drain_async_subq(scrq);
+
+	return IRQ_HANDLED;
+}
+
 static void ibmvfc_drain_sub_crq(struct ibmvfc_queue *scrq)
 {
 	struct ibmvfc_crq *crq;
@@ -6340,14 +6388,29 @@ static int ibmvfc_init_crq(struct ibmvfc_host *vhost)
 	return retrc;
 }
 
-static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
-				   struct ibmvfc_channels *channels,
-				   int index)
+/**
+ * ibmvfc_register_channel_common - Register a sub-CRQ with the hypervisor
+ * @vhost:	ibmvfc host struct
+ * @channels:	ibmvfc channels struct
+ * @scrq:	sub-CRQ to register
+ * @index:	channel index (negative for async)
+ * @irq:	interrupt handler for the sub-CRQ
+ *
+ * Return value:
+ *	0 on success / non-zero on failure
+ **/
+static int ibmvfc_register_channel_common(struct ibmvfc_host *vhost,
+					  struct ibmvfc_channels *channels,
+					  struct ibmvfc_queue *scrq,
+					  int index,
+					  irq_handler_t irq)
 {
 	struct device *dev = vhost->dev;
 	struct vio_dev *vdev = to_vio_dev(dev);
-	struct ibmvfc_queue *scrq = &channels->scrqs[index];
+	long hcall_rc;
 	int rc = -ENOMEM;
+	const char *name_suffix;
+	bool is_async = (index < 0);
 
 	ENTER;
 
@@ -6366,20 +6429,19 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 
 	if (!scrq->irq) {
 		rc = -EINVAL;
-		dev_err(dev, "Error mapping sub-crq[%d] irq\n", index);
+		if (is_async)
+			dev_err(dev, "Error mapping sub-crq[%s] irq\n", "async");
+		else
+			dev_err(dev, "Error mapping sub-crq[%d] irq\n", index);
 		goto irq_failed;
 	}
 
 	switch (channels->protocol) {
 	case IBMVFC_PROTO_SCSI:
-		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-scsi%d",
-			 vdev->unit_address, index);
-		scrq->handler = ibmvfc_interrupt_mq;
+		name_suffix = "scsi";
 		break;
 	case IBMVFC_PROTO_NVME:
-		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-nvmf%d",
-			 vdev->unit_address, index);
-		scrq->handler = ibmvfc_interrupt_mq;
+		name_suffix = "nvmf";
 		break;
 	default:
 		dev_err(dev, "Unknown channel protocol (%d)\n",
@@ -6387,35 +6449,63 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 		goto irq_failed;
 	}
 
+	if (is_async) {
+		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-%s%s",
+			 vdev->unit_address, name_suffix, "async");
+		scrq->handler = irq;
+	} else {
+		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-%s%d",
+			 vdev->unit_address, name_suffix, index);
+		scrq->handler = irq ? irq : ibmvfc_interrupt_mq;
+		scrq->hwq_id = index;
+	}
+
 	rc = request_irq(scrq->irq, scrq->handler, 0, scrq->name, scrq);
 
 	if (rc) {
-		dev_err(dev, "Couldn't register sub-crq[%d] irq\n", index);
+		if (is_async)
+			dev_err(dev, "Couldn't register sub-crq[%s] irq\n", "async");
+		else
+			dev_err(dev, "Couldn't register sub-crq[%d] irq\n", index);
 		irq_dispose_mapping(scrq->irq);
 		goto irq_failed;
 	}
 
-	scrq->hwq_id = index;
-
 	LEAVE;
 	return 0;
 
 irq_failed:
 	do {
-		rc = plpar_hcall_norets(H_FREE_SUB_CRQ, vdev->unit_address, scrq->cookie);
-	} while (rc == H_BUSY || H_IS_LONG_BUSY(rc));
+		hcall_rc = plpar_hcall_norets(H_FREE_SUB_CRQ, vdev->unit_address, scrq->cookie);
+	} while (hcall_rc == H_BUSY || H_IS_LONG_BUSY(hcall_rc));
 reg_failed:
 	LEAVE;
 	return rc;
 }
 
+static int ibmvfc_register_channel_async(struct ibmvfc_host *vhost,
+					   struct ibmvfc_channels *channels,
+					   struct ibmvfc_queue *scrq,
+					   irq_handler_t irq)
+{
+	return ibmvfc_register_channel_common(vhost, channels, scrq, -1, irq);
+}
+
+static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
+				   struct ibmvfc_channels *channels,
+				   int index)
+{
+	struct ibmvfc_queue *scrq = &channels->scrqs[index];
+
+	return ibmvfc_register_channel_common(vhost, channels, scrq, index, NULL);
+}
+
 static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 				      struct ibmvfc_channels *channels,
-				      int index)
+				      struct ibmvfc_queue *scrq)
 {
 	struct device *dev = vhost->dev;
 	struct vio_dev *vdev = to_vio_dev(dev);
-	struct ibmvfc_queue *scrq = &channels->scrqs[index];
 	long rc;
 
 	ENTER;
@@ -6430,7 +6520,7 @@ static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 	} while (rc == H_BUSY || H_IS_LONG_BUSY(rc));
 
 	if (rc)
-		dev_err(dev, "Failed to free sub-crq[%d]: rc=%ld\n", index, rc);
+		dev_err(dev, "Failed to free sub-crq[%s]: rc=%ld\n", scrq->name, rc);
 
 	/* Clean out the queue */
 	memset(scrq->msgs.crq, 0, PAGE_SIZE);
@@ -6448,10 +6538,21 @@ static void ibmvfc_reg_sub_crqs(struct ibmvfc_host *vhost,
 	if (!vhost->mq_enabled || !channels->scrqs)
 		return;
 
+	if (ibmvfc_register_channel_async(vhost, channels,
+					  channels->async_scrq,
+					  ibmvfc_interrupt_async_subq)) {
+		vhost->do_enquiry = 0;
+		return;
+	}
+
 	for (i = 0; i < channels->max_queues; i++) {
 		if (ibmvfc_register_channel(vhost, channels, i)) {
 			for (j = i; j > 0; j--)
-				ibmvfc_deregister_channel(vhost, channels, j - 1);
+				ibmvfc_deregister_channel(
+					vhost, channels, &channels->scrqs[j - 1]);
+			ibmvfc_deregister_channel(vhost, channels,
+							channels->async_scrq);
+
 			vhost->do_enquiry = 0;
 			return;
 		}
@@ -6470,7 +6571,8 @@ static void ibmvfc_dereg_sub_crqs(struct ibmvfc_host *vhost,
 		return;
 
 	for (i = 0; i < channels->max_queues; i++)
-		ibmvfc_deregister_channel(vhost, channels, i);
+		ibmvfc_deregister_channel(vhost, channels, &channels->scrqs[i]);
+	ibmvfc_deregister_channel(vhost, channels, channels->async_scrq);
 
 	LEAVE;
 }

-- 
2.55.0

