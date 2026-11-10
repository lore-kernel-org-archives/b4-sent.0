From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:05:25 +0000
Subject: [PATCH RFC 11/11] media: h264: Add a VBR mode to the stateless
 encode rate control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-h264-encode-fixes-v1-11-7a64486df499@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305116; l=2597;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=supRZTl1AvC00lV2bzX7xn0VFI0B/bSEPB87pSRgFFQ=;
 b=xHWnw7KxUwqWPaqyeTwDZiHs3gWXjvAJANgbHO5qQKsCy39hZlO6aaXqIOqFE53x2OGnAXSdc
 8DMBmtKzErnAx/bgxY38dLt64TsPAUQR9goCZ1q0Mv85LWJ5tcN+MUG
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The core reads V4L2_CID_MPEG_VIDEO_BITRATE and _BITRATE_PEAK for
V4L2_MPEG_VIDEO_BITRATE_MODE_VBR, but has no mode for it, so a driver
offering VBR fails the first picture with -EINVAL.

Add one with the encode rate control and its peak bitrate: the bitrate is
met on average and every second stays within the peak (a peak below the
bitrate counts as the bitrate). Drivers offer it with the VBR entry of
V4L2_CID_MPEG_VIDEO_BITRATE_MODE and V4L2_CID_MPEG_VIDEO_BITRATE_PEAK.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/v4l2-core/v4l2-h264-enc-rc.c | 24 ++++++++++++++++++++++++
 drivers/media/v4l2-core/v4l2-h264-enc.c    |  3 ++-
 2 files changed, 26 insertions(+), 1 deletion(-)

diff --git a/drivers/media/v4l2-core/v4l2-h264-enc-rc.c b/drivers/media/v4l2-core/v4l2-h264-enc-rc.c
index c4f1718ead0e..691c80c2a950 100644
--- a/drivers/media/v4l2-core/v4l2-h264-enc-rc.c
+++ b/drivers/media/v4l2-core/v4l2-h264-enc-rc.c
@@ -218,10 +218,34 @@ static const struct v4l2_h264_enc_rc_mode cbr_mode = {
 	.complete	= cbr_complete,
 };
 
+/*
+ * Variable bitrate mode: the same rate control with the peak bitrate, which
+ * meets the bitrate on average and keeps every second within the peak.
+ */
+static int vbr_measure(struct v4l2_h264_enc_rc *rc, unsigned long *size)
+{
+	struct v4l2_h264_enc_state *state = rc->state;
+
+	v4l2_enc_cbr_set_peak(&rc->cbr, max(state->bitrate_peak,
+					    state->bitrate));
+
+	return cbr_measure(rc, size);
+}
+
+static const struct v4l2_h264_enc_rc_mode vbr_mode = {
+	.name		= "variable bitrate",
+	.type		= V4L2_H264_ENC_RC_TYPE_VBR,
+	.init		= cbr_init,
+	.measure	= vbr_measure,
+	.estimate	= cbr_estimate,
+	.complete	= cbr_complete,
+};
+
 static const struct v4l2_h264_enc_rc_mode *modes[] = {
 	&direct_mode,
 	&cq_mode,
 	&cbr_mode,
+	&vbr_mode,
 };
 
 static int mode_prepare(struct v4l2_h264_enc_rc *rc)
diff --git a/drivers/media/v4l2-core/v4l2-h264-enc.c b/drivers/media/v4l2-core/v4l2-h264-enc.c
index 9745c0e85ee5..66473231df94 100644
--- a/drivers/media/v4l2-core/v4l2-h264-enc.c
+++ b/drivers/media/v4l2-core/v4l2-h264-enc.c
@@ -1273,7 +1273,8 @@ static int rc_step(struct v4l2_h264_enc *enc)
 	if (rc->mode) {
 		pr_debug("  rc mode: %s", rc->mode->name);
 
-		if (rc->mode->type == V4L2_H264_ENC_RC_TYPE_CBR) {
+		if (rc->mode->type == V4L2_H264_ENC_RC_TYPE_CBR ||
+		    rc->mode->type == V4L2_H264_ENC_RC_TYPE_VBR) {
 			pr_debug("  rc bitrate: %u bits/s", state->bitrate);
 			pr_debug("  rc target: %lu bytes", rc->size);
 		}

-- 
2.55.0

