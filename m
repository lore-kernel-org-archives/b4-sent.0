From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 20 Nov 2026 01:10:39 +0000
Subject: [PATCH 1/2] media: verisilicon: Decode monochrome H.264 to GREY on
 Rockchip
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-b4-h264-monochrome-grey-v1-1-887102a688fd@gmail.com>
References: <20261120-b4-h264-monochrome-grey-v1-0-887102a688fd@gmail.com>
In-Reply-To: <20261120-b4-h264-monochrome-grey-v1-0-887102a688fd@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795137038; l=9453;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Cg78992fL67XsePaXBhmaELrgNkRAfWpGaMq2lmYWt0=;
 b=8e/q6GX/hugFSbVYzGVUr5yizHYOxXBzXjN9BhZegL4mpogiBBXuUUJxzUdJyWQPTFqvRSLlS
 ByRhQXIypolBgNxrDcTMtl39keT8k0Y1W09JQfp2cxdlpOQf7mypvv6
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rockchip G1 and VDPU2 decoders write no chroma for a 4:0:0 H.264
picture, and the driver places the direct mode motion vectors right
after the luma plane. The driver offers NV12 only, so userspace reads
motion vectors as chroma. JVT-FR-EXT HPCAMOLQ_BRCM_B and
HPCVMOLQ_BRCM_B fail although their luma is bit-exact.

Track 4:0:0 from the SPS and offer only GREY for such streams on these
variants. Refuse the switch with -EBUSY while CAPTURE streams. Other
variants are unchanged.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro.h        |  4 +++
 drivers/media/platform/verisilicon/hantro_drv.c    | 40 ++++++++++++++++++++--
 drivers/media/platform/verisilicon/hantro_v4l2.c   | 27 ++++++++++++---
 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 39 +++++++++++++++++++++
 4 files changed, 103 insertions(+), 7 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro.h b/drivers/media/platform/verisilicon/hantro.h
