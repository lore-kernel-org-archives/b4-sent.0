From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 21 Nov 2026 10:10:56 +0000
Subject: [PATCH v2 3/3] media: cedrus: mpeg2: decode MPEG-1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-b4-cedrus-mpeg1-v2-3-95e4decf03fa@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795255854; l=3799;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ENgCu+1MFMZtAJZUuEt0T+q6P9F/T+1zchxBMroIOiw=;
 b=i5C3tVNnGqk1IrEyGSmXdZ2XEwdhU7cGA82UV4f11t7RXP0HNEAvQEtdnKwP2DzacRy5m35Pa
 xZgEqCOj6eQAg8Am49A4qiLCCykWgl3+ChPpmm6D961m0tS721fJQu5
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The engine has an MPEG-1 mode, selected with the MPEG-1 decoder type in
the trigger register, and takes the full pel flags and the picture
coding type (D-pictures included) in the picture header register.

Select the MPEG-1 mode when V4L2_MPEG2_SEQ_FLAG_MPEG1 is set (every
variant with the MPEG-2 decoder; tested on H616 only). A job fails if
an MPEG-1 sequence has field pictures, or an MPEG-2 one has D-pictures
or full pel flags.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/staging/media/sunxi/cedrus/cedrus.h       |  3 +++
 drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c | 27 +++++++++++++++++++----
 2 files changed, 26 insertions(+), 4 deletions(-)

diff --git a/drivers/staging/media/sunxi/cedrus/cedrus.h b/drivers/staging/media/sunxi/cedrus/cedrus.h
index c4b1217c14b6..9c35078ef02f 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus.h
+++ b/drivers/staging/media/sunxi/cedrus/cedrus.h
@@ -144,6 +144,9 @@ struct cedrus_ctx {
 			void		*entry_points_buf;
 			dma_addr_t	entry_points_buf_addr;
 		} h265;
+		struct {
+			bool		mpeg1;
+		} mpeg2;
 		struct {
 			unsigned int	last_frame_p_type;
 			unsigned int	last_filter_type;
diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c b/drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c
index 10e98f08aafc..557e3d029318 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c
@@ -48,6 +48,17 @@ static void cedrus_mpeg2_irq_disable(struct cedrus_ctx *ctx)
 	cedrus_write(dev, VE_DEC_MPEG_CTRL, reg);
 }
 
+static bool cedrus_mpeg2_pic_valid(const struct v4l2_ctrl_mpeg2_sequence *seq,
+				   const struct v4l2_ctrl_mpeg2_picture *pic)
+{
+	if (seq->flags & V4L2_MPEG2_SEQ_FLAG_MPEG1)
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
@@ -63,6 +74,11 @@ static int cedrus_mpeg2_setup(struct cedrus_ctx *ctx, struct cedrus_run *run)
 	seq = run->mpeg2.sequence;
 	pic = run->mpeg2.picture;
 
+	if (!cedrus_mpeg2_pic_valid(seq, pic))
+		return -EINVAL;
+
+	ctx->codec.mpeg2.mpeg1 = seq->flags & V4L2_MPEG2_SEQ_FLAG_MPEG1;
+
 	quantisation = run->mpeg2.quantisation;
 
 	/* Activate MPEG engine. */
@@ -101,8 +117,10 @@ static int cedrus_mpeg2_setup(struct cedrus_ctx *ctx, struct cedrus_run *run)
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
 
@@ -183,8 +201,9 @@ static void cedrus_mpeg2_trigger(struct cedrus_ctx *ctx)
 	u32 reg;
 
 	/* Trigger MPEG engine. */
-	reg = VE_DEC_MPEG_TRIGGER_HW_MPEG_VLD | VE_DEC_MPEG_TRIGGER_MPEG2 |
-	      VE_DEC_MPEG_TRIGGER_MB_BOUNDARY;
+	reg = VE_DEC_MPEG_TRIGGER_HW_MPEG_VLD | VE_DEC_MPEG_TRIGGER_MB_BOUNDARY;
+	reg |= ctx->codec.mpeg2.mpeg1 ? VE_DEC_MPEG_TRIGGER_MPEG1 :
+					    VE_DEC_MPEG_TRIGGER_MPEG2;
 
 	cedrus_write(dev, VE_DEC_MPEG_TRIGGER, reg);
 }

-- 
2.55.0

