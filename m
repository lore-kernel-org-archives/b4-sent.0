From: Nathan Lynch <nathan.lynch@amd.com>
Date: Mon, 11 May 2026 14:16:18 -0500
Subject: [PATCH v2 06/23] dmaengine: sdxi: Allocate DMA pools
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-sdxi-base-v2-6-889cfed17e3f@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778526994; l=4565;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=FWApHbetBl60BiG/6UcSxf9DaE9B7+UhongIG9ld7oY=;
 b=L4STfDQDOGqFuQLEn+GJs20sPovVE4KT5rq+t6BfOzmpyuLi/RaCXVunO3/zkO4OpsVBYNa8G
 qH2gdw7B7faARxgRjxKJdKa1LfBwTJtabxRRMZ7/RAOtR/Sls5mGSFD
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each SDXI context consists of several control structures in system
memory:

* Descriptor ring
* Access key (AKey) table
* Context control block (CXT_CTL)
* Context status block (CXT_STS)
* Write index

Of these, the write index, context control and context status blocks
are small enough to justify DMA pools.

SDXI descriptors also may have 32-byte completion status
blocks (CST_BLK) associated with them that software can poll for
completion.

Introduce the C structures for context control, context status, and
completion status blocks. Create a DMA pool for each of these objects
as well as write indexes during SDXI function initialization, ensuring
that potentially frequently-updated objects are aligned to avoid
cacheline sharing.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/device.c | 42 +++++++++++++++++++++++++++++++++++++++++-
 drivers/dma/sdxi/hw.h     | 28 ++++++++++++++++++++++++++++
 drivers/dma/sdxi/sdxi.h   |  5 +++++
 3 files changed, 74 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index 6a2204ff7fde..851e73597c22 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -6,12 +6,15 @@
  */
 
 #include <linux/bitfield.h>
+#include <linux/cache.h>
 #include <linux/delay.h>
 #include <linux/device.h>
 #include <linux/dma-mapping.h>
+#include <linux/dmapool.h>
 #include <linux/iopoll.h>
 #include <linux/jiffies.h>
 #include <linux/log2.h>
+#include <linux/minmax.h>
 #include <linux/slab.h>
 #include <linux/time.h>
 
@@ -211,6 +214,43 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 	return 0;
 }
 
+static int sdxi_device_init(struct sdxi_dev *sdxi)
+{
+	struct device *dev = sdxi->dev;
+	size_t size, align;
+	int err;
+
+	size = sizeof(__le64);
+	align = max(size, SMP_CACHE_BYTES);
+	sdxi->write_index_pool = dmam_pool_create("Write_Index", dev, size,
+						  align, 0);
+	if (!sdxi->write_index_pool)
+		return -ENOMEM;
+
+	size = sizeof(struct sdxi_cxt_sts);
+	align = max(size, SMP_CACHE_BYTES);
+	sdxi->cxt_sts_pool = dmam_pool_create("CXT_STS", dev, size, align, 0);
+	if (!sdxi->cxt_sts_pool)
+		return -ENOMEM;
+
+	size = align = sizeof(struct sdxi_cxt_ctl);
+	sdxi->cxt_ctl_pool = dmam_pool_create("CXT_CTL", dev, size, align, 0);
+	if (!sdxi->cxt_ctl_pool)
+		return -ENOMEM;
+
+	size = sizeof(struct sdxi_cst_blk);
+	align = max(size, SMP_CACHE_BYTES);
+	sdxi->cst_blk_pool = dmam_pool_create("CST_BLK", dev, size, align, 0);
+	if (!sdxi->cst_blk_pool)
+		return -ENOMEM;
+
+	err = sdxi_fn_activate(sdxi);
+	if (err)
+		return err;
+
+	return 0;
+}
+
 int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 {
 	struct sdxi_dev *sdxi;
@@ -228,5 +268,5 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 	if (err)
 		return err;
 
-	return sdxi_fn_activate(sdxi);
+	return sdxi_device_init(sdxi);
 }
diff --git a/drivers/dma/sdxi/hw.h b/drivers/dma/sdxi/hw.h
index df520ca7792b..846c671c423f 100644
--- a/drivers/dma/sdxi/hw.h
+++ b/drivers/dma/sdxi/hw.h
@@ -58,4 +58,32 @@ struct sdxi_cxt_L1_table {
 };
 static_assert(sizeof(struct sdxi_cxt_L1_table) == 4096);
 
+/* SDXI 1.0 Table 3-4: Context Control (CXT_CTL) */
+struct sdxi_cxt_ctl {
+	__le64 ds_ring_ptr;
+	__le32 ds_ring_sz;
+	__u8 rsvd_0[4];
+	__le64 cxt_sts_ptr;
+	__le64 write_index_ptr;
+	__u8 rsvd_1[32];
+} __packed;
+static_assert(sizeof(struct sdxi_cxt_ctl) == 64);
+
+/* SDXI 1.0 Table 3-5: Context Status (CXT_STS) */
+struct sdxi_cxt_sts {
+	__u8 state;
+	__u8 misc0;
+	__u8 rsvd_0[6];
+	__le64 read_index;
+} __packed;
+static_assert(sizeof(struct sdxi_cxt_sts) == 16);
+
+/* SDXI 1.0 Table 6-4: CST_BLK (Completion Status Block) */
+struct sdxi_cst_blk {
+	__le64 signal;
+	__le32 flags;
+	__u8 rsvd_0[20];
+} __packed;
+static_assert(sizeof(struct sdxi_cst_blk) == 32);
+
 #endif /* DMA_SDXI_HW_H */
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index 85ff17c48d40..fbc95ef69d5c 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -44,6 +44,11 @@ struct sdxi_dev {
 	struct sdxi_cxt_L1_table *L1_table;
 	dma_addr_t L1_dma;
 
+	struct dma_pool *write_index_pool;
+	struct dma_pool *cxt_sts_pool;
+	struct dma_pool *cxt_ctl_pool;
+	struct dma_pool *cst_blk_pool;
+
 	const struct sdxi_bus_ops *bus_ops;
 };
 

-- 
2.54.0

