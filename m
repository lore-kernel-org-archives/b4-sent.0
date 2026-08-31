From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 31 Aug 2026 14:00:17 -0500
Subject: [PATCH v7 5/8] scsi: ibmvfc: add interrupt routine for
 asynchronous sub CRQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-ibmvfc-fpin-support-v7-5-77d0b9809080@linux.ibm.com>
References: <20260831-ibmvfc-fpin-support-v7-0-77d0b9809080@linux.ibm.com>
In-Reply-To: <20260831-ibmvfc-fpin-support-v7-0-77d0b9809080@linux.ibm.com>
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>, 
 "Martin K. Petersen" <mkp@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, Brian King <brking@linux.ibm.com>, 
 Greg Joyce <gjoyce@linux.ibm.com>, Kyle Mahlkuch <kmahlkuc@linux.ibm.com>, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788202815; l=2764;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=7W2E8wNnNCT6dRKpJAoR0RSGm10kkog2oddF7I2lfCY=;
 b=Dg+2adqbpCsZvOQ8QrGbdBUmYLxSYyjN3twltuhxFvFRy3zJrmhxK3BTqVYySPO3uy0zVQIQb
 JYvlYhJJiwQCs4SzQwR+DeR06GqwZ8HEpJvrquIjQDxtD2MEzTzDDSz
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ibmvfc_interrupt_async_subq(), an IRQ handler dedicated to
asynchronous sub-CRQ events from the adapter. The handler disables
the sub-CRQ IRQ and then calls ibmvfc_drain_async_subq() to consume
all pending entries before re-enabling interrupts. The handler is
marked as __maybe_unused until a later patch when it is used.

ibmvfc_drain_async_subq() holds the per-queue q_lock while
processing. It loops over available CRQ entries via ibmvfc_next_scrq(),
wrapping each in a typed struct ibmvfc_async_crq_event and dispatching
it to ibmvfc_handle_async(), then clears the valid bit and issues a
write barrier. After draining, it re-enables the sub-CRQ IRQ and performs
one final check for a newly arrived entry to close the IRQ-enable race;
if one is found it is processed before exiting the loop.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 50 +++++++++++++++++++++++++++++++++++++
 1 file changed, 50 insertions(+)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 229b06effd4c..a28875c1f983 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -4369,6 +4369,56 @@ static struct ibmvfc_crq *ibmvfc_next_scrq(struct ibmvfc_queue *scrq)
 	return crq;
 }
 
+static void ibmvfc_drain_async_subq(struct ibmvfc_queue *scrq)
+{
+	struct ibmvfc_crq *crq;
+	int done = 0;
+
+	spin_lock(scrq->q_lock);
+	while (!done) {
+		while ((crq = ibmvfc_next_scrq(scrq)) != NULL) {
+			struct ibmvfc_async_crq_event ae = {
+				.type = IBMVFC_ASYNC_CRQ_SUB,
+				.subq = *(struct ibmvfc_async_sub_crq *)crq,
+			};
+			ibmvfc_handle_async(&ae, scrq->vhost);
+			crq->valid = 0;
+			wmb();	/* complete write */
+		}
+
+		ibmvfc_toggle_scrq_irq(scrq, 1);
+		crq = ibmvfc_next_scrq(scrq);
+		if (crq != NULL) {
+			struct ibmvfc_async_crq_event ae = {
+				.type = IBMVFC_ASYNC_CRQ_SUB,
+				.subq = *(struct ibmvfc_async_sub_crq *)crq,
+			};
+			ibmvfc_toggle_scrq_irq(scrq, 0);
+			ibmvfc_handle_async(&ae, scrq->vhost);
+			crq->valid = 0;
+			wmb();	/* complete write */
+		} else
+			done = 1;
+	}
+	spin_unlock(scrq->q_lock);
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
2.55.0

