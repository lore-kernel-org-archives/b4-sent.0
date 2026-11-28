From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:35:53 +0000
Subject: [PATCH v2 2/2] media: cedrus: report only the picture as capture
 payload
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-b4-cedrus-generic-fixes-v2-2-af8472be660b@gmail.com>
References: <20261128-b4-cedrus-generic-fixes-v2-0-af8472be660b@gmail.com>
In-Reply-To: <20261128-b4-cedrus-generic-fixes-v2-0-af8472be660b@gmail.com>
To: Maxime Ripard <mripard@kernel.org>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-staging@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887352; l=1509;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=FP6Lm3fHTfm6zAAHrW3o7Y6Gw9UVBp+bRwgni+SH+6A=;
 b=hopLpEAIwrBwxe2SeBvid6cQFivWi2rGxLd/TsBXBzdyUctPiAdC7cDaAL//p7juLiEsakXNM
 I0PsnauJlxbAzEpsZebUZlOdwA+Y0+T8BZILxmwqodxstcD1dPLusgd
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For 10-bit H.265 the driver appends the low 2 bits of every sample to
the capture buffer and counts them in sizeimage (extra_cap_size).
buf_prepare reports the whole sizeimage as bytesused, so userspace that
copies the payload gets the private plane as part of the picture.

Report only the picture; sizeimage stays the allocation size.

Fixes: 65429ba82572 ("media: cedrus: h265: Support decoding 10-bit frames")
Reviewed-by: Jernej Skrabec <jernej.skrabec@gmail.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/staging/media/sunxi/cedrus/cedrus_video.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_video.c b/drivers/staging/media/sunxi/cedrus/cedrus_video.c
index 9b2d24e77fdb..b7e0cbe548e6 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_video.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_video.c
@@ -511,8 +511,15 @@ static int cedrus_buf_prepare(struct vb2_buffer *vb)
 	 * (for OUTPUT buffers, if userspace passes 0 bytesused, v4l2-core sets
 	 * it to buffer length).
 	 */
-	if (V4L2_TYPE_IS_CAPTURE(vq->type))
-		vb2_set_plane_payload(vb, 0, pix_fmt->sizeimage);
+	if (V4L2_TYPE_IS_CAPTURE(vq->type)) {
+		unsigned int payload = pix_fmt->sizeimage;
+
+		if (ctx->current_codec->extra_cap_size)
+			payload -= ctx->current_codec->extra_cap_size(ctx,
+								     pix_fmt);
+
+		vb2_set_plane_payload(vb, 0, payload);
+	}
 
 	return 0;
 }

-- 
2.55.0

