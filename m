From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Apr 2026 13:37:55 +0200
Subject: [PATCH RFC 5/5] nvme: Add CDQ ioctl interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260424-jag-cdq-lkml-v1-5-d773343a717c@kernel.org>
References: <20260424-jag-cdq-lkml-v1-0-d773343a717c@kernel.org>
In-Reply-To: <20260424-jag-cdq-lkml-v1-0-d773343a717c@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4647;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=4sHaCCccq5eLSKvrkGZ7ST8L13vQIeDmpX57uViLJyE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGnrVis0PgumY0ewTsOM/34h4kUkJuD+/2+4f
 PTJZqQVf1j6dYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJp61YrAAoJELqXzVK3
 lkFPn3wL/jKdR3jvoJ0nVQYDcX4EEO2SLnTzID0qaLwYRqAPiJmn/jBYhrYUsNL4fXi6a+E2tJ1
 IEETlT35XxhtJdlxAfL0aWZ/6GcemL5+6hFMT60dajXJvGyaCYXW2Ew5lgzYlEZ9uFOgkMKyEYK
 IItpm8sLMG8XnAlI8re4VwZBU0xXSmfUG+A6ePP0S/y1kKqS8RbBBv5JeNqOGUfkFKJ5MiqO2D2
 LW67cNFUGY8fUI2/UmatG8XQITi1qUlTISBcNs/ET/B/S5efz4ulMpgIi/MwiHmO6U05stXYty5
 tVdmNtWcBqe8E81ADtOHdBCPSh2ljFQORv1Dne9Nhgk6Py/wSMw88jQ+in3hqgCoGv2ygpHjWR7
 /b7HW8k0h4tq1QjObs9Xa3VGV89vIxyLYulDE6QyRjsdiDDrpubK1LX3MgeMailp96i6ZiK3+7v
 SLHJQlEf/NJoniwSD6kiJ8PSWLB9XV/wiuk1s0+KZIlEf7Ou/MpWNIsk1NugFnxoA8aVrg8+m26
 Gk=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add userspace ioctl interface for CDQ (Controller Data Queue)
management. This allows userspace applications to create, configure,
and delete CDQs.

The interface includes:
- struct nvme_cdq_cmd for passing CDQ parameters
- NVME_IOCTL_CDQ ioctl command (0x50)
- Support for both controller and device ioctls

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/ioctl.c       | 53 ++++++++++++++++++++++++++++++++++++++++-
 include/uapi/linux/nvme_ioctl.h | 29 ++++++++++++++++++++++
 2 files changed, 81 insertions(+), 1 deletion(-)

diff --git a/drivers/nvme/host/ioctl.c b/drivers/nvme/host/ioctl.c
index 8844bbd395159e544218db413e066cae6c24b2f1..98441439bd6be67e20717fed4ffc4d32c9b37725 100644
--- a/drivers/nvme/host/ioctl.c
+++ b/drivers/nvme/host/ioctl.c
@@ -8,6 +8,7 @@
 #include <linux/nvme_ioctl.h>
 #include <linux/io_uring/cmd.h>
 #include "nvme.h"
