From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 24 Apr 2026 13:37:52 +0200
Subject: [PATCH RFC 2/5] nvme: Add CDQ data structures to host driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260424-jag-cdq-lkml-v1-2-d773343a717c@kernel.org>
References: <20260424-jag-cdq-lkml-v1-0-d773343a717c@kernel.org>
In-Reply-To: <20260424-jag-cdq-lkml-v1-0-d773343a717c@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1538;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=DyeHMsiA53Hg5qFneyAbch7hM4sTqy1Q2kOzjNNoSVs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGnrVikL1ufBNaxO3jg3y3Fffg+8zf+zzw/B0
 P4HbfBBQDTamokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJp61YpAAoJELqXzVK3
 lkFPV4kL/0d5y27c0jUzAL+8oyMRSaia0vmNA+oFoLsBT8frQWdmpj2QI0FNzwgs5iW2L+PxQoy
 uLAlgCpABgAtn+4ya4fqJV3c/sZW14Fgvg6rKfU2NevWJftYVqiRiIfm61a4zwwCr+qhby2WhFN
 0GHodx3+LUgRCa/NVVGB5SoE1sYevG/IO8T9zpw10aUJ2x6CuO+b9Q/JScvqUAxq7gCx6y6YJ6x
 hoiLk5oXsP7USr164PHKFhntwcIPlYCFcI+7QiU8MIMu+z3JGxxaNbavNPJbAkulfKhCBaa4L7S
 FSZ0V1ikIBLK3gy0LwfYz7EI6nzDdP8gTQ0e0NZ9ZsCGc7R73xiUwZyz0Y32JYoPuOSPJqUSZvp
 lSBtM3Svfhk7r6IoL5/+KiV8IBctEvH63Jg6f/+8wEdCJXx81IA4GRpyYif4z80eyjgV/fNMuma
 +Amx+WANJbExznXr5EPSB6NzOFV7EmQv3hu9jy6nShqDzvtMe5Zf7/LE9uPIgZKOTj1lOip9a27
 m0=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add host-side Controller Data Queue (CDQ) data structures and function
declarations to drivers/nvme/host/nvme.h:
- Add cdqs xarray to nvme_ctrl for managing CDQ instances
- Add cdq_nvme_queue structure containing:
  - DMA mapping state
  - PRP list management
  - eventfd context for tail pointer event notifications

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/nvme/host/nvme.h | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/nvme/host/nvme.h b/drivers/nvme/host/nvme.h
index 9971045dbc05e9bb9d7fa32ad540fd107d8c8b83..30d5052c7728c0d5c5e8772ff531bc672e96940f 100644
--- a/drivers/nvme/host/nvme.h
+++ b/drivers/nvme/host/nvme.h
@@ -466,6 +466,7 @@ struct nvme_ctrl {
 	enum nvme_dctype dctype;
 
 	u16			awupf; /* 0's based value. */
+	struct xarray cdqs; /* Controller Data Queue */
 };
 
 static inline enum nvme_ctrl_state nvme_ctrl_state(struct nvme_ctrl *ctrl)
@@ -619,6 +620,20 @@ static inline unsigned long nvme_get_virt_boundary(struct nvme_ctrl *ctrl,
 	return NVME_CTRL_PAGE_SIZE - 1;
 }
 
+#define MAX_NR_CDQ_PRPS		20
+struct cdq_nvme_queue {
+	struct nvme_ctrl *ctrl;
+	__u32	size_nbyte;
+	u16 cdq_id;
+	struct eventfd_ctx *tpt_efd_ctx;
+	struct sg_table sgt;
+	struct page **pages;
+	unsigned long nr_pages;
+	void *prp_lists[MAX_NR_CDQ_PRPS];
+	dma_addr_t prp_lists_dma[MAX_NR_CDQ_PRPS];
+	u32 nr_prp_lists; /*number of PRP lists*/
+};
+
 struct nvme_ctrl_ops {
 	const char *name;
 	struct module *module;

-- 
2.50.1

