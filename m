From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Tue, 24 Nov 2026 16:40:19 +0300
Subject: [PATCH v3 3/3] media: verisilicon: leave room for the JPEG header
 and one stream burst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-hantro-buflimit-v3-3-780903970ca0@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795527620; l=4102;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=TiSzcOqC25j0e7itf9kkOEO+cKiYOn5aUH2hDB8nhgU=;
 b=jW5fYvcKbkWssPYObNaxhqM72zSZMbb7b9O5FS5MeHiXeZaCt+uToeE5hT7tZlwAb6E5w6MmS
 /2PZNFVgMCDCCXe4zrVtiIAfl6r4rv5Z1iSXTCBy4U2fQf7khO2rOPZ
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hantro_try_fmt() keeps any non-zero CAPTURE sizeimage of the JPEG
encoder, however small. The CPU writes the 624-byte header into the
plane, and on the RK3026 the H1 then writes at least one 64-byte burst
even with a stream limit of 0, so a smaller plane is written past its
end. A plane smaller than the header also makes the WARN_ON() in
hantro_h1_jpeg_enc_set_buffers() fire on every job.

Add a minimum plane size to struct hantro_fmt, set it to header_size +
64 in the JPEG encoder formats of the Rockchip and STM32MP25 variants,
and raise a smaller coded sizeimage to it in hantro_try_fmt().

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board; the assistant also drafted this change. Tested
on that board: a sizeimage of 1 or 600 now reads back 688, and frames
that do not fit a 688-byte plane stop exactly at its end. Not tested on
other SoCs.
---
 drivers/media/platform/verisilicon/hantro.h           | 2 ++
 drivers/media/platform/verisilicon/hantro_v4l2.c      | 3 +++
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c  | 1 +
 drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c | 1 +
 4 files changed, 7 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro.h b/drivers/media/platform/verisilicon/hantro.h
index 0353de154a1e..f51beae79f1f 100644
--- a/drivers/media/platform/verisilicon/hantro.h
+++ b/drivers/media/platform/verisilicon/hantro.h
@@ -286,6 +286,7 @@ struct hantro_ctx {
  * @codec_mode:	Codec mode related to this format. See
  *		enum hantro_codec_mode.
  * @header_size: Optional header size. Currently used by JPEG encoder.
+ * @min_size:	Optional minimum sizeimage, for bitstream formats.
  * @max_depth:	Maximum depth, for bitstream formats
  * @enc_fmt:	Format identifier for encoder registers.
  * @frmsize:	Supported range of frame sizes (only for bitstream formats).
@@ -297,6 +298,7 @@ struct hantro_fmt {
 	u32 fourcc;
 	enum hantro_codec_mode codec_mode;
 	int header_size;
+	u32 min_size;
 	int max_depth;
 	enum hantro_enc_fmt enc_fmt;
 	struct v4l2_frmsize_stepwise frmsize;
diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 83af9fa1ce94..b3dbc0629d25 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -394,6 +394,9 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 		 */
 		pix_mp->plane_fmt[0].sizeimage = fmt->header_size +
 			pix_mp->width * pix_mp->height * fmt->max_depth;
+	} else {
+		pix_mp->plane_fmt[0].sizeimage =
+			max(pix_mp->plane_fmt[0].sizeimage, fmt->min_size);
 	}
 
 	return 0;
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index d201b058e5e8..ab5abe2c78ad 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -50,6 +50,7 @@ static const struct hantro_fmt rockchip_vpu_enc_fmts[] = {
 		.codec_mode = HANTRO_MODE_JPEG_ENC,
 		.max_depth = 2,
 		.header_size = JPEG_HEADER_SIZE,
+		.min_size = JPEG_HEADER_SIZE + 64,	/* header + one burst */
 		.frmsize = {
 			.min_width = 96,
 			.max_width = 8192,
diff --git a/drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c b/drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c
index 833821120b20..3f337554e936 100644
--- a/drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c
@@ -83,6 +83,7 @@ static const struct hantro_fmt stm32mp25_venc_fmts[] = {
 		.codec_mode = HANTRO_MODE_JPEG_ENC,
 		.max_depth = 2,
 		.header_size = JPEG_HEADER_SIZE,
+		.min_size = JPEG_HEADER_SIZE + 64,	/* header + one burst */
 		.frmsize = {
 			.min_width = 96,
 			.max_width = FMT_4K_WIDTH,

-- 
2.53.0

