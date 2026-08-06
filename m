From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Thu, 06 Aug 2026 10:17:35 -0500
Subject: [PATCH v5 5/7] scsi: ibmvfc: extend async event handlers to handle
 async sub queue events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-ibmvfc-fpin-support-v5-5-13fd6f8a8f8b@linux.ibm.com>
References: <20260806-ibmvfc-fpin-support-v5-0-13fd6f8a8f8b@linux.ibm.com>
In-Reply-To: <20260806-ibmvfc-fpin-support-v5-0-13fd6f8a8f8b@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786029459; l=13895;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=k1+095EGq7VZWAHVlNP6StVTuZjc2jmI+D0cZtE1Fhk=;
 b=EeCe6UrKAKjqSG2FinpluE4mDvYNS8JHdCsR2tZ+0FOmNaGlf0pX1IvovU1GviU+4kkED77h6
 Wg2/Ex5123dAKQlPnFwPwCsToYRWuPzQe9NLmEOCOyaumQer2II6iA0
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor async event handling to support both traditional async CRQs and
new asynchronous sub-queue CRQs.

Modify ibmvfc_handle_async() to accept events from either source and
update ibmvfc_process_async_work() to handle both ibmvfc_async_crq and
ibmvfc_async_subq structures. Add is_subq flag to ibmvfc_async_work to
distinguish between event sources.

Add ibmvfc_full_fpin_to_desc() to convert full FPIN messages from async
sub-queue format to fc_els_fpin structures. Update FPIN processing logic
to extract WWPN, node_name, and scsi_id from the appropriate structure
based on event source.

