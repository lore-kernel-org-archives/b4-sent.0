From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Jul 2026 13:11:06 +0200
Subject: [PATCH RFC v2 12/14] nvme: Update the controller with the CDQ
 set-feature cmd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-jag-cdq-lkml-v2-12-659a7449e849@kernel.org>
References: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
In-Reply-To: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5127;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=p2OZjMW1aIwGnbexC/PZCKu+1prCQGnCZ5ZAUVdjkWM=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpjSF+IZ0GpbnntyoJIT9QK1csf6j1fLmAe5
 qy2sotJya/cdokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqY0hfAAoJELqXzVK3
 lkFPSp4L/2bx6gV2MXX8pyIuo2xg6uRpOW37BzoC4T+J9pMFwKwByXw6/4Sp4vZdME1lhwDOwzd
 ge22GnNrV4/y+++108ouaTkBnR4O8R66V5cLDkcZie7bw+PRP60UNfeQm6vzSh5hwR5eIUz2S7v
 oib/aPqaKEwGZN8W9TefSiUwKtkXEAPrU3DdyJP5EmsoCzoNTV2u8p7h2tgS2h473vUXs5V0mlM
 UAHR7wBb0YLts28vM2MdNkLBJK12oTndVnigpeB9TLTLRRjHTfAA0a/XPuewao4oC/iCYHFOyAd
 SzeQ1VORlDKxR4DRVheK4fJsQTWc1Yuj6U8muvePBZxiwn7ZVsgze+0K15rG93eM3+rU9qgbmzI
 a/coe+Auwt82waFN8gLUaw9bERzGVIznwtdQUVw1gA2xCgmRlGjZAcDKSd2O3SwozAW7ckXtbca
 ITZ8idANAgvOoQ26nlsOIAb8PP4pYmUDUAXOcmUaG/zDWFokvJIexGTBhB+BSbntkKIf8ikH2k8
 Ic=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After advancing the queue head, send the new head position to the
controller using an NVMe set feature command. Avoid unnecessary wait on
the read by not waiting for command completion.

sf_lock serializes reads that finish before the in-flight set feature has
completed; in these cases the cmd will be resent after completion of the
previous one.

Also, re-send the set feature command right after returning and seeing
that the host head has actually moved forward since the last time the
command was sent.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/cdq.c | 92 +++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/nvme/host/cdq.h | 14 ++++++++
 2 files changed, 106 insertions(+)

diff --git a/drivers/nvme/host/cdq.c b/drivers/nvme/host/cdq.c
index 36107cf2fe11ff212d5b02dd5513fe02e3ae8f81..8e59c16ddf63df4977e1bd869be1e3a7ad19b9c5 100644
--- a/drivers/nvme/host/cdq.c
+++ b/drivers/nvme/host/cdq.c
@@ -202,6 +202,90 @@ static size_t nvme_advance_cdq(struct cdq_nvme_queue *cdq, size_t max_nrbyte)
 	return target_nbyte;
 }
 
