From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Jul 2026 13:11:07 +0200
Subject: [PATCH RFC v2 13/14] nvme: Use eventfd for CDQ Tail pointer
 triggers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-jag-cdq-lkml-v2-13-659a7449e849@kernel.org>
References: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
In-Reply-To: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8352;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=6pPy4EUhqfqpoPvpDTe9oapGjYosFOX+XzrMx0vub4M=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpjSGDfdJ5RLXRYxe/CcpVME8VxdzG0J5xor
 lIAlNP+JtTSPIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqY0hgAAoJELqXzVK3
 lkFPeqAL/2jnxMo9aPeJBUk707BZFahn7rX9tVW/ymdR/0cxmh9WnLWVWh4GVbn1X8ITKFGbi4d
 t+KEJm7Om95n0DVRw9Fpukzrb5tn8xf27tTRARleHfEkQ5tU2V3k9LTjIuyDTDkDthFK0w6gH/1
 Or7U4ugNqnc+SqsuyN9522ZZ4ITSTWPQvBwwpbBTIb3/NebWt/e+mWuJictWkkxCBELgx7KpIhl
 2++T2M/La9QzYdpRAS4XG7cncnuYlljIdxQhrhrgzukihuOjvNx0+iQV7P1FUgOTa3bSUNSZOL/
 eDYNSBIdJYJhGZqZENj6vYzBZRo2RRq7w0qL+ibmRGKxZO8BAYfiZnflTVV3YAgApL6NBjCiy/u
 hDzaniyMsvwIii/oaZjnyVYP2OCEEAUxOgPvnb/qc8CCDnlXPK0YYCrSP+eDjuY7QvS0SEC+5Kp
 5wTODTbhVTP6zp+Fhnep2dPNwRSZsZy2AYWeH4bR+WSHXy1UlQZgasNuROzPFJdl2jvUYMXS0r5
 tM=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When an eventfd file descriptor is passed to the nvme_create_cdq
function, add the eventfd context to the cdq struct and increase its
reference. Route the AEN one shot event triggered by the controller to
the eventfd signal. Set the tail pointer trigger (TPT) as soon as an
empty CDQ is encountered.

The TPT offset sent to the controller is in pending_tpt which has the
last value assigned to it. For the time being it is set to +1 on a
"zero" read.

Note:
if a set-feature is already in flight on an empty read, the arm lingers
in pending_tpt until the next submitting kick.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/cdq.c  | 81 +++++++++++++++++++++++++++++++++++++++++++++---
 drivers/nvme/host/cdq.h  |  9 +++++-
 drivers/nvme/host/core.c |  3 +-
 include/linux/nvme.h     |  1 +
 4 files changed, 88 insertions(+), 6 deletions(-)

diff --git a/drivers/nvme/host/cdq.c b/drivers/nvme/host/cdq.c
index 8e59c16ddf63df4977e1bd869be1e3a7ad19b9c5..f4aabf0a8817058a11e6c30dcea9554076861327 100644
--- a/drivers/nvme/host/cdq.c
+++ b/drivers/nvme/host/cdq.c
@@ -4,6 +4,7 @@
  */
 
 #include <linux/anon_inodes.h>
+#include <linux/eventfd.h>
 #include <linux/file.h>
 #include <linux/uaccess.h>
 
@@ -240,10 +241,26 @@ static void nvme_submit_sfcmd_cdq(struct cdq_nvme_queue *cdq)
 	struct request *rq;
 	unsigned long flags;
 	u32 head = READ_ONCE(cdq->host_head);
+	u32 tpt = READ_ONCE(cdq->pending_tpt);
+	u32 dword11 = cdq->id & NVME_FEAT_CDQ_ID_MASK;
+	u32 cdq_nrentry = cdq->size_nbyte / NVME_CDQ_MQ_ENTRY_NRBYTES;
 
 	c.features.opcode = nvme_admin_set_features;
 	c.features.fid = cpu_to_le32(NVME_FEAT_CDQ);
