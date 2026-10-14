From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 14 Oct 2026 08:49:10 +0200
Subject: [PATCH v2 3/8] media: i2c: ov9282: fix flash duration to/from
 microseconds conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261014-ov9282-fixes-v2-3-3bb376d8b1a9@linux.dev>
References: <20261014-ov9282-fixes-v2-0-3bb376d8b1a9@linux.dev>
In-Reply-To: <20261014-ov9282-fixes-v2-0-3bb376d8b1a9@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Daniele Alessandrelli <daniele.alessandrelli@gmail.com>, 
 "Paul J. Murphy" <paul.j.murphy@intel.com>, 
 Martina Krasteva <martinax.krasteva@intel.com>, 
 Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 Gyula Kelemen <gyula.kelemen@advasolutions.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791960586; l=5802;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=/TZMWM5u1jhdfw45vVJQm0syeDKeBCYD9MP5LfiRMB4=;
 b=FGOsHYmd0t4EfOzxtNN5BPFiS2yOBMuE7k74IsGsGiSlWy4K1qDheO1N/drj/1Y9b0uwVei01
 +qTe6BXoDu+BCV+ZsRAzNLgCnQyfVMlL1+FsJ+30pUM+l3emQg0Q/j6
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the flash duration is converted to/from microseconds using a
fixed OV9282_STROBE_SPAN_FACTOR constant. This is inaccurate as it was
found that the "step width of shift and span" (which is not documented
further in the datasheet) scales with the line, so the span is counted
in lines. This was verified by comparing the stobe pulses measured on
the camera module against the calculated line times.

As this is the same conversion as for the exposure: rename those functions
to a more generic ov9282_us_to_lines/ov9282_lines_to_us and use them also
for the flash/strobe duration.

Fixes: b95d8058a2786 ("media: i2c: ov9282: implement try_ctrl for strobe_duration")
Cc: stable@vger.kernel.org
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 65 +++++++++++++++++-----------------------------
 1 file changed, 24 insertions(+), 41 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index 5907f57b34523..e2a1f875160b9 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -136,8 +136,6 @@
 #define OV9282_REG_MIN		0x00
 #define OV9282_REG_MAX		0xfffff
 
-#define OV9282_STROBE_SPAN_FACTOR	192
-
 static const char * const ov9282_supply_names[] = {
 	"avdd",		/* Analog power */
 	"dovdd",	/* Digital I/O power */
@@ -491,18 +489,31 @@ static u32 ov9282_line_time_ns(struct ov9282 *ov9282)
 }
 
 /**
- * ov9282_exposure_to_us() - Convert an exposure register value to microseconds
+ * ov9282_lines_to_us() - Convert a number of lines to microseconds
  * @ov9282: pointer to ov9282 device
- * @exposure: exposure register value to convert
+ * @lines: line count to convert
  *
- * Return: microsecond representation of the given exposure register value.
+ * Return: microsecond representation of the given line count.
  */
