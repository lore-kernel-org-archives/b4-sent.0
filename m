From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Apr 2026 13:37:54 +0200
Subject: [PATCH RFC 4/5] nvme: Implement CDQ core functionality
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260424-jag-cdq-lkml-v1-4-d773343a717c@kernel.org>
References: <20260424-jag-cdq-lkml-v1-0-d773343a717c@kernel.org>
In-Reply-To: <20260424-jag-cdq-lkml-v1-0-d773343a717c@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=11713;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=03dIhM6pDJ5/ddT82ZomuEoboyghm3luwc7xkzLLs88=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGnrVivxNLZQykSGg3CE/47xTNKxYrOEd9nZf
 vOda17oyKYwHIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJp61YrAAoJELqXzVK3
 lkFP2rgMAJbWG0HCVpWSQ6yt2fAL2UfZYcpGbZAEeROPC/XSdN4bs9E3Ex6WXAsb94amuofT2hs
 EPJuiG1pRPneAJoiIe6Qo6/Qss/rOhyZNtzaZEh3ljWWEuFxnB0an6KlloMlCPRwZxhPl5XtLL8
 E7Cr3gQnoQmmoxc+jNrYwBQCD6/8fUuTe+vweaO4Fteys4meuuxVc3RiQqS0YlXkQNXXcRP45fd
 4vhA6A1ldF1XJBO7f/DlX9gF2UJdxl8ruE1awQXrvQWt8wohZa+CsuGSmuH1XBmS+gT9fyAD/nk
 nb78UEpqT+Cbv5O7YoOysw1X74mOMhVEg9AXni0pWdDS8HBEJzZLMWumFNXFDI4Tt4RmQAEL/0R
 fMMukadKvTNK8U5XJ0SzNuxD8Uu4JrQhA5DyptiCMqUzrvEwTadNb9NNfWuY6U0vw6rVNRXdOr/
 7FEVQAasLkGgfnEL/tDGHIkuVAjAzw8CmBd9gJKUkGb6owM5xMsFUEoUc9pGk0xlUF4JFt/86g5
 bg=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Controller Data Queue (CDQ) support to the NVMe driver. CDQs enable
efficient device-to-host data transfer through dedicated queues with
DMA-mapped user memory.

This patch implements:
- DMA mapping with user page pinning (nvme_cdq_map_dma_usr)
- PRP list allocation for discontiguous memory (nvme_cdq_alloc_prp_list)
- CDQ create/delete commands (nvme_cdq_create, nvme_cdq_delete)
- Tail pointer event notification via eventfd (nvme_cdq_set_tpt)
- Async event notification handling for CDQ events
- xarray-based CDQ instance management
- Integration into controller init/free paths
- Add function declarations for CDQ lifecycle management:
  nvme_cdq_create(), nvme_cdq_delete(), nvme_cdq_set_tpt()

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c | 306 +++++++++++++++++++++++++++++++++++++++++++++--
 drivers/nvme/host/nvme.h |   5 +
 2 files changed, 304 insertions(+), 7 deletions(-)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index be4807591d2d80d228c10e3c78b6b7dc371b3865..1bcdf328b0edf0ede7a799a965fd0b539404e3c6 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -23,6 +23,7 @@
 #include <linux/pm_qos.h>
 #include <linux/ratelimit.h>
 #include <linux/unaligned.h>
+#include <linux/eventfd.h>
 
 #include "nvme.h"
 #include "fabrics.h"
@@ -1252,6 +1253,298 @@ u32 nvme_passthru_start(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u8 opcode)
 }
 EXPORT_SYMBOL_NS_GPL(nvme_passthru_start, "NVME_TARGET_PASSTHRU");
 
