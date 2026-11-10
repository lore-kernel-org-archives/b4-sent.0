From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Tue, 10 Nov 2026 15:41:46 +0300
Subject: [PATCH v2 3/3] media: verisilicon: leave room for the JPEG header
 and one stream burst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-buflimit-v2-3-ff7790def9fc@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794314506; l=1858;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=CeJV7WTdl8YyEt6UT/A5SLtk2CJudxLaFIgLvsKKuB8=;
 b=a6Kl0B0YyzxhYqxv/b89jliXBQrKiAALwDgE0BamEs0dxGx9Dj/wZSns3/8hB3anPmZ4cp3a/
 WDD3Wbae9U3DCBHdA8Zs+B3G/zVCgIKLABK1qhp6RWL8uvwdivejO63
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hantro_try_fmt() keeps any non-zero CAPTURE sizeimage of the JPEG
encoder, however small. The CPU writes the 624-byte header into the
plane, and on the RK3026 VEPU1 the encoder then writes at least one
64-byte burst even with a stream limit of 0, so a smaller plane is
written past its end. A plane smaller than the header also makes the
WARN_ON() in hantro_h1_jpeg_enc_set_buffers() fire on every job.

Raise a smaller request to header_size + 64.

Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board; the assistant also drafted this change. Tested
on that board: a sizeimage of 1 or 600 now reads back 688, and frames
that do not fit a 688-byte plane stop exactly at its end. Not tested on
other SoCs.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 83af9fa1ce94..6a6d27443a5e 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -394,6 +394,15 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 		 */
 		pix_mp->plane_fmt[0].sizeimage = fmt->header_size +
 			pix_mp->width * pix_mp->height * fmt->max_depth;
+	} else if (fmt->codec_mode == HANTRO_MODE_JPEG_ENC) {
+		/*
+		 * Room for the header and one stream burst (64 bytes on the
+		 * RK3026 VEPU1), which the encoder writes even with a stream
+		 * limit of 0.
+		 */
+		pix_mp->plane_fmt[0].sizeimage =
+			max_t(u32, pix_mp->plane_fmt[0].sizeimage,
+			      fmt->header_size + 64);
 	}
 
 	return 0;

-- 
2.53.0

