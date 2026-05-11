From: Nathan Lynch <nathan.lynch@amd.com>
Date: Mon, 11 May 2026 14:16:29 -0500
Subject: [PATCH v2 17/23] dmaengine: sdxi: Add completion status block API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-sdxi-base-v2-17-889cfed17e3f@amd.com>
References: <20260511-sdxi-base-v2-0-889cfed17e3f@amd.com>
In-Reply-To: <20260511-sdxi-base-v2-0-889cfed17e3f@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Bjorn Helgaas <bhelgaas@google.com>, 
 David Rientjes <rientjes@google.com>, John.Kariuki@amd.com, 
 Kinsey Ho <kinseyho@google.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 PradeepVineshReddy.Kodamati@amd.com, Shivank Garg <shivankg@amd.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, Wei Huang <wei.huang2@amd.com>, 
 Wei Xu <weixugc@google.com>, dmaengine@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, Frank Li <Frank.Li@nxp.com>, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778526994; l=5618;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=9fepl59gMiRbxFIPaJqwOukhNQRqs6c+J1CU6zShfFU=;
 b=JpF0ZU5r3GJvX0LRqArHM9n+SCqk8dB/BqWXERC9jGVXfTUUFG7xcMA1PC763C2cd6m4oKvAM
 CD3kqs9A2fwBNE1Wuw9o8DnpocPdkHSvyirLx6OUelSNd5aO+f5ktdP
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce an API for managing completion status blocks. These are
DMA-coherent buffers that may be optionally attached to SDXI
descriptors to signal completion. The SDXI implementation clears the
signal field (initialized to 1) upon completion, setting an
error bit in the flags field if problems were encountered executing
the descriptor.

Callers allocate completion blocks from a per-device DMA pool via
sdxi_completion_alloc(). sdxi_completion_attach() associates a
completion with a descriptor by encoding the completion's DMA address
into the descriptor's csb_ptr field.

sdxi_completion_poll() busy-waits until the signal field is cleared by
the implementation, and is intended for descriptors that are expected
to execute quickly.

sdxi_completion_signaled() and sdxi_completion_errored() query the
signal field and error flag of the completion, respectively.

struct sdxi_completion is kept opaque to callers. A DEFINE_FREE
cleanup handler is provided.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/Makefile     |  1 +
 drivers/dma/sdxi/completion.c | 87 +++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/completion.h | 25 +++++++++++++
 drivers/dma/sdxi/hw.h         |  1 +
 4 files changed, 114 insertions(+)

diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
index 372f793c15b1..dd08f4a5f723 100644
--- a/drivers/dma/sdxi/Makefile
+++ b/drivers/dma/sdxi/Makefile
@@ -2,6 +2,7 @@
 obj-$(CONFIG_SDXI) += sdxi.o
 
 sdxi-objs += \
+	completion.o  \
 	context.o     \
 	device.o      \
 	ring.o
