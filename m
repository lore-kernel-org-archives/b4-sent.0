From: Max Bretschneider <max.bretschneider@leica-geosystems.com>
Date: Sat, 24 Oct 2026 00:28:54 +0200
Subject: [PATCH v2 4/4] media: i2c: ov08d10: add get_selection support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-ov08d10-get-selection-v2-4-f8c49972ca18@leica-geosystems.com>
References: <20261024-ov08d10-get-selection-v2-0-f8c49972ca18@leica-geosystems.com>
In-Reply-To: <20261024-ov08d10-get-selection-v2-0-f8c49972ca18@leica-geosystems.com>
To: Jimmy Su <jimmy.su@intel.com>, Matthias Fend <matthias.fend@emfend.at>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Max Bretschneider <max.bretschneider@leica-geosystems.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792794706; l=4916;
 i=max.bretschneider@leica-geosystems.com; s=20260501;
 h=from:subject:message-id; bh=pSPbfW/+rQXIuQoU/4hrAg5l2fsycIgBp7w9O8RjxoE=;
 b=zoQokf57qmjGEky4VZ/Z/6RraDLuWEPTwXHwQplZUWcK/7SQxcfb41UenzEFp2UzWJzx8rMWn
 npE8Fr5YQBOCEo6VMB+YifxjKIyb+vzktfm86Dzi462BmqNBx34pRxP
X-Developer-Key: i=max.bretschneider@leica-geosystems.com; a=ed25519;
 pk=jf4ba33jrWlsOdGemi2InMtJAngoJVZU8Moetp0ixik=
X-Endpoint-Received: by B4 Relay for max.bretschneider@leica-geosystems.com/20260501 with auth_id=1161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver does not implement .get_selection, so it never reports the
analogue crop rectangle of the active mode. Userspace has no way to learn
which region of the pixel array a given mode reads out, and cannot assume
a fixed one, because the modes differ: the full mode reads 3280x2460 at
offset (4,8), while the 3264x2448 and the 2x2 binned 1632x1224 modes read
3264x2448 at offset (12,16).

Consumers that derive the sensor scale from the analogue crop and the
output size therefore compute a wrong result for the cropped and binned
modes, and may reject those configurations.

Track the analogue crop rectangle per mode, store it in the subdev state
when the format is set, and report it through .get_selection. Also report
V4L2_SEL_TGT_CROP_DEFAULT, V4L2_SEL_TGT_CROP_BOUNDS and
V4L2_SEL_TGT_NATIVE_SIZE from the pixel array geometry.

The pixel array geometry and the per-mode offsets are taken from the
sensor datasheet and the recommended reference register sets.

Signed-off-by: Max Bretschneider <max.bretschneider@leica-geosystems.com>
---
 drivers/media/i2c/ov08d10.c | 50 ++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 49 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov08d10.c b/drivers/media/i2c/ov08d10.c
index 4b503ddfa042..2e5ae8c49067 100644
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
@@ -624,6 +635,7 @@ static const struct ov08d10_lane_cfg lane_cfg_2 = {
 		},
 		.link_freq_index = 0,
 		.data_lanes = 2,
+		.crop = { .left =  4, .top =  8, .width = 3280, .height = 2460 },
 	},
 	{
 		.width = 3264,
@@ -637,6 +649,7 @@ static const struct ov08d10_lane_cfg lane_cfg_2 = {
 		},
 		.link_freq_index = 0,
 		.data_lanes = 2,
+		.crop = { .left = 12, .top = 16, .width = 3264, .height = 2448 },
 	},
 	{
 		.width = 1632,
@@ -650,6 +663,7 @@ static const struct ov08d10_lane_cfg lane_cfg_2 = {
 		},
 		.link_freq_index = 1,
 		.data_lanes = 2,
+		.crop = { .left = 12, .top = 16, .width = 3264, .height = 2448 },
 	}}
 };
 
@@ -1209,6 +1223,7 @@ static int ov08d10_set_format(struct v4l2_subdev *sd,
 
 	ov08d10_update_pad_format(ov08d10, mode, &fmt->format);
 	*v4l2_subdev_state_get_format(sd_state, fmt->pad) = fmt->format;
+	*v4l2_subdev_state_get_crop(sd_state, fmt->pad) = mode->crop;
 
 	if (fmt->which == V4L2_SUBDEV_FORMAT_ACTIVE) {
 		__v4l2_ctrl_s_ctrl(ov08d10->link_freq, mode->link_freq_index);
@@ -1270,13 +1285,45 @@ static int ov08d10_enum_frame_size(struct v4l2_subdev *sd,
 	return 0;
 }
 
+static int ov08d10_get_selection(struct v4l2_subdev *sd,
+				 const struct v4l2_subdev_client_info *ci,
+				 struct v4l2_subdev_state *sd_state,
+				 struct v4l2_subdev_selection *sel)
+{
+	switch (sel->target) {
+	case V4L2_SEL_TGT_CROP:
+		sel->r = *v4l2_subdev_state_get_crop(sd_state, sel->pad);
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
 static int ov08d10_init_state(struct v4l2_subdev *sd,
 			      struct v4l2_subdev_state *sd_state)
 {
 	struct ov08d10 *ov08d10 = to_ov08d10(sd);
+	const struct ov08d10_mode *mode = &ov08d10->priv_lane->sp_modes[0];
 
-	ov08d10_update_pad_format(ov08d10, &ov08d10->priv_lane->sp_modes[0],
+	ov08d10_update_pad_format(ov08d10, mode,
 				  v4l2_subdev_state_get_format(sd_state, 0));
+	*v4l2_subdev_state_get_crop(sd_state, 0) = mode->crop;
 
 	return 0;
 }
@@ -1290,6 +1337,7 @@ static const struct v4l2_subdev_pad_ops ov08d10_pad_ops = {
 	.get_fmt = v4l2_subdev_get_fmt,
 	.enum_mbus_code = ov08d10_enum_mbus_code,
 	.enum_frame_size = ov08d10_enum_frame_size,
+	.get_selection = ov08d10_get_selection,
 };
 
 static const struct v4l2_subdev_ops ov08d10_subdev_ops = {

-- 
2.43.0

