From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 17:00:53 +0000
Subject: [PATCH v3 1/5] media: verisilicon: Keep the encoder CAPTURE format
 while buffers exist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-hantro-jpeg-enc-fixes-v3-1-07357d84a64b@gmail.com>
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
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795712452; l=1271;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=rhVB/MQQBTXrMfV0wT+knKAvpmw8YXdorkxIRoc8kco=;
 b=QRkbjQEFZtsRyIsCY+XfpjOgKRWx3yh2lAg5TN2NUtiEbbyJRmPwR05LgXfUCqsWGmMHShTQu
 xjX+GWWfRuoAlWQwMMFqfrKzqfeWjmwsH0jleRRUOHPV+10JUZv8lsf
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit bbd267daf4fc ("media: verisilicon: vp9: Allow to change
resolution while streaming") dropped the CAPTURE busy check in
hantro_set_fmt_cap() for decoders. On the encoder, CAPTURE is the coded
queue, so its sizeimage can now change under allocated buffers. Restore
the check for the encoder.

Fixes: bbd267daf4fc ("media: verisilicon: vp9: Allow to change resolution while streaming")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 83af9fa1ce94..0d6d4f36d012 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -596,7 +596,12 @@ static int hantro_set_fmt_cap(struct hantro_ctx *ctx,
 	int ret;
 
 	if (ctx->is_encoder) {
-		struct vb2_queue *peer_vq;
+		struct vb2_queue *vq, *peer_vq;
+
+		vq = v4l2_m2m_get_vq(ctx->fh.m2m_ctx,
+				     V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE);
+		if (vb2_is_busy(vq))
+			return -EBUSY;
 
 		/*
 		 * Since format change on the CAPTURE queue will reset

-- 
2.55.0

