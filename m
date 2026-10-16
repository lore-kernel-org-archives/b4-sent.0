From: HuskerMinion <mocker-mug-unwoven@duck.com>
Date: Fri, 16 Oct 2026 02:15:42 -0600
Subject: [PATCH 2/2] iio: light: tcs3472: Add TCS3400 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-tcs3400-v1-2-3d79d2a7f449@duck.com>
References: <20261016-tcs3400-v1-0-3d79d2a7f449@duck.com>
In-Reply-To: <20261016-tcs3400-v1-0-3d79d2a7f449@duck.com>
To: Jonathan Cameron <jic23@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Meerwald-Stadler <pmeerw@pmeerw.net>, 
 Arka Mondal <arka@arkamondal.net>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 HuskerMinion <mocker-mug-unwoven@duck.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792138543; l=15047;
 i=mocker-mug-unwoven@duck.com; s=20261016; h=from:subject:message-id;
 bh=LguA4RR1202+1RYrnRumLKPVZRIg/f/gWk6msEcmmGQ=;
 b=7Bqj92hYkkqq7uFI0WIszySQGI+OeBEBP32O1NSoCmPjk67QnvqV3Ksrtor9eu4/AYs36t53B
 e38il7rnmZ4CThwqrdERUVNcxuwZ+LradCzDHM7EzbM4iJGouSJxDf2
X-Developer-Key: i=mocker-mug-unwoven@duck.com; a=ed25519;
 pk=Q7l9BnP4XnFimCK28K+NVowcECqTaJNXicdBAInot0k=
X-Endpoint-Received: by B4 Relay for mocker-mug-unwoven@duck.com/20261016 with auth_id=1206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AMS TCS3400 is the ambient light sensor of the Amazon Echo Show 8
(2nd gen). It has the TCS3472 register map (ENABLE at 0x80 up to BDATAH
at 0x9b, ID at 0x92, STATUS at 0x93 with the same bits), with these
differences:

- There is no command type field. Addresses auto-increment on their
  own, so word registers are read and written at their plain address
  (CDATA at 0x94, AILT at 0x84). With the TCS3472 auto-increment bit
  set the driver would address 0xb4 and 0xa4, which are not the data
  and threshold registers on the TCS3400.
- Interrupts are cleared by writing AICLEAR (0xe7).
- The gains are 1x, 4x, 16x and 64x instead of 1x, 4x, 16x and 60x.
- The ATIME step is 2.78 ms instead of 2.4 ms. The driver uses the
  same step for WTIME and the RGBC init time, as on the TCS3472.
- The ID register reads 0x90 (TCS34001, TCS34005) or 0x93 (TCS34003,
  TCS34007).

Describe each family in a chip_info structure and pick it from the ID
register, which the driver already reads to detect the part. The
TCS3472 behavior does not change. The IIO device is named "tcs3400" on
a TCS3400.

Add the "tcs3400" I2C ID and an OF match table with "ams,tcs3400" and
"ams,tcs3472".

Tested on the Amazon Echo Show 8 (2nd gen), which has a TCS34003 or
TCS34007 (ID 0x93) at 0x29: raw reads follow the light, and a hand over
the sensor takes the clear channel from about 2100 to 35 counts. The
threshold interrupt was not tested.

Signed-off-by: HuskerMinion <mocker-mug-unwoven@duck.com>
---
 drivers/iio/light/Kconfig   |   7 +-
 drivers/iio/light/tcs3472.c | 162 ++++++++++++++++++++++++++++++++++----------
 2 files changed, 132 insertions(+), 37 deletions(-)

diff --git a/drivers/iio/light/Kconfig b/drivers/iio/light/Kconfig
index 462fff1dd..4949d4446 100644
--- a/drivers/iio/light/Kconfig
+++ b/drivers/iio/light/Kconfig
@@ -610,13 +610,14 @@ config TCS3414
 	  will be called tcs3414.
 
 config TCS3472
-	tristate "TAOS TCS3472 color light-to-digital converter"
+	tristate "TAOS TCS3472 and AMS TCS3400 color light-to-digital converters"
 	depends on I2C
 	select IIO_BUFFER
 	select IIO_TRIGGERED_BUFFER
 	help
