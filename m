From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Wed, 08 Apr 2026 12:07:45 -0500
Subject: [PATCH 4/5] ibmvfc: use async sub-queue for FPIN messages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-ibmvfc-fpin-support-v1-4-52b06c464e03@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775668068; l=23596;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=yxFkgxkcN0WiR0tHGPw55PFL9hgdZ6iAncVKx5i+7t8=;
 b=Cv5rV+VK+yRNI9py9uv+D6Gam8zx+kUIBP6CF4ku06BiP9OVx2TS9OEpoRuwyx/qdTXWfgqyP
 D9kQFd2Wi5qBTAadME4847ncXUjkkqSVCnZ776nS4wt5JJd7rcN/B42
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- allocate async sub-queue
- allocate interrupt and set up handler
- negotiate use of async sub-queue with NPIV (VIOS)
- refactor ibmvfc_basic_fpin_to_desc() and ibmvfc_full_fpin_to_desc()
  into common routine
- add KUnit test to verify async sub-queue is allocated
---
 drivers/scsi/ibmvscsi/ibmvfc.c       | 325 ++++++++++++++++++++++++++++++++---
 drivers/scsi/ibmvscsi/ibmvfc.h       |  29 +++-
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c |  52 +++---
 3 files changed, 363 insertions(+), 43 deletions(-)

diff --git a/drivers/scsi/ibmvscsi/ibmvfc.c b/drivers/scsi/ibmvscsi/ibmvfc.c
index 803fc3caa14d..26e39b367022 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc.c
@@ -1471,6 +1471,13 @@ static void ibmvfc_gather_partition_info(struct ibmvfc_host *vhost)
 	of_node_put(rootdn);
 }
 
+static __be64 ibmvfc_npiv_chan_caps[] = {
+	cpu_to_be64(IBMVFC_CAN_USE_CHANNELS | IBMVFC_USE_ASYNC_SUBQ |
+		    IBMVFC_YES_SCSI | IBMVFC_CAN_HANDLE_FPIN),
+	cpu_to_be64(IBMVFC_CAN_USE_CHANNELS),
+};
+#define IBMVFC_NPIV_CHAN_CAPS_SIZE (sizeof(ibmvfc_npiv_chan_caps)/sizeof(__be64))
+
 /**
  * ibmvfc_set_login_info - Setup info for NPIV login
  * @vhost:	ibmvfc host struct
@@ -1486,6 +1493,8 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 	const char *location;
 	u16 max_cmds;
 
+	ENTER;
+
 	max_cmds = scsi_qdepth + IBMVFC_NUM_INTERNAL_REQ;
 	if (mq_enabled)
 		max_cmds += (scsi_qdepth + IBMVFC_NUM_INTERNAL_SUBQ_REQ) *
@@ -1509,8 +1518,12 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 		cpu_to_be64(IBMVFC_CAN_MIGRATE | IBMVFC_CAN_SEND_VF_WWPN |
 			    IBMVFC_CAN_USE_NOOP_CMD);
 
-	if (vhost->mq_enabled || vhost->using_channels)
-		login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_USE_CHANNELS);
+	if (vhost->mq_enabled || vhost->using_channels) {
+		if (vhost->login_cap_index >= IBMVFC_NPIV_CHAN_CAPS_SIZE)
+			login_info->capabilities |= cpu_to_be64(IBMVFC_CAN_USE_CHANNELS);
+		else
+			login_info->capabilities |= ibmvfc_npiv_chan_caps[vhost->login_cap_index];
+	}
 
 	login_info->async.va = cpu_to_be64(vhost->async_crq.msg_token);
 	login_info->async.len = cpu_to_be32(async_crq->size *
@@ -1524,6 +1537,8 @@ static void ibmvfc_set_login_info(struct ibmvfc_host *vhost)
 	location = of_get_property(of_node, "ibm,loc-code", NULL);
 	location = location ? location : dev_name(vhost->dev);
 	strscpy(login_info->drc_name, location, sizeof(login_info->drc_name));
+
+	LEAVE;
 }
 
 /**
@@ -3323,7 +3338,7 @@ ibmvfc_common_fpin_to_desc(u8 fpin_status, __be64 wwpn, __be16 modifier,
  * non-NULL - pointer to populated struct fc_els_fpin
  */
 static struct fc_els_fpin *