+static void nvme_submit_sfcmd_cdq(struct cdq_nvme_queue *cdq);
+
+/* updates cntl_head, exits sf_inflight and re-arms if needed */
+static enum rq_end_io_ret nvme_endio_sfcmd_cdq(struct request *rq,
+					       blk_status_t status,
+					       const struct io_comp_batch *iob)
+{
+	struct cdq_nvme_queue *cdq = rq->end_io_data;
+	unsigned long flags;
+	bool rearm = false;
+
+	WRITE_ONCE(cdq->cntl_head, cdq->sent_head);
+	blk_mq_free_request(rq);
+
+	spin_lock_irqsave(&cdq->sf_lock, flags);
+	cdq->sf_inflight = false;
+	/* cntl_head was just written above, plain read under the lock. */
+	if (READ_ONCE(cdq->host_head) != cdq->cntl_head) {
+		cdq->sf_inflight = true;
+		rearm = true;
+	}
+	spin_unlock_irqrestore(&cdq->sf_lock, flags);
+
+	/* Re-arm (takes its own ref) before dropping ours, so cdq stays alive. */
+	if (rearm)
+		nvme_submit_sfcmd_cdq(cdq);
+
+	nvme_cdq_put(cdq);
+	return RQ_END_IO_NONE;
+}
+
+/* Inform ctrl that head as advance by sending a CDQ set-feature command*/
+static void nvme_submit_sfcmd_cdq(struct cdq_nvme_queue *cdq)
+{
+	struct nvme_command c = { };
+	struct request *rq;
+	unsigned long flags;
+	u32 head = READ_ONCE(cdq->host_head);
+
+	c.features.opcode = nvme_admin_set_features;
+	c.features.fid = cpu_to_le32(NVME_FEAT_CDQ);
+	c.features.dword11 = cpu_to_le32(cdq->id & NVME_FEAT_CDQ_ID_MASK);
+	c.features.dword12 = cpu_to_le32(head);
+
+	rq = blk_mq_alloc_request(cdq->ctrl->admin_q, nvme_req_op(&c),
+				  BLK_MQ_REQ_NOWAIT);
+	if (IS_ERR(rq)) {
+		/*
+		 * No admin tag right now and we cannot sleep. Drop the slot; the
+		 * next read() will re-arm.
+		 */
+		spin_lock_irqsave(&cdq->sf_lock, flags);
+		cdq->sf_inflight = false;
+		spin_unlock_irqrestore(&cdq->sf_lock, flags);
+		return;
+	}
+
+	cdq->sent_head = head;
+	nvme_init_request(rq, &c);
+	rq->end_io = nvme_endio_sfcmd_cdq;
+	rq->end_io_data = cdq;
+
+	/* Pin cdq for the lifetime of the command */
+	nvme_cdq_get(cdq);
+	blk_execute_rq_nowait(rq, false);
+}
+
+/* submit set feature if none are in-flight */
+static void nvme_kick_cdq(struct cdq_nvme_queue *cdq)
+{
+	unsigned long flags;
+	bool submit = false;
+
+	spin_lock_irqsave(&cdq->sf_lock, flags);
+	if (!cdq->sf_inflight) {
+		cdq->sf_inflight = true;
+		submit = true;
+	}
+	spin_unlock_irqrestore(&cdq->sf_lock, flags);
+
+	if (submit)
+		nvme_submit_sfcmd_cdq(cdq);
+}
+
 static ssize_t nvme_traversecopy_cdq(struct cdq_nvme_queue *cdq, size_t max_nrbyte,
 				   void *priv_data)
 {
@@ -231,6 +315,13 @@ static ssize_t nvme_traversecopy_cdq(struct cdq_nvme_queue *cdq, size_t max_nrby
 	}
 
 out:
+	/*
+	 * host_head advanced past consumed entries; tell the controller its head
+	 * can move up. Decoupled from this read: the set-feature admin
+	 * round-trip must not delay the data path.
+	 */
+	if (copied_nbyte)
+		nvme_kick_cdq(cdq);
 	return copied_nbyte;
 
 err_out:
@@ -416,6 +507,7 @@ int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id)
 	cdq->mc_id = mc_id;
 	cdq->ctrl = ctrl;
 	cdq->size_nbyte = (u32)size_nbyte;
+	spin_lock_init(&cdq->sf_lock);
 
 	ret = nvme_create_cdq_backing(cdq);
 	if (ret) {
diff --git a/drivers/nvme/host/cdq.h b/drivers/nvme/host/cdq.h
index 96f208264c6144d26aa4ffc34854bb16d3f19af9..893aeefb2dfc2c25f390e43eb508067b34dce31f 100644
--- a/drivers/nvme/host/cdq.h
+++ b/drivers/nvme/host/cdq.h
@@ -50,8 +50,22 @@ struct cdq_nvme_queue {
 
 	/* How far the CDQ was consumed by the host */
 	u32 host_head;
+
+	/*
+	 * Value sent by the in-flight set-feature cmd
+	 * Differs from cntl_head until set-feature cmd completes
+	 */
+	u32 sent_head;
+
+	/* Last acked CDQ head update. Trails host_head.*/
+	u32 cntl_head;
+
 	u8 phase_bit;
 
+	/* sf_* controlls if the feature set cmd is done or is still inflight */
+	spinlock_t sf_lock;
+	bool sf_inflight;
+
 	/* Manage refs for read FD and controller xarray */
 	struct kref ref;
 };

-- 
2.50.1

