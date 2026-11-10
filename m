From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH RFC 00/12] media: rockchip: Add a VEPU580 stateless
 H.264/HEVC encoder driver for the RK3588
Date: Tue, 10 Nov 2026 10:08:02 +0000
Message-Id: <20261110-rkvenc-v1-0-ea8b47122d8c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/11VSY5cNwy9ilHrNEBSFEl5GyAHyDbwQuIQdwIP6
 baNAIbvHpZtBOi/LH1x0Jvq6+05nx7z+fb61dfbU355fH788L5/4C+vbv52v/8zHx6jf98ISBA
 RHp7+/pLv/SGh0AUdYNOtL398ynr893ujP26///br7c2Pw+fP56/0T/cWP6895T+fe8ynn3c/7
 k/+toe8flWBWLhIRCcHnmA4JRgxA2MrbwjH4T/G/V+lrhmug3kti0mQtUsPD/AF1Qd9Adj1ZRW
 LrUhVyIPHu+8cISdjU45FAZ5S3TJeVsGucCe2RblddcCQgBlWEzin+xkzj1w2THfjdcYgCx5Lh
 kGBl4/RU8VRghKC7GWVS6/RkIiCOHetEC82g55AZaGHaOyEy6w1G60pMCpAAQYvgY1DKNlEnQq
 JQ9YFQ+mtOXQRRGNRJLZrS+GIQvZagWugXzaUyd4IbMmVvAeC5dq5jvraW63WPEYO/rJqSbFCD
 7FDvm1UOd/PsN+qIxdN7DcCvqyqPZrR8iwAGXqOcS0GPGcBzwgWXEzrsmFsEYksy6AzaUlsi0w
 8OazxM7Szh/u4oJFzkJvUaQL0RDMwt3PhZD4aGi2p4yQXbaxEG3KIBcQGn9U1u9vbxBirpjSQW
 Zeqau24KytPy0l3yZXeGdMjqNwN8dQ5FzTMRmZVbc2t0N1jTGVRNfDDRUeWW4zLrL0BzZfOWgc
 L5pzYpLMwN0b9LaSJMLqgERYyWmkTVUsOtjMEt0nmtNbHnKe5n3rRIU2f3ukgutoiA8chcDLt4
 mgqW1w+qeDilNB9ZiM8kHm23WWD7AGzACcIJOamfsXFldL0Dsi5o9+lAduKmyBzJjU/h7a1Xa/
 v6qZMP1fcULMF4SE0UlZojb2pjc2el9zIUXkMkTEXtKJo9kErdkV03TGPu1H5uiERnX3HkJo43
 CdOzxkJBAumnNXWiXmpCpGtnqTUDGOn7T0RwIys4a5Okv627Jps4Q1h+7md2ZoFXeyid1v2Yze
 jE1iDjJcEmONEAhscNUXMjohOzXvStO9OJ3L1xmCXWeIFnS8Ondveq87+g8Bl6kNltLOTkKH1d
 qlqouaEWrIzw9q2Olq50CFSLjnmSfKRF5aZaDaGk2K5zLtesXpJHGumwnLnUyX2HcOzn/PBP7x
 79/ipxwlZalPZ3pxtC7TONZ45muEgNOq0Sk2+vfn27T9Xf+LODwcAAA==
X-Change-ID: 20261110-rkvenc-e0f1c61c00a2
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Kocialkowski <paulk@sys-base.io>, 
 =?utf-8?q?Sven_P=C3=BCschel?= <s.pueschel@pengutronix.de>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Detlev Casanova <detlev.casanova@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Jiaxing Hu <gahing@gahingwoo.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305283; l=9591;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ZAT0wBXyyAUYNvuDNGERTIQu8xp4Lu6oc4UsNxSc1ZA=;
 b=dCUzZ1YoJi3kGTk14s7KuFvWLxUQnuzAXxm/cOHewA14+tyeJYYUlA34D0HBJUWbdK/M7MXfX
 0sQJGZg4p9oCRmMKLlmjzAWxHbJiIiLNuQiOzCy9fv+c8cUk79gklnr
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This RFC adds a V4L2 stateless encoder driver for the VEPU580 (RKVENC)
of the Rockchip RK3588, the H.264/HEVC encoder block with two cores
that the vendor kernel drives through its "mpp" framework. It is a
non-Hantro user of Paul Kocialkowski's H.264 stateless encode uAPI, and
the first user of the HEVC stateless encode uAPI I am proposing in a
separate RFC.

