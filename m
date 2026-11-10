From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:08:08 +0000
Subject: [PATCH RFC 06/12] media: rockchip: rkvenc: Use MPP's moving-scene
 H.264 RDO tuning
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvenc-v1-6-ea8b47122d8c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305283; l=10003;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=2mw4fp9eMoAO0CrQU4c2+B4z7EEsgAFGVFEXM/O20kw=;
 b=paoNF5ZudwK6p2Tk8iSHdHtRSgGEssYY+DzItu9+ZFZHhMj3nI7cnOo7udY2cJ6Aa+qMMDax7
 csnbLh0nHsCBmefgjQ4Hux9wTu+dQZSZGref7gjPs7QmraPewaUy/I8
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H.264 mode decision and motion search registers had the values of
MPP's still-scene tuning set. MPP keeps two sets and switches per picture
from a motion detector (hal_h264e_vepu580_tune.c): the still-scene one
biases the decision towards intra and skip blocks and toward the zero
motion vector against flicker in surveillance video; the moving-scene
one is neutral: ATF weights 16, ATR weights 20, CIME/RIME cost
multipliers 4, no anti-flicker skip or intra, zero PMV off, no CIME SAD
early exits, move lambda 8, P dead zone 341/1024, ATR QP threshold 51,
intra cost thresholds 0 and the intra chroma weights.

Use the moving-scene set for every picture, and start the RDO lambda
table one entry lower than MPP (index 5, lambda / 2^(1/3)). At a fixed QP
(22-36, 1080p60 clips) this needs 7% (animation) to 11% (natural video)
fewer bits for the same PSNR-Y than the still-scene set with MPP's
lambda.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../media/platform/rockchip/rkvenc/rkvenc-h264.c   |  3 +-
 .../platform/rockchip/rkvenc/rkvenc-vepu580.c      | 79 +++++++++++-----------
 2 files changed, 41 insertions(+), 41 deletions(-)

diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c
index 227d341d060b..665c54278029 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c
@@ -333,8 +333,7 @@ static void rkvenc_h264_setup_syntax(struct rkvenc_core *core,
 	rkvenc_set(core, VEPU580_H264_SYNT_REFM2, 0);
 
 	val = VEPU580_RDO_CFG_INTER_4X4 | VEPU580_RDO_CFG_CHRM_SPCL |
-	      VEPU580_RDO_CFG_CCWA_E | VEPU580_RDO_CFG_ATR_E |
-	      VEPU580_RDO_CFG_ATF_INTRA_E;
+	      VEPU580_RDO_CFG_CCWA_E | VEPU580_RDO_CFG_ATR_E;
 	if (sps->profile_idc == RKVENC_H264_PROFILE_BASELINE &&
 	    sps->level_idc <= 30)
 		val |= VEPU580_RDO_CFG_RECT_SIZE;
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c
index 86703dc659f6..f14d5ae0b7f7 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c
@@ -336,12 +336,18 @@ void vepu580_setup_h264_tuning(struct rkvenc_dev *rkvenc,
 	const s8 *aq_step = intra ? vepu580_aq_step_i : vepu580_aq_step_p;
 	unsigned int i;
 
-	/* Intra prediction cost / mode decision */
-	rkvenc_set(core, VEPU580_IPRD_CSTS,
-		   FIELD_PREP(VEPU580_IPRD_CSTS_VTHD_Y, 9) |
-		   FIELD_PREP(VEPU580_IPRD_CSTS_VTHD_C, 63));
+	/*
+	 * MPP has two H.264 tuning sets and picks one per picture from a
+	 * motion detector: one for still scenes (surveillance cameras), which
+	 * biases the mode decision towards intra and skip blocks against
+	 * flicker, and a neutral one for moving content. The neutral one is
+	 * used for every picture: at the same QP it needs 7-11% fewer bits
+	 * for the same PSNR on moving clips. With it the intra prediction
+	 * cost thresholds are 0 and the chroma weights start at entry 0.
+	 */
+	rkvenc_set(core, VEPU580_IPRD_CSTS, 0);
 
-	vepu580_setup_klut(core, intra);
+	vepu580_setup_klut(core, true);
 
 	rkvenc_set(core, VEPU580_MADI_CFG, FIELD_PREP(VEPU580_MADI_CFG_MADI_THD, 25));
 	rkvenc_set(core, VEPU580_MD_SAD_THD, pack4(4, 9, 15, 0));
@@ -363,23 +369,23 @@ void vepu580_setup_h264_tuning(struct rkvenc_dev *rkvenc,
 	rkvenc_set(core, VEPU580_LVL16_INTRA_CST_THD1, pack2x12(9, 36));
 	rkvenc_set(core, VEPU580_LVL8_INTRA_CST_THD0, pack2x12(1, 4));
 	rkvenc_set(core, VEPU580_LVL8_INTRA_CST_THD1, pack2x12(9, 36));
-	rkvenc_set(core, VEPU580_LVL16_INTRA_UL_CST_THD, 0);
+	rkvenc_set(core, VEPU580_LVL16_INTRA_UL_CST_THD, 2501);
 	rkvenc_set(core, VEPU580_LVL32_INTRA_CST_WGT0, pack4(48, 60, 40, 48));
 	rkvenc_set(core, VEPU580_LVL32_INTRA_CST_WGT1, pack4(48, 60, 40, 48));
 	rkvenc_set(core, VEPU580_LVL16_INTRA_CST_WGT0, pack4(48, 60, 40, 48));
 	rkvenc_set(core, VEPU580_LVL16_INTRA_CST_WGT1, pack4(36, 42, 28, 32));
 
-	/* Quantisation dead zone: 683/1024 (I) or 583/1024, 171/1024 (P) */
+	/* Quantisation dead zone: 683/1024 (I) or 583/1024, 341/1024 (P) */
 	rkvenc_set(core, VEPU580_RDO_QUANT,
 		   FIELD_PREP(VEPU580_RDO_QUANT_F_BIAS_I, intra ? 683 : 583) |
-		   FIELD_PREP(VEPU580_RDO_QUANT_F_BIAS_P, 171));
+		   FIELD_PREP(VEPU580_RDO_QUANT_F_BIAS_P, 341));
 
 	/* Adaptive transform (H.264 only) */
 	if (intra) {
 		rkvenc_set(core, VEPU580_ATR_THD0, pack2x12(1, 4));
 		rkvenc_set(core, VEPU580_ATR_THD1,
 			   FIELD_PREP(VEPU580_ATR_THD1_THD2, 36) |
-			   FIELD_PREP(VEPU580_ATR_THD1_THDQP, 45));
+			   FIELD_PREP(VEPU580_ATR_THD1_THDQP, 51));
 		rkvenc_set(core, VEPU580_LVL16_ATR_WGT, pack4(16, 16, 16, 0));
 		rkvenc_set(core, VEPU580_LVL8_ATR_WGT, pack4(22, 21, 20, 0));
 		rkvenc_set(core, VEPU580_LVL4_ATR_WGT, pack4(20, 18, 16, 0));
@@ -387,19 +393,15 @@ void vepu580_setup_h264_tuning(struct rkvenc_dev *rkvenc,
 		rkvenc_set(core, VEPU580_ATR_THD0, pack2x12(4, 16));
 		rkvenc_set(core, VEPU580_ATR_THD1,
 			   FIELD_PREP(VEPU580_ATR_THD1_THD2, 81) |
-			   FIELD_PREP(VEPU580_ATR_THD1_THDQP, 45));
-		rkvenc_set(core, VEPU580_LVL16_ATR_WGT, pack4(22, 19, 16, 0));
-		rkvenc_set(core, VEPU580_LVL8_ATR_WGT, pack4(22, 19, 18, 0));
-		rkvenc_set(core, VEPU580_LVL4_ATR_WGT, pack4(22, 19, 16, 0));
+			   FIELD_PREP(VEPU580_ATR_THD1_THDQP, 51));
+		rkvenc_set(core, VEPU580_LVL16_ATR_WGT, pack4(20, 20, 20, 0));
+		rkvenc_set(core, VEPU580_LVL8_ATR_WGT, pack4(20, 20, 20, 0));
+		rkvenc_set(core, VEPU580_LVL4_ATR_WGT, pack4(20, 20, 20, 0));
 	}
 
-	/*
-	 * Motion search quality / cost multipliers. Where MPP's tuning differs
-	 * per scene mode, the values of its default (non-IPC) mode are used.
-	 */
+	/* Motion search quality / cost multipliers (neutral set) */
 	rkvenc_set(core, VEPU580_CIME_SQI_CFG,
 		   VEPU580_CIME_SQI_CFG_SAD_BIG_BLOCK |
-		   VEPU580_CIME_SQI_CFG_PMV_SET_ZERO |
 		   FIELD_PREP(VEPU580_CIME_SQI_CFG_PMV_NUM, 3));
 	rkvenc_set(core, VEPU580_CIME_SQI_THD,
 		   FIELD_PREP(VEPU580_CIME_SQI_THD_MVD_TH0, 32) |
@@ -407,49 +409,48 @@ void vepu580_setup_h264_tuning(struct rkvenc_dev *rkvenc,
 		   FIELD_PREP(VEPU580_CIME_SQI_THD_MVD_TH2, 128));
 	rkvenc_set(core, VEPU580_CIME_SQI_MULTI0,
 		   FIELD_PREP(VEPU580_CIME_SQI_MULTI_LO, 4) |
-		   FIELD_PREP(VEPU580_CIME_SQI_MULTI_HI, 7));
+		   FIELD_PREP(VEPU580_CIME_SQI_MULTI_HI, 4));
 	rkvenc_set(core, VEPU580_CIME_SQI_MULTI1,
-		   FIELD_PREP(VEPU580_CIME_SQI_MULTI_LO, 20) |
-		   FIELD_PREP(VEPU580_CIME_SQI_MULTI_HI, 20));
+		   FIELD_PREP(VEPU580_CIME_SQI_MULTI_LO, 4) |
+		   FIELD_PREP(VEPU580_CIME_SQI_MULTI_HI, 4));
 	rkvenc_set(core, VEPU580_RIME_SQI_THD,
-		   FIELD_PREP(VEPU580_RIME_SQI_THD_CIME_SAD_TH0, 50) |
 		   FIELD_PREP(VEPU580_RIME_SQI_THD_MVD_TH0, 3) |
 		   FIELD_PREP(VEPU580_RIME_SQI_THD_MVD_TH1, 8));
 	rkvenc_set(core, VEPU580_RIME_SQI_MULTI,
 		   FIELD_PREP(VEPU580_RIME_SQI_MULTI0, 4) |
-		   FIELD_PREP(VEPU580_RIME_SQI_MULTI1, 16) |
-		   FIELD_PREP(VEPU580_RIME_SQI_MULTI2, 64));
-	rkvenc_set(core, VEPU580_FME_SQI_THD0,
-		   FIELD_PREP(VEPU580_FME_SQI_THD0_PU16_TH, 2));
+		   FIELD_PREP(VEPU580_RIME_SQI_MULTI1, 4) |
+		   FIELD_PREP(VEPU580_RIME_SQI_MULTI2, 4));
+	rkvenc_set(core, VEPU580_FME_SQI_THD0, 0);
 	rkvenc_set(core, VEPU580_FME_SQI_THD1,
-		   FIELD_PREP(VEPU580_FME_SQI_THD1_MOVE_LAMBDA, 1));
+		   FIELD_PREP(VEPU580_FME_SQI_THD1_MOVE_LAMBDA, 8));
 
