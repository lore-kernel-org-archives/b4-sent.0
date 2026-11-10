From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:28 +0000
Subject: [PATCH 2/4] media: verisilicon: Find the second MPEG-2 field
 without top_field_first
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-codec-fixes-v1-2-0fd5372ce831@gmail.com>
References: <20261110-hantro-codec-fixes-v1-0-0fd5372ce831@gmail.com>
In-Reply-To: <20261110-hantro-codec-fixes-v1-0-0fd5372ce831@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sebastian Fricke <sebastian.fricke@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Jonas Karlman <jonas@kwiboo.se>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Jeffy Chen <jeffy.chen@rock-chips.com>, Tomasz Figa <tfiga@chromium.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295107; l=7659;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=I7zmqlMx+hMV7YYngac8E4NYGa6wp3wrWqDQDzG0598=;
 b=mezKjJ9P0sRKIFj0jeOHB95gv01nI5wJw/TisOgWgCvsfV9A1uv8MAlICQ8oDq5hdIp54H3J/
 PhV00iXFqeICyhh+3jOTxOpHEMWgh0mfrGkqKOZtEyo7s/USFdKzynf
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The second field of a field-coded P frame can predict from the first
field of the same frame, which is already in the destination buffer. The
G1 and VPU2 back-ends then point the reference of that parity at the
current buffer, and both back-ends tell the first field from the second
one with V4L2_MPEG2_PIC_FLAG_TOP_FIELD_FIRST: a top field is the first
field if the flag is set, a bottom field if it is not.

But top_field_first is always 0 in a field picture (ISO/IEC 13818-2,
6.3.10: "In a field picture top_field_first shall have the value '0'").
So the top field of every top-field-first frame is taken as a second
field, and predicts from the not-yet-decoded bottom field of the buffer,
while the bottom field is taken as a first field and loses its
reference to the top field. The error grows over the GOP: the field
picture conformance streams of ISO/IEC 13818-4 decoded at 6-25 dB
against FFmpeg (tcela-8, tcela-9, tcela-10, and sony-ct1/2/4 once they
switch to field pictures).

The uAPI has no flag for this, but the second field is the one of
opposite parity that follows the first with the same OUTPUT timestamp,
the two fields being decoded into one CAPTURE buffer held with
V4L2_BUF_FLAG_M2M_HOLD_CAPTURE_BUF. Track that in the context and use
it in both back-ends. This also replaces the VPU2 back-end's test of
V4L2_MPEG2_PIC_TOP_FIELD, a picture_structure value, against the flags.

Fixes: ceaac6dc5b7a ("media: rockchip/vpu: Add support for MPEG-2 decoding on RK3288")
Fixes: 879dee56a40c ("media: rockchip/vpu: Add MPEG2 decoding support to RK3399")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../platform/verisilicon/hantro_g1_mpeg2_dec.c     |  8 +++---
 drivers/media/platform/verisilicon/hantro_hw.h     |  8 ++++++
 drivers/media/platform/verisilicon/hantro_mpeg2.c  | 31 ++++++++++++++++++++++
 .../verisilicon/rockchip_vpu2_hw_mpeg2_dec.c       |  8 +++---
 4 files changed, 47 insertions(+), 8 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_g1_mpeg2_dec.c b/drivers/media/platform/verisilicon/hantro_g1_mpeg2_dec.c
