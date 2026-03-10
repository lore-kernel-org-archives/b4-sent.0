From: Radu Sabau <radu.sabau@analog.com>
Date: Tue, 10 Mar 2026 16:32:25 +0200
Subject: [PATCH v2 4/4] iio: adc: ad4691: add SPI offload support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260310-ad4692-multichannel-sar-adc-driver-v2-4-d9bb8aeb5e17@analog.com>
References: <20260310-ad4692-multichannel-sar-adc-driver-v2-0-d9bb8aeb5e17@analog.com>
In-Reply-To: <20260310-ad4692-multichannel-sar-adc-driver-v2-0-d9bb8aeb5e17@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773153147; l=18450;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=BHgIa8pe6A8XMJvEo+AxZy5Cw3LLOU1NleJ4RT2NNoA=;
 b=Q/yPNk0DAT4z68vxkEwQKoqZtxKG/l6e454OJkJ78fAiEt5plSzXcuxnJxD2/GMlX8fxEZnVt
 BZuhR63eSzOAlIYW6gr6/F7JOjeSl94/KqIscOPilyGe1cRNpNTmIcC
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SPI offload support to enable DMA-based, CPU-independent data
acquisition using the SPI Engine offload framework.

When an SPI offload is available (devm_spi_offload_get() succeeds),
the driver registers a DMA engine IIO buffer and uses dedicated buffer
setup operations. If no offload is available the existing software
triggered buffer path is used unchanged.

Both CNV Clock Mode and Manual Mode support offload, but use different
trigger mechanisms:

CNV Clock Mode: the SPI Engine is triggered by the ADC's DATA_READY
signal on GP0. For this mode the driver acts as both an SPI offload
consumer (DMA RX stream, message optimization) and a trigger source
provider: it registers the GP0/DATA_READY output via
devm_spi_offload_trigger_register() so the offload framework can
match the '#trigger-source-cells' phandle from the device tree and
automatically fire the SPI Engine DMA transfer at end-of-conversion.
The pre-built SPI message reads all active channels from the AVG_IN
accumulator registers (2-byte address + 2-byte data per channel,
one 4-byte transfer each) followed by a state reset word to re-arm
the accumulator for the next cycle.

Manual Mode: the SPI Engine is triggered by a periodic trigger at
the configured sampling frequency. The pre-built SPI message uses
the pipelined CNV-on-CS protocol: N+1 4-byte transfers are issued
for N active channels (the first result is discarded as garbage from
the pipeline flush) and the remaining N results are captured by DMA.

All offload transfers use 32-bit frames (bits_per_word=32, len=4) for
DMA word alignment. In Manual Mode the 4-byte DMA word layout is
[dummy(8), data_hi(8), data_lo(8), extra(8)]; the channel scan type
storagebits=32, shift=8, realbits=16 correctly extracts the 16-bit
ADC result from the middle two bytes.

Kconfig gains a dependency on IIO_BUFFER_DMAENGINE.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/adc/Kconfig  |   1 +
 drivers/iio/adc/ad4691.c | 398 +++++++++++++++++++++++++++++++++++++++++++++--
 2 files changed, 389 insertions(+), 10 deletions(-)

diff --git a/drivers/iio/adc/Kconfig b/drivers/iio/adc/Kconfig
index d498f16c0816..93f090e9a562 100644
--- a/drivers/iio/adc/Kconfig
+++ b/drivers/iio/adc/Kconfig
@@ -144,6 +144,7 @@ config AD4691
 	depends on SPI
 	select IIO_BUFFER
 	select IIO_TRIGGERED_BUFFER
+	select IIO_BUFFER_DMAENGINE
 	select REGMAP
 	help
 	  Say yes here to build support for Analog Devices AD4691 Family MuxSAR
diff --git a/drivers/iio/adc/ad4691.c b/drivers/iio/adc/ad4691.c
index 8b3caf0334ba..2ed384cfc1b9 100644
--- a/drivers/iio/adc/ad4691.c
+++ b/drivers/iio/adc/ad4691.c
@@ -9,6 +9,7 @@
 #include <linux/clk.h>
 #include <linux/delay.h>
 #include <linux/device.h>
