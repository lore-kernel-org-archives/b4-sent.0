From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:08:07 +0000
Subject: [PATCH RFC 05/12] media: rockchip: rkvenc: Don't enable adaptive
 QP with the row rate control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvenc-v1-5-ea8b47122d8c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305283; l=3648;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=tLKMbjBrFkOCagEOqlv6uXY4NBsMdfw5qJbiBJd+iIo=;
 b=lo5eJNn04MYXqUEt3tXUrIg0BJZcQ1BF25ZTy1Dqp4LeRaO2C6Z2alDIUl2ex+h914cJCyJpJ
 LIXBslSRMkrD5CnUnYMQtMvnUy1f0KtwL+36JX2yy8vJpJ/t0RvgIji
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The row rate control setup enables the texture adaptive QP (aq_en) with
MPP's MADI threshold and QP step tables, as MPP does. On the board it
costs PSNR at the same bitrate in every case measured: 0.7-1.3 dB for
H.264 (where SSIM drops too) and 0.3-0.7 dB for HEVC (1080p60 clips, 2 to
16 Mb/s, CBR). Leave it off: only the row size deviation moves the QP
within a picture, and the aq_mode field of the row rate control
parameters goes away.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c    | 3 +--
 drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c | 9 ++++++---
 drivers/media/platform/rockchip/rkvenc/rkvenc.h         | 2 --
 3 files changed, 7 insertions(+), 7 deletions(-)

diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
index 5bc6960a521a..a3d35a7fdc3f 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
@@ -40,12 +40,11 @@ static const struct v4l2_hevc_enc_rps_limits rkvenc_hevc_rps_limits = {
 
 /*
  * Row rate control: MPP's HEVC deviation thresholds are {2n, n, p, 2p}
- * with the adjustments {-2, -1, 0, 1, 2} and AQ mode 1.
+ * with the adjustments {-2, -1, 0, 1, 2}.
  */
 static const struct vepu580_row_rc rkvenc_hevc_row_rc = {
 	.qp_adj = { -2, -1, 0, 1, 2, 0, 0, 0, 0 },
 	.dthd_outer = 2,
-	.aq_mode = true,
 };
 
 static int rkvenc_hevc_state_constrain(struct v4l2_hevc_enc *enc,
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c
index ab23845a288d..86703dc659f6 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c
@@ -805,7 +805,6 @@ void vepu580_setup_hevc_tuning(struct rkvenc_core *core, bool intra)
 const struct vepu580_row_rc vepu580_h264_row_rc = {
 	.qp_adj = { -2, -1, 0, 1, 2, 0, 0, 0, 1 },
 	.dthd_outer = 4,
-	.aq_mode = false,
 };
 
 void vepu580_setup_row_rc(struct rkvenc_core *core,
@@ -825,9 +824,13 @@ void vepu580_setup_row_rc(struct rkvenc_core *core,
 	thd = 5 * row_bits / 16;
 
 	rkvenc_or(core, VEPU580_ENC_PIC, FIELD_PREP(VEPU580_ENC_PIC_PIC_QP, qp));
+	/*
+	 * MPP also enables the texture adaptive QP here (aq_en). With its
+	 * tables that costs 0.3-1.3 dB of PSNR at the same bitrate (and SSIM
+	 * for H.264), so the QP only follows the row size deviation.
+	 */
 	rkvenc_set(core, VEPU580_RC_CFG,
-		   VEPU580_RC_CFG_RC_EN | VEPU580_RC_CFG_AQ_EN |
-		   (cfg->aq_mode ? VEPU580_RC_CFG_AQ_MODE : 0) |
+		   VEPU580_RC_CFG_RC_EN |
 		   FIELD_PREP(VEPU580_RC_CFG_RC_CTU_NUM, blocks_per_row));
 	rkvenc_set(core, VEPU580_RC_QP,
 		   FIELD_PREP(VEPU580_RC_QP_RANGE, qp_range) |
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc.h b/drivers/media/platform/rockchip/rkvenc/rkvenc.h
index 3515ffc2b490..c2dd0bb91c51 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc.h
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc.h
@@ -264,12 +264,10 @@ void vepu580_setup_hevc_tuning(struct rkvenc_core *core, bool intra);
  * struct vepu580_row_rc - codec-specific row rate control parameters
  * @qp_adj: QP adjustment for each of the nine deviation buckets
  * @dthd_outer: multiple of the base threshold for the outer buckets
- * @aq_mode: value of rc_cfg.aq_mode
  */
 struct vepu580_row_rc {
 	s8 qp_adj[9];
 	unsigned int dthd_outer;
-	bool aq_mode;
 };
 
 extern const struct vepu580_row_rc vepu580_h264_row_rc;

-- 
2.55.0

