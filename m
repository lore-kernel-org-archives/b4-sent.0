From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:30 -0500
Subject: [PATCH 20/23] dmaengine: sdxi: Encode nop, copy, and interrupt
 descriptors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-20-1d184cb5c60a@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=7375;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=v16ENkACRv4VCqxQPotIvR4Vnct9VpRc0P+k81qylyw=;
 b=+zXZ1AgjxXQBpKYfy4UE6tmfRHEptiPyVL4ZwGwBNB2bvFgWwhoK3HFHk9727msmrFd3t3kFQ
 57TcM4fEF/9CzMzVFjRO8m3SxKlLED00JmUIm6Lvy9oKnhtUC8yPm+0
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce low-level support for serializing three operation types to
the descriptor ring of a client context: nop, copy, and interrupt.
As with the administrative descriptor support introduced earlier, each
operation has its own distinct type that overlays the generic struct
sdxi_desc, along with a dedicated encoder function that accepts an
operation-specific parameter struct.

Copy descriptors are used to implement memcpy offload for the DMA
engine provider, and interrupt descriptors are used to signal the
completion of preceding descriptors in the ring. Nops can be used in
error paths where a ring reservation has been obtained and the caller
needs to submit valid descriptors before returning.

Conditionally expose sdxi_encode_size32() for unit testing.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/descriptor.c | 107 ++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/descriptor.h |  25 ++++++++++
 drivers/dma/sdxi/hw.h         |  33 +++++++++++++
 3 files changed, 165 insertions(+)

diff --git a/drivers/dma/sdxi/descriptor.c b/drivers/dma/sdxi/descriptor.c
index be2a9244ce19..41019e747528 100644
--- a/drivers/dma/sdxi/descriptor.c
+++ b/drivers/dma/sdxi/descriptor.c
@@ -7,12 +7,119 @@
 
 #include <kunit/visibility.h>
 #include <linux/bitfield.h>
+#include <linux/bug.h>
+#include <linux/range.h>
+#include <linux/sizes.h>
 #include <linux/types.h>
 #include <asm/byteorder.h>
 
 #include "hw.h"
 #include "descriptor.h"
 
