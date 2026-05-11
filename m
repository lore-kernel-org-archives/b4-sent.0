From: Nathan Lynch <nathan.lynch@amd.com>
Date: Mon, 11 May 2026 14:16:17 -0500
Subject: [PATCH v2 05/23] dmaengine: sdxi: Configure context tables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-sdxi-base-v2-5-889cfed17e3f@amd.com>
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
 Jonathan Cameron <jic23@kernel.org>, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778526994; l=6882;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=SJzCBbJFQwsyPu9ZY+bi1GfbFcp2Ugeir8s9gli+zx8=;
 b=PC/X78ReHlbxSzzDkjYMmCaUWPeUsaVWTpwro9y1f0Lauwi5uHvMJc9tiB5OsfRpcCs7WbWKW
 kYjdXpgN3LxANhYHG7rC5J+8+2I1f5T/KgiB1IAs2qULISOcwgjrzh+
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SDXI uses a two-level table hierarchy to track contexts. There is a
single level 2 table per function which enumerates up to 512 level 1
tables. Each level 1 table enumerates up to 128 contexts.

Allocate and install the L2 table and a single L1 table, enough for
context IDs 0-127 (i.e. the admin context with reserved id 0, plus 127
client contexts). For now, to avoid dynamic management of additional
L1 tables, cap ctl2.max_cxt to 127.

