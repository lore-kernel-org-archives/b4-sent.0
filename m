From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:08:13 +0000
Subject: [PATCH RFC 11/12] media: rockchip: rkvenc: Offer VBR for H.264
 encoding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvenc-v1-11-ea8b47122d8c@gmail.com>
References: <20261110-rkvenc-v1-0-ea8b47122d8c@gmail.com>
In-Reply-To: <20261110-rkvenc-v1-0-ea8b47122d8c@gmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Kocialkowski <paulk@sys-base.io>, 
 =?utf-8?q?Sven_P=C3=BCschel?= <s.pueschel@pengutronix.de>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Detlev Casanova <detlev.casanova@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Jiaxing Hu <gahing@gahingwoo.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305283; l=2309;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=JF9FEhr+Fnv76x4udoa/NyLN+ajs26dykYgNbWUENQo=;
 b=RzAbjJ74L7b+RRhiG7UT37yP7BGoU6GeGywkhjOgqEOVXxXNrH0bqsfUP8SikAg1F4XkcPxx5
 x5LRkXw7TtiA4hD1pDWP1uz5bWPWEnEWOQvoUHWA2WuafXj4OG9P3wg
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H.264 encode core has a variable bitrate mode now. Offer it in
V4L2_CID_MPEG_VIDEO_BITRATE_MODE and add V4L2_CID_MPEG_VIDEO_BITRATE_PEAK,
which the core reads for it (default 20 Mbit/s, twice the default
bitrate), and hand the size target of the variable bitrate pictures to the
hardware row rate control as for constant bitrate.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c
index fcb8c070ab30..313c33038670 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c
@@ -381,11 +381,13 @@ static int rkvenc_h264_run(struct rkvenc_ctx *ctx, struct rkvenc_core *core,
 	vepu580_setup_h264_tuning(ctx->dev, core, intra);
 
 	/*
-	 * In CBR mode the frame size target of the rate control is handed to
-	 * the hardware row rate control, which adapts the QP of each
+	 * In CBR and VBR mode the frame size target of the rate control is
+	 * handed to the hardware row rate control, which adapts the QP of each
 	 * macroblock row by up to the row_rc_qp_range parameter.
 	 */
-	h264->hw_rc = rc->mode && rc->mode->type == V4L2_H264_ENC_RC_TYPE_CBR &&
+	h264->hw_rc = rc->mode &&
+		      (rc->mode->type == V4L2_H264_ENC_RC_TYPE_CBR ||
+		       rc->mode->type == V4L2_H264_ENC_RC_TYPE_VBR) &&
 		      READ_ONCE(rkvenc_row_rc_qp_range);
 	if (h264->hw_rc)
 		vepu580_setup_row_rc(core, &vepu580_h264_row_rc, rc->qp,
@@ -466,12 +468,15 @@ static const struct v4l2_ctrl_config rkvenc_h264_ctrl_cfgs[] = {
 		.min = V4L2_MPEG_VIDEO_BITRATE_MODE_VBR,
 		.max = V4L2_MPEG_VIDEO_BITRATE_MODE_CQ,
 		.def = V4L2_MPEG_VIDEO_BITRATE_MODE_CBR,
-		.menu_skip_mask = BIT(V4L2_MPEG_VIDEO_BITRATE_MODE_VBR),
 	},
 	{
 		.id = V4L2_CID_MPEG_VIDEO_BITRATE,
 		.min = 10000, .max = 200000000, .step = 1, .def = 10000000,
 	},
+	{
+		.id = V4L2_CID_MPEG_VIDEO_BITRATE_PEAK,
+		.min = 10000, .max = 200000000, .step = 1, .def = 20000000,
+	},
 	{
 		.id = V4L2_CID_MPEG_VIDEO_CONSTANT_QUALITY,
 		.min = 1, .max = 100, .step = 1, .def = 50,

-- 
2.55.0

