From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 12:04:09 +0200
Subject: [PATCH 4/7] iio: light: opt3001: move driver to guard(mutex)() use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-opt3001-cleanup-v1-4-f7879dc3455c@gmail.com>
References: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
In-Reply-To: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778493846; l=4899;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=XWsG3BHkkDBA7GXFpyBdwvkQTMljrbd6jqDNEGFJaN8=;
 b=8KSszUzy4a0H0dtNVqmPjBpJHSKzHegXar85FigjLhXDQ065uI99XwwNblwVLhNF4EwMkZH4q
 7dmwh9wYCbTDLaZ9PguZv+2ipglzIvONPkqrgSQbIzEa8CvUXKmD7nt
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move driver to use guard(mutex)() macro, to facilitate automatic
locking/unlocking of resources. This modernizes the driver and
improves code style.

While at it, remove unnecessary gotos and return variables.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 61 +++++++++++++--------------------------------
 1 file changed, 18 insertions(+), 43 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 4d9a17be04555aca368f7bc70a9d9a47fb5b279e..bdff785bcfa9744cd25d32c5d00d62a11dd9d866 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -10,6 +10,7 @@
 
 #include <linux/array_size.h>
 #include <linux/bits.h>
+#include <linux/cleanup.h>
 #include <linux/delay.h>
 #include <linux/dev_printk.h>
 #include <linux/errno.h>
@@ -478,7 +479,6 @@ static int opt3001_read_raw(struct iio_dev *iio,
 		long mask)
 {
 	struct opt3001 *opt = iio_priv(iio);
-	int ret;
 
 	if (opt->mode == OPT3001_CONFIGURATION_M_CONTINUOUS)
 		return -EBUSY;
@@ -486,23 +486,17 @@ static int opt3001_read_raw(struct iio_dev *iio,
 	if (chan->type != opt->chip_info->chan_type)
 		return -EINVAL;
 
-	mutex_lock(&opt->lock);
+	guard(mutex)(&opt->lock);
 
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
 	case IIO_CHAN_INFO_PROCESSED:
-		ret = opt3001_get_processed(opt, val, val2);
-		break;
+		return opt3001_get_processed(opt, val, val2);
 	case IIO_CHAN_INFO_INT_TIME:
-		ret = opt3001_get_int_time(opt, val, val2);
-		break;
+		return opt3001_get_int_time(opt, val, val2);
 	default:
-		ret = -EINVAL;
+		return -EINVAL;
 	}
-
-	mutex_unlock(&opt->lock);
-
-	return ret;
 }
 
 static int opt3001_write_raw(struct iio_dev *iio,
@@ -510,7 +504,6 @@ static int opt3001_write_raw(struct iio_dev *iio,
 		long mask)
 {
 	struct opt3001 *opt = iio_priv(iio);
-	int ret;
 
 	if (opt->mode == OPT3001_CONFIGURATION_M_CONTINUOUS)
 		return -EBUSY;
@@ -524,11 +517,9 @@ static int opt3001_write_raw(struct iio_dev *iio,
 	if (val != 0)
 		return -EINVAL;
 
-	mutex_lock(&opt->lock);
-	ret = opt3001_set_int_time(opt, val2);
-	mutex_unlock(&opt->lock);
+	guard(mutex)(&opt->lock);
 
-	return ret;
+	return opt3001_set_int_time(opt, val2);
 }
 
 static int opt3001_read_event_value(struct iio_dev *iio,
@@ -537,26 +528,21 @@ static int opt3001_read_event_value(struct iio_dev *iio,
 		int *val, int *val2)
 {
 	struct opt3001 *opt = iio_priv(iio);
-	int ret = IIO_VAL_INT_PLUS_MICRO;
 
-	mutex_lock(&opt->lock);
+	guard(mutex)(&opt->lock);
 
 	switch (dir) {
 	case IIO_EV_DIR_RISING:
 		opt3001_to_iio_ret(opt, opt->high_thresh_exp,
 				opt->high_thresh_mantissa, val, val2);
-		break;
+		return IIO_VAL_INT_PLUS_MICRO;
 	case IIO_EV_DIR_FALLING:
 		opt3001_to_iio_ret(opt, opt->low_thresh_exp,
 				opt->low_thresh_mantissa, val, val2);
-		break;
+		return IIO_VAL_INT_PLUS_MICRO;
 	default:
-		ret = -EINVAL;
+		return -EINVAL;
 	}
-
-	mutex_unlock(&opt->lock);
-
-	return ret;
 }
 
 static int opt3001_write_event_value(struct iio_dev *iio,
@@ -579,12 +565,12 @@ static int opt3001_write_event_value(struct iio_dev *iio,
 	if (val < 0)
 		return -EINVAL;
 
-	mutex_lock(&opt->lock);
+	guard(mutex)(&opt->lock);
 
 	ret = opt3001_find_scale(opt, val, val2, &exponent);
 	if (ret < 0) {
 		dev_err(opt->dev, "can't find scale for %d.%06u\n", val, val2);
-		goto err;
+		return ret;
 	}
 
 	whole = opt->chip_info->factor_whole;
@@ -607,18 +593,12 @@ static int opt3001_write_event_value(struct iio_dev *iio,
 		opt->low_thresh_exp = exponent;
 		break;
 	default:
-		ret = -EINVAL;
-		goto err;
+		return -EINVAL;
 	}
 
 	ret = i2c_smbus_write_word_swapped(opt->client, reg, value);
-	if (ret < 0) {
+	if (ret < 0)
 		dev_err(opt->dev, "failed to write register %02x\n", reg);
-		goto err;
-	}
-
-err:
-	mutex_unlock(&opt->lock);
 
 	return ret;
 }
@@ -647,7 +627,7 @@ static int opt3001_write_event_config(struct iio_dev *iio,
 	if (!state && opt->mode == OPT3001_CONFIGURATION_M_SHUTDOWN)
 		return 0;
 
-	mutex_lock(&opt->lock);
+	guard(mutex)(&opt->lock);
 
 	mode = state ? OPT3001_CONFIGURATION_M_CONTINUOUS
 		: OPT3001_CONFIGURATION_M_SHUTDOWN;
@@ -656,7 +636,7 @@ static int opt3001_write_event_config(struct iio_dev *iio,
 	if (ret < 0) {
 		dev_err(opt->dev, "failed to read register %02x\n",
 				OPT3001_CONFIGURATION);
-		goto err;
+		return ret;
 	}
 
 	reg = ret;
@@ -664,14 +644,9 @@ static int opt3001_write_event_config(struct iio_dev *iio,
 
 	ret = i2c_smbus_write_word_swapped(opt->client, OPT3001_CONFIGURATION,
 			reg);
-	if (ret < 0) {
+	if (ret < 0)
 		dev_err(opt->dev, "failed to write register %02x\n",
 				OPT3001_CONFIGURATION);
-		goto err;
-	}
-
-err:
-	mutex_unlock(&opt->lock);
 
 	return ret;
 }

-- 
2.47.3

