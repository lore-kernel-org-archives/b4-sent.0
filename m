From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Fri, 27 Nov 2026 09:03:12 +0300
Subject: [PATCH] media: verisilicon: size the JPEG encoder's sizeimage by
 quality
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-hantro-enc-sizestep-v1-1-7a732d1a4bbf@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/zWN0W7CMAxFf6XK8zzZaVqXakL8x8SDSV1mibYsK
 Wga4t+XwfZ2z5V97s1lTabZ9dXNJb1atmUuQC+Vix8yHxVsKOw8+pbIM5RyTQvoHCHbt+ZVzxB
 82wxdo0I+uPJ5Tjra18P6vn9y0s9Lka/P0k2aszzkffX25w7/7sNlPNlkK1xrQOAON1hvGKPg7
 jiJnV7jMm1/dw6SFQqU274SwTHEQEPoGIU6bRtmXwKxjNQGzx6xZnL7+/0HPjC7+PcAAAA=
X-Change-ID: 20261127-hantro-enc-sizestep-4265d85ea124
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hugues Fruchet <hugues.fruchet@foss.st.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>, linux-media@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sergei Khomenkov <shomenkow@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795759394; l=5937;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=v4JYN3YP75FPPDeInscD9Tx05Zfnftf4wowv5Ck5XCc=;
 b=H8XlpsNWAdXQENHAOEeE+KkW61TiJHBZUhsiu+rFCvKb8sRMwOJx45xk6MxI8bcKzKr7W24el
 OlsOoi/lUsYCAnCWMWpZ0LZsK8nfRRnwXW/A9ffgDHfds8iYVkCn4Ib
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The JPEG encoder's default CAPTURE sizeimage is header_size + width *
height * 2, but the H1 (VEPU1) of an RK3026 writes up to 3.23 bytes per
pixel at quality 100.

Size it by the quality. With the 4:2:0 header and the Annex K tables
this driver writes, an 8-bit frame needs at most 4.89 bytes per pixel at
quality 100, 2.91 at 94 and 1.98 at 83, byte stuffing included. Use 5
bytes per pixel from quality 95, 3 from 84 and 2 below as the default,
when the client passes sizeimage 0. Below quality 84, the default 50
included, the size is unchanged; from 95 it is 2.5 times larger, 10.4 MB
instead of 4.2 MB for 1920x1080.

A request was raised to min_size but had no upper bound. S_FMT and
TRY_FMT now cap it at the quality 100 size: no frame of that size can
use more, and a request sized for a later quality raise still fits.
CREATE_BUFS still takes any larger size. The default follows the quality
at the time of S_FMT, so set V4L2_CID_JPEG_COMPRESSION_QUALITY first; a
frame that no longer fits after a later raise ends with an error at the
stream limit.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board; it also drafted the code and this message and
computed the bounds (scripts on request). Tested on that board: 2316
frames of 30 worst-case inputs, 640x480 and 1280x720, quality 80..100,
all within the default size (largest 3.23 B/px at q100, 1.92 at q94,
1.33 at q83); v4l2-compliance shows no new failure. Not tested on
other SoCs.

The bounds are a per-block maximum of the Huffman-coded bits at the
quantizers of each quality, under the energy that 8-bit samples allow,
DC difference and byte stuffing included; frames found by search reach
about 0.7 of them.

Where a ceiling matters: GStreamer up to 1.26.11 and 1.28.7 sizes the
request from the largest enumerated frame, 8192x8192, and asks for
32 MiB per buffer for a 640x480 JPEG; 1.28.8 sizes it from the
negotiated frame:
https://gitlab.freedesktop.org/gstreamer/gstreamer/-/commit/08ea5bc9fab9

Depends on "media: verisilicon: fix JPEG encoder writes past the
CAPTURE buffer" v3:
https://lore.kernel.org/all/20261124-hantro-buflimit-v3-0-780903970ca0@gmail.com/
It overlaps Arun Iyengar's "media: verisilicon: Fix the JPEG encoder
format handling" v2 2/7 in hantro_try_fmt(); whichever goes second
needs a rebase.
---
 drivers/media/platform/verisilicon/hantro_jpeg.c | 25 ++++++++++++++++++++++++
 drivers/media/platform/verisilicon/hantro_jpeg.h |  4 ++++
 drivers/media/platform/verisilicon/hantro_v4l2.c |  6 ++++++
 3 files changed, 35 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_jpeg.c b/drivers/media/platform/verisilicon/hantro_jpeg.c
