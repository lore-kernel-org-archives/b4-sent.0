From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 14 Jul 2025 11:15:39 +0200
Subject: [PATCH RFC 8/8] nvme: Connect CDQ ioctl to nvme driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-jag-cdq-v1-8-01e027d256d5@kernel.org>
References: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
In-Reply-To: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: Klaus Jensen <k.jensen@samsung.com>, linux-nvme@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3054;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=El37Gj/bO4g5zQC6jForLJm2KfkQjW+oJE5NpN3BFes=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGh0yu1QDNzxro8uFOrjz5Om6eL02tjmaGJu5
 aLz1ZtA3CJvJIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJodMrtAAoJELqXzVK3
 lkFPKYcL/Aj/dE4mCCSzsfDlmLZU5vG9LCjMgMNhbWmVgR1IikffXCVuR95AW50beEaxpCO6FpL
 WK1u0mq6NGFl2m+TL7VzOFZefVQecM01MKSUtmKS5G+aigVL8qpkdMY36cHEd5HBr0bPN1sMpIQ
 6QnIUxpDFntnTtBapJaHqof42yxORjUq7gFbi0jKgrL5UZ6spXnV7aQ0+Dl+QpOdyRJBg1HxSO3
 +br6NweNXKCOJ9BJCZrNXrz79sT8dIwmWh252JUDz++ifiJ2soO4czczOocyHzG8ebgVHtTmUg5
 uunhZFf+cpwVR1ImceGMvwGDE8uuFnqirmYW+1DAzuTbteOIlZBZYulJ1y9uGvORgRlQj7Pymnf
 PmMj7KpRXwx8LWEcPhH71fJFEqX0R9ZtbRhkuI3qqEM8OyBB+p2zFUWno1kPruI5BJVVDj+65T9
 0BdD93axnX4v8CYxlXO715PwNSQ3Z9XqVY5PnvBDE5T3Boz6kX54C+OrQcgl0rbfY8J35G1Q1q7
 6o=
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
 drivers/nvme/host/ioctl.c | 47 ++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 46 insertions(+), 1 deletion(-)

diff --git a/drivers/nvme/host/ioctl.c b/drivers/nvme/host/ioctl.c
index ca86d3bf7ea49d0ec812640a6c0267a5aad40b79..6ab42381b6fe4e88bae341874b111ed4b7ade397 100644
--- a/drivers/nvme/host/ioctl.c
+++ b/drivers/nvme/host/ioctl.c
@@ -378,6 +378,46 @@ static int nvme_user_cmd64(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
 	return status;
 }
 
+static int nvme_user_cdq(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
+		struct nvme_cdq_cmd __user *ucmd, unsigned int flags,
+		bool open_for_write)
+{
+	int status;
+	u16 cdq_id = 0;
+	int cdq_fd = 0;
+	struct nvme_command c = {};
+	struct nvme_cdq_cmd cmd = {};
+
+	if (copy_from_user(&cmd, ucmd, sizeof(cmd)))
+		return -EFAULT;
+
+	if (cmd.cdqp_offset >= cmd.entry_nbyte)
+		return -EINVAL;
+
+	c.cdq.opcode = nvme_admin_cdq;
+	c.cdq.sel = NVME_CDQ_SEL_CREATE_CDQ;
+	c.cdq.mos = cpu_to_le16(cmd.mos);
+	c.cdq.create.cdq_flags = cpu_to_le16(NVME_CDQ_CFG_PC_CONT);
+	c.cdq.create.cqs = cpu_to_le16(cmd.cqs);
+	/* >>2: size is in dwords */
+	c.cdq.cdqsize = (cmd.entry_nbyte * cmd.entry_nr) >> 2;
+
+	status = nvme_cdq_create(ctrl, &c,
+				 cmd.entry_nr, cmd.entry_nbyte,
+				 cmd.cdqp_offset, cmd.cdqp_mask,
+				 &cdq_id, &cdq_fd);
+	if (status)
+		return status;
+
+	cmd.cdq_id = cdq_id;
+	cmd.read_fd = cdq_fd;
+
+	if (copy_to_user(ucmd, &cmd, sizeof(cmd)))
+		return -EFAULT;
+
+	return status;
+}
+
 struct nvme_uring_data {
 	__u64	metadata;
 	__u64	addr;
@@ -541,7 +581,8 @@ static int nvme_uring_cmd_io(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
 
 static bool is_ctrl_ioctl(unsigned int cmd)
 {
-	if (cmd == NVME_IOCTL_ADMIN_CMD || cmd == NVME_IOCTL_ADMIN64_CMD)
+	if (cmd == NVME_IOCTL_ADMIN_CMD || cmd == NVME_IOCTL_ADMIN64_CMD ||
+	    cmd == NVME_IOCTL_ADMIN_CDQ)
 		return true;
 	if (is_sed_ioctl(cmd))
 		return true;
@@ -556,6 +597,8 @@ static int nvme_ctrl_ioctl(struct nvme_ctrl *ctrl, unsigned int cmd,
 		return nvme_user_cmd(ctrl, NULL, argp, 0, open_for_write);
 	case NVME_IOCTL_ADMIN64_CMD:
 		return nvme_user_cmd64(ctrl, NULL, argp, 0, open_for_write);
+	case NVME_IOCTL_ADMIN_CDQ:
+		return nvme_user_cdq(ctrl, NULL, argp, 0, open_for_write);
 	default:
 		return sed_ioctl(ctrl->opal_dev, cmd, argp);
 	}
@@ -874,6 +917,8 @@ long nvme_dev_ioctl(struct file *file, unsigned int cmd,
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

