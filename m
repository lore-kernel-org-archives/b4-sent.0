From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 00:13:51 +0000
Subject: [PATCH 2/3] media: rockchip: Add IEP2 deinterlacer driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-iep2-v1-2-a8edde5a21e1@gmail.com>
References: <20261114-iep2-v1-0-a8edde5a21e1@gmail.com>
In-Reply-To: <20261114-iep2-v1-0-a8edde5a21e1@gmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Alex Bee <knaerzche@gmail.com>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615229; l=53932;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=QDA4JD2dwhClrIkdEC+BaCuZk08DrzzCaMXtcNe6BMc=;
 b=Yh2VAdfNKj4C+AUM5NiEkuuFjvwvaILedsAFp7ffNUAFf08MYM8DgX1nA4kjV7W1RWrxi+Vwo
 lMhczRh1wePDSLejvDvQImRqY030me3qBMXghB6HNkMXd238kTZdyzs
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a V4L2 mem2mem driver for the IEP2 deinterlacer of the RK3568 and
RK3588 SoCs.

The register map, programming sequence and default parameters come
from the Rockchip vendor kernel (github.com/rockchip-linux/kernel
develop-6.1, mpp_iep2.c and rockchip_iep2_regs.h, GPL-2.0+ OR MIT,
Ding Wei and Alpha Lin) and the Rockchip MPP library. The V4L2 part
follows Alex Bee's out-of-tree driver for the older IEP, a different
block that keeps the iep names, and sun8i-di.

V4L2_CID_DEINTERLACING_MODE selects bob or motion adaptive at frame or
field rate (see rockchip-iep2.rst). Bob is the default: without
look-ahead, motion adaptive is not reliably better.

The IEP2 reads past the end of the source, so the OUTPUT sizeimage has
4 KiB of tail padding. The vendor kernel maps a spare page at the
faulting address instead.

The interrupt line is shared with the IOMMU. Since the IEP retries a
faulting read forever, a job during which the line fires without IEP
status is aborted. Stuck jobs get a soft reset, then a CRU reset; both
put the IOMMU in bypass, so it is reprogrammed.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 Documentation/admin-guide/media/rockchip-iep2.rst |   59 +
 Documentation/admin-guide/media/v4l-drivers.rst   |    1 +
 MAINTAINERS                                       |    2 +
 drivers/media/platform/rockchip/Kconfig           |    1 +
 drivers/media/platform/rockchip/Makefile          |    1 +
 drivers/media/platform/rockchip/iep2/Kconfig      |   16 +
 drivers/media/platform/rockchip/iep2/Makefile     |    3 +
 drivers/media/platform/rockchip/iep2/iep2-regs.h  |  192 ++++
 drivers/media/platform/rockchip/iep2/iep2.c       | 1275 +++++++++++++++++++++
 drivers/media/platform/rockchip/iep2/iep2.h       |  106 ++
 10 files changed, 1656 insertions(+)

diff --git a/Documentation/admin-guide/media/rockchip-iep2.rst b/Documentation/admin-guide/media/rockchip-iep2.rst
new file mode 100644
index 000000000000..5c95a19146d0
--- /dev/null
+++ b/Documentation/admin-guide/media/rockchip-iep2.rst
@@ -0,0 +1,59 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+Rockchip IEP2 deinterlacer driver
+=================================
+
+The rockchip-iep2 driver supports the IEP2 deinterlacer of the Rockchip RK3568
+and RK3588 SoCs as a V4L2 memory to memory device. It is a different block from
+the IEP of older Rockchip SoCs. The OUTPUT queue takes frames with both fields
+interleaved (``V4L2_FIELD_INTERLACED_TB``, ``V4L2_FIELD_INTERLACED_BT`` or
+``V4L2_FIELD_INTERLACED``), the CAPTURE queue returns progressive frames in the
+same pixel format. A mem2mem device has no video standard, so for
+``V4L2_FIELD_INTERLACED`` the driver takes the field order from the height:
+bottom field first below 576 lines (525-line video), top field first
+otherwise. Userspace that knows the order should use
+``V4L2_FIELD_INTERLACED_TB`` or ``V4L2_FIELD_INTERLACED_BT``.
+
+OUTPUT buffers with ``V4L2_FIELD_NONE`` are copied through unchanged. At field
+rate such a buffer still produces one CAPTURE buffer, but it is only processed
+once two CAPTURE buffers are queued.
+
+The driver implements the following control.
+
+``V4L2_CID_DEINTERLACING_MODE (menu)``
+    The video deinterlacing mode. It selects both the algorithm and the output
+    rate. The rate cannot be changed while one of the queues is streaming
+    (``EBUSY``); a change of algorithm at the same rate is accepted at any
+    time.
+
+.. flat-table::
+    :header-rows:  0
+    :stub-columns: 0
+    :widths:       1 4
+
+    * - ``"Bob, Frame Rate" (0)``
+      - The missing lines are interpolated within one field. One CAPTURE
+        buffer is produced per OUTPUT buffer. This is the default.
+    * - ``"Bob, Field Rate" (1)``
+      - As above for both fields: two CAPTURE buffers are produced per OUTPUT
+        buffer, the temporally first field first (e.g. 50i to 50p).
+    * - ``"Motion Adaptive, Frame Rate" (2)``
+      - Motion-adaptive, motion-compensated interpolation that uses the
+        previous OUTPUT buffer as reference. The first frame of a stream is
+        processed with bob. One CAPTURE buffer is produced per OUTPUT buffer.
+        The driver holds the previous OUTPUT buffer until the next one has
+        been processed, so at least two OUTPUT buffers are needed.
+    * - ``"Motion Adaptive, Field Rate" (3)``
+      - As above for both fields: two CAPTURE buffers are produced per OUTPUT
+        buffer.
+
+Both queues use ``V4L2_BUF_FLAG_TIMESTAMP_COPY``. At field rate both CAPTURE
+buffers of an OUTPUT buffer carry its timestamp; the second one shows the
+field that is half a frame period later.
+
+The hardware reads past the end of the source image, so the ``sizeimage`` of
+the OUTPUT format is 4 KiB larger than the image. Buffers queued on the
+OUTPUT queue, including imported DMABUFs, must have at least that size. The
+payload (``bytesused``) of an OUTPUT buffer must cover at least the image,
+i.e. ``sizeimage`` minus the 4 KiB; a smaller payload is refused with
+``EINVAL`` when the buffer is queued.
diff --git a/Documentation/admin-guide/media/v4l-drivers.rst b/Documentation/admin-guide/media/v4l-drivers.rst
index 4621eae9fa1e..3d59d5d73fd0 100644
--- a/Documentation/admin-guide/media/v4l-drivers.rst
+++ b/Documentation/admin-guide/media/v4l-drivers.rst
@@ -29,6 +29,7 @@ Video4Linux (V4L) driver-specific documentation
 	rcar-fdp1
 	rkcif
 	rkisp1
+	rockchip-iep2
 	raspberrypi-rp1-cfe
 	saa7134
 	si470x
diff --git a/MAINTAINERS b/MAINTAINERS
index b32b7eeb0a9e..564d39b2cca9 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24290,7 +24290,9 @@ M:	Arun Iyengar <aiyengar1990@gmail.com>
 L:	linux-media@vger.kernel.org
 L:	linux-rockchip@lists.infradead.org
 S:	Maintained
+F:	Documentation/admin-guide/media/rockchip-iep2.rst
 F:	Documentation/devicetree/bindings/media/rockchip,rk3568-iep2.yaml
+F:	drivers/media/platform/rockchip/iep2/
 
 ROCKCHIP ISP V1 DRIVER
 M:	Dafna Hirschfeld <dafna@fastmail.com>
diff --git a/drivers/media/platform/rockchip/Kconfig b/drivers/media/platform/rockchip/Kconfig
index ba401d32f01b..4f65bd0126de 100644
--- a/drivers/media/platform/rockchip/Kconfig
+++ b/drivers/media/platform/rockchip/Kconfig
@@ -2,6 +2,7 @@
 
 comment "Rockchip media platform drivers"
 
+source "drivers/media/platform/rockchip/iep2/Kconfig"
 source "drivers/media/platform/rockchip/rga/Kconfig"
 source "drivers/media/platform/rockchip/rkcif/Kconfig"
 source "drivers/media/platform/rockchip/rkisp1/Kconfig"
diff --git a/drivers/media/platform/rockchip/Makefile b/drivers/media/platform/rockchip/Makefile
index 0e0b2cbbd4bd..c385048ba347 100644
--- a/drivers/media/platform/rockchip/Makefile
+++ b/drivers/media/platform/rockchip/Makefile
@@ -1,4 +1,5 @@
 # SPDX-License-Identifier: GPL-2.0-only
+obj-y += iep2/
 obj-y += rga/
 obj-y += rkcif/
 obj-y += rkisp1/
