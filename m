From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Thu, 26 Nov 2026 09:11:48 +0100
Subject: [PATCH v2 2/2] iio: light: add ams OSRAM TCS3430 XYZ and ambient
 light sensor driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-iio-tcs3430-v2-2-6c5329d20919@gmail.com>
References: <20261126-iio-tcs3430-v2-0-6c5329d20919@gmail.com>
In-Reply-To: <20261126-iio-tcs3430-v2-0-6c5329d20919@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795680706; l=16430;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=in4VebEdFxHqAsk+FhtC1r2kz9sL2OuipHJfc+M1vPY=;
 b=7ZVAIT8w9SWYAcgWdhmwLcj3f3GuN1mGcIizpermIeAN6SNbYC38BKIJpeursZZIQJi5Ujx8o
 YKly11S+NdWDcP1KixCFZS8D+cqxInjpNJUU9lhcgDC0N8y2ELcN5ZM
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an IIO driver for the ams OSRAM TCS3430 ambient light and CIE 1931
XYZ tristimulus color sensor (found at I2C address 0x39 on devices such
as the Microsoft Surface Pro X).

The driver exposes:
- Illuminance (photopic Y channel) with raw counts and lux scale
- Modified intensity channels for X, Y, Z, and IR1
- Selectable scale and integration time via the IIO GTS helper across
  1x/4x/16x/64x/128x gain and 50.04/100.08/200.16/400.32 ms integration
  time settings
- Regulator management and system sleep suspend/resume support

Tested on Microsoft Surface Pro X SQ2 (SC8180X).

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 MAINTAINERS                 |   1 +
 drivers/iio/light/Kconfig   |  12 ++
 drivers/iio/light/Makefile  |   1 +
 drivers/iio/light/tcs3430.c | 489 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 503 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index ea8ebd8ccd849702e82bf6aaeb4d8d60c2255628..0534464e1d5df51a5ddbc77798143fa1eb03f9cc 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1493,6 +1493,7 @@ AMS TCS3430 DRIVER
 M:	Robert Ijtsma <robertijtsma@gmail.com>
 S:	Maintained
 F:	Documentation/devicetree/bindings/iio/light/ams,tcs3430.yaml
+F:	drivers/iio/light/tcs3430.c
 
 AMT (Automatic Multicast Tunneling)
 M:	Taehee Yoo <ap420073@gmail.com>
diff --git a/drivers/iio/light/Kconfig b/drivers/iio/light/Kconfig
index 462fff1ddef20700aedf20743c3e8a36017a9151..d1da709a0587a95875d265484f82c56e04902fd6 100644
--- a/drivers/iio/light/Kconfig
+++ b/drivers/iio/light/Kconfig
@@ -609,6 +609,18 @@ config TCS3414
 	  This driver can also be built as a module.  If so, the module
 	  will be called tcs3414.
 
+config TCS3430
+	tristate "ams OSRAM TCS3430 ambient light and XYZ color sensor"
+	depends on I2C
+	select IIO_GTS_HELPER
+	select REGMAP_I2C
+	help
+	  If you say yes here you get support for the ams OSRAM TCS3430
+	  ambient light and CIE 1931 XYZ tristimulus color sensor.
+
+	  This driver can also be built as a module.  If so, the module
+	  will be called tcs3430.
+
 config TCS3472
 	tristate "TAOS TCS3472 color light-to-digital converter"
 	depends on I2C
diff --git a/drivers/iio/light/Makefile b/drivers/iio/light/Makefile
index 6672ed01a8193b9e96a9c84ba5d069f37b307a08..cd7b42e5524678c112e0ffa1b4dc07222077262d 100644
--- a/drivers/iio/light/Makefile
+++ b/drivers/iio/light/Makefile
@@ -56,6 +56,7 @@ obj-$(CONFIG_ST_UVIS25)		+= st_uvis25_core.o
 obj-$(CONFIG_ST_UVIS25_I2C)	+= st_uvis25_i2c.o
 obj-$(CONFIG_ST_UVIS25_SPI)	+= st_uvis25_spi.o
 obj-$(CONFIG_TCS3414)		+= tcs3414.o
+obj-$(CONFIG_TCS3430)		+= tcs3430.o
 obj-$(CONFIG_TCS3472)		+= tcs3472.o
 obj-$(CONFIG_SENSORS_TSL2563)	+= tsl2563.o
 obj-$(CONFIG_TSL2583)		+= tsl2583.o
