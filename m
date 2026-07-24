From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Jul 2026 13:11:05 +0200
Subject: [PATCH RFC v2 11/14] nvme: Implement CDQ traversal on the read
 path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-jag-cdq-lkml-v2-11-659a7449e849@kernel.org>
References: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
In-Reply-To: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4810;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Hl9wyVfReowmH9lQXOTj9hunvFlCPgM9Uuy4AsqCz3I=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpjSF+n2iXlrweqzc/nxEwB/z4f0UK8MBU+j
 NCK/boeFLJJjYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqY0hfAAoJELqXzVK3
 lkFPUhsMAIGYljanPcOwQ6j/9z4kH80xLUK3aACtckcxSC/qwqXnuS1jRQ/wfkFNlGm7mHLaLmG
 soKtFi6Cqblp/e8GuLUJqKYK5APRpeoSw8jyNNVEGP/9W+ddXMDjeS29pAXKzw3+OLrzk6E70hd
 4BG+b5iBTlhF/R5MpKCguGYIHIy7JgGH45natCdyWbEItJcYCsTijxW1vYXNzs0Qtn5T+9d1n8E
 P8iGo60G2+RoGKfqGCMQ4cAdbRQgWwYmrzOs7w9rQEHgqcMqeu6cUtb8GWCXarUnKZpVqontwfW
 yB2C6wgfTLS01ethQcQUpleFB/9btqTf9fBJMMyK6MF9A9mSjLQ/GJAq+/nqGK1Gc6lT0K+R8MV
 av9LZLbMOkwXtnOqt7PJCSPNc+JSkH6EmBqB2Oxqh/GF72ohYT2WDyAbCQ92d6o6JYfM1x9yxEs
 kRTx2fNi3KWNnH7kkLnqw2+QKGyYA2M0eMgy+P+O2KTTnc2sxgMn3aRTNXZH4jevDHI9I6bkAq7
 HY=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the initial -EOPNOTSUPP stub with a call to
nvme_traversecopy_cdq which copies new controller entries to the user
space buffer, forwards and wraps host_head around when it reaches the
end of the queue.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/cdq.c | 73 +++++++++++++++++++++++++++++++++++++++++++++++--
 drivers/nvme/host/cdq.h |  7 +++++
 2 files changed, 78 insertions(+), 2 deletions(-)

diff --git a/drivers/nvme/host/cdq.c b/drivers/nvme/host/cdq.c
index 7fe08afa0d80db5f3d60993aba05624b5c59b309..36107cf2fe11ff212d5b02dd5513fe02e3ae8f81 100644
--- a/drivers/nvme/host/cdq.c
+++ b/drivers/nvme/host/cdq.c
@@ -5,6 +5,7 @@
 
 #include <linux/anon_inodes.h>
 #include <linux/file.h>
+#include <linux/uaccess.h>
 
 #include "nvme.h"
 #include "cdq.h"
@@ -169,6 +170,75 @@ static inline void nvme_release_cdq_backing(struct cdq_nvme_queue *cdq)
 	nvme_free_cdqmem_chunks(cdq);
 }
 
