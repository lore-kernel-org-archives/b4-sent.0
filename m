From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/3] media: rockchip: Add the IEP2 deinterlacer of
 RK3568/RK3588
Date: Sat, 14 Nov 2026 00:13:49 +0000
Message-Id: <20261114-iep2-v1-0-a8edde5a21e1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MD3czUAiPdJMtEy2SzVHPzZBMTJaDSgqLUtMwKsDHRsRB+cWlSVmp
 yCUivUm0tAEkCkF9oAAAA
X-Change-ID: 20261110-iep2-b9a9c6e77c44
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Alex Bee <knaerzche@gmail.com>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615229; l=6741;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=OpCTf+DntkJDTyfZ3/J0N4OqBaxbAYAunGoZnsZjH2s=;
 b=fBLb7QhzTLrMzpxNDgL+CKTSM7jvAO8XNEhGsM9vy//P24fCJNATWcaOBG8nXGm1GUXIwGJNw
 mkgtkaJAvO9CICYC4XSn6ApIOcLKAs5aEGsc4AIaQJxzjEntf4Vlyr7
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds a V4L2 mem2mem driver for IEP2, the deinterlacer of the
RK3568 and RK3588 SoCs, with its binding and the RK3588 DT node.

It is based on Rockchip's vendor driver and MPP; the V4L2 part follows
Alex Bee's out-of-tree driver for the older IEP and sun8i-di. The older
IEP is a different block, so this driver uses iep2 names and leaves
the iep ones to Alex's driver.

The OUTPUT sizeimage is 4 KiB larger than the image: the hardware
reads past the end of the source (seen in a bob mode), which faults in
the IOMMU, and the block retries the read forever. How far it reads is not
known; 4 KiB never faulted. So an imported DMABUF of exactly the image
size is refused at QBUF.

Tested on an Orange Pi 5 (RK3588S) with a v7.3-based kernel carrying
this driver (plus a test-only parameter that shortens the watchdog); on
this series' base it is build-tested only.
The posted code ran v4l2-compliance (all three runs), the exact-size
DMABUF check and a motion adaptive stream; the other results below are
from the version before the last review fixes (size clamp, open error
path, Kconfig text).
- v4l2-compliance -s: 59/59, 1 warning (no --expbuf-device); 59/59, 0
  warnings with vivid vmalloc and dma-contig exporters
- exact-size DMABUF refused with -EINVAL; field order; timestamps at
  field rate; payload check; unbind with an open file and while
  streaming; rebind; s2idle and deep suspend while streaming
- with earlier unposted versions: 72 cases (576i/1080i, NV12/NV16/NV21,
  TFF/BFF/progressive, all four modes) without IOMMU faults, luma PSNR
  35.2-37.2 dB (bob) and 33.2-36.6 dB (motion adaptive), progressive
  bit-exact; -EBUSY on a rate change while streaming; 1080i motion
  adaptive at 290 frames/s

Not tested: RK3568 (no board), NV61, DMABUF on CAPTURE, the recovery
paths (never triggered).

v4l2-compliance output (no --expbuf-device):

v4l2-compliance 1.33.0-5524, 64 bits, 64-bit time_t
v4l2-compliance SHA: d2e89246cefc 2026-10-30 13:45:36

Compliance test for rockchip-iep2 device /dev/video3:

Driver Info:
	Driver name      : rockchip-iep2
	Card type        : Rockchip IEP2 deinterlacer
	Bus info         : platform:fdbb0000.deinterlace
	Driver version   : 7.3.0
	Capabilities     : 0x84204000
		Video Memory-to-Memory Multiplanar
		Streaming
		Extended Pix Format
		Device Capabilities
	Device Caps      : 0x04204000
		Video Memory-to-Memory Multiplanar
		Streaming
		Extended Pix Format

Required ioctls:
	test VIDIOC_QUERYCAP: OK
	test invalid ioctls: OK

Allow for multiple opens:
	test second /dev/video3 open: OK
	test VIDIOC_QUERYCAP: OK
	test VIDIOC_G/S_PRIORITY: OK
	test for unlimited opens: OK

Debug ioctls:
	test VIDIOC_DBG_G/S_REGISTER: OK (Not Supported)
	test VIDIOC_LOG_STATUS: OK (Not Supported)

Input ioctls:
	test VIDIOC_G/S_TUNER/ENUM_FREQ_BANDS: OK (Not Supported)
	test VIDIOC_G/S_FREQUENCY: OK (Not Supported)
	test VIDIOC_S_HW_FREQ_SEEK: OK (Not Supported)
	test VIDIOC_ENUMAUDIO: OK (Not Supported)
	test VIDIOC_G/S/ENUMINPUT: OK (Not Supported)
	test VIDIOC_G/S_AUDIO: OK (Not Supported)
	Inputs: 0 Audio Inputs: 0 Tuners: 0

