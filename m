From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Tue, 10 Nov 2026 15:41:45 +0300
Subject: [PATCH v2 2/3] media: verisilicon: program the H1 JPEG stream
 limit in 64-bit words
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-buflimit-v2-2-ff7790def9fc@gmail.com>
References: <20261110-hantro-buflimit-v2-0-ff7790def9fc@gmail.com>
In-Reply-To: <20261110-hantro-buflimit-v2-0-ff7790def9fc@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Chen-Yu Tsai <wenst@chromium.org>, 
 Hugues Fruchet <hugues.fruchet@foss.st.com>, linux-media@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sergei Khomenkov <shomenkow@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794314506; l=2059;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=rSixJW+4SIvnxSyMoeLcNv71TQPTVPSPPdIZPn8IhxE=;
 b=rZnn4NFdWljPtdenIbYFVQCzkOroyvKYlmdGUI5ooGa+U4zK58oD4WfY32zIqxq2Hfq4rWxuN
 8s+/6csbyvVA6SX20juy4wkJtJWVLjQoFbNCblknsk6EKf4Mi32K267
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
it write up to 56 bytes past it.

Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board; the assistant also drafted this change. Tested
on that board: overflowing frames now stop at the programmed limit
without writing past the plane, and frames that fit are byte for byte
the same as before. Not tested on other SoCs, including the STM32MP25,
which shares this code.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c b/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
index 86cc1a07026f..665a87e9fe92 100644
--- a/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
+++ b/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
@@ -55,7 +55,12 @@ static void hantro_h1_jpeg_enc_set_buffers(struct hantro_dev *vpu,
 	vepu_write_relaxed(vpu, vb2_dma_contig_plane_dma_addr(dst_buf, 0) +
 				ctx->vpu_dst_fmt->header_size,
 			   H1_REG_ADDR_OUTPUT_STREAM);
-	vepu_write_relaxed(vpu, size_left, H1_REG_STR_BUF_LIMIT);
+	/*
+	 * The limit is in 64-bit words. The encoder finishes a 64-byte burst
+	 * it has started (measured on the RK3026), so give it whole bursts.
+	 */
+	vepu_write_relaxed(vpu, round_down(size_left, 64) / 8,
+			   H1_REG_STR_BUF_LIMIT);
 
 	if (pix_fmt->num_planes == 1) {
 		src[0] = vb2_dma_contig_plane_dma_addr(src_buf, 0);

-- 
2.53.0

