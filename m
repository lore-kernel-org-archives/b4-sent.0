From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Thu, 02 Jul 2026 12:59:36 -0500
Subject: [PATCH v3 6/8] ibmvfc: extend async event handlers to handle async
 sub queue events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260702-ibmvfc-fpin-support-v3-6-d95b9547cf88@linux.ibm.com>
References: <20260702-ibmvfc-fpin-support-v3-0-d95b9547cf88@linux.ibm.com>
In-Reply-To: <20260702-ibmvfc-fpin-support-v3-0-d95b9547cf88@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783015177; l=12011;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=TGKfNyGbOqjpabBs8wC1jz9JAgWE7OngsIIrumszrc4=;
 b=83kpVYQN9ESorVFMD3yuDiQwu/RVkMGdRaDkAWKR1CRosHCrP0rJJtV0U8tbNSiBqT4uRsXsK
 cQE85RE1X3nBRM0he51i4N7oRQK5uvJVNUNa4EX2l1U+QKm5YfmqX96
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make ibmvfc_handle_async and ibmvfc_process_async_work handle both
async CRQs and the new asynchronous sub-queue CRQs.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc.c       | 156 +++++++++++++++++++++++++++--------
 drivers/scsi/ibmvscsi/ibmvfc.h       |  17 ++--
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c |  10 +--
 3 files changed, 136 insertions(+), 47 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc.c b/drivers/scsi/ibmvscsi/ibmvfc.c
index 804887fb5635..4678d76c84fe 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc.c
@@ -3349,6 +3349,27 @@ ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, u64 wwpn)
 					  cpu_to_be32(1));
 }
 
+/**
+ * ibmvfc_full_fpin_to_desc(): allocate and populate a struct fc_els_fpin struct
+ * containing a descriptor.
+ * @ibmvfc_fpin: Pointer to async subq FPIN data
+ *
+ * Allocate a struct fc_els_fpin containing a descriptor and populate
+ * based on data from *ibmvfc_fpin.
+ *
+ * Return:
+ * NULL     - unable to allocate structure
+ * non-NULL - pointer to populated struct fc_els_fpin
+ */
+static struct fc_els_fpin *
+ibmvfc_full_fpin_to_desc(struct ibmvfc_async_subq *ibmvfc_fpin)
+{
+	return ibmvfc_common_fpin_to_desc(ibmvfc_fpin->fpin_status, ibmvfc_fpin->wwpn,
+					  cpu_to_be16(0), cpu_to_be16(0),
+					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD),
+					  cpu_to_be32(1));
+}
+
 /**
  * ibmvfc_process_async_work - Process IBMVFC_AE_FPIN async CRQ from work queue
  * @work: pointer to work_struct
@@ -3356,26 +3377,51 @@ ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, u64 wwpn)
 static void ibmvfc_process_async_work(struct work_struct *work)
 {
 	struct ibmvfc_target *tgt, *next;
+	struct ibmvfc_async_subq *subq = NULL;
 	struct ibmvfc_async_work *aw;
-	struct ibmvfc_async_crq *crq;
+	struct ibmvfc_async_crq *crq = NULL;
 	struct ibmvfc_host *vhost;
-	struct fc_els_fpin *fpin;
+	struct fc_els_fpin *fpin = NULL;
 	unsigned long flags;
+	__be64 node_name;
+	__be64 scsi_id;
+	bool is_subq;
+	__be64 wwpn;
 
 	aw = container_of(work, struct ibmvfc_async_work, async_work_s);
-	crq = &aw->crq;
 	vhost = aw->vhost;
+	is_subq = aw->is_subq;
+	if (is_subq)
+		subq = &aw->crq.subq;
+	else
+		crq = &aw->crq.async_crq;
 
-	if (!crq->scsi_id && !crq->wwpn && !crq->node_name)
+	if (!crq && !subq) {
+		dev_err_ratelimited(vhost->dev,
+				    "FPIN event received, unable to process\n");
+		goto end;
+	}
+
+	if (crq) {
+		wwpn = crq->wwpn;
+		node_name = crq->node_name;
+		scsi_id = crq->scsi_id;
+	} else {
+		wwpn = subq->wwpn;
+		node_name = subq->id.node_name;
+		scsi_id = 0;
+	}
+
+	if (!scsi_id && !wwpn && !node_name)
 		goto end;
 
 	spin_lock_irqsave(vhost->host->host_lock, flags);
 	list_for_each_entry_safe(tgt, next, &vhost->targets, queue) {
-		if (crq->scsi_id && cpu_to_be64(tgt->scsi_id) != crq->scsi_id)
+		if (scsi_id && cpu_to_be64(tgt->scsi_id) != scsi_id)
 			continue;
-		if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
+		if (wwpn && cpu_to_be64(tgt->ids.port_name) != wwpn)
 			continue;
-		if (crq->node_name && cpu_to_be64(tgt->ids.node_name) != crq->node_name)
+		if (node_name && cpu_to_be64(tgt->ids.node_name) != node_name)
 			continue;
 		if (!tgt->rport)
 			continue;
@@ -3388,41 +3434,71 @@ static void ibmvfc_process_async_work(struct work_struct *work)
 		goto end;
 	}
 
-	fpin = ibmvfc_basic_fpin_to_desc(crq, tgt->wwpn);
+	if (crq)
+		fpin = ibmvfc_basic_fpin_to_desc(crq, tgt->wwpn);
+	else
+		fpin = ibmvfc_full_fpin_to_desc(subq);
+
 	if (fpin) {
 		fc_host_fpin_rcv(tgt->vhost->host,
 				 sizeof(*fpin) + be32_to_cpu(fpin->desc_len),
 				 (char *)fpin, 0);
 		kfree(fpin);
 	} else
-		dev_err_ratelimited(vhost->dev,
-				    "FPIN event %u received, unable to process\n",
-				    crq->fpin_status);
+		dev_err_ratelimited(vhost->dev, "FPIN event received, unable to process\n");
+
  end:
 	kfree(aw);
 }
 
 /**
  * ibmvfc_handle_async - Handle an async event from the adapter
- * @crq:	crq to process
+ * @crq:	ibmvfc_async_crq or ibmvfc_async_subq
  * @vhost:	ibmvfc host struct
+ * @is_subq:	indicates whether the crq points to a struct ibmvfc_async_subq
  *
  **/
-VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
-					  struct ibmvfc_host *vhost)
+VISIBLE_IF_KUNIT void ibmvfc_handle_async(void *crq,
+					  struct ibmvfc_host *vhost,
+					  bool is_subq)
 {
-	const struct ibmvfc_async_desc *desc = ibmvfc_get_ae_desc(be64_to_cpu(crq->event));
+	struct ibmvfc_async_crq *async_crq = NULL;
+	struct ibmvfc_async_subq *subq = NULL;
+	const struct ibmvfc_async_desc *desc;
+	struct ibmvfc_target *tgt, *next;
 	struct ibmvfc_async_work *aw;
-	struct ibmvfc_target *tgt;
-
-	ibmvfc_log(vhost, desc->log_level, "%s event received. scsi_id: %llx, wwpn: %llx,"
-		   " node_name: %llx%s\n", desc->desc, be64_to_cpu(crq->scsi_id),
-		   be64_to_cpu(crq->wwpn), be64_to_cpu(crq->node_name),
-		   ibmvfc_get_link_state(crq->link_state));
-
-	switch (be64_to_cpu(crq->event)) {
+	__be64 node_name;
+	__be64 scsi_id;
+	u8 link_state;
+	__be64 wwpn;
+	u64 event;
+
+	if (is_subq) {
+		subq = crq;
+		event = be16_to_cpu(subq->event);
+		link_state = subq->link_state;
+		scsi_id = 0;
+		wwpn = subq->wwpn;
+		node_name = subq->id.node_name;
+	} else {
+		async_crq = crq;
+		event = be64_to_cpu(async_crq->event);
+		link_state = async_crq->link_state;
+		scsi_id = async_crq->scsi_id;
+		wwpn = async_crq->wwpn;
+		node_name = async_crq->node_name;
+	}
+
+	desc = ibmvfc_get_ae_desc(event);
+	ibmvfc_log(vhost, desc->log_level,
+		   "%s event received. scsi_id: %llx, wwpn: %llx, node_name: %llx, event %llx%s\n",
+		   desc->desc, be64_to_cpu(scsi_id),
+		   be64_to_cpu(wwpn), be64_to_cpu(node_name), event,
+		   ibmvfc_get_link_state(link_state));
+
+	switch (event) {
 	case IBMVFC_AE_RESUME:
-		switch (crq->link_state) {
+		switch (link_state) {
 		case IBMVFC_AE_LS_LINK_DOWN:
 			ibmvfc_link_down(vhost, IBMVFC_LINK_DOWN);
 			break;
@@ -3460,18 +3536,18 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 	case IBMVFC_AE_ELS_LOGO:
 	case IBMVFC_AE_ELS_PRLO:
 	case IBMVFC_AE_ELS_PLOGI:
-		list_for_each_entry(tgt, &vhost->targets, queue) {
-			if (!crq->scsi_id && !crq->wwpn && !crq->node_name)
+		list_for_each_entry_safe(tgt, next, &vhost->targets, queue) {
+			if (!scsi_id && !wwpn && !node_name)
 				break;
-			if (crq->scsi_id && cpu_to_be64(tgt->scsi_id) != crq->scsi_id)
+			if (scsi_id && cpu_to_be64(tgt->scsi_id) != scsi_id)
 				continue;
-			if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
+			if (wwpn && cpu_to_be64(tgt->ids.port_name) != wwpn)
 				continue;
-			if (crq->node_name && cpu_to_be64(tgt->ids.node_name) != crq->node_name)
+			if (node_name && cpu_to_be64(tgt->ids.node_name) != node_name)
 				continue;
-			if (tgt->need_login && be64_to_cpu(crq->event) == IBMVFC_AE_ELS_LOGO)
+			if (tgt->need_login && event == IBMVFC_AE_ELS_LOGO)
 				tgt->logo_rcvd = 1;
-			if (!tgt->need_login || be64_to_cpu(crq->event) == IBMVFC_AE_ELS_PLOGI) {
+			if (!tgt->need_login || event == IBMVFC_AE_ELS_PLOGI) {
 				ibmvfc_del_tgt(tgt);
 				ibmvfc_reinit_host(vhost);
 			}
@@ -3492,16 +3568,26 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 		if (aw) {
 			INIT_WORK(&aw->async_work_s, ibmvfc_process_async_work);
 			aw->vhost = vhost;
-			aw->crq = *crq;
+			aw->is_subq = is_subq;
+			if (is_subq)
+				aw->crq.subq = *subq;
+			else
+				aw->crq.async_crq = *async_crq;
 			queue_work(vhost->fpin_workq, &aw->async_work_s);
 		} else
 			dev_err_ratelimited(vhost->dev,
 					    "can't offload async CRQ to work queue\n");
 		break;
 	default:
-		dev_err(vhost->dev, "Unknown async event received: %lld\n", crq->event);
+		dev_err(vhost->dev, "Unknown async event received: %llu\n", event);
 		break;
 	}
+
+	if (is_subq)
+		subq->valid = 0;
+	else
+		async_crq->valid = 0;
+	wmb();
 }
 EXPORT_SYMBOL_IF_KUNIT(ibmvfc_handle_async);
 
@@ -4040,7 +4126,7 @@ static void ibmvfc_tasklet(void *data)
 	while (!done) {
 		/* Pull all the valid messages off the async CRQ */
 		while ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
-			ibmvfc_handle_async(async, vhost);
+			ibmvfc_handle_async(async, vhost, false);
 		}
 
 		/* Pull all the valid messages off the CRQ */
@@ -4053,7 +4139,7 @@ static void ibmvfc_tasklet(void *data)
 		vio_enable_interrupts(vdev);
 		if ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
 			vio_disable_interrupts(vdev);
-			ibmvfc_handle_async(async, vhost);
+			ibmvfc_handle_async(async, vhost, false);
 		} else if ((crq = ibmvfc_next_crq(vhost)) != NULL) {
 			vio_disable_interrupts(vdev);
 			ibmvfc_handle_crq(crq, vhost, &evt_doneq);
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index f38dfae9924c..bbf19220af70 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -712,12 +712,6 @@ struct ibmvfc_async_crq {
 	__be64 reserved;
 } __packed __aligned(8);
 
-struct ibmvfc_async_work {
-	struct ibmvfc_host *vhost;
-	struct ibmvfc_async_crq crq;
-	struct work_struct async_work_s;
-};
-
 struct ibmvfc_async_subq {
 	volatile u8 valid;
 #define IBMVFC_ASYNC_ID_IS_ASSOC_ID	0x01
@@ -737,6 +731,15 @@ struct ibmvfc_async_subq {
 	} id;
 } __packed __aligned(8);
 
+struct ibmvfc_async_work {
+	struct ibmvfc_host *vhost;
+	bool is_subq;
+	union {
+		struct ibmvfc_async_crq async_crq;
+		struct ibmvfc_async_subq subq;
+	} crq;
+	struct work_struct async_work_s;
+};
 union ibmvfc_iu {
 	struct ibmvfc_mad_common mad_common;
 	struct ibmvfc_npiv_login_mad npiv_login;
@@ -1008,7 +1011,7 @@ struct ibmvfc_host {
 #endif
 
 #ifdef VISIBLE_IF_KUNIT
-VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq, struct ibmvfc_host *vhost);
+VISIBLE_IF_KUNIT void ibmvfc_handle_async(void *crq, struct ibmvfc_host *vhost, bool is_subq);
 VISIBLE_IF_KUNIT struct list_head *ibmvfc_get_headp(void);
 #endif
 
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index e41e2a49e549..6bde92197549 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -44,7 +44,7 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	fc_host = shost_to_fc_host(vhost->host);
 
 	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
-	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
 	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
 	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
@@ -57,7 +57,8 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 		crq[fs].scsi_id = cpu_to_be64(tgt->scsi_id);
 		crq[fs].wwpn = cpu_to_be64(tgt->wwpn);
 		crq[fs].node_name = cpu_to_be64(tgt->ids.node_name);
-		ibmvfc_handle_async(&crq[fs], vhost);
+		ibmvfc_handle_async(&crq[fs], vhost, false);
+		msleep(1U);
 	}
 
 	msleep(500U);
@@ -93,9 +94,8 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	crq[0].scsi_id = cpu_to_be64(tgt->scsi_id);
 	crq[0].wwpn = cpu_to_be64(tgt->wwpn);
 	crq[0].node_name = cpu_to_be64(tgt->ids.node_name);
-	ibmvfc_handle_async(&crq[0], vhost);
-
-	msleep(500U);
+	ibmvfc_handle_async(&crq[0], vhost, false);
+	msleep(1U);
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
 	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);

-- 
2.54.0

