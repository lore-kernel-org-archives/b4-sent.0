From: Wenqiang Zhao <berringtoni36@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, Nuno =?utf-8?q?S=C3=A1?= <nuno.sa@analog.com>, Michael Hennerich <Michael.Hennerich@analog.com>
Cc: David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, linux@analog.com, linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org
Subject: [PATCH v2 RESEND] iio: accel: adxl345: update period cache after successful write
Date: Sun, 18 Oct 2026 21:42:00 +0800
Message-ID: <20261018-adxl345-period-cache-v2-resend-1@gmail.com>
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792330907; l=2895;
 i=berringtoni36@gmail.com; s=review-20261018; h=from:subject:message-id;
 bh=gzk/oV5DxvB5SYVBfqj3OWFCMqVZXw8MAoKLN74hP0E=;
 b=Mb2B/AFNc0QLKH07NYJvnlGaYS7HB1+5O8/qSTVwxi2BHmLjWSes3ii3rGw+VFP5siTpmfMl9
 dJtMUq5ujayB/0IjKUNid+XcFDN3juinVN/izAo10tdTHP5Qd3DYg8/
X-Developer-Key: i=berringtoni36@gmail.com; a=ed25519;
 pk=rRiAvRvS4MMqogNnloZgVnqWliVWNDq+PcP6vMYXOvs=
X-Endpoint-Received: by B4 Relay for berringtoni36@gmail.com/review-20261018 with auth_id=1226
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADXL345 event-period read path returns st->inact_time_ms. The setters
for inactivity, free-fall and the ODR-derived default currently update
this cache before writing TIME_INACT or TIME_FF. If the regmap write
fails, the sysfs write reports an error but a subsequent read returns
the requested period even though it was not programmed.

Update the cached period only after the corresponding regmap write
succeeds.

Fixes: 8a1536cc4a1c ("iio: accel: adxl345: add inactivity feature")
Fixes: f6f22950d925 ("iio: accel: adxl345: extend inactivity time for less than 1s")
Assisted-by: LLM
Signed-off-by: Wenqiang Zhao <berringtoni36@gmail.com>
---
Resend: unchanged code; submitted via b4 web submission to avoid delivery-time wrapping.

v2:
- Keep Fixes: tags on a single line (Nuno)
- Use a Latin-script name in From: and Signed-off-by: (Nuno)
- Drop the long validation notes; build-tested only, not tested on hardware

The missing serialization between concurrent sysfs callers that Nuno
pointed out is a separate issue and will be addressed in a follow-up
patch.

 drivers/iio/accel/adxl345_core.c | 27 ++++++++++++++++++++++-----
 1 file changed, 22 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/accel/adxl345_core.c b/drivers/iio/accel/adxl345_core.c
index 6c9080d..cd58304 100644
--- a/drivers/iio/accel/adxl345_core.c
+++ b/drivers/iio/accel/adxl345_core.c
@@ -391,30 +391,47 @@ static int adxl345_set_default_time(struct adxl345_state *st)
 	odr = FIELD_GET(ADXL345_BW_RATE_MSK, regval);
 	val = clamp(max_boundary - adxl345_odr_tbl[odr][0],
 		    min_boundary, max_boundary);
-	st->inact_time_ms = MILLI * val;
 
 	/* Inactivity time in s */
-	return regmap_write(st->regmap, ADXL345_REG_TIME_INACT, val);
+	ret = regmap_write(st->regmap, ADXL345_REG_TIME_INACT, val);
+	if (ret)
+		return ret;
+
+	st->inact_time_ms = MILLI * val;
+
+	return 0;
 }
 
 static int adxl345_set_inactivity_time(struct adxl345_state *st, u32 val_int)
 {
+	int ret;
+
+	ret = regmap_write(st->regmap, ADXL345_REG_TIME_INACT, val_int);
+	if (ret)
+		return ret;
+
 	st->inact_time_ms = MILLI * val_int;
 
-	return regmap_write(st->regmap, ADXL345_REG_TIME_INACT, val_int);
+	return 0;
 }
 
 static int adxl345_set_freefall_time(struct adxl345_state *st, u32 val_fract)
 {
+	int ret;
+
 	/*
 	 * Datasheet max. value is 255 * 5000 us = 1.275000 seconds.
 	 *
 	 * Recommended values between 100ms and 350ms (0x14 to 0x46)
 	 */
+	ret = regmap_write(st->regmap, ADXL345_REG_TIME_FF,
+			   DIV_ROUND_CLOSEST(val_fract, 5));
+	if (ret)
+		return ret;
+
 	st->inact_time_ms = DIV_ROUND_UP(val_fract, MILLI);
 
-	return regmap_write(st->regmap, ADXL345_REG_TIME_FF,
-			    DIV_ROUND_CLOSEST(val_fract, 5));
+	return 0;
 }
 
 /**

base-commit: 9ee8306121495d2a25aa5d1bfd519f2748786b83
-- 
2.50.1 (Apple Git-155)
