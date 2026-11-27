From: Jerome Berclaz <jerome.berclaz@proton.me>
Date: Thu, 26 Nov 2026 16:55:47 -0800
Subject: [PATCH 3/4] media: tegra-vde: clean only the used part of the
 bitstream buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-tegra-vde-fixes-v1-3-fa4a7c1d24cc@proton.me>
References: <20261126-tegra-vde-fixes-v1-0-fa4a7c1d24cc@proton.me>
In-Reply-To: <20261126-tegra-vde-fixes-v1-0-fa4a7c1d24cc@proton.me>
To: Dmitry Osipenko <digetx@gmail.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-media@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jerome Berclaz <jerome.berclaz@proton.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2968;
 i=jerome.berclaz@proton.me; s=2026-11; h=from:subject:message-id;
 bh=rI4bjGiLaIB/dHE/FaYnR9GQxHnftZtGARPOU0E1YCI=;
 b=owGbwMvMwCVmvC9341tRgSLG02pJDNkcV4V/Rd0O/F/wautk1ydMOXbaby9t+9PbE/Ihevr/T
 K6X/7fVdZSyMIhxMciKKbKwNhimzj/BFlCoP+8QzBxWJpAhDFycAjCR4COMDF1/1h5/8+aECuOb
 78x22a4MMbtlG1ZcMDqX9CaCf8l6g+uMDCcFrUsvGDDqO8Ttmuq1tGyjV5L8og7d3RtvKrucrxP
 4yg0A
X-Developer-Key: i=jerome.berclaz@proton.me; a=openpgp;
 fpr=058031659FC80650712F9EC233BE6DB1ED151072
X-Endpoint-Received: by B4 Relay for jerome.berclaz@proton.me/2026-11 with auth_id=1658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the decoder sits behind the SMMU, buffers use vb2_dma_sg_memops,
i.e. cached pages, and vb2 cleans the whole bitstream (OUTPUT) buffer
from the CPU caches on every QBUF. FFmpeg's V4L2 request decoder makes
these buffers width * height * 3 / 2 bytes, 1.4 MB at 720p, while a coded
frame is usually a few KB, so most of that work is wasted: it was the
largest remaining kernel cost of hardware H.264 playback on a Tegra30.

The hardware only reads the coded data and the zero padding that
tegra_buf_prepare() writes after it. Clean that range from
tegra_buf_prepare() and let vb2 skip its whole-buffer sync. OUTPUT
buffers are never synced for the CPU on DQBUF already (DMA_TO_DEVICE).

Signed-off-by: Jerome Berclaz <jerome.berclaz@proton.me>
---
 drivers/media/platform/nvidia/tegra-vde/v4l2.c | 33 ++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/drivers/media/platform/nvidia/tegra-vde/v4l2.c b/drivers/media/platform/nvidia/tegra-vde/v4l2.c
index cd25307ad9db..3269ca75593f 100644
--- a/drivers/media/platform/nvidia/tegra-vde/v4l2.c
+++ b/drivers/media/platform/nvidia/tegra-vde/v4l2.c
@@ -12,6 +12,7 @@
  * Copyright (C) 2019 Boris Brezillon <boris.brezillon@collabora.com>
  */
 
+#include <linux/dma-mapping.h>
 #include <linux/err.h>
 #include <linux/slab.h>
 
@@ -214,6 +215,30 @@ static void tegra_buf_cleanup(struct vb2_buffer *vb)
 	__tegra_buf_cleanup(vb, vb->num_planes);
 }
 
+/*
+ * With the SMMU the buffers are cached pages (vb2_dma_sg), and vb2 would
+ * clean the whole bitstream buffer on every QBUF, although the hardware
+ * only reads the coded data and its padding. Clean just that range.
+ */
+static void tegra_sync_coded_data(struct vb2_buffer *vb, unsigned int plane,
+				  size_t size)
+{
+	struct device *dev = vb->vb2_queue->dev;
+	struct sg_table *sgt = vb2_dma_sg_plane_desc(vb, plane);
+	struct scatterlist *sg;
+	unsigned int i;
+
+	for_each_sgtable_dma_sg(sgt, sg, i) {
+		size_t len = min_t(size_t, sg_dma_len(sg), size);
+
+		dma_sync_single_for_device(dev, sg_dma_address(sg), len,
+					   DMA_TO_DEVICE);
+		size -= len;
+		if (!size)
+			break;
+	}
+}
+
 static int tegra_buf_prepare(struct vb2_buffer *vb)
 {
 	struct vb2_queue *vq = vb->vb2_queue;
@@ -264,11 +289,19 @@ static int tegra_buf_prepare(struct vb2_buffer *vb)
 			if (vb_data)
 				memset(vb_data + offset + size, 0,
 				       hw_size - offset - size);
+
+			if (ctx->vde->domain && vb->memory == VB2_MEMORY_MMAP)
+				tegra_sync_coded_data(vb, i, hw_size);
 		}
 
 		tb->dma_addr[i] = tb->dma_base[i] + offset;
 	}
 
+	/* the range in use was synced above, skip vb2's whole-buffer sync */
+	if (V4L2_TYPE_IS_OUTPUT(vq->type) && ctx->vde->domain &&
+	    vb->memory == VB2_MEMORY_MMAP)
+		vb->skip_cache_sync_on_prepare = 1;
+
 	switch (pixfmt->pixelformat) {
 	case V4L2_PIX_FMT_YVU420M:
 		swap(tb->dma_addr[1], tb->dma_addr[2]);

-- 
2.53.0

