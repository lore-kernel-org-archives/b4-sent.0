From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 14 Sep 2026 21:21:00 +0200
Subject: [PATCH 03/10] media: i2c: ov9282: fix flash duration to/from
 microseconds conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260914-ov9282-fixes-v1-3-f520af59df1b@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789413683; l=4054;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=wRsep6ftLnvl73/k/AgvdYj/Y1swLSJ+eRnAI9/2x1I=;
 b=5Q4lEYS24T3+vl53pFRvnHP9QQtLJFP4hJgNQgkoaooxsyUXLuBl1vaZAuoadYV02Kh5ersKK
 dUq7uTxrWi1C+r6GtD25ChEzASB7SgjXA4df+mPV8rA5Ui4Twzm5n1x
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently the flash duration is converted to/from microseconds using a
fixed OV9282_STROBE_SPAN_FACTOR constant. This is inaccurate as it was
found that the "step width of shift and span" (which is not documented
further in the datasheet) scales with the line, so the span is counted
in lines.

Fix the conversion by dropping the constant factor and using the
previously introduced ov9282_line_time_ns() helper instead.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 66 +++++++++++++++++++++++++---------------------
 1 file changed, 36 insertions(+), 30 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index 3f83a6cf338d8..90a0fe542ce4a 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -133,8 +133,6 @@
 #define OV9282_REG_MIN		0x00
 #define OV9282_REG_MAX		0xfffff
 
-#define OV9282_STROBE_SPAN_FACTOR	192
-
 static const char * const ov9282_supply_names[] = {
 	"avdd",		/* Analog power */
 	"dovdd",	/* Digital I/O power */
@@ -509,6 +507,42 @@ static u32 ov9282_exposure_to_us(struct ov9282 *ov9282, u32 exposure)
 		       NSEC_PER_USEC);
 }
 
+/**
+ * ov9282_us_to_flash_duration() - Convert µs to flash duration register value
+ * @ov9282: pointer to ov9282 device
+ * @value: microseconds value to convert
+ *
+ * Calculate "strobe_frame_span" increments from a given value (µs). According
+ * to the datasheet "The step width of shift and span is programmable under
+ * system clock domain.", but this is not documented further. Nonetheless the
+ * step width was found empirically to scale with the line length, so the span
+ * is counted in lines.
+ *
+ * Return: flash duration register value
+ */
+static u32 ov9282_us_to_flash_duration(struct ov9282 *ov9282, u32 value)
+{
+	return div_u64((u64)value * NSEC_PER_USEC, ov9282_line_time_ns(ov9282));
+}
+
+/**
+ * ov9282_flash_duration_to_us() - Convert flash duration register value to µs
+ * @ov9282: pointer to ov9282 device
+ * @value: flash duration register value to convert
+ *
+ * Convert a given "strobe_frame_span" increment value to microseconds. For an
+ * explanation regarding conversion factor see the documentation of
+ * ov9282_us_to_flash_duration. As the calculation there uses an integer
+ * division round up here.
+ *
+ * Return: microseconds
+ */
+static u32 ov9282_flash_duration_to_us(struct ov9282 *ov9282, u32 value)
+{
+	return DIV_ROUND_UP_ULL((u64)value * ov9282_line_time_ns(ov9282),
+				NSEC_PER_USEC);
+}
+
 /**
  * ov9282_update_controls() - Update control ranges based on streaming mode
  * @ov9282: pointer to ov9282 device
@@ -585,34 +619,6 @@ static int ov9282_update_exp_gain(struct ov9282 *ov9282, u32 exposure, u32 gain)
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

-- 
2.53.0

