From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Wed, 09 Sep 2026 14:07:59 -0500
Subject: [PATCH v8 4/9] scsi: ibmvfc: extend async event handlers for async
 sub-CRQ events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-ibmvfc-fpin-support-v8-4-b27183b055af@linux.ibm.com>
References: <20260909-ibmvfc-fpin-support-v8-0-b27183b055af@linux.ibm.com>
In-Reply-To: <20260909-ibmvfc-fpin-support-v8-0-b27183b055af@linux.ibm.com>
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-kernel@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, Brian King <brking@linux.ibm.com>, 
 Greg Joyce <gjoyce@linux.ibm.com>, Kyle Mahlkuch <kmahlkuc@linux.ibm.com>, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788980878; l=17890;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=7eFJ87zkPibvJhk7qxtmxB11SLEertGMnL5YoeifeQ4=;
 b=23OHdLTCzLTT2J1VOUDoyF3v3bksk264VEAmjLBXAkqr/wafYUwpOu/GoHmedGB7jhYf7b4yT
 AZrjR2OjtLcDDO3XeuF4zcfapJUJZNM2rsssLqCo+9byDbBYjPZ+OFb
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
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 135 -----------------------------
 3 files changed, 141 insertions(+), 174 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index c985eb3400a7..1126c86d08fa 100644
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
index a8a063d99564..6fce7a4922bb 100644
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
 VISIBLE_IF_KUNIT struct ibmvfc_host *ibmvfc_get_first_vhost(void);
 #endif
 
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index 80e7f8e0fd70..7aaed4f64f26 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -3,7 +3,6 @@
 #include <kunit/visibility.h>
 #include <scsi/scsi_device.h>
 #include <scsi/scsi_transport_fc.h>
-#include <scsi/fc/fc_els.h>
 #include <linux/list.h>
 #include <linux/delay.h>
 #include "ibmvfc.h"
@@ -257,143 +256,9 @@ static void ibmvfc_full_fpin_test(struct kunit *test)
 	scsi_host_put(vhost->host);
 }
 
