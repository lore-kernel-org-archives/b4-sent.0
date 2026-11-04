From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:54 -0600
Subject: [PATCH v4 13/25] dmaengine: sdxi: Add descriptor ring management
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-13-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=10534;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=gwpMo5yt4RWU8vsQKUuKNSDl6X5I8qYOPUC619Zy4NE=;
 b=ElzlA5xjdjg9N7bzZKBZq2ehqM65JYXVsMYDgAAVXkr2wVXlxe8A25VisVa9KLu6TJ6P47ILB
 zOR1bIJfQeWDl/XhxoVaDA9fBXhWUHespju0QyI2zBTcO6OL3Cd/WNv
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce software state and reservation helpers for driving an SDXI
submission queue. A spinlock serializes space checks and write-index
updates; blocking reservations use a bounded, killable wait.

Provide exact-size and bounded-size reservations, with descriptor access
through a ring slot carrying its index and ring state. Reservations
publish the write index and cannot be rolled back, so callers must
populate and publish every reserved slot.

Allocate and initialize ring state with each administrative or client
context, and free it during context release.

The hardware read index bounds descriptor reuse. Completion handlers
wake blocked reservations as hardware consumes slots.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/Makefile  |   3 +-
 drivers/dma/sdxi/context.c |   9 +++
 drivers/dma/sdxi/context.h |   2 +
 drivers/dma/sdxi/ring.c    | 143 +++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/ring.h    |  94 +++++++++++++++++++++++++++++
 5 files changed, 250 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
index cdf8a455077b..bfcb443f1e64 100644
--- a/drivers/dma/sdxi/Makefile
+++ b/drivers/dma/sdxi/Makefile
@@ -2,7 +2,8 @@
 obj-$(CONFIG_SDXI_CORE) += sdxi-core.o
 sdxi-core-y := \
 	context.o     \
-	device.o
+	device.o      \
+	ring.o
 
 obj-$(CONFIG_SDXI_PCI) += sdxi-pci.o
 sdxi-pci-y := pci.o
diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index f52479ecf96a..b26eec3805fb 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -23,6 +23,7 @@
 
 #include "context.h"
 #include "hw.h"
+#include "ring.h"
 #include "sdxi.h"
 #include "submission.h"
 
@@ -56,6 +57,7 @@ static void sdxi_free_cxt(struct sdxi_cxt *cxt)
 				  cxt->akey_table, cxt->akey_table_dma);
 	if (cxt->sq)
 		sdxi_sq_free(sdxi, cxt->sq);
+	kfree(cxt->ring_state);
 	kfree(cxt);
 }
 
@@ -72,6 +74,10 @@ static struct sdxi_cxt *sdxi_alloc_cxt(struct sdxi_dev *sdxi)
 
 	cxt->sdxi = sdxi;
 
+	cxt->ring_state = kzalloc_obj(*cxt->ring_state, GFP_KERNEL);
+	if (!cxt->ring_state)
+		return NULL;
+
 	cxt->sq = sdxi_sq_alloc(sdxi, DEFAULT_DESC_RING_ENTRIES);
 	if (!cxt->sq)
 		return NULL;
@@ -243,6 +249,7 @@ int sdxi_admin_cxt_init(struct sdxi_dev *sdxi)
 	sq->cxt_sts.state = FIELD_PREP(SDXI_CXT_STS_STATE, CXTV_RUN);
 	cxt->id = SDXI_ADMIN_CXT_ID;
 	cxt->sq->doorbell = sdxi->dbs + cxt->id * sdxi->db_stride;
+	sdxi_ring_state_init(cxt->ring_state, sq);
 
 	err = sdxi_publish_cxt(cxt);
 	if (err)
@@ -324,6 +331,8 @@ struct sdxi_cxt *sdxi_cxt_new(struct sdxi_dev *sdxi)
 
 	cxt->sq->doorbell = sdxi->dbs + cxt->id * sdxi->db_stride;
 
+	sdxi_ring_state_init(cxt->ring_state, cxt->sq);
+
 	if (sdxi_publish_cxt(cxt))
 		return NULL;
 
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index 28cd7ed401f8..14ce4f5f9b74 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -36,6 +36,8 @@ struct sdxi_cxt {
 	dma_addr_t akey_table_dma;
 
 	struct sdxi_sq *sq;
+
+	struct sdxi_ring_state *ring_state;
 };
 
 int sdxi_admin_cxt_init(struct sdxi_dev *sdxi);
