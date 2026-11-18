From: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
Date: Wed, 18 Nov 2026 10:20:09 -0800
Subject: [PATCH v3] staging: media: imx: ic-prpencvf: add FORMAT_TRY frame
 interval support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-batch1-m2-prpencvf-try-v3-1-9f3ae7b1c6d8@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNTQ7CIBgFr2JYi+GDFFpX3sO44K8Wo20DlNg0v
 btQN90Yl5O8N7OgYL2zAZ0PC/I2ueCGPgM7HpDuZH+32JnMiBLKAYjASkbdAX5RPPrR9jq1OPo
 ZM6ihZlzU3DQon0dvW/fexNfbl8OkHlbHYiuLzoU4+HkrJyi7v5EEGLDgyjRtRSoB5BInNcTTU
 0ZUIonuNPBbQ7PGGMZAKmDAxF6zrusHP+jYFxUBAAA=
X-Change-ID: 20261107-batch1-m2-prpencvf-try-3181836786d9
To: slongerbeam@gmail.com
Cc: linux-staging@lists.linux.dev, error27@gmail.com, 
 p.zabel@pengutronix.de, imx@lists.linux.dev, linux-kernel@vger.kernel.org, 
 mchehab@kernel.org, gregkh@linuxfoundation.org, linux-media@vger.kernel.org, 
 Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=6976; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=ELrkKApt3e08NLg/GQDX2WOQ7c0hwWDn+V8cx4t3NR8=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFl/30z7FrDrwqP6hO+qK559eP3s/se2z0mzGXeWPYrNu
 vNMnon1XEcpC4MYB4OsmCKLmAzP+/r7OnHWVnNOwMxhZQIZwsDFKQAT4W5mZNjdbLNrwZ3dXMuW
 +Ao3HZkgsVo7fYayrVBjQPfxlG/7uucw/K85f1H1ndPMTUUzT6coHyjzevliaeD1PXf3L51j4TV
 vwg9GAA==
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Frame-interval negotiation on the TRY state failed with EINVAL: both
get and set rejected anything but ACTIVE. Setup tools that probe an
interval on the TRY state before committing it got EINVAL and could
not validate frame rates on this subdev.

Store per-pad TRY intervals in the subdev state, following the same
pattern the driver already uses for TRY formats: ACTIVE intervals stay
in priv->frame_interval while TRY intervals live in the subdev state.
Add a PRPENCVF-specific init_state callback to initialize TRY
intervals from the active default, and move default interval
initialization to prp_init(), which runs before any state can be
initialized. The IC does not alter frame rate between pads, so setting
a TRY interval on either pad updates both pads' TRY slots.

Signed-off-by: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
---
Compile-tested only: x86_64, VIDEO_IMX_MEDIA=m via COMPILE_TEST, zero
warnings. No i.MX hardware here for runtime testing; hardware testing
by others is welcome.
---
Changes in v3:
- Rewrite the commit message to state the user-visible effect (Dan Carpenter).
- Keep both TRY slots in sync when setting on either pad, so sink/source TRY intervals cannot diverge (Sashiko review).
- Link to v2: https://patch.msgid.link/20261117-batch1-m2-prpencvf-try-v2-1-dd331ab13137@tubot.lat

Changes in v2:
- Propagate TRY intervals from sink to source pad in prp_set_frame_interval(), mirroring prp_set_fmt() (spotted by Sashiko review; apologies for the oversight).
- Resend under my real name (From/Signed-off-by: Maximo Manriquez Lizarraga).
- Link to v1: https://patch.msgid.link/20261107-batch1-m2-prpencvf-try-v1-1-76bd9f505710@tubot.lat
---
 drivers/staging/media/imx/imx-ic-prpencvf.c | 110 +++++++++++++++++++++-------
 1 file changed, 85 insertions(+), 25 deletions(-)

