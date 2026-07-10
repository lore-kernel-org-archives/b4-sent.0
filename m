From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Fri, 10 Jul 2026 14:16:41 -0500
Subject: [PATCH v4 1/8] ibmvfc: add basic FPIN support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-ibmvfc-fpin-support-v4-1-ef031ac19520@linux.ibm.com>
References: <20260710-ibmvfc-fpin-support-v4-0-ef031ac19520@linux.ibm.com>
In-Reply-To: <20260710-ibmvfc-fpin-support-v4-0-ef031ac19520@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783711016; l=20898;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=h7uTz/n5LZnGcsqIITUlKoEOKP5bouVsCbK6LtnUe2c=;
 b=/735JNVEZBOSiCZss9sI2A3gDAX8Ib71Nt42hUlsnKbFK2xnrhtJpKj7VhjynhSrhMFNHoqgU
 iGOg+RsHNsgBC45LGDINMhMGN/Te5T7L8F3q7njnPC0fJwEKywnvQa4
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement support for a basic level of Fabric Performance Impact
Notifications (FPIN) in the ibmvfc driver to enable monitoring of
fabric congestion and link integrity events.

Add async event handler for IBMVFC_AE_FPIN events that offloads FPIN
processing to a dedicated workqueue. Convert VIOS FPIN messages to
standard fc_els_fpin structures and pass them to fc_host_fpin_rcv() for
processing by the FC transport layer.

Introduce common FPIN conversion routines that will be reused for full
and extended FPIN support in subsequent patches. Add KUnit test
infrastructure to validate FPIN event handling and statistics updates.

Changes include:
- Add FPIN async event handling in ibmvfc_handle_async()
- Create dedicated workqueue for FPIN processing
- Implement FPIN message conversion to fc_els_fpin format
- Add support for link congestion, port congestion, port cleared, port
  degraded, and congestion cleared events
- Add KUnit test module for FPIN functionality

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/Kconfig                 |  10 ++
 drivers/scsi/ibmvscsi/Makefile       |   1 +
 drivers/scsi/ibmvscsi/ibmvfc.c       | 253 ++++++++++++++++++++++++++++++++++-
 drivers/scsi/ibmvscsi/ibmvfc.h       |  16 +++
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 132 ++++++++++++++++++
 5 files changed, 405 insertions(+), 7 deletions(-)

diff --git a/drivers/scsi/Kconfig b/drivers/scsi/Kconfig
index c3042393af23..d5fc7eb2ebb1 100644
--- a/drivers/scsi/Kconfig
+++ b/drivers/scsi/Kconfig
@@ -758,6 +758,16 @@ config SCSI_IBMVFC
 	  To compile this driver as a module, choose M here: the
 	  module will be called ibmvfc.
 
+config SCSI_IBMVFC_KUNIT_TEST
+	tristate "KUnit tests for the IBM POWER Virtual FC Client" if !KUNIT_ALL_TESTS
+	depends on SCSI_IBMVFC && KUNIT
+	default KUNIT_ALL_TESTS
+	help
+	  Compile IBM POWER Virtual FC client KUnit tests. These tests
+	  specifically test FPIN functionality. To compile this driver
+	  as a module, choose M here: the module will be called
+	  ibmvfc_kunit.
+
 config SCSI_IBMVFC_TRACE
 	bool "enable driver internal trace"
 	depends on SCSI_IBMVFC
diff --git a/drivers/scsi/ibmvscsi/Makefile b/drivers/scsi/ibmvscsi/Makefile
index 5eb1cb1a0028..75dc7aee15a0 100644
--- a/drivers/scsi/ibmvscsi/Makefile
+++ b/drivers/scsi/ibmvscsi/Makefile
@@ -1,3 +1,4 @@
 # SPDX-License-Identifier: GPL-2.0-only
 obj-$(CONFIG_SCSI_IBMVSCSI)	+= ibmvscsi.o
 obj-$(CONFIG_SCSI_IBMVFC)	+= ibmvfc.o
+obj-$(CONFIG_SCSI_IBMVFC_KUNIT_TEST)	+= ibmvfc_kunit.o
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.c b/drivers/scsi/ibmvscsi/ibmvfc.c
index 3dd2adda195e..d3fd1d3437c6 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc.c
@@ -30,6 +30,9 @@
 #include <scsi/scsi_tcq.h>
 #include <scsi/scsi_transport_fc.h>
 #include <scsi/scsi_bsg_fc.h>
