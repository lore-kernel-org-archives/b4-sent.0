From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 00:14:12 +0000
Subject: [PATCH 1/4] media: verisilicon: Size the VP8 segment map for the
 largest frame
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-hantro-fixes-v1-1-abb78264801e@gmail.com>
References: <20261114-hantro-fixes-v1-0-abb78264801e@gmail.com>
In-Reply-To: <20261114-hantro-fixes-v1-0-abb78264801e@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615252; l=1568;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=uf0y3QXiqPaWDkwu0IT1uHWdZkMxGVfJurXyC9ak0Fo=;
 b=36HLcA/Lv1TOaerShkK/mv3DJsPckfFXASIgVkUHIXZygIv9/3DMuaI2P0/PHsSvjuRVyEd9J
 uK+fK0M6wkDCRnXRq1PYfmzz0EeZnilnqU2FSExRAyHTnw4/SlQSNhs
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The segment map is allocated at STREAMON for the CAPTURE format of that
time, but the format can grow while streaming, and the decoder writes
2 bits per macroblock of the new size. The map of a small format is one
page, which a frame of more than 16384 macroblocks (3840x2160, for
example) overruns.

Size it for the largest frame the variant decodes, as VP9 does.

Found by Sashiko in its review of hantro-dec-size-check v1.

Fixes: bbd267daf4fc ("media: verisilicon: vp9: Allow to change resolution while streaming")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_vp8.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_vp8.c b/drivers/media/platform/verisilicon/hantro_vp8.c
index 381bc1d3bfda..12907f000a92 100644
--- a/drivers/media/platform/verisilicon/hantro_vp8.c
+++ b/drivers/media/platform/verisilicon/hantro_vp8.c
@@ -150,9 +150,9 @@ int hantro_vp8_dec_init(struct hantro_ctx *ctx)
 	size_t segment_map_size;
 	int ret;
 
-	/* segment map table size calculation */
-	mb_width = DIV_ROUND_UP(ctx->dst_fmt.width, 16);
-	mb_height = DIV_ROUND_UP(ctx->dst_fmt.height, 16);
+	/* The format can grow while streaming: size for the largest frame. */
+	mb_width = DIV_ROUND_UP(ctx->vpu_src_fmt->frmsize.max_width, 16);
+	mb_height = DIV_ROUND_UP(ctx->vpu_src_fmt->frmsize.max_height, 16);
 	segment_map_size = round_up(DIV_ROUND_UP(mb_width * mb_height, 4), 64);
 
 	/*

-- 
2.55.0

