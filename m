From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Mon, 09 Nov 2026 16:43:53 +0300
Subject: [PATCH 3/3] media: verisilicon: leave room for the JPEG header and
 one stream burst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-hantro-buflimit-v1-3-f0b86ce61e66@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794231837; l=2875;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=WFzfE2RiWdT+i+qq0glggXPv17AxZu0PiVwPxE5rxXQ=;
 b=pPK6FLWKeibNzXyvohaaL0PsnBvzKTougQAG6KwXp2yfxpo4tasR1lz+/mNE91PalLZ0uU93p
 0Pp3dUaw9zCAA3hw1AA6gCnAy32OCAfz/TuRbgsnNesnOQZWA78mcPb
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hantro_try_fmt() keeps any non-zero sizeimage on the JPEG encoder's
CAPTURE queue, however small, and hantro_buf_prepare() then accepts a
plane of that size. hantro_jpeg_header_assemble() writes the 624-byte
header into the plane with the CPU before the hardware starts, and a
plane smaller than the header also makes the WARN_ON() in
hantro_h1_jpeg_enc_set_buffers() and
rockchip_vpu2_jpeg_enc_set_buffers() fire on every job, which userspace
can trigger at will. After the header the encoder writes its stream in
bursts, one of them even when the stream limit is 0; on the RK3026
VEPU1 a burst is 64 bytes. A plane smaller than the header plus 64 bytes
is therefore written past its end.

Raise a smaller request to header_size + 64, so that every plane the
driver accepts holds the header and at least one such burst.

Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board (VEPU1); the assistant also drafted the code and
this message. Tested on that board: a 640x480 CAPTURE format set with
sizeimage 1, 600, 656 and 689 reads back 688, 688, 688 and 689, a
656-byte DMABUF plane is then refused with EINVAL, and frames that do
not fit a 688-byte plane stop exactly at its end and come back with the
ERROR flag. A request of 600, now raised to 688, encodes with no
warning; before this change it was kept, and the encode hit the
WARN_ON() at hantro_h1_jpeg_enc.c:50 (hantro_h1_jpeg_enc_set_buffers(),
reported in hantro_h1_jpeg_enc_run()). Also before it, with 32 and 8
bytes after the header (a stream limit of 0), the encoder wrote one
burst, 32 and 56 bytes past the plane. The burst size is measured there
only; not tested on other SoCs.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 83af9fa1ce94..cc35beac8338 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -394,6 +394,16 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 		 */
 		pix_mp->plane_fmt[0].sizeimage = fmt->header_size +
 			pix_mp->width * pix_mp->height * fmt->max_depth;
+	} else if (fmt->codec_mode == HANTRO_MODE_JPEG_ENC) {
+		/*
+		 * The JPEG encoder writes the header with the CPU, then the
+		 * stream in bursts, one of them even when the stream limit
+		 * is 0. Leave room for both; a burst is 64 bytes on the
+		 * RK3026 VEPU1.
+		 */
+		pix_mp->plane_fmt[0].sizeimage =
+			max_t(u32, pix_mp->plane_fmt[0].sizeimage,
+			      fmt->header_size + 64);
 	}
 
 	return 0;

-- 
2.53.0

