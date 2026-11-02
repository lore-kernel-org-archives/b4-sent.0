From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 02 Nov 2026 11:25:43 +0200
Subject: [PATCH v5 7/8] iio: imu: adis16607: Add external clock sync
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-adis16607-v5-7-4f98b0d271ac@analog.com>
References: <20261102-adis16607-v5-0-4f98b0d271ac@analog.com>
In-Reply-To: <20261102-adis16607-v5-0-4f98b0d271ac@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux@analog.com, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793611539; l=11832;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=Ylk05uW9ugh2tgjL5wxtfOdaTVWwFFqtc2VpPHNBiAM=;
 b=7UfS4dw+6HrRVJzthbJ+j5Rg2WmzbJbtvSKtDoUTGY7/qDfvlKoAwIGygJWKPa+lMUZ8gpRCu
 On01W1jZAGCCwNro+FGQESjsKotmKsG1vEaiZZxB8acEVOJpoZch8Ve
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for an optional external clock (clocks property),
selecting between SYNC_DIRECT (1 kHz to 8 kHz) and SYNC_SCALED (1 Hz
to 400 Hz) depending on the supplied frequency, with the internal
8 kHz clock used as the default when no clock is provided.

The clock rate is requested as exclusive since the sample period and
the sync scale are derived from it. In scaled mode the sync scale is
chosen when the sampling frequency is set, so that the requested rate
is matched as closely as possible while keeping the clock multiplied
at or below the internal rate. Loss of sync or of the PLL lock is
reported from the trigger handler, as the device keeps sampling
without it.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16607.c | 219 +++++++++++++++++++++++++++++++++++++++++---
 1 file changed, 206 insertions(+), 13 deletions(-)

diff --git a/drivers/iio/imu/adis16607.c b/drivers/iio/imu/adis16607.c
index bd7752f7a1ec..58504d351de1 100644
--- a/drivers/iio/imu/adis16607.c
+++ b/drivers/iio/imu/adis16607.c
@@ -8,6 +8,7 @@
 #include <linux/bitfield.h>
 #include <linux/bitops.h>
 #include <linux/build_bug.h>
+#include <linux/clk.h>
 #include <linux/debugfs.h>
 #include <linux/delay.h>
 #include <linux/iio/buffer.h>
@@ -50,6 +51,7 @@
 #define ADIS16607_REG_FIFO_WORD_CNT	0x2B
 #define ADIS16607_REG_USER_GPIO_CFG	0x2F
 #define ADIS16607_REG_SPI_HALFDUPLEX	0x32
+#define ADIS16607_REG_USER_SYNC		0x33
 #define ADIS16607_REG_USER_DATA_CFG	0x34
 #define ADIS16607_REG_USER_FIFO_CFG	0x35
 #define ADIS16607_REG_SOFT_RESET	0x36
@@ -62,12 +64,18 @@
 
 /* Masks */
 #define ADIS16607_RESET_GPIO_MASK	GENMASK(2, 0)
+#define ADIS16607_SYNC_GPIO_MASK	GENMASK(8, 6)
 #define ADIS16607_DR_GPIO_MASK		GENMASK(11, 9)
 #define ADIS16607_DEV_NOK_MASK		GENMASK(14, 12)
 #define ADIS16607_DATA_CNTR_EN_MASK	BIT(14)
 #define ADIS16607_BURST32_MASK		BIT(15)
+#define ADIS16607_SYNC_MODE_MASK	BIT(15)
 #define ADIS16607_BOOTLOADER_BUSY_MASK	BIT(0)
 
+/* DIAG_STAT sync flags */
+#define ADIS16607_DIAG_DPLL_UNLOCKED	BIT(1)
+#define ADIS16607_DIAG_SYNC_LOST	BIT(2)
+
 /* FIFO masks */
 #define ADIS16607_FIFO_THR_MASK		GENMASK(10, 0)
 #define ADIS16607_FIFO_FLUSH_MASK	BIT(15)
@@ -95,8 +103,22 @@
 #define ADIS16607_ACCEL_Z_DELTA_MAX	4000
 #define ADIS16607_GYRO_DELTA_MAX	2600
 
