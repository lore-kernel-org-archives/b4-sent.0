From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 16:34:52 +0000
Subject: [PATCH RFC 1/2] media: uapi: mpeg2: add MPEG-1 flags and the
 MPEG-1 parsed slice format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-cedrus-mpeg1-v1-1-aa5ba1192822@gmail.com>
References: <20261119-b4-cedrus-mpeg1-v1-0-aa5ba1192822@gmail.com>
In-Reply-To: <20261119-b4-cedrus-mpeg1-v1-0-aa5ba1192822@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795106091; l=10856;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=cr1ebbEpYfWsicr/Rh2XWDklPbPQq1/SEj00xW+AuGw=;
 b=YTzvKL1/vIhS7V+WNcIzdm3mzTdaytbUeglRKrle4YvKlRrIG2OTzwAFizgCyoeGQvQAjOfn0
 HkIAv+gc5dyAiLacoGNM9MuZJx7lJ3pYpRxt7PTO2kyxq6Sc7ZE6tXb
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Stateless MPEG-2 decoders can decode MPEG-1, but the uAPI cannot say a
stream is MPEG-1, and decoding it as MPEG-2 is wrong: MPEG-1 has its own
inverse quantisation mismatch control, full pel motion vectors and
D-pictures.

Add V4L2_MPEG2_SEQ_FLAG_MPEG1, V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD and
_BACKWARD, and allow V4L2_MPEG2_PIC_CODING_TYPE_D for MPEG-1.

Flags alone are not discoverable (the control framework does not check
compound control flags, and existing drivers would decode such a stream
as MPEG-2), so add V4L2_PIX_FMT_MPEG1_SLICE ('MG1S'). It reuses the
MPEG-2 controls; the MPEG-1 flag is set with this format only. Drivers
that cannot decode D-pictures reject that coding type, also in
VIDIOC_TRY_EXT_CTRLS, so applications can check before decoding.

hantro has no MPEG-1 mode: reject the MPEG-1 flags and D-pictures
there, which it would otherwise decode as MPEG-2 inter pictures.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../media/v4l/ext-ctrls-codec-stateless.rst        | 35 ++++++++++++++++++++--
 .../userspace-api/media/v4l/pixfmt-compressed.rst  | 23 ++++++++++++++
 drivers/media/platform/verisilicon/hantro_drv.c    | 12 ++++++++
 drivers/media/v4l2-core/v4l2-ctrls-core.c          |  1 +
 drivers/media/v4l2-core/v4l2-ioctl.c               |  1 +
 include/uapi/linux/v4l2-controls.h                 |  3 ++
 include/uapi/linux/videodev2.h                     |  1 +
 7 files changed, 74 insertions(+), 2 deletions(-)

diff --git a/Documentation/userspace-api/media/v4l/ext-ctrls-codec-stateless.rst b/Documentation/userspace-api/media/v4l/ext-ctrls-codec-stateless.rst
index d7a3b8ef03a7..afe57be7cb87 100644
--- a/Documentation/userspace-api/media/v4l/ext-ctrls-codec-stateless.rst
+++ b/Documentation/userspace-api/media/v4l/ext-ctrls-codec-stateless.rst
@@ -1317,6 +1317,23 @@ FWHT Flags
       - 0x01
       - Indication that all the frames for the sequence are progressive instead
 	of interlaced.
