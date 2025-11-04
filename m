From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 15:35:14 +0000
Subject: [PATCH v4 09/12] iio: dac: ad5446: Make use of the cleanup helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-dev-add-ad5542-v4-9-6fe35458bf8c@analog.com>
References: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
In-Reply-To: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762270508; l=2674;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=P6Q56RZLd4vphT9+7rmQ2/k6u0FMBB1x8oEsC8XLutE=;
 b=f22ZGkjQO8NVFBqBN0ycu/YMKvP9ulzJd0EKiMKVdz5wg1v9p9IrkVDnpLc8fcaISULlSGxZb
 HkTq4LG1sOdCgKBxRgrZ9Y/swp6x6B6/sKwbBCbFRZgdswX8WZTMhdf
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the auto unlocking helpers from cleanup.h. Allows for some code
simplification.

While at it, don't use the ternary operator in
ad5446_write_dac_powerdown() and add an helper function to write the DAC
code. The reason for the function was purely to avoid having to use
unreachable().

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 45 ++++++++++++++++++++++++++-------------------
 1 file changed, 26 insertions(+), 19 deletions(-)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index 59e1f67ef334..1943e8014990 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -5,6 +5,7 @@
  * Copyright 2010 Analog Devices Inc.
  */
 
+#include <linux/cleanup.h>
 #include <linux/export.h>
 #include <linux/interrupt.h>
 #include <linux/workqueue.h>
@@ -80,7 +81,7 @@ static ssize_t ad5446_write_dac_powerdown(struct iio_dev *indio_dev,
 	if (ret)
 		return ret;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 	st->pwr_down = powerdown;
 
 	if (st->pwr_down) {
@@ -91,9 +92,10 @@ static ssize_t ad5446_write_dac_powerdown(struct iio_dev *indio_dev,
 	}
 
 	ret = st->chip_info->write(st, val);
-	mutex_unlock(&st->lock);
+	if (ret)
+		return ret;
 
-	return ret ? ret : len;
+	return len;
 }
 
 const struct iio_chan_spec_ext_info ad5446_ext_info_powerdown[] = {
@@ -129,32 +131,37 @@ static int ad5446_read_raw(struct iio_dev *indio_dev,
 	return -EINVAL;
 }
 
+static int ad5446_write_dac_raw(struct iio_dev *indio_dev,
+				const struct iio_chan_spec *chan,
+				int val)
+{
+	struct ad5446_state *st = iio_priv(indio_dev);
+
+	if (val >= (1 << chan->scan_type.realbits) || val < 0)
+		return -EINVAL;
+
+	val <<= chan->scan_type.shift;
+	guard(mutex)(&st->lock);
+
+	st->cached_val = val;
+	if (st->pwr_down)
+		return 0;
+
+	return st->chip_info->write(st, val);
+}
+
 static int ad5446_write_raw(struct iio_dev *indio_dev,
 			       struct iio_chan_spec const *chan,
 			       int val,
 			       int val2,
 			       long mask)
 {
-	struct ad5446_state *st = iio_priv(indio_dev);
-	int ret = 0;
-
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
-		if (val >= (1 << chan->scan_type.realbits) || val < 0)
-			return -EINVAL;
-
-		val <<= chan->scan_type.shift;
-		mutex_lock(&st->lock);
-		st->cached_val = val;
-		if (!st->pwr_down)
-			ret = st->chip_info->write(st, val);
-		mutex_unlock(&st->lock);
-		break;
+		return ad5446_write_dac_raw(indio_dev, chan, val);
 	default:
-		ret = -EINVAL;
+		return -EINVAL;
 	}
-
-	return ret;
 }
 
 static const struct iio_info ad5446_info = {

-- 
2.51.0

