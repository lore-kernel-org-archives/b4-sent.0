From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:51 -0600
Subject: [PATCH v4 10/25] dmaengine: sdxi: Install administrative context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-10-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=8778;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=qIRQFUsn8xcSF9rKDvVAgvzvOX/M/QNU3jdX3vroBLI=;
 b=NoRY3iHlU8EmPwun3jAhs2jKBCNIKfrTqnvwCYAg+U67p5mKFTe11Y2LxK8dIyp5heN7vBz3k
 jMtu6vXpxL5BeVDOkSU8xLgEWpQEIi5rHuS0sNLawEqcYnAvjBLJfne
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Serialize the context control block, akey table, and L1 entry for the
admin context, making its descriptor ring, write index, and context
status block visible to the SDXI implementation once it is activated.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.c | 149 +++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/context.h |   7 +++
 drivers/dma/sdxi/hw.h      |  15 +++++
 drivers/dma/sdxi/sdxi.h    |   9 +++
 4 files changed, 180 insertions(+)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index 4132618ae17a..ebce30dc462a 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -7,16 +7,22 @@
 
 #define pr_fmt(fmt)     "SDXI: " fmt
 
+#include <linux/align.h>
+#include <linux/bitfield.h>
 #include <linux/bug.h>
 #include <linux/cleanup.h>
 #include <linux/device/devres.h>
 #include <linux/dma-mapping.h>
 #include <linux/dmapool.h>
 #include <linux/errno.h>
+#include <linux/iommu.h>
 #include <linux/slab.h>
 #include <linux/types.h>
+#include <asm/barrier.h>
+#include <asm/rwonce.h>
 
 #include "context.h"
+#include "hw.h"
 #include "sdxi.h"
 #include "submission.h"
 
@@ -79,6 +85,139 @@ static struct sdxi_cxt *sdxi_alloc_cxt(struct sdxi_dev *sdxi)
 	return_ptr(cxt);
 }
 
