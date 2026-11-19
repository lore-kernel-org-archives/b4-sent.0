From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH RFC 0/2] media: stateless MPEG-1 decoding, cedrus support
Date: Thu, 19 Nov 2026 16:34:51 +0000
Message-Id: <20261119-b4-cedrus-mpeg1-v1-0-aa5ba1192822@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQuCQBBG/4rMuQFn0RCvQT+ga3TYXT91gkx2M
 gTxv7fV8T14byNDUhi1xUYJbzV9ThnkUFAc/TSAtctMrnRHEak4VBzRpcX4MWMQboL3qL0DelC
 u5oRe19/xSpfziW5/aUu4I76+L9r3D2CfiaF4AAAA
X-Change-ID: 20261114-b4-cedrus-mpeg1-8baae5a2eefe
To: Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Maxime Ripard <mripard@kernel.org>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: Jonas Karlman <jonas@kwiboo.se>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-staging@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, 
 =?utf-8?q?Christian_Stefan_K=C3=B6v=C3=A9r-Draxl?= <ckoever@outlook.de>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795106091; l=2835;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=QsCl51k6uk/8eEVXP0Noi7pULDA/cGnoC7OzqiRMj5g=;
 b=MYPO5m+L0jmlqTvYEY0eCmCBMWbjwjJHDslt1mReSBrEQU7MTDgJ1D3KZkcUhztoSEOsBraMV
 xTNroU694dVBGFSp+ZoGG2ldSZGOKMDVuVi8/YwrZytRZTyKa5S1TKc
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Builds on Jernej Skrabec's cedrus work; tested with an FFmpeg hwaccel
on top of Jonas Karlman's V4L2 request API series (FFmpeg PR 20847).

MPEG-1 decoded as MPEG-2 is wrong: the mismatch control differs, and
MPEG-1 has full pel motion vectors and D-pictures. Patch 1 adds
V4L2_PIX_FMT_MPEG1_SLICE, which reuses the MPEG-2 controls with one
sequence flag and two picture flags; hantro rejects the new flags and
D-pictures (compile tested only). Patch 2 implements it in cedrus.

RFC questions:
- Is a separate pixel format the right way to make MPEG-1
  discoverable? Christian's Amlogic series decodes MPEG-1 through
  V4L2_PIX_FMT_MPEG2_SLICE.
- V4L2_MPEG2_SEQ_FLAG_MPEG1 is redundant with the format. I kept it so
  that the controls describe the bitstream on their own; happy to drop
  it.

FFmpeg patches (the second corrects D-picture handling of the first):
https://github.com/SomeComputerGuy/orangepizero2/blob/7ed24f39cbf0f4b285cd142c291267c9cfb818f4/patches/ffmpeg/0304-avcodec-add-V4L2-Request-API-MPEG-1-hwaccel.patch
https://github.com/SomeComputerGuy/orangepizero2/blob/7ed24f39cbf0f4b285cd142c291267c9cfb818f4/patches/ffmpeg/0309-avcodec-mpeg12dec-hand-D-pictures-only-to-hwaccels-t.patch

Tested on H616 only, on media-committers next: MPEG-1 (D-pictures
included), MPEG-2, H.264 and H.265 decode bit-exact against FFmpeg
software decoding; v4l2-compliance 49 of 49 with the v4l-utils patch
that teaches it the new format (sent separately).

Developed with Claude (Anthropic) as a coding assistant, which wrote
the code and the commit messages. I reviewed and tested them as
described above.

---
Arun Iyengar (2):
      media: uapi: mpeg2: add MPEG-1 flags and the MPEG-1 parsed slice format
      media: cedrus: mpeg2: decode MPEG-1 as V4L2_PIX_FMT_MPEG1_SLICE

 .../media/v4l/ext-ctrls-codec-stateless.rst        | 35 ++++++++++++++++++--
 .../userspace-api/media/v4l/pixfmt-compressed.rst  | 23 +++++++++++++
 drivers/media/platform/verisilicon/hantro_drv.c    | 12 +++++++
 drivers/media/v4l2-core/v4l2-ctrls-core.c          |  1 +
 drivers/media/v4l2-core/v4l2-ioctl.c               |  1 +
 drivers/staging/media/sunxi/cedrus/cedrus.c        | 22 +++++++++++++
 drivers/staging/media/sunxi/cedrus/cedrus_dec.c    |  1 +
 drivers/staging/media/sunxi/cedrus/cedrus_hw.c     |  1 +
 drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c  | 38 +++++++++++++++++++---
 drivers/staging/media/sunxi/cedrus/cedrus_video.c  |  7 ++++
 include/uapi/linux/v4l2-controls.h                 |  3 ++
 include/uapi/linux/videodev2.h                     |  1 +
 12 files changed, 139 insertions(+), 6 deletions(-)
---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261114-b4-cedrus-mpeg1-8baae5a2eefe

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

