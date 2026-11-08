From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Sun, 08 Nov 2026 20:16:13 +0000
Subject: [PATCH] iio: light: adux1020: use guard() to simplify lock
 handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-adux1020-guard-v1-1-db9c582f1eea@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ7CIBBA4as0sy7J8BPFXqVxgTDiuMAGimlCu
 Luoy2/xXoNCmanAMjXI9ObCrzQg5wn8w6VIgsMwKFQnKdEKF+ohUaGI1eUgtFXo6Xwx1mgY0Zb
 pzsdvuF7/LvX2JL9/L9D7B8SmqstyAAAA
X-Change-ID: 20261108-adux1020-guard-3820ce794843
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794168974; l=6978;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=55DgnX1l0P6Wx7Y7PSWErzxISKBLMVyhkL//RtenSVw=;
 b=x3obLC4cZbut96blzDpJjPH6a2VtoPWL4w5PhctkC17cNEMyYBQ10YX1bzOLC3VbljvLQyLYU
 NkhkLMIVm9xANai0c+R/QV84E50MuWQtdN2fCQTDtH4PKoqvw6tR10M
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
Link: https://lore.kernel.org/all/20261107222957.5332237b@jic23-hlaptop/
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
This follows Jonathan's suggestion, made when applying the sampling
frequency hardening patch. It applies on top of iio/testing.

Tested on arm64 QEMU with i2c-stub and lockdep enabled: reading and
writing the sampling frequency (valid and invalid values), reading the
LED current, reading in_proximity_raw (error path) and enabling the
threshold event. No lockdep warnings and no hangs after the error
paths.

I prepared this patch with the help of an AI coding assistant, and
reviewed and tested it myself.
---
 drivers/iio/light/adux1020.c | 104 ++++++++++++++++---------------------------
 1 file changed, 39 insertions(+), 65 deletions(-)

diff --git a/drivers/iio/light/adux1020.c b/drivers/iio/light/adux1020.c
index d4281b9754c3..3e8f53e5a1a0 100644
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
+	int ret;
 	unsigned int regval;
 
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

---
base-commit: ee79148f1586fb0a6d6918995cfc84da6feb35da
change-id: 20261108-adux1020-guard-3820ce794843

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

