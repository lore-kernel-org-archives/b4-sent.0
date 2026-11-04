From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:50 -0600
Subject: [PATCH v4 09/25] dmaengine: sdxi: Allocate administrative context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-sdxi-base-v4-9-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=7313;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=ABINdQLGoTQPFYNtfmhB61OIp2UOK7aQ9a1VYsTZZRo=;
 b=nVYY71K6YMmzL140lSoldUv+xkDMY0LrGmJMCoLVUrWOtBJtYEBGb4s3N8OOfHZCg9zXHyBNc
 AspT25OA9f/CGegQk4K0EG4DP6Svqrvlmkil53ngHEQ8CrMVmuY8bNF
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allocate the administrative context’s control structures and register
device-managed cleanup.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/Makefile  |   4 +-
 drivers/dma/sdxi/context.c | 101 +++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/context.h |  36 ++++++++++++++++
 drivers/dma/sdxi/device.c  |  12 ++++++
 drivers/dma/sdxi/hw.h      |  27 ++++++++++++
 drivers/dma/sdxi/sdxi.h    |   2 +
 6 files changed, 181 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
index 0006edf74d86..cdf8a455077b 100644
--- a/drivers/dma/sdxi/Makefile
+++ b/drivers/dma/sdxi/Makefile
@@ -1,6 +1,8 @@
 # SPDX-License-Identifier: GPL-2.0
 obj-$(CONFIG_SDXI_CORE) += sdxi-core.o
-sdxi-core-y := device.o
+sdxi-core-y := \
+	context.o     \
+	device.o
 
 obj-$(CONFIG_SDXI_PCI) += sdxi-pci.o
 sdxi-pci-y := pci.o
diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
new file mode 100644
index 000000000000..4132618ae17a
--- /dev/null
+++ b/drivers/dma/sdxi/context.c
@@ -0,0 +1,101 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SDXI context management
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+
+#define pr_fmt(fmt)     "SDXI: " fmt
+
+#include <linux/bug.h>
+#include <linux/cleanup.h>
+#include <linux/device/devres.h>
+#include <linux/dma-mapping.h>
+#include <linux/dmapool.h>
+#include <linux/errno.h>
+#include <linux/slab.h>
+#include <linux/types.h>
+
+#include "context.h"
+#include "sdxi.h"
+#include "submission.h"
+
+#define DEFAULT_DESC_RING_ENTRIES 1024
+
+enum {
+	/*
+	 * The admin context always has ID 0. See SDXI 1.0 3.5
+	 * Administrative Context (Context 0).
+	 */
+	SDXI_ADMIN_CXT_ID = 0,
+};
+
+/*
+ * Free context and its resources. @cxt may be partially allocated but
+ * must have ->sdxi set.
+ */
+static void sdxi_free_cxt(struct sdxi_cxt *cxt)
+{
+	struct sdxi_dev *sdxi = cxt->sdxi;
+
+	if (cxt->cxt_ctl)
+		dma_pool_free(sdxi->cxt_ctl_pool, cxt->cxt_ctl,
+			      cxt->cxt_ctl_dma);
+	if (cxt->akey_table)
+		dma_free_coherent(sdxi->dev, sizeof(*cxt->akey_table),
+				  cxt->akey_table, cxt->akey_table_dma);
+	if (cxt->sq)
+		sdxi_sq_free(sdxi, cxt->sq);
+	kfree(cxt);
+}
+
+DEFINE_FREE(sdxi_cxt, struct sdxi_cxt *, if (_T) sdxi_free_cxt(_T))
+
+/* Allocate a context and its control structure hierarchy in memory. */
+static struct sdxi_cxt *sdxi_alloc_cxt(struct sdxi_dev *sdxi)
+{
+	struct device *dev = sdxi->dev;
+	struct sdxi_cxt *cxt __free(sdxi_cxt) = kzalloc(sizeof(*cxt), GFP_KERNEL);
+
+	if (!cxt)
+		return NULL;
+
+	cxt->sdxi = sdxi;
+
+	cxt->sq = sdxi_sq_alloc(sdxi, DEFAULT_DESC_RING_ENTRIES);
+	if (!cxt->sq)
+		return NULL;
+
+	cxt->akey_table = dma_alloc_coherent(dev, sizeof(*cxt->akey_table),
+					     &cxt->akey_table_dma, GFP_KERNEL);
+	if (!cxt->akey_table)
+		return NULL;
+
+	cxt->cxt_ctl = dma_pool_zalloc(sdxi->cxt_ctl_pool, GFP_KERNEL,
+				       &cxt->cxt_ctl_dma);
+	if (!cxt->cxt_ctl)
+		return NULL;
+
+	return_ptr(cxt);
+}
+
+static void free_admin_cxt(void *ptr)
+{
+	struct sdxi_dev *sdxi = ptr;
+
+	sdxi_free_cxt(sdxi->admin_cxt);
+}
+
+int sdxi_admin_cxt_init(struct sdxi_dev *sdxi)
+{
+	struct sdxi_cxt *cxt __free(sdxi_cxt) = sdxi_alloc_cxt(sdxi);
+	if (!cxt)
+		return -ENOMEM;
+
+	cxt->id = SDXI_ADMIN_CXT_ID;
+	cxt->sq->doorbell = sdxi->dbs + cxt->id * sdxi->db_stride;
+
+	sdxi->admin_cxt = no_free_ptr(cxt);
+
+	return devm_add_action_or_reset(sdxi->dev, free_admin_cxt, sdxi);
+}
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
new file mode 100644
index 000000000000..873ad49c3c86
--- /dev/null
+++ b/drivers/dma/sdxi/context.h
@@ -0,0 +1,36 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/*
+ * Copyright Advanced Micro Devices, Inc.
+ */
+
+#ifndef DMA_SDXI_CONTEXT_H
+#define DMA_SDXI_CONTEXT_H
+
+#include <linux/dma-mapping.h>
+#include <linux/types.h>
+
+#include "hw.h"
+#include "sdxi.h"
+#include "submission.h"
+
+/* Use a 4 KiB AKey table, the minimum architectural size. */
+struct sdxi_akey_table {
+	struct sdxi_akey_ent entry[SZ_4K / sizeof(struct sdxi_akey_ent)];
+};
+
+struct sdxi_cxt {
+	struct sdxi_dev *sdxi;
+	u16 id;
+
+	struct sdxi_cxt_ctl *cxt_ctl;
+	dma_addr_t cxt_ctl_dma;
+
+	struct sdxi_akey_table *akey_table;
+	dma_addr_t akey_table_dma;
+
+	struct sdxi_sq *sq;
+};
+
+int sdxi_admin_cxt_init(struct sdxi_dev *sdxi);
+
+#endif /* DMA_SDXI_CONTEXT_H */
diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index acc955b088ba..f9787d7190d4 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -20,6 +20,7 @@
 #include <linux/slab.h>
 #include <linux/time.h>
 
