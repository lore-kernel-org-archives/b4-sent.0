From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:46 -0600
Subject: [PATCH v4 05/25] dmaengine: sdxi: Feature discovery and initial
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-5-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=5209;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=PsmUsZs0rNQf6wIHSDpbWCqhqZyz/6uJ047WgkPg8tU=;
 b=Xkxmtc1dtrM14A8i1cg86RtBzBtEWRONyy8sA+RTYDxtj2j7XjmnqEGTcep95SweU5R5+4P1V
 Er+rwx4lzfVCjnN84BtxqN9Fp1HNXEj0RAGIdSvHCOcSqslhcmycq6E
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Discover the stopped function's version, doorbell stride, supported
operation groups, and context and buffer limits. Apply the driver
configuration to MMIO_CTL2 after function preparation has removed
inherited state.

Add capability fields and device bookkeeping. Report the SDXI version implemented by the function.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/device.c | 47 ++++++++++++++++++++++++++++++++++++++++++++++-
 drivers/dma/sdxi/mmio.h   | 13 +++++++++++++
 drivers/dma/sdxi/sdxi.h   |  6 ++++++
 3 files changed, 65 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index 23a75beb6912..c03af5833414 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -8,9 +8,13 @@
 #include <linux/bitfield.h>
 #include <linux/delay.h>
 #include <linux/device.h>
+#include <linux/dma-mapping.h>
 #include <linux/export.h>
 #include <linux/iopoll.h>
 #include <linux/jiffies.h>
+#include <linux/limits.h>
+#include <linux/minmax.h>
+#include <linux/sizes.h>
 #include <linux/slab.h>
 #include <linux/time.h>
 
@@ -275,6 +279,43 @@ static int sdxi_fn_prepare(struct sdxi_dev *sdxi)
 	return 0;
 }
 
+/*
+ * See SDXI 1.0 4.1.8 Activation of the SDXI Function by Software.
+ */
+static int sdxi_fn_activate(struct sdxi_dev *sdxi)
+{
+	u64 version, cap0, cap1, ctl2;
+
+	version = sdxi_read64(sdxi, SDXI_MMIO_VERSION);
+	dev_info(sdxi->dev, "SDXI %llu.%llu device found\n",
+		  FIELD_GET(SDXI_MMIO_VERSION_MAJOR, version),
+		  FIELD_GET(SDXI_MMIO_VERSION_MINOR, version));
+
+	/* Read capabilities and features. */
+	cap0 = sdxi_read64(sdxi, SDXI_MMIO_CAP0);
+	sdxi->db_stride = SZ_4K;
+	sdxi->db_stride *= 1U << FIELD_GET(SDXI_MMIO_CAP0_DB_STRIDE, cap0);
+
+	cap1 = sdxi_read64(sdxi, SDXI_MMIO_CAP1);
+	sdxi->op_grp_cap = FIELD_GET(SDXI_MMIO_CAP1_OPB_000_CAP, cap1);
+	sdxi->max_buffer = FIELD_GET(SDXI_MMIO_CAP1_MAX_BUFFER, cap1);
+	dma_set_max_seg_size(sdxi->dev,
+			     min((u64)SZ_2M << sdxi->max_buffer, U32_MAX));
+	sdxi->max_cxtid = FIELD_GET(SDXI_MMIO_CAP1_MAX_CXT, cap1);
+
+	/* Apply our configuration. */
+	ctl2 = FIELD_PREP(SDXI_MMIO_CTL2_MAX_CXT, sdxi->max_cxtid);
+	ctl2 |= FIELD_PREP(SDXI_MMIO_CTL2_MAX_BUFFER,
+			   sdxi->max_buffer);
+	ctl2 |= FIELD_PREP(SDXI_MMIO_CTL2_MAX_AKEY_SZ,
+			   FIELD_GET(SDXI_MMIO_CAP1_MAX_AKEY_SZ, cap1));
+	ctl2 |= FIELD_PREP(SDXI_MMIO_CTL2_OPB_000_AVL,
+			   FIELD_GET(SDXI_MMIO_CAP1_OPB_000_CAP, cap1));
+	sdxi_write64(sdxi, SDXI_MMIO_CTL2, ctl2);
+
+	return 0;
+}
+
 int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 {
 	struct sdxi_dev *sdxi;
@@ -292,7 +333,11 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 	if (err)
 		return err;
 
-	return sdxi_fn_prepare(sdxi);
+	err = sdxi_fn_prepare(sdxi);
+	if (err)
+		return err;
+
+	return sdxi_fn_activate(sdxi);
 }
 EXPORT_SYMBOL_NS_GPL(sdxi_register, "SDXI");
 