+struct sdxi_cxt_ctl_cfg {
+	dma_addr_t ds_ring_ptr;
+	dma_addr_t cxt_sts_ptr;
+	dma_addr_t write_index_ptr;
+	u32 ds_ring_sz;
+	u8 qos;
+	u8 csa;
+	bool se;
+};
+
+static int configure_cxt_ctl(struct sdxi_cxt_ctl *ctl, const struct sdxi_cxt_ctl_cfg *cfg)
+{
+	u64 ds_ring_ptr, cxt_sts_ptr, write_index_ptr;
+
+	write_index_ptr = FIELD_PREP(SDXI_CXT_CTL_WRITE_INDEX_PTR,
+				     cfg->write_index_ptr >> WRT_INDEX_PTR_SHIFT);
+	cxt_sts_ptr = FIELD_PREP(SDXI_CXT_CTL_CXT_STS_PTR,
+				 cfg->cxt_sts_ptr >> CXT_STATUS_PTR_SHIFT);
+
+	*ctl = (typeof(*ctl)) {
+		.ds_ring_sz      = cpu_to_le32(cfg->ds_ring_sz),
+		.cxt_sts_ptr     = cpu_to_le64(cxt_sts_ptr),
+		.write_index_ptr = cpu_to_le64(write_index_ptr),
+	};
+
+	ds_ring_ptr = FIELD_PREP(SDXI_CXT_CTL_VL, 1) |
+		      FIELD_PREP(SDXI_CXT_CTL_QOS, cfg->qos) |
+		      FIELD_PREP(SDXI_CXT_CTL_SE, cfg->se) |
+		      FIELD_PREP(SDXI_CXT_CTL_CSA, cfg->csa) |
+		      FIELD_PREP(SDXI_CXT_CTL_DS_RING_PTR,
+				 cfg->ds_ring_ptr >> DESC_RING_BASE_PTR_SHIFT);
+	/* Ensure other fields are visible before hw sees vl=1. */
+	dma_wmb();
+	WRITE_ONCE(ctl->ds_ring_ptr, cpu_to_le64(ds_ring_ptr));
+
+	return 0;
+}
+
+/*
+ * Logical representation of CXT_L1_ENT subfields.
+ */
+struct sdxi_cxt_L1_cfg {
+	dma_addr_t cxt_ctl_ptr;
+	dma_addr_t akey_ptr;
+	u32 cxt_pasid;
+	u32 opb_000_enb;
+	u16 max_buffer;
+	u8 akey_sz;
+	bool ka;
+	bool pv;
+};
+
+static int configure_L1_entry(struct sdxi_cxt_L1_ent *ent,
+			      const struct sdxi_cxt_L1_cfg *cfg)
+{
+	u64 cxt_ctl_ptr, akey_ptr;
+	u32 misc0;
+
+	if (WARN_ON_ONCE(!IS_ALIGNED(cfg->cxt_ctl_ptr, SZ_64)))
+		return -EFAULT;
+	if (WARN_ON_ONCE(!IS_ALIGNED(cfg->akey_ptr, SZ_4K)))
+		return -EFAULT;
+
+	akey_ptr = FIELD_PREP(SDXI_CXT_L1_ENT_AKEY_SZ, cfg->akey_sz) |
+		   FIELD_PREP(SDXI_CXT_L1_ENT_AKEY_PTR,
+			      cfg->akey_ptr >> L1_CXT_AKEY_PTR_SHIFT);
+
+	misc0 = FIELD_PREP(SDXI_CXT_L1_ENT_PASID, cfg->cxt_pasid) |
+		FIELD_PREP(SDXI_CXT_L1_ENT_MAX_BUFFER, cfg->max_buffer);
+
+	*ent = (typeof(*ent)) {
+		.akey_ptr    = cpu_to_le64(akey_ptr),
+		.misc0       = cpu_to_le32(misc0),
+		.opb_000_enb = cpu_to_le32(cfg->opb_000_enb),
+	};
+
+	cxt_ctl_ptr = FIELD_PREP(SDXI_CXT_L1_ENT_VL, 1) |
+		      FIELD_PREP(SDXI_CXT_L1_ENT_KA, cfg->ka) |
+		      FIELD_PREP(SDXI_CXT_L1_ENT_PV, cfg->pv) |
+		      FIELD_PREP(SDXI_CXT_L1_ENT_CXT_CTL_PTR,
+				 cfg->cxt_ctl_ptr >> L1_CXT_CTRL_PTR_SHIFT);
+	/* Ensure other fields are visible before hw sees vl=1. */
+	dma_wmb();
+	WRITE_ONCE(ent->cxt_ctl_ptr, cpu_to_le64(cxt_ctl_ptr));
+
+	return 0;
+}
+
+/* Publish the context control block and L1 entry to hardware. */
+static int sdxi_publish_cxt(const struct sdxi_cxt *cxt)
+{
+	struct sdxi_cxt_ctl_cfg ctl_cfg;
+	struct sdxi_cxt_L1_cfg L1_cfg;
+	struct sdxi_cxt_L1_ent *ent;
+	u8 l1_idx;
+	int err;
+
+	if (WARN_ONCE(cxt->id > cxt->sdxi->max_cxtid,
+		      "can't install cxt with id %u (limit %u)",
+		      cxt->id, cxt->sdxi->max_cxtid))
+		return -EINVAL;
+
+	ctl_cfg = (typeof(ctl_cfg)) {
+		.se              = 1,
+		.csa             = 1,
+		.ds_ring_ptr     = sdxi_sq_ring_dma(cxt->sq),
+		.ds_ring_sz      = cxt->sq->count,
+		.cxt_sts_ptr     = sdxi_sq_cxt_sts_dma(cxt->sq),
+		.write_index_ptr = sdxi_sq_write_index_dma(cxt->sq),
+	};
+
+	err = configure_cxt_ctl(cxt->cxt_ctl, &ctl_cfg);
+	if (err)
+		return err;
+
+	l1_idx = ID_TO_L1_INDEX(cxt->id);
+
+	ent = &cxt->sdxi->L1_table->entry[l1_idx];
+
+	L1_cfg = (typeof(L1_cfg)) {
+		.ka          = 1,
+		.pv          = 0,
+		.cxt_ctl_ptr = cxt->cxt_ctl_dma,
+		.akey_sz     = akey_table_order(cxt->akey_table),
+		.akey_ptr    = cxt->akey_table_dma,
+		.cxt_pasid   = IOMMU_NO_PASID,
+		.max_buffer  = cxt->sdxi->max_buffer,
+		.opb_000_enb = cxt->sdxi->op_grp_cap,
+	};
+
+	return configure_L1_entry(ent, &L1_cfg);
+}
+
 static void free_admin_cxt(void *ptr)
 {
 	struct sdxi_dev *sdxi = ptr;
@@ -88,13 +227,23 @@ static void free_admin_cxt(void *ptr)
 
 int sdxi_admin_cxt_init(struct sdxi_dev *sdxi)
 {
+	int err;
+	struct sdxi_sq *sq;
+
 	struct sdxi_cxt *cxt __free(sdxi_cxt) = sdxi_alloc_cxt(sdxi);
 	if (!cxt)
 		return -ENOMEM;
 
+	sq = cxt->sq;
+	/* SDXI 1.0 4.1.8.4.b: Set CXT_STS.state to CXTV_RUN. */
+	sq->cxt_sts.state = FIELD_PREP(SDXI_CXT_STS_STATE, CXTV_RUN);
 	cxt->id = SDXI_ADMIN_CXT_ID;
 	cxt->sq->doorbell = sdxi->dbs + cxt->id * sdxi->db_stride;
 
+	err = sdxi_publish_cxt(cxt);
+	if (err)
+		return err;
+
 	sdxi->admin_cxt = no_free_ptr(cxt);
 
 	return devm_add_action_or_reset(sdxi->dev, free_admin_cxt, sdxi);
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index 873ad49c3c86..ae1584d00b54 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -18,6 +18,13 @@ struct sdxi_akey_table {
 	struct sdxi_akey_ent entry[SZ_4K / sizeof(struct sdxi_akey_ent)];
 };
 
+/* For encoding the akey table size in CXT_L1_ENT's akey_sz. */
+static inline u8 akey_table_order(const struct sdxi_akey_table *tbl)
+{
+	static_assert(sizeof(*tbl) == SZ_4K);
+	return 0;
+}
+
 struct sdxi_cxt {
 	struct sdxi_dev *sdxi;
 	u16 id;
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index d1917dad243f..b333e091c583 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -34,8 +34,16 @@ static_assert(sizeof(struct sdxi_cxt_L2_table) == 4096);
 /* SDXI 1.0 Table 3-3: Context Level 1 Table Entry (CXT_L1_ENT) */
 struct sdxi_cxt_L1_ent {
 	__le64 cxt_ctl_ptr;
+#define SDXI_CXT_L1_ENT_VL             BIT_ULL(0)
+#define SDXI_CXT_L1_ENT_KA             BIT_ULL(1)
+#define SDXI_CXT_L1_ENT_PV             BIT_ULL(2)
+#define SDXI_CXT_L1_ENT_CXT_CTL_PTR    GENMASK_ULL(63, 6)
 	__le64 akey_ptr;
+#define SDXI_CXT_L1_ENT_AKEY_SZ        GENMASK_ULL(3, 0)
+#define SDXI_CXT_L1_ENT_AKEY_PTR       GENMASK_ULL(63, 12)
 	__le32 misc0;
+#define SDXI_CXT_L1_ENT_PASID          GENMASK(19, 0)
+#define SDXI_CXT_L1_ENT_MAX_BUFFER     GENMASK(23, 20)
 	__le32 opb_000_enb;
 	__u8 rsvd_0[8];
 } __packed __aligned(32);
@@ -51,10 +59,17 @@ static_assert(sizeof(struct sdxi_cxt_L1_table) == 4096);
 /* SDXI 1.0 Table 3-4: Context Control (CXT_CTL) */
 struct sdxi_cxt_ctl {
 	__le64 ds_ring_ptr;
+#define SDXI_CXT_CTL_VL             BIT_ULL(0)
+#define SDXI_CXT_CTL_QOS            GENMASK_ULL(3, 2)
+#define SDXI_CXT_CTL_SE             BIT_ULL(4)
+#define SDXI_CXT_CTL_CSA            BIT_ULL(5)
+#define SDXI_CXT_CTL_DS_RING_PTR    GENMASK_ULL(63, 6)
 	__le32 ds_ring_sz;
 	__u8 rsvd_0[4];
 	__le64 cxt_sts_ptr;
+#define SDXI_CXT_CTL_CXT_STS_PTR    GENMASK_ULL(63, 4)
 	__le64 write_index_ptr;
+#define SDXI_CXT_CTL_WRITE_INDEX_PTR GENMASK_ULL(63, 3)
 	__u8 rsvd_1[32];
 } __packed __aligned(64);
 static_assert(sizeof(struct sdxi_cxt_ctl) == 64);
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index b7d754132268..525473029987 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -15,6 +15,15 @@
 
 #include "mmio.h"
 
+#define ID_TO_L1_INDEX(id)	((id) & 0x7F)
+
+#define DESC_RING_BASE_PTR_SHIFT	6
+#define CXT_STATUS_PTR_SHIFT		4
+#define WRT_INDEX_PTR_SHIFT		3
+
+#define L1_CXT_CTRL_PTR_SHIFT		6
+#define L1_CXT_AKEY_PTR_SHIFT		12
+
 struct sdxi_dev;
 
 /**

-- 
2.56.0

