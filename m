From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 02 Nov 2026 11:25:41 +0200
Subject: [PATCH v5 5/8] iio: imu: Add driver for the ADI ADIS16607
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261102-adis16607-v5-5-4f98b0d271ac@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793611539; l=29035;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=L8mSyaDqwow/aF3O/FBcrike/bqYF8TXOzJl5lmf3K4=;
 b=Dotvn4GsSpkhkYzi09nO3FfeVne2VFAPdajo6W83Qd88WV0hRualkXL9s7k/oDMZQunEHU7gb
 o2BF343epzHDsqF4pHjDn37E+roJiVmSyJyY6Gi0QDB+FzHE1P2lh5/
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADIS16607 is a Precision MEMS IMU from Analog Devices with
triaxial gyroscope and accelerometer, delta angle/velocity, and
temperature channels, communicating over a custom SPI Half-Duplex
protocol. ADIS16607-2 has a ±450°/s gyroscope range, ADIS16607-3
±2000°/s; both share a ±40g accelerometer range and an 8 kHz internal
clock.

This is the base driver: probe, raw channel reads, sampling-frequency
control, startup/self-test via adislib, and debugfs identity entries.
No buffered capture, external clock sync, or calibration bias yet -
those follow in later patches.

Self-test leaves the device's SELF_TEST register cleared on every exit
path, not just on success, so a read failure or a failed delta check
doesn't leave the sensor stuck in its self-test/force state until the
next reset.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 MAINTAINERS                 |   1 +
 drivers/iio/imu/Kconfig     |  13 +
 drivers/iio/imu/Makefile    |   1 +
 drivers/iio/imu/adis16607.c | 894 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 909 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index d5679e8d0ffd..268a82adeb1d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1798,6 +1798,7 @@ L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/imu/adi,adis16607.yaml
+F:	drivers/iio/imu/adis16607.c
 
 ANALOG DEVICES INC ADL8113 DRIVER
 M:	Antoniu Miclaus <antoniu.miclaus@analog.com>
diff --git a/drivers/iio/imu/Kconfig b/drivers/iio/imu/Kconfig
index 8bab4616be20..0b39057d0a7c 100644
--- a/drivers/iio/imu/Kconfig
+++ b/drivers/iio/imu/Kconfig
@@ -65,6 +65,19 @@ config ADIS16550
 	  To compile this driver as a module, choose M here: the module will be
 	  called adis16550.
 
+config ADIS16607
+	tristate "Analog Devices ADIS16607 and similar IMU driver"
+	depends on SPI
+	select IIO_ADIS_LIB
+	select IIO_ADIS_LIB_BUFFER if IIO_BUFFER
+	help
+	  Say yes here to build support for Analog Devices ADIS16607-2
+	  and ADIS16607-3 inertial sensors containing triaxis
+	  gyroscope and triaxis accelerometer.
+
+	  To compile this driver as a module, choose M here: the module will be
+	  called adis16607.
+
 source "drivers/iio/imu/bmi160/Kconfig"
 source "drivers/iio/imu/bmi270/Kconfig"
 source "drivers/iio/imu/bmi323/Kconfig"
diff --git a/drivers/iio/imu/Makefile b/drivers/iio/imu/Makefile
index 3268dc2371ae..6eeec1ee387f 100644
--- a/drivers/iio/imu/Makefile
+++ b/drivers/iio/imu/Makefile
@@ -9,6 +9,7 @@ obj-$(CONFIG_ADIS16460) += adis16460.o
 obj-$(CONFIG_ADIS16475) += adis16475.o
 obj-$(CONFIG_ADIS16480) += adis16480.o
 obj-$(CONFIG_ADIS16550) += adis16550.o
+obj-$(CONFIG_ADIS16607) += adis16607.o
 
 adis_lib-y += adis.o
 adis_lib-$(CONFIG_IIO_ADIS_LIB_BUFFER) += adis_trigger.o
