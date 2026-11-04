From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:59 -0600
Subject: [PATCH v4 18/25] dmaengine: sdxi: Add context submission helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-18-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=7115;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=D2VhE9T4zXLg/qsEzHpzFlwOhD/dwDNnB6nHgIPOxQE=;
 b=2EVbzrZ386lHM3wjp6DCLqX3xLNDdDUuFYM/BnGRhLcTXdbVe+aR0xRzfDn0uufViE/LR2UGl
 +U8qdvjUWcrDizt/xPbyCm5usEnIME/uPCz/fDwenUhliNP8/MotwHl
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add sdxi_cxt_submit() to consolidate optional fence and completion-status
block setup, valid-bit publication, and doorbell ringing. An optional
struct sdxi_completion input identifies storage already claimed and
initialized by the caller.

Introduce generic descriptor helpers for attaching completion storage,
setting completion-status mode, fencing, and publishing the valid bit.
Publishing orders prior descriptor writes before transferring ownership
to hardware; the helpers warn if a caller attempts to modify an already
valid descriptor.

Provide sdxi_cxt_attach_cst() for attaching completion storage without
publishing the descriptor, and sdxi_cxt_kick() for ringing a context
doorbell.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.c    | 36 ++++++++++++++++++++++++
 drivers/dma/sdxi/context.h    | 28 +++++++++++++++++++
 drivers/dma/sdxi/descriptor.h | 64 +++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/hw.h         | 10 +++++++
 4 files changed, 138 insertions(+)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index 60cc812df204..679c5cfab19d 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -24,6 +24,7 @@
 
 #include "completion.h"
 #include "context.h"
+#include "descriptor.h"
 #include "hw.h"
 #include "ring.h"
 #include "sdxi.h"
@@ -362,3 +363,38 @@ void sdxi_client_cxts_exit(struct sdxi_dev *sdxi)
 		sdxi_free_cxt(cxt);
 	xa_destroy(&sdxi->client_cxts);
 }
+
+/*
+ * Attach a claimed, initialized completion block to a descriptor slot.
+ * The descriptor is not published; the caller sets the valid bit (and
+ * kicks) once the operation is fully encoded.
+ */
+void sdxi_cxt_attach_cst(struct sdxi_slot slot,
+			 const struct sdxi_completion *comp)
+{
+	struct sdxi_desc *desc = sdxi_slot_desc(slot);
+
+	/*
+	 * We use simple (non-atomic) completion status mode only; set the
+	 * descriptor's CSR bit. See SDXI 1.0 4.4.2 Completion-Status Modes.
+	 */
+	sdxi_desc_set_csr(desc);
+	sdxi_desc_set_csb(desc, comp->cst_blk_dma);
+}
+
+void sdxi_cxt_submit(struct sdxi_cxt *cxt, struct sdxi_slot slot,
+		     const struct sdxi_completion *comp, enum sdxi_submit_flags flags)
+{
+	struct sdxi_desc *desc = sdxi_slot_desc(slot);
+
+	if (flags & SDXI_CXT_SUBMIT_FENCE)
+		sdxi_desc_set_fence(desc);
+
+	if (comp)
+		sdxi_cxt_attach_cst(slot, comp);
+
+	sdxi_desc_make_valid(desc);
+
+	if (flags & SDXI_CXT_SUBMIT_KICK)
+		sdxi_cxt_kick(cxt);
+}
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index 94e0fc45f281..f048e298f6de 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -9,10 +9,12 @@
 #include <linux/array_size.h>
 #include <linux/dma-mapping.h>
 #include <linux/idr.h>
+#include <linux/io.h>
 #include <linux/string.h>
 #include <linux/types.h>
 
 #include "hw.h"
+#include "ring.h"
 #include "sdxi.h"
 #include "submission.h"
 
@@ -52,6 +54,16 @@ int sdxi_admin_cxt_init(struct sdxi_dev *sdxi);
 struct sdxi_cxt *sdxi_cxt_new(struct sdxi_dev *sdxi);
 void sdxi_client_cxts_exit(struct sdxi_dev *sdxi);
 
+enum sdxi_submit_flags {
+	SDXI_CXT_SUBMIT_KICK  = BIT(0),
+	SDXI_CXT_SUBMIT_FENCE = BIT(1),
+};
+
+void sdxi_cxt_attach_cst(struct sdxi_slot slot,
+			 const struct sdxi_completion *comp);
+void sdxi_cxt_submit(struct sdxi_cxt *cxt, struct sdxi_slot slot,
+		     const struct sdxi_completion *comp, enum sdxi_submit_flags flags);
+
 static inline struct sdxi_cxt *to_admin_cxt(const struct sdxi_cxt *cxt)
 {
 	return cxt->sdxi->admin_cxt;
@@ -62,6 +74,22 @@ static inline bool sdxi_cxt_is_admin(const struct sdxi_cxt *cxt)
 	return cxt == to_admin_cxt(cxt);
 }
 
