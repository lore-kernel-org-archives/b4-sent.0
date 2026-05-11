From: Nathan Lynch <nathan.lynch@amd.com>
Date: Mon, 11 May 2026 14:16:30 -0500
Subject: [PATCH v2 18/23] dmaengine: sdxi: Encode context start, stop, and
 sync descriptors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-sdxi-base-v2-18-889cfed17e3f@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778526994; l=8361;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=dQwO4BfselYk/3ti1YIOa6wwy+gdrN39N2deDB7oPCU=;
 b=Wfb/KK6lABIgiVXyUno+QM4Vr5LfHKjNWgkUDQV8JkSn8X2Hz0aJod4cm5+Hvm/40nXK8MCxh
 OC5P6dLxRWCAIpS4Ye/A/gWv/Tgp44WwGqtNQ32DzWyjMoGy2NE0N0R
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce the low-level support for serializing three operation types
to the descriptor ring of the admin context: context start, context
stop, and sync. Each operation has its own distinct type that overlays
the generic struct sdxi_desc, along with a dedicated encoder function
that accepts an operation-specific parameter struct.

The parameter structs (sdxi_cxt_start, sdxi_cxt_stop, sdxi_sync)
expose only a necessary subset of the available descriptor fields to
callers, i.e. the target context range. These can be expanded over
time as needed.

Each encoder function is intended to 1) set any mandatory field values
for the descriptor type (e.g. SDXI_DSC_FE=1 for context start); and 2)
translate conventional kernel types (dma_addr_t, CPU-endian values)
from the parameter block to the descriptor in memory. While they're
expected to operate directly on descriptor ring memory, they do not
set the descriptor validity bit. That is left to the caller, which may
need to make other modifictions to the descriptor, such as attaching a
completion block, before releasing it to the SDXI implementation.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/Makefile     |  1 +
 drivers/dma/sdxi/descriptor.c | 91 +++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/descriptor.h | 46 ++++++++++++++++++++++
 drivers/dma/sdxi/hw.h         | 64 ++++++++++++++++++++++++++++++
 4 files changed, 202 insertions(+)

diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
index dd08f4a5f723..08dd73a45dc7 100644
--- a/drivers/dma/sdxi/Makefile
+++ b/drivers/dma/sdxi/Makefile
@@ -4,6 +4,7 @@ obj-$(CONFIG_SDXI) += sdxi.o
 sdxi-objs += \
 	completion.o  \
 	context.o     \
+	descriptor.o  \
 	device.o      \
 	ring.o
 
