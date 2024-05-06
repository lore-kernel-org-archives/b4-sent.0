From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 06 May 2024 16:55:37 +0200
Subject: [PATCH] iio: adc: ad9467: use DMA safe buffer for spi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240506-dev-ad9467-dma-v1-1-e5c31b464e8f@analog.com>
X-B4-Tracking: v=1; b=H4sIAGjvOGYC/x3MTQqAIBBA4avErBtQM6WuEi2kGWsW/aAQgXT3p
 OW3eK9A5iScYWwKJL4ly3lU6LaBZQvHyihUDUYZq3rlkPjGQIN1HmkP2GltI5Hxi45QoytxlOc
 fTvP7fsxiP/hgAAAA
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715007341; l=7669;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=yjQ9Kl1CO2VbhiML81IVUgm28c6D981/Lxk8Db/pIek=;
 b=qnSAAgMAnAPS5lkFzcc2IX6M8ZZvFlEJtAe2Uqv6bWp8Idqblkte1+MymrdLbxNBytaQArBAT
 KuMHwbL1cwGBPoECCkVfFPSpF6XUwnmzfU3HFpGS0XH0xjoxB0nHS8e
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure we use a DMA safe buffer (IIO_DMA_MINALIGN) for all the spi
transfers.

Note that as we noe use a shared buffer, lock guards had to be added
accordingly.