+
+static inline void *nvme_get_cdq_entryvaddr(struct cdq_nvme_queue *cdq,
+					    unsigned int entry_idx)
+{
+	return cdq->chunks[entry_idx / NVME_CDQ_MQ_ENTRY_PER_CHUNK].vaddr +
+		(entry_idx % NVME_CDQ_MQ_ENTRY_PER_CHUNK) * NVME_CDQ_MQ_ENTRY_NRBYTES;
+}
+
+/* Advance cdq->host_head at most nrbytes and return actual advanced bytes */
+static size_t nvme_advance_cdq(struct cdq_nvme_queue *cdq, size_t max_nrbyte)
+{
+	size_t target_nbyte = 0;
+	void *entry;
+	u8 phase_bit;
+	u32 cdq_nrentry = cdq->size_nbyte / NVME_CDQ_MQ_ENTRY_NRBYTES;
+
+	while (target_nbyte < max_nrbyte) {
+		entry = nvme_get_cdq_entryvaddr(cdq, cdq->host_head);
+		phase_bit = (*(u8 *)(entry + NVME_CDQ_MQ_PHASE_OFFSET) & NVME_CDQ_MQ_PHASE_MASK);
+
+		if (phase_bit == cdq->phase_bit)
+			break;
+
+		cdq->host_head = (cdq->host_head + 1) % cdq_nrentry;
+		target_nbyte += NVME_CDQ_MQ_ENTRY_NRBYTES;
+		if (unlikely(cdq->host_head == 0))
+			cdq->phase_bit = ~cdq->phase_bit & NVME_CDQ_MQ_PHASE_MASK;
+	}
+
+	return target_nbyte;
+}
+
+static ssize_t nvme_traversecopy_cdq(struct cdq_nvme_queue *cdq, size_t max_nrbyte,
+				   void *priv_data)
+{
+	char __user *to_buf = priv_data;
+	void *from_buf;
+	u32 init_host_head = cdq->host_head;
+	u8 init_phase_bit = cdq->phase_bit;
+
+	size_t target_nbyte = nvme_advance_cdq(cdq, max_nrbyte);
+	size_t copied_nbyte = 0, chunks_idx, entry_idx, tx_nbytes;
+
+	if (target_nbyte == 0)
+		goto out;
+
+	for (chunks_idx = init_host_head / NVME_CDQ_MQ_ENTRY_PER_CHUNK,
+	     entry_idx = init_host_head % NVME_CDQ_MQ_ENTRY_PER_CHUNK;
+	     copied_nbyte < target_nbyte;
+	     chunks_idx = (chunks_idx + 1) % cdq->nr_chunks, entry_idx = 0) {
+		from_buf = cdq->chunks[chunks_idx].vaddr +
+			(entry_idx * NVME_CDQ_MQ_ENTRY_NRBYTES);
+		tx_nbytes = min(target_nbyte - copied_nbyte,
+				NVME_CDQ_CHUNK_SIZE - (entry_idx * NVME_CDQ_MQ_ENTRY_NRBYTES));
+		if (copy_to_user(to_buf, from_buf, tx_nbytes))
+			goto err_out;
+		copied_nbyte += tx_nbytes;
+		to_buf += tx_nbytes;
+	}
+
+out:
+	return copied_nbyte;
+
+err_out:
+	cdq->host_head = init_host_head;
+	cdq->phase_bit = init_phase_bit;
+	return -EFAULT;
+}
+
 static ssize_t nvme_cdq_fops_read(struct file *filep, char __user *buf,
 				  size_t size_nbyte, loff_t *ppos)
 {
@@ -187,8 +257,7 @@ static ssize_t nvme_cdq_fops_read(struct file *filep, char __user *buf,
 	if (!READ_ONCE(cdq->valid_mem))
 		return -EINVAL;
 
-	/* CDQ traversal not implemented yet. */
-	return -EOPNOTSUPP;
+	return nvme_traversecopy_cdq(cdq, nbytes, buf);
 }
 
 /* File reference already dropped by the close path, so don't fput() */
diff --git a/drivers/nvme/host/cdq.h b/drivers/nvme/host/cdq.h
index a8c714ab5fada4325463013c2ffb23a117cd8423..96f208264c6144d26aa4ffc34854bb16d3f19af9 100644
--- a/drivers/nvme/host/cdq.h
+++ b/drivers/nvme/host/cdq.h
@@ -9,6 +9,8 @@
 #include "nvme.h"
 
 #define NVME_CDQ_MQ_ENTRY_NRBYTES	32
+#define NVME_CDQ_MQ_PHASE_MASK		0x1
+#define NVME_CDQ_MQ_PHASE_OFFSET	(NVME_CDQ_MQ_ENTRY_NRBYTES - 1)
 
 /*
  * The CDQ backing is a set of coherent DMA chunks expressed in
@@ -17,6 +19,7 @@
 #define NVME_CDQ_CHUNK_ORDER		2
 #define NVME_CDQ_CHUNK_SIZE		(PAGE_SIZE << NVME_CDQ_CHUNK_ORDER)
 #define NVME_CDQ_PAGES_PER_CHUNK	(NVME_CDQ_CHUNK_SIZE / NVME_CTRL_PAGE_SIZE)
+#define NVME_CDQ_MQ_ENTRY_PER_CHUNK	(NVME_CDQ_CHUNK_SIZE / NVME_CDQ_MQ_ENTRY_NRBYTES)
 
 /* Max PRP List pages we are willing to chain to describe a discontiguous CDQ. */
 #define MAX_NR_CDQ_PRPS		20
@@ -45,6 +48,10 @@ struct cdq_nvme_queue {
 	/* True if mem for chunks and prps is valid */
 	bool valid_mem;
 
+	/* How far the CDQ was consumed by the host */
+	u32 host_head;
+	u8 phase_bit;
+
 	/* Manage refs for read FD and controller xarray */
 	struct kref ref;
 };

-- 
2.50.1

