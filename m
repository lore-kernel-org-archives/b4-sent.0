From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Wed, 07 Oct 2026 14:25:53 -0500
Subject: [PATCH v13 09/11] scsi: ibmvfc: extend channel reg/dereg helpers
 for async sub-CRQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261007-ibmvfc-fpin-support-v13-9-b816abfa4fcc@linux.ibm.com>
References: <20261007-ibmvfc-fpin-support-v13-0-b816abfa4fcc@linux.ibm.com>
In-Reply-To: <20261007-ibmvfc-fpin-support-v13-0-b816abfa4fcc@linux.ibm.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791401146; l=5367;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=JDJmhWehR4q7Qm61ouvsxo1Axqijzg1BewhRiLN+/fA=;
 b=abkfIBOAVlSqF/b5z0ecS81BGegBx6VJmD7BPwExYLmXHiK60buYbCcMDUH9HGzjF3VcKnqrZ
 8/MM2izykjpAsnSOkKN2UYEBBzAfeIwlouW8t+q7u2wpm8Qa4EtWI8R
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
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 43 ++++++++++++++++++++++++++++++++-----
 drivers/scsi/ibmvscsi/ibmvfc.h      |  1 +
 2 files changed, 39 insertions(+), 5 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 32bc00a4be7e..76246002ac72 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -4430,7 +4430,7 @@ static void ibmvfc_drain_async_subq(struct ibmvfc_queue *scrq)
  * @scrq_instance: async subq
  *
  **/
-static irqreturn_t __maybe_unused ibmvfc_interrupt_async_subq(int irq, void *scrq_instance)
+static irqreturn_t ibmvfc_interrupt_async_subq(int irq, void *scrq_instance)
 {
 	struct ibmvfc_queue *scrq = (struct ibmvfc_queue *)scrq_instance;
 
@@ -6820,6 +6820,19 @@ static int ibmvfc_init_crq(struct ibmvfc_host *vhost)
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
@@ -6847,7 +6860,8 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 
 	if (!scrq->irq) {
 		rc = -EINVAL;
-		dev_err(dev, "Error mapping sub-crq[%d] irq\n", index);
+		dev_err(dev, "Error mapping protocol (%d) sub-crq[%d] irq\n",
+			channels->protocol, index);
 		goto irq_failed;
 	}
 
@@ -6862,6 +6876,11 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
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
@@ -6871,7 +6890,8 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 	rc = request_irq(scrq->irq, scrq->handler, 0, scrq->name, scrq);
 
 	if (rc) {
-		dev_err(dev, "Couldn't register sub-crq[%d] irq\n", index);
+		dev_err(dev, "Couldn't register protocol (%d) sub-crq[%d] irq\n",
+			channels->protocol, index);
 		irq_dispose_mapping(scrq->irq);
 		scrq->irq = 0;
 		goto irq_failed;
@@ -6891,6 +6911,17 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 	return rc;
 }
 
+/**
+ * ibmvfc_deregister_channel - Deregister a sub-CRQ channel with the hypervisor
+ * @vhost:	ibmvfc host struct
+ * @channels:	ibmvfc channels struct containing the sub-CRQ array
+ * @index:	index into the sub-CRQ array
+ *
+ * Frees the IRQ, disposes of the IRQ mapping, and calls H_FREE_SUB_CRQ to
+ * release the sub-CRQ with the hypervisor. On success the queue message
+ * buffer is zeroed and the current index is reset. If H_FREE_SUB_CRQ fails,
+ * an error is logged but the channel resources are cleaned up regardless.
+ */
 static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 				      struct ibmvfc_channels *channels,
 				      int index)
@@ -6913,8 +6944,10 @@ static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 					scrq->cookie);
 	} while (rc == H_BUSY || H_IS_LONG_BUSY(rc));
 
-	if (rc)
-		dev_err(dev, "Failed to free sub-crq[%d]: rc=%ld\n", index, rc);
+	if (rc) {
+		dev_err(dev, "Failed to free protocol (%d) sub-crq[%d]: rc=%ld\n",
+			channels->protocol, index, rc);
+	}
 
 	/* Clean out the queue */
 	if (scrq->msgs.handle) {
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index ebbcb911f639..1cb6f20b0626 100644
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
2.55.0

