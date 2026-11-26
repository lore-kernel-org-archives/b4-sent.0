From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/5] media: verisilicon: Fix the JPEG encoder format
 handling
Date: Thu, 26 Nov 2026 17:00:52 +0000
Message-Id: <20261126-hantro-jpeg-enc-fixes-v3-0-07357d84a64b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNyw6DIBBFf8Ww7jSA7676H00XCoNiqhiwpI3x3
 wt246bp8s7ce85KHFqNjlySlVj02mkzhZCeEiL6ZuoQtAyZcMoLxhiFcFysgWHGDnASoPQLHdR
 KVa0qmqxmioTtbHF/hOnt/s3u2Q4olgiLjV67xdj3LvYs9v45PAMKSmRSlFhXueTXbmz04yzMS
 KLD8yOF/6LwQJFIUyyyVJS5PFK2bfsAA4/sWBIBAAA=
X-Change-ID: 20261110-hantro-jpeg-enc-fixes-9ff8bf6a491f
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Sergei Khomenkov <shomenkow@gmail.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795712452; l=2725;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Jk9ltudzLGJ5X0zC94Mk8NkNqBgItiMI3b+1wG84SiM=;
 b=ApY1KF73XXUXDH3C0VEMRV5ZZDNEiArQ47FtiQBbFbzfex+990Kq9Xg/yhEIt/qJ3HFpxFc3m
 RT1jcf93sQHC17hDvk411/FLiBoO6r/BvJJwvlLF4HTnx6B6cj9Jtbf
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the format handling of the Hantro JPEG encoders, found
with v4l2-ctl, v4l2-compliance and GStreamer on the RK3588 VEPU121.

Patch 1 keeps the coded format while CAPTURE buffers exist. Patch 2 sets
the coded size from the OUTPUT format. Patch 3 reports the fixed JPEG
colorimetry. Patch 4 restores the raw format descriptor when a CAPTURE
S_FMT can't reset it; this was the IOMMU fault at IOVA 0 seen with
v4l2-ctl --stream-mmap. Patch 5 limits the frame size to 8176x8176.

The VEPU2 stream limit in 64-bit words is patch 2 of Sergei Khomenkov's
v3 [1].

[1] https://lore.kernel.org/r/20261124-hantro-buflimit-v3-0-780903970ca0@gmail.com
[2] https://lore.kernel.org/r/20261126-b4-v4l2-enc-sizeimage-v1-1-dd2cb99bd717@gmail.com

Based on v7.4-rc1; on top of [1], patches 3 and 5 need git am -3.

Tested on Orange Pi 5 (RK3588S, VEPU121), v7.3-based KASAN kernel that
also carries the change of [1] 2/3: GStreamer encodes (NV12/I420/YUY2,
720p to 4K) and v4l2-compliance pass. The v2 reproducer no longer
faults; its 8 frames end in buffer full, as the CAPTURE sizeimage stays
at the 96x32 default (6768 bytes). The dev-encoder.rst proposal for
that case is [2]. H1 untested.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v3:
- Dropped the CAPTURE sizeimage minimum (v2 2/7) and the job-time
  geometry check (v2 4/7) (Nicolas); with [1], a too small CAPTURE
  buffer ends in buffer full
- Spec proposal for the CAPTURE sizeimage sent as [2] (Nicolas)
- Patch 2: only width/height follow OUTPUT; sizeimage and -EBUSY dropped
- Patch 4: only restore the descriptor in hantro_reset_raw_fmt()
- Patch 5: Fixes tag (Sashiko)
- Shorter commit messages and comments
- Link to v2: https://patch.msgid.link/20261112-hantro-jpeg-enc-fixes-v2-0-de03e643c75d@gmail.com

---
Arun Iyengar (5):
      media: verisilicon: Keep the encoder CAPTURE format while buffers exist
      media: verisilicon: Keep the encoder coded size in sync with OUTPUT
      media: verisilicon: Report fixed JPEG colorimetry on the encoder
      media: verisilicon: Restore the encoder raw format when its reset fails
      media: verisilicon: rockchip: Limit the JPEG encoder to 8176x8176

 drivers/media/platform/verisilicon/hantro_v4l2.c   | 26 ++++++++++++++++++++--
 .../media/platform/verisilicon/rockchip_vpu_hw.c   |  7 ++++--
 2 files changed, 29 insertions(+), 4 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-hantro-jpeg-enc-fixes-9ff8bf6a491f

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

