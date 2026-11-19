From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 10:07:58 +0000
Subject: [PATCH] media: verisilicon: Limit the i.MX8MM G1 decoder to 1920
 pixel wide pictures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-hantro-imx8mm-vp8-v1-1-835dd9b5382c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0Q5EMBCF4VeRuTaJ6Qrtvoq4sEwZSZEWkYh3V
 +vyO8n5TwjshQN8kxM87xJkniIoTaAdmqlnlC4aVKYKIjIYx9XPKO7QzuG+aFQfy7q0ZLrcQPw
 tnq0c/2ZVvw7bb+R2fUJwXTfIrYPTdQAAAA==
X-Change-ID: 20261119-hantro-imx8mm-vp8-23fe87f19d49
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Hans Verkuil <hverkuil@kernel.org>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Adam Ford <aford173@gmail.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795082877; l=3675;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ttabhbq6HX9n6LkD9lfDtGqujWqiEJqLK1Woo7amLA4=;
 b=+G5/+KW2AA45IYVMYGsAK031f3/0CCyalGQ+9VZaUy/I1qNSEut0kIdVEsvlPABpwv/SV97aN
 by0MkGaTorGCX58eERoTDkfsA1sJAYMPiaiCNQwfVdOyBtXjalc1cP+
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The i.MX8MM G1 uses the i.MX8MQ format table, which allows H.264, VP8
and NV12 up to 3840x2160. The i.MX 8M Mini data sheet rates the decoder
at 1080p60, and NXP's hantro_v4l2 driver offers a decoder of that size
1920 pixels wide and up to 4096 high.

Give it its own table with these formats limited to 1920 pixels wide.
Heights are kept so that portrait pictures such as 1080x1920 are still
accepted, as in NXP's driver.

Fixes: cf1abc501a5c ("media: hantro: Add support for i.MX8MM Hantro-G1")
Reported-by: Nicolas Dufresne <nicolas.dufresne@collabora.com>
Closes: https://lore.kernel.org/r/f041c5d87698ab3be8283ecc71ead0679327238e.camel@collabora.com
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Not tested on hardware: I have no i.MX8MM board, so the limit is from the
data sheet and NXP's driver, not from the decoder's configuration
register. Build-tested only (W=1 arm64). The i.MX8MQ table is unchanged:
NXP's driver gives VP8 the same 4096x4096 as H.264 there.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.
---
 drivers/media/platform/verisilicon/imx8m_vpu_hw.c | 58 ++++++++++++++++++++++-
 1 file changed, 56 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/verisilicon/imx8m_vpu_hw.c b/drivers/media/platform/verisilicon/imx8m_vpu_hw.c
index fa4224de4b99..805c57a4adcb 100644
--- a/drivers/media/platform/verisilicon/imx8m_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/imx8m_vpu_hw.c
@@ -148,6 +148,60 @@ static const struct hantro_fmt imx8m_vpu_dec_fmts[] = {
 	},
 };
 
+static const struct hantro_fmt imx8mm_vpu_g1_dec_fmts[] = {
+	{
+		.fourcc = V4L2_PIX_FMT_NV12,
+		.codec_mode = HANTRO_MODE_NONE,
+		.frmsize = {
+			.min_width = FMT_MIN_WIDTH,
+			.max_width = FMT_FHD_WIDTH,
+			.step_width = MB_DIM,
+			.min_height = FMT_MIN_HEIGHT,
+			.max_height = FMT_UHD_HEIGHT,
+			.step_height = MB_DIM,
+		},
+	},
+	{
+		.fourcc = V4L2_PIX_FMT_MPEG2_SLICE,
+		.codec_mode = HANTRO_MODE_MPEG2_DEC,
+		.max_depth = 2,
+		.frmsize = {
+			.min_width = FMT_MIN_WIDTH,
+			.max_width = FMT_FHD_WIDTH,
+			.step_width = MB_DIM,
+			.min_height = FMT_MIN_HEIGHT,
+			.max_height = FMT_FHD_HEIGHT,
+			.step_height = MB_DIM,
+		},
+	},
+	{
+		.fourcc = V4L2_PIX_FMT_VP8_FRAME,
+		.codec_mode = HANTRO_MODE_VP8_DEC,
+		.max_depth = 2,
+		.frmsize = {
+			.min_width = FMT_MIN_WIDTH,
+			.max_width = FMT_FHD_WIDTH,
+			.step_width = MB_DIM,
+			.min_height = FMT_MIN_HEIGHT,
+			.max_height = FMT_UHD_HEIGHT,
+			.step_height = MB_DIM,
+		},
+	},
+	{
+		.fourcc = V4L2_PIX_FMT_H264_SLICE,
+		.codec_mode = HANTRO_MODE_H264_DEC,
+		.max_depth = 2,
+		.frmsize = {
+			.min_width = FMT_MIN_WIDTH,
+			.max_width = FMT_FHD_WIDTH,
+			.step_width = MB_DIM,
+			.min_height = FMT_MIN_HEIGHT,
+			.max_height = FMT_UHD_HEIGHT,
+			.step_height = MB_DIM,
+		},
+	},
+};
+
 static const struct hantro_fmt imx8m_vpu_g2_postproc_fmts[] = {
 	{
 		.fourcc = V4L2_PIX_FMT_NV12,
@@ -382,8 +436,8 @@ const struct hantro_variant imx8mq_vpu_g2_variant = {
 };
 
 const struct hantro_variant imx8mm_vpu_g1_variant = {
-	.dec_fmts = imx8m_vpu_dec_fmts,
-	.num_dec_fmts = ARRAY_SIZE(imx8m_vpu_dec_fmts),
+	.dec_fmts = imx8mm_vpu_g1_dec_fmts,
+	.num_dec_fmts = ARRAY_SIZE(imx8mm_vpu_g1_dec_fmts),
 	.codec = HANTRO_MPEG2_DECODER | HANTRO_VP8_DECODER |
 		 HANTRO_H264_DECODER,
 	.codec_ops = imx8mq_vpu_g1_codec_ops,

---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261119-hantro-imx8mm-vp8-23fe87f19d49

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

