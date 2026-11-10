From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH RFC 00/11] media: h264: Stateless encode core follow-ups:
 parameter sets, POC type 2, CBR and VBR
Date: Tue, 10 Nov 2026 10:05:14 +0000
Message-Id: <20261110-h264-encode-fixes-v1-0-7a64486df499@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12RzWocMRCEX2WZcwb6Ty3JV0MeINfgg9Tdyk7Au
 87OOgSM3z2yYwLrY7fqqypaL8sely325e7wslzi97Zv59Mc8MthsWM7/Yh18zkvBKSICOuRVNY
 42dljHduf2FdDozEqYM1jmdzTJd4fJvZ9+fb1fnn4t9yf+8+w65vbh+wSv55n4vVD+9Sudpx5d
 4fhiAMrqeYkjt0F+lB0T47esjRwQzZ69/lPZcvhllmk1uKJIEYbuQuDVRhzMQUglm8p0VI9cob
 o2G36Jnbt4Y2CKzlY6JiWfktBG25GUipFs5wZWB2Sl5FAIpl1TtH1U8MwK1I7MxUXrsoFBtgw5
 pmqhuoU4FRuKdNZY55EM6jJZJWkSikwE2gUz52IW8CnrJrmtZICD4cMwFIVGrJSSNE8/wxJXOs
 b1dseq50fH7fr3UGVSmQX007JimMZyJKCG81uWKi2FjlkeXh9/Qs9p3E0QAIAAA==
X-Change-ID: 20261110-h264-encode-fixes-c1c2ff90197f
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Paul Kocialkowski <paulk@sys-base.io>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Marco Felsch <m.felsch@pengutronix.de>, 
 Michael Tretter <m.tretter@pengutronix.de>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305116; l=6899;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=5TrgGHhotbPNvGgRX8BBgP7U78u5uxGT8X+sv1aYgpo=;
 b=RJ8lRlZVwnaZvWwKDiD165cU4Z206OeBip9IDZe2y7nk6gDIoJr728YADk1FuKZonv57kmcTO
 J+0yL22ZtnPACRCrAF2KApn4YmpY1dRQvkVmXut4NPPhs+JrArjJOOf
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Paul,

