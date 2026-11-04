From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:57 -0600
Subject: [PATCH v4 16/25] dmaengine: sdxi: Add completion status block API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-16-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=10310;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=j3/k2eey6V1fTjlbEcUw0J0Ib+RLO8BnpFndZkQrQuo=;
 b=FvoUQFy+G7v1ZNLSls1amzLgHZt4W9q2+4zjA0qVRLskW0QY54PAG8gFoXI8bMwAeqFh5bGvP
 GO2WgVmxyYTAF/jxWrs/D2YyBtWsILoaW/qaUHNLZfPa/osFBZmCAsK
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce completion status handling and a fixed-capacity pool owned by
each context. Only the 32-byte-aligned status blocks are DMA-visible;
a private bitmap and spinlock track claims independently of descriptor
ring indices.

Preallocate storage during context allocation. Claiming and initializing
a block cannot allocate memory and fails only when capacity is exhausted.
Provide a bounded, killable wait for administrative callers, and wake
waiters when blocks are returned. Release blocks only after consumption,
unpublished rollback, or hardware quiescence; destroy the pool only when
hardware and software no longer access it.

Represent a completion-status block by its CPU pointer and DMA address.
Check the little-endian signal with READ_ONCE(), then use dma_rmb() before
consuming error status or operation results. Polling returns success,
-EIO for a terminal error, or -ETIMEDOUT without relinquishing ownership.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/Makefile     |   1 +
 drivers/dma/sdxi/completion.c | 152 ++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/completion.h |  48 +++++++++++++
 drivers/dma/sdxi/context.c    |   7 ++
 drivers/dma/sdxi/context.h    |   4 ++
 drivers/dma/sdxi/hw.h         |  15 +++++
 6 files changed, 227 insertions(+)

diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
index 00e3f1cb0808..eacad504a816 100644
--- a/drivers/dma/sdxi/Makefile
+++ b/drivers/dma/sdxi/Makefile
@@ -1,6 +1,7 @@
 # SPDX-License-Identifier: GPL-2.0
 obj-$(CONFIG_SDXI_CORE) += sdxi-core.o
 sdxi-core-y := \
+	completion.o  \
 	context.o     \
 	device.o      \
 	ring.o
