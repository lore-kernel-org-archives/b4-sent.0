From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Jul 2026 13:11:00 +0200
Subject: [PATCH RFC v2 06/14] nvme: Add file descriptor to read CDQs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-jag-cdq-lkml-v2-6-659a7449e849@kernel.org>
References: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
In-Reply-To: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4622;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=cuXW3w1fKxELbA7o+sSCBXcLYsqfoxI6yUn985dXTOA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpjSFx5KyutJlzAtt7LfqGf+4dOO0DZ/yiHc
 wmz28VygnJVXokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqY0hcAAoJELqXzVK3
 lkFPSrYL/A8YCfOy/tCi1jiOi5MVYG0dCQ4K5wVNRQmhJgD+9xWG4XlU9NXj4IEt93v0eiInGwC
 JfKM+vAlAP7A2Co2M8pDJEphJ5jxt++mHhz3//y/NsjkaDQmae3vn6jZE0qDJV/JnAjYBlMMpnO
 Mys2x3qlg/XWIn/JyhWsVgyFd5cx/NjLoXZErZBewVsNxevfi2PouqS4X6+YaPiHhWex2ZPx9xV
 B2VsoSlieq3mNlmJ1eH8KMeH/O4jPnJ6NGucFQwqG5FCrEC2gOvwj6gUSdTRy5zlou8DTGOsoI5
 vfSkFrpHo2SFiYcvsFKbWxH/s42HHWyvw8dN9Ruy4s6MAXmD7Y1hK+XNgrHld6GH+446pPKfU+s
 X8NN+xPqx0EW/J4TVMgGer8SqvPlytdIf05vPYZtzsin+5ugsgmr/hNE8sU3MyJUPUe/14Rc/G6
 g6kywQBzWURq2eyOY3kb+VnCa6kCQq9Sl5lUzDZ7Wjrh0RmE/mp7Wv3GXN+PL20YNHqK8IWhwe8
 aM=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CDQs are read using file descriptors provided by nvme_create_cdqfd. Only
add the logic to create and release the file descriptor; return "not
implemented" for now. The CDQ traversal logic will be added in a future
commit.

The CDQ memory is now pointed from two different places (the user space
FD and the nvme controller struct) and should only be freed when there
are no pointers left. Use a kref to ensure that it is in the FD's
private_data even if the controller is goes down.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/cdq.c | 71 +++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/nvme/host/cdq.h | 21 +++++++++++++++
 2 files changed, 92 insertions(+)

diff --git a/drivers/nvme/host/cdq.c b/drivers/nvme/host/cdq.c
index 73dd6af42055687bec62ad0350c67736c9c047c2..63c0852e0ba17a17227b9a0189be5123358a2262 100644
--- a/drivers/nvme/host/cdq.c
+++ b/drivers/nvme/host/cdq.c
@@ -3,6 +3,9 @@
  * NVMe Controller Data Queue (CDQ) support.
  */
 
+#include <linux/anon_inodes.h>
+#include <linux/file.h>
+
 #include "nvme.h"
 #include "cdq.h"
 
@@ -151,6 +154,9 @@ static inline int nvme_create_cdq_backing(struct cdq_nvme_queue *cdq)
 			goto err_chunks;
 	}
 
+	/* FIXME: put this on the create_cdq function*/
+	kref_init(&cdq->ref);
+
 	return 0;
 
 err_chunks:
@@ -166,6 +172,69 @@ static inline void nvme_release_cdq_backing(struct cdq_nvme_queue *cdq)
 	nvme_free_cdqmem_chunks(cdq);
 }
 
