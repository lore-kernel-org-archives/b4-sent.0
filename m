From: Radu Sabau <radu.sabau@analog.com>
Date: Thu, 09 Apr 2026 18:28:26 +0300
Subject: [PATCH v7 5/6] iio: adc: ad4691: add oversampling support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260409-ad4692-multichannel-sar-adc-driver-v7-5-be375d4df2c5@analog.com>
References: <20260409-ad4692-multichannel-sar-adc-driver-v7-0-be375d4df2c5@analog.com>
In-Reply-To: <20260409-ad4692-multichannel-sar-adc-driver-v7-0-be375d4df2c5@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-doc@vger.kernel.org, 
 Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775748505; l=9894;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=eB6uvSJZMwxlszpLMEXiVdwqo2+1DAbz0m1ETwwp1E8=;
 b=Q9j9fNUH+gyIVtPhmTXEJpOmAQAIZwPDs3DvcRhKK3vjvmaqorlbeSfKFkBOsWJcG4pAwxb5U
 ENfshks7CfnBUWaVta7dRxuHpc0ypqzrtQRNwA4SpgDL2BydQYuRE81
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add per-channel oversampling ratio (OSR) support for CNV burst mode.
The accumulator depth register (ACC_DEPTH_IN) is programmed with the
selected OSR at buffer enable time and before each single-shot read.

Supported OSR values: 1, 2, 4, 8, 16, 32.

Introduce AD4691_MANUAL_CHANNEL() for manual mode channels, which do
not expose the oversampling ratio attribute since OSR is not applicable
in that mode. A separate manual_channels array is added to
struct ad4691_channel_info and selected at probe time; offload paths
reuse the same arrays with num_channels capping access before the soft
timestamp entry.

The reported sampling frequency accounts for the active OSR:
effective_freq = oscillator_freq / osr

OSR defaults to 1 (no accumulation) for all channels.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/adc/ad4691.c | 137 +++++++++++++++++++++++++++++++++++++++++++----
 1 file changed, 128 insertions(+), 9 deletions(-)

