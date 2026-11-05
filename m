From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Thu, 05 Nov 2026 11:22:59 -0600
Subject: [PATCH v18 06/13] scsi: ibmvfc: add basic FPIN support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ibmvfc-fpin-support-v18-6-d683b74736a3@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793899377; l=29433;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=gTyvxf6mPdy66SHq0ozozoE9+GTJcAP1uJtNFlpfXQU=;
 b=PhhRLzbgJBsFPmfAq/tFEYzsWZte8pPEvPOcYJLk7fWEnppOIXFbok5HrOD7rRmBkHvfysuZE
 GAf1H40BB9sDCJcJF+HjsLca74HaJRcVoahKE/ZnOhRp1Perr0eUpzS
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement support for a basic level of Fabric Performance Impact
Notifications (FPIN) in the ibmvfc driver to enable monitoring of
fabric congestion and link integrity events.

Add async event handler for IBMVFC_AE_FPIN events that offloads FPIN
processing via a per-adapter ordered workqueue (fpin_workq). Convert
VIOS FPIN messages to standard fc_els_fpin structures and pass them to
fc_host_fpin_rcv() for processing by the FC transport layer.

The per-adapter workqueue is allocated in ibmvfc_probe() and destroyed
in ibmvfc_remove() after ibmvfc_release_crq_queue(). This ordering is
critical: ibmvfc_release_crq_queue() disables CRQ interrupts and kills
the tasklet, ensuring no new work items can be queued after that point.
destroy_workqueue() then drains any already-queued items before
ibmvfc_free_mem() runs, preventing use-after-free of tgt_pool.
In ibmvfc_probe(), allocate fpin_workq after ibmvfc_alloc_mem() succeeds
so that the error unwind path never calls destroy_workqueue() before
ibmvfc_free_mem() -- which would otherwise double-free resources that
ibmvfc_alloc_mem() already unwound internally.

Introduce common FPIN conversion routines that will be reused for full
and extended FPIN support in subsequent patches. Add KUnit test
infrastructure to validate FPIN event handling and statistics updates.

The KUnit test uses a private owned workqueue per test created with
alloc_ordered_workqueue(). This gives ibmvfc_process_async_work() its
own thread stack, avoiding kernel stack overflow when called from the
deep KUnit test context.

Host-scope FPIN events (IBMVFC_AE_FPIN_LINK_CONGESTED and
IBMVFC_AE_FPIN_CONGESTION_CLEARED) carry no per-target WWPN -- the
all-zero identifier fields in the CRQ are intentional, not an error.
Handle these events by calling ibmvfc_basic_fpin_to_desc() with wwpn=0
and delivering the resulting descriptor directly to fc_host_fpin_rcv()
without requiring a target lookup. Per-target events continue to look
up the target by scsi_id/wwpn/node_name as before. Use vhost->host
(available in both paths) rather than tgt->vhost->host for the
fc_host_fpin_rcv() call.

The basic CRQ format carries no detecting port WWPN. Set detecting_wwpn
in fc_fn_peer_congn_desc and fc_fn_li_desc to fc_host_port_name(), the
local port's own WWPN, which is the port that received and is reporting
the event. Without this, detecting_wwpn would be zero from kzalloc and
propagate to userspace verbatim via fc_host_post_fc_event(). The basic
CRQ format also carries no event_threshold or event_count; compile-time
defaults are used for those fields and documented as such in the
ibmvfc_basic_fpin_to_desc() kernel-doc.

Add ibmvfc_handle_async() support for IBMVFC_AE_FPIN events, FPIN
message conversion to fc_els_fpin format, handling of link congestion,
port congestion, port cleared, port degraded, and congestion cleared
events, and a KUnit test module for FPIN functionality.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
Signed-off-by: Tyrel Datwyler <tyreld@linux.ibm.com>
---
 drivers/scsi/Kconfig                 |   6 +-
 drivers/scsi/ibmvscsi/ibmvfc-core.c  | 308 ++++++++++++++++++++++++++++++++++-
 drivers/scsi/ibmvscsi/ibmvfc.h       |  12 ++
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 238 +++++++++++++++++++++++++++
 4 files changed, 559 insertions(+), 5 deletions(-)