-	  If you say yes here you get support for the TAOS TCS3472
-	  family of color light-to-digital converters with IR filter.
+	  If you say yes here you get support for the TAOS TCS3472 and
+	  AMS TCS3400 families of color light-to-digital converters with
+	  IR filter.
 
 	  This driver can also be built as a module.  If so, the module
 	  will be called tcs3472.
diff --git a/drivers/iio/light/tcs3472.c b/drivers/iio/light/tcs3472.c
index b392943e5..fbd9a1b34 100644
--- a/drivers/iio/light/tcs3472.c
+++ b/drivers/iio/light/tcs3472.c
@@ -9,6 +9,11 @@
  * TCS34727)
  *
  * Datasheet: http://ams.com/eng/content/download/319364/1117183/file/TCS3472_Datasheet_EN_v2.pdf
+ *
+ * Also supports the AMS TCS3400 (TCS34001, TCS34003, TCS34005, TCS34007).
+ * It has the same registers, but no command type field (the register
+ * address auto-increments by itself), other gains, a 2.78 ms time step
+ * and a separate register to clear interrupts.
  */
 
 #include <linux/cleanup.h>
@@ -33,6 +38,7 @@
 #define TCS3472_SPECIAL_FUNC (BIT(5) | BIT(6))
 
 #define TCS3472_INTR_CLEAR (TCS3472_COMMAND | TCS3472_SPECIAL_FUNC | 0x06)
+#define TCS3400_AICLEAR 0xe7
 
 #define TCS3472_ENABLE (TCS3472_COMMAND | 0x00)
 #define TCS3472_ATIME (TCS3472_COMMAND | 0x01)
@@ -60,10 +66,37 @@
 #define TCS3472_CONTROL_AGAIN_MASK (BIT(0) | BIT(1))
 #define TCS3472_CONFIG_WLONG BIT(1)
 
