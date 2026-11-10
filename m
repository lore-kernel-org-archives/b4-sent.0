From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:05:15 +0000
Subject: [PATCH RFC 01/11] media: h264: Only write the SPS and PPS of a
 stateless encode when they change
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-h264-encode-fixes-v1-1-7a64486df499@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305116; l=2032;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Rto6Khl5v0MGxvUzll0pj/YSX45EUzCtavvbMJo4tew=;
 b=jjcaKoArzPuOamZoqU36/oXnjN5APV5b06YiPYwcMEvNtx9xtEj6NvctZvji6eR2zQVLoqdLz
 hr7Ex7e7BoJCeKmn4/x6Xnm/YfG+e1H8LWFm4KKMNFbFHX4/pfB1qP5
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The stateless encode core is meant to write the SPS and PPS for the first
picture of a stream, and then only when they change. The check is
inverted: the first picture compares the new SPS and PPS with the zeroed
active state, which always differs, and all the following pictures get
them unconditionally. This wastes some bits on every picture, and skews
the size statistics of the rate control.

Compare with the active state once a picture was encoded, and write them
unconditionally for the first picture. The
V4L2_CID_MPEG_VIDEO_PREPEND_SPSPPS_TO_IDR control still forces them on
IDR pictures.

To be squashed into "media: h264: Add stateless encode core" from
https://patch.msgid.link/20260522101653.2565125-5-paulk@sys-base.io

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/v4l2-core/v4l2-h264-enc.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/drivers/media/v4l2-core/v4l2-h264-enc.c b/drivers/media/v4l2-core/v4l2-h264-enc.c
index 67ea82cebe7f..af925b6626cf 100644
--- a/drivers/media/v4l2-core/v4l2-h264-enc.c
+++ b/drivers/media/v4l2-core/v4l2-h264-enc.c
@@ -762,9 +762,12 @@ static int rbsp_update(struct v4l2_h264_enc *enc)
 	if (ctrl && ctrl->cur.val)
 		enc->rbsp_update |= V4L2_H264_ENC_RBSP_UPDATE_AUD;
 
-	/* SPS */
+	/*
+	 * SPS: always written for the first picture of the stream, then only
+	 * when it changes.
+	 */
 
-	if (!enc->state_serial) {
+	if (enc->state_serial) {
 		if (memcmp(&state_active->sps, &state->sps,
 			   sizeof(state_active->sps)) ||
 		    memcmp(&state_active->sps_video, &state->sps_video,
@@ -774,9 +777,9 @@ static int rbsp_update(struct v4l2_h264_enc *enc)
 		enc->rbsp_update |= V4L2_H264_ENC_RBSP_UPDATE_SPS;
 	}
 
-	/* PPS */
+	/* PPS: same as the SPS. */
 
-	if (!enc->state_serial) {
+	if (enc->state_serial) {
 		if (memcmp(&state_active->pps, &state->pps,
 			   sizeof(state_active->pps)))
 			enc->rbsp_update |= V4L2_H264_ENC_RBSP_UPDATE_PPS;

-- 
2.55.0

