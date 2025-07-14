From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 14 Jul 2025 11:15:34 +0200
Subject: [PATCH RFC 3/8] nvme: Add file descriptor to read CDQs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-jag-cdq-v1-3-01e027d256d5@kernel.org>
References: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
In-Reply-To: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: Klaus Jensen <k.jensen@samsung.com>, linux-nvme@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4170;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=TtseZ4TcQtCKALUdMCarP65Y58vXB5ipsP5nGvWI3FY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGh0yupLwwxxgJrdT4OCImvVb4tPC51BwzORZ
 pOM+8l5nbK/zYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJodMrqAAoJELqXzVK3
 lkFPZd8L/RkR/7Fkg+619MfcZxBcXjZMOxL7y2OrZGCmS+dje9Lgd0/QgfCfwKb2/OXbeKfjr98
 2I4Xj1un/j9+qOdJj+v2F2J7F9eqsmp+0qT5b1l+LvhB5zwCE1sk//KQIH20xTRmeJjJCLsKrIA
 vjIxz6vIF6qNmiLjvZQfAOeqwk2jvczAEUO7y2hqSZBXqBWO6Umzpf04Kek6i1kWJ9uSS/VRAT9
 6EL9+Pa9EN+V5P29zCqsBcj5WdnxjHb4wzkPbbXMLdvLKEVcdqEyOogVt0DPzbQXQtJN+Ir2GZM
 moBm+Iw54083IQalIPhyU8ku1H1nZYDaTyQ4EwACAXfBwmdNtzvSSYBTGbe7lkb9avOuuwYfGTe
 Rw5dFwqcPbp3tVv7GoXgc8yFA5bX5inogPEzYa67MEmEpRq0KdC8IAAL6xKFU1MUDiiT7Frsc7z
 JxxRO4CqPfilGrDQcaAWHgXOXBEp602tBmtQS/5rrT3v8lMDHyoDICJYBRKuOMA00qaF3/JS9b7
 74=
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
 drivers/nvme/host/core.c | 91 ++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 91 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 9b2de74d62f7a65aea2d28bbbed6681195d9afcd..8517253002941e1f892e62bb7dacac40395b16d9 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -23,6 +23,7 @@
 #include <linux/pm_qos.h>
 #include <linux/ratelimit.h>
 #include <linux/unaligned.h>
+#include <linux/anon_inodes.h>
 
 #include "nvme.h"
 #include "fabrics.h"
@@ -1228,6 +1229,96 @@ u32 nvme_passthru_start(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u8 opcode)
 }
 EXPORT_SYMBOL_NS_GPL(nvme_passthru_start, "NVME_TARGET_PASSTHRU");
 
+/* Returns true if curr_entry forwarded by 1 */
+static bool nvme_cdq_next(struct cdq_nvme_queue *cdq)
+{
+	void *curr_entry = cdq->entries + (cdq->curr_entry * cdq->entry_nbyte);
+	u8 phase_bit = (*(u8 *)(curr_entry + cdq->cdqp_offset) & cdq->cdqp_mask);
+	/* if different, then its new! */
+	if (phase_bit != cdq->curr_cdqp) {
+		cdq->curr_entry = (cdq->curr_entry + 1) % cdq->entry_nr;
+		if (unlikely(cdq->curr_entry == 0))
+			cdq->curr_cdqp = ~cdq->curr_cdqp & 0x1;
+		return true;
+	}
+	return false;
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
+ * count_nbyte : Count bytes to "traverse" before sending feature id
+ * priv_data : argument for consume
+ */
+static size_t nvme_cdq_traverse(struct cdq_nvme_queue *cdq, size_t count_nbyte,
+				 void *priv_data)
+{
+	int ret;
+	char __user *to_buf = priv_data;
+	size_t tx_nbyte, target_nbyte = 0;
+	size_t orig_tail_nbyte = (cdq->entry_nr - cdq->curr_entry) * cdq->entry_nbyte;
+	void *from_buf = cdq->entries + (cdq->curr_entry * cdq->entry_nbyte);
+
+	while (target_nbyte < count_nbyte && nvme_cdq_next(cdq))
+		target_nbyte += cdq->entry_nbyte;
+	tx_nbyte = min(orig_tail_nbyte, target_nbyte);
+
+	if (copy_to_user(to_buf, from_buf, tx_nbyte))
+		return -EFAULT;
+
+	if (tx_nbyte < target_nbyte) {
+		/* Copy the entries that have been wrapped around */
+		from_buf = cdq->entries;
+		to_buf += tx_nbyte;
+		if (copy_to_user(to_buf, from_buf, target_nbyte - tx_nbyte))
+			return -EFAULT;
+	}
+
+	ret = nvme_cdq_send_feature_id(cdq);
+	if (ret < 0)
+		return ret;
+
+	return tx_nbyte;
+}
+
+static ssize_t nvme_cdq_fops_read(struct file *filep, char __user *buf,
+				  size_t count, loff_t *ppos)
+{
+	struct cdq_nvme_queue *cdq = filep->private_data;
+	size_t nbytes = round_down(count, cdq->entry_nbyte);
+
+	if (*ppos)
+		return -ESPIPE;
+
+	if (count < cdq->entry_nbyte)
+		return -EINVAL;
+
+	if (nbytes > (cdq->entry_nr * cdq->entry_nbyte))
+		return -EINVAL;
+
+	return nvme_cdq_traverse(cdq, nbytes, buf);
+}
+
+static const struct file_operations cdq_fops = {
+	.owner		= THIS_MODULE,
+	.open		= nonseekable_open,
+	.read		= nvme_cdq_fops_read,
+};
+
 void nvme_passthru_end(struct nvme_ctrl *ctrl, struct nvme_ns *ns, u32 effects,
 		       struct nvme_command *cmd, int status)
 {

-- 
2.47.2