diff --git a/drivers/dma/sdxi/ring.c b/drivers/dma/sdxi/ring.c
new file mode 100644
index 000000000000..a15c8751a7be
--- /dev/null
+++ b/drivers/dma/sdxi/ring.c
@@ -0,0 +1,143 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SDXI descriptor ring reservations and write index management
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+#include <kunit/test-bug.h>
+#include <kunit/visibility.h>
+#include <linux/io-64-nonatomic-lo-hi.h>
+#include <linux/jiffies.h>
+#include <linux/lockdep.h>
+#include <linux/range.h>
+#include <linux/sched.h>
+#include <linux/spinlock.h>
+#include <linux/types.h>
+#include <linux/wait.h>
+#include <asm/barrier.h>
+#include <asm/byteorder.h>
+#include <asm/div64.h>
+#include <asm/rwonce.h>
+
+#include "ring.h"
+#include "hw.h"
+#include "submission.h"
+
+/*
+ * Initialize ring management state from a submission queue. Caller is
+ * responsible for allocating and initializing @sq.
+ */
+void sdxi_ring_state_init(struct sdxi_ring_state *rs, struct sdxi_sq *sq)
+{
+	WARN_ON_ONCE(!sq);
+	/*
+	 * See SDXI 1.0 Table 3-1 Memory Structure Summary. Minimum
+	 * descriptor ring size in bytes is 64KB; thus 1024 64-byte
+	 * entries.
+	 */
+	WARN_ON_ONCE(sq->count < SZ_1K);
+
+	*rs = (typeof(*rs)) {
+		.sq = sq,
+	};
+	spin_lock_init(&rs->lock);
+	init_waitqueue_head(&rs->wqh);
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_ring_state_init);
+
+/*
+ * Non-blocking ring reservation. Callers must handle ring full (-EBUSY).
+ *
+ * Reserving publishes the write index before the caller has written the
+ * descriptors. Callers are required to publish every reserved slot.
+ */
+int sdxi_ring_try_reserve_range(struct sdxi_ring_state *rs, size_t min_nr,
+				size_t max_nr, struct sdxi_ring_resv *resv)
+{
+	struct sdxi_sq *sq = rs->sq;
+	u64 ridx, widx, available;
+	size_t nr;
+
+	if (!min_nr || min_nr > max_nr || max_nr > sq->count) {
+		WARN_ONCE(!kunit_get_current_test(),
+			  "Reservation of size %zu..%zu requested from ring of size %u\n",
+			  min_nr, max_nr, sq->count);
+		return -EINVAL;
+	}
+
+	guard(spinlock_irqsave)(&rs->lock);
+	/* SDXI 1.0a 5.3: Read_Index advances at execution start. */
+	ridx = le64_to_cpu(READ_ONCE(sq->cxt_sts.read_index));
+	widx = le64_to_cpu(sq->write_index);
+	if (ridx > widx)
+		return -EIO;
+	if (widx - ridx > sq->count)
+		return -EIO;
+
+	available = sq->count - (widx - ridx);
+	if (available < min_nr)
+		return -EBUSY;
+	nr = min_t(u64, max_nr, available);
+
+	/* The device reads this; it must not observe a torn value. */
+	WRITE_ONCE(sq->write_index, cpu_to_le64(widx + nr));
+	*resv = (typeof(*resv)) {
+		.rs = rs,
+		.range = {
+			.start = widx,
+			.end = widx + nr - 1,
+		},
+	};
+	return 0;
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_ring_try_reserve_range);
+
+int sdxi_ring_try_reserve(struct sdxi_ring_state *rs, size_t nr,
+			  struct sdxi_ring_resv *resv)
+{
+	return sdxi_ring_try_reserve_range(rs, nr, nr, resv);
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_ring_try_reserve);
+
+/*
+ * Wait up to one second for ring space; return early on success, a
+ * non-transient error, or a fatal signal.
+ */
+int sdxi_ring_reserve(struct sdxi_ring_state *rs, size_t nr,
+		      struct sdxi_ring_resv *resv)
+{
+	int ret, left;
+
+	left = wait_event_killable_timeout(rs->wqh,
+					   (ret = sdxi_ring_try_reserve(rs, nr, resv)) != -EBUSY,
+					   HZ);
+
+	/* success or hard error from try_reserve() */
+	if (left > 0)
+		return ret;
+
+	/* timed out */
+	if (left == 0)
+		return -ETIMEDOUT;
+
+	/* killed: -ERESTARTSYS */
+	return left;
+}
+
+/* Completion code should call this whenever descriptors have been consumed. */
+void sdxi_ring_wake_up(struct sdxi_ring_state *rs)
+{
+	wake_up_all(&rs->wqh);
+}
+
+/*
+ * Map a logical (unwrapped) ring index onto its entry. The ring size is
+ * not constrained to a power of two, hence the division.
+ */
+struct sdxi_desc *sdxi_ring_desc(const struct sdxi_ring_state *rs, u64 index)
+{
+	struct sdxi_sq *sq = rs->sq;
+
+	return &sq->ring[do_div(index, sq->count)];
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_ring_desc);
diff --git a/drivers/dma/sdxi/ring.h b/drivers/dma/sdxi/ring.h
new file mode 100644
index 000000000000..fb6c7ab36b57
--- /dev/null
+++ b/drivers/dma/sdxi/ring.h
@@ -0,0 +1,94 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/* Copyright Advanced Micro Devices, Inc. */
+#ifndef DMA_SDXI_RING_H
+#define DMA_SDXI_RING_H
+
+#include <linux/bug.h>
+#include <linux/io-64-nonatomic-lo-hi.h>
+#include <linux/range.h>
+#include <linux/spinlock.h>
+#include <linux/types.h>
+#include <linux/wait.h>
+#include <asm/barrier.h>
+#include <asm/byteorder.h>
+#include <asm/div64.h>
+#include <asm/rwonce.h>
+
+#include "hw.h"
+
+struct sdxi_sq;
+
+/*
+ * struct sdxi_ring_state - Software state for driving a submission queue.
+ *
+ * @lock: Guards the write index.
+ * @sq: The submission queue being driven.
+ * @wqh: Pending reservations.
+ */
+struct sdxi_ring_state {
+	spinlock_t lock;
+	struct sdxi_sq *sq;
+	wait_queue_head_t wqh;
+};
+
+/*
+ * A claim on a contiguous span of the ring's logical index space. The
+ * indexes are monotonic and unwrapped; sdxi_ring_desc() maps them onto
+ * ring entries.
+ */
+struct sdxi_ring_resv {
+	const struct sdxi_ring_state *rs;
+	struct range range;
+};
+
+void sdxi_ring_state_init(struct sdxi_ring_state *ring, struct sdxi_sq *sq);
+void sdxi_ring_wake_up(struct sdxi_ring_state *rs);
+int sdxi_ring_reserve(struct sdxi_ring_state *ring, size_t nr,
+		      struct sdxi_ring_resv *resv);
+int sdxi_ring_try_reserve(struct sdxi_ring_state *ring, size_t nr,
+			  struct sdxi_ring_resv *resv);
+int sdxi_ring_try_reserve_range(struct sdxi_ring_state *rs, size_t min_nr,
+				size_t max_nr, struct sdxi_ring_resv *resv);
+struct sdxi_desc *sdxi_ring_desc(const struct sdxi_ring_state *rs, u64 index);
+
+/* Number of slots held by @resv. */
+static inline size_t sdxi_ring_resv_count(const struct sdxi_ring_resv *resv)
+{
+	return range_len(&resv->range);
+}
+
+/*
+ * Logical index of slot @i of @resv, suitable for passing to
+ * sdxi_ring_desc(). @i must be less than sdxi_ring_resv_count().
+ */
+static inline u64 sdxi_ring_resv_index(const struct sdxi_ring_resv *resv,
+				       unsigned int i)
+{
+	/* Keep a caller's mistake inside the slots it owns. */
+	if (WARN_ON_ONCE(i >= sdxi_ring_resv_count(resv)))
+		return resv->range.start;
+	return resv->range.start + i;
+}
+
+/* A reserved descriptor slot identified by its ring and logical index. */
+struct sdxi_slot {
+	const struct sdxi_ring_state *rs;
+	u64 index;
+};
+
+/* Slot @i of @resv. @i must be less than sdxi_ring_resv_count(). */
+static inline struct sdxi_slot sdxi_ring_resv_slot(const struct sdxi_ring_resv *resv,
+						   unsigned int i)
+{
+	return (struct sdxi_slot) {
+		.rs = resv->rs,
+		.index = sdxi_ring_resv_index(resv, i),
+	};
+}
+
+static inline struct sdxi_desc *sdxi_slot_desc(struct sdxi_slot slot)
+{
+	return sdxi_ring_desc(slot.rs, slot.index);
+}
+
+#endif /* DMA_SDXI_RING_H */

-- 
2.56.0

