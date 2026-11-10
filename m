From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:30 +0000
Subject: [PATCH 1/2] media: rkvdec: vdpu381: Compress the co-located motion
 vectors of H.264
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvdec-colmv-v1-1-012b84ea43f7@gmail.com>
References: <20261110-rkvdec-colmv-v1-0-012b84ea43f7@gmail.com>
In-Reply-To: <20261110-rkvdec-colmv-v1-0-012b84ea43f7@gmail.com>
To: Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295110; l=4313;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ybXnDgp5I8D2JJsP+6qloNGqCzU5IJqFRabb2XdAB/Y=;
 b=HaXOWx//OEJFbzyvP1ryFMhNtoiX9Vl9j4SpdcMcbIXsZVkjTKblV4ft4iZDUIWhKlkZfVL8g
 r7a8M1zPurnDz3MSOd9OlUMaQ5ZmLQqgXZBtyrM4c2dWQNi5YLlegx/
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VDPU381 can store the co-located motion vectors of a frame
compressed (reg012 colmv_compress_en). The vendor code (MPP,
hal_h264d_vdpu34x.c) enables it for H.264 streams without field
pictures or MBAFF, and for HEVC. Mainline never does.

B-frames are what limits H.264 decoding at 4K: the core is 99% busy,
and a B-frame of a 48 Mbit/s 4K stream takes 16 ms of hardware time
against 10.8 ms for a P-frame and 7.0 ms for an I-frame. Storing the
motion vectors compressed cuts that memory traffic. Decoding the same
240 frames to fakevideosink on RK3588 goes from 65.4 to 68.4 fps at
3840x2160 (+4.7%) and from 214 to 234 fps at 1920x1080 (+9%). The
decoded frames are identical (same checksum for all 240 frames, and
bit-exact with FFmpeg).

The compressed layout is made of 64x16-pixel segments, each with a
header and up to 1 KiB of payload. How much of that is used depends on
the content and can exceed the uncompressed layout: the hardware wrote
up to 556128 bytes compressed against 522240 uncompressed for the
motion vectors of a 4K HEVC stream. So reserve what the vendor code
reserves for the compressed layout on VDPU381, which is twice the
current 128 bytes per macroblock: 8.3 MB instead of 4.1 MB per 4K
CAPTURE buffer.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../platform/rockchip/rkvdec/rkvdec-vdpu381-h264.c     | 10 ++++++++++
 drivers/media/platform/rockchip/rkvdec/rkvdec.c        | 18 +++++++++++++++++-
 2 files changed, 27 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-h264.c b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-h264.c
index b961fddc8583..06d83a6ed617 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-h264.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-h264.c
@@ -237,6 +237,16 @@ static void config_registers(struct rkvdec_ctx *ctx,
 	regs->common.reg011_important_en.dec_timeout_e = 1;
 	regs->common.reg011_important_en.pix_range_det_e = 1;
 
+	/*
+	 * Store the co-located motion vectors compressed, as the vendor code
+	 * does for frame-only streams. This cuts the memory traffic of
+	 * B-frames and the hardware time of 4K streams by about 5%. The
+	 * compressed data fits the space reserved for the uncompressed
+	 * layout. Field and MBAFF streams use the uncompressed layout.
+	 */
+	regs->common.reg012_secondary_en.colmv_compress_en =
+		!!(run->sps->flags & V4L2_H264_SPS_FLAG_FRAME_MBS_ONLY);
+
 	/*
 	 * Even though the scan list address can be set in RPS,
 	 * with some frames, it will try to use the address set in the register.
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec.c b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
index fbcd0f175ad3..5f7e876da6eb 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
@@ -20,6 +20,7 @@
 #include <linux/platform_device.h>
 #include <linux/pm.h>
 #include <linux/pm_runtime.h>
+#include <linux/sizes.h>
 #include <linux/slab.h>
 #include <linux/videodev2.h>
 #include <linux/workqueue.h>
@@ -93,6 +94,21 @@ static u32 rkvdec_colmv_size(u16 width, u16 height)
 	return 128 * DIV_ROUND_UP(width, 16) * DIV_ROUND_UP(height, 16);
 }
 
+/*
+ * The VDPU381 stores co-located motion vectors compressed, in segments of
+ * 64x16 pixels, with a segment header (rows padded to 16 headers)
+ * and up to 1 KiB of payload. That's the bound the vendor code allocates;
+ * how much is used depends on the content, and can be more than the
+ * uncompressed layout of rkvdec_colmv_size() takes.
+ */
+static u32 vdpu381_colmv_size(u16 width, u16 height)
+{
+	u32 seg_w = DIV_ROUND_UP(width, 64);
+	u32 seg_h = DIV_ROUND_UP(height, 16);
+
+	return ALIGN(ALIGN(seg_w, 16) * seg_h + seg_w * seg_h * SZ_1K, 128);
+}
+
 static u32 vdpu383_colmv_size(u16 width, u16 height)
 {
 	return ALIGN(width, 64) * ALIGN(height, 16);
@@ -1700,7 +1716,7 @@ static const struct rcb_size_info vdpu381_rcb_sizes[] = {
 
 static const struct rkvdec_variant_ops vdpu381_variant_ops = {
 	.irq_handler = vdpu381_irq_handler,
-	.colmv_size = rkvdec_colmv_size,
+	.colmv_size = vdpu381_colmv_size,
 	.flatten_matrices = transpose_and_flatten_matrices,
 };
 

-- 
2.55.0

