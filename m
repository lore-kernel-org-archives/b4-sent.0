From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 00:14:15 +0000
Subject: [PATCH 4/4] media: verisilicon: Set the bit depth again when its
 control is rewritten
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-hantro-fixes-v1-4-abb78264801e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615252; l=3003;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=g1FKZCeiFkbp6h/EOPblVSfvHIN9lybSdPAZ2FY8L+U=;
 b=XtEqFv07p6afEIhLvhgVrMIRR/y2skjNRqfE0Ws4C+M2qg8OS812JKjgaRNebETxXcT5KQDj3
 HfHLsUAESK+DH2MKcgwHY6jkvcthvi9BFAilADw8gmFmIhat9Y4tKkp
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S_FMT on the OUTPUT queue resets the CAPTURE format to 8 bits, but the
HEVC SPS, VP9 frame and AV1 sequence controls keep their 10-bit value.
Writing the same value again doesn't call s_ctrl, so the CAPTURE format
stays at 8 bits while the decoder writes 10-bit pictures. The same holds
for the AV1 film grain flag.

Mark these controls EXECUTE_ON_WRITE. Every write of them then sends a
V4L2_EVENT_CTRL value change, and VIDIOC_QUERY_EXT_CTRL shows the flag.

Found by Sashiko in its review of hantro-dec-size-check v1.

Fixes: 3c32d94c9c52 ("media: verisilicon: Do not change context bit depth before validating the format")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_drv.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..dffba6c43a0f 100644
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
@@ -607,6 +611,12 @@ static int hantro_ctrls_setup(struct hantro_dev *vpu,
 			v4l2_ctrl_handler_free(&ctx->ctrl_handler);
 			return ctx->ctrl_handler.error;
 		}
+
+		/*
+		 * Standard controls get their flags from the core. S_FMT on
+		 * OUTPUT resets the bit depth: set it again on every write.
+		 */
+		ctrl->flags |= controls[i].cfg.flags & V4L2_CTRL_FLAG_EXECUTE_ON_WRITE;
 	}
 	return v4l2_ctrl_handler_setup(&ctx->ctrl_handler);
 }

-- 
2.55.0

