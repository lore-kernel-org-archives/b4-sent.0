From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Tue, 24 Nov 2026 16:40:18 +0300
Subject: [PATCH v3 2/3] media: verisilicon: program the JPEG encoder stream
 limit in 64-bit words
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-hantro-buflimit-v3-2-780903970ca0@gmail.com>
References: <20261124-hantro-buflimit-v3-0-780903970ca0@gmail.com>
In-Reply-To: <20261124-hantro-buflimit-v3-0-780903970ca0@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Chen-Yu Tsai <wenst@chromium.org>, 
 Hugues Fruchet <hugues.fruchet@foss.st.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sergei Khomenkov <shomenkow@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795527620; l=3597;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=biQGrB6UYPvhg65jUpDgSfn1YhBxiYA0k15PHlCqCLk=;
 b=P5pNeXlKk5cfoFc6oXQ0j5mBRlqXJJwCmuZ2j/huGy6S5VX16cLw9qmvdyeaWZf4mr/NJV6lN
 V8/NCe6s+/ICjb9cvrhYg3ULwwHNjWcpWWCHX+0sSk4Vq+DaDS7Cm4L
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

H1_REG_STR_BUF_LIMIT counts 64-bit words, but the driver writes the room
left in the CAPTURE plane in bytes. A stream that does not fit, such as
a quality 100 frame of noise in a default-sized buffer, is then written
past the end of the plane, up to eight times its size.

Write the limit in 64-bit words, rounded down to whole 64-byte bursts:
the encoder finishes a burst it has started, so an unrounded limit lets
it write up to 56 bytes past it. rockchip_vpu2_jpeg_enc_set_buffers()
has the same bug with VEPU_REG_STR_BUF_LIMIT, which
rockchip_vpu2_jpeg_enc_done() reads back as a bit count; give the VEPU2
the same limit.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board; the assistant also drafted this change. Tested
on that board (its H1 is Rockchip's VEPU1): overflowing frames now
stop at the programmed limit without writing past the plane (a canary
after the plane stays intact), and frames that fit are byte for byte
the same as before. Not tested on other SoCs, including the STM32MP25,
which shares the H1 code. The VEPU2 change is not tested: there is no
VEPU2 on the RK3026.

Rockchip's MPP programs VEPU_REG_STR_BUF_LIMIT the same way ("limit >>=
3; limit &= ~7" in hal_h264e_vepu2_v2.c). Patch 1 stops the encoder
only in the VEPU1 interrupt handler; the VEPU2 and STM32MP25 handlers do
not: if those encoders pause on a full buffer as the RK3026 H1 does, the
next job may time out.
---
 drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c        | 4 +++-
 drivers/media/platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c | 4 +++-
 2 files changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c b/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
index 86cc1a07026f..cbf0e3d034f6 100644
--- a/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
+++ b/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
@@ -55,7 +55,9 @@ static void hantro_h1_jpeg_enc_set_buffers(struct hantro_dev *vpu,
 	vepu_write_relaxed(vpu, vb2_dma_contig_plane_dma_addr(dst_buf, 0) +
 				ctx->vpu_dst_fmt->header_size,
 			   H1_REG_ADDR_OUTPUT_STREAM);
-	vepu_write_relaxed(vpu, size_left, H1_REG_STR_BUF_LIMIT);
+	/* In 64-bit words; the encoder finishes a started 64-byte burst. */
+	vepu_write_relaxed(vpu, round_down(size_left, 64) / 8,
+			   H1_REG_STR_BUF_LIMIT);
 
 	if (pix_fmt->num_planes == 1) {
 		src[0] = vb2_dma_contig_plane_dma_addr(src_buf, 0);
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c b/drivers/media/platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c
index 61621b1be8a2..ab976c762239 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c
@@ -82,7 +82,9 @@ static void rockchip_vpu2_jpeg_enc_set_buffers(struct hantro_dev *vpu,
 	vepu_write_relaxed(vpu, vb2_dma_contig_plane_dma_addr(dst_buf, 0) +
 				ctx->vpu_dst_fmt->header_size,
 			   VEPU_REG_ADDR_OUTPUT_STREAM);
-	vepu_write_relaxed(vpu, size_left, VEPU_REG_STR_BUF_LIMIT);
+	/* In 64-bit words, in whole 64-byte bursts as on the H1. */
+	vepu_write_relaxed(vpu, round_down(size_left, 64) / 8,
+			   VEPU_REG_STR_BUF_LIMIT);
 
 	if (pix_fmt->num_planes == 1) {
 		src[0] = vb2_dma_contig_plane_dma_addr(src_buf, 0);

-- 
2.53.0

