From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH RFC 00/10] media: Add a V4L2 HEVC stateless encode uAPI and
 helpers
Date: Tue, 10 Nov 2026 10:07:30 +0000
Message-Id: <20261110-hevc-encode-uapi-v1-0-38ae9fcfedd4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/11Ty24cOQz8FWPOGYCUKJLKdYH9gL0GOUh8xBMgt
 tdjBwGC/PvS3iDA9FFqVhVVVf3zdI3nS1xPH+9+np7j++V6eXyoA364O9n9evgS54vX+dSgMSL
 C+T6+2zke7NHj/LqeLufVeE7Yfejup4I9PUdefrxTfjr98/dfp8//X15f99ewlzey32PP8e9rC
 b78nn1aL3Zfch/v0hETZ2OWQY7bCXYyug9HX0IL3LBbe+f5gxKTcJNONKf6aBC5UjZ1sAlZFzU
 AZHKLItbpIQKxcVvxju68w1eLPpuDBWdR+i0KVrpZI50tlol06OwwXHMAxTArP2LzYcMwU5q79
 6ZOfXJXSLC03kuVDdlbgDe9RRnXGmUJC7BRYbnRJFUohZbqslvrK+CgNUe5NRh6OghAp8mwsHM
 LUhZriY2c58FDrq3JZTbw8iIb68rFid0TyXI6zo522JAHWTmwOGbQ6ggac8XcYnMt0ZxjazOwW
 9TkJIES0d1sac80ervDeqv0mG1gvRHwFpWrV6JpkQDcZW+lnAS49wQa7sQ4qc3Dhr6Y2SM1vO3
 RJvtSj8AdXcs/Rd2rm/WDGzF6M+XcFYBsrwTGMkocRFtcvCq1rfGhGzNQO+9GDKyd9izMKnod6
 H3m4DIy8oDK6o6ZkNDQGO2tcilviclmFCpC3Ln3wQ3VHpGZS2IJFLv3IcQiCrYp2+Zp6v2gtRa
 g2pSRc2PCGAMrdGKi8qi+OVcQ2g5uuDr3atpAkeSN9WcwLuWIodWPMXZlP+S9h3td42yP375dX
 qoe3DTEycqTUeugVp9oRF/VsobaqiUhQafPv379B0kygumRBAAA
X-Change-ID: 20261110-hevc-encode-uapi-a26990b358b3
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305251; l=9759;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Z1BQ5cXyaAhXO6BO5tRHmO1fyC4asnDS7NBf/na01e4=;
 b=G6HaDXA+sokBZheUQDioslIeodxaAwEoCNsz+BVlG/yQOd1YoP3tKwv64VSJUDoGUn73wVW5j
 AfgCymQ4DAYCN/+pJvSr9ajYQBwYH/goUOpxb6Z/ryIxcS4iF0q6/AO
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi everyone,

This RFC proposes a V4L2 uAPI for stateless HEVC (H.265) encoders, built
on the kernel-driven design of Paul Kocialkowski's H.264 stateless
encode series, "[PATCH 00/14] media: Add V4L2 H.264 stateless encode and
VC8000E support" (v1, 2026-05-22):
https://lore.kernel.org/all/20260522101653.2565125-1-paulk@sys-base.io/
(https://patchwork.kernel.org/project/linux-media/list/?series=1099281)

It applies on media next 6628e7d4c6b2 (v7.4-rc1) with, in this order,
patches 1-7 of that series and my "[PATCH RFC 00/11] media: h264:
Stateless encode core follow-ups" applied first (the prerequisite lines
below). Only patches 7-9 here need them: they use the codec-independent
constant bitrate helper (v4l2-enc-cbr) of the follow-ups; patches 1-6
and 10 only share Kconfig/Makefile context. As far as I can tell, this is
the first HEVC stateless encode proposal. It is meant to help the H.264
discussion as much as to add HEVC: HEVC makes one answer to reference
handling concrete. I expect to adapt it to the rework of the H.264 core helpers
that Paul announced for v2.

