From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 14 Sep 2026 21:21:06 +0200
Subject: [PATCH 09/10] media: i2c: ov9282: fix flash duration control range
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-ov9282-fixes-v1-9-f520af59df1b@linux.dev>
References: <20260914-ov9282-fixes-v1-0-f520af59df1b@linux.dev>
In-Reply-To: <20260914-ov9282-fixes-v1-0-f520af59df1b@linux.dev>
To: Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Martina Krasteva <martinax.krasteva@intel.com>, 
 "Paul J. Murphy" <paul.j.murphy@intel.com>, 
 Daniele Alessandrelli <daniele.alessandrelli@gmail.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 Gyula Kelemen <gyula.kelemen@advasolutions.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789413683; l=4273;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=MgosDSepN/VAOdz00IAVr7J4q2hquqwEmAxEj3m5LkQ=;
 b=6J5T3TCPbUGlmQx6mf1lG2b/++XSje4gsjGhSx8QNPCYrmlUK9KfEYkp16qRB5+t3+Ax7BQDp
 reD6CCEB0v9BTnYvvJdjXdd2fk68YT3Cgu0kp+OMpVD68OY2kD3uL76
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When updating the flash_duration range ensure the ceiling is at least as
long as the exposure time is. This may cause the calculated
flash_duration register value to be rounded up.

This is done by introducing a new
ov9282_update_ctrl_range_flash_duration() function and using them
wherever possible.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 47 +++++++++++++++++++++++++++-------------------
 1 file changed, 28 insertions(+), 19 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index f728709fcf0a6..be38ecfad8c82 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -541,6 +541,29 @@ static u32 ov9282_flash_duration_to_us(struct ov9282 *ov9282, u32 value)
 				NSEC_PER_USEC);
 }
 
+/**
+ * ov9282_update_ctrl_range_flash_duration() - Update flash_duration control range
+ * @ov9282: pointer to ov9282 device
+ *
+ * This may round up the ceiling to the microseconds representation of the
+ * next flash_duration register value to make sure one can illuminate the whole
+ * exposure time long.
+ *
+ * Return: 0 if successful, error code otherwise.
+ */
+static int ov9282_update_ctrl_range_flash_duration(struct ov9282 *ov9282)
+{
+	u32 exposure_us = ov9282_exposure_to_us(ov9282, ov9282->exp_ctrl->val);
+	u32 fd_max = ov9282_us_to_flash_duration(ov9282, exposure_us);
+	u32 fd_max_us = ov9282_flash_duration_to_us(ov9282, fd_max);
+
+	if (fd_max_us < exposure_us)
+		fd_max_us = ov9282_flash_duration_to_us(ov9282, fd_max + 1);
+
+	return __v4l2_ctrl_modify_range(ov9282->flash_duration, 0, fd_max_us,
+					1, OV9282_STROBE_FRAME_SPAN_DEFAULT);
+}
+
 /**
  * ov9282_update_controls() - Update control ranges based on streaming mode
  * @ov9282: pointer to ov9282 device
@@ -555,7 +578,6 @@ static int ov9282_update_controls(struct ov9282 *ov9282,
 {
 	u32 hblank_min;
 	s64 pixel_rate;
-	u32 exposure_us;
 	u32 lpfr;
 	int ret;
 
@@ -590,9 +612,7 @@ static int ov9282_update_controls(struct ov9282 *ov9282,
 	if (ret)
 		return ret;
 
-	exposure_us = ov9282_exposure_to_us(ov9282, ov9282->exp_ctrl->val);
-	return __v4l2_ctrl_modify_range(ov9282->flash_duration, 0, exposure_us,
-					1, OV9282_STROBE_FRAME_SPAN_DEFAULT);
+	return ov9282_update_ctrl_range_flash_duration(ov9282);
 }
 
 /**
@@ -605,11 +625,9 @@ static int ov9282_update_controls(struct ov9282 *ov9282,
  */
 static int ov9282_update_exp_gain(struct ov9282 *ov9282, u32 exposure, u32 gain)
 {
-	u32 exposure_us = ov9282_exposure_to_us(ov9282, exposure);
 	int ret, ret_hold;
 
-	dev_dbg(ov9282->dev, "Set exp %u (~%u us), analog gain %u",
-		exposure, exposure_us, gain);
+	dev_dbg(ov9282->dev, "Set exp %u, analog gain %u", exposure, gain);
 
 	ret = cci_write(ov9282->regmap, OV9282_REG_HOLD, 0x01, NULL);
 	if (ret)
@@ -623,9 +641,7 @@ static int ov9282_update_exp_gain(struct ov9282 *ov9282, u32 exposure, u32 gain)
 	if (ret)
 		goto error_release_group_hold;
 
-	ret = __v4l2_ctrl_modify_range(ov9282->flash_duration,
-				       0, exposure_us, 1,
-				       OV9282_STROBE_FRAME_SPAN_DEFAULT);
+	ret = ov9282_update_ctrl_range_flash_duration(ov9282);
 
 error_release_group_hold:
 	ret_hold = cci_write(ov9282->regmap, OV9282_REG_HOLD, 0, NULL);
@@ -660,11 +676,7 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 		 * Ensure the flash duration range is also updated on powered
 		 * down sensors.
 		 */
-		ret = __v4l2_ctrl_modify_range(ov9282->flash_duration, 0,
-					       ov9282_exposure_to_us(ov9282,
-								     ctrl->val),
-					       1,
-					       OV9282_STROBE_FRAME_SPAN_DEFAULT);
+		ret = ov9282_update_ctrl_range_flash_duration(ov9282);
 		if (ret)
 			return ret;
 		break;
@@ -674,10 +686,7 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 		 * duration. Therefore recalculate the flash duration range
 		 * here.
 		 */
-		exposure = ov9282_exposure_to_us(ov9282, ov9282->exp_ctrl->val);
-		ret = __v4l2_ctrl_modify_range(ov9282->flash_duration, 0,
-					       exposure, 1,
-					       OV9282_STROBE_FRAME_SPAN_DEFAULT);
+		ret = ov9282_update_ctrl_range_flash_duration(ov9282);
 		if (ret)
 			return ret;
 		break;

-- 
2.53.0