Update KUnit tests to reflect the new async event handling interface.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c  | 204 +++++++++++++++++++++++++----------
 drivers/scsi/ibmvscsi/ibmvfc.h       |  17 +--
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c |   6 +-
 3 files changed, 158 insertions(+), 69 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 06898a407d07..230bf2be6531 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -3406,67 +3406,115 @@ ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, u64 wwpn)
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
+/**
+ * ibmvfc_find_target - Search for a target in a target list
+ * @target_list: list head of targets to search
+ * @scsi_id: SCSI ID to match (0 to skip this check)
+ * @wwpn: WWPN to match (0 to skip this check)
+ * @node_name: Node name to match (0 to skip this check)
+ *
+ * Returns:
+ * Pointer to matching target, or NULL if not found
+ **/
+static struct ibmvfc_target *ibmvfc_find_target(struct list_head *target_list,
+						__be64 scsi_id, __be64 wwpn,
+						__be64 node_name)
+{
+	struct ibmvfc_target *tgt;
+
+	list_for_each_entry(tgt, target_list, queue) {
+		if (scsi_id && cpu_to_be64(tgt->scsi_id) != scsi_id)
+			continue;
+		if (wwpn && cpu_to_be64(tgt->ids.port_name) != wwpn)
+			continue;
+		if (node_name && cpu_to_be64(tgt->ids.node_name) != node_name)
+			continue;
+		if (!tgt->rport)
+			continue;
+		return tgt;
+	}
+
+	return NULL;
+}
+
 /**
  * ibmvfc_process_async_work - Process IBMVFC_AE_FPIN async CRQ from work queue
  * @work: pointer to work_struct
  */
 static void ibmvfc_process_async_work(struct work_struct *work)
 {
+	struct ibmvfc_async_subq *subq = NULL;
 	struct ibmvfc_async_work *aw;
-	struct ibmvfc_async_crq *crq;
+	struct ibmvfc_async_crq *crq = NULL;
 	struct ibmvfc_target *tgt;
 	struct ibmvfc_host *vhost;
-	struct fc_els_fpin *fpin;
+	struct fc_els_fpin *fpin = NULL;
 	unsigned long flags;
+	__be64 node_name;
+	__be64 scsi_id;
+	bool is_subq;
+	__be64 wwpn;
 
 	aw = container_of_const(work, struct ibmvfc_async_work, async_work_s);
 	vhost = aw->vhost;
-	crq = &aw->crq;
+	is_subq = aw->is_subq;
+	if (is_subq) {
+		subq = &aw->crq.subq;
+		scsi_id = 0;
+		wwpn = subq->wwpn;
+		node_name = subq->id.node_name;
+	} else {
+		crq = &aw->crq.async_crq;
+		scsi_id = crq->scsi_id;
+		wwpn = crq->wwpn;
+		node_name = crq->node_name;
+	}
 
-	if (!crq->scsi_id && !crq->wwpn && !crq->node_name)
+	if (!scsi_id && !wwpn && !node_name)
 		goto free;
 
 	spin_lock_irqsave(vhost->host->host_lock, flags);
-	list_for_each_entry(tgt, &vhost->scsi_scrqs.targets, queue) {
-		if (crq->scsi_id && cpu_to_be64(tgt->scsi_id) != crq->scsi_id)
-			continue;
-		if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
-			continue;
-		if (crq->node_name && cpu_to_be64(tgt->ids.node_name) != crq->node_name)
-			continue;
-		if (!tgt->rport)
-			continue;
-		break;
+	tgt = ibmvfc_find_target(&vhost->scsi_scrqs.targets, scsi_id, wwpn, node_name);
+	if (!tgt) {
+		/* Target not found in scsi_scrqs, search nvme_scrqs */
+		tgt = ibmvfc_find_target(&vhost->nvme_scrqs.targets, scsi_id, wwpn, node_name);
 	}
 
-	if (!list_entry_is_head(tgt, &vhost->scsi_scrqs.targets, queue) ||
-	    !tgt->rport) {
+	if (tgt) {
 		kref_get(&tgt->kref);
 		spin_unlock_irqrestore(vhost->host->host_lock, flags);
 	} else {
-		/* Target not found in scsi_scrqs, search nvme_scrqs */
-		list_for_each_entry(tgt, &vhost->nvme_scrqs.targets, queue) {
-			if (crq->scsi_id && cpu_to_be64(tgt->scsi_id) != crq->scsi_id)
-				continue;
-			if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
-				continue;
-			if (crq->node_name && cpu_to_be64(tgt->ids.node_name) != crq->node_name)
-				continue;
-			if (!tgt->rport)
-				continue;
-			break;
-		}
-		if (!list_entry_is_head(tgt, &vhost->nvme_scrqs.targets, queue)) {
-			kref_get(&tgt->kref);
-			spin_unlock_irqrestore(vhost->host->host_lock, flags);
-		} else {
-			spin_unlock_irqrestore(vhost->host->host_lock, flags);
-			dev_err_ratelimited(vhost->dev, "Invalid target for FPIN\n");
-			goto free;
-		}
+		spin_unlock_irqrestore(vhost->host->host_lock, flags);
+		dev_err_ratelimited(vhost->dev, "Invalid target for FPIN\n");
+		goto free;
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
@@ -3482,25 +3530,52 @@ static void ibmvfc_process_async_work(struct work_struct *work)
 
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
 	struct ibmvfc_async_work *aw;
 	struct ibmvfc_target *tgt;
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
@@ -3539,17 +3614,17 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 	case IBMVFC_AE_ELS_PRLO:
 	case IBMVFC_AE_ELS_PLOGI:
 		list_for_each_entry(tgt, &vhost->scsi_scrqs.targets, queue) {
-			if (!crq->scsi_id && !crq->wwpn && !crq->node_name)
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
@@ -3570,16 +3645,27 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
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
+	rmb();
+	if (is_subq)
+		subq->valid = 0;
+	else
+		async_crq->valid = 0;
+	wmb();
 }
 EXPORT_SYMBOL_IF_KUNIT(ibmvfc_handle_async);
 
@@ -4118,7 +4204,7 @@ static void ibmvfc_tasklet(void *data)
 	while (!done) {
 		/* Pull all the valid messages off the async CRQ */
 		while ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
-			ibmvfc_handle_async(async, vhost);
+			ibmvfc_handle_async(async, vhost, false);
 			async->valid = 0;
 			wmb();
 		}
@@ -4133,7 +4219,7 @@ static void ibmvfc_tasklet(void *data)
 		vio_enable_interrupts(vdev);
 		if ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
 			vio_disable_interrupts(vdev);
-			ibmvfc_handle_async(async, vhost);
+			ibmvfc_handle_async(async, vhost, false);
 			async->valid = 0;
 			wmb();
 		} else if ((crq = ibmvfc_next_crq(vhost)) != NULL) {
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index 3711be4b6748..89c1ef462d52 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -785,12 +785,6 @@ struct ibmvfc_async_sub_crq {
 	} id;
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
@@ -810,6 +804,15 @@ struct ibmvfc_async_subq {
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
@@ -1120,7 +1123,7 @@ static inline struct ibmvfc_host *ibmvfc_channels_to_vhost(struct ibmvfc_channel
 #endif
 
 #ifdef VISIBLE_IF_KUNIT
-VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq, struct ibmvfc_host *vhost);
+VISIBLE_IF_KUNIT void ibmvfc_handle_async(void *crq, struct ibmvfc_host *vhost, bool is_subq);
 VISIBLE_IF_KUNIT struct list_head *ibmvfc_get_headp(void);
 #endif
 
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index 64a517a74af8..a3e3e3471c5e 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -45,7 +45,7 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	fc_host = shost_to_fc_host(vhost->host);
 
 	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
-	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
 	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
 	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
@@ -58,7 +58,7 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 		crq[fs].scsi_id = cpu_to_be64(tgt->scsi_id);
 		crq[fs].wwpn = cpu_to_be64(tgt->wwpn);
 		crq[fs].node_name = cpu_to_be64(tgt->ids.node_name);
-		ibmvfc_handle_async(&crq[fs], vhost);
+		ibmvfc_handle_async(&crq[fs], vhost, false);
 		msleep(1U);
 	}
 
@@ -93,7 +93,7 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	crq[0].scsi_id = cpu_to_be64(tgt->scsi_id);
 	crq[0].wwpn = cpu_to_be64(tgt->wwpn);
 	crq[0].node_name = cpu_to_be64(tgt->ids.node_name);
-	ibmvfc_handle_async(&crq[0], vhost);
+	ibmvfc_handle_async(&crq[0], vhost, false);
 	msleep(1U);
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);

-- 
2.55.0

