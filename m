From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/6] media: verisilicon: Fix MPEG-2 field pictures, 4K
 VP8 and the AV1 tile buffers
Date: Thu, 12 Nov 2026 08:54:54 +0000
Message-Id: <20261112-hantro-codec-fixes-v2-0-f44424df585b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NSw6CMBCGr0Jm7Zi2PBRX3sOwgOkAY4SaFomGc
 HcL7l1+/3OBwF44wCVZwPMsQdwYwRwSoL4eO0axkcEoU2itFUZx8g7JWSZs5c0B89JmpskLVVI
 Gsfj0vBuxd6t+HF7NnWnalrZEL2Fy/rO/znrL/T2YNSpUrc3TkyE+p/raDbU8juQGqNZ1/QJi/
 bxLxgAAAA==
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
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473695; l=5709;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=14/Usk3FROrX4ekaBxCq2un3fe3l8v6T1pUSFIb3wbU=;
 b=I8FCbKxmDlXAbZTZczzBATxWUVvHQmGp4VI0DT5ZEhNxCJ4YuU/yy8ZU5s447PCqx6ts3oD/S
 aC/QOYxxEz5BLLGSQmeL/RRi0jNz4t2pmf0j91/5WXrgTZG1Evte4Gi
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes for the Hantro decoders on Rockchip SoCs, found while running
conformance streams and v4l2-compliance on the RK3588.

Patches 1 and 2 make field-coded MPEG-2 decode on the G1 and VPU2: the
driver refused V4L2_BUF_FLAG_M2M_HOLD_CAPTURE_BUF for MPEG-2, so the
second field of a frame could not land in the same CAPTURE buffer as the
first one, and once it can, the second field was identified with
top_field_first, which is always 0 in field pictures, so it predicted
from the wrong field. None of the field-picture streams of the ISO/IEC
13818-4 main-profile suite decoded before; they decode now.

Patch 3 stops advertising VP8 above 1080p on the VDPU2 and RK3399
tables, whose only CAPTURE format stops at 1920x1088, so that a 4K VP8
stream is refused instead of mis-decoded.

Patch 4 fixes the reuse check of the VPU981 AV1 tile column buffers,
which only compared the deblocking data buffer although the five buffers
scale differently with the frame height, bit depth and number of tile
columns, and clears the sizes when the buffers are freed.

Patches 5 and 6 reject malformed AV1 frames before the decoder is
programmed with them. With no tile columns the tile column buffers are
sized to zero and the decoder runs without them (patch 5). A frame that
is larger than the CAPTURE format does not fit in the buffer the decoder
writes it to, whose size and layout come from the format, and a frame
height beyond the limit of the decoder also wraps the 32-bit size
computation of the tile column buffers, which leaves them too small for
the height programmed into the hardware (patch 6). Both are rejected at
prepare time.

Tested on an Orange Pi 5 (RK3588S). Patches 1 and 2 were verified with
the ISO/IEC 13818-4 main-profile conformance streams through GStreamer's
v4l2slmpeg2dec on the VPU121, compared with FFmpeg: the field-picture
streams (sony-ct1..4, tcela-8/9/10, hhi_burst_short/long) went from
rejected to 53-67 dB PSNR, and the 26 frame-picture streams are
unchanged. Patch 3: the VPU121 decoder lists VP8F frame sizes from 48x48
to 1920x1088, S_FMT of a 3840x2160 VP8 OUTPUT format is clamped to
1920x1088, a 1080p VP8 clip still decodes bit-exact against libvpx, and
the 4K clip is now refused instead of decoded into 1920x1088 buffers.
Patch 4: one v4l2slav1dec context decoding a 1920x1080 10-bit
4-tile-column stream and then an 8-bit 5-column one (and 2048x128 with 4
then 8 columns) is bit-exact against libdav1d, 32/32 frames each, and a
kprobe trace of the DMA allocations shows the tile buffers reallocated
when the second stream needs larger ones.

The new rejects of patches 5 and 6 were tested on the board with v2:
requests with a no-tile AV1 frame, with a frame height that wraps, and
with a frame that is wider, taller or, through superres, upscaled wider
than the 1920x1088 CAPTURE format (3840x2160 among them) are each not
decoded and both of their buffers come back with V4L2_BUF_FLAG_ERROR,
and a frame of the format size and a smaller one after them are still
accepted. Four runs of the fluster AV1 conformance suite give 203/242
each, failing the same 39 vectors as an earlier run on the same board;
the streams that change the frame size and the ones with spatial layers
still decode. In a fifth run av1-1-b8-06-mfmv also failed, with one
decoder timeout and no reject; it passed in the other four runs. The
board kernel is 7.3-based and also carries a fix for the ->run() error
paths (the AV1 one finishes a refused job twice), which Sascha Hauer's
series "media: verisilicon: Fix error paths in hantro drivers" addresses
upstream [1].

[1] https://lore.kernel.org/all/20260824-rk3588-jpegdec-v1-0-180a30a2852d@pengutronix.de/

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v2:
- New patch 5: reject an AV1 frame with no tile columns, which would
  otherwise size the tile column buffers to zero (Sashiko: AV1
  tile_cols == 0)
- New patch 6: reject an AV1 frame larger than the CAPTURE format, which
  does not fit in the buffers of the decoder and whose height can
  otherwise wrap the 32-bit size computation of the tile column buffers
  (Sashiko: u32 overflow from frame_height_minus_1)
- Patches 1-4 unchanged
- Link to v1: https://patch.msgid.link/20261110-hantro-codec-fixes-v1-0-0fd5372ce831@gmail.com

---
Arun Iyengar (6):
      media: verisilicon: Support holding the CAPTURE buffer for MPEG-2
      media: verisilicon: Find the second MPEG-2 field without top_field_first
      media: verisilicon: Don't offer VP8 above 1080p on the Rockchip VDPU2
      media: verisilicon: Check every VPU981 AV1 tile column buffer before reusing them
      media: verisilicon: Reject AV1 frames without tiles
      media: verisilicon: Reject AV1 frames larger than the CAPTURE format

 .../platform/verisilicon/hantro_g1_mpeg2_dec.c     |  8 ++--
 drivers/media/platform/verisilicon/hantro_hw.h     |  8 ++++
 drivers/media/platform/verisilicon/hantro_mpeg2.c  | 31 +++++++++++++
 drivers/media/platform/verisilicon/hantro_v4l2.c   |  2 +-
 .../verisilicon/rockchip_vpu2_hw_mpeg2_dec.c       |  8 ++--
 .../verisilicon/rockchip_vpu981_hw_av1_dec.c       | 53 +++++++++++++++++++---
 .../media/platform/verisilicon/rockchip_vpu_hw.c   |  8 ++--
 7 files changed, 98 insertions(+), 20 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-hantro-codec-fixes-59d42b5609c4

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

