From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 03 Mar 2025 23:58:59 +0100
Subject: [PATCH 3/3] media: i2c: ov9282: add strobe_timeout v4l2 control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250303-ov9282-flash-strobe-v1-3-0fd57a1564ba@linux.dev>
References: <20250303-ov9282-flash-strobe-v1-0-0fd57a1564ba@linux.dev>
In-Reply-To: <20250303-ov9282-flash-strobe-v1-0-0fd57a1564ba@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741042742; l=3993;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=2qBIlc61Bz0jLXzWYXDw1jJCbwLUdYBGjPC1XgOpVUc=;
 b=j8FXv3/aOnxHqzyRM0RPHz9QmI2mC4+6onIZX4C0TQL+YMCjlVdVkVd7gWomBgJaN13tzgcCR
 ZvKCC3Ef+JzDTPOoYFUQPDkRcYMuEzTLCuyo4z4BlJvom4QFXhRCxMl
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add V4L2_CID_FLASH_TIMEOUT support using the "strobe_frame_span"
feature of the sensor. This is implemented by transforming the given µs
value by an interpolated formula to a "span step width" value and
writing it to register PWM_CTRL_25, PWM_CTRL_26, PWM_CTRL_27,
PWM_CTRL_28 (0x3925, 0x3926, 0x3927, 0x3928).

The maximum control value is set to the period of the current framerate.
This must be changed to a dynamic range as soon as this driver
implements the set_frame_interval() pad operation.

All register values are based on the OV9281 datasheet v1.53 (jan 2019)
and tested using an ov9281 VisionComponents module.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 31 +++++++++++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index c98ba466e9aea29baff0b13578d760bf69c958c5..f7dfe8987e524b73af7e16e12567e96627b4f89a 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -97,6 +97,10 @@
 #define OV9282_REG_MIPI_CTRL00	0x4800
 #define OV9282_GATED_CLOCK	BIT(5)
 
+/* Flash/Strobe control registers */
+#define OV9282_REG_FLASH_DURATION	0x3925
+#define OV9282_FLASH_DURATION_DEFAULT	0x0000001A
+
 /* Input clock rate */
 #define OV9282_INCLK_RATE	24000000
 
@@ -193,6 +197,7 @@ struct ov9282_mode {
  * @again_ctrl: Pointer to analog gain control
  * @pixel_rate: Pointer to pixel rate control
  * @flash_led_mode: Pointer to flash led mode control
+ * @flash_timeout: Pointer to flash timeout control
  * @vblank: Vertical blanking in lines
  * @noncontinuous_clock: Selection of CSI2 noncontinuous clock mode
  * @cur_mode: Pointer to current selected sensor mode
@@ -216,6 +221,7 @@ struct ov9282 {
 	};
 	struct v4l2_ctrl *pixel_rate;
 	struct v4l2_ctrl *flash_led_mode;
+	struct v4l2_ctrl *flash_timeout;
 	u32 vblank;
 	bool noncontinuous_clock;
 	const struct ov9282_mode *cur_mode;
@@ -689,6 +695,24 @@ static int ov9282_set_ctrl_flash_led_mode(struct ov9282 *ov9282, int mode)
 				current_val);
 }
 
+static int ov9282_set_ctrl_flash_timeout(struct ov9282 *ov9282, int value)
+{
+	/* Calculate "strobe_frame_span" increments from a given value (µs).
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
@@ -758,6 +782,9 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 	case V4L2_CID_FLASH_LED_MODE:
 		ret = ov9282_set_ctrl_flash_led_mode(ov9282, ctrl->val);
 		break;
+	case V4L2_CID_FLASH_TIMEOUT:
+		ret = ov9282_set_ctrl_flash_timeout(ov9282, ctrl->val);
+		break;
 	default:
 		dev_err(ov9282->dev, "Invalid control %d", ctrl->id);
 		ret = -EINVAL;
@@ -1420,6 +1447,10 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 							(1 << V4L2_FLASH_LED_MODE_TORCH),
 							V4L2_FLASH_LED_MODE_NONE);
 
+	ov9282->flash_timeout = v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops,
+						  V4L2_CID_FLASH_TIMEOUT,
+						  0, 13900, 1, 8);
+
 	ret = v4l2_fwnode_device_parse(ov9282->dev, &props);
 	if (!ret) {
 		/* Failure sets ctrl_hdlr->error, which we check afterwards anyway */

-- 
2.47.2

