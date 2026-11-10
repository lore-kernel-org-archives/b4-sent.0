From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:01 +0000
Subject: [PATCH 6/6] media: verisilicon: rockchip: Limit the JPEG encoder
 to 8176x8176
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-jpeg-enc-fixes-v1-6-fc4dc7e985d2@gmail.com>
References: <20261110-hantro-jpeg-enc-fixes-v1-0-fc4dc7e985d2@gmail.com>
In-Reply-To: <20261110-hantro-jpeg-enc-fixes-v1-0-fc4dc7e985d2@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Boris Brezillon <boris.brezillon@collabora.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295075; l=2124;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=YcQepcs/kiqGO0VYJKSScKTM3/q57290AfxfFBFuGJE=;
 b=1+8p98vHStkEBOrBQLzikJyt9X7HUs6F5Qbcu93cIySUhBBC0ChChkoaPM+/PzBYUA0rxE/4r
 Yd2zb2U/jfdB1XlESEAqh0u4gswbvk48/dwzF8nON+0hXuT2otryzgS
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rockchip JPEG encoders advertise frame sizes up to 8192x8192, but
both register layouts take the picture size in 9-bit macroblock counts:

 - VEPU2 (RK3399, RK3568, PX30, RK3588 VEPU121): enc_width is bits 16:8
   and enc_height bits 28:20 of the encoder start register.
   rockchip_vpu2_jpeg_enc_run() masks the counts with 0x1ff, so an 8192
   pixel (512 macroblock) dimension is programmed as 0 macroblocks.
   Setting the bit above each field on an RK3588 VEPU121 did not give a
   512 macroblock picture either, so the fields really are 9 bits wide.
 - H1 (RK3066, RK3288): the height count starts at bit 10 and the width
   count at bit 19, so a 512 macroblock height runs into the width field.

Limit the shared format table to 511 macroblocks, 8176 pixels, so
userspace gets the largest size the hardware can encode instead of a
corrupt or timed out frame.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 02673be9878e..f8079f96c398 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -20,6 +20,13 @@
 
 #define ROCKCHIP_VPU981_MIN_SIZE 64
 
+/*
+ * The H1 and VEPU2 JPEG encoders take the picture size in macroblocks in
+ * 9-bit register fields, so 511 macroblocks (8176 pixels) is the largest
+ * width and height they can encode.
+ */
+#define ROCKCHIP_VPU_JPEG_ENC_MAX_SIZE (511 * MB_DIM)
+
 /*
  * Supported formats.
  */
@@ -52,10 +59,10 @@ static const struct hantro_fmt rockchip_vpu_enc_fmts[] = {
 		.header_size = JPEG_HEADER_SIZE,
 		.frmsize = {
 			.min_width = 96,
-			.max_width = 8192,
+			.max_width = ROCKCHIP_VPU_JPEG_ENC_MAX_SIZE,
 			.step_width = MB_DIM,
 			.min_height = 32,
-			.max_height = 8192,
+			.max_height = ROCKCHIP_VPU_JPEG_ENC_MAX_SIZE,
 			.step_height = MB_DIM,
 		},
 	},

-- 
2.55.0