-	/* RDO lambda, intra prediction weights stay zero for H.264 */
+	/*
+	 * RDO lambda, intra prediction weights stay zero for H.264. MPP
+	 * starts at entry 6 (its lambda_idx); entry 5, one 2^(1/3) step
+	 * lower, saves 3-4% of the bits at the same PSNR.
+	 */
 	for (i = 0; i < 52; i++)
-		rkvenc_set(core, VEPU580_RDO_WGTA_QP(i), vepu580_h264_lambda[i + 6]);
+		rkvenc_set(core, VEPU580_RDO_WGTA_QP(i), vepu580_h264_lambda[i + 5]);
 
-	/* RDO intra / skip thresholds and weights */
-	rkvenc_set(core, VEPU580_RDO_SQI_CFG, VEPU580_RDO_SQI_CFG_ATF_PSKIP_EN);
+	/* RDO intra / skip thresholds and weights; no anti-flicker skips */
+	rkvenc_set(core, VEPU580_RDO_SQI_CFG, 0);
 	rkvenc_set(core, VEPU580_RDO_INTRA_CIME_THD0, pack2x12(28, 44));
 	rkvenc_set(core, VEPU580_RDO_INTRA_CIME_THD1, pack2x12(72, 0));
 	rkvenc_set(core, VEPU580_RDO_INTRA_VAR_THD(0), pack2x12(25, 64));
 	rkvenc_set(core, VEPU580_RDO_INTRA_VAR_THD(1), pack2x12(25, 64));
 	rkvenc_set(core, VEPU580_RDO_INTRA_VAR_THD(2), pack2x12(70, 100));
 	rkvenc_set(core, VEPU580_RDO_INTRA_VAR_THD(3), pack2x12(70, 100));
