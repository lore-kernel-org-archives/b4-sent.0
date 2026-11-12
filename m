From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:31:25 +0000
Subject: [PATCH v2 3/7] media: verisilicon: Keep the encoder coded size in
 sync with OUTPUT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hantro-jpeg-enc-fixes-v2-3-de03e643c75d@gmail.com>
References: <20261112-hantro-jpeg-enc-fixes-v2-0-de03e643c75d@gmail.com>
In-Reply-To: <20261112-hantro-jpeg-enc-fixes-v2-0-de03e643c75d@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Sergei Khomenkov <shomenkow@gmail.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472282; l=3589;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=OJEFqjdZC2EJLo/FyCqrvkQ+A2FOxXjkcSLl5BADKq4=;
 b=3mR9MSso6c0lCPdo4Pm1XntRNu/w47veV1nzKGxRCeSVTaIrZCaTkXVGh8v0BXujR3b5NTRWK
 SwD7iMBGyhmAuiQj7iJIe2l8Id92B6LUIy1q25J9Iy5KtB5q9XQtXIA
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

Fixes: 953aaa1492c5 ("media: rockchip/vpu: Prepare things to support decoders")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 26 ++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index c4e36a79eecc..e9d91504fab2 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -542,6 +542,7 @@ static int hantro_set_fmt_out(struct hantro_ctx *ctx,
 			      struct v4l2_pix_format_mplane *pix_mp,
 			      bool need_postproc)
 {
+	struct v4l2_pix_format_mplane coded_fmt;
 	struct vb2_queue *vq;
 	int ret;
 
@@ -561,16 +562,41 @@ static int hantro_set_fmt_out(struct hantro_ctx *ctx,
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

