From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 09 Dec 2025 23:44:41 +0100
Subject: [PATCH v10 6/8] media: i2c: ov9282: add strobe_duration v4l2
 control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251209-ov9282-flash-strobe-v10-6-0117cab82e2d@linux.dev>
References: <20251209-ov9282-flash-strobe-v10-0-0117cab82e2d@linux.dev>
In-Reply-To: <20251209-ov9282-flash-strobe-v10-0-0117cab82e2d@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-leds@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil@kernel.org>
X-Mailer: b4 0.15-dev-a3fc8
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765320290; l=3706;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=ql9elevyOa14jUq8mUYlt9RSPi/+CkHVrpCz7LqekyU=;
 b=7zJ17msfNyBOkCo7lYPVkSr5Nf6V8EdjwObQINRDVpUOP4W38Pjfo72g5cfRxvjliwV8uv6zb
 SDZMSdfnnBaBqrvkmMTwlrwhJITdIPbgXbCOpMM6siYWmAePZTAMs7P
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
 drivers/media/i2c/ov9282.c | 46 +++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 45 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index 6afce803a049d..790d421157e54 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -97,6 +97,10 @@
 #define OV9282_REG_MIPI_CTRL00	0x4800
 #define OV9282_GATED_CLOCK	BIT(5)
 
+/* Flash/Strobe control registers */
+#define OV9282_REG_STROBE_FRAME_SPAN		0x3925
+#define OV9282_STROBE_FRAME_SPAN_DEFAULT	0x0000001a
+
 /* Input clock rate */
 #define OV9282_INCLK_RATE	24000000
 
@@ -687,6 +691,40 @@ static int ov9282_set_ctrl_flash_strobe_oe(struct ov9282 *ov9282, bool enable)
 	return ov9282_write_reg(ov9282, OV9282_REG_OUTPUT_ENABLE6, 1, current_val);
 }
 
+static int ov9282_set_ctrl_flash_duration(struct ov9282 *ov9282, u32 value)
+{
+	int ret;
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
+	ret = ov9282_write_reg(ov9282, OV9282_REG_STROBE_FRAME_SPAN, 1,
+			       (val >> 24) & 0xff);
+	if (ret)
+		return ret;
+
+	ret = ov9282_write_reg(ov9282, OV9282_REG_STROBE_FRAME_SPAN + 1, 1,
+			       (val >> 16) & 0xff);
+	if (ret)
+		return ret;
+
+	ret = ov9282_write_reg(ov9282, OV9282_REG_STROBE_FRAME_SPAN + 2, 1,
+			       (val >> 8) & 0xff);
+	if (ret)
+		return ret;
+
+	ret = ov9282_write_reg(ov9282, OV9282_REG_STROBE_FRAME_SPAN + 3, 1,
+			       val & 0xff);
+	return ret;
+}
+
 /**
  * ov9282_set_ctrl() - Set subdevice control
  * @ctrl: pointer to v4l2_ctrl structure
@@ -756,6 +794,9 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 	case V4L2_CID_FLASH_STROBE_OE:
 		ret = ov9282_set_ctrl_flash_strobe_oe(ov9282, ctrl->val);
 		break;
+	case V4L2_CID_FLASH_DURATION:
+		ret = ov9282_set_ctrl_flash_duration(ov9282, ctrl->val);
+		break;
 	default:
 		dev_err(ov9282->dev, "Invalid control %d", ctrl->id);
 		ret = -EINVAL;
@@ -1345,7 +1386,7 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	u32 lpfr;
 	int ret;
 
-	ret = v4l2_ctrl_handler_init(ctrl_hdlr, 11);
+	ret = v4l2_ctrl_handler_init(ctrl_hdlr, 12);
 	if (ret)
 		return ret;
 
@@ -1414,6 +1455,9 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops,
 			  V4L2_CID_FLASH_STROBE_OE, 0, 1, 1, 0);
 
+	v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops, V4L2_CID_FLASH_DURATION,
+			  0, 13900, 1, 8);
+
 	ret = v4l2_fwnode_device_parse(ov9282->dev, &props);
 	if (!ret) {
 		/* Failure sets ctrl_hdlr->error, which we check afterwards anyway */

-- 
2.47.3

