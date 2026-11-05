From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Thu, 05 Nov 2026 11:23:02 -0600
Subject: [PATCH v18 09/13] scsi: ibmvfc: extend async event handlers for
 async sub-CRQ events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ibmvfc-fpin-support-v18-9-d683b74736a3@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793899377; l=26937;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=9QxVlZUjdwUgMXV+3ObzaJH9YtMvL0KXZmFn03rQw7A=;
 b=U4dScz0R/Z3y1rbsL4rh9mq7CmHcB1Nel/sAz9Ezfgp9lyK+J9+SaW+2IV9OmHK3cFg4oiJMB
 jG/w+KycxarBLLDYyCcXk7duk49MunV0Kdla/bOrb26iUKUbGhQkRl8
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
sub-queue format to fc_els_fpin structures. Thread detecting_wwpn
(fc_host_port_name()) through ibmvfc_full_fpin_to_desc() to
ibmvfc_common_fpin_to_desc() so that fc_fn_peer_congn_desc.detecting_wwpn
and fc_fn_li_desc.detecting_wwpn are set to the local port WWPN rather
than left as zero from kzalloc. Set severity to 0 for PORT_CLEARED and
CONGESTION_CLEARED events in ibmvfc_full_fpin_to_desc() since those
cleared states carry no active severity level. Update FPIN processing
logic to extract WWPN, node_name, and scsi_id from the appropriate union
member based on event type. Extract fpin_status as a local u8 from either
subq->fpin_status or crq->fpin_status so it is available for both paths.

Add ibmvfc_find_target() for target lookup by scsi_id, wwpn, node_name,
and assoc_id (all optional; 0 skips that field). When an async sub-CRQ
event has IBMVFC_ASYNC_ID_IS_ASSOC_ID set, extract assoc_id from
subq->id.assoc_id and pass it to ibmvfc_find_target() so NVMe targets
with a shared wwpn are distinguished by their association ID rather than
matched by wwpn alone. Propagate assoc_id into the ELS LOGO/PRLO/PLOGI
target loops in ibmvfc_handle_async() for the same reason.

ibmvfc_find_target() skips targets mid-teardown (rport == NULL and
nvme_remote_port == NULL), so a LINK_CONGESTED or CONGESTION_CLEARED
event with non-zero identifiers may still fail to find a target when
the matching port is being torn down. Since those event types describe
host-scope congestion that does not require a live rport, fall through
to a host-scope descriptor (wwpn=0) via the existing send_fpin path
rather than dropping the event with "Invalid target for FPIN".

Update KUnit tests to use ibmvfc_run_async_work() with a single reused
struct ibmvfc_async_crq_event rather than arrays at call sites.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
Signed-off-by: Tyrel Datwyler <tyreld@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c  | 213 ++++++++++++++++++++++++++++-------
 drivers/scsi/ibmvscsi/ibmvfc.h       |  15 ++-
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 189 ++++++++++++++++++++++++++-----
 3 files changed, 349 insertions(+), 68 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index b9b571db4464..7406e7182777 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -3446,19 +3446,62 @@ ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, __be64 detecting_wwpn,
 					  cpu_to_be32(1));
 }
 