Output ioctls:
	test VIDIOC_G/S_MODULATOR: OK (Not Supported)
	test VIDIOC_G/S_FREQUENCY: OK (Not Supported)
	test VIDIOC_ENUMAUDOUT: OK (Not Supported)
	test VIDIOC_G/S/ENUMOUTPUT: OK (Not Supported)
	test VIDIOC_G/S_AUDOUT: OK (Not Supported)
	Outputs: 0 Audio Outputs: 0 Modulators: 0

Input/Output configuration ioctls:
	test VIDIOC_ENUM/G/S/QUERY_STD: OK (Not Supported)
	test VIDIOC_ENUM/G/S/QUERY_DV_TIMINGS: OK (Not Supported)
	test VIDIOC_DV_TIMINGS_CAP: OK (Not Supported)
	test VIDIOC_G/S_EDID: OK (Not Supported)

Control ioctls:
	test VIDIOC_QUERY_EXT_CTRL/QUERYMENU: OK
	test VIDIOC_QUERYCTRL: OK
	test VIDIOC_G/S_CTRL: OK
	test VIDIOC_G/S/TRY_EXT_CTRLS: OK
	test VIDIOC_(UN)SUBSCRIBE_EVENT/DQEVENT: OK
	test VIDIOC_G/S_JPEGCOMP: OK (Not Supported)
	Standard Controls: 2 Private Controls: 0

Format ioctls:
	test VIDIOC_ENUM_FMT/FRAMESIZES/FRAMEINTERVALS: OK
	test VIDIOC_G/S_PARM: OK (Not Supported)
	test VIDIOC_G_FBUF: OK (Not Supported)
	test VIDIOC_G_FMT: OK
	test VIDIOC_TRY_FMT: OK
	test VIDIOC_S_FMT: OK
	test VIDIOC_G_SLICED_VBI_CAP: OK (Not Supported)
	test Cropping: OK (Not Supported)
	test Composing: OK (Not Supported)
	test Scaling: OK (Not Supported)

Codec ioctls:
	test VIDIOC_(TRY_)ENCODER_CMD: OK (Not Supported)
	test VIDIOC_G_ENC_INDEX: OK (Not Supported)
	test VIDIOC_(TRY_)DECODER_CMD: OK (Not Supported)

Buffer ioctls:
	test VIDIOC_REQBUFS/CREATE_BUFS/QUERYBUF: OK
	test CREATE_BUFS maximum buffers: OK
	test VIDIOC_REMOVE_BUFS: OK
	test VIDIOC_EXPBUF: OK
	test Requests: OK (Not Supported)
	test blocking wait: OK

Test input 0:

Streaming ioctls:
	test read/write: OK (Not Supported)
	test MMAP (no poll, REQBUFS): OK
	test MMAP (select, REQBUFS): OK
	test MMAP (epoll, REQBUFS): OK
	test MMAP (no poll, CREATE_BUFS): OK
	test MMAP (select, CREATE_BUFS): OK
	test MMAP (epoll, CREATE_BUFS): OK
	test USERPTR (no poll): OK (Not Supported)
	test USERPTR (select): OK (Not Supported)
		warn: v4l2-test-buffers.cpp(2223): Cannot test DMABUF, specify --expbuf-device
	test DMABUF (no poll): OK (Not Supported)
	test DMABUF (select): OK (Not Supported)

Total for rockchip-iep2 device /dev/video3: 59, Succeeded: 59, Failed: 0, Warnings: 1

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (3):
      media: dt-bindings: Add Rockchip IEP2 deinterlacer
      media: rockchip: Add IEP2 deinterlacer driver
      arm64: dts: rockchip: Add IEP2 deinterlacer to RK3588

 Documentation/admin-guide/media/rockchip-iep2.rst  |   59 +
 Documentation/admin-guide/media/v4l-drivers.rst    |    1 +
 .../bindings/media/rockchip,rk3568-iep2.yaml       |   95 ++
 MAINTAINERS                                        |    9 +
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      |   22 +
 drivers/media/platform/rockchip/Kconfig            |    1 +
 drivers/media/platform/rockchip/Makefile           |    1 +
 drivers/media/platform/rockchip/iep2/Kconfig       |   16 +
 drivers/media/platform/rockchip/iep2/Makefile      |    3 +
 drivers/media/platform/rockchip/iep2/iep2-regs.h   |  192 +++
 drivers/media/platform/rockchip/iep2/iep2.c        | 1275 ++++++++++++++++++++
 drivers/media/platform/rockchip/iep2/iep2.h        |  106 ++
 12 files changed, 1780 insertions(+)
---
base-commit: ad6549a46748d00818483b535e5cd2a704685c98
change-id: 20261110-iep2-b9a9c6e77c44

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