-	c.features.dword11 = cpu_to_le32(cdq->id & NVME_FEAT_CDQ_ID_MASK);
+
+	if (unlikely(tpt != 0)) {
+		/*
+		 * FIXME: There is a small chance that the sent tpt will have
+		 * already been handled by the time this command completes. If
+		 * we find this to be true in the CDQ, we need to send a
+		 * subsequent feature_id to disable the tail pointer trigger.
+		 * section 5.1.25.1.23 nvme base spec.
+		 */
+		dword11 |= NVME_FEAT_CDQ_ETPT_MASK;
+		c.features.dword13 = cpu_to_le32((head + tpt) % cdq_nrentry);
+	}
+
+	c.features.dword11 = cpu_to_le32(dword11);
 	c.features.dword12 = cpu_to_le32(head);
 
 	rq = blk_mq_alloc_request(cdq->ctrl->admin_q, nvme_req_op(&c),
@@ -260,6 +277,7 @@ static void nvme_submit_sfcmd_cdq(struct cdq_nvme_queue *cdq)
 	}
 
 	cdq->sent_head = head;
+	WRITE_ONCE(cdq->pending_tpt, 0);
 	nvme_init_request(rq, &c);
 	rq->end_io = nvme_endio_sfcmd_cdq;
 	rq->end_io_data = cdq;
@@ -320,8 +338,13 @@ static ssize_t nvme_traversecopy_cdq(struct cdq_nvme_queue *cdq, size_t max_nrby
 	 * can move up. Decoupled from this read: the set-feature admin
 	 * round-trip must not delay the data path.
 	 */
-	if (copied_nbyte)
+	if (copied_nbyte) {
 		nvme_kick_cdq(cdq);
+	} else if (cdq->tpt_efd_ctx) {
+		/* Controller will one-shot AEN when more entries are added */
+		WRITE_ONCE(cdq->pending_tpt, 1);
+		nvme_kick_cdq(cdq);
+	}
 	return copied_nbyte;
 
 err_out:
@@ -404,6 +427,31 @@ static int nvme_create_cdqfd(struct cdq_nvme_queue *cdq, int *cdq_fdno)
 	return 0;
 }
 
+static void nvme_put_cdq_tpt(struct cdq_nvme_queue *cdq)
+{
+	if (cdq->tpt_efd_ctx)
+		eventfd_ctx_put(cdq->tpt_efd_ctx);
+	cdq->tpt_efd_ctx = NULL;
+}
+
+static int nvme_get_cdq_tpt(struct cdq_nvme_queue *cdq, const int tpt_fd)
+{
+	struct eventfd_ctx *tmp;
+
+	if (tpt_fd <= 0)
+		return 0;
+
+	/* put the old one */
+	nvme_put_cdq_tpt(cdq);
+
+	tmp = eventfd_ctx_fdget(tpt_fd);
+	if (IS_ERR(tmp))
+		return -EINVAL;
+
+	cdq->tpt_efd_ctx = tmp;
+	return 0;
+}
+
 static int nvme_submit_delete_cdq_cmd(const struct cdq_nvme_queue *cdq)
 {
 	struct nvme_command c = {
@@ -450,6 +498,8 @@ static void nvme_delete_cdq_host(struct cdq_nvme_queue *cdq)
 
 	WRITE_ONCE(cdq->valid_mem, false);
 
+	nvme_put_cdq_tpt(cdq);
+
 	nvme_release_cdq_backing(cdq);
 	nvme_cdq_put(cdq);
 }
@@ -461,6 +511,22 @@ void nvme_delete_cdq(struct cdq_nvme_queue *cdq)
 }
 EXPORT_SYMBOL_GPL(nvme_delete_cdq);
 
+int nvme_handle_cdq_aen_tpevent(struct nvme_ctrl *ctrl, u32 event_param)
+{
+	u16 cdq_id = event_param & NVME_FEAT_CDQ_ID_MASK;
+	struct cdq_nvme_queue *cdq;
+
+	cdq = xa_load(&ctrl->cdqs, cdq_id);
+	if (xa_is_err(cdq))
+		return xa_err(cdq);
+	if (!cdq->tpt_efd_ctx)
+		return -EINVAL;
+
+	eventfd_signal(cdq->tpt_efd_ctx);
+
+	return 0;
+}
+
 static int nvme_submit_create_cdq_cmd(struct cdq_nvme_queue *cdq)
 {
 	int ret;
@@ -490,7 +556,7 @@ static int nvme_submit_create_cdq_cmd(struct cdq_nvme_queue *cdq)
 	return ret;
 }
 
-int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id)
+int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id, const int tpt_fd)
 {
 	u64 size_nbyte = (u64)entry_nr * NVME_CDQ_MQ_ENTRY_NRBYTES;
 	struct cdq_nvme_queue *cdq = NULL;
@@ -518,10 +584,14 @@ int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id)
 	kref_init(&cdq->ref);
 	nvme_get_ctrl(cdq->ctrl);
 