diff --git a/drivers/scsi/Kconfig b/drivers/scsi/Kconfig
index f47789b1102d..db934a18488d 100644
--- a/drivers/scsi/Kconfig
+++ b/drivers/scsi/Kconfig
@@ -765,9 +765,9 @@ config SCSI_IBMVFC_KUNIT_TEST
 	default KUNIT_ALL_TESTS
 	help
 	  Compile IBM POWER Virtual FC client KUnit tests. These tests
-	  cover the sub-CRQ channel deregistration guard path.
-	  To compile this driver as a module, choose M here: the module
-	  will be called ibmvfc_kunit.
+	  cover the sub-CRQ channel deregistration guard path and FPIN
+	  event processing. To compile this driver as a module, choose
+	  M here: the module will be called ibmvfc_kunit.
 
 config SCSI_IBMVFC_TRACE
 	bool "enable driver internal trace"
diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index e04c80050b98..a87beaeca13c 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -31,6 +31,8 @@
 #include <scsi/scsi_tcq.h>
 #include <scsi/scsi_transport_fc.h>
 #include <scsi/scsi_bsg_fc.h>
+#include <scsi/fc/fc_els.h>
+#include <linux/overflow.h>
 #include <kunit/visibility.h>
 #include "ibmvfc.h"
 
@@ -1436,6 +1438,7 @@ void ibmvfc_release_tgt(struct kref *kref)
 	struct ibmvfc_target *tgt = container_of(kref, struct ibmvfc_target, kref);
 	mempool_free(tgt, tgt->vhost->tgt_pool);
 }
