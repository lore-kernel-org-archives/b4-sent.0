From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 31 Aug 2026 14:00:16 -0500
Subject: [PATCH v7 4/8] scsi: ibmvfc: extend async event handlers to handle
 async sub queue events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-ibmvfc-fpin-support-v7-4-77d0b9809080@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788202815; l=20614;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=eqcb5Vyo4dyCzqI/6Mp+rnCevMwMGZpMnXtxeqESXoc=;
 b=q/YbSu9Kjj1wzpesH17Nk8jfTEMtIGqEoKEClbhYzuNyNfp9xFeN2U4EXXiKJB38zItBvFXhX
 Bipfv+RMQKyCyNPrML0QPzCtvA5BzBosoJV5PfH2akLsc2Nd1cFDdxN
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor async event handling to support both traditional async CRQs and
new asynchronous sub-queue CRQs.

Introduce struct ibmvfc_async_crq_event, a tagged union that wraps
either an ibmvfc_async_crq (main CRQ) or an ibmvfc_async_sub_crq
(async sub-CRQ), with an enum ibmvfc_async_crq_type discriminator.
Replace the ibmvfc_async_work bare union and is_subq bool with a
single event field of this type.

Modify ibmvfc_handle_async() to accept a struct ibmvfc_async_crq_event *
instead of a void * plus a bool flag. Update ibmvfc_process_async_work()
to dispatch based on event.type.

Add ibmvfc_full_fpin_to_desc() to convert full FPIN messages from async
sub-queue format to fc_els_fpin structures. Update FPIN processing logic
to extract WWPN, node_name, and scsi_id from the appropriate union member
based on event type.

