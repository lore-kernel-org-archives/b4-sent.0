From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 17 Aug 2026 15:28:00 -0500
Subject: [PATCH v6 7/8] scsi: ibmvfc: register and use asynchronous sub CRQ
 for events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-ibmvfc-fpin-support-v6-7-62a2d525e70d@linux.ibm.com>
References: <20260817-ibmvfc-fpin-support-v6-0-62a2d525e70d@linux.ibm.com>
In-Reply-To: <20260817-ibmvfc-fpin-support-v6-0-62a2d525e70d@linux.ibm.com>
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786998478; l=4793;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=j22BIxygRjLa4p+iYGPOotTe0EA7iaqbwa3Kd3tyrQ0=;
 b=bmM1vQX/hlqZescK8GyIzDVs13rycnVQ8XYyh2XPfyATmUqG9Yqb5T4roaPkoGnU19d30Y1gj
 daUXzc6XyV9BhsxITyxziYnDvV/NpasYpGwbNwYJP8ho59+tARxt7Ye
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wire the async sub-CRQ into the sub-CRQ lifecycle so it is allocated,
registered, and freed alongside the SCSI channel queues.

In ibmvfc_init_sub_crqs(), allocate the async sub-CRQ queue buffer via
ibmvfc_alloc_queue() before allocating the SCSI channels. Register it
with the VIOS by calling ibmvfc_register_channel() with index -1 (the
negative-index sentinel introduced in the previous commit). Either
failure disables multi-queue and aborts init.

In ibmvfc_release_sub_crqs(), deregister and free the async sub-CRQ
before tearing down the SCSI channels.

In ibmvfc_channel_setup_done(), capture the async sub-CRQ handle
returned by the VIOS in the channel setup response and store it in
vhost->async_sub_crq.vios_cookie.

In ibmvfc_set_login_info(), advertise IBMVFC_USE_ASYNC_SUBQ,
IBMVFC_CAN_HANDLE_FPIN, and IBMVFC_YES_SCSI capabilities whenever
multi-queue channels are enabled. IBMVFC_YES_SCSI was previously only
set for NVMe-enabled configurations; move it to the common multi-queue
path so it is always advertised when channels are in use.
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 32 +++++++++++++++++++++++++++++---
 1 file changed, 29 insertions(+), 3 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index da34b572518a..686142761863 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -1568,9 +1568,11 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 
 	if (vhost->mq_enabled || vhost->using_channels) {
 		login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_USE_CHANNELS);
+		login_info->capabilities |= cpu_to_be64(IBMVFC_USE_ASYNC_SUBQ);
+		login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_HANDLE_FPIN);
+		login_info->capabilities |= cpu_to_be64(IBMVFC_YES_SCSI);
 		if (vhost->nvme_enabled) {
 			login_info->capabilities |= cpu_to_be64(IBMVFC_YES_NVMEOF);
-			login_info->capabilities |= cpu_to_be64(IBMVFC_YES_SCSI);
 			login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_USE_WWPN_ALL);
 		}
 	}
@@ -5749,6 +5751,7 @@ static void ibmvfc_channel_setup_done(struct ibmvfc_event *evt)
 		for (i = 0; i < nvme->active_queues; i++)
 			nvme->scrqs[i].vios_cookie =
 				be64_to_cpu(setup->channel_handles[scsi->active_queues + i]);
+		vhost->async_sub_crq.vios_cookie = be64_to_cpu(setup->async_sub_crq_handle);
 
 		ibmvfc_dbg(vhost, "Using %u SCSI channels\n",
 			   scsi->active_queues);
@@ -5808,6 +5811,7 @@ static void ibmvfc_channel_setup(struct ibmvfc_host *vhost)
 		for (i = 0; i < nvme_channels; i++)
 			setup_buf->channel_handles[scsi_channels + i] =
 				cpu_to_be64(nvme->scrqs[i].cookie);
+		setup_buf->async_sub_crq_handle = cpu_to_be64(vhost->async_sub_crq.cookie);
 	}
 
 	ibmvfc_init_event(evt, ibmvfc_channel_setup_done, IBMVFC_MAD_FORMAT);
@@ -6879,7 +6883,9 @@ static void ibmvfc_reg_sub_crqs(struct ibmvfc_host *vhost,
 	for (i = 0; i < channels->max_queues; i++) {
 		if (ibmvfc_register_channel(vhost, channels, i)) {
 			for (j = i; j > 0; j--)
-				ibmvfc_deregister_channel(vhost, channels, j - 1);
+				ibmvfc_deregister_channel(
+					vhost, channels, j - 1);
+
 			vhost->do_enquiry = 0;
 			return;
 		}
@@ -6934,10 +6940,27 @@ static int ibmvfc_alloc_channels(struct ibmvfc_host *vhost,
 
 static void ibmvfc_init_sub_crqs(struct ibmvfc_host *vhost)
 {
+	int rc = 0;
+
 	ENTER;
 	if (!vhost->mq_enabled)
 		return;
 
+	rc = ibmvfc_alloc_queue(vhost, &vhost->async_sub_crq, IBMVFC_SUB_CRQ_FMT);
+	if (rc) {
+		vhost->do_enquiry = 0;
+		vhost->mq_enabled = 0;
+		return;
+	}
+
+	/* register async_sub_crq channel */
+	if (ibmvfc_register_channel(vhost, &vhost->scsi_scrqs, -1)) {
+		ibmvfc_free_queue(vhost, &vhost->async_sub_crq);
+		vhost->do_enquiry = 0;
+		vhost->mq_enabled = 0;
+		return;
+	}
+
 	if (ibmvfc_alloc_channels(vhost, &vhost->scsi_scrqs)) {
 		vhost->do_enquiry = 0;
 		vhost->mq_enabled = 0;
@@ -6980,6 +7003,9 @@ static void ibmvfc_release_sub_crqs(struct ibmvfc_host *vhost)
 	if (!vhost->scsi_scrqs.scrqs)
 		return;
 
+	ibmvfc_deregister_channel(vhost, &vhost->scsi_scrqs, -1);
+	ibmvfc_free_queue(vhost, &vhost->async_sub_crq);
+
 	ibmvfc_dereg_sub_crqs(vhost, &vhost->scsi_scrqs);
 	ibmvfc_release_channels(vhost, &vhost->scsi_scrqs);
 
@@ -7258,7 +7284,7 @@ static int ibmvfc_probe(struct vio_dev *vdev, const struct vio_device_id *id)
 	INIT_WORK(&vhost->rport_add_work_q, ibmvfc_rport_add_thread);
 	mutex_init(&vhost->passthru_mutex);
 
-	vhost->fpin_workq = alloc_workqueue("%s-fpin-workq-%u", 0, 0,
+	vhost->fpin_workq = alloc_workqueue("%s-fpin-workq-%u", WQ_PERCPU, 0,
 						 IBMVFC_NAME, shost->host_no);
 	if (vhost->fpin_workq == NULL)
 		goto free_scsi_host;

-- 
2.55.0

