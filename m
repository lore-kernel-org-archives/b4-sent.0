From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] media: rockchip: Decode monochrome H.264 to GREY
Date: Fri, 20 Nov 2026 01:10:38 +0000
Message-Id: <20261120-b4-h264-monochrome-grey-v1-0-887102a688fd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDvgpEHBq4gLEydmCiYyaUuLe
 Pem7fIt/j+gsAoXGJoDlJ9SJKcKujTg45xWRlmqwbSmIyKLzmI0ncUtp+yj5o1xVX5jv1CYXbj
 a1vRQ6105yOt3Hqe/y8Pd2N+/OzjPD5NJivJ7AAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795137038; l=2385;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Kth308z9xet7HD14BaAuot7KC10IQsCGy3sPJ6BL+4w=;
 b=MD0JLxy134nHpzoALsF9cBnaF8xpguqRYHQBg1VjwtiVZPbB+c6gBF4eTyGUtLou/YFPT0Rh3
 TwGsKhSbL1wDCYyQd3hyNt/T18K5Y25KnkSnuOZi5dHKI6/9RetzYrL
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rockchip Hantro (G1/VDPU2) and rkvdec decoders write no chroma for
4:0:0 H.264, but the drivers offer only formats with chroma. Offer GREY
for such streams.

Tested on an Orange Pi 5 (RK3588S: VDPU121 and rkvdec), 7.3-based tree
(patch 1 there differs in the control ops struct and an out-of-tree AVS+
format table; build-tested on media next), with GStreamer v4l2codecs
patched locally to map GREY and to renegotiate on a chroma format
change: JVT-FR-EXT HPCAMOLQ_BRCM_B and HPCVMOLQ_BRCM_B now pass on both
decoders, other fluster H.264, HEVC, VP8, VP9 and AV1 results unchanged.
Other SoCs are untested. Userspace without GREY support no longer gets
NV12 for these streams: unpatched GStreamer stops with an error instead
of showing wrong chroma.

A change between 4:0:0 and 4:2:0 inside a stream needs new CAPTURE
buffers: Hantro refuses the new SPS with -EBUSY while CAPTURE streams,
rkvdec while CAPTURE buffers exist (as before). Unpatched GStreamer
does not renegotiate for it. With the local patch a 4:0:0 + 4:2:0 +
4:0:0 concatenation decodes bit-exact on Hantro; on rkvdec it was run
only with an out-of-tree busy check.

Conflicts in hantro_try_fmt() with my pending "media: verisilicon: Only
accept formats of the queue's kind in TRY_FMT" [1]; I will rebase
whichever goes second.

[1] https://lore.kernel.org/r/20261112-hantro-fmt-role-v1-1-e596d6f4828f@gmail.com

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

---
Arun Iyengar (2):
      media: verisilicon: Decode monochrome H.264 to GREY on Rockchip
      media: rkvdec: Decode monochrome H.264 to GREY

 .../platform/rockchip/rkvdec/rkvdec-h264-common.c  |  4 ++-
 drivers/media/platform/rockchip/rkvdec/rkvdec.c    |  4 +++
 drivers/media/platform/rockchip/rkvdec/rkvdec.h    |  1 +
 drivers/media/platform/verisilicon/hantro.h        |  4 +++
 drivers/media/platform/verisilicon/hantro_drv.c    | 40 ++++++++++++++++++++--
 drivers/media/platform/verisilicon/hantro_v4l2.c   | 27 ++++++++++++---
 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 39 +++++++++++++++++++++
 7 files changed, 111 insertions(+), 8 deletions(-)
---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261114-b4-h264-monochrome-grey-7d1fabf34027

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

