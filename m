From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 19 Oct 2026 17:15:55 -0500
Subject: [PATCH v15 10/11] scsi: ibmvfc: register and use asynchronous sub
 CRQ for events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-ibmvfc-fpin-support-v15-10-a858726e178a@linux.ibm.com>
References: <20261019-ibmvfc-fpin-support-v15-0-a858726e178a@linux.ibm.com>
In-Reply-To: <20261019-ibmvfc-fpin-support-v15-0-a858726e178a@linux.ibm.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792448148; l=12459;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=qvxpALcfzPOnlHpZd2xWVJEYCUaOcQ+Ez2c5y8IawwY=;
 b=3d3i3PU9dNsbiJ/AvfSC06riTfYKsOm5Ru3ITYsVMgOtF0MF8Ri8nyN+KQ39FhfC1hjtBKCpN
 TO0JHgSY4JrCCICJ0Qg1Ljz8dHhr8BVHCIcPFVbW9ND1SghjaLeb8Si
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wire the async sub-CRQ into the sub-CRQ lifecycle so it is allocated,
registered, and freed alongside the SCSI channel queues.

In ibmvfc_probe(), initialize vhost->async_scrqs with desired_queues=1,
max_queues=1, and protocol=IBMVFC_PROTO_ASYNC. Add
ibmvfc_release_channels() as a helper to free a channels array and its
queue buffers.

In ibmvfc_init_sub_crqs(), allocate the async sub-CRQ via
ibmvfc_alloc_channels() before allocating the SCSI channels. Register it
with the VIOS via ibmvfc_reg_sub_crqs(). Either failure disables
multi-queue and aborts init. In ibmvfc_reg_sub_crqs(), also clear
vhost->mq_enabled on registration failure to prevent a host state
machine stall: without this, mq_enabled remaining set causes
ibmvfc_npiv_login_done() to enter the multi-queue branch while
do_enquiry is 0, bypassing both
ibmvfc_channel_enquiry() and the fallback that would wake up the work
queue, leaving the host indefinitely in IBMVFC_HOST_ACTION_INIT_WAIT.

Both mq_enabled and do_enquiry are bitfields packed into the same word
as other state flags such as using_channels. Writes to these fields
from ibmvfc_reg_sub_crqs() and ibmvfc_init_sub_crqs() are performed
outside host_lock, while concurrent writers like
ibmvfc_channel_setup_done() hold host_lock when modifying other fields
in the same word. To prevent lost updates from concurrent
read-modify-write operations on the packed bitfield word, take
host_lock around all failure-path writes to mq_enabled, do_enquiry, and
nvme_enabled in ibmvfc_reg_sub_crqs() and ibmvfc_init_sub_crqs().

In ibmvfc_alloc_channels(), select IBMVFC_ASYNC_SUB_CRQ_FMT for async
protocol channels instead of IBMVFC_SUB_CRQ_FMT, so the queue is sized
for ibmvfc_async_sub_crq entries. Zero active_queues on allocation
failure to ensure the field is always consistent with scrqs.

In ibmvfc_release_sub_crqs(), ibmvfc_reenable_crq_queue(), and
ibmvfc_reset_crq(), deregister and re-register the async sub-CRQ
alongside the SCSI channel queues.

In ibmvfc_channel_setup_done(), compute async->active_queues from the
VIOS response: set it to 1 only when async->scrqs is non-NULL and the
response contains a non-zero async_sub_crq_handle, otherwise 0. Store
the handle in vhost->async_scrqs.scrqs[0].vios_cookie via the
active_queues loop. Clamp scsi->active_queues and nvme->active_queues
to their respective max_queues values before using them as loop bounds,
preventing out-of-bounds access to scrqs[] if the hypervisor returns a
larger value than was allocated. In ibmvfc_channel_setup(), guard the
access to async->scrqs[0].cookie behind a NULL check to prevent a
dereference when mq_enabled is 0 and async->scrqs was never allocated.

