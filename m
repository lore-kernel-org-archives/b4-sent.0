From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Tue, 17 Nov 2026 07:11:02 +0000
Subject: [PATCH v2 2/2] iio: light: adux1020: return early on unsupported
 channel types
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-adux1020-guard-v2-2-89707fa070c9@gmail.com>
References: <20261117-adux1020-guard-v2-0-89707fa070c9@gmail.com>
In-Reply-To: <20261117-adux1020-guard-v2-0-89707fa070c9@gmail.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794899463; l=5018;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=Mb4JTj/5n+0Q7IBjaPH3v6RUZj2Y9BygVBPXXhkxAvI=;
 b=i2c0tLU/q3Y07UFEJ8eWf41SejLcLc4ifsRfevxra1gfuR6YGpRNnaBcOEhu7k6ZnC3NLGlXt
 RKZ/+hHeQDbCpUbwf9E2s8oN8uV7ycxQ/Hzh0kLejopOZ+wQkWB9t97
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that adux1020_read_raw() and adux1020_write_raw() can return
directly, check the channel type with an inverted condition and return
-EINVAL early instead of nesting the work in an inner switch or if
block. This removes one level of indentation and makes the two
functions consistent with each other.

While at it, drop the stray semicolon after the closing brace of
adux1020_read_raw().

No functional change intended.

Suggested-by: Jonathan Cameron <jic23@kernel.org>
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/iio/light/adux1020.c | 131 ++++++++++++++++++++-----------------------
 1 file changed, 61 insertions(+), 70 deletions(-)

diff --git a/drivers/iio/light/adux1020.c b/drivers/iio/light/adux1020.c
index b595faf4abc5..afb0798a2894 100644
--- a/drivers/iio/light/adux1020.c
+++ b/drivers/iio/light/adux1020.c
@@ -370,61 +370,56 @@ static int adux1020_read_raw(struct iio_dev *indio_dev,
 
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
-		switch (chan->type) {
-		case IIO_PROXIMITY:
-			ret = adux1020_set_mode(data, ADUX1020_MODE_PROX_I);
-			if (ret < 0)
-				return ret;
-
-			ret = adux1020_measure(data, ADUX1020_MODE_PROX_I, buf);
-			if (ret < 0)
-				return ret;
-
-			*val = buf[0];
-			return IIO_VAL_INT;
-		default:
+		if (chan->type != IIO_PROXIMITY)
 			return -EINVAL;
-		}
-	case IIO_CHAN_INFO_PROCESSED:
-		switch (chan->type) {
-		case IIO_CURRENT:
-			ret = regmap_read(data->regmap,
-					  ADUX1020_REG_LED_CURRENT, &regval);
-			if (ret < 0)
-				return ret;
 
-			regval = regval & ADUX1020_LED_CURRENT_MASK;
+		ret = adux1020_set_mode(data, ADUX1020_MODE_PROX_I);
+		if (ret < 0)
+			return ret;
+
+		ret = adux1020_measure(data, ADUX1020_MODE_PROX_I, buf);
+		if (ret < 0)
+			return ret;
 
-			*val = adux1020_led_currents[regval][0];
-			*val2 = adux1020_led_currents[regval][1];
+		*val = buf[0];
 
-			return IIO_VAL_INT_PLUS_MICRO;
-		default:
+		return IIO_VAL_INT;
+	case IIO_CHAN_INFO_PROCESSED:
+		if (chan->type != IIO_CURRENT)
 			return -EINVAL;
-		}
+
+		ret = regmap_read(data->regmap, ADUX1020_REG_LED_CURRENT,
+				  &regval);
+		if (ret < 0)
+			return ret;
+
+		regval = regval & ADUX1020_LED_CURRENT_MASK;
+
+		*val = adux1020_led_currents[regval][0];
+		*val2 = adux1020_led_currents[regval][1];
+
+		return IIO_VAL_INT_PLUS_MICRO;
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		switch (chan->type) {
-		case IIO_PROXIMITY:
-			ret = regmap_read(data->regmap, ADUX1020_REG_FREQUENCY,
-					  &regval);
-			if (ret < 0)
-				return ret;
-
-			regval = FIELD_GET(ADUX1020_PROX_FREQ_MASK, regval);
-			if (regval >= ARRAY_SIZE(adux1020_rates))
-				return -EINVAL;
-
-			*val = adux1020_rates[regval][0];
-			*val2 = adux1020_rates[regval][1];
-
-			return IIO_VAL_INT_PLUS_MICRO;
-		default:
+		if (chan->type != IIO_PROXIMITY)
 			return -EINVAL;
-		}
+
+		ret = regmap_read(data->regmap, ADUX1020_REG_FREQUENCY,
+				  &regval);
+		if (ret < 0)
+			return ret;
+
+		regval = FIELD_GET(ADUX1020_PROX_FREQ_MASK, regval);
+		if (regval >= ARRAY_SIZE(adux1020_rates))
+			return -EINVAL;
+
+		*val = adux1020_rates[regval][0];
+		*val2 = adux1020_rates[regval][1];
+
+		return IIO_VAL_INT_PLUS_MICRO;
 	default:
 		return -EINVAL;
 	}
-};
+}
 
 static inline int adux1020_find_index(const int array[][2], int count, int val,
 				      int val2)
@@ -449,37 +444,33 @@ static int adux1020_write_raw(struct iio_dev *indio_dev,
 
 	switch (mask) {
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		if (chan->type == IIO_PROXIMITY) {
-			i = adux1020_find_index(adux1020_rates,
-						ARRAY_SIZE(adux1020_rates),
-						val, val2);
-			if (i < 0)
-				return i;
-
-			return regmap_update_bits(data->regmap,
-						  ADUX1020_REG_FREQUENCY,
-						  ADUX1020_PROX_FREQ_MASK,
-						  ADUX1020_PROX_FREQ(i));
-		}
-		break;
+		if (chan->type != IIO_PROXIMITY)
+			return -EINVAL;
+
+		i = adux1020_find_index(adux1020_rates,
+					ARRAY_SIZE(adux1020_rates), val, val2);
+		if (i < 0)
+			return i;
+
+		return regmap_update_bits(data->regmap, ADUX1020_REG_FREQUENCY,
+					  ADUX1020_PROX_FREQ_MASK,
+					  ADUX1020_PROX_FREQ(i));
 	case IIO_CHAN_INFO_PROCESSED:
-		if (chan->type == IIO_CURRENT) {
-			i = adux1020_find_index(adux1020_led_currents,
+		if (chan->type != IIO_CURRENT)
+			return -EINVAL;
+
+		i = adux1020_find_index(adux1020_led_currents,
 					ARRAY_SIZE(adux1020_led_currents),
 					val, val2);
-			if (i < 0)
-				return i;
+		if (i < 0)
+			return i;
 
-			return regmap_update_bits(data->regmap,
-						  ADUX1020_REG_LED_CURRENT,
-						  ADUX1020_LED_CURRENT_MASK, i);
-		}
-		break;
+		return regmap_update_bits(data->regmap,
+					  ADUX1020_REG_LED_CURRENT,
+					  ADUX1020_LED_CURRENT_MASK, i);
 	default:
-		break;
+		return -EINVAL;
 	}
-
-	return -EINVAL;
 }
 
 static int adux1020_write_event_config(struct iio_dev *indio_dev,

-- 
2.56.0

