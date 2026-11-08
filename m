From: DelaySystem <DelaySystem@tubot.lat>
Date: Sat, 07 Nov 2026 18:47:00 -0800
Subject: [PATCH] media: staging: tegra-video: csi: use active state for
 frame interval
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-staging-csi-interval-v1-1-4860ac021065@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDtgQo3VqxQXMU7TKRIlk4og3
 t2oy7f4fwOhyCTQFhtEWlh4ChnqUYD72uAJecgGXWqjVFmjJOs5eHTCyCFRXOyIjal19ewb44Y
 X5HSO9OH12r672/Lvf+TS+YJ9PwCILw1reAAAAA==
X-Change-ID: 20261107-staging-csi-interval-967254b96cd8
To: luca.ceresoli@bootlin.com, gregkh@linuxfoundation.org, 
 thierry.reding@kernel.org, skomatineni@nvidia.com, mchehab@kernel.org, 
 jonathanh@nvidia.com
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-tegra@vger.kernel.org, 
 DelaySystem <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7208; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=RFWR0QKV3z3LtnLnQBGjQGyiW1c3/1+A78zjLwzdzP8=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFnvHy2x/CDdoV5ypyZpyY8UJ5EawcRpNpc3Fc/bKZdis
 UrdksOgo5SFQYyDQVZMkUVMhud9/X2dOGurOSdg5rAygQxh4OIUgImUuTIyPJ//pfI+89ODqx4u
 31aZVZORPuPOs0X3pK+3FebrrL+/q4aR4fgm51j9gq9+nM/FSuWaTZxvbIhqXVLQVm/wf5XN91I
 jNgA=
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert tegra_csi_{get,set}_frame_interval to the V4L2 subdev active
state API, resolving the FIXME asking for TRY format support via the
active state.

The interval now lives in the per-pad subdev state instead of the
driver-private csi_chan->framerate field:
- add csi_init_state() to seed each pad's interval from the TPG
  framerate table at the channel's current format,
- initialize the state with v4l2_subdev_init_finalize() in channel
  probe and release it with v4l2_subdev_cleanup() on teardown,
- re-sync the interval in csi_set_format() when the format changes,
  matching the previous behavior where the format path refreshed the
  stored framerate,
- validate the pad index against the entity's num_pads in both the
  get and set paths.

With the state handling both ACTIVE and TRY buffers, the TRY path now
works instead of returning -EINVAL, and the .set_frame_interval op
(which wrongly pointed at the get helper) is fixed to the new set
helper.

Non-TPG builds keep returning -ENOIOCTLCMD as before.

Signed-off-by: DelaySystem <DelaySystem@tubot.lat>
---
 drivers/staging/media/tegra-video/csi.c | 80 ++++++++++++++++++++++++++++-----
 drivers/staging/media/tegra-video/csi.h |  2 -
 2 files changed, 70 insertions(+), 12 deletions(-)

diff --git a/drivers/staging/media/tegra-video/csi.c b/drivers/staging/media/tegra-video/csi.c
index 5a5fca378ae6..629b543c76c1 100644
--- a/drivers/staging/media/tegra-video/csi.c
+++ b/drivers/staging/media/tegra-video/csi.c
@@ -111,7 +111,6 @@ static void csi_chan_update_blank_intervals(struct tegra_csi_channel *csi_chan,
 	if (index >= 0) {
 		csi_chan->h_blank = frmrate[index].h_blank;
 		csi_chan->v_blank = frmrate[index].v_blank;
-		csi_chan->framerate = frmrate[index].framerate;
 	}
 }
 
