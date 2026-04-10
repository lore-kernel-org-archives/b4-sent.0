From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:25 -0500
Subject: [PATCH 15/23] dmaengine: sdxi: Per-context access key (AKey) table
 entry allocator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-15-1d184cb5c60a@amd.com>
References: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
In-Reply-To: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
To: Vinod Koul <vkoul@kernel.org>
Cc: Wei Huang <wei.huang2@amd.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Jonathan Cameron <jonathan.cameron@huawei.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, PradeepVineshReddy.Kodamati@amd.com, 
 John.Kariuki@amd.com, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dmaengine@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=3996;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=xM2FGHLq6TQB7ArRAf3V9Xhjrb67k3x/AkY1HQPO5Q4=;
 b=rTIQiw+zTFxDWBJcNZ1EhzZHuGqJ/VcHG0jcXFMHnx9gZ0q7el1Y4xTktMb48O5pJLc0z6jWz
 mxATmGFkhIWBSOQU4z+Y2mBWMmA1NhqSQFaNRipagID+VrPDfEAFsh3
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each SDXI context has a table of access keys (AKeys). SDXI descriptors
submitted to a context may refer to an AKey associated with that
context by its index in the table. AKeys describe properties of the
access that the descriptor is to perform, such as PASID or a target
SDXI function, or an interrupt to trigger.

Use a per-context IDA to keep track of used entries in the table.
Provide sdxi_alloc_akey(), which claims an AKey table entry for the
caller to program directly; sdxi_akey_index(), which returns the
entry's index for programming into descriptors the caller intends to
submit; and sdxi_free_akey(), which clears the entry and makes it
available again.

The DMA engine provider is currently the only user and allocates a
single entry that encodes the access properties for copy operations
and a completion interrupt. More complex use patterns are possible
when user space gains access to SDXI contexts (not in this series).

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.c |  5 +++++
 drivers/dma/sdxi/context.h | 24 ++++++++++++++++++++++++
 2 files changed, 29 insertions(+)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index 792b5032203b..04e0d3e6a337 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -15,6 +15,7 @@
 #include <linux/dma-mapping.h>
 #include <linux/dmapool.h>
 #include <linux/errno.h>
+#include <linux/idr.h>
 #include <linux/iommu.h>
 #include <linux/io-64-nonatomic-lo-hi.h>
 #include <linux/slab.h>
@@ -61,6 +62,7 @@ static void sdxi_free_cxt(struct sdxi_cxt *cxt)
 		dma_free_coherent(sdxi_to_dev(sdxi), sq->ring_size,
 				  sq->desc_ring, sq->ring_dma);
 	kfree(cxt->sq);
+	ida_destroy(&cxt->akey_ida);
 	kfree(cxt->ring_state);
 	kfree(cxt);
 }
@@ -381,6 +383,7 @@ int sdxi_admin_cxt_init(struct sdxi_dev *sdxi)
 	cxt->db = sdxi->dbs + cxt->id * sdxi->db_stride;
 	sdxi_ring_state_init(cxt->ring_state, &sq->cxt_sts->read_index,
 			     sq->write_index, sq->ring_entries, sq->desc_ring);
+	ida_init(&cxt->akey_ida);
 
 	err = sdxi_publish_cxt(cxt);
 	if (err)
@@ -406,6 +409,8 @@ struct sdxi_cxt *sdxi_cxt_new(struct sdxi_dev *sdxi)
 	sq = cxt->sq;
 	sdxi_ring_state_init(cxt->ring_state, &sq->cxt_sts->read_index,
 			     sq->write_index, sq->ring_entries, sq->desc_ring);
+	ida_init(&cxt->akey_ida);
+
 	if (register_cxt(sdxi, cxt))
 		return NULL;
 
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index 9779b9aa4f86..5310e51a668c 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -6,7 +6,10 @@
 #ifndef DMA_SDXI_CONTEXT_H
 #define DMA_SDXI_CONTEXT_H
 
+#include <linux/array_size.h>
 #include <linux/dma-mapping.h>
+#include <linux/idr.h>
+#include <linux/string.h>
 #include <linux/types.h>
 
 #include "hw.h"
@@ -50,6 +53,7 @@ struct sdxi_cxt {
 	struct sdxi_cxt_ctl *cxt_ctl;
 	dma_addr_t cxt_ctl_dma;
 
+	struct ida akey_ida;
 	struct sdxi_akey_table *akey_table;
 	dma_addr_t akey_table_dma;
 
@@ -75,4 +79,24 @@ static inline bool sdxi_cxt_is_admin(const struct sdxi_cxt *cxt)
 
 void sdxi_cxt_push_doorbell(struct sdxi_cxt *cxt, u64 index);
 
+static inline struct sdxi_akey_ent *sdxi_alloc_akey(struct sdxi_cxt *cxt)
+{
+	unsigned int max = ARRAY_SIZE(cxt->akey_table->entry) - 1;
+	int idx = ida_alloc_max(&cxt->akey_ida, max, GFP_KERNEL);
+
+	return idx < 0 ? NULL : &cxt->akey_table->entry[idx];
+}
+
+static inline unsigned int sdxi_akey_index(const struct sdxi_cxt *cxt,
+					   const struct sdxi_akey_ent *akey)
+{
+	return akey - &cxt->akey_table->entry[0];
+}
+
+static inline void sdxi_free_akey(struct sdxi_cxt *cxt, struct sdxi_akey_ent *akey)
+{
+	memset(akey, 0, sizeof(*akey));
+	ida_free(&cxt->akey_ida, sdxi_akey_index(cxt, akey));
+}
+
 #endif /* DMA_SDXI_CONTEXT_H */

-- 
2.53.0

