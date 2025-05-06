From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Tue, 06 May 2025 10:53:45 +0200
Subject: [PATCH v3 2/2] iio: chemical: Add driver for SEN0322
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250506-iio-chemical-sen0322-v3-2-d6aa4acd00e0@gmail.com>
References: <20250506-iio-chemical-sen0322-v3-0-d6aa4acd00e0@gmail.com>
In-Reply-To: <20250506-iio-chemical-sen0322-v3-0-d6aa4acd00e0@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746521633; l=6662;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=+Ezp/DsTUmLfMfPAYh8WgNX/9ol2LZWhHTJ8ACAmRtg=;
 b=lNJ3POaMp6+ymQM46/7mICY7Rt3Y7H3fBjsRIdZ10PvabqxzECDaYBbp6jWGR7F6SOSgNwEjI
 k6MjKiCLXLNDHExDX7cGAYdj6+silja5np2SgL4m/GSdTbjahLhLvbh
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the DFRobot SEN0322 oxygen sensor.

To instantiate (assuming device is connected to I2C-2):
	echo 'sen0322 0x73' > /sys/class/i2c-dev/i2c-2/device/new_device

To get the oxygen concentration (assuming device is iio:device0) multiply
the values read from:
	/sys/bus/iio/devices/iio:device0/in_concentration_raw
	/sys/bus/iio/devices/iio:device0/in_concentration_scale

Datasheet: https://wiki.dfrobot.com/Gravity_I2C_Oxygen_Sensor_SKU_SEN0322

Signed-off-by: Tóth János <gomba007@gmail.com>
---
 MAINTAINERS                    |   6 ++
 drivers/iio/chemical/Kconfig   |  10 +++
 drivers/iio/chemical/Makefile  |   1 +
 drivers/iio/chemical/sen0322.c | 163 +++++++++++++++++++++++++++++++++++++++++
 4 files changed, 180 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 3cbf9ac0d83f..6fda7a2f1248 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -6852,6 +6852,12 @@ L:	linux-rtc@vger.kernel.org
 S:	Maintained
 F:	drivers/rtc/rtc-sd2405al.c
 
+DFROBOT SEN0322 DRIVER
+M:	Tóth János <gomba007@gmail.com>
+L:	linux-iio@vger.kernel.org
+S:	Maintained
+F:	drivers/iio/chemical/sen0322.c
+
 DH ELECTRONICS DHSOM SOM AND BOARD SUPPORT
 M:	Christoph Niedermaier <cniedermaier@dh-electronics.com>
 M:	Marek Vasut <marex@denx.de>
diff --git a/drivers/iio/chemical/Kconfig b/drivers/iio/chemical/Kconfig
index 330fe0af946f..60a81863d123 100644
--- a/drivers/iio/chemical/Kconfig
+++ b/drivers/iio/chemical/Kconfig
@@ -166,6 +166,16 @@ config SCD4X
 	  To compile this driver as a module, choose M here: the module will
 	  be called scd4x.
 
+config SEN0322
+	tristate "SEN0322 oxygen sensor"
+	depends on I2C
+	select REGMAP_I2C
+	help
+	  Say Y here to build support for the DFRobot SEN0322 oxygen sensor.
+
+	  To compile this driver as a module, choose M here: the module will
+	  be called sen0322.
+
 config SENSIRION_SGP30
 	tristate "Sensirion SGPxx gas sensors"
 	depends on I2C
diff --git a/drivers/iio/chemical/Makefile b/drivers/iio/chemical/Makefile
index 4866db06bdc9..deeff0e4e6f7 100644
--- a/drivers/iio/chemical/Makefile
+++ b/drivers/iio/chemical/Makefile
@@ -20,6 +20,7 @@ obj-$(CONFIG_SCD30_CORE) += scd30_core.o
 obj-$(CONFIG_SCD30_I2C) += scd30_i2c.o
 obj-$(CONFIG_SCD30_SERIAL) += scd30_serial.o
 obj-$(CONFIG_SCD4X) += scd4x.o
+obj-$(CONFIG_SEN0322)	+= sen0322.o
 obj-$(CONFIG_SENSEAIR_SUNRISE_CO2) += sunrise_co2.o
 obj-$(CONFIG_SENSIRION_SGP30)	+= sgp30.o
 obj-$(CONFIG_SENSIRION_SGP40)	+= sgp40.o