What it reuses from the H.264 design:
- V4L2_PIX_FMT_HEVC_SLICE on the CAPTURE queue, with one access unit per
  buffer;
- the existing V4L2_CID_STATELESS_HEVC_SPS/PPS controls and structures
  for the coding tools. The parts a decoder never needed (profile, tier
  and level, conformance window, VUI, VPS) are derived in the kernel
  from the format, S_PARM, S_SELECTION and the stateful HEVC
  profile/level/tier controls;
- the kernel writes the VPS, SPS, PPS, AUD and, unless the hardware does
  it, the slice segment header;
- the QP comes from the stateful QP/rate control controls: direct QP,
  constant quality and constant bitrate in the core;
- the driver API: init/step/complete/exit, state_constrain and
  reconstruction buffer callbacks.

What is new:
- V4L2_CID_STATELESS_HEVC_ENCODE_PARAMS: the NAL unit type, TemporalId,
  slice type and POC of the picture, the slice header syntax elements
  that the SPS/PPS enable, and its reference picture set, given as a
  list of OUTPUT buffer timestamps, each marked used-by-current-picture
  and/or long-term. The kernel keeps the reconstructed pictures,
  computes the POC deltas, codes the RPS, builds the default reference
  lists and drops every picture that is not listed, exactly as a decoder
  does (8.3.2). Userspace keeps full control of the GOP structure,
  long-term references and temporal layers without any MMCO-like
  syntax. Hardware with one reference read port uses the single entry
  marked as used.
- V4L2_CID_STATELESS_HEVC_ENCODE_FEEDBACK, read-only: the values the
  kernel settled on (QP, resolved reference lists) and hardware
  statistics, in a codec-agnostic struct v4l2_stateless_encode_stats
  (QP sum/min/max, luma SSE, block counts) that H.264 could share.
  Applications never set it, so v4l2_ctrl_request_complete() stores the
  value the driver set at the end of the run in the request, and it can
  be read per request today, without read-only requests.
- A kernel HEVC NAL unit writer (v4l2-hevc-enc-rbsp) with byte-wise
  emulation prevention, and an encode core (v4l2-hevc-enc) for the
  RPS/DPB, accommodation, headers and feedback.
- KUnit tests for both: byte-exact VPS/SPS/PPS/AUD/slice headers for
  three configurations (vectors from an independent reference
  implementation, see the commit message), and GOP sequences through
  the core.
- Patches 7-9: the constant bitrate mode of the core on v4l2-enc-cbr,
  QP limits for I pictures and a re-encode hook for drivers whose
  hardware writes the slice header.

