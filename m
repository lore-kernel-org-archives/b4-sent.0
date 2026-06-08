From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 08 Jun 2026 13:30:18 -0500
Subject: [PATCH v2 3/7] ibmvfc: make ibmvfc login to fabric
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-ibmvfc-fpin-support-v2-3-d41f540fba5c@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780943423; l=5878;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=0mN8HnDhMnJNVlV5l4t+QmjOxydG3CBgcYKoM9KofFM=;
 b=WQIoqOr+bBgsgDM+aspnPNcu/zbwbGDbr9SgBohAsOGyHA0lSuvZCxeBY2dkx9mD96sZNWm+P
 vAqakpklsv3CjhTRQ8hHofw/jy0TMtstA+SmvCnNAmt6S+DP9oYX0Yr
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for fabric login in order to support the asynchronous
event queue with its own interrupt as required by NPIV specification
to support the asynchronous sub-queue and interrupt in order to
support full and extended FPIN messages.
---
 drivers/scsi/ibmvscsi/ibmvfc.c | 94 ++++++++++++++++++++++++++++++++++++++++--
 drivers/scsi/ibmvscsi/ibmvfc.h | 16 +++++++
 2 files changed, 106 insertions(+), 4 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc.c b/drivers/scsi/ibmvscsi/ibmvfc.c
index 88386d7c9106..a18861808325 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc.c
@@ -5244,6 +5244,86 @@ static void ibmvfc_discover_targets(struct ibmvfc_host *vhost)
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
+		ibmvfc_hard_reset_host(vhost);
+		return;
+	}
+
+	ibmvfc_init_event(evt, ibmvfc_fabric_login_done, IBMVFC_MAD_FORMAT);
+	mad = &evt->iu.fabric_login;
+	memset(mad, 0, sizeof(*mad));
+	if (vhost->scsi_scrqs.protocol == IBMVFC_PROTO_SCSI)
+		mad->common.opcode = cpu_to_be32(IBMVFC_FABRIC_LOGIN);
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
@@ -5290,8 +5370,12 @@ static void ibmvfc_channel_setup_done(struct ibmvfc_event *evt)
 		return;
 	}
 
-	ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_QUERY);
-	wake_up(&vhost->work_wait_q);
+	if (ibmvfc_check_caps(vhost, IBMVFC_SUPPORT_SCSI)) {
+		ibmvfc_fabric_login(vhost);
+	} else {
+		ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_QUERY);
+		wake_up(&vhost->work_wait_q);
+	}
 }
 
 static void ibmvfc_channel_setup(struct ibmvfc_host *vhost)
@@ -5482,9 +5566,11 @@ static void ibmvfc_npiv_login_done(struct ibmvfc_event *evt)
 	vhost->host->can_queue = be32_to_cpu(rsp->max_cmds) - IBMVFC_NUM_INTERNAL_REQ;
 	vhost->host->max_sectors = npiv_max_sectors;
 
-	if (ibmvfc_check_caps(vhost, IBMVFC_CAN_SUPPORT_CHANNELS) && vhost->do_enquiry) {
+	if (ibmvfc_check_caps(vhost, IBMVFC_CAN_SUPPORT_CHANNELS) && vhost->do_enquiry)
 		ibmvfc_channel_enquiry(vhost);
-	} else {
+	else if (ibmvfc_check_caps(vhost, IBMVFC_SUPPORT_SCSI))
+		ibmvfc_fabric_login(vhost);
+	else {
 		vhost->do_enquiry = 0;
 		ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_QUERY);
 		wake_up(&vhost->work_wait_q);
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index dd26248cac3e..c996b36d335d 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -138,6 +138,7 @@ enum ibmvfc_mad_types {
 	IBMVFC_CHANNEL_ENQUIRY	= 0x1000,
 	IBMVFC_CHANNEL_SETUP	= 0x2000,
 	IBMVFC_CONNECTION_INFO	= 0x4000,
+	IBMVFC_FABRIC_LOGIN	= 0x8000,
 };
 
 struct ibmvfc_mad_common {
@@ -227,6 +228,7 @@ struct ibmvfc_npiv_login_resp {
 #define IBMVFC_MAD_VERSION_CAP		0x20
 #define IBMVFC_HANDLE_VF_WWPN		0x40
 #define IBMVFC_CAN_SUPPORT_CHANNELS	0x80
+#define IBMVFC_SUPPORT_SCSI		0x200
 #define IBMVFC_SUPPORT_NOOP_CMD		0x1000
 	__be32 max_cmds;
 	__be32 scsi_id_sz;
@@ -590,6 +592,19 @@ struct ibmvfc_connection_info {
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
@@ -715,6 +730,7 @@ union ibmvfc_iu {
 	struct ibmvfc_channel_enquiry channel_enquiry;
 	struct ibmvfc_channel_setup_mad channel_setup;
 	struct ibmvfc_connection_info connection_info;
+	struct ibmvfc_fabric_login fabric_login;
 } __packed __aligned(8);
 
 enum ibmvfc_target_action {

-- 
2.54.0