-/*XXX*/ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq)
+ibmvfc_basic_fpin_to_desc(struct ibmvfc_async_crq *crq)
 {
 	return ibmvfc_common_fpin_to_desc(crq->fpin_status, crq->wwpn,
 					  cpu_to_be16(0),
@@ -3332,6 +3347,29 @@ static struct fc_els_fpin *
 					  cpu_to_be32(1));
 }
 
+/**
+ * ibmvfc_full_fpin_to_desc(): allocate and populate a struct fc_els_fpin struct
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
+ibmvfc_full_fpin_to_desc(struct ibmvfc_async_subq *ibmvfc_fpin)
+{
+	return ibmvfc_common_fpin_to_desc(ibmvfc_fpin->fpin_status,
+					  ibmvfc_fpin->wwpn,
+					  cpu_to_be16(0),
+					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_PERIOD),
+					  cpu_to_be32(IBMVFC_FPIN_DEFAULT_EVENT_THRESHOLD),
+					  cpu_to_be32(1));
+}
+
 /**
  * ibmvfc_handle_async - Handle an async event from the adapter
  * @crq:	crq to process
@@ -3449,6 +3487,120 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq,
 }
 EXPORT_SYMBOL_IF_KUNIT(ibmvfc_handle_async);
 
+VISIBLE_IF_KUNIT void ibmvfc_handle_asyncq(struct ibmvfc_crq *crq_instance,
+					   struct ibmvfc_host *vhost,
+					   struct list_head *evt_doneq)
+{
+	struct ibmvfc_async_subq *crq = (struct ibmvfc_async_subq *)crq_instance;
+	const struct ibmvfc_async_desc *desc = ibmvfc_get_ae_desc(be16_to_cpu(crq->event));
+	struct ibmvfc_target *tgt;
+	struct fc_els_fpin *fpin;
+
+	ibmvfc_log(vhost, desc->log_level,
+		   "%s event received. wwpn: %llx, node_name: %llx%s event 0x%x\n",
+		   desc->desc, be64_to_cpu(crq->wwpn), be64_to_cpu(crq->id.node_name),
+		   ibmvfc_get_link_state(crq->link_state), be16_to_cpu(crq->event));
+
+	switch (be16_to_cpu(crq->event)) {
+	case IBMVFC_AE_RESUME:
+		switch (crq->link_state) {
+		case IBMVFC_AE_LS_LINK_DOWN:
+			ibmvfc_link_down(vhost, IBMVFC_LINK_DOWN);
+			break;
+		case IBMVFC_AE_LS_LINK_DEAD:
+			ibmvfc_link_down(vhost, IBMVFC_LINK_DEAD);
+			break;
+		case IBMVFC_AE_LS_LINK_UP:
+		case IBMVFC_AE_LS_LINK_BOUNCED:
+		default:
+			vhost->events_to_log |= IBMVFC_AE_LINKUP;
+			vhost->delay_init = 1;
+			__ibmvfc_reset_host(vhost);
+			break;
+		}
+
+		break;
+	case IBMVFC_AE_LINK_UP:
+		vhost->events_to_log |= IBMVFC_AE_LINKUP;
+		vhost->delay_init = 1;
+		__ibmvfc_reset_host(vhost);
+		break;
+	case IBMVFC_AE_SCN_FABRIC:
+	case IBMVFC_AE_SCN_DOMAIN:
+		vhost->events_to_log |= IBMVFC_AE_RSCN;
+		if (vhost->state < IBMVFC_HALTED) {
+			vhost->delay_init = 1;
+			__ibmvfc_reset_host(vhost);
+		}
+		break;
+	case IBMVFC_AE_SCN_NPORT:
+	case IBMVFC_AE_SCN_GROUP:
+		vhost->events_to_log |= IBMVFC_AE_RSCN;
+		ibmvfc_reinit_host(vhost);
+		break;
+	case IBMVFC_AE_ELS_LOGO:
+	case IBMVFC_AE_ELS_PRLO:
+	case IBMVFC_AE_ELS_PLOGI:
+		list_for_each_entry(tgt, &vhost->targets, queue) {
+			if (!crq->wwpn && !crq->id.node_name)
+				break;
+	#ifdef notyet
+			if (cpu_to_be64(tgt->scsi_id) != acrq->scsi_id)
+				continue;
+	#endif
+			if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
+				continue;
+			if (crq->id.node_name &&
+			    cpu_to_be64(tgt->ids.node_name) != crq->id.node_name)
+				continue;
+			if (tgt->need_login && be64_to_cpu(crq->event) == IBMVFC_AE_ELS_LOGO)
+				tgt->logo_rcvd = 1;
+			if (!tgt->need_login || be64_to_cpu(crq->event) == IBMVFC_AE_ELS_PLOGI) {
+				ibmvfc_del_tgt(tgt);
+				ibmvfc_reinit_host(vhost);
+			}
+		}
+		break;
+	case IBMVFC_AE_LINK_DOWN:
+	case IBMVFC_AE_ADAPTER_FAILED:
+		ibmvfc_link_down(vhost, IBMVFC_LINK_DOWN);
+		break;
+	case IBMVFC_AE_LINK_DEAD:
+		ibmvfc_link_down(vhost, IBMVFC_LINK_DEAD);
+		break;
+	case IBMVFC_AE_HALT:
+		ibmvfc_link_down(vhost, IBMVFC_HALTED);
+		break;
+	case IBMVFC_AE_FPIN:
+		if (!crq->wwpn && !crq->id.node_name)
+			break;
+		list_for_each_entry(tgt, &vhost->targets, queue) {
+			if (crq->wwpn && cpu_to_be64(tgt->ids.port_name) != crq->wwpn)
+				continue;
+			if (crq->id.node_name &&
+			    cpu_to_be64(tgt->ids.node_name) != crq->id.node_name)
+				continue;
+			if (!tgt->rport)
+				continue;
+			fpin = ibmvfc_full_fpin_to_desc(crq);
+			if (fpin) {
+				fc_host_fpin_rcv(tgt->vhost->host,
+						 sizeof(*fpin) + be32_to_cpu(fpin->desc_len),
+						 (char *)fpin, 0);
+				kfree(fpin);
+			} else
+				dev_err(vhost->dev,
+					"FPIN event %u received, unable to process\n",
+					crq->fpin_status);
+		}
+		break;
+	default:
+		dev_err(vhost->dev, "Unknown async event received: %d\n", crq->event);
+		break;
+	}
+}
+EXPORT_SYMBOL_IF_KUNIT(ibmvfc_handle_asyncq);
+
 /**
  * ibmvfc_handle_crq - Handles and frees received events in the CRQ
  * @crq:	Command/Response queue
@@ -3500,6 +3652,7 @@ VISIBLE_IF_KUNIT void ibmvfc_handle_crq(struct ibmvfc_crq *crq, struct ibmvfc_ho
 			dev_err(vhost->dev, "Host partner adapter deregistered or failed (rc=%d)\n", crq->format);
 			ibmvfc_purge_requests(vhost, DID_ERROR);
 			ibmvfc_link_down(vhost, IBMVFC_LINK_DOWN);
+			vhost->login_cap_index++;
 			ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_RESET);
 		} else {
 			dev_err(vhost->dev, "Received unknown transport event from partner (rc=%d)\n", crq->format);
@@ -4078,6 +4231,13 @@ static void ibmvfc_handle_scrq(struct ibmvfc_crq *crq, struct ibmvfc_host *vhost
 	spin_unlock(&evt->queue->l_lock);
 }
 
+/**
+ * ibmvfc_next_scrq - Returns the next entry in message subqueue
+ * @scrq:	Pointer to message subqueue
+ *
+ * Returns:
+ *	Pointer to next entry in queue / NULL if empty
+ **/
 static struct ibmvfc_crq *ibmvfc_next_scrq(struct ibmvfc_queue *scrq)
 {
 	struct ibmvfc_crq *crq;
@@ -4093,6 +4253,65 @@ static struct ibmvfc_crq *ibmvfc_next_scrq(struct ibmvfc_queue *scrq)
 	return crq;
 }
 