+#include "trace.h"
 
 enum {
 	NVME_IOCTL_VEC		= (1 << 0),
@@ -373,6 +374,51 @@ static int nvme_user_cmd64(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
 	return status;
 }
 
+static int nvme_user_cdq(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
+		struct nvme_cdq_cmd __user *ucmd, unsigned int flags,
+		bool open_for_write)
+{
+	int status;
+	u16 cdq_id = 0;
+	struct nvme_cdq_cmd cmd = {};
+
+	if (copy_from_user(&cmd, ucmd, sizeof(cmd)))
+		return -EFAULT;
+
+	/* 21 = 12 (PAGE_SHIFT) + 9 (PAGE_SHIFT / sizeof(u64)) */
+	if (cmd.size_nbyte > MAX_NR_CDQ_PRPS << 21)
+		return -EINVAL;
+
+	if (cmd.size_nbyte == 0) {
+		status = nvme_cdq_delete(ctrl, cmd.id);
+	} else {
+		status = nvme_cdq_create(ctrl, cmd.mos, cmd.cqs, cmd.entries,
+					 cmd.size_nbyte, &cdq_id);
+		if (status)
+			return status;
+
+		if (cmd.tpt_fd > 0) {
+			status = nvme_cdq_set_tpt(ctrl, cdq_id, cmd.tpt_fd);
+			if (status)
+				goto del_cdq;
+		}
+
+		cmd.id = cdq_id;
+
+		if (copy_to_user(ucmd, &cmd, sizeof(cmd))) {
+			status = -EINVAL;
+			goto del_cdq;
+		}
+	}
+
+	return status;
+
+del_cdq:
+	// Ignore return; already in error
+	nvme_cdq_delete(ctrl, cdq_id);
+	return status;
+}
+
 struct nvme_uring_data {
 	__u64	metadata;
 	__u64	addr;
@@ -540,7 +586,8 @@ static int nvme_uring_cmd_io(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
 
 static bool is_ctrl_ioctl(unsigned int cmd)
 {
-	if (cmd == NVME_IOCTL_ADMIN_CMD || cmd == NVME_IOCTL_ADMIN64_CMD)
+	if (cmd == NVME_IOCTL_ADMIN_CMD || cmd == NVME_IOCTL_ADMIN64_CMD ||
+	    cmd == NVME_IOCTL_CDQ)
 		return true;
 	if (is_sed_ioctl(cmd))
 		return true;
@@ -555,6 +602,8 @@ static int nvme_ctrl_ioctl(struct nvme_ctrl *ctrl, unsigned int cmd,
 		return nvme_user_cmd(ctrl, NULL, argp, 0, open_for_write);
 	case NVME_IOCTL_ADMIN64_CMD:
 		return nvme_user_cmd64(ctrl, NULL, argp, 0, open_for_write);
+	case NVME_IOCTL_CDQ:
+		return nvme_user_cdq(ctrl, NULL, argp, 0, open_for_write);
 	default:
 		return sed_ioctl(ctrl->opal_dev, cmd, argp);
 	}
@@ -873,6 +922,8 @@ long nvme_dev_ioctl(struct file *file, unsigned int cmd,
 			return -EACCES;
 		nvme_queue_scan(ctrl);
 		return 0;
+	case NVME_IOCTL_CDQ:
+		return nvme_user_cdq(ctrl, NULL, argp, 0, open_for_write);
 	default:
 		return -ENOTTY;
 	}
diff --git a/include/uapi/linux/nvme_ioctl.h b/include/uapi/linux/nvme_ioctl.h
index 2f76cba6716637baff53e167a6141b68420d75c3..8d220c276d959dbd45f224d8ed300fe02dea2f20 100644
--- a/include/uapi/linux/nvme_ioctl.h
+++ b/include/uapi/linux/nvme_ioctl.h
@@ -92,6 +92,34 @@ struct nvme_uring_cmd {
 	__u32   rsvd2;
 };
 
+struct nvme_cdq_cmd {
+	/*
+	 * CDQ size in bytes:
+	 * (Number of entries) * (entry size in bytes)
+	 */
+	__u32	size_nbyte;
+
+	/*
+	 * Virtual mem (returned by mmap). Start of the entries buf in virtual mem.
+	 */
+	__u64	entries;
+
+	/*
+	 * Tail Pointer Trigger eventfd File Descriptor
+	 * Passed when creating the cdq.
+	 * -1 means that there is no FD and AER should not be forwarded.
+	 */
+	int	tpt_fd;
+
+	/*
+	 * Returned by controller; CDQ ID
+	 */
+	__u16	id;
+
+	__u16	cqs;
+	__u16	mos;
+};
+
 #define nvme_admin_cmd nvme_passthru_cmd
 
 #define NVME_IOCTL_ID		_IO('N', 0x40)
@@ -104,6 +132,7 @@ struct nvme_uring_cmd {
 #define NVME_IOCTL_ADMIN64_CMD	_IOWR('N', 0x47, struct nvme_passthru_cmd64)
 #define NVME_IOCTL_IO64_CMD	_IOWR('N', 0x48, struct nvme_passthru_cmd64)
 #define NVME_IOCTL_IO64_CMD_VEC	_IOWR('N', 0x49, struct nvme_passthru_cmd64)
+#define NVME_IOCTL_CDQ		_IOR('N', 0x50, struct nvme_cdq_cmd)
 
 /* io_uring async commands: */
 #define NVME_URING_CMD_IO	_IOWR('N', 0x80, struct nvme_uring_cmd)

-- 
2.50.1

