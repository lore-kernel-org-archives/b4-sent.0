From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Wed, 09 Sep 2026 14:08:03 -0500
Subject: [PATCH v8 8/9] scsi: ibmvfc: register and use asynchronous sub CRQ
 for events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-ibmvfc-fpin-support-v8-8-b27183b055af@linux.ibm.com>
References: <20260909-ibmvfc-fpin-support-v8-0-b27183b055af@linux.ibm.com>
In-Reply-To: <20260909-ibmvfc-fpin-support-v8-0-b27183b055af@linux.ibm.com>
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-kernel@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, Brian King <brking@linux.ibm.com>, 
 Greg Joyce <gjoyce@linux.ibm.com>, Kyle Mahlkuch <kmahlkuc@linux.ibm.com>, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788980878; l=8263;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=P/y/m4IYJHpKt739kYnzaytO6yfjYsjo3oP1eJ9dUKw=;
 b=bNcdxz58fPYyX2UvTjsAN2/TXSQRdCgar+ngICgdeW6i8deXeyQ7nxknzYDvTnR4Nr7j6wmRx
 qvovPgIaT6mB9TuIrZ5+DjeE5AJClW9G17LAmXPWD5g9pDgyTzY5ob1
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

In ibmvfc_release_sub_crqs(), ibmvfc_reenable_crq_queue(), and
ibmvfc_reset_crq(), deregister and re-register the async sub-CRQ
alongside the SCSI channel queues.

In ibmvfc_channel_setup_done(), capture the async sub-CRQ handle
returned by the VIOS in the channel setup response and store it in
vhost->async_sub_crq.vios_cookie.

In ibmvfc_set_login_info(), advertise IBMVFC_USE_ASYNC_SUBQ,
IBMVFC_CAN_HANDLE_FPIN, and IBMVFC_YES_SCSI capabilities whenever
multi-queue channels are enabled. IBMVFC_YES_SCSI was previously only
set for NVMe-enabled configurations; move it to the common multi-queue
path so it is always advertised when channels are in use.

Fix a variable-shadowing bug in ibmvfc_register_channel() where the
irq_failed cleanup loop reused rc for the H_FREE_SUB_CRQ hcall result,
clobbering the error code returned to the caller. Introduce hcall_rc
for the cleanup loop instead.

Guard the memset() in ibmvfc_deregister_channel() behind a check of
scrq->msgs.handle to prevent a NULL dereference when the function is
called on a queue that was never allocated, such as async_sub_crq when
multi-queue is disabled or initialization failed before
ibmvfc_alloc_queue() was reached.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 drivers/scsi/ibmvscsi/ibmvfc-core.c | 51 ++++++++++++++++++++++++++++++++-----
 1 file changed, 44 insertions(+), 7 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc-core.c b/drivers/scsi/ibmvscsi/ibmvfc-core.c
index f88262ffad13..edd1b2e0504c 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc-core.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc-core.c
@@ -192,6 +192,8 @@ static void ibmvfc_tgt_move_login(struct ibmvfc_target *);
 
 static void ibmvfc_dereg_sub_crqs(struct ibmvfc_host *, struct ibmvfc_channels *);
 static void ibmvfc_reg_sub_crqs(struct ibmvfc_host *, struct ibmvfc_channels *);
+static void ibmvfc_deregister_channel(struct ibmvfc_host *, struct ibmvfc_channels *, int);
+static int ibmvfc_register_channel(struct ibmvfc_host *, struct ibmvfc_channels *, int);
 
 static const char *unknown_error = "unknown error";
 
@@ -964,6 +966,7 @@ static int ibmvfc_reenable_crq_queue(struct ibmvfc_host *vhost)
 	struct vio_dev *vdev = to_vio_dev(vhost->dev);
 	unsigned long flags;
 
+	ibmvfc_deregister_channel(vhost, &vhost->scsi_scrqs, -1);
 	ibmvfc_dereg_sub_crqs(vhost, &vhost->scsi_scrqs);
 	ibmvfc_dereg_sub_crqs(vhost, &vhost->nvme_scrqs);
 
@@ -986,6 +989,7 @@ static int ibmvfc_reenable_crq_queue(struct ibmvfc_host *vhost)
 	spin_unlock(vhost->crq.q_lock);
 	spin_unlock_irqrestore(vhost->host->host_lock, flags);
 
+	ibmvfc_register_channel(vhost, &vhost->scsi_scrqs, -1);
 	ibmvfc_reg_sub_crqs(vhost, &vhost->scsi_scrqs);
 	ibmvfc_reg_sub_crqs(vhost, &vhost->nvme_scrqs);
 
@@ -1006,6 +1010,7 @@ static int ibmvfc_reset_crq(struct ibmvfc_host *vhost)
 	struct vio_dev *vdev = to_vio_dev(vhost->dev);
 	struct ibmvfc_queue *crq = &vhost->crq;
 
+	ibmvfc_deregister_channel(vhost, &vhost->scsi_scrqs, -1);
 	ibmvfc_dereg_sub_crqs(vhost, &vhost->scsi_scrqs);
 	ibmvfc_dereg_sub_crqs(vhost, &vhost->nvme_scrqs);
 
@@ -1042,6 +1047,7 @@ static int ibmvfc_reset_crq(struct ibmvfc_host *vhost)
 	spin_unlock(vhost->crq.q_lock);
 	spin_unlock_irqrestore(vhost->host->host_lock, flags);
 
