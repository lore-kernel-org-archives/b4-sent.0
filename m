From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:47 -0600
Subject: [PATCH v4 06/25] dmaengine: sdxi: Configure context tables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-6-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=6296;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=o0vJ62GP4ndIAcnrJU81SrNe9hbTyV2kdUPr0Ixa5UY=;
 b=JR73PJnqqwkGu53/hOvYgsROMotgAIl3rjEGJVbYHpIfNzTXJFkyfM55/VZXu9ef1A5kgSncB
 EH4TDM5+Y/8AGfZQEQ3c/Kn/HtyAACQQ+M95L+vu4kyMCvlL/+mEia9
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
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
 drivers/dma/sdxi/device.c | 39 ++++++++++++++++++++++++++++++++++--
 drivers/dma/sdxi/hw.h     | 50 +++++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/mmio.h   |  3 +++
 drivers/dma/sdxi/sdxi.h   |  5 +++++
 4 files changed, 95 insertions(+), 2 deletions(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index c03af5833414..baf55f6b6826 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -13,11 +13,13 @@
 #include <linux/iopoll.h>
 #include <linux/jiffies.h>
 #include <linux/limits.h>
+#include <linux/log2.h>
 #include <linux/minmax.h>
 #include <linux/sizes.h>
 #include <linux/slab.h>
 #include <linux/time.h>
 
+#include "hw.h"
 #include "mmio.h"
 #include "sdxi.h"
 
@@ -284,7 +286,8 @@ static int sdxi_fn_prepare(struct sdxi_dev *sdxi)
  */
 static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 {
-	u64 version, cap0, cap1, ctl2;
+	u64 version, cap0, cap1, ctl2, cxt_l2, lv01_ptr;
+	struct sdxi_cxt_L2_ent *L2_ent;
 
 	version = sdxi_read64(sdxi, SDXI_MMIO_VERSION);
 	dev_info(sdxi->dev, "SDXI %llu.%llu device found\n",
@@ -301,7 +304,13 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 	sdxi->max_buffer = FIELD_GET(SDXI_MMIO_CAP1_MAX_BUFFER, cap1);
 	dma_set_max_seg_size(sdxi->dev,
 			     min((u64)SZ_2M << sdxi->max_buffer, U32_MAX));
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
@@ -313,6 +322,32 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
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
index 000000000000..0551c2b52980
--- /dev/null
+++ b/drivers/dma/sdxi/hw.h
@@ -0,0 +1,50 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/* Copyright Advanced Micro Devices, Inc. */
+
+/*
+ * Hardware layouts and constants follow SDXI specification names and
+ * definition order. Reserved fields and bits must be zero unless specified
+ * otherwise.
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
+} __packed __aligned(8);
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
+} __packed __aligned(32);
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
index 7c416de9f874..b040d2283fb2 100644
--- a/drivers/dma/sdxi/mmio.h
+++ b/drivers/dma/sdxi/mmio.h
@@ -68,6 +68,9 @@ enum sdxi_reg {
 #define SDXI_MMIO_VERSION_MINOR GENMASK_ULL(7, 0)
 #define SDXI_MMIO_VERSION_MAJOR GENMASK_ULL(23, 16)
 
+/* SDXI 1.0 Table 9-9: MMIO_CXT_L2 */
+#define SDXI_MMIO_CXT_L2_PTR GENMASK_ULL(63, 12)
+
 /* SDXI 1.0 Table 9-10: MMIO_RKEY */
 #define SDXI_MMIO_RKEY_EN BIT_ULL(0)
 
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index 7569b8395ce1..856a3838eec3 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -44,6 +44,11 @@ struct sdxi_dev {
 	u8 max_buffer;			/* Configured log2 buffer size minus 21. */
 	u32 op_grp_cap;			/* supported operation group cap */
 
+	struct sdxi_cxt_L2_table *L2_table;
+	dma_addr_t L2_dma;
+	struct sdxi_cxt_L1_table *L1_table;
+	dma_addr_t L1_dma;
+
 	bool has_mailbox;
 
 	const struct sdxi_bus_ops *bus_ops;

-- 
2.56.0