diff --git a/drivers/dma/sdxi/completion.c b/drivers/dma/sdxi/completion.c
new file mode 100644
index 000000000000..7ffd034b129b
--- /dev/null
+++ b/drivers/dma/sdxi/completion.c
@@ -0,0 +1,87 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SDXI Descriptor Completion Status Block handling.
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+#include <linux/cleanup.h>
+#include <linux/dma-mapping.h>
+#include <linux/dmapool.h>
+#include <linux/jiffies.h>
+#include <linux/slab.h>
+
+#include "completion.h"
+#include "descriptor.h"
+#include "hw.h"
+
+struct sdxi_completion {
+	struct sdxi_dev *sdxi;
+	struct sdxi_cst_blk *cst_blk;
+	dma_addr_t cst_blk_dma;
+};
+
+struct sdxi_completion *sdxi_completion_alloc(struct sdxi_dev *sdxi)
+{
+	struct sdxi_cst_blk *cst_blk;
+	dma_addr_t cst_blk_dma;
+
+	/*
+	 * Assume callers can't tolerate GFP_KERNEL and use
+	 * GFP_NOWAIT. Add a gfp_t flags parameter if that changes.
+	 */
+	struct sdxi_completion *sc __free(kfree) = kmalloc(sizeof(*sc), GFP_NOWAIT);
+	if (!sc)
+		return NULL;
+
+	cst_blk = dma_pool_zalloc(sdxi->cst_blk_pool, GFP_NOWAIT, &cst_blk_dma);
+	if (!cst_blk)
+		return NULL;
+
+	cst_blk->signal = cpu_to_le64(1);
+
+	*sc = (typeof(*sc)) {
+		.sdxi        = sdxi,
+		.cst_blk     = cst_blk,
+		.cst_blk_dma = cst_blk_dma,
+	};
+
+	return_ptr(sc);
+}
+
+void sdxi_completion_free(struct sdxi_completion *sc)
+{
+	dma_pool_free(sc->sdxi->cst_blk_pool, sc->cst_blk, sc->cst_blk_dma);
+	kfree(sc);
+}
+
+int sdxi_completion_poll(const struct sdxi_completion *sc)
+{
+	unsigned long deadline = jiffies + msecs_to_jiffies(1000);
+
+	while (le64_to_cpu(READ_ONCE(sc->cst_blk->signal)) != 0) {
+		if (time_after(jiffies, deadline))
+			return -ETIMEDOUT;
+		cpu_relax();
+	}
+
+	return sdxi_completion_errored(sc) ? -EIO : 0;
+}
+
+bool sdxi_completion_signaled(const struct sdxi_completion *sc)
+{
+	dma_rmb();
+	return (sc->cst_blk->signal == 0);
+}
+
+bool sdxi_completion_errored(const struct sdxi_completion *sc)
+{
+	dma_rmb();
+	return FIELD_GET(SDXI_CST_BLK_ER_BIT, le32_to_cpu(sc->cst_blk->flags));
+}
+
+
+void sdxi_completion_attach(struct sdxi_desc *desc,
+			    const struct sdxi_completion *cs)
+{
+	sdxi_desc_set_csb(desc, cs->cst_blk_dma);
+}
diff --git a/drivers/dma/sdxi/completion.h b/drivers/dma/sdxi/completion.h
new file mode 100644
index 000000000000..2d11568ac2b9
--- /dev/null
+++ b/drivers/dma/sdxi/completion.h
@@ -0,0 +1,25 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/* Copyright Advanced Micro Devices, Inc. */
+#ifndef DMA_SDXI_COMPLETION_H
+#define DMA_SDXI_COMPLETION_H
+
+#include <linux/compiler_attributes.h>
+#include "sdxi.h"
+
+/*
+ * Polled completion status block that can be attached to a
+ * descriptor.
+ */
+struct sdxi_completion;
+struct sdxi_desc;
+struct sdxi_completion *sdxi_completion_alloc(struct sdxi_dev *sdxi);
+void sdxi_completion_free(struct sdxi_completion *sc);
+int __must_check sdxi_completion_poll(const struct sdxi_completion *sc);
+void sdxi_completion_attach(struct sdxi_desc *desc,
+			    const struct sdxi_completion *sc);
+bool sdxi_completion_signaled(const struct sdxi_completion *sc);
+bool sdxi_completion_errored(const struct sdxi_completion *sc);
+
+DEFINE_FREE(sdxi_completion, struct sdxi_completion *, if (_T) sdxi_completion_free(_T))
+
+#endif /* DMA_SDXI_COMPLETION_H */
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index cb1bed2f83f2..178161588bd0 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -125,6 +125,7 @@ static_assert(sizeof(struct sdxi_akey_ent) == 16);
 struct sdxi_cst_blk {
 	__le64 signal;
 	__le32 flags;
+#define SDXI_CST_BLK_ER_BIT BIT(31)
 	__u8 rsvd_0[20];
 } __packed;
 static_assert(sizeof(struct sdxi_cst_blk) == 32);

-- 
2.54.0

