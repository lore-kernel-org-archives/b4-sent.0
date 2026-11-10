From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:08:09 +0000
Subject: [PATCH RFC 07/12] media: rockchip: rkvenc: Encode pictures wider
 than 4096 pixels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvenc-v1-7-ea8b47122d8c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305283; l=7132;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=56b7J5fUEmfLr8Fj+TP9yyNIRX3fqgMQpuiuYDuQe0k=;
 b=YJG7IIZbn+1H7XmugCQJIpUWIBMUzPf7b49krYrJy0urWaN0yXq8LYI6DaUPP67KT3MVcgAeq
 uE9PlWt7NEOCgM1xRnPHoKIdw9GWDg3ET8rmfAYlIJ6VcVHiz3PaIjg
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The internal line buffers of the VEPU580 cover pictures up to 4096
pixels wide. Wider pictures need an external line buffer of 480 bytes per
64-pixel column, given to the encoder by its bottom address and its
(exclusive) top address in ADR_ELBB and ADR_ELBT. Both registers hold
address bits 31:8.

Allocate that buffer per context at stream start when the encoded width
is above 4096, program it for every picture, and raise the frame size
limits of both codecs to the 16384x8192 the encoder supports.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../media/platform/rockchip/rkvenc/rkvenc-h264.c   |  6 ++--
 .../media/platform/rockchip/rkvenc/rkvenc-hevc.c   |  6 ++--
 .../media/platform/rockchip/rkvenc/rkvenc-regs.h   |  2 ++
 .../platform/rockchip/rkvenc/rkvenc-vepu580.c      | 38 ++++++++++++++++++++--
 drivers/media/platform/rockchip/rkvenc/rkvenc.c    |  8 ++++-
 drivers/media/platform/rockchip/rkvenc/rkvenc.h    |  4 +++
 6 files changed, 54 insertions(+), 10 deletions(-)

diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c
index 665c54278029..11051aea43b4 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-h264.c
@@ -501,11 +501,11 @@ const struct rkvenc_coded_fmt_desc rkvenc_h264_fmt_desc = {
 	.size_align = 16,
 	.frmsize = {
 		.min_width = 64,
-		/* The external line buffer for wider pictures is not handled. */
-		.max_width = 4096,
+		/* Wider than 4096 with the external line buffer. */
+		.max_width = 16384,
 		.step_width = 2,
 		.min_height = 64,
-		.max_height = 4096,
+		.max_height = 8192,
 		.step_height = 2,
 	},
 	.ctrls = &rkvenc_h264_ctrls,
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
index a3d35a7fdc3f..638b13d6642a 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-hevc.c
@@ -689,11 +689,11 @@ const struct rkvenc_coded_fmt_desc rkvenc_hevc_fmt_desc = {
 	.size_align = 8,
 	.frmsize = {
 		.min_width = 64,
-		/* Wider pictures need tiles, which are not implemented. */
-		.max_width = 4096,
+		/* Wider than 4096 with the external line buffer. */
+		.max_width = 16384,
 		.step_width = 2,
 		.min_height = 64,
-		.max_height = 4096,
+		.max_height = 8192,
 		.step_height = 2,
 	},
 	.ctrls = &rkvenc_hevc_ctrls,
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-regs.h b/drivers/media/platform/rockchip/rkvenc/rkvenc-regs.h
index e8e7ce045f90..dd91004e31cf 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-regs.h
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-regs.h
@@ -82,6 +82,8 @@
 #define VEPU580_LPFR_ADDR			0x02c4
 #define VEPU580_EBUFT_ADDR			0x02d8
 #define VEPU580_EBUFB_ADDR			0x02dc
+/* Widest picture the internal line buffers cover. */
+#define VEPU580_LINE_BUF_MAX_WIDTH		4096
 
 /* Frame class: control */
 #define VEPU580_ENC_PIC				0x0300
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c b/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c
index f14d5ae0b7f7..adb1372dff57 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc-vepu580.c
@@ -179,9 +179,41 @@ void vepu580_setup_common(struct rkvenc_ctx *ctx, struct rkvenc_core *core,
 	rkvenc_set(core, VEPU580_SLI_SPLT, 0);
 	rkvenc_set(core, VEPU580_SLI_CFG, VEPU580_SLI_CFG_SLI_CRS_EN);
 
-	/* No external line buffer: widths above 4096 are rejected for now. */
-	rkvenc_set(core, VEPU580_EBUFT_ADDR, 0);
-	rkvenc_set(core, VEPU580_EBUFB_ADDR, 0);
+	/* The external line buffer: top is the exclusive end, 0 when unused. */
+	if (ctx->line_buf.cpu) {
+		rkvenc_set(core, VEPU580_EBUFT_ADDR,
+			   ctx->line_buf.dma + ctx->line_buf.size);
+		rkvenc_set(core, VEPU580_EBUFB_ADDR, ctx->line_buf.dma);
+	} else {
+		rkvenc_set(core, VEPU580_EBUFT_ADDR, 0);
+		rkvenc_set(core, VEPU580_EBUFB_ADDR, 0);
+	}
+}
+
+/*
+ * The internal line buffers cover pictures up to 4096 pixels wide. Wider
+ * pictures need an external one of 480 bytes per 64-pixel column. Its
+ * address registers hold bits 31:8 only, hence the 256-byte rounding (the
+ * DMA allocation itself is page aligned). The content does not outlive a
+ * picture, and a context runs one picture at a time, so one buffer per
+ * context is enough.
+ */
+int vepu580_alloc_line_buf(struct rkvenc_ctx *ctx)
+{
+	unsigned int width = ALIGN(ctx->coded_fmt.fmt.pix_mp.width,
+				   ctx->coded_fmt_desc->size_align);
+
+	if (width <= VEPU580_LINE_BUF_MAX_WIDTH)
+		return 0;
+
+	return rkvenc_alloc_aux(ctx->dev, &ctx->line_buf,
+				ALIGN(DIV_ROUND_UP(width, 64) * 480, 256),
+				false);
+}
+
+void vepu580_free_line_buf(struct rkvenc_ctx *ctx)
+{
+	rkvenc_free_aux(ctx->dev, &ctx->line_buf);
 }
 
 /*
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc.c b/drivers/media/platform/rockchip/rkvenc/rkvenc.c
index 26bee08d4c2d..61c745994da9 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc.c
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc.c
@@ -505,7 +505,12 @@ static int rkvenc_start_streaming(struct vb2_queue *q, unsigned int count)
 	    ctx->src_fmt.fmt.pix_mp.height != ctx->coded_fmt.fmt.pix_mp.height)
 		ret = -EINVAL;
 	else
-		ret = desc->ops->start ? desc->ops->start(ctx) : 0;
+		ret = vepu580_alloc_line_buf(ctx);
+	if (!ret && desc->ops->start) {
+		ret = desc->ops->start(ctx);
+		if (ret)
+			vepu580_free_line_buf(ctx);
+	}
 	if (ret) {
 		rkvenc_queue_cleanup(q, VB2_BUF_STATE_QUEUED);
 		return ret;
@@ -524,6 +529,7 @@ static void rkvenc_stop_streaming(struct vb2_queue *q)
 	if (ctx->started) {
 		if (desc->ops->stop)
 			desc->ops->stop(ctx);
+		vepu580_free_line_buf(ctx);
 		ctx->started = false;
 	}
 
diff --git a/drivers/media/platform/rockchip/rkvenc/rkvenc.h b/drivers/media/platform/rockchip/rkvenc/rkvenc.h
index c2dd0bb91c51..ec6a955921b8 100644
--- a/drivers/media/platform/rockchip/rkvenc/rkvenc.h
+++ b/drivers/media/platform/rockchip/rkvenc/rkvenc.h
@@ -226,6 +226,8 @@ struct rkvenc_ctx {
 	struct v4l2_ctrl_handler ctrl_hdl;
 	struct rkvenc_core *core;
 	struct v4l2_ctrl *avg_qp_ctrl;
+	/* External line buffer, only for pictures wider than 4096 pixels. */
+	struct rkvenc_aux_buf line_buf;
 	void *priv;
 	bool started;
 };
@@ -249,6 +251,8 @@ static inline void rkvenc_or(struct rkvenc_core *core, u32 reg, u32 val)
 int rkvenc_alloc_aux(struct rkvenc_dev *rkvenc, struct rkvenc_aux_buf *buf,
 		     size_t size, bool kernel_mapping);
 void rkvenc_free_aux(struct rkvenc_dev *rkvenc, struct rkvenc_aux_buf *buf);
+int vepu580_alloc_line_buf(struct rkvenc_ctx *ctx);
+void vepu580_free_line_buf(struct rkvenc_ctx *ctx);
 void vepu580_setup_common(struct rkvenc_ctx *ctx, struct rkvenc_core *core,
 			  struct rkvenc_run *run);
 void vepu580_setup_me(struct rkvenc_core *core, unsigned int width_mbs,

-- 
2.55.0

