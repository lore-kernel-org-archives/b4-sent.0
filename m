From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 17 Jun 2025 09:31:40 +0200
Subject: [PATCH v5 06/10] media: i2c: ov9282: add led_mode v4l2 control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250617-ov9282-flash-strobe-v5-6-9762da74d065@linux.dev>
References: <20250617-ov9282-flash-strobe-v5-0-9762da74d065@linux.dev>
In-Reply-To: <20250617-ov9282-flash-strobe-v5-0-9762da74d065@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Hans Verkuil <hverkuil@xs4all.nl>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750145501; l=2663;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=vj4AZ2VwKF/zDloCshyajTedmued0DDmjMCD6CM2Ep8=;
 b=gkGMtTqdRP2ZqpP/QeyIOA+7vgfR8r6qWp3xe3u8MCx7IPMK1bjL0jhOcL4ZnE49sggj2kVSv
 9Trv1X7E37uBELtjEKqhBqjfi9z30J8HF9khw4BMwgIUJAiPAuJ9lFZ
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add V4L2_CID_FLASH_LED_MODE support using the "strobe output enable"
feature of the sensor. This implements following modes:

 - V4L2_FLASH_LED_MODE_NONE, which disables the strobe output
 - V4L2_FLASH_LED_MODE_FLASH, which enables the strobe output

All values are based on the OV9281 datasheet v1.53 (january 2019) and
tested using an ov9281 VisionComponents module.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 29 ++++++++++++++++++++++++++++-
 1 file changed, 28 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index f42e0d439753e74d14e3a3592029e48f49234927..b6de96997426f7225a061bfdc841aa062e8d0891 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -670,6 +670,23 @@ static int ov9282_set_ctrl_vflip(struct ov9282 *ov9282, int value)
 				current_val);
 }
 
+static int ov9282_set_ctrl_flash_led_mode(struct ov9282 *ov9282, int mode)
+{
+	u32 current_val;
+	int ret = ov9282_read_reg(ov9282, OV9282_REG_OUTPUT_ENABLE6, 1,
+				  &current_val);
+	if (ret)
+		return ret;
+
+	if (mode == V4L2_FLASH_LED_MODE_FLASH)
+		current_val |= OV9282_OUTPUT_ENABLE6_STROBE;
+	else
+		current_val &= ~OV9282_OUTPUT_ENABLE6_STROBE;
+
+	return ov9282_write_reg(ov9282, OV9282_REG_OUTPUT_ENABLE6, 1,
+				current_val);
+}
+
 /**
  * ov9282_set_ctrl() - Set subdevice control
  * @ctrl: pointer to v4l2_ctrl structure
@@ -736,6 +753,9 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 		ret = ov9282_write_reg(ov9282, OV9282_REG_TIMING_HTS, 2,
 				       (ctrl->val + ov9282->cur_mode->width) >> 1);
 		break;
+	case V4L2_CID_FLASH_LED_MODE:
+		ret = ov9282_set_ctrl_flash_led_mode(ov9282, ctrl->val);
+		break;
 	default:
 		dev_err(ov9282->dev, "Invalid control %d", ctrl->id);
 		ret = -EINVAL;
@@ -1326,7 +1346,7 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	u32 lpfr;
 	int ret;
 
-	ret = v4l2_ctrl_handler_init(ctrl_hdlr, 10);
+	ret = v4l2_ctrl_handler_init(ctrl_hdlr, 11);
 	if (ret)
 		return ret;
 
@@ -1391,6 +1411,13 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 						OV9282_TIMING_HTS_MAX - mode->width,
 						1, hblank_min);
 
+	/* Flash/Strobe controls */
+	v4l2_ctrl_new_std_menu(ctrl_hdlr, &ov9282_ctrl_ops,
+			       V4L2_CID_FLASH_LED_MODE,
+			       V4L2_FLASH_LED_MODE_TORCH,
+			       (1 << V4L2_FLASH_LED_MODE_TORCH),
+			       V4L2_FLASH_LED_MODE_NONE);
+
 	ret = v4l2_fwnode_device_parse(ov9282->dev, &props);
 	if (!ret) {
 		/* Failure sets ctrl_hdlr->error, which we check afterwards anyway */

-- 
2.47.2

