From: Radu Sabau <radu.sabau@analog.com>
Date: Thu, 16 Apr 2026 12:18:50 +0300
Subject: [PATCH v8 5/6] iio: adc: ad4691: add oversampling support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260416-ad4692-multichannel-sar-adc-driver-v8-5-c415bd048fa3@analog.com>
References: <20260416-ad4692-multichannel-sar-adc-driver-v8-0-c415bd048fa3@analog.com>
In-Reply-To: <20260416-ad4692-multichannel-sar-adc-driver-v8-0-c415bd048fa3@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776331127; l=16532;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=n0K/y5C7IZmxkrNiM6UmyZVIAz6TL7shyevZcB+gqoA=;
 b=XS/B1thyqYPnvPo3nYIXIzLHfu/100KztVF35y9jX5ClYZA036iGpzBUrRna9EUUw9iid4lPo
 0kO/yZ+x9isDssylRJ7V5il9S/EtftF2q3ZkqAT1cOMXbNTvO4hwXQ9
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

in_voltageN_sampling_frequency represents the effective output rate for
channel N, defined as osc_freq / osr[N]. The chip has one internal
oscillator shared by all channels; each channel independently
accumulates osr[N] oscillator cycles before producing a result.

Writing sampling_frequency computes needed_osc = freq * osr[N] and
snaps down to the largest oscillator table entry that satisfies both
osc <= needed_osc and osc % osr[N] == 0, guaranteeing an exact integer
read-back. The result is stored in target_osc_freq_Hz and written to
OSC_FREQ_REG at buffer enable and single-shot time, so sampling_frequency
and oversampling_ratio can be set in any order.

in_voltageN_sampling_frequency_available is computed dynamically from
the channel's current OSR, listing only oscillator table entries that
divide evenly by osr[N], expressed as effective rates. The list becomes
sparser as OSR increases, capping at max_rate / osr[N].

Writing oversampling_ratio stores the new OSR for that channel;
target_osc_freq_Hz is left unchanged. The effective rate read back via
in_voltageN_sampling_frequency becomes target_osc_freq_Hz / new_osr
automatically. The two attributes are orthogonal: sampling_frequency
controls the oscillator, oversampling_ratio controls the averaging depth.

OSR defaults to 1 (no accumulation) for all channels.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/adc/ad4691.c | 251 +++++++++++++++++++++++++++++++++++++++++------
 1 file changed, 221 insertions(+), 30 deletions(-)

