From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Thu, 15 Oct 2026 10:07:04 -0500
Subject: [PATCH v14 05/11] scsi: ibmvfc: add NOOP command support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-ibmvfc-fpin-support-v14-5-a0b063b8d825@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792076820; l=4964;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=vnA8TM32RSDLRijz6T07CNbPtZpZ3/+HXqbwADXe+L4=;
 b=Cw6YHF6xRgFYF8QRpv9c5I526OI22aW6RsXf3U+OKqga/zIqn/cSF8cehOIXTstglCJp9HVY1
 aeOqQ09U0MFBvj1UUTogYb2TMk/jCVmf+bUU+aja4DNM+PJzA9fuPUr
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for handling IBMVFC_NOOP format CRQ messages from the
VIOS partner.

Advertise the client's ability to handle NOOP commands by setting the
IBMVFC_CAN_USE_NOOP_CMD capability in ibmvfc_set_login_info().

Handle and ignore IBMVFC_NOOP format messages in both ibmvfc_handle_crq()
and ibmvfc_handle_scrq(). In both handlers, log a rate-limited error if a
NOOP is received while in the IBMVFC_ACTIVE state without the partner
having advertised IBMVFC_SUPPORT_NOOP_CMD.

In ibmvfc_handle_scrq(), also fix a typo ("Got and invalid" -> "Got an
invalid"), add a missing return on invalid message types, and guard
against null event pointers before processing CRQ responses.

Change ibmvfc_handle_scrq() to take a struct ibmvfc_queue *scrq
parameter instead of struct ibmvfc_host *vhost, deriving vhost from
scrq->vhost internally. Use &scrq->evt_pool for event validation instead
of &evt->queue->evt_pool, avoiding a potential wild pointer dereference
if crq->ioba contains a non-zero garbage token before ibmvfc_valid_event()
has a chance to validate it.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
Acked-by: Tyrel Datwyler <tyreld@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 36 ++++++++++++++++++++++++++++++------
 1 file changed, 30 insertions(+), 6 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 871decab2985..9c710897cd54 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -1578,7 +1578,9 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 		login_info->flags |= cpu_to_be16(IBMVFC_CLIENT_MIGRATED);
 
 	login_info->max_cmds = cpu_to_be32(max_cmds);
-	login_info->capabilities = cpu_to_be64(IBMVFC_CAN_MIGRATE | IBMVFC_CAN_SEND_VF_WWPN);
+	login_info->capabilities =
+		cpu_to_be64(IBMVFC_CAN_MIGRATE | IBMVFC_CAN_SEND_VF_WWPN |
+			    IBMVFC_CAN_USE_NOOP_CMD);
 
 	if (vhost->mq_enabled || vhost->using_channels) {
 		login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_USE_CHANNELS);
@@ -3704,6 +3706,14 @@ static void ibmvfc_handle_crq(struct ibmvfc_crq *crq, struct ibmvfc_host *vhost,
 	if (crq->format == IBMVFC_ASYNC_EVENT)
 		return;
 
+	if (crq->format == IBMVFC_NOOP) {
+		if (vhost->state == IBMVFC_ACTIVE &&
+		    !ibmvfc_check_caps(vhost, IBMVFC_SUPPORT_NOOP_CMD))
+			dev_err_ratelimited(vhost->dev,
+					    "Received unexpected NOOP command from partner\n");
+		return;
+	}
+
 	/* The only kind of payload CRQs we should get are responses to
 	 * things we send. Make sure this response is to something we
 	 * actually sent
@@ -4223,9 +4233,10 @@ static int ibmvfc_toggle_scrq_irq(struct ibmvfc_queue *scrq, int enable)
 	return rc;
 }
 
-static void ibmvfc_handle_scrq(struct ibmvfc_crq *crq, struct ibmvfc_host *vhost,
+static void ibmvfc_handle_scrq(struct ibmvfc_crq *crq, struct ibmvfc_queue *scrq,
 			       struct list_head *evt_doneq)
 {
+	struct ibmvfc_host *vhost = scrq->vhost;
 	struct ibmvfc_event *evt = (struct ibmvfc_event *)be64_to_cpu(crq->ioba);
 
 	switch (crq->valid) {
@@ -4234,7 +4245,20 @@ static void ibmvfc_handle_scrq(struct ibmvfc_crq *crq, struct ibmvfc_host *vhost
 	case IBMVFC_CRQ_XPORT_EVENT:
 		return;
 	default:
-		dev_err(vhost->dev, "Got and invalid message type 0x%02x\n", crq->valid);
+		dev_err(vhost->dev, "Got an invalid message type 0x%02x\n", crq->valid);
+		return;
+	}
+
+	if (crq->format == IBMVFC_NOOP) {
+		if (vhost->state == IBMVFC_ACTIVE &&
+		    !ibmvfc_check_caps(vhost, IBMVFC_SUPPORT_NOOP_CMD))
+			dev_err_ratelimited(vhost->dev,
+					    "Received unexpected NOOP command from partner\n");
+		return;
+	}
+
+	if (unlikely(!evt)) {
+		dev_err(vhost->dev, "Received null event\n");
 		return;
 	}
 
@@ -4242,7 +4266,7 @@ static void ibmvfc_handle_scrq(struct ibmvfc_crq *crq, struct ibmvfc_host *vhost
 	 * things we send. Make sure this response is to something we
 	 * actually sent
 	 */
-	if (unlikely(!ibmvfc_valid_event(&evt->queue->evt_pool, evt))) {
+	if (unlikely(!ibmvfc_valid_event(&scrq->evt_pool, evt))) {
 		dev_err(vhost->dev, "Returned correlation_token 0x%08llx is invalid!\n",
 			crq->ioba);
 		return;
@@ -4285,7 +4309,7 @@ static void ibmvfc_drain_sub_crq(struct ibmvfc_queue *scrq)
 	spin_lock_irqsave(scrq->q_lock, flags);
 	while (!done) {
 		while ((crq = ibmvfc_next_scrq(scrq)) != NULL) {
-			ibmvfc_handle_scrq(crq, scrq->vhost, &evt_doneq);
+			ibmvfc_handle_scrq(crq, scrq, &evt_doneq);
 			crq->valid = 0;
 			wmb();
 		}
@@ -4293,7 +4317,7 @@ static void ibmvfc_drain_sub_crq(struct ibmvfc_queue *scrq)
 		ibmvfc_toggle_scrq_irq(scrq, 1);
 		if ((crq = ibmvfc_next_scrq(scrq)) != NULL) {
 			ibmvfc_toggle_scrq_irq(scrq, 0);
-			ibmvfc_handle_scrq(crq, scrq->vhost, &evt_doneq);
+			ibmvfc_handle_scrq(crq, scrq, &evt_doneq);
 			crq->valid = 0;
 			wmb();
 		} else

-- 
2.56.0

