From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 16:34:53 +0000
Subject: [PATCH RFC 2/2] media: cedrus: mpeg2: decode MPEG-1 as
 V4L2_PIX_FMT_MPEG1_SLICE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-cedrus-mpeg1-v1-2-aa5ba1192822@gmail.com>
References: <20261119-b4-cedrus-mpeg1-v1-0-aa5ba1192822@gmail.com>
In-Reply-To: <20261119-b4-cedrus-mpeg1-v1-0-aa5ba1192822@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795106091; l=7907;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=4OAKGNj/fvmq8EYTd28gnpjS58JFKm9IwxTpeVBNv6Y=;
 b=v7c4QB6HYvoCijXa6CR58r6I2XrsRc8fvnD2VvUrhaOtDSTbc4FBqIYDsbUmvRirCtYZf5bvb
 kebyPf5NBO2C0QDcpgrEq34vXpJec2kk3XROo0eHjO399aA6cK8AFfN
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The engine has an MPEG-1 mode, selected with the MPEG-1 decoder type in
the trigger register, and takes the full pel flags and the picture
coding type (D-pictures included) in the picture header register.

Enumerate V4L2_PIX_FMT_MPEG1_SLICE on every variant with the MPEG-2
decoder (tested on H616 only), with the MPEG-2 limits, and select the
MPEG-1 mode from the coded format. try_ctrl accepts the MPEG-1 flag, the
full pel flags and D-pictures only with the MPEG-1 format. A job whose
sequence control does not match the coded format fails, as do field
pictures in MPEG-1 sequences.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/staging/media/sunxi/cedrus/cedrus.c       | 22 +++++++++++++
 drivers/staging/media/sunxi/cedrus/cedrus_dec.c   |  1 +
 drivers/staging/media/sunxi/cedrus/cedrus_hw.c    |  1 +
 drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c | 38 ++++++++++++++++++++---
 drivers/staging/media/sunxi/cedrus/cedrus_video.c |  7 +++++
 5 files changed, 65 insertions(+), 4 deletions(-)

diff --git a/drivers/staging/media/sunxi/cedrus/cedrus.c b/drivers/staging/media/sunxi/cedrus/cedrus.c
index c3331b4f3f02..60b296032a90 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus.c
@@ -77,6 +77,26 @@ static int cedrus_try_ctrl(struct v4l2_ctrl *ctrl)
 			ctx->bit_depth = bit_depth;
 			cedrus_reset_cap_format(ctx);
 		}
+	} else if (ctrl->id == V4L2_CID_STATELESS_MPEG2_SEQUENCE) {
+		const struct v4l2_ctrl_mpeg2_sequence *seq =
+			ctrl->p_new.p_mpeg2_sequence;
+		struct cedrus_ctx *ctx = container_of(ctrl->handler,
+						      struct cedrus_ctx, hdl);
+
+		if (seq->flags & V4L2_MPEG2_SEQ_FLAG_MPEG1 &&
+		    ctx->src_fmt.pixelformat != V4L2_PIX_FMT_MPEG1_SLICE)
+			return -EINVAL;
+	} else if (ctrl->id == V4L2_CID_STATELESS_MPEG2_PICTURE) {
+		const struct v4l2_ctrl_mpeg2_picture *pic =
+			ctrl->p_new.p_mpeg2_picture;
+		struct cedrus_ctx *ctx = container_of(ctrl->handler,
+						      struct cedrus_ctx, hdl);
+
+		if (ctx->src_fmt.pixelformat != V4L2_PIX_FMT_MPEG1_SLICE &&
+		    (pic->picture_coding_type == V4L2_MPEG2_PIC_CODING_TYPE_D ||
+		     pic->flags & (V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD |
+				   V4L2_MPEG2_PIC_FLAG_FULL_PEL_BACKWARD)))
+			return -EINVAL;
 	}
 
 	return 0;