diff --git a/drivers/iio/chemical/sen0322.c b/drivers/iio/chemical/sen0322.c
new file mode 100644
index 000000000000..088f8947083e
--- /dev/null
+++ b/drivers/iio/chemical/sen0322.c
@@ -0,0 +1,163 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Driver for the DFRobot SEN0322 oxygen sensor.
+ *
+ * Datasheet:
+ *	https://wiki.dfrobot.com/Gravity_I2C_Oxygen_Sensor_SKU_SEN0322
+ *
+ * Possible I2C slave addresses:
+ *	0x70
+ *	0x71
+ *	0x72
+ *	0x73
+ *
+ * Copyright (C) 2025 Tóth János <gomba007@gmail.com>
+ */
+
+#include <linux/i2c.h>
+#include <linux/regmap.h>
+
+#include <linux/iio/iio.h>
+
+#define SEN0322_REG_DATA	0x03
+#define SEN0322_REG_COEFF	0x0A
+
+struct sen0322 {
+	struct regmap	*regmap;
+};
+
+static int sen0322_read_data(struct sen0322 *sen0322)
+{
+	u8 data[3] = { 0 };
+	int ret;
+
+	ret = regmap_bulk_read(sen0322->regmap, SEN0322_REG_DATA, data,
+			       sizeof(data));
+	if (ret < 0)
+		return ret;
+
+	/*
+	 * The actual value in the registers is:
+	 *	val = data[0] + data[1] / 10 + data[2] / 100
+	 * but it is multiplied by 100 here to avoid floating-point math
+	 * and the scale is divided by 100 to compensate this.
+	 */
+	ret = data[0] * 100 + data[1] * 10 + data[2];
+
+	return ret;
+}
+
+static int sen0322_read_scale(struct sen0322 *sen0322, int *num, int *den)
+{
+	u32 val;
+	int ret;
+
+	ret = regmap_read(sen0322->regmap, SEN0322_REG_COEFF, &val);
+	if (ret < 0)
+		return ret;
+
+	if (val) {
+		*num = val;
+		*den = 100000;	/* Coeff is scaled by 1000 at calibration. */
+	} else { /* The device is not calibrated, using the factory-defaults. */
+		*num = 209;	/* Oxygen content in the atmosphere is 20.9%. */
+		*den = 120000;	/* Output of the sensor at 20.9% is 120 uA. */
+	}
+
+	dev_dbg(regmap_get_device(sen0322->regmap), "scale: %d/%d\n",
+		*num, *den);
+
+	return 0;
+}
+
+static int sen0322_read_raw(struct iio_dev *iio_dev,
+			    const struct iio_chan_spec *chan,
+			    int *val, int *val2, long mask)
+{
+	struct sen0322 *sen0322 = iio_priv(iio_dev);
+	int ret;
+
+	if (chan->type != IIO_CONCENTRATION)
+		return -EINVAL;
+
+	switch (mask) {
+	case IIO_CHAN_INFO_RAW:
+		ret = sen0322_read_data(sen0322);
+		if (ret < 0)
+			return ret;
+
+		*val = ret;
+		return IIO_VAL_INT;
+
+	case IIO_CHAN_INFO_SCALE:
+		ret = sen0322_read_scale(sen0322, val, val2);
+		if (ret < 0)
+			return ret;
+
+		return IIO_VAL_FRACTIONAL;
+
+	default:
+		return -EINVAL;
+	}
+}
+
+static const struct iio_info sen0322_info = {
+	.read_raw = sen0322_read_raw,
+};
+
+static const struct regmap_config sen0322_regmap_conf = {
+	.reg_bits = 8,
+	.val_bits = 8,
+};
+
+static const struct iio_chan_spec sen0322_channel = {
+	.type = IIO_CONCENTRATION,
+	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
+			      BIT(IIO_CHAN_INFO_SCALE),
+};
+
+static int sen0322_probe(struct i2c_client *client)
+{
+	struct sen0322 *sen0322;
+	struct iio_dev *iio_dev;
+
+	if (!i2c_check_functionality(client->adapter, I2C_FUNC_I2C))
+		return -ENODEV;
+
+	iio_dev = devm_iio_device_alloc(&client->dev, sizeof(*sen0322));
+	if (!iio_dev)
+		return -ENOMEM;
+
+	sen0322 = iio_priv(iio_dev);
+
+	sen0322->regmap = devm_regmap_init_i2c(client, &sen0322_regmap_conf);
+	if (IS_ERR(sen0322->regmap))
+		return PTR_ERR(sen0322->regmap);
+
+	iio_dev->info = &sen0322_info;
+	iio_dev->name = "sen0322";
+	iio_dev->channels = &sen0322_channel;
+	iio_dev->num_channels = 1;
+	iio_dev->modes = INDIO_DIRECT_MODE;
+
+	return devm_iio_device_register(&client->dev, iio_dev);
+}
+
+static const struct of_device_id sen0322_of_match[] = {
+	{ .compatible = "dfrobot,sen0322" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, sen0322_of_match);
+
+static struct i2c_driver sen0322_driver = {
+	.driver = {
+		.name = "sen0322",
+		.of_match_table = sen0322_of_match,
+	},
+	.probe = sen0322_probe,
+};
+module_i2c_driver(sen0322_driver);
+
+MODULE_AUTHOR("Tóth János <gomba007@gmail.com>");
+MODULE_LICENSE("GPL");
+MODULE_DESCRIPTION("SEN0322 oxygen sensor driver");

-- 
2.34.1

