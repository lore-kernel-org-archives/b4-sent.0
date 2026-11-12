From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:31:24 +0000
Subject: [PATCH v2 2/7] media: verisilicon: Enforce a minimum CAPTURE
 sizeimage for the encoder
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hantro-jpeg-enc-fixes-v2-2-de03e643c75d@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472282; l=2439;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=YQ5ecCRUVeVgOkI6N/CRbGwzdtVVxR9e29iInCuRPn8=;
 b=DkBGBOuCHyV4Q9kcGGxhfFctCWJWujliWLY1tlsvqCTAWl/NgbBA4xFiJNhh42o61ZSQZb2IM
 ddR4yNNre0BDrCvUPL2CmBJzW3PAQcLJ96AuYR7L/kpWKTsfwggoCTm
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For coded formats hantro_try_fmt() only computes sizeimage when the
application passes 0, and otherwise accepts any value. On the encoder
that lets the CAPTURE buffers be far too small for the selected
resolution.

This is easy to hit: "v4l2-ctl --set-fmt-video=width=1920,height=1080,
pixelformat=JPEG" does G_FMT, modifies the size and calls S_FMT, so it
passes back the 6768 byte sizeimage of the 96x32 default format. The
driver accepts it for 1920x1088, the hardware runs out of stream buffer
on every frame and the encoder only produces empty buffers.

The stateful encoder specification lets the encoder adjust sizeimage to
match hardware requirements. For the encoder, clamp the requested
sizeimage up to the size already used as the default, while still
allowing applications to ask for larger buffers. The decoder behaviour
is unchanged.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 17 ++++++++++++++---
 1 file changed, 14 insertions(+), 3 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index d033fe0ecef6..c4e36a79eecc 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -386,14 +386,25 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 			pix_mp->plane_fmt[0].sizeimage +=
 				hantro_av1_mv_size(pix_mp->width,
 						   pix_mp->height);
-	} else if (!pix_mp->plane_fmt[0].sizeimage) {
+	} else {
+		u32 max_size = fmt->header_size +
+			pix_mp->width * pix_mp->height * fmt->max_depth;
+		u32 *sizeimage = &pix_mp->plane_fmt[0].sizeimage;
+
 		/*
 		 * For coded formats the application can specify
 		 * sizeimage. If the application passes a zero sizeimage,
 		 * let's default to the maximum frame size.
+		 *
+		 * On the encoder, a buffer that is too small for the
+		 * current resolution only gives failed frames, so never
+		 * let the application go below that default. Larger
+		 * values are kept.
 		 */
-		pix_mp->plane_fmt[0].sizeimage = fmt->header_size +
-			pix_mp->width * pix_mp->height * fmt->max_depth;
+		if (ctx->is_encoder)
+			*sizeimage = max(*sizeimage, max_size);
+		else if (!*sizeimage)
+			*sizeimage = max_size;
 	}
 
 	return 0;

-- 
2.55.0

