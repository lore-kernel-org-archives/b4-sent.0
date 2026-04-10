From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:16 -0500
Subject: [PATCH 06/23] dmaengine: sdxi: Allocate DMA pools
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-6-1d184cb5c60a@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=4160;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=yYsDKehkM4Su6gA/w8eyy9OZyEDpuCpJ6inX5B52w14=;
 b=wAVdujdNT6YNKgQ26NGu8syqu1ZYOAPoCK0Kpv5qHmpAE5Hs22ujLAZMKUrpY5EKAAEvIN38+
 f/3+JTAETKODXyk/g9POCTXV9E2qjlypR2KZ3oVphLIu4IzECrkwBiE
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

SDXI descriptors may optionally have 32-byte completion status
blocks (CST_BLK) associated with them that software can poll for
completion.

Introduce the C structures for context control, context status, and
completion status blocks. Create a DMA pool for each of these objects
as well as write indexes during SDXI function initialization.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/device.c | 34 +++++++++++++++++++++++++++++++++-
 drivers/dma/sdxi/hw.h     | 28 ++++++++++++++++++++++++++++
 drivers/dma/sdxi/sdxi.h   |  5 +++++
 3 files changed, 66 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index 7e772ce81365..80bd1bbd9c7c 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -9,6 +9,7 @@
 #include <linux/delay.h>
 #include <linux/device.h>
 #include <linux/dma-mapping.h>
+#include <linux/dmapool.h>
 #include <linux/log2.h>
 #include <linux/slab.h>
 
@@ -188,6 +189,37 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 	return 0;
 }
 
+static int sdxi_create_dma_pool(struct sdxi_dev *sdxi, struct dma_pool **pool,
+				const char *name, size_t size)
+{
+	*pool = dmam_pool_create(name, sdxi_to_dev(sdxi), size, size, 0);
+	return *pool ? 0 : -ENOMEM;
+}
+
+static int sdxi_device_init(struct sdxi_dev *sdxi)
+{
+	int err;
+
+	if (sdxi_create_dma_pool(sdxi, &sdxi->write_index_pool,
+				 "Write_Index", sizeof(__le64)))
+		return -ENOMEM;
+	if (sdxi_create_dma_pool(sdxi, &sdxi->cxt_sts_pool,
+				 "CXT_STS", sizeof(struct sdxi_cxt_sts)))
+		return -ENOMEM;
+	if (sdxi_create_dma_pool(sdxi, &sdxi->cxt_ctl_pool,
+				 "CXT_CTL", sizeof(struct sdxi_cxt_ctl)))
+		return -ENOMEM;
+	if (sdxi_create_dma_pool(sdxi, &sdxi->cst_blk_pool,
+				 "CST_BLK", sizeof(struct sdxi_cst_blk)))
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
@@ -205,5 +237,5 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
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
index 185f58b725da..6cda60bb33c4 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -46,6 +46,11 @@ struct sdxi_dev {
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
2.53.0