+static void nvme_cdq_unmap_dma_usr(struct nvme_ctrl *ctrl, struct cdq_nvme_queue *cdq)
+{
+	dma_unmap_sgtable(ctrl->dev, &cdq->sgt, DMA_BIDIRECTIONAL, 0);
+	sg_free_table(&cdq->sgt);
+	unpin_user_pages(cdq->pages, cdq->nr_pages);
+	kfree(cdq->pages);
+}
+
+/* nvme_cdq_alloc_from_usr - Make user virtual memory DMAable */
+static int nvme_cdq_map_dma_usr(struct nvme_ctrl *ctrl, struct cdq_nvme_queue *cdq,
+				const u32 size_nbytes, unsigned long uaddr)
+{
+	int ret = -ENOMEM;
+	struct page **pages;
+
+	if (!PAGE_ALIGN(uaddr))
+		return -EINVAL;
+
+	cdq->nr_pages = (size_nbytes + PAGE_SIZE - 1) >> PAGE_SHIFT;
+	pages = kvmalloc_array(cdq->nr_pages, sizeof(struct page *), GFP_KERNEL);
+	if (!pages)
+		return -ENOMEM;
+
+	mmap_read_lock(current->mm);
+	ret = pin_user_pages(uaddr, cdq->nr_pages, FOLL_WRITE | FOLL_LONGTERM, pages);
+	if (ret != cdq->nr_pages) {
+		if (ret > 0)
+			unpin_user_pages(pages, ret);
+		ret = -EFAULT;
+		mmap_read_unlock(current->mm);
+		goto free_pages;
+	}
+	mmap_read_unlock(current->mm);
+
+	ret = sg_alloc_table_from_pages_segment(&cdq->sgt, pages, cdq->nr_pages,
+						0, size_nbytes, PAGE_SIZE, GFP_KERNEL);
+	if (ret)
+		goto unpin_pages;
+
+	ret = dma_map_sgtable(ctrl->dev, &cdq->sgt, DMA_BIDIRECTIONAL, 0);
+	if (ret)
+		goto free_sgt;
+
+	cdq->pages = pages;
+
+	return 0;
+
+free_sgt:
+	sg_free_table(&cdq->sgt);
+
+unpin_pages:
+	unpin_user_pages(pages, cdq->nr_pages);
+
+free_pages:
+	kvfree(pages);
+
+	return ret;
+}
+
+static void nvme_cdq_free_prp_lists(struct nvme_ctrl *ctrl,
+				    struct cdq_nvme_queue *cdq)
+{
+	for (int i = 0; i < cdq->nr_prp_lists; ++i) {
+		if (cdq->prp_lists[i])
+			dma_free_coherent(ctrl->dev, PAGE_SIZE,
+					  cdq->prp_lists[i],
+					  cdq->prp_lists_dma[i]);
+	}
+}
+static int nvme_cdq_alloc_prp_single(struct nvme_ctrl *ctrl, struct cdq_nvme_queue *cdq)
+{
+	cdq->nr_prp_lists = 0;
+	memset(cdq->prp_lists, 0, sizeof(cdq->prp_lists));
+	cdq->prp_lists_dma[0] = sg_dma_address(cdq->sgt.sgl);
+	cdq->prp_lists_dma[1] = 0;
+	return 0;
+}
+
+static int nvme_cdq_alloc_prp_list(struct nvme_ctrl *ctrl, struct cdq_nvme_queue *cdq)
+{
+	unsigned int i, prp_list_idx = 0;
+	struct scatterlist *sg;
+	u64 *prp_list, *prp_list_tmp;
+	dma_addr_t prp_list_tmp_dma;
+
+	prp_list = dma_alloc_coherent(ctrl->dev, PAGE_SIZE, &prp_list_tmp_dma, GFP_KERNEL);
+	if (!prp_list)
+		return -ENOMEM;
+
+	cdq->prp_lists[0] = prp_list;
+	cdq->prp_lists_dma[0] = prp_list_tmp_dma;
+	cdq->nr_prp_lists = 1;
+
+	for_each_sgtable_dma_sg(&cdq->sgt, sg, i) {
+		if (prp_list_idx == PAGE_SIZE >> 3) {
+			if (cdq->nr_prp_lists == MAX_NR_CDQ_PRPS)
+				goto prps_err;
+
+			prp_list_tmp = dma_alloc_coherent(ctrl->dev,
+					PAGE_SIZE, &prp_list_tmp_dma, GFP_KERNEL);
+			if (!prp_list_tmp)
+				goto prps_err;
+
+			cdq->prp_lists_dma[cdq->nr_prp_lists] = prp_list_tmp_dma;
+			cdq->prp_lists[cdq->nr_prp_lists++] = prp_list_tmp;
+
+			prp_list = prp_list_tmp;
+			prp_list_idx = 0;
+		}
+		prp_list[prp_list_idx++] = sg_dma_address(sg);
+	}
+
+	return 0;
+
+prps_err:
+	nvme_cdq_free_prp_lists(ctrl, cdq);
+
+	return -EFAULT;
+}
+
+static int nvme_cdq_cmd_delete(struct nvme_ctrl *ctrl, const u16 cdq_id)
+{
+	struct nvme_command c = {
+		.cdq.opcode = nvme_admin_cdq,
+		.cdq.sel = NVME_CDQ_SEL_DELETE_CDQ,
+		.cdq.dw11.cdqid = cdq_id
+	};
+
+	return __nvme_submit_sync_cmd(ctrl->admin_q, &c, NULL, NULL, 0, NVME_QID_ANY, 0);
+}
+
+static int nvme_cdq_cmd_create(struct cdq_nvme_queue *cdq, const u16 mos, const u16 cqs,
+			       const u16 dw11_flags)
+{
+	int ret;
+	union nvme_result result = { };
+	struct nvme_command c = {
+		.cdq.opcode = nvme_admin_cdq,
+		.cdq.sel = NVME_CDQ_SEL_CREATE_CDQ,
+		.cdq.mos = cpu_to_le16(mos),
+		.cdq.dw11.cqs = cpu_to_le16(cqs),
+		.cdq.cdqsize = cdq->size_nbyte >> 2, // >>2: size is in dwords
+		.cdq.dw11.flags = cpu_to_le16(dw11_flags),
+		.cdq.prp1 = cdq->prp_lists_dma[0]
+	};
+
+	ret = __nvme_submit_sync_cmd(cdq->ctrl->admin_q, &c, &result, NULL, 0, NVME_QID_ANY, 0);
+	if (ret)
+		return ret;
+
+	cdq->cdq_id = le16_to_cpu(result.u16);
+
+	return ret;
+}
+
+int nvme_cdq_set_tpt(struct nvme_ctrl *ctrl, u16 cdq_id, const int tpt_fd)
+{
+
+	struct cdq_nvme_queue *cdq;
+
+	if (tpt_fd < 0)
+		return -EINVAL;
+
+	cdq = xa_load(&ctrl->cdqs, cdq_id);
+	if (xa_is_err(cdq))
+		return -EINVAL;
+
+	if (cdq->tpt_efd_ctx)
+		eventfd_ctx_put(cdq->tpt_efd_ctx);
+
+	cdq->tpt_efd_ctx = eventfd_ctx_fdget(tpt_fd);
+	if (IS_ERR(cdq->tpt_efd_ctx))
+		return -EINVAL;
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(nvme_cdq_set_tpt);
+
+int nvme_cdq_create(struct nvme_ctrl *ctrl, const u16 mos, const u16 cqs,
+		    unsigned long uaddr, const u32 size_nbyte, u16 *cdq_id)
+{
+	int ret;
+	u16 d11_flags;
+	struct cdq_nvme_queue *cdq, *xa_ret;
+
+	cdq = kzalloc(sizeof(*cdq), GFP_KERNEL);
+	if (!cdq)
+		return -ENOMEM;
+
+	cdq->ctrl = ctrl;
+	cdq->size_nbyte = size_nbyte;
+
+	ret = nvme_cdq_map_dma_usr(ctrl, cdq, size_nbyte, uaddr);
+	if (ret)
+		goto err_cdq_free;
+
+	if (cdq->sgt.nents > 1) {
+		d11_flags = NVME_CDQ_CFG_PC_DISCONT;
+		ret = nvme_cdq_alloc_prp_list(ctrl, cdq);
+	} else {
+		d11_flags = NVME_CDQ_CFG_PC_CONT;
+		ret = nvme_cdq_alloc_prp_single(ctrl, cdq);
+	}
+
+	if (ret)
+		goto err_cdq_unmap_dma;
+
+	ret = nvme_cdq_cmd_create(cdq, mos, cqs, d11_flags);
+	if (ret)
+		goto err_cdq_free_prp;
+
+	xa_ret = xa_store(&ctrl->cdqs, cdq->cdq_id, cdq, GFP_KERNEL);
+	if (xa_is_err(xa_ret)) {
+		ret = xa_err(xa_ret);
+		goto err_cmd_del;
+	}
+
+	*cdq_id = cdq->cdq_id;
+
+	return 0;
+
+err_cmd_del:
+	nvme_cdq_cmd_delete(ctrl, cdq->cdq_id);
+
+err_cdq_free_prp:
+	nvme_cdq_free_prp_lists(ctrl, cdq);
+
+err_cdq_unmap_dma:
+	cdq_id = NULL;
+	nvme_cdq_unmap_dma_usr(ctrl, cdq);
+
+err_cdq_free:
+	kfree(cdq);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(nvme_cdq_create);
+
+int nvme_cdq_delete(struct nvme_ctrl *ctrl, const u16 cdq_id)
+{
+	int ret;
+	struct cdq_nvme_queue *cdq;
+
+	cdq = xa_load(&ctrl->cdqs, cdq_id);
+	if (xa_is_err(cdq))
+		return -EINVAL;
+
+	if (cdq->tpt_efd_ctx)
+		eventfd_ctx_put(cdq->tpt_efd_ctx);
+
+	ret = nvme_cdq_cmd_delete(ctrl, cdq_id);
+	if (ret)
+		return ret;
+
+	cdq = xa_erase(&ctrl->cdqs, cdq_id);
+	if (!cdq)
+		return -EINVAL;
+
+	nvme_cdq_free_prp_lists(ctrl, cdq);
+	nvme_cdq_unmap_dma_usr(ctrl, cdq);
+
+	kfree(cdq);
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(nvme_cdq_delete);
+
+static int nvme_cdq_handle_aen_tpevent(struct nvme_ctrl *ctrl, u32 event_param)
+{
+	u16 cdq_id = event_param & NVME_FEAT_CDQ_ID_MASK;
+	struct cdq_nvme_queue *cdq;
+
+	cdq = xa_load(&ctrl->cdqs, cdq_id);
+	if (!cdq || xa_is_err(cdq) || !cdq->tpt_efd_ctx)
+		return false;
+
+	eventfd_signal(cdq->tpt_efd_ctx);
+
+	return true;
+}
+
+static void nvme_free_cdqs(struct nvme_ctrl *ctrl)
+{
+	struct cdq_nvme_queue *cdq;
+	unsigned long i;
+
+	xa_for_each(&ctrl->cdqs, i, cdq)
+		nvme_cdq_delete(ctrl, i);
+
+	xa_destroy(&ctrl->cdqs);
+}
+
 void nvme_passthru_end(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u32 effects,
 		       struct nvme_command *cmd, int status)
 {
@@ -4751,9 +5044,9 @@ static bool nvme_handle_aen_oneshot(struct nvme_ctrl *ctrl, u32 result, u32 even
 {
 	u32 aer_subtype = nvme_aer_subtype(result);
 
-	/* Will be extended to handle specific one-shot event types */
 	if (aer_subtype == NVME_AER_ONE_SHOT_CDQ_TAIL_PTR)
-		return -ENOSYS;
+		return nvme_cdq_handle_aen_tpevent(ctrl, event_param);
+
 	return false;
 }
 
@@ -4819,13 +5112,9 @@ void nvme_complete_async_event(struct nvme_ctrl *ctrl, __le16 status,
 		requeue = nvme_handle_aen_notice(ctrl, result);
 		break;
 	case NVME_AER_ONE_SHOT:
-		/*
-		 * One-shot events like CDQ tail pointer events.
-		 * Extract event parameter from upper 32 bits.
-		 */
+		/* One-shot events like CDQ tail pointer events. */
 		event_param = le64_to_cpu(res->u64) >> 32;
 		requeue = nvme_handle_aen_oneshot(ctrl, result, event_param);
-		trace_nvme_async_event(ctrl, result);
 		break;
 	case NVME_AER_ERROR:
 		/*
@@ -5064,6 +5353,7 @@ static void nvme_free_ctrl(struct device *dev)
 	if (!subsys || ctrl->instance != subsys->instance)
 		ida_free(&nvme_instance_ida, ctrl->instance);
 	nvme_free_cels(ctrl);
+	nvme_free_cdqs(ctrl);
 	nvme_mpath_uninit(ctrl);
 	cleanup_srcu_struct(&ctrl->srcu);
 	nvme_auth_stop(ctrl);
@@ -5110,6 +5400,7 @@ int nvme_init_ctrl(struct nvme_ctrl *ctrl, struct device *dev,
 	mutex_init(&ctrl->scan_lock);
 	INIT_LIST_HEAD(&ctrl->namespaces);
 	xa_init(&ctrl->cels);
+	xa_init(&ctrl->cdqs);
 	ctrl->dev = dev;
 	ctrl->ops = ops;
 	ctrl->quirks = quirks;
@@ -5375,6 +5666,7 @@ static inline void _nvme_check_size(void)
 	BUILD_BUG_ON(sizeof(struct nvme_rotational_media_log) != 512);
 	BUILD_BUG_ON(sizeof(struct nvme_dbbuf) != 64);
 	BUILD_BUG_ON(sizeof(struct nvme_directive_cmd) != 64);
+	BUILD_BUG_ON(sizeof(struct nvme_cdq) != 64);
 	BUILD_BUG_ON(sizeof(struct nvme_feat_host_behavior) != 512);
 }
 
diff --git a/drivers/nvme/host/nvme.h b/drivers/nvme/host/nvme.h
index 30d5052c7728c0d5c5e8772ff531bc672e96940f..2e8bbd3a7394303f6c803b0d5a457abb6d1b485d 100644
--- a/drivers/nvme/host/nvme.h
+++ b/drivers/nvme/host/nvme.h
@@ -1285,6 +1285,11 @@ u32 nvme_passthru_start(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u8 opcode);
 int nvme_execute_rq(struct request *rq, bool at_head);
 void nvme_passthru_end(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u32 effects,
 		       struct nvme_command *cmd, int status);
+int nvme_cdq_create(struct nvme_ctrl *ctrl, const u16 mos, const u16 cqs,
+		    unsigned long uaddr, const u32 size_nbyte,
+		    u16 *cdq_id);
+int nvme_cdq_delete(struct nvme_ctrl *ctrl, const u16 cdq_id);
+int nvme_cdq_set_tpt(struct nvme_ctrl *ctrl, u16 cdq_id, const int tpt_fd);
 struct nvme_ctrl *nvme_ctrl_from_file(struct file *file);
 struct nvme_ns *nvme_find_get_ns(struct nvme_ctrl *ctrl, unsigned nsid);
 bool nvme_get_ns(struct nvme_ns *ns);

-- 
2.50.1

