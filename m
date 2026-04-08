From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Wed, 08 Apr 2026 12:07:42 -0500
Subject: [PATCH 1/5] ibmvfc: add basic FPIN support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-ibmvfc-fpin-support-v1-1-52b06c464e03@linux.ibm.com>
References: <20260408-ibmvfc-fpin-support-v1-0-52b06c464e03@linux.ibm.com>
In-Reply-To: <20260408-ibmvfc-fpin-support-v1-0-52b06c464e03@linux.ibm.com>
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
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775668068; l=14243;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=Dl00hOQbbC4RypcktadD3eAH088sQG3T5G/LZ4uD1gw=;
 b=S1I7+xP1l1nWPy8gVi7/26B6OD+IWNadA8id5ws1319dCjiZT/Kmu3TGxtwI0QBYCt9KZkQ21
 OFjT7iP4e8ICz9YQuvAuYXSO1YalYbbeNTcdWGwHcHJdhW2np9nuBdK
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Add FPIN event descriptor
- Add congestion cleared status
- Add code to handle basic FPIN async event
- Add KUnit tests
---
 drivers/scsi/Kconfig                 |  10 ++
 drivers/scsi/ibmvscsi/Makefile       |   1 +
 drivers/scsi/ibmvscsi/ibmvfc.c       | 189 ++++++++++++++++++++++++++++++++++-
 drivers/scsi/ibmvscsi/ibmvfc.h       |   9 ++
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c |  95 ++++++++++++++++++
 5 files changed, 302 insertions(+), 2 deletions(-)

diff --git a/drivers/scsi/Kconfig b/drivers/scsi/Kconfig
index f811ce473c2a..9a4b18cde834 100644
--- a/drivers/scsi/Kconfig
+++ b/drivers/scsi/Kconfig
@@ -761,6 +761,16 @@ config SCSI_IBMVFC
 	  To compile this driver as a module, choose M here: the
 	  module will be called ibmvfc.
 