diff --git a/drivers/dma/sdxi/mmio.h b/drivers/dma/sdxi/mmio.h
index a9c1fbb404d5..7c416de9f874 100644
--- a/drivers/dma/sdxi/mmio.h
+++ b/drivers/dma/sdxi/mmio.h
@@ -16,7 +16,9 @@ enum sdxi_reg {
 	SDXI_MMIO_CTL0       = 0x00000,
 	SDXI_MMIO_CTL2       = 0x00010,
 	SDXI_MMIO_STS0       = 0x00100,
+	SDXI_MMIO_CAP0       = 0x00200,
 	SDXI_MMIO_CAP1       = 0x00208,
+	SDXI_MMIO_VERSION    = 0x00210,
 
 	/* SDXI 1.0 9.2 Context and RKey Table Registers */
 	SDXI_MMIO_CXT_L2     = 0x10000,
@@ -48,6 +50,11 @@ enum sdxi_reg {
 /* SDXI 1.0 Table 9-5: MMIO_STS0 */
 #define SDXI_MMIO_STS0_FN_GSV GENMASK_ULL(2, 0)
 
+/* SDXI 1.0 Table 9-6: MMIO_CAP0 */
+#define SDXI_MMIO_CAP0_SFUNC          GENMASK_ULL(15, 0)
+#define SDXI_MMIO_CAP0_DB_STRIDE      GENMASK_ULL(22, 20)
+#define SDXI_MMIO_CAP0_MAX_DS_RING_SZ GENMASK_ULL(28, 24)
+
 /* SDXI 1.0 Table 9-7: MMIO_CAP1 */
 #define SDXI_MMIO_CAP1_MAX_BUFFER  GENMASK_ULL(3, 0)
 #define SDXI_MMIO_CAP1_RKEY_CAP    BIT_ULL(4)
@@ -55,6 +62,12 @@ enum sdxi_reg {
 #define SDXI_MMIO_CAP1_MAX_AKEY_SZ GENMASK_ULL(15, 12)
 #define SDXI_MMIO_CAP1_MAX_CXT     GENMASK_ULL(31, 16)
 
+#define SDXI_MMIO_CAP1_OPB_000_CAP GENMASK_ULL(63, 32)
+
+/* SDXI 1.0 Table 9-8: MMIO_VERSION */
+#define SDXI_MMIO_VERSION_MINOR GENMASK_ULL(7, 0)
+#define SDXI_MMIO_VERSION_MAJOR GENMASK_ULL(23, 16)
+
 /* SDXI 1.0 Table 9-10: MMIO_RKEY */
 #define SDXI_MMIO_RKEY_EN BIT_ULL(0)
 
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index bb0d2165d495..7569b8395ce1 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -38,6 +38,12 @@ struct sdxi_dev {
 	void __iomem *ctrl_regs;	/* virt addr of ctrl registers */
 	void __iomem *dbs;		/* virt addr of doorbells */
 
+	/* hardware capabilities (from cap0 & cap1) */
+	u32 db_stride;			/* doorbell stride in bytes */
+	u16 max_cxtid;			/* Maximum context ID allowed. */
+	u8 max_buffer;			/* Configured log2 buffer size minus 21. */
+	u32 op_grp_cap;			/* supported operation group cap */
+
 	bool has_mailbox;
 
 	const struct sdxi_bus_ops *bus_ops;

-- 
2.56.0