Since the table allocations are devres-managed, there is no
corresponding cleanup code required.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/device.c | 40 +++++++++++++++++++++++++++++--
 drivers/dma/sdxi/hw.h     | 61 +++++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/mmio.h   |  6 +++++
 drivers/dma/sdxi/sdxi.h   |  5 ++++
 4 files changed, 110 insertions(+), 2 deletions(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index f9a9944ad892..6a2204ff7fde 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -8,11 +8,14 @@
 #include <linux/bitfield.h>
 #include <linux/delay.h>
 #include <linux/device.h>
+#include <linux/dma-mapping.h>
 #include <linux/iopoll.h>
 #include <linux/jiffies.h>
+#include <linux/log2.h>
 #include <linux/slab.h>
 #include <linux/time.h>
 
+#include "hw.h"
 #include "mmio.h"
 #include "sdxi.h"
 
@@ -136,7 +139,8 @@ static int sdxi_dev_stop(struct sdxi_dev *sdxi)
  */
 static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 {
-	u64 version, cap0, cap1, ctl2;
+	u64 version, cap0, cap1, ctl2, cxt_l2, lv01_ptr;
+	struct sdxi_cxt_L2_ent *L2_ent;
 	int err;
 
 	/*
@@ -160,7 +164,13 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 
 	cap1 = sdxi_read64(sdxi, SDXI_MMIO_CAP1);
 	sdxi->op_grp_cap = FIELD_GET(SDXI_MMIO_CAP1_OPB_000_CAP, cap1);
-	sdxi->max_cxtid = FIELD_GET(SDXI_MMIO_CAP1_MAX_CXT, cap1);
+
+	/*
+	 * Constrain the number of client contexts supported by the
+	 * driver to what fits in a single L1 table.
+	 */
+	sdxi->max_cxtid = min(SDXI_L1_TABLE_ENTRIES - 1,
+			      FIELD_GET(SDXI_MMIO_CAP1_MAX_CXT, cap1));
 
 	/* Apply our configuration. */
 	ctl2 = FIELD_PREP(SDXI_MMIO_CTL2_MAX_CXT, sdxi->max_cxtid);
@@ -172,6 +182,32 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 			   FIELD_GET(SDXI_MMIO_CAP1_OPB_000_CAP, cap1));
 	sdxi_write64(sdxi, SDXI_MMIO_CTL2, ctl2);
 
+	/* SDXI 1.0 4.1.8.2 Context Level 2 Table Setup */
+	sdxi->L2_table = dmam_alloc_coherent(sdxi->dev,
+					     sizeof(*sdxi->L2_table),
+					     &sdxi->L2_dma, GFP_KERNEL);
+	if (!sdxi->L2_table)
+		return -ENOMEM;
+
+	cxt_l2 = FIELD_PREP(SDXI_MMIO_CXT_L2_PTR, sdxi->L2_dma >> ilog2(SZ_4K));
+	sdxi_write64(sdxi, SDXI_MMIO_CXT_L2, cxt_l2);
+
+	/* SDXI 1.0 4.1.8.3 Context Level 1 Table Setup */
+	sdxi->L1_table = dmam_alloc_coherent(sdxi->dev,
+					     sizeof(*sdxi->L1_table),
+					     &sdxi->L1_dma, GFP_KERNEL);
+	if (!sdxi->L1_table)
+		return -ENOMEM;
+	/*
+	 * SDXI 1.0 4.1.8.3.c: Initialize the Context level 2 table to
+	 * point to the Context Level 1 [table].
+	 */
+	L2_ent = &sdxi->L2_table->entry[0];
+	lv01_ptr = FIELD_PREP(SDXI_CXT_L2_ENT_VL, 1) |
+		   FIELD_PREP(SDXI_CXT_L2_ENT_LV01_PTR,
+			      sdxi->L1_dma >> ilog2(SZ_4K));
+	L2_ent->lv01_ptr = cpu_to_le64(lv01_ptr);
+
 	return 0;
 }
 
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
new file mode 100644
index 000000000000..df520ca7792b
--- /dev/null
+++ b/drivers/dma/sdxi/hw.h
@@ -0,0 +1,61 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/* Copyright Advanced Micro Devices, Inc. */
+
+/*
+ * Control structures and constants defined in the SDXI specification,
+ * with low-level accessors. The ordering of the structures here
+ * follows the order of their definitions in the SDXI spec.
+ *
+ * Names of structures, members, and subfields (bit ranges within
+ * members) are written to match the spec, generally. E.g. struct
+ * sdxi_cxt_L2_ent corresponds to CXT_L2_ENT in the spec.
+ *
+ * Note: a member can have a subfield whose name is identical to the
+ * member's name. E.g. CXT_L2_ENT's lv01_ptr.
+ *
+ * All reserved fields and bits (usually named "rsvd" or some
+ * variation) must be set to zero by the driver unless otherwise
+ * specified.
+ */
+
+#ifndef DMA_SDXI_HW_H
+#define DMA_SDXI_HW_H
+
+#include <linux/bits.h>
+#include <linux/build_bug.h>
+#include <linux/types.h>
+#include <asm/byteorder.h>
+
+/* SDXI 1.0 Table 3-2: Context Level 2 Table Entry (CXT_L2_ENT) */
+struct sdxi_cxt_L2_ent {
+	__le64 lv01_ptr;
+#define SDXI_CXT_L2_ENT_VL       BIT_ULL(0)
+#define SDXI_CXT_L2_ENT_LV01_PTR GENMASK_ULL(63, 12)
+} __packed;
+static_assert(sizeof(struct sdxi_cxt_L2_ent) == 8);
+
+/* SDXI 1.0 3.2.1 Context Level 2 Table */
+#define SDXI_L2_TABLE_ENTRIES 512
+struct sdxi_cxt_L2_table {
+	struct sdxi_cxt_L2_ent entry[SDXI_L2_TABLE_ENTRIES];
+};
+static_assert(sizeof(struct sdxi_cxt_L2_table) == 4096);
+
+/* SDXI 1.0 Table 3-3: Context Level 1 Table Entry (CXT_L1_ENT) */
+struct sdxi_cxt_L1_ent {
+	__le64 cxt_ctl_ptr;
+	__le64 akey_ptr;
+	__le32 misc0;
+	__le32 opb_000_enb;
+	__u8 rsvd_0[8];
+} __packed;
+static_assert(sizeof(struct sdxi_cxt_L1_ent) == 32);
+
+/* SDXI 1.0 3.2.2 Context Level 1 Table */
+#define SDXI_L1_TABLE_ENTRIES 128
+struct sdxi_cxt_L1_table {
+	struct sdxi_cxt_L1_ent entry[SDXI_L1_TABLE_ENTRIES];
+};
+static_assert(sizeof(struct sdxi_cxt_L1_table) == 4096);
+
+#endif /* DMA_SDXI_HW_H */
diff --git a/drivers/dma/sdxi/mmio.h b/drivers/dma/sdxi/mmio.h
index c9a11c3f2f76..d8d631849938 100644
--- a/drivers/dma/sdxi/mmio.h
+++ b/drivers/dma/sdxi/mmio.h
@@ -19,6 +19,9 @@ enum sdxi_reg {
 	SDXI_MMIO_CAP0       = 0x00200,
 	SDXI_MMIO_CAP1       = 0x00208,
 	SDXI_MMIO_VERSION    = 0x00210,
+
+	/* SDXI 1.0 9.2 Context and RKey Table Registers */
+	SDXI_MMIO_CXT_L2     = 0x10000,
 };
 
 /* SDXI 1.0 Table 9-2: MMIO_CTL0 */
@@ -48,4 +51,7 @@ enum sdxi_reg {
 #define SDXI_MMIO_VERSION_MINOR GENMASK_ULL(7, 0)
 #define SDXI_MMIO_VERSION_MAJOR GENMASK_ULL(23, 16)
 
+/* SDXI 1.0 Table 9-9: MMIO_CXT_L2 */
+#define SDXI_MMIO_CXT_L2_PTR GENMASK_ULL(63, 12)
+
 #endif  /* DMA_SDXI_MMIO_H */
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index 84b87066f438..85ff17c48d40 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -39,6 +39,11 @@ struct sdxi_dev {
 	u16 max_cxtid;			/* Maximum context ID allowed. */
 	u32 op_grp_cap;			/* supported operation group cap */
 
+	struct sdxi_cxt_L2_table *L2_table;
+	dma_addr_t L2_dma;
+	struct sdxi_cxt_L1_table *L1_table;
+	dma_addr_t L1_dma;
+
 	const struct sdxi_bus_ops *bus_ops;
 };
 

-- 
2.54.0

