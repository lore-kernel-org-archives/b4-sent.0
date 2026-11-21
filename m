From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 21 Nov 2026 10:10:54 +0000
Subject: [PATCH v2 1/3] media: uapi: mpeg2: add MPEG-1 flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-b4-cedrus-mpeg1-v2-1-95e4decf03fa@gmail.com>
References: <20261121-b4-cedrus-mpeg1-v2-0-95e4decf03fa@gmail.com>
In-Reply-To: <20261121-b4-cedrus-mpeg1-v2-0-95e4decf03fa@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795255854; l=5165;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=yksBdmk3Npzg1iAQRYT2QfTDslkSWSpomxA3ajPshVg=;
 b=zD3hF4yDQP2+FziY10T7J5ajIdxFnwDrZGEPewwBy9KBqn4EnsqL+XI7bKPKjDvN1Cpmx2NmD
 7U5MVYsy/1tBKXuGUofujHtyHmVJBX/GhkxJywxr8SP+DDnEobfHqOe
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Stateless MPEG-2 decoders can decode MPEG-1, but the uAPI cannot say a
stream is MPEG-1, and decoding it as MPEG-2 is wrong: MPEG-1 has its own
inverse quantisation mismatch control, full pel motion vectors and
D-pictures.

Add V4L2_MPEG2_SEQ_FLAG_MPEG1, V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD and
_BACKWARD, and allow V4L2_MPEG2_PIC_CODING_TYPE_D for MPEG-1. Drivers
that cannot decode MPEG-1 or D-pictures reject them, also in
VIDIOC_TRY_EXT_CTRLS. Kernels without this change accept the flag and
decode the stream as MPEG-2.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../media/v4l/ext-ctrls-codec-stateless.rst        | 34 ++++++++++++++++++++--
 drivers/media/v4l2-core/v4l2-ctrls-core.c          |  1 +
 include/uapi/linux/v4l2-controls.h                 |  3 ++
 3 files changed, 36 insertions(+), 2 deletions(-)

diff --git a/Documentation/userspace-api/media/v4l/ext-ctrls-codec-stateless.rst b/Documentation/userspace-api/media/v4l/ext-ctrls-codec-stateless.rst
index d7a3b8ef03a7..f51017b5d6f0 100644
--- a/Documentation/userspace-api/media/v4l/ext-ctrls-codec-stateless.rst
+++ b/Documentation/userspace-api/media/v4l/ext-ctrls-codec-stateless.rst
@@ -1317,6 +1317,22 @@ FWHT Flags
       - 0x01
       - Indication that all the frames for the sequence are progressive instead
 	of interlaced.
+    * - ``V4L2_MPEG2_SEQ_FLAG_MPEG1``
+      - 0x02
+      - The sequence is an ISO/IEC 11172-2 (MPEG-1) sequence: the inverse
+	quantisation uses the MPEG-1 mismatch control, motion vectors may be
+	full pel and pictures may be D-pictures. Drivers that cannot decode
+	MPEG-1 reject this flag, also in ``VIDIOC_TRY_EXT_CTRLS``. MPEG-1 has
+	no sequence or picture extensions: applications set the fields that
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
 
@@ -1366,8 +1382,12 @@ FWHT Flags
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
@@ -1415,6 +1435,16 @@ FWHT Flags
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

-- 
2.55.0

