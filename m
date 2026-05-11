From: Nathan Lynch <nathan.lynch@amd.com>
Date: Mon, 11 May 2026 14:16:28 -0500
Subject: [PATCH v2 16/23] dmaengine: sdxi: Generic descriptor manipulation
 helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-sdxi-base-v2-16-889cfed17e3f@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778526994; l=4018;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=CWw/LnMDvdhwLVv3mDj+Nnv+P4Rnl41ZD9nlo0X7QnE=;
 b=GnIyDbAwT+HtcXUUYAUUWu6wuxscmHfZ5Z9weR8KErF2qlU3eOX15XufGJnYtZHhmhWJDExt3
 WT8VMv934LcAgfuVOUNeGgvaJHggLhxwE5KtJk+N1SjhgQZIIV3dvT8
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce small helper functions for manipulating certain common
properties of descriptors after their operation-specific encoding has
been performed but before they are submitted.

sdxi_desc_set_csb() associates an optional completion status block
with a descriptor.

sdxi_desc_set_fence() forces retirement of any prior descriptors in
the ring before the target descriptor is executed. This is useful for
interrupt descriptors that signal the completion of an operation.

sdxi_desc_set_sequential() ensures that all writes from prior
descriptor operations in the same context are made globally visible
prior to making writes from the target descriptor globally visible.

sdxi_desc_make_valid() sets the descriptor validity bit, transferring
ownership of the descriptor from software to the SDXI
implementation. (The implementation is allowed to execute the
descriptor at this point, but the caller is still obligated to push
the doorbell to ensure execution occurs.)

Each of the preceding functions will warn if invoked on a descriptor
that has already been released to the SDXI implementation (i.e. had
its validity bit set).

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/descriptor.h | 64 +++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/hw.h         |  9 ++++++
 2 files changed, 73 insertions(+)

diff --git a/drivers/dma/sdxi/descriptor.h b/drivers/dma/sdxi/descriptor.h
new file mode 100644
index 000000000000..c0f01b1be726
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
+static inline void sdxi_desc_set_sequential(struct sdxi_desc *desc)
+{
+	u32 opcode = le32_to_cpu(desc->opcode);
+
+	sdxi_desc_vl_expect(desc, 0);
+	FIELD_MODIFY(SDXI_DSC_SE, &opcode, 1);
+	desc->opcode = cpu_to_le32(opcode);
+}
+
+#endif /* DMA_SDXI_DESCRIPTOR_H */
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index 46424376f26f..cb1bed2f83f2 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -140,6 +140,15 @@ struct sdxi_desc {
 			__u8 operation[52];
 			__le64 csb_ptr;
 		);
+
+/* For opcode field */
+#define SDXI_DSC_VL  BIT(0)
+#define SDXI_DSC_SE  BIT(1)
+#define SDXI_DSC_FE  BIT(2)
+
+/* For csb_ptr field */
+#define SDXI_DSC_CSB_PTR GENMASK_ULL(63, 5)
+
 	};
 } __packed;
 static_assert(sizeof(struct sdxi_desc) == 64);

-- 
2.54.0

