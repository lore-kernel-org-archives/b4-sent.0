From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 17:00:54 +0000
Subject: [PATCH v3 2/5] media: verisilicon: Keep the encoder coded size in
 sync with OUTPUT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-hantro-jpeg-enc-fixes-v3-2-07357d84a64b@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795712452; l=1236;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=n5bwyJSG49jkdtemL0KSh1+eA5aydhtKJOe/+pE2GYE=;
 b=NfLRhF66l70a82f9aVI0jgytzYgmcM0cedvnN1BdyhvfiTZZ8enGBRSy6G0WOqkP2S1ted/Id
 tIE6TxLkzHHClI43MKvJMIcHhEwyNhWcJuE8NM7clN1leLm4Bk4py6m
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Setting the OUTPUT format leaves the coded size at the 96x32 default,
so the JPEG header does not match the encoded frame. The OUTPUT S_FMT
resets the crop to the full frame: copy its size to the coded format.

Fixes: 953aaa1492c5 ("media: rockchip/vpu: Prepare things to support decoders")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 0d6d4f36d012..88b1cf66b713 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -561,6 +561,12 @@ static int hantro_set_fmt_out(struct hantro_ctx *ctx,
 	ctx->vpu_src_fmt = hantro_find_format(ctx, pix_mp->pixelformat);
 	ctx->src_fmt = *pix_mp;
 
+	/* Setting the OUTPUT format resets the encoder crop to the full frame. */
+	if (ctx->is_encoder) {
+		ctx->dst_fmt.width = pix_mp->width;
+		ctx->dst_fmt.height = pix_mp->height;
+	}
+
 	/*
 	 * Current raw format might have become invalid with newly
 	 * selected codec, so reset it to default just to be safe and

-- 
2.55.0