@@ -178,6 +177,9 @@ static int csi_set_format(struct v4l2_subdev *subdev,
 	struct v4l2_mbus_framefmt *format = &fmt->format;
 	const struct v4l2_frmsize_discrete *sizes;
 	unsigned int i;
+	const struct tpg_framerate *frmrate;
+	struct v4l2_fract *interval;
+	int index;
 
 	if (!IS_ENABLED(CONFIG_VIDEO_TEGRA_TPG))
 		return -ENOIOCTLCMD;
@@ -199,6 +201,16 @@ static int csi_set_format(struct v4l2_subdev *subdev,
 	format->code = tegra_csi_tpg_fmts[i].code;
 	format->field = V4L2_FIELD_NONE;
 
+	/* keep the frame interval in sync with the format */
+	frmrate = csi_chan->csi->soc->tpg_frmrate_table;
+	index = csi_get_frmrate_table_index(csi_chan->csi, format->code,
+					    format->width, format->height);
+	if (index >= 0) {
+		interval = v4l2_subdev_state_get_interval(sd_state, fmt->pad);
+		interval->numerator = 1;
+		interval->denominator = frmrate[index].framerate;
+	}
+
 	if (fmt->which == V4L2_SUBDEV_FORMAT_TRY)
 		return 0;
 
@@ -217,20 +229,53 @@ static int tegra_csi_get_frame_interval(struct v4l2_subdev *subdev,
 					struct v4l2_subdev_state *sd_state,
 					struct v4l2_subdev_frame_interval *vfi)
 {
-	struct tegra_csi_channel *csi_chan = to_csi_chan(subdev);
+	if (!IS_ENABLED(CONFIG_VIDEO_TEGRA_TPG))
+		return -ENOIOCTLCMD;
+
+	if (vfi->pad >= subdev->entity.num_pads)
+		return -EINVAL;
 
+	vfi->interval = *v4l2_subdev_state_get_interval(sd_state, vfi->pad);
+
+	return 0;
+}
+
+static int tegra_csi_set_frame_interval(struct v4l2_subdev *subdev,
+					struct v4l2_subdev_state *sd_state,
+					struct v4l2_subdev_frame_interval *vfi)
+{
 	if (!IS_ENABLED(CONFIG_VIDEO_TEGRA_TPG))
 		return -ENOIOCTLCMD;
 
-	/*
-	 * FIXME: Implement support for V4L2_SUBDEV_FORMAT_TRY, using the V4L2
-	 * subdev active state API.
-	 */
-	if (vfi->which != V4L2_SUBDEV_FORMAT_ACTIVE)
+	if (vfi->pad >= subdev->entity.num_pads)
 		return -EINVAL;
 
-	vfi->interval.numerator = 1;
-	vfi->interval.denominator = csi_chan->framerate;
+	*v4l2_subdev_state_get_interval(sd_state, vfi->pad) = vfi->interval;
+
+	return 0;
+}
+
+static int csi_init_state(struct v4l2_subdev *sd,
+			  struct v4l2_subdev_state *state)
+{
+	struct tegra_csi_channel *csi_chan = to_csi_chan(sd);
+	const struct tpg_framerate *frmrate;
+	struct v4l2_fract *interval;
+	unsigned int i;
+	int index;
+
+	frmrate = csi_chan->csi->soc->tpg_frmrate_table;
+	index = csi_get_frmrate_table_index(csi_chan->csi,
+					    csi_chan->format.code,
+					    csi_chan->format.width,
+					    csi_chan->format.height);
+
+	for (i = 0; i < sd->entity.num_pads; i++) {
+		interval = v4l2_subdev_state_get_interval(state, i);
+		interval->numerator = 1;
+		interval->denominator =
+			index >= 0 ? frmrate[index].framerate : 0;
+	}
 
 	return 0;
 }
@@ -438,7 +483,7 @@ static const struct v4l2_subdev_pad_ops tegra_csi_pad_ops = {
 	.get_fmt		= csi_get_format,
 	.set_fmt		= csi_set_format,
 	.get_frame_interval	= tegra_csi_get_frame_interval,
-	.set_frame_interval	= tegra_csi_get_frame_interval,
+	.set_frame_interval	= tegra_csi_set_frame_interval,
 };
 
 static const struct v4l2_subdev_ops tegra_csi_ops = {
@@ -446,6 +491,10 @@ static const struct v4l2_subdev_ops tegra_csi_ops = {
 	.pad    = &tegra_csi_pad_ops,
 };
 
+static const struct v4l2_subdev_internal_ops tegra_csi_internal_ops = {
+	.init_state = csi_init_state,
+};
+
 struct v4l2_subdev *tegra_channel_get_remote_csi_subdev(struct tegra_vi_channel *chan)
 {
 	struct media_pad *pad;
@@ -642,6 +691,16 @@ static int tegra_csi_channel_init(struct tegra_csi_channel *chan)
 		return ret;
 	}
 
+	subdev->internal_ops = &tegra_csi_internal_ops;
+	ret = v4l2_subdev_init_finalize(subdev);
+	if (ret < 0) {
+		dev_err(csi->dev,
+			"failed to initialize subdev state: %d\n", ret);
+		media_entity_cleanup(&subdev->entity);
+		subdev->dev = NULL;
+		return ret;
+	}
+
 	if (!IS_ENABLED(CONFIG_VIDEO_TEGRA_TPG)) {
 		ret = v4l2_async_register_subdev(subdev);
 		if (ret < 0) {
@@ -696,6 +755,7 @@ static void tegra_csi_channels_cleanup(struct tegra_csi *csi)
 		if (subdev->dev) {
 			if (!IS_ENABLED(CONFIG_VIDEO_TEGRA_TPG))
 				v4l2_async_unregister_subdev(subdev);
+			v4l2_subdev_cleanup(subdev);
 			media_entity_cleanup(&subdev->entity);
 		}
 
diff --git a/drivers/staging/media/tegra-video/csi.h b/drivers/staging/media/tegra-video/csi.h
index f0277cb42446..25aff2581f06 100644
--- a/drivers/staging/media/tegra-video/csi.h
+++ b/drivers/staging/media/tegra-video/csi.h
@@ -53,7 +53,6 @@ struct tegra_csi;
  * @csi_port_nums: CSI channel port numbers
  * @pg_mode: test pattern generator mode for channel
  * @format: active format of the channel
- * @framerate: active framerate for TPG
  * @h_blank: horizontal blanking for TPG active format
  * @v_blank: vertical blanking for TPG active format
  * @mipi: mipi device for corresponding csi channel pads, or NULL if not applicable (TPG, error)
@@ -71,7 +70,6 @@ struct tegra_csi_channel {
 	u8 csi_port_nums[GANG_PORTS_MAX];
 	u8 pg_mode;
 	struct v4l2_mbus_framefmt format;
-	unsigned int framerate;
 	unsigned int h_blank;
 	unsigned int v_blank;
 	struct tegra_mipi_device *mipi;

---
base-commit: a41e364995bbcfa627418a70fe913c35b7510728
change-id: 20261107-staging-csi-interval-967254b96cd8

Best regards,
--  
DelaySystem <DelaySystem@tubot.lat>