diff --git a/drivers/iio/adc/ad4691.c b/drivers/iio/adc/ad4691.c
index fbd44f595cbe..f000e4cde339 100644
--- a/drivers/iio/adc/ad4691.c
+++ b/drivers/iio/adc/ad4691.c
@@ -115,6 +115,7 @@ enum ad4691_ref_ctrl {
 
 struct ad4691_channel_info {
 	const struct iio_chan_spec *channels;
+	const struct iio_chan_spec *manual_channels;
 	unsigned int num_channels;
 };
 
@@ -125,7 +126,34 @@ struct ad4691_chip_info {
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
@@ -176,25 +204,65 @@ static const struct iio_chan_spec ad4693_channels[] = {
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
-	/* Exclude the soft timestamp entry; num_channels caps access. */
+	/*
+	 * Offload paths share the SW channel arrays. num_channels caps access
+	 * before the soft timestamp entry, so no separate array is needed.
+	 */
+	.manual_channels = ad4691_manual_channels,
 	.num_channels = ARRAY_SIZE(ad4691_channels) - 1,
 };
 
 static const struct ad4691_channel_info ad4693_offload_info = {
 	.channels = ad4693_channels,
-	/* Exclude the soft timestamp entry; num_channels caps access. */
+	.manual_channels = ad4693_manual_channels,
 	.num_channels = ARRAY_SIZE(ad4693_channels) - 1,
 };
 
@@ -269,6 +337,19 @@ struct ad4691_state {
 	int irq;
 	int vref_uV;
 	u32 cnv_period_ns;
+	/*
+	 * Snapped oscillator frequency (Hz) shared by all channels. Set when
+	 * sampling_frequency or oversampling_ratio is written; written to
+	 * OSC_FREQ_REG at buffer enable and single-shot time so both attributes
+	 * can be set in any order. Reading in_voltageN_sampling_frequency
+	 * returns target_osc_freq_Hz / osr[N] — the effective rate for that
+	 * channel given its oversampling ratio.
+	 */
+	u32 target_osc_freq_Hz;
+	/* Per-channel oversampling ratio; always 1 in manual mode. */
+	u8 osr[16];
+	/* Scratch buffer for read_avail SAMP_FREQ; content is OSR-dependent. */
+	int samp_freq_avail[ARRAY_SIZE(ad4691_osc_freqs_Hz)];
 
 	bool manual_mode;
 	bool refbuf_en;
@@ -489,6 +570,18 @@ static const struct regmap_config ad4691_regmap_config = {
 	.cache_type = REGCACHE_MAPLE,
 };
 
+/* Write target_osc_freq_Hz to OSC_FREQ_REG. Called at use time. */
+static int ad4691_write_osc_freq(struct ad4691_state *st)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(ad4691_osc_freqs_Hz); i++) {
+		if (ad4691_osc_freqs_Hz[i] == st->target_osc_freq_Hz)
+			return regmap_write(st->regmap, AD4691_OSC_FREQ_REG, i);
+	}
+	return -EINVAL;
+}
+
 /*
  * Index 0 in ad4691_osc_freqs_Hz is 1 MHz — valid only for AD4692/AD4694
  * (max_rate == 1 MHz). AD4691/AD4693 cap at 500 kHz so their valid range
@@ -499,36 +592,58 @@ static unsigned int ad4691_samp_freq_start(const struct ad4691_chip_info *info)
 	return (info->max_rate == 1 * HZ_PER_MHZ) ? 0 : 1;
 }
 
-static int ad4691_get_sampling_freq(struct ad4691_state *st, int *val)
+/*
+ * Find the largest oscillator table entry that is both <= needed_osc and
+ * evenly divisible by osr (guaranteeing an integer effective rate on
+ * read-back). Returns 0 if no such entry exists in the chip's valid range.
+ */
+static unsigned int ad4691_find_osc_freq(struct ad4691_state *st,
+					 unsigned int needed_osc,
+					 unsigned int osr)
 {
-	unsigned int reg_val;
-	int ret;
+	unsigned int start = ad4691_samp_freq_start(st->info);
 
-	ret = regmap_read(st->regmap, AD4691_OSC_FREQ_REG, &reg_val);
-	if (ret)
-		return ret;
+	for (unsigned int i = start; i < ARRAY_SIZE(ad4691_osc_freqs_Hz); i++) {
+		if ((unsigned int)ad4691_osc_freqs_Hz[i] > needed_osc)
+			continue;
+		if (ad4691_osc_freqs_Hz[i] % osr != 0)
+			continue;
+		return ad4691_osc_freqs_Hz[i];
+	}
+	return 0;
+}
 
-	*val = ad4691_osc_freqs_Hz[FIELD_GET(AD4691_OSC_FREQ_MASK, reg_val)];
+static int ad4691_get_sampling_freq(struct ad4691_state *st, u8 osr, int *val)
+{
+	*val = st->target_osc_freq_Hz / osr;
 	return IIO_VAL_INT;
 }
 
-static int ad4691_set_sampling_freq(struct iio_dev *indio_dev, int freq)
+static int ad4691_set_sampling_freq(struct iio_dev *indio_dev,
+				    struct iio_chan_spec const *chan, int freq)
 {
 	struct ad4691_state *st = iio_priv(indio_dev);
-	unsigned int start = ad4691_samp_freq_start(st->info);
+	unsigned int osr = st->osr[chan->channel];
+	unsigned int found;
 
 	IIO_DEV_ACQUIRE_DIRECT_MODE(indio_dev, claim);
 	if (IIO_DEV_ACQUIRE_FAILED(claim))
 		return -EBUSY;
 
-	for (unsigned int i = start; i < ARRAY_SIZE(ad4691_osc_freqs_Hz); i++) {
-		if (ad4691_osc_freqs_Hz[i] != freq)
-			continue;
-		return regmap_update_bits(st->regmap, AD4691_OSC_FREQ_REG,
-					  AD4691_OSC_FREQ_MASK, i);
-	}
+	if (freq <= 0 || (unsigned int)freq > st->info->max_rate / osr)
+		return -EINVAL;
 
-	return -EINVAL;
+	found = ad4691_find_osc_freq(st, (unsigned int)freq * osr, osr);
+	if (!found)
+		return -EINVAL;
+
+	/*
+	 * Store the snapped oscillator frequency; OSC_FREQ_REG is written at
+	 * buffer enable and single-shot time so that sampling_frequency and
+	 * oversampling_ratio can be set in any order.
+	 */
+	st->target_osc_freq_Hz = found;
+	return 0;
 }
 
 static int ad4691_read_avail(struct iio_dev *indio_dev,
@@ -540,10 +655,30 @@ static int ad4691_read_avail(struct iio_dev *indio_dev,
 	unsigned int start = ad4691_samp_freq_start(st->info);
 
 	switch (mask) {
-	case IIO_CHAN_INFO_SAMP_FREQ:
-		*vals = &ad4691_osc_freqs_Hz[start];
+	case IIO_CHAN_INFO_SAMP_FREQ: {
+		unsigned int osr = st->osr[chan->channel];
+		int n = 0;
+
+		/*
+		 * Only oscillator frequencies evenly divisible by the channel's
+		 * OSR yield an integer effective rate; expose those as effective
+		 * rates (osc / osr) so the user works entirely in output-sample
+		 * space.
+		 */
+		for (unsigned int i = start; i < ARRAY_SIZE(ad4691_osc_freqs_Hz); i++) {
+			if (ad4691_osc_freqs_Hz[i] % osr != 0)
+				continue;
+			st->samp_freq_avail[n++] = ad4691_osc_freqs_Hz[i] / osr;
+		}
+		*vals = st->samp_freq_avail;
 		*type = IIO_VAL_INT;
-		*length = ARRAY_SIZE(ad4691_osc_freqs_Hz) - start;
+		*length = n;
+		return IIO_AVAIL_LIST;
+	}
+	case IIO_CHAN_INFO_OVERSAMPLING_RATIO:
+		*vals = ad4691_oversampling_ratios;
+		*type = IIO_VAL_INT;
+		*length = ARRAY_SIZE(ad4691_oversampling_ratios);
 		return IIO_AVAIL_LIST;
 	default:
 		return -EINVAL;
@@ -554,7 +689,7 @@ static int ad4691_single_shot_read(struct iio_dev *indio_dev,
 				   struct iio_chan_spec const *chan, int *val)
 {
 	struct ad4691_state *st = iio_priv(indio_dev);
-	unsigned int reg_val, osc_idx, period_us;
+	unsigned int reg_val, period_us;
 	int ret;
 
 	guard(mutex)(&st->lock);
@@ -575,7 +710,12 @@ static int ad4691_single_shot_read(struct iio_dev *indio_dev,
 	if (ret)
 		return ret;
 
-	ret = regmap_read(st->regmap, AD4691_OSC_FREQ_REG, &reg_val);
+	ret = regmap_write(st->regmap, AD4691_ACC_DEPTH_IN(chan->channel),
+			   st->osr[chan->channel]);
+	if (ret)
+		return ret;
+
+	ret = ad4691_write_osc_freq(st);
 	if (ret)
 		return ret;
 
@@ -583,9 +723,12 @@ static int ad4691_single_shot_read(struct iio_dev *indio_dev,
 	if (ret)
 		return ret;
 
-	osc_idx = FIELD_GET(AD4691_OSC_FREQ_MASK, reg_val);
-	/* Wait 2 oscillator periods for the conversion to complete. */
-	period_us = DIV_ROUND_UP(2UL * USEC_PER_SEC, ad4691_osc_freqs_Hz[osc_idx]);
+	/*
+	 * Wait osr + 1 oscillator periods: osr for accumulation, +1 for the
+	 * pipeline margin (one extra period ensures the final result is ready).
+	 */
+	period_us = DIV_ROUND_UP((unsigned long)(st->osr[chan->channel] + 1) * USEC_PER_SEC,
+				 st->target_osc_freq_Hz);
 	fsleep(period_us);
 
 	ret = regmap_write(st->regmap, AD4691_OSC_EN_REG, 0);
@@ -620,7 +763,10 @@ static int ad4691_read_raw(struct iio_dev *indio_dev,
 		return ad4691_single_shot_read(indio_dev, chan, val);
 	}
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		return ad4691_get_sampling_freq(st, val);
+		return ad4691_get_sampling_freq(st, st->osr[chan->channel], val);
+	case IIO_CHAN_INFO_OVERSAMPLING_RATIO:
+		*val = st->osr[chan->channel];
+		return IIO_VAL_INT;
 	case IIO_CHAN_INFO_SCALE:
 		*val = st->vref_uV / (MICRO / MILLI);
 		*val2 = chan->scan_type.realbits;
@@ -634,9 +780,29 @@ static int ad4691_write_raw(struct iio_dev *indio_dev,
 			    struct iio_chan_spec const *chan,
 			    int val, int val2, long mask)
 {
+	struct ad4691_state *st = iio_priv(indio_dev);
+
 	switch (mask) {
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		return ad4691_set_sampling_freq(indio_dev, val);
+		return ad4691_set_sampling_freq(indio_dev, chan, val);
+	case IIO_CHAN_INFO_OVERSAMPLING_RATIO: {
+		IIO_DEV_ACQUIRE_DIRECT_MODE(indio_dev, claim);
+		if (IIO_DEV_ACQUIRE_FAILED(claim))
+			return -EBUSY;
+
+		for (unsigned int i = 0; i < ARRAY_SIZE(ad4691_oversampling_ratios); i++) {
+			if (ad4691_oversampling_ratios[i] != val)
+				continue;
+			/*
+			 * Store the new OSR; target_osc_freq_Hz is unchanged.
+			 * The effective rate read back via in_voltageN_sampling_frequency
+			 * becomes target_osc_freq_Hz / new_osr automatically.
+			 */
+			st->osr[chan->channel] = val;
+			return 0;
+		}
+		return -EINVAL;
+	}
 	default:
 		return -EINVAL;
 	}
@@ -691,6 +857,10 @@ static int ad4691_enter_conversion_mode(struct ad4691_state *st)
 		return regmap_update_bits(st->regmap, AD4691_DEVICE_SETUP,
 					  AD4691_MANUAL_MODE, AD4691_MANUAL_MODE);
 
+	ret = ad4691_write_osc_freq(st);
+	if (ret)
+		return ret;
+
 	ret = regmap_update_bits(st->regmap, AD4691_ADC_SETUP,
 				 AD4691_ADC_MODE_MASK, AD4691_CNV_BURST_MODE);
 	if (ret)
@@ -844,6 +1014,12 @@ static int ad4691_cnv_burst_buffer_preenable(struct iio_dev *indio_dev)
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
@@ -995,6 +1171,12 @@ static int ad4691_cnv_burst_offload_buffer_postenable(struct iio_dev *indio_dev)
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
@@ -1361,6 +1543,8 @@ static int ad4691_config(struct ad4691_state *st)
 	if (ret)
 		return dev_err_probe(dev, ret, "Failed to write OSC_FREQ\n");
 
+	st->target_osc_freq_Hz = ad4691_osc_freqs_Hz[ad4691_samp_freq_start(st->info)];
+
 	ret = regmap_update_bits(st->regmap, AD4691_ADC_SETUP,
 				 AD4691_ADC_MODE_MASK, AD4691_AUTONOMOUS_MODE);
 	if (ret)
@@ -1518,6 +1702,7 @@ static int ad4691_probe(struct spi_device *spi)
 	st = iio_priv(indio_dev);
 	st->spi = spi;
 	st->info = spi_get_device_match_data(spi);
+	memset(st->osr, 1, sizeof(st->osr));
 
 	ret = devm_mutex_init(dev, &st->lock);
 	if (ret)
@@ -1552,11 +1737,17 @@ static int ad4691_probe(struct spi_device *spi)
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