+static void ibmvfc_drain_async_subq(struct ibmvfc_queue *scrq)
+{
+	struct ibmvfc_crq *crq;
+	struct ibmvfc_event *evt, *temp;
+	unsigned long flags;
+	int done = 0;
+	LIST_HEAD(evt_doneq);
+
+	ENTER;
+
+	spin_lock_irqsave(scrq->q_lock, flags);
+	while (!done) {
+		while ((crq = ibmvfc_next_scrq(scrq)) != NULL) {
+			ibmvfc_handle_asyncq(crq, scrq->vhost, &evt_doneq);
+			crq->valid = 0;
+			wmb();
+		}
+
+		ibmvfc_toggle_scrq_irq(scrq, 1);
+		crq = ibmvfc_next_scrq(scrq);
+		if (crq != NULL) {
+			ibmvfc_toggle_scrq_irq(scrq, 0);
+			ibmvfc_handle_asyncq(crq, scrq->vhost, &evt_doneq);
+			crq->valid = 0;
+			wmb();
+		} else
+			done = 1;
+	}
+	spin_unlock_irqrestore(scrq->q_lock, flags);
+
+	list_for_each_entry_safe(evt, temp, &evt_doneq, queue_list) {
+		timer_delete(&evt->timer);
+		list_del(&evt->queue_list);
+		ibmvfc_trc_end(evt);
+		evt->done(evt);
+	}
+	LEAVE;
+}
+
+/**
+ * ibmvfc_interrupt_asyncq - Handle an async event from the adapter
+ * @irq:           interrupt request
+ * @scrq_instance: async subq
+ *
+ **/
+static irqreturn_t ibmvfc_interrupt_asyncq(int irq, void *scrq_instance)
+{
+	struct ibmvfc_queue *scrq = (struct ibmvfc_queue *)scrq_instance;
+
+	ENTER;
+
+	ibmvfc_toggle_scrq_irq(scrq, 0);
+	ibmvfc_drain_async_subq(scrq);
+
+	LEAVE;
+
+	return IRQ_HANDLED;
+}
+
 static void ibmvfc_drain_sub_crq(struct ibmvfc_queue *scrq)
 {
 	struct ibmvfc_crq *crq;
@@ -5316,6 +5535,8 @@ static void ibmvfc_channel_setup_done(struct ibmvfc_event *evt)
 			for (i = 0; i < active_queues; i++)
 				scrqs->scrqs[i].vios_cookie =
 					be64_to_cpu(setup->channel_handles[i]);
+			scrqs->async_scrq->vios_cookie =
+				be64_to_cpu(setup->asyncSubqHandle);
 
 			ibmvfc_dbg(vhost, "Using %u channels\n",
 				   vhost->scsi_scrqs.active_queues);
@@ -5366,6 +5587,7 @@ static void ibmvfc_channel_setup(struct ibmvfc_host *vhost)
 		setup_buf->num_scsi_subq_channels = cpu_to_be32(num_channels);
 		for (i = 0; i < num_channels; i++)
 			setup_buf->channel_handles[i] = cpu_to_be64(scrqs->scrqs[i].cookie);
+		setup_buf->asyncSubqHandle = cpu_to_be64(scrqs->async_scrq->cookie);
 	}
 
 	ibmvfc_init_event(evt, ibmvfc_channel_setup_done, IBMVFC_MAD_FORMAT);
