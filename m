From: Jerome Berclaz <jerome.berclaz@proton.me>
Subject: [PATCH 0/4] media: tegra-vde: less cache maintenance, reject CABAC
 early
Date: Thu, 26 Nov 2026 16:55:44 -0800
Message-Id: <20261126-tegra-vde-fixes-v1-0-fa4a7c1d24cc@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ5EQBCE4VeRPm8nZg6CV9k4MKppByvTViTi3
 Q2OXyp/HWSICqM6OyhiU9PfnOA+GYWxnQew9snkc1845wteMcSWtx4susNYBFWQvCo7KSlVS8Q
 zpOjbvLZ/NyGs9w2d5wWK5/AOcwAAAA==
X-Change-ID: 20261126-tegra-vde-fixes-ffe9cf098bf8
To: Dmitry Osipenko <digetx@gmail.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-media@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jerome Berclaz <jerome.berclaz@proton.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2262;
 i=jerome.berclaz@proton.me; s=2026-11; h=from:subject:message-id;
 bh=pSN+aMWG4bSfy4wRZg6S1xm4J1XJvjMCKBOGZErTLfM=;
 b=owGbwMvMwCVmvC9341tRgSLG02pJDNkcV4XuuO9cuz2+xlJvdjD70VWPKngOH+KYoPlu8/tVe
 3c9Y+pd3VHKwiDGxSArpsjC2mCYOv8EW0Ch/rxDMHNYmUCGMHBxCsBEZvgy/M8/8prT8eiT30zx
 0y1SSycvm/ZvbvT3wzdiL3+ubo7L5WRg+CtqY3/0ravbUd473gsFzxtEvbwfs8g1ZtkHbYZ1qkd
 2/eIGAA==
X-Developer-Key: i=jerome.berclaz@proton.me; a=openpgp;
 fpr=058031659FC80650712F9EC233BE6DB1ED151072
X-Endpoint-Received: by B4 Relay for jerome.berclaz@proton.me/2026-11 with auth_id=1658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These patches came out of getting hardware H.264 playback working well on a
Tegra30 device (Microsoft Surface RT) with mpv and FFmpeg's V4L2 request
hwaccel. The decoder sits behind the SMMU there, so buffers use
vb2_dma_sg_memops with cached pages, and cache maintenance turned out to be
the largest kernel cost of playback.

Patches 1 and 3 shrink what gets cleaned for the bitstream (OUTPUT)
buffers: a smaller default size derived from the frame size, and cleaning
only the bytes the hardware reads instead of the whole buffer (FFmpeg
allocates width x height x 3/2, while a coded frame is usually a few KB).
Patch 2 lets clients that never read decoded frames through the CPU skip
the capture-side sync with the existing cache hint flags, as the MediaTek
decoder already allows. Patch 4 rejects CABAC in try_ctrl, so that setting
the controls fails right away instead of the decode job failing later.
Userspace that ignores buffer error flags otherwise shows broken frames.

Tested on the Surface RT with the same patches on a 7.3.1-based kernel
(720p/1080p H.264, mpv and GStreamer). On 720p playback, the v7/l2c210
cache maintenance functions had been about 21% of all CPU samples in the
decoding thread before patch 1. Build-tested on media/next for ARM
(tegra_defconfig, W=1), each patch individually.

A follow-up RFC will add CABAC, weighted prediction and High profile
support on Tegra30, by parsing slice headers in software. With it,
patch 4's check only remains for SoCs without that support.

These patches were developed with the help of an AI assistant;
I have reviewed them and tested them on the device.

---
Jerome Berclaz (4):
      media: tegra-vde: size the bitstream buffer from the frame size
      media: tegra-vde: allow cache hints on the capture queue
      media: tegra-vde: clean only the used part of the bitstream buffer
      media: tegra-vde: reject CABAC in the H.264 PPS control

 drivers/media/platform/nvidia/tegra-vde/v4l2.c | 71 +++++++++++++++++++++++++-
 1 file changed, 69 insertions(+), 2 deletions(-)
---
base-commit: b7ac871daee981f1963f632586ff9b9d898ce5dd
change-id: 20261126-tegra-vde-fixes-ffe9cf098bf8

Best regards,
--  
Jerome Berclaz <jerome.berclaz@proton.me>

