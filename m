From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:31:23 +0000
Subject: [PATCH v2 1/7] media: verisilicon: Keep the encoder CAPTURE format
 while buffers exist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hantro-jpeg-enc-fixes-v2-1-de03e643c75d@gmail.com>
References: <20261112-hantro-jpeg-enc-fixes-v2-0-de03e643c75d@gmail.com>
In-Reply-To: <20261112-hantro-jpeg-enc-fixes-v2-0-de03e643c75d@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472282; l=1571;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=7zDhcZU0lTpApx1EUzAD0IAc3hAGo9Ri1nYbxunoybc=;
 b=VaOagJtxtLbJjMIi0AjpaEOh/LVDBVpBUdjPoVus+uiAlo12MT+Je3MwbMPDvcK8be2lsntXj
 tamKKUagZw+D59aJB9F/PbI3io6c0VCMIF/IBnr2GKKHPmUkYRE7o3i
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit bbd267daf4fc ("media: verisilicon: vp9: Allow to change
resolution while streaming") dropped the busy check of the CAPTURE queue
in hantro_set_fmt_cap() to let the decoder change resolutions. On the
encoder, CAPTURE is the coded queue, and its format can now be changed
while buffers are allocated, prepared or queued: the new sizeimage, and
the size of the OUTPUT format reset along with it, no longer match the
buffers.

Return -EBUSY again for the encoder when the CAPTURE queue is busy, as
before that commit.

Fixes: bbd267daf4fc ("media: verisilicon: vp9: Allow to change resolution while streaming")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 83af9fa1ce94..d033fe0ecef6 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -596,7 +596,13 @@ static int hantro_set_fmt_cap(struct hantro_ctx *ctx,
 	int ret;
 
 	if (ctx->is_encoder) {
-		struct vb2_queue *peer_vq;
+		struct vb2_queue *vq, *peer_vq;
+
+		/* The CAPTURE buffers are sized for the current coded format. */
+		vq = v4l2_m2m_get_vq(ctx->fh.m2m_ctx,
+				     V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE);
+		if (vb2_is_busy(vq))
+			return -EBUSY;
 
 		/*
 		 * Since format change on the CAPTURE queue will reset

-- 
2.55.0