+config SCSI_IBMVFC_KUNIT_TEST
+	tristate "KUnit tests for the IBM POWER Virtual FC Client" if !KUNIT_ALL_TESTS
+	depends on SCSI_IBMVFC && KUNIT
+	default KUNIT_ALL_TESTS
+	help
+	  Compile IBM POWER Virtual FC client KUnit tests.
+
+	  To compile this driver as a module, choose M here: the
+	  module will be called ibmvfc_kunit.
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
index 3dd2adda195e..3ac376ba2c62 100644
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
@@ -3185,17 +3189,166 @@ static const char *ibmvfc_get_link_state(enum ibmvfc_ae_link_state state)
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
+ * @fpin_status: status value
+ * @wwpn: attached wwpn
+ *
+ * Allocate a struct fc_els_fpin containing a descriptor and populate
+ * based on data from *ibmvfc_fpin.
+ *
+ * Return:
+ * NULL     - unable to allocate structure
+ * non-NULL - pointer to populated struct fc_els_fpin
+ */
+static struct fc_els_fpin *
+ibmvfc_common_fpin_to_desc(u8 fpin_status, __be64 wwpn, __be16 modifier,
+			   __be32 period, __be32 threshold, __be32 event_count)
+{
+	struct fc_fn_peer_congn_desc *pdesc;
+	struct fc_fn_congn_desc *cdesc;
+	struct fc_fn_li_desc *ldesc;
+	struct fc_els_fpin *fpin;
+	size_t size;
+
+	size = ibmvfc_fpin_size_helper(fpin_status);
+	if (size == 0)
+		return NULL;
+
+	fpin = kzalloc(size, GFP_KERNEL);
+	if (fpin == NULL)
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
+		if (fpin_status == IBMVFC_AE_FPIN_CONGESTION_CLEARED)
+			cdesc->event_type = cpu_to_be16(FPIN_CONGN_CLEAR);
+		else
+			cdesc->event_type = cpu_to_be16(FPIN_CONGN_DEVICE_SPEC);
+		cdesc->event_modifier = modifier;
+		cdesc->event_period = period;
+		cdesc->severity = FPIN_CONGN_SEVERITY_WARNING;
+		break;
+	case IBMVFC_AE_FPIN_PORT_CONGESTED:
+	case IBMVFC_AE_FPIN_PORT_CLEARED:
+		fpin->desc_len = cpu_to_be32(sizeof(struct fc_fn_peer_congn_desc));
+		pdesc = (struct fc_fn_peer_congn_desc *)fpin->fpin_desc;
+		pdesc->desc_tag = cpu_to_be32(ELS_DTAG_PEER_CONGEST);
+		pdesc->desc_len = cpu_to_be32(FC_TLV_DESC_LENGTH_FROM_SZ(*pdesc));
+		if (fpin_status == IBMVFC_AE_FPIN_PORT_CLEARED)
+			pdesc->event_type = cpu_to_be16(FPIN_CONGN_CLEAR);
+		else
+			pdesc->event_type = cpu_to_be16(FPIN_CONGN_DEVICE_SPEC);
+		pdesc->event_modifier = modifier;
+		pdesc->event_period = period;
+		pdesc->detecting_wwpn = cpu_to_be64(0);
+		pdesc->attached_wwpn = wwpn;
+		pdesc->pname_count = cpu_to_be32(1);
+		pdesc->pname_list[0] = wwpn;
+		break;
+	case IBMVFC_AE_FPIN_PORT_DEGRADED:
+		fpin->desc_len = cpu_to_be32(sizeof(struct fc_fn_li_desc));
+		ldesc = (struct fc_fn_li_desc *)fpin->fpin_desc;
+		ldesc->desc_tag = cpu_to_be32(ELS_DTAG_LNK_INTEGRITY);
+		ldesc->desc_len = cpu_to_be32(FC_TLV_DESC_LENGTH_FROM_SZ(*ldesc));
+		ldesc->event_type = cpu_to_be16(FPIN_LI_UNKNOWN);
+		ldesc->event_modifier = modifier;
+		ldesc->event_threshold = threshold;
+		ldesc->event_count = event_count;
+		ldesc->detecting_wwpn = cpu_to_be64(0);
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
+/*XXX*/ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq)
+{
+	return ibmvfc_common_fpin_to_desc(crq->fpin_status, crq->wwpn,
+					  cpu_to_be16(0),
+					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_PERIOD),
+					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD),
+					  cpu_to_be32(1));
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
 	struct ibmvfc_target *tgt;
+	struct fc_els_fpin *fpin;
 
 	ibmvfc_log(vhost, desc->log_level, "%s event received. scsi_id: %llx, wwpn: %llx,"
 		   " node_name: %llx%s\n", desc->desc, be64_to_cpu(crq->scsi_id),
@@ -3269,11 +3422,37 @@ static void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 	case IBMVFC_AE_HALT:
 		ibmvfc_link_down(vhost, IBMVFC_HALTED);
 		break;
+	case IBMVFC_AE_FPIN:
+		if (!crq->scsi_id && !crq->wwpn && !crq->node_name)
+			break;
+		list_for_each_entry(tgt, &vhost->targets, queue) {
+			if (crq->scsi_id && cpu_to_be64(tgt->scsi_id) != crq->scsi_id)
+				continue;
+			if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
+				continue;
+			if (crq->node_name && cpu_to_be64(tgt->ids.node_name) != crq->node_name)
+				continue;
+			if (!tgt->rport)
+				continue;
+			fpin = ibmvfc_basic_fpin_to_desc(crq);
+			if (fpin) {
+				fc_host_fpin_rcv(tgt->vhost->host,
+						 sizeof(*fpin) +
+						       be32_to_cpu(fpin->desc_len),
+						 (char *)fpin, 0);
+				kfree(fpin);
+			} else
+				dev_err(vhost->dev,
+					"FPIN event %u received, unable to process\n",
+					crq->fpin_status);
+		}
+		break;
 	default:
 		dev_err(vhost->dev, "Unknown async event received: %lld\n", crq->event);
 		break;
 	}
 }
