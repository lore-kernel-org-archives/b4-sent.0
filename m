From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 24 Jun 2025 22:05:51 +0200
Subject: [PATCH RFC 4/7] nvme: Add function to create a CDQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-jag-cdq-v1-4-6d88476c9165@kernel.org>
References: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
In-Reply-To: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
To: joshi.k@samsung.com
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3913;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=5T4wQYOae7YNgVSRghoozLUTA5utfIc03ICqA7bo9kY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhbBR+KwFGDR39Z4lAf4H4oXj7AbAceR6n6u
 72rrkj2MDJkTIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoWwUfAAoJELqXzVK3
 lkFPoooL/3fqpIr9ymovD27aY71yJhJ7bsGgMTtG6dzaH/nQF8uHKFBV/0yLjpWOEoITZb33AOE
 mnLsmYo3b6QNAjiuhci4TD7dxEuA9DTYD4RlLpQthqXVy+7uXab/ipaLeMmTRk3y/0hEhsAu2d/
 dkmrBdhlukQlhcozAmMtJKj8lAcgoMFxysA22w+FSa55erkQnZ+/xPQUOAv0U739WlCmlkegItc
 emj1gNXSgyMBqCwNPnJRuB2NKFI99MzRibRhE2b3vCx52JxLfeOu3V3PdcVX7tRZez3VhQEHJdP
 rcLwAsI8ayyp3gE0fsnwUCWlhbODh23mbUI9KE6TZDm0Q3bVdNQvoHl4jp6/79DUh7oteKuGRvx
 BH9qoajhfu8cdZTBnjiTNTwTWccESLSnEEDYop835MD5cY133zZHepcirteaB6HxBgX41Sh9aXg
 LkAasg3ovDiO7ZYXZuZNRx+cKjfI/AZw3c+HO1E9te8kMORfGW+ZSdKFc7ggoc6KtyGTAaAUqQ5
 Ik=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CDQ creation allocates DMAable memory and forwards the address to
the NVME controller for queue creation. After the NVME admin command
returns the CDQ id, the CDQ object is stored in the controller CDQ
xarray and the file descriptor is setup ready to be used.

The CDQ id is returned in cdq_id and the file descriptor is set in
cdq_fd.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c | 82 ++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/nvme/host/nvme.h |  4 +++
 2 files changed, 86 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index bffeb329b5c95e74d2b255296dcacfb683030867..710ad14fbab5849f06b0bc2190f3f905aacd039c 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -1377,6 +1377,88 @@ static int nvme_cdq_fd(struct cdq_nvme_queue *cdq, int *fdno)
 	return ret;
 }
 
+static int nvme_cdq_alloc(struct nvme_ctrl *ctrl, struct cdq_nvme_queue **cdq,
+			  u32 entry_nr, u32 entry_nbyte)
+{
+	struct cdq_nvme_queue *ret_cdq = kzalloc(sizeof(*ret_cdq), GFP_KERNEL);
+
+	if (!ret_cdq)
+		return -ENOMEM;
+
+	ret_cdq->entries = dma_alloc_coherent(ctrl->dev,
+					      entry_nr * entry_nbyte,
+					      &ret_cdq->entries_dma_addr,
+					      GFP_KERNEL);
+	if (!ret_cdq->entries) {
+		kfree(ret_cdq);
+		return -ENOMEM;
+	}
+
+	*cdq = ret_cdq;
+
+	return 0;
+}
+
+static void nvme_cdq_free(struct nvme_ctrl *ctrl, struct cdq_nvme_queue *cdq)
+{
+	dma_free_coherent(ctrl->dev, cdq->entry_nr * cdq->entry_nbyte,
+			  cdq->entries, cdq->entries_dma_addr);
+	kfree(cdq);
+}
+
+
+int nvme_cdq_create(struct nvme_ctrl *ctrl, struct nvme_command *c,
+		    const u32 entry_nr, const u32 entry_nbyte,
+		    uint cdqp_offset, uint cdqp_mask,
+		    u16 *cdq_id, int *cdq_fd)
+{
+	int ret, fdno;
+	struct cdq_nvme_queue *cdq, *xa_ret;
+	union nvme_result result = { };
+
+	ret = nvme_cdq_alloc(ctrl, &cdq, entry_nr, entry_nbyte);
+	if (ret)
+		return ret;
+	c->cdq.prp1 = cdq->entries_dma_addr;
+
+	ret = __nvme_submit_sync_cmd(ctrl->admin_q, c, &result, NULL, 0, NVME_QID_ANY, 0);
+	if (ret)
+		goto err_cdq_free;
+
+	cdq->cdq_id = le16_to_cpu(result.u16);
+	cdq->entry_nbyte = entry_nbyte;
+	cdq->entry_nr = entry_nr;
+	cdq->ctrl = ctrl;
+	cdq->cdqp_offset = cdqp_offset;
+	cdq->cdqp_mask = cdqp_mask;
+
+	xa_ret = xa_store(&ctrl->cdqs, cdq->cdq_id, cdq, GFP_KERNEL);
+	if (xa_is_err(xa_ret)) {
+		ret = xa_err(xa_ret);
+		goto err_cdq_free;
+	}
+
+	ret = nvme_cdq_fd(cdq, &fdno);
+	if (ret)
+		goto err_cdq_erase;
+
+	*cdq_id = cdq->cdq_id;
+	*cdq_fd = fdno;
+
+	return 0;
+
+err_cdq_erase:
+	xa_erase(&ctrl->cdqs, cdq->cdq_id);
+
+err_cdq_free:
+	cdq_id = NULL;
+	cdq_fd = NULL;
+	nvme_cdq_free(ctrl, cdq);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(nvme_cdq_create);
+
 void nvme_passthru_end(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u32 effects,
 		       struct nvme_command *cmd, int status)
 {
diff --git a/drivers/nvme/host/nvme.h b/drivers/nvme/host/nvme.h
index 800970a0bb87f7a3b6e855f56a2493a7deed1ecd..ddec5b44fe022831280458ed9fc1cb1ed11633b7 100644
--- a/drivers/nvme/host/nvme.h
+++ b/drivers/nvme/host/nvme.h
@@ -1207,6 +1207,10 @@ u32 nvme_passthru_start(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u8 opcode);
 int nvme_execute_rq(struct request *rq, bool at_head);
 void nvme_passthru_end(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u32 effects,
 		       struct nvme_command *cmd, int status);
+int nvme_cdq_create(struct nvme_ctrl *ctrl, struct nvme_command *c,
+		    const u32 entry_nr, const u32 entry_nbyte,
+		    uint cdqp_offset, uint cdqp_mask,
+		    u16 *cdq_id, int *cdq_fd);
 struct nvme_ctrl *nvme_ctrl_from_file(struct file *file);
 struct nvme_ns *nvme_find_get_ns(struct nvme_ctrl *ctrl, unsigned nsid);
 bool nvme_get_ns(struct nvme_ns *ns);

-- 
2.47.2