+    * - ``V4L2_MPEG2_SEQ_FLAG_MPEG1``
+      - 0x02
+      - The sequence is an ISO/IEC 11172-2 (MPEG-1) sequence: the inverse
+	quantisation uses the MPEG-1 mismatch control, motion vectors may be
+	full pel and pictures may be D-pictures. Applications set this flag
+	if and only if the coded format is ``V4L2_PIX_FMT_MPEG1_SLICE``;
+	drivers reject it with ``V4L2_PIX_FMT_MPEG2_SLICE``. MPEG-1 has no
+	sequence or picture extensions: applications set the fields that
+	come from them to chroma_format 1, V4L2_MPEG2_SEQ_FLAG_PROGRESSIVE,
+	frame pictures with V4L2_MPEG2_PIC_FLAG_FRAME_PRED_DCT and
+	V4L2_MPEG2_PIC_FLAG_PROGRESSIVE, intra_dc_precision 0, the flags
+	V4L2_MPEG2_PIC_FLAG_Q_SCALE_TYPE, V4L2_MPEG2_PIC_FLAG_INTRA_VLC,
+	V4L2_MPEG2_PIC_FLAG_ALT_SCAN, V4L2_MPEG2_PIC_FLAG_CONCEALMENT_MV,
+	V4L2_MPEG2_PIC_FLAG_TOP_FIELD_FIRST and
+	V4L2_MPEG2_PIC_FLAG_REPEAT_FIRST cleared, both components of
+	``f_code[0]`` set to forward_f_code and of ``f_code[1]`` to
+	backward_f_code.
 
 .. raw:: latex
 
@@ -1366,8 +1383,12 @@ FWHT Flags
     * - __u8
       - ``picture_coding_type``
       - Picture coding type for the frame covered by the current slice