diff --git a/drivers/media/platform/rockchip/iep2/Kconfig b/drivers/media/platform/rockchip/iep2/Kconfig
new file mode 100644
index 000000000000..de1e445b3fd8
--- /dev/null
+++ b/drivers/media/platform/rockchip/iep2/Kconfig
@@ -0,0 +1,16 @@
+# SPDX-License-Identifier: GPL-2.0-only
+config VIDEO_ROCKCHIP_IEP2
+	tristate "Rockchip IEP2 deinterlacer"
+	depends on V4L_MEM2MEM_DRIVERS
+	depends on VIDEO_DEV
+	depends on ARCH_ROCKCHIP || COMPILE_TEST
+	select VIDEOBUF2_DMA_CONTIG
+	select V4L2_MEM2MEM_DEV
+	help
+	  Support for the IEP2 (image enhancement processor) found in the
+	  Rockchip RK3568 and RK3588 SoCs. It is exposed as a V4L2 memory to
+	  memory device that deinterlaces NV12/NV21/NV16/NV61 frames, using
+	  either intra-field (bob) or motion-adaptive interpolation.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called rockchip-iep2.
diff --git a/drivers/media/platform/rockchip/iep2/Makefile b/drivers/media/platform/rockchip/iep2/Makefile
new file mode 100644
index 000000000000..f13bb799de54
--- /dev/null
+++ b/drivers/media/platform/rockchip/iep2/Makefile
@@ -0,0 +1,3 @@
+# SPDX-License-Identifier: GPL-2.0-only
+obj-$(CONFIG_VIDEO_ROCKCHIP_IEP2) += rockchip-iep2.o
+rockchip-iep2-y := iep2.o
diff --git a/drivers/media/platform/rockchip/iep2/iep2-regs.h b/drivers/media/platform/rockchip/iep2/iep2-regs.h
new file mode 100644
index 000000000000..d46aba5b50cf
--- /dev/null
+++ b/drivers/media/platform/rockchip/iep2/iep2-regs.h
@@ -0,0 +1,192 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later OR MIT */
+/*
+ * Based on the Rockchip BSP rockchip_iep2_regs.h,
+ * Copyright (c) 2020 Fuzhou Rockchip Electronics Co., Ltd
+ * Author: Alpha Lin <alpha.lin@rock-chips.com>
+ */
+
+#ifndef __ROCKCHIP_IEP2_REGS_H__
+#define __ROCKCHIP_IEP2_REGS_H__
+
+#include <linux/bits.h>
+
+#define IEP2_FRM_START			0x0000
+#define   IEP2_FRM_EN			BIT(0)
+
+#define IEP2_CONFIG0			0x0004
+#define   IEP2_CCLK_SRESET_P		BIT(22)
+#define   IEP2_ACLK_SRESET_P		BIT(21)
+#define   IEP2_HANDSAVE_P		BIT(20)
+#define   IEP2_RST_PROTECT_EN		BIT(19)
+#define   IEP2_DEBUG_DATA_EN		BIT(16)
+#define   IEP2_DST_YUV_SWAP(x)		(((x) & 3) << 12)
+#define   IEP2_DST_FMT(x)		(((x) & 3) << 8)
+#define   IEP2_SRC_YUV_SWAP(x)		(((x) & 3) << 4)
+#define   IEP2_SRC_FMT(x)		((x) & 3)
+
+#define IEP2_FMT_YUV422			2
+#define IEP2_FMT_YUV420			3
+
+#define IEP2_YUV_SWAP_SP_UV		0
+#define IEP2_YUV_SWAP_SP_VU		1
+
+#define IEP2_WORK_MODE			0x0008
+#define   IEP2_WORK_MODE_IEP2		BIT(0)
+#define   IEP2_WORK_MODE_MASK		GENMASK(1, 0)
+
+#define IEP2_GATING_CTRL		0x0010
+
+#define IEP2_STATUS			0x0014
+#define   IEP2_ARST_FINISH_DONE		BIT(0)
+
+#define IEP2_INT_EN			0x0020
+#define IEP2_INT_CLR			0x0024
+#define IEP2_INT_STS			0x0028
+#define IEP2_INT_RAW_STS		0x002c
+#define   IEP2_INT_TIMEOUT		BIT(5)
+#define   IEP2_INT_BUS_ERROR		BIT(4)
+#define   IEP2_INT_OSD_MAX		BIT(1)
+#define   IEP2_INT_FRM_DONE		BIT(0)
+#define   IEP2_INT_VALID		(IEP2_INT_TIMEOUT | IEP2_INT_BUS_ERROR | \
+					 IEP2_INT_FRM_DONE)
+
+/* Strides are in units of 32-bit words */
+#define IEP2_VIR_SRC_IMG_WIDTH		0x0030
+#define   IEP2_SRC_VIR_UV_STRIDE(x)	(((x) & 0xffff) << 16)
+#define   IEP2_SRC_VIR_Y_STRIDE(x)	((x) & 0xffff)
+#define IEP2_VIR_DST_IMG_WIDTH		0x0034
+#define   IEP2_DST_VIR_STRIDE(x)	((x) & 0xffff)
+
+#define IEP2_SRC_IMG_SIZE		0x0038
+#define   IEP2_SRC_PIC_HEIGHT(x)	(((x) & 0x7ff) << 16)
+#define   IEP2_SRC_PIC_WIDTH(x)		((x) & 0x7ff)
+
+#define IEP2_DIL_CONFIG0		0x0040
+#define   IEP2_DIL_MV_HIST_EN		BIT(17)
+#define   IEP2_DIL_ROI_EN		BIT(16)
+#define   IEP2_DIL_COMB_EN		BIT(15)
+#define   IEP2_DIL_BLE_EN		BIT(14)
+#define   IEP2_DIL_EEDI_EN		BIT(13)
+#define   IEP2_DIL_MEMC_EN		BIT(12)
+#define   IEP2_DIL_OSD_EN		BIT(11)
+#define   IEP2_DIL_PD_EN		BIT(10)
+#define   IEP2_DIL_FF_EN		BIT(9)
+#define   IEP2_DIL_MD_PRE_EN		BIT(8)
+#define   IEP2_DIL_FIELD_ORDER(x)	(((x) & 1) << 5)
+#define   IEP2_DIL_OUT_MODE(x)		(((x) & 1) << 4)
+#define   IEP2_DIL_MODE(x)		((x) & 0xf)
+
+#define IEP2_DIL_FIELD_ORDER_TB		0
+#define IEP2_DIL_FIELD_ORDER_BT		1
+
+#define IEP2_DIL_OUT_MODE_LINE		0
+#define IEP2_DIL_OUT_MODE_TILE		1
+
+#define IEP2_DIL_MODE_DISABLE		0
+#define IEP2_DIL_MODE_I5O2		1
+#define IEP2_DIL_MODE_I5O1T		2
+#define IEP2_DIL_MODE_I5O1B		3
+#define IEP2_DIL_MODE_I2O2		4
+#define IEP2_DIL_MODE_I1O1T		5
+#define IEP2_DIL_MODE_I1O1B		6
+#define IEP2_DIL_MODE_PD		7
+#define IEP2_DIL_MODE_BYPASS		8
+#define IEP2_DIL_MODE_DECT		9
+
+#define IEP2_TIMEOUT_CFG		0x0050
+#define   IEP2_TIMEOUT_CFG_EN		BIT(31)
+#define   IEP2_TIMEOUT_CFG_MAX		GENMASK(25, 0)
+
+#define IEP2_DBG_FRM_CNT		0x0058
+#define IEP2_DBG_TIMEOUT_CNT		0x005c
+
+#define IEP2_SRC_ADDR_CURY		0x0060
+#define IEP2_SRC_ADDR_NXTY		0x0064
+#define IEP2_SRC_ADDR_PREY		0x0068
+#define IEP2_SRC_ADDR_CURUV		0x006c
+#define IEP2_SRC_ADDR_CURV		0x0070
+#define IEP2_SRC_ADDR_NXTUV		0x0074
+#define IEP2_SRC_ADDR_NXTV		0x0078
+#define IEP2_SRC_ADDR_PREUV		0x007c
+#define IEP2_SRC_ADDR_PREV		0x0080
+#define IEP2_SRC_ADDR_MD		0x0084
+#define IEP2_SRC_ADDR_MV		0x0088
+#define IEP2_ROI_ADDR			0x008c
+#define IEP2_DST_ADDR_TOPY		0x00b0
+#define IEP2_DST_ADDR_BOTY		0x00b4
+#define IEP2_DST_ADDR_TOPC		0x00b8
+#define IEP2_DST_ADDR_BOTC		0x00bc
+#define IEP2_DST_ADDR_MD		0x00c0
+#define IEP2_DST_ADDR_MV		0x00c4
+
+#define IEP2_MD_CONFIG0			0x00e0
+#define   IEP2_MD_THETA(x)		(((x) & 3) << 8)
+#define   IEP2_MD_R(x)			(((x) & 0xf) << 4)
+#define   IEP2_MD_LAMBDA(x)		((x) & 0xf)
+
+#define IEP2_DECT_CONFIG0		0x00e4
+#define   IEP2_OSD_GRADV_THR(x)		(((x) & 0xff) << 24)
+#define   IEP2_OSD_GRADH_THR(x)		(((x) & 0xff) << 16)
+#define   IEP2_OSD_AREA_NUM(x)		(((x) & 0xf) << 8)
+#define   IEP2_DECT_RESI_THR(x)		((x) & 0xff)
+
+#define IEP2_OSD_LIMIT_CONFIG		0x00f0
+#define   IEP2_OSD_POS_LIMIT_NUM(x)	(((x) & 7) << 4)
+#define   IEP2_OSD_POS_LIMIT_EN		BIT(0)
+#define IEP2_OSD_LIMIT_AREA(i)		(0x00f4 + ((i) * 4))
+
+#define IEP2_OSD_CONFIG0		0x00fc
+#define   IEP2_OSD_LINE_NUM(x)		(((x) & 0x1ff) << 16)
+#define   IEP2_OSD_PEC_THR(x)		((x) & 0x7ff)
+
+#define IEP2_OSD_AREA_CONF(i)		(0x0100 + ((i) * 4))
+#define IEP2_OSD_AREA_NUM_MAX		8
+
+#define IEP2_ME_CONFIG0			0x0120
+#define   IEP2_ME_THR_OFFSET(x)		(((x) & 0xff) << 16)
+#define   IEP2_MV_SIMILAR_NUM_THR0(x)	(((x) & 0xf) << 12)
+#define   IEP2_MV_SIMILAR_THR(x)	(((x) & 0xf) << 8)
+#define   IEP2_MV_BONUS(x)		(((x) & 0xf) << 4)
+#define   IEP2_ME_PENA(x)		((x) & 0xf)
+
+#define IEP2_ME_LIMIT_CONFIG		0x0124
+#define   IEP2_MV_RIGHT_LIMIT(x)	(((x) & 0x3f) << 8)
+#define   IEP2_MV_LEFT_LIMIT(x)		((x) & 0x3f)
+
+#define IEP2_MV_TRU_LIST(i)		(0x0128 + ((i) * 4))
+#define IEP2_MV_TRU_LIST_NUM		2
+
+#define IEP2_EEDI_CONFIG0		0x0130
+#define   IEP2_EEDI_THR0(x)		((x) & 0x1f)
+
+#define IEP2_BLE_CONFIG0		0x0134
+#define   IEP2_BLE_BACKTOMA_NUM(x)	((x) & 7)
+
+#define IEP2_COMB_CONFIG0		0x0138
+#define   IEP2_COMB_CNT_THR(x)		(((x) & 0xf) << 24)
+#define   IEP2_COMB_FEATURE_THR(x)	(((x) & 0x3f) << 16)
+#define   IEP2_COMB_T_THR(x)		(((x) & 0xff) << 8)
+#define   IEP2_COMB_OSD_VLD(x)		((x) & 0xff)
+
+#define IEP2_DIL_MTN_TAB(i)		(0x0140 + ((i) * 4))
+#define IEP2_DIL_MTN_TAB_NUM		16
+
+#define IEP2_RO_PD_TCNT			0x0400
+#define IEP2_RO_PD_BCNT			0x0404
+#define IEP2_RO_FF_CUR_TCNT		0x0408
+#define IEP2_RO_FF_CUR_BCNT		0x040c
+#define IEP2_RO_FF_NXT_TCNT		0x0410
+#define IEP2_RO_FF_NXT_BCNT		0x0414
+#define IEP2_RO_FF_BLE_TCNT		0x0418
+#define IEP2_RO_FF_BLE_BCNT		0x041c
+#define IEP2_RO_FF_COMB_NZ		0x0420
+#define IEP2_RO_FF_COMB_F		0x0424
+#define IEP2_RO_OSD_NUM			0x0428
+#define IEP2_RO_COMB_CNT		0x042c
+#define IEP2_RO_FF_GRADT_TCNT		0x0430
+#define IEP2_RO_FF_GRADT_BCNT		0x0434
+#define IEP2_RO_OSD_AREA_X(i)		(0x0440 + ((i) * 8))
+#define IEP2_RO_OSD_AREA_Y(i)		(0x0444 + ((i) * 8))
+#define IEP2_RO_MV_HIST_BIN(i)		(0x0480 + ((i) * 4))
+
+#endif /* __ROCKCHIP_IEP2_REGS_H__ */
diff --git a/drivers/media/platform/rockchip/iep2/iep2.c b/drivers/media/platform/rockchip/iep2/iep2.c
new file mode 100644
index 000000000000..26f5fec02b67
--- /dev/null
+++ b/drivers/media/platform/rockchip/iep2/iep2.c
@@ -0,0 +1,1275 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Rockchip IEP2 deinterlacer
+ *
+ * Based on the Rockchip BSP mpp_iep2.c (GPL-2.0+ OR MIT),
+ * Copyright (c) 2020 Rockchip Electronics Co., Ltd.,
+ * Ding Wei <leo.ding@rock-chips.com>, Alpha Lin <alpha.lin@rock-chips.com>
+ */
+
+#include <linux/delay.h>
+#include <linux/dma-mapping.h>
+#include <linux/interrupt.h>
+#include <linux/iommu.h>
+#include <linux/iopoll.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/pm_runtime.h>
+
+#include <media/v4l2-common.h>
+#include <media/v4l2-event.h>
+#include <media/v4l2-ioctl.h>
+#include <media/videobuf2-dma-contig.h>
+
+#include "iep2.h"
+#include "iep2-regs.h"
+
+#define IEP_WATCHDOG_MS		500
+#define IEP_AUTOSUSPEND_MS	100
+
+#define IEP_IRQ_IOMMU_FAULT	BIT(31)
+#define IEP_MAX_FOREIGN_IRQS	4
+
+static const struct iep_fmt iep_formats[] = {
+	{
+		.fourcc = V4L2_PIX_FMT_NV12,
+		.hw_fmt = IEP2_FMT_YUV420,
+		.hw_swap = IEP2_YUV_SWAP_SP_UV,
+		.vdiv = 2,
+	}, {
+		.fourcc = V4L2_PIX_FMT_NV21,
+		.hw_fmt = IEP2_FMT_YUV420,
+		.hw_swap = IEP2_YUV_SWAP_SP_VU,
+		.vdiv = 2,
+	}, {
+		.fourcc = V4L2_PIX_FMT_NV16,
+		.hw_fmt = IEP2_FMT_YUV422,
+		.hw_swap = IEP2_YUV_SWAP_SP_UV,
+		.vdiv = 1,
+	}, {
+		.fourcc = V4L2_PIX_FMT_NV61,
+		.hw_fmt = IEP2_FMT_YUV422,
+		.hw_swap = IEP2_YUV_SWAP_SP_VU,
+		.vdiv = 1,
+	},
+};
+
+static const u32 iep_mtn_tab[IEP2_DIL_MTN_TAB_NUM] = {
+	0x00000000, 0x00000000, 0x00000000, 0x00000000,
+	0x01010000, 0x06050302, 0x0f0d0a08, 0x1c191512,
+	0x2b282420, 0x3634312e, 0x3d3c3a38, 0x40403f3e,
+	0x40404040, 0x40404040, 0x40404040, 0x40404040,
+};
+
+static inline void iep_write(struct iep_dev *iep, u32 reg, u32 val)
+{
+	writel_relaxed(val, iep->regs + reg);
+}
+
+static inline u32 iep_read(struct iep_dev *iep, u32 reg)
+{
+	return readl_relaxed(iep->regs + reg);
+}
+
+static inline struct iep_ctx *file_to_iep_ctx(struct file *file)
+{
+	return container_of(file_to_v4l2_fh(file), struct iep_ctx, fh);
+}
+
+static const struct iep_fmt *iep_find_fmt(u32 fourcc)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(iep_formats); i++)
+		if (iep_formats[i].fourcc == fourcc)
+			return &iep_formats[i];
+
+	return NULL;
+}
+
+static enum v4l2_field iep_buf_field(struct iep_ctx *ctx,
+				     struct vb2_v4l2_buffer *vbuf)
+{
+	enum v4l2_field field = vbuf->field;
+
+	if (field == V4L2_FIELD_ANY)
+		field = ctx->src_fmt.field;
+	/* No video standard: bottom field first below 576 lines, as rcar_fdp1 */
+	if (field == V4L2_FIELD_INTERLACED)
+		field = ctx->src_fmt.height < 576 ? V4L2_FIELD_INTERLACED_BT :
+						    V4L2_FIELD_INTERLACED_TB;
+
+	return field;
+}
+
+static void iep_iommu_restore(struct iep_dev *iep)
+{
+	/* A reset leaves the IOMMU in bypass; reattaching reprograms it */
+	if (iep->empty_domain) {
+		iommu_attach_device(iep->empty_domain, iep->dev);
+		iommu_detach_device(iep->empty_domain, iep->dev);
+	}
+}
+
+static void iep_reset(struct iep_dev *iep)
+{
+	u32 status;
+	int ret;
+
+	iep_write(iep, IEP2_CONFIG0, IEP2_ACLK_SRESET_P);
+	ret = readl_relaxed_poll_timeout(iep->regs + IEP2_STATUS, status,
+					 status & IEP2_ARST_FINISH_DONE, 0, 5);
+	if (ret) {
+		dev_warn(iep->dev, "soft reset timeout, using CRU reset\n");
+		if (iep->rstc) {
+			reset_control_assert(iep->rstc);
+			udelay(5);
+			reset_control_deassert(iep->rstc);
+		}
+	}
+
+	iep_iommu_restore(iep);
+}
+
+static void iep_set_src(struct iep_dev *iep, u32 y_reg, u32 uv_reg, u32 v_reg,
+			dma_addr_t addr, u32 luma_size)
+{
+	iep_write(iep, y_reg, addr);
+	iep_write(iep, uv_reg, addr + luma_size);
+	iep_write(iep, v_reg, 0);
+}
+
+static void iep_hw_config(struct iep_ctx *ctx, u32 mode, u32 field_order,
+			  dma_addr_t prv, dma_addr_t cur, dma_addr_t nxt,
+			  dma_addr_t dst_top, dma_addr_t dst_bot)
+{
+	struct iep_dev *iep = ctx->iep;
+	const struct iep_fmt *fmt = ctx->fmt;
+	u32 width = ctx->src_fmt.width;
+	u32 height = ctx->src_fmt.height;
+	u32 src_stride = ctx->src_fmt.plane_fmt[0].bytesperline;
+	u32 dst_stride = ctx->dst_fmt.plane_fmt[0].bytesperline;
+	u32 src_luma = src_stride * height;
+	u32 dst_luma = dst_stride * height;
+	u32 tiles_x = DIV_ROUND_UP(width, IEP_TILE_W);
+	u32 tiles_y = DIV_ROUND_UP(height, IEP_TILE_H);
+	u32 md_lambda = 4;
+	unsigned int i;
+	u32 reg;
+
+	iep_write(iep, IEP2_CONFIG0,
+		  IEP2_SRC_FMT(fmt->hw_fmt) | IEP2_SRC_YUV_SWAP(fmt->hw_swap) |
+		  IEP2_DST_FMT(fmt->hw_fmt) | IEP2_DST_YUV_SWAP(fmt->hw_swap) |
+		  IEP2_DEBUG_DATA_EN);
+	iep_write(iep, IEP2_WORK_MODE, IEP2_WORK_MODE_IEP2);
+
+	iep_write(iep, IEP2_SRC_IMG_SIZE,
+		  IEP2_SRC_PIC_WIDTH(tiles_x * IEP_TILE_W - 1) |
+		  IEP2_SRC_PIC_HEIGHT(tiles_y * IEP_TILE_H - 1));
+	iep_write(iep, IEP2_VIR_SRC_IMG_WIDTH,
+		  IEP2_SRC_VIR_Y_STRIDE(src_stride / 4) |
+		  IEP2_SRC_VIR_UV_STRIDE(src_stride / 4));
+	iep_write(iep, IEP2_VIR_DST_IMG_WIDTH,
+		  IEP2_DST_VIR_STRIDE(dst_stride / 4));
+
+	reg = IEP2_DIL_MV_HIST_EN | IEP2_DIL_COMB_EN | IEP2_DIL_BLE_EN |
+	      IEP2_DIL_EEDI_EN | IEP2_DIL_MEMC_EN | IEP2_DIL_OSD_EN |
+	      IEP2_DIL_PD_EN | IEP2_DIL_FF_EN |
+	      IEP2_DIL_FIELD_ORDER(field_order) |
+	      IEP2_DIL_OUT_MODE(IEP2_DIL_OUT_MODE_LINE) |
+	      IEP2_DIL_MODE(mode);
+	if (md_lambda < 8)
+		reg |= IEP2_DIL_MD_PRE_EN;
+	iep_write(iep, IEP2_DIL_CONFIG0, reg);
+
+	iep_set_src(iep, IEP2_SRC_ADDR_CURY, IEP2_SRC_ADDR_CURUV,
+		    IEP2_SRC_ADDR_CURV, cur, src_luma);
+	iep_set_src(iep, IEP2_SRC_ADDR_NXTY, IEP2_SRC_ADDR_NXTUV,
+		    IEP2_SRC_ADDR_NXTV, nxt, src_luma);
+	iep_set_src(iep, IEP2_SRC_ADDR_PREY, IEP2_SRC_ADDR_PREUV,
+		    IEP2_SRC_ADDR_PREV, prv, src_luma);
+
+	iep_write(iep, IEP2_TIMEOUT_CFG,
+		  IEP2_TIMEOUT_CFG_EN | IEP2_TIMEOUT_CFG_MAX);
+
+	iep_write(iep, IEP2_SRC_ADDR_MD, ctx->md_dma);
+	iep_write(iep, IEP2_SRC_ADDR_MV, ctx->mv_dma);
+	iep_write(iep, IEP2_DST_ADDR_MD, ctx->md_dma);
+	iep_write(iep, IEP2_DST_ADDR_MV, ctx->mv_dma);
+	iep_write(iep, IEP2_ROI_ADDR, iep->roi_dma);
+
+	iep_write(iep, IEP2_DST_ADDR_TOPY, dst_top);
+	iep_write(iep, IEP2_DST_ADDR_TOPC, dst_top + dst_luma);
+	iep_write(iep, IEP2_DST_ADDR_BOTY, dst_bot);
+	iep_write(iep, IEP2_DST_ADDR_BOTC, dst_bot + dst_luma);
+
+	iep_write(iep, IEP2_MD_CONFIG0,
+		  IEP2_MD_THETA(1) | IEP2_MD_R(6) | IEP2_MD_LAMBDA(md_lambda));
+	iep_write(iep, IEP2_DECT_CONFIG0,
+		  IEP2_DECT_RESI_THR(30) | IEP2_OSD_AREA_NUM(0) |
+		  IEP2_OSD_GRADH_THR(60) | IEP2_OSD_GRADV_THR(60));
+	iep_write(iep, IEP2_OSD_LIMIT_CONFIG, 0);
+	iep_write(iep, IEP2_OSD_LIMIT_AREA(0), 0);
+	iep_write(iep, IEP2_OSD_LIMIT_AREA(1), 0);
+	iep_write(iep, IEP2_OSD_CONFIG0,
+		  IEP2_OSD_PEC_THR((width * 26) >> 7) | IEP2_OSD_LINE_NUM(2));
+	iep_write(iep, IEP2_ME_CONFIG0,
+		  IEP2_ME_PENA(5) | IEP2_MV_BONUS(10) |
+		  IEP2_MV_SIMILAR_THR(4) | IEP2_MV_SIMILAR_NUM_THR0(4) |
+		  IEP2_ME_THR_OFFSET(20));
+	iep_write(iep, IEP2_ME_LIMIT_CONFIG,
+		  IEP2_MV_LEFT_LIMIT(-28) | IEP2_MV_RIGHT_LIMIT(27));
+	iep_write(iep, IEP2_EEDI_CONFIG0, IEP2_EEDI_THR0(12));
+	iep_write(iep, IEP2_BLE_CONFIG0, IEP2_BLE_BACKTOMA_NUM(1));
+
+	for (i = 0; i < IEP2_OSD_AREA_NUM_MAX; i++)
+		iep_write(iep, IEP2_OSD_AREA_CONF(i), 0);
+
+	for (i = 0; i < IEP2_DIL_MTN_TAB_NUM; i++)
+		iep_write(iep, IEP2_DIL_MTN_TAB(i), iep_mtn_tab[i]);
+
+	for (i = 0; i < IEP2_MV_TRU_LIST_NUM; i++)
+		iep_write(iep, IEP2_MV_TRU_LIST(i), 0);
+
+	iep_write(iep, IEP2_COMB_CONFIG0,
+		  IEP2_COMB_OSD_VLD(0xff) | IEP2_COMB_T_THR(4) |
+		  IEP2_COMB_FEATURE_THR(16) | IEP2_COMB_CNT_THR(0));
+
+	iep_write(iep, IEP2_INT_EN,
+		  IEP2_INT_FRM_DONE | IEP2_INT_OSD_MAX |
+		  IEP2_INT_BUS_ERROR | IEP2_INT_TIMEOUT);
+}
+
+static void iep_job_done(struct iep_ctx *ctx, enum vb2_buffer_state state)
+{
+	struct iep_dev *iep = ctx->iep;
+	struct vb2_v4l2_buffer *src = ctx->job_src;
+	unsigned int i;
+
+	for (i = 0; i < ctx->job_ndst; i++) {
+		v4l2_m2m_buf_done(ctx->job_dst[i], state);
+		ctx->job_dst[i] = NULL;
+	}
+	ctx->job_ndst = 0;
+	ctx->job_src = NULL;
+
+	if (ctx->prev) {
+		v4l2_m2m_buf_done(ctx->prev, VB2_BUF_STATE_DONE);
+		ctx->prev = NULL;
+	}
+
+	if (src) {
+		if (ctx->job_keep_src && state == VB2_BUF_STATE_DONE)
+			ctx->prev = src;
+		else
+			v4l2_m2m_buf_done(src, state);
+	}
+	ctx->job_keep_src = false;
+
+	pm_runtime_put_autosuspend(iep->dev);
+	v4l2_m2m_job_finish(iep->m2m_dev, ctx->fh.m2m_ctx);
+}
+
+static void iep_fail_job(struct iep_ctx *ctx)
+{
+	struct vb2_v4l2_buffer *src, *dst;
+
+	src = v4l2_m2m_src_buf_remove(ctx->fh.m2m_ctx);
+	dst = v4l2_m2m_dst_buf_remove(ctx->fh.m2m_ctx);
+	if (src)
+		v4l2_m2m_buf_done(src, VB2_BUF_STATE_ERROR);
+	if (dst)
+		v4l2_m2m_buf_done(dst, VB2_BUF_STATE_ERROR);
+	v4l2_m2m_job_finish(ctx->iep->m2m_dev, ctx->fh.m2m_ctx);
+}
+
+static void iep_set_dst_meta(struct iep_ctx *ctx, struct vb2_v4l2_buffer *src,
+			     struct vb2_v4l2_buffer *dst)
+{
+	v4l2_m2m_buf_copy_metadata(src, dst);
+	dst->field = V4L2_FIELD_NONE;
+	dst->sequence = ctx->cap_sequence++;
+	vb2_set_plane_payload(&dst->vb2_buf, 0,
+			      ctx->dst_fmt.plane_fmt[0].sizeimage);
+}
+
+static void iep_device_run(void *priv)
+{
+	struct iep_ctx *ctx = priv;
+	struct iep_dev *iep = ctx->iep;
+	struct vb2_v4l2_buffer *src, *dst0, *dst1 = NULL;
+	dma_addr_t src_addr, prv_addr, dst_top, dst_bot;
+	enum v4l2_field field;
+	bool motion_adaptive = READ_ONCE(ctx->motion_adaptive);
+	bool field_rate = READ_ONCE(ctx->field_rate);
+	bool bff, first_frame;
+	unsigned long flags;
+	u32 mode;
+	int ret;
+
+	ret = pm_runtime_resume_and_get(iep->dev);
+	if (ret < 0) {
+		dev_err(iep->dev, "failed to resume: %d\n", ret);
+		iep_fail_job(ctx);
+		return;
+	}
+
+	if (field_rate && v4l2_m2m_num_dst_bufs_ready(ctx->fh.m2m_ctx) < 2)
+		field_rate = false;
+
+	src = v4l2_m2m_src_buf_remove(ctx->fh.m2m_ctx);
+	dst0 = v4l2_m2m_dst_buf_remove(ctx->fh.m2m_ctx);
+	field = iep_buf_field(ctx, src);
+	bff = field == V4L2_FIELD_INTERLACED_BT;
+	first_frame = !ctx->prev;
+
+	src->sequence = ctx->out_sequence++;
+	src_addr = vb2_dma_contig_plane_dma_addr(&src->vb2_buf, 0);
+	prv_addr = ctx->prev ?
+		   vb2_dma_contig_plane_dma_addr(&ctx->prev->vb2_buf, 0) :
+		   src_addr;
+
+	if (field == V4L2_FIELD_NONE) {
+		mode = IEP2_DIL_MODE_BYPASS;
+		field_rate = false;
+	} else if (!motion_adaptive || first_frame) {
+		if (field_rate)
+			mode = IEP2_DIL_MODE_I2O2;
+		else
+			mode = bff ? IEP2_DIL_MODE_I1O1B : IEP2_DIL_MODE_I1O1T;
+	} else {
+		if (field_rate)
+			mode = IEP2_DIL_MODE_I5O2;
+		else
+			mode = bff ? IEP2_DIL_MODE_I5O1B : IEP2_DIL_MODE_I5O1T;
+	}
+
+	ctx->job_src = src;
+	ctx->job_dst[0] = dst0;
+	ctx->job_ndst = 1;
+	ctx->job_keep_src = field != V4L2_FIELD_NONE && motion_adaptive;
+
+	if (field_rate) {
+		dst1 = v4l2_m2m_dst_buf_remove(ctx->fh.m2m_ctx);
+		ctx->job_dst[1] = dst1;
+		ctx->job_ndst = 2;
+	}
+
+	iep_set_dst_meta(ctx, src, dst0);
+	if (dst1)
+		iep_set_dst_meta(ctx, src, dst1);
+
+	dst_top = vb2_dma_contig_plane_dma_addr(&dst0->vb2_buf, 0);
+	dst_bot = dst_top;
+	if (dst1) {
+		if (bff)
+			dst_top = vb2_dma_contig_plane_dma_addr(&dst1->vb2_buf, 0);
+		else
+			dst_bot = vb2_dma_contig_plane_dma_addr(&dst1->vb2_buf, 0);
+	}
+
+	/* No look-ahead: the current frame is also the next one */
+	dev_dbg(iep->dev,
+		"mode %u order %u src %pad prv %pad dst %pad %pad\n", mode, bff,
+		&src_addr, &prv_addr, &dst_top, &dst_bot);
+
+	iep_hw_config(ctx, mode,
+		      bff ? IEP2_DIL_FIELD_ORDER_BT : IEP2_DIL_FIELD_ORDER_TB,
+		      prv_addr, src_addr, src_addr, dst_top, dst_bot);
+
+	spin_lock_irqsave(&iep->irq_lock, flags);
+	iep->busy = true;
+	iep->irq_status = 0;
+	iep->foreign_irqs = 0;
+	spin_unlock_irqrestore(&iep->irq_lock, flags);
+
+	schedule_delayed_work(&iep->watchdog_work,
+			      msecs_to_jiffies(IEP_WATCHDOG_MS));
+
+	writel(IEP2_FRM_EN, iep->regs + IEP2_FRM_START);
+}
+
+static int iep_job_ready(void *priv)
+{
+	struct iep_ctx *ctx = priv;
+	unsigned int ndst = READ_ONCE(ctx->field_rate) ? 2 : 1;
+
+	return v4l2_m2m_num_src_bufs_ready(ctx->fh.m2m_ctx) >= 1 &&
+	       v4l2_m2m_num_dst_bufs_ready(ctx->fh.m2m_ctx) >= ndst;
+}
+
+static const struct v4l2_m2m_ops iep_m2m_ops = {
+	.device_run = iep_device_run,
+	.job_ready = iep_job_ready,
+};
+
+static irqreturn_t iep_irq(int irq, void *data)
+{
+	struct iep_dev *iep = data;
+	irqreturn_t ret = IRQ_NONE;
+	u32 status;
+
+	/* Shared with the IOMMU: registers are only accessible during a job */
+	spin_lock(&iep->irq_lock);
+	if (!iep->busy)
+		goto out;
+
+	status = iep_read(iep, IEP2_INT_STS);
+	if (!status) {
+		/* IOMMU fault: the IEP would retry the read forever */
+		if (++iep->foreign_irqs < IEP_MAX_FOREIGN_IRQS)
+			goto out;
+
+		iep_write(iep, IEP2_INT_EN, 0);
+		iep_write(iep, IEP2_CONFIG0, IEP2_ACLK_SRESET_P);
+		iep->busy = false;
+		iep->irq_status = IEP_IRQ_IOMMU_FAULT;
+		ret = IRQ_WAKE_THREAD;
+		goto out;
+	}
+
+	iep_write(iep, IEP2_INT_CLR, 0xffffffff);
+	ret = IRQ_HANDLED;
+
+	if (status & IEP2_INT_VALID) {
+		iep->busy = false;
+		iep->irq_status = status;
+		ret = IRQ_WAKE_THREAD;
+	}
+out:
+	spin_unlock(&iep->irq_lock);
+
+	return ret;
+}
+
+static irqreturn_t iep_irq_thread(int irq, void *data)
+{
+	struct iep_dev *iep = data;
+	enum vb2_buffer_state state = VB2_BUF_STATE_DONE;
+	struct iep_ctx *ctx;
+	u32 status;
+
+	/* A watchdog that tests busy after the next job started would fail it */
+	cancel_delayed_work_sync(&iep->watchdog_work);
+
+	spin_lock_irq(&iep->irq_lock);
+	status = iep->irq_status;
+	spin_unlock_irq(&iep->irq_lock);
+
+	ctx = v4l2_m2m_get_curr_priv(iep->m2m_dev);
+	if (WARN_ON(!ctx))
+		return IRQ_HANDLED;
+
+	if (status & (IEP2_INT_BUS_ERROR | IEP2_INT_TIMEOUT |
+		      IEP_IRQ_IOMMU_FAULT)) {
+		dev_err_ratelimited(iep->dev, "job failed, status %#x\n",
+				    status);
+		iep_reset(iep);
+		state = VB2_BUF_STATE_ERROR;
+	}
+
+	iep_job_done(ctx, state);
+
+	return IRQ_HANDLED;
+}
+
+static void iep_watchdog(struct work_struct *work)
+{
+	struct iep_dev *iep = container_of(to_delayed_work(work),
+					   struct iep_dev, watchdog_work);
+	struct iep_ctx *ctx;
+	bool timeout;
+
+	/* Mask first: a late completion must not hold the shared line */
+	spin_lock_irq(&iep->irq_lock);
+	timeout = iep->busy;
+	if (timeout) {
+		iep_write(iep, IEP2_INT_EN, 0);
+		iep_write(iep, IEP2_INT_CLR, 0xffffffff);
+		iep->busy = false;
+	}
+	spin_unlock_irq(&iep->irq_lock);
+
+	if (!timeout)
+		return;
+
+	ctx = v4l2_m2m_get_curr_priv(iep->m2m_dev);
+	if (WARN_ON(!ctx))
+		return;
+
+	dev_err(iep->dev, "frame processing timed out\n");
+	iep_reset(iep);
+	iep_job_done(ctx, VB2_BUF_STATE_ERROR);
+}
+
+static int iep_queue_setup(struct vb2_queue *vq, unsigned int *nbuffers,
+			   unsigned int *nplanes, unsigned int sizes[],
+			   struct device *alloc_devs[])
+{
+	struct iep_ctx *ctx = vb2_get_drv_priv(vq);
+	struct v4l2_pix_format_mplane *pix;
+
+	pix = V4L2_TYPE_IS_OUTPUT(vq->type) ? &ctx->src_fmt : &ctx->dst_fmt;
+
+	if (*nplanes)
+		return (*nplanes != 1 ||
+			sizes[0] < pix->plane_fmt[0].sizeimage) ? -EINVAL : 0;
+
+	*nplanes = 1;
+	sizes[0] = pix->plane_fmt[0].sizeimage;
+
+	return 0;
+}
+
+static int iep_buf_out_validate(struct vb2_buffer *vb)
+{
+	struct vb2_v4l2_buffer *vbuf = to_vb2_v4l2_buffer(vb);
+	struct iep_ctx *ctx = vb2_get_drv_priv(vb->vb2_queue);
+
+	switch (vbuf->field) {
+	case V4L2_FIELD_ANY:
+		vbuf->field = ctx->src_fmt.field;
+		return 0;
+	case V4L2_FIELD_NONE:
+	case V4L2_FIELD_INTERLACED:
+	case V4L2_FIELD_INTERLACED_TB:
+	case V4L2_FIELD_INTERLACED_BT:
+		return 0;
+	default:
+		return -EINVAL;
+	}
+}
+
+static int iep_buf_prepare(struct vb2_buffer *vb)
+{
+	struct iep_ctx *ctx = vb2_get_drv_priv(vb->vb2_queue);
+	struct v4l2_pix_format_mplane *pix;
+
+	pix = V4L2_TYPE_IS_OUTPUT(vb->vb2_queue->type) ?
+	      &ctx->src_fmt : &ctx->dst_fmt;
+
+	if (vb2_plane_size(vb, 0) < pix->plane_fmt[0].sizeimage)
+		return -EINVAL;
+
+	if (!V4L2_TYPE_IS_OUTPUT(vb->vb2_queue->type)) {
+		vb2_set_plane_payload(vb, 0, pix->plane_fmt[0].sizeimage);
+		return 0;
+	}
+
+	/* The tail padding is optional */
+	if (vb2_get_plane_payload(vb, 0) <
+	    pix->plane_fmt[0].sizeimage - IEP_SRC_TAIL) {
+		dev_dbg(ctx->iep->dev, "OUTPUT payload %lu too small\n",
+			vb2_get_plane_payload(vb, 0));
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+static void iep_buf_queue(struct vb2_buffer *vb)
+{
+	struct vb2_v4l2_buffer *vbuf = to_vb2_v4l2_buffer(vb);
+	struct iep_ctx *ctx = vb2_get_drv_priv(vb->vb2_queue);
+
+	v4l2_m2m_buf_queue(ctx->fh.m2m_ctx, vbuf);
+}
+
+static void iep_free_ctx_bufs(struct iep_ctx *ctx)
+{
+	struct device *dev = ctx->iep->dev;
+
+	if (ctx->md_cpu)
+		dma_free_coherent(dev, IEP_MD_BUF_SIZE, ctx->md_cpu,
+				  ctx->md_dma);
+	if (ctx->mv_cpu)
+		dma_free_coherent(dev, IEP_MV_BUF_SIZE, ctx->mv_cpu,
+				  ctx->mv_dma);
+	ctx->md_cpu = NULL;
+	ctx->mv_cpu = NULL;
+}
+
+static void iep_return_bufs(struct vb2_queue *vq, enum vb2_buffer_state state)
+{
+	struct iep_ctx *ctx = vb2_get_drv_priv(vq);
+	struct vb2_v4l2_buffer *vbuf;
+
+	for (;;) {
+		if (V4L2_TYPE_IS_OUTPUT(vq->type))
+			vbuf = v4l2_m2m_src_buf_remove(ctx->fh.m2m_ctx);
+		else
+			vbuf = v4l2_m2m_dst_buf_remove(ctx->fh.m2m_ctx);
+		if (!vbuf)
+			break;
+		v4l2_m2m_buf_done(vbuf, state);
+	}
+
+	if (V4L2_TYPE_IS_OUTPUT(vq->type) && ctx->prev) {
+		v4l2_m2m_buf_done(ctx->prev, state);
+		ctx->prev = NULL;
+	}
+}
+
+static int iep_start_streaming(struct vb2_queue *vq, unsigned int count)
+{
+	struct iep_ctx *ctx = vb2_get_drv_priv(vq);
+	struct device *dev = ctx->iep->dev;
+
+	if (!V4L2_TYPE_IS_OUTPUT(vq->type)) {
+		ctx->cap_sequence = 0;
+		return 0;
+	}
+
+	ctx->out_sequence = 0;
+
+	ctx->md_cpu = dma_alloc_coherent(dev, IEP_MD_BUF_SIZE, &ctx->md_dma,
+					 GFP_KERNEL);
+	ctx->mv_cpu = dma_alloc_coherent(dev, IEP_MV_BUF_SIZE, &ctx->mv_dma,
+					 GFP_KERNEL);
+	if (!ctx->md_cpu || !ctx->mv_cpu) {
+		iep_free_ctx_bufs(ctx);
+		iep_return_bufs(vq, VB2_BUF_STATE_QUEUED);
+		return -ENOMEM;
+	}
+
+	return 0;
+}
+
+static void iep_stop_streaming(struct vb2_queue *vq)
+{
+	struct iep_ctx *ctx = vb2_get_drv_priv(vq);
+
+	iep_return_bufs(vq, VB2_BUF_STATE_ERROR);
+
+	if (V4L2_TYPE_IS_OUTPUT(vq->type))
+		iep_free_ctx_bufs(ctx);
+}
+
+static const struct vb2_ops iep_qops = {
+	.queue_setup = iep_queue_setup,
+	.buf_out_validate = iep_buf_out_validate,
+	.buf_prepare = iep_buf_prepare,
+	.buf_queue = iep_buf_queue,
+	.start_streaming = iep_start_streaming,
+	.stop_streaming = iep_stop_streaming,
+};
+
+static int iep_queue_init(void *priv, struct vb2_queue *src_vq,
+			  struct vb2_queue *dst_vq)
+{
+	struct iep_ctx *ctx = priv;
+	int ret;
+
+	src_vq->type = V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE;
+	src_vq->io_modes = VB2_MMAP | VB2_DMABUF;
+	src_vq->drv_priv = ctx;
+	src_vq->buf_struct_size = sizeof(struct v4l2_m2m_buffer);
+	src_vq->ops = &iep_qops;
+	src_vq->mem_ops = &vb2_dma_contig_memops;
+	src_vq->timestamp_flags = V4L2_BUF_FLAG_TIMESTAMP_COPY;
+	src_vq->lock = &ctx->iep->mutex;
+	src_vq->dev = ctx->iep->dev;
+	/* Motion adaptive holds one OUTPUT buffer as reference */
+	src_vq->min_reqbufs_allocation = 2;
+
+	ret = vb2_queue_init(src_vq);
+	if (ret)
+		return ret;
+
+	dst_vq->type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
+	dst_vq->io_modes = VB2_MMAP | VB2_DMABUF;
+	dst_vq->drv_priv = ctx;
+	dst_vq->buf_struct_size = sizeof(struct v4l2_m2m_buffer);
+	dst_vq->ops = &iep_qops;
+	dst_vq->mem_ops = &vb2_dma_contig_memops;
+	dst_vq->timestamp_flags = V4L2_BUF_FLAG_TIMESTAMP_COPY;
+	dst_vq->lock = &ctx->iep->mutex;
+	dst_vq->dev = ctx->iep->dev;
+
+	return vb2_queue_init(dst_vq);
+}
+
+static void iep_fill_pix(struct v4l2_pix_format_mplane *pix,
+			 const struct iep_fmt *fmt, u32 tail)
+{
+	struct v4l2_plane_pix_format *plane = &pix->plane_fmt[0];
+	u32 width, height, bpl;
+
+	width = ALIGN(clamp(pix->width, IEP_MIN_WIDTH, IEP_MAX_WIDTH),
+		      IEP_TILE_W);
+	height = ALIGN(clamp(pix->height, IEP_MIN_HEIGHT, IEP_MAX_HEIGHT),
+		       IEP_TILE_H);
+
+	bpl = ALIGN(plane->bytesperline, IEP_STRIDE_ALIGN);
+	bpl = clamp_t(u32, bpl, width,
+		      ALIGN_DOWN(IEP_MAX_STRIDE, IEP_STRIDE_ALIGN));
+
+	pix->pixelformat = fmt->fourcc;
+	pix->width = width;
+	pix->height = height;
+	pix->num_planes = 1;
+	pix->flags = 0;
+	memset(pix->reserved, 0, sizeof(pix->reserved));
+
+	plane->bytesperline = bpl;
+	plane->sizeimage = bpl * height + bpl * height / fmt->vdiv + tail;
+	memset(plane->reserved, 0, sizeof(plane->reserved));
+}
+
+static int iep_querycap(struct file *file, void *priv,
+			struct v4l2_capability *cap)
+{
+	strscpy(cap->driver, IEP_NAME, sizeof(cap->driver));
+	strscpy(cap->card, "Rockchip IEP2 deinterlacer", sizeof(cap->card));
+
+	return 0;
+}
+
+static int iep_enum_fmt_vid_out(struct file *file, void *priv,
+				struct v4l2_fmtdesc *f)
+{
+	if (f->index >= ARRAY_SIZE(iep_formats))
+		return -EINVAL;
+
+	f->pixelformat = iep_formats[f->index].fourcc;
+
+	return 0;
+}
+
+static int iep_enum_fmt_vid_cap(struct file *file, void *priv,
+				struct v4l2_fmtdesc *f)
+{
+	struct iep_ctx *ctx = file_to_iep_ctx(file);
+
+	if (f->index)
+		return -EINVAL;
+
+	f->pixelformat = ctx->fmt->fourcc;
+
+	return 0;
+}
+
+static int iep_enum_framesizes(struct file *file, void *priv,
+			       struct v4l2_frmsizeenum *fsize)
+{
+	if (fsize->index || !iep_find_fmt(fsize->pixel_format))
+		return -EINVAL;
+
+	fsize->type = V4L2_FRMSIZE_TYPE_STEPWISE;
+	fsize->stepwise.min_width = IEP_MIN_WIDTH;
+	fsize->stepwise.max_width = IEP_MAX_WIDTH;
+	fsize->stepwise.step_width = IEP_TILE_W;
+	fsize->stepwise.min_height = IEP_MIN_HEIGHT;
+	fsize->stepwise.max_height = IEP_MAX_HEIGHT;
+	fsize->stepwise.step_height = IEP_TILE_H;
+
+	return 0;
+}
+
+static int iep_g_fmt_vid_out(struct file *file, void *priv,
+			     struct v4l2_format *f)
+{
+	f->fmt.pix_mp = file_to_iep_ctx(file)->src_fmt;
+
+	return 0;
+}
+
+static int iep_g_fmt_vid_cap(struct file *file, void *priv,
+			     struct v4l2_format *f)
+{
+	f->fmt.pix_mp = file_to_iep_ctx(file)->dst_fmt;
+
+	return 0;
+}
+
+static int iep_try_fmt_vid_out(struct file *file, void *priv,
+			       struct v4l2_format *f)
+{
+	struct v4l2_pix_format_mplane *pix = &f->fmt.pix_mp;
+	const struct iep_fmt *fmt;
+
+	fmt = iep_find_fmt(pix->pixelformat);
+	if (!fmt)
+		fmt = &iep_formats[0];
+
+	if (pix->field != V4L2_FIELD_INTERLACED_TB &&
+	    pix->field != V4L2_FIELD_INTERLACED_BT &&
+	    pix->field != V4L2_FIELD_INTERLACED &&
+	    pix->field != V4L2_FIELD_NONE)
+		pix->field = V4L2_FIELD_INTERLACED;
+
+	if (pix->colorspace == V4L2_COLORSPACE_DEFAULT) {
+		pix->colorspace = pix->height > 576 ? V4L2_COLORSPACE_REC709 :
+						      V4L2_COLORSPACE_SMPTE170M;
+		pix->xfer_func = V4L2_XFER_FUNC_DEFAULT;
+		pix->ycbcr_enc = V4L2_YCBCR_ENC_DEFAULT;
+		pix->quantization = V4L2_QUANTIZATION_DEFAULT;
+	}
+
+	iep_fill_pix(pix, fmt, IEP_SRC_TAIL);
+
+	return 0;
+}
+
+static int iep_try_fmt_vid_cap(struct file *file, void *priv,
+			       struct v4l2_format *f)
+{
+	struct iep_ctx *ctx = file_to_iep_ctx(file);
+	struct v4l2_pix_format_mplane *pix = &f->fmt.pix_mp;
+
+	pix->width = ctx->src_fmt.width;
+	pix->height = ctx->src_fmt.height;
+	pix->field = V4L2_FIELD_NONE;
+	pix->colorspace = ctx->src_fmt.colorspace;
+	pix->xfer_func = ctx->src_fmt.xfer_func;
+	pix->ycbcr_enc = ctx->src_fmt.ycbcr_enc;
+	pix->quantization = ctx->src_fmt.quantization;
+
+	iep_fill_pix(pix, ctx->fmt, 0);
+
+	return 0;
+}
+
+static int iep_s_fmt_vid_out(struct file *file, void *priv,
+			     struct v4l2_format *f)
+{
+	struct iep_ctx *ctx = file_to_iep_ctx(file);
+	struct v4l2_pix_format_mplane *dst = &ctx->dst_fmt;
+	struct vb2_queue *vq;
+	int ret;
+
+	vq = v4l2_m2m_get_vq(ctx->fh.m2m_ctx, f->type);
+	if (vb2_is_busy(vq))
+		return -EBUSY;
+
+	vq = v4l2_m2m_get_dst_vq(ctx->fh.m2m_ctx);
+	if (vb2_is_busy(vq))
+		return -EBUSY;
+
+	ret = iep_try_fmt_vid_out(file, priv, f);
+	if (ret)
+		return ret;
+
+	ctx->src_fmt = f->fmt.pix_mp;
+	ctx->fmt = iep_find_fmt(ctx->src_fmt.pixelformat);
+
+	dst->width = ctx->src_fmt.width;
+	dst->height = ctx->src_fmt.height;
+	dst->field = V4L2_FIELD_NONE;
+	dst->colorspace = ctx->src_fmt.colorspace;
+	dst->xfer_func = ctx->src_fmt.xfer_func;
+	dst->ycbcr_enc = ctx->src_fmt.ycbcr_enc;
+	dst->quantization = ctx->src_fmt.quantization;
+	dst->plane_fmt[0].bytesperline = 0;
+	iep_fill_pix(dst, ctx->fmt, 0);
+
+	return 0;
+}
+
+static int iep_s_fmt_vid_cap(struct file *file, void *priv,
+			     struct v4l2_format *f)
+{
+	struct iep_ctx *ctx = file_to_iep_ctx(file);
+	struct vb2_queue *vq;
+	int ret;
+
+	vq = v4l2_m2m_get_vq(ctx->fh.m2m_ctx, f->type);
+	if (vb2_is_busy(vq))
+		return -EBUSY;
+
+	ret = iep_try_fmt_vid_cap(file, priv, f);
+	if (ret)
+		return ret;
+
+	ctx->dst_fmt = f->fmt.pix_mp;
+
+	return 0;
+}
+
+static const struct v4l2_ioctl_ops iep_ioctl_ops = {
+	.vidioc_querycap = iep_querycap,
+	.vidioc_enum_framesizes = iep_enum_framesizes,
+
+	.vidioc_enum_fmt_vid_cap = iep_enum_fmt_vid_cap,
+	.vidioc_g_fmt_vid_cap_mplane = iep_g_fmt_vid_cap,
+	.vidioc_try_fmt_vid_cap_mplane = iep_try_fmt_vid_cap,
+	.vidioc_s_fmt_vid_cap_mplane = iep_s_fmt_vid_cap,
+
+	.vidioc_enum_fmt_vid_out = iep_enum_fmt_vid_out,
+	.vidioc_g_fmt_vid_out_mplane = iep_g_fmt_vid_out,
+	.vidioc_try_fmt_vid_out_mplane = iep_try_fmt_vid_out,
+	.vidioc_s_fmt_vid_out_mplane = iep_s_fmt_vid_out,
+
+	.vidioc_reqbufs = v4l2_m2m_ioctl_reqbufs,
+	.vidioc_querybuf = v4l2_m2m_ioctl_querybuf,
+	.vidioc_qbuf = v4l2_m2m_ioctl_qbuf,
+	.vidioc_dqbuf = v4l2_m2m_ioctl_dqbuf,
+	.vidioc_prepare_buf = v4l2_m2m_ioctl_prepare_buf,
+	.vidioc_create_bufs = v4l2_m2m_ioctl_create_bufs,
+	.vidioc_expbuf = v4l2_m2m_ioctl_expbuf,
+
+	.vidioc_streamon = v4l2_m2m_ioctl_streamon,
+	.vidioc_streamoff = v4l2_m2m_ioctl_streamoff,
+
+	.vidioc_subscribe_event = v4l2_ctrl_subscribe_event,
+	.vidioc_unsubscribe_event = v4l2_event_unsubscribe,
+};
+
+static int iep_s_ctrl(struct v4l2_ctrl *ctrl)
+{
+	struct iep_ctx *ctx = container_of(ctrl->handler, struct iep_ctx,
+					   ctrl_handler);
+	bool field_rate;
+
+	switch (ctrl->id) {
+	case V4L2_CID_DEINTERLACING_MODE:
+		field_rate = ctrl->val == IEP_DEINT_BOB_FIELD ||
+			     ctrl->val == IEP_DEINT_MA_FIELD;
+		/* The rate sets the CAPTURE buffers per job: fixed while streaming */
+		if (field_rate != ctx->field_rate && ctx->fh.m2m_ctx &&
+		    (vb2_is_streaming(v4l2_m2m_get_src_vq(ctx->fh.m2m_ctx)) ||
+		     vb2_is_streaming(v4l2_m2m_get_dst_vq(ctx->fh.m2m_ctx))))
+			return -EBUSY;
+		WRITE_ONCE(ctx->motion_adaptive,
+			   ctrl->val == IEP_DEINT_MA_FRAME ||
+			   ctrl->val == IEP_DEINT_MA_FIELD);
+		WRITE_ONCE(ctx->field_rate, field_rate);
+		return 0;
+	}
+
+	return -EINVAL;
+}
+
+static const struct v4l2_ctrl_ops iep_ctrl_ops = {
+	.s_ctrl = iep_s_ctrl,
+};
+
+static const char * const iep_deint_mode_menu[] = {
+	[IEP_DEINT_BOB_FRAME]	= "Bob, Frame Rate",
+	[IEP_DEINT_BOB_FIELD]	= "Bob, Field Rate",
+	[IEP_DEINT_MA_FRAME]	= "Motion Adaptive, Frame Rate",
+	[IEP_DEINT_MA_FIELD]	= "Motion Adaptive, Field Rate",
+	NULL,
+};
+
+static int iep_ctrls_init(struct iep_ctx *ctx)
+{
+	struct v4l2_ctrl_handler *hdl = &ctx->ctrl_handler;
+
+	v4l2_ctrl_handler_init(hdl, 1);
+	/* Without look-ahead, motion adaptive is not reliably better */
+	v4l2_ctrl_new_std_menu_items(hdl, &iep_ctrl_ops,
+				     V4L2_CID_DEINTERLACING_MODE,
+				     IEP_DEINT_MA_FIELD, 0, IEP_DEINT_BOB_FRAME,
+				     iep_deint_mode_menu);
+
+	if (hdl->error) {
+		int ret = hdl->error;
+
+		v4l2_ctrl_handler_free(hdl);
+		return ret;
+	}
+
+	ctx->fh.ctrl_handler = hdl;
+
+	return v4l2_ctrl_handler_setup(hdl);
+}
+
+static int iep_open(struct file *file)
+{
+	struct iep_dev *iep = video_drvdata(file);
+	struct iep_ctx *ctx;
+	int ret;
+
+	ctx = kzalloc_obj(*ctx);
+	if (!ctx)
+		return -ENOMEM;
+
+	ctx->iep = iep;
+	ctx->fmt = &iep_formats[0];
+
+	ctx->src_fmt.width = 720;
+	ctx->src_fmt.height = 576;
+	ctx->src_fmt.field = V4L2_FIELD_INTERLACED_TB;
+	ctx->src_fmt.colorspace = V4L2_COLORSPACE_SMPTE170M;
+	iep_fill_pix(&ctx->src_fmt, ctx->fmt, IEP_SRC_TAIL);
+
+	ctx->dst_fmt = ctx->src_fmt;
+	ctx->dst_fmt.field = V4L2_FIELD_NONE;
+	iep_fill_pix(&ctx->dst_fmt, ctx->fmt, 0);
+
+	v4l2_fh_init(&ctx->fh, video_devdata(file));
+
+	ret = iep_ctrls_init(ctx);
+	if (ret)
+		goto err_free_ctrls;
+
+	if (mutex_lock_interruptible(&iep->mutex)) {
+		ret = -ERESTARTSYS;
+		goto err_free_ctrls;
+	}
+	ctx->fh.m2m_ctx = v4l2_m2m_ctx_init(iep->m2m_dev, ctx,
+					    iep_queue_init);
+	mutex_unlock(&iep->mutex);
+	if (IS_ERR(ctx->fh.m2m_ctx)) {
+		ret = PTR_ERR(ctx->fh.m2m_ctx);
+		goto err_free_ctrls;
+	}
+
+	v4l2_fh_add(&ctx->fh, file);
+
+	return 0;
+
+err_free_ctrls:
+	v4l2_ctrl_handler_free(&ctx->ctrl_handler);
+	v4l2_fh_exit(&ctx->fh);
+	kfree(ctx);
+	return ret;
+}
+
+static int iep_release(struct file *file)
+{
+	struct iep_dev *iep = video_drvdata(file);
+	struct iep_ctx *ctx = file_to_iep_ctx(file);
+
+	mutex_lock(&iep->mutex);
+	v4l2_m2m_ctx_release(ctx->fh.m2m_ctx);
+	mutex_unlock(&iep->mutex);
+
+	v4l2_fh_del(&ctx->fh, file);
+	v4l2_fh_exit(&ctx->fh);
+	v4l2_ctrl_handler_free(&ctx->ctrl_handler);
+	kfree(ctx);
+
+	return 0;
+}
+
+static const struct v4l2_file_operations iep_fops = {
+	.owner = THIS_MODULE,
+	.open = iep_open,
+	.release = iep_release,
+	.poll = v4l2_m2m_fop_poll,
+	.unlocked_ioctl = video_ioctl2,
+	.mmap = v4l2_m2m_fop_mmap,
+};
+
+static const struct video_device iep_video_device = {
+	.name = IEP_NAME,
+	.vfl_dir = VFL_DIR_M2M,
+	.fops = &iep_fops,
+	.ioctl_ops = &iep_ioctl_ops,
+	.minor = -1,
+	.release = video_device_release_empty,
+	.device_caps = V4L2_CAP_VIDEO_M2M_MPLANE | V4L2_CAP_STREAMING,
+};
+
+static int iep_runtime_suspend(struct device *dev)
+{
+	struct iep_dev *iep = dev_get_drvdata(dev);
+
+	clk_bulk_disable_unprepare(iep->num_clks, iep->clks);
+
+	return 0;
+}
+
+static int iep_runtime_resume(struct device *dev)
+{
+	struct iep_dev *iep = dev_get_drvdata(dev);
+
+	return clk_bulk_prepare_enable(iep->num_clks, iep->clks);
+}
+
+/* Open files keep iep_dev alive after unbind, through v4l2_dev */
+static void iep_v4l2_release(struct v4l2_device *v4l2_dev)
+{
+	struct iep_dev *iep = container_of(v4l2_dev, struct iep_dev, v4l2_dev);
+
+	if (iep->m2m_dev)
+		v4l2_m2m_release(iep->m2m_dev);
+	v4l2_device_unregister(v4l2_dev);
+	mutex_destroy(&iep->mutex);
+	kfree(iep);
+}
+
+static void iep_put(void *data)
+{
+	struct iep_dev *iep = data;
+
+	v4l2_device_put(&iep->v4l2_dev);
+}
+
+static int iep_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct iep_dev *iep;
+	int irq, ret;
+
+	iep = kzalloc_obj(*iep);
+	if (!iep)
+		return -ENOMEM;
+
+	iep->dev = dev;
+	iep->vfd = iep_video_device;
+	mutex_init(&iep->mutex);
+	spin_lock_init(&iep->irq_lock);
+	INIT_DELAYED_WORK(&iep->watchdog_work, iep_watchdog);
+
+	ret = v4l2_device_register(dev, &iep->v4l2_dev);
+	if (ret) {
+		mutex_destroy(&iep->mutex);
+		kfree(iep);
+		return ret;
+	}
+	iep->v4l2_dev.release = iep_v4l2_release;
+
+	/* Put after the devm IRQ, which is requested later, is freed */
+	ret = devm_add_action_or_reset(dev, iep_put, iep);
+	if (ret)
+		return ret;
+
+	platform_set_drvdata(pdev, iep);
+
+	iep->regs = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(iep->regs))
+		return PTR_ERR(iep->regs);
+
+	iep->num_clks = devm_clk_bulk_get_all(dev, &iep->clks);
+	if (iep->num_clks < 0)
+		return dev_err_probe(dev, iep->num_clks,
+				     "failed to get clocks\n");
+
+	iep->rstc = devm_reset_control_array_get_optional_exclusive(dev);
+	if (IS_ERR(iep->rstc))
+		return dev_err_probe(dev, PTR_ERR(iep->rstc),
+				     "failed to get resets\n");
+
+	ret = dma_set_mask_and_coherent(dev, DMA_BIT_MASK(32));
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to set DMA mask\n");
+	vb2_dma_contig_set_max_seg_size(dev, DMA_BIT_MASK(32));
+
+	iep->roi_cpu = dmam_alloc_coherent(dev, IEP_ROI_BUF_SIZE,
+					   &iep->roi_dma, GFP_KERNEL);
+	if (!iep->roi_cpu)
+		return -ENOMEM;
+
+	irq = platform_get_irq(pdev, 0);
+	if (irq < 0)
+		return irq;
+
+	ret = devm_request_threaded_irq(dev, irq, iep_irq, iep_irq_thread,
+					IRQF_SHARED, dev_name(dev), iep);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to request IRQ\n");
+
+	if (iommu_get_domain_for_dev(dev)) {
+		iep->empty_domain = iommu_paging_domain_alloc(dev);
+		if (IS_ERR(iep->empty_domain)) {
+			dev_warn(dev, "cannot allocate empty IOMMU domain\n");
+			iep->empty_domain = NULL;
+		}
+	}
+
+	pm_runtime_set_autosuspend_delay(dev, IEP_AUTOSUSPEND_MS);
+	pm_runtime_use_autosuspend(dev);
+	pm_runtime_enable(dev);
+
+	iep->m2m_dev = v4l2_m2m_init(&iep_m2m_ops);
+	if (IS_ERR(iep->m2m_dev)) {
+		ret = PTR_ERR(iep->m2m_dev);
+		iep->m2m_dev = NULL;
+		v4l2_err(&iep->v4l2_dev, "failed to init mem2mem device\n");
+		goto err_pm;
+	}
+
+	iep->vfd.lock = &iep->mutex;
+	iep->vfd.v4l2_dev = &iep->v4l2_dev;
+	video_set_drvdata(&iep->vfd, iep);
+
+	ret = video_register_device(&iep->vfd, VFL_TYPE_VIDEO, -1);
+	if (ret) {
+		v4l2_err(&iep->v4l2_dev, "failed to register video device\n");
+		goto err_pm;
+	}
+
+	return 0;
+
+err_pm:
+	pm_runtime_dont_use_autosuspend(dev);
+	pm_runtime_disable(dev);
+	if (iep->empty_domain)
+		iommu_domain_free(iep->empty_domain);
+	return ret;
+}
+
+static void iep_remove(struct platform_device *pdev)
+{
+	struct iep_dev *iep = platform_get_drvdata(pdev);
+
+	v4l2_m2m_suspend(iep->m2m_dev);
+	video_unregister_device(&iep->vfd);
+	cancel_delayed_work_sync(&iep->watchdog_work);
+
+	/* Disabling runtime PM drops a pending autosuspend */
+	pm_runtime_dont_use_autosuspend(&pdev->dev);
+	pm_runtime_disable(&pdev->dev);
+	if (!pm_runtime_status_suspended(&pdev->dev))
+		iep_runtime_suspend(&pdev->dev);
+	pm_runtime_set_suspended(&pdev->dev);
+
+	if (iep->empty_domain)
+		iommu_domain_free(iep->empty_domain);
+	iep->empty_domain = NULL;
+}
+
+static int iep_suspend(struct device *dev)
+{
+	struct iep_dev *iep = dev_get_drvdata(dev);
+	int ret;
+
+	v4l2_m2m_suspend(iep->m2m_dev);
+
+	ret = pm_runtime_force_suspend(dev);
+	if (ret)
+		v4l2_m2m_resume(iep->m2m_dev);
+
+	return ret;
+}
+
+static int iep_resume(struct device *dev)
+{
+	struct iep_dev *iep = dev_get_drvdata(dev);
+	int ret;
+
+	ret = pm_runtime_force_resume(dev);
+	/* Even on error, so that queued jobs fail instead of hanging */
+	v4l2_m2m_resume(iep->m2m_dev);
+
+	return ret;
+}
+
+static const struct dev_pm_ops iep_pm_ops = {
+	SYSTEM_SLEEP_PM_OPS(iep_suspend, iep_resume)
+	RUNTIME_PM_OPS(iep_runtime_suspend, iep_runtime_resume, NULL)
+};
+
+static const struct of_device_id iep_of_match[] = {
+	{ .compatible = "rockchip,rk3568-iep2" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, iep_of_match);
+
+static struct platform_driver iep_driver = {
+	.probe = iep_probe,
+	.remove = iep_remove,
+	.driver = {
+		.name = IEP_NAME,
+		.of_match_table = iep_of_match,
+		.pm = pm_ptr(&iep_pm_ops),
+	},
+};
+module_platform_driver(iep_driver);
+
+MODULE_DESCRIPTION("Rockchip IEP2 deinterlacer driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/media/platform/rockchip/iep2/iep2.h b/drivers/media/platform/rockchip/iep2/iep2.h
new file mode 100644
index 000000000000..8650882387f0
--- /dev/null
+++ b/drivers/media/platform/rockchip/iep2/iep2.h
@@ -0,0 +1,106 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+
+#ifndef __ROCKCHIP_IEP2_H__
+#define __ROCKCHIP_IEP2_H__
+
+#include <linux/clk.h>
+#include <linux/mutex.h>
+#include <linux/reset.h>
+#include <linux/sizes.h>
+#include <linux/spinlock.h>
+#include <linux/workqueue.h>
+
+#include <media/v4l2-ctrls.h>
+#include <media/v4l2-device.h>
+#include <media/v4l2-fh.h>
+#include <media/v4l2-mem2mem.h>
+#include <media/videobuf2-v4l2.h>
+
+#define IEP_NAME		"rockchip-iep2"
+
+#define IEP_TILE_W		16
+#define IEP_TILE_H		4
+
+#define IEP_MIN_WIDTH		32U
+#define IEP_MAX_WIDTH		1920U
+#define IEP_MIN_HEIGHT		16U
+#define IEP_MAX_HEIGHT		1088U
+
+#define IEP_MAX_STRIDE		(0xffff * 4)
+#define IEP_STRIDE_ALIGN	16
+
+/* The IEP2 reads past the end of the OUTPUT buffer */
+#define IEP_SRC_TAIL		SZ_4K
+
+enum iep_deint_mode {
+	IEP_DEINT_BOB_FRAME,
+	IEP_DEINT_BOB_FIELD,
+	IEP_DEINT_MA_FRAME,
+	IEP_DEINT_MA_FIELD,
+};
+
+#define IEP_MD_BUF_SIZE		(IEP_MAX_WIDTH * IEP_MAX_HEIGHT)
+#define IEP_MV_BUF_SIZE		(120 * 480)
+#define IEP_ROI_BUF_SIZE	(120 * 272)
+
+struct iep_fmt {
+	u32 fourcc;
+	u8 hw_fmt;
+	u8 hw_swap;
+	u8 vdiv;
+};
+
+struct iep_dev {
+	struct v4l2_device v4l2_dev;
+	struct v4l2_m2m_dev *m2m_dev;
+	struct video_device vfd;
+	struct device *dev;
+	/* serialises ioctls and vb2 queue operations */
+	struct mutex mutex;
+
+	void __iomem *regs;
+	struct clk_bulk_data *clks;
+	int num_clks;
+	struct reset_control *rstc;
+	struct iommu_domain *empty_domain;
+
+	void *roi_cpu;
+	dma_addr_t roi_dma;
+
+	struct delayed_work watchdog_work;
+	/* protects busy and irq_status */
+	spinlock_t irq_lock;
+	bool busy;
+	u32 irq_status;
+	unsigned int foreign_irqs;
+};
+
+struct iep_ctx {
+	struct v4l2_fh fh;
+	struct iep_dev *iep;
+	struct v4l2_ctrl_handler ctrl_handler;
+
+	const struct iep_fmt *fmt;
+	struct v4l2_pix_format_mplane src_fmt;
+	struct v4l2_pix_format_mplane dst_fmt;
+
+	bool motion_adaptive;
+	bool field_rate;
+
+	void *md_cpu;
+	dma_addr_t md_dma;
+	void *mv_cpu;
+	dma_addr_t mv_dma;
+
+	struct vb2_v4l2_buffer *prev;
+
+	struct vb2_v4l2_buffer *job_src;
+	struct vb2_v4l2_buffer *job_dst[2];
+	unsigned int job_ndst;
+	bool job_keep_src;
+
+	u32 out_sequence;
+	u32 cap_sequence;
+};
+
+#endif /* __ROCKCHIP_IEP2_H__ */

-- 
2.55.0

