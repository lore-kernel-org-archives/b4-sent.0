From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 24 Jun 2025 22:05:52 +0200
Subject: [PATCH RFC 5/7] nvme: Add function to delete CDQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-jag-cdq-v1-5-6d88476c9165@kernel.org>
References: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
In-Reply-To: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
To: joshi.k@samsung.com
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2687;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=+/EYd8SR0bVRki/fhRjiv3cR1okt297DyLyfHH9/J+0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhbBSDoo0KqGWmuo2UtERBgq0uzH88sz/5Ph
 ozPw2KGlP6+FokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoWwUgAAoJELqXzVK3
 lkFPRdAL+gMpgcLAjMWkqDdSyrRRCJNVl8Bx1X41sot7uwHsKVaFiuHWFQN5A3KSO19HsjNJjxA
 3EEXcrAlPLtnodKCbmHveXvG7E1NkZmKhtNn4ywtP6IwM/VUf5+AuV3dSVvHPvjTA5KQkwuX84s
 9qIVoJ6fd9QarUXKmc+4hV4kzNVKOLdOg0U0TSyhGkAB79m6NFyGrgGTs3+3zkXmk7zge7f0Uk+
 1MyX7nZZkLuQ0iQNMlj7QDJTMJfilXiU/z7AoO9UIAJSePHPMz/z3m2zQyzqNZaWTs9RPBgj0QC
 GspBaj41W1GXBBQ/cbnqferuFHQWmuc6iaxuWpWHFfRaXZMQ5Kwd18T+30TKOfBSTlvBSZGd8Xl
 JPNqZkkwsusX2DEeNjRCsMsGvwIXc4f8NiouOiq6OvtHM1FTRn99o4V5/JVfhQrfR0HQ5LGZdGW
 SfuN41hYaAQhXZ/nNuo831Z7UA/odTufX3Smz9aEpw9VJ4wxUcVDc+ZGRRPp0j2jY4I3OV4Dfl7
 gw=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Besides freeing the memory held by the CDQ pointer, remove it from the
xarray and submit a NVME command informing the controller of the delete.
Also perform the delete when the nvme controller is being freed.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c | 36 ++++++++++++++++++++++++++++++++++++
 drivers/nvme/host/nvme.h |  1 +
 2 files changed, 37 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 710ad14fbab5849f06b0bc2190f3f905aacd039c..18ca88b6288fe12d8c4e0bfac5b42d09a7f36416 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -1459,6 +1459,41 @@ int nvme_cdq_create(struct nvme_ctrl *ctrl, struct nvme_command *c,
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
@@ -5053,6 +5088,7 @@ static void nvme_free_ctrl(struct device *dev)
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