-	(V4L2_MPEG2_PIC_CODING_TYPE_I, V4L2_MPEG2_PIC_CODING_TYPE_P or
-	V4L2_MPEG2_PIC_CODING_TYPE_B).
+	(V4L2_MPEG2_PIC_CODING_TYPE_I, V4L2_MPEG2_PIC_CODING_TYPE_P,
+	V4L2_MPEG2_PIC_CODING_TYPE_B, or V4L2_MPEG2_PIC_CODING_TYPE_D in MPEG-1
+	sequences). Decoding D-pictures is optional: drivers that cannot
+	decode them reject V4L2_MPEG2_PIC_CODING_TYPE_D, also in
+	``VIDIOC_TRY_EXT_CTRLS``, which applications can use to find out
+	whether D-pictures are supported.
     * - __u8
       - ``picture_structure``
       - Picture structure (1: interlaced top field, 2: interlaced bottom field,
@@ -1415,6 +1436,16 @@ FWHT Flags
     * - ``V4L2_MPEG2_PIC_FLAG_PROGRESSIVE``
       - 0x00000080
       - Indicates whether the current frame is progressive.
+    * - ``V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD``
+      - 0x00000100
+      - full_pel_forward_vector of an MPEG-1 picture header: the forward
+	motion vectors are in full pel units. Only valid with
+	V4L2_MPEG2_SEQ_FLAG_MPEG1.
+    * - ``V4L2_MPEG2_PIC_FLAG_FULL_PEL_BACKWARD``
+      - 0x00000200
+      - full_pel_backward_vector of an MPEG-1 picture header: the backward
+	motion vectors are in full pel units. Only valid with
+	V4L2_MPEG2_SEQ_FLAG_MPEG1.
 
 .. raw:: latex
 
diff --git a/Documentation/userspace-api/media/v4l/pixfmt-compressed.rst b/Documentation/userspace-api/media/v4l/pixfmt-compressed.rst
index 235f955d3cd5..898bb5393f9f 100644
--- a/Documentation/userspace-api/media/v4l/pixfmt-compressed.rst
+++ b/Documentation/userspace-api/media/v4l/pixfmt-compressed.rst
@@ -129,6 +129,29 @@ Compressed Formats
 	this pixel format. The output buffer must contain the appropriate number
 	of macroblocks to decode a full corresponding frame to the matching
 	capture buffer.
+    * .. _V4L2-PIX-FMT-MPEG1-SLICE:
+
+      - ``V4L2_PIX_FMT_MPEG1_SLICE``
+      - 'MG1S'
+      - MPEG-1 parsed slice data, as extracted from the MPEG-1
+	(ISO/IEC 11172-2) bitstream. This format is adapted for stateless
+	video decoders that implement a MPEG-1 pipeline with the
+	:ref:`stateless_decoder`. It uses the controls of
+	``V4L2_PIX_FMT_MPEG2_SLICE``: metadata associated with the frame to
+	decode is required to be passed through the
+	``V4L2_CID_STATELESS_MPEG2_SEQUENCE`` and
+	``V4L2_CID_STATELESS_MPEG2_PICTURE`` controls, with
+	``V4L2_MPEG2_SEQ_FLAG_MPEG1`` set in the sequence control and the
+	fields that come from the MPEG-2 extensions filled as described for
+	that flag. Quantisation matrices can optionally be specified through
+	the ``V4L2_CID_STATELESS_MPEG2_QUANTISATION`` control.
+	See the :ref:`associated Codec Control IDs <v4l2-codec-stateless-mpeg2>`.
+	Exactly one output and one capture buffer must be provided for use with
+	this pixel format. The output buffer must contain the appropriate number
+	of macroblocks to decode a full corresponding frame to the matching
+	capture buffer. Decoders that enumerate this format decode MPEG-1
+	sequences; decoders that only enumerate ``V4L2_PIX_FMT_MPEG2_SLICE``
+	do not.
     * .. _V4L2-PIX-FMT-MPEG4:
 
       - ``V4L2_PIX_FMT_MPEG4``
diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index 26e5d5547466..c910a69e8e3c 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -264,6 +264,16 @@ static int hantro_try_ctrl(struct v4l2_ctrl *ctrl)
 		if (sps->bit_depth_luma_minus8 != 0 && sps->bit_depth_luma_minus8 != 2)
 			/* Only 8-bit and 10-bit are supported */
 			return -EINVAL;
+	} else if (ctrl->id == V4L2_CID_STATELESS_MPEG2_SEQUENCE) {
+		if (ctrl->p_new.p_mpeg2_sequence->flags & V4L2_MPEG2_SEQ_FLAG_MPEG1)
+			return -EINVAL;
+	} else if (ctrl->id == V4L2_CID_STATELESS_MPEG2_PICTURE) {
+		const struct v4l2_ctrl_mpeg2_picture *pic = ctrl->p_new.p_mpeg2_picture;
+
+		if (pic->picture_coding_type == V4L2_MPEG2_PIC_CODING_TYPE_D ||
+		    pic->flags & (V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD |
+				  V4L2_MPEG2_PIC_FLAG_FULL_PEL_BACKWARD))
+			return -EINVAL;
 	} else if (ctrl->id == V4L2_CID_STATELESS_VP9_FRAME) {
 		const struct v4l2_ctrl_vp9_frame *dec_params = ctrl->p_new.p_vp9_frame;
 
@@ -435,11 +445,13 @@ static const struct hantro_ctrl controls[] = {
 		.codec = HANTRO_MPEG2_DECODER,
 		.cfg = {
 			.id = V4L2_CID_STATELESS_MPEG2_SEQUENCE,
+			.ops = &hantro_ctrl_ops,
 		},
 	}, {
 		.codec = HANTRO_MPEG2_DECODER,
 		.cfg = {
 			.id = V4L2_CID_STATELESS_MPEG2_PICTURE,
+			.ops = &hantro_ctrl_ops,
 		},
 	}, {
 		.codec = HANTRO_MPEG2_DECODER,
diff --git a/drivers/media/v4l2-core/v4l2-ctrls-core.c b/drivers/media/v4l2-core/v4l2-ctrls-core.c
index 6e751a043a21..a12359626121 100644
--- a/drivers/media/v4l2-core/v4l2-ctrls-core.c
+++ b/drivers/media/v4l2-core/v4l2-ctrls-core.c
@@ -1049,6 +1049,7 @@ static int std_validate_compound(const struct v4l2_ctrl *ctrl, u32 idx,
 		case V4L2_MPEG2_PIC_CODING_TYPE_I:
 		case V4L2_MPEG2_PIC_CODING_TYPE_P:
 		case V4L2_MPEG2_PIC_CODING_TYPE_B:
+		case V4L2_MPEG2_PIC_CODING_TYPE_D:
 			break;
 		default:
 			return -EINVAL;
diff --git a/drivers/media/v4l2-core/v4l2-ioctl.c b/drivers/media/v4l2-core/v4l2-ioctl.c
index b7d248ab7db2..bbe7a0ae75df 100644
--- a/drivers/media/v4l2-core/v4l2-ioctl.c
+++ b/drivers/media/v4l2-core/v4l2-ioctl.c
@@ -1507,6 +1507,7 @@ static void v4l_fill_fmtdesc(struct v4l2_fmtdesc *fmt)
 		case V4L2_PIX_FMT_H263:		descr = "H.263"; break;
 		case V4L2_PIX_FMT_MPEG1:	descr = "MPEG-1 ES"; break;
 		case V4L2_PIX_FMT_MPEG2:	descr = "MPEG-2 ES"; break;
+		case V4L2_PIX_FMT_MPEG1_SLICE:	descr = "MPEG-1 Parsed Slice Data"; break;
 		case V4L2_PIX_FMT_MPEG2_SLICE:	descr = "MPEG-2 Parsed Slice Data"; break;
 		case V4L2_PIX_FMT_MPEG4:	descr = "MPEG-4 Part 2 ES"; break;
 		case V4L2_PIX_FMT_XVID:		descr = "Xvid"; break;
diff --git a/include/uapi/linux/v4l2-controls.h b/include/uapi/linux/v4l2-controls.h
index d17e41d51d2e..e7e6030ac00c 100644
--- a/include/uapi/linux/v4l2-controls.h
+++ b/include/uapi/linux/v4l2-controls.h
@@ -2007,6 +2007,7 @@ struct v4l2_ctrl_vp8_frame {
 /* Stateless MPEG-2 controls */
 
 #define V4L2_MPEG2_SEQ_FLAG_PROGRESSIVE	0x01
+#define V4L2_MPEG2_SEQ_FLAG_MPEG1	0x02
 
 #define V4L2_CID_STATELESS_MPEG2_SEQUENCE (V4L2_CID_CODEC_STATELESS_BASE+220)
 /**
@@ -2055,6 +2056,8 @@ struct v4l2_ctrl_mpeg2_sequence {
 #define V4L2_MPEG2_PIC_FLAG_ALT_SCAN			0x0020
 #define V4L2_MPEG2_PIC_FLAG_REPEAT_FIRST		0x0040
 #define V4L2_MPEG2_PIC_FLAG_PROGRESSIVE			0x0080
+#define V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD		0x0100
+#define V4L2_MPEG2_PIC_FLAG_FULL_PEL_BACKWARD		0x0200
 
 #define V4L2_CID_STATELESS_MPEG2_PICTURE (V4L2_CID_CODEC_STATELESS_BASE+221)
 /**
diff --git a/include/uapi/linux/videodev2.h b/include/uapi/linux/videodev2.h
index 5373dba640fa..c7469c01e83f 100644
--- a/include/uapi/linux/videodev2.h
+++ b/include/uapi/linux/videodev2.h
@@ -761,6 +761,7 @@ struct v4l2_pix_format {
 #define V4L2_PIX_FMT_MPEG1    v4l2_fourcc('M', 'P', 'G', '1') /* MPEG-1 ES     */
 #define V4L2_PIX_FMT_MPEG2    v4l2_fourcc('M', 'P', 'G', '2') /* MPEG-2 ES     */
 #define V4L2_PIX_FMT_MPEG2_SLICE v4l2_fourcc('M', 'G', '2', 'S') /* MPEG-2 parsed slice data */
+#define V4L2_PIX_FMT_MPEG1_SLICE v4l2_fourcc('M', 'G', '1', 'S') /* MPEG-1 parsed slice data */
 #define V4L2_PIX_FMT_MPEG4    v4l2_fourcc('M', 'P', 'G', '4') /* MPEG-4 part 2 ES */
 #define V4L2_PIX_FMT_XVID     v4l2_fourcc('X', 'V', 'I', 'D') /* Xvid           */
 #define V4L2_PIX_FMT_VC1_ANNEX_G v4l2_fourcc('V', 'C', '1', 'G') /* SMPTE 421M Annex G compliant stream */

-- 
2.55.0

