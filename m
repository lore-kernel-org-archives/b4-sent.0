From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 14 Jul 2025 11:15:37 +0200
Subject: [PATCH RFC 6/8] nvme: Add a release ops to cdq file ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-jag-cdq-v1-6-01e027d256d5@kernel.org>
References: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
In-Reply-To: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: Klaus Jensen <k.jensen@samsung.com>, linux-nvme@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1127;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=EHkkGMG990RW999qEL6xHGIOP1Da82Ed2KKxscvok4M=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGh0yuzCPnoh3XuDoNYYYg9pd/tFQFMVzY5jm
 1hhsoBW+XgbM4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJodMrsAAoJELqXzVK3
 lkFPKH0L/0qsA6rA7Qq1k+nKg8zYcsedZJbW9A+9Njb5EJ9ozssyLfDi/X3F7mERgG3L4s06IMM
 lIXAJW6WeOi/bsENRotDv1nJmzZYbHF2zEjNjYnM0WgGbOzxHk1vgAmvd8ZXk61GAqal+gm4MsB
 7CxCoxBnFGCmzkpuOdqJrMM2FGQ8JROLPd0tqkwwbT0G+BvFp6UU8luqhfy9T8BVohqsBriRiRL
 tpUfm7nj9DqOhLMNMUhUbkbWdANEGzhvSioV2Dxtd+JbGMzIH72e4wZAG3Vrf7Pl5X+yP/IFd4d
 fxxHgq1CEQnRJscAFA05rYDaTQjKVgHkfZqNAhAkRtyetX4OU9B+MrcQ/pMze3S5MrrfAsEmc0T
 mT++IqnKhop6Jv88b6GXHvIWzgsPg+SfttxF91MNHrxJEJ9O8AvLuNTxB24lh+vQ5SzLG65cxzN
 ccvbUNGREcQtQXRNn3qGPeKVjA7X49tGvIPT/QcJvCXbDB6WQ6CGllmjtwMKNVsj8EHt2j02x97
 HE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When user space calls close on the file descriptor or crashes,
nvme_cdq_fops_release will ensure everything related to the CDQ is
properly released.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/core.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 427e482530bdb5c7124d1230f35693ba756ce4d9..4745b961c6b874375ff4399c104f312b5ac608b8 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -1313,10 +1313,18 @@ static ssize_t nvme_cdq_fops_read(struct file *filep, char __user *buf,
 	return nvme_cdq_traverse(cdq, nbytes, buf);
 }
 
+static int nvme_cdq_fops_release(struct inode *inode, struct file *filep)
+{
+	struct cdq_nvme_queue *cdq = filep->private_data;
+
+	return nvme_cdq_delete(cdq->ctrl, cdq->cdq_id);
+}
+
 static const struct file_operations cdq_fops = {
 	.owner		= THIS_MODULE,
 	.open		= nonseekable_open,
 	.read		= nvme_cdq_fops_read,
+	.release	= nvme_cdq_fops_release,
 };
 
 static int nvme_cdq_fd(struct cdq_nvme_queue *cdq, int *fdno)

-- 
2.47.2