diff --git a/drivers/iio/imu/adis16607.c b/drivers/iio/imu/adis16607.c
new file mode 100644
index 000000000000..5e2c999e68ac
--- /dev/null
+++ b/drivers/iio/imu/adis16607.c
@@ -0,0 +1,894 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * ADIS16607 IMU driver
+ *
+ * Copyright 2026 Analog Devices Inc.
+ */
+#include <linux/array_size.h>
+#include <linux/bitfield.h>
+#include <linux/bitops.h>
+#include <linux/build_bug.h>
+#include <linux/debugfs.h>
+#include <linux/delay.h>
+#include <linux/iio/buffer.h>
+#include <linux/iio/iio.h>
+#include <linux/iio/imu/adis.h>
+#include <linux/math.h>
+#include <linux/minmax.h>
+#include <linux/module.h>
+#include <linux/property.h>
+#include <linux/regulator/consumer.h>
+#include <linux/seq_file.h>
+#include <linux/spi/spi.h>
+#include <linux/unaligned.h>
+#include <linux/units.h>
+
+/* Register addresses */
+#define ADIS16607_REG_DEV_ID		0x00
+#define ADIS16607_REG_REV_ID		0x01
+#define ADIS16607_REG_SERIAL_NUM0	0x02
+#define ADIS16607_REG_SERIAL_NUM1	0x03
+#define ADIS16607_REG_SERIAL_NUM2	0x04
+#define ADIS16607_REG_DIAG_STAT		0x05
+#define ADIS16607_REG_X_ACCEL		0x06
+#define ADIS16607_REG_Y_ACCEL		0x08
+#define ADIS16607_REG_Z_ACCEL		0x0A
+#define ADIS16607_REG_X_GYRO		0x0C
+#define ADIS16607_REG_Y_GYRO		0x0E
+#define ADIS16607_REG_Z_GYRO		0x10
+#define ADIS16607_REG_X_DELTVEL		0x12
+#define ADIS16607_REG_Y_DELTVEL		0x14
+#define ADIS16607_REG_Z_DELTVEL		0x16
+#define ADIS16607_REG_X_DELTANG		0x18
+#define ADIS16607_REG_Y_DELTANG		0x1A
+#define ADIS16607_REG_Z_DELTANG		0x1C
+#define ADIS16607_REG_TEMP		0x20
+#define ADIS16607_REG_USER_GPIO_CFG	0x2F
+#define ADIS16607_REG_SPI_HALFDUPLEX	0x32
+#define ADIS16607_REG_SOFT_RESET	0x36
+#define ADIS16607_REG_SELF_TEST		0x39
+#define ADIS16607_REG_DEC_RATE		0x3A
+#define ADIS16607_REG_DIGITAL_STATUS	0x4E
+
+/* SPI Half-Duplex lock value */
+#define ADIS16607_LOCK_SPI_HALFDUPLEX	0xB4B4
+
+/* Masks */
+#define ADIS16607_RESET_GPIO_MASK	GENMASK(2, 0)
+#define ADIS16607_BOOTLOADER_BUSY_MASK	BIT(0)
+
+/* Self-test registers and masks */
+#define ADIS16607_REG_SELF_TEST_DATA(x)	((x) + 0x23)
+#define ADIS16607_SNSR_SELF_TEST_MASK	BIT(6)
+#define ADIS16607_ST_FORCE_MASK		BIT(7)
+
+/* Self-test delta check limits */
+#define ADIS16607_ACCEL_XY_DELTA_MAX	260
+#define ADIS16607_ACCEL_Z_DELTA_MAX	4000
+#define ADIS16607_GYRO_DELTA_MAX	2600
+
+struct adis16607_chip_info {
+	const struct iio_chan_spec *channels;
+	const char *name;
+	u32 num_channels;
+	u32 gyro_max_val;
+	u32 gyro_max_scale;
+	u32 accel_max_val;
+	u32 accel_max_scale;
+	u32 temp_scale;
+	u32 deltang_max_val;
+	u32 deltvel_max_val;
+	u32 int_clk_Hz;
+	u16 max_dec;
+};
+
+struct adis16607 {
+	struct adis adis;
+	const struct adis16607_chip_info *info;
+	unsigned long clk_freq_mHz;
+	u64 sample_period_ns;
+};
+
+enum {
+	ADIS16607_SCAN_ACCEL_X,
+	ADIS16607_SCAN_ACCEL_Y,
+	ADIS16607_SCAN_ACCEL_Z,
+	ADIS16607_SCAN_GYRO_X,
+	ADIS16607_SCAN_GYRO_Y,
+	ADIS16607_SCAN_GYRO_Z,
+	ADIS16607_SCAN_DELTVEL_X,
+	ADIS16607_SCAN_DELTVEL_Y,
+	ADIS16607_SCAN_DELTVEL_Z,
+	ADIS16607_SCAN_DELTANG_X,
+	ADIS16607_SCAN_DELTANG_Y,
+	ADIS16607_SCAN_DELTANG_Z,
+	ADIS16607_SCAN_TEMP,
+	ADIS16607_SCAN_MAX,
+};
+
+struct adis16607_chan_regs {
+	u16 raw_reg;
+};
+
+static const struct adis16607_chan_regs adis16607_chan_regs[] = {
+	[ADIS16607_SCAN_ACCEL_X]   = { ADIS16607_REG_X_ACCEL },
+	[ADIS16607_SCAN_ACCEL_Y]   = { ADIS16607_REG_Y_ACCEL },
+	[ADIS16607_SCAN_ACCEL_Z]   = { ADIS16607_REG_Z_ACCEL },
+	[ADIS16607_SCAN_GYRO_X]    = { ADIS16607_REG_X_GYRO },
+	[ADIS16607_SCAN_GYRO_Y]    = { ADIS16607_REG_Y_GYRO },
+	[ADIS16607_SCAN_GYRO_Z]    = { ADIS16607_REG_Z_GYRO },
+	[ADIS16607_SCAN_DELTVEL_X] = { ADIS16607_REG_X_DELTVEL },
+	[ADIS16607_SCAN_DELTVEL_Y] = { ADIS16607_REG_Y_DELTVEL },
+	[ADIS16607_SCAN_DELTVEL_Z] = { ADIS16607_REG_Z_DELTVEL },
+	[ADIS16607_SCAN_DELTANG_X] = { ADIS16607_REG_X_DELTANG },
+	[ADIS16607_SCAN_DELTANG_Y] = { ADIS16607_REG_Y_DELTANG },
+	[ADIS16607_SCAN_DELTANG_Z] = { ADIS16607_REG_Z_DELTANG },
+	[ADIS16607_SCAN_TEMP]      = { ADIS16607_REG_TEMP },
+};
+
+static_assert(ARRAY_SIZE(adis16607_chan_regs) == ADIS16607_SCAN_MAX);
+
+static int adis16607_spi_read(struct adis *adis, unsigned int reg,
+			      unsigned int *val, unsigned int size)
+{
+	struct spi_message msg;
+	struct spi_transfer xfers[2] = {
+		{
+			.tx_buf = adis->tx,
+			.len = 4,
+			.cs_change = 1,
+		},
+		{
+			.tx_buf = adis->tx,
+			.rx_buf = adis->rx,
+			.len = 4,
+		},
+	};
+	u16 val_msw, val_lsw;
+	int ret;
+
+	/*
+	 * Half-Duplex read: two 4-byte transfers with CS toggling in between.
+	 * The first one latches the command, the second sends it again and
+	 * the device answers in bytes 2-3.
+	 */
+	switch (size) {
+	case 2:
+		adis->tx[0] = reg | BIT(7);
+
+		spi_message_init_with_transfers(&msg, xfers, ARRAY_SIZE(xfers));
+
+		ret = spi_sync(adis->spi, &msg);
+		if (ret)
+			return ret;
+
+		*val = get_unaligned_be16(&adis->rx[2]);
+		return 0;
+
+	case 4:
+		/* Read MSW from reg */
+		adis->tx[0] = reg | BIT(7);
+
+		spi_message_init_with_transfers(&msg, xfers, ARRAY_SIZE(xfers));
+
+		ret = spi_sync(adis->spi, &msg);
+		if (ret)
+			return ret;
+
+		val_msw = get_unaligned_be16(&adis->rx[2]);
+
+		/* Read LSW from reg+1 */
+		adis->tx[0] = (reg + 1) | BIT(7);
+
+		spi_message_init_with_transfers(&msg, xfers, ARRAY_SIZE(xfers));
+
+		ret = spi_sync(adis->spi, &msg);
+		if (ret)
+			return ret;
+
+		val_lsw = adis->rx[2];
+
+		/*
+		 * Combine: 24-bit value with MSW in upper 16 bits,
+		 * LSW in lower 8 bits.
+		 */
+		*val = FIELD_PREP(GENMASK(23, 8), val_msw) | val_lsw;
+		return 0;
+
+	default:
+		return -EINVAL;
+	}
+}
+
+/*
+ * SPI Half-Duplex write operation for ADIS16607.
+ * Protocol:
+ *   - Send 3 bytes: [reg, val_high, val_low]
+ *   - Only 16-bit writes are supported
+ */
+static int adis16607_spi_write(struct adis *adis, unsigned int reg,
+			       unsigned int val, unsigned int size)
+{
+	if (size != 2)
+		return -EINVAL;
+
+	adis->tx[0] = reg;
+	put_unaligned_be16(val, &adis->tx[1]);
+
+	return spi_write(adis->spi, adis->tx, 3);
+}
+
+static int adis16607_reset(struct adis *adis)
+{
+	return adis16607_spi_write(adis, ADIS16607_REG_SOFT_RESET, BIT(0), 2);
+}
+
+static const struct adis_ops adis16607_ops = {
+	.read = adis16607_spi_read,
+	.write = adis16607_spi_write,
+	.reset = adis16607_reset,
+};
+
+/*
+ * Check if the delta between two values is within specified range.
+ */
+static bool adis16607_delta_check(s16 val1, s16 val2, s16 delta_max)
+{
+	return abs(val1 - val2) <= delta_max;
+}
+
+/*
+ * Perform sensor self-test for ADIS16607.
+ * Reads self-test data before and after forcing self-test,
+ * then verifies delta values are within acceptable ranges.
+ */
+static int adis16607_sensor_self_test(struct adis16607 *st)
+{
+	struct adis *adis = &st->adis;
+	u16 st1_val[6], st2_val[6];
+	s16 delta_max[6] = {
+		ADIS16607_ACCEL_XY_DELTA_MAX,
+		ADIS16607_ACCEL_XY_DELTA_MAX,
+		ADIS16607_ACCEL_Z_DELTA_MAX,
+		ADIS16607_GYRO_DELTA_MAX,
+		ADIS16607_GYRO_DELTA_MAX,
+		ADIS16607_GYRO_DELTA_MAX,
+	};
+	int ret;
+
+	/* Enable sensor self-test */
+	ret = __adis_write_reg_16(adis, ADIS16607_REG_SELF_TEST,
+				  ADIS16607_SNSR_SELF_TEST_MASK);
+	if (ret)
+		return ret;
+
+	/* Wait for self-test to settle before reading results */
+	msleep(adis->data->timeouts->self_test_ms);
+
+	/* Read first set of self-test data */
+	for (unsigned int i = 0; i < ARRAY_SIZE(st1_val); i++) {
+		ret = __adis_read_reg_16(adis, ADIS16607_REG_SELF_TEST_DATA(i),
+					 &st1_val[i]);
+		if (ret)
+			goto clear_self_test;
+	}
+
+	/* Force self-test */
+	ret = __adis_write_reg_16(adis, ADIS16607_REG_SELF_TEST,
+				  ADIS16607_SNSR_SELF_TEST_MASK | ADIS16607_ST_FORCE_MASK);
+	if (ret)
+		goto clear_self_test;
+
+	/* Wait for forced self-test to settle before reading results */
+	msleep(adis->data->timeouts->self_test_ms);
+
+	/* Read second set of self-test data */
+	for (unsigned int i = 0; i < ARRAY_SIZE(st2_val); i++) {
+		ret = __adis_read_reg_16(adis, ADIS16607_REG_SELF_TEST_DATA(i),
+					 &st2_val[i]);
+		if (ret)
+			goto clear_self_test;
+
+		if (!adis16607_delta_check((s16)st1_val[i], (s16)st2_val[i],
+					   delta_max[i])) {
+			ret = dev_err_probe(&adis->spi->dev, -EINVAL,
+					    "Self-test failed for axis %u: delta out of range\n",
+					    i);
+			goto clear_self_test;
+		}
+	}
+
+	/* Clear self-test register */
+	return __adis_write_reg_16(adis, ADIS16607_REG_SELF_TEST, 0);
+
+clear_self_test:
+	/*
+	 * Best-effort cleanup after a failure above - leave the device out
+	 * of its self-test/force state rather than stuck in it until the
+	 * next reset. Warn rather than returning this write's own result,
+	 * so a cleanup failure doesn't mask the real error that got us here.
+	 */
+	if (__adis_write_reg_16(adis, ADIS16607_REG_SELF_TEST, 0))
+		dev_warn(&adis->spi->dev, "failed to clear self-test register\n");
+
+	return ret;
+}
+
+/*
+ * Called by __adis_initial_startup() right after reset, before self-test:
+ * SPI Half-Duplex locking, dev_id verification and the bootloader check.
+ */
+static int adis16607_init(struct adis *adis)
+{
+	struct device *dev = &adis->spi->dev;
+	u16 diag_stat, digital_status, dev_id;
+	int ret;
+
+	/* Lock the device into SPI Half-Duplex mode */
+	ret = __adis_write_reg_16(adis, ADIS16607_REG_SPI_HALFDUPLEX,
+				  ADIS16607_LOCK_SPI_HALFDUPLEX);
+	if (ret)
+		return ret;
+
+	/* Verify the correct device is attached */
+	ret = __adis_read_reg_16(adis, ADIS16607_REG_DEV_ID, &dev_id);
+	if (ret)
+		return ret;
+
+	if (dev_id != adis->data->prod_id)
+		return dev_err_probe(dev, -ENODEV,
+				     "device ID mismatch: expected 0x%04x, got 0x%04x\n",
+				     adis->data->prod_id, dev_id);
+
+	/* Read diag_stat to clear any latched faults */
+	ret = __adis_read_reg_16(adis, ADIS16607_REG_DIAG_STAT, &diag_stat);
+	if (ret)
+		return ret;
+
+	ret = __adis_check_status(adis);
+	if (ret)
+		return ret;
+
+	/* Check that bootloader is not busy */
+	ret = __adis_read_reg_16(adis, ADIS16607_REG_DIGITAL_STATUS, &digital_status);
+	if (ret)
+		return ret;
+
+	if (digital_status & ADIS16607_BOOTLOADER_BUSY_MASK)
+		return dev_err_probe(dev, -EBUSY, "bootloader is busy\n");
+
+	return 0;
+}
+
+/*
+ * Self-test callback for struct adis_data (see adis16607_data below).
+ * Called by __adis_initial_startup() right after adis16607_init().
+ */
+static int adis16607_self_test(struct adis *adis)
+{
+	struct adis16607 *st = container_of(adis, struct adis16607, adis);
+	u16 diag_stat;
+	int ret;
+
+	/*
+	 * Inertial Settling Time (Table 1), needed before self-test
+	 * reads sensor data.
+	 */
+	msleep(40);
+
+	ret = adis16607_sensor_self_test(st);
+	if (ret)
+		return ret;
+
+	/* Read diag_stat again to clear any faults latched during self-test */
+	ret = __adis_read_reg_16(adis, ADIS16607_REG_DIAG_STAT, &diag_stat);
+	if (ret)
+		return ret;
+
+	return __adis_check_status(adis);
+}
+
+static int adis16607_firmware_revision_show(struct seq_file *s, void *arg)
+{
+	struct adis16607 *st = s->private;
+	struct {
+		u8 minor;
+		u8 major;
+	} rev;
+	u16 tmp;
+	int ret;
+
+	ret = adis_read_reg_16(&st->adis, ADIS16607_REG_REV_ID, &tmp);
+	if (ret)
+		return ret;
+
+	rev.major = FIELD_GET(GENMASK(15, 8), tmp);
+	rev.minor = FIELD_GET(GENMASK(7, 0), tmp);
+
+	seq_printf(s, "%u.%u\n", rev.major, rev.minor);
+	return 0;
+}
+DEFINE_SHOW_ATTRIBUTE(adis16607_firmware_revision);
+
+static int adis16607_show_serial_number(void *arg, u64 *val)
+{
+	struct adis16607 *st = arg;
+	u64 serial;
+	u16 tmp;
+	int ret;
+
+	ret = adis_read_reg_16(&st->adis, ADIS16607_REG_SERIAL_NUM2, &tmp);
+	if (ret)
+		return ret;
+
+	serial = tmp;
+
+	ret = adis_read_reg_16(&st->adis, ADIS16607_REG_SERIAL_NUM1, &tmp);
+	if (ret)
+		return ret;
+
+	serial <<= 16;
+	serial |= tmp;
+
+	ret = adis_read_reg_16(&st->adis, ADIS16607_REG_SERIAL_NUM0, &tmp);
+	if (ret)
+		return ret;
+
+	serial <<= 16;
+	serial |= tmp;
+
+	*val = serial;
+	return 0;
+}
+DEFINE_DEBUGFS_ATTRIBUTE(adis16607_serial_number_fops,
+			 adis16607_show_serial_number, NULL, "0x%.8llx\n");
+
+static int adis16607_show_dev_id(void *arg, u64 *val)
+{
+	struct adis16607 *st = arg;
+	u16 dev_id;
+	int ret;
+
+	ret = adis_read_reg_16(&st->adis, ADIS16607_REG_DEV_ID, &dev_id);
+	if (ret)
+		return ret;
+
+	*val = dev_id;
+	return 0;
+}
+DEFINE_DEBUGFS_ATTRIBUTE(adis16607_dev_id_fops,
+			 adis16607_show_dev_id, NULL, "%llu\n");
+
+static void adis16607_debugfs_init(struct iio_dev *indio_dev)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+	struct dentry *d = iio_get_debugfs_dentry(indio_dev);
+
+	debugfs_create_file_unsafe("serial_number", 0400, d, st,
+				   &adis16607_serial_number_fops);
+	debugfs_create_file_unsafe("dev_id", 0400, d, st,
+				   &adis16607_dev_id_fops);
+	debugfs_create_file("firmware_revision", 0400, d, st,
+			    &adis16607_firmware_revision_fops);
+}
+
+static int adis16607_get_freq(struct adis16607 *st, u32 *freq)
+{
+	u16 dec;
+	int ret;
+
+	ret = adis_read_reg_16(&st->adis, ADIS16607_REG_DEC_RATE, &dec);
+	if (ret)
+		return ret;
+
+	*freq = DIV_ROUND_CLOSEST(st->clk_freq_mHz, dec + 1);
+
+	return 0;
+}
+
+static int adis16607_set_freq(struct adis16607 *st, u32 freq)
+{
+	u64 period_ns;
+	u32 dec;
+	int ret;
+
+	if (!freq)
+		return -EINVAL;
+
+	dec = DIV_ROUND_CLOSEST(st->clk_freq_mHz, freq);
+	if (dec)
+		dec--;
+
+	dec = min(dec, st->info->max_dec);
+
+	/*
+	 * The sample period is (dec + 1) / clk_freq. clk_freq_mHz is in
+	 * millihertz, hence the MILLIHZ_PER_HZ factor to get back to ns.
+	 * Starting from a u64 forces every multiplication below to 64 bits:
+	 * NSEC_PER_SEC * MILLIHZ_PER_HZ alone (~1e12) overflows 32 bits.
+	 */
+	period_ns = NSEC_PER_SEC;
+	period_ns *= MILLIHZ_PER_HZ;
+	period_ns *= dec + 1;
+	period_ns = DIV_ROUND_CLOSEST_ULL(period_ns, st->clk_freq_mHz);
+
+	adis_dev_auto_scoped_lock(&st->adis) {
+		/* Reset the decimation accumulator before the new value */
+		ret = __adis_write_reg_16(&st->adis, ADIS16607_REG_DEC_RATE, 0);
+		if (ret)
+			return ret;
+
+		if (dec) {
+			ret = __adis_write_reg_16(&st->adis,
+						  ADIS16607_REG_DEC_RATE, dec);
+			if (ret)
+				return ret;
+		}
+
+		st->sample_period_ns = period_ns;
+	}
+
+	return 0;
+}
+
+/*
+ * .address is an index into adis16607_chan_regs[] for this driver, not a
+ * literal register like adis_single_conversion() expects - resolve it on a
+ * local copy rather than reimplementing the helper's locking and
+ * sign-extension logic ourselves.
+ */
+static int adis16607_raw_read(struct iio_dev *indio_dev,
+			      const struct iio_chan_spec *chan, int *val)
+{
+	struct iio_chan_spec raw_chan = *chan;
+
+	raw_chan.address = adis16607_chan_regs[chan->address].raw_reg;
+
+	return adis_single_conversion(indio_dev, &raw_chan, 0, val);
+}
+
+static int adis16607_read_raw(struct iio_dev *indio_dev,
+			      const struct iio_chan_spec *chan,
+			      int *val, int *val2, long info)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+	int ret;
+	u32 tmp;
+
+	switch (info) {
+	case IIO_CHAN_INFO_RAW:
+		return adis16607_raw_read(indio_dev, chan, val);
+	case IIO_CHAN_INFO_SCALE:
+		switch (chan->type) {
+		case IIO_ANGL_VEL:
+			*val = st->info->gyro_max_val;
+			*val2 = st->info->gyro_max_scale;
+			return IIO_VAL_FRACTIONAL;
+		case IIO_ACCEL:
+			*val = st->info->accel_max_val;
+			*val2 = st->info->accel_max_scale;
+			return IIO_VAL_FRACTIONAL;
+		case IIO_TEMP:
+			*val = st->info->temp_scale;
+			return IIO_VAL_INT;
+		case IIO_DELTA_ANGL:
+			*val = st->info->deltang_max_val;
+			*val2 = 23;
+			return IIO_VAL_FRACTIONAL_LOG2;
+		case IIO_DELTA_VELOCITY:
+			*val = st->info->deltvel_max_val;
+			*val2 = 23;
+			return IIO_VAL_FRACTIONAL_LOG2;
+		default:
+			return -EINVAL;
+		}
+	case IIO_CHAN_INFO_OFFSET:
+		/* Temperature: 0 raw counts = 25°C; offset = 25000 mdeg / 5 mdeg per LSB = 5000 */
+		*val = 5000;
+		return IIO_VAL_INT;
+	case IIO_CHAN_INFO_SAMP_FREQ:
+		ret = adis16607_get_freq(st, &tmp);
+		if (ret)
+			return ret;
+		/* tmp is in mHz: split into Hz and the remainder in uHz */
+		*val = tmp / MILLIHZ_PER_HZ;
+		*val2 = (tmp % MILLIHZ_PER_HZ) *
+			(MICROHZ_PER_HZ / MILLIHZ_PER_HZ);
+		return IIO_VAL_INT_PLUS_MICRO;
+
+	default:
+		return -EINVAL;
+	}
+}
+
+static int adis16607_write_raw(struct iio_dev *indio_dev,
+			       const struct iio_chan_spec *chan,
+			       int val, int val2, long info)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+	u32 tmp;
+
+	switch (info) {
+	case IIO_CHAN_INFO_SAMP_FREQ:
+		if (val < 0 || val2 < 0)
+			return -EINVAL;
+
+		/* val is in Hz and val2 in uHz: convert both to mHz */
+		tmp = val * MILLIHZ_PER_HZ +
+		      val2 / (MICROHZ_PER_HZ / MILLIHZ_PER_HZ);
+		return adis16607_set_freq(st, tmp);
+
+	default:
+		return -EINVAL;
+	}
+}
+
+/*
+ * .address indexes adis16607_chan_regs[], .scan_index is the buffer position;
+ * both come from the same enum today but are separate fields on purpose.
+ */
+#define ADIS16607_MOD_CHAN(_type, _mod, _idx)				       \
+	{								       \
+		.type = (_type),					       \
+		.modified = 1,						       \
+		.channel2 = (_mod),					       \
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW),		       \
+		.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE),	       \
+		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),       \
+		.address = (_idx),					       \
+		.scan_index = (_idx),					       \
+		.scan_type = {						       \
+			.sign = 's',					       \
+			.realbits = 24,					       \
+			.storagebits = 32,				       \
+			.endianness = IIO_BE,				       \
+		},							       \
+	}
+
+#define ADIS16607_ACCEL_CHANNEL(_mod)					       \
+	ADIS16607_MOD_CHAN(IIO_ACCEL, IIO_MOD_ ## _mod,			       \
+			   ADIS16607_SCAN_ACCEL_ ## _mod)
+
+#define ADIS16607_GYRO_CHANNEL(_mod)					       \
+	ADIS16607_MOD_CHAN(IIO_ANGL_VEL, IIO_MOD_ ## _mod,		       \
+			   ADIS16607_SCAN_GYRO_ ## _mod)
+
+#define ADIS16607_MOD_CHAN_DELTA(_type, _mod, _idx)			       \
+	{								       \
+		.type = (_type),					       \
+		.modified = 1,						       \
+		.channel2 = (_mod),					       \
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW),		       \
+		.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE),	       \
+		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),       \
+		.address = (_idx),					       \
+		.scan_index = (_idx),					       \
+		.scan_type = {						       \
+			.sign = 's',					       \
+			.realbits = 24,					       \
+			.storagebits = 32,				       \
+			.endianness = IIO_BE,				       \
+		},							       \
+	}
+
+#define ADIS16607_DELTANG_CHAN(_mod)					       \
+	ADIS16607_MOD_CHAN_DELTA(IIO_DELTA_ANGL, IIO_MOD_ ## _mod,	       \
+				 ADIS16607_SCAN_DELTANG_ ## _mod)
+
+#define ADIS16607_DELTVEL_CHAN(_mod)					       \
+	ADIS16607_MOD_CHAN_DELTA(IIO_DELTA_VELOCITY, IIO_MOD_ ## _mod,	       \
+				 ADIS16607_SCAN_DELTVEL_ ## _mod)
+
+static const struct iio_chan_spec adis16607_channels[] = {
+	ADIS16607_ACCEL_CHANNEL(X),
+	ADIS16607_ACCEL_CHANNEL(Y),
+	ADIS16607_ACCEL_CHANNEL(Z),
+	ADIS16607_GYRO_CHANNEL(X),
+	ADIS16607_GYRO_CHANNEL(Y),
+	ADIS16607_GYRO_CHANNEL(Z),
+	ADIS16607_DELTVEL_CHAN(X),
+	ADIS16607_DELTVEL_CHAN(Y),
+	ADIS16607_DELTVEL_CHAN(Z),
+	ADIS16607_DELTANG_CHAN(X),
+	ADIS16607_DELTANG_CHAN(Y),
+	ADIS16607_DELTANG_CHAN(Z),
+	{
+		.type = IIO_TEMP,
+		.indexed = 1,
+		.channel = 0,
+		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
+				      BIT(IIO_CHAN_INFO_SCALE) |
+				      BIT(IIO_CHAN_INFO_OFFSET),
+		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),
+		.address = ADIS16607_SCAN_TEMP,
+		.scan_index = ADIS16607_SCAN_TEMP,
+		.scan_type = {
+			.sign = 's',
+			.realbits = 16,
+			.storagebits = 16,
+			.endianness = IIO_BE,
+		},
+	},
+	IIO_CHAN_SOFT_TIMESTAMP(ADIS16607_SCAN_MAX),
+};
+
+static const struct iio_info adis16607_info = {
+	.read_raw = adis16607_read_raw,
+	.write_raw = adis16607_write_raw,
+	.debugfs_reg_access = adis_debugfs_reg_access,
+};
+
+static const char * const adis16607_status_error_msgs[] = {
+	[9] = "Boot Memory Failure",
+	[11] = "Power Supply Failure",
+	[12] = "Accelerometer Failure",
+	[13] = "Gyroscope Failure",
+};
+
+static const struct adis_timeout adis16607_timeouts = {
+	.reset_ms = 130,
+	.sw_reset_ms = 50,
+	.self_test_ms = 15,
+};
+
+static const struct adis_data adis16607_data = {
+	.diag_stat_reg = ADIS16607_REG_DIAG_STAT,
+	.diag_stat_size = 2,
+	.prod_id_reg = ADIS16607_REG_DEV_ID,
+	.prod_id = 0x6000,
+	.unmasked_drdy = true,
+	.init = adis16607_init,
+	.self_test = adis16607_self_test,
+	.status_error_msgs = adis16607_status_error_msgs,
+	.status_error_mask = BIT(9) | BIT(11) | BIT(12) | BIT(13),
+	.timeouts = &adis16607_timeouts,
+};
+
+/*
+ * ADIS16607-2: 450 deg/s gyro, 40g accel
+ * ADIS16607-3: 2000 deg/s gyro, 40g accel
+ */
+static const struct adis16607_chip_info adis16607_2_chip_info = {
+	.channels	= adis16607_channels,
+	.num_channels	= ARRAY_SIZE(adis16607_channels),
+	.name		= "adis16607-2",
+	.gyro_max_val	= IIO_DEGREE_TO_RAD(450),
+	.gyro_max_scale	= 30000 << 8,
+	.accel_max_val	= IIO_G_TO_M_S_2(40),
+	.accel_max_scale = 31250 << 8,
+	.temp_scale	= 5,
+	.deltang_max_val = IIO_DEGREE_TO_RAD(450),
+	.deltvel_max_val = IIO_G_TO_M_S_2(40),
+	.int_clk_Hz	= 8000,
+	.max_dec	= 65535,
+};
+
+static const struct adis16607_chip_info adis16607_3_chip_info = {
+	.channels	= adis16607_channels,
+	.num_channels	= ARRAY_SIZE(adis16607_channels),
+	.name		= "adis16607-3",
+	.gyro_max_val	= IIO_DEGREE_TO_RAD(2000),
+	.gyro_max_scale	= 31250 << 8,
+	.accel_max_val	= IIO_G_TO_M_S_2(40),
+	.accel_max_scale = 31250 << 8,
+	.temp_scale	= 5,
+	.deltang_max_val = IIO_DEGREE_TO_RAD(2000),
+	.deltvel_max_val = IIO_G_TO_M_S_2(40),
+	.int_clk_Hz	= 8000,
+	.max_dec	= 65535,
+};
+
+/*
+ * No external clock sync support yet: always run on the internal clock.
+ * Default dec=0 after reset, so period = 1 / clk_freq_mHz.
+ */
+static int adis16607_config_clk(struct adis16607 *st)
+{
+	u64 period_ns = NSEC_PER_SEC;
+
+	st->clk_freq_mHz = st->info->int_clk_Hz * MILLIHZ_PER_HZ;
+
+	/* clk_freq_mHz is in millihertz: scale to get the period in ns */
+	period_ns *= MILLIHZ_PER_HZ;
+	st->sample_period_ns = DIV_ROUND_CLOSEST_ULL(period_ns,
+						     st->clk_freq_mHz);
+	return 0;
+}
+
+static int adis16607_probe(struct spi_device *spi)
+{
+	struct device *dev = &spi->dev;
+	struct iio_dev *indio_dev;
+	struct adis16607 *st;
+	int ret;
+
+	indio_dev = devm_iio_device_alloc(dev, sizeof(*st));
+	if (!indio_dev)
+		return -ENOMEM;
+
+	st = iio_priv(indio_dev);
+	st->info = spi_get_device_match_data(spi);
+	if (!st->info)
+		return -ENODATA;
+
+	indio_dev->name = st->info->name;
+	indio_dev->channels = st->info->channels;
+	indio_dev->num_channels = st->info->num_channels;
+	indio_dev->info = &adis16607_info;
+	indio_dev->modes = INDIO_DIRECT_MODE;
+
+	st->adis.ops = &adis16607_ops;
+
+	ret = devm_regulator_get_enable(dev, "vdd");
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to get vdd regulator\n");
+
+	ret = adis_init(&st->adis, indio_dev, spi, &adis16607_data);
+	if (ret)
+		return ret;
+
+	/*
+	 * Force GPIO0 back to its RESET function before relying on toggling
+	 * it below - RESET_GPIO_MASK is runtime-writable on this part, so a
+	 * prior write (buggy driver, direct reg access, etc.) could have
+	 * left it de-routed, which would make the GPIO toggle in
+	 * __adis_initial_startup() silently do nothing. This write goes out
+	 * over SPI, which stays live regardless of this mask's state, so it
+	 * can re-arm the mux as long as the device is merely
+	 * reset-pin-defeated and not fully unresponsive. Only warn on
+	 * failure instead of erroring out - bailing here would throw away
+	 * whatever chance the GPIO toggle below still has of working.
+	 */
+	if (device_property_present(dev, "reset-gpios")) {
+		ret = __adis_update_bits_base(&st->adis, ADIS16607_REG_USER_GPIO_CFG,
+					      ADIS16607_RESET_GPIO_MASK,
+					      FIELD_PREP(ADIS16607_RESET_GPIO_MASK, 1), 2);
+		if (ret)
+			dev_warn(dev, "failed to force reset-pin routing: %d\n", ret);
+	}
+
+	ret = __adis_initial_startup(&st->adis);
+	if (ret)
+		return ret;
+
+	ret = adis16607_config_clk(st);
+	if (ret)
+		return ret;
+
+	ret = devm_iio_device_register(dev, indio_dev);
+	if (ret)
+		return ret;
+
+	adis16607_debugfs_init(indio_dev);
+
+	return 0;
+}
+
+static const struct spi_device_id adis16607_id[] = {
+	{ .name = "adis16607-2", .driver_data = (kernel_ulong_t)&adis16607_2_chip_info },
+	{ .name = "adis16607-3", .driver_data = (kernel_ulong_t)&adis16607_3_chip_info },
+	{ }
+};
+MODULE_DEVICE_TABLE(spi, adis16607_id);
+
+static const struct of_device_id adis16607_of_match[] = {
+	{ .compatible = "adi,adis16607-2", .data = &adis16607_2_chip_info },
+	{ .compatible = "adi,adis16607-3", .data = &adis16607_3_chip_info },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, adis16607_of_match);
+
+static struct spi_driver adis16607_driver = {
+	.driver = {
+		.name = "adis16607",
+		.of_match_table = adis16607_of_match,
+	},
+	.probe = adis16607_probe,
+	.id_table = adis16607_id,
+};
+module_spi_driver(adis16607_driver);
+
+MODULE_AUTHOR("Radu Sabau <radu.sabau@analog.com>");
+MODULE_DESCRIPTION("Analog Devices ADIS16607 and similar IMU driver");
+MODULE_IMPORT_NS("IIO_ADISLIB");
+MODULE_LICENSE("GPL");

-- 
2.43.0

