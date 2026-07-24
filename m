From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Jul 2026 13:11:03 +0200
Subject: [PATCH RFC v2 09/14] nvme: Coordinate CDQ backing mem and CDQ FD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-jag-cdq-lkml-v2-9-659a7449e849@kernel.org>
References: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
In-Reply-To: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2709;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=TK6sw5sLChDD2H14umlWrgyrMjWvsU5BCPObipz5PyY=;
 b=owJ4nAHsARP+kA0DAAoBupfNUreWQU8ByyZiAGpjSF6CUSvlQHseGsKAdm427Y9qEzQ/VUWdO
 AR/T7ClZ+UfjokBsgQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqY0heAAoJELqXzVK3
 lkFPx2ML+NaqLg199fgUV85XEXgknviUKpS8KqSiDa4eaaEHsvqN6v4ho19xSXVj0daHjpTZ5Jk
 p+OMxfcBkhqO1pPq/hdxQqh0t9+Eh+jxtO7XMwcArbCVTT5TU8u3eQd9+a+UBN3y1aMNiiX95V+
 ozbooV4le3S0VuMYsHleuBpO/kCqua25ogMJAH10dlYh/1SWqfs3GadVE1pIk2jKbbAOnbVwkN4
 nVZclnt5e1edlrwrFRkP25d1SPfPtaOTbQQQzM5AgDWBXLjaiZpWkjyVAJi/dcHdUIVattGsP5V
 oGcnIm4dnMJU0dXofgsiZMZrZfIEuN/r07KiS9dVNKqkxZdPXCAB6tUAKDrJ8834vIy7NV3e6kX
 6kXhYhV5KVJ8MgYfOk65opzSCRwes4LnT342ev+J8uI5zL1XEblM06T7SdbiBYHpDKyxMheTv+o
 tNSWAjMAT8u9waUneiS6N6+jbDdpuQu3HIzYiPtxz8Zw9tbtRWfU2syBMP8hO7gikstWGUuTPrB
 A==
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The user space file descriptor fails if the memory backing the
Controller Data Queue (CDQ) is not "valid". This can happen as part of
the controller tear-down procedure.

Test the valid_mem variable when reading the from the file descriptor.
Set on CDQ creation and unset when the CDQ is being deleted on the host
side.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/cdq.c | 20 ++++++++++++++++++--
 drivers/nvme/host/cdq.h |  3 +++
 2 files changed, 21 insertions(+), 2 deletions(-)

diff --git a/drivers/nvme/host/cdq.c b/drivers/nvme/host/cdq.c
index 0f01b58a9c3145faae83a81627fa5a93cfc03cf4..7fe08afa0d80db5f3d60993aba05624b5c59b309 100644
--- a/drivers/nvme/host/cdq.c
+++ b/drivers/nvme/host/cdq.c
@@ -184,6 +184,9 @@ static ssize_t nvme_cdq_fops_read(struct file *filep, char __user *buf,
 	if (nbytes > (cdq->size_nbyte))
 		return -EINVAL;
 
+	if (!READ_ONCE(cdq->valid_mem))
+		return -EINVAL;
+
 	/* CDQ traversal not implemented yet. */
 	return -EOPNOTSUPP;
 }
@@ -207,7 +210,16 @@ static const struct file_operations cdq_fops = {
 	.release	= nvme_cdq_fops_release,
 };
 
-__maybe_unused
+/* Should only handle cdq struct and ctrl kref */
+void nvme_free_cdq(struct kref *ref)
+{
+	struct cdq_nvme_queue *cdq = container_of(ref, struct cdq_nvme_queue, ref);
+
+	/* Drop the ctrl kref held since creation */
+	nvme_put_ctrl(cdq->ctrl);
+	kfree(cdq);
+}
+
 static int nvme_create_cdqfd(struct cdq_nvme_queue *cdq, int *cdq_fdno)
 {
 	int fdno;
@@ -276,8 +288,9 @@ static void nvme_delete_cdq_host(struct cdq_nvme_queue *cdq)
 	if (xa_erase(&ctrl->cdqs, cdq->id) != cdq)
 		return;
 
-	nvme_release_cdq_backing(cdq);
+	WRITE_ONCE(cdq->valid_mem, false);
 
+	nvme_release_cdq_backing(cdq);
 	nvme_cdq_put(cdq);
 }
 
@@ -342,11 +355,14 @@ int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id)
 	}
 
 	kref_init(&cdq->ref);
+	nvme_get_ctrl(cdq->ctrl);
 
 	ret = nvme_submit_create_cdq_cmd(cdq);
 	if (ret)
 		goto del_cdqmem;
 
+	WRITE_ONCE(cdq->valid_mem, true);
+
 	ret = xa_insert(&cdq->ctrl->cdqs, cdq->id, cdq, GFP_KERNEL);
 	if (ret)
 		goto del_cmd;
diff --git a/drivers/nvme/host/cdq.h b/drivers/nvme/host/cdq.h
index 773f93817d498784450eb0c8c9ab00a95f0657dc..aa9469af0c7ef08b9f8ebf93e468c7f892aee4b1 100644
--- a/drivers/nvme/host/cdq.h
+++ b/drivers/nvme/host/cdq.h
@@ -42,6 +42,9 @@ struct cdq_nvme_queue {
 	dma_addr_t prp_lists_dma[MAX_NR_CDQ_PRPS];
 	unsigned int nr_prp_lists;
 
+	/* True if mem for chunks and prps is valid */
+	bool valid_mem;
+
 	/* Manage refs for read FD and controller xarray */
 	struct kref ref;
 };

-- 
2.50.1