index 13a60638e43f..16ff9c49f889 100644
--- a/drivers/media/platform/verisilicon/hantro_jpeg.c
+++ b/drivers/media/platform/verisilicon/hantro_jpeg.c
@@ -243,3 +243,28 @@ void hantro_jpeg_header_assemble(struct hantro_jpeg_ctx *ctx)
 
 	jpeg_set_quality(ctx);
 }
+
+/*
+ * Worst case for the quality set at the time of S_FMT, with the header
+ * above: 4:2:0, the Annex K Huffman tables and the quantizers of
+ * jpeg_set_quality(). A request is clamped to the quality 100 size, so
+ * one sized for a later quality raise still fits.
+ */
+u32 hantro_jpeg_enc_sizeimage(const struct hantro_fmt *fmt, int quality,
+			      u32 width, u32 height, u32 sizeimage)
+{
+	u32 bytes;
+
+	if (sizeimage)
+		return clamp(sizeimage, fmt->min_size,
+			     fmt->header_size + width * height * 5);
+
+	if (quality >= 95)
+		bytes = 5;
+	else if (quality >= 84)
+		bytes = 3;
+	else
+		bytes = 2;
+
+	return fmt->header_size + width * height * bytes;
+}
diff --git a/drivers/media/platform/verisilicon/hantro_jpeg.h b/drivers/media/platform/verisilicon/hantro_jpeg.h
index 0b49d0b82caa..1f5582df5244 100644
--- a/drivers/media/platform/verisilicon/hantro_jpeg.h
+++ b/drivers/media/platform/verisilicon/hantro_jpeg.h
@@ -1,5 +1,7 @@
 /* SPDX-License-Identifier: GPL-2.0+ */
 
+struct hantro_fmt;
+
 #define JPEG_HEADER_SIZE	624
 #define JPEG_QUANT_SIZE		64
 
@@ -13,3 +15,5 @@ struct hantro_jpeg_ctx {
 };
 
 void hantro_jpeg_header_assemble(struct hantro_jpeg_ctx *ctx);
+u32 hantro_jpeg_enc_sizeimage(const struct hantro_fmt *fmt, int quality,
+			      u32 width, u32 height, u32 sizeimage);
diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index b3dbc0629d25..5e8d8de072a8 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -26,6 +26,7 @@
 
 #include "hantro.h"
 #include "hantro_hw.h"
+#include "hantro_jpeg.h"
 #include "hantro_v4l2.h"
 
 #define  HANTRO_DEFAULT_BIT_DEPTH 8
@@ -386,6 +387,11 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 			pix_mp->plane_fmt[0].sizeimage +=
 				hantro_av1_mv_size(pix_mp->width,
 						   pix_mp->height);
+	} else if (fmt->codec_mode == HANTRO_MODE_JPEG_ENC) {
+		pix_mp->plane_fmt[0].sizeimage =
+			hantro_jpeg_enc_sizeimage(fmt, ctx->jpeg_quality,
+						  pix_mp->width, pix_mp->height,
+						  pix_mp->plane_fmt[0].sizeimage);
 	} else if (!pix_mp->plane_fmt[0].sizeimage) {
 		/*
 		 * For coded formats the application can specify

---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261127-hantro-enc-sizestep-4265d85ea124
prerequisite-message-id: <20261124-hantro-buflimit-v3-0-780903970ca0@gmail.com>
prerequisite-patch-id: bbf362b5a6b3ef0c7424c424979bbbdb7934aaf1
prerequisite-patch-id: 3d509ba55530afd4d418732df88696e105e36512
prerequisite-patch-id: bb3462a5633f2af738ddecf3915a8a3121e20611

Best regards,
-- 
Sergei Khomenkov <shomenkow@gmail.com>

