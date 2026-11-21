From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 21 Nov 2026 10:10:55 +0000
Subject: [PATCH v2 2/3] media: verisilicon: reject MPEG-1 controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-b4-cedrus-mpeg1-v2-2-95e4decf03fa@gmail.com>
References: <20261121-b4-cedrus-mpeg1-v2-0-95e4decf03fa@gmail.com>
In-Reply-To: <20261121-b4-cedrus-mpeg1-v2-0-95e4decf03fa@gmail.com>
To: Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Maxime Ripard <mripard@kernel.org>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: Jonas Karlman <jonas@kwiboo.se>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-staging@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, 
 =?utf-8?q?Christian_Stefan_K=C3=B6v=C3=A9r-Draxl?= <ckoever@outlook.de>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795255854; l=1859;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=FQStrbwGL4QdSNvEd7D9LYJAA2FvyeyUQoe74GUu02I=;
 b=ebfDy9i8ixnAvMHvwqGQgQzsroi7ROGjPvbLkfaHAC8Y0OJuixh3Xqnqs0S+QnBtvVKPCd36h
 M8qLiINqHZ/AwFnvbY067aC+w9u1xTsiLqiR9EiSpB609O7zJcwOzfs
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver decodes everything in MPEG-2 mode. Reject
V4L2_MPEG2_SEQ_FLAG_MPEG1, the full pel flags and D-pictures, which it
would otherwise decode as MPEG-2. Compile tested only.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_drv.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..c910a69e8e3c 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -264,6 +264,16 @@ static int hantro_try_ctrl(struct v4l2_ctrl *ctrl)
 		if (sps->bit_depth_luma_minus8 != 0 && sps->bit_depth_luma_minus8 != 2)
 			/* Only 8-bit and 10-bit are supported */
 			return -EINVAL;
+	} else if (ctrl->id == V4L2_CID_STATELESS_MPEG2_SEQUENCE) {
+		if (ctrl->p_new.p_mpeg2_sequence->flags & V4L2_MPEG2_SEQ_FLAG_MPEG1)
+			return -EINVAL;
+	} else if (ctrl->id == V4L2_CID_STATELESS_MPEG2_PICTURE) {
+		const struct v4l2_ctrl_mpeg2_picture *pic = ctrl->p_new.p_mpeg2_picture;
+
+		if (pic->picture_coding_type == V4L2_MPEG2_PIC_CODING_TYPE_D ||
+		    pic->flags & (V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD |
+				  V4L2_MPEG2_PIC_FLAG_FULL_PEL_BACKWARD))
+			return -EINVAL;
 	} else if (ctrl->id == V4L2_CID_STATELESS_VP9_FRAME) {
 		const struct v4l2_ctrl_vp9_frame *dec_params = ctrl->p_new.p_vp9_frame;
 
@@ -435,11 +445,13 @@ static const struct hantro_ctrl controls[] = {
 		.codec = HANTRO_MPEG2_DECODER,
 		.cfg = {
 			.id = V4L2_CID_STATELESS_MPEG2_SEQUENCE,
+			.ops = &hantro_ctrl_ops,
 		},
 	}, {
 		.codec = HANTRO_MPEG2_DECODER,
 		.cfg = {
 			.id = V4L2_CID_STATELESS_MPEG2_PICTURE,
+			.ops = &hantro_ctrl_ops,
 		},
 	}, {
 		.codec = HANTRO_MPEG2_DECODER,

-- 
2.55.0

