From: Max Bretschneider <max.bretschneider@leica-geosystems.com>
Date: Sun, 11 Oct 2026 21:55:23 +0200
Subject: [PATCH] media: i2c: ov08d10: add get_selection support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-ov08d10-get-selection-v1-1-5debe6436765@leica-geosystems.com>
X-B4-Tracking: v=1; b=H4sIAKrpy2oC/x3MSwqAIBRG4a3EHXfBHPTaSjQw/bULUaERQbj3p
 OEZfOelhChINFYvRdyS5NhLNHVFdjV7AIsrTVrpVg164ONWvWsUB1ycsMFeRbA1pltau/TOg4o
 9I7w8/3eac/4AdWH36mcAAAA=
To: Jimmy Su <jimmy.su@intel.com>, Matthias Fend <matthias.fend@emfend.at>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Max Bretschneider <max.bretschneider@leica-geosystems.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791748532; l=7199;
 i=max.bretschneider@leica-geosystems.com; s=20260501;
 h=from:subject:message-id; bh=E3xQubIkPTvx2wL9DZkujO+3/+i9lmKaF0B4AxGybZA=;
 b=9vswjrUEaoOtfN9mkxB9X5vc4a/hINTznbcg04kikaRCSeBHpfyUAEQdDzCBEEGd5wAhfhfQy
 n7h2otlC6lPB7pUyUU9y8k2A6b1PpcCIgbHui3JhL6cxkzm+jzlbaRZ
X-Developer-Key: i=max.bretschneider@leica-geosystems.com; a=ed25519;
 pk=jf4ba33jrWlsOdGemi2InMtJAngoJVZU8Moetp0ixik=
X-Endpoint-Received: by B4 Relay for max.bretschneider@leica-geosystems.com/20260501 with auth_id=1161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver does not implement .get_selection, so it never reports the
analogue crop rectangle of the active mode. Userspace has no way to
learn which region of the pixel array a given mode reads out, and
cannot assume a fixed one, because the modes differ: the full mode
reads 3280x2460 at offset (4,8), while the 3264x2448 and the 2x2
binned 1632x1224 modes read 3264x2448 at offset (12,16).

Consumers that derive the sensor scale from the analogue crop and the
output size therefore compute a wrong result for the cropped and
binned modes, and may reject those configurations.

Track the analogue crop rectangle per mode, store it in the subdev
state when the format is set, and report it through .get_selection.
Also report V4L2_SEL_TGT_CROP_DEFAULT, V4L2_SEL_TGT_CROP_BOUNDS and
V4L2_SEL_TGT_NATIVE_SIZE from the pixel array geometry. Implement
.init_state so a newly allocated state holds a valid format and crop,
and add the v4l2_subdev_init_finalize() and v4l2_subdev_cleanup()
calls required to use the subdev active state.

The pixel array geometry and the per-mode offsets are taken from the
sensor datasheet and the recommended reference register sets.

Signed-off-by: Max Bretschneider <max.bretschneider@leica-geosystems.com>
---
Tested on a Hexagon/Leica CS50 (i.MX8MP, rkisp1) running 6.16.12 with the
equivalent of this patch applied, where it fixes configuration of the 2x2
binned 1632x1224 mode with libcamera's rkisp1 CAC algorithm enabled.
Compile-tested against media/next.

Modelled on imx335.
---
 drivers/media/i2c/ov08d10.c | 74 ++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 73 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov08d10.c b/drivers/media/i2c/ov08d10.c
index 0710d2243cc0..b32a1246df45 100644
--- a/drivers/media/i2c/ov08d10.c
+++ b/drivers/media/i2c/ov08d10.c
@@ -65,6 +65,14 @@
 #define OV08D10_REG_FLIP_OPT			0x32
 #define OV08D10_REG_FLIP_MASK			0x3
 
+/* OV08D10 native and active pixel array size */
+#define OV08D10_NATIVE_WIDTH			3288
+#define OV08D10_NATIVE_HEIGHT			2476
+#define OV08D10_PIXEL_ARRAY_LEFT		4
+#define OV08D10_PIXEL_ARRAY_TOP			8
+#define OV08D10_PIXEL_ARRAY_WIDTH		3280
+#define OV08D10_PIXEL_ARRAY_HEIGHT		2464
+
 #define to_ov08d10(_sd)		container_of(_sd, struct ov08d10, sd)
 
 struct ov08d10_reg {
@@ -110,6 +118,9 @@ struct ov08d10_mode {
 
 	/* Number of data lanes */
 	u8 data_lanes;
+
+	/* Analogue crop rectangle, in native sensor coordinates */
+	struct v4l2_rect crop;
 };
 
 /* 3280x2460, 3264x2448 need 720Mbps/lane, 2 lanes - 19.2 MHz */
@@ -630,6 +641,7 @@ static const struct ov08d10_lane_cfg lane_cfg_2 = {
 		},
 		.link_freq_index = 0,
 		.data_lanes = 2,
+		.crop = { .left =  4, .top =  8, .width = 3280, .height = 2460 },
 	},
 	{
 		.width = 3264,
@@ -643,6 +655,7 @@ static const struct ov08d10_lane_cfg lane_cfg_2 = {
 		},
 		.link_freq_index = 0,
 		.data_lanes = 2,
+		.crop = { .left = 12, .top = 16, .width = 3264, .height = 2448 },
 	},
 	{
 		.width = 1632,
@@ -656,6 +669,7 @@ static const struct ov08d10_lane_cfg lane_cfg_2 = {
 		},
 		.link_freq_index = 1,
 		.data_lanes = 2,
+		.crop = { .left = 12, .top = 16, .width = 3264, .height = 2448 },
 	}}
 };
 