These are changes to the H.264 stateless encode core of your "media: Add
V4L2 H.264 stateless encode and VC8000E support" series, v1 (2026-05-22):
https://lore.kernel.org/all/20260522101653.2565125-1-paulk@sys-base.io/
(https://patchwork.kernel.org/project/linux-media/list/?series=1099281)

They came out of three drivers written on top of the series: a VEPU2
backend for the Rockchip RK3588 VPU121 in the Hantro driver and a driver
for the Rockchip VEPU580 (both posted as separate RFCs on top of this
one), and a cedrus encoder backend for the Allwinner H616 that the
Orange Pi Zero 2 project carries (not posted). They apply on media next
6628e7d4c6b2 (v7.4-rc1) with patches 1-7 of your v1 applied first; the
prerequisite-patch-id lines below are those seven patches. Patches 2, 4,
5 and 7 of v1 need trivial context fixes on v7.4-rc1 (the HEVC
extended SPS RPS control declarations in v4l2-ctrls-core.c, the v4l2-isp
line in the v4l2-core Makefile); the code is unchanged.

As far as I can see on patchwork there is no v2 yet. I'm sending these as
an RFC so that they can be folded into it or reworked with it, rather
than to be merged on their own.

Patches 1-3 are fixes:
1. The SPS/PPS change detection in rbsp_update() is inverted: every
   picture after the first gets the parameter sets again. Only write
   them for the first picture and when they change.
2. Encoders whose hardware writes the slice header cannot put a
   pic_order_cnt_lsb in it: the Hantro H1 and the Rockchip VEPU1/VEPU2
   only produce slice headers for pic_order_cnt_type 2. Accept type 2
   (selected through state_constrain) and derive the picture order
   count from frame_num (H.264 8.2.1.3).
3. The SPS and PPS NAL units are written with nal_ref_idc 0, which
   H.264 7.4.1 forbids (FFmpeg's probe gives such a stream a score of 1).
   Write them with nal_ref_idc 3.

Patches 4-11 rework the rate control:
4. Rework the constant bitrate mode after the frame-level rate control
   of the Rockchip MPP library: one QP state for the stream, picture
   size targets from a GOP plan with the I/P size ratio measured on the
   stream, and the size error spread over the next 8 pictures. The v1
   mode stays 5-9% below the bitrate and overshoots several times on
   the first P picture after each IDR picture (details in the patch).
5. Move that model to a codec-independent helper, v4l2-enc-cbr, so that
   an HEVC core can use it (the HEVC encode RFC does).
6-9. Bound the I picture size, halve the QP increase of I pictures,
   re-encode pictures far above their size target (for drivers that
   can run a picture again; the H.264 core does not offer it yet) and
   fix all-intra streams.
10-11. A peak bitrate in the helper and a VBR mode
   (V4L2_MPEG_VIDEO_BITRATE_MODE_VBR with V4L2_CID_MPEG_VIDEO_BITRATE_PEAK)
   in the H.264 core.

One more observation, not changed here: state_commit() publishes
V4L2_CID_STATELESS_H264_ENCODE_PARAMS before rc_step() sets
slice_qp_delta, so the slice_qp_delta read back from the request is the
value before rate control. The QP used for the encode is the right one.

Tested on an Orange Pi 5 (RK3588S) through the VEPU2 (Hantro) and
VEPU580 drivers, on a v7.3-based kernel whose v4l2-core encode files are
byte-identical to this series. 1080p60, 300 pictures of two clips (Big
Buck Bunny and a natural one), every stream decoded with FFmpeg to 300
pictures:
- CBR at 4 Mbit/s with an IDR period of 120, 8 Mbit/s with 10 and
  20 Mbit/s all-intra: bitrate within 2.2% of the target on both
  encoders; the largest one second window is at most 1.37 times the
  bitrate (a scene change in a P picture of Big Buck Bunny on the
  VEPU580), 1.24 on the VEPU2;
- VBR with the peak at 1.5 times the bitrate, the same cases and
  8 Mbit/s with an IDR period of 120: bitrate within
  4.5% of the target, every one second window within the peak (at most
  0.94 of it);
- the GStreamer v4l2codecs H.264 encoder (local patches) on the VEPU2,
  CBR at 2-16 Mbit/s: bitrate within 2.5% of the target;
- patch 1: a 60-picture GOP-30 stream carries one SPS and PPS before
  each of its two IDR pictures and none before the P pictures.
The whole series also passes on an Orange Pi Zero 2 (Allwinner H616)
with the cedrus H.264 encoder: CBR and VBR rate control within 5% of the
target (measured within 0.1%, every one-second window at most 1.2 times
the peak bitrate), all-intra and GOP 10 streams, and every stream
decoded bit-exact by the board's hardware decoder against FFmpeg.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (11):
      media: h264: Only write the SPS and PPS of a stateless encode when they change
      media: h264: Support picture order count type 2 in stateless encode
      media: h264: Write the stateless encode SPS and PPS with nal_ref_idc 3
      media: v4l2-h264-enc-rc: Rework the constant bitrate mode
      media: v4l2-core: Move the H.264 encode CBR rate control to a helper
      media: v4l2-core: Bound the I picture size in the encode CBR rate control
      media: v4l2-core: Halve the I picture QP increase of the encode CBR
      media: v4l2-core: Re-encode oversized pictures in the encode CBR
      media: v4l2-core: Fix all-intra streams in the encode CBR rate control
      media: v4l2-core: Add a peak bitrate to the encode rate control
      media: h264: Add a VBR mode to the stateless encode rate control

 drivers/media/v4l2-core/Kconfig              |   5 +
 drivers/media/v4l2-core/Makefile             |   1 +
 drivers/media/v4l2-core/v4l2-enc-cbr.c       | 593 +++++++++++++++++++++++++++
 drivers/media/v4l2-core/v4l2-h264-enc-rbsp.c |   7 +-
 drivers/media/v4l2-core/v4l2-h264-enc-rc.c   | 294 +++----------
 drivers/media/v4l2-core/v4l2-h264-enc.c      |  65 ++-
 include/media/v4l2-enc-cbr.h                 | 103 +++++
 include/media/v4l2-h264-enc-rc.h             |   3 +
 include/media/v4l2-h264-enc.h                |   3 +
 9 files changed, 820 insertions(+), 254 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-h264-encode-fixes-c1c2ff90197f
prerequisite-patch-id: fd11f19266754d1bd40bf61dd5d1da74a0dc13c2
prerequisite-patch-id: 7c7edc7344998d520efaf7b430c90fd527c704c7
prerequisite-patch-id: 4689de770eb1bcdc153d6beda2e392d0ce6f344d
prerequisite-patch-id: 0afdcc24892eac773036d05d8f504e5ccb35eb62
prerequisite-patch-id: ecc849b3328d4396380f0cfc331536c16d2e0d28
prerequisite-patch-id: c62d0fd16706c4328624948805eb2f8d7b223ae0
prerequisite-patch-id: e955d15603fd070034960a1362e4867c2f124d69

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

