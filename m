From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:59:04 +0000
Subject: [PATCH 1/2] media: verisilicon: av1: Find the reference buffers by
 timestamp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-vpu981-av1-refs-v1-1-c65769715db9@gmail.com>
References: <20261115-b4-vpu981-av1-refs-v1-0-c65769715db9@gmail.com>
In-Reply-To: <20261115-b4-vpu981-av1-refs-v1-0-c65769715db9@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794733143; l=5334;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=nRwuv7ZOUhXWAqCeQr6LwCeSgpkrEt0gULCQ43OMD0g=;
 b=fJ/ecB6NvRMd8bXQ6bmKJeEKmmT9WHfqmSSKsnPyxv07xVXlz8yztL4x+jkqf9S505hxoQOYL
 nhvyokCntfkAJ4B8yugDAXgNWEGwQ9EXIB0ZT9F9I7GjG3Vw+1iKM66
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

frame_refs[] keeps a CAPTURE buffer pointer per reference across jobs.
VIDIOC_REMOVE_BUFS can free that buffer, and a missing reference falls
back to slot 0, which can hold a stale pointer.

Look the buffer up by timestamp at each job, as the other Hantro codecs
do, and use the current CAPTURE buffer and frame size when the reference
is missing.

Fixes: 727a400686a2 ("media: verisilicon: Add Rockchip AV1 decoder")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_hw.h     |  1 -
 .../verisilicon/rockchip_vpu981_hw_av1_dec.c       | 37 ++++++++++++----------
 2 files changed, 21 insertions(+), 17 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_hw.h b/drivers/media/platform/verisilicon/hantro_hw.h