+/* Sync modes */
+enum adis16607_sync_mode {
+	ADIS16607_SYNC_DEFAULT,
+	ADIS16607_SYNC_DIRECT,
+	ADIS16607_SYNC_SCALED,
+};
+
+struct adis16607_sync {
+	u16 sync_mode;
+	u16 min_rate;
+	u16 max_rate;
+};
+
 struct adis16607_chip_info {
 	const struct iio_chan_spec *channels;
+	const struct adis16607_sync *sync_mode;
 	const char *name;
 	u32 num_channels;
 	u32 gyro_max_val;
@@ -108,6 +130,7 @@ struct adis16607_chip_info {
 	u32 deltvel_max_val;
 	u32 int_clk_Hz;
 	u16 max_dec;
+	u8 num_sync;
 };
 
 struct adis16607 {
@@ -115,6 +138,9 @@ struct adis16607 {
 	const struct adis16607_chip_info *info;
 	unsigned long clk_freq_mHz;
 	u64 sample_period_ns;
+	unsigned long ext_clk_Hz;
+	u32 sync_mode;
+	u16 sync_scale;
 	u16 fifo_watermark;
 	/* IIO buffer for reordered data - sized for max channels */
 	IIO_DECLARE_BUFFER_WITH_TS(u8, data, ADIS16607_SCAN_DATA_SIZE);
@@ -407,11 +433,18 @@ static void adis16607_fifo_drain(struct iio_dev *indio_dev, s64 irq_timestamp)
 
 	adis_dev_auto_lock(&st->adis);
 
-	/* Check if FIFO threshold is met */
 	ret = __adis_read_reg_16(&st->adis, ADIS16607_REG_DIAG_STAT, &diag_stat);
 	if (ret)
 		return;
 
+	/* The device keeps sampling without sync, so only warn about it */
+	if (diag_stat & ADIS16607_DIAG_SYNC_LOST)
+		dev_warn_ratelimited(&st->adis.spi->dev, "external sync lost\n");
+
+	if (diag_stat & ADIS16607_DIAG_DPLL_UNLOCKED)
+		dev_warn_ratelimited(&st->adis.spi->dev, "sync PLL unlocked\n");
+
+	/* Check if FIFO threshold is met */
 	if (!(diag_stat & ADIS16607_FIFO_THR_MET_MASK))
 		return;
 
@@ -841,8 +874,44 @@ static int adis16607_get_freq(struct adis16607 *st, u32 *freq)
 	return 0;
 }
 
+/*
+ * In scaled sync mode the output rate is ext_clk * scale / (dec + 1). Find the
+ * (scale, dec) pair closest to the requested rate (in mHz), keeping
+ * ext_clk * scale at or below the internal rate. On a tie the higher scale
+ * wins, so the decimation filter averages more samples.
+ */
+static void adis16607_scaled_params(struct adis16607 *st, u32 freq,
+				    u16 *scale, u32 *dec)
+{
+	u32 max_scale = st->info->int_clk_Hz / st->ext_clk_Hz;
+	u32 max_dec = st->info->max_dec + 1;
+	u64 best_err = U64_MAX;
+	u64 target = freq;
+
+	for (u32 k = 1; k <= max_scale; k++) {
+		u64 rate = st->ext_clk_Hz;
+		u64 div, odr, err;
+
+		rate *= k;
+		rate *= MILLIHZ_PER_HZ;
+
+		div = DIV_ROUND_CLOSEST_ULL(rate, freq);
+		div = clamp(div, 1, max_dec);
+		odr = DIV_ROUND_CLOSEST_ULL(rate, div);
+		err = abs_diff(odr, target);
+		if (err > best_err)
+			continue;
+
+		best_err = err;
+		*scale = k;
+		*dec = div - 1;
+	}
+}
+
 static int adis16607_set_freq(struct adis16607 *st, u32 freq)
 {
+	unsigned long clk_freq_mHz = st->clk_freq_mHz;
+	u16 scale = st->sync_scale;
 	u64 period_ns;
 	u32 dec;
 	int ret;
@@ -850,11 +919,16 @@ static int adis16607_set_freq(struct adis16607 *st, u32 freq)
 	if (!freq)
 		return -EINVAL;
 
-	dec = DIV_ROUND_CLOSEST(st->clk_freq_mHz, freq);
-	if (dec)
-		dec--;
+	if (st->sync_mode == ADIS16607_SYNC_SCALED) {
+		adis16607_scaled_params(st, freq, &scale, &dec);
+		clk_freq_mHz = st->ext_clk_Hz * scale * MILLIHZ_PER_HZ;
+	} else {
+		dec = DIV_ROUND_CLOSEST(clk_freq_mHz, freq);
+		if (dec)
+			dec--;
 
-	dec = min(dec, st->info->max_dec);
+		dec = min(dec, st->info->max_dec);
+	}
 
 	/*
 	 * The sample period is (dec + 1) / clk_freq. clk_freq_mHz is in
@@ -865,7 +939,7 @@ static int adis16607_set_freq(struct adis16607 *st, u32 freq)
 	period_ns = NSEC_PER_SEC;
 	period_ns *= MILLIHZ_PER_HZ;
 	period_ns *= dec + 1;
-	period_ns = DIV_ROUND_CLOSEST_ULL(period_ns, st->clk_freq_mHz);
+	period_ns = DIV_ROUND_CLOSEST_ULL(period_ns, clk_freq_mHz);
 
 	adis_dev_auto_scoped_lock(&st->adis) {
 		/* Reset the decimation accumulator before the new value */
@@ -873,6 +947,21 @@ static int adis16607_set_freq(struct adis16607 *st, u32 freq)
 		if (ret)
 			return ret;
 
+		/*
+		 * Writing USER_SYNC restarts the PLL lock, so only do it when
+		 * the scale actually changes.
+		 */
+		if (scale != st->sync_scale) {
+			ret = __adis_write_reg_16(&st->adis,
+						  ADIS16607_REG_USER_SYNC,
+						  ADIS16607_SYNC_MODE_MASK | scale);
+			if (ret)
+				return ret;
+
+			st->sync_scale = scale;
+			st->clk_freq_mHz = clk_freq_mHz;
+		}
+
 		if (dec) {
 			ret = __adis_write_reg_16(&st->adis,
 						  ADIS16607_REG_DEC_RATE, dec);
@@ -1079,6 +1168,17 @@ static const struct iio_info adis16607_info = {
 	.hwfifo_set_watermark = adis16607_set_watermark,
 };
 
+/*
+ * External sync clock ranges in Hz. The datasheet gives 0.8 Hz as the scaled
+ * mode minimum, but clk_get_rate() reports whole Hz so 1 Hz is the lowest
+ * rate we can match.
+ */
+static const struct adis16607_sync adis16607_sync_modes[] = {
+	{ ADIS16607_SYNC_DEFAULT, 0, 0 },
+	{ ADIS16607_SYNC_DIRECT, 1000, 8000 },
+	{ ADIS16607_SYNC_SCALED, 1, 400 },
+};
+
 static const char * const adis16607_status_error_msgs[] = {
 	[9] = "Boot Memory Failure",
 	[11] = "Power Supply Failure",
@@ -1123,6 +1223,8 @@ static const struct adis16607_chip_info adis16607_2_chip_info = {
 	.deltvel_max_val = IIO_G_TO_M_S_2(40),
 	.int_clk_Hz	= 8000,
 	.max_dec	= 65535,
+	.sync_mode	= adis16607_sync_modes,
+	.num_sync	= ARRAY_SIZE(adis16607_sync_modes),
 };
 
 static const struct adis16607_chip_info adis16607_3_chip_info = {
@@ -1138,22 +1240,113 @@ static const struct adis16607_chip_info adis16607_3_chip_info = {
 	.deltvel_max_val = IIO_G_TO_M_S_2(40),
 	.int_clk_Hz	= 8000,
 	.max_dec	= 65535,
+	.sync_mode	= adis16607_sync_modes,
+	.num_sync	= ARRAY_SIZE(adis16607_sync_modes),
 };
 
-/*
- * No external clock sync support yet: always run on the internal clock.
- * Default dec=0 after reset, so period = 1 / clk_freq_mHz.
- */
 static int adis16607_config_clk(struct adis16607 *st)
 {
-	u64 period_ns = NSEC_PER_SEC;
+	const struct adis16607_sync *sync_mode_data = NULL;
+	struct device *dev = &st->adis.spi->dev;
+	struct clk *clk;
+	u64 period_ns;
+	u16 dec;
+	int ret;
+
+	clk = devm_clk_get_optional_enabled(dev, NULL);
+	if (IS_ERR(clk))
+		return PTR_ERR(clk);
+
+	if (clk) {
+		/* The sync scale and sample period depend on this rate */
+		ret = devm_clk_rate_exclusive_get(dev, clk);
+		if (ret)
+			return dev_err_probe(dev, ret,
+					     "Failed to get exclusive clk rate\n");
+
+		st->ext_clk_Hz = clk_get_rate(clk);
+
+		for (unsigned int i = 1; i < st->info->num_sync; i++) {
+			if (st->ext_clk_Hz >= st->info->sync_mode[i].min_rate &&
+			    st->ext_clk_Hz <= st->info->sync_mode[i].max_rate) {
+				sync_mode_data = &st->info->sync_mode[i];
+				break;
+			}
+		}
+
+		if (!sync_mode_data)
+			return dev_err_probe(dev, -EINVAL,
+					     "Clk rate: %lu not in a valid range\n",
+					     st->ext_clk_Hz);
+
+		st->sync_mode = sync_mode_data->sync_mode;
+	} else {
+		st->sync_mode = ADIS16607_SYNC_DEFAULT;
+	}
+
+	/*
+	 * Write the full desired sync state explicitly for every mode,
+	 * rather than only when enabling non-default sync: USER_SYNC's
+	 * documented reset default (0x0000, direct mode / scale 0) means
+	 * this isn't fixing a known reset-state issue, but each mode
+	 * establishing its own complete state here, instead of only
+	 * touching bits conditionally, is simpler to reason about and
+	 * doesn't depend on that default holding true.
+	 */
+	ret = adis_update_bits_base(&st->adis, ADIS16607_REG_USER_GPIO_CFG,
+				    ADIS16607_SYNC_GPIO_MASK,
+				    FIELD_PREP(ADIS16607_SYNC_GPIO_MASK,
+					       st->sync_mode != ADIS16607_SYNC_DEFAULT), 2);
+	if (ret)
+		return ret;
+
+	/*
+	 * Start at the highest scale that keeps ext_clk * scale at or below
+	 * the internal rate, which the datasheet says the part performs best
+	 * with. set_freq() picks the scale from then on.
+	 */
+	if (st->sync_mode == ADIS16607_SYNC_SCALED)
+		st->sync_scale = st->info->int_clk_Hz / st->ext_clk_Hz;
 
-	st->clk_freq_mHz = st->info->int_clk_Hz * MILLIHZ_PER_HZ;
+	ret = adis_write_reg_16(&st->adis, ADIS16607_REG_USER_SYNC,
+				(st->sync_mode == ADIS16607_SYNC_SCALED) ?
+				ADIS16607_SYNC_MODE_MASK | st->sync_scale : 0);
+	if (ret)
+		return ret;
 
-	/* clk_freq_mHz is in millihertz: scale to get the period in ns */
+	switch (st->sync_mode) {
+	case ADIS16607_SYNC_SCALED:
+		/*
+		 * The effective rate is ext_clk * sync_scale, not necessarily
+		 * int_clk_Hz - use the real value here so sample_period_ns (and
+		 * therefore FIFO sample timestamps) don't drift from it.
+		 */
+		st->clk_freq_mHz = st->ext_clk_Hz * st->sync_scale *
+				   MILLIHZ_PER_HZ;
+		break;
+	case ADIS16607_SYNC_DIRECT:
+		/* DIRECT: external clock is the effective internal rate */
+		st->clk_freq_mHz = st->ext_clk_Hz * MILLIHZ_PER_HZ;
+		break;
+	default:
+		st->clk_freq_mHz = st->info->int_clk_Hz * MILLIHZ_PER_HZ;
+		break;
+	}
+
+	ret = adis_read_reg_16(&st->adis, ADIS16607_REG_DEC_RATE, &dec);
+	if (ret)
+		return ret;
+
+	/*
+	 * Sample period is (dec + 1) / clk_freq, with clk_freq_mHz in
+	 * millihertz. Same u64-first scheme as adis16607_set_freq().
+	 */
+	period_ns = NSEC_PER_SEC;
 	period_ns *= MILLIHZ_PER_HZ;
+	period_ns *= dec + 1;
 	st->sample_period_ns = DIV_ROUND_CLOSEST_ULL(period_ns,
 						     st->clk_freq_mHz);
+
 	return 0;
 }
 

-- 
2.43.0

