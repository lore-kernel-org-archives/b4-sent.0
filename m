From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:56 -0600
Subject: [PATCH v4 15/25] dmaengine: sdxi: Per-context access key (AKey)
 table entry allocator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-15-3668ccc7aab8@amd.com>
References: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
In-Reply-To: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Bjorn Helgaas <bhelgaas@google.com>, 
 David Rientjes <rientjes@google.com>, John.Kariuki@amd.com, 
 Jonathan Cameron <jic23@kernel.org>, Kinsey Ho <kinseyho@google.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 PradeepVineshReddy.Kodamati@amd.com, Shivank Garg <shivankg@amd.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Wei Huang <wei.huang2@amd.com>, Wei Xu <weixugc@google.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=3365;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=Zo1+a8sWpK/eHij843wg4qLlKt/M4ON13u/7GfMYhEU=;
 b=6/z6E1PqghFJVOkrE9Ols1+6AvMJqWZ+JIjKzo7SPQUrQm/BI/iurlgHxWvy9d+xwVieJjPoD
 qXKICVVYlG5BwSJpHweXjawcHEvAY5lKR91S8vAAwT+3F/nIwxlT+B9
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
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

The DMAengine provider uses one AKey for copy-buffer access and completion
interrupts.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.c |  3 +++
 drivers/dma/sdxi/context.h | 24 ++++++++++++++++++++++++
 2 files changed, 27 insertions(+)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index b26eec3805fb..956bb06f9499 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -15,6 +15,7 @@
 #include <linux/dma-mapping.h>
 #include <linux/dmapool.h>
 #include <linux/errno.h>
+#include <linux/idr.h>
 #include <linux/iommu.h>
 #include <linux/slab.h>
 #include <linux/types.h>
@@ -57,6 +58,7 @@ static void sdxi_free_cxt(struct sdxi_cxt *cxt)
 				  cxt->akey_table, cxt->akey_table_dma);
 	if (cxt->sq)
 		sdxi_sq_free(sdxi, cxt->sq);
+	ida_destroy(&cxt->akey_ida);
 	kfree(cxt->ring_state);
 	kfree(cxt);
 }
@@ -73,6 +75,7 @@ static struct sdxi_cxt *sdxi_alloc_cxt(struct sdxi_dev *sdxi)
 		return NULL;
 
 	cxt->sdxi = sdxi;
+	ida_init(&cxt->akey_ida);
 
 	cxt->ring_state = kzalloc_obj(*cxt->ring_state, GFP_KERNEL);
 	if (!cxt->ring_state)
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index 14ce4f5f9b74..cad5a153ec22 100644
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
@@ -32,6 +35,7 @@ struct sdxi_cxt {
 	struct sdxi_cxt_ctl *cxt_ctl;
 	dma_addr_t cxt_ctl_dma;
 
+	struct ida akey_ida;
 	struct sdxi_akey_table *akey_table;
 	dma_addr_t akey_table_dma;
 
@@ -54,4 +58,24 @@ static inline bool sdxi_cxt_is_admin(const struct sdxi_cxt *cxt)
 	return cxt == to_admin_cxt(cxt);
 }
 
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
2.56.0

