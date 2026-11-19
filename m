From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 16:44:46 +0000
Subject: [PATCH RFC v4l-utils] v4l2-compliance: detect
 V4L2_PIX_FMT_MPEG1_SLICE decoders
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-v4l-utils-mpeg1-slice-v1-1-204ec6ef9166@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0NL3TKTHN3SksycYt3cgtR0Q93inMzkVF3zJEuDNHNjA5NEixQloN6
 CotS0zAqwudFKQW7OIDG4TqVYiIri0qSs1OQSkPFKtbUAcuFIoIsAAAA=
X-Change-ID: 20261119-v4l-utils-mpeg1-slice-7b90f7304a8d
To: Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795106686; l=3935;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=3DdqQ3KNlKglmIG7Q1VxCQYz+FeFKYbpbQNmL/+qqag=;
 b=h/SGZskaAHxRm1UZmHho4noMYeAX3sK6hWx2K3uGfPOAcn/JbMsERaBHrzPfJY1IkqAlBDSMW
 SyTOf6R7g0rAjjawD3x3lngpgMX7JJ/CV1gnBK/AGSZFfmN+cMTGlkG
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

determine_codec_mask() gives up on a compressed format it does not
know, so a decoder that lists 'MG1S' is not tested as a stateless
decoder and fails VIDIOC_(TRY_)DECODER_CMD.

The format and flags are added to the headers and v4l2-pix-formats.h
by hand; sync-with-kernel replaces them once the kernel series is in.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
For the kernel RFC "media: stateless MPEG-1 decoding, cedrus support":
https://lore.kernel.org/r/20261119-b4-cedrus-mpeg1-v1-0-aa5ba1192822@gmail.com

Tested with it on an Orange Pi Zero2 (cedrus): 49 of 49 tests pass.
Developed with Claude (Anthropic) as a coding assistant; I reviewed and
tested it.
---
 include/linux/v4l2-controls.h             | 3 +++
 include/linux/videodev2.h                 | 1 +
 utils/common/v4l2-pix-formats.h           | 1 +
 utils/v4l2-compliance/v4l2-compliance.cpp | 1 +
 4 files changed, 6 insertions(+)

diff --git a/include/linux/v4l2-controls.h b/include/linux/v4l2-controls.h
index 80d0e12e..8108f0ea 100644
--- a/include/linux/v4l2-controls.h
+++ b/include/linux/v4l2-controls.h
@@ -1986,6 +1986,7 @@ struct v4l2_ctrl_vp8_frame {
 /* Stateless MPEG-2 controls */
 
 #define V4L2_MPEG2_SEQ_FLAG_PROGRESSIVE	0x01
+#define V4L2_MPEG2_SEQ_FLAG_MPEG1	0x02
 
 #define V4L2_CID_STATELESS_MPEG2_SEQUENCE (V4L2_CID_CODEC_STATELESS_BASE+220)
 /**
@@ -2034,6 +2035,8 @@ struct v4l2_ctrl_mpeg2_sequence {
 #define V4L2_MPEG2_PIC_FLAG_ALT_SCAN			0x0020
 #define V4L2_MPEG2_PIC_FLAG_REPEAT_FIRST		0x0040
 #define V4L2_MPEG2_PIC_FLAG_PROGRESSIVE			0x0080
+#define V4L2_MPEG2_PIC_FLAG_FULL_PEL_FORWARD		0x0100
+#define V4L2_MPEG2_PIC_FLAG_FULL_PEL_BACKWARD		0x0200
 
 #define V4L2_CID_STATELESS_MPEG2_PICTURE (V4L2_CID_CODEC_STATELESS_BASE+221)
 /**
diff --git a/include/linux/videodev2.h b/include/linux/videodev2.h
index feb32668..d027e134 100644
--- a/include/linux/videodev2.h
+++ b/include/linux/videodev2.h
@@ -734,6 +734,7 @@ struct v4l2_pix_format {
 #define V4L2_PIX_FMT_MPEG1    v4l2_fourcc('M', 'P', 'G', '1') /* MPEG-1 ES     */
 #define V4L2_PIX_FMT_MPEG2    v4l2_fourcc('M', 'P', 'G', '2') /* MPEG-2 ES     */
 #define V4L2_PIX_FMT_MPEG2_SLICE v4l2_fourcc('M', 'G', '2', 'S') /* MPEG-2 parsed slice data */
+#define V4L2_PIX_FMT_MPEG1_SLICE v4l2_fourcc('M', 'G', '1', 'S') /* MPEG-1 parsed slice data */
 #define V4L2_PIX_FMT_MPEG4    v4l2_fourcc('M', 'P', 'G', '4') /* MPEG-4 part 2 ES */
 #define V4L2_PIX_FMT_XVID     v4l2_fourcc('X', 'V', 'I', 'D') /* Xvid           */
 #define V4L2_PIX_FMT_VC1_ANNEX_G v4l2_fourcc('V', 'C', '1', 'G') /* SMPTE 421M Annex G compliant stream */
diff --git a/utils/common/v4l2-pix-formats.h b/utils/common/v4l2-pix-formats.h
index efc31d73..e34c9ae1 100644
--- a/utils/common/v4l2-pix-formats.h
+++ b/utils/common/v4l2-pix-formats.h
@@ -223,6 +223,7 @@
 	case V4L2_PIX_FMT_H263: return "H.263";
 	case V4L2_PIX_FMT_MPEG1: return "MPEG-1 ES";
 	case V4L2_PIX_FMT_MPEG2: return "MPEG-2 ES";
+	case V4L2_PIX_FMT_MPEG1_SLICE: return "MPEG-1 Parsed Slice Data";
 	case V4L2_PIX_FMT_MPEG2_SLICE: return "MPEG-2 Parsed Slice Data";
 	case V4L2_PIX_FMT_MPEG4: return "MPEG-4 Part 2 ES";
 	case V4L2_PIX_FMT_XVID: return "Xvid";
diff --git a/utils/v4l2-compliance/v4l2-compliance.cpp b/utils/v4l2-compliance/v4l2-compliance.cpp
index e9e84363..f31b7ed5 100644
--- a/utils/v4l2-compliance/v4l2-compliance.cpp
+++ b/utils/v4l2-compliance/v4l2-compliance.cpp
@@ -604,6 +604,7 @@ static void determine_codec_mask(struct node &node)
 			case V4L2_PIX_FMT_FWHT:
 				mask |= STATEFUL_DECODER;
 				break;
+			case V4L2_PIX_FMT_MPEG1_SLICE:
 			case V4L2_PIX_FMT_MPEG2_SLICE:
 			case V4L2_PIX_FMT_H264_SLICE:
 			case V4L2_PIX_FMT_HEVC_SLICE:

---
base-commit: d2e89246cefcb6371425361b12c4ca2a36a662d2
change-id: 20261119-v4l-utils-mpeg1-slice-7b90f7304a8d

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

