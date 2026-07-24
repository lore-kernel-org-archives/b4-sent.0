From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Jul 2026 13:11:08 +0200
Subject: [PATCH RFC v2 14/14] nvme: Add NVME_IOCTL_CDQ to create/delete
 migration CDQs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-jag-cdq-lkml-v2-14-659a7449e849@kernel.org>
References: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
In-Reply-To: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6659;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=d1zkJDIbXXjPHU7K9NaiA+mfZPVXne7PNdWSFhuUYSQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpjSGG4UvFbI8wiFtfmB5bgwXKTltOYOGg8w
 ForyT5Mgi3g+YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqY0hhAAoJELqXzVK3
 lkFP+/4L/1ZQCUenB+UJVFl3tXLpC7+xLkOUDCyPOmo4OeclITNiPo2Ffz2+XiKMOaWnD9dKfG/
 3HAZprtR4WJkQvRjoCtnrHF4EOGu55YM/v39CWHfeaEM1v3BemGsYXwhyVU7TMrCBzQ8Nmk8+Nw
 2XzHII9ExTo4uQe+NXjoYKtu21ibDjlHftMZXWmCRFw+t9t5zMWQQe+ACTihRl46DTgJSoXoLgO
 xd56VzVB7tINK7TH9+VJIGAl9GrjvvKCHrITEotkRhl6uBZO2I2c9bsYuRS+qRQ1P0em/Gj67n4
 Bg52FP+aPpSBj65FuWjRcdrQzsvBgVnp0ydtkYctM0B6nh3TRHh69hvvfQmzl6BRnHPdBdTnuti
 unVg6DD1DJT05oOOm0gLti36b2hyCl4tdw19AgCkEEwhp20polFUR5Qu23ZhyJW0/LLVEQyZeoE
 0taGb608txEiKKFPjzgRffi9v2ZVGEtPLmrJVvTGr9VL+UcZSTwFw2TlgBqBlSidm3cghAcbSs5
 fE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Controller Data Queue (CDQ) creation and deletion executed for the
migratable controller id defined in mc_id. When an eventfd file
descriptor is passed in tpt_fd, the AEN tail pointer trigger event is
routed as an eventfd signal. When tpt_fd is <= 0, the routing is turned
off.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/cdq.c         | 23 ++++++++++++++++++---
 drivers/nvme/host/cdq.h         |  4 +++-
 drivers/nvme/host/ioctl.c       | 44 ++++++++++++++++++++++++++++++++++++++++-
 include/uapi/linux/nvme_ioctl.h | 22 +++++++++++++++++++++
 4 files changed, 88 insertions(+), 5 deletions(-)

diff --git a/drivers/nvme/host/cdq.c b/drivers/nvme/host/cdq.c
index f4aabf0a8817058a11e6c30dcea9554076861327..ac10c8d48864615f53da232a547cd5da72630ed1 100644
--- a/drivers/nvme/host/cdq.c
+++ b/drivers/nvme/host/cdq.c
@@ -511,6 +511,22 @@ void nvme_delete_cdq(struct cdq_nvme_queue *cdq)
 }
 EXPORT_SYMBOL_GPL(nvme_delete_cdq);
 
+int nvme_delete_cdq_mcid(struct nvme_ctrl *ctrl, u16 mc_id)
+{
+	struct cdq_nvme_queue *cdq;
+	unsigned long i;
+
+	xa_for_each(&ctrl->cdqs, i, cdq) {
+		if (cdq->mc_id == mc_id) {
+			nvme_delete_cdq(cdq);
+			return 0;
+		}
+	}
+
+	return -ENOENT;
+}
+EXPORT_SYMBOL_GPL(nvme_delete_cdq_mcid);
+
 int nvme_handle_cdq_aen_tpevent(struct nvme_ctrl *ctrl, u32 event_param)
 {
 	u16 cdq_id = event_param & NVME_FEAT_CDQ_ID_MASK;
@@ -556,11 +572,12 @@ static int nvme_submit_create_cdq_cmd(struct cdq_nvme_queue *cdq)
 	return ret;
 }
 