-static u32 ov9282_exposure_to_us(struct ov9282 *ov9282, u32 exposure)
+static u32 ov9282_lines_to_us(struct ov9282 *ov9282, u32 lines)
 {
-	return div_u64((u64)exposure * ov9282_line_time_ns(ov9282),
+	return div_u64((u64)lines * ov9282_line_time_ns(ov9282),
 		       NSEC_PER_USEC);
 }
 
+/**
+ * ov9282_us_to_lines() - Convert µs to line count
+ * @ov9282: pointer to ov9282 device
+ * @duration: microseconds value to convert
+ *
+ * Return: number of lines fitting into the given duration
+ */
+static u32 ov9282_us_to_lines(struct ov9282 *ov9282, u32 duration)
+{
+	return DIV_ROUND_UP((u64)duration * NSEC_PER_USEC,
+			    ov9282_line_time_ns(ov9282));
+}
+
 /**
  * ov9282_update_controls() - Update control ranges based on streaming mode
  * @ov9282: pointer to ov9282 device
@@ -551,7 +562,7 @@ static int ov9282_update_controls(struct ov9282 *ov9282,
  */
 static int ov9282_update_exp_gain(struct ov9282 *ov9282, u32 exposure, u32 gain)
 {
-	u32 exposure_us = ov9282_exposure_to_us(ov9282, exposure);
+	u32 exposure_us = ov9282_lines_to_us(ov9282, exposure);
 	int ret, ret_hold;
 
 	dev_dbg(ov9282->dev, "Set exp %u (~%u us), analog gain %u",
@@ -579,34 +590,6 @@ static int ov9282_update_exp_gain(struct ov9282 *ov9282, u32 exposure, u32 gain)
 	return ret ? ret : ret_hold;
 }
 
-static u32 ov9282_us_to_flash_duration(struct ov9282 *ov9282, u32 value)
-{
-	/*
-	 * Calculate "strobe_frame_span" increments from a given value (µs).
-	 * This is quite tricky as "The step width of shift and span is
-	 * programmable under system clock domain.", but it's not documented
-	 * how to program this step width (at least in the datasheet available
-	 * to the author at time of writing).
-	 * The formula below is interpolated from different modes/framerates
-	 * and should work quite well for most settings.
-	 */
-	u32 frame_width = ov9282->cur_mode->width + ov9282->hblank_ctrl->val;
-
-	return value * OV9282_STROBE_SPAN_FACTOR / frame_width;
-}
-
-static u32 ov9282_flash_duration_to_us(struct ov9282 *ov9282, u32 value)
-{
-	/*
-	 * Calculate back to microseconds from "strobe_frame_span" increments.
-	 * As the calculation in ov9282_us_to_flash_duration uses an integer
-	 * divison round up here.
-	 */
-	u32 frame_width = ov9282->cur_mode->width + ov9282->hblank_ctrl->val;
-
-	return DIV_ROUND_UP(value * frame_width, OV9282_STROBE_SPAN_FACTOR);
-}
-
 static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 {
 	struct ov9282 *ov9282 =
@@ -672,7 +655,7 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 		break;
 	case V4L2_CID_FLASH_DURATION:
 		ret = cci_write(ov9282->regmap, OV9282_REG_STROBE_FRAME_SPAN,
-				ov9282_us_to_flash_duration(ov9282, ctrl->val), NULL);
+				ov9282_us_to_lines(ov9282, ctrl->val), NULL);
 		break;
 	default:
 		dev_err(ov9282->dev, "Invalid control %d", ctrl->id);
@@ -691,11 +674,11 @@ static int ov9282_try_ctrl(struct v4l2_ctrl *ctrl)
 
 	if (ctrl->id == V4L2_CID_FLASH_DURATION) {
 		u32 us = ctrl->val;
-		u32 fd = ov9282_us_to_flash_duration(ov9282, us);
+		u32 fd = ov9282_us_to_lines(ov9282, us);
 
 		/* get nearest strobe_duration value */
-		u32 us0 = ov9282_flash_duration_to_us(ov9282, fd);
-		u32 us1 = ov9282_flash_duration_to_us(ov9282, fd + 1);
+		u32 us0 = ov9282_lines_to_us(ov9282, fd);
+		u32 us1 = ov9282_lines_to_us(ov9282, fd + 1);
 
 		if (abs(us1 - us) < abs(us - us0))
 			ctrl->val = us1;
@@ -1277,7 +1260,7 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops,
 			  V4L2_CID_FLASH_STROBE_OE, 0, 1, 1, 0);
 
-	exposure_us = ov9282_exposure_to_us(ov9282, OV9282_EXPOSURE_DEFAULT);
+	exposure_us = ov9282_lines_to_us(ov9282, OV9282_EXPOSURE_DEFAULT);
 	ov9282->flash_duration =
 		v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops,
 				  V4L2_CID_FLASH_DURATION, 0, exposure_us, 1,

-- 
2.53.0