@@ -5461,6 +5683,8 @@ static void ibmvfc_npiv_login_done(struct ibmvfc_event *evt)
 	unsigned int npiv_max_sectors;
 	int level = IBMVFC_DEFAULT_LOG_LEVEL;
 
+	ENTER;
+
 	switch (mad_status) {
 	case IBMVFC_MAD_SUCCESS:
 		ibmvfc_free_event(evt);
@@ -5540,6 +5764,8 @@ static void ibmvfc_npiv_login_done(struct ibmvfc_event *evt)
 		ibmvfc_set_host_action(vhost, IBMVFC_HOST_ACTION_QUERY);
 		wake_up(&vhost->work_wait_q);
 	}
+
+	LEAVE;
 }
 
 /**
@@ -6188,14 +6414,26 @@ static int ibmvfc_init_crq(struct ibmvfc_host *vhost)
 	return retrc;
 }
 
-static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
-				   struct ibmvfc_channels *channels,
-				   int index)
+static inline char *ibmvfc_channel_index(struct ibmvfc_channels *channels,
+					 struct ibmvfc_queue *scrq,
+					 char *buf, size_t bufsize)
+{
+	if (scrq < channels->scrqs || scrq >= channels->scrqs + channels->active_queues)
+		strscpy(buf, "async", 6);
+	else
+		snprintf(buf, bufsize, "%ld", scrq - channels->scrqs);
+	return buf;
+}
+
+static int ibmvfc_register_channel_handler(struct ibmvfc_host *vhost,
+					   struct ibmvfc_channels *channels,
+					   struct ibmvfc_queue *scrq,
+					   irq_handler_t irq)
 {
 	struct device *dev = vhost->dev;
 	struct vio_dev *vdev = to_vio_dev(dev);
-	struct ibmvfc_queue *scrq = &channels->scrqs[index];
 	int rc = -ENOMEM;
+	char buf[16];
 
 	ENTER;
 
@@ -6214,20 +6452,23 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 
 	if (!scrq->irq) {
 		rc = -EINVAL;
-		dev_err(dev, "Error mapping sub-crq[%d] irq\n", index);
+		dev_err(dev, "Error mapping sub-crq[%s] irq\n",
+			ibmvfc_channel_index(channels, scrq, buf, sizeof(buf)));
 		goto irq_failed;
 	}
 
 	switch (channels->protocol) {
 	case IBMVFC_PROTO_SCSI:
-		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-scsi%d",
-			 vdev->unit_address, index);
-		scrq->handler = ibmvfc_interrupt_mq;
+		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-scsi%s",
+			 vdev->unit_address,
+			 ibmvfc_channel_index(channels, scrq, buf, sizeof(buf)));
+		scrq->handler = irq;
 		break;
 	case IBMVFC_PROTO_NVME:
-		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-nvmf%d",
-			 vdev->unit_address, index);
-		scrq->handler = ibmvfc_interrupt_mq;
+		snprintf(scrq->name, sizeof(scrq->name), "ibmvfc-%x-nvmf%s",
+			 vdev->unit_address,
+			 ibmvfc_channel_index(channels, scrq, buf, sizeof(buf)));
+		scrq->handler = irq;
 		break;
 	default:
 		dev_err(dev, "Unknown channel protocol (%d)\n",
@@ -6238,12 +6479,14 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 	rc = request_irq(scrq->irq, scrq->handler, 0, scrq->name, scrq);
 
 	if (rc) {
-		dev_err(dev, "Couldn't register sub-crq[%d] irq\n", index);
+		dev_err(dev, "Couldn't register sub-crq[%s] irq\n",
+			ibmvfc_channel_index(channels, scrq, buf, sizeof(buf)));
 		irq_dispose_mapping(scrq->irq);
 		goto irq_failed;
 	}
 
-	scrq->hwq_id = index;
+	if (scrq >= channels->scrqs && scrq < channels->scrqs + channels->active_queues)
+		scrq->hwq_id = scrq - channels->scrqs;
 
 	LEAVE;
 	return 0;
@@ -6257,13 +6500,21 @@ static int ibmvfc_register_channel(struct ibmvfc_host *vhost,
 	return rc;
 }
 
+static inline int
+ibmvfc_register_channel(struct ibmvfc_host *vhost,
+			struct ibmvfc_channels *channels,
+			struct ibmvfc_queue *scrq)
+{
+	return ibmvfc_register_channel_handler(vhost, channels, scrq, ibmvfc_interrupt_mq);
+}
+
 static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 				      struct ibmvfc_channels *channels,
-				      int index)
+				      struct ibmvfc_queue *scrq)
 {
 	struct device *dev = vhost->dev;
 	struct vio_dev *vdev = to_vio_dev(dev);
-	struct ibmvfc_queue *scrq = &channels->scrqs[index];
+	char buf[16];
 	long rc;
 
 	ENTER;
@@ -6278,7 +6529,8 @@ static void ibmvfc_deregister_channel(struct ibmvfc_host *vhost,
 	} while (rc == H_BUSY || H_IS_LONG_BUSY(rc));
 
 	if (rc)
-		dev_err(dev, "Failed to free sub-crq[%d]: rc=%ld\n", index, rc);
+		dev_err(dev, "Failed to free sub-crq[%s]: rc=%ld\n",
+			ibmvfc_channel_index(channels, scrq, buf, sizeof(buf)), rc);
 
 	/* Clean out the queue */
 	memset(scrq->msgs.crq, 0, PAGE_SIZE);
