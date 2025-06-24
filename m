From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 24 Jun 2025 22:05:50 +0200
Subject: [PATCH RFC 3/7] nvme: Add file descriptor to read CDQs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-jag-cdq-v1-3-6d88476c9165@kernel.org>
References: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
In-Reply-To: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
To: joshi.k@samsung.com
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5473;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=VpEiKje7pYbIaUqTR1qpen3fjJouahq56YuI9Z/pLlE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhbBR7b2/6NIozIGcgACsgGxTUF8rP2U2Cz7
 xg2dmn+7WCikIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoWwUeAAoJELqXzVK3
 lkFPoQcL/34cbj/KWSWKMcWJBqagfFPiojPIPokL/+LJMueY7O/8sjNwTU23H0pY+MMahMVAgmS
 Hfj5aT1K6VQfOuHZh+LLwxt60GdkybqDOypA+2dJbneHbJ637CDfUqe3lCDnKkeO9Wy3/D/D7Q3
 IIh5+f/xhx4dzDWuDz0cIuICOY8LWElbRe4HOpjSF70rrS3o8/UYZeQLKhauaWhBX1vy65bOSEq
 kHdfKfnk4XvsBD2KIc/H7Mnw5Ka0JsHwNloK9rxtCFMd08j6Nn6ITvwGEuKv5wowUmXxKoSKrgT
 kYOEEZKID9ZcwJM6JIWlVRtZR+xg7UtUDXzMx64NcMWBTVNAsKtb0k8RO70wwfCAwm6DTmJLJUD
 gimic7B0RPkkA7/0sACbM4ik7zO6LzCSUpB3nEBv5MKzeq65vto/ZLDR6THvx2dmuPy/7xfS9Rf
 /mao3r7n0eMNbPxq14bsc1DM+DrDVsXrB5xxgFPKptBkJEDKuasBZ0z2DwfFDeza9Ka9dcceLT8
 w4=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The file descriptor provided by nvme_cdq_fd is to be used to consume the
entries in the newly created CDQ. This commit both adds the creation of
the file descriptor as well as the mechanism to read and copy entry data
back to user space.

All available entries are consumed on every read. Phase bits and current
head are updated before sending the cdq feature id which tells the
controller the entries have been cosumed.

The nvme_cdq_fd is not called anywhere yet as this is a preparation
commit for when the CDQ create and delete are added.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c | 149 +++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 149 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 9b2de74d62f7a65aea2d28bbbed6681195d9afcd..bffeb329b5c95e74d2b255296dcacfb683030867 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -23,6 +23,7 @@
 #include <linux/pm_qos.h>
 #include <linux/ratelimit.h>
 #include <linux/unaligned.h>
+#include <linux/anon_inodes.h>
 
 #include "nvme.h"
 #include "fabrics.h"
@@ -1228,6 +1229,154 @@ u32 nvme_passthru_start(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u8 opcode)
 }
 EXPORT_SYMBOL_NS_GPL(nvme_passthru_start, "NVME_TARGET_PASSTHRU");
 
