From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 08 Jun 2026 13:30:22 -0500
Subject: [PATCH v2 7/7] ibmvfc: handle extended FPIN events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-ibmvfc-fpin-support-v2-7-d41f540fba5c@linux.ibm.com>
References: <20260608-ibmvfc-fpin-support-v2-0-d41f540fba5c@linux.ibm.com>
In-Reply-To: <20260608-ibmvfc-fpin-support-v2-0-d41f540fba5c@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780943423; l=11383;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=2RqC+rU2A9gSh64NyYLbxM+SEGYa8ZsXYS3BOiaFMSo=;
 b=w4G1hFagIYmgT4hvi/1N8dfCxJbcCPexRMzW1ytE6gZV07LmyfYEYRN6E8vlFBmd2MfIhgkw6
 lXomtzfWx9zBOwEpBJrUgouN3sYFIsdc0FzJFRAGFuTGLvR/PQ+5yrW
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add extended FPIN handling to ibmvfc driver. Tell VIOS ibmvfc can
handle extended FPIN messages, convert any received to struct fc_els
descriptors, and call fc_host_fpin_rcv to update statistics and send
netlink multicast messages to listeners such as multipathd.
---
 drivers/scsi/ibmvscsi/ibmvfc.c       |  41 +++++++++++-
 drivers/scsi/ibmvscsi/ibmvfc.h       |  31 +++++++++
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 122 +++++++++++++++++++++++++++++++++--
 3 files changed, 186 insertions(+), 8 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc.c b/drivers/scsi/ibmvscsi/ibmvfc.c
index a2252cd2f44b..b034a894e3ec 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc.c
@@ -1515,7 +1515,8 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 	login_info->capabilities =
 		cpu_to_be64(IBMVFC_CAN_MIGRATE | IBMVFC_CAN_SEND_VF_WWPN |
 			    IBMVFC_CAN_USE_NOOP_CMD | IBMVFC_YES_SCSI |
-			    IBMVFC_USE_ASYNC_SUBQ | IBMVFC_CAN_HANDLE_FPIN);
+			    IBMVFC_USE_ASYNC_SUBQ | IBMVFC_CAN_HANDLE_FPIN |
+			    IBMVFC_CAN_HANDLE_FPIN_EXT);
 
 	if (vhost->mq_enabled || vhost->using_channels)
 		login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_USE_CHANNELS);
@@ -3254,7 +3255,7 @@ ibmvfc_common_fpin_to_desc(u8 fpin_status, __be64 wwpn, __be16 type, __be16 modi
 	if (size == 0)
 		return NULL;
 
-	fpin = kzalloc(size, GFP_ATOMIC);
+	fpin = kzalloc(size, GFP_KERNEL);
 	if (fpin == NULL)
 		return NULL;
 
@@ -3371,6 +3372,28 @@ ibmvfc_full_fpin_to_desc(struct ibmvfc_async_subq *ibmvfc_fpin)
 					  cpu_to_be32(1));
 }
 