Update KUnit tests to use struct ibmvfc_async_crq_event arrays at call
sites.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c  | 162 +++++++++++++++++++++++++++--------
 drivers/scsi/ibmvscsi/ibmvfc.h       |  18 +++-
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 162 +++++++++++++++++++++++++++++++----
 3 files changed, 284 insertions(+), 58 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index e972e4ec5be0..229b06effd4c 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -3426,6 +3426,45 @@ ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, u64 wwpn)
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
+ibmvfc_full_fpin_to_desc(struct ibmvfc_async_sub_crq *ibmvfc_fpin)
+{
+	__be16 type;
+
+	switch (ibmvfc_fpin->fpin_status) {
+	case IBMVFC_AE_FPIN_LINK_CONGESTED:
+	case IBMVFC_AE_FPIN_PORT_CONGESTED:
+		type = cpu_to_be16(FPIN_CONGN_DEVICE_SPEC);
+		break;
+	case IBMVFC_AE_FPIN_PORT_CLEARED:
+	case IBMVFC_AE_FPIN_CONGESTION_CLEARED:
+		type = cpu_to_be16(FPIN_CONGN_CLEAR);
+		break;
+	case IBMVFC_AE_FPIN_PORT_DEGRADED:
+		type = cpu_to_be16(FPIN_LI_UNKNOWN);
+		break;
+	default:
+		return NULL;
+	}
+
+	return ibmvfc_common_fpin_to_desc(ibmvfc_fpin->fpin_status, ibmvfc_fpin->wwpn,
+					  type, cpu_to_be16(0),
+					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD),
+					  cpu_to_be32(1));
+}
+
 /**
  * ibmvfc_find_target - Search for a target in a target list
  * @target_list: list head of targets to search
@@ -3463,28 +3502,39 @@ static struct ibmvfc_target *ibmvfc_find_target(struct list_head *target_list,
  */
 static void ibmvfc_process_async_work(struct work_struct *work)
 {
+	struct ibmvfc_async_sub_crq *subq = NULL;
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
+	__be64 wwpn;
 
 	aw = container_of_const(work, struct ibmvfc_async_work, async_work_s);
 	vhost = aw->vhost;
-	crq = &aw->crq;
+	if (aw->event.type == IBMVFC_ASYNC_CRQ_SUB) {
+		subq = &aw->event.subq;
+		scsi_id = 0;
+		wwpn = subq->wwpn;
+		node_name = (subq->flags & IBMVFC_ASYNC_ID_IS_ASSOC_ID) ? 0 : subq->id.node_name;
+	} else {
+		crq = &aw->event.async_crq;
+		scsi_id = crq->scsi_id;
+		wwpn = crq->wwpn;
+		node_name = crq->node_name;
+	}
 
-	if (!crq->scsi_id && !crq->wwpn && !crq->node_name)
+	if (!scsi_id && !wwpn && !node_name)
 		goto free;
 
 	spin_lock_irqsave(vhost->host->host_lock, flags);
-	tgt = ibmvfc_find_target(&vhost->scsi_scrqs.targets, crq->scsi_id,
-				 crq->wwpn, crq->node_name);
+	tgt = ibmvfc_find_target(&vhost->scsi_scrqs.targets, scsi_id, wwpn, node_name);
 	if (!tgt) {
 		/* Target not found in scsi_scrqs, search nvme_scrqs */
-		tgt = ibmvfc_find_target(&vhost->nvme_scrqs.targets,
-					 crq->scsi_id, crq->wwpn,
-					 crq->node_name);
+		tgt = ibmvfc_find_target(&vhost->nvme_scrqs.targets, scsi_id, wwpn, node_name);
 	}
 
 	if (tgt) {
@@ -3496,7 +3546,11 @@ static void ibmvfc_process_async_work(struct work_struct *work)
 		goto free;
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
@@ -3512,25 +3566,51 @@ static void ibmvfc_process_async_work(struct work_struct *work)
 
 /**
  * ibmvfc_handle_async - Handle an async event from the adapter
- * @crq:	crq to process
+ * @ae:		tagged union wrapping either an ibmvfc_async_crq (main CRQ) or an
+ *		ibmvfc_async_sub_crq (async sub-CRQ); the type field identifies which
  * @vhost:	ibmvfc host struct
  *
  **/
-VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
+VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq_event *ae,
 					  struct ibmvfc_host *vhost)
 {
-	const struct ibmvfc_async_desc *desc = ibmvfc_get_ae_desc(be64_to_cpu(crq->event));
+	struct ibmvfc_async_crq *async_crq = NULL;
+	struct ibmvfc_async_sub_crq *subq = NULL;
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
+	if (ae->type == IBMVFC_ASYNC_CRQ_SUB) {
+		subq = &ae->subq;
+		event = be16_to_cpu(subq->event);
+		link_state = subq->link_state;
+		scsi_id = 0;
+		wwpn = subq->wwpn;
+		node_name = subq->flags & IBMVFC_ASYNC_ID_IS_ASSOC_ID ? 0 : subq->id.node_name;
+	} else {
+		async_crq = &ae->async_crq;
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
@@ -3569,33 +3649,33 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
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
 		}
 		list_for_each_entry(tgt, &vhost->nvme_scrqs.targets, queue) {
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
@@ -3616,14 +3696,14 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 		if (aw) {
 			INIT_WORK(&aw->async_work_s, ibmvfc_process_async_work);
 			aw->vhost = vhost;
-			aw->crq = *crq;
+			aw->event = *ae;
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
 }
@@ -4164,7 +4244,11 @@ static void ibmvfc_tasklet(void *data)
 	while (!done) {
 		/* Pull all the valid messages off the async CRQ */
 		while ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
-			ibmvfc_handle_async(async, vhost);
+			struct ibmvfc_async_crq_event ae = {
+				.type = IBMVFC_ASYNC_CRQ_MAIN,
+				.async_crq = *async,
+			};
+			ibmvfc_handle_async(&ae, vhost);
 			async->valid = 0;
 			wmb();
 		}
@@ -4178,8 +4262,12 @@ static void ibmvfc_tasklet(void *data)
 
 		vio_enable_interrupts(vdev);
 		if ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
+			struct ibmvfc_async_crq_event ae = {
+				.type = IBMVFC_ASYNC_CRQ_MAIN,
+				.async_crq = *async,
+			};
 			vio_disable_interrupts(vdev);
-			ibmvfc_handle_async(async, vhost);
+			ibmvfc_handle_async(&ae, vhost);
 			async->valid = 0;
 			wmb();
 		} else if ((crq = ibmvfc_next_crq(vhost)) != NULL) {
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index 3848fa936e38..464baf1077e0 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -786,9 +786,22 @@ struct ibmvfc_async_sub_crq {
 	} id;
 } __packed __aligned(8);
 
+enum ibmvfc_async_crq_type {
+	IBMVFC_ASYNC_CRQ_MAIN = 0,
+	IBMVFC_ASYNC_CRQ_SUB,
+};
+
+struct ibmvfc_async_crq_event {
+	enum ibmvfc_async_crq_type type;
+	union {
+		struct ibmvfc_async_crq async_crq;
+		struct ibmvfc_async_sub_crq subq;
+	};
+};
+
 struct ibmvfc_async_work {
 	struct ibmvfc_host *vhost;
-	struct ibmvfc_async_crq crq;
+	struct ibmvfc_async_crq_event event;
 	struct work_struct async_work_s;
 };
 
@@ -1103,7 +1116,8 @@ static inline struct ibmvfc_host *ibmvfc_channels_to_vhost(struct ibmvfc_channel
 
 #if IS_ENABLED(CONFIG_KUNIT)
 #include <kunit/visibility.h>
-VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq, struct ibmvfc_host *vhost);
+VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq_event *event,
+					  struct ibmvfc_host *vhost);
 VISIBLE_IF_KUNIT struct list_head *ibmvfc_get_headp(void);
 #endif
 
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index 8a73ea1b1da8..bc6e542f11ce 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -24,9 +24,11 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 {
 	u64 post[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
 	u64 pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	struct ibmvfc_async_crq_event ae[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1] = {
+		[0 ... IBMVFC_AE_FPIN_CONGESTION_CLEARED] = { .type = IBMVFC_ASYNC_CRQ_MAIN },
+	};
 	enum ibmvfc_ae_fpin_status fs;
 	struct fc_host_attrs *fc_host;
-	struct ibmvfc_async_crq crq[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
 	struct ibmvfc_target *tgt;
 	struct ibmvfc_host *vhost;
 	struct list_head *queue;
@@ -61,15 +63,15 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
 
 	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
-		crq[fs].valid = 0x80;
-		crq[fs].link_state = IBMVFC_AE_LS_LINK_UP;
-		crq[fs].fpin_status = fs;
-		crq[fs].event = cpu_to_be64(IBMVFC_AE_FPIN);
-		crq[fs].scsi_id = cpu_to_be64(tgt->scsi_id);
-		crq[fs].wwpn = cpu_to_be64(tgt->wwpn);
-		crq[fs].node_name = cpu_to_be64(tgt->ids.node_name);
-		ibmvfc_handle_async(&crq[fs], vhost);
-		crq[fs].valid = 0;
+		ae[fs].async_crq.valid = 0x80;
+		ae[fs].async_crq.link_state = IBMVFC_AE_LS_LINK_UP;
+		ae[fs].async_crq.fpin_status = fs;
+		ae[fs].async_crq.event = cpu_to_be64(IBMVFC_AE_FPIN);
+		ae[fs].async_crq.scsi_id = cpu_to_be64(tgt->scsi_id);
+		ae[fs].async_crq.wwpn = cpu_to_be64(tgt->wwpn);
+		ae[fs].async_crq.node_name = cpu_to_be64(tgt->ids.node_name);
+		ibmvfc_handle_async(&ae[fs], vhost);
+		ae[fs].async_crq.valid = 0;
 		wmb();
 	}
 	flush_workqueue(vhost->fpin_workq);
@@ -98,15 +100,136 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
 
-	crq[0].valid = 0x80;
-	crq[0].link_state = IBMVFC_AE_LS_LINK_UP;
-	crq[0].fpin_status = 0; /* bad value */
-	crq[0].event = cpu_to_be64(IBMVFC_AE_FPIN);
-	crq[0].scsi_id = cpu_to_be64(tgt->scsi_id);
-	crq[0].wwpn = cpu_to_be64(tgt->wwpn);
-	crq[0].node_name = cpu_to_be64(tgt->ids.node_name);
-	ibmvfc_handle_async(&crq[0], vhost);
-	crq[0].valid = 0;
+	ae[0].async_crq.valid = 0x80;
+	ae[0].async_crq.link_state = IBMVFC_AE_LS_LINK_UP;
+	ae[0].async_crq.fpin_status = 0; /* bad value */
+	ae[0].async_crq.event = cpu_to_be64(IBMVFC_AE_FPIN);
+	ae[0].async_crq.scsi_id = cpu_to_be64(tgt->scsi_id);
+	ae[0].async_crq.wwpn = cpu_to_be64(tgt->wwpn);
+	ae[0].async_crq.node_name = cpu_to_be64(tgt->ids.node_name);
+	ibmvfc_handle_async(&ae[0], vhost);
+	ae[0].async_crq.valid = 0;
+	wmb();
+	flush_workqueue(vhost->fpin_workq);
+
+	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
+	post[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
+	post[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	KUNIT_EXPECT_EQ(test, pre[IBMVFC_AE_FPIN_LINK_CONGESTED],
+			post[IBMVFC_AE_FPIN_LINK_CONGESTED]);
+	KUNIT_EXPECT_EQ(test, pre[IBMVFC_AE_FPIN_PORT_CONGESTED],
+			post[IBMVFC_AE_FPIN_PORT_CONGESTED]);
+	KUNIT_EXPECT_EQ(test, pre[IBMVFC_AE_FPIN_PORT_CLEARED],
+			post[IBMVFC_AE_FPIN_PORT_CLEARED]);
+	KUNIT_EXPECT_EQ(test, pre[IBMVFC_AE_FPIN_PORT_DEGRADED],
+			post[IBMVFC_AE_FPIN_PORT_DEGRADED]);
+	KUNIT_EXPECT_EQ(test, pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED],
+			post[IBMVFC_AE_FPIN_CONGESTION_CLEARED]);
+
+	kref_put(&tgt->kref, ibmvfc_release_tgt);
+}
+
+/**
+ * ibmvfc_full_fpin_event_test - unit test for IBMVFC_AE_FPIN parts of
+ * ibmvfc_handle_async
+ * @test: pointer to kunit structure
+ *
+ * Tests
+ * - error returns from ibmvfc_handle_async
+ * - statistics updates
+ *
+ * Return: void
+ */
+static void ibmvfc_full_fpin_test(struct kunit *test)
+{
+	u64 post[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	u64 pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	struct ibmvfc_async_crq_event ae[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1] = {
+		[0 ... IBMVFC_AE_FPIN_CONGESTION_CLEARED] = { .type = IBMVFC_ASYNC_CRQ_SUB },
+	};
+	enum ibmvfc_ae_fpin_status fs;
+	struct fc_host_attrs *fc_host;
+	struct ibmvfc_target *tgt;
+	struct ibmvfc_host *vhost;
+	struct list_head *queue;
+	struct list_head *headp;
+	unsigned long flags;
+
+	headp = ibmvfc_get_headp();
+	if (list_empty(headp))
+		kunit_skip(test, "No ibmvfc devices available");
+	queue = headp->next;
+	vhost = container_of_const(queue, struct ibmvfc_host, queue);
+
+	spin_lock_irqsave(vhost->host->host_lock, flags);
+	if (vhost->scsi_scrqs.num_targets < 1) {
+		spin_unlock_irqrestore(vhost->host->host_lock, flags);
+		kunit_skip(test, "No targets");
+	}
+	tgt = list_first_entry(&vhost->scsi_scrqs.targets, struct ibmvfc_target, queue);
+	if (!tgt->rport) {
+		spin_unlock_irqrestore(vhost->host->host_lock, flags);
+		kunit_skip(test, "No rport");
+	}
+	kref_get(&tgt->kref);
+	spin_unlock_irqrestore(vhost->host->host_lock, flags);
+
+	fc_host = shost_to_fc_host(vhost->host);
+
+	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
+	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
+	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
+		ae[fs].subq.valid = 0x80;
+		ae[fs].subq.link_state = IBMVFC_AE_LS_LINK_UP;
+		ae[fs].subq.fpin_status = fs;
+		ae[fs].subq.event = cpu_to_be16(IBMVFC_AE_FPIN);
+		ae[fs].subq.wwpn = cpu_to_be64(tgt->wwpn);
+		ae[fs].subq.id.node_name = cpu_to_be64(tgt->ids.node_name);
+		ibmvfc_handle_async(&ae[fs], vhost);
+		ae[fs].subq.valid = 0;
+		wmb();
+	}
+	flush_workqueue(vhost->fpin_workq);
+
+	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	post[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
+	post[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
+	post[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	KUNIT_EXPECT_GE(test, post[IBMVFC_AE_FPIN_LINK_CONGESTED],
+			pre[IBMVFC_AE_FPIN_LINK_CONGESTED]+1);
+	KUNIT_EXPECT_GE(test, post[IBMVFC_AE_FPIN_PORT_CONGESTED],
+			pre[IBMVFC_AE_FPIN_PORT_CONGESTED]+1);
+	KUNIT_EXPECT_GE(test, post[IBMVFC_AE_FPIN_PORT_CLEARED],
+			pre[IBMVFC_AE_FPIN_PORT_CLEARED]+1);
+	KUNIT_EXPECT_GE(test, post[IBMVFC_AE_FPIN_PORT_DEGRADED],
+			pre[IBMVFC_AE_FPIN_PORT_DEGRADED]+1);
+	KUNIT_EXPECT_GE(test, post[IBMVFC_AE_FPIN_CONGESTION_CLEARED],
+			pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED]+1);
+
+	/* bad path */
+	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
+	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
+	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	ae[0].subq.valid = 0x80;
+	ae[0].subq.link_state = IBMVFC_AE_LS_LINK_UP;
+	ae[0].subq.fpin_status = 0; /* bad value */
+	ae[0].subq.event = cpu_to_be16(IBMVFC_AE_FPIN);
+	ae[0].subq.wwpn = cpu_to_be64(tgt->wwpn);
+	ae[0].subq.id.node_name = cpu_to_be64(tgt->ids.node_name);
+	ibmvfc_handle_async(&ae[0], vhost);
+	ae[0].subq.valid = 0;
 	wmb();
 	flush_workqueue(vhost->fpin_workq);
 
@@ -132,6 +255,7 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 
 static struct kunit_case ibmvfc_fpin_test_cases[] = {
 	KUNIT_CASE(ibmvfc_async_fpin_test),
+	KUNIT_CASE(ibmvfc_full_fpin_test),
 	{},
 };
 

-- 
2.55.0

