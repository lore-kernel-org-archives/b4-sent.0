From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 17:00:55 +0000
Subject: [PATCH v3 3/5] media: verisilicon: Report fixed JPEG colorimetry
 on the encoder
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-hantro-jpeg-enc-fixes-v3-3-07357d84a64b@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795712452; l=1351;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=jQGwq2ezjyS5OLBIC3b8uIm11FWRMfbVW9fV1IdCb0w=;
 b=tXEbeaN9I4IMEXcW5M9uBtrdJN/78BRij3bVNmt+vhPG1Y8YDzU02itwWpfXoS77yLI3qnVC7
 h8ni9TI72ioBXwrC5F5TOvUG3Xr/Urp2ELusDrnmCcWyM+PARNHxnGn
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The JPEG encoder accepts any colorimetry and reports
V4L2_COLORSPACE_JPEG on the raw queue, which v4l2-compliance rejects:

  fail: v4l2-test-formats.cpp(892): fmt_raw.g_colorspace() != V4L2_COLORSPACE_SRGB

JPEG colorimetry is fixed and the hardware does not convert, so report
sRGB with full range BT.601 Y'CbCr on both queues.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 88b1cf66b713..b91c0ef9b6a3 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -396,6 +396,14 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 			pix_mp->width * pix_mp->height * fmt->max_depth;
 	}
 
+	if (ctx->is_encoder && vpu_fmt->codec_mode == HANTRO_MODE_JPEG_ENC) {
+		/* JPEG colorimetry is fixed; the hardware does not convert. */
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