index 0353de154a1e..abd50d15b2e0 100644
--- a/drivers/media/platform/verisilicon/hantro.h
+++ b/drivers/media/platform/verisilicon/hantro.h
@@ -234,6 +234,7 @@ struct hantro_dev {
  * @ctrl_handler:	Control handler used to register controls.
  * @jpeg_quality:	User-specified JPEG compression quality.
  * @bit_depth:		Bit depth of current frame
+ * @monochrome:		The stream is 4:0:0 (H.264), the decoder writes luma only
  * @need_postproc:	Set to true if the bitstream features require to
  *			use the post-processor.
  *
@@ -263,6 +264,7 @@ struct hantro_ctx {
 	struct v4l2_ctrl_handler ctrl_handler;
 	int jpeg_quality;
 	int bit_depth;
+	bool monochrome;
 
 	const struct hantro_codec_ops *codec_ops;
 	struct hantro_postproc_ctx postproc;
@@ -291,6 +293,7 @@ struct hantro_ctx {
  * @frmsize:	Supported range of frame sizes (only for bitstream formats).
  * @postprocessed: Indicates if this format needs the post-processor.
  * @match_depth: Indicates if format bit depth must match video bit depth
+ * @monochrome: Decoded format for 4:0:0 streams only
  */
 struct hantro_fmt {
 	char *name;
@@ -302,6 +305,7 @@ struct hantro_fmt {
 	struct v4l2_frmsize_stepwise frmsize;
 	bool postprocessed;
 	bool match_depth;
+	bool monochrome;
 };
 
 struct hantro_reg {
diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..25d7ac4b45da 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -300,6 +300,41 @@ static int hantro_jpeg_s_ctrl(struct v4l2_ctrl *ctrl)
 	return 0;
 }
 
+static int hantro_h264_s_ctrl(struct v4l2_ctrl *ctrl)
+{
+	struct hantro_ctx *ctx;
+	bool monochrome;
+	int ret;
+
+	ctx = container_of(ctrl->handler,
+			   struct hantro_ctx, ctrl_handler);
+
+	switch (ctrl->id) {
+	case V4L2_CID_STATELESS_H264_SPS:
+		monochrome = ctrl->p_new.p_h264_sps->chroma_format_idc == 0;
+		if (ctx->monochrome == monochrome)
+			return 0;
+
+		ctx->monochrome = monochrome;
+		/* Variants without a 4:0:0 format keep their formats */
+		if (!hantro_get_default_fmt(ctx, false, ctx->bit_depth,
+					    HANTRO_AUTO_POSTPROC)) {
+			ctx->monochrome = false;
+			return 0;
+		}
+		if (vb2_is_streaming(v4l2_m2m_get_dst_vq(ctx->fh.m2m_ctx))) {
+			ctx->monochrome = !monochrome;
+			return -EBUSY;
+		}
+		ret = hantro_reset_raw_fmt(ctx, ctx->bit_depth, HANTRO_AUTO_POSTPROC);
+		if (ret)
+			ctx->monochrome = !monochrome;
+		return ret;
+	default:
+		return -EINVAL;
+	}
+}
+
 static int hantro_vp9_s_ctrl(struct v4l2_ctrl *ctrl)
 {
 	struct hantro_ctx *ctx;
@@ -377,8 +412,9 @@ static int hantro_av1_s_ctrl(struct v4l2_ctrl *ctrl)
 	return 0;
 }
 
-static const struct v4l2_ctrl_ops hantro_ctrl_ops = {
+static const struct v4l2_ctrl_ops hantro_h264_ctrl_ops = {
 	.try_ctrl = hantro_try_ctrl,
+	.s_ctrl = hantro_h264_s_ctrl,
 };
 
 static const struct v4l2_ctrl_ops hantro_jpeg_ctrl_ops = {
@@ -460,7 +496,7 @@ static const struct hantro_ctrl controls[] = {
 		.codec = HANTRO_H264_DECODER,
 		.cfg = {
 			.id = V4L2_CID_STATELESS_H264_SPS,
-			.ops = &hantro_ctrl_ops,
+			.ops = &hantro_h264_ctrl_ops,
 		},
 	}, {
 		.codec = HANTRO_H264_DECODER,
diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 83af9fa1ce94..550062069b04 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -109,6 +109,17 @@ hantro_check_depth_match(const struct hantro_fmt *fmt, int bit_depth)
 	return fmt_depth == bit_depth;
 }
 
+static bool
+hantro_check_fmt_match(const struct hantro_ctx *ctx,
+		       const struct hantro_fmt *fmt, int bit_depth)
+{
+	if (!ctx->is_encoder && fmt->codec_mode == HANTRO_MODE_NONE &&
+	    fmt->monochrome != ctx->monochrome)
+		return false;
+
+	return hantro_check_depth_match(fmt, bit_depth);
+}
+
 static const struct hantro_fmt *
 hantro_find_format(const struct hantro_ctx *ctx, u32 fourcc)
 {
@@ -156,7 +167,7 @@ hantro_get_default_fmt(const struct hantro_ctx *ctx, bool bitstream,
 	for (i = 0; i < num_fmts; i++) {
 		if (bitstream == (formats[i].codec_mode !=
 				  HANTRO_MODE_NONE) &&
-		    hantro_check_depth_match(&formats[i], bit_depth))
+		    hantro_check_fmt_match(ctx, &formats[i], bit_depth))
 			return &formats[i];
 	}
 
@@ -164,7 +175,7 @@ hantro_get_default_fmt(const struct hantro_ctx *ctx, bool bitstream,
 	for (i = 0; i < num_fmts; i++) {
 		if (bitstream == (formats[i].codec_mode !=
 				  HANTRO_MODE_NONE) &&
-		    hantro_check_depth_match(&formats[i], bit_depth))
+		    hantro_check_fmt_match(ctx, &formats[i], bit_depth))
 			return &formats[i];
 	}
 
@@ -253,7 +264,7 @@ static int vidioc_enum_fmt(struct file *file, void *priv,
 
 		if (skip_mode_none == mode_none)
 			continue;
-		if (!hantro_check_depth_match(fmt, ctx->bit_depth) && !enum_all_formats)
+		if (!hantro_check_fmt_match(ctx, fmt, ctx->bit_depth) && !enum_all_formats)
 			continue;
 		if (j == index) {
 			f->pixelformat = fmt->fourcc;
@@ -273,7 +284,7 @@ static int vidioc_enum_fmt(struct file *file, void *priv,
 	for (i = 0; i < num_fmts; i++) {
 		fmt = &formats[i];
 
-		if (!hantro_check_depth_match(fmt, ctx->bit_depth) && !enum_all_formats)
+		if (!hantro_check_fmt_match(ctx, fmt, ctx->bit_depth) && !enum_all_formats)
 			continue;
 		if (j == index) {
 			f->pixelformat = fmt->fourcc;
@@ -337,6 +348,9 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 	vpu_debug(4, "trying format %p4cc\n", &pix_mp->pixelformat);
 
 	fmt = hantro_find_format(ctx, pix_mp->pixelformat);
+	if (fmt && !coded && !ctx->is_encoder &&
+	    fmt->monochrome != ctx->monochrome)
+		fmt = NULL;
 	if (!fmt) {
 		fmt = hantro_get_default_fmt(ctx, coded, HANTRO_DEFAULT_BIT_DEPTH, HANTRO_AUTO_POSTPROC);
 		pix_mp->pixelformat = fmt->fourcc;
@@ -570,10 +584,13 @@ static int hantro_set_fmt_out(struct hantro_ctx *ctx,
 	 * Note that hantro_reset_raw_fmt() also propagates size
 	 * changes to the raw format.
 	 */
-	if (!ctx->is_encoder)
+	if (!ctx->is_encoder) {
+		/* A new stream: assume chroma until its H.264 SPS says otherwise */
+		ctx->monochrome = false;
 		hantro_reset_raw_fmt(ctx,
 				     hantro_get_format_depth(pix_mp->pixelformat),
 				     need_postproc);
+	}
 
 	/* Colorimetry information are always propagated. */
 	ctx->dst_fmt.colorspace = pix_mp->colorspace;
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 02673be9878e..851af0e6c80b 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -134,6 +134,19 @@ static const struct hantro_fmt rk3066_vpu_dec_fmts[] = {
 			.step_height = MB_DIM,
 		},
 	},
+	{
+		.fourcc = V4L2_PIX_FMT_GREY,
+		.codec_mode = HANTRO_MODE_NONE,
+		.monochrome = true,
+		.frmsize = {
+			.min_width = FMT_MIN_WIDTH,
+			.max_width = FMT_FHD_WIDTH,
+			.step_width = MB_DIM,
+			.min_height = FMT_MIN_HEIGHT,
+			.max_height = FMT_FHD_HEIGHT,
+			.step_height = MB_DIM,
+		},
+	},
 	{
 		.fourcc = V4L2_PIX_FMT_H264_SLICE,
 		.codec_mode = HANTRO_MODE_H264_DEC,
@@ -188,6 +201,19 @@ static const struct hantro_fmt rk3288_vpu_dec_fmts[] = {
 			.step_height = MB_DIM,
 		},
 	},
+	{
+		.fourcc = V4L2_PIX_FMT_GREY,
+		.codec_mode = HANTRO_MODE_NONE,
+		.monochrome = true,
+		.frmsize = {
+			.min_width = FMT_MIN_WIDTH,
+			.max_width = FMT_4K_WIDTH,
+			.step_width = MB_DIM,
+			.min_height = FMT_MIN_HEIGHT,
+			.max_height = FMT_4K_HEIGHT,
+			.step_height = MB_DIM,
+		},
+	},
 	{
 		.fourcc = V4L2_PIX_FMT_H264_SLICE,
 		.codec_mode = HANTRO_MODE_H264_DEC,
@@ -242,6 +268,19 @@ static const struct hantro_fmt rockchip_vdpu2_dec_fmts[] = {
 			.step_height = MB_DIM,
 		},
 	},
+	{
+		.fourcc = V4L2_PIX_FMT_GREY,
+		.codec_mode = HANTRO_MODE_NONE,
+		.monochrome = true,
+		.frmsize = {
+			.min_width = FMT_MIN_WIDTH,
+			.max_width = FMT_FHD_WIDTH,
+			.step_width = MB_DIM,
+			.min_height = FMT_MIN_HEIGHT,
+			.max_height = FMT_FHD_HEIGHT,
+			.step_height = MB_DIM,
+		},
+	},
 	{
 		.fourcc = V4L2_PIX_FMT_H264_SLICE,
 		.codec_mode = HANTRO_MODE_H264_DEC,

-- 
2.55.0

