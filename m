From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Wed, 18 Nov 2026 07:29:54 +0000
Subject: [PATCH v3 1/2] iio: light: adux1020: use guard() to simplify lock
 handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-adux1020-guard-v3-1-2c6a18954fc7@gmail.com>
References: <20261118-adux1020-guard-v3-0-2c6a18954fc7@gmail.com>
In-Reply-To: <20261118-adux1020-guard-v3-0-2c6a18954fc7@gmail.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>, 
 Joshua Crofts <crofts@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794986997; l=6315;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=DMtHrOaeoSbk69l93gv+SBOwCJ/sq3BfFEE9UbzKpVM=;
 b=fEXS8coQDCkDBlpSSLJkLT1MpCdBCZyfdktBYJRrZ1oXuDMfUB6XPy27wYJxxW55Owokn1FPd
 f+pyeGHhXGmDUR6KylinD9g8mTcaNlC1GEkUR438ZfS1LdQwCHxkZbI
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use guard(mutex) in adux1020_read_raw(), adux1020_write_raw() and
adux1020_write_event_config() so the lock is released automatically on
return. This allows returning directly instead of jumping to a common
unlock label, and lets adux1020_write_raw() drop its ret variable.

No functional change intended.

Suggested-by: Jonathan Cameron <jic23@kernel.org>
Reviewed-by: Joshua Crofts <crofts@kernel.org>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/iio/light/adux1020.c | 104 ++++++++++++++++---------------------------
 1 file changed, 39 insertions(+), 65 deletions(-)

diff --git a/drivers/iio/light/adux1020.c b/drivers/iio/light/adux1020.c
index 6b32c5be4753..b595faf4abc5 100644
--- a/drivers/iio/light/adux1020.c
+++ b/drivers/iio/light/adux1020.c
@@ -9,6 +9,7 @@
  */
 
 #include <linux/bitfield.h>
+#include <linux/cleanup.h>
 #include <linux/delay.h>
 #include <linux/err.h>
 #include <linux/i2c.h>