@@ -90,12 +110,14 @@ static const struct cedrus_control cedrus_controls[] = {
 	{
 		.cfg = {
 			.id	= V4L2_CID_STATELESS_MPEG2_SEQUENCE,
+			.ops	= &cedrus_ctrl_ops,
 		},
 		.capabilities	= CEDRUS_CAPABILITY_MPEG2_DEC,
 	},
 	{
 		.cfg = {
 			.id	= V4L2_CID_STATELESS_MPEG2_PICTURE,
+			.ops	= &cedrus_ctrl_ops,
 		},
 		.capabilities	= CEDRUS_CAPABILITY_MPEG2_DEC,
 	},
diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_dec.c b/drivers/staging/media/sunxi/cedrus/cedrus_dec.c
index 9f8b0555b7dc..6657d6060c39 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_dec.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_dec.c
@@ -41,6 +41,7 @@ void cedrus_device_run(void *priv)
 
 	switch (ctx->src_fmt.pixelformat) {
 	case V4L2_PIX_FMT_MPEG2_SLICE:
+	case V4L2_PIX_FMT_MPEG1_SLICE:
 		run.mpeg2.sequence = cedrus_find_control_data(ctx,
 			V4L2_CID_STATELESS_MPEG2_SEQUENCE);
 		run.mpeg2.picture = cedrus_find_control_data(ctx,
diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_hw.c b/drivers/staging/media/sunxi/cedrus/cedrus_hw.c
index 444fb53878d1..fd3ee8f5e9a5 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_hw.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_hw.c
@@ -44,6 +44,7 @@ int cedrus_engine_enable(struct cedrus_ctx *ctx)
 
 	switch (ctx->src_fmt.pixelformat) {
 	case V4L2_PIX_FMT_MPEG2_SLICE:
+	case V4L2_PIX_FMT_MPEG1_SLICE:
 		reg |= VE_MODE_DEC_MPEG;
 		break;
 
diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c b/drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c
index 10e98f08aafc..18d91b9b1e4a 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c
@@ -48,6 +48,30 @@ static void cedrus_mpeg2_irq_disable(struct cedrus_ctx *ctx)
 	cedrus_write(dev, VE_DEC_MPEG_CTRL, reg);
 }
 
+static bool cedrus_mpeg2_is_mpeg1(struct cedrus_ctx *ctx)
+{
+	return ctx->src_fmt.pixelformat == V4L2_PIX_FMT_MPEG1_SLICE;
+}
+
+static bool
+cedrus_mpeg2_format_matches(struct cedrus_ctx *ctx,
+			    const struct v4l2_ctrl_mpeg2_sequence *seq,
+			    const struct v4l2_ctrl_mpeg2_picture *pic)
+{
+	bool mpeg1 = cedrus_mpeg2_is_mpeg1(ctx);
+
+	/* try_ctrl checked the controls against the format set at that time. */
+	if (mpeg1 != !!(seq->flags & V4L2_MPEG2_SEQ_FLAG_MPEG1))
+		return false;
+
+	if (mpeg1)
+		return pic->picture_structure == V4L2_MPEG2_PIC_FRAME;
+
+	return pic->picture_coding_type != V4L2_MPEG2_PIC_CODING_TYPE_D &&
+	       !(pic->flags & (V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD |
+			       V4L2_MPEG2_PIC_FLAG_FULL_PEL_BACKWARD));
+}
+
 static int cedrus_mpeg2_setup(struct cedrus_ctx *ctx, struct cedrus_run *run)
 {
 	const struct v4l2_ctrl_mpeg2_sequence *seq;
@@ -63,6 +87,9 @@ static int cedrus_mpeg2_setup(struct cedrus_ctx *ctx, struct cedrus_run *run)
 	seq = run->mpeg2.sequence;
 	pic = run->mpeg2.picture;
 
+	if (!cedrus_mpeg2_format_matches(ctx, seq, pic))
+		return -EINVAL;
+
 	quantisation = run->mpeg2.quantisation;
 
 	/* Activate MPEG engine. */
@@ -101,8 +128,10 @@ static int cedrus_mpeg2_setup(struct cedrus_ctx *ctx, struct cedrus_run *run)
 	reg |= VE_DEC_MPEG_MP12HDR_Q_SCALE_TYPE(pic->flags & V4L2_MPEG2_PIC_FLAG_Q_SCALE_TYPE);
 	reg |= VE_DEC_MPEG_MP12HDR_INTRA_VLC_FORMAT(pic->flags & V4L2_MPEG2_PIC_FLAG_INTRA_VLC);
 	reg |= VE_DEC_MPEG_MP12HDR_ALTERNATE_SCAN(pic->flags & V4L2_MPEG2_PIC_FLAG_ALT_SCAN);
-	reg |= VE_DEC_MPEG_MP12HDR_FULL_PEL_FORWARD_VECTOR(0);
-	reg |= VE_DEC_MPEG_MP12HDR_FULL_PEL_BACKWARD_VECTOR(0);
+	reg |= VE_DEC_MPEG_MP12HDR_FULL_PEL_FORWARD_VECTOR(pic->flags &
+				V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD);
+	reg |= VE_DEC_MPEG_MP12HDR_FULL_PEL_BACKWARD_VECTOR(pic->flags &
+				V4L2_MPEG2_PIC_FLAG_FULL_PEL_BACKWARD);
 
 	cedrus_write(dev, VE_DEC_MPEG_MP12HDR, reg);
 
@@ -183,8 +212,9 @@ static void cedrus_mpeg2_trigger(struct cedrus_ctx *ctx)
 	u32 reg;
 
 	/* Trigger MPEG engine. */
-	reg = VE_DEC_MPEG_TRIGGER_HW_MPEG_VLD | VE_DEC_MPEG_TRIGGER_MPEG2 |
-	      VE_DEC_MPEG_TRIGGER_MB_BOUNDARY;
+	reg = VE_DEC_MPEG_TRIGGER_HW_MPEG_VLD | VE_DEC_MPEG_TRIGGER_MB_BOUNDARY;
+	reg |= cedrus_mpeg2_is_mpeg1(ctx) ? VE_DEC_MPEG_TRIGGER_MPEG1 :
+					    VE_DEC_MPEG_TRIGGER_MPEG2;
 
 	cedrus_write(dev, VE_DEC_MPEG_TRIGGER, reg);
 }
diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_video.c b/drivers/staging/media/sunxi/cedrus/cedrus_video.c
index ad4ec3490775..8979693e9109 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_video.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_video.c
@@ -40,6 +40,11 @@ static struct cedrus_format cedrus_formats[] = {
 		.directions	= CEDRUS_DECODE_SRC,
 		.capabilities	= CEDRUS_CAPABILITY_MPEG2_DEC,
 	},
+	{
+		.pixelformat	= V4L2_PIX_FMT_MPEG1_SLICE,
+		.directions	= CEDRUS_DECODE_SRC,
+		.capabilities	= CEDRUS_CAPABILITY_MPEG2_DEC,
+	},
 	{
 		.pixelformat	= V4L2_PIX_FMT_H264_SLICE,
 		.directions	= CEDRUS_DECODE_SRC,
@@ -125,6 +130,7 @@ void cedrus_prepare_format(struct v4l2_pix_format *pix_fmt)
 
 	switch (pix_fmt->pixelformat) {
 	case V4L2_PIX_FMT_MPEG2_SLICE:
+	case V4L2_PIX_FMT_MPEG1_SLICE:
 	case V4L2_PIX_FMT_H264_SLICE:
 	case V4L2_PIX_FMT_HEVC_SLICE:
 	case V4L2_PIX_FMT_VP8_FRAME:
@@ -352,6 +358,7 @@ static int cedrus_s_fmt_vid_out_p(struct cedrus_ctx *ctx,
 
 	switch (ctx->src_fmt.pixelformat) {
 	case V4L2_PIX_FMT_MPEG2_SLICE:
+	case V4L2_PIX_FMT_MPEG1_SLICE:
 		ctx->current_codec = &cedrus_dec_ops_mpeg2;
 		break;
 	case V4L2_PIX_FMT_H264_SLICE:

-- 
2.55.0