+static inline void sdxi_cxt_kick(struct sdxi_cxt *cxt)
+{
+	/*
+	 * Ring the context's doorbell with its current write index.
+	 *
+	 * It's OK to locklessly sample the index for this purpose: it
+	 * monotonically increases and the implementation is required
+	 * to ignore out-of-order doorbell values (SDXI 1.0 5.2.1
+	 * Multi-Producer Enqueue).
+	 *
+	 * writeq() orders the descriptors' valid bits ahead of the
+	 * doorbell, so no explicit barrier is needed here.
+	 */
+	writeq(le64_to_cpu(READ_ONCE(cxt->sq->write_index)), cxt->sq->doorbell);
+}
+
 static inline struct sdxi_akey_ent *sdxi_alloc_akey(struct sdxi_cxt *cxt)
 {
 	unsigned int max = ARRAY_SIZE(cxt->akey_table->entry) - 1;
diff --git a/drivers/dma/sdxi/descriptor.h b/drivers/dma/sdxi/descriptor.h
new file mode 100644
index 000000000000..b19d5d329e43
--- /dev/null
+++ b/drivers/dma/sdxi/descriptor.h
@@ -0,0 +1,64 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+#ifndef DMA_SDXI_DESCRIPTOR_H
+#define DMA_SDXI_DESCRIPTOR_H
+
+/*
+ * Facilities for encoding SDXI descriptors.
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/ratelimit.h>
+#include <linux/types.h>
+#include <asm/byteorder.h>
+
+#include "hw.h"
+
+static inline void sdxi_desc_vl_expect(const struct sdxi_desc *desc, bool expected)
+{
+	u8 vl = FIELD_GET(SDXI_DSC_VL, le32_to_cpu(desc->opcode));
+
+	WARN_RATELIMIT(vl != expected, "expected vl=%u but got %u\n", expected, vl);
+}
+
+static inline void sdxi_desc_set_csb(struct sdxi_desc *desc, dma_addr_t addr)
+{
+	sdxi_desc_vl_expect(desc, 0);
+	desc->csb_ptr = cpu_to_le64(FIELD_PREP(SDXI_DSC_CSB_PTR, addr >> 5));
+}
+
+static inline void sdxi_desc_make_valid(struct sdxi_desc *desc)
+{
+	u32 opcode = le32_to_cpu(desc->opcode);
+
+	sdxi_desc_vl_expect(desc, 0);
+	FIELD_MODIFY(SDXI_DSC_VL, &opcode, 1);
+	/*
+	 * Once vl is set, no more modifications to the descriptor
+	 * payload are allowed. Ensure the vl update is ordered after
+	 * all other initialization of the descriptor.
+	 */
+	dma_wmb();
+	WRITE_ONCE(desc->opcode, cpu_to_le32(opcode));
+}
+
+static inline void sdxi_desc_set_fence(struct sdxi_desc *desc)
+{
+	u32 opcode = le32_to_cpu(desc->opcode);
+
+	sdxi_desc_vl_expect(desc, 0);
+	FIELD_MODIFY(SDXI_DSC_FE, &opcode, 1);
+	desc->opcode = cpu_to_le32(opcode);
+}
+
+static inline void sdxi_desc_set_csr(struct sdxi_desc *desc)
+{
+	u32 opcode = le32_to_cpu(desc->opcode);
+
+	sdxi_desc_vl_expect(desc, 0);
+	FIELD_MODIFY(SDXI_DSC_CSR, &opcode, 1);
+	desc->opcode = cpu_to_le32(opcode);
+}
+
+#endif /* DMA_SDXI_DESCRIPTOR_H */
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index c1bff631a5ae..edc43190148c 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -136,6 +136,16 @@ struct sdxi_desc {
 			__u8 operation[52];
 			__le64 csb_ptr;
 		);
+
+/* For opcode field */
+#define SDXI_DSC_VL  BIT(0)
+#define SDXI_DSC_SE  BIT(1)
+#define SDXI_DSC_FE  BIT(2)
+#define SDXI_DSC_CSR BIT(4)
+
+/* For csb_ptr field */
+#define SDXI_DSC_CSB_PTR GENMASK_ULL(63, 5)
+
 	};
 } __packed __aligned(64);
 static_assert(sizeof(struct sdxi_desc) == 64);

-- 
2.56.0

