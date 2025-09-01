From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 01 Sep 2025 17:05:12 +0200
Subject: [PATCH v7 07/10] media: i2c: ov9282: add strobe_duration v4l2
 control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250901-ov9282-flash-strobe-v7-7-d58d5a694afc@linux.dev>
References: <20250901-ov9282-flash-strobe-v7-0-d58d5a694afc@linux.dev>
In-Reply-To: <20250901-ov9282-flash-strobe-v7-0-d58d5a694afc@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-leds@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756739145; l=3529;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=zHiadu/PJkoFNn6YwHGG0Az+tad6OHewe3uLyIg6GGY=;
 b=16+arFAFs6tUt862WUqqdOIz7Bp3nAPy/UtsL5FYgvbkTSbwZzg8uWu9c/E/s8JDG9xzMczYM
 8QWVBn19fdZCG6Uo4nFG1QD2PPA46RHFlk7XEJiwIbCq4xnO9acYGn4
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add V4L2_CID_FLASH_DURATION support using the "strobe_frame_span"
feature of the sensor. This is implemented by transforming the given µs
value by an interpolated formula to a "span step width" value and
writing it to register PWM_CTRL_25, PWM_CTRL_26, PWM_CTRL_27,
PWM_CTRL_28 (0x3925, 0x3926, 0x3927, 0x3928).

The maximum control value is set to the period of the current default
framerate.

All register values are based on the OV9281 datasheet v1.53 (jan 2019)
and tested using an ov9281 VisionComponents module.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 31 ++++++++++++++++++++++++++++++-
 1 file changed, 30 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index ff0f69f0dc3a2d0518806b9ea65c1b520b5c55fb..c405e3411daf37cf98d5af3535702f8321394af5 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -97,6 +97,10 @@
 #define OV9282_REG_MIPI_CTRL00	0x4800
 #define OV9282_GATED_CLOCK	BIT(5)
 
+/* Flash/Strobe control registers */
+#define OV9282_REG_FLASH_DURATION	0x3925
+#define OV9282_FLASH_DURATION_DEFAULT	0x0000001a
+
 /* Input clock rate */
 #define OV9282_INCLK_RATE	24000000
 
@@ -687,6 +691,25 @@ static int ov9282_set_ctrl_flash_hw_strobe_signal(struct ov9282 *ov9282, bool en
 				current_val);
 }
 
+static int ov9282_set_ctrl_flash_duration(struct ov9282 *ov9282, u32 value)
+{
+	/*
+	 * Calculate "strobe_frame_span" increments from a given value (µs).
+	 * This is quite tricky as "The step width of shift and span is
+	 * programmable under system clock domain.", but it's not documented
+	 * how to program this step width (at least in the datasheet available
+	 * to the author at time of writing).
+	 * The formula below is interpolated from different modes/framerates
+	 * and should work quite well for most settings.
+	 */
+	u32 val = value * 192 / (ov9282->cur_mode->width + ov9282->hblank_ctrl->val);
+
+	ov9282_write_reg(ov9282, OV9282_REG_FLASH_DURATION, 1, (val >> 24) & 0xff);
+	ov9282_write_reg(ov9282, OV9282_REG_FLASH_DURATION + 1, 1, (val >> 16) & 0xff);
+	ov9282_write_reg(ov9282, OV9282_REG_FLASH_DURATION + 2, 1, (val >> 8) & 0xff);
+	return ov9282_write_reg(ov9282, OV9282_REG_FLASH_DURATION + 3, 1, val & 0xff);
+}
+
 /**
  * ov9282_set_ctrl() - Set subdevice control
  * @ctrl: pointer to v4l2_ctrl structure
@@ -756,6 +779,9 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 	case V4L2_CID_FLASH_HW_STROBE_SIGNAL:
 		ret = ov9282_set_ctrl_flash_hw_strobe_signal(ov9282, ctrl->val);
 		break;
+	case V4L2_CID_FLASH_DURATION:
+		ret = ov9282_set_ctrl_flash_duration(ov9282, ctrl->val);
+		break;
 	default:
 		dev_err(ov9282->dev, "Invalid control %d", ctrl->id);
 		ret = -EINVAL;
@@ -1346,7 +1372,7 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	u32 lpfr;
 	int ret;
 
-	ret = v4l2_ctrl_handler_init(ctrl_hdlr, 11);
+	ret = v4l2_ctrl_handler_init(ctrl_hdlr, 12);
 	if (ret)
 		return ret;
 
@@ -1414,6 +1440,9 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	/* Flash/Strobe controls */
 	v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops, V4L2_CID_FLASH_HW_STROBE_SIGNAL, 0, 1, 1, 0);
 
+	v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops, V4L2_CID_FLASH_DURATION,
+			  0, 13900, 1, 8);
+
 	ret = v4l2_fwnode_device_parse(ov9282->dev, &props);
 	if (!ret) {
 		/* Failure sets ctrl_hdlr->error, which we check afterwards anyway */

-- 
2.47.2