+/**
+ * ibmvfc_full_fpin_to_desc(): allocate and populate a struct fc_els_fpin struct
+ * containing a descriptor.
+ * @ibmvfc_fpin:	Pointer to async subq FPIN data
+ * @detecting_wwpn:	WWPN of the local port that detected the event (big-endian)
+ * @wwpn:		attached port WWPN (host-endian)
+ *
+ * Allocate a struct fc_els_fpin containing a descriptor and populate
+ * based on data from *ibmvfc_fpin.
+ *
+ * Return:
+ * NULL     - unable to allocate structure
+ * non-NULL - pointer to populated struct fc_els_fpin
+ */
+static struct fc_els_fpin *
+ibmvfc_full_fpin_to_desc(struct ibmvfc_async_sub_crq *ibmvfc_fpin,
+			 __be64 detecting_wwpn, u64 wwpn)
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
+	return ibmvfc_common_fpin_to_desc(ibmvfc_fpin->fpin_status, detecting_wwpn,
+					  cpu_to_be64(wwpn), type, cpu_to_be16(0),
+					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD),
+					  cpu_to_be32(1));
+}
+
 /**
  * ibmvfc_find_target - Search for a target in a target list
  * @target_list: list head of targets to search
  * @scsi_id: SCSI ID to match (0 to skip this check)
  * @wwpn: WWPN to match (0 to skip this check)
  * @node_name: Node name to match (0 to skip this check)
+ * @assoc_id: Association ID to match (0 to skip this check)
  *
  * Returns:
  * Pointer to matching target, or NULL if not found
  **/
 static struct ibmvfc_target *ibmvfc_find_target(struct list_head *target_list,
 						__be64 scsi_id, __be64 wwpn,
-						__be64 node_name)
+						__be64 node_name, __be64 assoc_id)
 {
 	struct ibmvfc_target *tgt;
 
@@ -3469,6 +3512,8 @@ static struct ibmvfc_target *ibmvfc_find_target(struct list_head *target_list,
 			continue;
 		if (node_name && tgt->ids.node_name != be64_to_cpu(node_name))
 			continue;
+		if (assoc_id && tgt->assoc_id != be64_to_cpu(assoc_id))
+			continue;
 		if (!tgt->rport && !tgt->nvme_remote_port)
 			continue;
 		return tgt;
@@ -3483,33 +3528,59 @@ static struct ibmvfc_target *ibmvfc_find_target(struct list_head *target_list,
  */
 VISIBLE_IF_KUNIT void ibmvfc_process_async_work(struct work_struct *work)
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
+	__be64 assoc_id;
+	__be64 node_name;
+	__be64 scsi_id;
+	__be64 wwpn;
+	u8 fpin_status;
 
 	aw = container_of_const(work, struct ibmvfc_async_work, async_work_s);
 	vhost = aw->vhost;
-	crq = &aw->crq;
+	if (aw->event.type == IBMVFC_ASYNC_CRQ_SUB) {
+		subq = &aw->event.subq;
+		scsi_id = 0;
+		wwpn = subq->wwpn;
+		fpin_status = subq->fpin_status;
+		if (subq->flags & IBMVFC_ASYNC_ID_IS_ASSOC_ID) {
+			node_name = 0;
+			assoc_id = subq->id.assoc_id;
+		} else if (subq->flags & IBMVFC_ASYNC_IS_FPIN_EXT) {
+			node_name = 0;
+			assoc_id = 0;
+		} else {
+			node_name = subq->id.node_name;
+			assoc_id = 0;
+		}
+	} else {
+		crq = &aw->event.async_crq;
+		scsi_id = crq->scsi_id;
+		wwpn = crq->wwpn;
+		node_name = crq->node_name;
+		fpin_status = crq->fpin_status;
+		assoc_id = 0;
+	}
 
-	if (!crq->scsi_id && !crq->wwpn && !crq->node_name) {
-		if (crq->fpin_status == IBMVFC_AE_FPIN_LINK_CONGESTED ||
-		    crq->fpin_status == IBMVFC_AE_FPIN_CONGESTION_CLEARED)
+	if (!scsi_id && !wwpn && !node_name && !assoc_id) {
+		if (fpin_status == IBMVFC_AE_FPIN_LINK_CONGESTED ||
+		    fpin_status == IBMVFC_AE_FPIN_CONGESTION_CLEARED)
 			fpin = ibmvfc_basic_fpin_to_desc(crq,
 					cpu_to_be64(fc_host_port_name(vhost->host)), 0);
 		goto send_fpin;
 	}
 
 	spin_lock_irqsave(&vhost->host->host_lock, flags);
-	tgt = ibmvfc_find_target(&vhost->scsi_scrqs.targets, crq->scsi_id,
-				 crq->wwpn, crq->node_name);
+	tgt = ibmvfc_find_target(&vhost->scsi_scrqs.targets, scsi_id, wwpn, node_name, assoc_id);
+
 	if (!tgt) {
 		/* Target not found in scsi_scrqs, search nvme_scrqs */
-		tgt = ibmvfc_find_target(&vhost->nvme_scrqs.targets,
-					 crq->scsi_id, crq->wwpn,
-					 crq->node_name);
+		tgt = ibmvfc_find_target(&vhost->nvme_scrqs.targets, scsi_id, wwpn, node_name, assoc_id);
 	}
 
 	if (tgt) {
@@ -3517,13 +3588,29 @@ VISIBLE_IF_KUNIT void ibmvfc_process_async_work(struct work_struct *work)
 		spin_unlock_irqrestore(&vhost->host->host_lock, flags);
 	} else {
 		spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+		if (fpin_status == IBMVFC_AE_FPIN_LINK_CONGESTED ||
+		    fpin_status == IBMVFC_AE_FPIN_CONGESTION_CLEARED) {
+			if (crq)
+				fpin = ibmvfc_basic_fpin_to_desc(crq,
+						cpu_to_be64(fc_host_port_name(vhost->host)), 0);
+			else
+				fpin = ibmvfc_full_fpin_to_desc(subq,
+						cpu_to_be64(fc_host_port_name(vhost->host)), 0);
+			goto send_fpin;
+		}
 		dev_err_ratelimited(vhost->dev, "Invalid target for FPIN\n");
 		goto free;
 	}
 
-	fpin = ibmvfc_basic_fpin_to_desc(crq,
+	if (crq)
+		fpin = ibmvfc_basic_fpin_to_desc(crq,
 				cpu_to_be64(fc_host_port_name(vhost->host)),
 				tgt->wwpn);
+	else
+		fpin = ibmvfc_full_fpin_to_desc(subq,
+				cpu_to_be64(fc_host_port_name(vhost->host)),
+				tgt->wwpn);
+
 send_fpin:
 	if (fpin) {
 		fc_host_fpin_rcv(vhost->host,
@@ -3543,25 +3630,62 @@ EXPORT_SYMBOL_IF_KUNIT(ibmvfc_process_async_work);
 
 /**
  * ibmvfc_handle_async - Handle an async event from the adapter
- * @crq:	crq to process
+ * @ae:		tagged union wrapping either an ibmvfc_async_crq (main CRQ) or an
+ *		ibmvfc_async_sub_crq (async sub-CRQ); the type field identifies which
  * @vhost:	ibmvfc host struct
  *
  **/
-static void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
+static void ibmvfc_handle_async(struct ibmvfc_async_crq_event *ae,
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
+	__be64 assoc_id;
+	__be64 node_name;
+	__be64 scsi_id;
+	u8 link_state;
+	__be64 wwpn;
+	u64 event;
+
+	if (ae->type == IBMVFC_ASYNC_CRQ_SUB) {
+		subq = &ae->subq;
+		event = (u64)be16_to_cpu(subq->event);
+		link_state = subq->link_state;
+		scsi_id = 0;
+		wwpn = subq->wwpn;
+		if (subq->flags & IBMVFC_ASYNC_ID_IS_ASSOC_ID) {
+			node_name = 0;
+			assoc_id = subq->id.assoc_id;
+		} else if (subq->flags & IBMVFC_ASYNC_IS_FPIN_EXT) {
+			node_name = 0;
+			assoc_id = 0;
+		} else {
+			node_name = subq->id.node_name;
+			assoc_id = 0;
+		}
+	} else {
+		async_crq = &ae->async_crq;
+		event = be64_to_cpu(async_crq->event);
+		link_state = async_crq->link_state;
+		scsi_id = async_crq->scsi_id;
+		wwpn = async_crq->wwpn;
+		node_name = async_crq->node_name;
+		assoc_id = 0;
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
@@ -3600,33 +3724,37 @@ static void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 	case IBMVFC_AE_ELS_PRLO:
 	case IBMVFC_AE_ELS_PLOGI:
 		list_for_each_entry(tgt, &vhost->scsi_scrqs.targets, queue) {
-			if (!crq->scsi_id && !crq->wwpn && !crq->node_name)
+			if (!scsi_id && !wwpn && !node_name && !assoc_id)
 				break;
-			if (crq->scsi_id && cpu_to_be64(tgt->scsi_id) != crq->scsi_id)
+			if (scsi_id && cpu_to_be64(tgt->scsi_id) != scsi_id)
+				continue;
+			if (wwpn && cpu_to_be64(tgt->ids.port_name) != wwpn)
 				continue;
-			if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
+			if (node_name && cpu_to_be64(tgt->ids.node_name) != node_name)
 				continue;
-			if (crq->node_name && cpu_to_be64(tgt->ids.node_name) != crq->node_name)
+			if (assoc_id && cpu_to_be64(tgt->assoc_id) != assoc_id)
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
+			if (!scsi_id && !wwpn && !node_name && !assoc_id)
 				break;
-			if (crq->scsi_id && cpu_to_be64(tgt->scsi_id) != crq->scsi_id)
+			if (scsi_id && cpu_to_be64(tgt->scsi_id) != scsi_id)
+				continue;
+			if (wwpn && cpu_to_be64(tgt->ids.port_name) != wwpn)
 				continue;
-			if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
+			if (node_name && cpu_to_be64(tgt->ids.node_name) != node_name)
 				continue;
-			if (crq->node_name && cpu_to_be64(tgt->ids.node_name) != crq->node_name)
+			if (assoc_id && cpu_to_be64(tgt->assoc_id) != assoc_id)
 				continue;
-			if (tgt->need_login && be64_to_cpu(crq->event) == IBMVFC_AE_ELS_LOGO)
+			if (tgt->need_login && event == IBMVFC_AE_ELS_LOGO)
 				tgt->logo_rcvd = 1;
-			if (!tgt->need_login || be64_to_cpu(crq->event) == IBMVFC_AE_ELS_PLOGI) {
+			if (!tgt->need_login || event == IBMVFC_AE_ELS_PLOGI) {
 				ibmvfc_del_tgt(tgt);
 				ibmvfc_reinit_host(vhost);
 			}
@@ -3653,14 +3781,14 @@ static void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 			}
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
@@ -4188,6 +4316,9 @@ static void ibmvfc_tasklet(void *data)
 {
 	struct ibmvfc_host *vhost = data;
 	struct vio_dev *vdev = to_vio_dev(vhost->dev);
+	struct ibmvfc_async_crq_event ae = {
+		.type = IBMVFC_ASYNC_CRQ_MAIN,
+	};
 	struct ibmvfc_crq *crq;
 	struct ibmvfc_async_crq *async;
 	struct ibmvfc_event *evt, *temp;
@@ -4200,7 +4331,8 @@ static void ibmvfc_tasklet(void *data)
 	while (!done) {
 		/* Pull all the valid messages off the async CRQ */
 		while ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
-			ibmvfc_handle_async(async, vhost);
+			ae.async_crq = *async;
+			ibmvfc_handle_async(&ae, vhost);
 			async->valid = 0;
 			wmb();
 		}
@@ -4214,8 +4346,9 @@ static void ibmvfc_tasklet(void *data)
 
 		vio_enable_interrupts(vdev);
 		if ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
+			ae.async_crq = *async;
 			vio_disable_interrupts(vdev);
-			ibmvfc_handle_async(async, vhost);
+			ibmvfc_handle_async(&ae, vhost);
 			async->valid = 0;
 			wmb();
 		} else if ((crq = ibmvfc_next_crq(vhost)) != NULL) {
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index 2ecd60138d58..86b600ec57c7 100644
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
 
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index 9d0675c33d42..71fbe779b0f2 100644
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
@@ -25,7 +24,7 @@ MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
  */
 static void ibmvfc_run_async_work(struct workqueue_struct *wq,
 				  struct ibmvfc_host *vhost,
-				  struct ibmvfc_async_crq *ae)
+				  struct ibmvfc_async_crq_event *ae)
 {
 	struct ibmvfc_async_work *aw;
 
@@ -38,7 +37,7 @@ static void ibmvfc_run_async_work(struct workqueue_struct *wq,
 	}
 	INIT_WORK(&aw->async_work_s, ibmvfc_process_async_work);
 	aw->vhost = vhost;
-	aw->crq = *ae;
+	aw->event = *ae;
 	queue_work(wq, &aw->async_work_s);
 	flush_workqueue(wq);
 }
@@ -60,7 +59,7 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 {
 	u64 post[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
 	u64 pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
-	struct ibmvfc_async_crq ae = {};
+	struct ibmvfc_async_crq_event ae = { .type = IBMVFC_ASYNC_CRQ_MAIN };
 	enum ibmvfc_ae_fpin_status fs;
 	struct workqueue_struct *wq;
 	struct fc_host_attrs *fc_host;
@@ -115,13 +114,13 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
 
 	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
-		ae.valid = 0x80;
-		ae.link_state = IBMVFC_AE_LS_LINK_UP;
-		ae.fpin_status = fs;
-		ae.event = cpu_to_be64(IBMVFC_AE_FPIN);
-		ae.scsi_id = cpu_to_be64(tgt->scsi_id);
-		ae.wwpn = cpu_to_be64(tgt->wwpn);
-		ae.node_name = cpu_to_be64(tgt->ids.node_name);
+		ae.async_crq.valid = 0x80;
+		ae.async_crq.link_state = IBMVFC_AE_LS_LINK_UP;
+		ae.async_crq.fpin_status = fs;
+		ae.async_crq.event = cpu_to_be64(IBMVFC_AE_FPIN);
+		ae.async_crq.scsi_id = cpu_to_be64(tgt->scsi_id);
+		ae.async_crq.wwpn = cpu_to_be64(tgt->wwpn);
+		ae.async_crq.node_name = cpu_to_be64(tgt->ids.node_name);
 		ibmvfc_run_async_work(wq, vhost, &ae);
 	}
 
@@ -149,13 +148,13 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(rport->fpin_stats.li_failure_unknown);
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
 
-	ae.valid = 0x80;
-	ae.link_state = IBMVFC_AE_LS_LINK_UP;
-	ae.fpin_status = 0; /* bad value */
-	ae.event = cpu_to_be64(IBMVFC_AE_FPIN);
-	ae.scsi_id = cpu_to_be64(tgt->scsi_id);
-	ae.wwpn = cpu_to_be64(tgt->wwpn);
-	ae.node_name = cpu_to_be64(tgt->ids.node_name);
+	ae.async_crq.valid = 0x80;
+	ae.async_crq.link_state = IBMVFC_AE_LS_LINK_UP;
+	ae.async_crq.fpin_status = 0; /* bad value */
+	ae.async_crq.event = cpu_to_be64(IBMVFC_AE_FPIN);
+	ae.async_crq.scsi_id = cpu_to_be64(tgt->scsi_id);
+	ae.async_crq.wwpn = cpu_to_be64(tgt->wwpn);
+	ae.async_crq.node_name = cpu_to_be64(tgt->ids.node_name);
 	ibmvfc_run_async_work(wq, vhost, &ae);
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
@@ -183,17 +182,17 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
 
-	ae.valid = 0x80;
-	ae.link_state = IBMVFC_AE_LS_LINK_UP;
-	ae.event = cpu_to_be64(IBMVFC_AE_FPIN);
-	ae.scsi_id = 0;
-	ae.wwpn = 0;
-	ae.node_name = 0;
+	ae.async_crq.valid = 0x80;
+	ae.async_crq.link_state = IBMVFC_AE_LS_LINK_UP;
+	ae.async_crq.event = cpu_to_be64(IBMVFC_AE_FPIN);
+	ae.async_crq.scsi_id = 0;
+	ae.async_crq.wwpn = 0;
+	ae.async_crq.node_name = 0;
 
-	ae.fpin_status = IBMVFC_AE_FPIN_LINK_CONGESTED;
+	ae.async_crq.fpin_status = IBMVFC_AE_FPIN_LINK_CONGESTED;
 	ibmvfc_run_async_work(wq, vhost, &ae);
 
-	ae.fpin_status = IBMVFC_AE_FPIN_CONGESTION_CLEARED;
+	ae.async_crq.fpin_status = IBMVFC_AE_FPIN_CONGESTION_CLEARED;
 	ibmvfc_run_async_work(wq, vhost, &ae);
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
@@ -214,7 +213,7 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(rport->fpin_stats.cn_device_specific);
 	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
 
-	ae.fpin_status = IBMVFC_AE_FPIN_PORT_CONGESTED;
+	ae.async_crq.fpin_status = IBMVFC_AE_FPIN_PORT_CONGESTED;
 	ibmvfc_run_async_work(wq, vhost, &ae);
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
@@ -285,8 +284,144 @@ static struct kunit_suite ibmvfc_channel_test_suite = {
 };
 kunit_test_init_section_suite(ibmvfc_channel_test_suite);
 
+
+/**
+ * ibmvfc_full_fpin_test - unit test for sub-CRQ FPIN handling via
+ * ibmvfc_process_async_work
+ * @test: pointer to kunit structure
+ *
+ * Tests
+ * - statistics updates on valid FPIN status values
+ * - statistics unchanged on invalid FPIN status value
+ *
+ * Return: void
+ */
+static void ibmvfc_full_fpin_test(struct kunit *test)
+{
+	u64 post[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	u64 pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	struct ibmvfc_async_crq_event ae = { .type = IBMVFC_ASYNC_CRQ_SUB };
+	enum ibmvfc_ae_fpin_status fs;
+	struct workqueue_struct *wq;
+	struct fc_host_attrs *fc_host;
+	struct ibmvfc_target *tgt;
+	struct ibmvfc_host *vhost;
+	struct fc_rport *rport;
+	unsigned long flags;
+
+	vhost = ibmvfc_get_first_vhost();
+	if (!vhost)
+		kunit_skip(test, "No ibmvfc devices available");
+
+	wq = alloc_ordered_workqueue("ibmvfc-kunit-fpin", 0);
+	if (!wq) {
+		scsi_host_put(vhost->host);
+		kunit_skip(test, "Failed to allocate workqueue");
+	}
+
+	spin_lock_irqsave(&vhost->host->host_lock, flags);
+	if (vhost->scsi_scrqs.num_targets < 1) {
+		spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+		destroy_workqueue(wq);
+		scsi_host_put(vhost->host);
+		kunit_skip(test, "No targets");
+	}
+	tgt = NULL;
+	rport = NULL;
+	list_for_each_entry(tgt, &vhost->scsi_scrqs.targets, queue) {
+		if (tgt->rport &&
+		    tgt->rport->port_state == FC_PORTSTATE_ONLINE &&
+		    (tgt->rport->roles & (FC_PORT_ROLE_FCP_TARGET | FC_PORT_ROLE_NVME_TARGET))) {
+			rport = tgt->rport;
+			get_device(&rport->dev);
+			kref_get(&tgt->kref);
+			break;
+		}
+	}
+	if (!rport) {
+		spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+		destroy_workqueue(wq);
+		scsi_host_put(vhost->host);
+		kunit_skip(test, "No suitable online target rport found");
+	}
+	spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+
+	fc_host = shost_to_fc_host(vhost->host);
+
+	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(rport->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(rport->fpin_stats.cn_clear);
+	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(rport->fpin_stats.li_failure_unknown);
+	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
+		ae.subq.valid = 0x80;
+		ae.subq.link_state = IBMVFC_AE_LS_LINK_UP;
+		ae.subq.fpin_status = fs;
+		ae.subq.event = cpu_to_be16(IBMVFC_AE_FPIN);
+		ae.subq.wwpn = cpu_to_be64(tgt->wwpn);
+		ae.subq.id.node_name = cpu_to_be64(tgt->ids.node_name);
+		ibmvfc_run_async_work(wq, vhost, &ae);
+	}
+
+	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(rport->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(rport->fpin_stats.cn_clear);
+	post[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(rport->fpin_stats.li_failure_unknown);
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
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(rport->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(rport->fpin_stats.cn_clear);
+	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(rport->fpin_stats.li_failure_unknown);
+	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	ae.subq.valid = 0x80;
+	ae.subq.link_state = IBMVFC_AE_LS_LINK_UP;
+	ae.subq.fpin_status = 0; /* bad value */
+	ae.subq.event = cpu_to_be16(IBMVFC_AE_FPIN);
+	ae.subq.wwpn = cpu_to_be64(tgt->wwpn);
+	ae.subq.id.node_name = cpu_to_be64(tgt->ids.node_name);
+	ibmvfc_run_async_work(wq, vhost, &ae);
+
+	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(rport->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(rport->fpin_stats.cn_clear);
+	post[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(rport->fpin_stats.li_failure_unknown);
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
+	destroy_workqueue(wq);
+	put_device(&rport->dev);
+	kref_put(&tgt->kref, ibmvfc_release_tgt);
+	scsi_host_put(vhost->host);
+}
+
 static struct kunit_case ibmvfc_fpin_test_cases[] = {
 	KUNIT_CASE(ibmvfc_async_fpin_test),
+	KUNIT_CASE(ibmvfc_full_fpin_test),
 	{},
 };
 

-- 
2.56.0

