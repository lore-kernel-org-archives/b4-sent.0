From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 19 Oct 2026 17:15:54 -0500
Subject: [PATCH v15 09/11] scsi: ibmvfc: extend channel reg/dereg helpers
 for async sub-CRQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-ibmvfc-fpin-support-v15-9-a858726e178a@linux.ibm.com>
References: <20261019-ibmvfc-fpin-support-v15-0-a858726e178a@linux.ibm.com>
In-Reply-To: <20261019-ibmvfc-fpin-support-v15-0-a858726e178a@linux.ibm.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792448148; l=4174;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=5womOToxpHLcD0Koo67IAN7Vu9wXmXDzbMbtaAcT9G0=;
 b=OmaBbzwa6atDhWxiFj6O0nm2Zg9A6hTiNkOKMMzI9mvrWQ02PZ9qKg/ZxJ6vlSD7Bq/jrxsPd
 wjxIxMr399wCjfLKLvFoVIivXKHD7kcWSzmVOGfSUyw35/L76Wqs++f
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ibmvfc_register_channel() and ibmvfc_deregister_channel() previously only
handled SCSI and NVMe sub-CRQ channels identified by the channel protocol
(IBMVFC_PROTO_SCSI, IBMVFC_PROTO_NVME). The async sub-CRQ had no
registration path through these helpers, requiring separate handling.

Add a new IBMVFC_PROTO_ASYNC protocol value to enum ibmvfc_protocol.
Extend both functions to handle IBMVFC_PROTO_ASYNC channels: the IRQ is
named "ibmvfc-<addr>-async<index>" and the handler is set to
ibmvfc_interrupt_async_subq rather than the per-protocol
ibmvfc_interrupt_mq handler.

Remove the __maybe_unused annotation from ibmvfc_interrupt_async_subq
now that it is referenced in ibmvfc_register_channel().

Error messages in both paths are updated to include the channel protocol
to distinguish async sub-CRQ failures from SCSI/NVMe sub-CRQ failures.
Kernel-doc headers are added to both functions.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
Signed-off-by: Tyrel Datwyler <tyreld@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 30 +++++++++++++++++++++++++-----
 drivers/scsi/ibmvscsi/ibmvfc.h      |  1 +
 2 files changed, 26 insertions(+), 5 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index c1ee8eb57491..7e012281d368 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -4441,7 +4441,7 @@ static void ibmvfc_drain_async_subq(struct ibmvfc_queue *scrq)
  * @scrq_instance: async subq
  *
  **/
-static irqreturn_t __maybe_unused ibmvfc_interrupt_async_subq(int irq, void *scrq_instance)
+static irqreturn_t ibmvfc_interrupt_async_subq(int irq, void *scrq_instance)
 {
 	struct ibmvfc_queue *scrq = (struct ibmvfc_queue *)scrq_instance;
 
@@ -6831,6 +6831,19 @@ static int ibmvfc_init_crq(struct ibmvfc_host *vhost)
 	return retrc;
 }
 
+/**
+ * ibmvfc_register_channel - Register a sub-CRQ channel with the hypervisor
+ * @vhost:	ibmvfc host struct
+ * @channels:	ibmvfc channels struct containing the channel array and protocol
+ * @index:	index into the channels array for the queue to register
+ *
+ * Register a sub-CRQ with the hypervisor via h_reg_sub_crq, map its hardware
+ * IRQ to a Linux IRQ, and bind an interrupt handler to it. The handler is
+ * selected based on the channel protocol.
+ *
+ * Return value:
+ *	0 on success / non-zero on failure
+ **/
 static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 				   struct ibmvfc_channels *channels,
 				   int index)
@@ -6858,7 +6871,8 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 
 	if (!scrq->irq) {
 		rc = -EINVAL;
-		dev_err(dev, "Error mapping sub-crq[%d] irq\n", index);
+		dev_err(dev, "Error mapping protocol (%d) sub-crq[%d] irq\n",
+			channels->protocol, index);
 		goto irq_failed;
 	}
 
@@ -6873,23 +6887,29 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 			 vdev->unit_address, index);
 		scrq->handler = ibmvfc_interrupt_mq;
 		break;
+	case IBMVFC_PROTO_ASYNC:
+		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-async%d",
+			 vdev->unit_address, index);
+		scrq->handler = ibmvfc_interrupt_async_subq;
+		break;
 	default:
 		dev_err(dev, "Unknown channel protocol (%d)\n",
 			channels->protocol);
 		goto irq_failed;
 	}
 
+	scrq->hwq_id = index;
+
 	rc = request_irq(scrq->irq, scrq->handler, 0, scrq->name, scrq);
 
 	if (rc) {
-		dev_err(dev, "Couldn't register sub-crq[%d] irq\n", index);
+		dev_err(dev, "Couldn't register protocol (%d) sub-crq[%d] irq\n",
+			channels->protocol, index);
 		irq_dispose_mapping(scrq->irq);
 		scrq->irq = 0;
 		goto irq_failed;
 	}
 
-	scrq->hwq_id = index;
-
 	LEAVE;
 	return 0;
 
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index 86b600ec57c7..f77966c85b0e 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -839,6 +839,7 @@ enum ibmvfc_target_action {
 enum ibmvfc_protocol {
 	IBMVFC_PROTO_SCSI = 0,
 	IBMVFC_PROTO_NVME = 1,
+	IBMVFC_PROTO_ASYNC = 2,
 };
 
 struct ibmvfc_target {

-- 
2.56.0

