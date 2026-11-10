From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:17:58 +0000
Subject: [PATCH 3/6] media: verisilicon: Refuse JPEG encode jobs with
 inconsistent geometry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-jpeg-enc-fixes-v1-3-fc4dc7e985d2@gmail.com>
References: <20261110-hantro-jpeg-enc-fixes-v1-0-fc4dc7e985d2@gmail.com>
In-Reply-To: <20261110-hantro-jpeg-enc-fixes-v1-0-fc4dc7e985d2@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Boris Brezillon <boris.brezillon@collabora.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295075; l=5281;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=do5fff0E77HztRZ7LZ0DBdjmX88jN/xzYgE6TJmApXI=;
 b=5ecRMYzhG87W1R1GcnfpbIkRyjcO7mKyaawyBusIX6qDd9JpZe0FuK2lKeTcA0fKXZdhT4AY1
 B/TGr74YK83AZ0g5FLNTmwTElehkTvVGNPQILcsRyYFxP3WjX2Sz774
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The JPEG encoders program the hardware with the macroblock count of the
OUTPUT format and treat the difference between the OUTPUT and CAPTURE
sizes as the crop inside the last macroblock, which is written into
narrow register fields. They also write the JPEG header into the
CAPTURE buffer without checking its size.

When the two formats disagree beyond that, as could happen before the
coded size was kept in sync with the OUTPUT format, the encoder on
RK3588 generated IOMMU page faults close to address 0, timed out, and
left the IOMMU unable to stall, requiring a reboot.

The format ioctls are now expected to keep the formats consistent, but
as getting this wrong takes down the whole encoder, check the geometry
and the CAPTURE buffer size before programming the hardware and fail
the job instead.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../platform/verisilicon/hantro_h1_jpeg_enc.c      |  5 +++
 drivers/media/platform/verisilicon/hantro_jpeg.c   | 37 ++++++++++++++++++++++
 drivers/media/platform/verisilicon/hantro_jpeg.h   |  5 +++
 .../verisilicon/rockchip_vpu2_hw_jpeg_enc.c        |  5 +++
 4 files changed, 52 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c b/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
index 86cc1a07026f..d8c71676a3f2 100644
--- a/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
+++ b/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
@@ -109,10 +109,15 @@ int hantro_h1_jpeg_enc_run(struct hantro_ctx *ctx)
 	struct vb2_v4l2_buffer *src_buf, *dst_buf;
 	struct hantro_jpeg_ctx jpeg_ctx;
 	u32 reg;
+	int ret;
 
 	src_buf = hantro_get_src_buf(ctx);
 	dst_buf = hantro_get_dst_buf(ctx);
 
+	ret = hantro_jpeg_enc_check_job(ctx, &dst_buf->vb2_buf);
+	if (ret)
+		return ret;
+
 	hantro_start_prepare_run(ctx);
 
 	memset(&jpeg_ctx, 0, sizeof(jpeg_ctx));
diff --git a/drivers/media/platform/verisilicon/hantro_jpeg.c b/drivers/media/platform/verisilicon/hantro_jpeg.c
index 13a60638e43f..2f2afd632c1b 100644
--- a/drivers/media/platform/verisilicon/hantro_jpeg.c
+++ b/drivers/media/platform/verisilicon/hantro_jpeg.c
@@ -14,6 +14,7 @@
 #include <media/v4l2-jpeg.h>
 #include "hantro_jpeg.h"
 #include "hantro.h"
+#include "hantro_hw.h"
 
 #define LUMA_QUANT_OFF		25
 #define CHROMA_QUANT_OFF	90
@@ -243,3 +244,39 @@ void hantro_jpeg_header_assemble(struct hantro_jpeg_ctx *ctx)
 
 	jpeg_set_quality(ctx);
 }
+
+/*
+ * Check that the formats describe a frame the JPEG encoders can be
+ * programmed with: the coded size may only crop the OUTPUT frame inside
+ * the right-most and bottom-most macroblocks, and the CAPTURE buffer
+ * must have room for the header and some payload. The V4L2 ioctls are
+ * expected to guarantee this, but programming the hardware with
+ * anything else makes it access memory outside the buffers, so refuse
+ * the job instead.
+ */
+int hantro_jpeg_enc_check_job(struct hantro_ctx *ctx,
+			      struct vb2_buffer *dst_buf)
+{
+	const struct v4l2_pix_format_mplane *src = &ctx->src_fmt;
+	const struct v4l2_pix_format_mplane *dst = &ctx->dst_fmt;
+
+	if (!dst->width || !dst->height ||
+	    !IS_ALIGNED(src->width, MB_DIM) ||
+	    !IS_ALIGNED(src->height, MB_DIM) ||
+	    dst->width > src->width || dst->height > src->height ||
+	    src->width - dst->width >= MB_DIM ||
+	    src->height - dst->height >= MB_DIM ||
+	    !IS_ALIGNED(src->width - dst->width, 4)) {
+		vpu_err("inconsistent geometry: OUTPUT %ux%u, CAPTURE %ux%u\n",
+			src->width, src->height, dst->width, dst->height);
+		return -EINVAL;
+	}
+
+	if (vb2_plane_size(dst_buf, 0) <= ctx->vpu_dst_fmt->header_size) {
+		vpu_err("CAPTURE buffer too small: %lu bytes\n",
+			vb2_plane_size(dst_buf, 0));
+		return -EINVAL;
+	}
+
+	return 0;
+}
diff --git a/drivers/media/platform/verisilicon/hantro_jpeg.h b/drivers/media/platform/verisilicon/hantro_jpeg.h
index 0b49d0b82caa..296ad1e821c7 100644
--- a/drivers/media/platform/verisilicon/hantro_jpeg.h
+++ b/drivers/media/platform/verisilicon/hantro_jpeg.h
@@ -1,5 +1,8 @@
 /* SPDX-License-Identifier: GPL-2.0+ */
 
+struct hantro_ctx;
+struct vb2_buffer;
+
 #define JPEG_HEADER_SIZE	624
 #define JPEG_QUANT_SIZE		64
 
@@ -13,3 +16,5 @@ struct hantro_jpeg_ctx {
 };
 
 void hantro_jpeg_header_assemble(struct hantro_jpeg_ctx *ctx);
+int hantro_jpeg_enc_check_job(struct hantro_ctx *ctx,
+			      struct vb2_buffer *dst_buf);
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c b/drivers/media/platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c
index 61621b1be8a2..b6217e332fc0 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c
@@ -135,10 +135,15 @@ int rockchip_vpu2_jpeg_enc_run(struct hantro_ctx *ctx)
 	struct vb2_v4l2_buffer *src_buf, *dst_buf;
 	struct hantro_jpeg_ctx jpeg_ctx;
 	u32 reg;
+	int ret;
 
 	src_buf = hantro_get_src_buf(ctx);
 	dst_buf = hantro_get_dst_buf(ctx);
 
+	ret = hantro_jpeg_enc_check_job(ctx, &dst_buf->vb2_buf);
+	if (ret)
+		return ret;
+
 	hantro_start_prepare_run(ctx);
 
 	memset(&jpeg_ctx, 0, sizeof(jpeg_ctx));

-- 
2.55.0

