From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:17:59 +0000
Subject: [PATCH 4/6] media: verisilicon: Report fixed JPEG colorimetry on
 the encoder
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-jpeg-enc-fixes-v1-4-fc4dc7e985d2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295075; l=2043;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Njpmt3ct0L9aPXSUlHIS0gp4XYUJhvc8SGbGxzWUYQo=;
 b=lmJZgJ7veqW9JDTDkJxb2RV+aFAksjw2y5DsqpJeTLf7LCxwNkX/+d6Z0mG2DpTnT2qNtU5BH
 0vkSeFaWXySClTXRgfWxaO6tKABqzcRSaD68e5XqweuPVSZT28paxks
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver reports V4L2_COLORSPACE_JPEG with default encoding,
quantization and transfer function on both queues, and lets the
application set any colorimetry, which is then copied to the other
queue. For the JPEG encoder this is wrong on the raw side:
V4L2_COLORSPACE_JPEG is only a shorthand for the colorimetry of the
JPEG data, and the raw frames should describe the actual samples. It
also makes v4l2-compliance fail on the encoder:

  fail: v4l2-test-formats.cpp(892): fmt_raw.g_colorspace() != V4L2_COLORSPACE_SRGB
  test VIDIOC_S_FMT: FAIL

The colorimetry of JPEG is fixed and the hardware doesn't convert the
samples. When the coded format is JPEG, report sRGB primaries and
transfer function with full range BT.601 Y'CbCr on both queues, as the
mediatek and imx JPEG encoders do, and ignore what the application
asks for. Other coded formats keep propagating the colorimetry set by
the application, which they signal in the bitstream.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 731182cde643..2761d37af7cd 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -406,6 +406,19 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 			*sizeimage = max_size;
 	}
 
+	if (ctx->is_encoder && vpu_fmt->codec_mode == HANTRO_MODE_JPEG_ENC) {
+		/*
+		 * The colorimetry of JPEG is fixed: full range BT.601
+		 * Y'CbCr with sRGB primaries and transfer function. The
+		 * hardware doesn't convert the samples, so the raw frames
+		 * must use it too.
+		 */
+		pix_mp->colorspace = V4L2_COLORSPACE_SRGB;
+		pix_mp->ycbcr_enc = V4L2_YCBCR_ENC_601;
+		pix_mp->xfer_func = V4L2_XFER_FUNC_SRGB;
+		pix_mp->quantization = V4L2_QUANTIZATION_FULL_RANGE;
+	}
+
 	return 0;
 }
 

-- 
2.55.0

