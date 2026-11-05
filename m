From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Thu, 05 Nov 2026 11:23:06 -0600
Subject: [PATCH v18 13/13] scsi: ibmvfc: handle extended FPIN events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ibmvfc-fpin-support-v18-13-d683b74736a3@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793899377; l=19007;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=KhBoNAppMpOr84z2zcn0/TQmcYQnnwJeHQUFyb7qseQ=;
 b=vyIrFVK9mjZhtw2X8eCCuTrXEBljyWM4sgIztpa7jtijEfDxROgHKIKTSZ6XkZIY/ixdcsg9B
 xNCdl05UpMNC6blYKleuVDKTCfCfmGBNp9FmrAOLhKQRVv1uZBgbLC1
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement support for extended FPIN messages received via the
asynchronous sub-queue, completing full FPIN functionality.

Extended FPIN messages provide more detailed information about fabric
events compared to basic FPIN messages, including specific event types,
modifiers, thresholds, event counts, and severity.

Add ibmvfc_ext_fpin_to_desc() to convert extended FPIN messages from
async sub-queue format to fc_els_fpin structures with complete descriptor
information. Thread detecting_wwpn (fc_host_port_name()) through
ibmvfc_ext_fpin_to_desc() to ibmvfc_common_fpin_to_desc() consistent
with ibmvfc_basic_fpin_to_desc() and ibmvfc_full_fpin_to_desc(). Update
ibmvfc_process_async_work() and ibmvfc_handle_async() to zero node_name
and dispatch to ibmvfc_ext_fpin_to_desc() when the
IBMVFC_ASYNC_IS_FPIN_EXT flag is set.

Extend ibmvfc_common_fpin_to_desc() with a severity parameter so that
extended FPIN events can propagate the severity value from the VIOS when
IBMVFC_FPIN_SEVERITY_VALID is set, rather than always defaulting to
FPIN_CONGN_SEVERITY_WARNING. Severity is only carried by the congestion
descriptor used for IBMVFC_AE_FPIN_LINK_CONGESTED and
IBMVFC_AE_FPIN_CONGESTION_CLEARED; the peer congestion and link
integrity descriptors have no severity field, so a severity supplied
for the other FPIN statuses is ignored.

Set the IBMVFC_CAN_HANDLE_FPIN_EXT capability bit (0x800) during login
to inform the VIOS that the client can process extended FPIN messages.
Add the IBMVFC_CAN_CLS_CRQ_PRE_DMP capability bit (0x400) definition
for the intervening protocol-defined capability. Also add the
IBMVFC_SUPPORT_FPIN_EXT response capability bit definition used to gate
extended FPIN processing.

In ibmvfc_process_async_work(), use goto to bypass the generic "FPIN
event received, unable to process" error message when a more specific
diagnostic has already been emitted for invalid or unsupported extended
FPIN events.

Add a KUnit test, ibmvfc_extended_fpin_test(), that sends extended FPIN
events through ibmvfc_process_async_work() for each FPIN status with
the event types valid for that status, setting only
IBMVFC_FPIN_EVENT_TYPE_VALID, and checks that the matching fc_host or
rport FPIN statistic is incremented. The test is skipped if no ibmvfc
device, online target rport, or IBMVFC_SUPPORT_FPIN_EXT capability is
available. It does not exercise the modifier, threshold, severity or
event count fields, nor the error paths for a missing
IBMVFC_FPIN_EVENT_TYPE_VALID flag or an unadvertised
IBMVFC_SUPPORT_FPIN_EXT capability.

Signed-off-by: Tyrel Datwyler <tyreld@linux.ibm.com>
Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c  |  92 +++++++++++++++++++---
 drivers/scsi/ibmvscsi/ibmvfc.h       |  31 ++++++++
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 148 +++++++++++++++++++++++++++++++++++
 3 files changed, 262 insertions(+), 9 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 6e1ecf6891c7..bc65c4d9cb7e 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -1609,6 +1609,7 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 		login_info->capabilities |= cpu_to_be64(IBMVFC_USE_ASYNC_SUBQ);
 		login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_HANDLE_FPIN);
 		login_info->capabilities |= cpu_to_be64(IBMVFC_YES_SCSI);
+		login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_HANDLE_FPIN_EXT);
 		if (vhost->nvme_enabled) {
 			login_info->capabilities |= cpu_to_be64(IBMVFC_YES_NVMEOF);
 			login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_USE_WWPN_ALL);
@@ -3344,6 +3345,11 @@ static size_t ibmvfc_fpin_size_helper(u8 fpin_status)
  *			IBMVFC_AE_FPIN_PORT_DEGRADED only
  * @event_count:	link integrity event count (big-endian); used for
  *			IBMVFC_AE_FPIN_PORT_DEGRADED only
