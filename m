From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/3] media: stateless MPEG-1 decoding, cedrus support
Date: Sat, 21 Nov 2026 10:10:53 +0000
Message-Id: <20261121-b4-cedrus-mpeg1-v2-0-95e4decf03fa@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNwQ6CQAxEf4X0bA3bgEFP/ofh0F0K1IiQXSAaw
 r+7YDx5fJmZNwsE8SoBLskCXmYN2j8j0CEB1/KzEdQqMlBKJ2NMhjZDJ5WfAnaDNAYLyyw5k0g
 tEFeDl1pfu/FWfjlM9i5u3DRbo9Uw9v69X85m6/3s5z/7bDBF5txyTKkgujYd6+Po+g7KdV0/F
 Z6c38AAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795255854; l=2157;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=c8hzlJkZuLFpk0HXOIpIk4bSfcFbpshbq1yBgA3J7r0=;
 b=LcFu5wkFyucpntRx5PrzCvk4fzFu+NMsGPmObo7KQBpVfbYaPwV/xiInc2sKUN4I2dKFMRkAZ
 m2W4TKocSF3AOTDWA+bzGhttSrMnytz4clUqk27dfahoDV/PtgBa4w5
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Builds on Jernej Skrabec's cedrus work; tested with an FFmpeg hwaccel
on top of Jonas Karlman's V4L2 request API series (FFmpeg PR 20847).

MPEG-1 decoded as MPEG-2 is wrong: the mismatch control differs, and
MPEG-1 has full pel motion vectors and D-pictures. Patch 1 adds
V4L2_MPEG2_SEQ_FLAG_MPEG1 and two full pel picture flags to the MPEG-2
controls and allows D-pictures; patch 2 makes hantro reject them
(compile tested only). Patch 3 implements them in cedrus.

Tested on H616 only, on media-committers next: MPEG-2, H.264 and H.265
decode bit-exact against FFmpeg software decoding. MPEG-1 streams with
B-pictures and full pel vectors differ from FFmpeg (-idct faani) by at
most 2 in I-, P- and B-pictures; FFmpeg's own IDCTs differ by up to 3
on the same streams. The full pel reference needs an FFmpeg fix for
skipped B macroblocks. MPEG-1 D-pictures are bit-exact against a
computed DC reference; stock v4l2-compliance 49 of 49.

Developed with Claude (Anthropic) as a coding assistant, which wrote
the code and the commit messages. I reviewed and tested them as
described above.

Changes in v2:
- Drop V4L2_PIX_FMT_MPEG1_SLICE: cedrus selects MPEG-1 from
  V4L2_MPEG2_SEQ_FLAG_MPEG1 alone (Nicolas)
- hantro reject in its own patch
- Link to v1: https://lore.kernel.org/r/20261119-b4-cedrus-mpeg1-v1-0-aa5ba1192822@gmail.com

---
Arun Iyengar (3):
      media: uapi: mpeg2: add MPEG-1 flags
      media: verisilicon: reject MPEG-1 controls
      media: cedrus: mpeg2: decode MPEG-1

 .../media/v4l/ext-ctrls-codec-stateless.rst        | 34 ++++++++++++++++++++--
 drivers/media/platform/verisilicon/hantro_drv.c    | 12 ++++++++
 drivers/media/v4l2-core/v4l2-ctrls-core.c          |  1 +
 drivers/staging/media/sunxi/cedrus/cedrus.h        |  3 ++
 drivers/staging/media/sunxi/cedrus/cedrus_mpeg2.c  | 27 ++++++++++++++---
 include/uapi/linux/v4l2-controls.h                 |  3 ++
 6 files changed, 74 insertions(+), 6 deletions(-)
---
base-commit: ccf78740d63813c452c035b57d17a650492562fa
change-id: 20261114-b4-cedrus-mpeg1-8baae5a2eefe

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

