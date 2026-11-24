From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Tue, 24 Nov 2026 23:46:58 +0100
Subject: [PATCH 2/2] iio: light: add ams OSRAM TCS3430 XYZ and ambient
 light sensor driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-iio-tcs3430-v1-2-0f2a38a6a4c1@gmail.com>
References: <20261124-iio-tcs3430-v1-0-0f2a38a6a4c1@gmail.com>
In-Reply-To: <20261124-iio-tcs3430-v1-0-0f2a38a6a4c1@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795560419; l=12434;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=dtV6AhP8bkV0dJ+wEFVJkec7NYtVmfKkQQtBOiTI0mQ=;
 b=ziAJVhuM+OAA1HRIQ7YR7JyPyH5YGLQeIGyVOAMUwK8RHirBjzueVywvLWEzKzCjn3+5KROE/
 fX91bIUDFf9Axh28cjc4yBtdygbF/0dQ6SWgs2ZCAB7gVEfqL859H6E
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
- Selectable hardware gain (1x, 4x, 16x, 64x, 128x) and integration time
- Regulator management and system sleep suspend/resume support

Tested on Microsoft Surface Pro X SQ2 (SC8180X).

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 MAINTAINERS                 |   1 +
 drivers/iio/light/Kconfig   |  10 ++
 drivers/iio/light/Makefile  |   1 +
 drivers/iio/light/tcs3430.c | 345 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 357 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index b1cebc2..5194709 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1494,6 +1494,7 @@ M:	Robert Ijtsma <robertijtsma@gmail.com>
 L:	linux-iio@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/iio/light/ams,tcs3430.yaml
+F:	drivers/iio/light/tcs3430.c
 
 AMT (Automatic Multicast Tunneling)
 M:	Taehee Yoo <ap420073@gmail.com>
diff --git a/drivers/iio/light/Kconfig b/drivers/iio/light/Kconfig
index 462fff1..09894cd 100644
--- a/drivers/iio/light/Kconfig
+++ b/drivers/iio/light/Kconfig
@@ -609,6 +609,16 @@ config TCS3414
 	  This driver can also be built as a module.  If so, the module
 	  will be called tcs3414.
 
