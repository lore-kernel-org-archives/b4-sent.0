From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 20 Nov 2026 01:10:40 +0000
Subject: [PATCH 2/2] media: rkvdec: Decode monochrome H.264 to GREY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-b4-h264-monochrome-grey-v1-2-887102a688fd@gmail.com>
References: <20261120-b4-h264-monochrome-grey-v1-0-887102a688fd@gmail.com>
In-Reply-To: <20261120-b4-h264-monochrome-grey-v1-0-887102a688fd@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795137038; l=2530;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=PaUrtuP231glBes9RSGbgqUD4OET3z2k5Uwhdrm6JOc=;
 b=ziqFhy0u+TcXxphBaKndOpcw060D4mWES5y6K3+Q8++wHVqYdqkdxbv075+tUd/TcQEdUHgXW
 bAsn9WYaHQLC8/BMFlgDI6p46QTkdHZA8gcNCvItWxKy6W3ODncr0yu
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The decoder writes only the luma plane of a 4:0:0 H.264 picture, but
the driver offers NV12, so userspace gets a chroma plane the decoder
never wrote (green or stale pictures). JVT-FR-EXT HPCAMOLQ_BRCM_B and
HPCVMOLQ_BRCM_B fail although their luma is bit-exact.

Offer GREY for 8-bit 4:0:0 streams. There is no V4L2 format for the
packed 10-bit luma that 10-bit 4:0:0 would need, so those keep NV15.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/rockchip/rkvdec/rkvdec-h264-common.c | 4 +++-
 drivers/media/platform/rockchip/rkvdec/rkvdec.c             | 4 ++++
 drivers/media/platform/rockchip/rkvdec/rkvdec.h             | 1 +
 3 files changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec-h264-common.c b/drivers/media/platform/rockchip/rkvdec/rkvdec-h264-common.c
index 54639512e456..8ad41c4e56c8 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec-h264-common.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec-h264-common.c
@@ -146,7 +146,9 @@ enum rkvdec_image_fmt rkvdec_h264_get_image_fmt(struct rkvdec_ctx *ctx,
 		return RKVDEC_IMG_FMT_ANY;
 
 	if (sps->bit_depth_luma_minus8 == 0) {
-		if (sps->chroma_format_idc == 2)
+		if (sps->chroma_format_idc == 0)
+			return RKVDEC_IMG_FMT_400_8BIT;
+		else if (sps->chroma_format_idc == 2)
 			return RKVDEC_IMG_FMT_422_8BIT;
 		else
 			return RKVDEC_IMG_FMT_420_8BIT;
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec.c b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
index fbcd0f175ad3..548659d23bc2 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
@@ -414,6 +414,10 @@ static const struct rkvdec_decoded_fmt_desc rkvdec_h264_decoded_fmts[] = {
 		.fourcc = V4L2_PIX_FMT_NV20,
 		.image_fmt = RKVDEC_IMG_FMT_422_10BIT,
 	},
+	{
+		.fourcc = V4L2_PIX_FMT_GREY,
+		.image_fmt = RKVDEC_IMG_FMT_400_8BIT,
+	},
 };
 
 static const struct rkvdec_ctrl_desc rkvdec_vp9_ctrl_descs[] = {
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec.h b/drivers/media/platform/rockchip/rkvdec/rkvdec.h
index a24be6638b6b..58c53a1f58b3 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec.h
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec.h
@@ -108,6 +108,7 @@ enum rkvdec_image_fmt {
 	RKVDEC_IMG_FMT_420_10BIT,
 	RKVDEC_IMG_FMT_422_8BIT,
 	RKVDEC_IMG_FMT_422_10BIT,
+	RKVDEC_IMG_FMT_400_8BIT,
 };
 
 struct rkvdec_decoded_fmt_desc {

-- 
2.55.0

