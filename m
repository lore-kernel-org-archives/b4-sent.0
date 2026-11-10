From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/4] media: verisilicon: Fix MPEG-2 field pictures, 4K VP8
 and the AV1 tile buffers
Date: Tue, 10 Nov 2026 07:18:26 +0000
Message-Id: <20261110-hantro-codec-fixes-v1-0-0fd5372ce831@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDQAxFryJZG5gZVNCrlC40E9u4cMrESmHw7
 o26fO/zfgHlLKwwVAUy76KSVgNfV0DvcX0xSjSG4ELnvXdocssJKUUmnOXHim0fmzC1neupAQs
 /ma/BusfzZv1OC9N2PsFx/AHaqUFodgAAAA==
X-Change-ID: 20261110-hantro-codec-fixes-59d42b5609c4
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
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295107; l=3328;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=igKj8pTGOK6tivQwkwcLG6VEOzLgnx6XNOOP3PoXh9c=;
 b=po4a40qKFMdHWavWbHbTpxo2TTFFZidjqDgVh19ZpmM/OYO76L6v1ER9lIrbL/+bP95avKUvL
 RU60OlJGE1pDu7MzH57U2amsU/77XY3T0RKqNTisqMTknKzsQuOi1mO
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Four fixes for the Hantro decoders on Rockchip SoCs, found while running
conformance streams and v4l2-compliance on the RK3588.

Patches 1 and 2 make field-coded MPEG-2 decode on the G1 and VPU2: the
driver refused V4L2_BUF_FLAG_M2M_HOLD_CAPTURE_BUF for MPEG-2, so the
second field of a frame could not land in the same CAPTURE buffer as
the first one, and once it can, the second field was identified with
top_field_first, which is always 0 in field pictures, so it predicted
from the wrong field. None of the field-picture streams of the ISO/IEC
13818-4 main-profile suite decoded before; they decode now.

Patch 3 stops advertising VP8 above 1080p on the VDPU2 and RK3399
tables, whose only CAPTURE format stops at 1920x1088, so that a 4K VP8
stream is refused instead of mis-decoded.

Patch 4 fixes the reuse check of the VPU981 AV1 tile column buffers,
which only compared the deblocking data buffer although the five
buffers scale differently with the frame height, bit depth and number
of tile columns, and clears the sizes when the buffers are freed.

Tested on an Orange Pi 5 (RK3588S). Patches 1 and 2 were verified with
the ISO/IEC 13818-4 main-profile conformance streams through GStreamer's
v4l2slmpeg2dec on the VPU121, compared with FFmpeg: the field-picture
streams (sony-ct1..4, tcela-8/9/10, hhi_burst_short/long) went from
rejected to 53-67 dB PSNR, and the 26 frame-picture streams are
unchanged. Patch 3: the VPU121 decoder lists VP8F frame sizes from
48x48 to 1920x1088, S_FMT of a 3840x2160 VP8 OUTPUT format is clamped to
1920x1088, a 1080p VP8 clip still decodes bit-exact against libvpx, and
the 4K clip is now refused instead of decoded into 1920x1088 buffers.
Patch 4: one v4l2slav1dec context decoding a 1920x1080 10-bit
4-tile-column stream and then an 8-bit 5-column one (and 2048x128 with
4 then 8 columns) is bit-exact against libdav1d, 32/32 frames each, and
a kprobe trace of the DMA allocations shows the tile buffers
reallocated when the second stream needs larger ones.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (4):
      media: verisilicon: Support holding the CAPTURE buffer for MPEG-2
      media: verisilicon: Find the second MPEG-2 field without top_field_first
      media: verisilicon: Don't offer VP8 above 1080p on the Rockchip VDPU2
      media: verisilicon: Check every VPU981 AV1 tile column buffer before reusing them

 .../platform/verisilicon/hantro_g1_mpeg2_dec.c     |  8 ++---
 drivers/media/platform/verisilicon/hantro_hw.h     |  8 +++++
 drivers/media/platform/verisilicon/hantro_mpeg2.c  | 31 ++++++++++++++++++++
 drivers/media/platform/verisilicon/hantro_v4l2.c   |  2 +-
 .../verisilicon/rockchip_vpu2_hw_mpeg2_dec.c       |  8 ++---
 .../verisilicon/rockchip_vpu981_hw_av1_dec.c       | 34 +++++++++++++++++-----
 .../media/platform/verisilicon/rockchip_vpu_hw.c   |  8 ++---
 7 files changed, 79 insertions(+), 20 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-hantro-codec-fixes-59d42b5609c4

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