+EXPORT_SYMBOL_IF_KUNIT(ibmvfc_handle_async);
 
 /**
  * ibmvfc_handle_crq - Handles and frees received events in the CRQ
@@ -6603,5 +6782,11 @@ static void __exit ibmvfc_module_exit(void)
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
index c73ed2314ad0..29932284a4c9 100644
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
@@ -953,4 +957,9 @@ struct ibmvfc_host {
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
index 000000000000..1c238896049f
--- /dev/null
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -0,0 +1,95 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+#include <kunit/test.h>
+#include <kunit/visibility.h>
+#include <scsi/scsi_device.h>
+#include <scsi/scsi_transport_fc.h>
+#include <linux/list.h>
+#include "ibmvfc.h"
+
+MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
+
+/**
+ * ibmvfc_handle_fpin_event_test - unit test for IBMVFC_AE_FPIN parts of
+ * ibmvfc_handle_async
+ * @test: pointer to kunit structure
+ *
+ * Tests
+ * - error returns from ibmvfc_handle_async
+ * - statistics updates
+ *
+ * Return: void
+ */
+static void ibmvfc_handle_fpin_event_test(struct kunit *test)
+{
+	u64 *stats[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1] = { NULL };
+	u64 post[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	u64 pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
+	enum ibmvfc_ae_fpin_status fs;
+	struct ibmvfc_async_crq crq;
+	struct ibmvfc_target *tgt;
+	struct ibmvfc_host *vhost;
+	struct list_head *queue;
+	struct list_head *headp;
+
+
+	headp = ibmvfc_get_headp();
+	KUNIT_ASSERT_NOT_NULL(test, headp);
+	queue = headp->next;
+	KUNIT_ASSERT_PTR_NE(test, queue, headp);
+	vhost = container_of(queue, struct ibmvfc_host, queue);
+
+	KUNIT_EXPECT_GE(test, vhost->num_targets, 1);
+	tgt = list_first_entry(&vhost->targets, struct ibmvfc_target, queue);
+	KUNIT_EXPECT_NOT_NULL(test, tgt->rport);
+
+	stats[IBMVFC_AE_FPIN_LINK_CONGESTED] = &tgt->rport->fpin_stats.cn;
+	stats[IBMVFC_AE_FPIN_PORT_CONGESTED] = &tgt->rport->fpin_stats.cn;
+	stats[IBMVFC_AE_FPIN_PORT_CLEARED] = &tgt->rport->fpin_stats.cn_clear;
+	stats[IBMVFC_AE_FPIN_CONGESTION_CLEARED] = &tgt->rport->fpin_stats.cn_clear;
+	stats[IBMVFC_AE_FPIN_PORT_DEGRADED] = &tgt->rport->fpin_stats.li;
+
+	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
+		crq.valid = 0x80;
+		crq.link_state = IBMVFC_AE_LS_LINK_UP;
+		crq.fpin_status = fs;
+		crq.event = cpu_to_be64(IBMVFC_AE_FPIN);
+		crq.scsi_id = cpu_to_be64(tgt->scsi_id);
+		crq.wwpn = cpu_to_be64(tgt->wwpn);
+		crq.node_name = cpu_to_be64(tgt->ids.node_name);
+		pre[fs] = *stats[fs];
+		ibmvfc_handle_async(&crq, vhost);
+		post[fs] = *stats[fs];
+		KUNIT_EXPECT_EQ(test, post[fs], pre[fs]+1);
+	}
+
+	/* bad path */
+	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++)
+		pre[fs] = *stats[fs];
+	crq.valid = 0x80;
+	crq.link_state = IBMVFC_AE_LS_LINK_UP;
+	crq.fpin_status = 0; /* bad value */
+	crq.event = cpu_to_be64(IBMVFC_AE_FPIN);
+	crq.scsi_id = cpu_to_be64(tgt->scsi_id);
+	crq.wwpn = cpu_to_be64(tgt->wwpn);
+	crq.node_name = cpu_to_be64(tgt->ids.node_name);
+	ibmvfc_handle_async(&crq, vhost);
+	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
+		post[fs] = *stats[fs];
+		KUNIT_EXPECT_EQ(test, pre[fs], post[fs]);
+	}
+}
+
+static struct kunit_case ibmvfc_fpin_test_cases[] = {
+	KUNIT_CASE(ibmvfc_handle_fpin_event_test),
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
2.53.0

