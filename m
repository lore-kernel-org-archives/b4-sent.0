From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:17:57 +0000
Subject: [PATCH 2/6] media: verisilicon: Keep the encoder coded size in
 sync with OUTPUT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-jpeg-enc-fixes-v1-2-fc4dc7e985d2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295075; l=3508;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=8CL78lP1zbfblnuwBB1CozKPfWypLHdbDLFXHop9x3E=;
 b=QaHOck0+KthvnjtsENcwU65wIMds6gwzLy02ycZ1p9iUovawZh5shgaxv3k3MGxal52dV8U85
 9KSWIbGQUcZDjVa0thDyvpViWcdd/Z3F8TahoFYexu9Qu0kruP/pT7P
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the encoder, setting the CAPTURE (coded) format resets the OUTPUT
(raw) format to the same size, but setting the OUTPUT format never
updates the CAPTURE format. Following the order mandated by the
stateful encoder specification (CAPTURE first, then OUTPUT) therefore
leaves the coded size at whatever it was before, e.g. the 96x32
default:

  v4l2-ctl --set-fmt-video-out=width=1920,height=1080,pixelformat=NM12 \
           --set-fmt-video=pixelformat=JPEG --stream-out-mmap ...

ends up with a 1920x1088 OUTPUT format and a 96x32 CAPTURE format with
a 96x32 sized buffer. The JPEG encoders treat the difference between
the two as the crop inside the last macroblock, which is expected to be
below 16 pixels, and program the hardware with the full OUTPUT frame
size. On RK3588 this results in IOMMU page faults, a frame processing
timeout and a wedged encoder.

The specification says that the CAPTURE width and height are set by the
encoder from the OUTPUT format and selection rectangles, and that
setting the OUTPUT format resets the crop rectangle to the full frame.
Do that in hantro_set_fmt_out(): derive the coded format from the new
OUTPUT size, re-applying the CAPTURE constraints, including the minimum
sizeimage. As the coded format can now change from an OUTPUT S_FMT,
return -EBUSY if this would require bigger CAPTURE buffers than the
ones already allocated.

With this, the coded size can only differ from the OUTPUT size by the
crop set through VIDIOC_S_SELECTION, which is restricted to the last
macroblock.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 26 ++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index c022b978f72b..731182cde643 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -541,6 +541,7 @@ static int hantro_set_fmt_out(struct hantro_ctx *ctx,
 			      struct v4l2_pix_format_mplane *pix_mp,
 			      bool need_postproc)
 {
+	struct v4l2_pix_format_mplane coded_fmt;
 	struct vb2_queue *vq;
 	int ret;
 
@@ -560,16 +561,41 @@ static int hantro_set_fmt_out(struct hantro_ctx *ctx,
 			return -EBUSY;
 		}
 	} else {
+		struct vb2_queue *peer_vq;
+
 		/*
 		 * The encoder doesn't admit a format change if
 		 * there are OUTPUT buffers allocated.
 		 */
 		if (vb2_is_busy(vq))
 			return -EBUSY;
+
+		/*
+		 * Setting the OUTPUT format resets the crop rectangle to
+		 * the full frame, so the coded size becomes the OUTPUT
+		 * size. Refuse the change if it would need bigger
+		 * CAPTURE buffers than the ones already allocated.
+		 */
+		coded_fmt = ctx->dst_fmt;
+		coded_fmt.width = pix_mp->width;
+		coded_fmt.height = pix_mp->height;
+		ret = hantro_try_fmt(ctx, &coded_fmt,
+				     V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE);
+		if (ret)
+			return ret;
+
+		peer_vq = v4l2_m2m_get_vq(ctx->fh.m2m_ctx,
+					  V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE);
+		if (vb2_is_busy(peer_vq) &&
+		    coded_fmt.plane_fmt[0].sizeimage >
+		    ctx->dst_fmt.plane_fmt[0].sizeimage)
+			return -EBUSY;
 	}
 
 	ctx->vpu_src_fmt = hantro_find_format(ctx, pix_mp->pixelformat);
 	ctx->src_fmt = *pix_mp;
+	if (ctx->is_encoder)
+		ctx->dst_fmt = coded_fmt;
 
 	/*
 	 * Current raw format might have become invalid with newly

-- 
2.55.0

