From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:39:48 +0000
Subject: [PATCH v2 3/4] media: verisilicon: Keep the CAPTURE format at the
 stream's bit depth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-hantro-fixes-v2-3-bfecfb07a3e7@gmail.com>
References: <20261115-hantro-fixes-v2-0-bfecfb07a3e7@gmail.com>
In-Reply-To: <20261115-hantro-fixes-v2-0-bfecfb07a3e7@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794731985; l=1385;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=yJzxOk5vcQF9E3Uzonthp07livyt1mzW4G+NIv6HiPY=;
 b=mPY8kAs5S/pR9Ol5PTZS6E+Nb6sk3g4K5WVCpvAajwvWIsAYY+/t/nbHQZPQNxVGxO58fjQ9v
 o66M/JkxPwkA8ENXjWa5bMGLE2mJVVuoeAkuRnQW8K+ajtZGBS6XFcD
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S_FMT and TRY_FMT on the decoder CAPTURE queue accept formats ENUM_FMT
hides: an 8-bit format for a 10-bit stream, which the decoder overruns,
or a native format while the post-processor is needed. Replace such a
format with the stream's default one.

Fixes: 8d03c2ab881b ("media: hantro: Support format filtering by depth")
Fixes: 80c7373a456e ("media: verisilicon: Conditionally ignore native formats")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 5939fffc350d..450775664742 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -342,6 +342,15 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 		pix_mp->pixelformat = fmt->fourcc;
 	}
 
+	if (!coded && !ctx->is_encoder &&
+	    (!hantro_check_depth_match(fmt, ctx->bit_depth) ||
+	     (ctx->need_postproc && !fmt->postprocessed))) {
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

