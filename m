From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] media: rkvdec: vdpu381: compress the co-located motion
 vectors
Date: Tue, 10 Nov 2026 07:18:29 +0000
Message-Id: <20261110-rkvdec-colmv-v1-0-012b84ea43f7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MD3aLsspTUZN3k/JzcMl0TU1MDU/PkJGNLcxMloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loA275TMHAAAAA=
X-Change-ID: 20261110-rkvdec-colmv-455057cb3974
To: Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295110; l=2112;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ek8nnlo2Z+H0om9KAswdYQk2Ei8TtpDwU/E3AzwDn9U=;
 b=pkad0colCQyFDuzCw0zt4yr4BdNBS2eYZJAuJmgk0HrbZkevIZyWUDS8CWoRVfxzbA2JsOYug
 cNwLsCysTI7CYDnH5IzBQqrdjpAwbA1YLhJ0YweiGOOTs5w03K2Y0U/
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VDPU381 can store the co-located motion vectors of a frame
compressed (colmv_compress_en in register 12). The Rockchip MPP enables
it for H.264 streams without field pictures or MBAFF and always for
HEVC; mainline never does. B-frames are what limits H.264 decoding at
4K on one core, and the motion vector traffic is part of that.

Patch 1 enables it for H.264 and reserves the worst case of the
compressed layout, which can be larger than the uncompressed one (the
hardware wrote up to 556128 bytes compressed against 522240
uncompressed for the motion vectors of a 4K HEVC stream): a 4K CAPTURE
buffer gets 8.3 MB instead of 4.1 MB of motion vector space on VDPU381.
Patch 2 enables it for HEVC.

Tested on an Orange Pi 5 (RK3588S), GStreamer into fakevideosink,
240-frame clips: H.264 3840x2160 65.4 -> 68.4 fps, 1920x1080 214 -> 234
fps, HEVC 3840x2160 98.6-102.8 -> 104.6 fps. Every frame's checksum is
the same with compression off and on, the decoded frames are bit-exact
with FFmpeg's software decoders, and fluster is unchanged
(JCT-VC-HEVC_V1 146/147, JVT-AVC_V1 129/135, JVT-FR-EXT 65/69). The
bytes the hardware writes into the motion vector area were measured
with a poisoned buffer to size the compressed layout.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (2):
      media: rkvdec: vdpu381: Compress the co-located motion vectors of H.264
      media: rkvdec: vdpu381: Compress the co-located motion vectors of HEVC

 .../platform/rockchip/rkvdec/rkvdec-vdpu381-h264.c     | 10 ++++++++++
 .../platform/rockchip/rkvdec/rkvdec-vdpu381-hevc.c     |  3 +++
 drivers/media/platform/rockchip/rkvdec/rkvdec.c        | 18 +++++++++++++++++-
 3 files changed, 30 insertions(+), 1 deletion(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-rkvdec-colmv-455057cb3974

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