@@ -362,10 +363,10 @@ static int adux1020_read_raw(struct iio_dev *indio_dev,
 {
 	struct adux1020_data *data = iio_priv(indio_dev);
 	u16 buf[3];
-	int ret = -EINVAL;
 	unsigned int regval;
+	int ret;
 
-	mutex_lock(&data->lock);
+	guard(mutex)(&data->lock);
 
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
@@ -373,69 +374,56 @@ static int adux1020_read_raw(struct iio_dev *indio_dev,
 		case IIO_PROXIMITY:
 			ret = adux1020_set_mode(data, ADUX1020_MODE_PROX_I);
 			if (ret < 0)
-				goto fail;
+				return ret;
 
 			ret = adux1020_measure(data, ADUX1020_MODE_PROX_I, buf);
 			if (ret < 0)
-				goto fail;
+				return ret;
 
 			*val = buf[0];
-			ret = IIO_VAL_INT;
-			break;
+			return IIO_VAL_INT;
 		default:
-			break;
+			return -EINVAL;
 		}
-		break;
 	case IIO_CHAN_INFO_PROCESSED:
 		switch (chan->type) {
 		case IIO_CURRENT:
 			ret = regmap_read(data->regmap,
 					  ADUX1020_REG_LED_CURRENT, &regval);
 			if (ret < 0)
-				goto fail;
+				return ret;
 
 			regval = regval & ADUX1020_LED_CURRENT_MASK;
 
 			*val = adux1020_led_currents[regval][0];
 			*val2 = adux1020_led_currents[regval][1];
 
-			ret = IIO_VAL_INT_PLUS_MICRO;
-			break;
+			return IIO_VAL_INT_PLUS_MICRO;
 		default:
-			break;
+			return -EINVAL;
 		}
-		break;
 	case IIO_CHAN_INFO_SAMP_FREQ:
 		switch (chan->type) {
 		case IIO_PROXIMITY:
 			ret = regmap_read(data->regmap, ADUX1020_REG_FREQUENCY,
 					  &regval);
 			if (ret < 0)
-				goto fail;
+				return ret;
 
 			regval = FIELD_GET(ADUX1020_PROX_FREQ_MASK, regval);
-			if (regval >= ARRAY_SIZE(adux1020_rates)) {
-				ret = -EINVAL;
-				goto fail;
-			}
+			if (regval >= ARRAY_SIZE(adux1020_rates))
+				return -EINVAL;
 
 			*val = adux1020_rates[regval][0];
 			*val2 = adux1020_rates[regval][1];
 
-			ret = IIO_VAL_INT_PLUS_MICRO;
-			break;
+			return IIO_VAL_INT_PLUS_MICRO;
 		default:
-			break;
+			return -EINVAL;
 		}
-		break;
 	default:
-		break;
+		return -EINVAL;
 	}
-
-fail:
-	mutex_unlock(&data->lock);
-
-	return ret;
 };
 
 static inline int adux1020_find_index(const int array[][2], int count, int val,
@@ -455,9 +443,9 @@ static int adux1020_write_raw(struct iio_dev *indio_dev,
 			      int val, int val2, long mask)
 {
 	struct adux1020_data *data = iio_priv(indio_dev);
-	int i, ret = -EINVAL;
+	int i;
 
-	mutex_lock(&data->lock);
+	guard(mutex)(&data->lock);
 
 	switch (mask) {
 	case IIO_CHAN_INFO_SAMP_FREQ:
@@ -465,15 +453,13 @@ static int adux1020_write_raw(struct iio_dev *indio_dev,
 			i = adux1020_find_index(adux1020_rates,
 						ARRAY_SIZE(adux1020_rates),
 						val, val2);
-			if (i < 0) {
-				ret = i;
-				goto fail;
-			}
-
-			ret = regmap_update_bits(data->regmap,
-						 ADUX1020_REG_FREQUENCY,
-						 ADUX1020_PROX_FREQ_MASK,
-						 ADUX1020_PROX_FREQ(i));
+			if (i < 0)
+				return i;
+
+			return regmap_update_bits(data->regmap,
+						  ADUX1020_REG_FREQUENCY,
+						  ADUX1020_PROX_FREQ_MASK,
+						  ADUX1020_PROX_FREQ(i));
 		}
 		break;
 	case IIO_CHAN_INFO_PROCESSED:
@@ -481,24 +467,19 @@ static int adux1020_write_raw(struct iio_dev *indio_dev,
 			i = adux1020_find_index(adux1020_led_currents,
 					ARRAY_SIZE(adux1020_led_currents),
 					val, val2);
-			if (i < 0) {
-				ret = i;
-				goto fail;
-			}
-
-			ret = regmap_update_bits(data->regmap,
-						 ADUX1020_REG_LED_CURRENT,
-						 ADUX1020_LED_CURRENT_MASK, i);
+			if (i < 0)
+				return i;
+
+			return regmap_update_bits(data->regmap,
+						  ADUX1020_REG_LED_CURRENT,
+						  ADUX1020_LED_CURRENT_MASK, i);
 		}
 		break;
 	default:
 		break;
 	}
 
-fail:
-	mutex_unlock(&data->lock);
-
-	return ret;
+	return -EINVAL;
 }
 
 static int adux1020_write_event_config(struct iio_dev *indio_dev,
@@ -510,16 +491,16 @@ static int adux1020_write_event_config(struct iio_dev *indio_dev,
 	struct adux1020_data *data = iio_priv(indio_dev);
 	int ret, mask;
 
-	mutex_lock(&data->lock);
+	guard(mutex)(&data->lock);
 
 	ret = regmap_write(data->regmap, ADUX1020_REG_INT_ENABLE,
 			   ADUX1020_INT_ENABLE);
 	if (ret < 0)
-		goto fail;
+		return ret;
 
 	ret = regmap_write(data->regmap, ADUX1020_REG_INT_POLARITY, 0);
 	if (ret < 0)
-		goto fail;
+		return ret;
 
 	switch (chan->type) {
 	case IIO_PROXIMITY:
@@ -535,7 +516,7 @@ static int adux1020_write_event_config(struct iio_dev *indio_dev,
 			ret = regmap_set_bits(data->regmap,
 					      ADUX1020_REG_INT_MASK, mask);
 		if (ret < 0)
-			goto fail;
+			return ret;
 
 		/*
 		 * Trigger proximity interrupt when the intensity is above
@@ -544,20 +525,13 @@ static int adux1020_write_event_config(struct iio_dev *indio_dev,
 		ret = regmap_set_bits(data->regmap, ADUX1020_REG_PROX_TYPE,
 				      ADUX1020_PROX_TYPE);
 		if (ret < 0)
-			goto fail;
+			return ret;
 
 		/* Set proximity mode */
-		ret = adux1020_set_mode(data, ADUX1020_MODE_PROX_I);
-		break;
+		return adux1020_set_mode(data, ADUX1020_MODE_PROX_I);
 	default:
-		ret = -EINVAL;
-		break;
+		return -EINVAL;
 	}
-
-fail:
-	mutex_unlock(&data->lock);
-
-	return ret;
 }
 
 static int adux1020_read_event_config(struct iio_dev *indio_dev,

-- 
2.56.0