In ibmvfc_set_login_info(), advertise IBMVFC_USE_ASYNC_SUBQ,
IBMVFC_CAN_HANDLE_FPIN, and IBMVFC_YES_SCSI capabilities whenever
multi-queue channels are enabled. IBMVFC_YES_SCSI was previously only
set for NVMe-enabled configurations; move it to the common multi-queue
path so it is always advertised when channels are in use.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
Signed-off-by: Tyrel Datwyler <tyreld@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 108 ++++++++++++++++++++++++++----------
 1 file changed, 79 insertions(+), 29 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index 7e012281d368..0d603542fe34 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -964,6 +964,7 @@ static int ibmvfc_reenable_crq_queue(struct ibmvfc_host *vhost)
 	struct vio_dev *vdev = to_vio_dev(vhost->dev);
 	unsigned long flags;
 
+	ibmvfc_dereg_sub_crqs(vhost, &vhost->async_scrqs);
 	ibmvfc_dereg_sub_crqs(vhost, &vhost->scsi_scrqs);
 	ibmvfc_dereg_sub_crqs(vhost, &vhost->nvme_scrqs);
 
@@ -986,6 +987,7 @@ static int ibmvfc_reenable_crq_queue(struct ibmvfc_host *vhost)
 	spin_unlock(vhost->crq.q_lock);
 	spin_unlock_irqrestore(&vhost->host->host_lock, flags);
 
+	ibmvfc_reg_sub_crqs(vhost, &vhost->async_scrqs);
 	ibmvfc_reg_sub_crqs(vhost, &vhost->scsi_scrqs);
 	ibmvfc_reg_sub_crqs(vhost, &vhost->nvme_scrqs);
 
@@ -1006,6 +1008,7 @@ static int ibmvfc_reset_crq(struct ibmvfc_host *vhost)
 	struct vio_dev *vdev = to_vio_dev(vhost->dev);
 	struct ibmvfc_queue *crq = &vhost->crq;
 
+	ibmvfc_dereg_sub_crqs(vhost, &vhost->async_scrqs);
 	ibmvfc_dereg_sub_crqs(vhost, &vhost->scsi_scrqs);
 	ibmvfc_dereg_sub_crqs(vhost, &vhost->nvme_scrqs);
 
@@ -1042,6 +1045,7 @@ static int ibmvfc_reset_crq(struct ibmvfc_host *vhost)
 	spin_unlock(vhost->crq.q_lock);
 	spin_unlock_irqrestore(&vhost->host->host_lock, flags);
 
+	ibmvfc_reg_sub_crqs(vhost, &vhost->async_scrqs);
 	ibmvfc_reg_sub_crqs(vhost, &vhost->scsi_scrqs);
 	ibmvfc_reg_sub_crqs(vhost, &vhost->nvme_scrqs);
 
