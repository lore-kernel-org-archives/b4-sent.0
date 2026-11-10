From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:05:17 +0000
Subject: [PATCH RFC 03/11] media: h264: Write the stateless encode SPS and
 PPS with nal_ref_idc 3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-h264-encode-fixes-v1-3-7a64486df499@gmail.com>
References: <20261110-h264-encode-fixes-v1-0-7a64486df499@gmail.com>
In-Reply-To: <20261110-h264-encode-fixes-v1-0-7a64486df499@gmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Paul Kocialkowski <paulk@sys-base.io>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Marco Felsch <m.felsch@pengutronix.de>, 
 Michael Tretter <m.tretter@pengutronix.de>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305116; l=1645;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=zXcv0YCbY9QS6/mK5AO05SvWHKGBxnD43EKlSGfUjz8=;
 b=wd8cdQ/TIylNSiaZgPRwRMIhpf4DXaAbjvBJxq8z+MDCmZaixkRI/Ow+2oE2SktxbD/vBYG1x
 /RVUlF+nuTbBZqZK0AlmoLs4c2TIdO1zPaE5/T4DEIqlV2bdTqe4k6q
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sequence and picture parameter set NAL units are written with
nal_ref_idc 0, which ITU-T H.264 section 7.4.1 forbids: "nal_ref_idc
shall not be equal to 0 for sequence parameter set or sequence parameter
set extension or subset sequence parameter set or picture parameter set
NAL units". FFmpeg's H.264 probe rejects such streams (an Annex B file
from the encoder is "detected only with low score of 1"), and stricter
decoders may drop the parameter sets.

Write them with nal_ref_idc 3, as other encoders do. Access unit
delimiters keep 0, which the specification requires for them.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/v4l2-core/v4l2-h264-enc-rbsp.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/media/v4l2-core/v4l2-h264-enc-rbsp.c b/drivers/media/v4l2-core/v4l2-h264-enc-rbsp.c
index 2d751855195b..fa5857b77d76 100644
--- a/drivers/media/v4l2-core/v4l2-h264-enc-rbsp.c
+++ b/drivers/media/v4l2-core/v4l2-h264-enc-rbsp.c
@@ -654,7 +654,7 @@ int v4l2_h264_enc_rbsp_sps(struct v4l2_h264_enc_rbsp *rbsp,
 	unsigned int i;
 	int ret;
 
-	ret = v4l2_h264_enc_rbsp_nalu_begin(rbsp, 0, V4L2_H264_NALU_TYPE_SPS);
+	ret = v4l2_h264_enc_rbsp_nalu_begin(rbsp, 3, V4L2_H264_NALU_TYPE_SPS);
 	if (ret)
 		return ret;
 
@@ -845,7 +845,7 @@ int v4l2_h264_enc_rbsp_pps(struct v4l2_h264_enc_rbsp *rbsp,
 	u8 pic_scaling_matrix_present_flag = 0;
 	int ret;
 
-	ret = v4l2_h264_enc_rbsp_nalu_begin(rbsp, 0, V4L2_H264_NALU_TYPE_PPS);
+	ret = v4l2_h264_enc_rbsp_nalu_begin(rbsp, 3, V4L2_H264_NALU_TYPE_PPS);
 	if (ret)
 		return ret;
 

-- 
2.55.0

