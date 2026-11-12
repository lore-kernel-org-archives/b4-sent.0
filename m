From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:55:00 +0000
Subject: [PATCH] media: verisilicon: Check the CAPTURE buffer size when a
 decode job starts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hantro-dec-size-check-v1-1-e5f1180b625f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QqCQBCF4VeRuW6gHWoVXyW60PGok6CxYxGJ7
 95Wl9+B82/kSAanutgo4Wluy5wRDgXp2MwD2LpskqPEEIJwHte0cAdltzdYR+jEfdWcWqlKied
 I+XtP6O31616uf/ujvUHXb4z2/QPmcRH5eQAAAA==
X-Change-ID: 20261112-hantro-dec-size-check-f8a4b2872656
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473699; l=5619;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=92PcgP27BM8JLOKwI+obstcAlHRvFAhAEyuDObXEIr8=;
 b=Ori6G9ZMLO2rfDUSBzAxBcY6QDgGGECnTRbCEIWdaZwdTgLlRxvwwCNM/c8P7/n3Ij3rXCnSF
 I1+5LCf6vERBaWRlQkyEWFebgvqQxnSpRimp6vkm5EIHvAsDUK9ZowW
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CAPTURE buffers of a decoder are checked against the CAPTURE format
when they are queued, in hantro_buf_prepare(). Since commit bbd267daf4fc
("media: verisilicon: vp9: Allow to change resolution while streaming")
the format can change while buffers are allocated and queued: S_FMT on
the OUTPUT queue resets the CAPTURE format to the new size, and the
HEVC, VP9 and AV1 controls reset it when the bit depth changes (AV1 also
when film grain turns the post-processor on), the latter when the
controls of the request are applied for the job.

A CAPTURE buffer that was queued before such a change can be smaller
than the new format needs, and the decoder, or the post-processor, is
started on it with the new size all the same.

Check the buffer of the job against the CAPTURE format again when the
job starts, and return the buffers of the job with an error if it is too
small. The controls of the request have to be applied before that, so
apply them in device_run() instead of hantro_start_prepare_run(), which
every codec calls before it reads a control.

Fixes: bbd267daf4fc ("media: verisilicon: vp9: Allow to change resolution while streaming")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
This check is for all the Hantro decoders. The AV1 decoder, which is
programmed with the frame size of its controls rather than the size of
the formats, also gets a check of the frame against the CAPTURE format
in patch 6 of the series "media: verisilicon: Fix MPEG-2 field pictures,
4K VP8 and the AV1 tile buffers" v2, sent shortly before this patch. The
two patches do not depend on each other.

Tested on an Orange Pi 5 (RK3588S), on a 7.3-based tree with the patch
ported to its device_run(), which other pending series have changed. A
CAPTURE buffer is queued for a 640x368 OUTPUT format, the OUTPUT format
is then set to 1920x1088 while streaming and a request is queued: for
H.264, VP8 and MPEG-2 on the VPU121 and for AV1 on the VPU981 the
request completes with both buffers flagged V4L2_BUF_FLAG_ERROR, and so
does an AV1 request whose sequence control switches an 8-bit context to
10 bits. The fluster H.264 (JVT-AVC_V1, JVT-FR-EXT) and VP8 runs on the
VPU121 give the same per-test results as an earlier run on the same
board, and so do four fluster AV1 runs on the VPU981 (203/242). In a
fifth AV1 run av1-1-b8-06-mfmv also failed, with one decoder timeout and
no reject; it passed in the other four runs.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed it and tested
it as described above.
---
 drivers/media/platform/verisilicon/hantro_drv.c    | 37 ++++++++++++++++++----
 .../platform/verisilicon/hantro_g1_mpeg2_dec.c     |  1 -
 2 files changed, 31 insertions(+), 7 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..c496df1d5652 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -130,12 +130,6 @@ void hantro_watchdog(struct work_struct *work)
 
 void hantro_start_prepare_run(struct hantro_ctx *ctx)
 {
-	struct vb2_v4l2_buffer *src_buf;
-
-	src_buf = hantro_get_src_buf(ctx);
-	v4l2_ctrl_request_setup(src_buf->vb2_buf.req_obj.req,
-				&ctx->ctrl_handler);
-
 	if (!ctx->is_encoder && !ctx->dev->variant->late_postproc) {
 		if (hantro_needs_postproc(ctx, ctx->vpu_dst_fmt))
 			hantro_postproc_enable(ctx);
@@ -164,6 +158,24 @@ void hantro_end_prepare_run(struct hantro_ctx *ctx)
 			      msecs_to_jiffies(2000));
 }
 
+/*
+ * The CAPTURE buffers of a decoder are checked against the CAPTURE format when
+ * they are queued, but the format can change while they are queued.
+ */
+static bool hantro_dec_dst_buf_fits(struct hantro_ctx *ctx,
+				    struct vb2_v4l2_buffer *dst)
+{
+	unsigned int i;
+
+	for (i = 0; i < ctx->dst_fmt.num_planes; i++) {
+		if (vb2_plane_size(&dst->vb2_buf, i) <
+		    ctx->dst_fmt.plane_fmt[i].sizeimage)
+			return false;
+	}
+
+	return true;
+}
+
 static void device_run(void *priv)
 {
 	struct hantro_ctx *ctx = priv;
@@ -182,6 +194,19 @@ static void device_run(void *priv)
 
 	v4l2_m2m_buf_copy_metadata(src, dst);
 
+	/*
+	 * Apply the controls of the request first: they can change the bit
+	 * depth, and with it the CAPTURE format.
+	 */
+	v4l2_ctrl_request_setup(src->vb2_buf.req_obj.req, &ctx->ctrl_handler);
+
+	if (!ctx->is_encoder && !hantro_dec_dst_buf_fits(ctx, dst)) {
+		v4l2_ctrl_request_complete(src->vb2_buf.req_obj.req,
+					   &ctx->ctrl_handler);
+		hantro_job_finish(ctx, VB2_BUF_STATE_ERROR);
+		return;
+	}
+
 	ret = ctx->codec_ops->run(ctx);
 	if (ret)
 		hantro_job_finish(ctx, VB2_BUF_STATE_ERROR);
diff --git a/drivers/media/platform/verisilicon/hantro_g1_mpeg2_dec.c b/drivers/media/platform/verisilicon/hantro_g1_mpeg2_dec.c
index 6a942f4b8a2d..1cc74f52daa9 100644
--- a/drivers/media/platform/verisilicon/hantro_g1_mpeg2_dec.c
+++ b/drivers/media/platform/verisilicon/hantro_g1_mpeg2_dec.c
@@ -156,7 +156,6 @@ int hantro_g1_mpeg2_dec_run(struct hantro_ctx *ctx)
 	src_buf = hantro_get_src_buf(ctx);
 	dst_buf = hantro_get_dst_buf(ctx);
 
-	/* Apply request controls if any */
 	hantro_start_prepare_run(ctx);
 
 	seq = hantro_get_ctrl(ctx,

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261112-hantro-dec-size-check-f8a4b2872656

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