+static int nvme_cdq_is_tip_new(const struct cdq_nvme_queue *cdq)
+{
+	void *tip = cdq->entries + (cdq->curr_entry * cdq->entry_nbyte);
+	/* if different, then its new! */
+	return (*(u8 *)(tip + cdq->cdqp_offset) & cdq->cdqp_mask) != cdq->curr_cdqp;
+}
+
+static void nvme_cdq_next(struct cdq_nvme_queue *cdq)
+{
+	if (cdq->curr_entry + 1 == cdq->entry_nr) {
+		cdq->curr_entry = 0;
+		cdq->curr_cdqp = ~cdq->curr_cdqp & 0x1;
+	} else {
+		cdq->curr_entry++;
+	}
+}
+
+static int nvme_cdq_send_feature_id(struct cdq_nvme_queue *cdq)
+{
+	struct nvme_command c = { };
+
+	c.features.opcode = nvme_admin_set_features;
+	c.features.fid = cpu_to_le32(NVME_FEAT_CDQ);
+	c.features.dword11 = cdq->cdq_id;
+	c.features.dword12 = cpu_to_le32(cdq->curr_entry);
+
+	return nvme_submit_sync_cmd(cdq->ctrl->admin_q, &c, NULL, 0);
+}
+
+/*
+ * Traverse the CDQ until max entries are reached or until the entry phase
+ * bit is the same as the current phase bit.
+ *
+ * cdq : Controller Data Queue
+ * max_nentry : Max entries to "traverse" before sending feature id
+ * consume : Executed after exhausting traversal and before seinding the nvme feature id
+ * priv_data : argument for consume
+ */
+static ssize_t nvme_cdq_traverse(struct cdq_nvme_queue *cdq, size_t max_nentry,
+				     ssize_t (*consume)(const u32 init_entry,
+							const size_t tx_nentry,
+							struct cdq_nvme_queue *cdq,
+							void *priv_data),
+				     void *priv_data)
+{
+	int ret;
+	ssize_t tx_nentry = 0; /* transferred num entries */
+	size_t target_nentry = 0; /* target num entries */
+	u32 init_entry = cdq->curr_entry;
+
+	for (; target_nentry < max_nentry && nvme_cdq_is_tip_new(cdq);
+	     ++target_nentry) {
+		nvme_cdq_next(cdq);
+	}
+	tx_nentry = consume(init_entry, target_nentry, cdq, priv_data);
+	if (tx_nentry < 0)
+		return tx_nentry;
+	if (tx_nentry != target_nentry)
+		return -EIO;
+
+	ret = nvme_cdq_send_feature_id(cdq);
+	if (ret < 0)
+		return ret;
+
+	return tx_nentry;
+}
+
+static ssize_t nvme_cdq_consume_fops_read(const u32 init_entry, const size_t tx_nentry,
+					  struct cdq_nvme_queue *cdq, void *priv)
+{
+	char __user *buf = priv;
+	void *entries_start;
+	size_t copy_nentry = min(cdq->entry_nr - init_entry, tx_nentry);
+
+	entries_start = cdq->entries + (init_entry * cdq->entry_nbyte);
+	if (copy_to_user(buf, entries_start, copy_nentry * cdq->entry_nbyte))
+		return -EFAULT;
+
+	if (copy_nentry == tx_nentry)
+		return tx_nentry;
+
+	/* Copy the entries that have been wrapped around */
+	buf += (copy_nentry * cdq->entry_nbyte);
+	copy_nentry = tx_nentry - copy_nentry;
+	if (copy_to_user(buf, cdq->entries, copy_nentry * cdq->entry_nbyte))
+		return -EFAULT;
+
+	return tx_nentry;
+}
+
+static ssize_t nvme_cdq_fops_read(struct file *filep, char __user *buf,
+				  size_t count, loff_t *ppos)
+{
+	struct cdq_nvme_queue *cdq = filep->private_data;
+	size_t max_nentry = count / cdq->entry_nbyte;
+
+	if (*ppos)
+		return -ESPIPE;
+
+	if (count < cdq->entry_nbyte)
+		return -EINVAL;
+
+	if (max_nentry > cdq->entry_nr)
+		return -EINVAL;
+
+	return nvme_cdq_traverse(cdq, max_nentry, nvme_cdq_consume_fops_read, buf);
+}
+
+static const struct file_operations cdq_fops = {
+	.owner		= THIS_MODULE,
+	.open		= nonseekable_open,
+	.read		= nvme_cdq_fops_read,
+};
+
+static int nvme_cdq_fd(struct cdq_nvme_queue *cdq, int *fdno)
+{
+	int ret = 0;
+	struct file *filep;
+
+	*fdno = -1;
+
+	if (cdq->filep)
+		return -EINVAL;
+
+	filep = anon_inode_getfile("[cdq-readfd]", &cdq_fops, cdq, O_RDWR);
+	if (IS_ERR(filep)) {
+		ret = PTR_ERR(filep);
+		goto out;
+	}
+
+	*fdno = get_unused_fd_flags(O_CLOEXEC | O_RDONLY | O_DIRECT);
+	if (*fdno < 0) {
+		ret = *fdno;
+		goto out_fput;
+	}
+
+	fd_install(*fdno, filep);
+	cdq->filep = filep;
+
+	return 0;
+
+out_fput:
+	put_unused_fd(*fdno);
+	fput(filep);
+out:
+	return ret;
+}
+
 void nvme_passthru_end(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u32 effects,
 		       struct nvme_command *cmd, int status)
 {

-- 
2.47.2

