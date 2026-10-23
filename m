From: Max Bretschneider <max.bretschneider@leica-geosystems.com>
Date: Sat, 24 Oct 2026 00:28:53 +0200
Subject: [PATCH v2 3/4] media: i2c: ov08d10: drop the cached current mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-ov08d10-get-selection-v2-3-f8c49972ca18@leica-geosystems.com>
References: <20261024-ov08d10-get-selection-v2-0-f8c49972ca18@leica-geosystems.com>
In-Reply-To: <20261024-ov08d10-get-selection-v2-0-f8c49972ca18@leica-geosystems.com>
To: Jimmy Su <jimmy.su@intel.com>, Matthias Fend <matthias.fend@emfend.at>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Max Bretschneider <max.bretschneider@leica-geosystems.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792794706; l=6552;
 i=max.bretschneider@leica-geosystems.com; s=20260501;
 h=from:subject:message-id; bh=d21sqW2s1rBsQYTJVFlGkOJYCmj7ODQmfprQSCaciQ4=;
 b=Mp+82zE6mOSCcphVHcyC0PElpSN4lmZamxKfLSqH7U98syrL9bNVBhTZupw7cK4ahtckSvuxx
 XV//LhnmyHUD4gH6nWqrlkCSfS5SP/tNhBgIk/67kUbNQ4lQtDSWyYI
X-Developer-Key: i=max.bretschneider@leica-geosystems.com; a=ed25519;
 pk=jf4ba33jrWlsOdGemi2InMtJAngoJVZU8Moetp0ixik=
X-Endpoint-Received: by B4 Relay for max.bretschneider@leica-geosystems.com/20260501 with auth_id=1161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With the subdev active state in place, the selected mode is fully
determined by the format stored in the state, so the cached cur_mode
pointer duplicates information that is already held authoritatively
elsewhere. Add a small helper that recovers the mode from the state and
use it where the mode is needed, as imx214 and imx355 do.

ov08d10_init_controls() runs before v4l2_subdev_init_finalize() has
created the active state, so it refers to the first mode directly
instead.

Signed-off-by: Max Bretschneider <max.bretschneider@leica-geosystems.com>
---
 drivers/media/i2c/ov08d10.c | 49 ++++++++++++++++++++++++++-------------------
 1 file changed, 28 insertions(+), 21 deletions(-)

diff --git a/drivers/media/i2c/ov08d10.c b/drivers/media/i2c/ov08d10.c
index f19c056608ea..4b503ddfa042 100644
--- a/drivers/media/i2c/ov08d10.c
+++ b/drivers/media/i2c/ov08d10.c
@@ -568,9 +568,6 @@ struct ov08d10 {
 	struct v4l2_ctrl *hflip;
 	struct v4l2_ctrl *exposure;
 
-	/* Current mode */
-	const struct ov08d10_mode *cur_mode;
-
 	/* lanes index */
 	u8 nlanes;
 
@@ -679,6 +676,19 @@ static unsigned int ov08d10_modes_num(const struct ov08d10 *ov08d10)
 	return count;
 }
 
