From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 05 Sep 2025 13:48:27 -0500
Subject: [PATCH RFC 04/13] dmaengine: sdxi: Add MMIO register definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250905-sdxi-base-v1-4-d0341a1292ba@amd.com>
References: <20250905-sdxi-base-v1-0-d0341a1292ba@amd.com>
In-Reply-To: <20250905-sdxi-base-v1-0-d0341a1292ba@amd.com>
To: Vinod Koul <vkoul@kernel.org>
Cc: Wei Huang <wei.huang2@amd.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dmaengine@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757098128; l=4036;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=AGyFf5vWBLGgXMTQeKDi2itH4wGLo9U+txLID+JDYc8=;
 b=ckXC4832wmhdl4X+GtoJDyWK0pWs8vPBZBZHOHorNo+MFrwg6bZ22a0Ak7sqn1klOyKsStt2B
 li2rBwFyrwtCp8P9srcd/tkiA9PC/r4rA82+S0RqE0uln/bfHYYtEKj
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=ZR637UTGg5YLDj56cxFeHdYoUjPMMFbcijfOkAmAnbc=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20241010 with auth_id=241
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add offsets and bitmasks for:

* General control and status registers (MMIO_CTL0, MMIO_CTL2,
  MMIO_STS0)
* Capability registers (MMIO_CAP0, MMIO_CAP1)
* Context table pointer register (MMIO_CXT_L2)
* Error logging control and status registers (MMIO_ERR_CTL,
  MMIO_ERR_STS, MMIO_ERR_CFG, MMIO_ERR_WRT, MMIO_ERR_RD)

This is a useful subset of the MMIO registers and fields defined in
the spec. The driver currently does not use MMIO_VERSION,
MMIO_GRP_ENUM, or the mailbox registers.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/mmio.h | 92 +++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 92 insertions(+)