The uAPI was checked against two unrelated encoders: the Rockchip
VEPU580 (RK3588; its driver is posted separately as an RFC) and the
VeriSilicon VC8000E (its HEVC registers are in Paul's series). Both
write slice headers from registers and take CPU-written parameter sets,
and both map one-to-one onto the resolved slice header structure.

Questions where I would particularly like feedback:
1. Explicit references for HEVC versus the sliding window of the H.264
   v1 series: is the asymmetry fine, or should H.264 go explicit too?
2. Should the H.264 and HEVC bit writers become one shared helper, as
   the rate control now is?
3. Is a read-only feedback control the right pattern, and should the
   stats be their own codec-agnostic control?
4. Capability discovery: reject-on-use plus written-back accommodation,
   or a dedicated caps control?
5. HEVC_SLICE reuse, or HEVC_SL alongside the H264_SL rename?

Not covered yet: multi-slice, tiles/WPP with kernel-written headers
(a driver can still signal uniform tile columns, as the VEPU580 driver
does above 4096 pixels), RPS candidates in the SPS, custom scaling
lists, weighted prediction, SEI/HRD, 4:2:2/4:4:4 and 10-bit beyond what
the SPS can express (Main 10 is signalled but untested).

Testing: the touched files build with W=1 on arm64. The KUnit tests
pass on UML (23 tests: 19 for the RBSP writer, 4 for the core).
"make SPHINXDIRS=userspace-api/media htmldocs" gives no new warnings.
On hardware, the uAPI and helpers ran on an Orange Pi 5 (RK3588S)
through the VEPU580 driver, on a v7.3-based kernel whose HEVC encode
files are byte-identical to this series:
- constant bitrate, IDR period 120: 1080p60 (300 pictures of two clips)
  at 2, 4, 8 and 16 Mbit/s and 2160p30 (120 pictures of two clips) at
  20 and 40 Mbit/s, within 3.4% of the target, the largest one second
  window at most 1.35 times the bitrate; PSNR at equal bitrate against
  the driver's earlier private rate control: +0.27 to +1.0 dB on the
  animation clips, -0.05 to -0.13 dB on the natural ones (+0.27 dB on
  average); 4104x2160, 5120x2880 and 8192x4320 in tile columns; every
  stream decodes in FFmpeg;
- with earlier revisions of these patches: 1080p and 4K at
  fixed QP and constant quality with GOP 1/10/30, long-term references,
  TMVP on/off and SAO off, plus two 4K streams in parallel, decode in
  FFmpeg without errors at 38-59 dB PSNR, and the feedback control
  matched the expected NAL type, POC, QP and reference list on every
  picture.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code, the documentation and the commit messages, and I
reviewed and tested every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (10):
      media: hevc: Add H.265 syntax definitions
      media: uapi: Add HEVC stateless encode support
      media: hevc: Add stateless encode RBSP writer
      media: hevc: Add KUnit tests for the stateless encode RBSP writer
      media: hevc: Add stateless encode core
      media: hevc: Add KUnit tests for the stateless encode core
      media: v4l2-hevc-enc: Add a constant bitrate mode
      media: v4l2-hevc-enc: Add QP limits for the I pictures
      media: v4l2-hevc-enc: Re-encode oversized pictures
      media: docs: Document the HEVC stateless encode uAPI

 .../media/v4l/ext-ctrls-codec-stateless.rst        |  411 ++++++
 .../userspace-api/media/v4l/pixfmt-compressed.rst  |    3 +
 .../media/v4l/videodev2.h.rst.exceptions           |    2 +
 .../userspace-api/media/v4l/vidioc-g-ext-ctrls.rst |    8 +
 .../userspace-api/media/v4l/vidioc-queryctrl.rst   |   12 +
 drivers/media/v4l2-core/.kunitconfig               |    6 +
 drivers/media/v4l2-core/Kconfig                    |   37 +
 drivers/media/v4l2-core/Makefile                   |    4 +
 drivers/media/v4l2-core/v4l2-ctrls-core.c          |  194 +++
 drivers/media/v4l2-core/v4l2-ctrls-defs.c          |    9 +
 drivers/media/v4l2-core/v4l2-hevc-enc-kunit.c      |  554 +++++++
 drivers/media/v4l2-core/v4l2-hevc-enc-rbsp-kunit.c |  696 +++++++++
 drivers/media/v4l2-core/v4l2-hevc-enc-rbsp.c       |  977 +++++++++++++
 drivers/media/v4l2-core/v4l2-hevc-enc.c            | 1510 ++++++++++++++++++++
 include/media/v4l2-ctrls.h                         |    4 +
 include/media/v4l2-hevc-enc-rbsp.h                 |  279 ++++
 include/media/v4l2-hevc-enc.h                      |  300 ++++
 include/media/v4l2-hevc.h                          |  132 +-
 include/uapi/linux/v4l2-controls.h                 |  188 +++
 include/uapi/linux/videodev2.h                     |    2 +
 20 files changed, 5327 insertions(+), 1 deletion(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-hevc-encode-uapi-a26990b358b3
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

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