diff --git a/drivers/dma/sdxi/descriptor.c b/drivers/dma/sdxi/descriptor.c
new file mode 100644
index 000000000000..be2a9244ce19
--- /dev/null
+++ b/drivers/dma/sdxi/descriptor.c
@@ -0,0 +1,91 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SDXI descriptor encoding.
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+
+#include <kunit/visibility.h>
+#include <linux/bitfield.h>
+#include <linux/types.h>
+#include <asm/byteorder.h>
+
+#include "hw.h"
+#include "descriptor.h"
+
+int sdxi_encode_cxt_start(struct sdxi_desc *desc,
+			  const struct sdxi_cxt_start *params)
+{
+	u64 csb_ptr;
+	u32 opcode;
+
+	opcode = (FIELD_PREP(SDXI_DSC_FE, 1) |
+		  FIELD_PREP(SDXI_DSC_SUBTYPE, SDXI_DSC_OP_SUBTYPE_CXT_START_NM) |
+		  FIELD_PREP(SDXI_DSC_TYPE, SDXI_DSC_OP_TYPE_ADMIN));
+
+	csb_ptr = FIELD_PREP(SDXI_DSC_NP, 1);
+
+	*desc = (typeof(*desc)) {
+		.cxt_start = (typeof(desc->cxt_start)) {
+			.opcode = cpu_to_le32(opcode),
+			.cxt_start = cpu_to_le16(params->range.cxt_start),
+			.cxt_end = cpu_to_le16(params->range.cxt_end),
+			.csb_ptr = cpu_to_le64(csb_ptr),
+		},
+	};
+
+	return 0;
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_encode_cxt_start);
+
+int sdxi_encode_cxt_stop(struct sdxi_desc *desc,
+			  const struct sdxi_cxt_stop *params)
+{
+	u64 csb_ptr;
+	u32 opcode;
+
+	opcode = (FIELD_PREP(SDXI_DSC_FE, 1) |
+		  FIELD_PREP(SDXI_DSC_SUBTYPE, SDXI_DSC_OP_SUBTYPE_CXT_STOP) |
+		  FIELD_PREP(SDXI_DSC_TYPE, SDXI_DSC_OP_TYPE_ADMIN));
+
+	csb_ptr = FIELD_PREP(SDXI_DSC_NP, 1);
+
+	*desc = (typeof(*desc)) {
+		.cxt_stop = (typeof(desc->cxt_stop)) {
+			.opcode = cpu_to_le32(opcode),
+			.cxt_start = cpu_to_le16(params->range.cxt_start),
+			.cxt_end = cpu_to_le16(params->range.cxt_end),
+			.csb_ptr = cpu_to_le64(csb_ptr),
+		},
+	};
+
+	return 0;
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_encode_cxt_stop);
+
+int sdxi_encode_sync(struct sdxi_desc *desc, const struct sdxi_sync *params)
+{
+	u64 csb_ptr;
+	u32 opcode;
+	u8 cflags;
+
+	opcode = (FIELD_PREP(SDXI_DSC_SUBTYPE, SDXI_DSC_OP_SUBTYPE_SYNC) |
+		  FIELD_PREP(SDXI_DSC_TYPE, SDXI_DSC_OP_TYPE_ADMIN));
+
+	cflags = FIELD_PREP(SDXI_DSC_SYNC_FLT, params->filter);
+
+	csb_ptr = FIELD_PREP(SDXI_DSC_NP, 1);
+
+	*desc = (typeof(*desc)) {
+		.sync = (typeof(desc->sync)) {
+			.opcode = cpu_to_le32(opcode),
+			.cflags = cflags,
+			.cxt_start = cpu_to_le16(params->range.cxt_start),
+			.cxt_end = cpu_to_le16(params->range.cxt_end),
+			.csb_ptr = cpu_to_le64(csb_ptr),
+		},
+	};
+
+	return 0;
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_encode_sync);
diff --git a/drivers/dma/sdxi/descriptor.h b/drivers/dma/sdxi/descriptor.h
index c0f01b1be726..5b8fd7cbaa03 100644
--- a/drivers/dma/sdxi/descriptor.h
+++ b/drivers/dma/sdxi/descriptor.h
@@ -9,6 +9,7 @@
  */
 
 #include <linux/bitfield.h>
+#include <linux/minmax.h>
 #include <linux/ratelimit.h>
 #include <linux/types.h>
 #include <asm/byteorder.h>
@@ -61,4 +62,49 @@ static inline void sdxi_desc_set_sequential(struct sdxi_desc *desc)
 	desc->opcode = cpu_to_le32(opcode);
 }
 
