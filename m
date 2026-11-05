From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Thu, 05 Nov 2026 11:23:03 -0600
Subject: [PATCH v18 10/13] scsi: ibmvfc: add interrupt routine for
 asynchronous sub CRQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ibmvfc-fpin-support-v18-10-d683b74736a3@linux.ibm.com>
References: <20261105-ibmvfc-fpin-support-v18-0-d683b74736a3@linux.ibm.com>
In-Reply-To: <20261105-ibmvfc-fpin-support-v18-0-d683b74736a3@linux.ibm.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793899377; l=5369;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=rzRLzI/0DVNhhsjrydAeA8hyA2ajK90jlhszpnL3xos=;
 b=hOW7hsP8mN/rP31S6HU+jig9QGUur24Tv3AdEsQRFNQ7eNFECoc41qpc0LPB2RQ+bdAroc0yv
 4lPB8AO8UZ9DPWVSz3KwKaXEUvPoAX87gEINWxQJ52fhO2Mw2DLI2w1
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

ibmvfc_drain_async_subq() separates ring drain from event dispatch.
With host_lock and q_lock both held, it loops over available entries
via ibmvfc_next_async_scrq() and passes each one to
ibmvfc_queue_async_subq_entry(). That helper allocates a
struct ibmvfc_async_drain_entry node with kzalloc_obj(..., GFP_ATOMIC),
copies the event into it, and appends it to a local doneq list.
The node is zero-allocated because struct ibmvfc_async_crq_event is a
union and the copied sub-CRQ is smaller than the main CRQ member; the
remaining bytes are later copied wholesale into the FPIN work item. The
valid bit is cleared and a write barrier issued regardless of whether
the allocation succeeded. If the GFP_ATOMIC allocation fails, a
ratelimited error is logged and that event is dropped; it is not
retried. After draining the inner loop, both locks
are still held while the sub-CRQ IRQ is re-enabled and one final
ring check is performed to close the race between the last drain and
IRQ re-enable; any newly arrived entry is collected the same way. Only
after both locks are released does ibmvfc_drain_async_subq() walk doneq,
re-taking host_lock around each ibmvfc_handle_async() call before
freeing the node.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
Signed-off-by: Tyrel Datwyler <tyreld@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 100 ++++++++++++++++++++++++++++++++++++
 1 file changed, 100 insertions(+)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 7406e7182777..5dba084086d5 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -4456,6 +4456,106 @@ static struct ibmvfc_crq *ibmvfc_next_scrq(struct ibmvfc_queue *scrq)
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
+struct ibmvfc_async_drain_entry {
+	struct ibmvfc_async_crq_event event;
+	struct list_head list;
+};
+
+/**
+ * ibmvfc_queue_async_subq_entry - Copy an async sub-CRQ entry to a deferred list
+ * @vhost:	ibmvfc host struct
+ * @crq:	async sub-CRQ entry to consume
+ * @doneq:	list on which to queue the copied event for later dispatch
+ *
+ * Copies @crq into a newly allocated ibmvfc_async_drain_entry and appends it
+ * to @doneq. If the allocation fails, a ratelimited error is logged and the
+ * event is dropped. In either case the entry is returned to the adapter by
+ * clearing its valid bit.
+ **/
+static void ibmvfc_queue_async_subq_entry(struct ibmvfc_host *vhost,
+					  struct ibmvfc_async_sub_crq *crq,
+					  struct list_head *doneq)
+{
+	struct ibmvfc_async_drain_entry *entry;
+
+	entry = kzalloc_obj(*entry, GFP_ATOMIC);
+	if (entry) {
+		entry->event.type = IBMVFC_ASYNC_CRQ_SUB;
+		entry->event.subq = *crq;
+		list_add_tail(&entry->list, doneq);
+	} else
+		dev_err_ratelimited(vhost->dev,
+				    "Couldn't allocate async drain entry\n");
+	crq->valid = 0;
+	wmb();	/* complete write */
+}
+
+static void ibmvfc_drain_async_subq(struct ibmvfc_queue *scrq)
+{
+	struct ibmvfc_host *vhost = scrq->vhost;
+	struct ibmvfc_async_drain_entry *entry, *temp;
+	struct ibmvfc_async_sub_crq *crq;
+	LIST_HEAD(doneq);
+	unsigned long flags;
+	int done = 0;
+
+	spin_lock_irqsave(&vhost->host->host_lock, flags);
+	spin_lock(scrq->q_lock);
+	while (!done) {
+		while ((crq = ibmvfc_next_async_scrq(scrq)) != NULL)
+			ibmvfc_queue_async_subq_entry(vhost, crq, &doneq);
+
+		ibmvfc_toggle_scrq_irq(scrq, 1);
+		crq = ibmvfc_next_async_scrq(scrq);
+		if (crq != NULL) {
+			ibmvfc_toggle_scrq_irq(scrq, 0);
+			ibmvfc_queue_async_subq_entry(vhost, crq, &doneq);
+		} else
+			done = 1;
+	}
+	spin_unlock(scrq->q_lock);
+	spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+
+	list_for_each_entry_safe(entry, temp, &doneq, list) {
+		list_del(&entry->list);
+		spin_lock_irqsave(&vhost->host->host_lock, flags);
+		ibmvfc_handle_async(&entry->event, vhost);
+		spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+		kfree(entry);
+	}
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