+config TCS3430
+	tristate "ams OSRAM TCS3430 ambient light and XYZ color sensor"
+	depends on I2C
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
index 6672ed0..cd7b42e 100644
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
index 0000000..138c8ab
--- /dev/null
+++ b/drivers/iio/light/tcs3430.c
@@ -0,0 +1,345 @@
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
+#include <linux/math64.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/pm.h>
+#include <linux/regulator/consumer.h>
+#include <linux/types.h>
+#include <linux/units.h>
+
+#include <linux/iio/iio.h>
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
+/* 72 integration cycles * 2.78 ms = 200.16 ms */
+#define TCS3430_DEFAULT_ATIME_CYCLES	72
+#define TCS3430_ATIME_STEP_US		2780
+
+/*
+ * Photopic Y channel typical sensitivity from datasheet optical characteristics:
+ * ~0.537 counts/lux at AGAIN = 16x and ATIME = 100 ms (36 cycles), giving:
+ *   lux/count = 2980 / (gain * integration_time_ms)
+ */
+#define TCS3430_LUX_FACTOR		2980ULL
+
+static const int tcs3430_gains[] = { 1, 4, 16, 64, 128 };
+
+struct tcs3430_data {
+	struct i2c_client *client;
+	/* Protects device configuration across multi-register updates */
+	struct mutex lock;
+	u8 gain_idx;
+};
+
+static int tcs3430_apply_gain(struct tcs3430_data *data, u8 gain_idx)
+{
+	u8 cfg1, cfg2;
+	int ret;
+
+	if (gain_idx == 4) {
+		cfg1 = FIELD_PREP(TCS3430_CFG1_AGAIN_MASK, 3);
+		cfg2 = TCS3430_CFG2_DEFAULT | TCS3430_CFG2_HGAIN;
+	} else {
+		cfg1 = FIELD_PREP(TCS3430_CFG1_AGAIN_MASK, gain_idx);
+		cfg2 = TCS3430_CFG2_DEFAULT;
+	}
+
+	ret = i2c_smbus_write_byte_data(data->client, TCS3430_REG_CFG1, cfg1);
+	if (ret)
+		return ret;
+
+	ret = i2c_smbus_write_byte_data(data->client, TCS3430_REG_CFG2, cfg2);
+	if (ret)
+		return ret;
+
+	data->gain_idx = gain_idx;
+	return 0;
+}
+
+static int tcs3430_init_hw(struct tcs3430_data *data)
+{
+	struct i2c_client *client = data->client;
+	int ret;
+
+	ret = i2c_smbus_write_byte_data(client, TCS3430_REG_ENABLE, 0x00);
+	if (ret)
+		return ret;
+
+	ret = i2c_smbus_write_byte_data(client, TCS3430_REG_ATIME,
+					TCS3430_DEFAULT_ATIME_CYCLES - 1);
+	if (ret)
+		return ret;
+
+	ret = tcs3430_apply_gain(data, data->gain_idx);
+	if (ret)
+		return ret;
+
+	ret = i2c_smbus_write_byte_data(client, TCS3430_REG_CFG3,
+					TCS3430_CFG3_DEFAULT);
+	if (ret)
+		return ret;
+
+	ret = i2c_smbus_write_byte_data(client, TCS3430_REG_INTENAB, 0x00);
+	if (ret)
+		return ret;
+
+	return i2c_smbus_write_byte_data(client, TCS3430_REG_ENABLE,
+					 TCS3430_ENABLE_PON |
+					 TCS3430_ENABLE_AEN);
+}
+
+static void tcs3430_power_off(void *priv)
+{
+	struct tcs3430_data *data = priv;
+
+	i2c_smbus_write_byte_data(data->client, TCS3430_REG_ENABLE, 0x00);
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
+	case IIO_CHAN_INFO_RAW:
+		guard(mutex)(&data->lock);
+		ret = i2c_smbus_read_word_data(data->client, chan->address);
+		if (ret < 0)
+			return ret;
+		*val = ret;
+		return IIO_VAL_INT;
+
+	case IIO_CHAN_INFO_SCALE: {
+		u32 itime_us = TCS3430_DEFAULT_ATIME_CYCLES * TCS3430_ATIME_STEP_US;
+		u64 scale_nano;
+		u32 rem;
+		int gain;
+
+		scoped_guard(mutex, &data->lock)
+			gain = tcs3430_gains[data->gain_idx];
+
+		scale_nano = div_u64(TCS3430_LUX_FACTOR * NSEC_PER_SEC * USEC_PER_MSEC,
+				     (u32)gain * itime_us);
+		*val = div_u64_rem(scale_nano, NSEC_PER_SEC, &rem);
+		*val2 = rem;
+		return IIO_VAL_INT_PLUS_NANO;
+	}
+
+	case IIO_CHAN_INFO_HARDWAREGAIN:
+		guard(mutex)(&data->lock);
+		*val = tcs3430_gains[data->gain_idx];
+		return IIO_VAL_INT;
+
+	case IIO_CHAN_INFO_INT_TIME:
+		*val = 0;
+		*val2 = TCS3430_DEFAULT_ATIME_CYCLES * TCS3430_ATIME_STEP_US;
+		return IIO_VAL_INT_PLUS_MICRO;
+
+	default:
+		return -EINVAL;
+	}
+}
+
+static int tcs3430_write_raw(struct iio_dev *indio_dev,
+			     const struct iio_chan_spec *chan,
+			     int val, int val2, long mask)
+{
+	struct tcs3430_data *data = iio_priv(indio_dev);
+	unsigned int i;
+
+	if (mask != IIO_CHAN_INFO_HARDWAREGAIN || val2 != 0)
+		return -EINVAL;
+
+	for (i = 0; i < ARRAY_SIZE(tcs3430_gains); i++) {
+		if (tcs3430_gains[i] == val) {
+			guard(mutex)(&data->lock);
+			return tcs3430_apply_gain(data, i);
+		}
+	}
+
+	return -EINVAL;
+}
+
+static int tcs3430_read_avail(struct iio_dev *indio_dev,
+			      const struct iio_chan_spec *chan,
+			      const int **vals, int *type, int *length,
+			      long mask)
+{
+	if (mask != IIO_CHAN_INFO_HARDWAREGAIN)
+		return -EINVAL;
+
+	*vals = tcs3430_gains;
+	*type = IIO_VAL_INT;
+	*length = ARRAY_SIZE(tcs3430_gains);
+	return IIO_AVAIL_LIST;
+}
+
+#define TCS3430_INTENSITY_CHANNEL(_mod, _addr) {			\
+	.type = IIO_INTENSITY,						\
+	.modified = 1,							\
+	.channel2 = (_mod),						\
+	.address = (_addr),						\
+	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW),			\
+	.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_HARDWAREGAIN) |	\
+				   BIT(IIO_CHAN_INFO_INT_TIME),		\
+	.info_mask_shared_by_all_available =				\
+		BIT(IIO_CHAN_INFO_HARDWAREGAIN),			\
+}
+
+static const struct iio_chan_spec tcs3430_channels[] = {
+	{
+		.type = IIO_LIGHT,
+		.address = TCS3430_REG_CH1DATAL,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
+				      BIT(IIO_CHAN_INFO_SCALE),
+		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_HARDWAREGAIN) |
+					   BIT(IIO_CHAN_INFO_INT_TIME),
+		.info_mask_shared_by_all_available =
+			BIT(IIO_CHAN_INFO_HARDWAREGAIN),
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
+	.read_avail = tcs3430_read_avail,
+};
+
+static int tcs3430_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct tcs3430_data *data;
+	struct iio_dev *indio_dev;
+	int ret;
+
+	if (!i2c_check_functionality(client->adapter,
+				     I2C_FUNC_SMBUS_BYTE_DATA |
+				     I2C_FUNC_SMBUS_WORD_DATA))
+		return -EOPNOTSUPP;
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
+	data->client = client;
+	data->gain_idx = 3; /* 64x default gain */
+	i2c_set_clientdata(client, data);
+
+	ret = devm_mutex_init(dev, &data->lock);
+	if (ret)
+		return ret;
+
+	ret = i2c_smbus_read_byte_data(client, TCS3430_REG_ID);
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to read device ID\n");
+	if ((ret & TCS3430_ID_MASK) != TCS3430_ID_VAL)
+		dev_info(dev, "unexpected part ID 0x%02x\n", ret);
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
+	return i2c_smbus_write_byte_data(data->client, TCS3430_REG_ENABLE, 0x00);
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
2.56.0