+#include "context.h"
 #include "hw.h"
 #include "mmio.h"
 #include "sdxi.h"
@@ -289,6 +290,7 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 {
 	u64 version, cap0, cap1, ctl2, cxt_l2, lv01_ptr;
 	struct sdxi_cxt_L2_ent *L2_ent;
+	int err;
 
 	version = sdxi_read64(sdxi, SDXI_MMIO_VERSION);
 	dev_info(sdxi->dev, "SDXI %llu.%llu device found\n",
@@ -349,6 +351,16 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 			      sdxi->L1_dma >> ilog2(SZ_4K));
 	L2_ent->lv01_ptr = cpu_to_le64(lv01_ptr);
 
+	/*
+	 * SDXI 1.0 4.1.8.4 Administrative Context
+	 *
+	 * The admin context will not consume descriptors until we
+	 * write its doorbell later.
+	 */
+	err = sdxi_admin_cxt_init(sdxi);
+	if (err)
+		return err;
+
 	return 0;
 }
 
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index 82a9c20d8bcf..d1917dad243f 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -62,12 +62,39 @@ static_assert(sizeof(struct sdxi_cxt_ctl) == 64);
 /* SDXI 1.0 Table 3-5: Context Status (CXT_STS) */
 struct sdxi_cxt_sts {
 	__u8 state;
+#define SDXI_CXT_STS_STATE GENMASK(3, 0)
 	__u8 misc0;
 	__u8 rsvd_0[6];
 	__le64 read_index;
 } __packed __aligned(16);
 static_assert(sizeof(struct sdxi_cxt_sts) == 16);
 
+/* SDXI 1.0 Table 3-6: CXT_STS.state Encoding */
+/* Valid values for FIELD_GET(SDXI_CXT_STS_STATE, sdxi_cxt_sts.state). */
+enum cxt_sts_state {
+	CXTV_STOP_SW  = 0x0,
+	CXTV_RUN      = 0x1,
+	CXTV_STOPG_SW = 0x2,
+	CXTV_STOP_FN  = 0x4,
+	CXTV_STOPG_FN = 0x6,
+	CXTV_ERR_FN   = 0xf,
+};
+
+/* SDXI 1.0 Table 3-7: AKey Table Entry (AKEY_ENT) */
+struct sdxi_akey_ent {
+	__le16 intr_num;
+#define SDXI_AKEY_ENT_VL BIT(0)
+#define SDXI_AKEY_ENT_IV BIT(1)
+#define SDXI_AKEY_ENT_INTR_NUM GENMASK(14, 4)
+	__le16 tgt_sfunc;
+	__le32 pasid;
+	__le16 stag;
+	__u8   rsvd_0[2];
+	__le16 rkey;
+	__u8   rsvd_1[2];
+} __packed __aligned(16);
+static_assert(sizeof(struct sdxi_akey_ent) == 16);
+
 struct sdxi_desc {
 	union {
 		/*
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index 356a47ed39da..b7d754132268 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -51,6 +51,8 @@ struct sdxi_dev {
 
 	struct dma_pool *cxt_ctl_pool;
 
+	struct sdxi_cxt *admin_cxt;
+
 	bool has_mailbox;
 
 	const struct sdxi_bus_ops *bus_ops;

-- 
2.56.0

