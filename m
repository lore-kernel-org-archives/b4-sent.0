From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Fri, 10 Jul 2026 14:16:42 -0500
Subject: [PATCH v4 2/8] ibmvfc: Add NOOP command support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-ibmvfc-fpin-support-v4-2-ef031ac19520@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783711016; l=4233;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=5KXW4HiPzhI1ypiHMLbjy5Mv9KevT3p+ueI1qaFVPf4=;
 b=YUG4wqho5z8jkmX/DnPcnCNZuTF+R9Cv0kCY2Wj5Uc0N+NZ1y4XOJ7c7s5TWzfCNjflkJzccb
 q1P5nxU3U8GB3hDbMcoCQmyPADAspGvab3gBSbfoBat+n5gZ5X5BoE1
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for VFC_NOOP messages from VIOS to enable keep-alive
functionality between the client and server.

Define the VFC_NOOP CRQ format and add handling in both the main CRQ
handler (ibmvfc_handle_crq) and sub-CRQ handler (ibmvfc_handle_scrq).
Log unexpected NOOP messages if received before VIOS advertises support
during NPIV login.

Set the IBMVFC_CAN_USE_NOOP_CMD capability bit during NPIV login to
inform VIOS that the client can handle NOOP commands.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc.c | 22 ++++++++++++++++++++--
 drivers/scsi/ibmvscsi/ibmvfc.h | 23 +++++++++++++----------
 2 files changed, 33 insertions(+), 12 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc.c b/drivers/scsi/ibmvscsi/ibmvfc.c
index d3fd1d3437c6..a7e3b7ee0683 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc.c
@@ -1512,7 +1512,9 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 		login_info->flags |= cpu_to_be16(IBMVFC_CLIENT_MIGRATED);
 
 	login_info->max_cmds = cpu_to_be32(max_cmds);
-	login_info->capabilities = cpu_to_be64(IBMVFC_CAN_MIGRATE | IBMVFC_CAN_SEND_VF_WWPN);
+	login_info->capabilities =
+		cpu_to_be64(IBMVFC_CAN_MIGRATE | IBMVFC_CAN_SEND_VF_WWPN |
+			    IBMVFC_CAN_USE_NOOP_CMD);
 
 	if (vhost->mq_enabled || vhost->using_channels)
 		login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_USE_CHANNELS);
@@ -3569,6 +3571,14 @@ static void ibmvfc_handle_crq(struct ibmvfc_crq *crq, struct ibmvfc_host *vhost,
 	if (crq->format == IBMVFC_ASYNC_EVENT)
 		return;
 
+	if (crq->format == IBMVFC_VFC_NOOP) {
+		if (vhost->state == IBMVFC_ACTIVE &&
+		    !ibmvfc_check_caps(vhost, IBMVFC_SUPPORT_NOOP_CMD))
+			dev_err_ratelimited(vhost->dev,
+					    "Received unexpected NOOP command from partner\n");
+		return;
+	}
+
 	/* The only kind of payload CRQs we should get are responses to
 	 * things we send. Make sure this response is to something we
 	 * actually sent
@@ -4095,7 +4105,15 @@ static void ibmvfc_handle_scrq(struct ibmvfc_crq *crq, struct ibmvfc_host *vhost
 	case IBMVFC_CRQ_XPORT_EVENT:
 		return;
 	default:
-		dev_err(vhost->dev, "Got and invalid message type 0x%02x\n", crq->valid);
+		dev_err(vhost->dev, "Got an invalid message type 0x%02x\n", crq->valid);
+		return;
+	}
+
+	if (crq->format == IBMVFC_VFC_NOOP)
+		return;
+
+	if (unlikely(!evt)) {
+		dev_err(vhost->dev, "Received null event\n");
 		return;
 	}
 
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index f69e0605a78d..526632cb7237 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -175,11 +175,12 @@ struct ibmvfc_npiv_login {
 #define IBMVFC_FLUSH_ON_HALT		0x02
 	__be32 max_cmds;
 	__be64 capabilities;
-#define IBMVFC_CAN_MIGRATE		0x01
-#define IBMVFC_CAN_USE_CHANNELS		0x02
-#define IBMVFC_CAN_HANDLE_FPIN		0x04
-#define IBMVFC_CAN_USE_MAD_VERSION	0x08
-#define IBMVFC_CAN_SEND_VF_WWPN		0x10
+#define IBMVFC_CAN_MIGRATE		0x001
+#define IBMVFC_CAN_USE_CHANNELS		0x002
+#define IBMVFC_CAN_HANDLE_FPIN		0x004
+#define IBMVFC_CAN_USE_MAD_VERSION	0x008
+#define IBMVFC_CAN_SEND_VF_WWPN		0x010
+#define IBMVFC_CAN_USE_NOOP_CMD		0x200
 	__be64 node_name;
 	struct srp_direct_buf async;
 	u8 partition_name[IBMVFC_MAX_NAME];
@@ -221,11 +222,12 @@ struct ibmvfc_npiv_login_resp {
 #define IBMVFC_NATIVE_FC		0x01
 	__be32 reserved;
 	__be64 capabilities;
-#define IBMVFC_CAN_FLUSH_ON_HALT	0x08
-#define IBMVFC_CAN_SUPPRESS_ABTS	0x10
-#define IBMVFC_MAD_VERSION_CAP		0x20
-#define IBMVFC_HANDLE_VF_WWPN		0x40
-#define IBMVFC_CAN_SUPPORT_CHANNELS	0x80
+#define IBMVFC_CAN_FLUSH_ON_HALT	0x0008
+#define IBMVFC_CAN_SUPPRESS_ABTS	0x0010
+#define IBMVFC_MAD_VERSION_CAP		0x0020
+#define IBMVFC_HANDLE_VF_WWPN		0x0040
+#define IBMVFC_CAN_SUPPORT_CHANNELS	0x0080
+#define IBMVFC_SUPPORT_NOOP_CMD		0x1000
 	__be32 max_cmds;
 	__be32 scsi_id_sz;
 	__be64 max_dma_len;
@@ -621,6 +623,7 @@ struct ibmvfc_trace_entry {
 enum ibmvfc_crq_formats {
 	IBMVFC_CMD_FORMAT		= 0x01,
 	IBMVFC_ASYNC_EVENT	= 0x02,
+	IBMVFC_VFC_NOOP		= 0x03,
 	IBMVFC_MAD_FORMAT		= 0x04,
 };
 

-- 
2.55.0

