From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:00 +0000
Subject: [PATCH 5/6] media: verisilicon: Don't reset the encoder raw format
 while OUTPUT buffers exist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-jpeg-enc-fixes-v1-5-fc4dc7e985d2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295075; l=4809;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=6ZAkyJS2xXZVjmfyUwqoguzm2MWh0Tv8oryah8QSDZw=;
 b=M/D7QYQlGPBD7LO5ikSRpoRG7kPotoeDdytjtgSMB0/SkiDUjHXbHZEqYumv6nfOPEP6Uxai4
 rJNZ2jysBzNDzDdsrw2X0YxCtZOiQ6HxDtjYdSPalMSb3UWRNnZIptn
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For an encoder, hantro_set_fmt_cap() allows S_FMT on the CAPTURE queue
while the OUTPUT queue has buffers as long as the coded pixel format and
size don't change, and then unconditionally resets the raw format through
hantro_reset_raw_fmt(). That helper sets ctx->vpu_src_fmt to the default
raw format before hantro_set_fmt_out() can refuse the change with -EBUSY
(the OUTPUT queue is busy), so the ioctl fails but leaves the context
inconsistent: ctx->src_fmt still describes the negotiated raw format
(e.g. NM12, two planes) while ctx->vpu_src_fmt describes the default one
(YM12, three planes).

The next job then programs the hardware with the wrong input format: on
the RK3588 VEPU121 JPEG encoder the third plane address is never written,
the encoder reads the V plane from IOVA 0 and the job ends in an IOMMU
page fault and a watchdog timeout. v4l2-ctl triggers this on every
--stream-mmap run, because it re-applies the CAPTURE format after the
OUTPUT queue has been set up:

  rk_iommu fdba0800.iommu: Page fault at 0x0000000000000000 of type read
  rk_iommu fdba0800.iommu: Page fault at 0x00000000000003c0 of type read
  ...
  hantro_watchdog:208: frame processing timed out!

Skip the raw format reset when OUTPUT buffers exist: the coded format is
unchanged in that case, so the raw format stays valid, and the S_FMT is
accepted as the busy check intends. Also restore ctx->vpu_src_fmt in
hantro_reset_raw_fmt() when hantro_set_fmt_out() fails, so that no other
caller can leave the two descriptors out of sync.

Fixes: 5980d40276b3 ("media: hantro: Cleanup format negotiation helpers")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 33 +++++++++++++++++++-----
 1 file changed, 26 insertions(+), 7 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 2761d37af7cd..ce01ec6ea33d 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -470,7 +470,7 @@ hantro_reset_encoded_fmt(struct hantro_ctx *ctx)
 int
 hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 {
-	const struct hantro_fmt *raw_vpu_fmt;
+	const struct hantro_fmt *raw_vpu_fmt, *old_vpu_src_fmt = NULL;
 	struct v4l2_pix_format_mplane raw_fmt, *encoded_fmt;
 	int ret;
 
@@ -480,6 +480,7 @@ hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 
 	if (ctx->is_encoder) {
 		encoded_fmt = &ctx->dst_fmt;
+		old_vpu_src_fmt = ctx->vpu_src_fmt;
 		ctx->vpu_src_fmt = raw_vpu_fmt;
 	} else {
 		encoded_fmt = &ctx->src_fmt;
@@ -496,6 +497,12 @@ hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 	if (!ret) {
 		ctx->bit_depth = bit_depth;
 		ctx->need_postproc = need_postproc;
+	} else if (ctx->is_encoder) {
+		/*
+		 * hantro_set_fmt_out() refused the new raw format, so the
+		 * OUTPUT format is unchanged: keep its descriptor in sync.
+		 */
+		ctx->vpu_src_fmt = old_vpu_src_fmt;
 	}
 
 	return ret;
@@ -642,6 +649,7 @@ static int hantro_set_fmt_out(struct hantro_ctx *ctx,
 static int hantro_set_fmt_cap(struct hantro_ctx *ctx,
 			      struct v4l2_pix_format_mplane *pix_mp)
 {
+	bool reset_raw_fmt = ctx->is_encoder;
 	int ret;
 
 	if (ctx->is_encoder) {
@@ -654,11 +662,22 @@ static int hantro_set_fmt_cap(struct hantro_ctx *ctx,
 		 */
 		peer_vq = v4l2_m2m_get_vq(ctx->fh.m2m_ctx,
 					  V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE);
-		if (vb2_is_busy(peer_vq) &&
-		    (pix_mp->pixelformat != ctx->dst_fmt.pixelformat ||
-		     pix_mp->height != ctx->dst_fmt.height ||
-		     pix_mp->width != ctx->dst_fmt.width))
-			return -EBUSY;
+		if (vb2_is_busy(peer_vq)) {
+			if (pix_mp->pixelformat != ctx->dst_fmt.pixelformat ||
+			    pix_mp->height != ctx->dst_fmt.height ||
+			    pix_mp->width != ctx->dst_fmt.width)
+				return -EBUSY;
+
+			/*
+			 * The coded format is unchanged, so the raw format
+			 * stays valid. It couldn't be reset anyway while
+			 * OUTPUT buffers exist (hantro_set_fmt_out() would
+			 * refuse), and failing here after the coded format
+			 * has been updated would leave the context
+			 * inconsistent.
+			 */
+			reset_raw_fmt = false;
+		}
 	}
 
 	ret = hantro_try_fmt(ctx, pix_mp, V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE);
@@ -680,7 +699,7 @@ static int hantro_set_fmt_cap(struct hantro_ctx *ctx,
 	 * Note that hantro_reset_raw_fmt() also propagates size
 	 * changes to the raw format.
 	 */
-	if (ctx->is_encoder)
+	if (reset_raw_fmt)
 		hantro_reset_raw_fmt(ctx, HANTRO_DEFAULT_BIT_DEPTH, HANTRO_AUTO_POSTPROC);
 
 	/* Colorimetry information are always propagated. */

-- 
2.55.0

