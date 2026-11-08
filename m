From: DelaySystem <DelaySystem@tubot.lat>
Date: Sat, 07 Nov 2026 21:16:11 -0800
Subject: [PATCH] staging: media: imx: ic-prp: add FORMAT_TRY frame interval
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-batch1-m1-prp-try-v1-1-56a08f54791b@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMAyA4VchPdukRYTEVzEetlGlJOLSDYIhv
 DtTj9/h/zdIYioJrtUGJosmfU8FfKogDG56CmpfDDXVLTN16F0OA+OLMVrEbB88d+ToQuKb3kP
 poslD19/zdv87zX6UkL8j2PcDkrMvbnUAAAA=
X-Change-ID: 20261107-batch1-m1-prp-try-370a050eb4db
To: slongerbeam@gmail.com
Cc: linux-kernel@vger.kernel.org, gregkh@linuxfoundation.org, 
 vickramk.207@gmail.com, linux-staging@lists.linux.dev, 
 linux-media@vger.kernel.org, mchehab@kernel.org, imx@lists.linux.dev, 
 p.zabel@pengutronix.de, DelaySystem <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5034; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=WVwUtRUjTKbxdRiEtnEo30aSNjX2ZGooES481TnxQgg=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFkfWGd9fOqwyWtq5BOrH5nv1DU/vb/7omYJ/+TszM3r1
 mhZaXyX7ChlYRDjYJAVU2QRk+F5X39fJ87aas4JmDmsTCBDGLg4BWAij14yMmwO4DdmCFppdeZt
 3zWtkF+P/rv9OcNbaPl0Z+PTJUlKn34w/A94EjT/0BobpxkrN/Y+8Res3C9p1r7QOz2Rs/fG+YV
 1N5gB
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vickram Kapoor <vickramk.207@gmail.com>

Implement frame interval handling for V4L2_SUBDEV_FORMAT_TRY
by storing and retrieving per-pad intervals from the subdev state.
Also add a PRP-specific init_state callback to initialize TRY intervals
from the active default, and move default interval initialization to
prp_init().

Link: https://lore.kernel.org/all/20260426002659.119625-1-vickramk.207@gmail.com/
Signed-off-by: Vickram Kapoor <vickramk.207@gmail.com>
Signed-off-by: DelaySystem <DelaySystem@tubot.lat>
---
Compile-tested only: x86_64, VIDEO_IMX_MEDIA=m via COMPILE_TEST, zero
warnings. No i.MX hardware here for runtime testing; hardware testing
by others is welcome.
---
 drivers/staging/media/imx/imx-ic-prp.c | 87 +++++++++++++++++++++++++---------
 1 file changed, 64 insertions(+), 23 deletions(-)

diff --git a/drivers/staging/media/imx/imx-ic-prp.c b/drivers/staging/media/imx/imx-ic-prp.c
index b2c648149964..3f1690d22483 100644
--- a/drivers/staging/media/imx/imx-ic-prp.c
+++ b/drivers/staging/media/imx/imx-ic-prp.c
@@ -87,6 +87,18 @@ __prp_get_fmt(struct prp_priv *priv, struct v4l2_subdev_state *sd_state,
 		return &priv->format_mbus;
 }
 
+static struct v4l2_fract *
+__prp_get_frame_interval(struct prp_priv *priv,
+			 struct v4l2_subdev_state *sd_state,
+			 unsigned int pad,
+			 enum v4l2_subdev_format_whence which)
+{
+	if (which == V4L2_SUBDEV_FORMAT_TRY)
+		return v4l2_subdev_state_get_interval(sd_state, pad);
+
+	return &priv->frame_interval;
+}
+
 /*
  * V4L2 subdev operations.
  */