index 6a942f4b8a2d..5f1ce21fa6e3 100644
--- a/drivers/media/platform/verisilicon/hantro_g1_mpeg2_dec.c
+++ b/drivers/media/platform/verisilicon/hantro_g1_mpeg2_dec.c
@@ -97,6 +97,9 @@ hantro_g1_mpeg2_dec_set_buffers(struct hantro_dev *vpu, struct hantro_ctx *ctx,
 {
 	dma_addr_t forward_addr = 0, backward_addr = 0;
 	dma_addr_t current_addr, addr;
+	bool second_field;
+
+	second_field = hantro_mpeg2_dec_second_field(ctx, pic, src_buf->timestamp);
 
 	switch (pic->picture_coding_type) {
 	case V4L2_MPEG2_PIC_CODING_TYPE_B:
@@ -126,10 +129,7 @@ hantro_g1_mpeg2_dec_set_buffers(struct hantro_dev *vpu, struct hantro_ctx *ctx,
 	/* Set forward ref frame (top/bottom field) */
 	if (pic->picture_structure == V4L2_MPEG2_PIC_FRAME ||
 	    pic->picture_coding_type == V4L2_MPEG2_PIC_CODING_TYPE_B ||
-	    (pic->picture_structure == V4L2_MPEG2_PIC_TOP_FIELD &&
-	     pic->flags & V4L2_MPEG2_PIC_FLAG_TOP_FIELD_FIRST) ||
-	    (pic->picture_structure == V4L2_MPEG2_PIC_BOTTOM_FIELD &&
-	     !(pic->flags & V4L2_MPEG2_PIC_FLAG_TOP_FIELD_FIRST))) {
+	    !second_field) {
 		vdpu_write_relaxed(vpu, forward_addr, G1_REG_REFER0_BASE);
 		vdpu_write_relaxed(vpu, forward_addr, G1_REG_REFER1_BASE);
 	} else if (pic->picture_structure == V4L2_MPEG2_PIC_TOP_FIELD) {
diff --git a/drivers/media/platform/verisilicon/hantro_hw.h b/drivers/media/platform/verisilicon/hantro_hw.h
index 13e573f1f19d..303e42b08c40 100644
--- a/drivers/media/platform/verisilicon/hantro_hw.h
+++ b/drivers/media/platform/verisilicon/hantro_hw.h
@@ -171,9 +171,14 @@ struct hantro_hevc_dec_hw_ctx {
  * struct hantro_mpeg2_dec_hw_ctx
  *
  * @qtable:		Quantization table
+ * @field_ts:		OUTPUT timestamp of the last field picture decoded, if it
+ *			was the first field of a frame
+ * @field_structure:	picture_structure of that field, 0 if there is none
  */
 struct hantro_mpeg2_dec_hw_ctx {
 	struct hantro_aux_buf qtable;
+	u64 field_ts;
+	u8 field_structure;
 };
 
 /**
@@ -567,6 +572,9 @@ int hantro_g1_mpeg2_dec_run(struct hantro_ctx *ctx);
 int rockchip_vpu2_mpeg2_dec_run(struct hantro_ctx *ctx);
 void hantro_mpeg2_dec_copy_qtable(u8 *qtable,
 				  const struct v4l2_ctrl_mpeg2_quantisation *ctrl);
+bool hantro_mpeg2_dec_second_field(struct hantro_ctx *ctx,
+				   const struct v4l2_ctrl_mpeg2_picture *pic,
+				   u64 timestamp);
 int hantro_mpeg2_dec_init(struct hantro_ctx *ctx);
 void hantro_mpeg2_dec_exit(struct hantro_ctx *ctx);
 
diff --git a/drivers/media/platform/verisilicon/hantro_mpeg2.c b/drivers/media/platform/verisilicon/hantro_mpeg2.c
index 04e545eb0a83..e5d70c64d7a7 100644
--- a/drivers/media/platform/verisilicon/hantro_mpeg2.c
+++ b/drivers/media/platform/verisilicon/hantro_mpeg2.c
@@ -35,10 +35,41 @@ void hantro_mpeg2_dec_copy_qtable(u8 *qtable,
 	}
 }
 
+/*
+ * Tell whether a field picture is the second field of its frame, which
+ * decides where its references are: the second field can predict from the
+ * first one, already decoded into the same buffer. top_field_first can't
+ * tell, it is always 0 in field pictures (ISO/IEC 13818-2, 6.3.10). The
+ * second field is the field of opposite parity decoded right after the
+ * first one, with the same OUTPUT timestamp.
+ */
+bool hantro_mpeg2_dec_second_field(struct hantro_ctx *ctx,
+				   const struct v4l2_ctrl_mpeg2_picture *pic,
+				   u64 timestamp)
+{
+	struct hantro_mpeg2_dec_hw_ctx *mpeg2 = &ctx->mpeg2_dec;
+	bool second;
+
+	if (pic->picture_structure == V4L2_MPEG2_PIC_FRAME) {
+		mpeg2->field_structure = 0;
+		return false;
+	}
+
+	second = mpeg2->field_structure &&
+		 mpeg2->field_structure != pic->picture_structure &&
+		 mpeg2->field_ts == timestamp;
+
+	mpeg2->field_structure = second ? 0 : pic->picture_structure;
+	mpeg2->field_ts = timestamp;
+
+	return second;
+}
+
 int hantro_mpeg2_dec_init(struct hantro_ctx *ctx)
 {
 	struct hantro_dev *vpu = ctx->dev;
 
+	ctx->mpeg2_dec.field_structure = 0;
 	ctx->mpeg2_dec.qtable.size = ARRAY_SIZE(zigzag) * 4;
 	ctx->mpeg2_dec.qtable.cpu =
 		dma_alloc_coherent(vpu->dev,
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu2_hw_mpeg2_dec.c b/drivers/media/platform/verisilicon/rockchip_vpu2_hw_mpeg2_dec.c
index 50a3a3eeaa00..57907dd5ea9c 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu2_hw_mpeg2_dec.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu2_hw_mpeg2_dec.c
@@ -100,6 +100,9 @@ rockchip_vpu2_mpeg2_dec_set_buffers(struct hantro_dev *vpu,
 {
 	dma_addr_t forward_addr = 0, backward_addr = 0;
 	dma_addr_t current_addr, addr;
+	bool second_field;
+
+	second_field = hantro_mpeg2_dec_second_field(ctx, pic, src_buf->timestamp);
 
 	switch (pic->picture_coding_type) {
 	case V4L2_MPEG2_PIC_CODING_TYPE_B:
@@ -129,10 +132,7 @@ rockchip_vpu2_mpeg2_dec_set_buffers(struct hantro_dev *vpu,
 	/* Set forward ref frame (top/bottom field) */
 	if (pic->picture_structure == V4L2_MPEG2_PIC_FRAME ||
 	    pic->picture_coding_type == V4L2_MPEG2_PIC_CODING_TYPE_B ||
-	    (pic->picture_structure == V4L2_MPEG2_PIC_TOP_FIELD &&
-	     pic->flags & V4L2_MPEG2_PIC_TOP_FIELD) ||
-	    (pic->picture_structure == V4L2_MPEG2_PIC_BOTTOM_FIELD &&
-	     !(pic->flags & V4L2_MPEG2_PIC_TOP_FIELD))) {
+	    !second_field) {
 		vdpu_write_relaxed(vpu, forward_addr, VDPU_REG_REFER0_BASE);
 		vdpu_write_relaxed(vpu, forward_addr, VDPU_REG_REFER1_BASE);
 	} else if (pic->picture_structure == V4L2_MPEG2_PIC_TOP_FIELD) {

-- 
2.55.0