-#define TCS3472_ATIME_TO_US(atime) (((256) - (atime)) * 2400)
+struct tcs3472_chip_info {
+	const char *name;
+	const char *calibscale_avail;
+	int agains[4];
+	/* step of ATIME and WTIME, and the RGBC init time, in us */
+	unsigned int step_us;
+	/* needs the auto-increment command type for word reads and writes */
+	bool auto_incr;
+	/* interrupts are cleared by writing AICLEAR */
+	bool aiclear;
+};
+
+static const struct tcs3472_chip_info tcs3472_chip_info = {
+	.name = "tcs3472",
+	.calibscale_avail = "1 4 16 60",
+	.agains = { 1, 4, 16, 60 },
+	.step_us = 2400,
+	.auto_incr = true,
+};
+
+static const struct tcs3472_chip_info tcs3400_chip_info = {
+	.name = "tcs3400",
+	.calibscale_avail = "1 4 16 64",
+	.agains = { 1, 4, 16, 64 },
+	.step_us = 2780,
+	.aiclear = true,
+};
 
 struct tcs3472_data {
 	struct i2c_client *client;
+	const struct tcs3472_chip_info *chip;
 	struct mutex lock;
 	int target_freq_hz;
 	int target_freq_uhz;
@@ -115,8 +148,6 @@ static const struct iio_event_spec tcs3472_events[] = {
 	.num_event_specs = _si ? 0 : ARRAY_SIZE(tcs3472_events), \
 }
 
-static const int tcs3472_agains[] = { 1, 4, 16, 60 };
-
 static const struct iio_chan_spec tcs3472_channels[] = {
 	TCS3472_CHANNEL(CLEAR, 0, TCS3472_CDATA),
 	TCS3472_CHANNEL(RED, 1, TCS3472_RDATA),
@@ -125,25 +156,42 @@ static const struct iio_chan_spec tcs3472_channels[] = {
 	IIO_CHAN_SOFT_TIMESTAMP(4),
 };
 
+static unsigned int tcs3472_atime_us(struct tcs3472_data *data, int atime)
+{
+	return (256 - atime) * data->chip->step_us;
+}
+
+/*
+ * Word registers need the auto-increment command type on the TCS3472. The
+ * TCS3400 has no command type field and takes the plain address.
+ */
+static u8 tcs3472_word_reg(struct tcs3472_data *data, u8 reg)
+{
+	if (data->chip->auto_incr)
+		return reg;
+
+	return reg & ~TCS3472_AUTO_INCR;
+}
+
 /*
  * The chip's cycle time is the sum of three components:
  *   - ATIME: the programmable RGBC integration time.
- *   - The fixed RGBC initialization time (2400 us).
+ *   - The fixed RGBC initialization time (one step, 2400 us on the TCS3472).
  *   - WTIME: the wait time, used only if WEN is set. If WLONG is active,
  *     the wait step is multiplied by 12 (2400 us -> 28800 us).
  */
 static unsigned int tcs3472_cycle_time_us(struct tcs3472_data *data)
 {
-	unsigned int atime_us = TCS3472_ATIME_TO_US(data->atime);
-	unsigned int init_us = 2400;
+	unsigned int atime_us = tcs3472_atime_us(data, data->atime);
+	unsigned int init_us = data->chip->step_us;
 	unsigned int wtime_us;
 
 	if (!(data->enable & TCS3472_ENABLE_WEN))
 		wtime_us = 0;
 	else if (data->wlong)
-		wtime_us = (256 - data->wtime) * 28800;
+		wtime_us = (256 - data->wtime) * data->chip->step_us * 12;
 	else
-		wtime_us = (256 - data->wtime) * 2400;
+		wtime_us = (256 - data->wtime) * data->chip->step_us;
 
 	return atime_us + init_us + wtime_us;
 }
@@ -219,19 +267,20 @@ static int tcs3472_read_raw(struct iio_dev *indio_dev,
 			iio_device_release_direct(indio_dev);
 			return ret;
 		}
-		ret = i2c_smbus_read_word_data(data->client, chan->address);
+		ret = i2c_smbus_read_word_data(data->client,
+					       tcs3472_word_reg(data, chan->address));
 		iio_device_release_direct(indio_dev);
 		if (ret < 0)
 			return ret;
 		*val = ret;
 		return IIO_VAL_INT;
 	case IIO_CHAN_INFO_CALIBSCALE:
-		*val = tcs3472_agains[data->control &
+		*val = data->chip->agains[data->control &
 			TCS3472_CONTROL_AGAIN_MASK];
 		return IIO_VAL_INT;
 	case IIO_CHAN_INFO_INT_TIME:
 		*val = 0;
-		*val2 = TCS3472_ATIME_TO_US(data->atime);
+		*val2 = tcs3472_atime_us(data, data->atime);
 		return IIO_VAL_INT_PLUS_MICRO;
 	case IIO_CHAN_INFO_SAMP_FREQ: {
 		unsigned int cycle_us;
@@ -253,8 +302,9 @@ static int tcs3472_read_raw(struct iio_dev *indio_dev,
 static int __tcs3472_set_sampling_freq(struct tcs3472_data *data,
 				       int val, int val2)
 {
+	unsigned int step_us = data->chip->step_us;
 	unsigned int atime_us;
-	unsigned int init_us = 2400;
+	unsigned int init_us = step_us;
 	u64 cycle_us;
 	s64 wait_us;
 	int wtime;
@@ -265,7 +315,7 @@ static int __tcs3472_set_sampling_freq(struct tcs3472_data *data,
 	if (val < 0 || val2 < 0 || (val == 0 && val2 == 0))
 		return -EINVAL;
 
-	atime_us = TCS3472_ATIME_TO_US(data->atime);
+	atime_us = tcs3472_atime_us(data, data->atime);
 
 	/*
 	 * cycle_us = 1 / freq, expressed in microseconds.
@@ -297,7 +347,7 @@ static int __tcs3472_set_sampling_freq(struct tcs3472_data *data,
 	 * Both fit comfortably in s64.
 	 */
 	wait_us = (s64)cycle_us - init_us - atime_us;
-	if (wait_us < 2400) {
+	if (wait_us < step_us) {
 		if (data->enable & TCS3472_ENABLE_WEN) {
 			u8 enable = data->enable & ~TCS3472_ENABLE_WEN;
 
@@ -329,16 +379,17 @@ static int __tcs3472_set_sampling_freq(struct tcs3472_data *data,
 		data->enable = enable;
 	}
 
-	wtime = 256 - DIV_ROUND_CLOSEST_ULL(wait_us, 2400);
+	wtime = 256 - DIV_ROUND_CLOSEST_ULL(wait_us, step_us);
 	if (wtime < 0) {
 		/*
 		 * If wait_us is too high (so the requested frequency is too
 		 * low), the resulting wait exceeds what WTIME can represent
-		 * (max 614 ms without WLONG). Enable WLONG, whose step is 12x
-		 * longer (28.8 ms instead of 2.4 ms), and recompute.
+		 * (max 614 ms without WLONG on the TCS3472). Enable WLONG,
+		 * whose step is 12x longer (28.8 ms instead of 2.4 ms), and
+		 * recompute.
 		 */
 		wlong = true;
-		wtime = 256 - DIV_ROUND_CLOSEST_ULL(wait_us, 28800);
+		wtime = 256 - DIV_ROUND_CLOSEST_ULL(wait_us, step_us * 12);
 	}
 
 	if (wlong != data->wlong) {
@@ -396,8 +447,8 @@ static int tcs3472_write_raw(struct iio_dev *indio_dev,
 	case IIO_CHAN_INFO_CALIBSCALE:
 		if (val2 != 0)
 			return -EINVAL;
-		for (i = 0; i < ARRAY_SIZE(tcs3472_agains); i++) {
-			if (val == tcs3472_agains[i]) {
+		for (i = 0; i < ARRAY_SIZE(data->chip->agains); i++) {
+			if (val == data->chip->agains[i]) {
 				data->control &= ~TCS3472_CONTROL_AGAIN_MASK;
 				data->control |= i;
 				return i2c_smbus_write_byte_data(
@@ -410,7 +461,7 @@ static int tcs3472_write_raw(struct iio_dev *indio_dev,
 		if (val != 0)
 			return -EINVAL;
 		for (i = 0; i < 256; i++) {
-			if (val2 != (256 - i) * 2400)
+			if (val2 != tcs3472_atime_us(data, i))
 				continue;
 
 			guard(mutex)(&data->lock);
@@ -499,7 +550,9 @@ static int tcs3472_write_event(struct iio_dev *indio_dev,
 		default:
 			return -EINVAL;
 		}
-		ret = i2c_smbus_write_word_data(data->client, command, val);
+		ret = i2c_smbus_write_word_data(data->client,
+						tcs3472_word_reg(data, command),
+						val);
 		if (ret)
 			return ret;
 
@@ -584,7 +637,12 @@ static irqreturn_t tcs3472_event_handler(int irq, void *priv)
 						IIO_EV_DIR_EITHER),
 				iio_get_time_ns(indio_dev));
 
-		i2c_smbus_read_byte_data(data->client, TCS3472_INTR_CLEAR);
+		if (data->chip->aiclear)
+			i2c_smbus_write_byte_data(data->client,
+						  TCS3400_AICLEAR, 0);
+		else
+			i2c_smbus_read_byte_data(data->client,
+						 TCS3472_INTR_CLEAR);
 	}
 
 	return IRQ_HANDLED;
@@ -608,7 +666,7 @@ static irqreturn_t tcs3472_trigger_handler(int irq, void *p)
 
 	iio_for_each_active_channel(indio_dev, i) {
 		ret = i2c_smbus_read_word_data(data->client,
-			TCS3472_CDATA + 2*i);
+			tcs3472_word_reg(data, TCS3472_CDATA + 2 * i));
 		if (ret < 0)
 			goto done;
 
@@ -628,12 +686,13 @@ static ssize_t tcs3472_show_int_time_available(struct device *dev,
 					struct device_attribute *attr,
 					char *buf)
 {
+	struct tcs3472_data *data = iio_priv(dev_to_iio_dev(dev));
 	size_t len = 0;
 	int i;
 
 	for (i = 1; i <= 256; i++)
 		len += scnprintf(buf + len, PAGE_SIZE - len, "0.%06d ",
-			2400 * i);
+			data->chip->step_us * i);
 
 	/* replace trailing space by newline */
 	buf[len - 1] = '\n';
@@ -641,11 +700,21 @@ static ssize_t tcs3472_show_int_time_available(struct device *dev,
 	return len;
 }
 
-static IIO_CONST_ATTR(calibscale_available, "1 4 16 60");
+static ssize_t tcs3472_show_calibscale_available(struct device *dev,
+						 struct device_attribute *attr,
+						 char *buf)
+{
+	struct tcs3472_data *data = iio_priv(dev_to_iio_dev(dev));
+
+	return sysfs_emit(buf, "%s\n", data->chip->calibscale_avail);
+}
+
+static IIO_DEVICE_ATTR(calibscale_available, 0444,
+		       tcs3472_show_calibscale_available, NULL, 0);
 static IIO_DEV_ATTR_INT_TIME_AVAIL(tcs3472_show_int_time_available);
 
 static struct attribute *tcs3472_attributes[] = {
-	&iio_const_attr_calibscale_available.dev_attr.attr,
+	&iio_dev_attr_calibscale_available.dev_attr.attr,
 	&iio_dev_attr_integration_time_available.dev_attr.attr,
 	NULL
 };
@@ -706,7 +775,6 @@ static int tcs3472_probe(struct i2c_client *client)
 		return ret;
 
 	indio_dev->info = &tcs3472_info;
-	indio_dev->name = TCS3472_DRV_NAME;
 	indio_dev->channels = tcs3472_channels;
 	indio_dev->num_channels = ARRAY_SIZE(tcs3472_channels);
 	indio_dev->modes = INDIO_DIRECT_MODE;
@@ -715,12 +783,27 @@ static int tcs3472_probe(struct i2c_client *client)
 	if (ret < 0)
 		return ret;
 
-	if (ret == 0x44)
+	switch (ret) {
+	case 0x44:
 		dev_info(dev, "TCS34721/34725 found\n");
-	else if (ret == 0x4d)
+		data->chip = &tcs3472_chip_info;
+		break;
+	case 0x4d:
 		dev_info(dev, "TCS34723/34727 found\n");
-	else
+		data->chip = &tcs3472_chip_info;
+		break;
+	case 0x90:
+		dev_info(dev, "TCS34001/34005 found\n");
+		data->chip = &tcs3400_chip_info;
+		break;
+	case 0x93:
+		dev_info(dev, "TCS34003/34007 found\n");
+		data->chip = &tcs3400_chip_info;
+		break;
+	default:
 		return -ENODEV;
+	}
+	indio_dev->name = data->chip->name;
 
 	ret = i2c_smbus_read_byte_data(data->client, TCS3472_CONTROL);
 	if (ret < 0)
@@ -742,12 +825,14 @@ static int tcs3472_probe(struct i2c_client *client)
 		return ret;
 	data->wlong = (ret & TCS3472_CONFIG_WLONG) ? 1 : 0;
 
-	ret = i2c_smbus_read_word_data(data->client, TCS3472_AILT);
+	ret = i2c_smbus_read_word_data(data->client,
+				       tcs3472_word_reg(data, TCS3472_AILT));
 	if (ret < 0)
 		return ret;
 	data->low_thresh = ret;
 
-	ret = i2c_smbus_read_word_data(data->client, TCS3472_AIHT);
+	ret = i2c_smbus_read_word_data(data->client,
+				       tcs3472_word_reg(data, TCS3472_AIHT));
 	if (ret < 0)
 		return ret;
 	data->high_thresh = ret;
@@ -844,14 +929,23 @@ static DEFINE_SIMPLE_DEV_PM_OPS(tcs3472_pm_ops, tcs3472_suspend,
 				tcs3472_resume);
 
 static const struct i2c_device_id tcs3472_id[] = {
+	{ .name = "tcs3400" },
 	{ .name = "tcs3472" },
 	{ }
 };
 MODULE_DEVICE_TABLE(i2c, tcs3472_id);
 
+static const struct of_device_id tcs3472_of_match[] = {
+	{ .compatible = "ams,tcs3400" },
+	{ .compatible = "ams,tcs3472" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, tcs3472_of_match);
+
 static struct i2c_driver tcs3472_driver = {
 	.driver = {
 		.name	= TCS3472_DRV_NAME,
+		.of_match_table = tcs3472_of_match,
 		.pm	= pm_sleep_ptr(&tcs3472_pm_ops),
 	},
 	.probe		= tcs3472_probe,
@@ -860,5 +954,5 @@ static struct i2c_driver tcs3472_driver = {
 module_i2c_driver(tcs3472_driver);
 
 MODULE_AUTHOR("Peter Meerwald <pmeerw@pmeerw.net>");
-MODULE_DESCRIPTION("TCS3472 color light sensors driver");
+MODULE_DESCRIPTION("TCS3472 and TCS3400 color light sensors driver");
 MODULE_LICENSE("GPL");

-- 
2.43.0

