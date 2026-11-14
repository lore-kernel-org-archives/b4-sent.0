From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 00:14:13 +0000
Subject: [PATCH 2/4] media: verisilicon: Set need_postproc before resetting
 the CAPTURE format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-hantro-fixes-v1-2-abb78264801e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615252; l=2134;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=K/OBfhFLZqelp4gN8EoRryPycBadFZf1ehuMruueJ3I=;
 b=K1Tm3Mg18Zf0xKACgdOObktcPQmZDw2LPUWDZZU4RmQjvmOo0nhAqHCKKwf2Cmh9SwV1NuYuw
 WHOKYE30lRXCA2c0N2BNt/yRi8N/w0JFlNf3RaOA43xllqFKr6SuasZ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hantro_reset_raw_fmt() stores need_postproc only after
hantro_set_fmt_cap(), so hantro_try_fmt() sizes the new format with the
old value. When an AV1 stream drops film grain, the post-processor goes
away but the CAPTURE format still lacks the motion vector area the
decoder then writes after the picture.

Set the bit depth and need_postproc first and restore them on error.
The next patch needs the bit depth set there too.

Found by Sashiko in its review of hantro-dec-size-check v1.

Fixes: 80c7373a456e ("media: verisilicon: Conditionally ignore native formats")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 83af9fa1ce94..2baab4cf3bbf 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -449,6 +449,8 @@ hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 {
 	const struct hantro_fmt *raw_vpu_fmt;
 	struct v4l2_pix_format_mplane raw_fmt, *encoded_fmt;
+	bool old_need_postproc = ctx->need_postproc;
+	int old_bit_depth = ctx->bit_depth;
 	int ret;
 
 	raw_vpu_fmt = hantro_get_default_fmt(ctx, false, bit_depth, need_postproc);
@@ -465,14 +467,18 @@ hantro_reset_raw_fmt(struct hantro_ctx *ctx, int bit_depth, bool need_postproc)
 	hantro_reset_fmt(&raw_fmt, raw_vpu_fmt);
 	raw_fmt.width = encoded_fmt->width;
 	raw_fmt.height = encoded_fmt->height;
+
+	/* hantro_try_fmt() uses these. */
+	ctx->bit_depth = bit_depth;
+	ctx->need_postproc = need_postproc;
 	if (ctx->is_encoder)
 		ret = hantro_set_fmt_out(ctx, &raw_fmt, need_postproc);
 	else
 		ret = hantro_set_fmt_cap(ctx, &raw_fmt);
 
-	if (!ret) {
-		ctx->bit_depth = bit_depth;
-		ctx->need_postproc = need_postproc;
+	if (ret) {
+		ctx->bit_depth = old_bit_depth;
+		ctx->need_postproc = old_need_postproc;
 	}
 
 	return ret;

-- 
2.55.0

