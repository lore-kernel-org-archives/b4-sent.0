From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/6] media: verisilicon: Fix the JPEG encoder format
 handling
Date: Tue, 10 Nov 2026 07:17:55 +0000
Message-Id: <20261110-hantro-jpeg-enc-fixes-v1-0-fc4dc7e985d2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQ6CUAwEf4X0bBNKDBF/xXiA5xbL4UFekZgQ/
 t2qx5nN7E6OYnC6VjsVbOY25wA5VZSefR7B9gimpm5aEak55FpmnhaMjJxY7Q3nTvUyaNufO1G
 Kdin4DZHe7n/21zAhrd8zOo4Pg5Gx2HkAAAA=
X-Change-ID: 20261110-hantro-jpeg-enc-fixes-9ff8bf6a491f
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295075; l=3705;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=l9EdD9HrzhlWt2Mxz7G0VDbz8OEfjBCsYmrzJUDKy3g=;
 b=pi/yod5JmjP0rOoxwnmNHQb0ZQ9V1eeK6lS4pqG836wIV8uK2VFJ0ld9b0TW9Sn74GkP4W7tE
 RWNvxT+f1D5CsFH+e3+Jq+ye8xhJODewYuTAGrk7Fy1Bks++w55aSky
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the format handling of the Hantro JPEG encoders,
found with v4l2-ctl, v4l2-compliance and GStreamer on the RK3588
VEPU121.

The encoder accepted a CAPTURE sizeimage far too small for the selected
resolution, and setting the OUTPUT format never updated the coded size,
so the sequence mandated by the stateful encoder specification (CAPTURE
format first, then OUTPUT) left a 96x32 coded format under a 1920x1088
raw one. The JPEG encoders program the hardware from the OUTPUT size
and use the difference as the crop inside the last macroblock, so this
ended in IOMMU page faults, a frame processing timeout and a wedged
encoder. Patches 1 and 2 fix the two ioctl paths, patch 3 refuses a job
whose geometry or CAPTURE buffer the hardware can't be programmed with,
as a last line of defence, and patch 4 reports the fixed colorimetry of
JPEG instead of propagating whatever the application set, which also
fixes a v4l2-compliance failure on the encoder.

Patch 5 fixes a CAPTURE S_FMT that v4l2-ctl --stream-mmap issues after
the OUTPUT queue is set up: it failed with -EBUSY but left the raw
format descriptor reset to the default (three planes) under a
negotiated two-plane format, so the next job read a plane from IOVA 0.

Patch 6 limits the advertised frame size to 8176x8176: both Rockchip
encoder register layouts hold the size in 9-bit macroblock counts, so
8192 was programmed as 0 macroblocks.

Tested on an Orange Pi 5 (RK3588S, VEPU121): with patches 1-5, an
explicit CAPTURE 1920x1080 JPEG plus OUTPUT NM12 stream gives 8
decodable 1920x1088 frames, a requested sizeimage of 1000 is raised to
4178544 and a larger one is kept, G_FMT on CAPTURE follows the OUTPUT
format, v4l2-compliance passes 49/49 (58/58 with streaming) with sRGB /
ITU-R 601 / full range on both queues, nine GStreamer v4l2jpegenc
pipelines reach EOS, and v4l2-ctl --stream-mmap no longer faults. Patch
3's checks are not reachable from userspace once patches 1 and 2 are
applied; no run printed them. With patch 6, NV12, I420, YUYV and UYVY
encodes from 96x96 up to 8176x8176 (including 8176x1080, 1920x8176 and
a cropped 8168x8164) decode back at 53 dB PSNR, 8192 wide or high is
refused at S_FMT, and a probe with the reserved bit above each field
set showed the hardware does not take a 512 macroblock count.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (6):
      media: verisilicon: Enforce a minimum CAPTURE sizeimage for the encoder
      media: verisilicon: Keep the encoder coded size in sync with OUTPUT
      media: verisilicon: Refuse JPEG encode jobs with inconsistent geometry
      media: verisilicon: Report fixed JPEG colorimetry on the encoder
      media: verisilicon: Don't reset the encoder raw format while OUTPUT buffers exist
      media: verisilicon: rockchip: Limit the JPEG encoder to 8176x8176

 .../platform/verisilicon/hantro_h1_jpeg_enc.c      |  5 ++
 drivers/media/platform/verisilicon/hantro_jpeg.c   | 37 +++++++++
 drivers/media/platform/verisilicon/hantro_jpeg.h   |  5 ++
 drivers/media/platform/verisilicon/hantro_v4l2.c   | 88 +++++++++++++++++++---
 .../verisilicon/rockchip_vpu2_hw_jpeg_enc.c        |  5 ++
 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 11 ++-
 6 files changed, 139 insertions(+), 12 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-hantro-jpeg-enc-fixes-9ff8bf6a491f

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

