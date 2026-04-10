From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:14 -0500
Subject: [PATCH 04/23] dmaengine: sdxi: Feature discovery and initial
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-4-1d184cb5c60a@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=9474;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=b7xu936IWaAWui2gDis8KlNNC8TGpATPQfcAYDAr6kM=;
 b=y69NHSxZh8DFXKYmeqC9Zq2QsmbA5eS5d6E5M/G8yii7wjB+0qj+1Z4ui552Kxyv9f01qwFqO
 ndycO+cNlbgC8bDMFQzRcOr2GONhO6O2ZxFr5wCAQ0uVJ0jMyUN5cQM
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After bus-specific initialization, force the SDXI function to stopped
state. This is the expected state from reset, but kexec or driver bugs
can leave a function in other states from which the initialization
code must be able to recover.

Discover via the capability registers the doorbell region stride, the
maximum supported context ID, the operation groups implemented, and
limits on buffer and control structure sizes. The driver has the
option of writing more conservative limits to the ctl2 register, but
it uses those supplied by the implementation for now.

Introduce device register definitions and associated masks via mmio.h.

Add convenience wrappers which are first used here:
- sdxi_dbg()
- sdxi_info()
- sdxi_err()
- sdxi_read64()
- sdxi_write64()

Report the version of the standard to which the device conforms, e.g.

  sdxi 0000:00:03.0: SDXI 1.0 device found

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/device.c | 149 +++++++++++++++++++++++++++++++++++++++++++++-
 drivers/dma/sdxi/mmio.h   |  51 ++++++++++++++++
 drivers/dma/sdxi/sdxi.h   |  23 +++++++
 3 files changed, 222 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index b718ce04afa0..1083fdddd72f 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -5,14 +5,157 @@
  * Copyright Advanced Micro Devices, Inc.
  */
 
+#include <linux/bitfield.h>
+#include <linux/delay.h>
 #include <linux/device.h>
 #include <linux/slab.h>
 
+#include "mmio.h"
 #include "sdxi.h"
 
