From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Fri, 06 Nov 2026 21:56:30 +0100
Subject: [PATCH v2 2/2] iio: light: Add Capella CM3217 ambient light sensor
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-upstream-iio-cm3217-v2-2-d97adde9171c@tsv-stahl-riesa.de>
References: <20261106-upstream-iio-cm3217-v2-0-d97adde9171c@tsv-stahl-riesa.de>
In-Reply-To: <20261106-upstream-iio-cm3217-v2-0-d97adde9171c@tsv-stahl-riesa.de>
To: Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Kevin Tsai <ktsai@capellamicro.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793998608; l=14761;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=55xTi2FXx0C0Q+ylXh3osYdNQ8yr1kEEfz/B/FieAac=;
 b=HpGWJxJwFa+FA2HDG+jIAQVMa2I5dTgxE6+y890znT3QZ4vth0/Y9tm+5i5DwAyCsiQz1bj/K
 2e+CK+GlcLeAjk7+dG3bTa12l0DkPC/KKIAk9gm7KNXnJPsVWK+UhYs
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CM3217 has no registers and no ID. Writing a byte to address 0x10
or 0x11 sets command byte 1 or 2, reading a byte from 0x10 or 0x11
returns the high or low byte of the 16-bit light count.

Command byte 1 holds the shutdown bit and the IT_T field (1/2 T, 1 T,
2 T or 4 T), command byte 2 the FD_IT field (800 ms down to 66 ms). The
count scales linearly with both. The driver exposes FD_IT as the
integration time and IT_T through the scale, so the scale list offers
four ranges for each integration time.

The datasheet is not public. The bit fields, the reserved bits that are
written as 1 and the startup setting of 2 T and 100 ms come from NVIDIA's
downstream drivers (drivers/staging/iio/light/cm3217.c in the 3.4 kernel
rel-tegranote-r8 and the 3.10 kernel
android-tegra-flounder-3.10-nougat-mr1.1). One value differs: the vendor
header defines 4 T as 4 << 2, which is outside the two-bit field. On a
Tegra Note 7 field value 3 gave four times the 1 T count, so the driver
uses that. For the resolution, Capella
gives a range of 0.01875 to 119156 lux. The driver takes 0.01875 lux
per count at 4 T and 800 ms. This matches both the upper end (65535
counts at 1/2 T and 66 ms) and the 0.3 lux per count that the NVIDIA
3.4 driver uses at 2 T and 100 ms.

The sensor has no data-ready flag, and a new setting only takes effect
when the conversion in progress ends. A conversion takes IT_T times
FD_IT, up to 3.2 s. Leaving shutdown starts a new one at once, so the
driver passes through shutdown on every change and waits one conversion
period plus a margin before it reads the count. The timing was measured
on a Tegra Note 7.

Tested-by: Svyatoslav Ryhel <clamor95@gmail.com> # Tegratab P1988
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/iio/light/Kconfig  |  10 ++
 drivers/iio/light/Makefile |   1 +
 drivers/iio/light/cm3217.c | 407 +++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 418 insertions(+)

diff --git a/drivers/iio/light/Kconfig b/drivers/iio/light/Kconfig
index d0dea4f3113b..451d26e6e97d 100644
--- a/drivers/iio/light/Kconfig
+++ b/drivers/iio/light/Kconfig
@@ -196,6 +196,16 @@ config BH1780
 	  To compile this driver as a module, choose M here: the module will
 	  be called bh1780.
 
+config CM3217
+	tristate "Capella CM3217 ambient light sensor"
+	depends on I2C
+	help
+	  Say Y here to build support for the Capella Microsystems CM3217
+	  ambient light sensor.
+
+	  To compile this driver as a module, choose M here: the module will
+	  be called cm3217.
+
 config CM32181
 	depends on I2C
 	tristate "CM32181 driver"
diff --git a/drivers/iio/light/Makefile b/drivers/iio/light/Makefile
index 9fc046e636a2..5daff8ef0daa 100644
--- a/drivers/iio/light/Makefile
+++ b/drivers/iio/light/Makefile
@@ -20,6 +20,7 @@ obj-$(CONFIG_AS7343)		+= as7343.o
 obj-$(CONFIG_BH1745)		+= bh1745.o
 obj-$(CONFIG_BH1750)		+= bh1750.o
 obj-$(CONFIG_BH1780)		+= bh1780.o