+#include <kunit/visibility.h>
+#include <scsi/fc/fc_els.h>
+#include <linux/overflow.h>
 #include "ibmvfc.h"
 
 static unsigned int init_timeout = IBMVFC_INIT_TIMEOUT;
@@ -3137,6 +3140,7 @@ static const struct ibmvfc_async_desc ae_desc [] = {
 	{ "Halt",	IBMVFC_AE_HALT,		IBMVFC_DEFAULT_LOG_LEVEL },
 	{ "Resume",	IBMVFC_AE_RESUME,	IBMVFC_DEFAULT_LOG_LEVEL },
 	{ "Adapter Failed", IBMVFC_AE_ADAPTER_FAILED, IBMVFC_DEFAULT_LOG_LEVEL },
+	{ "FPIN",	IBMVFC_AE_FPIN,		IBMVFC_DEFAULT_LOG_LEVEL },
 };
 
 static const struct ibmvfc_async_desc unknown_ae = {
@@ -3185,16 +3189,228 @@ static const char *ibmvfc_get_link_state(enum ibmvfc_ae_link_state state)
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
+ *
+ * Allocate a struct fc_els_fpin containing a descriptor and populate
+ * based on data from *ibmvfc_fpin.
+ *
+ * Return:
+ * NULL     - unable to allocate structure
+ * non-NULL - pointer to populated struct fc_els_fpin
+ */
+static struct fc_els_fpin *
+ibmvfc_common_fpin_to_desc(u8 fpin_status, __be64 wwpn, __be16 type, __be16 modifier,
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
+ * @ibmvfc_fpin: Pointer to async crq
+ *
+ * Allocate a struct fc_els_fpin containing a descriptor and populate
+ * based on data from *ibmvfc_fpin.
+ *
+ * Return:
+ * NULL     - unable to allocate structure
+ * non-NULL - pointer to populated struct fc_els_fpin
+ */
+static struct fc_els_fpin *
+ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, u64 wwpn)
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
+		return (NULL);
+	}
+
+	return ibmvfc_common_fpin_to_desc(crq->fpin_status, cpu_to_be64(wwpn),
+					  type, cpu_to_be16(0),
+					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD),
+					  cpu_to_be32(1));
+}
+
+/**
+ * ibmvfc_process_async_work - Process IBMVFC_AE_FPIN async CRQ from work queue
+ * @work: pointer to work_struct
+ */
+static void ibmvfc_process_async_work(struct work_struct *work)
+{
+	struct ibmvfc_target *tgt, *next;
+	struct ibmvfc_async_work *aw;
+	struct ibmvfc_async_crq *crq;
+	struct ibmvfc_host *vhost;
+	struct fc_els_fpin *fpin;
+	unsigned long flags;
+
+	aw = container_of(work, struct ibmvfc_async_work, async_work_s);
+	crq = &aw->crq;
+	vhost = aw->vhost;
+
+	if (!crq->scsi_id && !crq->wwpn && !crq->node_name)
+		goto end;
+
+	spin_lock_irqsave(vhost->host->host_lock, flags);
+	list_for_each_entry_safe(tgt, next, &vhost->targets, queue) {
+		if (crq->scsi_id && cpu_to_be64(tgt->scsi_id) != crq->scsi_id)
+			continue;
+		if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
+			continue;
+		if (crq->node_name && cpu_to_be64(tgt->ids.node_name) != crq->node_name)
+			continue;
+		if (!tgt->rport)
+			continue;
+		break;
+	}
+	spin_unlock_irqrestore(vhost->host->host_lock, flags);
+
+	if (list_entry_is_head(tgt, &vhost->targets, queue) || !tgt->rport) {
+		dev_err_ratelimited(vhost->dev, "Invalid target for FPIN\n");
+		goto end;
+	}
+
+	fpin = ibmvfc_basic_fpin_to_desc(crq, tgt->wwpn);
+	if (fpin) {
+		fc_host_fpin_rcv(tgt->vhost->host,
+				 sizeof(*fpin) + be32_to_cpu(fpin->desc_len),
+				 (char *)fpin, 0);
+		kfree(fpin);
+	} else
+		dev_err_ratelimited(vhost->dev,
+				    "FPIN event %u received, unable to process\n",
+				    crq->fpin_status);
+ end:
+	kfree(aw);
+}
+
 /**
  * ibmvfc_handle_async - Handle an async event from the adapter
  * @crq:	crq to process
  * @vhost:	ibmvfc host struct
  *
  **/