diff --git a/drivers/iio/adc/ad4691.c b/drivers/iio/adc/ad4691.c
index 839ea7f44c78..ef96d736996e 100644
--- a/drivers/iio/adc/ad4691.c
+++ b/drivers/iio/adc/ad4691.c
@@ -116,6 +116,7 @@ enum ad4691_ref_ctrl {
 
 struct ad4691_channel_info {
 	const struct iio_chan_spec *channels;
+	const struct iio_chan_spec *manual_channels;
 	unsigned int num_channels;
 };
 
@@ -126,7 +127,34 @@ struct ad4691_chip_info {
 	const struct ad4691_channel_info *offload_info;
 };
 
+/* CNV burst mode channel — exposes oversampling ratio. */
 #define AD4691_CHANNEL(ch)						\
+	{								\
+		.type = IIO_VOLTAGE,					\
+		.indexed = 1,						\
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |		\
+				      BIT(IIO_CHAN_INFO_OVERSAMPLING_RATIO) | \
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),	\
+		.info_mask_separate_available =				\
+				      BIT(IIO_CHAN_INFO_OVERSAMPLING_RATIO) | \
+				      BIT(IIO_CHAN_INFO_SAMP_FREQ),	\
+		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SCALE),	\
+		.channel = ch,						\
+		.scan_index = ch,					\
+		.scan_type = {						\
+			.sign = 'u',					\
+			.realbits = 16,					\
+			.storagebits = 16,				\
+			.endianness = IIO_BE,				\
+		},							\
+	}
+
+/*
+ * Manual mode channel — no oversampling ratio attribute. OSR is not
+ * supported in manual mode; ACC_DEPTH_IN is not configured during manual
+ * buffer enable.
+ */
+#define AD4691_MANUAL_CHANNEL(ch)					\
 	{								\
 		.type = IIO_VOLTAGE,					\
 		.indexed = 1,						\
@@ -177,25 +205,65 @@ static const struct iio_chan_spec ad4693_channels[] = {
 	IIO_CHAN_SOFT_TIMESTAMP(8),
 };
 
+static const struct iio_chan_spec ad4691_manual_channels[] = {
+	AD4691_MANUAL_CHANNEL(0),
+	AD4691_MANUAL_CHANNEL(1),
+	AD4691_MANUAL_CHANNEL(2),
+	AD4691_MANUAL_CHANNEL(3),
+	AD4691_MANUAL_CHANNEL(4),
+	AD4691_MANUAL_CHANNEL(5),
+	AD4691_MANUAL_CHANNEL(6),
+	AD4691_MANUAL_CHANNEL(7),
+	AD4691_MANUAL_CHANNEL(8),
+	AD4691_MANUAL_CHANNEL(9),
+	AD4691_MANUAL_CHANNEL(10),
+	AD4691_MANUAL_CHANNEL(11),
+	AD4691_MANUAL_CHANNEL(12),
+	AD4691_MANUAL_CHANNEL(13),
+	AD4691_MANUAL_CHANNEL(14),
+	AD4691_MANUAL_CHANNEL(15),
+	IIO_CHAN_SOFT_TIMESTAMP(16),
+};
+
+static const struct iio_chan_spec ad4693_manual_channels[] = {
+	AD4691_MANUAL_CHANNEL(0),
+	AD4691_MANUAL_CHANNEL(1),
+	AD4691_MANUAL_CHANNEL(2),
+	AD4691_MANUAL_CHANNEL(3),
+	AD4691_MANUAL_CHANNEL(4),
+	AD4691_MANUAL_CHANNEL(5),
+	AD4691_MANUAL_CHANNEL(6),
+	AD4691_MANUAL_CHANNEL(7),
+	IIO_CHAN_SOFT_TIMESTAMP(8),
+};
+
+static const int ad4691_oversampling_ratios[] = { 1, 2, 4, 8, 16, 32 };
+
 static const struct ad4691_channel_info ad4691_sw_info = {
 	.channels = ad4691_channels,
+	.manual_channels = ad4691_manual_channels,
 	.num_channels = ARRAY_SIZE(ad4691_channels),
 };
 
 static const struct ad4691_channel_info ad4693_sw_info = {
 	.channels = ad4693_channels,
+	.manual_channels = ad4693_manual_channels,
 	.num_channels = ARRAY_SIZE(ad4693_channels),
 };
 
 static const struct ad4691_channel_info ad4691_offload_info = {
 	.channels = ad4691_channels,
-	/* No soft timestamp; num_channels caps access to 16. */
+	/*
+	 * Offload paths share the SW channel arrays. num_channels caps access
+	 * before the soft timestamp entry, so no separate array is needed.
+	 */
+	.manual_channels = ad4691_manual_channels,
 	.num_channels = 16,
 };
 
 static const struct ad4691_channel_info ad4693_offload_info = {
 	.channels = ad4693_channels,
-	/* No soft timestamp; num_channels caps access to 8. */
+	.manual_channels = ad4693_manual_channels,
 	.num_channels = 8,
 };
 
@@ -270,6 +338,8 @@ struct ad4691_state {
 	int irq;
 	int vref_uV;
 	u32 cnv_period_ns;
+	/* Per-channel oversampling ratio; always 1 in manual mode. */
+	u8 osr[16];
 
 	bool manual_mode;
 	bool refbuf_en;
@@ -490,7 +560,8 @@ static const struct regmap_config ad4691_regmap_config = {
 	.cache_type = REGCACHE_MAPLE,
 };
 
-static int ad4691_get_sampling_freq(struct ad4691_state *st, int *val)
+static int ad4691_get_sampling_freq(struct ad4691_state *st, int *val,
+				    unsigned int osr)
 {
 	unsigned int reg_val;
 	int ret;
@@ -499,7 +570,7 @@ static int ad4691_get_sampling_freq(struct ad4691_state *st, int *val)
 	if (ret)
 		return ret;
 
-	*val = ad4691_osc_freqs_Hz[FIELD_GET(AD4691_OSC_FREQ_MASK, reg_val)];
+	*val = ad4691_osc_freqs_Hz[FIELD_GET(AD4691_OSC_FREQ_MASK, reg_val)] / osr;
 	return IIO_VAL_INT;
 }
 
@@ -536,6 +607,11 @@ static int ad4691_read_avail(struct iio_dev *indio_dev,
 		*type = IIO_VAL_INT;
 		*length = ARRAY_SIZE(ad4691_osc_freqs_Hz) - start;
 		return IIO_AVAIL_LIST;
+	case IIO_CHAN_INFO_OVERSAMPLING_RATIO:
+		*vals = ad4691_oversampling_ratios;
+		*type = IIO_VAL_INT;
+		*length = ARRAY_SIZE(ad4691_oversampling_ratios);
+		return IIO_AVAIL_LIST;
 	default:
 		return -EINVAL;
 	}
@@ -566,6 +642,11 @@ static int ad4691_single_shot_read(struct iio_dev *indio_dev,
 	if (ret)
 		return ret;
 
+	ret = regmap_write(st->regmap, AD4691_ACC_DEPTH_IN(chan->channel),
+			   st->osr[chan->channel]);
+	if (ret)
+		return ret;
+
 	ret = regmap_read(st->regmap, AD4691_OSC_FREQ_REG, &reg_val);
 	if (ret)
 		return ret;
@@ -575,8 +656,9 @@ static int ad4691_single_shot_read(struct iio_dev *indio_dev,
 		return ret;
 
 	osc_idx = FIELD_GET(AD4691_OSC_FREQ_MASK, reg_val);
-	/* Wait 2 oscillator periods for the conversion to complete. */
-	period_us = DIV_ROUND_UP(2UL * USEC_PER_SEC, ad4691_osc_freqs_Hz[osc_idx]);
+	/* Wait osr oscillator periods for all accumulator samples to complete. */
+	period_us = DIV_ROUND_UP((unsigned long)st->osr[chan->channel] * USEC_PER_SEC,
+				 ad4691_osc_freqs_Hz[osc_idx]);
 	fsleep(period_us);
 
 	ret = regmap_write(st->regmap, AD4691_OSC_EN_REG, 0);
@@ -611,7 +693,10 @@ static int ad4691_read_raw(struct iio_dev *indio_dev,
 		return ad4691_single_shot_read(indio_dev, chan, val);
 	}
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		return ad4691_get_sampling_freq(st, val);
+		return ad4691_get_sampling_freq(st, val, st->osr[chan->channel]);
+	case IIO_CHAN_INFO_OVERSAMPLING_RATIO:
+		*val = st->osr[chan->channel];
+		return IIO_VAL_INT;
 	case IIO_CHAN_INFO_SCALE:
 		*val = st->vref_uV / (MICRO / MILLI);
 		*val2 = chan->scan_type.realbits;
@@ -625,9 +710,24 @@ static int ad4691_write_raw(struct iio_dev *indio_dev,
 			    struct iio_chan_spec const *chan,
 			    int val, int val2, long mask)
 {
+	struct ad4691_state *st = iio_priv(indio_dev);
+
 	switch (mask) {
 	case IIO_CHAN_INFO_SAMP_FREQ:
 		return ad4691_set_sampling_freq(indio_dev, val);
+	case IIO_CHAN_INFO_OVERSAMPLING_RATIO: {
+		IIO_DEV_ACQUIRE_DIRECT_MODE(indio_dev, claim);
+		if (IIO_DEV_ACQUIRE_FAILED(claim))
+			return -EBUSY;
+
+		for (unsigned int i = 0; i < ARRAY_SIZE(ad4691_oversampling_ratios); i++) {
+			if (ad4691_oversampling_ratios[i] != val)
+				continue;
+			st->osr[chan->channel] = val;
+			return 0;
+		}
+		return -EINVAL;
+	}
 	default:
 		return -EINVAL;
 	}
@@ -842,6 +942,12 @@ static int ad4691_cnv_burst_buffer_preenable(struct iio_dev *indio_dev)
 	if (ret)
 		goto err_unoptimize;
 
+	iio_for_each_active_channel(indio_dev, i) {
+		ret = regmap_write(st->regmap, AD4691_ACC_DEPTH_IN(i), st->osr[i]);
+		if (ret)
+			goto err_unoptimize;
+	}
+
 	ret = ad4691_enter_conversion_mode(st);
 	if (ret)
 		goto err_unoptimize;
@@ -998,6 +1104,12 @@ static int ad4691_cnv_burst_offload_buffer_postenable(struct iio_dev *indio_dev)
 	if (ret)
 		return ret;
 
+	iio_for_each_active_channel(indio_dev, bit) {
+		ret = regmap_write(st->regmap, AD4691_ACC_DEPTH_IN(bit), st->osr[bit]);
+		if (ret)
+			return ret;
+	}
+
 	ret = ad4691_enter_conversion_mode(st);
 	if (ret)
 		return ret;
@@ -1519,6 +1631,7 @@ static int ad4691_probe(struct spi_device *spi)
 	st = iio_priv(indio_dev);
 	st->spi = spi;
 	st->info = spi_get_device_match_data(spi);
+	memset(st->osr, 1, sizeof(st->osr));
 
 	ret = devm_mutex_init(dev, &st->lock);
 	if (ret)
@@ -1553,11 +1666,17 @@ static int ad4691_probe(struct spi_device *spi)
 	indio_dev->modes = INDIO_DIRECT_MODE;
 
 	if (spi_offload) {
-		indio_dev->channels = st->info->offload_info->channels;
+		if (st->manual_mode)
+			indio_dev->channels = st->info->offload_info->manual_channels;
+		else
+			indio_dev->channels = st->info->offload_info->channels;
 		indio_dev->num_channels = st->info->offload_info->num_channels;
 		ret = ad4691_setup_offload(indio_dev, st, spi_offload);
 	} else {
-		indio_dev->channels = st->info->sw_info->channels;
+		if (st->manual_mode)
+			indio_dev->channels = st->info->sw_info->manual_channels;
+		else
+			indio_dev->channels = st->info->sw_info->channels;
 		indio_dev->num_channels = st->info->sw_info->num_channels;
 		ret = ad4691_setup_triggered_buffer(indio_dev, st);
 	}

-- 
2.43.0