diff --git a/drivers/dma/sdxi/mmio.h b/drivers/dma/sdxi/mmio.h
new file mode 100644
index 0000000000000000000000000000000000000000..36d174a1f8859055f7808d520de1ff193c49ae26
--- /dev/null
+++ b/drivers/dma/sdxi/mmio.h
@@ -0,0 +1,92 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+
+/*
+ * SDXI MMIO register offsets and layouts.
+ *
+ * Copyright (C) 2025 Advanced Micro Devices, Inc.
+ */
+
+#ifndef DMA_SDXI_MMIO_H
+#define DMA_SDXI_MMIO_H
+
+#include <linux/bits.h>
+#include <linux/compiler_attributes.h>
+#include <linux/compiler_types.h>
+#include <linux/types.h>
+
+/* Refer to "MMIO Control Registers". */
+enum sdxi_reg {
+	SDXI_MMIO_CTL0       = 0x00000,
+	SDXI_MMIO_CTL2       = 0x00010,
+	SDXI_MMIO_STS0       = 0x00100,
+	SDXI_MMIO_CAP0       = 0x00200,
+	SDXI_MMIO_CAP1       = 0x00208,
+	SDXI_MMIO_VERSION    = 0x00210,
+	SDXI_MMIO_CXT_L2     = 0x10000,
+	SDXI_MMIO_RKEY       = 0x10100,
+	SDXI_MMIO_ERR_CTL    = 0x20000,
+	SDXI_MMIO_ERR_STS    = 0x20008,
+	SDXI_MMIO_ERR_CFG    = 0x20010,
+	SDXI_MMIO_ERR_WRT    = 0x20020,
+	SDXI_MMIO_ERR_RD     = 0x20028,
+};
+
+enum {
+	/* SDXI_MMIO_CTL0 fields */
+	SDXI_MMIO_CTL0_FN_GSR         = GENMASK_ULL(1, 0),
+	SDXI_MMIO_CTL0_FN_PASID_VL    = BIT_ULL(2),
+	SDXI_MMIO_CTL0_FN_ERR_INTR_EN = BIT_ULL(4),
+	SDXI_MMIO_CTL0_FN_PASID       = GENMASK_ULL(27, 8),
+	SDXI_MMIO_CTL0_FN_GRP_ID      = GENMASK_ULL(63, 32),
+
+	/* SDXI_MMIO_CTL2 fields */
+	SDXI_MMIO_CTL2_MAX_BUFFER  = GENMASK_ULL(3, 0),
+	SDXI_MMIO_CTL2_MAX_AKEY_SZ = GENMASK_ULL(15, 12),
+	SDXI_MMIO_CTL2_MAX_CXT     = GENMASK_ULL(31, 16),
+	SDXI_MMIO_CTL2_OPB_000_AVL = GENMASK_ULL(63, 32),
+
+	/* SDXI_MMIO_STS0 bit definitions */
+	SDXI_MMIO_STS0_FN_GSV = GENMASK_ULL(2, 0),
+
+	/* SDXI_MMIO_CAP0 bit definitions */
+	SDXI_MMIO_CAP0_SFUNC = GENMASK_ULL(15, 0),
+	SDXI_MMIO_CAP0_DB_STRIDE = GENMASK_ULL(22, 20),
+	SDXI_MMIO_CAP0_MAX_DS_RING_SZ = GENMASK_ULL(28, 24),
+
+	/* SDXI_MMIO_CAP1 fields */
+	SDXI_MMIO_CAP1_MAX_BUFFER    = GENMASK_ULL(3, 0),
+	SDXI_MMIO_CAP1_RKEY_CAP      = BIT_ULL(4),
+	SDXI_MMIO_CAP1_RM            = BIT_ULL(5),
+	SDXI_MMIO_CAP1_MMIO64        = BIT_ULL(6),
+	SDXI_MMIO_CAP1_MAX_ERRLOG_SZ = GENMASK_ULL(11, 8),
+	SDXI_MMIO_CAP1_MAX_AKEY_SZ   = GENMASK_ULL(15, 12),
+	SDXI_MMIO_CAP1_MAX_CXT       = GENMASK_ULL(31, 16),
+	SDXI_MMIO_CAP1_OPB_000_CAP   = GENMASK_ULL(63, 32),
+
+	/* SDXI_MMIO_VERSION fields */
+	SDXI_MMIO_VERSION_MINOR = GENMASK_ULL(7, 0),
+	SDXI_MMIO_VERSION_MAJOR = GENMASK_ULL(23, 16),
+
+	/* SDXI_MMIO_CXT_L2 fields */
+	SDXI_MMIO_CXT_L2_PTR = GENMASK_ULL(63, 12),
+
+	/* SDXI_MMIO_ERR_CFG bit definitions */
+	SDXI_MMIO_ERR_CFG_PTR = GENMASK_ULL(63, 12),
+	SDXI_MMIO_ERR_CFG_SZ  = GENMASK_ULL(5, 1),
+	SDXI_MMIO_ERR_CFG_EN  = BIT_ULL(0),
+
+	/* SDXI_MMIO_RKEY bit definitions */
+	SDXI_MMIO_RKEY_PTR = GENMASK_ULL(63, 12),
+	SDXI_MMIO_RKEY_SZ = GENMASK_ULL(4, 1),
+	SDXI_MMIO_RKEY_EN = BIT_ULL(0),
+
+	/* SDXI_MMIO_ERR_CTL bit definitions */
+	SDXI_MMIO_ERR_CTL_EN = BIT_ULL(0),
+
+	/* SDXI_MMIO_ERR_STS bit definitions. */
+	SDXI_MMIO_ERR_STS_STS_BIT = BIT_ULL(0),
+	SDXI_MMIO_ERR_STS_OVF_BIT = BIT_ULL(1),
+	SDXI_MMIO_ERR_STS_ERR_BIT = BIT_ULL(3),
+};
+
+#endif  /* DMA_SDXI_MMIO_H */

-- 
2.39.5