diff --git a/drivers/iio/light/tcs3430.c b/drivers/iio/light/tcs3430.c
new file mode 100644
index 0000000000000000000000000000000000000000..226568c95e8da3217be1650186a716f1bef3bebb
--- /dev/null
+++ b/drivers/iio/light/tcs3430.c
@@ -0,0 +1,489 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * IIO driver for ams OSRAM TCS3430 Ambient Light and CIE 1931 XYZ Sensor
+ *
+ * Copyright (C) 2026 Robert Ijtsma <robertijtsma@gmail.com>
+ *
+ * Datasheet:
+ *   https://look.ams-osram.com/m/43d518b4cd81e3f2/original/TCS3430-DS000539.pdf
+ */
+
+#include <linux/array_size.h>
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/cleanup.h>
+#include <linux/device.h>
+#include <linux/err.h>
+#include <linux/i2c.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/pm.h>
+#include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
+#include <linux/types.h>
+
+#include <asm/byteorder.h>
+
+#include <linux/iio/iio.h>
+#include <linux/iio/iio-gts-helper.h>
+
+#define TCS3430_REG_ENABLE		0x80
+#define   TCS3430_ENABLE_PON		BIT(0)
+#define   TCS3430_ENABLE_AEN		BIT(1)
+#define TCS3430_REG_ATIME		0x81
+#define TCS3430_REG_CFG1		0x90
+#define   TCS3430_CFG1_AGAIN_MASK	GENMASK(1, 0)
+#define TCS3430_REG_ID			0x92
+#define   TCS3430_ID_MASK		GENMASK(7, 2)
+#define   TCS3430_ID_VAL		0xdc
+#define TCS3430_REG_CH0DATAL		0x94
+#define TCS3430_REG_CH1DATAL		0x96
+#define TCS3430_REG_CH2DATAL		0x98
+#define TCS3430_REG_CH3DATAL		0x9a
+#define TCS3430_REG_CFG2		0x9f
+#define   TCS3430_CFG2_DEFAULT		0x04
+#define   TCS3430_CFG2_HGAIN		BIT(4)
+#define TCS3430_REG_CFG3		0xab
+#define   TCS3430_CFG3_DEFAULT		0x0c
+#define TCS3430_REG_INTENAB		0xdd
+
+#define TCS3430_DEFAULT_GAIN_SEL	3	/* 64x */
+#define TCS3430_DEFAULT_ATIME_SEL	71	/* 72 * 2.78 ms = 200.16 ms */
+
+/*
+ * Photopic Y channel typical sensitivity from datasheet optical characteristics:
+ * ~0.537 counts/lux at AGAIN = 16x and ATIME = 100 ms (36 cycles), giving:
+ *   lux/count = 2980 / (gain * integration_time_ms)
+ *
+ * At minimum gain (1x) and shortest integration time (50.04 ms, 18 cycles):
+ *   max_scale = 2980 / 50.04 = 59.552358113 lux/count
+ */
+#define TCS3430_MAX_SCALE_INT		59
+#define TCS3430_MAX_SCALE_NANO		552358113
+
+static const struct iio_gain_sel_pair tcs3430_gain_sel[] = {
+	GAIN_SCALE_GAIN(1, 0),
+	GAIN_SCALE_GAIN(4, 1),
+	GAIN_SCALE_GAIN(16, 2),
+	GAIN_SCALE_GAIN(64, 3),
+	GAIN_SCALE_GAIN(128, 4),
+};
+
+/*
+ * Integration time = (ATIME + 1) * 2.78 ms.
+ * Default 200.16 ms (72 cycles, ATIME = 71) is placed first so
+ * iio_gts_find_gain_time_sel_for_scale() prefers it when possible.
+ */
+static const struct iio_itime_sel_mul tcs3430_itime_sel[] = {
+	GAIN_SCALE_ITIME_US(200160, 71, 4),
+	GAIN_SCALE_ITIME_US(100080, 35, 2),
+	GAIN_SCALE_ITIME_US(50040, 17, 1),
+	GAIN_SCALE_ITIME_US(400320, 143, 8),
+};
+
+struct tcs3430_data {
+	struct regmap *regmap;
+	struct iio_gts gts;
+	/* Protects device configuration across multi-register updates */
+	struct mutex lock;
+	u8 gain_sel;
+	u8 atime;
+};
+
+static const struct regmap_config tcs3430_regmap_config = {
+	.name = "tcs3430",
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = TCS3430_REG_INTENAB,
+};
+
+static int tcs3430_apply_gain(struct tcs3430_data *data, u8 gain_sel)
+{
+	u8 cfg1, cfg2;
+	int ret;
+
+	if (gain_sel == 4) {
+		cfg1 = FIELD_PREP(TCS3430_CFG1_AGAIN_MASK, 3);
+		cfg2 = TCS3430_CFG2_DEFAULT | TCS3430_CFG2_HGAIN;
+	} else {
+		cfg1 = FIELD_PREP(TCS3430_CFG1_AGAIN_MASK, gain_sel);
+		cfg2 = TCS3430_CFG2_DEFAULT;
+	}
+
+	ret = regmap_write(data->regmap, TCS3430_REG_CFG1, cfg1);
+	if (ret)
+		return ret;
+
+	ret = regmap_write(data->regmap, TCS3430_REG_CFG2, cfg2);
+	if (ret)
+		return ret;
+
+	data->gain_sel = gain_sel;
+	return 0;
+}
+
+static int tcs3430_apply_itime(struct tcs3430_data *data, u8 atime)
+{
+	int ret;
+
+	ret = regmap_write(data->regmap, TCS3430_REG_ATIME, atime);
+	if (ret)
+		return ret;
+
+	data->atime = atime;
+	return 0;
+}
+
+static int tcs3430_init_hw(struct tcs3430_data *data)
+{
+	int ret;
+
+	ret = regmap_write(data->regmap, TCS3430_REG_ENABLE, 0x00);
+	if (ret)
+		return ret;
+
+	ret = tcs3430_apply_itime(data, data->atime);
+	if (ret)
+		return ret;
+
+	ret = tcs3430_apply_gain(data, data->gain_sel);
+	if (ret)
+		return ret;
+
+	ret = regmap_write(data->regmap, TCS3430_REG_CFG3,
+			   TCS3430_CFG3_DEFAULT);
+	if (ret)
+		return ret;
+
+	ret = regmap_write(data->regmap, TCS3430_REG_INTENAB, 0x00);
+	if (ret)
+		return ret;
+
+	return regmap_write(data->regmap, TCS3430_REG_ENABLE,
+			    TCS3430_ENABLE_PON | TCS3430_ENABLE_AEN);
+}
+
+static void tcs3430_power_off(void *priv)
+{
+	struct tcs3430_data *data = priv;
+
+	regmap_write(data->regmap, TCS3430_REG_ENABLE, 0x00);
+}
+
+static int tcs3430_read_raw(struct iio_dev *indio_dev,
+			    const struct iio_chan_spec *chan,
+			    int *val, int *val2, long mask)
+{
+	struct tcs3430_data *data = iio_priv(indio_dev);
+	int ret;
+
+	switch (mask) {
+	case IIO_CHAN_INFO_RAW: {
+		__le16 raw;
+
+		guard(mutex)(&data->lock);
+		ret = regmap_bulk_read(data->regmap, chan->address, &raw,
+				       sizeof(raw));
+		if (ret)
+			return ret;
+		*val = le16_to_cpu(raw);
+		return IIO_VAL_INT;
+	}
+
+	case IIO_CHAN_INFO_SCALE: {
+		int gain, itime;
+
+		guard(mutex)(&data->lock);
+		gain = iio_gts_find_gain_by_sel(&data->gts, data->gain_sel);
+		if (gain < 0)
+			return gain;
+
+		itime = iio_gts_find_int_time_by_sel(&data->gts, data->atime);
+		if (itime < 0)
+			return itime;
+
+		ret = iio_gts_get_scale(&data->gts, gain, itime, val, val2);
+		if (ret)
+			return ret;
+
+		return IIO_VAL_INT_PLUS_NANO;
+	}
+
+	case IIO_CHAN_INFO_INT_TIME: {
+		int itime;
+
+		guard(mutex)(&data->lock);
+		itime = iio_gts_find_int_time_by_sel(&data->gts, data->atime);
+		if (itime < 0)
+			return itime;
+
+		*val = 0;
+		*val2 = itime;
+		return IIO_VAL_INT_PLUS_MICRO;
+	}
+
+	default:
+		return -EINVAL;
+	}
+}
+
+static int tcs3430_set_scale(struct tcs3430_data *data, int val, int val2)
+{
+	int gain_sel, time_sel, ret;
+	bool keep_time = false;
+
+	ret = iio_gts_find_gain_sel_for_scale_using_time(&data->gts, data->atime,
+							 val, val2, &gain_sel);
+	if (!ret) {
+		keep_time = true;
+		time_sel = data->atime;
+	} else {
+		ret = iio_gts_find_gain_time_sel_for_scale(&data->gts, val, val2,
+							   &gain_sel, &time_sel);
+		if (ret)
+			return ret;
+	}
+
+	if (!keep_time) {
+		ret = tcs3430_apply_itime(data, time_sel);
+		if (ret)
+			return ret;
+	}
+
+	return tcs3430_apply_gain(data, gain_sel);
+}
+
+static int tcs3430_set_itime(struct tcs3430_data *data, int val, int val2)
+{
+	struct device *dev = regmap_get_device(data->regmap);
+	int prev_gain, prev_time, new_gain, gain_sel, time_sel, ret;
+	bool in_range;
+
+	if (val || !iio_gts_valid_time(&data->gts, val2))
+		return -EINVAL;
+
+	prev_time = iio_gts_find_int_time_by_sel(&data->gts, data->atime);
+	if (prev_time < 0)
+		return prev_time;
+	if (prev_time == val2)
+		return 0;
+
+	prev_gain = iio_gts_find_gain_by_sel(&data->gts, data->gain_sel);
+	if (prev_gain < 0)
+		return prev_gain;
+
+	ret = iio_gts_find_new_gain_by_gain_time_min(&data->gts, prev_gain,
+						     prev_time, val2,
+						     &new_gain, &in_range);
+	if (ret)
+		return ret;
+	if (!in_range)
+		dev_dbg(dev, "optimal gain out of range for integration time %d\n",
+			val2);
+
+	time_sel = iio_gts_find_sel_by_int_time(&data->gts, val2);
+	if (time_sel < 0)
+		return time_sel;
+
+	gain_sel = iio_gts_find_sel_by_gain(&data->gts, new_gain);
+	if (gain_sel < 0)
+		return gain_sel;
+
+	ret = tcs3430_apply_itime(data, time_sel);
+	if (ret)
+		return ret;
+
+	return tcs3430_apply_gain(data, gain_sel);
+}
+
+static int tcs3430_write_raw(struct iio_dev *indio_dev,
+			     const struct iio_chan_spec *chan,
+			     int val, int val2, long mask)
+{
+	struct tcs3430_data *data = iio_priv(indio_dev);
+
+	guard(mutex)(&data->lock);
+	switch (mask) {
+	case IIO_CHAN_INFO_SCALE:
+		return tcs3430_set_scale(data, val, val2);
+	case IIO_CHAN_INFO_INT_TIME:
+		return tcs3430_set_itime(data, val, val2);
+	default:
+		return -EINVAL;
+	}
+}
+
+static int tcs3430_write_raw_get_fmt(struct iio_dev *indio_dev,
+				     const struct iio_chan_spec *chan,
+				     long mask)
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
+static int tcs3430_read_avail(struct iio_dev *indio_dev,
+			      const struct iio_chan_spec *chan,
+			      const int **vals, int *type, int *length,
+			      long mask)
+{
+	struct tcs3430_data *data = iio_priv(indio_dev);
+
+	switch (mask) {
+	case IIO_CHAN_INFO_SCALE:
+		return iio_gts_all_avail_scales(&data->gts, vals, type, length);
+	case IIO_CHAN_INFO_INT_TIME:
+		return iio_gts_avail_times(&data->gts, vals, type, length);
+	default:
+		return -EINVAL;
+	}
+}
+
+#define TCS3430_INTENSITY_CHANNEL(_mod, _addr) {			\
+	.type = IIO_INTENSITY,						\
+	.modified = 1,							\
+	.channel2 = (_mod),						\
+	.address = (_addr),						\
+	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW),			\
+	.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_INT_TIME),		\
+	.info_mask_shared_by_all_available =				\
+		BIT(IIO_CHAN_INFO_INT_TIME),				\
+}
+
+static const struct iio_chan_spec tcs3430_channels[] = {
+	{
+		.type = IIO_LIGHT,
+		.address = TCS3430_REG_CH1DATAL,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
+				      BIT(IIO_CHAN_INFO_SCALE),
+		.info_mask_separate_available = BIT(IIO_CHAN_INFO_SCALE),
+		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_INT_TIME),
+		.info_mask_shared_by_all_available =
+			BIT(IIO_CHAN_INFO_INT_TIME),
+	},
+	TCS3430_INTENSITY_CHANNEL(IIO_MOD_Z, TCS3430_REG_CH0DATAL),
+	TCS3430_INTENSITY_CHANNEL(IIO_MOD_Y, TCS3430_REG_CH1DATAL),
+	TCS3430_INTENSITY_CHANNEL(IIO_MOD_LIGHT_IR, TCS3430_REG_CH2DATAL),
+	TCS3430_INTENSITY_CHANNEL(IIO_MOD_X, TCS3430_REG_CH3DATAL),
+};
+
+static const struct iio_info tcs3430_info = {
+	.read_raw = tcs3430_read_raw,
+	.write_raw = tcs3430_write_raw,
+	.write_raw_get_fmt = tcs3430_write_raw_get_fmt,
+	.read_avail = tcs3430_read_avail,
+};
+
+static int tcs3430_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct tcs3430_data *data;
+	struct iio_dev *indio_dev;
+	unsigned int dev_id;
+	int ret;
+
+	ret = devm_regulator_get_enable(dev, "vdd");
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to enable vdd supply\n");
+
+	indio_dev = devm_iio_device_alloc(dev, sizeof(*data));
+	if (!indio_dev)
+		return -ENOMEM;
+
+	data = iio_priv(indio_dev);
+	data->regmap = devm_regmap_init_i2c(client, &tcs3430_regmap_config);
+	if (IS_ERR(data->regmap))
+		return dev_err_probe(dev, PTR_ERR(data->regmap),
+				     "failed to initialize regmap\n");
+
+	ret = devm_iio_init_iio_gts(dev, TCS3430_MAX_SCALE_INT,
+				    TCS3430_MAX_SCALE_NANO,
+				    tcs3430_gain_sel,
+				    ARRAY_SIZE(tcs3430_gain_sel),
+				    tcs3430_itime_sel,
+				    ARRAY_SIZE(tcs3430_itime_sel),
+				    &data->gts);
+	if (ret)
+		return ret;
+
+	data->gain_sel = TCS3430_DEFAULT_GAIN_SEL;
+	data->atime = TCS3430_DEFAULT_ATIME_SEL;
+	dev_set_drvdata(dev, data);
+
+	ret = devm_mutex_init(dev, &data->lock);
+	if (ret)
+		return ret;
+
+	ret = regmap_read(data->regmap, TCS3430_REG_ID, &dev_id);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to read device ID\n");
+	if ((dev_id & TCS3430_ID_MASK) != TCS3430_ID_VAL)
+		dev_info(dev, "unexpected part ID 0x%02x\n", dev_id);
+
+	ret = tcs3430_init_hw(data);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to initialize device\n");
+
+	ret = devm_add_action_or_reset(dev, tcs3430_power_off, data);
+	if (ret)
+		return ret;
+
+	indio_dev->name = "tcs3430";
+	indio_dev->info = &tcs3430_info;
+	indio_dev->modes = INDIO_DIRECT_MODE;
+	indio_dev->channels = tcs3430_channels;
+	indio_dev->num_channels = ARRAY_SIZE(tcs3430_channels);
+
+	return devm_iio_device_register(dev, indio_dev);
+}
+
+static int tcs3430_suspend(struct device *dev)
+{
+	struct tcs3430_data *data = dev_get_drvdata(dev);
+
+	guard(mutex)(&data->lock);
+	return regmap_write(data->regmap, TCS3430_REG_ENABLE, 0x00);
+}
+
+static int tcs3430_resume(struct device *dev)
+{
+	struct tcs3430_data *data = dev_get_drvdata(dev);
+
+	guard(mutex)(&data->lock);
+	return tcs3430_init_hw(data);
+}
+
+static DEFINE_SIMPLE_DEV_PM_OPS(tcs3430_pm_ops, tcs3430_suspend,
+				tcs3430_resume);
+
+static const struct of_device_id tcs3430_of_match[] = {
+	{ .compatible = "ams,tcs3430" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, tcs3430_of_match);
+
+static const struct i2c_device_id tcs3430_id[] = {
+	{ .name = "tcs3430" },
+	{ }
+};
+MODULE_DEVICE_TABLE(i2c, tcs3430_id);
+
+static struct i2c_driver tcs3430_driver = {
+	.driver = {
+		.name = "tcs3430",
+		.of_match_table = tcs3430_of_match,
+		.pm = pm_sleep_ptr(&tcs3430_pm_ops),
+	},
+	.probe = tcs3430_probe,
+	.id_table = tcs3430_id,
+};
+module_i2c_driver(tcs3430_driver);
+
+MODULE_AUTHOR("Robert Ijtsma <robertijtsma@gmail.com>");
+MODULE_DESCRIPTION("ams OSRAM TCS3430 Ambient Light and XYZ Color Sensor Driver");
+MODULE_LICENSE("GPL");

-- 
2.47.3

