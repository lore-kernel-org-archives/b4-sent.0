From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] media: rockchip: Decode monochrome H.264 to GREY
Date: Sat, 21 Nov 2026 14:25:22 +0000
Message-Id: <20261121-b4-h264-monochrome-grey-v2-0-ffe7f2383cbe@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ6CMBAFf4Xs2TVtbaDx5H8YDqVsaY2lpEUiI
 fy7gF49TvLezAKZkqcM12KBRJPPPvYbiFMBxum+I/TtxiCYKDnnEhuJTpQSQ+yjcSkGwi7RjFX
 LrW7sRTJRwfYeEln/Psz3+sv51TzIjLtuXzifx5jmIz3xfferCPa3MnFkqFTFmdClUra9dUH75
 9nEAPW6rh+wQams0AAAAA==
X-Change-ID: 20261114-b4-h264-monochrome-grey-7d1fabf34027
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795271122; l=2963;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=1AOZgIbbymLsepcyi/gXZ6yRt0VKzk+OlM1UFXxm2b8=;
 b=3ERUJbxJDYvzH/UaEKVOw3M5cAyVjzAefXCUw4H3a8KGOzweL/kzmUMT9pc/f4YHra7mkYjKs
 j4B/lRaEZwfA2S77mFfpFkPJbx/PHUOdaYrGZK/p8XTAAW4fZjjWNRC
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rockchip Hantro (G1/VDPU2) and rkvdec decoders write no chroma for
4:0:0 H.264, but the drivers offer only formats with chroma. Offer GREY
for such streams.

Tested on an Orange Pi 5 (RK3588S: VDPU121 and rkvdec) on a 7.3-based
tree that carries my other pending Hantro series; build-tested on media
next. v1 passed fluster: JVT-FR-EXT HPCAMOLQ_BRCM_B and HPCVMOLQ_BRCM_B
on both decoders, other results unchanged. v2: format and control ioctl
cases, including a too small CAPTURE buffer and a refused request, with
the size check and request error path of patch 1 in the posted form;
4:0:0, 4:2:0 and concatenated streams bit-exact with a locally patched
GStreamer, there with the size check of [2]. All under KASAN. Other
SoCs are untested. Userspace without GREY support gets an error for
these streams instead of wrong chroma.

A change between 4:0:0 and 4:2:0 needs new CAPTURE buffers: Hantro
refuses the new SPS with -EBUSY while CAPTURE streams, rkvdec while
CAPTURE buffers exist (as before; the rkvdec concatenation ran only
with an out-of-tree busy check).

Conflicts with my pending [1] in hantro_try_fmt() and [2] in
device_run() (the same size check); I will rebase whichever goes second.

[1] https://lore.kernel.org/r/20261112-hantro-fmt-role-v1-1-e596d6f4828f@gmail.com
[2] https://lore.kernel.org/r/20261112-hantro-dec-size-check-v1-1-e5f1180b625f@gmail.com

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

---
Changes in v2:
- Hantro: GREY only for High profile 4:0:0, as the hardware does (Sashiko)
- Hantro: no GREY on open, SPS ignored for other codecs (Sashiko)
- Hantro: keep the 4:0:0 state across S_FMT(OUTPUT) (Sashiko)
- Hantro: no transient 4:0:0 state on variants without GREY (Sashiko)
- Hantro: fail refused requests and too small CAPTURE buffers (Sashiko)
- Link to v1: https://patch.msgid.link/20261120-b4-h264-monochrome-grey-v1-0-887102a688fd@gmail.com

---
Arun Iyengar (2):
      media: verisilicon: Decode monochrome H.264 to GREY on Rockchip
      media: rkvdec: Decode monochrome H.264 to GREY

 .../platform/rockchip/rkvdec/rkvdec-h264-common.c  |  4 +-
 drivers/media/platform/rockchip/rkvdec/rkvdec.c    |  4 ++
 drivers/media/platform/rockchip/rkvdec/rkvdec.h    |  1 +
 drivers/media/platform/verisilicon/hantro.h        | 11 ++++
 drivers/media/platform/verisilicon/hantro_drv.c    | 71 ++++++++++++++++++++--
 drivers/media/platform/verisilicon/hantro_h264.c   | 11 +++-
 drivers/media/platform/verisilicon/hantro_hw.h     |  2 +-
 drivers/media/platform/verisilicon/hantro_v4l2.c   | 22 +++++--
 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 39 ++++++++++++
 9 files changed, 152 insertions(+), 13 deletions(-)
---
base-commit: ccf78740d63813c452c035b57d17a650492562fa
change-id: 20261114-b4-h264-monochrome-grey-7d1fabf34027

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

