From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 21:30:16 +0100
Subject: [PATCH 4/4] media: i2c: ov7251: add V4L2_CID_FLASH_STROBE_OE
 control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-ov7251-strobe-ncont-v1-4-cefa8c6c020b@gmail.com>
References: <20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com>
In-Reply-To: <20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>, Todor Tomov <todor.too@gmail.com>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811412; l=3757;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=yvTV+s3D7NAOh5BV09o0U6C+V+jBgQvfOZD1tUWs0hM=;
 b=P6FZyAR+Ml3t5H3BowgEG7cVPUV/eVKhy0qBjPnxV/PVXTvynBHS9e0PB6FDbkeeQ0CmMU29F
 PH8WvxBV8vUClaaW2gsj2T8tc9uP48GlVjlXVS7L7E1PP3/WkeZgxXG
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Devices such as the Microsoft Surface Pro X wire the OV7251 sensor's
hardware STROBE output pin to an 850 nm IR illuminator for synchronized
frame-exposure illumination.

Expose V4L2_CID_FLASH_STROBE_OE (default disabled) to drive the sensor's
STROBE pin (0x3005, 0x3027, 0x3b81, 0x3b8e..0x3b8f) while streaming, and
disable the strobe output when stopping the stream.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/i2c/ov7251.c | 47 +++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 46 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov7251.c b/drivers/media/i2c/ov7251.c
index 13fcc4cdb31a5e7350bcc0b15d186f4912b074be..e6007708139964c423c68dae86e7c07c26349fea 100644
--- a/drivers/media/i2c/ov7251.c
+++ b/drivers/media/i2c/ov7251.c
@@ -30,7 +30,15 @@
 #define OV7251_CHIP_ID_HIGH_BYTE	0x77
 #define OV7251_CHIP_ID_LOW		0x300b
 #define OV7251_CHIP_ID_LOW_BYTE		0x50
+#define OV7251_SC_IO_CTRL1		0x3005
+#define OV7251_IO_CTRL1_STROBE_EN	BIT(3)
+#define OV7251_SC_GP_IO_SEL1		0x3027
 #define OV7251_SC_GP_IO_IN1		0x3029
+#define OV7251_STROBE_PATTERN		0x3b81
+#define OV7251_STROBE_PATTERN_ALL	0xff
+#define OV7251_STROBE_SPAN_H		0x3b8e
+#define OV7251_STROBE_SPAN_L		0x3b8f
+#define OV7251_STROBE_SPAN_DEFAULT	0x0200
 #define OV7251_AEC_EXPO_0		0x3500
 #define OV7251_AEC_EXPO_1		0x3501
 #define OV7251_AEC_EXPO_2		0x3502
@@ -979,6 +987,37 @@ static int ov7251_set_hflip(struct ov7251 *ov7251, s32 value)
 	return ret;
 }
 
+static int ov7251_set_strobe(struct ov7251 *ov7251, bool enable)
+{
+	int ret;
+
+	if (enable) {
+		ret = ov7251_write_reg(ov7251, OV7251_STROBE_PATTERN,
+				       OV7251_STROBE_PATTERN_ALL);
+		if (ret)
+			return ret;
+
+		ret = ov7251_write_reg(ov7251, OV7251_STROBE_SPAN_H,
+				       OV7251_STROBE_SPAN_DEFAULT >> 8);
+		if (ret)
+			return ret;
+
+		ret = ov7251_write_reg(ov7251, OV7251_STROBE_SPAN_L,
+				       OV7251_STROBE_SPAN_DEFAULT & 0xff);
+		if (ret)
+			return ret;
+
+		ret = ov7251_write_reg(ov7251, OV7251_SC_GP_IO_SEL1, 0x00);
+		if (ret)
+			return ret;
+
+		return ov7251_write_reg(ov7251, OV7251_SC_IO_CTRL1,
+					OV7251_IO_CTRL1_STROBE_EN);
+	}
+
+	return ov7251_write_reg(ov7251, OV7251_SC_IO_CTRL1, 0x00);
+}
+
 static int ov7251_set_vflip(struct ov7251 *ov7251, s32 value)
 {
 	u8 val = ov7251->timing_format1;
@@ -1072,6 +1111,9 @@ static int ov7251_s_ctrl(struct v4l2_ctrl *ctrl)
 	case V4L2_CID_VBLANK:
 		ret = ov7251_vts_configure(ov7251, ctrl->val);
 		break;
+	case V4L2_CID_FLASH_STROBE_OE:
+		ret = ov7251_set_strobe(ov7251, ctrl->val);
+		break;
 	default:
 		ret = -EINVAL;
 		break;
@@ -1394,6 +1436,7 @@ static int ov7251_s_stream(struct v4l2_subdev *subdev, int enable)
 		if (ret)
 			goto err_power_down;
 	} else {
+		ov7251_set_strobe(ov7251, false);
 		ret = ov7251_write_reg(ov7251, OV7251_SC_MODE_SELECT,
 				       OV7251_SC_MODE_SELECT_SW_STANDBY);
 		pm_runtime_mark_last_busy(ov7251->dev);
@@ -1594,7 +1637,7 @@ static int ov7251_init_ctrls(struct ov7251 *ov7251)
 	s64 pixel_rate;
 	int hblank;
 
-	v4l2_ctrl_handler_init(&ov7251->ctrls, 7);
+	v4l2_ctrl_handler_init(&ov7251->ctrls, 8);
 	ov7251->ctrls.lock = &ov7251->lock;
 
 	v4l2_ctrl_new_std(&ov7251->ctrls, &ov7251_ctrl_ops,
@@ -1609,6 +1652,8 @@ static int ov7251_init_ctrls(struct ov7251 *ov7251)
 				     V4L2_CID_TEST_PATTERN,
 				     ARRAY_SIZE(ov7251_test_pattern_menu) - 1,
 				     0, 0, ov7251_test_pattern_menu);
+	v4l2_ctrl_new_std(&ov7251->ctrls, &ov7251_ctrl_ops,
+			  V4L2_CID_FLASH_STROBE_OE, 0, 1, 1, 0);
 
 	pixel_rate = pixel_rates[ov7251->link_freq_idx];
 	ov7251->pixel_clock = v4l2_ctrl_new_std(&ov7251->ctrls,

-- 
2.47.3