-static void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
-				struct ibmvfc_host *vhost)
+VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
+					  struct ibmvfc_host *vhost)
 {
 	const struct ibmvfc_async_desc *desc = ibmvfc_get_ae_desc(be64_to_cpu(crq->event));
+	struct ibmvfc_async_work *aw;
 	struct ibmvfc_target *tgt;
 
 	ibmvfc_log(vhost, desc->log_level, "%s event received. scsi_id: %llx, wwpn: %llx,"
@@ -3269,11 +3485,23 @@ static void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 	case IBMVFC_AE_HALT:
 		ibmvfc_link_down(vhost, IBMVFC_HALTED);
 		break;
+	case IBMVFC_AE_FPIN:
+		aw = kzalloc(sizeof(struct ibmvfc_async_work), GFP_ATOMIC);
+		if (aw) {
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
 	}
 }
+EXPORT_SYMBOL_IF_KUNIT(ibmvfc_handle_async);
 
 /**
  * ibmvfc_handle_crq - Handles and frees received events in the CRQ
@@ -3803,8 +4031,6 @@ static void ibmvfc_tasklet(void *data)
 		/* Pull all the valid messages off the async CRQ */
 		while ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
 			ibmvfc_handle_async(async, vhost);
-			async->valid = 0;
-			wmb();
 		}
 
 		/* Pull all the valid messages off the CRQ */
@@ -3818,8 +4044,6 @@ static void ibmvfc_tasklet(void *data)
 		if ((async = ibmvfc_next_async_crq(vhost)) != NULL) {
 			vio_disable_interrupts(vdev);
 			ibmvfc_handle_async(async, vhost);
-			async->valid = 0;
-			wmb();
 		} else if ((crq = ibmvfc_next_crq(vhost)) != NULL) {
 			vio_disable_interrupts(vdev);
 			ibmvfc_handle_crq(crq, vhost, &evt_doneq);
@@ -6364,9 +6588,15 @@ static int ibmvfc_probe(struct vio_dev *vdev, const struct vio_device_id *id)
 	INIT_WORK(&vhost->rport_add_work_q, ibmvfc_rport_add_thread);
 	mutex_init(&vhost->passthru_mutex);
 
-	if ((rc = ibmvfc_alloc_mem(vhost)))
+	vhost->fpin_workq = devm_alloc_workqueue(vhost->dev, "%s-fpin-workq-%u", 0, 0,
+						 IBMVFC_NAME, shost->host_no);
+	if (vhost->fpin_workq == NULL)
 		goto free_scsi_host;
 
+	rc = ibmvfc_alloc_mem(vhost);
+	if (rc)
+		goto free_workq;
+
 	vhost->work_thread = kthread_run(ibmvfc_work, vhost, "%s_%d", IBMVFC_NAME,
 					 shost->host_no);
 
@@ -6412,6 +6642,9 @@ static int ibmvfc_probe(struct vio_dev *vdev, const struct vio_device_id *id)
 	kthread_stop(vhost->work_thread);
 free_host_mem:
 	ibmvfc_free_mem(vhost);
+free_workq:
+	destroy_workqueue(vhost->fpin_workq);
+	vhost->fpin_workq = NULL;
 free_scsi_host:
 	scsi_host_put(shost);
 out:
@@ -6603,5 +6836,11 @@ static void __exit ibmvfc_module_exit(void)
 	fc_release_transport(ibmvfc_transport_template);
 }
 
