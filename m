From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 00:14:14 +0000
Subject: [PATCH 3/4] media: verisilicon: Keep the CAPTURE format at the
 stream's bit depth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-hantro-fixes-v1-3-abb78264801e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615252; l=1438;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=mXsqYy0PJIO8RW/ep6ozTJeepcxK3PGTSINO9ycmhwE=;
 b=tLpy5tv59U2Ro7kaItdF8i3ov9qaV21o4xMBS8B4whtF/nSccwrZClo6yLBRnU7Z8mpsg6ps7
 q0YdIYvsTOXC+AOk/OR0fTbBlil3Pm2m1kffIT2kx0hEsZbTxmuxnj8
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ENUM_FMT on the CAPTURE queue of a decoder lists only the formats that
match the bit depth of the stream, but S_FMT and TRY_FMT accept any of
them, so userspace can select an 8-bit format for a 10-bit stream and
the decoder writes 10-bit pictures into buffers sized for 8 bits.

Replace a format of the wrong depth with the default one for the depth,
as for an unknown format.

Found by Sashiko in its review of hantro-dec-size-check v1.

Fixes: 8d03c2ab881b ("media: hantro: Support format filtering by depth")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 2baab4cf3bbf..362fbc747eea 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -342,6 +342,14 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 		pix_mp->pixelformat = fmt->fourcc;
 	}
 
+	if (!coded && !ctx->is_encoder &&
+	    !hantro_check_depth_match(fmt, ctx->bit_depth)) {
+		fmt = hantro_get_default_fmt(ctx, false, ctx->bit_depth, ctx->need_postproc);
+		if (!fmt)
+			return -EINVAL;
+		pix_mp->pixelformat = fmt->fourcc;
+	}
+
 	if (coded) {
 		pix_mp->num_planes = 1;
 		vpu_fmt = fmt;

-- 
2.55.0

