From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Wed, 04 Nov 2026 14:27:00 +0300
Subject: [PATCH] media: verisilicon: postproc: fix the G1 input height
 extension
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b4-hantro-pp-v1-1-1d75e9b225f8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvyJ7bqEtkeor0SFrq72oaEQg/j3pO
 AMzGRJH4QSTyhD5kSTeVaBGwXat7mSUvTJ0bWeIWo1WY/V39BgC0sZkzTCSNj3UJEQ+5P1381L
 KB/YdnS5eAAAA
X-Change-ID: 20261104-b4-hantro-pp-1ce1b6891463
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Hugues Fruchet <hugues.fruchet@foss.st.com>, 
 Heiko Stuebner <heiko@sntech.de>, linux-media@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Sergei Khomenkov <shomenkow@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793791629; l=2696;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=6KMLDE6dsLI68WIn7HDBXCi9zZIMm6q13VtI26jCIEQ=;
 b=GW+Um0KlDUSjAUHiJBO3u19Fpg5eM42bH6xinnVwJ65mnTUtQeE34SUyzblxmnVX92v/MDvJv
 BdzIUwJKlk3CrSB3jJg0tsT7D0ZdZJCL/g6cBPYs7j7XbbeP0rkvNZF
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The G1 post-processor takes its input size in macroblocks: the low
bits in swreg72, the high bits in swreg92 (bits 28:26 for bits 11:9
of the width, bits 31:29 for bits 10:8 of the height). This is the
VDPU1 layout in Rockchip's MPP library, whose JPEG decoder writes the
height extension as ((height / 16) & 0x700) >> 8.

hantro_postproc_g1_enable() computes the width extension that way but
writes the height extension as MB_HEIGHT(height >> 8), shifting lines
instead of macroblocks. Every input of 256 to 4080 lines gets an
extension of 1 instead of 0, so the post-processor is told it has 256
more macroblock rows than it has: 286 instead of 30 for 480 lines,
301 instead of 45 for 720 and 324 instead of 68 for 1080. Inputs
below 256 lines are not affected.

Shift the macroblock count, as is done for the width.

The problem was found with an LLM coding assistant while porting
mainline Linux to a Rockchip RK3026 board; the assistant also drafted
this change. Tested on that board (G1, ID 0x6731), decoding H.264
(640x480, 854x480, 1280x720) and VP8 (640x480, 1280x720) to YUYV
through the post-processor, 241 frames, against a software conversion
of the decoder's NV12 output. Without this change only the 4 VP8 key
frames match: a few pixels at the bottom left of the last macroblock
row differ from run to run, and VP8 inter frames propagate them. With
it all 241 frames match. 320x240 is correct either way.

Fixes: 3f6702e1be8a ("media: verisilicon: postproc: 4K support")
Cc: stable@vger.kernel.org
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_postproc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/hantro_postproc.c b/drivers/media/platform/verisilicon/hantro_postproc.c
index e94d1ba5ef10..ecc6b3137eb0 100644
--- a/drivers/media/platform/verisilicon/hantro_postproc.c
+++ b/drivers/media/platform/verisilicon/hantro_postproc.c
@@ -106,7 +106,7 @@ static void hantro_postproc_g1_enable(struct hantro_ctx *ctx)
 	HANTRO_PP_REG_WRITE(vpu, orig_width, MB_WIDTH(ctx->dst_fmt.width));
 	HANTRO_PP_REG_WRITE(vpu, display_width, ctx->dst_fmt.width);
 	HANTRO_PP_REG_WRITE(vpu, input_width_ext, MB_WIDTH(ctx->dst_fmt.width) >> 9);
-	HANTRO_PP_REG_WRITE(vpu, input_height_ext, MB_HEIGHT(ctx->dst_fmt.height >> 8));
+	HANTRO_PP_REG_WRITE(vpu, input_height_ext, MB_HEIGHT(ctx->dst_fmt.height) >> 8);
 }
 
 static int down_scale_factor(struct hantro_ctx *ctx)

---
base-commit: 27285b099fbc5cb2ae3aef20f3bbd7b3c88b3005
change-id: 20261104-b4-hantro-pp-1ce1b6891463

Best regards,
-- 
Sergei Khomenkov <shomenkow@gmail.com>

