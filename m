From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Wed, 08 Apr 2026 12:07:44 -0500
Subject: [PATCH 3/5] ibmvfc: make ibmvfc login to fabric
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-ibmvfc-fpin-support-v1-3-52b06c464e03@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775668068; l=6364;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=Cbt/rfPik4XB8M92YhjaqQXiYCRxYwBJ6PtbbYpBhuo=;
 b=PXjs5+PHKlzRHjXbLUSryG+lUh5EBrAAbuiDita0EbTjLRL/t6LJedUzoIHU9xDcXXxT1naLW
 LWJZM0Iqw8qA+RDwk8neWFD38h7cMPjLzGzXIoNZtyBn8j6A0+EavPp
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make ibmvfc login to fabric when NPIV login returns SUPPORT_SCSI or
SUPPORT_NVMEOF capabilities.
---
 drivers/scsi/ibmvscsi/ibmvfc.c | 100 ++++++++++++++++++++++++++++++++++++++---
 drivers/scsi/ibmvscsi/ibmvfc.h |  20 +++++++++
 2 files changed, 115 insertions(+), 5 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc.c b/drivers/scsi/ibmvscsi/ibmvfc.c
index 808301fa452d..803fc3caa14d 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc.c
@@ -5205,6 +5205,89 @@ static void ibmvfc_discover_targets(struct ibmvfc_host *vhost)
 		ibmvfc_link_down(vhost, IBMVFC_LINK_DEAD);
 }
 
+static void ibmvfc_fabric_login_done(struct ibmvfc_event *evt)
+{
+	struct ibmvfc_fabric_login *rsp = &evt->xfer_iu->fabric_login;
+	u32 mad_status = be16_to_cpu(rsp->common.status);
+	struct ibmvfc_host *vhost = evt->vhost;
+	int level = IBMVFC_DEFAULT_LOG_LEVEL;
+
+	ENTER;
+
+	switch (mad_status) {
+	case IBMVFC_MAD_SUCCESS:
+		vhost->logged_in = 1;
+		vhost->fabric_capabilities = rsp->capabilities;
+		fc_host_port_id(vhost->host) = be64_to_cpu(rsp->nport_id);
+		ibmvfc_free_event(evt);
+		break;
+
+	case IBMVFC_MAD_FAILED:
+		if (ibmvfc_retry_cmd(be16_to_cpu(rsp->status), be16_to_cpu(rsp->error)))
+			level += ibmvfc_retry_host_init(vhost);
+		else
+			ibmvfc_link_down(vhost, IBMVFC_LINK_DEAD);
+		ibmvfc_log(vhost, level, "Fabric Login failed: %s (%x:%x)\n",
+			   ibmvfc_get_cmd_error(be16_to_cpu(rsp->status), be16_to_cpu(rsp->error)),
+						be16_to_cpu(rsp->status), be16_to_cpu(rsp->error));
+		ibmvfc_free_event(evt);
+		LEAVE;
+		return;
+
+	case IBMVFC_MAD_CRQ_ERROR:
+		ibmvfc_retry_host_init(vhost);
+		fallthrough;
+
+	case IBMVFC_MAD_DRIVER_FAILED:
+		ibmvfc_free_event(evt);
+		LEAVE;
+		return;
+
+	default:
+		dev_err(vhost->dev, "Invalid fabric Login response: 0x%x\n", mad_status);
+		ibmvfc_link_down(vhost, IBMVFC_LINK_DEAD);
+		ibmvfc_free_event(evt);
+		LEAVE;
+		return;
+	}
+
+	ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_QUERY);
+	wake_up(&vhost->work_wait_q);
+
+	LEAVE;
+}
+
+static void ibmvfc_fabric_login(struct ibmvfc_host *vhost)
+{
+	struct ibmvfc_fabric_login *mad;
+	struct ibmvfc_event *evt = ibmvfc_get_reserved_event(&vhost->crq);
+	int level = IBMVFC_DEFAULT_LOG_LEVEL;
+
+	if (!evt) {
+		ibmvfc_log(vhost, level, "Fabric Login failed: no available events\n");
+		return;
+	}
+
+	ibmvfc_init_event(evt, ibmvfc_fabric_login_done, IBMVFC_MAD_FORMAT);
+	mad = &evt->iu.fabric_login;
+	memset(mad, 0, sizeof(*mad));
+	if (vhost->scsi_scrqs.protocol == IBMVFC_PROTO_SCSI)
+		mad->common.opcode = cpu_to_be32(IBMVFC_FABRIC_LOGIN);
+	else if (vhost->scsi_scrqs.protocol == IBMVFC_PROTO_NVME)
+		mad->common.opcode = cpu_to_be32(IBMVFC_NVMF_FABRIC_LOGIN);
+	else {
+		ibmvfc_log(vhost, level, "Fabric Login failed: unknown protocol\n");
+		return;
+	}
+	mad->common.version = cpu_to_be32(1);
+	mad->common.length = cpu_to_be16(sizeof(*mad));
+
+	ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_INIT_WAIT);
+
+	if (ibmvfc_send_event(evt, vhost, default_timeout))
+		ibmvfc_link_down(vhost, IBMVFC_LINK_DOWN);
+}
+
 static void ibmvfc_channel_setup_done(struct ibmvfc_event *evt)
 {
 	struct ibmvfc_host *vhost = evt->vhost;
@@ -5251,8 +5334,12 @@ static void ibmvfc_channel_setup_done(struct ibmvfc_event *evt)
 		return;
 	}
 