@@ -1584,9 +1588,11 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 
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
@@ -5802,6 +5808,7 @@ static void ibmvfc_channel_setup_done(struct ibmvfc_event *evt)
 {
 	struct ibmvfc_host *vhost = evt->vhost;
 	struct ibmvfc_channel_setup *setup = vhost->channel_setup_buf;
+	struct ibmvfc_channels *async = &vhost->async_scrqs;
 	struct ibmvfc_channels *scsi = &vhost->scsi_scrqs;
 	struct ibmvfc_channels *nvme = &vhost->nvme_scrqs;
 	u32 mad_status = be16_to_cpu(evt->xfer_iu->channel_setup.common.status);
@@ -5815,8 +5822,11 @@ static void ibmvfc_channel_setup_done(struct ibmvfc_event *evt)
 		ibmvfc_dbg(vhost, "Channel Setup succeeded\n");
 		flags = be32_to_cpu(setup->flags);
 		vhost->do_enquiry = 0;
-		scsi->active_queues = be32_to_cpu(setup->num_scsi_subq_channels);
-		nvme->active_queues = be32_to_cpu(setup->num_nvme_subq_channels);
+		scsi->active_queues = min(be32_to_cpu(setup->num_scsi_subq_channels),
+					  scsi->max_queues);
+		nvme->active_queues = min(be32_to_cpu(setup->num_nvme_subq_channels),
+					  nvme->max_queues);
+		async->active_queues = (async->scrqs && setup->async_sub_crq_handle) ? 1 : 0;
 
 		if (flags & IBMVFC_CHANNELS_CANCELED) {
 			ibmvfc_dbg(vhost, "Channels Canceled\n");
@@ -5832,6 +5842,8 @@ static void ibmvfc_channel_setup_done(struct ibmvfc_event *evt)
 		for (i = 0; i < nvme->active_queues; i++)
 			nvme->scrqs[i].vios_cookie =
 				be64_to_cpu(setup->channel_handles[scsi->active_queues + i]);
+		for (i = 0; i < async->active_queues; i++)
+			async->scrqs[i].vios_cookie = be64_to_cpu(setup->async_sub_crq_handle);
 
 		ibmvfc_dbg(vhost, "Using %u SCSI channels\n",
 			   scsi->active_queues);
@@ -5866,6 +5878,7 @@ static void ibmvfc_channel_setup(struct ibmvfc_host *vhost)
 	struct ibmvfc_event *evt = ibmvfc_get_reserved_event(&vhost->crq);
 	struct ibmvfc_channels *scsi = &vhost->scsi_scrqs;
 	struct ibmvfc_channels *nvme = &vhost->nvme_scrqs;
+	struct ibmvfc_channels *async = &vhost->async_scrqs;
 	unsigned int scsi_channels =
 		min(scsi->desired_queues, vhost->max_vios_scsi_channels);
 	unsigned int nvme_channels =
@@ -5891,6 +5904,8 @@ static void ibmvfc_channel_setup(struct ibmvfc_host *vhost)
 		for (i = 0; i < nvme_channels; i++)
 			setup_buf->channel_handles[scsi_channels + i] =
 				cpu_to_be64(nvme->scrqs[i].cookie);
+		if (async->scrqs)
+			setup_buf->async_sub_crq_handle = cpu_to_be64(async->scrqs[0].cookie);
 	}
 
 	ibmvfc_init_event(evt, ibmvfc_channel_setup_done, IBMVFC_MAD_FORMAT);
@@ -6738,6 +6753,9 @@ static int ibmvfc_alloc_queue(struct ibmvfc_host *vhost,
 		queue->evt_depth = scsi_qdepth;
 		queue->reserved_depth = IBMVFC_NUM_INTERNAL_SUBQ_REQ;
 		break;
+	case IBMVFC_ASYNC_SUB_CRQ_FMT:
+		fmt_size = sizeof(*queue->msgs.async_scrq);
+		break;
 	default:
 		dev_warn(dev, "Unknown command/response queue message format: %d\n", fmt);
 		return -EINVAL;
@@ -6977,6 +6995,7 @@ EXPORT_SYMBOL_IF_KUNIT(ibmvfc_deregister_channel);
 static void ibmvfc_reg_sub_crqs(struct ibmvfc_host *vhost,
 				struct ibmvfc_channels *channels)
 {
+	unsigned long flags;
 	int i, j;
 
 	ENTER;
@@ -6987,7 +7006,10 @@ static void ibmvfc_reg_sub_crqs(struct ibmvfc_host *vhost,
 		if (ibmvfc_register_channel(vhost, channels, i)) {
 			for (j = i; j > 0; j--)
 				ibmvfc_deregister_channel(vhost, channels, j - 1);
+			spin_lock_irqsave(&vhost->host->host_lock, flags);
 			vhost->do_enquiry = 0;
+			vhost->mq_enabled = 0;
+			spin_unlock_irqrestore(&vhost->host->host_lock, flags);
 			return;
 		}
 	}
@@ -7014,16 +7036,21 @@ static int ibmvfc_alloc_channels(struct ibmvfc_host *vhost,
 				 struct ibmvfc_channels *channels)
 {
 	struct ibmvfc_queue *scrq;
+	enum ibmvfc_msg_fmt fmt;
 	int i, j;
 	int rc = 0;
 
 	channels->scrqs = kzalloc_objs(*channels->scrqs, channels->max_queues);
-	if (!channels->scrqs)
+	if (!channels->scrqs) {
+		channels->active_queues = 0;
 		return -ENOMEM;
+	}
 
+	fmt = (channels->protocol != IBMVFC_PROTO_ASYNC) ? IBMVFC_SUB_CRQ_FMT :
+		IBMVFC_ASYNC_SUB_CRQ_FMT;
 	for (i = 0; i < channels->max_queues; i++) {
 		scrq = &channels->scrqs[i];
-		rc = ibmvfc_alloc_queue(vhost, scrq, IBMVFC_SUB_CRQ_FMT);
+		rc = ibmvfc_alloc_queue(vhost, scrq, fmt);
 		if (rc) {
 			for (j = i; j > 0; j--) {
 				scrq = &channels->scrqs[j - 1];
@@ -7039,30 +7066,6 @@ static int ibmvfc_alloc_channels(struct ibmvfc_host *vhost,
 	return rc;
 }
 
-static void ibmvfc_init_sub_crqs(struct ibmvfc_host *vhost)
-{
-	ENTER;
-	if (!vhost->mq_enabled)
-		return;
-
-	if (ibmvfc_alloc_channels(vhost, &vhost->scsi_scrqs)) {
-		vhost->do_enquiry = 0;
-		vhost->mq_enabled = 0;
-		return;
-	}
-
-	ibmvfc_reg_sub_crqs(vhost, &vhost->scsi_scrqs);
-
-	if (vhost->nvme_enabled) {
-		if (ibmvfc_alloc_channels(vhost, &vhost->nvme_scrqs))
-			vhost->nvme_enabled = 0;
-		else
-			ibmvfc_reg_sub_crqs(vhost, &vhost->nvme_scrqs);
-	}
-
-	LEAVE;
-}
-
 static void ibmvfc_release_channels(struct ibmvfc_host *vhost,
 				    struct ibmvfc_channels *channels)
 {
@@ -7081,9 +7084,53 @@ static void ibmvfc_release_channels(struct ibmvfc_host *vhost,
 	}
 }
 
+static void ibmvfc_init_sub_crqs(struct ibmvfc_host *vhost)
+{
+	unsigned long flags;
+
+	ENTER;
+	if (!vhost->mq_enabled)
+		return;
+
+	/* register async_sub_crq channel */
+	if (ibmvfc_alloc_channels(vhost, &vhost->async_scrqs))
+		goto out;
+
+	ibmvfc_reg_sub_crqs(vhost, &vhost->async_scrqs);
+
+	if (ibmvfc_alloc_channels(vhost, &vhost->scsi_scrqs))
+		goto deregister_async_sub_crq;
+
+	ibmvfc_reg_sub_crqs(vhost, &vhost->scsi_scrqs);
+
+	if (vhost->nvme_enabled) {
+		if (ibmvfc_alloc_channels(vhost, &vhost->nvme_scrqs)) {
+			spin_lock_irqsave(&vhost->host->host_lock, flags);
+			vhost->nvme_enabled = 0;
+			spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+		} else
+			ibmvfc_reg_sub_crqs(vhost, &vhost->nvme_scrqs);
+	}
+
+	LEAVE;
+	return;
+
+deregister_async_sub_crq:
+	ibmvfc_dereg_sub_crqs(vhost, &vhost->async_scrqs);
+	ibmvfc_release_channels(vhost, &vhost->async_scrqs);
+out:
+	spin_lock_irqsave(&vhost->host->host_lock, flags);
+	vhost->do_enquiry = 0;
+	vhost->mq_enabled = 0;
+	spin_unlock_irqrestore(&vhost->host->host_lock, flags);
+}
+
 static void ibmvfc_release_sub_crqs(struct ibmvfc_host *vhost)
 {
 	ENTER;
+	ibmvfc_dereg_sub_crqs(vhost, &vhost->async_scrqs);
+	ibmvfc_release_channels(vhost, &vhost->async_scrqs);
+
 	if (!vhost->scsi_scrqs.scrqs)
 		return;
 
@@ -7349,6 +7396,9 @@ static int ibmvfc_probe(struct vio_dev *vdev, const struct vio_device_id *id)
 	vhost->task_set = 1;
 
 	vhost->mq_enabled = mq_enabled;
+	vhost->async_scrqs.desired_queues = 1;
+	vhost->async_scrqs.max_queues = 1;
+	vhost->async_scrqs.protocol = IBMVFC_PROTO_ASYNC;
 	vhost->scsi_scrqs.desired_queues = min(shost->nr_hw_queues, nr_scsi_channels);
 	vhost->scsi_scrqs.max_queues = shost->nr_hw_queues;
 	vhost->scsi_scrqs.protocol = IBMVFC_PROTO_SCSI;

-- 
2.56.0