+/**
+ * ibmvfc_ext_fpin_to_desc(): allocate and populate a struct fc_els_fpin struct
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
+ibmvfc_ext_fpin_to_desc(struct ibmvfc_async_subq_fpin *ibmvfc_fpin)
+{
+	return ibmvfc_common_fpin_to_desc(ibmvfc_fpin->fpin_status, ibmvfc_fpin->wwpn,
+					  ibmvfc_fpin->fpin_data.event_type,
+					  ibmvfc_fpin->fpin_data.event_type_modifier,
+					  ibmvfc_fpin->fpin_data.event_threshold,
+					  ibmvfc_fpin->fpin_data.event_data.event_count);
+}
+
 /**
  * ibmvfc_process_async_work - Process IBMVFC_AE_FPIN async CRQ from work queue
  * @work: pointer to work_struct
@@ -3425,7 +3448,19 @@ static void ibmvfc_process_async_work(struct work_struct *work)
 			fpin = ibmvfc_basic_fpin_to_desc(crq, tgt->wwpn);
 		} else {
 			sqfpin = (struct ibmvfc_async_subq_fpin *)subq;
-			fpin = ibmvfc_full_fpin_to_desc(subq);
+			if ((subq->flags & IBMVFC_ASYNC_IS_FPIN_EXT) == 0) {
+				fpin = ibmvfc_full_fpin_to_desc(subq);
+			} else if (!(sqfpin->fpin_data.flags & IBMVFC_FPIN_EVENT_TYPE_VALID)) {
+				dev_err_ratelimited(vhost->dev,
+						    "Invalid extended FPIN event received");
+				fpin = NULL;
+			} else if (!ibmvfc_check_caps(vhost, IBMVFC_SUPPORT_FPIN_EXT)) {
+				dev_err_ratelimited(vhost->dev,
+						    "Unexpected extended FPIN event received");
+				fpin = NULL;
+			} else {
+				fpin = ibmvfc_ext_fpin_to_desc(sqfpin);
+			}
 		}
 		if (fpin) {
 			fc_host_fpin_rcv(tgt->vhost->host,
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index 2e02acde0178..5c4cf4be4b67 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -184,6 +184,7 @@ struct ibmvfc_npiv_login {
 #define IBMVFC_YES_SCSI			0x40
 #define IBMVFC_USE_ASYNC_SUBQ		0x100
 #define IBMVFC_CAN_USE_NOOP_CMD		0x200
+#define IBMVFC_CAN_HANDLE_FPIN_EXT	0x800
 	__be64 node_name;
 	struct srp_direct_buf async;
 	u8 partition_name[IBMVFC_MAX_NAME];
@@ -233,6 +234,7 @@ struct ibmvfc_npiv_login_resp {
 #define IBMVFC_SUPPORT_SCSI		0x200
 #define IBMVFC_SUPPORT_ASYNC_SUBQ	0x800
 #define IBMVFC_SUPPORT_NOOP_CMD		0x1000
+#define IBMVFC_SUPPORT_FPIN_EXT		0x2000
 	__be32 max_cmds;
 	__be32 scsi_id_sz;
 	__be64 max_dma_len;
@@ -722,6 +724,7 @@ struct ibmvfc_async_work {
 struct ibmvfc_async_subq {
 	volatile u8 valid;
 #define IBMVFC_ASYNC_ID_IS_ASSOC_ID	0x01
+#define IBMVFC_ASYNC_IS_FPIN_EXT	0x02
 #define IBMVFC_FC_EEH			0x04
 #define IBMVFC_FC_FW_UPDATE		0x08
 #define IBMVFC_FC_FW_DUMP		0x10
@@ -738,6 +741,34 @@ struct ibmvfc_async_subq {
 	} id;
 } __packed __aligned(8);
 
+struct ibmvfc_fpin_data {
+#define IBMVFC_FPIN_EVENT_TYPE_VALID	0x01
+#define IBMVFC_FPIN_MODIFIER_VALID	0x02
+#define IBMVFC_FPIN_THRESHOLD_VALID	0x04
+#define IBMVFC_FPIN_SEVERITY_VALID	0x08
+#define IBMVFC_FPIN_EVENT_COUNT_VALID	0x10
+	u8 flags;
+	u8 reserved[3];
+	__be16 event_type;
+	__be16 event_type_modifier;
+	__be32 event_threshold;
+	union {
+		u8 severity;
+		__be32 event_count;
+	} event_data;
+} __packed __aligned(8);
+
+struct ibmvfc_async_subq_fpin {
+	volatile u8 valid;
+	u8 flags;
+	u8 link_state;
+	u8 fpin_status;
+	__be16 event;
+	__be16 pad;
+	volatile __be64 wwpn;
+	struct ibmvfc_fpin_data fpin_data;
+} __packed __aligned(8);
+
 union ibmvfc_iu {
 	struct ibmvfc_mad_common mad_common;
 	struct ibmvfc_npiv_login_mad npiv_login;
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index c8799eaf4927..2e6cbaaebdba 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -3,6 +3,7 @@
 #include <kunit/visibility.h>
 #include <scsi/scsi_device.h>
 #include <scsi/scsi_transport_fc.h>
+#include <scsi/fc/fc_els.h>
 #include <linux/list.h>
 #include <linux/delay.h>
 #include "ibmvfc.h"
@@ -58,10 +59,10 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 		crq[fs].wwpn = cpu_to_be64(tgt->wwpn);
 		crq[fs].node_name = cpu_to_be64(tgt->ids.node_name);
 		ibmvfc_handle_async(&crq[fs], vhost);
+		while (crq[fs].valid)
+			msleep(1U);
 	}
 
-	msleep(500U);
-
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
 	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
 	post[IBMVFC_AE_FPIN_PORT_CLEARED] = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
@@ -94,8 +95,8 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 	crq[0].wwpn = cpu_to_be64(tgt->wwpn);
 	crq[0].node_name = cpu_to_be64(tgt->ids.node_name);
 	ibmvfc_handle_async(&crq[0], vhost);
-
-	msleep(500U);
+	while (crq[0].valid)
+		msleep(1U);
 
 	post[IBMVFC_AE_FPIN_LINK_CONGESTED] = READ_ONCE(fc_host->fpin_stats.cn_device_specific);
 	post[IBMVFC_AE_FPIN_PORT_CONGESTED] = READ_ONCE(tgt->rport->fpin_stats.cn);
@@ -115,8 +116,119 @@ static void ibmvfc_async_fpin_test(struct kunit *test)
 			post[IBMVFC_AE_FPIN_CONGESTION_CLEARED]);
 }
 
+#define IBMVFC_TEST_FPIN_EXT(fs, ev, stat, crq) {		\
+	crq.valid = 0x80;					\
+	crq.flags = IBMVFC_ASYNC_IS_FPIN_EXT;			\
+	crq.link_state = IBMVFC_AE_LS_LINK_UP;			\
+	crq.fpin_status = (fs);					\
+	crq.event = cpu_to_be16(IBMVFC_AE_FPIN);		\
+	crq.wwpn = cpu_to_be64(tgt->wwpn);			\
+	crq.fpin_data.flags = IBMVFC_FPIN_EVENT_TYPE_VALID;	\
+	crq.fpin_data.event_type = cpu_to_be16((ev));		\
+	pre = READ_ONCE(tgt->rport->fpin_stats.stat);		\
+	ibmvfc_handle_asyncq((struct ibmvfc_crq *)&crq, vhost);	\
+	while (crq.valid)					\
+		msleep(1U);					\
+	post = READ_ONCE(tgt->rport->fpin_stats.stat);		\
+}
+
+/**
+ * ibmvfc_extended_fpin_test - unit test for extended FPIN events
+ * @test: pointer to kunit structure
+ *
+ * Tests
+ *
+ * Return: void
+ */
+static void ibmvfc_extended_fpin_test(struct kunit *test)
+{
+	enum ibmvfc_ae_fpin_status fs;
+	struct ibmvfc_async_subq_fpin crq[IBMVFC_AE_FPIN_CONGESTION_CLEARED+1];
+	struct ibmvfc_async_subq_fpin
+		crqcn[IBMVFC_AE_FPIN_PORT_CONGESTED][FPIN_CONGN_DEVICE_SPEC+1];
+	struct ibmvfc_async_subq_fpin crqportdg[FPIN_LI_DEVICE_SPEC+1];
+	struct ibmvfc_target *tgt;
+	struct ibmvfc_host *vhost;
+	struct list_head *headp;
+	LIST_HEAD(evt_doneq);
+	u64 pre, post;
+
+	headp = ibmvfc_get_headp();
+	KUNIT_ASSERT_FALSE_MSG(test, list_empty(headp), "No ibmvfc devices available\n");
+	vhost = list_first_entry(headp, struct ibmvfc_host, queue);
+	KUNIT_ASSERT_GE_MSG(test, vhost->num_targets, 1, "No targets");
+
+	tgt = list_first_entry(&vhost->targets, struct ibmvfc_target, queue);
+	KUNIT_ASSERT_NOT_NULL(test, tgt->rport);
+
+	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
+		switch (fs) {
+		case IBMVFC_AE_FPIN_PORT_CLEARED:
+		case IBMVFC_AE_FPIN_CONGESTION_CLEARED:
+			crq[fs].valid = 0x80;
+			crq[fs].flags = IBMVFC_ASYNC_IS_FPIN_EXT;
+			crq[fs].link_state = IBMVFC_AE_LS_LINK_UP;
+			crq[fs].fpin_status = fs;
+			crq[fs].event = cpu_to_be16(IBMVFC_AE_FPIN);
+			crq[fs].wwpn = cpu_to_be64(tgt->wwpn);
+			crq[fs].fpin_data.flags = IBMVFC_FPIN_EVENT_TYPE_VALID;
+			crq[fs].fpin_data.event_type = cpu_to_be16(FPIN_CONGN_CLEAR);
+			pre = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
+			ibmvfc_handle_asyncq((struct ibmvfc_crq *)&crq[fs], vhost);
+			while (crq[fs].valid)
+				msleep(1U);
+			post = READ_ONCE(tgt->rport->fpin_stats.cn_clear);
+			break;
+		case IBMVFC_AE_FPIN_LINK_CONGESTED:
+		case IBMVFC_AE_FPIN_PORT_CONGESTED:
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_CLEAR, cn_clear,
+					     crqcn[fs-1][FPIN_CONGN_CLEAR]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_LOST_CREDIT,
+					     cn_lost_credit,
+					     crqcn[fs-1][FPIN_CONGN_LOST_CREDIT]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_CREDIT_STALL,
+					     cn_credit_stall,
+					     crqcn[fs-1][FPIN_CONGN_CREDIT_STALL]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_OVERSUBSCRIPTION,
+					     cn_oversubscription,
+					     crqcn[fs-1][FPIN_CONGN_OVERSUBSCRIPTION]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_CONGN_DEVICE_SPEC,
+					     cn_device_specific,
+					     crqcn[fs-1][FPIN_CONGN_DEVICE_SPEC]);
+			break;
+		case IBMVFC_AE_FPIN_PORT_DEGRADED:
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_UNKNOWN,
+					     li_failure_unknown,
+					     crqportdg[FPIN_LI_UNKNOWN]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_LINK_FAILURE,
+					     li_link_failure_count,
+					     crqportdg[FPIN_LI_LINK_FAILURE]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_LOSS_OF_SYNC,
+					     li_loss_of_sync_count,
+					     crqportdg[FPIN_LI_LOSS_OF_SYNC]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_LOSS_OF_SIG,
+					     li_loss_of_signals_count,
+					     crqportdg[FPIN_LI_LOSS_OF_SIG]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_PRIM_SEQ_ERR,
+					     li_prim_seq_err_count,
+					     crqportdg[FPIN_LI_PRIM_SEQ_ERR]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_INVALID_TX_WD,
+					     li_invalid_tx_word_count,
+					     crqportdg[FPIN_LI_INVALID_TX_WD]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_INVALID_CRC,
+					     li_invalid_crc_count,
+					     crqportdg[FPIN_LI_INVALID_CRC]);
+			IBMVFC_TEST_FPIN_EXT(fs, FPIN_LI_DEVICE_SPEC,
+					     li_device_specific,
+					     crqportdg[FPIN_LI_DEVICE_SPEC]);
+			break;
+		}
+	}
+}
+
 static struct kunit_case ibmvfc_fpin_test_cases[] = {
-	KUNIT_CASE_SLOW(ibmvfc_async_fpin_test),
+	KUNIT_CASE(ibmvfc_async_fpin_test),
+	KUNIT_CASE(ibmvfc_extended_fpin_test),
 	{},
 };
 

-- 
2.54.0