+enum sdxi_fn_gsv {
+	SDXI_GSV_STOP,
+	SDXI_GSV_INIT,
+	SDXI_GSV_ACTIVE,
+	SDXI_GSV_STOPG_SF,
+	SDXI_GSV_STOPG_HD,
+	SDXI_GSV_ERROR,
+};
+
+static const char *const gsv_strings[] = {
+	[SDXI_GSV_STOP]     = "stopped",
+	[SDXI_GSV_INIT]     = "initializing",
+	[SDXI_GSV_ACTIVE]   = "active",
+	[SDXI_GSV_STOPG_SF] = "soft stopping",
+	[SDXI_GSV_STOPG_HD] = "hard stopping",
+	[SDXI_GSV_ERROR]    = "error",
+};
+
+static const char *gsv_str(enum sdxi_fn_gsv gsv)
+{
+	if ((size_t)gsv < ARRAY_SIZE(gsv_strings))
+		return gsv_strings[(size_t)gsv];
+
+	WARN_ONCE(1, "unexpected gsv %u\n", gsv);
+
+	return "unknown";
+}
+
+enum sdxi_fn_gsr {
+	SDXI_GSRV_RESET,
+	SDXI_GSRV_STOP_SF,
+	SDXI_GSRV_STOP_HD,
+	SDXI_GSRV_ACTIVE,
+};
+
+static enum sdxi_fn_gsv sdxi_dev_gsv(const struct sdxi_dev *sdxi)
+{
+	return (enum sdxi_fn_gsv)FIELD_GET(SDXI_MMIO_STS0_FN_GSV,
+					   sdxi_read64(sdxi, SDXI_MMIO_STS0));
+}
+
+static void sdxi_write_fn_gsr(struct sdxi_dev *sdxi, enum sdxi_fn_gsr cmd)
+{
+	u64 ctl0 = sdxi_read64(sdxi, SDXI_MMIO_CTL0);
+
+	FIELD_MODIFY(SDXI_MMIO_CTL0_FN_GSR, &ctl0, cmd);
+	sdxi_write64(sdxi, SDXI_MMIO_CTL0, ctl0);
+}
+
+/* Get the device to the GSV_STOP state. */
+static int sdxi_dev_stop(struct sdxi_dev *sdxi)
+{
+	unsigned long deadline = jiffies + msecs_to_jiffies(1000);
+	bool reset_issued = false;
+
+	do {
+		enum sdxi_fn_gsv status = sdxi_dev_gsv(sdxi);
+
+		sdxi_dbg(sdxi, "%s: function state: %s\n", __func__, gsv_str(status));
+
+		switch (status) {
+		case SDXI_GSV_ACTIVE:
+			sdxi_write_fn_gsr(sdxi, SDXI_GSRV_STOP_SF);
+			break;
+		case SDXI_GSV_ERROR:
+			if (!reset_issued) {
+				sdxi_info(sdxi,
+					  "function in error state, issuing reset\n");
+				sdxi_write_fn_gsr(sdxi, SDXI_GSRV_RESET);
+				reset_issued = true;
+			} else {
+				fsleep(1000);
+			}
+			break;
+		case SDXI_GSV_STOP:
+			return 0;
+		case SDXI_GSV_INIT:
+		case SDXI_GSV_STOPG_SF:
+		case SDXI_GSV_STOPG_HD:
+			/* transitional states, wait */
+			sdxi_dbg(sdxi, "waiting for stop (gsv = %u)\n",
+				 status);
+			fsleep(1000);
+			break;
+		default:
+			sdxi_err(sdxi, "unknown gsv %u, giving up\n", status);
+			return -EIO;
+		}
+	} while (time_before(jiffies, deadline));
+
+	sdxi_err(sdxi, "stop attempt timed out, current status %u\n",
+		sdxi_dev_gsv(sdxi));
+	return -ETIMEDOUT;
+}
+
+/*
+ * See SDXI 1.0 4.1.8 Activation of the SDXI Function by Software.
+ */
+static int sdxi_fn_activate(struct sdxi_dev *sdxi)
+{
+	u64 version, cap0, cap1, ctl2;
+	int err;
+
+	/*
+	 * Clear any existing configuration from MMIO_CTL0 and ensure
+	 * the function is in GSV_STOP state.
+	 */
+	sdxi_write64(sdxi, SDXI_MMIO_CTL0, 0);
+	err = sdxi_dev_stop(sdxi);
+	if (err)
+		return err;
+
+	version = sdxi_read64(sdxi, SDXI_MMIO_VERSION);
+	sdxi_info(sdxi, "SDXI %llu.%llu device found\n",
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
+	sdxi->max_cxtid = FIELD_GET(SDXI_MMIO_CAP1_MAX_CXT, cap1);
+
+	/* Apply our configuration. */
+	ctl2 = FIELD_PREP(SDXI_MMIO_CTL2_MAX_CXT, sdxi->max_cxtid);
+	ctl2 |= FIELD_PREP(SDXI_MMIO_CTL2_MAX_BUFFER,
+			   FIELD_GET(SDXI_MMIO_CAP1_MAX_BUFFER, cap1));
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
+	int err;
 
 	sdxi = devm_kzalloc(dev, sizeof(*sdxi), GFP_KERNEL);
 	if (!sdxi)
@@ -22,5 +165,9 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 	sdxi->bus_ops = ops;
 	dev_set_drvdata(dev, sdxi);
 
-	return sdxi->bus_ops->init(sdxi);
+	err = sdxi->bus_ops->init(sdxi);
+	if (err)
+		return err;
+
+	return sdxi_fn_activate(sdxi);
 }
diff --git a/drivers/dma/sdxi/mmio.h b/drivers/dma/sdxi/mmio.h
new file mode 100644
index 000000000000..c9a11c3f2f76
--- /dev/null
+++ b/drivers/dma/sdxi/mmio.h
@@ -0,0 +1,51 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+
+/*
+ * SDXI MMIO register offsets and layouts.
+ *
+ * Copyright Advanced Micro Devices, Inc.
+ */
+
+#ifndef DMA_SDXI_MMIO_H
+#define DMA_SDXI_MMIO_H
+
+#include <linux/bits.h>
+
+enum sdxi_reg {
+	/* SDXI 1.0 9.1 General Control and Status Registers */
+	SDXI_MMIO_CTL0       = 0x00000,
+	SDXI_MMIO_CTL2       = 0x00010,
+	SDXI_MMIO_STS0       = 0x00100,
+	SDXI_MMIO_CAP0       = 0x00200,
+	SDXI_MMIO_CAP1       = 0x00208,
+	SDXI_MMIO_VERSION    = 0x00210,
+};
+
+/* SDXI 1.0 Table 9-2: MMIO_CTL0 */
+#define SDXI_MMIO_CTL0_FN_GSR         GENMASK_ULL(1, 0)
+
+/* SDXI 1.0 Table 9-4: MMIO_CTL2 */
+#define SDXI_MMIO_CTL2_MAX_BUFFER  GENMASK_ULL(3, 0)
+#define SDXI_MMIO_CTL2_MAX_AKEY_SZ GENMASK_ULL(15, 12)
+#define SDXI_MMIO_CTL2_MAX_CXT     GENMASK_ULL(31, 16)
+#define SDXI_MMIO_CTL2_OPB_000_AVL GENMASK_ULL(63, 32)
+
+/* SDXI 1.0 Table 9-5: MMIO_STS0 */
+#define SDXI_MMIO_STS0_FN_GSV GENMASK_ULL(2, 0)
+
+/* SDXI 1.0 Table 9-6: MMIO_CAP0 */
+#define SDXI_MMIO_CAP0_SFUNC          GENMASK_ULL(15, 0)
+#define SDXI_MMIO_CAP0_DB_STRIDE      GENMASK_ULL(22, 20)
+#define SDXI_MMIO_CAP0_MAX_DS_RING_SZ GENMASK_ULL(28, 24)
+
+/* SDXI 1.0 Table 9-7: MMIO_CAP1 */
+#define SDXI_MMIO_CAP1_MAX_BUFFER    GENMASK_ULL(3, 0)
+#define SDXI_MMIO_CAP1_MAX_AKEY_SZ   GENMASK_ULL(15, 12)
+#define SDXI_MMIO_CAP1_MAX_CXT       GENMASK_ULL(31, 16)
+#define SDXI_MMIO_CAP1_OPB_000_CAP   GENMASK_ULL(63, 32)
+
+/* SDXI 1.0 Table 9-8: MMIO_VERSION */
+#define SDXI_MMIO_VERSION_MINOR GENMASK_ULL(7, 0)
+#define SDXI_MMIO_VERSION_MAJOR GENMASK_ULL(23, 16)
+
+#endif  /* DMA_SDXI_MMIO_H */
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index 9430f3b8d0b3..427118e60aa6 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -9,8 +9,12 @@
 #define DMA_SDXI_H
 
 #include <linux/compiler_types.h>
+#include <linux/dev_printk.h>
+#include <linux/io-64-nonatomic-lo-hi.h>
 #include <linux/types.h>
 
+#include "mmio.h"
+
 #define SDXI_DRV_DESC		"SDXI driver"
 
 struct sdxi_dev;
@@ -32,6 +36,11 @@ struct sdxi_dev {
 	void __iomem *ctrl_regs;	/* virt addr of ctrl registers */
 	void __iomem *dbs;		/* virt addr of doorbells */
 
+	/* hardware capabilities (from cap0 & cap1) */
+	u32 db_stride;			/* doorbell stride in bytes */
+	u16 max_cxtid;			/* Maximum context ID allowed. */
+	u32 op_grp_cap;			/* supported operation group cap */
+
 	const struct sdxi_bus_ops *bus_ops;
 };
 
@@ -40,6 +49,20 @@ static inline struct device *sdxi_to_dev(const struct sdxi_dev *sdxi)
 	return sdxi->dev;
 }
 
+#define sdxi_dbg(s, fmt, ...) dev_dbg(sdxi_to_dev(s), fmt, ## __VA_ARGS__)
+#define sdxi_info(s, fmt, ...) dev_info(sdxi_to_dev(s), fmt, ## __VA_ARGS__)
+#define sdxi_err(s, fmt, ...) dev_err(sdxi_to_dev(s), fmt, ## __VA_ARGS__)
+
 int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops);
 
+static inline u64 sdxi_read64(const struct sdxi_dev *sdxi, enum sdxi_reg reg)
+{
+	return ioread64(sdxi->ctrl_regs + reg);
+}
+
+static inline void sdxi_write64(struct sdxi_dev *sdxi, enum sdxi_reg reg, u64 val)
+{
+	iowrite64(val, sdxi->ctrl_regs + reg);
+}
+
 #endif /* DMA_SDXI_H */

-- 
2.53.0