+EXPORT_SYMBOL_IF_KUNIT(ibmvfc_release_tgt);
 
 /**
  * ibmvfc_get_starget_node_name - Get SCSI target's node name
@@ -3216,6 +3219,7 @@ static const struct ibmvfc_async_desc ae_desc [] = {
 	{ "Halt",	IBMVFC_AE_HALT,		IBMVFC_DEFAULT_LOG_LEVEL },
 	{ "Resume",	IBMVFC_AE_RESUME,	IBMVFC_DEFAULT_LOG_LEVEL },
 	{ "Adapter Failed", IBMVFC_AE_ADAPTER_FAILED, IBMVFC_DEFAULT_LOG_LEVEL },
+	{ "FPIN",	IBMVFC_AE_FPIN,		IBMVFC_DEFAULT_LOG_LEVEL },
 };
 
 static const struct ibmvfc_async_desc unknown_ae = {
@@ -3264,6 +3268,277 @@ static const char *ibmvfc_get_link_state(enum ibmvfc_ae_link_state state)
 	return "";
 }
 
+#define IBMVFC_FPIN_CONGN_DESC_SZ (sizeof(struct fc_els_fpin) + sizeof(struct fc_fn_congn_desc))
+#define IBMVFC_FPIN_LI_DESC_SZ (sizeof(struct fc_els_fpin) + \
+				struct_size_t(struct fc_fn_li_desc, pname_list, 1))
+#define IBMVFC_FPIN_PEER_CONGN_DESC_SZ (sizeof(struct fc_els_fpin) + \
+					struct_size_t(struct fc_fn_peer_congn_desc, pname_list, 1))
+
+/**
+ * ibmvfc_fpin_size_helper(): compute fpin structure size based on fpin status
+ * @fpin_status: status value
+ *
+ * Return:
+ * 0: invalid fpin_status
+ * other: valid size
+ */
+static size_t ibmvfc_fpin_size_helper(u8 fpin_status)
+{
+	size_t size = 0;
+
+	switch (fpin_status) {
+	case IBMVFC_AE_FPIN_LINK_CONGESTED:
+	case IBMVFC_AE_FPIN_CONGESTION_CLEARED:
+		size = IBMVFC_FPIN_CONGN_DESC_SZ;
+		break;
+	case IBMVFC_AE_FPIN_PORT_CONGESTED:
+	case IBMVFC_AE_FPIN_PORT_CLEARED:
+		size = IBMVFC_FPIN_PEER_CONGN_DESC_SZ;
+		break;
+	case IBMVFC_AE_FPIN_PORT_DEGRADED:
+		size = IBMVFC_FPIN_LI_DESC_SZ;
+		break;
+	default:
+		break;
+	}
+
+	return size;
+}
+
+/**
+ * ibmvfc_common_fpin_to_desc(): allocate and populate a struct fc_els_fpin struct
+ * containing a descriptor.
+ * @fpin_status:	IBMVFC FPIN status value; selects descriptor type
+ * @detecting_wwpn:	WWPN of the local port that detected the event (big-endian);
+ *			used for IBMVFC_AE_FPIN_PORT_CONGESTED,
+ *			IBMVFC_AE_FPIN_PORT_CLEARED, and
+ *			IBMVFC_AE_FPIN_PORT_DEGRADED only
+ * @wwpn:		attached port WWPN (big-endian)
+ * @type:		FC FPIN event type (big-endian)
+ * @modifier:		FC FPIN event modifier (big-endian)
+ * @threshold:		link integrity event threshold (big-endian); used for
+ *			IBMVFC_AE_FPIN_PORT_DEGRADED only
+ * @event_count:	link integrity event count (big-endian); used for
+ *			IBMVFC_AE_FPIN_PORT_DEGRADED only
+ *
+ * Return:
+ * NULL     - unable to allocate structure or unrecognised fpin_status
+ * non-NULL - pointer to populated struct fc_els_fpin
+ */
+static struct fc_els_fpin *
+ibmvfc_common_fpin_to_desc(u8 fpin_status, __be64 detecting_wwpn, __be64 wwpn,
+			   __be16 type, __be16 modifier,
+			   __be32 threshold, __be32 event_count)
+{
+	struct fc_fn_peer_congn_desc *pdesc;
+	struct fc_fn_congn_desc *cdesc;
+	struct fc_fn_li_desc *ldesc;
+	struct fc_els_fpin *fpin;
+	size_t size;
+
+	size = ibmvfc_fpin_size_helper(fpin_status);
+	if (!size)
+		return NULL;
+
+	fpin = kzalloc(size, GFP_KERNEL);
+	if (!fpin)
+		return NULL;
+
+	fpin->fpin_cmd = ELS_FPIN;
+
+	switch (fpin_status) {
+	case IBMVFC_AE_FPIN_CONGESTION_CLEARED:
+	case IBMVFC_AE_FPIN_LINK_CONGESTED:
+		fpin->desc_len = cpu_to_be32(sizeof(struct fc_fn_congn_desc));
+		cdesc = (struct fc_fn_congn_desc *)fpin->fpin_desc;
+		cdesc->desc_tag = cpu_to_be32(ELS_DTAG_CONGESTION);
+		cdesc->desc_len = cpu_to_be32(FC_TLV_DESC_LENGTH_FROM_SZ(*cdesc));
+		cdesc->event_type = type;
+		cdesc->event_modifier = modifier;
+		cdesc->event_period = cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_PERIOD);
+		cdesc->severity = FPIN_CONGN_SEVERITY_WARNING;
+		break;
+	case IBMVFC_AE_FPIN_PORT_CONGESTED:
+	case IBMVFC_AE_FPIN_PORT_CLEARED:
+		fpin->desc_len =
+			cpu_to_be32(struct_size_t(struct fc_fn_peer_congn_desc, pname_list, 1));
+		pdesc = (struct fc_fn_peer_congn_desc *)fpin->fpin_desc;
+		pdesc->desc_tag = cpu_to_be32(ELS_DTAG_PEER_CONGEST);
+		pdesc->desc_len = cpu_to_be32(struct_size_t(struct fc_fn_peer_congn_desc,
+							    pname_list, 1) - FC_TLV_DESC_HDR_SZ);
+		pdesc->event_type = type;
+		pdesc->event_modifier = modifier;
+		pdesc->event_period = cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_PERIOD);
+		pdesc->detecting_wwpn = detecting_wwpn;
+		pdesc->attached_wwpn = wwpn;
+		pdesc->pname_count = cpu_to_be32(1);
+		pdesc->pname_list[0] = wwpn;
+		break;
+	case IBMVFC_AE_FPIN_PORT_DEGRADED:
+		fpin->desc_len = cpu_to_be32(struct_size_t(struct fc_fn_li_desc, pname_list, 1));
+		ldesc = (struct fc_fn_li_desc *)fpin->fpin_desc;
+		ldesc->desc_tag = cpu_to_be32(ELS_DTAG_LNK_INTEGRITY);
+		ldesc->desc_len = cpu_to_be32(struct_size_t(struct fc_fn_li_desc,
+							    pname_list, 1) - FC_TLV_DESC_HDR_SZ);
+		ldesc->event_type = type;
+		ldesc->event_modifier = modifier;
+		ldesc->event_threshold = threshold;
+		ldesc->event_count = event_count;
+		ldesc->detecting_wwpn = detecting_wwpn;
+		ldesc->attached_wwpn = wwpn;
+		ldesc->pname_count = cpu_to_be32(1);
+		ldesc->pname_list[0] = wwpn;
+		break;
+	default:
+		/* This should be caught above. */
+		kfree(fpin);
+		fpin = NULL;
+		break;
+	}
+
+	return fpin;
+}
+
+/**
+ * ibmvfc_basic_fpin_to_desc(): allocate and populate a struct fc_els_fpin struct
+ * containing a descriptor.
+ * @crq:		Pointer to async crq
+ * @detecting_wwpn:	WWPN of the local port that detected the event (big-endian)
+ * @wwpn:		attached port WWPN (host-endian)
+ *
+ * Allocate a struct fc_els_fpin containing a descriptor and populate
+ * based on data from @crq. @detecting_wwpn is set from fc_host_port_name
+ * since the basic CRQ format carries no detecting port information.
+ * @threshold and event_count are fixed compile-time defaults since the basic
+ * CRQ format carries no adapter-provided values for these fields.
+ *
+ * Return:
+ * NULL     - unable to allocate structure
+ * non-NULL - pointer to populated struct fc_els_fpin
+ */
+static struct fc_els_fpin *
+ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, __be64 detecting_wwpn,
+			  u64 wwpn)
+{
+	__be16 type;
+
+	switch (crq->fpin_status) {
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
+	return ibmvfc_common_fpin_to_desc(crq->fpin_status, detecting_wwpn,
+					  cpu_to_be64(wwpn), type, cpu_to_be16(0),
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
+		if (scsi_id && tgt->scsi_id != be64_to_cpu(scsi_id))
+			continue;
+		if (wwpn && tgt->ids.port_name != be64_to_cpu(wwpn))
+			continue;
+		if (node_name && tgt->ids.node_name != be64_to_cpu(node_name))
+			continue;
+		if (!tgt->rport && !tgt->nvme_remote_port)
+			continue;
+		return tgt;
+	}
+
+	return NULL;
+}
+
+/**
+ * ibmvfc_process_async_work - Process IBMVFC_AE_FPIN async CRQ from work queue
+ * @work: pointer to work_struct
+ */
+VISIBLE_IF_KUNIT void ibmvfc_process_async_work(struct work_struct *work)
+{
+	struct ibmvfc_async_work *aw;
+	struct ibmvfc_async_crq *crq;
+	struct ibmvfc_target *tgt;
+	struct ibmvfc_host *vhost;
+	struct fc_els_fpin *fpin;
+	unsigned long flags;
+
+	aw = container_of_const(work, struct ibmvfc_async_work, async_work_s);
+	vhost = aw->vhost;
+	crq = &aw->crq;
+
+	if (!crq->scsi_id && !crq->wwpn && !crq->node_name) {
+		if (crq->fpin_status == IBMVFC_AE_FPIN_LINK_CONGESTED ||
+		    crq->fpin_status == IBMVFC_AE_FPIN_CONGESTION_CLEARED)
+			fpin = ibmvfc_basic_fpin_to_desc(crq,
+					cpu_to_be64(fc_host_port_name(vhost->host)), 0);
+		goto send_fpin;
+	}
+
+	spin_lock_irqsave(&vhost->host->host_lock, flags);
+	tgt = ibmvfc_find_target(&vhost->scsi_scrqs.targets, crq->scsi_id,
+				 crq->wwpn, crq->node_name);
+	if (!tgt) {
+		/* Target not found in scsi_scrqs, search nvme_scrqs */
+		tgt = ibmvfc_find_target(&vhost->nvme_scrqs.targets,
+					 crq->scsi_id, crq->wwpn,
+					 crq->node_name);
+	}
+
+	if (tgt) {
+		kref_get(&tgt->kref);
+		spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+	} else {
+		spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+		dev_err_ratelimited(vhost->dev, "Invalid target for FPIN\n");
+		goto free;
+	}
+
+	fpin = ibmvfc_basic_fpin_to_desc(crq,
+				cpu_to_be64(fc_host_port_name(vhost->host)),
+				tgt->wwpn);
+send_fpin:
+	if (fpin) {
+		fc_host_fpin_rcv(vhost->host,
+				 sizeof(*fpin) + be32_to_cpu(fpin->desc_len),
+				 (char *)fpin, 0);
+		kfree(fpin);
+	} else
+		dev_err_ratelimited(vhost->dev, "FPIN event received, unable to process\n");
+
+	if (tgt)
+		kref_put(&tgt->kref, ibmvfc_release_tgt);
+ free:
+	scsi_host_put(aw->vhost->host);
+	kfree(aw);
+}
+EXPORT_SYMBOL_IF_KUNIT(ibmvfc_process_async_work);
+
 /**
  * ibmvfc_handle_async - Handle an async event from the adapter
  * @crq:	crq to process
@@ -3274,6 +3549,7 @@ static void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 				struct ibmvfc_host *vhost)
 {
 	const struct ibmvfc_async_desc *desc = ibmvfc_get_ae_desc(be64_to_cpu(crq->event));
+	struct ibmvfc_async_work *aw;
 	struct ibmvfc_target *tgt;
 
 	ibmvfc_log(vhost, desc->log_level, "%s event received. scsi_id: %llx, wwpn: %llx,"
@@ -3364,6 +3640,23 @@ static void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 	case IBMVFC_AE_HALT:
 		ibmvfc_link_down(vhost, IBMVFC_HALTED);
 		break;
+	case IBMVFC_AE_FPIN:
+		if (vhost->state == IBMVFC_HOST_OFFLINE)
+			break;
+		aw = kzalloc_obj(*aw, GFP_ATOMIC);
+		if (aw) {
+			if (!scsi_host_get(vhost->host)) {
+				kfree(aw);
+				break;
+			}
+			INIT_WORK(&aw->async_work_s, ibmvfc_process_async_work);
+			aw->vhost = vhost;
+			aw->crq = *crq;
+			queue_work(vhost->fpin_workq, &aw->async_work_s);
+		} else
+			dev_err_ratelimited(vhost->dev,
+					    "can't offload async CRQ to work queue\n");
+		break;
 	default:
 		dev_err(vhost->dev, "Unknown async event received: %lld\n", crq->event);
 		break;
@@ -6906,9 +7199,17 @@ static int ibmvfc_probe(struct vio_dev *vdev, const struct vio_device_id *id)
 	INIT_WORK(&vhost->rport_add_work_q, ibmvfc_rport_add_thread);
 	mutex_init(&vhost->passthru_mutex);
 
-	if ((rc = ibmvfc_alloc_mem(vhost)))
+	rc = ibmvfc_alloc_mem(vhost);
+	if (rc)
 		goto free_scsi_host;
 
+	vhost->fpin_workq = alloc_ordered_workqueue("%s-fpin-workq-%u", 0,
+						    IBMVFC_NAME, shost->host_no);
+	if (!vhost->fpin_workq) {
+		rc = -ENOMEM;
+		goto free_host_mem;
+	}
+
 	vhost->work_thread = kthread_run(ibmvfc_work, vhost, "%s_%d", IBMVFC_NAME,
 					 shost->host_no);
 
@@ -6916,7 +7217,7 @@ static int ibmvfc_probe(struct vio_dev *vdev, const struct vio_device_id *id)
 		dev_err(dev, "Couldn't create kernel thread: %ld\n",
 			PTR_ERR(vhost->work_thread));
 		rc = PTR_ERR(vhost->work_thread);
-		goto free_host_mem;
+		goto free_workq;
 	}
 
 	if ((rc = ibmvfc_init_crq(vhost))) {
@@ -6952,6 +7253,8 @@ static int ibmvfc_probe(struct vio_dev *vdev, const struct vio_device_id *id)
 	ibmvfc_release_crq_queue(vhost);
 kill_kthread:
 	kthread_stop(vhost->work_thread);
+free_workq:
+	destroy_workqueue(vhost->fpin_workq);
 free_host_mem:
 	ibmvfc_free_mem(vhost);
 free_scsi_host:
@@ -6994,6 +7297,7 @@ static void ibmvfc_remove(struct vio_dev *vdev)
 	ibmvfc_complete_purge(&purge);
 	ibmvfc_release_sub_crqs(vhost);
 	ibmvfc_release_crq_queue(vhost);
+	destroy_workqueue(vhost->fpin_workq);
 
 	ibmvfc_free_mem(vhost);
 	spin_lock(&ibmvfc_driver_lock);
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index 421ce8bc3ea3..3fffd2db8ef5 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -750,8 +750,12 @@ enum ibmvfc_ae_fpin_status {
 	IBMVFC_AE_FPIN_PORT_CONGESTED	= 0x2,
 	IBMVFC_AE_FPIN_PORT_CLEARED	= 0x3,
 	IBMVFC_AE_FPIN_PORT_DEGRADED	= 0x4,
+	IBMVFC_AE_FPIN_CONGESTION_CLEARED	= 0x5,
 };
 
+#define IBMVFC_FPIN_DEFAULT_EVENT_PERIOD	(5*60*MSEC_PER_SEC) /* 5 minutes */
+#define IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD	(5*60*MSEC_PER_SEC/2) /* 2.5 minutes */
+
 struct ibmvfc_async_crq {
 	volatile u8 valid;
 	u8 link_state;
@@ -781,6 +785,12 @@ struct ibmvfc_async_sub_crq {
 	} id;
 } __packed __aligned(8);
 
+struct ibmvfc_async_work {
+	struct ibmvfc_host *vhost;
+	struct ibmvfc_async_crq crq;
+	struct work_struct async_work_s;
+};
+
 union ibmvfc_iu {
 	struct ibmvfc_mad_common mad_common;
 	struct ibmvfc_npiv_login_mad npiv_login;
@@ -1022,6 +1032,7 @@ struct ibmvfc_host {
 	wait_queue_head_t work_wait_q;
 	struct nvme_fc_local_port *nvme_local_port;
 	struct completion nvme_delete_done;
+	struct workqueue_struct *fpin_workq;
 };
 
 struct ibmvfc_event *__ibmvfc_get_event(struct ibmvfc_queue *queue, int reserved);
@@ -1090,6 +1101,7 @@ static inline struct ibmvfc_host *ibmvfc_channels_to_vhost(struct ibmvfc_channel
 
 #if IS_ENABLED(CONFIG_KUNIT)
 #include <kunit/visibility.h>
+VISIBLE_IF_KUNIT void ibmvfc_process_async_work(struct work_struct *work);
 VISIBLE_IF_KUNIT void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 						struct ibmvfc_channels *channels,
 						int index);
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index 24799aa2368a..9d0675c33d42 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -3,10 +3,237 @@
 #include <kunit/visibility.h>
 #include <scsi/scsi_device.h>
 #include <scsi/scsi_transport_fc.h>
+#include <scsi/fc/fc_els.h>
+#include <linux/list.h>
+#include <linux/delay.h>
 #include "ibmvfc.h"
 
 MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
 
+/**
+ * ibmvfc_run_async_work - queue and drain an FPIN work item via a private workqueue
+ * @wq:		private workqueue to use
+ * @vhost:	ibmvfc host struct
+ * @ae:		async CRQ event to process
+ *
+ * Allocates an ibmvfc_async_work, takes a scsi_host reference (released by
+ * ibmvfc_process_async_work()), populates the work item, queues it on @wq
+ * (which the caller owns), and flushes @wq so the work completes before
+ * returning. Using a private workqueue gives ibmvfc_process_async_work() its
+ * own thread stack, avoiding kernel stack overflow when called from a deep
+ * KUnit context.
+ */
+static void ibmvfc_run_async_work(struct workqueue_struct *wq,
+				  struct ibmvfc_host *vhost,
+				  struct ibmvfc_async_crq *ae)
+{
+	struct ibmvfc_async_work *aw;
+
+	aw = kzalloc_obj(*aw);
+	if (WARN_ON(!aw))
+		return;
+	if (WARN_ON(!scsi_host_get(vhost->host))) {
+		kfree(aw);
+		return;
+	}
+	INIT_WORK(&aw->async_work_s, ibmvfc_process_async_work);
+	aw->vhost = vhost;
+	aw->crq = *ae;
+	queue_work(wq, &aw->async_work_s);
+	flush_workqueue(wq);
+}
+
+/**
+ * ibmvfc_async_fpin_test - unit test for IBMVFC_AE_FPIN handling via
+ * ibmvfc_process_async_work
+ * @test: pointer to kunit structure
+ *
+ * Tests
+ * - statistics updates on valid FPIN status values (per-target path)
+ * - statistics unchanged on invalid FPIN status value
+ * - host-scope delivery for zero-identifier LINK_CONGESTED/CONGESTION_CLEARED
+ * - silent drop for zero-identifier per-port events (PORT_CONGESTED)
+ *
+ * Return: void
+ */
+static void ibmvfc_async_fpin_test(struct kunit *test)
+{
+	u64 post[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	u64 pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	struct ibmvfc_async_crq ae = {};
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
+		ae.valid = 0x80;
+		ae.link_state = IBMVFC_AE_LS_LINK_UP;
+		ae.fpin_status = fs;
+		ae.event = cpu_to_be64(IBMVFC_AE_FPIN);
+		ae.scsi_id = cpu_to_be64(tgt->scsi_id);
+		ae.wwpn = cpu_to_be64(tgt->wwpn);
+		ae.node_name = cpu_to_be64(tgt->ids.node_name);
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
+	ae.valid = 0x80;
+	ae.link_state = IBMVFC_AE_LS_LINK_UP;
+	ae.fpin_status = 0; /* bad value */
+	ae.event = cpu_to_be64(IBMVFC_AE_FPIN);
+	ae.scsi_id = cpu_to_be64(tgt->scsi_id);
+	ae.wwpn = cpu_to_be64(tgt->wwpn);
+	ae.node_name = cpu_to_be64(tgt->ids.node_name);
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
+	/*
+	 * Zero-identifier host-scope path: scsi_id/wwpn/node_name all zero.
+	 * LINK_CONGESTED and CONGESTION_CLEARED deliver a host-scope descriptor
+	 * (no target needed) and must update fc_host fpin_stats.
+	 */
+	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	ae.valid = 0x80;
+	ae.link_state = IBMVFC_AE_LS_LINK_UP;
+	ae.event = cpu_to_be64(IBMVFC_AE_FPIN);
+	ae.scsi_id = 0;
+	ae.wwpn = 0;
+	ae.node_name = 0;
+
+	ae.fpin_status = IBMVFC_AE_FPIN_LINK_CONGESTED;
+	ibmvfc_run_async_work(wq, vhost, &ae);
+
+	ae.fpin_status = IBMVFC_AE_FPIN_CONGESTION_CLEARED;
+	ibmvfc_run_async_work(wq, vhost, &ae);
+
+	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	KUNIT_EXPECT_GE(test, post[IBMVFC_AE_FPIN_LINK_CONGESTED],
+			pre[IBMVFC_AE_FPIN_LINK_CONGESTED] + 1);
+	KUNIT_EXPECT_GE(test, post[IBMVFC_AE_FPIN_CONGESTION_CLEARED],
+			pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] + 1);
+
+	/*
+	 * Zero-identifier silent-drop path: scsi_id/wwpn/node_name all zero,
+	 * but fpin_status is a per-port type (PORT_CONGESTED) that requires a
+	 * target. ibmvfc_process_async_work() reaches send_fpin with fpin==NULL
+	 * and emits no fc_host_fpin_rcv() call, so no stat counter increments.
+	 */
+	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(rport->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	ae.fpin_status = IBMVFC_AE_FPIN_PORT_CONGESTED;
+	ibmvfc_run_async_work(wq, vhost, &ae);
+
+	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(rport->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	KUNIT_EXPECT_EQ(test, pre[IBMVFC_AE_FPIN_LINK_CONGESTED],
+			post[IBMVFC_AE_FPIN_LINK_CONGESTED]);
+	KUNIT_EXPECT_EQ(test, pre[IBMVFC_AE_FPIN_PORT_CONGESTED],
+			post[IBMVFC_AE_FPIN_PORT_CONGESTED]);
+	KUNIT_EXPECT_EQ(test, pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED],
+			post[IBMVFC_AE_FPIN_CONGESTION_CLEARED]);
+
+	destroy_workqueue(wq);
+	kref_put(&tgt->kref, ibmvfc_release_tgt);
+	put_device(&rport->dev);
+	scsi_host_put(vhost->host);
+}
+
 /**
  * ibmvfc_deregister_channel_guard_test - unit test for ibmvfc_deregister_channel()
  *   guard conditions
@@ -58,6 +285,17 @@ static struct kunit_suite ibmvfc_channel_test_suite = {
 };
 kunit_test_init_section_suite(ibmvfc_channel_test_suite);
 
+static struct kunit_case ibmvfc_fpin_test_cases[] = {
+	KUNIT_CASE(ibmvfc_async_fpin_test),
+	{},
+};
+
+static struct kunit_suite ibmvfc_fpin_test_suite = {
+	.name = "ibmvfc-fpin-test",
+	.test_cases = ibmvfc_fpin_test_cases,
+};
+kunit_test_init_section_suite(ibmvfc_fpin_test_suite);
+
 MODULE_LICENSE("GPL");
 MODULE_AUTHOR("Dave Marquardt <davemarq@linux.ibm.com>");
 MODULE_DESCRIPTION("Test module for IBM Virtual Fibre Channel Driver");

-- 
2.56.0

