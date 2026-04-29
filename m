From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 29 Apr 2026 14:07:40 +0100
Subject: [PATCH v4 10/13] iio: dac: ad5686: remove powerdown mask magic
 number
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-ad5686-fixes-v4-10-bb8f1cbd68e1@analog.com>
References: <20260429-ad5686-fixes-v4-0-bb8f1cbd68e1@analog.com>
In-Reply-To: <20260429-ad5686-fixes-v4-0-bb8f1cbd68e1@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Stefan Popa <stefan.popa@analog.com>, Jonathan Cameron <jic23@cam.ac.uk>, 
 Greg Kroah-Hartman <gregkh@suse.de>, 
 Michael Auchter <michael.auchter@ni.com>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777468056; l=2952;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=x+f5X9G+QgQmbzFHF+5ueLvHY+KAC7dvWbfcoQHYU34=;
 b=X2uVsE4M/sgiAOEaPE2oy3tNs+ey1gwQCHd2/J4JwZu3egSDguRYLm7Ok+A6/Kr4YVErYcQD8
 ZYhNTC83U81A7ZC8dH0fTfHk7eyABP16PBLY8AGPZxcyNxSE5KzeqF8
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Define macro AD5686_PD_MSK to hold powerdown mask value.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 16 ++++++++--------
 drivers/iio/dac/ad5686.h |  1 +
 2 files changed, 9 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 4bcabdbaf1d8..0590716191c1 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -39,7 +39,7 @@ static int ad5686_get_powerdown_mode(struct iio_dev *indio_dev,
 	unsigned int shift = ad5686_pd_mask_shift(chan);
 	struct ad5686_state *st = iio_priv(indio_dev);
 
-	return ((st->pwr_down_mode >> shift) & 0x3) - 1;
+	return ((st->pwr_down_mode >> shift) & AD5686_PD_MSK) - 1;
 }
 
 static int ad5686_set_powerdown_mode(struct iio_dev *indio_dev,
@@ -51,8 +51,8 @@ static int ad5686_set_powerdown_mode(struct iio_dev *indio_dev,
 
 	guard(mutex)(&st->lock);
 
-	st->pwr_down_mode &= ~(0x3 << shift);
-	st->pwr_down_mode |= (mode + 1) << shift;
+	st->pwr_down_mode &= ~(AD5686_PD_MSK << shift);
+	st->pwr_down_mode |= ((mode + 1) & AD5686_PD_MSK) << shift;
 
 	return 0;
 }
@@ -70,7 +70,7 @@ static ssize_t ad5686_read_dac_powerdown(struct iio_dev *indio_dev,
 	unsigned int shift = ad5686_pd_mask_shift(chan);
 	struct ad5686_state *st = iio_priv(indio_dev);
 
-	return sysfs_emit(buf, "%d\n", !!(st->pwr_down_mask & (0x3 << shift)));
+	return sysfs_emit(buf, "%d\n", !!(st->pwr_down_mask & (AD5686_PD_MSK << shift)));
 }
 
 static ssize_t ad5686_write_dac_powerdown(struct iio_dev *indio_dev,
@@ -92,9 +92,9 @@ static ssize_t ad5686_write_dac_powerdown(struct iio_dev *indio_dev,
 	guard(mutex)(&st->lock);
 
 	if (readin)
-		st->pwr_down_mask |= 0x3 << ad5686_pd_mask_shift(chan);
+		st->pwr_down_mask |= AD5686_PD_MSK << ad5686_pd_mask_shift(chan);
 	else
-		st->pwr_down_mask &= ~(0x3 << ad5686_pd_mask_shift(chan));
+		st->pwr_down_mask &= ~(AD5686_PD_MSK << ad5686_pd_mask_shift(chan));
 
 	switch (st->chip_info->regmap_type) {
 	case AD5310_REGMAP:
@@ -468,8 +468,8 @@ int ad5686_probe(struct device *dev,
 	/* Set all the power down mode for all channels to 1K pulldown */
 	for (i = 0; i < st->chip_info->num_channels; i++) {
 		shift = ad5686_pd_mask_shift(&st->chip_info->channels[i]);
-		st->pwr_down_mask &= ~(0x3 << shift); /* powered up state */
-		st->pwr_down_mode &= ~(0x3 << shift);
+		st->pwr_down_mask &= ~(AD5686_PD_MSK << shift); /* powered up state */
+		st->pwr_down_mode &= ~(AD5686_PD_MSK << shift);
 		st->pwr_down_mode |= 0x01 << shift;
 	}
 
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index caadc7403da1..b9eee3ad4dc8 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -47,6 +47,7 @@
 #define AD5683_REF_BIT_MSK			BIT(12)
 #define AD5686_REF_BIT_MSK			BIT(0)
 
+#define AD5686_PD_MSK				GENMASK(1, 0)
 
 enum ad5686_regmap_type {
 	AD5310_REGMAP,

-- 
2.43.0

