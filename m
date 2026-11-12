From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:54:55 +0000
Subject: [PATCH v2 1/6] media: verisilicon: Support holding the CAPTURE
 buffer for MPEG-2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hantro-codec-fixes-v2-1-f44424df585b@gmail.com>
References: <20261112-hantro-codec-fixes-v2-0-f44424df585b@gmail.com>
In-Reply-To: <20261112-hantro-codec-fixes-v2-0-f44424df585b@gmail.com>
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
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473695; l=2131;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=BG5kaLLN/ROlelCT7uSwGI2mCcFqWk5IizY+1FV3tNk=;
 b=yXPRYR2wiGuZ1YcJfg2Z2ApU6rSML13Ry0jpgE96Hrl1t/aHvg6/w7SCinDYdf93XffeCuZRx
 IX6v3cMc7ZnB3G8wc3g9cgbavJ8Y6rd1z0qMm1iBRQ+wBMVdZU4XJKr
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An MPEG-2 frame can be coded as two field pictures, each decoded by its
own request. Both fields have to land in the same CAPTURE buffer: the
G1 and VPU2 back-ends already write a bottom field one line into the
destination buffer and use the current buffer as the reference for the
second field of a P picture, so the second field must be decoded into
the buffer that holds the first one.

Userspace asks for that with V4L2_BUF_FLAG_M2M_HOLD_CAPTURE_BUF, which
the driver only allows for H.264. GStreamer's v4l2slmpeg2dec sets it on
the first field of every field-coded frame, so queueing that request
fails ("Driver does not support holding capture buffer") and decoding
stops. On RK3588 none of the field-picture streams of the ISO/IEC
13818-4 main-profile conformance suite (sony-ct1..4, tcela-8/9/10/16/19,
hhi_burst_*) decoded.

Allow holding the CAPTURE buffer for MPEG-2 too. Job completion goes
through v4l2_m2m_buf_done_and_job_finish(), which already keeps a held
CAPTURE buffer queued until the last field has been decoded.

Fixes: 340ce50f75a6 ("media: hantro: Enable HOLD_CAPTURE_BUF for H.264")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 83af9fa1ce94..822c4b371671 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -513,13 +513,13 @@ hantro_update_requires_hold_capture_buf(struct hantro_ctx *ctx, u32 fourcc)
 
 	switch (fourcc) {
 	case V4L2_PIX_FMT_JPEG:
-	case V4L2_PIX_FMT_MPEG2_SLICE:
 	case V4L2_PIX_FMT_VP8_FRAME:
 	case V4L2_PIX_FMT_HEVC_SLICE:
 	case V4L2_PIX_FMT_VP9_FRAME:
 		vq->subsystem_flags &= ~(VB2_V4L2_FL_SUPPORTS_M2M_HOLD_CAPTURE_BUF);
 		break;
 	case V4L2_PIX_FMT_H264_SLICE:
+	case V4L2_PIX_FMT_MPEG2_SLICE:
 		vq->subsystem_flags |= VB2_V4L2_FL_SUPPORTS_M2M_HOLD_CAPTURE_BUF;
 		break;
 	default:

-- 
2.55.0