-int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id, const int tpt_fd)
+int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id,
+		    const int tpt_fd, int *cdq_fd)
 {
 	u64 size_nbyte = (u64)entry_nr * NVME_CDQ_MQ_ENTRY_NRBYTES;
 	struct cdq_nvme_queue *cdq = NULL;
-	int ret, cdq_fd;
+	int ret;
 
 	/* The backing size and the CDQSIZE field are both u32 (bytes). */
 	if (size_nbyte > U32_MAX)
@@ -598,7 +615,7 @@ int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id,
 	if (ret)
 		goto del_cmd;
 
-	ret = nvme_create_cdqfd(cdq, &cdq_fd);
+	ret = nvme_create_cdqfd(cdq, cdq_fd);
 	if (ret)
 		goto del_xarray;
 
diff --git a/drivers/nvme/host/cdq.h b/drivers/nvme/host/cdq.h
index 2958c6b92b1312930414b8466690aa7c0eb57754..06a6224a6583dd2ec7463c62f9381e0edcb6718f 100644
--- a/drivers/nvme/host/cdq.h
+++ b/drivers/nvme/host/cdq.h
@@ -89,7 +89,9 @@ void nvme_free_cdq(struct kref *ref);
  *    - Calls nvme_free_cdq if there are no more refs
  */
 void nvme_delete_cdq(struct cdq_nvme_queue *cdq);
-int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id, int tpt_fd);
+int nvme_delete_cdq_mcid(struct nvme_ctrl *ctrl, u16 mc_id);
+int nvme_create_cdq(struct nvme_ctrl *ctrl, const u32 entry_nr, const u16 mc_id,
+		    int tpt_fd, int *cdq_fd);
 
 static inline void nvme_cdq_get(struct cdq_nvme_queue *cdq)
 {
diff --git a/drivers/nvme/host/ioctl.c b/drivers/nvme/host/ioctl.c
index 8844bbd395159e544218db413e066cae6c24b2f1..c289a220cb18b39bef4edbd0a8daaa4b46f8b4d9 100644
--- a/drivers/nvme/host/ioctl.c
+++ b/drivers/nvme/host/ioctl.c
@@ -8,6 +8,7 @@
 #include <linux/nvme_ioctl.h>
 #include <linux/io_uring/cmd.h>
 #include "nvme.h"
+#include "cdq.h"
 
 enum {
 	NVME_IOCTL_VEC		= (1 << 0),
@@ -538,9 +539,46 @@ static int nvme_uring_cmd_io(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
 	return ret;
 }
 
+static int nvme_user_cdq(struct nvme_ctrl *ctrl, void __user *argp)
+{
+	struct nvme_cdq_cmd cmd;
+	u32 entry_nr;
+	int ret, cdq_fd;
+
+	if (copy_from_user(&cmd, argp, sizeof(cmd)))
+		return -EFAULT;
+
+	/* A zero size requests deletion of the CDQ created for this mc_id. */
+	if (cmd.size_nbyte == 0)
+		return nvme_delete_cdq_mcid(ctrl, cmd.mc_id);
+
+	if (cmd.size_nbyte % NVME_CDQ_MQ_ENTRY_NRBYTES)
+		return -EINVAL;
+
+	entry_nr = cmd.size_nbyte / NVME_CDQ_MQ_ENTRY_NRBYTES;
+
+	ret = nvme_create_cdq(ctrl, entry_nr, cmd.mc_id, cmd.tpt_fd, &cdq_fd);
+	if (ret)
+		goto err_out;
+
+	cmd.cdq_fd = cdq_fd;
+	if (copy_to_user(argp, &cmd, sizeof(cmd))) {
+		ret = -EFAULT;
+		goto err_out;
+	}
+
+	return 0;
+
+err_out:
+	nvme_delete_cdq_mcid(ctrl, cmd.mc_id);
+	return ret;
+
+}
+
 static bool is_ctrl_ioctl(unsigned int cmd)
 {
-	if (cmd == NVME_IOCTL_ADMIN_CMD || cmd == NVME_IOCTL_ADMIN64_CMD)
+	if (cmd == NVME_IOCTL_ADMIN_CMD || cmd == NVME_IOCTL_ADMIN64_CMD ||
+	    cmd == NVME_IOCTL_CDQ)
 		return true;
 	if (is_sed_ioctl(cmd))
 		return true;
@@ -555,6 +593,8 @@ static int nvme_ctrl_ioctl(struct nvme_ctrl *ctrl, unsigned int cmd,
 		return nvme_user_cmd(ctrl, NULL, argp, 0, open_for_write);
 	case NVME_IOCTL_ADMIN64_CMD:
 		return nvme_user_cmd64(ctrl, NULL, argp, 0, open_for_write);
+	case NVME_IOCTL_CDQ:
+		return nvme_user_cdq(ctrl, argp);
 	default:
 		return sed_ioctl(ctrl->opal_dev, cmd, argp);
 	}
@@ -873,6 +913,8 @@ long nvme_dev_ioctl(struct file *file, unsigned int cmd,
 			return -EACCES;
 		nvme_queue_scan(ctrl);
 		return 0;
+	case NVME_IOCTL_CDQ:
+		return nvme_user_cdq(ctrl, argp);
 	default:
 		return -ENOTTY;
 	}
diff --git a/include/uapi/linux/nvme_ioctl.h b/include/uapi/linux/nvme_ioctl.h
index 2f76cba6716637baff53e167a6141b68420d75c3..b3fbab48a903bfb10521ca44d08e61fd2b37bbbd 100644
--- a/include/uapi/linux/nvme_ioctl.h
+++ b/include/uapi/linux/nvme_ioctl.h
@@ -92,6 +92,27 @@ struct nvme_uring_cmd {
 	__u32   rsvd2;
 };
 
+struct nvme_cdq_cmd {
+	/* Migratable controller id (filled by user space). */
+	__u16	mc_id;
+
+	/*
+	 * CDQ size in bytes: (number of entries) * 32. Must be a multiple of
+	 * 32. A size of 0 requests deletion of the CDQ created for mc_id.
+	 */
+	__u32	size_nbyte;
+
+	/*
+	 * Tail Pointer Trigger eventfd file descriptor, passed when creating
+	 * the CDQ. A value <= 0 means there is no eventfd and AERs are not
+	 * forwarded.
+	 */
+	__s32	tpt_fd;
+
+	/* Returned by the kernel: the CDQ file descriptor. */
+	__s32	cdq_fd;
+};
+
 #define nvme_admin_cmd nvme_passthru_cmd
 
 #define NVME_IOCTL_ID		_IO('N', 0x40)
@@ -104,6 +125,7 @@ struct nvme_uring_cmd {
 #define NVME_IOCTL_ADMIN64_CMD	_IOWR('N', 0x47, struct nvme_passthru_cmd64)
 #define NVME_IOCTL_IO64_CMD	_IOWR('N', 0x48, struct nvme_passthru_cmd64)
 #define NVME_IOCTL_IO64_CMD_VEC	_IOWR('N', 0x49, struct nvme_passthru_cmd64)
+#define NVME_IOCTL_CDQ		_IOWR('N', 0x50, struct nvme_cdq_cmd)
 
 /* io_uring async commands: */
 #define NVME_URING_CMD_IO	_IOWR('N', 0x80, struct nvme_uring_cmd)

-- 
2.50.1