+ * @severity:		congestion severity value; stored in the congestion
+ *			descriptor for IBMVFC_AE_FPIN_LINK_CONGESTED and
+ *			IBMVFC_AE_FPIN_CONGESTION_CLEARED only. Ignored for
+ *			other statuses because their descriptors have no
+ *			severity field
  *
  * Return:
  * NULL     - unable to allocate structure or unrecognised fpin_status
@@ -3352,7 +3358,7 @@ static size_t ibmvfc_fpin_size_helper(u8 fpin_status)
 static struct fc_els_fpin *
 ibmvfc_common_fpin_to_desc(u8 fpin_status, __be64 detecting_wwpn, __be64 wwpn,
 			   __be16 type, __be16 modifier,
-			   __be32 threshold, __be32 event_count)
+			   __be32 threshold, __be32 event_count, __u8 severity)
 {
 	struct fc_fn_peer_congn_desc *pdesc;
 	struct fc_fn_congn_desc *cdesc;
@@ -3380,7 +3386,7 @@ ibmvfc_common_fpin_to_desc(u8 fpin_status, __be64 detecting_wwpn, __be64 wwpn,
 		cdesc->event_type = type;
 		cdesc->event_modifier = modifier;
 		cdesc->event_period = cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_PERIOD);
-		cdesc->severity = FPIN_CONGN_SEVERITY_WARNING;
+		cdesc->severity = severity;
 		break;
 	case IBMVFC_AE_FPIN_PORT_CONGESTED:
 	case IBMVFC_AE_FPIN_PORT_CLEARED:
@@ -3444,6 +3450,7 @@ static struct fc_els_fpin *
 ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, __be64 detecting_wwpn,
 			  u64 wwpn)
 {
+	__u8 severity = FPIN_CONGN_SEVERITY_WARNING;
 	__be16 type;
 
 	switch (crq->fpin_status) {
@@ -3454,6 +3461,7 @@ ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, __be64 detecting_wwpn,
 	case IBMVFC_AE_FPIN_PORT_CLEARED:
 	case IBMVFC_AE_FPIN_CONGESTION_CLEARED:
 		type = cpu_to_be16(FPIN_CONGN_CLEAR);
+		severity = 0;
 		break;
 	case IBMVFC_AE_FPIN_PORT_DEGRADED:
 		type = cpu_to_be16(FPIN_LI_UNKNOWN);
@@ -3465,7 +3473,7 @@ ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq, __be64 detecting_wwpn,
 	return ibmvfc_common_fpin_to_desc(crq->fpin_status, detecting_wwpn,
 					  cpu_to_be64(wwpn), type, cpu_to_be16(0),
 					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD),
-					  cpu_to_be32(1));
+					  cpu_to_be32(1), severity);
 }
 
 /**
@@ -3486,6 +3494,7 @@ static struct fc_els_fpin *
 ibmvfc_full_fpin_to_desc(struct ibmvfc_async_sub_crq *ibmvfc_fpin,
 			 __be64 detecting_wwpn, u64 wwpn)
 {
+	__u8 severity = FPIN_CONGN_SEVERITY_WARNING;
 	__be16 type;
 
 	switch (ibmvfc_fpin->fpin_status) {
@@ -3496,6 +3505,7 @@ ibmvfc_full_fpin_to_desc(struct ibmvfc_async_sub_crq *ibmvfc_fpin,
 	case IBMVFC_AE_FPIN_PORT_CLEARED:
 	case IBMVFC_AE_FPIN_CONGESTION_CLEARED:
 		type = cpu_to_be16(FPIN_CONGN_CLEAR);
+		severity = 0;
 		break;
 	case IBMVFC_AE_FPIN_PORT_DEGRADED:
 		type = cpu_to_be16(FPIN_LI_UNKNOWN);
@@ -3507,7 +3517,48 @@ ibmvfc_full_fpin_to_desc(struct ibmvfc_async_sub_crq *ibmvfc_fpin,
 	return ibmvfc_common_fpin_to_desc(ibmvfc_fpin->fpin_status, detecting_wwpn,
 					  cpu_to_be64(wwpn), type, cpu_to_be16(0),
 					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD),
-					  cpu_to_be32(1));
+					  cpu_to_be32(1), severity);
+}
+
+/**
+ * ibmvfc_ext_fpin_to_desc(): allocate and populate a struct fc_els_fpin struct
+ * containing a descriptor.
+ * @ibmvfc_fpin:	Pointer to async subq FPIN data
+ * @detecting_wwpn:	WWPN of the local port that detected the event (big-endian)
+ * @wwpn:		attached port WWPN (host-endian)
+ *
+ * Allocate a struct fc_els_fpin containing a descriptor and populate
+ * based on data from *ibmvfc_fpin. The caller must have verified that
+ * IBMVFC_FPIN_EVENT_TYPE_VALID is set in the FPIN data flags.
+ *
+ * Return:
+ * NULL     - unable to allocate structure
+ * non-NULL - pointer to populated struct fc_els_fpin
+ */
+static struct fc_els_fpin *
+ibmvfc_ext_fpin_to_desc(struct ibmvfc_async_subq_fpin *ibmvfc_fpin,
+			__be64 detecting_wwpn, u64 wwpn)
+{
+	u8 flags = ibmvfc_fpin->fpin_data.flags;
+	__be32 threshold = cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD);
+	__be16 modifier = 0;
+	__be32 count = cpu_to_be32(1);
+	__be16 type = ibmvfc_fpin->fpin_data.event_type;
+	__u8 severity = FPIN_CONGN_SEVERITY_WARNING;
+
+	if (flags & IBMVFC_FPIN_MODIFIER_VALID)
+		modifier = ibmvfc_fpin->fpin_data.event_type_modifier;
+	if (flags & IBMVFC_FPIN_THRESHOLD_VALID)
+		threshold = ibmvfc_fpin->fpin_data.event_threshold;
+	if (flags & IBMVFC_FPIN_EVENT_COUNT_VALID)
+		count = ibmvfc_fpin->fpin_data.event_data.event_count;
+	if (flags & IBMVFC_FPIN_SEVERITY_VALID)
+		severity = ibmvfc_fpin->fpin_data.event_data.severity;
+
+	return ibmvfc_common_fpin_to_desc(ibmvfc_fpin->fpin_status, detecting_wwpn,
+					  cpu_to_be64(wwpn), type,
+					  modifier, threshold, count,
+					  severity);
 }
 
 /**
@@ -3544,6 +3595,11 @@ static struct ibmvfc_target *ibmvfc_find_target(struct list_head *target_list,
 	return NULL;
 }
 
+static_assert(sizeof(struct ibmvfc_async_subq_fpin) ==
+	      sizeof(struct ibmvfc_async_sub_crq));
+static_assert(offsetof(struct ibmvfc_async_subq_fpin, fpin_data) ==
+	      offsetof(struct ibmvfc_async_sub_crq, nport_id));
+
 /**
  * ibmvfc_process_async_work - Process IBMVFC_AE_FPIN async CRQ from work queue
  * @work: pointer to work_struct
@@ -3551,6 +3607,7 @@ static struct ibmvfc_target *ibmvfc_find_target(struct list_head *target_list,
 VISIBLE_IF_KUNIT void ibmvfc_process_async_work(struct work_struct *work)
 {
 	struct ibmvfc_async_sub_crq *subq = NULL;
+	struct ibmvfc_async_subq_fpin *sqfpin;
 	struct ibmvfc_async_work *aw;
 	struct ibmvfc_async_crq *crq = NULL;
 	struct ibmvfc_target *tgt;
@@ -3624,14 +3681,30 @@ VISIBLE_IF_KUNIT void ibmvfc_process_async_work(struct work_struct *work)
 		goto free;
 	}
 
-	if (crq)
+	if (crq) {
 		fpin = ibmvfc_basic_fpin_to_desc(crq,
 				cpu_to_be64(fc_host_port_name(vhost->host)),
 				tgt->wwpn);
-	else
-		fpin = ibmvfc_full_fpin_to_desc(subq,
-				cpu_to_be64(fc_host_port_name(vhost->host)),
-				tgt->wwpn);
+	} else {
+		sqfpin = (struct ibmvfc_async_subq_fpin *)subq;
+		if ((subq->flags & IBMVFC_ASYNC_IS_FPIN_EXT) == 0) {
+			fpin = ibmvfc_full_fpin_to_desc(subq,
+					cpu_to_be64(fc_host_port_name(vhost->host)),
+					tgt->wwpn);
+		} else if (!(sqfpin->fpin_data.flags & IBMVFC_FPIN_EVENT_TYPE_VALID)) {
+			dev_err_ratelimited(vhost->dev,
+					    "Invalid extended FPIN event received\n");
+			goto skip_generic_error;
+		} else if (!ibmvfc_check_caps(vhost, IBMVFC_SUPPORT_FPIN_EXT)) {
+			dev_err_ratelimited(vhost->dev,
+					    "Unexpected extended FPIN event received\n");
+			goto skip_generic_error;
+		} else {
+			fpin = ibmvfc_ext_fpin_to_desc(sqfpin,
+					cpu_to_be64(fc_host_port_name(vhost->host)),
+					tgt->wwpn);
+		}
+	}
 
 send_fpin:
 	if (fpin) {
@@ -3642,6 +3715,7 @@ VISIBLE_IF_KUNIT void ibmvfc_process_async_work(struct work_struct *work)
 	} else
 		dev_err_ratelimited(vhost->dev, "FPIN event received, unable to process\n");
 
+ skip_generic_error:
 	if (tgt)
 		kref_put(&tgt->kref, ibmvfc_release_tgt);
  free:
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index f77966c85b0e..6c9ff5a93b9e 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -210,6 +210,8 @@ struct ibmvfc_npiv_login {
 #define IBMVFC_CAN_USE_WWPN_ALL		0x080
 #define IBMVFC_USE_ASYNC_SUBQ		0x100
 #define IBMVFC_CAN_USE_NOOP_CMD		0x200
+#define IBMVFC_CAN_CLS_CRQ_PRE_DMP	0x400
+#define IBMVFC_CAN_HANDLE_FPIN_EXT	0x800
 	__be64 node_name;
 	struct srp_direct_buf async;
 	u8 partition_name[IBMVFC_MAX_NAME];
@@ -261,6 +263,7 @@ struct ibmvfc_npiv_login_resp {
 #define IBMVFC_SUPPORT_WWPN_ALL		0x0400
 #define IBMVFC_ASYNC_SUBQ		0x0800
 #define IBMVFC_SUPPORT_NOOP_CMD		0x1000
+#define IBMVFC_SUPPORT_FPIN_EXT		0x2000
 	__be32 max_cmds;
 	__be32 scsi_id_sz;
 	__be64 max_dma_len;
@@ -786,6 +789,34 @@ struct ibmvfc_async_sub_crq {
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
+	u8 valid;
+	u8 flags;
+	u8 link_state;
+	u8 fpin_status;
+	__be16 event;
+	__be16 pad;
+	__be64 wwpn;
+	struct ibmvfc_fpin_data fpin_data;
+} __packed __aligned(8);
+
 enum ibmvfc_async_crq_type {
 	IBMVFC_ASYNC_CRQ_MAIN = 0,
 	IBMVFC_ASYNC_CRQ_SUB,
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index 71fbe779b0f2..954e5b451990 100644
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
@@ -419,9 +420,156 @@ static void ibmvfc_full_fpin_test(struct kunit *test)
 	scsi_host_put(vhost->host);
 }
 
+#define IBMVFC_TEST_FPIN_EXT_TARGET(fs, ev, stat) do {				\
+	struct ibmvfc_async_crq_event ae = { .type = IBMVFC_ASYNC_CRQ_SUB };	\
+	memset(&crq, 0, sizeof(crq));						\
+	crq.valid = 0x80;							\
+	crq.flags = IBMVFC_ASYNC_IS_FPIN_EXT;					\
+	crq.link_state = IBMVFC_AE_LS_LINK_UP;					\
+	crq.fpin_status = (fs);							\
+	crq.event = cpu_to_be16(IBMVFC_AE_FPIN);				\
+	crq.wwpn = cpu_to_be64(tgt->wwpn);					\
+	crq.fpin_data.flags = IBMVFC_FPIN_EVENT_TYPE_VALID;			\
+	crq.fpin_data.event_type = cpu_to_be16((ev));				\
+	ae.subq = *(struct ibmvfc_async_sub_crq *)&crq;				\
+	pre = READ_ONCE(rport->fpin_stats.stat);				\
+	ibmvfc_run_async_work(wq, vhost, &ae);					\
+	post = READ_ONCE(rport->fpin_stats.stat);				\
+	KUNIT_EXPECT_GT(test, post, pre);					\
+} while (0)
+
+#define IBMVFC_TEST_FPIN_EXT_HOST(fs, ev, stat) do {				\
+	struct ibmvfc_async_crq_event ae = { .type = IBMVFC_ASYNC_CRQ_SUB };	\
+	memset(&crq, 0, sizeof(crq));						\
+	crq.valid = 0x80;							\
+	crq.flags = IBMVFC_ASYNC_IS_FPIN_EXT;					\
+	crq.link_state = IBMVFC_AE_LS_LINK_UP;					\
+	crq.fpin_status = (fs);							\
+	crq.event = cpu_to_be16(IBMVFC_AE_FPIN);				\
+	crq.wwpn = cpu_to_be64(tgt->wwpn);					\
+	crq.fpin_data.flags = IBMVFC_FPIN_EVENT_TYPE_VALID;			\
+	crq.fpin_data.event_type = cpu_to_be16((ev));				\
+	ae.subq = *(struct ibmvfc_async_sub_crq *)&crq;				\
+	pre = READ_ONCE(fc_host->fpin_stats.stat);				\
+	ibmvfc_run_async_work(wq, vhost, &ae);					\
+	post = READ_ONCE(fc_host->fpin_stats.stat);				\
+	KUNIT_EXPECT_GT(test, post, pre);					\
+} while (0)
+
+/**
+ * ibmvfc_extended_fpin_test - unit test for extended FPIN events
+ * @test: pointer to kunit structure
+ *
+ * Return: void
+ */
+static void ibmvfc_extended_fpin_test(struct kunit *test)
+{
+	enum ibmvfc_ae_fpin_status fs;
+	struct ibmvfc_async_subq_fpin crq;
+	struct workqueue_struct *wq;
+	struct ibmvfc_target *tgt;
+	struct ibmvfc_host *vhost;
+	struct fc_host_attrs *fc_host;
+	struct fc_rport *rport;
+	unsigned long flags;
+	u64 pre, post;
+
+	vhost = ibmvfc_get_first_vhost();
+	if (!vhost)
+		kunit_skip(test, "No ibmvfc devices available");
+
+	if (!ibmvfc_check_caps(vhost, IBMVFC_SUPPORT_FPIN_EXT)) {
+		scsi_host_put(vhost->host);
+		kunit_skip(test, "Extended FPIN not supported");
+	}
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
+	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
+		switch (fs) {
+		case IBMVFC_AE_FPIN_LINK_CONGESTED:
+			IBMVFC_TEST_FPIN_EXT_HOST(fs, FPIN_CONGN_CLEAR, cn_clear);
+			IBMVFC_TEST_FPIN_EXT_HOST(fs, FPIN_CONGN_LOST_CREDIT, cn_lost_credit);
+			IBMVFC_TEST_FPIN_EXT_HOST(fs, FPIN_CONGN_CREDIT_STALL, cn_credit_stall);
+			IBMVFC_TEST_FPIN_EXT_HOST(fs, FPIN_CONGN_OVERSUBSCRIPTION,
+						  cn_oversubscription);
+			IBMVFC_TEST_FPIN_EXT_HOST(fs, FPIN_CONGN_DEVICE_SPEC, cn_device_specific);
+			break;
+		case IBMVFC_AE_FPIN_PORT_CONGESTED:
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_CONGN_CLEAR, cn_clear);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_CONGN_LOST_CREDIT, cn_lost_credit);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_CONGN_CREDIT_STALL, cn_credit_stall);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_CONGN_OVERSUBSCRIPTION,
+						    cn_oversubscription);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_CONGN_DEVICE_SPEC, cn_device_specific);
+			break;
+		case IBMVFC_AE_FPIN_PORT_CLEARED:
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_CONGN_CLEAR, cn_clear);
+			break;
+		case IBMVFC_AE_FPIN_CONGESTION_CLEARED:
+			IBMVFC_TEST_FPIN_EXT_HOST(fs, FPIN_CONGN_CLEAR, cn_clear);
+			break;
+		case IBMVFC_AE_FPIN_PORT_DEGRADED:
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_LI_UNKNOWN, li_failure_unknown);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_LI_LINK_FAILURE,
+						    li_link_failure_count);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_LI_LOSS_OF_SYNC,
+						    li_loss_of_sync_count);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_LI_LOSS_OF_SIG,
+						    li_loss_of_signals_count);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_LI_PRIM_SEQ_ERR,
+						    li_prim_seq_err_count);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_LI_INVALID_TX_WD,
+						    li_invalid_tx_word_count);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_LI_INVALID_CRC, li_invalid_crc_count);
+			IBMVFC_TEST_FPIN_EXT_TARGET(fs, FPIN_LI_DEVICE_SPEC, li_device_specific);
+			break;
+		}
+	}
+
+	destroy_workqueue(wq);
+	put_device(&rport->dev);
+	kref_put(&tgt->kref, ibmvfc_release_tgt);
+	scsi_host_put(vhost->host);
+}
+
 static struct kunit_case ibmvfc_fpin_test_cases[] = {
 	KUNIT_CASE(ibmvfc_async_fpin_test),
 	KUNIT_CASE(ibmvfc_full_fpin_test),
+	KUNIT_CASE(ibmvfc_extended_fpin_test),
 	{},
 };
 

-- 
2.56.0