+obj-$(CONFIG_CM3217)		+= cm3217.o
 obj-$(CONFIG_CM32181)		+= cm32181.o
 obj-$(CONFIG_CM3232)		+= cm3232.o
 obj-$(CONFIG_CM3323)		+= cm3323.o
diff --git a/drivers/iio/light/cm3217.c b/drivers/iio/light/cm3217.c
new file mode 100644
index 000000000000..cab352196f4f
--- /dev/null
+++ b/drivers/iio/light/cm3217.c
@@ -0,0 +1,407 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Capella CM3217 ambient light sensor driver
+ *
+ * The CM3217 has no registers. It answers on two fixed I2C addresses:
+ * writing a byte to 0x10 or 0x11 sets command byte 1 or 2, reading a byte
+ * from 0x10 or 0x11 returns the MSB or LSB of the 16-bit light count.
+ *
+ * Copyright (C) 2026 Patrick Fischer <admin@tsv-stahl-riesa.de>
+ */
+
+#include <linux/array_size.h>
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/build_bug.h>
+#include <linux/cleanup.h>
+#include <linux/delay.h>
+#include <linux/device.h>
+#include <linux/err.h>
+#include <linux/i2c.h>
+#include <linux/ktime.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/pm.h>
+#include <linux/regulator/consumer.h>
+#include <linux/time64.h>
+#include <linux/types.h>
+#include <linux/units.h>
+
+#include <linux/iio/iio.h>
+
+#define CM3217_ADDR_CMD2_LSB	0x11
+
+#define CM3217_CMD1_RSVD	BIT(5)		/* reserved, set to 1 */
+#define CM3217_CMD1_IT_T	GENMASK(3, 2)	/* 1/2 T, 1 T, 2 T, 4 T */
+#define CM3217_CMD1_WDM		BIT(1)		/* set to 1 like the vendor driver */
+#define CM3217_CMD1_SD		BIT(0)		/* shutdown when set */
+
+#define CM3217_CMD2_FD_IT	GENMASK(7, 5)
+
+#define CM3217_IT_T_2T		2
+#define CM3217_FD_IT_100MS	5
+
+/*
+ * 0.01875 lux per count at 4 T and 800 ms, the finest resolution. The
+ * resolution is inversely proportional to IT_T and FD_IT, so keep it as
+ * lux per count times milliseconds: 0.01875 lux * 800 ms = 15 lux * ms.
+ */
+#define CM3217_NLUX_MS		(15ULL * NANO)
+
+#define CM3217_MARGIN_MS	10
+
+/* FD_IT settings in seconds, indexed by the field value */
+static const int cm3217_int_time_avail[][2] = {
+	{ 0, 800000 }, { 0, 400000 }, { 0, 266000 }, { 0, 200000 },
+	{ 0, 130000 }, { 0, 100000 }, { 0, 80000 }, { 0, 66000 },
+};
+
+/* Scale in lux per count at FD_IT = ms milliseconds and IT_T = 1/2 T << it_t */
+#define CM3217_SCALE(ms, it_t) {				\
+	(CM3217_NLUX_MS << (3 - (it_t))) / (ms) / NANO,		\
+	(CM3217_NLUX_MS << (3 - (it_t))) / (ms) % NANO,		\
+}
+
+#define CM3217_SCALES(ms) {					\
+	CM3217_SCALE(ms, 0), CM3217_SCALE(ms, 1),		\
+	CM3217_SCALE(ms, 2), CM3217_SCALE(ms, 3),		\
+}
+
+/* Available scales, indexed by FD_IT and then by IT_T */
+static const int cm3217_scale_avail[][4][2] = {
+	CM3217_SCALES(800), CM3217_SCALES(400),
+	CM3217_SCALES(266), CM3217_SCALES(200),
+	CM3217_SCALES(130), CM3217_SCALES(100),
+	CM3217_SCALES(80), CM3217_SCALES(66),
+};
+
+static_assert(ARRAY_SIZE(cm3217_scale_avail) ==
+	      ARRAY_SIZE(cm3217_int_time_avail));
+
+struct cm3217_data {
+	struct i2c_client *client;
+	struct i2c_client *client_lsb;
+	/* protects the command bytes and ready */
+	struct mutex lock;
+	u8 cmd1;
+	u8 cmd2;
+	ktime_t ready;
+};
+
+static unsigned int cm3217_conv_ms(struct cm3217_data *data)
+	__must_hold(&data->lock)
+{
+	unsigned int fd_it = FIELD_GET(CM3217_CMD2_FD_IT, data->cmd2);
+	unsigned int it_t = FIELD_GET(CM3217_CMD1_IT_T, data->cmd1);
+
+	return ((cm3217_int_time_avail[fd_it][1] / USEC_PER_MSEC) << it_t) / 2;
+}
+
+static int cm3217_power_down(struct cm3217_data *data, u8 cmd1)
+{
+	return i2c_smbus_write_byte(data->client, cmd1 | CM3217_CMD1_SD);
+}
+
+/*
+ * A new setting only takes effect when the conversion in progress ends,
+ * which can take up to 3.2 s. Leaving shutdown starts a new conversion
+ * right away, so pass through shutdown on every change.
+ */
+static int cm3217_write_cmd(struct cm3217_data *data, u8 cmd1, u8 cmd2)
+	__must_hold(&data->lock)
+{
+	unsigned int conv_ms;
+	int ret;
+
+	ret = cm3217_power_down(data, cmd1);
+	if (ret)
+		return ret;
+
+	ret = i2c_smbus_write_byte(data->client_lsb, cmd2);
+	if (ret)
+		return ret;
+
+	ret = i2c_smbus_write_byte(data->client, cmd1);
+	if (ret)
+		return ret;
+
+	data->cmd1 = cmd1;
+	data->cmd2 = cmd2;
+
+	/* the first count is ready after one conversion */
+	conv_ms = cm3217_conv_ms(data);
+	data->ready = ktime_add_ms(ktime_get(),
+				   conv_ms + conv_ms / 10 + CM3217_MARGIN_MS);
+
+	return 0;
+}
+
+static int cm3217_read_count(struct cm3217_data *data, int *val)
+	__must_hold(&data->lock)
+{
+	s64 wait_ms;
+	int lsb, msb;
+
+	wait_ms = ktime_ms_delta(data->ready, ktime_get());
+	if (wait_ms > 0)
+		msleep(wait_ms);
+
+	lsb = i2c_smbus_read_byte(data->client_lsb);
+	if (lsb < 0)
+		return lsb;
+
+	msb = i2c_smbus_read_byte(data->client);
+	if (msb < 0)
+		return msb;
+
+	*val = msb << 8 | lsb;
+
+	return 0;
+}
+
+static const struct iio_chan_spec cm3217_channels[] = {
+	{
+		.type = IIO_LIGHT,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
+				      BIT(IIO_CHAN_INFO_SCALE),
+		.info_mask_separate_available = BIT(IIO_CHAN_INFO_SCALE),
+		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_INT_TIME),
+		.info_mask_shared_by_all_available = BIT(IIO_CHAN_INFO_INT_TIME),
+	},
+};
+
+static int cm3217_read_raw(struct iio_dev *indio_dev,
+			   struct iio_chan_spec const *chan,
+			   int *val, int *val2, long mask)
+{
+	struct cm3217_data *data = iio_priv(indio_dev);
+	unsigned int fd_it, it_t;
+	int ret;
+
+	guard(mutex)(&data->lock);
+
+	fd_it = FIELD_GET(CM3217_CMD2_FD_IT, data->cmd2);
+	it_t = FIELD_GET(CM3217_CMD1_IT_T, data->cmd1);
+
+	switch (mask) {
+	case IIO_CHAN_INFO_RAW:
+		ret = cm3217_read_count(data, val);
+		if (ret)
+			return ret;
+		return IIO_VAL_INT;
+	case IIO_CHAN_INFO_SCALE:
+		*val = cm3217_scale_avail[fd_it][it_t][0];
+		*val2 = cm3217_scale_avail[fd_it][it_t][1];
+		return IIO_VAL_INT_PLUS_NANO;
+	case IIO_CHAN_INFO_INT_TIME:
+		*val = cm3217_int_time_avail[fd_it][0];
+		*val2 = cm3217_int_time_avail[fd_it][1];
+		return IIO_VAL_INT_PLUS_MICRO;
+	default:
+		return -EINVAL;
+	}
+}
+
+static int cm3217_read_avail(struct iio_dev *indio_dev,
+			     struct iio_chan_spec const *chan,
+			     const int **vals, int *type, int *length,
+			     long mask)
+{
+	struct cm3217_data *data = iio_priv(indio_dev);
+	unsigned int fd_it;
+
+	switch (mask) {
+	case IIO_CHAN_INFO_SCALE:
+		scoped_guard(mutex, &data->lock)
+			fd_it = FIELD_GET(CM3217_CMD2_FD_IT, data->cmd2);
+		*vals = (const int *)cm3217_scale_avail[fd_it];
+		*length = 2 * ARRAY_SIZE(cm3217_scale_avail[0]);
+		*type = IIO_VAL_INT_PLUS_NANO;
+		return IIO_AVAIL_LIST;
+	case IIO_CHAN_INFO_INT_TIME:
+		*vals = (const int *)cm3217_int_time_avail;
+		*length = 2 * ARRAY_SIZE(cm3217_int_time_avail);
+		*type = IIO_VAL_INT_PLUS_MICRO;
+		return IIO_AVAIL_LIST;
+	default:
+		return -EINVAL;
+	}
+}
+
+static int cm3217_find_avail(const int (*avail)[2], unsigned int len,
+			     int val, int val2)
+{
+	for (unsigned int i = 0; i < len; i++) {
+		if (avail[i][0] == val && avail[i][1] == val2)
+			return i;
+	}
+
+	return -EINVAL;
+}
+
+static int cm3217_write_raw(struct iio_dev *indio_dev,
+			    struct iio_chan_spec const *chan,
+			    int val, int val2, long mask)
+{
+	struct cm3217_data *data = iio_priv(indio_dev);
+	unsigned int fd_it;
+	u8 cmd1, cmd2;
+	int i;
+
+	guard(mutex)(&data->lock);
+
+	switch (mask) {
+	case IIO_CHAN_INFO_SCALE:
+		fd_it = FIELD_GET(CM3217_CMD2_FD_IT, data->cmd2);
+		i = cm3217_find_avail(cm3217_scale_avail[fd_it],
+				      ARRAY_SIZE(cm3217_scale_avail[0]),
+				      val, val2);
+		if (i < 0)
+			return i;
+
+		cmd1 = data->cmd1 & ~CM3217_CMD1_IT_T;
+		cmd1 |= FIELD_PREP(CM3217_CMD1_IT_T, i);
+
+		return cm3217_write_cmd(data, cmd1, data->cmd2);
+	case IIO_CHAN_INFO_INT_TIME:
+		i = cm3217_find_avail(cm3217_int_time_avail,
+				      ARRAY_SIZE(cm3217_int_time_avail),
+				      val, val2);
+		if (i < 0)
+			return i;
+
+		cmd2 = FIELD_PREP(CM3217_CMD2_FD_IT, i);
+
+		return cm3217_write_cmd(data, data->cmd1, cmd2);
+	default:
+		return -EINVAL;
+	}
+}
+
+static int cm3217_write_raw_get_fmt(struct iio_dev *indio_dev,
+				    struct iio_chan_spec const *chan,
+				    long mask)
+{
+	switch (mask) {
+	case IIO_CHAN_INFO_SCALE:
+		return IIO_VAL_INT_PLUS_NANO;
+	case IIO_CHAN_INFO_INT_TIME:
+		return IIO_VAL_INT_PLUS_MICRO;
+	default:
+		return -EINVAL;
+	}
+}
+
+static const struct iio_info cm3217_info = {
+	.read_raw = cm3217_read_raw,
+	.read_avail = cm3217_read_avail,
+	.write_raw = cm3217_write_raw,
+	.write_raw_get_fmt = cm3217_write_raw_get_fmt,
+};
+
+static void cm3217_power_off(void *_data)
+{
+	struct cm3217_data *data = _data;
+
+	cm3217_power_down(data, data->cmd1);
+}
+
+static int cm3217_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct cm3217_data *data;
+	struct iio_dev *indio_dev;
+	u8 cmd1, cmd2;
+	int ret;
+
+	indio_dev = devm_iio_device_alloc(dev, sizeof(*data));
+	if (!indio_dev)
+		return -ENOMEM;
+
+	data = iio_priv(indio_dev);
+	data->client = client;
+	i2c_set_clientdata(client, indio_dev);
+
+	ret = devm_mutex_init(dev, &data->lock);
+	if (ret)
+		return ret;
+
+	ret = devm_regulator_get_enable(dev, "vdd");
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to enable vdd supply\n");
+
+	data->client_lsb = devm_i2c_new_dummy_device(dev, client->adapter,
+						     CM3217_ADDR_CMD2_LSB);
+	if (IS_ERR(data->client_lsb))
+		return dev_err_probe(dev, PTR_ERR(data->client_lsb),
+				     "failed to register second address\n");
+
+	/* Start with the setting of the vendor driver: 2 T, 100 ms */
+	cmd1 = CM3217_CMD1_RSVD | CM3217_CMD1_WDM |
+	       FIELD_PREP(CM3217_CMD1_IT_T, CM3217_IT_T_2T);
+	cmd2 = FIELD_PREP(CM3217_CMD2_FD_IT, CM3217_FD_IT_100MS);
+
+	scoped_guard(mutex, &data->lock)
+		ret = cm3217_write_cmd(data, cmd1, cmd2);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to power on\n");
+
+	ret = devm_add_action_or_reset(dev, cm3217_power_off, data);
+	if (ret)
+		return ret;
+
+	indio_dev->name = "cm3217";
+	indio_dev->info = &cm3217_info;
+	indio_dev->channels = cm3217_channels;
+	indio_dev->num_channels = ARRAY_SIZE(cm3217_channels);
+	indio_dev->modes = INDIO_DIRECT_MODE;
+
+	return devm_iio_device_register(dev, indio_dev);
+}
+
+static int cm3217_suspend(struct device *dev)
+{
+	struct cm3217_data *data = iio_priv(dev_get_drvdata(dev));
+
+	guard(mutex)(&data->lock);
+
+	return cm3217_power_down(data, data->cmd1);
+}
+
+static int cm3217_resume(struct device *dev)
+{
+	struct cm3217_data *data = iio_priv(dev_get_drvdata(dev));
+
+	guard(mutex)(&data->lock);
+
+	return cm3217_write_cmd(data, data->cmd1, data->cmd2);
+}
+
+static DEFINE_SIMPLE_DEV_PM_OPS(cm3217_pm_ops, cm3217_suspend, cm3217_resume);
+
+static const struct i2c_device_id cm3217_id[] = {
+	{ .name = "cm3217" },
+	{ }
+};
+MODULE_DEVICE_TABLE(i2c, cm3217_id);
+
+static const struct of_device_id cm3217_of_match[] = {
+	{ .compatible = "capella,cm3217" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, cm3217_of_match);
+
+static struct i2c_driver cm3217_driver = {
+	.driver = {
+		.name = "cm3217",
+		.of_match_table = cm3217_of_match,
+		.pm = pm_sleep_ptr(&cm3217_pm_ops),
+	},
+	.probe = cm3217_probe,
+	.id_table = cm3217_id,
+};
+module_i2c_driver(cm3217_driver);
+
+MODULE_AUTHOR("Patrick Fischer <admin@tsv-stahl-riesa.de>");
+MODULE_DESCRIPTION("Capella CM3217 ambient light sensor driver");
+MODULE_LICENSE("GPL");

-- 
2.56.0