diff --git a/drivers/staging/media/imx/imx-ic-prpencvf.c b/drivers/staging/media/imx/imx-ic-prpencvf.c
index 3430ddeac356..50d81c711c35 100644
--- a/drivers/staging/media/imx/imx-ic-prpencvf.c
+++ b/drivers/staging/media/imx/imx-ic-prpencvf.c
@@ -795,6 +795,18 @@ __prp_get_fmt(struct prp_priv *priv, struct v4l2_subdev_state *sd_state,
 		return &priv->format_mbus[pad];
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
  * Applies IC resizer and IDMAC alignment restrictions to output
  * rectangle given the input rectangle, and depending on given
@@ -1208,22 +1220,25 @@ static int prp_get_frame_interval(struct v4l2_subdev *sd,
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
 
 	if (fi->pad >= PRPENCVF_NUM_PADS)
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
@@ -1231,24 +1246,69 @@ static int prp_set_frame_interval(struct v4l2_subdev *sd,
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
 
 	if (fi->pad >= PRPENCVF_NUM_PADS)
 		return -EINVAL;
 
 	mutex_lock(&priv->lock);
+	interval = __prp_get_frame_interval(priv, sd_state, fi->pad,
+					    fi->which);
+	if (!interval) {
+		ret = -EINVAL;
+		goto out;
+	}
 
 	/* No limits on valid frame intervals */
-	if (fi->interval.numerator == 0 || fi->interval.denominator == 0)
-		fi->interval = priv->frame_interval;
-	else
-		priv->frame_interval = fi->interval;
+	if (fi->interval.numerator == 0 || fi->interval.denominator == 0) {
+		fi->interval = *interval;
+	} else {
+		*interval = fi->interval;
+
+		/*
+		 * The IC task does not change the frame rate between sink
+		 * and source, so keep both TRY slots in sync the same way
+		 * prp_set_fmt() propagates formats between pads.
+		 * (ACTIVE uses a single shared interval and needs nothing.)
+		 */
+		if (fi->which == V4L2_SUBDEV_FORMAT_TRY) {
+			unsigned int other = fi->pad == PRPENCVF_SINK_PAD ?
+				PRPENCVF_SRC_PAD : PRPENCVF_SINK_PAD;
+			struct v4l2_fract *other_interval;
+
+			other_interval = __prp_get_frame_interval(priv, sd_state,
+								  other,
+								  fi->which);
+			if (other_interval)
+				*other_interval = fi->interval;
+		}
+	}
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
+	for (pad = 0; pad < PRPENCVF_NUM_PADS; pad++) {
+		interval = v4l2_subdev_state_get_interval(sd_state, pad);
+		if (interval)
+			*interval = priv->frame_interval;
+	}
 
 	mutex_unlock(&priv->lock);
 
@@ -1274,10 +1334,6 @@ static int prp_registered(struct v4l2_subdev *sd)
 			return ret;
 	}
 
-	/* init default frame interval */
-	priv->frame_interval.numerator = 1;
-	priv->frame_interval.denominator = 30;
-
 	priv->vdev = imx_media_capture_device_init(ic_priv->ipu_dev,
 						   &ic_priv->sd,
 						   PRPENCVF_SRC_PAD, true);
@@ -1335,7 +1391,7 @@ static const struct v4l2_subdev_ops prp_subdev_ops = {
 };
 
 static const struct v4l2_subdev_internal_ops prp_internal_ops = {
-	.init_state = imx_media_init_state,
+	.init_state = prp_init_state,
 	.registered = prp_registered,
 	.unregistered = prp_unregistered,
 };
@@ -1352,6 +1408,10 @@ static int prp_init(struct imx_ic_priv *ic_priv)
 	ic_priv->task_priv = priv;
 	priv->ic_priv = ic_priv;
 
+	/* init default frame interval */
+	priv->frame_interval.numerator = 1;
+	priv->frame_interval.denominator = 30;
+
 	spin_lock_init(&priv->irqlock);
 	timer_setup(&priv->eof_timeout_timer, prp_eof_timeout, 0);
 

---
base-commit: fa4ad798f6f681031775266044ba1b0cf3c670bd
change-id: 20261107-batch1-m2-prpencvf-try-3181836786d9

Best regards,
--  
Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>