+#include <linux/dmaengine.h>
 #include <linux/err.h>
 #include <linux/gpio/consumer.h>
 #include <linux/hrtimer.h>
@@ -22,11 +23,15 @@
 #include <linux/regmap.h>
 #include <linux/regulator/consumer.h>
 #include <linux/spi/spi.h>
+#include <linux/spi/offload/consumer.h>
+#include <linux/spi/offload/provider.h>
 #include <linux/util_macros.h>
 #include <linux/units.h>
 #include <linux/unaligned.h>
 
 #include <linux/iio/buffer.h>
+#include <linux/iio/buffer-dma.h>
+#include <linux/iio/buffer-dmaengine.h>
 #include <linux/iio/iio.h>
 
 #include <linux/iio/trigger.h>
@@ -47,6 +52,7 @@
  */
 #define AD4691_MANUAL_MODE_STD_FREQ(x, y)	((y) / (36 * ((x) + 1)))
 #define AD4691_BITS_PER_XFER			24
+#define AD4691_OFFLOAD_BITS_PER_WORD		32
 #define AD4691_CNV_DUTY_CYCLE_NS		380
 #define AD4691_MAX_CONV_PERIOD_US		800
 
@@ -252,6 +258,16 @@ struct ad4691_state {
 	struct hrtimer			sampling_timer;
 	ktime_t				sampling_period;
 
+	struct spi_offload		*offload;
+	struct spi_offload_trigger	*offload_trigger;
+	struct spi_offload_trigger	*offload_trigger_periodic;
+	u64				offload_trigger_hz;
+	struct spi_message		offload_msg;
+	/* Max 16 channel transfers + 1 state reset or NOOP */
+	struct spi_transfer		offload_xfer[17];
+	/* TX commands for manual and accumulator modes */
+	u32				offload_tx_cmd[17];
+	u32				offload_tx_reset;
 	/*
 	 * DMA (thus cache coherency maintenance) may require the
 	 * transfer buffers to live in their own cache lines.
@@ -265,6 +281,65 @@ struct ad4691_state {
 	} scan __aligned(IIO_DMA_MINALIGN);
 };
 
+static const struct spi_offload_config ad4691_offload_config = {
+	.capability_flags = SPI_OFFLOAD_CAP_TRIGGER |
+			    SPI_OFFLOAD_CAP_RX_STREAM_DMA,
+};
+
+static bool ad4691_offload_trigger_match(struct spi_offload_trigger *trigger,
+					 enum spi_offload_trigger_type type,
+					 u64 *args, u32 nargs)
+{
+	if (type != SPI_OFFLOAD_TRIGGER_DATA_READY)
+		return false;
+
+	/*
+	 * Requires 2 args:
+	 * args[0] is the trigger event (BUSY or DATA_READY).
+	 * args[1] is the GPIO pin number (only GP0 supported).
+	 */
+	if (nargs != 2)
+		return false;
+
+	if (args[0] != AD4691_TRIGGER_EVENT_BUSY &&
+	    args[0] != AD4691_TRIGGER_EVENT_DATA_READY)
+		return false;
+
+	if (args[1] != AD4691_TRIGGER_PIN_GP0)
+		return false;
+
+	return true;
+}
+
+static int ad4691_offload_trigger_request(struct spi_offload_trigger *trigger,
+					  enum spi_offload_trigger_type type,
+					  u64 *args, u32 nargs)
+{
+	/*
+	 * GP0 is configured as DATA_READY or BUSY in ad4691_config()
+	 * based on the ADC mode. No additional configuration needed here.
+	 */
+	if (nargs != 2)
+		return -EINVAL;
+
+	return 0;
+}
+
+static int ad4691_offload_trigger_validate(struct spi_offload_trigger *trigger,
+					   struct spi_offload_trigger_config *config)
+{
+	if (config->type != SPI_OFFLOAD_TRIGGER_DATA_READY)
+		return -EINVAL;
+
+	return 0;
+}
+
+static const struct spi_offload_trigger_ops ad4691_offload_trigger_ops = {
+	.match = ad4691_offload_trigger_match,
+	.request = ad4691_offload_trigger_request,
+	.validate = ad4691_offload_trigger_validate,
+};
+
 static void ad4691_disable_pwm(void *data)
 {
 	struct pwm_device *pwm = data;
@@ -442,6 +517,9 @@ static int ad4691_transfer(struct ad4691_state *st, int command,
 static int ad4691_get_sampling_freq(struct ad4691_state *st)
 {
 	if (st->adc_mode == AD4691_MANUAL_MODE) {
+		/* Offload uses periodic trigger, non-offload uses hrtimer */
+		if (st->offload)
+			return st->offload_trigger_hz;
 		return DIV_ROUND_CLOSEST_ULL(NSEC_PER_SEC,
 					     ktime_to_ns(st->sampling_period));
 	}
@@ -497,6 +575,7 @@ static int ad4691_pwm_get(struct spi_device *spi, struct ad4691_state *st)
 static int ad4691_set_sampling_freq(struct iio_dev *indio_dev, unsigned int freq)
 {
 	struct ad4691_state *st = iio_priv(indio_dev);
+	int ret;
 
 	IIO_DEV_ACQUIRE_DIRECT_MODE(indio_dev, claim);
 
@@ -506,12 +585,31 @@ static int ad4691_set_sampling_freq(struct iio_dev *indio_dev, unsigned int freq
 	guard(mutex)(&st->lock);
 
 	if (st->adc_mode == AD4691_MANUAL_MODE) {
-		if (!freq || freq > st->chip->max_rate)
-			return -EINVAL;
-
-		st->sampling_period = ns_to_ktime(DIV_ROUND_CLOSEST_ULL
-			(NSEC_PER_SEC, freq));
-		return 0;
+		/* For offload mode, validate and store frequency for periodic trigger */
+		if (st->offload) {
+			struct spi_offload_trigger_config config = {
+				.type = SPI_OFFLOAD_TRIGGER_PERIODIC,
+				.periodic = {
+					.frequency_hz = freq,
+				},
+			};
+
+			ret = spi_offload_trigger_validate(st->offload_trigger_periodic,
+							   &config);
+			if (ret)
+				return ret;
+
+			st->offload_trigger_hz = config.periodic.frequency_hz;
+			return 0;
+		} else {
+			/* Non-offload: update hrtimer sampling period */
+			if (!freq || freq > st->chip->max_rate)
+				return -EINVAL;
+
+			st->sampling_period = ns_to_ktime(DIV_ROUND_CLOSEST_ULL
+				(NSEC_PER_SEC, freq));
+			return 0;
+		}
 	}
 
 	if (!st->conv_trigger)
@@ -787,6 +885,224 @@ static const struct iio_buffer_setup_ops ad4691_buffer_setup_ops = {
 	.postdisable = &ad4691_buffer_postdisable,
 };
 
+static int ad4691_offload_buffer_postenable(struct iio_dev *indio_dev)
+{
+	struct ad4691_state *st = iio_priv(indio_dev);
+	struct spi_offload_trigger_config config = { };
+	struct spi_offload_trigger *trigger;
+	struct spi_transfer *xfer = st->offload_xfer;
+	int ret, num_xfers = 0;
+	int active_chans[16];
+	unsigned int bit;
+	int n_active = 0;
+	int i;
+
+	memset(xfer, 0, sizeof(st->offload_xfer));
+
+	/* Collect active channels in scan order */
+	iio_for_each_active_channel(indio_dev, bit)
+		active_chans[n_active++] = bit;
+
+	ret = ad4691_enter_conversion_mode(st);
+	if (ret)
+		return ret;
+
+	/*
+	 * MANUAL_MODE uses a periodic (PWM) trigger and reads directly from
+	 * the ADC. CNV_CLOCK_MODE uses the DATA_READY trigger and reads from
+	 * accumulators.
+	 */
+	if (st->adc_mode == AD4691_MANUAL_MODE) {
+		config.type = SPI_OFFLOAD_TRIGGER_PERIODIC;
+		config.periodic.frequency_hz = st->offload_trigger_hz;
+		trigger = st->offload_trigger_periodic;
+		if (!trigger)
+			return -EINVAL;
+	} else {
+		ret = regmap_write(st->regmap, AD4691_STATE_RESET_REG,
+				   AD4691_STATE_RESET_ALL);
+		if (ret)
+			return ret;
+
+		/* Configure accumulator masks - 0 = enabled, 1 = masked */
+		ret = regmap_write(st->regmap, AD4691_ACC_MASK1_REG,
+				   ~(*indio_dev->active_scan_mask) & 0xFF);
+		if (ret)
+			return ret;
+
+		ret = regmap_write(st->regmap, AD4691_ACC_MASK2_REG,
+				   ~(*indio_dev->active_scan_mask >> 8) & 0xFF);
+		if (ret)
+			return ret;
+
+		/* Configure sequencer with active channels */
+		ret = regmap_write(st->regmap, AD4691_STD_SEQ_CONFIG,
+				   *indio_dev->active_scan_mask);
+		if (ret)
+			return ret;
+
+		iio_for_each_active_channel(indio_dev, bit) {
+			ret = regmap_write(st->regmap, AD4691_ACC_COUNT_LIMIT(bit),
+					   AD4691_ACC_COUNT_VAL);
+			if (ret)
+				return ret;
+		}
+
+		config.type = SPI_OFFLOAD_TRIGGER_DATA_READY;
+		trigger = st->offload_trigger;
+	}
+
+	if (st->adc_mode == AD4691_MANUAL_MODE) {
+		/*
+		 * Manual mode with CNV tied to CS: Each CS toggle triggers a
+		 * conversion AND reads the previous conversion result (pipeline).
+		 */
+		for (i = 0; i < n_active; i++) {
+			st->offload_tx_cmd[num_xfers] = AD4691_ADC_CHAN(active_chans[i]) << 24;
+			xfer[num_xfers].tx_buf = &st->offload_tx_cmd[num_xfers];
+			xfer[num_xfers].len = 4;
+			xfer[num_xfers].bits_per_word = 32;
+			xfer[num_xfers].speed_hz = st->spi->max_speed_hz;
+			xfer[num_xfers].cs_change = 1;
+			xfer[num_xfers].cs_change_delay.value = 1000;
+			xfer[num_xfers].cs_change_delay.unit = SPI_DELAY_UNIT_NSECS;
+			/* First transfer RX is garbage - don't capture it */
+			if (num_xfers)
+				xfer[num_xfers].offload_flags = SPI_OFFLOAD_XFER_RX_STREAM;
+			num_xfers++;
+		}
+
+		/* Final NOOP to flush pipeline and get last channel's data */
+		st->offload_tx_cmd[num_xfers] = AD4691_NOOP << 24;
+		xfer[num_xfers].tx_buf = &st->offload_tx_cmd[num_xfers];
+		xfer[num_xfers].len = 4;
+		xfer[num_xfers].bits_per_word = 32;
+		xfer[num_xfers].speed_hz = st->spi->max_speed_hz;
+		xfer[num_xfers].cs_change = 0;
+		xfer[num_xfers].offload_flags = SPI_OFFLOAD_XFER_RX_STREAM;
+		num_xfers++;
+	} else {
+		/*
+		 * CNV_CLOCK_MODE: single transfer per channel (2-byte cmd +
+		 * 2-byte data = 4 bytes, one 32-bit SPI Engine DMA word).
+		 * AVG_IN registers are used; RX layout: [cmd_hi, cmd_lo, d_hi, d_lo]
+		 */
+		for (i = 0; i < n_active; i++) {
+			unsigned int reg;
+			int ch = active_chans[i];
+
+			reg = AD4691_AVG_IN(ch);
+			st->offload_tx_cmd[ch] =
+				((reg >> 8) | 0x80) << 24 |
+				(reg & 0xFF) << 16;
+			xfer[num_xfers].tx_buf = &st->offload_tx_cmd[ch];
+			xfer[num_xfers].len = 4;
+			xfer[num_xfers].bits_per_word = 32;
+			xfer[num_xfers].speed_hz = st->spi->max_speed_hz;
+			xfer[num_xfers].offload_flags = SPI_OFFLOAD_XFER_RX_STREAM;
+			xfer[num_xfers].cs_change = 1;
+			num_xfers++;
+		}
+
+		/*
+		 * State reset: clear accumulator so DATA_READY can fire again.
+		 * With bits_per_word=32, SPI engine transmits MSB first.
+		 */
+		st->offload_tx_reset = ((AD4691_STATE_RESET_REG >> 8) << 24) |
+				       ((AD4691_STATE_RESET_REG & 0xFF) << 16) |
+				       (0x01 << 8);
+
+		xfer[num_xfers].tx_buf = &st->offload_tx_reset;
+		xfer[num_xfers].len = 4;
+		xfer[num_xfers].bits_per_word = 32;
+		xfer[num_xfers].speed_hz = st->spi->max_speed_hz;
+		xfer[num_xfers].cs_change = 0;
+		num_xfers++;
+	}
+
+	if (num_xfers == 0)
+		return -EINVAL;
+
+	/*
+	 * For MANUAL_MODE, validate that the trigger frequency is low enough
+	 * for all SPI transfers to complete. Each transfer is 32 bits.
+	 * Add 50% margin for CS setup/hold and other overhead.
+	 */
+	if (st->adc_mode == AD4691_MANUAL_MODE) {
+		u64 min_period_ns;
+		u64 trigger_period_ns;
+
+		/* Time for all transfers in nanoseconds, with 50% overhead margin */
+		min_period_ns = div64_u64((u64)num_xfers * AD4691_OFFLOAD_BITS_PER_WORD *
+					  NSEC_PER_SEC * 3,
+					  st->spi->max_speed_hz * 2);
+
+		trigger_period_ns = div64_u64(NSEC_PER_SEC, st->offload_trigger_hz);
+
+		if (trigger_period_ns < min_period_ns)
+			return -EINVAL;
+	}
+
+	spi_message_init_with_transfers(&st->offload_msg, xfer, num_xfers);
+	st->offload_msg.offload = st->offload;
+
+	ret = spi_optimize_message(st->spi, &st->offload_msg);
+	if (ret)
+		return ret;
+
+	/*
+	 * For CNV_CLOCK_MODE, start conversions before enabling the trigger.
+	 * If the trigger is enabled first, the SPI engine blocks waiting for
+	 * DATA_READY, and any subsequent SPI write times out.
+	 *
+	 * MANUAL_MODE: CNV is tied to CS; conversion starts with each transfer.
+	 */
+	if (st->adc_mode == AD4691_CNV_CLOCK_MODE) {
+		ret = ad4691_sampling_enable(st, true);
+		if (ret)
+			goto err_unoptimize_message;
+	}
+
+	ret = spi_offload_trigger_enable(st->offload, trigger, &config);
+	if (ret)
+		goto err_sampling_disable;
+
+	return 0;
+
+err_sampling_disable:
+	if (st->adc_mode == AD4691_CNV_CLOCK_MODE)
+		ad4691_sampling_enable(st, false);
+err_unoptimize_message:
+	spi_unoptimize_message(&st->offload_msg);
+	return ret;
+}
+
+static int ad4691_offload_buffer_predisable(struct iio_dev *indio_dev)
+{
+	struct ad4691_state *st = iio_priv(indio_dev);
+	struct spi_offload_trigger *trigger;
+	int ret;
+
+	trigger = (st->adc_mode == AD4691_MANUAL_MODE) ?
+		  st->offload_trigger_periodic : st->offload_trigger;
+
+	spi_offload_trigger_disable(st->offload, trigger);
+	spi_unoptimize_message(&st->offload_msg);
+
+	if (st->adc_mode == AD4691_CNV_CLOCK_MODE) {
+		ret = ad4691_sampling_enable(st, false);
+		if (ret)
+			return ret;
+	}
+
+	return ad4691_exit_conversion_mode(st);
+}
+
+static const struct iio_buffer_setup_ops ad4691_offload_buffer_setup_ops = {
+	.postenable = &ad4691_offload_buffer_postenable,
+	.predisable = &ad4691_offload_buffer_predisable,
+};
+
 static irqreturn_t ad4691_irq(int irq, void *private)
 {
 	struct iio_dev *indio_dev = private;
@@ -981,6 +1297,54 @@ static int ad4691_config(struct ad4691_state *st)
 	return regmap_write(st->regmap, AD4691_GPIO_MODE1_REG, AD4691_ADC_BUSY);
 }
 
+static int ad4691_setup_offload(struct iio_dev *indio_dev,
+				struct ad4691_state *st)
+{
+	struct device *dev = &st->spi->dev;
+	struct dma_chan *rx_dma;
+	int ret;
+
+	if (st->adc_mode == AD4691_MANUAL_MODE) {
+		st->offload_trigger_periodic = devm_spi_offload_trigger_get(dev,
+				st->offload, SPI_OFFLOAD_TRIGGER_PERIODIC);
+		if (IS_ERR(st->offload_trigger_periodic))
+			return dev_err_probe(dev,
+				PTR_ERR(st->offload_trigger_periodic),
+				"failed to get periodic offload trigger\n");
+
+		st->offload_trigger_hz = AD4691_MANUAL_MODE_STD_FREQ(st->chip->num_channels,
+								      st->spi->max_speed_hz);
+	} else {
+		struct spi_offload_trigger_info trigger_info = {
+			.fwnode = dev_fwnode(dev),
+			.ops = &ad4691_offload_trigger_ops,
+			.priv = st,
+		};
+
+		ret = devm_spi_offload_trigger_register(dev, &trigger_info);
+		if (ret)
+			return dev_err_probe(dev, ret,
+					     "failed to register offload trigger\n");
+
+		st->offload_trigger = devm_spi_offload_trigger_get(dev,
+				st->offload, SPI_OFFLOAD_TRIGGER_DATA_READY);
+		if (IS_ERR(st->offload_trigger))
+			return dev_err_probe(dev, PTR_ERR(st->offload_trigger),
+					     "failed to get offload trigger\n");
+	}
+
+	rx_dma = devm_spi_offload_rx_stream_request_dma_chan(dev, st->offload);
+	if (IS_ERR(rx_dma))
+		return dev_err_probe(dev, PTR_ERR(rx_dma),
+				     "failed to get offload RX DMA\n");
+
+	indio_dev->modes = INDIO_DIRECT_MODE | INDIO_BUFFER_HARDWARE;
+	indio_dev->setup_ops = &ad4691_offload_buffer_setup_ops;
+
+	return devm_iio_dmaengine_buffer_setup_with_handle(dev, indio_dev,
+			rx_dma, IIO_BUFFER_DIRECTION_IN);
+}
+
 static int ad4691_setup_triggered_buffer(struct iio_dev *indio_dev,
 					 struct ad4691_state *st)
 {
@@ -1064,6 +1428,14 @@ static int ad4691_probe(struct spi_device *spi)
 		return dev_err_probe(dev, PTR_ERR(st->regmap),
 				     "Failed to initialize regmap\n");
 
+	st->offload = devm_spi_offload_get(dev, spi, &ad4691_offload_config);
+	if (IS_ERR(st->offload)) {
+		if (PTR_ERR(st->offload) != -ENODEV)
+			return dev_err_probe(dev, PTR_ERR(st->offload),
+					     "failed to get SPI offload\n");
+		st->offload = NULL;
+	}
+
 	st->chip = spi_get_device_match_data(spi);
 	if (!st->chip)
 		return dev_err_probe(dev, -ENODEV, "Could not find chip info\n");
@@ -1088,10 +1460,15 @@ static int ad4691_probe(struct spi_device *spi)
 		? st->chip->manual_channels : st->chip->channels;
 	indio_dev->num_channels = st->chip->num_channels;
 
-	ret = ad4691_setup_triggered_buffer(indio_dev, st);
-	if (ret)
-		return ret;
-
+	if (st->offload) {
+		ret = ad4691_setup_offload(indio_dev, st);
+		if (ret)
+			return ret;
+	} else {
+		ret = ad4691_setup_triggered_buffer(indio_dev, st);
+		if (ret)
+			return ret;
+	}
 	return devm_iio_device_register(dev, indio_dev);
 }
 
@@ -1126,3 +1503,4 @@ module_spi_driver(ad4691_driver);
 MODULE_AUTHOR("Radu Sabau <radu.sabau@analog.com>");
 MODULE_DESCRIPTION("Analog Devices AD4691 Family ADC Driver");
 MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("IIO_DMA_BUFFER");

-- 
2.43.0

