From: Andrei Stancovici <andrei.stancovici@analog.com>
Date: Fri, 09 Oct 2026 11:43:38 +0300
Subject: [PATCH 5/6] iio: adc: ltc2497: add FA/FB line-frequency rejection
 selection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-submission-ltc2493-support-v1-v1-5-3dad1d4b152a@analog.com>
References: <20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com>
In-Reply-To: <20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Beguin <liambeguin@gmail.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Andrei Stancovici <andrei.stancovici@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791535413; l=17540;
 i=andrei.stancovici@analog.com; s=20261009; h=from:subject:message-id;
 bh=3WzDnx7l3QZ4eSXr/SXax8YW3t9ZVpiRswr5scXjEDo=;
 b=0Ez+AVIfkHSk/kbUDicyZPr2noTWMeLpnyJkjTkCUk5Dm9+qtLP9GfSTnJdre/IH9D719F2Tj
 2aZyM435qy7DAi18cJTDY44kGQE1r9wasxbB/7Kpv4oG9iCIv2tJwNX
X-Developer-Key: i=andrei.stancovici@analog.com; a=ed25519;
 pk=wgT+au+blAhVYxhwNgdx0woNl/1p+OCG484rnTRFrsE=
X-Endpoint-Received: by B4 Relay for andrei.stancovici@analog.com/20261009 with auth_id=1140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC2499 can suppress mains interference at 50Hz, 60Hz, or
simultaneously at both (the power-up default). Expose it through
filter_mode and filter_mode_available on the voltage channels.

The conversion time also depends on the rejection mode: 50Hz-only is the
longest at 163.5 ms (1x). The previous 150 ms budget was 13.5 ms short,
risking a mid-conversion reprogram in 50Hz-only 1x mode.

Tested on live LTC2499 hardware connected through an IIO network backend:
all three modes are selectable and readable; voltage reads succeed in each
mode; conversion times are respected; temperature reads honour the
rejection selection.

Datasheet: https://www.analog.com/media/en/technical-documentation/data-sheets/2499fa.pdf
Signed-off-by: Andrei Stancovici <andrei.stancovici@analog.com>
---
 drivers/iio/adc/ltc2497-core.c | 159 +++++++++++++++++++++++++++++++++--------
 drivers/iio/adc/ltc2497.c      |  50 +++++++++----
 drivers/iio/adc/ltc2497.h      |  44 +++++++++---
 3 files changed, 200 insertions(+), 53 deletions(-)

diff --git a/drivers/iio/adc/ltc2497-core.c b/drivers/iio/adc/ltc2497-core.c
index 816312bf0e90..e5a8ab568128 100644
--- a/drivers/iio/adc/ltc2497-core.c
+++ b/drivers/iio/adc/ltc2497-core.c
@@ -7,6 +7,8 @@
  */
 
 #include <linux/delay.h>
+#include <linux/device/devres.h>
+#include <linux/gfp.h>
 #include <linux/iio/iio.h>
 #include <linux/iio/driver.h>
 #include <linux/math64.h>
@@ -22,33 +24,37 @@
 #define LTC2497_SIGN			BIT(3)
 
 /*
- * Output-rate modes, indexed by ltc2497core_driverdata.speed_2x
- * (0 = 1x, the power-on default; 1 = 2x, LTC2499 only).  The advertised
- * sampling_frequency and the conversion-time budget are two views of the same
- * mode, so they are kept in lock-step here.
+ * Output rates indexed as [rejection][speed]; each row matches the
+ * corresponding conv_time_ms_tbl row so rates and wait times stay in step.
  */