-	ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_QUERY);
-	wake_up(&vhost->work_wait_q);
+	if (ibmvfc_check_caps(vhost, (IBMVFC_SUPPORT_SCSI | IBMVFC_SUPPORT_NVMEOF))) {
+		ibmvfc_fabric_login(vhost);
+	} else {
+		ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_QUERY);
+		wake_up(&vhost->work_wait_q);
+	}
 }
 
 static void ibmvfc_channel_setup(struct ibmvfc_host *vhost)
@@ -5443,9 +5530,12 @@ static void ibmvfc_npiv_login_done(struct ibmvfc_event *evt)
 	vhost->host->can_queue = be32_to_cpu(rsp->max_cmds) - IBMVFC_NUM_INTERNAL_REQ;
 	vhost->host->max_sectors = npiv_max_sectors;
 
-	if (ibmvfc_check_caps(vhost, IBMVFC_CAN_SUPPORT_CHANNELS) && vhost->do_enquiry) {
-		ibmvfc_channel_enquiry(vhost);
-	} else {
+	if (ibmvfc_check_caps(vhost, IBMVFC_CAN_SUPPORT_CHANNELS)) {
+		if (vhost->do_enquiry)
+			ibmvfc_channel_enquiry(vhost);
+	} else if (ibmvfc_check_caps(vhost, (IBMVFC_SUPPORT_SCSI | IBMVFC_SUPPORT_NVMEOF)))
+		ibmvfc_fabric_login(vhost);
+	else {
 		vhost->do_enquiry = 0;
 		ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_QUERY);
 		wake_up(&vhost->work_wait_q);
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index cd0917f70c6d..4f680c5d9558 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -138,6 +138,8 @@ enum ibmvfc_mad_types {
 	IBMVFC_CHANNEL_ENQUIRY	= 0x1000,
 	IBMVFC_CHANNEL_SETUP	= 0x2000,
 	IBMVFC_CONNECTION_INFO	= 0x4000,
+	IBMVFC_FABRIC_LOGIN	= 0x8000,
+	IBMVFC_NVMF_FABRIC_LOGIN	= 0x8001,
 };
 
 struct ibmvfc_mad_common {
@@ -227,6 +229,8 @@ struct ibmvfc_npiv_login_resp {
 #define IBMVFC_MAD_VERSION_CAP		0x20
 #define IBMVFC_HANDLE_VF_WWPN		0x40
 #define IBMVFC_CAN_SUPPORT_CHANNELS	0x80
+#define IBMVFC_SUPPORT_NVMEOF		0x100
+#define IBMVFC_SUPPORT_SCSI		0x200
 #define IBMVFC_SUPPORT_NOOP_CMD		0x1000
 	__be32 max_cmds;
 	__be32 scsi_id_sz;
@@ -590,6 +594,19 @@ struct ibmvfc_connection_info {
 	__be64 reserved[16];
 } __packed __aligned(8);
 
+struct ibmvfc_fabric_login {
+	struct ibmvfc_mad_common common;
+	__be64 flags;
+#define IBMVFC_STRIP_MERGE	0x1
+#define IBMVFC_LINK_COMMANDS	0x2
+	__be64 capabilities;
+	__be64 nport_id;
+	__be16 status;
+	__be16 error;
+	__be32 pad;
+	__be64 reserved[16];
+} __packed __aligned(8);
+
 struct ibmvfc_trace_start_entry {
 	u32 xfer_len;
 } __packed;
@@ -709,6 +726,7 @@ union ibmvfc_iu {
 	struct ibmvfc_channel_enquiry channel_enquiry;
 	struct ibmvfc_channel_setup_mad channel_setup;
 	struct ibmvfc_connection_info connection_info;
+	struct ibmvfc_fabric_login fabric_login;
 } __packed __aligned(8);
 
 enum ibmvfc_target_action {
@@ -921,6 +939,8 @@ struct ibmvfc_host {
 	struct work_struct rport_add_work_q;
 	wait_queue_head_t init_wait_q;
 	wait_queue_head_t work_wait_q;
+	__be64 fabric_capabilities;
+	unsigned int login_cap_index;
 };
 
 #define DBG_CMD(CMD) do { if (ibmvfc_debug) CMD; } while (0)

-- 
2.53.0

