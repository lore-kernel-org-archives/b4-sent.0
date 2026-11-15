From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:39:49 +0000
Subject: [PATCH v2 4/4] media: verisilicon: Set the bit depth again when
 its control is rewritten
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-hantro-fixes-v2-4-bfecfb07a3e7@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794731985; l=2693;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=HWxB2YEEQC+V3ysP/l33g5scqDBlUMjlgqm8A4O3QvE=;
 b=6IQgd9D/SW76qY9HjFa29Wet/8gTddE+EEmFkx5EZ/ybrFIcq5PbxkpFRoUW8Zk6kq8g819nD
 uC1L5n9cMfQB2Y9RbbhF53rMWsZjScbPNRs7yOHajMko/fVGe+hiz+q
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S_FMT on OUTPUT resets the CAPTURE format to 8 bits, but rewriting an
unchanged 10-bit HEVC SPS, VP9 frame or AV1 sequence control skips
s_ctrl, so the format stays 8-bit. Mark these controls EXECUTE_ON_WRITE;
every write of them then also sends a V4L2_EVENT_CTRL value change.

Fixes: 3c32d94c9c52 ("media: verisilicon: Do not change context bit depth before validating the format")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_drv.c | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..248fb0e23a29 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -534,6 +534,7 @@ static const struct hantro_ctrl controls[] = {
 		.cfg = {
 			.id = V4L2_CID_STATELESS_HEVC_SPS,
 			.ops = &hantro_hevc_ctrl_ops,
+			.flags = V4L2_CTRL_FLAG_EXECUTE_ON_WRITE,
 		},
 	}, {
 		.codec = HANTRO_HEVC_DECODER,
@@ -555,6 +556,7 @@ static const struct hantro_ctrl controls[] = {
 		.cfg = {
 			.id = V4L2_CID_STATELESS_VP9_FRAME,
 			.ops = &hantro_vp9_ctrl_ops,
+			.flags = V4L2_CTRL_FLAG_EXECUTE_ON_WRITE,
 		},
 	}, {
 		.codec = HANTRO_VP9_DECODER,
@@ -577,6 +579,7 @@ static const struct hantro_ctrl controls[] = {
 		.cfg = {
 			.id = V4L2_CID_STATELESS_AV1_SEQUENCE,
 			.ops = &hantro_av1_ctrl_ops,
+			.flags = V4L2_CTRL_FLAG_EXECUTE_ON_WRITE,
 		},
 	}, {
 		.codec = HANTRO_AV1_DECODER,
@@ -591,6 +594,7 @@ static int hantro_ctrls_setup(struct hantro_dev *vpu,
 			      int allowed_codecs)
 {
 	int i, num_ctrls = ARRAY_SIZE(controls);
+	struct v4l2_ctrl *ctrl;
 
 	v4l2_ctrl_handler_init(&ctx->ctrl_handler, num_ctrls);
 
@@ -598,8 +602,8 @@ static int hantro_ctrls_setup(struct hantro_dev *vpu,
 		if (!(allowed_codecs & controls[i].codec))
 			continue;
 
-		v4l2_ctrl_new_custom(&ctx->ctrl_handler,
-				     &controls[i].cfg, NULL);
+		ctrl = v4l2_ctrl_new_custom(&ctx->ctrl_handler,
+					    &controls[i].cfg, NULL);
 		if (ctx->ctrl_handler.error) {
 			vpu_err("Adding control (%d) failed %d\n",
 				controls[i].cfg.id,
@@ -607,6 +611,10 @@ static int hantro_ctrls_setup(struct hantro_dev *vpu,
 			v4l2_ctrl_handler_free(&ctx->ctrl_handler);
 			return ctx->ctrl_handler.error;
 		}
+
+		/* v4l2_ctrl_new_custom() drops cfg.flags of standard controls. */
+		if (ctrl)
+			ctrl->flags |= controls[i].cfg.flags & V4L2_CTRL_FLAG_EXECUTE_ON_WRITE;
 	}
 	return v4l2_ctrl_handler_setup(&ctx->ctrl_handler);
 }

-- 
2.55.0

