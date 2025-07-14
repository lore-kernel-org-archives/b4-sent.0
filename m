From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 14 Jul 2025 11:15:36 +0200
Subject: [PATCH RFC 5/8] nvme: Add function to delete CDQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-jag-cdq-v1-5-01e027d256d5@kernel.org>
References: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
In-Reply-To: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: Klaus Jensen <k.jensen@samsung.com>, linux-nvme@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2669;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=h/8HKJiIxonpUreNA5H+hoWGCKVY95KaVnm3Y8PyTeQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGh0yuudcGZUR2uVvVZVbTvw7vHJi5lLEu15d
 lrtXTGNT5iAAYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJodMrrAAoJELqXzVK3
 lkFPgA4MAJnh8BX1id2J+lN8ZFOg/K6xgneL3zZWCqjDcUOU1mvQsFqK1ymrCwSHqfA/4HcwV5A
 vdKcwXkvwNRfuEA7u7IsQG07hccZ1NKIVv0lwyPIlAjmoqL2RxrviO+RLOVRckf2ce4Dka4+N69
 eh3zYsfP2G0K9Gjc0kxt5PcZ4X+lgE0o1+m9fdS3R5smtjlfp33mmM0GpFqSadzML8HmmloMqdv
 9S2A0Ss8DVuK6HQl4j+ulYPUX+7l67hDSvM6m/PVNC6A6L7fCu/JdUnMQrjmeWn3nmJ1KXRDbEv
 LjMHmPDdftztDRvHLLuXvqvAxj1nEnNpWHqk1uPG3+A9fCC/HK8GAj9Z128CU8HuwgLJ6HEvOcO
 5a+S6YWfCi6hKsz/5vUhaVPQvhQbKCTNw+kWTaxQZL2B0z3yYzcmCzktP3xtCpeaMruF5R6m+8k
 FEZNOYkcX/c1spi/xH+npL322AklGng6uFcyd91Nf9GlU0CU9mUW69t7nNtLmxuJSF24u0oVv5+
 AE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The delete function frees the memory held by the CDQ pointer, removes it
from the xarray and submits a NVME command informing the controller of
the delete. Call cdq delete on nvme_free_ctrl.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c | 36 ++++++++++++++++++++++++++++++++++++
 drivers/nvme/host/nvme.h |  1 +
 2 files changed, 37 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 81b7183a4e3167290e68dc2eb26a8dbcd88c7924..427e482530bdb5c7124d1230f35693ba756ce4d9 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -1435,6 +1435,41 @@ int nvme_cdq_create(struct nvme_ctrl *ctrl, struct nvme_command *c,
 }
 EXPORT_SYMBOL_GPL(nvme_cdq_create);
 
+int nvme_cdq_delete(struct nvme_ctrl *ctrl, const u16 cdq_id)
+{
+	int ret;
+	struct cdq_nvme_queue *cdq;
+	struct nvme_command c = { };
+
+	cdq = xa_erase(&ctrl->cdqs, cdq_id);
+	if (!cdq)
+		return -EINVAL;
+
+	c.cdq.opcode = nvme_admin_cdq;
+	c.cdq.sel = NVME_CDQ_SEL_DELETE_CDQ;
+	c.cdq.delete.cdqid = cdq->cdq_id;
+
+	ret = __nvme_submit_sync_cmd(ctrl->admin_q, &c, NULL, NULL, 0, NVME_QID_ANY, 0);
+	if (ret)
+		return ret;
+
+	nvme_cdq_free(ctrl, cdq);
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(nvme_cdq_delete);
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
@@ -5029,6 +5064,7 @@ static void nvme_free_ctrl(struct device *dev)
 	if (!subsys || ctrl->instance != subsys->instance)
 		ida_free(&nvme_instance_ida, ctrl->instance);
 	nvme_free_cels(ctrl);
+	nvme_free_cdqs(ctrl);
 	nvme_mpath_uninit(ctrl);
 	cleanup_srcu_struct(&ctrl->srcu);
 	nvme_auth_stop(ctrl);
diff --git a/drivers/nvme/host/nvme.h b/drivers/nvme/host/nvme.h
index ddec5b44fe022831280458ed9fc1cb1ed11633b7..07a1a9e4772281d68d0ade0423372a35f9f7055e 100644
--- a/drivers/nvme/host/nvme.h
+++ b/drivers/nvme/host/nvme.h
@@ -1211,6 +1211,7 @@ int nvme_cdq_create(struct nvme_ctrl *ctrl, struct nvme_command *c,
 		    const u32 entry_nr, const u32 entry_nbyte,
 		    uint cdqp_offset, uint cdqp_mask,
 		    u16 *cdq_id, int *cdq_fd);
+int nvme_cdq_delete(struct nvme_ctrl *ctrl, const u16 cdq_id);
 struct nvme_ctrl *nvme_ctrl_from_file(struct file *file);
 struct nvme_ns *nvme_find_get_ns(struct nvme_ctrl *ctrl, unsigned nsid);
 bool nvme_get_ns(struct nvme_ns *ns);

-- 
2.47.2