+	ibmvfc_register_channel(vhost, &vhost->scsi_scrqs, -1);
 	ibmvfc_reg_sub_crqs(vhost, &vhost->scsi_scrqs);
 	ibmvfc_reg_sub_crqs(vhost, &vhost->nvme_scrqs);
 
@@ -1584,9 +1590,11 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 
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
@@ -5809,6 +5817,7 @@ static void ibmvfc_channel_setup_done(struct ibmvfc_event *evt)
 		for (i = 0; i < nvme->active_queues; i++)
 			nvme->scrqs[i].vios_cookie =
 				be64_to_cpu(setup->channel_handles[scsi->active_queues + i]);
+		vhost->async_sub_crq.vios_cookie = be64_to_cpu(setup->async_sub_crq_handle);
 
 		ibmvfc_dbg(vhost, "Using %u SCSI channels\n",
 			   scsi->active_queues);
@@ -5868,6 +5877,7 @@ static void ibmvfc_channel_setup(struct ibmvfc_host *vhost)
 		for (i = 0; i < nvme_channels; i++)
 			setup_buf->channel_handles[scsi_channels + i] =
 				cpu_to_be64(nvme->scrqs[i].cookie);
+		setup_buf->async_sub_crq_handle = cpu_to_be64(vhost->async_sub_crq.cookie);
 	}
 
 	ibmvfc_init_event(evt, ibmvfc_channel_setup_done, IBMVFC_MAD_FORMAT);
@@ -6832,6 +6842,7 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 	bool is_async = index < 0;
 	struct ibmvfc_queue *scrq = !is_async ? &channels->scrqs[index] : &vhost->async_sub_crq;
 	int rc = -ENOMEM;
+	int hcall_rc;
 
 	ENTER;
 
@@ -6900,8 +6911,8 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 
 irq_failed:
 	do {
-		rc = plpar_hcall_norets(H_FREE_SUB_CRQ, vdev->unit_address, scrq->cookie);
-	} while (rc == H_BUSY || H_IS_LONG_BUSY(rc));
+		hcall_rc = plpar_hcall_norets(H_FREE_SUB_CRQ, vdev->unit_address, scrq->cookie);
+	} while (hcall_rc == H_BUSY || H_IS_LONG_BUSY(hcall_rc));
 reg_failed:
 	LEAVE;
 	return rc;
@@ -6951,8 +6962,10 @@ static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 	}
 
 	/* Clean out the queue */
-	memset(scrq->msgs.crq, 0, PAGE_SIZE);
-	scrq->cur = 0;
+	if (scrq->msgs.handle) {
+		memset(scrq->msgs.crq, 0, PAGE_SIZE);
+		scrq->cur = 0;
+	}
 
 	LEAVE;
 }
@@ -6969,7 +6982,9 @@ static void ibmvfc_reg_sub_crqs(struct ibmvfc_host *vhost,
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
@@ -7024,16 +7039,26 @@ static int ibmvfc_alloc_channels(struct ibmvfc_host *vhost,
 
 static void ibmvfc_init_sub_crqs(struct ibmvfc_host *vhost)
 {
+	int rc = 0;
+
 	ENTER;
 	if (!vhost->mq_enabled)
 		return;
 
-	if (ibmvfc_alloc_channels(vhost, &vhost->scsi_scrqs)) {
+	rc = ibmvfc_alloc_queue(vhost, &vhost->async_sub_crq, IBMVFC_SUB_CRQ_FMT);
+	if (rc) {
 		vhost->do_enquiry = 0;
 		vhost->mq_enabled = 0;
 		return;
 	}
 
+	/* register async_sub_crq channel */
+	if (ibmvfc_register_channel(vhost, &vhost->scsi_scrqs, -1))
+		goto free_async_sub_crq;
+
+	if (ibmvfc_alloc_channels(vhost, &vhost->scsi_scrqs))
+		goto deregister_async_sub_crq;
+
 	ibmvfc_reg_sub_crqs(vhost, &vhost->scsi_scrqs);
 
 	if (vhost->nvme_enabled) {
@@ -7044,6 +7069,15 @@ static void ibmvfc_init_sub_crqs(struct ibmvfc_host *vhost)
 	}
 
 	LEAVE;
+	return;
+
+ deregister_async_sub_crq:
+	ibmvfc_deregister_channel(vhost, &vhost->scsi_scrqs, -1);
+free_async_sub_crq:
+	ibmvfc_free_queue(vhost, &vhost->async_sub_crq);
+	vhost->do_enquiry = 0;
+	vhost->mq_enabled = 0;
+	return;
 }
 
 static void ibmvfc_release_channels(struct ibmvfc_host *vhost,
@@ -7067,6 +7101,9 @@ static void ibmvfc_release_channels(struct ibmvfc_host *vhost,
 static void ibmvfc_release_sub_crqs(struct ibmvfc_host *vhost)
 {
 	ENTER;
+	ibmvfc_deregister_channel(vhost, &vhost->scsi_scrqs, -1);
+	ibmvfc_free_queue(vhost, &vhost->async_sub_crq);
+
 	if (!vhost->scsi_scrqs.scrqs)
 		return;
 

-- 
2.55.0