+static ssize_t nvme_cdq_fops_read(struct file *filep, char __user *buf,
+				  size_t size_nbyte, loff_t *ppos)
+{
+	struct cdq_nvme_queue *cdq = filep->private_data;
+	size_t nbytes = round_down(size_nbyte, NVME_CDQ_MQ_ENTRY_NRBYTES);
+
+	if (*ppos)
+		return -ESPIPE;
+
+	if (size_nbyte < NVME_CDQ_MQ_ENTRY_NRBYTES)
+		return -EINVAL;
+
+	if (nbytes > (cdq->size_nbyte))
+		return -EINVAL;
+
+	/* CDQ traversal not implemented yet. */
+	return -EOPNOTSUPP;
+}
+
+/* File reference already dropped by the close path, so don't fput() */
+static int nvme_release_cdqfd(struct cdq_nvme_queue *cdq)
+{
+	nvme_cdq_put(cdq);
+	return 0;
+}
+
+static int nvme_cdq_fops_release(struct inode *inode, struct file *filep)
+{
+	return nvme_release_cdqfd(filep->private_data);
+}
+
+static const struct file_operations cdq_fops = {
+	.owner		= THIS_MODULE,
+	.open		= nonseekable_open,
+	.read		= nvme_cdq_fops_read,
+	.release	= nvme_cdq_fops_release,
+};
+
+__maybe_unused
+static int nvme_create_cdqfd(struct cdq_nvme_queue *cdq, int *cdq_fdno)
+{
+	int fdno;
+	struct file *filep;
+
+	filep = anon_inode_getfile("[cdq-readfd]", &cdq_fops, cdq, O_RDWR);
+	if (IS_ERR(filep))
+		return PTR_ERR(filep);
+
+	/* cdq is being pionted at by ->private_data. increase ref */
+	nvme_cdq_get(cdq);
+
+	fdno = get_unused_fd_flags(O_CLOEXEC | O_RDONLY | O_DIRECT);
+	if (fdno < 0) {
+		fput(filep); /* nvme_cdq_put through release */
+		return fdno;
+	}
+
+	fd_install(fdno, filep);
+	*cdq_fdno = fdno;
+
+	return 0;
+}
+
 static int nvme_submit_delete_cdq_cmd(const struct cdq_nvme_queue *cdq)
 {
 	struct nvme_command c = {
@@ -193,6 +262,8 @@ static void nvme_delete_cdq_host(struct cdq_nvme_queue *cdq)
 		return;
 
 	nvme_release_cdq_backing(cdq);
+
+	nvme_cdq_put(cdq);
 }
 
 void nvme_delete_cdq(struct cdq_nvme_queue *cdq)
diff --git a/drivers/nvme/host/cdq.h b/drivers/nvme/host/cdq.h
index 5deaf3705c65250ea9fdc69e2e973987c8f084c1..8c003aa75bd3e4df9a5f8af7ff21d1957dd43923 100644
--- a/drivers/nvme/host/cdq.h
+++ b/drivers/nvme/host/cdq.h
@@ -8,6 +8,8 @@
 
 #include "nvme.h"
 
+#define NVME_CDQ_MQ_ENTRY_NRBYTES	32
+
 /*
  * The CDQ backing is a set of coherent DMA chunks. Chunk size expressed in
  * host pages to match dma_alloc_coherency granularity.
@@ -38,8 +40,27 @@ struct cdq_nvme_queue {
 	__le64 *prp_lists[MAX_NR_CDQ_PRPS];
 	dma_addr_t prp_lists_dma[MAX_NR_CDQ_PRPS];
 	unsigned int nr_prp_lists;
+
+	/* Manage refs for read FD and controller xarray */
+	struct kref ref;
 };
 
+/* Must not touch cdq->ctrl: Ctrl may have been freed */
+static inline void nvme_free_cdq(struct kref *ref)
+{
+	kfree(container_of(ref, struct cdq_nvme_queue, ref));
+}
+
+static inline void nvme_cdq_get(struct cdq_nvme_queue *cdq)
+{
+	kref_get(&cdq->ref);
+}
+
+static inline void nvme_cdq_put(struct cdq_nvme_queue *cdq)
+{
+	kref_put(&cdq->ref, nvme_free_cdq);
+}
+
 void nvme_delete_cdq(struct cdq_nvme_queue *cdq);
 void nvme_delete_cdqs_host(struct nvme_ctrl *ctrl);
 void nvme_free_cdqs(struct nvme_ctrl *ctrl);

-- 
2.50.1