+struct sdxi_cxt_range {
+	u16 cxt_start;
+	u16 cxt_end;
+};
+
+static inline struct sdxi_cxt_range sdxi_cxt_range(u16 a, u16 b)
+{
+	return (struct sdxi_cxt_range) {
+		.cxt_start = min(a, b),
+		.cxt_end   = max(a, b),
+	};
+}
+
+static inline struct sdxi_cxt_range sdxi_cxt_range_single(u16 nr)
+{
+	return sdxi_cxt_range(nr, nr);
+}
+
+struct sdxi_cxt_start {
+	struct sdxi_cxt_range range;
+};
+
+int sdxi_encode_cxt_start(struct sdxi_desc *desc,
+			  const struct sdxi_cxt_start *params);
+
+struct sdxi_cxt_stop {
+	struct sdxi_cxt_range range;
+};
+
+int sdxi_encode_cxt_stop(struct sdxi_desc *desc,
+			  const struct sdxi_cxt_stop *params);
+
+struct sdxi_sync {
+	enum sdxi_sync_filter  {
+		SDXI_SYNC_FLT_CXT  = 0x0,
+		SDXI_SYNC_FLT_STOP = 0x1,
+		SDXI_SYNC_FLT_AKEY = 0x2,
+		SDXI_SYNC_FLT_RKEY = 0x3,
+		SDXI_SYNC_FLT_FN   = 0x4,
+	} filter;
+	struct sdxi_cxt_range range;
+};
+
+int sdxi_encode_sync(struct sdxi_desc *desc, const struct sdxi_sync *params);
+
 #endif /* DMA_SDXI_DESCRIPTOR_H */
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index 178161588bd0..4dcd0a3ff0fd 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -146,12 +146,76 @@ struct sdxi_desc {
 #define SDXI_DSC_VL  BIT(0)
 #define SDXI_DSC_SE  BIT(1)
 #define SDXI_DSC_FE  BIT(2)
+#define SDXI_DSC_SUBTYPE GENMASK(15, 8)
+#define SDXI_DSC_TYPE    GENMASK(26, 16)
 
 /* For csb_ptr field */
+#define SDXI_DSC_NP BIT_ULL(0)
 #define SDXI_DSC_CSB_PTR GENMASK_ULL(63, 5)
 
+#define define_sdxi_dsc(tag_, name_, op_body_)				\
+	struct tag_ {							\
+		__le32 opcode;						\
+		op_body_						\
+		__le64 csb_ptr;						\
+	} __packed name_;						\
+	static_assert(sizeof(struct tag_) ==				\
+		      sizeof(struct sdxi_dsc_generic));			\
+	static_assert(offsetof(struct tag_, csb_ptr) ==			\
+		      offsetof(struct sdxi_dsc_generic, csb_ptr))
+
+		/* SDXI 1.0 Table 6-14: DSC_CXT_START Descriptor Format */
+		define_sdxi_dsc(sdxi_dsc_cxt_start, cxt_start,
+			__u8 rsvd_0;
+			__u8 vflags;
+			__le16 vf_num;
+			__le16 cxt_start;
+			__le16 cxt_end;
+			__u8 rsvd_1[4];
+			__le64 db_value;
+			__u8 rsvd_2[32];
+		);
+
+		/* SDXI 1.0 Table 6-15: DSC_CXT_STOP Descriptor Format */
+		define_sdxi_dsc(sdxi_dsc_cxt_stop, cxt_stop,
+			__u8 rsvd_0;
+			__u8 vflags;
+			__le16 vf_num;
+			__le16 cxt_start;
+			__le16 cxt_end;
+			__u8 rsvd_1[44];
+		);
+
+		/* SDXI 1.0 Table 6-22: DSC_SYNC Descriptor Format */
+		define_sdxi_dsc(sdxi_dsc_sync, sync,
+			__u8 cflags;
+			__u8 vflags;
+			__le16 vf_num;
+			__le16 cxt_start;
+			__le16 cxt_end;
+			__le16 key_start;
+			__le16 key_end;
+			__u8 rsvd_0[40];
+		);
+/* For use with sync.cflags */
+#define SDXI_DSC_SYNC_FLT GENMASK(2, 0)
+
+#undef define_sdxi_dsc
 	};
 } __packed;
 static_assert(sizeof(struct sdxi_desc) == 64);
 
+/* SDXI 1.0 Table 6-1: SDXI Operation Groups */
+enum sdxi_dsc_type {
+	SDXI_DSC_OP_TYPE_ADMIN   = 0x002,
+};
+
+/* SDXI 1.0 Table 6-2: SDXI Operation Groups, Types, and Subtypes */
+enum sdxi_dsc_subtype {
+	/* Administrative */
+	SDXI_DSC_OP_SUBTYPE_CXT_START_NM = 0x03,
+	SDXI_DSC_OP_SUBTYPE_CXT_STOP     = 0x04,
+	SDXI_DSC_OP_SUBTYPE_SYNC         = 0x06,
+};
+
 #endif /* DMA_SDXI_HW_H */

-- 
2.54.0

