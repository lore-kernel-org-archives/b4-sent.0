From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:49 -0600
Subject: [PATCH v4 08/25] dmaengine: sdxi: Introduce submission queue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-8-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=3882;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=yJE7exedP3qwV2lj7ohEV56qZOREBafNUbGQtilO+Eg=;
 b=8dwevBUGia9DwkprGrFQzW3zh94wwQ4KItbhEwb3vlwmc814srjmAc8oHOHv5ktxnM1z9HUya
 92euDqUgqkkD9a8Yrf+2UiHkKBWyPtaIWlxrBXgM3crM+inkxtQqUjV
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the sdxi_sq (submission queue) type and APIs that act on it. The
sq contains three control structures shared with hardware: descriptor
ring, write index, and context status block (which contains the read
index). Define the hardware context-status and generic descriptor
layouts, including assertions for their sizes.

The descriptor ring requires only 64-byte alignment, so it's practical
to implement it as a flexible array member. The write index and context
status are small enough to place in the struct as well, so we have a
single DMA coherent allocation to manage.

Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/hw.h         | 25 ++++++++++++++++
 drivers/dma/sdxi/submission.h | 66 +++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 91 insertions(+)

diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index 82c6b4a20cde..82a9c20d8bcf 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -12,6 +12,7 @@
 
 #include <linux/bits.h>
 #include <linux/build_bug.h>
+#include <linux/stddef.h>
 #include <linux/types.h>
 #include <asm/byteorder.h>
 
@@ -58,4 +59,28 @@ struct sdxi_cxt_ctl {
 } __packed __aligned(64);
 static_assert(sizeof(struct sdxi_cxt_ctl) == 64);
 
+/* SDXI 1.0 Table 3-5: Context Status (CXT_STS) */
+struct sdxi_cxt_sts {
+	__u8 state;
+	__u8 misc0;
+	__u8 rsvd_0[6];
+	__le64 read_index;
+} __packed __aligned(16);
+static_assert(sizeof(struct sdxi_cxt_sts) == 16);
+
+struct sdxi_desc {
+	union {
+		/*
+		 * SDXI 1.0 Table 6-3: DSC_GENERIC SDXI Descriptor
+		 * Common Header and Footer Format
+		 */
+		struct_group_tagged(sdxi_dsc_generic, generic,
+			__le32 opcode;
+			__u8 operation[52];
+			__le64 csb_ptr;
+		);
+	};
+} __packed __aligned(64);
+static_assert(sizeof(struct sdxi_desc) == 64);
+
 #endif /* DMA_SDXI_HW_H */
diff --git a/drivers/dma/sdxi/submission.h b/drivers/dma/sdxi/submission.h
new file mode 100644
index 000000000000..d60897a373c9
--- /dev/null
+++ b/drivers/dma/sdxi/submission.h
@@ -0,0 +1,66 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/* Copyright Advanced Micro Devices, Inc. */
+#ifndef DMA_SDXI_SUBMISSION_H
+#define DMA_SDXI_SUBMISSION_H
+
+#include <linux/cache.h>
+#include <linux/compiler_attributes.h>
+#include <linux/dma-mapping.h>
+#include <linux/overflow.h>
+#include <linux/types.h>
+
+#include "hw.h"
+#include "sdxi.h"
+
+/*
+ * Submission queue: one DMA-coherent allocation holding the
+ * descriptor ring, write index, and context status (which includes
+ * the read index). cxt_sts gets its own cache line to avoid sharing
+ * with write_index.
+ */
+struct sdxi_sq {
+	dma_addr_t handle;
+	void __iomem *doorbell;
+	__le64 write_index;
+	u32 count;
+	struct sdxi_cxt_sts cxt_sts ____cacheline_aligned;
+	struct sdxi_desc ring[] __counted_by(count);
+};
+
+static inline struct sdxi_sq *sdxi_sq_alloc(struct sdxi_dev *sdxi, unsigned int count)
+{
+	dma_addr_t handle;
+	struct sdxi_sq *sq;
+	size_t sz = struct_size(sq, ring, count);
+
+	sq = dma_alloc_coherent(sdxi->dev, sz, &handle, GFP_KERNEL);
+	if (!sq)
+		return NULL;
+
+	sq->count = count;
+	sq->handle = handle;
+	return sq;
+}
+
+static inline void sdxi_sq_free(struct sdxi_dev *sdxi, struct sdxi_sq *sq)
+{
+	dma_free_coherent(sdxi->dev, struct_size(sq, ring, sq->count), sq,
+			  sq->handle);
+}
+
+static inline dma_addr_t sdxi_sq_ring_dma(const struct sdxi_sq *sq)
+{
+	return sq->handle + struct_offset(sq, ring);
+}
+
+static inline dma_addr_t sdxi_sq_write_index_dma(const struct sdxi_sq *sq)
+{
+	return sq->handle + struct_offset(sq, write_index);
+}
+
+static inline dma_addr_t sdxi_sq_cxt_sts_dma(const struct sdxi_sq *sq)
+{
+	return sq->handle + struct_offset(sq, cxt_sts);
+}
+
+#endif /* DMA_SDXI_SUBMISSION_H */

-- 
2.56.0