Fixes: ad6797120238 ("iio: adc: ad9467: add support AD9467 ADC")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 87 ++++++++++++++++++++++++------------------------
 1 file changed, 44 insertions(+), 43 deletions(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index e85b763b9ffcb..368546b032891 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -141,55 +141,55 @@ struct ad9467_state {
 	struct gpio_desc		*pwrdown_gpio;
 	/* ensure consistent state obtained on multiple related accesses */
 	struct mutex			lock;
+	union {
+		u8 buf[3];
+		u8 tbuf[2];
+		u8 rbuf[1];
+	} __aligned(IIO_DMA_MINALIGN);
 };
 
-static int ad9467_spi_read(struct spi_device *spi, unsigned int reg)
+static int ad9467_spi_read(struct ad9467_state *st, unsigned int reg)
 {
-	unsigned char tbuf[2], rbuf[1];
 	int ret;
 
-	tbuf[0] = 0x80 | (reg >> 8);
-	tbuf[1] = reg & 0xFF;
+	st->tbuf[0] = 0x80 | (reg >> 8);
+	st->tbuf[1] = reg & 0xFF;
 
-	ret = spi_write_then_read(spi,
-				  tbuf, ARRAY_SIZE(tbuf),
-				  rbuf, ARRAY_SIZE(rbuf));
+	ret = spi_write_then_read(st->spi, st->tbuf, ARRAY_SIZE(st->tbuf),
+				  st->rbuf, ARRAY_SIZE(st->rbuf));
 
 	if (ret < 0)
 		return ret;
 
-	return rbuf[0];
+	return st->rbuf[0];
 }
 
-static int ad9467_spi_write(struct spi_device *spi, unsigned int reg,
+static int ad9467_spi_write(struct ad9467_state *st, unsigned int reg,
 			    unsigned int val)
 {
-	unsigned char buf[3];
+	st->buf[0] = reg >> 8;
+	st->buf[1] = reg & 0xFF;
+	st->buf[2] = val;
 
-	buf[0] = reg >> 8;
-	buf[1] = reg & 0xFF;
-	buf[2] = val;
-
-	return spi_write(spi, buf, ARRAY_SIZE(buf));
+	return spi_write(st->spi, st->buf, ARRAY_SIZE(st->buf));
 }
 
 static int ad9467_reg_access(struct iio_dev *indio_dev, unsigned int reg,
 			     unsigned int writeval, unsigned int *readval)
 {
 	struct ad9467_state *st = iio_priv(indio_dev);
-	struct spi_device *spi = st->spi;
 	int ret;
 
+	guard(mutex)(&st->lock);
 	if (!readval) {
-		guard(mutex)(&st->lock);
-		ret = ad9467_spi_write(spi, reg, writeval);
+		ret = ad9467_spi_write(st, reg, writeval);
 		if (ret)
 			return ret;
-		return ad9467_spi_write(spi, AN877_ADC_REG_TRANSFER,
+		return ad9467_spi_write(st, AN877_ADC_REG_TRANSFER,
 					AN877_ADC_TRANSFER_SYNC);
 	}
 
-	ret = ad9467_spi_read(spi, reg);
+	ret = ad9467_spi_read(st, reg);
 	if (ret < 0)
 		return ret;
 	*readval = ret;
@@ -295,9 +295,11 @@ static int ad9467_get_scale(struct ad9467_state *st, int *val, int *val2)
 	unsigned int i, vref_val;
 	int ret;
 
-	ret = ad9467_spi_read(st->spi, AN877_ADC_REG_VREF);
-	if (ret < 0)
-		return ret;
+	scoped_guard(mutex, &st->lock) {
+		ret = ad9467_spi_read(st, AN877_ADC_REG_VREF);
+		if (ret < 0)
+			return ret;
+	}
 
 	vref_val = ret & info->vref_mask;
 
@@ -330,31 +332,31 @@ static int ad9467_set_scale(struct ad9467_state *st, int val, int val2)
 			continue;
 
 		guard(mutex)(&st->lock);
-		ret = ad9467_spi_write(st->spi, AN877_ADC_REG_VREF,
+		ret = ad9467_spi_write(st, AN877_ADC_REG_VREF,
 				       info->scale_table[i][1]);
 		if (ret < 0)
 			return ret;
 
-		return ad9467_spi_write(st->spi, AN877_ADC_REG_TRANSFER,
+		return ad9467_spi_write(st, AN877_ADC_REG_TRANSFER,
 					AN877_ADC_TRANSFER_SYNC);
 	}
 
 	return -EINVAL;
 }
 
-static int ad9467_outputmode_set(struct spi_device *spi, unsigned int mode)
+static int ad9467_outputmode_set(struct ad9467_state *st, unsigned int mode)
 {
 	int ret;
 
-	ret = ad9467_spi_write(spi, AN877_ADC_REG_OUTPUT_MODE, mode);
+	ret = ad9467_spi_write(st, AN877_ADC_REG_OUTPUT_MODE, mode);
 	if (ret < 0)
 		return ret;
 
-	return ad9467_spi_write(spi, AN877_ADC_REG_TRANSFER,
+	return ad9467_spi_write(st, AN877_ADC_REG_TRANSFER,
 				AN877_ADC_TRANSFER_SYNC);
 }
 
-static int ad9647_calibrate_prepare(const struct ad9467_state *st)
+static int ad9647_calibrate_prepare(struct ad9467_state *st)
 {
 	struct iio_backend_data_fmt data = {
 		.enable = false,
@@ -362,17 +364,17 @@ static int ad9647_calibrate_prepare(const struct ad9467_state *st)
 	unsigned int c;
 	int ret;
 
-	ret = ad9467_spi_write(st->spi, AN877_ADC_REG_TEST_IO,
+	ret = ad9467_spi_write(st, AN877_ADC_REG_TEST_IO,
 			       AN877_ADC_TESTMODE_PN9_SEQ);
 	if (ret)
 		return ret;
 
-	ret = ad9467_spi_write(st->spi, AN877_ADC_REG_TRANSFER,
+	ret = ad9467_spi_write(st, AN877_ADC_REG_TRANSFER,
 			       AN877_ADC_TRANSFER_SYNC);
 	if (ret)
 		return ret;
 
-	ret = ad9467_outputmode_set(st->spi, st->info->default_output_mode);
+	ret = ad9467_outputmode_set(st, st->info->default_output_mode);
 	if (ret)
 		return ret;
 
@@ -390,7 +392,7 @@ static int ad9647_calibrate_prepare(const struct ad9467_state *st)
 	return iio_backend_chan_enable(st->back, 0);
 }
 
-static int ad9647_calibrate_polarity_set(const struct ad9467_state *st,
+static int ad9647_calibrate_polarity_set(struct ad9467_state *st,
 					 bool invert)
 {
 	enum iio_backend_sample_trigger trigger;
@@ -401,7 +403,7 @@ static int ad9647_calibrate_polarity_set(const struct ad9467_state *st,
 		if (invert)
 			phase |= AN877_ADC_INVERT_DCO_CLK;
 
-		return ad9467_spi_write(st->spi, AN877_ADC_REG_OUTPUT_PHASE,
+		return ad9467_spi_write(st, AN877_ADC_REG_OUTPUT_PHASE,
 					phase);
 	}
 
@@ -437,19 +439,18 @@ static unsigned int ad9467_find_optimal_point(const unsigned long *calib_map,
 	return cnt;
 }
 
-static int ad9467_calibrate_apply(const struct ad9467_state *st,
-				  unsigned int val)
+static int ad9467_calibrate_apply(struct ad9467_state *st, unsigned int val)
 {
 	unsigned int lane;
 	int ret;
 
 	if (st->info->has_dco) {
-		ret = ad9467_spi_write(st->spi, AN877_ADC_REG_OUTPUT_DELAY,
+		ret = ad9467_spi_write(st, AN877_ADC_REG_OUTPUT_DELAY,
 				       val);
 		if (ret)
 			return ret;
 
-		return ad9467_spi_write(st->spi, AN877_ADC_REG_TRANSFER,
+		return ad9467_spi_write(st, AN877_ADC_REG_TRANSFER,
 					AN877_ADC_TRANSFER_SYNC);
 	}
 
@@ -462,7 +463,7 @@ static int ad9467_calibrate_apply(const struct ad9467_state *st,
 	return 0;
 }
 
-static int ad9647_calibrate_stop(const struct ad9467_state *st)
+static int ad9647_calibrate_stop(struct ad9467_state *st)
 {
 	struct iio_backend_data_fmt data = {
 		.sign_extend = true,
@@ -487,16 +488,16 @@ static int ad9647_calibrate_stop(const struct ad9467_state *st)
 	}
 
 	mode = st->info->default_output_mode | AN877_ADC_OUTPUT_MODE_TWOS_COMPLEMENT;
-	ret = ad9467_outputmode_set(st->spi, mode);
+	ret = ad9467_outputmode_set(st, mode);
 	if (ret)
 		return ret;
 
-	ret = ad9467_spi_write(st->spi, AN877_ADC_REG_TEST_IO,
+	ret = ad9467_spi_write(st, AN877_ADC_REG_TEST_IO,
 			       AN877_ADC_TESTMODE_OFF);
 	if (ret)
 		return ret;
 
-	return ad9467_spi_write(st->spi, AN877_ADC_REG_TRANSFER,
+	return ad9467_spi_write(st, AN877_ADC_REG_TRANSFER,
 			       AN877_ADC_TRANSFER_SYNC);
 }
 
@@ -846,7 +847,7 @@ static int ad9467_probe(struct spi_device *spi)
 	if (ret)
 		return ret;
 
-	id = ad9467_spi_read(spi, AN877_ADC_REG_CHIP_ID);
+	id = ad9467_spi_read(st, AN877_ADC_REG_CHIP_ID);
 	if (id != st->info->id) {
 		dev_err(&spi->dev, "Mismatch CHIP_ID, got 0x%X, expected 0x%X\n",
 			id, st->info->id);

---
base-commit: 5e3c5871138da700796587aa5f096d39135f9d36
change-id: 20240506-dev-ad9467-dma-3114fdd27c1f
--

Thanks!
- Nuno Sá

