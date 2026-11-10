From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:29 +0000
Subject: [PATCH 3/4] media: verisilicon: Don't offer VP8 above 1080p on the
 Rockchip VDPU2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-codec-fixes-v1-3-0fd5372ce831@gmail.com>
References: <20261110-hantro-codec-fixes-v1-0-0fd5372ce831@gmail.com>
In-Reply-To: <20261110-hantro-codec-fixes-v1-0-0fd5372ce831@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sebastian Fricke <sebastian.fricke@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Jonas Karlman <jonas@kwiboo.se>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Jeffy Chen <jeffy.chen@rock-chips.com>, Tomasz Figa <tfiga@chromium.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295107; l=2123;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=EXI8QBEeHs1R1u0NRn+cDDndC1H6YMS5/uVvMAcEFAg=;
 b=m4jnbHaknfIBjsaMF7gll6ze3KeL+9wDGhUJowJvUWrLufyEswgM3m6nX5sHrSaksG/83qNC2
 jyJ2Yoqy9NxCbqgeusDMt43iYdOG9tPyDN2VW7BiVS6wMBmkyprlDYJ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VDPU2 decoder format tables (RK3328, RK3568, RK3588 VPU121) and the
RK3399 one let the VP8 OUTPUT format go up to 3840x2160, but their only
CAPTURE format, NV12, stops at 1920x1088, and the CAPTURE size is
clamped to it. A 4K VP8 stream is therefore accepted on OUTPUT and then
decoded into a 1920x1088 buffer: on RK3588 GStreamer v4l2slvp8dec runs
into "gst_video_frame_map_id: assertion 'info->width <= meta->width'
failed" for every frame of a 3840x2160 stream and none of the frames
match FFmpeg.

Nothing above 1080p can be decoded with these tables, so don't
advertise it: limit VP8 to the 1920x1088 of the other codecs and of the
CAPTURE format. Userspace that checks VIDIOC_ENUM_FRAMESIZES, and the
S_FMT clamping, then know that a 4K VP8 stream needs another decoder.

Fixes: 73fb5bfa53e9 ("media: hantro: Support RK3399 VP8 decoding")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 02673be9878e..2b6242c1fb86 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -274,10 +274,10 @@ static const struct hantro_fmt rockchip_vdpu2_dec_fmts[] = {
 		.max_depth = 2,
 		.frmsize = {
 			.min_width = FMT_MIN_WIDTH,
-			.max_width = FMT_UHD_WIDTH,
+			.max_width = FMT_FHD_WIDTH,
 			.step_width = MB_DIM,
 			.min_height = FMT_MIN_HEIGHT,
-			.max_height = FMT_UHD_HEIGHT,
+			.max_height = FMT_FHD_HEIGHT,
 			.step_height = MB_DIM,
 		},
 	},
@@ -315,10 +315,10 @@ static const struct hantro_fmt rk3399_vpu_dec_fmts[] = {
 		.max_depth = 2,
 		.frmsize = {
 			.min_width = FMT_MIN_WIDTH,
-			.max_width = FMT_UHD_WIDTH,
+			.max_width = FMT_FHD_WIDTH,
 			.step_width = MB_DIM,
 			.min_height = FMT_MIN_HEIGHT,
-			.max_height = FMT_UHD_HEIGHT,
+			.max_height = FMT_FHD_HEIGHT,
 			.step_height = MB_DIM,
 		},
 	},

-- 
2.55.0

