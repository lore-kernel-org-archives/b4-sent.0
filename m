From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 17:00:56 +0000
Subject: [PATCH v3 4/5] media: verisilicon: Restore the encoder raw format
 when its reset fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-hantro-jpeg-enc-fixes-v3-4-07357d84a64b@gmail.com>
References: <20261126-hantro-jpeg-enc-fixes-v3-0-07357d84a64b@gmail.com>
In-Reply-To: <20261126-hantro-jpeg-enc-fixes-v3-0-07357d84a64b@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795712452; l=1799;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=T4JxJzrpJHZ7bcC2wFn6o1S3mEh6CI2vghqlDg9OD7U=;
 b=ryypf3/xIzVrNPoN9rN4vu2bdfqVXd85Gr/I4tuCQaAXlLpV/0aPDjaYFtCEM9drV8h8hlwra
 BGr2IFX8va8AYYWgYws9LjNpF5bptF6PSpeZy7D0EOagqZ5fytNFpJb
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hantro_reset_raw_fmt() sets ctx->vpu_src_fmt to the default raw format
before hantro_set_fmt_out(), which fails while OUTPUT buffers exist. A
CAPTURE S_FMT then leaves NM12 in ctx->src_fmt and YM12 in
ctx->vpu_src_fmt, and the next job reads the third plane from IOVA 0
(v4l2-ctl --stream-mmap). Restore ctx->vpu_src_fmt on failure.

Fixes: 14b4bd01f8e5 ("media: verisilicon: Additional fix for the crash when opening the driver")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index b91c0ef9b6a3..69e1ef985bff 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -455,7 +455,7 @@ hantro_reset_encoded_fmt(struct hantro_ctx *ctx)
 int
 hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 {
-	const struct hantro_fmt *raw_vpu_fmt;
+	const struct hantro_fmt *raw_vpu_fmt, *old_vpu_src_fmt = NULL;
 	struct v4l2_pix_format_mplane raw_fmt, *encoded_fmt;
 	int ret;
 
@@ -465,6 +465,7 @@ hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 
 	if (ctx->is_encoder) {
 		encoded_fmt = &ctx->dst_fmt;
+		old_vpu_src_fmt = ctx->vpu_src_fmt;
 		ctx->vpu_src_fmt = raw_vpu_fmt;
 	} else {
 		encoded_fmt = &ctx->src_fmt;
@@ -481,6 +482,8 @@ hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 	if (!ret) {
 		ctx->bit_depth = bit_depth;
 		ctx->need_postproc = need_postproc;
+	} else if (ctx->is_encoder) {
+		ctx->vpu_src_fmt = old_vpu_src_fmt;
 	}
 
 	return ret;

-- 
2.55.0