-	ret = nvme_submit_create_cdq_cmd(cdq);
+	ret = nvme_get_cdq_tpt(cdq, tpt_fd);
 	if (ret)
 		goto del_cdqmem;
 
+	ret = nvme_submit_create_cdq_cmd(cdq);
+	if (ret)
+		goto put_tpt;
+
 	WRITE_ONCE(cdq->valid_mem, true);
 
 	ret = xa_insert(&cdq->ctrl->cdqs, cdq->id, cdq, GFP_KERNEL);
@@ -546,6 +616,9 @@ int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id)
 	if (nvme_submit_delete_cdq_cmd(cdq))
 		WARN_ONCE(1, "Failed delete CDQ (id: %d)", cdq->id);
 
+put_tpt:
+	nvme_put_cdq_tpt(cdq);
+
 del_cdqmem:
 	/* puts the ref acquired by kref_init */
 	nvme_release_cdq_backing(cdq);
diff --git a/drivers/nvme/host/cdq.h b/drivers/nvme/host/cdq.h
index 893aeefb2dfc2c25f390e43eb508067b34dce31f..2958c6b92b1312930414b8466690aa7c0eb57754 100644
--- a/drivers/nvme/host/cdq.h
+++ b/drivers/nvme/host/cdq.h
@@ -60,6 +60,9 @@ struct cdq_nvme_queue {
 	/* Last acked CDQ head update. Trails host_head.*/
 	u32 cntl_head;
 
+	/* ETPT offset to arm on next set-feature send, 0 = none */
+	u32 pending_tpt;
+
 	u8 phase_bit;
 
 	/* sf_* controlls if the feature set cmd is done or is still inflight */
@@ -68,6 +71,9 @@ struct cdq_nvme_queue {
 
 	/* Manage refs for read FD and controller xarray */
 	struct kref ref;
+
+	/* Has a value if user setup an event fd for AEN tpt events */
+	struct eventfd_ctx *tpt_efd_ctx;
 };
 
 /*
@@ -83,7 +89,7 @@ void nvme_free_cdq(struct kref *ref);
  *    - Calls nvme_free_cdq if there are no more refs
  */
 void nvme_delete_cdq(struct cdq_nvme_queue *cdq);
-int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id);
+int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id, int tpt_fd);
 
 static inline void nvme_cdq_get(struct cdq_nvme_queue *cdq)
 {
@@ -97,5 +103,6 @@ static inline void nvme_cdq_put(struct cdq_nvme_queue *cdq)
 
 void nvme_delete_cdqs_host(struct nvme_ctrl *ctrl);
 void nvme_free_cdqs(struct nvme_ctrl *ctrl);
+int nvme_handle_cdq_aen_tpevent(struct nvme_ctrl *ctrl, u32 event_param);
 
 #endif /* _NVME_CDQ_H */
diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index fbaa2e065ab846e4700cddd7ae9f30a52e8a2cd9..bf6daeb0176fa69f1609280a8c7db89dadf43161 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -4765,7 +4765,8 @@ static bool nvme_handle_aen_oneshot(struct nvme_ctrl *ctrl, u32 result, u32 even
 
 	switch (aer_subtype) {
 	case NVME_AER_ONE_SHOT_CDQ_TAIL_PTR:
-		WARN_ONCE(1, "CDQ Tail Pointer one shot event ignored");
+		if (nvme_handle_cdq_aen_tpevent(ctrl, event_param))
+			WARN_ONCE(1, "Error handling CDQ AEN oneshot");
 		break;
 	case NVME_AER_ONE_SHOT_CDQ_FULL:
 		WARN_ONCE(1, "CDQ Full Error one shot event ignored");
diff --git a/include/linux/nvme.h b/include/linux/nvme.h
index 7cabedce022eda98fff789596682f257203e3b45..3c100fae1a4bd2a1f43fe3264680214194d2d262 100644
--- a/include/linux/nvme.h
+++ b/include/linux/nvme.h
@@ -1746,6 +1746,7 @@ enum {
 
 enum {
 	NVME_FEAT_CDQ_ID_MASK = GENMASK(15, 0),
+	NVME_FEAT_CDQ_ETPT_MASK = GENMASK(31, 31),
 };
 
 struct nvme_supported_log {

-- 
2.50.1