diff --git a/drivers/dma/sdxi/completion.c b/drivers/dma/sdxi/completion.c
new file mode 100644
index 000000000000..c07a0fc101c8
--- /dev/null
+++ b/drivers/dma/sdxi/completion.c
@@ -0,0 +1,152 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SDXI Descriptor Completion Status Block handling.
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+#include <linux/bitfield.h>
+#include <linux/bitmap.h>
+#include <linux/dma-mapping.h>
+#include <linux/iopoll.h>
+#include <linux/slab.h>
+#include <linux/spinlock.h>
+#include <linux/wait.h>
+
+#include "completion.h"
+#include "hw.h"
+
+/* Only the status blocks themselves are visible to hardware. */
+struct sdxi_cst_pool {
+	struct sdxi_cst_blk *blocks;
+	dma_addr_t dma;
+	unsigned int count;
+	spinlock_t lock;
+	wait_queue_head_t wait;
+	unsigned long *allocated;
+};
+
+static void sdxi_cst_pool_init(struct sdxi_cst_pool *pool, unsigned int count)
+{
+	pool->count = count;
+	spin_lock_init(&pool->lock);
+	init_waitqueue_head(&pool->wait);
+}
+
+struct sdxi_cst_pool *sdxi_cst_pool_create(struct sdxi_dev *sdxi,
+					unsigned int count)
+{
+	struct sdxi_cst_pool *pool;
+
+	if (!count)
+		return NULL;
+
+	pool = kzalloc_obj(*pool, GFP_KERNEL);
+	if (!pool)
+		return NULL;
+
+	pool->allocated = bitmap_zalloc(count, GFP_KERNEL);
+	if (!pool->allocated) {
+		kfree(pool);
+		return NULL;
+	}
+
+	/* SDXI 1.0a 6.1.1 requires a 32-byte-aligned completion block. */
+	pool->blocks = dma_alloc_coherent(sdxi->dev,
+					 array_size(count, sizeof(*pool->blocks)),
+					 &pool->dma, GFP_KERNEL);
+	if (!pool->blocks) {
+		bitmap_free(pool->allocated);
+		kfree(pool);
+		return NULL;
+	}
+
+	sdxi_cst_pool_init(pool, count);
+	return pool;
+}
+
+void sdxi_cst_pool_destroy(struct sdxi_dev *sdxi, struct sdxi_cst_pool *pool)
+{
+	dma_free_coherent(sdxi->dev, array_size(pool->count, sizeof(*pool->blocks)),
+			  pool->blocks, pool->dma);
+	bitmap_free(pool->allocated);
+	kfree(pool);
+}
+
+bool sdxi_cst_pool_get(struct sdxi_cst_pool *pool, struct sdxi_completion *comp)
+{
+	unsigned long flags;
+	unsigned int index;
+
+	spin_lock_irqsave(&pool->lock, flags);
+	index = find_first_zero_bit(pool->allocated, pool->count);
+	if (index < pool->count)
+		__set_bit(index, pool->allocated);
+	spin_unlock_irqrestore(&pool->lock, flags);
+	if (index == pool->count)
+		return false;
+
+	comp->cst_blk = &pool->blocks[index];
+	comp->cst_blk_dma = pool->dma + index * sizeof(*pool->blocks);
+	sdxi_cst_blk_init(comp->cst_blk);
+	return true;
+}
+
+int sdxi_cst_pool_get_wait(struct sdxi_cst_pool *pool,
+			 struct sdxi_completion *comp)
+{
+	long ret;
+
+	ret = wait_event_killable_timeout(pool->wait,
+					 sdxi_cst_pool_get(pool, comp), HZ);
+	if (ret < 0)
+		return ret;
+	return ret ? 0 : -ETIMEDOUT;
+}
+
+void sdxi_cst_pool_put(struct sdxi_cst_pool *pool, struct sdxi_cst_blk *cst)
+{
+	unsigned int index = cst - pool->blocks;
+	unsigned long flags;
+
+	if (WARN_ON_ONCE(index >= pool->count))
+		return;
+
+	spin_lock_irqsave(&pool->lock, flags);
+	WARN_ON_ONCE(!__test_and_clear_bit(index, pool->allocated));
+	spin_unlock_irqrestore(&pool->lock, flags);
+	wake_up_all(&pool->wait);
+}
+
+
+enum sdxi_completion_state sdxi_cst_blk_check(const struct sdxi_cst_blk *cst)
+{
+	u64 signal = le64_to_cpu(READ_ONCE(cst->signal));
+
+	if (signal != SDXI_CST_BLK_SIGNAL_TERMINAL)
+		return SDXI_COMPLETION_PENDING;
+	/*
+	 * The final ER state (and the operation's effects) are
+	 * guaranteed visible only after a cleared signal is observed.
+	 * See SDXI 1.0 5.6 Memory Consistency Model.
+	 */
+	dma_rmb();
+
+	if (FIELD_GET(SDXI_CST_BLK_ER, le32_to_cpu(cst->flags)))
+		return SDXI_COMPLETION_ERROR;
+
+	return SDXI_COMPLETION_DONE;
+}
+
+int sdxi_cst_blk_poll(const struct sdxi_cst_blk *cst)
+{
+	enum sdxi_completion_state state;
+	int ret;
+
+	ret = read_poll_timeout(sdxi_cst_blk_check, state,
+				state != SDXI_COMPLETION_PENDING,
+				10, USEC_PER_SEC, false, cst);
+	if (ret)
+		return ret;		/* -ETIMEDOUT */
+
+	return state == SDXI_COMPLETION_ERROR ? -EIO : 0;
+}
diff --git a/drivers/dma/sdxi/completion.h b/drivers/dma/sdxi/completion.h
new file mode 100644
index 000000000000..f91f44b9b516
--- /dev/null
+++ b/drivers/dma/sdxi/completion.h
@@ -0,0 +1,48 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/* Copyright Advanced Micro Devices, Inc. */
+#ifndef DMA_SDXI_COMPLETION_H
+#define DMA_SDXI_COMPLETION_H
+
+#include <linux/compiler_attributes.h>
+#include "sdxi.h"
+#include "hw.h"
+
+
+/* A completion status block and the device address the hardware needs. */
+struct sdxi_completion {
+	struct sdxi_cst_blk *cst_blk;
+	dma_addr_t cst_blk_dma;
+};
+
+struct sdxi_cst_pool;
+
+/* Software completion states derived from CST_BLK. */
+enum sdxi_completion_state {
+	SDXI_COMPLETION_PENDING,
+	SDXI_COMPLETION_DONE,
+	SDXI_COMPLETION_ERROR,
+};
+
+struct sdxi_cst_pool *sdxi_cst_pool_create(struct sdxi_dev *sdxi,
+					unsigned int count);
+/* Hardware and software must no longer access any blocks before destruction. */
+void sdxi_cst_pool_destroy(struct sdxi_dev *sdxi, struct sdxi_cst_pool *pool);
+/* Claims and initializes a block; false means the fixed pool is exhausted. */
+bool sdxi_cst_pool_get(struct sdxi_cst_pool *pool, struct sdxi_completion *comp);
+int sdxi_cst_pool_get_wait(struct sdxi_cst_pool *pool,
+			 struct sdxi_completion *comp);
+/* Release only after consumption, unpublished rollback, or hardware quiescence. */
+void sdxi_cst_pool_put(struct sdxi_cst_pool *pool, struct sdxi_cst_blk *cst);
+
+
+static inline void sdxi_cst_blk_init(struct sdxi_cst_blk *cst)
+{
+	*cst = (typeof(*cst)) {
+		.signal = cpu_to_le64(SDXI_CST_BLK_SIGNAL_INIT),
+	};
+}
+
+int __must_check sdxi_cst_blk_poll(const struct sdxi_cst_blk *cst);
+enum sdxi_completion_state sdxi_cst_blk_check(const struct sdxi_cst_blk *cst);
+
+#endif /* DMA_SDXI_COMPLETION_H */
diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index 956bb06f9499..60cc812df204 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -22,6 +22,7 @@
 #include <asm/barrier.h>
 #include <asm/rwonce.h>
 