+VISIBLE_IF_KUNIT int __must_check sdxi_encode_size32(u64 size, __le32 *dest)
+{
+	/*
+	 * sizes are encoded as value - 1:
+	 * value    encoding
+	 *     1           0
+	 *     2           1
+	 *   ...
+	 *    4G  0xffffffff
+	 */
+	if (WARN_ON_ONCE(size > SZ_4G) ||
+	    WARN_ON_ONCE(size == 0))
+		return -EINVAL;
+	size = clamp_val(size, 1, SZ_4G);
+	*dest = cpu_to_le32((u32)(size - 1));
+	return 0;
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_encode_size32);
+
+void sdxi_serialize_nop(struct sdxi_desc *desc)
+{
+	u32 opcode = (FIELD_PREP(SDXI_DSC_SUBTYPE, SDXI_DSC_OP_SUBTYPE_NOP) |
+		      FIELD_PREP(SDXI_DSC_TYPE, SDXI_DSC_OP_TYPE_DMAB));
+	u64 csb_ptr = FIELD_PREP(SDXI_DSC_NP, 1);
+
+	*desc = (typeof(*desc)) {
+		.nop = (typeof(desc->nop)) {
+			.opcode = cpu_to_le32(opcode),
+			.csb_ptr = cpu_to_le64(csb_ptr),
+		},
+	};
+
+}
+
+int sdxi_encode_copy(struct sdxi_desc *desc, const struct sdxi_copy *params)
+{
+	u64 csb_ptr;
+	u32 opcode;
+	__le32 size;
+	int err;
+
+	err = sdxi_encode_size32(params->len, &size);
+	if (err)
+		return err;
+	/*
+	 * Reject overlapping src and dst. "Software ... shall not
+	 * overlap the source buffer, destination buffer, Atomic
+	 * Return Data, or completion status block." - SDXI 1.0 5.6
+	 * Memory Consistency Model
+	 */
+	if (range_overlaps(&(const struct range) {
+				   .start = params->src,
+				   .end   = params->src + params->len - 1,
+			   },
+			   &(const struct range) {
+				   .start = params->dst,
+				   .end   = params->dst + params->len - 1,
+			   }))
+		return -EINVAL;
+
+	opcode = (FIELD_PREP(SDXI_DSC_SUBTYPE, SDXI_DSC_OP_SUBTYPE_COPY) |
+		  FIELD_PREP(SDXI_DSC_TYPE, SDXI_DSC_OP_TYPE_DMAB));
+
+	csb_ptr = FIELD_PREP(SDXI_DSC_NP, 1);
+
+	*desc = (typeof(*desc)) {
+		.copy = (typeof(desc->copy)) {
+			.opcode = cpu_to_le32(opcode),
+			.size = size,
+			.akey0 = cpu_to_le16(params->src_akey),
+			.akey1 = cpu_to_le16(params->dst_akey),
+			.addr0 = cpu_to_le64(params->src),
+			.addr1 = cpu_to_le64(params->dst),
+			.csb_ptr = cpu_to_le64(csb_ptr),
+		},
+	};
+
+	return 0;
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_encode_copy);
+
+int sdxi_encode_intr(struct sdxi_desc *desc,
+		     const struct sdxi_intr *params)
+{
+	u64 csb_ptr;
+	u32 opcode;
+
+	opcode = (FIELD_PREP(SDXI_DSC_SUBTYPE, SDXI_DSC_OP_SUBTYPE_INTR) |
+		  FIELD_PREP(SDXI_DSC_TYPE, SDXI_DSC_OP_TYPE_INTR));
+
+	csb_ptr = FIELD_PREP(SDXI_DSC_NP, 1);
+
+	*desc = (typeof(*desc)) {
+		.intr = (typeof(desc->intr)) {
+			.opcode = cpu_to_le32(opcode),
+			.akey = cpu_to_le16(params->akey),
+			.csb_ptr = cpu_to_le64(csb_ptr),
+		},
+	};
+
+	return 0;
+}
+EXPORT_SYMBOL_IF_KUNIT(sdxi_encode_intr);
+
 int sdxi_encode_cxt_start(struct sdxi_desc *desc,
 			  const struct sdxi_cxt_start *params)
 {
diff --git a/drivers/dma/sdxi/descriptor.h b/drivers/dma/sdxi/descriptor.h
index 5b8fd7cbaa03..14f92c8dea1d 100644
--- a/drivers/dma/sdxi/descriptor.h
+++ b/drivers/dma/sdxi/descriptor.h
@@ -9,6 +9,7 @@
  */
 
 #include <linux/bitfield.h>
+#include <linux/kconfig.h>
 #include <linux/minmax.h>
 #include <linux/ratelimit.h>
 #include <linux/types.h>
@@ -16,6 +17,10 @@
 
 #include "hw.h"
 
+#if IS_ENABLED(CONFIG_KUNIT)
+int __must_check sdxi_encode_size32(u64 size, __le32 *dest);
+#endif
+
 static inline void sdxi_desc_vl_expect(const struct sdxi_desc *desc, bool expected)
 {
 	u8 vl = FIELD_GET(SDXI_DSC_VL, le32_to_cpu(desc->opcode));
@@ -80,6 +85,26 @@ static inline struct sdxi_cxt_range sdxi_cxt_range_single(u16 nr)
 	return sdxi_cxt_range(nr, nr);
 }
 
+void sdxi_serialize_nop(struct sdxi_desc *desc);
+
+struct sdxi_copy {
+	dma_addr_t src;
+	dma_addr_t dst;
+	u64 len;
+	u16 src_akey;
+	u16 dst_akey;
+};
+
+int sdxi_encode_copy(struct sdxi_desc *desc,
+		     const struct sdxi_copy *params);
+
+struct sdxi_intr {
+	u16 akey;
+};
+
+int sdxi_encode_intr(struct sdxi_desc *desc,
+		     const struct sdxi_intr *params);
+
 struct sdxi_cxt_start {
 	struct sdxi_cxt_range range;
 };
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index 4dcd0a3ff0fd..11d88cfc8819 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -164,6 +164,30 @@ struct sdxi_desc {
 	static_assert(offsetof(struct tag_, csb_ptr) ==			\
 		      offsetof(struct sdxi_dsc_generic, csb_ptr))
 
+		/* SDXI 1.0 Table 6-6: DSC_DMAB_NOP Descriptor Format */
+		define_sdxi_dsc(sdxi_dsc_dmab_nop, nop,
+			__u8 rsvd_0[52];
+		);
+
+		/* SDXI 1.0 Table 6-8: DSC_DMAB_COPY Descriptor Format */
+		define_sdxi_dsc(sdxi_dsc_dmab_copy, copy,
+			__le32 size;
+			__u8 attr;
+			__u8 rsvd_0[3];
+			__le16 akey0;
+			__le16 akey1;
+			__le64 addr0;
+			__le64 addr1;
+			__u8 rsvd_1[24];
+		);
+
+		/* SDXI 1.0 Table 6-12: DSC_INTR Descriptor Format */
+		define_sdxi_dsc(sdxi_dsc_intr, intr,
+			__u8 rsvd_0[8];
+			__le16 akey;
+			__u8 rsvd_1[42];
+		);
+
 		/* SDXI 1.0 Table 6-14: DSC_CXT_START Descriptor Format */
 		define_sdxi_dsc(sdxi_dsc_cxt_start, cxt_start,
 			__u8 rsvd_0;
@@ -207,11 +231,20 @@ static_assert(sizeof(struct sdxi_desc) == 64);
 
 /* SDXI 1.0 Table 6-1: SDXI Operation Groups */
 enum sdxi_dsc_type {
+	SDXI_DSC_OP_TYPE_DMAB    = 0x001,
 	SDXI_DSC_OP_TYPE_ADMIN   = 0x002,
+	SDXI_DSC_OP_TYPE_INTR    = 0x004,
 };
 
 /* SDXI 1.0 Table 6-2: SDXI Operation Groups, Types, and Subtypes */
 enum sdxi_dsc_subtype {
+	/* DMA Base */
+	SDXI_DSC_OP_SUBTYPE_NOP     = 0x01,
+	SDXI_DSC_OP_SUBTYPE_COPY    = 0x03,
+
+	/* Interrupt */
+	SDXI_DSC_OP_SUBTYPE_INTR = 0x00,
+
 	/* Administrative */
 	SDXI_DSC_OP_SUBTYPE_CXT_START_NM = 0x03,
 	SDXI_DSC_OP_SUBTYPE_CXT_STOP     = 0x04,

-- 
2.53.0

