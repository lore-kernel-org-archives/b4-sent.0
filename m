From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:08:12 +0000
Subject: [PATCH RFC 10/12] media: rockchip: rkvenc: Re-encode oversized
 HEVC pictures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvenc-v1-10-ea8b47122d8c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305283; l=5197;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=CnTD9k51xhPhovXec4M42UtPMZ1lQDg4WDx349udodE=;
 b=UUJtPAINCYJCxhN14fvrq/KWdnnGuiFyM242OcxpOY2HMHNMedmUAWZzgTaGaG52znL8+nheO
 08PQMiNgBj7CcwkIcVJUEdjeOGvHzzmaf2OEqHI1G2Jdb8oCd+yozUP
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let the constant bitrate mode of the HEVC encode core code a picture far
above its size target a second time, as the Rockchip MPP library does:
once the last pass of the picture finished, ask v4l2_hevc_enc_reencode()
and run the whole picture again with the new QP, writing the slice data
over that of the first pass. The hardware writes the slice header, so the
software headers stay as they are.

A codec backend now returns RKVENC_PASS_AGAIN from next_pass to encode the
whole picture again, which restarts the summed status of the passes, and
RKVENC_PASS_NEXT for the next pass of the same picture.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../media/platform/rockchip/rkvenc/rkvenc-hevc.c   | 24 +++++++++++++++++-----
 drivers/media/platform/rockchip/rkvenc/rkvenc.c    |  6 +++++-
 drivers/media/platform/rockchip/rkvenc/rkvenc.h    | 11 +++++++---
 3 files changed, 32 insertions(+), 9 deletions(-)

diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
index 9baf76f7fc43..acbbfdd3f613 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
@@ -688,19 +688,33 @@ static int rkvenc_hevc_run(struct rkvenc_ctx *ctx, struct rkvenc_core *core,
 
 /*
  * The next tile column continues the bitstream right after the previous
- * one, as a slice of its own (the hardware writes its slice header).
+ * one, as a slice of its own (the hardware writes its slice header). Once
+ * the picture is complete, the rate control may have it encoded again with
+ * a higher QP, from the first tile column, over the slice data of the first
+ * encode.
  */
 static int rkvenc_hevc_next_pass(struct rkvenc_ctx *ctx,
 				 struct rkvenc_core *core,
 				 struct rkvenc_run *run)
 {
 	struct rkvenc_hevc_ctx *hevc = ctx->priv;
-	const struct v4l2_ctrl_hevc_pps *pps = &hevc->enc.state_active.pps;
+	struct v4l2_hevc_enc *enc = &hevc->enc;
+	const struct v4l2_ctrl_hevc_pps *pps = &enc->state_active.pps;
 	u64 offset = run->hdr_bytes + run->fb.bs_len;
 
 	if (!(pps->flags & V4L2_HEVC_PPS_FLAG_TILES_ENABLED) ||
-	    hevc->tile >= pps->num_tile_columns_minus1)
-		return 0;
+	    hevc->tile >= pps->num_tile_columns_minus1) {
+		if (!run->fb.bs_len || offset > rkvenc_dst_size(run) ||
+		    !v4l2_hevc_enc_reencode(enc, offset))
+			return 0;
+
+		rkvenc_set(core, VEPU580_ADR_BSBS,
+			   rkvenc_dst_addr(run) + run->hdr_bytes);
+		rkvenc_hevc_setup_qp(hevc, core);
+		rkvenc_hevc_setup_tile(hevc, core, 0);
+
+		return RKVENC_PASS_AGAIN;
+	}
 
 	if (!run->fb.bs_len || offset + SZ_4K > rkvenc_dst_size(run))
 		return -ENOSPC;
@@ -708,7 +722,7 @@ static int rkvenc_hevc_next_pass(struct rkvenc_ctx *ctx,
 	rkvenc_set(core, VEPU580_ADR_BSBS, rkvenc_dst_addr(run) + offset);
 	rkvenc_hevc_setup_tile(hevc, core, hevc->tile + 1);
 
-	return 1;
+	return RKVENC_PASS_NEXT;
 }
 
 static void rkvenc_hevc_done(struct rkvenc_ctx *ctx, struct rkvenc_run *run,
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc.c b/drivers/media/platform/rockchip/rkvenc/rkvenc.c
index a82a22137488..7313523af6b3 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc.c
@@ -965,7 +965,11 @@ static irqreturn_t rkvenc_irq_thread(int irq, void *priv)
 		if (ops->next_pass)
 			ret = ops->next_pass(core->curr_ctx, core, &core->run);
 		if (ret > 0) {
-			core->run.pass++;
+			/* A picture encoded again starts a new status sum. */
+			if (ret == RKVENC_PASS_AGAIN)
+				core->run.pass = 0;
+			else
+				core->run.pass++;
 			rkvenc_hw_start(core);
 			pm_runtime_put_noidle(core->dev);
 			return IRQ_HANDLED;
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc.h b/drivers/media/platform/rockchip/rkvenc/rkvenc.h
index c1dce59d8308..8fae10e2c69d 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc.h
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc.h
@@ -113,12 +113,17 @@ struct rkvenc_run {
  *	 registers (codec syntax, rate control and references)
  * @next_pass: optional, called after each hardware pass that finished without
  *	       error, with the status of the passes so far summed in @run->fb.
- *	       Returns 1 after updating @core's shadow registers for another
- *	       pass of the same picture, 0 when the picture is complete, or a
- *	       negative error code.
+ *	       Returns RKVENC_PASS_NEXT after updating @core's shadow registers
+ *	       for another pass of the same picture, RKVENC_PASS_AGAIN after
+ *	       setting them up to encode the whole picture again (the status
+ *	       of the passes so far is dropped), 0 when the picture is
+ *	       complete, or a negative error code.
  * @done: called after the hardware finished; @fb holds the status read-back.
  *	  The backend sets the CAPTURE payload and may change @state.
  */
+#define RKVENC_PASS_NEXT	1
+#define RKVENC_PASS_AGAIN	2
+
 struct rkvenc_codec_ops {
 	int (*adjust_fmt)(struct rkvenc_ctx *ctx, struct v4l2_format *f);
 	int (*start)(struct rkvenc_ctx *ctx);

-- 
2.55.0

