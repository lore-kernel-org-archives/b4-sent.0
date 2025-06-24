From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 24 Jun 2025 22:05:54 +0200
Subject: [PATCH RFC 7/7] nvme: Connect CDQ ioctl to nvme driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-jag-cdq-v1-7-6d88476c9165@kernel.org>
References: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
In-Reply-To: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
To: joshi.k@samsung.com
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3354;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=8Uc5Kt3YKwvBpMl0ckKhTD03paROsmdOBY9mZi6DXFQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhbBSFE8zqyHPQcHSPusr8+jpIdaEKFQ9+Sj
 DryNNXNPEu0QokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoWwUhAAoJELqXzVK3
 lkFPudIL/iNir1MmshOHf/ebESR+Wid03zAa81fXyIRnAqbUsXGH6kXE6QgsyiivRhZrDewnoEI
 01BU2wqJ6bYy8rxbdKgHTrSHv2vOu1Py/lMs4V2pCv85Oc8mQNKjydco8vl7XC66/tpuD6dEZby
 GOf/tegsGDkiHqlzRtlf1Wjkkb+R/h3cM95y15U3JDi5G9uFbe3cjDc+F/i0/iTR+7Cbl6HpQtD
 /lYTordde3GJjGt66hxY9PLtsGaZ6Au+uOXG9s9PS+nKFF6qVUQaXY3iVYAz00jrgj2iYzuaef/
 TnDM07T3kJCkjt/cXdHzn3+Sb+RDO+J210qYRCaAa7yf2xEt9k8440V+w5yfGSIZkcx362rgkU0
 fVT9S0h3rYwq4IB2vD1uBEPPKLX5IMtN8McGaND/a5+d5MxcV0wc5MQBy6Eh7u96u0MwpDBTiNy
 hlnGVeCEX8QZb4aAPsjAZedNpZnuCVWqvRHzWJyioLPqMF0jCrMAsO0U/bFMoVihgUini3jopu6
 Kg=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When deleting, call the nvme_cdq_delete directly as there is no
additional preparation needed. Construct the nvme admin command to
create before sending it down to the driver; this effectively sets mos
and cqs among other variables. Once the controller has returned, set the
cdq_id and cdq_fd for the ioctl caller.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/ioctl.c | 59 ++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 58 insertions(+), 1 deletion(-)

diff --git a/drivers/nvme/host/ioctl.c b/drivers/nvme/host/ioctl.c
index ca86d3bf7ea49d0ec812640a6c0267a5aad40b79..e9758aef47f4ffe97d843580de63c8a9c9cbf555 100644
--- a/drivers/nvme/host/ioctl.c
+++ b/drivers/nvme/host/ioctl.c
@@ -378,6 +378,58 @@ static int nvme_user_cmd64(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
 	return status;
 }
 
+static int nvme_user_cdq_create(struct nvme_ctrl *ctrl,
+				struct nvme_cdq_cmd *cmd,
+				struct nvme_cdq_cmd __user *ucmd)
+{
+	int status;
+	u16 cdq_id = 0;
+	int cdq_fd = 0;
+	struct nvme_command c = {};
+
+	c.cdq.opcode = nvme_admin_cdq;
+	c.cdq.sel = NVME_CDQ_SEL_CREATE_CDQ;
+	c.cdq.mos = cpu_to_le16(cmd->mos);
+	c.cdq.create.cdq_flags = cpu_to_le16(NVME_CDQ_CFG_PC_CONT);
+	c.cdq.create.cqs = cpu_to_le16(cmd->cqs);
+	/* >>2: size is in dwords */
+	c.cdq.cdqsize = (cmd->entry_nbyte * cmd->entry_nr) >> 2;
+
+	status = nvme_cdq_create(ctrl, &c,
+				 cmd->entry_nr, cmd->entry_nbyte,
+				 cmd->cdqp_offset, cmd->cdqp_mask,
+				 &cdq_id, &cdq_fd);
+	if (status)
+		return status;
+
+	cmd->cdq_id = cdq_id;
+	cmd->read_fd = cdq_fd;
+
+	if (copy_to_user(ucmd, cmd, sizeof(*cmd)))
+		return -EFAULT;
+
+	return status;
+}
+
+static int nvme_user_cdq(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
+		struct nvme_cdq_cmd __user *ucmd, unsigned int flags,
+		bool open_for_write)
+{
+	struct nvme_cdq_cmd cmd;
+
+	if (copy_from_user(&cmd, ucmd, sizeof(cmd)))
+		return -EFAULT;
+
+	switch (cmd.flags) {
+	case NVME_CDQ_ADM_FLAGS_CREATE:
+		return nvme_user_cdq_create(ctrl, &cmd, ucmd);
+	case NVME_CDQ_ADM_FLAGS_DELETE:
+		return nvme_cdq_delete(ctrl, cmd.cdq_id);
+	}
+
+	return -EPERM;
+}
+
 struct nvme_uring_data {
 	__u64	metadata;
 	__u64	addr;
@@ -541,7 +593,8 @@ static int nvme_uring_cmd_io(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
 
 static bool is_ctrl_ioctl(unsigned int cmd)
 {
-	if (cmd == NVME_IOCTL_ADMIN_CMD || cmd == NVME_IOCTL_ADMIN64_CMD)
+	if (cmd == NVME_IOCTL_ADMIN_CMD || cmd == NVME_IOCTL_ADMIN64_CMD ||
+	    cmd == NVME_IOCTL_ADMIN_CDQ)
 		return true;
 	if (is_sed_ioctl(cmd))
 		return true;
@@ -556,6 +609,8 @@ static int nvme_ctrl_ioctl(struct nvme_ctrl *ctrl, unsigned int cmd,
 		return nvme_user_cmd(ctrl, NULL, argp, 0, open_for_write);
 	case NVME_IOCTL_ADMIN64_CMD:
 		return nvme_user_cmd64(ctrl, NULL, argp, 0, open_for_write);
+	case NVME_IOCTL_ADMIN_CDQ:
+		return nvme_user_cdq(ctrl, NULL, argp, 0, open_for_write);
 	default:
 		return sed_ioctl(ctrl->opal_dev, cmd, argp);
 	}
@@ -874,6 +929,8 @@ long nvme_dev_ioctl(struct file *file, unsigned int cmd,
 			return -EACCES;
 		nvme_queue_scan(ctrl);
 		return 0;
+	case NVME_IOCTL_ADMIN_CDQ:
+		return nvme_user_cdq(ctrl, NULL, argp, 0, open_for_write);
 	default:
 		return -ENOTTY;
 	}

-- 
2.47.2

