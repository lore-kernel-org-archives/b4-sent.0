From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:07:39 +0000
Subject: [PATCH RFC 09/10] media: v4l2-hevc-enc: Re-encode oversized
 pictures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hevc-encode-uapi-v1-9-38ae9fcfedd4@gmail.com>
References: <20261110-hevc-encode-uapi-v1-0-38ae9fcfedd4@gmail.com>
In-Reply-To: <20261110-hevc-encode-uapi-v1-0-38ae9fcfedd4@gmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305251; l=3645;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=BLpAo/ixfrwr4n6bp3710+JDuneOuRSPbETSTp9CIrU=;
 b=+xbqip82hxr2sijn1KFdJqn+hIKzMJ43VyBK2/bw+6Z1rl7XZP/9SJl56bCM+5EKcg8qStMfW
 fmINAf9Bl1CBG5PSNAVySLZ7SImXk5w03LxDG6zUMyiXJaPAii6PrjK
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A scene change in a P picture can make it many times larger than its size
target, and the peak bitrate around it can then exceed what a decoder
buffer of the stream takes. v4l2-enc-cbr can ask for a second pass of such
a picture at a higher QP (v4l2_enc_cbr_reencode()).

Provide v4l2_hevc_enc_reencode() in the HEVC encode core for drivers whose
hardware writes the slice header: called after the hardware finished a
picture and before v4l2_hevc_enc_complete(), it returns true with the new
QP in enc->qp when the constant bitrate mode wants the picture encoded
again. Hardware that takes the slice header from the core cannot use it:
that header holds the QP of the first pass.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/v4l2-core/v4l2-hevc-enc.c | 39 +++++++++++++++++++++++++++++++++
 include/media/v4l2-hevc-enc.h           |  2 ++
 2 files changed, 41 insertions(+)

diff --git a/drivers/media/v4l2-core/v4l2-hevc-enc.c b/drivers/media/v4l2-core/v4l2-hevc-enc.c
index 2e0ba832b868..d49cee336558 100644
--- a/drivers/media/v4l2-core/v4l2-hevc-enc.c
+++ b/drivers/media/v4l2-core/v4l2-hevc-enc.c
@@ -1369,6 +1369,45 @@ static int ref_complete(struct v4l2_hevc_enc *enc, u64 timestamp)
 	return 0;
 }
 
+/**
+ * v4l2_hevc_enc_reencode() - decide on encoding the picture a second time
+ * @enc: the core context
+ * @bytesused: size of the encoded picture in bytes, with the headers the core
+ *	       wrote
+ *
+ * In the constant bitrate mode of the core, a picture far above its size
+ * target can be encoded again with a higher QP (see v4l2_enc_cbr_reencode()).
+ * Drivers that can run the hardware again for the same picture call it after
+ * the hardware finished it and before v4l2_hevc_enc_complete(). If it returns
+ * true, @enc->qp holds the new QP and the driver encodes the picture again,
+ * with the same size target and the same headers, writing the slice data
+ * from the same offset. Only for hardware that writes the slice header
+ * (V4L2_HEVC_ENC_FLAG_HW_SLICE_HEADER): the slice header of the core holds the
+ * QP of the first pass.
+ *
+ * Return: true if the picture is to be encoded again.
+ */
+bool v4l2_hevc_enc_reencode(struct v4l2_hevc_enc *enc, unsigned int bytesused)
+{
+	struct v4l2_hevc_enc_state *state = &enc->state_active;
+	bool intra = state->encode.slice_type == V4L2_HEVC_SLICE_TYPE_I;
+	int qp_max = intra ? state->qp_max_i : state->qp_max;
+
+	if (!(enc->flags & V4L2_HEVC_ENC_FLAG_HW_SLICE_HEADER) ||
+	    !rc_core_cbr(enc, state))
+		return false;
+
+	if (!v4l2_enc_cbr_reencode(&enc->cbr, (u64)bytesused * 8,
+				   &state->timeperframe, enc->qp,
+				   min(qp_max, 51)))
+		return false;
+
+	enc->qp = rc_clamp_qp(state, v4l2_enc_cbr_qp(&enc->cbr));
+
+	return true;
+}
+EXPORT_SYMBOL_GPL(v4l2_hevc_enc_reencode);
+
 /**
  * v4l2_hevc_enc_complete() - complete the encode run of a picture
  * @enc: the core context
diff --git a/include/media/v4l2-hevc-enc.h b/include/media/v4l2-hevc-enc.h
index f1d3da3269f1..5be449e5ec03 100644
--- a/include/media/v4l2-hevc-enc.h
+++ b/include/media/v4l2-hevc-enc.h
@@ -285,6 +285,8 @@ int v4l2_hevc_enc_init(struct v4l2_hevc_enc *enc);
 void v4l2_hevc_enc_exit(struct v4l2_hevc_enc *enc);
 int v4l2_hevc_enc_step(struct v4l2_hevc_enc *enc,
 		       struct vb2_v4l2_buffer *buffer);
+bool v4l2_hevc_enc_reencode(struct v4l2_hevc_enc *enc,
+			    unsigned int bytesused);
 int v4l2_hevc_enc_complete(struct v4l2_hevc_enc *enc,
 			   struct vb2_v4l2_buffer *buffer,
 			   const struct v4l2_stateless_encode_stats *stats);

-- 
2.55.0

