From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:31:28 +0000
Subject: [PATCH v2 6/7] media: verisilicon: Don't reset the encoder raw
 format while OUTPUT buffers exist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hantro-jpeg-enc-fixes-v2-6-de03e643c75d@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472283; l=5213;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=NvWLsoYjF8H/jW8URNFkSbK/PgqFx88YkKipI7WobH4=;
 b=opKVutUysf8SZuTFjmHZMaBipKT2oJM6M2rbma++cqwWub8gooXWEXSmEj9J4EE6hBgRjLjls
 Xo21081UJWCCzmTqp8pNkXxQziJu+aYdWCvUcAHzyK2+ev4PQvkaPu1
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For an encoder, hantro_set_fmt_cap() allows S_FMT on the CAPTURE queue
while the OUTPUT queue has buffers as long as the coded pixel format and
size don't change, and then unconditionally resets the raw format through
hantro_reset_raw_fmt(). That helper sets ctx->vpu_src_fmt to the default
raw format before hantro_set_fmt_out() refuses the change with -EBUSY
(the OUTPUT queue is busy). hantro_set_fmt_cap() ignores that error, so
the ioctl succeeds but leaves the context inconsistent: ctx->src_fmt
still describes the negotiated raw format (e.g. NM12, two planes) while
ctx->vpu_src_fmt describes the default one (YM12, three planes).

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

The raw format has been reset under allocated OUTPUT buffers since the
encoder was added. Since commit 14b4bd01f8e5 ("media: verisilicon:
Additional fix for the crash when opening the driver") only the
descriptor is reset, which gives the mismatch described above.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Fixes: 14b4bd01f8e5 ("media: verisilicon: Additional fix for the crash when opening the driver")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 33 +++++++++++++++++++-----
 1 file changed, 26 insertions(+), 7 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 11bce0cdf4b3..a40abe2c459f 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -471,7 +471,7 @@ hantro_reset_encoded_fmt(struct hantro_ctx *ctx)
 int
 hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 {
-	const struct hantro_fmt *raw_vpu_fmt;
+	const struct hantro_fmt *raw_vpu_fmt, *old_vpu_src_fmt = NULL;
 	struct v4l2_pix_format_mplane raw_fmt, *encoded_fmt;
 	int ret;
 
@@ -481,6 +481,7 @@ hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 
 	if (ctx->is_encoder) {
 		encoded_fmt = &ctx->dst_fmt;
+		old_vpu_src_fmt = ctx->vpu_src_fmt;
 		ctx->vpu_src_fmt = raw_vpu_fmt;
 	} else {
 		encoded_fmt = &ctx->src_fmt;
@@ -497,6 +498,12 @@ hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
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
@@ -643,6 +650,7 @@ static int hantro_set_fmt_out(struct hantro_ctx *ctx,
 static int hantro_set_fmt_cap(struct hantro_ctx *ctx,
 			      struct v4l2_pix_format_mplane *pix_mp)
 {
+	bool reset_raw_fmt = ctx->is_encoder;
 	int ret;
 
 	if (ctx->is_encoder) {
@@ -661,11 +669,22 @@ static int hantro_set_fmt_cap(struct hantro_ctx *ctx,
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
@@ -687,7 +706,7 @@ static int hantro_set_fmt_cap(struct hantro_ctx *ctx,
 	 * Note that hantro_reset_raw_fmt() also propagates size
 	 * changes to the raw format.
 	 */
-	if (ctx->is_encoder)
+	if (reset_raw_fmt)
 		hantro_reset_raw_fmt(ctx, HANTRO_DEFAULT_BIT_DEPTH, HANTRO_AUTO_POSTPROC);
 
 	/* Colorimetry information are always propagated. */

-- 
2.55.0

