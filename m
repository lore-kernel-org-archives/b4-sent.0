From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:08:11 +0000
Subject: [PATCH RFC 09/12] media: rockchip: rkvenc: Limit the QP of the
 HEVC I pictures to 15..51
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvenc-v1-9-ea8b47122d8c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305283; l=4902;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=nzRroLyTR3LHObcUYhvHk+s1nb5TLThp8XYLPeVz9WI=;
 b=l9yS0DDt5begQJkokDdkchuL6PbD2r0zXcU8kfYrOM/QTLy7cq8lOqkaCeRafnQOwf8MxJkEU
 UJGE4M3QSrRDorWFMp+xJFpx/fOAK7Ck2mD1M6LuBnpWm0+K1dxasfc
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As the Rockchip MPP library does by default for HEVC, keep the I pictures
of the frame rate control at QP 15 or above, while the P pictures may go
down to 10: add the I picture QP limit controls, with the defaults 15 and
51. The hardware row rate control of an I picture gets the same limits.

Move the QP setup of the picture to a function of its own.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../media/platform/rockchip/rkvenc/rkvenc-hevc.c   | 61 +++++++++++++++-------
 1 file changed, 41 insertions(+), 20 deletions(-)

diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
index 27006e393121..9baf76f7fc43 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
@@ -567,6 +567,43 @@ static void rkvenc_hevc_setup_tile(struct rkvenc_hevc_ctx *hevc,
 		   buf + (tile ? tile - 1 : 1) * hevc->tile_buf_size);
 }
 
+/*
+ * QP of the picture. In CBR mode the size target of the frame rate control
+ * is handed to the hardware CTU row rate control, which adapts the QP of
+ * each CTU row by up to the row_rc_qp_range parameter, within the QP limits
+ * of the picture type.
+ */
+static void rkvenc_hevc_setup_qp(struct rkvenc_hevc_ctx *hevc,
+				 struct rkvenc_core *core)
+{
+	struct v4l2_hevc_enc *enc = &hevc->enc;
+	const struct v4l2_hevc_enc_state *state = &enc->state_active;
+	bool intra = state->encode.slice_type == V4L2_HEVC_SLICE_TYPE_I;
+	unsigned int qp_range;
+	int qp_min, qp_max;
+
+	rkvenc_update(core, VEPU580_ENC_PIC, VEPU580_ENC_PIC_PIC_QP, 0);
+	rkvenc_update(core, VEPU580_HEVC_SYNT_SLI1, VEPU580_HEVC_SLI1_SLI_QP,
+		      FIELD_PREP(VEPU580_HEVC_SLI1_SLI_QP, enc->qp));
+
+	qp_range = min(READ_ONCE(rkvenc_row_rc_qp_range), 15U);
+	hevc->hw_rc = state->frame_rc_enable &&
+		      state->bitrate_mode == V4L2_MPEG_VIDEO_BITRATE_MODE_CBR &&
+		      qp_range;
+	if (!hevc->hw_rc) {
+		vepu580_setup_fixed_qp(core, enc->qp);
+		return;
+	}
+
+	qp_min = intra ? state->qp_min_i : state->qp_min;
+	qp_max = intra ? state->qp_max_i : state->qp_max;
+	vepu580_setup_row_rc(core, &rkvenc_hevc_row_rc, enc->qp,
+			     clamp(qp_min, 0, 51), clamp(qp_max, 0, 51),
+			     qp_range, enc->cbr.target_bits,
+			     state->width_ctbs * state->height_ctbs,
+			     state->width_ctbs);
+}
+
 static int rkvenc_hevc_run(struct rkvenc_ctx *ctx, struct rkvenc_core *core,
 			   struct rkvenc_run *run)
 {
@@ -574,7 +611,6 @@ static int rkvenc_hevc_run(struct rkvenc_ctx *ctx, struct rkvenc_core *core,
 	struct v4l2_hevc_enc *enc = &hevc->enc;
 	const struct v4l2_hevc_enc_state *state = &enc->state_active;
 	struct rkvenc_rec_buf *rec, *refr = NULL, *col = NULL;
-	unsigned int ctus, qp_range;
 	bool intra, tmvp, colmv_stor;
 	int ret;
 
@@ -591,7 +627,6 @@ static int rkvenc_hevc_run(struct rkvenc_ctx *ctx, struct rkvenc_core *core,
 		return -ENOSPC;
 
 	intra = state->encode.slice_type == V4L2_HEVC_SLICE_TYPE_I;
-	ctus = state->width_ctbs * state->height_ctbs;
 
 	rec = enc->ref.buffer_current.private_data;
 	if (!rec)
@@ -645,24 +680,7 @@ static int rkvenc_hevc_run(struct rkvenc_ctx *ctx, struct rkvenc_core *core,
 			      colmv_stor, col && col->colmv_valid);
 	vepu580_setup_hevc_tuning(core, intra);
 
-	/*
-	 * In CBR mode the size target of the frame rate control is handed to
-	 * the hardware CTU row rate control, which adapts the QP of each CTU
-	 * row by up to the row_rc_qp_range parameter.
-	 */
-	qp_range = min(READ_ONCE(rkvenc_row_rc_qp_range), 15U);
-	hevc->hw_rc = state->frame_rc_enable &&
-		      state->bitrate_mode == V4L2_MPEG_VIDEO_BITRATE_MODE_CBR &&
-		      qp_range;
-	if (hevc->hw_rc)
-		vepu580_setup_row_rc(core, &rkvenc_hevc_row_rc, enc->qp,
-				     clamp(state->qp_min, 0, 51),
-				     clamp(state->qp_max, 0, 51), qp_range,
-				     enc->cbr.target_bits, ctus,
-				     state->width_ctbs);
-	else
-		vepu580_setup_fixed_qp(core, enc->qp);
-
+	rkvenc_hevc_setup_qp(hevc, core);
 	rkvenc_hevc_setup_tile(hevc, core, 0);
 
 	return 0;
@@ -807,6 +825,9 @@ static const struct v4l2_ctrl_config rkvenc_hevc_ctrl_cfgs[] = {
 	},
 	{ .id = V4L2_CID_MPEG_VIDEO_HEVC_MIN_QP, .max = 51, .step = 1, .def = 10, },
 	{ .id = V4L2_CID_MPEG_VIDEO_HEVC_MAX_QP, .max = 51, .step = 1, .def = 51, },
+	/* I pictures of the frame rate control: 15..51 as in MPP */
+	{ .id = V4L2_CID_MPEG_VIDEO_HEVC_I_FRAME_MIN_QP, .max = 51, .step = 1, .def = 15, },
+	{ .id = V4L2_CID_MPEG_VIDEO_HEVC_I_FRAME_MAX_QP, .max = 51, .step = 1, .def = 51, },
 	{ .id = V4L2_CID_MPEG_VIDEO_HEVC_I_FRAME_QP, .max = 51, .step = 1, .def = 30, },
 	{ .id = V4L2_CID_MPEG_VIDEO_HEVC_P_FRAME_QP, .max = 51, .step = 1, .def = 32, },
 	{ .id = V4L2_CID_MPEG_VIDEO_AVERAGE_QP, .max = 51, .step = 1, },

-- 
2.55.0