It depends on unmerged work and is sent for review of the approach. It
applies on media next 6628e7d4c6b2 (v7.4-rc1) with, in this order:
- patches 1-7 of "[PATCH 00/14] media: Add V4L2 H.264 stateless encode
  and VC8000E support" v1 (Paul Kocialkowski, 2026-05-22):
  https://lore.kernel.org/all/20260522101653.2565125-1-paulk@sys-base.io/
  (https://patchwork.kernel.org/project/linux-media/list/?series=1099281)
- my "[PATCH RFC 00/11] media: h264: Stateless encode core follow-ups"
  (the SPS/PPS fix, the CBR rework on v4l2-enc-cbr and VBR);
- my "[PATCH RFC 00/10] media: Add a V4L2 HEVC stateless encode uAPI
  and helpers", for the HEVC patches;
- patches 6 and 7 of "[PATCH v2 00/17] media: rockchip: rga: Add
  multi-core support" (Sven Püschel, 2026-09-16), for
  v4l2_m2m_set_max_parallel_jobs():
  https://lore.kernel.org/all/20260916-spu-rga3multicore-v2-0-23aa2cb74e61@pengutronix.de/
Paul has announced a rework of the H.264 core helpers for v2; the
driver will follow it.

Patches 1-4 add the binding, the driver with H.264, and HEVC. Both
cores are independent DT nodes (nothing in the hardware ties them
together) bound as components of one m2m device, sharing the first
core's IOMMU domain; jobs of different contexts run on both cores in
parallel. The one-stream-on-two-cores handshake of the vendor driver is
not used. Patches 5-6 change the defaults the driver took from MPP
(no texture adaptive QP, MPP's moving-scene H.264 tuning), with the
measurements in the commit messages. Patches 7-8 encode pictures wider
than 4096 pixels (HEVC in tile columns, as MPP does), patches 9-10 add
MPP's I picture QP limits and re-encoding of oversized pictures for
HEVC, patch 11 offers VBR for H.264. Patch 12 adds the device tree
nodes and can go through the Rockchip tree once the binding is
accepted.

H.264: Baseline/Main/High, CAVLC/CABAC, 8x8 transform, I and P pictures
with one reference (the hardware has a single reference read port),
single slice. HEVC: Main profile, I and P pictures, inline short-term
RPS and long-term pictures as resolved by the core, TMVP. Both up to
16384x8192. For both, the core writes the parameter sets at the start
of the CAPTURE buffer and the hardware writes the slice header and data
from its syntax registers. Reconstructed/reference pictures are
driver-internal FBC buffers. Fixed QP, constant quality and constant
bitrate come from the cores, whose picture size target drives the
hardware row rate control; the measured per-picture statistics are
reported back (V4L2_CID_MPEG_VIDEO_AVERAGE_QP for H.264, the HEVC
feedback control for HEVC).

There is no public documentation of this block. The register layout,
meanings and default tuning values were derived from the Rockchip MPP
userspace library (Apache-2.0), read as documentation and written as
named fields and formulas; the power, watchdog and reset/IOMMU recovery
sequences follow the vendor kernel driver. No code was copied.

Related: Jiaxing Hu's RFC for the VEPU510 of the RK3576 (a stateful
H.264 driver) is a different generation of this block:
https://lore.kernel.org/all/20260722073417.2064667-1-gahing@gahingwoo.com/

Tested on an Orange Pi 5 (RK3588S), on a v7.3-based kernel whose
rkvenc files and binding are byte-identical to this series, with a
request-API test client and GStreamer (local patches), decoding every
stream with FFmpeg and measuring PSNR against the source:
- H.264, 1080p60, 300 pictures of two clips (Big Buck Bunny and a
  natural one): CBR at 4 Mbit/s with an IDR period of 120, 8 Mbit/s
  with 10 and 20 Mbit/s all-intra within 2.2% of the target, the
  largest one second window at most 1.37 times the bitrate (a scene
  change in a P picture); VBR with the peak at 1.5 times the bitrate
  in the same cases and at 8 Mbit/s with an IDR period of 120
  within 3.2% of the target, every one second window
  within the peak (at most 0.94 of it);
- HEVC, CBR with an IDR period of 120: 1080p60 at 2-16 Mbit/s and
  2160p30 at 20 and 40 Mbit/s within 3.4% of the target, the largest
  one second window at most 1.35 times the bitrate; 4104x2160,
  5120x2880 and 8192x4320 in tile columns, PSNR-Y 43-52 dB.
With earlier revisions of patches 2-4: both cores probe and bind,
v4l2-compliance 1.32 44/49 with 0 warnings (the 5 failures are the
tool not knowing stateless encoders); H.264 and HEVC at 1080p and 4K,
fixed QP 22-37 with GOP 1/10/30, the three H.264 profiles with CAVLC and
CABAC, HEVC TMVP on/off, SAO off, long-term references, CQ and odd
sizes with a conformance window, decode with 0 errors at 38-59 dB PSNR,
and the HEVC feedback control matched the expected NAL type, POC, QP
and reference list on every picture; two parallel 4K streams run one
on each core at about twice the single-stream rate with outputs
identical to single-stream runs; both cores runtime-suspend after the
last job; H.264 up to 16384x2048 and 8192x4320 through the external
line buffer. The error, watchdog and IOMMU recovery paths have not been
exercised on hardware.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (12):
      dt-bindings: media: Add the Rockchip VEPU580 video encoder
      media: rockchip: Add a VEPU580 stateless video encoder driver
      media: rockchip: rkvenc: Prepare the VEPU580 helpers for a second codec
      media: rockchip: rkvenc: Add HEVC encoding
      media: rockchip: rkvenc: Don't enable adaptive QP with the row rate control
      media: rockchip: rkvenc: Use MPP's moving-scene H.264 RDO tuning
      media: rockchip: rkvenc: Encode pictures wider than 4096 pixels
      media: rockchip: rkvenc: Encode HEVC wider than 4096 pixels in tile columns
      media: rockchip: rkvenc: Limit the QP of the HEVC I pictures to 15..51
      media: rockchip: rkvenc: Re-encode oversized HEVC pictures
      media: rockchip: rkvenc: Offer VBR for H.264 encoding
      arm64: dts: rockchip: Add the VEPU580 encoder cores to the RK3588

 .../bindings/media/rockchip,rk3588-vepu580.yaml    |   93 ++
 MAINTAINERS                                        |    8 +
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      |   56 +
 drivers/media/platform/rockchip/Kconfig            |    1 +
 drivers/media/platform/rockchip/Makefile           |    1 +
 drivers/media/platform/rockchip/rkvenc/Kconfig     |   18 +
 drivers/media/platform/rockchip/rkvenc/Makefile    |    8 +
 .../media/platform/rockchip/rkvenc/rkvenc-h264.c   |  519 +++++++
 .../media/platform/rockchip/rkvenc/rkvenc-hevc.c   |  869 +++++++++++
 .../media/platform/rockchip/rkvenc/rkvenc-regs.h   |  539 +++++++
 .../platform/rockchip/rkvenc/rkvenc-vepu580.c      |  999 +++++++++++++
 drivers/media/platform/rockchip/rkvenc/rkvenc.c    | 1581 ++++++++++++++++++++
 drivers/media/platform/rockchip/rkvenc/rkvenc.h    |  329 ++++
 13 files changed, 5021 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-rkvenc-e0f1c61c00a2
prerequisite-patch-id: fd11f19266754d1bd40bf61dd5d1da74a0dc13c2
prerequisite-patch-id: 7c7edc7344998d520efaf7b430c90fd527c704c7
prerequisite-patch-id: 4689de770eb1bcdc153d6beda2e392d0ce6f344d
prerequisite-patch-id: 0afdcc24892eac773036d05d8f504e5ccb35eb62
prerequisite-patch-id: ecc849b3328d4396380f0cfc331536c16d2e0d28
prerequisite-patch-id: c62d0fd16706c4328624948805eb2f8d7b223ae0
prerequisite-patch-id: e955d15603fd070034960a1362e4867c2f124d69
prerequisite-patch-id: 76eb64d7920ddc1f268afa6f13df14cf9d1931c8
prerequisite-patch-id: 654c303a6e9e4a3108e9ae9b7c9aa78f95b82c0c
prerequisite-patch-id: 96f470c1f8b2ca83ffc496f41fd173e925180501
prerequisite-patch-id: fa3430fcef00637bb84f9401bb9045dd46194298
prerequisite-patch-id: da666def8ed2b5296da8dee1be387b2818ba3cc3
prerequisite-patch-id: 7e532c86fbd0f7bd6705ac4f1544b7d7d27cbc26
prerequisite-patch-id: 09e1836b24606834b9ac4aa3c851d39f564cfef6
prerequisite-patch-id: fd8fcc747458e52344df760a17b61748361bfbb1
prerequisite-patch-id: 883eefffa7ea70d39d357467780cb4f2b69c8d36
prerequisite-patch-id: aa018c975f9b1f0555164d46446dea01d6496823
prerequisite-patch-id: d8d6323a5177f6b1ce661a86ee5813d55b4a3570
prerequisite-patch-id: 25c5c1c067936d313b20c287e66da34fa6c52f02
prerequisite-patch-id: d7ab57d731445a0d6a06a305f015060e1ea2aa0d
prerequisite-patch-id: 68ed30e5ad9b17d0a8f4cbc8c4278cbb2a82ea23
prerequisite-patch-id: 5f042c1c0679a0f587bcd623e69d7f3aa205d4ce
prerequisite-patch-id: 4e3feb81141e90296253fe1809dd9d7b8cd86244
prerequisite-patch-id: 68222baa5172eef1abdbe693e0209056b98e9d54
prerequisite-patch-id: d66a7ce272d3911c662d008828570f439ce298c7
prerequisite-patch-id: dcb576eb303c4f0794c67ae9b2c1a41c208ab519
prerequisite-patch-id: 53bde0480b78711ed69704eb2f343b667fdbe087
prerequisite-patch-id: 6cf0960c01f1c7ce51101987c37633ffe214075f
prerequisite-patch-id: 6ad9550f96aeed8429737800e4afc6e35be2c3ed
prerequisite-patch-id: 42252ba52d9c65ea011f6971395e709cc4bff684

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