+#include "completion.h"
 #include "context.h"
 #include "hw.h"
 #include "ring.h"
@@ -56,6 +57,8 @@ static void sdxi_free_cxt(struct sdxi_cxt *cxt)
 	if (cxt->akey_table)
 		dma_free_coherent(sdxi->dev, sizeof(*cxt->akey_table),
 				  cxt->akey_table, cxt->akey_table_dma);
+	if (cxt->cst_pool)
+		sdxi_cst_pool_destroy(sdxi, cxt->cst_pool);
 	if (cxt->sq)
 		sdxi_sq_free(sdxi, cxt->sq);
 	ida_destroy(&cxt->akey_ida);
@@ -85,6 +88,10 @@ static struct sdxi_cxt *sdxi_alloc_cxt(struct sdxi_dev *sdxi)
 	if (!cxt->sq)
 		return NULL;
 
+	cxt->cst_pool = sdxi_cst_pool_create(sdxi, DEFAULT_DESC_RING_ENTRIES);
+	if (!cxt->cst_pool)
+		return NULL;
+
 	cxt->akey_table = dma_alloc_coherent(dev, sizeof(*cxt->akey_table),
 					     &cxt->akey_table_dma, GFP_KERNEL);
 	if (!cxt->akey_table)
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index cad5a153ec22..94e0fc45f281 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -16,6 +16,9 @@
 #include "sdxi.h"
 #include "submission.h"
 
+struct sdxi_completion;
+struct sdxi_cst_pool;
+
 /* Use a 4 KiB AKey table, the minimum architectural size. */
 struct sdxi_akey_table {
 	struct sdxi_akey_ent entry[SZ_4K / sizeof(struct sdxi_akey_ent)];
@@ -40,6 +43,7 @@ struct sdxi_cxt {
 	dma_addr_t akey_table_dma;
 
 	struct sdxi_sq *sq;
+	struct sdxi_cst_pool *cst_pool;
 
 	struct sdxi_ring_state *ring_state;
 };
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index b333e091c583..c1bff631a5ae 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -110,6 +110,21 @@ struct sdxi_akey_ent {
 } __packed __aligned(16);
 static_assert(sizeof(struct sdxi_akey_ent) == 16);
 
+/* SDXI 1.0 Table 6-4: CST_BLK (Completion Status Block) */
+struct sdxi_cst_blk {
+	__le64 signal;
+	__le32 flags;
+#define SDXI_CST_BLK_ER BIT(31)
+	__u8 rsvd_0[20];
+} __packed __aligned(32);
+static_assert(sizeof(struct sdxi_cst_blk) == 32);
+
+/* SDXI 1.0 4.4.2 Completion-Status Modes */
+enum sdxi_cst_blk_signal {
+	SDXI_CST_BLK_SIGNAL_TERMINAL = 0,
+	SDXI_CST_BLK_SIGNAL_INIT     = 1,
+};
+
 struct sdxi_desc {
 	union {
 		/*

-- 
2.56.0