@@ -6296,10 +6548,19 @@ static void ibmvfc_reg_sub_crqs(struct ibmvfc_host *vhost,
 	if (!vhost->mq_enabled || !channels->scrqs)
 		return;
 
+	if (ibmvfc_register_channel_handler(vhost, channels,
+					    channels->async_scrq,
+					    ibmvfc_interrupt_asyncq))
+		return;
+
 	for (i = 0; i < channels->max_queues; i++) {
-		if (ibmvfc_register_channel(vhost, channels, i)) {
+		if (ibmvfc_register_channel(vhost, channels, &channels->scrqs[i])) {
 			for (j = i; j > 0; j--)
-				ibmvfc_deregister_channel(vhost, channels, j - 1);
+				ibmvfc_deregister_channel(
+					vhost, channels, &channels->scrqs[j - 1]);
+			ibmvfc_deregister_channel(vhost, channels,
+							channels->async_scrq);
+
 			vhost->do_enquiry = 0;
 			return;
 		}
@@ -6318,7 +6579,8 @@ static void ibmvfc_dereg_sub_crqs(struct ibmvfc_host *vhost,
 		return;
 
 	for (i = 0; i < channels->max_queues; i++)
-		ibmvfc_deregister_channel(vhost, channels, i);
+		ibmvfc_deregister_channel(vhost, channels, &channels->scrqs[i]);
+	ibmvfc_deregister_channel(vhost, channels, channels->async_scrq);
 
 	LEAVE;
 }
@@ -6334,6 +6596,21 @@ static int ibmvfc_alloc_channels(struct ibmvfc_host *vhost,
 	if (!channels->scrqs)
 		return -ENOMEM;
 
+	channels->async_scrq = kzalloc_obj(*channels->async_scrq, GFP_KERNEL);
+
+	if (!channels->async_scrq) {
+		kfree(channels->scrqs);
+		return -ENOMEM;
+	}
+
+	rc = ibmvfc_alloc_queue(vhost, channels->async_scrq,
+				IBMVFC_SUB_CRQ_FMT);
+	if (rc) {
+		kfree(channels->scrqs);
+		kfree(channels->async_scrq);
+		return rc;
+	}
+
 	for (i = 0; i < channels->max_queues; i++) {
 		scrq = &channels->scrqs[i];
 		rc = ibmvfc_alloc_queue(vhost, scrq, IBMVFC_SUB_CRQ_FMT);
@@ -6345,6 +6622,9 @@ static int ibmvfc_alloc_channels(struct ibmvfc_host *vhost,
 			kfree(channels->scrqs);
 			channels->scrqs = NULL;
 			channels->active_queues = 0;
+			ibmvfc_free_queue(vhost, channels->async_scrq);
+			kfree(channels->async_scrq);
+			channels->async_scrq = NULL;
 			return rc;
 		}
 	}
@@ -6629,6 +6909,7 @@ static int ibmvfc_probe(struct vio_dev *vdev, const struct vio_device_id *id)
 	vhost->using_channels = 0;
 	vhost->do_enquiry = 1;
 	vhost->scan_timeout = 0;
+	vhost->login_cap_index = 0;
 
 	strcpy(vhost->partition_name, "UNKNOWN");
 	init_waitqueue_head(&vhost->work_wait_q);
diff --git a/drivers/scsi/ibmvscsi/ibmvfc.h b/drivers/scsi/ibmvscsi/ibmvfc.h
index 4f680c5d9558..b9f22613d144 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc.h
+++ b/drivers/scsi/ibmvscsi/ibmvfc.h
@@ -182,6 +182,9 @@ struct ibmvfc_npiv_login {
 #define IBMVFC_CAN_HANDLE_FPIN		0x04
 #define IBMVFC_CAN_USE_MAD_VERSION	0x08
 #define IBMVFC_CAN_SEND_VF_WWPN		0x10
+#define IBMVFC_YES_NVMEOF		0x20
+#define IBMVFC_YES_SCSI			0x40
+#define IBMVFC_USE_ASYNC_SUBQ		0x100
 #define IBMVFC_CAN_USE_NOOP_CMD		0x200
 	__be64 node_name;
 	struct srp_direct_buf async;
@@ -231,6 +234,7 @@ struct ibmvfc_npiv_login_resp {
 #define IBMVFC_CAN_SUPPORT_CHANNELS	0x80
 #define IBMVFC_SUPPORT_NVMEOF		0x100
 #define IBMVFC_SUPPORT_SCSI		0x200
+#define IBMVFC_SUPPORT_ASYNC_SUBQ	0x800
 #define IBMVFC_SUPPORT_NOOP_CMD		0x1000
 	__be32 max_cmds;
 	__be32 scsi_id_sz;
@@ -565,7 +569,7 @@ struct ibmvfc_channel_setup_mad {
 	struct srp_direct_buf buffer;
 } __packed __aligned(8);
 
-#define IBMVFC_MAX_CHANNELS	502
+#define IBMVFC_MAX_CHANNELS	501
 
 struct ibmvfc_channel_setup {
 	__be32 flags;
@@ -580,6 +584,7 @@ struct ibmvfc_channel_setup {
 	struct srp_direct_buf buffer;
 	__be64 reserved2[5];
 	__be64 channel_handles[IBMVFC_MAX_CHANNELS];
+	__be64 asyncSubqHandle;
 } __packed __aligned(8);
 
 struct ibmvfc_connection_info {
@@ -710,6 +715,25 @@ struct ibmvfc_async_crq {
 	__be64 reserved;
 } __packed __aligned(8);
 
+struct ibmvfc_async_subq {
+	volatile u8 valid;
+#define IBMVFC_ASYNC_ID_IS_ASSOC_ID	0x01
+#define IBMVFC_FC_EEH			0x04
+#define IBMVFC_FC_FW_UPDATE		0x08
+#define IBMVFC_FC_FW_DUMP		0x10
+	u8 flags;
+	u8 link_state;
+	u8 fpin_status;
+	__be16 event;
+	__be16 pad;
+	volatile __be64 wwpn;
+	volatile __be64 nport_id;
+	union {
+		__be64 node_name;
+		__be64 assoc_id;
+	} id;
+} __packed __aligned(8);
+
 union ibmvfc_iu {
 	struct ibmvfc_mad_common mad_common;
 	struct ibmvfc_npiv_login_mad npiv_login;
@@ -849,6 +873,7 @@ struct ibmvfc_queue {
 
 struct ibmvfc_channels {
 	struct ibmvfc_queue *scrqs;
+	struct ibmvfc_queue *async_scrq;
 	enum ibmvfc_protocol protocol;
 	unsigned int active_queues;
 	unsigned int desired_queues;
@@ -989,6 +1014,8 @@ static inline int ibmvfc_check_caps(struct ibmvfc_host *vhost, unsigned long cap
 
 #ifdef VISIBLE_IF_KUNIT
 VISIBLE_IF_KUNIT void ibmvfc_handle_async(struct ibmvfc_async_crq *crq, struct ibmvfc_host *vhost);
+VISIBLE_IF_KUNIT void ibmvfc_handle_asyncq(struct ibmvfc_crq *crq_instance,
+					   struct ibmvfc_host *vhost, struct list_head *evt_doneq);
 VISIBLE_IF_KUNIT struct list_head *ibmvfc_get_headp(void);
 VISIBLE_IF_KUNIT void ibmvfc_handle_crq(struct ibmvfc_crq *crq,
 					struct ibmvfc_host *vhost,
diff --git a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
index 3359e4ebebe2..3a41127c4e81 100644
--- a/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
+++ b/drivers/scsi/ibmvscsi/ibmvfc_kunit.c
@@ -22,14 +22,14 @@ MODULE_IMPORT_NS("EXPORTED_FOR_KUNIT_TESTING");
 static void ibmvfc_handle_fpin_event_test(struct kunit *test)
 {
 	u64 *stats[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1] = { NULL };
-	u64 post[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
-	u64 pre[IBMVFC_AE_FPIN_CONGESTION_CLEARED + 1];
 	enum ibmvfc_ae_fpin_status fs;
-	struct ibmvfc_async_crq crq;
+	struct ibmvfc_async_subq crq;
 	struct ibmvfc_target *tgt;
 	struct ibmvfc_host *vhost;
 	struct list_head *queue;
 	struct list_head *headp;
+	LIST_HEAD(evt_doneq);
+	u64 pre, post;
 
 
 	headp = ibmvfc_get_headp();
@@ -52,31 +52,23 @@ static void ibmvfc_handle_fpin_event_test(struct kunit *test)
 		crq.valid = 0x80;
 		crq.link_state = IBMVFC_AE_LS_LINK_UP;
 		crq.fpin_status = fs;
-		crq.event = cpu_to_be64(IBMVFC_AE_FPIN);
-		crq.scsi_id = cpu_to_be64(tgt->scsi_id);
+		crq.event = cpu_to_be16(IBMVFC_AE_FPIN);
 		crq.wwpn = cpu_to_be64(tgt->wwpn);
-		crq.node_name = cpu_to_be64(tgt->ids.node_name);
-		pre[fs] = *stats[fs];
-		ibmvfc_handle_async(&crq, vhost);
-		post[fs] = *stats[fs];
-		KUNIT_EXPECT_EQ(test, post[fs], pre[fs]+1);
+		crq.id.node_name = cpu_to_be64(tgt->ids.node_name);
+		pre = *stats[fs];
+		ibmvfc_handle_asyncq((struct ibmvfc_crq *)&crq, vhost, &evt_doneq);
+		post = *stats[fs];
+		KUNIT_EXPECT_EQ(test, post, pre+1);
 	}
 
 	/* bad path */
-	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++)
-		pre[fs] = *stats[fs];
 	crq.valid = 0x80;
 	crq.link_state = IBMVFC_AE_LS_LINK_UP;
 	crq.fpin_status = 0; /* bad value */
-	crq.event = cpu_to_be64(IBMVFC_AE_FPIN);
-	crq.scsi_id = cpu_to_be64(tgt->scsi_id);
+	crq.event = cpu_to_be16(IBMVFC_AE_FPIN);
 	crq.wwpn = cpu_to_be64(tgt->wwpn);
-	crq.node_name = cpu_to_be64(tgt->ids.node_name);
-	ibmvfc_handle_async(&crq, vhost);
-	for (fs = IBMVFC_AE_FPIN_LINK_CONGESTED; fs <= IBMVFC_AE_FPIN_CONGESTION_CLEARED; fs++) {
-		post[fs] = *stats[fs];
-		KUNIT_EXPECT_EQ(test, pre[fs], post[fs]);
-	}
+	crq.id.node_name = cpu_to_be64(tgt->ids.node_name);
+	ibmvfc_handle_asyncq((struct ibmvfc_crq *)&crq, vhost, &evt_doneq);
 }
 
 /**
@@ -105,9 +97,29 @@ static void ibmvfc_noop_test(struct kunit *test)
 	ibmvfc_handle_crq(&crq, vhost, &evtq);
 }
 
+/**
+ * ibmvfc_async_subq_test - unit test for allocating async subqueue
+ * @test: pointer to kunit structure
+ *
+ * Return: void
+ */
+static void ibmvfc_async_subq_test(struct kunit *test)
+{
+	struct ibmvfc_host *vhost;
+	struct list_head *queue;
+	struct list_head *headp;
+
+	headp = ibmvfc_get_headp();
+	queue = headp->next;
+	vhost = container_of(queue, struct ibmvfc_host, queue);
+
+	KUNIT_EXPECT_NOT_NULL(test, vhost->scsi_scrqs.async_scrq);
+}
+
 static struct kunit_case ibmvfc_fpin_test_cases[] = {
 	KUNIT_CASE(ibmvfc_handle_fpin_event_test),
 	KUNIT_CASE(ibmvfc_noop_test),
+	KUNIT_CASE(ibmvfc_async_subq_test),
 	{},
 };
 

-- 
2.53.0