-	rkvenc_set(core, VEPU580_RDO_INTRA_ATF_WGT(0), pack4(22, 21, 20, 0));
-	rkvenc_set(core, VEPU580_RDO_INTRA_ATF_WGT(1), pack4(21, 20, 19, 0));
-	rkvenc_set(core, VEPU580_RDO_INTRA_ATF_WGT(2), pack4(20, 19, 18, 0));
-	rkvenc_set(core, VEPU580_RDO_INTRA_ATF_WGT(3), pack4(16, 16, 16, 0));
+	for (i = 0; i < 4; i++)
+		rkvenc_set(core, VEPU580_RDO_INTRA_ATF_WGT(i), pack4(16, 16, 16, 0));
 	rkvenc_set(core, VEPU580_RDO_SKIP_CIME_THD0, pack2x12(10, 8));
 	rkvenc_set(core, VEPU580_RDO_SKIP_CIME_THD1, pack2x12(15, 25));
 	rkvenc_set(core, VEPU580_RDO_SKIP_VAR_THD(0), pack2x12(25, 40));
 	rkvenc_set(core, VEPU580_RDO_SKIP_VAR_THD(1), pack2x12(25, 40));
 	rkvenc_set(core, VEPU580_RDO_SKIP_VAR_THD(2), pack2x12(70, 100));
 	rkvenc_set(core, VEPU580_RDO_SKIP_VAR_THD(3), pack2x12(70, 100));
-	rkvenc_set(core, VEPU580_RDO_SKIP_ATF_WGT(0), pack4(20, 16, 16, 16));
-	rkvenc_set(core, VEPU580_RDO_SKIP_ATF_WGT(1), pack4(16, 16, 16, 0));
-	rkvenc_set(core, VEPU580_RDO_SKIP_ATF_WGT(2), pack4(16, 16, 16, 0));
-	rkvenc_set(core, VEPU580_RDO_SKIP_ATF_WGT(3), pack4(16, 16, 16, 0));
+	rkvenc_set(core, VEPU580_RDO_SKIP_ATF_WGT(0), pack4(16, 16, 16, 16));
+	for (i = 1; i < 4; i++)
+		rkvenc_set(core, VEPU580_RDO_SKIP_ATF_WGT(i), pack4(16, 16, 16, 0));
 
 	/* Flat quantisation tables */
 	memcpy(&core->shadow[VEPU580_SCL_START / 4], rkvenc->h264_scl,

-- 
2.55.0

