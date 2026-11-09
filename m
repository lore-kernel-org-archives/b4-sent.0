From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Mon, 09 Nov 2026 16:43:52 +0300
Subject: [PATCH 2/3] media: verisilicon: program the H1 JPEG stream limit
 in 64-bit words
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-hantro-buflimit-v1-2-f0b86ce61e66@gmail.com>
References: <20261109-hantro-buflimit-v1-0-f0b86ce61e66@gmail.com>
In-Reply-To: <20261109-hantro-buflimit-v1-0-f0b86ce61e66@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794231837; l=4212;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=YK3E1q/MxAtcBQVsrMtlnwZsWtudnoCZ/mj9nUB82Sw=;
 b=pywUwWFlxV95giMYgYS1GRar2cxlY1SxSiD+V7TeIDBpGxEnUU+CAnv+9OzMdgPqCpD3oypY8
 X7ZJWsernX6DmkEY66rt3mM8jyhQ5mpKkcMrVDDn9oCwjdqPrDNz8mm
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H1 JPEG encoder takes the stream buffer limit in 64-bit words. The
same register reads back the stream size in bits when the frame is
done, which hantro_h1_jpeg_enc_done() already divides by 8. The driver
writes the room left in the CAPTURE plane in bytes, so the hardware may
write up to eight times the buffer size, and a stream that does not fit
runs past the end of the plane into whatever memory follows it.

Userspace can get there. hantro_try_fmt() keeps any non-zero CAPTURE
sizeimage, and even the default of header_size + width * height * 2 is
not a bound: at quality 100 a high-entropy frame takes up to about 2.75
bytes per pixel. On a 640x480 frame the encoder wrote 230 KB past the
end of a default-sized buffer, on a 1920x1088 frame 1.6 MB. Without an
IOMMU in front of the encoder that is memory owned by someone else.

Write the limit in 64-bit words, rounded down to whole 64-byte bursts:
on the RK3026 the encoder writes the stream in 64-byte bursts and
finishes a burst it has started, so a limit that is not a multiple of 8
words lets it write up to 56 bytes past it. Rockchip's MPP library
programs this register the same way for H.264, in 64-bit words rounded
down to a multiple of 8 (mpp/hal/vpu/h264e/hal_h264e_vepu1_v2.c). The
stream starts header_size (624) bytes into the plane, so its address
stays 8-byte aligned. A stream that does not fit now stops at the limit
with a buffer-full interrupt, and the frame comes back with the ERROR
flag. A plane with less than one burst after the header is left to the
next patch.

The STM32MP25 VENC uses the same code, so it gets this change too. I
cannot test it there, and its interrupt handler does not get the stop
of the previous patch. rockchip_vpu2_jpeg_enc_set_buffers() writes
VEPU_REG_STR_BUF_LIMIT in bytes the same way, and
rockchip_vpu2_jpeg_enc_done() divides the read-back by 8 as well; I
cannot test the VEPU2 either, so this patch leaves it alone.

Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board (VEPU1); the assistant also drafted the code and
this message. Tested on that board, with CAPTURE buffers imported
through DMABUF from a larger buffer filled with a pattern: without this
change the encoder wrote the rest of the stream past the end of the
plane in each of 16 overflowing frames (640x480 to 1920x1088, quality
100, 12 of them in default-sized planes). With this and the previous
patch, 14 overflowing frames (640x480 and 1920x1088, four of them queued
back to back) stopped exactly at the limit with BUFFER_FULL in the
status, nothing past the plane changed, and frames that fit are byte for
byte the same as before. With the limit in words but not rounded down to
a burst, the encoder wrote up to 56 bytes past it. Not tested on other
SoCs.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c b/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
index 86cc1a07026f..1e548e91612b 100644
--- a/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
+++ b/drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c
@@ -55,7 +55,15 @@ static void hantro_h1_jpeg_enc_set_buffers(struct hantro_dev *vpu,
 	vepu_write_relaxed(vpu, vb2_dma_contig_plane_dma_addr(dst_buf, 0) +
 				ctx->vpu_dst_fmt->header_size,
 			   H1_REG_ADDR_OUTPUT_STREAM);
-	vepu_write_relaxed(vpu, size_left, H1_REG_STR_BUF_LIMIT);
+	/*
+	 * The stream buffer limit is counted in 64-bit words, not in bytes
+	 * (the register reads back the stream size in bits once the frame is
+	 * done). On the RK3026 the encoder writes the stream in 64-byte
+	 * bursts and finishes a burst it has started, so give it whole
+	 * bursts only.
+	 */
+	vepu_write_relaxed(vpu, round_down(size_left, 64) / 8,
+			   H1_REG_STR_BUF_LIMIT);
 
 	if (pix_fmt->num_planes == 1) {
 		src[0] = vb2_dma_contig_plane_dma_addr(src_buf, 0);

-- 
2.53.0