@@ -398,22 +410,25 @@ static int prp_get_frame_interval(struct v4l2_subdev *sd,
 				  struct v4l2_subdev_frame_interval *fi)
 {
 	struct prp_priv *priv = sd_to_priv(sd);
-
-	/*
-	 * FIXME: Implement support for V4L2_SUBDEV_FORMAT_TRY, using the V4L2
-	 * subdev active state API.
-	 */
-	if (fi->which != V4L2_SUBDEV_FORMAT_ACTIVE)
-		return -EINVAL;
+	struct v4l2_fract *interval;
+	int ret = 0;
 
 	if (fi->pad >= PRP_NUM_PADS)
 		return -EINVAL;
 
 	mutex_lock(&priv->lock);
-	fi->interval = priv->frame_interval;
+	interval = __prp_get_frame_interval(priv, sd_state, fi->pad,
+					    fi->which);
+	if (!interval) {
+		ret = -EINVAL;
+		goto out;
+	}
+
+	fi->interval = *interval;
+out:
 	mutex_unlock(&priv->lock);
 
-	return 0;
+	return ret;
 }
 
 static int prp_set_frame_interval(struct v4l2_subdev *sd,
@@ -421,24 +436,50 @@ static int prp_set_frame_interval(struct v4l2_subdev *sd,
 				  struct v4l2_subdev_frame_interval *fi)
 {
 	struct prp_priv *priv = sd_to_priv(sd);
-
-	/*
-	 * FIXME: Implement support for V4L2_SUBDEV_FORMAT_TRY, using the V4L2
-	 * subdev active state API.
-	 */
-	if (fi->which != V4L2_SUBDEV_FORMAT_ACTIVE)
-		return -EINVAL;
+	struct v4l2_fract *interval;
+	int ret = 0;
 
 	if (fi->pad >= PRP_NUM_PADS)
 		return -EINVAL;
 
 	mutex_lock(&priv->lock);
+	interval = __prp_get_frame_interval(priv, sd_state, fi->pad,
+					    fi->which);
+	if (!interval) {
+		ret = -EINVAL;
+		goto out;
+	}
 
 	/* No limits on valid frame intervals */
 	if (fi->interval.numerator == 0 || fi->interval.denominator == 0)
-		fi->interval = priv->frame_interval;
+		fi->interval = *interval;
 	else
-		priv->frame_interval = fi->interval;
+		*interval = fi->interval;
+out:
+	mutex_unlock(&priv->lock);
+
+	return ret;
+}
+
+static int prp_init_state(struct v4l2_subdev *sd,
+			  struct v4l2_subdev_state *sd_state)
+{
+	struct prp_priv *priv = sd_to_priv(sd);
+	struct v4l2_fract *interval;
+	unsigned int pad;
+	int ret;
+
+	ret = imx_media_init_state(sd, sd_state);
+	if (ret)
+		return ret;
+
+	mutex_lock(&priv->lock);
+
+	for (pad = 0; pad < PRP_NUM_PADS; pad++) {
+		interval = v4l2_subdev_state_get_interval(sd_state, pad);
+		if (interval)
+			*interval = priv->frame_interval;
+	}
 
 	mutex_unlock(&priv->lock);
 
@@ -450,10 +491,6 @@ static int prp_registered(struct v4l2_subdev *sd)
 	struct prp_priv *priv = sd_to_priv(sd);
 	u32 code;
 
-	/* init default frame interval */
-	priv->frame_interval.numerator = 1;
-	priv->frame_interval.denominator = 30;
-
 	/* set a default mbus format  */
 	imx_media_enum_ipu_formats(&code, 0, PIXFMT_SEL_YUV);
 
@@ -487,7 +524,7 @@ static const struct v4l2_subdev_ops prp_subdev_ops = {
 };
 
 static const struct v4l2_subdev_internal_ops prp_internal_ops = {
-	.init_state = imx_media_init_state,
+	.init_state = prp_init_state,
 	.registered = prp_registered,
 };
 
@@ -504,6 +541,10 @@ static int prp_init(struct imx_ic_priv *ic_priv)
 	ic_priv->task_priv = priv;
 	priv->ic_priv = ic_priv;
 
+	/* init default frame interval */
+	priv->frame_interval.numerator = 1;
+	priv->frame_interval.denominator = 30;
+
 	for (i = 0; i < PRP_NUM_PADS; i++)
 		priv->pad[i].flags = (i == PRP_SINK_PAD) ?
 			MEDIA_PAD_FL_SINK : MEDIA_PAD_FL_SOURCE;

---
base-commit: fa4ad798f6f681031775266044ba1b0cf3c670bd
change-id: 20261107-batch1-m1-prp-try-370a050eb4db

Best regards,
--  
DelaySystem <DelaySystem@tubot.lat>