@@ -955,6 +969,36 @@ static int ov08d10_set_ctrl(struct v4l2_ctrl *ctrl)
 	return ret;
 }
 
+static int ov08d10_get_selection(struct v4l2_subdev *sd,
+				 const struct v4l2_subdev_client_info *ci,
+				 struct v4l2_subdev_state *sd_state,
+				 struct v4l2_subdev_selection *sel)
+{
+	switch (sel->target) {
+	case V4L2_SEL_TGT_CROP:
+		sel->r = *v4l2_subdev_state_get_crop(sd_state, 0);
+		return 0;
+
+	case V4L2_SEL_TGT_NATIVE_SIZE:
+		sel->r.left = 0;
+		sel->r.top = 0;
+		sel->r.width = OV08D10_NATIVE_WIDTH;
+		sel->r.height = OV08D10_NATIVE_HEIGHT;
+		return 0;
+
+	case V4L2_SEL_TGT_CROP_DEFAULT:
+	case V4L2_SEL_TGT_CROP_BOUNDS:
+		sel->r.left = OV08D10_PIXEL_ARRAY_LEFT;
+		sel->r.top = OV08D10_PIXEL_ARRAY_TOP;
+		sel->r.width = OV08D10_PIXEL_ARRAY_WIDTH;
+		sel->r.height = OV08D10_PIXEL_ARRAY_HEIGHT;
+		return 0;
+
+	default:
+		return -EINVAL;
+	}
+}
+
 static const struct v4l2_ctrl_ops ov08d10_ctrl_ops = {
 	.s_ctrl = ov08d10_set_ctrl,
 };
@@ -1194,6 +1238,9 @@ static int ov08d10_set_format(struct v4l2_subdev *sd,
 
 	mutex_lock(&ov08d10->mutex);
 	ov08d10_update_pad_format(ov08d10, mode, &fmt->format);
+
+	*v4l2_subdev_state_get_crop(sd_state, fmt->pad) = mode->crop;
+
 	if (fmt->which == V4L2_SUBDEV_FORMAT_TRY) {
 		*v4l2_subdev_state_get_format(sd_state, fmt->pad) =
 								fmt->format;
@@ -1297,6 +1344,19 @@ static int ov08d10_open(struct v4l2_subdev *sd, struct v4l2_subdev_fh *fh)
 	return 0;
 }
 
+static int ov08d10_init_state(struct v4l2_subdev *sd,
+			      struct v4l2_subdev_state *sd_state)
+{
+	struct ov08d10 *ov08d10 = to_ov08d10(sd);
+	const struct ov08d10_mode *mode = &ov08d10->priv_lane->sp_modes[0];
+
+	*v4l2_subdev_state_get_crop(sd_state, 0) = mode->crop;
+	ov08d10_update_pad_format(ov08d10, mode,
+				  v4l2_subdev_state_get_format(sd_state, 0));
+
+	return 0;
+}
+
 static const struct v4l2_subdev_video_ops ov08d10_video_ops = {
 	.s_stream = ov08d10_set_stream,
 };
@@ -1306,6 +1366,7 @@ static const struct v4l2_subdev_pad_ops ov08d10_pad_ops = {
 	.get_fmt = ov08d10_get_format,
 	.enum_mbus_code = ov08d10_enum_mbus_code,
 	.enum_frame_size = ov08d10_enum_frame_size,
+	.get_selection = ov08d10_get_selection,
 };
 
 static const struct v4l2_subdev_ops ov08d10_subdev_ops = {
@@ -1315,6 +1376,7 @@ static const struct v4l2_subdev_ops ov08d10_subdev_ops = {
 
 static const struct v4l2_subdev_internal_ops ov08d10_internal_ops = {
 	.open = ov08d10_open,
+	.init_state = ov08d10_init_state,
 };
 
 static int ov08d10_power_off(struct device *dev)
@@ -1470,6 +1532,7 @@ static void ov08d10_remove(struct i2c_client *client)
 	struct ov08d10 *ov08d10 = to_ov08d10(sd);
 
 	v4l2_async_unregister_subdev(sd);
+	v4l2_subdev_cleanup(sd);
 	media_entity_cleanup(&sd->entity);
 	v4l2_ctrl_handler_free(sd->ctrl_handler);
 	pm_runtime_disable(ov08d10->dev);
@@ -1565,17 +1628,26 @@ static int ov08d10_probe(struct i2c_client *client)
 	pm_runtime_set_active(ov08d10->dev);
 	pm_runtime_enable(ov08d10->dev);
 
+	ret = v4l2_subdev_init_finalize(&ov08d10->sd);
+	if (ret) {
+		dev_err(ov08d10->dev, "failed to init subdev state: %d\n", ret);
+		goto probe_error_media_entity_cleanup;
+	}
+
 	ret = v4l2_async_register_subdev_sensor(&ov08d10->sd);
 	if (ret < 0) {
 		dev_err(ov08d10->dev, "failed to register V4L2 subdev: %d\n",
 			ret);
-		goto probe_error_media_entity_cleanup;
+		goto probe_error_subdev_cleanup;
 	}
 
 	pm_runtime_idle(ov08d10->dev);
 
 	return 0;
 
+probe_error_subdev_cleanup:
+	v4l2_subdev_cleanup(&ov08d10->sd);
+
 probe_error_media_entity_cleanup:
 	pm_runtime_disable(ov08d10->dev);
 	pm_runtime_set_suspended(ov08d10->dev);

---
base-commit: 2dcdfb625c3b8fe87454e19dfbc54b3e3f0ad70e
change-id: 20260929-ov08d10-get-selection-caa7b6cb8dfe

Best regards,
-- 
Max Bretschneider <max.bretschneider@leica-geosystems.com>