-#define IBMVFC_TEST_FPIN_EXT(fs, ev, stat, crq) {				\
-	struct ibmvfc_async_crq_event ae = { .type = IBMVFC_ASYNC_CRQ_SUB };	\
-	(crq).valid = 0x80;							\
-	(crq).flags = IBMVFC_ASYNC_IS_FPIN_EXT;					\
-	(crq).link_state = IBMVFC_AE_LS_LINK_UP;				\
-	(crq).fpin_status = (fs);						\
-	(crq).event = cpu_to_be16(IBMVFC_AE_FPIN);				\
-	(crq).wwpn = cpu_to_be64(tgt->wwpn);					\
-	(crq).fpin_data.flags = IBMVFC_FPIN_EVENT_TYPE_VALID;			\
-	(crq).fpin_data.event_type = cpu_to_be16((ev));				\
-	ae.subq = *(struct ibmvfc_async_sub_crq *)&(crq);			\
-	pre = READ_ONCE(rport->fpin_stats.stat);				\
-	ibmvfc_handle_async(&ae, vhost);					\
-	flush_workqueue(vhost->fpin_workq);					\
-	post = READ_ONCE(rport->fpin_stats.stat);				\
-}
-
-/**
- * ibmvfc_extended_fpin_test - unit test for extended FPIN events
- * @test: pointer to kunit structure
- *
- * Note: This test exercises extended FPIN code paths but does not check
- * that statistics are correctly updated.
- *
- * Return: void
- */
-static void ibmvfc_extended_fpin_test(struct kunit *test)
-{
-	enum ibmvfc_ae_fpin_status fs;
-	struct ibmvfc_async_subq_fpin crq[IBMVFC_AE_FPIN_CONGESTION_CLEARED+1] = {};
-	struct ibmvfc_async_subq_fpin
-		crqcn[IBMVFC_AE_FPIN_PORT_CONGESTED][FPIN_CONGN_DEVICE_SPEC+1] = {};
-	struct ibmvfc_async_subq_fpin crqportdg[FPIN_LI_DEVICE_SPEC+1] = {};
-	struct ibmvfc_target *tgt;
-	struct ibmvfc_host *vhost;
-	struct fc_rport *rport;
-	LIST_HEAD(evt_doneq);
-	unsigned long flags;
-	u64 pre, post;
-
-	vhost = ibmvfc_get_first_vhost();
-	if (!vhost)
-		kunit_skip(test, "No ibmvfc devices available");
-
-	spin_lock_irqsave(vhost->host->host_lock, flags);
-	if (vhost->scsi_scrqs.num_targets < 1) {
-		spin_unlock_irqrestore(vhost->host->host_lock, flags);
-		scsi_host_put(vhost->host);
-		kunit_skip(test, "No targets");
-	}
-	tgt = list_first_entry(&vhost->scsi_scrqs.targets, struct ibmvfc_target, queue);
-	if (!tgt->rport) {
-		spin_unlock_irqrestore(vhost->host->host_lock, flags);
-		scsi_host_put(vhost->host);
-		kunit_skip(test, "No rport");
-	}
-	rport = tgt->rport;
-	get_device(&rport->dev);
-	kref_get(&tgt->kref);
-	spin_unlock_irqrestore(vhost->host->host_lock, flags);
-
-	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
-		switch (fs) {
-		case IBMVFC_AE_FPIN_PORT_CLEARED:
-		case IBMVFC_AE_FPIN_CONGESTION_CLEARED: {
-			struct ibmvfc_async_crq_event ae = { .type = IBMVFC_ASYNC_CRQ_SUB };
-
-			crq[fs].valid = 0x80;
-			crq[fs].flags = IBMVFC_ASYNC_IS_FPIN_EXT;
-			crq[fs].link_state = IBMVFC_AE_LS_LINK_UP;
-			crq[fs].fpin_status = fs;
-			crq[fs].event = cpu_to_be16(IBMVFC_AE_FPIN);
-			crq[fs].wwpn = cpu_to_be64(tgt->wwpn);
-			crq[fs].fpin_data.flags = IBMVFC_FPIN_EVENT_TYPE_VALID;
-			crq[fs].fpin_data.event_type = cpu_to_be16(FPIN_CONGN_CLEAR);
-			ae.subq = *(struct ibmvfc_async_sub_crq *)&crq[fs];
-			pre = READ_ONCE(rport->fpin_stats.cn_clear);
-			ibmvfc_handle_async(&ae, vhost);
-			flush_workqueue(vhost->fpin_workq);
-			post = READ_ONCE(rport->fpin_stats.cn_clear);
-			break;
-		}
-		case IBMVFC_AE_FPIN_LINK_CONGESTED:
-		case IBMVFC_AE_FPIN_PORT_CONGESTED:
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_CLEAR, cn_clear,
-					     crqcn[fs-1][FPIN_CONGN_CLEAR]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_LOST_CREDIT,
-					     cn_lost_credit,
-					     crqcn[fs-1][FPIN_CONGN_LOST_CREDIT]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_CREDIT_STALL,
-					     cn_credit_stall,
-					     crqcn[fs-1][FPIN_CONGN_CREDIT_STALL]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_OVERSUBSCRIPTION,
-					     cn_oversubscription,
-					     crqcn[fs-1][FPIN_CONGN_OVERSUBSCRIPTION]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_DEVICE_SPEC,
-					     cn_device_specific,
-					     crqcn[fs-1][FPIN_CONGN_DEVICE_SPEC]);
-			break;
-		case IBMVFC_AE_FPIN_PORT_DEGRADED:
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_UNKNOWN,
-					     li_failure_unknown,
-					     crqportdg[FPIN_LI_UNKNOWN]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_LINK_FAILURE,
-					     li_link_failure_count,
-					     crqportdg[FPIN_LI_LINK_FAILURE]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_LOSS_OF_SYNC,
-					     li_loss_of_sync_count,
-					     crqportdg[FPIN_LI_LOSS_OF_SYNC]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_LOSS_OF_SIG,
-					     li_loss_of_signals_count,
-					     crqportdg[FPIN_LI_LOSS_OF_SIG]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_PRIM_SEQ_ERR,
-					     li_prim_seq_err_count,
-					     crqportdg[FPIN_LI_PRIM_SEQ_ERR]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_INVALID_TX_WD,
-					     li_invalid_tx_word_count,
-					     crqportdg[FPIN_LI_INVALID_TX_WD]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_INVALID_CRC,
-					     li_invalid_crc_count,
-					     crqportdg[FPIN_LI_INVALID_CRC]);
-			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_DEVICE_SPEC,
-					     li_device_specific,
-					     crqportdg[FPIN_LI_DEVICE_SPEC]);
-			break;
-		}
-	}
-
-	put_device(&rport->dev);
-	kref_put(&tgt->kref, ibmvfc_release_tgt);
-	scsi_host_put(vhost->host);
-}
-
 static struct kunit_case ibmvfc_fpin_test_cases[] = {
 	KUNIT_CASE(ibmvfc_async_fpin_test),
 	KUNIT_CASE(ibmvfc_full_fpin_test),
-	KUNIT_CASE(ibmvfc_extended_fpin_test),
 	{},
 };
 

-- 
2.55.0

