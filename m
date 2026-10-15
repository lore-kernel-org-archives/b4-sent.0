From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Thu, 15 Oct 2026 10:07:07 -0500
Subject: [PATCH v14 08/11] scsi: ibmvfc: add interrupt routine for
 asynchronous sub CRQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-ibmvfc-fpin-support-v14-8-a0b063b8d825@linux.ibm.com>
References: <20261015-ibmvfc-fpin-support-v14-0-a0b063b8d825@linux.ibm.com>
In-Reply-To: <20261015-ibmvfc-fpin-support-v14-0-a0b063b8d825@linux.ibm.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792076821; l=3347;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=WNVoNGZBEz4/7wCFyOgiP6KjDxMl9VfXNGvmuFjPfuA=;
 b=RVgxExPBnhN4NFcKz905G9iS2IvA7GSOmYcuN2mFZGAzCUnONsoNf5/W1NfXsyEy/ww5xa0y3
 OhEj4e+b5x+Doa/eDy31XjjtSI5EjXOBtuxLIvrGPIC/ITS4Dpao3T0
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ibmvfc_interrupt_async_subq(), an IRQ handler dedicated to
asynchronous sub-CRQ events from the adapter. The handler disables
the sub-CRQ IRQ and then calls ibmvfc_drain_async_subq() to consume
all pending entries before re-enabling interrupts.

Add ibmvfc_next_async_scrq() to traverse the async sub-CRQ ring
directly via msgs.async_scrq[], returning a typed
struct ibmvfc_async_sub_crq * without the cast that would be needed
when going through ibmvfc_next_scrq().

ibmvfc_drain_async_subq() holds the host lock and per-queue q_lock
while processing. It loops over available entries via
ibmvfc_next_async_scrq(), wrapping each in a struct
ibmvfc_async_crq_event and dispatching to ibmvfc_handle_async(),
then clears the valid bit and issues a write barrier. After draining,
it re-enables the sub-CRQ IRQ and performs one final check for a
newly arrived entry to close the IRQ-enable race; if one is found it
is processed before exiting the loop.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
Signed-off-by: Tyrel Datwyler <tyreld@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 66 +++++++++++++++++++++++++++++++++++++
 1 file changed, 66 insertions(+)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 87ee19057551..fc69012efccc 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -4385,6 +4385,72 @@ static struct ibmvfc_crq *ibmvfc_next_scrq(struct ibmvfc_queue *scrq)
 	return crq;
 }
 
+static struct ibmvfc_async_sub_crq *ibmvfc_next_async_scrq(struct ibmvfc_queue *scrq)
+{
+	struct ibmvfc_async_sub_crq *crq;
+
+	crq = &scrq->msgs.async_scrq[scrq->cur];
+	if (crq->valid & 0x80) {
+		if (++scrq->cur == scrq->size)
+			scrq->cur = 0;
+		rmb();
+	} else
+		crq = NULL;
+
+	return crq;
+}
+
+static void ibmvfc_drain_async_subq(struct ibmvfc_queue *scrq)
+{
+	struct ibmvfc_host *vhost = scrq->vhost;
+	struct ibmvfc_async_crq_event ae = {
+		.type = IBMVFC_ASYNC_CRQ_SUB,
+	};
+	struct ibmvfc_async_sub_crq *crq;
+	unsigned long flags;
+	int done = 0;
+
+	spin_lock_irqsave(&vhost->host->host_lock, flags);
+	spin_lock(scrq->q_lock);
+	while (!done) {
+		while ((crq = ibmvfc_next_async_scrq(scrq)) != NULL) {
+			ae.subq = *crq;
+			ibmvfc_handle_async(&ae, scrq->vhost);
+			crq->valid = 0;
+			wmb();	/* complete write */
+		}
+
+		ibmvfc_toggle_scrq_irq(scrq, 1);
+		crq = ibmvfc_next_async_scrq(scrq);
+		if (crq != NULL) {
+			ae.subq = *crq;
+			ibmvfc_toggle_scrq_irq(scrq, 0);
+			ibmvfc_handle_async(&ae, scrq->vhost);
+			crq->valid = 0;
+			wmb();	/* complete write */
+		} else
+			done = 1;
+	}
+	spin_unlock(scrq->q_lock);
+	spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+}
+
+/**
+ * ibmvfc_interrupt_async_subq - Handle an async event from the adapter
+ * @irq:           interrupt request
+ * @scrq_instance: async subq
+ *
+ **/
+static irqreturn_t __maybe_unused ibmvfc_interrupt_async_subq(int irq, void *scrq_instance)
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

-- 
2.56.0