index 13e573f1f19d..36df8caa077d 100644
--- a/drivers/media/platform/verisilicon/hantro_hw.h
+++ b/drivers/media/platform/verisilicon/hantro_hw.h
@@ -287,7 +287,6 @@ struct hantro_av1_frame_ref {
 	bool used;
 	u32 order_hint;
 	u32 order_hints[V4L2_AV1_TOTAL_REFS_PER_FRAME];
-	struct vb2_v4l2_buffer *vb2_ref;
 };
 
 /**
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c b/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c
index 2a145433e6d1..59f2adf74850 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c
@@ -169,7 +169,6 @@ static int rockchip_vpu981_av1_dec_frame_ref(struct hantro_ctx *ctx,
 		av1_dec->frame_refs[i].timestamp = timestamp;
 		av1_dec->frame_refs[i].frame_type = frame->frame_type;
 		av1_dec->frame_refs[i].order_hint = frame->order_hint;
-		av1_dec->frame_refs[i].vb2_ref = hantro_get_dst_buf(ctx);
 
 		for (j = 0; j < V4L2_AV1_TOTAL_REFS_PER_FRAME; j++)
 			av1_dec->frame_refs[i].order_hints[j] = frame->order_hints[j];
@@ -182,6 +181,18 @@ static int rockchip_vpu981_av1_dec_frame_ref(struct hantro_ctx *ctx,
 	return AV1_INVALID_IDX;
 }
 
+static struct vb2_buffer *rockchip_vpu981_av1_dec_ref_buf(struct hantro_ctx *ctx, int idx)
+{
+	struct hantro_av1_dec_hw_ctx *av1_dec = &ctx->av1_dec;
+	struct vb2_queue *q = v4l2_m2m_get_dst_vq(ctx->fh.m2m_ctx);
+	struct vb2_buffer *buf = NULL;
+
+	if (idx >= 0 && av1_dec->frame_refs[idx].used)
+		buf = vb2_find_buffer(q, av1_dec->frame_refs[idx].timestamp);
+
+	return buf ?: &hantro_get_dst_buf(ctx)->vb2_buf;
+}
+
 static void rockchip_vpu981_av1_dec_frame_unref(struct hantro_ctx *ctx, int idx)
 {
 	struct hantro_av1_dec_hw_ctx *av1_dec = &ctx->av1_dec;
@@ -829,7 +840,7 @@ rockchip_vpu981_av1_dec_set_ref(struct hantro_ctx *ctx, int ref, int idx,
 		pr_warn("AV1 invalid reference frame index\n");
 	}
 
-	dst = vb2_to_hantro_decoded_buf(&av1_dec->frame_refs[idx].vb2_ref->vb2_buf);
+	dst = vb2_to_hantro_decoded_buf(rockchip_vpu981_av1_dec_ref_buf(ctx, idx));
 	luma_addr = hantro_get_dec_buf_addr(ctx, &dst->base.vb.vb2_buf);
 	chroma_addr = luma_addr + dst->av1.chroma_offset;
 	mv_addr = luma_addr + dst->av1.mv_offset;
@@ -894,7 +905,7 @@ static void rockchip_vpu981_av1_dec_set_segmentation(struct hantro_ctx *ctx)
 			struct hantro_decoded_buffer *seg;
 			size_t mv_offset = rockchip_vpu981_av1_dec_chroma_size(ctx);
 
-			seg = vb2_to_hantro_decoded_buf(&av1_dec->frame_refs[idx].vb2_ref->vb2_buf);
+			seg = vb2_to_hantro_decoded_buf(rockchip_vpu981_av1_dec_ref_buf(ctx, idx));
 			luma_addr = hantro_get_dec_buf_addr(ctx, &seg->base.vb.vb2_buf);
 			mv_addr = luma_addr + mv_offset;
 
@@ -1983,16 +1994,13 @@ static void rockchip_vpu981_av1_dec_set_reference_frames(struct hantro_ctx *ctx)
 
 	for (i = V4L2_AV1_REF_LAST_FRAME; i < V4L2_AV1_TOTAL_REFS_PER_FRAME; i++) {
 		u32 ref = i - 1;
-		int idx = 0;
-		int width, height;
+		int idx = AV1_INVALID_IDX;
+		int width = frame->frame_width_minus_1 + 1;
+		int height = frame->frame_height_minus_1 + 1;
 
-		if (allow_intrabc) {
-			idx = av1_dec->current_frame_index;
-			width = frame->frame_width_minus_1 + 1;
-			height = frame->frame_height_minus_1 + 1;
-		} else {
-			if (rockchip_vpu981_get_frame_index(ctx, ref) > 0)
-				idx = rockchip_vpu981_get_frame_index(ctx, ref);
+		if (!allow_intrabc)
+			idx = rockchip_vpu981_get_frame_index(ctx, ref);
+		if (idx >= 0) {
 			width = av1_dec->frame_refs[idx].width;
 			height = av1_dec->frame_refs[idx].height;
 		}
@@ -2185,16 +2193,13 @@ rockchip_vpu981_av1_dec_set_input_buffer(struct hantro_ctx *ctx,
 static void
 rockchip_vpu981_av1_dec_set_output_buffer(struct hantro_ctx *ctx)
 {
-	struct hantro_av1_dec_hw_ctx *av1_dec = &ctx->av1_dec;
 	struct hantro_dev *vpu = ctx->dev;
 	struct hantro_decoded_buffer *dst;
-	struct vb2_v4l2_buffer *vb2_dst;
 	dma_addr_t luma_addr, chroma_addr, mv_addr = 0;
 	size_t cr_offset = rockchip_vpu981_av1_dec_luma_size(ctx);
 	size_t mv_offset = rockchip_vpu981_av1_dec_chroma_size(ctx);
 
-	vb2_dst = av1_dec->frame_refs[av1_dec->current_frame_index].vb2_ref;
-	dst = vb2_to_hantro_decoded_buf(&vb2_dst->vb2_buf);
+	dst = vb2_to_hantro_decoded_buf(&hantro_get_dst_buf(ctx)->vb2_buf);
 	luma_addr = hantro_get_dec_buf_addr(ctx, &dst->base.vb.vb2_buf);
 	chroma_addr = luma_addr + cr_offset;
 	mv_addr = luma_addr + mv_offset;

-- 
2.55.0