-static const int ltc2497core_samp_freq_avail[] = {
-	6, 800000,	/* 1x: ~6.8 Hz  (1 / t_CONV_1 typ 146.9ms) */
-	13, 600000,	/* 2x: ~13.6 Hz (1 / t_CONV_2 typ  73.6ms) */
+static const int ltc2497core_samp_freq_avail[][4] = {
+	[LTC2499_REJECT_50_60]	= { 6, 800000, 13, 600000 },	/* ~6.8 / 13.6 Hz */
+	[LTC2499_REJECT_50]	= { 6, 240000, 12, 450000 },	/* ~6.24 / 12.45 Hz */
+	[LTC2499_REJECT_60]	= { 7, 490000, 14, 950000 },	/* ~7.49 / 14.95 Hz */
 };
 
-static const unsigned int ltc2497core_conv_time_ms_tbl[] = {
-	LTC2497_CONV_TIME_1X_MS,		/* 1x */
-	LTC2499_CONV_TIME_2X_MS,		/* 2x */
+static const unsigned int ltc2497core_conv_time_ms_tbl[][2] = {
+	[LTC2499_REJECT_50_60]	= { LTC2497_CONV_TIME_50_60_1X_MS,
+				    LTC2499_CONV_TIME_50_60_2X_MS },
+	[LTC2499_REJECT_50]	= { LTC2499_CONV_TIME_50_1X_MS,
+				    LTC2499_CONV_TIME_50_2X_MS },
+	[LTC2499_REJECT_60]	= { LTC2499_CONV_TIME_60_1X_MS,
+				    LTC2499_CONV_TIME_60_2X_MS },
 };
 
 static unsigned int ltc2497core_conv_time_ms(struct ltc2497core_driverdata *ddata,
 					     u8 address)
 {
 	/*
-	 * SPD is ignored by the part during a temperature measurement: it
-	 * always converts at 1x, so budget the 1x time regardless of the
-	 * selected voltage-channel mode.
+	 * A temperature measurement always converts at 1x (the part ignores
+	 * SPD while measuring temperature) but still honours the FA/FB
+	 * rejection selection, so budget the 1x cell of the current rejection
+	 * row regardless of the selected voltage-channel speed.
 	 */
 	if (address == LTC2497_TEMP_ADDR)
-		return ltc2497core_conv_time_ms_tbl[0];
+		return ltc2497core_conv_time_ms_tbl[ddata->rejection][0];
 
-	return ltc2497core_conv_time_ms_tbl[ddata->speed_2x];
+	return ltc2497core_conv_time_ms_tbl[ddata->rejection][ddata->speed_2x];
 }
 
 static int ltc2497core_wait_conv(struct ltc2497core_driverdata *ddata,
@@ -192,11 +198,12 @@ static int ltc2497core_read_raw(struct iio_dev *indio_dev,
 		/*
 		 * Only advertised on the voltage channels of parts with a speed
 		 * mode; the sampling frequency is a property of the selected 1x/2x
-		 * mode, not of an individual conversion.
+		 * speed and of the FA/FB rejection mode, not of an individual
+		 * conversion.
 		 */
 		mutex_lock(&ddata->lock);
-		*val = ltc2497core_samp_freq_avail[ddata->speed_2x * 2];
-		*val2 = ltc2497core_samp_freq_avail[ddata->speed_2x * 2 + 1];
+		*val = ltc2497core_samp_freq_avail[ddata->rejection][ddata->speed_2x * 2];
+		*val2 = ltc2497core_samp_freq_avail[ddata->rejection][ddata->speed_2x * 2 + 1];
 		mutex_unlock(&ddata->lock);
 
 		return IIO_VAL_INT_PLUS_MICRO;
@@ -211,11 +218,13 @@ static int ltc2497core_read_avail(struct iio_dev *indio_dev,
 				  const int **vals, int *type, int *length,
 				  long mask)
 {
+	struct ltc2497core_driverdata *ddata = iio_priv(indio_dev);
+
 	switch (mask) {
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		*vals = ltc2497core_samp_freq_avail;
+		*vals = ltc2497core_samp_freq_avail[ddata->rejection];
 		*type = IIO_VAL_INT_PLUS_MICRO;
-		*length = ARRAY_SIZE(ltc2497core_samp_freq_avail);
+		*length = ARRAY_SIZE(ltc2497core_samp_freq_avail[ddata->rejection]);
 		return IIO_AVAIL_LIST;
 
 	default:
@@ -228,23 +237,28 @@ static int ltc2497core_write_raw(struct iio_dev *indio_dev,
 				 int val, int val2, long mask)
 {
 	struct ltc2497core_driverdata *ddata = iio_priv(indio_dev);
+	const int *avail;
 	unsigned int i;
 	bool speed_2x;
 
 	switch (mask) {
 	case IIO_CHAN_INFO_SAMP_FREQ:
-		/* Match the (val, val2) pair against the advertised rates. */
-		for (i = 0; i < ARRAY_SIZE(ltc2497core_samp_freq_avail); i += 2) {
-			if (val == ltc2497core_samp_freq_avail[i] &&
-			    val2 == ltc2497core_samp_freq_avail[i + 1])
+		/*
+		 * The rates differ per rejection mode, so match against the
+		 * current mode's row under lock.
+		 */
+		mutex_lock(&ddata->lock);
+		avail = ltc2497core_samp_freq_avail[ddata->rejection];
+		for (i = 0; i < ARRAY_SIZE(ltc2497core_samp_freq_avail[0]); i += 2) {
+			if (val == avail[i] && val2 == avail[i + 1])
 				break;
 		}
-		if (i == ARRAY_SIZE(ltc2497core_samp_freq_avail))
+		if (i == ARRAY_SIZE(ltc2497core_samp_freq_avail[0])) {
+			mutex_unlock(&ddata->lock);
 			return -EINVAL;
+		}
 
 		speed_2x = i / 2;
-
-		mutex_lock(&ddata->lock);
 		ddata->speed_2x = speed_2x;
 		/*
 		 * The new speed only takes effect once the second command byte
@@ -268,6 +282,72 @@ static int ltc2497core_write_raw(struct iio_dev *indio_dev,
 	}
 }
 
+/*
+ * The three legal FA/FB combinations map one-to-one to the enumerators,
+ * so the reserved FA = FB = 1 state is unreachable through this driver.
+ */
+static const char * const ltc2497core_filter_modes_str[] = {
+	[LTC2499_REJECT_50_60]	= "50_60",
+	[LTC2499_REJECT_50]	= "50",
+	[LTC2499_REJECT_60]	= "60",
+};
+
+static int ltc2497core_set_filter_mode(struct iio_dev *indio_dev,
+				       const struct iio_chan_spec *chan,
+				       unsigned int val)
+{
+	struct ltc2497core_driverdata *ddata = iio_priv(indio_dev);
+
+	mutex_lock(&ddata->lock);
+	ddata->rejection = val;
+	/*
+	 * The new rejection mode only takes effect once the second command byte
+	 * is reprogrammed, so force the next read to reprogram rather than reuse
+	 * the value already latched for this address.  LTC2497_CONFIG_DEFAULT is
+	 * not a valid channel/temperature address, so it is a safe re-arm
+	 * sentinel (as used at probe).
+	 *
+	 * A conversion started under the old rejection mode may still be in
+	 * flight; its own duration (conv_time_prev), not the new mode's, still
+	 * gates the next reprogram, so the timing state is left untouched here.
+	 */
+	ddata->addr_prev = LTC2497_CONFIG_DEFAULT;
+	mutex_unlock(&ddata->lock);
+
+	return 0;
+}
+
+static int ltc2497core_get_filter_mode(struct iio_dev *indio_dev,
+				       const struct iio_chan_spec *chan)
+{
+	struct ltc2497core_driverdata *ddata = iio_priv(indio_dev);
+	enum ltc2497_rejection rejection;
+
+	mutex_lock(&ddata->lock);
+	rejection = ddata->rejection;
+	mutex_unlock(&ddata->lock);
+
+	return rejection;
+}
+
+static const struct iio_enum ltc2497core_filter_mode_enum = {
+	.items = ltc2497core_filter_modes_str,
+	.num_items = ARRAY_SIZE(ltc2497core_filter_modes_str),
+	.set = ltc2497core_set_filter_mode,
+	.get = ltc2497core_get_filter_mode,
+};
+
+/*
+ * Rejection applies to voltage and temperature alike, so the attribute is
+ * device-wide.
+ */
+static const struct iio_chan_spec_ext_info ltc2497core_ext_info[] = {
+	IIO_ENUM("filter_mode", IIO_SHARED_BY_ALL, &ltc2497core_filter_mode_enum),
+	IIO_ENUM_AVAILABLE("filter_mode", IIO_SHARED_BY_ALL,
+			   &ltc2497core_filter_mode_enum),
+	{ }
+};
+
 #define LTC2497_CHAN(_chan, _addr, _ds_name, _extra_mask) { \
 	.type = IIO_VOLTAGE, \
 	.indexed = 1, \
@@ -404,6 +484,27 @@ int ltc2497core_probe(struct device *dev, struct iio_dev *indio_dev)
 	if (!ddata->chip_info->has_temp)
 		indio_dev->num_channels--;
 
+	if (ddata->chip_info->has_rejection_mode) {
+		struct iio_chan_spec *channels;
+		unsigned int i;
+
+		/*
+		 * Rejection applies to every channel; ext_info is attached at
+		 * probe because a const table would expose filter_mode on all
+		 * parts unconditionally.
+		 */
+		channels = devm_kmemdup(dev, indio_dev->channels,
+					indio_dev->num_channels * sizeof(*channels),
+					GFP_KERNEL);
+		if (!channels)
+			return -ENOMEM;
+
+		for (i = 0; i < indio_dev->num_channels; i++)
+			channels[i].ext_info = ltc2497core_ext_info;
+
+		indio_dev->channels = channels;
+	}
+
 	ret = ddata->result_and_measure(ddata, LTC2497_CONFIG_DEFAULT, NULL);
 	if (ret < 0)
 		return ret;
@@ -428,8 +529,8 @@ int ltc2497core_probe(struct device *dev, struct iio_dev *indio_dev)
 
 	ddata->addr_prev = LTC2497_CONFIG_DEFAULT;
 	ddata->time_prev = ktime_get();
-	/* Power-on default mode is 1x; a conversion is already in flight. */
-	ddata->conv_time_prev = LTC2497_CONV_TIME_1X_MS;
+	/* Power-on default is 50/60Hz rejection at 1x; a conversion is already in flight. */
+	ddata->conv_time_prev = LTC2497_CONV_TIME_50_60_1X_MS;
 
 	mutex_init(&ddata->lock);
 
diff --git a/drivers/iio/adc/ltc2497.c b/drivers/iio/adc/ltc2497.c
index a655b04e2454..0df2ad9b3243 100644
--- a/drivers/iio/adc/ltc2497.c
+++ b/drivers/iio/adc/ltc2497.c
@@ -38,6 +38,23 @@ struct ltc2497_driverdata {
 	} data __aligned(IIO_DMA_MINALIGN);
 };
 
+/*
+ * The reserved FA = FB = 1 combination is not reachable: the enum has no
+ * enumerator for it.
+ */
+static u8 ltc2497_rejection_bits(enum ltc2497_rejection rejection)
+{
+	switch (rejection) {
+	case LTC2499_REJECT_50:
+		return LTC2499_FB;
+	case LTC2499_REJECT_60:
+		return LTC2499_FA;
+	case LTC2499_REJECT_50_60:
+	default:
+		return 0;
+	}
+}
+
 static int ltc2497_result_and_measure(struct ltc2497core_driverdata *ddata,
 				      u8 address, int *val)
 {
@@ -86,32 +103,34 @@ static int ltc2497_result_and_measure(struct ltc2497core_driverdata *ddata,
 	}
 
 	/*
-	 * Parts with a second config byte (LTC2499: internal PTAT sensor and/or
-	 * the 2x speed mode) latch their converter configuration from that byte
-	 * and only re-evaluate it when EN2 is set; a single byte, or a second
-	 * byte with EN2 = 0, means "keep previous".  A one-byte channel select
-	 * therefore cannot pull the device back out of temperature mode, so a
-	 * voltage read after a temperature read would keep returning the PTAT
-	 * result.  Always drive the second byte with EN2 set on these parts:
+	 * Parts with a second config byte (LTC2499: internal PTAT sensor, the 2x
+	 * speed mode, and/or FA/FB line-rejection selection) latch their
+	 * converter configuration from that byte and only re-evaluate it when
+	 * EN2 is set; a single byte, or a second byte with EN2 = 0, means "keep
+	 * previous".  A one-byte channel select therefore cannot pull the device
+	 * back out of temperature mode, so a voltage read after a temperature
+	 * read would keep returning the PTAT result.  Always drive the second
+	 * byte with EN2 set on these parts:
 	 *   - temperature read: IM = 1 (SPD is ignored by the part in
-	 *     temperature mode and is left 0 here);
-	 *   - voltage read: IM = 0 (external input), plus SPD when 2x is
-	 *     selected.
-	 * FA = FB = 0 keeps the power-on simultaneous 50/60Hz rejection, whose
-	 * worst-case conversion time the driver's wait already covers.
+	 *     temperature mode and is left 0 here), plus FA/FB (rejection is
+	 *     honoured during temperature conversion);
+	 *   - voltage read: IM = 0 (external input), plus FA/FB, plus SPD when
+	 *     2x is selected.
 	 *
 	 * The byte could be skipped while the latched configuration is already
 	 * the one wanted; it is sent on every conversion for simplicity.
 	 */
-	if (ddata->chip_info->has_temp || ddata->chip_info->has_speed_mode) {
+	if (ddata->chip_info->has_temp || ddata->chip_info->has_speed_mode ||
+	    ddata->chip_info->has_rejection_mode) {
+		u8 rejection_bits = ltc2497_rejection_bits(ddata->rejection);
 		u8 cmd[2];
 
 		if (address == LTC2497_TEMP_ADDR) {
 			cmd[0] = LTC2497_ENABLE | LTC2497_CONFIG_DEFAULT;
-			cmd[1] = LTC2499_EN2 | LTC2499_IM;
+			cmd[1] = LTC2499_EN2 | LTC2499_IM | rejection_bits;
 		} else {
 			cmd[0] = LTC2497_ENABLE | address;
-			cmd[1] = LTC2499_EN2;
+			cmd[1] = LTC2499_EN2 | rejection_bits;
 			if (ddata->speed_2x)
 				cmd[1] |= LTC2499_SPD;
 		}
@@ -187,6 +206,7 @@ static const struct ltc2497_chip_info ltc2497_info[] = {
 		.name = "ltc2499",
 		.has_temp = true,
 		.has_speed_mode = true,
+		.has_rejection_mode = true,
 	},
 };
 
diff --git a/drivers/iio/adc/ltc2497.h b/drivers/iio/adc/ltc2497.h
index 219f7d49854b..34ea62c2a4bc 100644
--- a/drivers/iio/adc/ltc2497.h
+++ b/drivers/iio/adc/ltc2497.h
@@ -4,15 +4,19 @@
 #define LTC2497_CONFIG_DEFAULT		LTC2497_ENABLE
 
 /*
- * Conversion-time bounds used to gate reads.  Each value is the datasheet
- * t_CONV maximum, rounded UP to the next whole millisecond.
+ * Worst-case conversion times (datasheet t_CONV max), one per rejection/speed
+ * combination.  Both FA/FB rejection and SPD speed shift the conversion time,
+ * so both must be correct to avoid reprogramming a conversion mid-flight (-EIO).
  *
- * The 2x mode (LTC2499_SPD, LTC2499 only) disables the offset auto-calibration
- * to roughly double the output rate; adding the 2x wait time is what makes the
- * SPD control actually faster.
+ * The simultaneous 50/60Hz 1x value is also used by LTC2496/LTC2497 (no speed
+ * or rejection control) and is the power-up default.
  */
-#define LTC2497_CONV_TIME_1X_MS		150ULL	/* ceil(t_CONV_1 simult. max 149.9) */
-#define LTC2499_CONV_TIME_2X_MS		76ULL	/* ceil(t_CONV_2 simult. max  75.1) */
+#define LTC2497_CONV_TIME_50_60_1X_MS	150ULL	/* t_CONV_1 simult. max 149.9 */
+#define LTC2499_CONV_TIME_50_60_2X_MS	76ULL	/* t_CONV_2 simult. max  75.1 */
+#define LTC2499_CONV_TIME_50_1X_MS	164ULL	/* t_CONV_1 50Hz    max 163.5 */
+#define LTC2499_CONV_TIME_50_2X_MS	82ULL	/* t_CONV_2 50Hz    max  81.9 */
+#define LTC2499_CONV_TIME_60_1X_MS	137ULL	/* t_CONV_1 60Hz    max 136.3 */
+#define LTC2499_CONV_TIME_60_2X_MS	69ULL	/* t_CONV_2 60Hz    max  68.2 */
 
 /*
  * Sentinel passed as `address` to result_and_measure() to request a
@@ -24,13 +28,29 @@
 /* Second config-byte bits (LTC2499 / LTC2493 only) */
 #define LTC2499_EN2			BIT(7)	/* enable second config byte */
 #define LTC2499_IM			BIT(6)	/* 1 = measure internal temp sensor */
+#define LTC2499_FA			BIT(5)	/* line-rejection select bit A */
+#define LTC2499_FB			BIT(4)	/* line-rejection select bit B */
 #define LTC2499_SPD			BIT(3)	/* 1 = 2x output rate (offset cal off) */
 
+/*
+ * Line-frequency rejection modes selected by FA/FB in the second config byte.
+ * The datasheet's fourth combination (FA = FB = 1) is reserved, so it is not
+ * given an enumerator and is unreachable through this driver.  Applies to both
+ * voltage and temperature conversions (unlike SPD, which the part ignores while
+ * measuring temperature).
+ */
+enum ltc2497_rejection {
+	LTC2499_REJECT_50_60,	/* FA=0 FB=0: simultaneous 50/60Hz (default) */
+	LTC2499_REJECT_50,	/* FA=0 FB=1: 50Hz only */
+	LTC2499_REJECT_60,	/* FA=1 FB=0: 60Hz only */
+};
+
 struct ltc2497_chip_info {
 	const char *name;
 	u32 resolution;
 	bool has_temp;
 	bool has_speed_mode;	/* SPD bit in the 2nd config byte (LTC2499/LTC2493) */
+	bool has_rejection_mode;	/* FA/FB bits in the 2nd config byte (LTC2499) */
 	bool four_channel;	/* 4 inputs (LTC2493) instead of 16 */
 };
 
@@ -41,8 +61,14 @@ struct ltc2497core_driverdata {
 	struct mutex lock;
 	const struct ltc2497_chip_info	*chip_info;
 	u8 addr_prev;
-	bool speed_2x;	/* SPD: false = 1x (default), true = 2x */
-	/* Conversion time (ms) of the conversion currently in flight. */
+	bool speed_2x;		/* SPD: false = 1x (default), true = 2x */
+	enum ltc2497_rejection rejection;	/* FA/FB line-rejection select */
+	/*
+	 * Conversion time (ms) of the conversion currently in flight.  It is
+	 * fixed by the mode active when that conversion was started, which
+	 * differs from the newly selected mode for the first read after a
+	 * sampling_frequency or filter_mode change.
+	 */
 	unsigned int conv_time_prev;
 	int (*result_and_measure)(struct ltc2497core_driverdata *ddata,
 				  u8 address, int *val);

-- 
2.43.0