+/* Must be called with the subdev state lock held */
+static const struct ov08d10_mode *ov08d10_get_mode(struct ov08d10 *ov08d10)
+{
+	struct v4l2_subdev_state *state =
+		v4l2_subdev_get_locked_active_state(&ov08d10->sd);
+	const struct v4l2_mbus_framefmt *fmt =
+		v4l2_subdev_state_get_format(state, 0);
+
+	return v4l2_find_nearest_size(ov08d10->priv_lane->sp_modes,
+				      ov08d10->modes_size, width, height,
+				      fmt->width, fmt->height);
+}
+
 static u64 to_rate(const s64 *link_freq_menu,
 		   u32 f_index, u8 nlanes)
 {
@@ -776,7 +786,7 @@ static int ov08d10_set_exposure(struct ov08d10 *ov08d10, u32 exposure)
 	u32 hts, cur_vts, exp_cal;
 	int ret;
 
-	cur_vts = ov08d10->cur_mode->vts_def;
+	cur_vts = ov08d10_get_mode(ov08d10)->vts_def;
 	ret = i2c_smbus_write_byte_data(client, OV08D10_REG_PAGE, 0x01);
 	if (ret < 0)
 		return ret;
@@ -896,13 +906,17 @@ static int ov08d10_set_ctrl(struct v4l2_ctrl *ctrl)
 {
 	struct ov08d10 *ov08d10 = container_of(ctrl->handler,
 					     struct ov08d10, ctrl_handler);
+	struct v4l2_subdev_state *state =
+		v4l2_subdev_get_locked_active_state(&ov08d10->sd);
+	struct v4l2_mbus_framefmt *fmt =
+		v4l2_subdev_state_get_format(state, 0);
 	s64 exposure_max;
 	int ret;
 
 	/* Propagate change of current control to all related controls */
 	if (ctrl->id == V4L2_CID_VBLANK) {
 		/* Update max exposure while meeting expected vblanking */
-		exposure_max = ov08d10->cur_mode->height + ctrl->val -
+		exposure_max = fmt->height + ctrl->val -
 			       OV08D10_EXPOSURE_MAX_MARGIN;
 		__v4l2_ctrl_modify_range(ov08d10->exposure,
 					 ov08d10->exposure->minimum,
@@ -911,13 +925,8 @@ static int ov08d10_set_ctrl(struct v4l2_ctrl *ctrl)
 	}
 
 	/* The flips change the Bayer order, refresh it even while powered off */
-	if (ctrl->id == V4L2_CID_HFLIP || ctrl->id == V4L2_CID_VFLIP) {
-		struct v4l2_subdev_state *state =
-			v4l2_subdev_get_locked_active_state(&ov08d10->sd);
-
-		v4l2_subdev_state_get_format(state, 0)->code =
-			ov08d10_get_format_code(ov08d10);
-	}
+	if (ctrl->id == V4L2_CID_HFLIP || ctrl->id == V4L2_CID_VFLIP)
+		fmt->code = ov08d10_get_format_code(ov08d10);
 
 	/* V4L2 control values will be applied only when power is already up */
 	if (!pm_runtime_get_if_in_use(ov08d10->dev))
@@ -974,7 +983,7 @@ static int ov08d10_init_controls(struct ov08d10 *ov08d10)
 	s64 vblank_min;
 	s64 h_blank;
 	s64 pixel_rate_max;
-	const struct ov08d10_mode *mode;
+	const struct ov08d10_mode *mode = &ov08d10->priv_lane->sp_modes[0];
 	int ret;
 
 	ctrl_hdlr = &ov08d10->ctrl_handler;
@@ -993,13 +1002,12 @@ static int ov08d10_init_controls(struct ov08d10 *ov08d10)
 		ov08d10->link_freq->flags |= V4L2_CTRL_FLAG_READ_ONLY;
 
 	pixel_rate_max = to_rate(ov08d10->priv_lane->link_freq_menu, 0,
-				 ov08d10->cur_mode->data_lanes);
+				 mode->data_lanes);
 	ov08d10->pixel_rate =
 		v4l2_ctrl_new_std(ctrl_hdlr, &ov08d10_ctrl_ops,
 				  V4L2_CID_PIXEL_RATE, 0, pixel_rate_max, 1,
 				  pixel_rate_max);
 
-	mode = ov08d10->cur_mode;
 	vblank_def = mode->vts_def - mode->height;
 	vblank_min = mode->vts_min - mode->height;
 	ov08d10->vblank =
@@ -1069,10 +1077,11 @@ static void ov08d10_update_pad_format(struct ov08d10 *ov08d10,
 static int ov08d10_start_streaming(struct ov08d10 *ov08d10)
 {
 	struct i2c_client *client = v4l2_get_subdevdata(&ov08d10->sd);
+	const struct ov08d10_mode *mode = ov08d10_get_mode(ov08d10);
 	const struct ov08d10_reg_list *reg_list;
 	int link_freq_index, ret;
 
-	link_freq_index = ov08d10->cur_mode->link_freq_index;
+	link_freq_index = mode->link_freq_index;
 	reg_list =
 		&ov08d10->priv_lane->link_freq_configs[link_freq_index]
 			 .reg_list[ov08d10->xvclk_index];
@@ -1102,7 +1111,7 @@ static int ov08d10_start_streaming(struct ov08d10 *ov08d10)
 		return ret;
 	}
 
-	reg_list = &ov08d10->cur_mode->reg_list;
+	reg_list = &mode->reg_list;
 	ret = ov08d10_write_reg_list(ov08d10, reg_list);
 	if (ret) {
 		dev_err(ov08d10->dev, "failed to set mode\n");
@@ -1202,11 +1211,10 @@ static int ov08d10_set_format(struct v4l2_subdev *sd,
 	*v4l2_subdev_state_get_format(sd_state, fmt->pad) = fmt->format;
 
 	if (fmt->which == V4L2_SUBDEV_FORMAT_ACTIVE) {
-		ov08d10->cur_mode = mode;
 		__v4l2_ctrl_s_ctrl(ov08d10->link_freq, mode->link_freq_index);
 		pixel_rate = to_rate(ov08d10->priv_lane->link_freq_menu,
 				     mode->link_freq_index,
-				     ov08d10->cur_mode->data_lanes);
+				     mode->data_lanes);
 		__v4l2_ctrl_s_ctrl_int64(ov08d10->pixel_rate, pixel_rate);
 
 		/* Update limits and set FPS to default */
@@ -1219,7 +1227,7 @@ static int ov08d10_set_format(struct v4l2_subdev *sd,
 		h_blank = to_pixels_per_line(ov08d10->priv_lane->link_freq_menu,
 					     mode->hts,
 					     mode->link_freq_index,
-					     ov08d10->cur_mode->data_lanes)
+					     mode->data_lanes)
 					     - mode->width;
 		__v4l2_ctrl_modify_range(ov08d10->hblank, h_blank, h_blank, 1,
 					 h_blank);
@@ -1521,7 +1529,6 @@ static int ov08d10_probe(struct i2c_client *client)
 		goto probe_error_power_off;
 	}
 
-	ov08d10->cur_mode = &ov08d10->priv_lane->sp_modes[0];
 	ret = ov08d10_init_controls(ov08d10);
 	if (ret) {
 		dev_err(ov08d10->dev, "failed to init controls: %d\n", ret);

-- 
2.43.0

