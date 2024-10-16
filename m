From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 16 Oct 2024 16:22:01 +0200
Subject: [PATCH 3/3] iio: addac: ad74413r: simplify with cleanup.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241016-dev-ad74413r-minor-improv-v1-3-13c9c769237d@analog.com>
References: <20241016-dev-ad74413r-minor-improv-v1-0-13c9c769237d@analog.com>
In-Reply-To: <20241016-dev-ad74413r-minor-improv-v1-0-13c9c769237d@analog.com>
To: linux-iio@vger.kernel.org
Cc: Cosmin Tanislav <cosmin.tanislav@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729088521; l=3081;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=fSsvW/amVn55Zii+damJ6Q75Aec5l4o8BgF4z/jzw4k=;
 b=rT8vdmqfQoH1Cf9MlwNFOiXKSZlPayhyO2TcM1OmRJpYfVtawRSGu5vntKSAxpramZfNuPyL1
 0EfIwKzS+FxAcBx4CC5ejw6LXUbky+nZ7R6bXLUG/IAsT0HSC5rbBU1
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of mutex guard() and IIO iio_device_claim_direct_scoped() to
simplify code and error handling.

While at it, use devm_mutex_init() to initialize the mutex.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/addac/ad74413r.c | 37 +++++++++++++++----------------------
 1 file changed, 15 insertions(+), 22 deletions(-)

diff --git a/drivers/iio/addac/ad74413r.c b/drivers/iio/addac/ad74413r.c
index cfe26a394465..daea2bde7acf 100644
--- a/drivers/iio/addac/ad74413r.c
+++ b/drivers/iio/addac/ad74413r.c
@@ -6,6 +6,7 @@
 
 #include <linux/unaligned.h>
 #include <linux/bitfield.h>
+#include <linux/cleanup.h>
 #include <linux/crc8.h>
 #include <linux/device.h>
 #include <linux/err.h>
@@ -864,19 +865,12 @@ static int ad74413r_get_single_adc_result(struct iio_dev *indio_dev,
 					  unsigned int channel, int *val)
 {
 	struct ad74413r_state *st = iio_priv(indio_dev);
-	int ret;
 
-	ret = iio_device_claim_direct_mode(indio_dev);
-	if (ret)
-		return ret;
-
-	mutex_lock(&st->lock);
-	ret = _ad74413r_get_single_adc_result(st, channel, val);
-	mutex_unlock(&st->lock);
-
-	iio_device_release_direct_mode(indio_dev);
-
-	return ret;
+	iio_device_claim_direct_scoped(return -EBUSY, indio_dev) {
+		guard(mutex)(&st->lock);
+		return _ad74413r_get_single_adc_result(st, channel, val);
+	}
+	unreachable();
 }
 
 static void ad74413r_adc_to_resistance_result(int adc_result, int *val)
@@ -898,7 +892,7 @@ static int ad74413r_update_scan_mode(struct iio_dev *indio_dev,
 	unsigned int channel;
 	int ret = -EINVAL;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 
 	spi_message_init(&st->adc_samples_msg);
 	st->adc_active_channels = 0;
@@ -906,11 +900,11 @@ static int ad74413r_update_scan_mode(struct iio_dev *indio_dev,
 	for_each_clear_bit(channel, active_scan_mask, AD74413R_CHANNEL_MAX) {
 		ret = ad74413r_set_adc_channel_enable(st, channel, false);
 		if (ret)
-			goto out;
+			return ret;
 	}
 
 	if (*active_scan_mask == 0)
-		goto out;
+		return ret;
 
 	/*
 	 * The read select register is used to select which register's value
@@ -928,7 +922,7 @@ static int ad74413r_update_scan_mode(struct iio_dev *indio_dev,
 	for_each_set_bit(channel, active_scan_mask, AD74413R_CHANNEL_MAX) {
 		ret = ad74413r_set_adc_channel_enable(st, channel, true);
 		if (ret)
-			goto out;
+			return ret;
 
 		st->adc_active_channels++;
 
@@ -959,11 +953,7 @@ static int ad74413r_update_scan_mode(struct iio_dev *indio_dev,
 	xfer->cs_change = 0;
 
 	spi_message_add_tail(xfer, &st->adc_samples_msg);
-
-out:
-	mutex_unlock(&st->lock);
-
-	return ret;
+	return 0;
 }
 
 static int ad74413r_buffer_postenable(struct iio_dev *indio_dev)
@@ -1368,7 +1358,10 @@ static int ad74413r_probe(struct spi_device *spi)
 	if (!st->chip_info)
 		return -EINVAL;
 
-	mutex_init(&st->lock);
+	ret = devm_mutex_init(st->dev, &st->lock);
+	if (ret)
+		return ret;
+
 	init_completion(&st->adc_data_completion);
 
 	st->regmap = devm_regmap_init(st->dev, NULL, st,

-- 
2.46.1