+VISIBLE_IF_KUNIT struct list_head *ibmvfc_get_headp(void)
+{
+	return &ibmvfc_head;
+}
+EXPORT_SYMBOL_IF_KUNIT(ibmvfc_get_headp);
+
 module_init(ibmvfc_module_init);
 module_exit(ibmvfc_module_exit);
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index c73ed2314ad0..f69e0605a78d 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -671,8 +671,12 @@ enum ibmvfc_ae_fpin_status {
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
@@ -686,6 +690,12 @@ struct ibmvfc_async_crq {
 	__be64 reserved;
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
@@ -914,6 +924,7 @@ struct ibmvfc_host {
 	struct work_struct rport_add_work_q;
 	wait_queue_head_t init_wait_q;
 	wait_queue_head_t work_wait_q;
+	struct workqueue_struct *fpin_workq;
 };
 
 #define DBG_CMD(CMD) do { if (ibmvfc_debug) CMD; } while (0)
@@ -953,4 +964,9 @@ struct ibmvfc_host {
 #define ibmvfc_remove_trace_file(kobj, attr) do { } while (0)
 #endif
 
+#ifdef VISIBLE_IF_KUNIT
+VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq, struct ibmvfc_host *vhost);
+VISIBLE_IF_KUNIT struct list_head *ibmvfc_get_headp(void);
+#endif
+
 #endif
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
new file mode 100644
index 000000000000..1c90318b6811
--- /dev/null
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -0,0 +1,132 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+#include <kunit/test.h>
+#include <kunit/visibility.h>
+#include <scsi/scsi_device.h>
+#include <scsi/scsi_transport_fc.h>
+#include <linux/list.h>
+#include <linux/delay.h>
+#include "ibmvfc.h"
+
+MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
+
+/**
+ * ibmvfc_async_fpin_event_test - unit test for IBMVFC_AE_FPIN parts of
+ * ibmvfc_handle_async
+ * @test: pointer to kunit structure
+ *
+ * Tests
+ * - error returns from ibmvfc_handle_async
+ * - statistics updates
+ *
+ * Return: void
+ */
+static void ibmvfc_async_fpin_test(struct kunit *test)
+{
+	u64 post[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	u64 pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	enum ibmvfc_ae_fpin_status fs;
+	struct fc_host_attrs *fc_host;
+	struct ibmvfc_async_crq crq[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	struct ibmvfc_target *tgt;
+	struct ibmvfc_host *vhost;
+	struct list_head *queue;
+	struct list_head *headp;
+
+	headp = ibmvfc_get_headp();
+	if (list_empty(headp))
+		kunit_skip(test, "No ibmvfc devices available");
+	queue = headp->next;
+	vhost = container_of(queue, struct ibmvfc_host, queue);
+
+	KUNIT_ASSERT_GE_MSG(test, vhost->num_targets, 1, "No targets");
+	tgt = list_first_entry(&vhost->targets, struct ibmvfc_target, queue);
+	KUNIT_EXPECT_NOT_NULL(test, tgt->rport);
+
+	fc_host = shost_to_fc_host(vhost->host);
+
+	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
+	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
+	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
+		crq[fs].valid = 0x80;
+		crq[fs].link_state = IBMVFC_AE_LS_LINK_UP;
+		crq[fs].fpin_status = fs;
+		crq[fs].event = cpu_to_be64(IBMVFC_AE_FPIN);
+		crq[fs].scsi_id = cpu_to_be64(tgt->scsi_id);
+		crq[fs].wwpn = cpu_to_be64(tgt->wwpn);
+		crq[fs].node_name = cpu_to_be64(tgt->ids.node_name);
+		ibmvfc_handle_async(&crq[fs], vhost);
+	}
+
+	msleep(500U);
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
+	pre[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	pre[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
+	pre[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
+	pre[IBMVFC_AE_FPIN_PORT_DEGRADED] = READ_ONCE(tgt->rport->fpin_stats.li_failure_unknown);
+	pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = READ_ONCE(fc_host->fpin_stats.cn_clear);
+
+	/* bad path */
+	crq[0].valid = 0x80;
+	crq[0].link_state = IBMVFC_AE_LS_LINK_UP;
+	crq[0].fpin_status = 0; /* bad value */
+	crq[0].event = cpu_to_be64(IBMVFC_AE_FPIN);
+	crq[0].scsi_id = cpu_to_be64(tgt->scsi_id);
+	crq[0].wwpn = cpu_to_be64(tgt->wwpn);
+	crq[0].node_name = cpu_to_be64(tgt->ids.node_name);
+	ibmvfc_handle_async(&crq[0], vhost);
+
+	msleep(500U);
+
+	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
+	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
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
+}
+
+static struct kunit_case ibmvfc_fpin_test_cases[] = {
+	KUNIT_CASE_SLOW(ibmvfc_async_fpin_test),
+	{},
+};
+
+static struct kunit_suite ibmvfc_fpin_test_suite = {
+	.name = "ibmvfc-fpin-test",
+	.test_cases = ibmvfc_fpin_test_cases,
+};
+kunit_test_init_section_suite(ibmvfc_fpin_test_suite);
+
+MODULE_LICENSE("GPL");
+MODULE_AUTHOR("Dave Marquardt <davemarq@linux.ibm.com>");
+MODULE_DESCRIPTION("Test module for IBM Virtual Fibre Channel Driver");

-- 
2.55.0

