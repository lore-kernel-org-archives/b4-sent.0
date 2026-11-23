From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 23 Nov 2026 15:25:30 +0200
Subject: [PATCH 6/7] iio: imu: adis16607: Add FIFO-based buffered capture
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-adis-fifo-v1-6-f6ad9e493e19@analog.com>
References: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
In-Reply-To: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Ramona Gradinariu <ramona.bolboaca13@gmail.com>, 
 Radu Sabau <radu.sabau@analog.com>
Cc: linux-iio@vger.kernel.org, linux@analog.com, 
 linux-kernel@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795440327; l=20070;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=0epzVaATHdlhZMznev2QxDmCJgaoqF206c0YC/Kdv18=;
 b=BhwQaqXdvGbYo1uKjJyWxCqulwhgar9P7uY8dZjmX96YvMRWH3g8wXStjpwAVqZYy6k3oDls2
 4PPp/jcofTBCcbbDRKibJJLoO63nxTlcj6cJp16PB3VTWCQUWlFRfHl
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add buffered capture via the device's hardware FIFO, the only capture
mode this driver supports. Popping the FIFO uses a dedicated command and
payload format (FIFO_DATA_CMD, 52 bytes, no checksum). The channels are
described as big endian words with the value in their upper bits, as the
device sends them, so the samples are copied to the buffer unchanged.

The samples go to a kfifo buffer set up with the adislib kfifo helper,
filled from a threaded interrupt: the device raises one interrupt per
watermark, not per sample, so there is nothing to trigger on. The
watermark-met condition is signaled via DEV_NOK on the device's one
interrupt pin, which stays asserted until DIAG_STAT is read and cleared.
The interrupt is therefore level-triggered and oneshot, and it is enabled
only while the buffer is. DEV_NOK fires on any DIAG_STAT flag, not just
FIFO_THRESH_MET, so the handler checks that specific bit before popping
anything and leaves interrupts it did not raise to the core. DR_GPIO_MASK
stays enabled unconditionally: DR pulses drive the FIFO controller's
internal sample enqueue, independent of pin routing.

Watermark is configurable via the standard hwfifo_set_watermark callback
and the usual hwfifo_* sysfs attributes. Changing the sampling frequency
while the buffer is enabled returns -EBUSY, as the decimation can't change
during capture.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/Kconfig     |   2 +
 drivers/iio/imu/adis16607.c | 386 ++++++++++++++++++++++++++++++++++++++++++--
 2 files changed, 377 insertions(+), 11 deletions(-)

diff --git a/drivers/iio/imu/Kconfig b/drivers/iio/imu/Kconfig
index b00acccab061..b56af04e003d 100644
--- a/drivers/iio/imu/Kconfig
+++ b/drivers/iio/imu/Kconfig
@@ -69,6 +69,8 @@ config ADIS16607
 	tristate "Analog Devices ADIS16607 and similar IMU driver"
 	depends on SPI
 	select IIO_ADIS_LIB
+	select IIO_ADIS_LIB_BUFFER
+	select IIO_BUFFER
 	help
 	  Say yes here to build support for Analog Devices ADIS16607-2
 	  and ADIS16607-3 inertial sensors containing triaxis
diff --git a/drivers/iio/imu/adis16607.c b/drivers/iio/imu/adis16607.c
index 749ed7445f73..60433c97a855 100644
--- a/drivers/iio/imu/adis16607.c
+++ b/drivers/iio/imu/adis16607.c
@@ -11,8 +11,11 @@
 #include <linux/clk.h>
 #include <linux/debugfs.h>
 #include <linux/delay.h>
+#include <linux/iio/buffer.h>
 #include <linux/iio/iio.h>
 #include <linux/iio/imu/adis.h>
+#include <linux/iio/sysfs.h>
+#include <linux/interrupt.h>
 #include <linux/math.h>
 #include <linux/minmax.h>
 #include <linux/module.h>
@@ -20,6 +23,7 @@
 #include <linux/regulator/consumer.h>
 #include <linux/seq_file.h>
 #include <linux/spi/spi.h>
+#include <linux/stringify.h>
 #include <linux/unaligned.h>
 #include <linux/units.h>
 
@@ -43,9 +47,12 @@
 #define ADIS16607_REG_Y_DELTANG		0x1A
 #define ADIS16607_REG_Z_DELTANG		0x1C
 #define ADIS16607_REG_TEMP		0x20
+#define ADIS16607_REG_FIFO_WORD_CNT	0x2B
 #define ADIS16607_REG_USER_GPIO_CFG	0x2F
 #define ADIS16607_REG_SPI_HALFDUPLEX	0x32
 #define ADIS16607_REG_USER_SYNC		0x33
+#define ADIS16607_REG_USER_DATA_CFG	0x34
+#define ADIS16607_REG_USER_FIFO_CFG	0x35
 #define ADIS16607_REG_SOFT_RESET	0x36
 #define ADIS16607_REG_SELF_TEST		0x39
 #define ADIS16607_REG_DEC_RATE		0x3A
@@ -63,9 +70,30 @@
 /* Masks */
 #define ADIS16607_RESET_GPIO_MASK	GENMASK(2, 0)
 #define ADIS16607_SYNC_GPIO_MASK	GENMASK(8, 6)
+#define ADIS16607_DR_GPIO_MASK		GENMASK(11, 9)
+#define ADIS16607_DEV_NOK_MASK		GENMASK(14, 12)
+#define ADIS16607_DATA_CNTR_EN_MASK	BIT(14)
+#define ADIS16607_BURST32_MASK		BIT(15)
 #define ADIS16607_SYNC_MODE_MASK	BIT(15)
 #define ADIS16607_BOOTLOADER_BUSY_MASK	BIT(0)
 
+/* FIFO masks */
+#define ADIS16607_FIFO_THR_MASK		GENMASK(10, 0)
+#define ADIS16607_FIFO_FLUSH_MASK	BIT(15)
+#define ADIS16607_FIFO_THR_MET_MASK	BIT(0)
+#define ADIS16607_FIFO_DATA_CMD		0xA9
+
+/* FIFO limits */
+#define ADIS16607_MAX_FIFO_WM		38
+#define ADIS16607_FIFO_WORDS_PER_SAMPLE	26
+#define ADIS16607_FIFO_DATA_LEN		52
+
+/* FIFO_DATA read - Half-Duplex: 2-byte command phase, then the FIFO data */
+#define ADIS16607_FIFO_DATA_CMD_SIZE	2
+
+/* Largest scan: 12 channels of 24 bits stored as 32, plus 16-bit temperature */
+#define ADIS16607_SCAN_DATA_SIZE	(12 * sizeof(s32) + sizeof(s16))
+
 /* Self-test registers and masks */
 #define ADIS16607_REG_SELF_TEST_DATA(x)	((x) + 0x23)
 #define ADIS16607_SNSR_SELF_TEST_MASK	BIT(6)
@@ -114,6 +142,12 @@ struct adis16607 {
 	u32 sync_mode;
 	u16 sync_scale;
 	u16 dec;
+	u16 fifo_watermark;
+	/* IIO buffer for reordered data - sized for max channels */
+	IIO_DECLARE_BUFFER_WITH_TS(u8, data, ADIS16607_SCAN_DATA_SIZE);
+	/* Scratch buffer used for FIFO pop operations, see adis16607_fifo_pop() */
+	u8 fifo_buf[ADIS16607_FIFO_DATA_CMD_SIZE + ADIS16607_FIFO_DATA_LEN]
+		__aligned(IIO_DMA_MINALIGN);
 };
 
 enum {
@@ -257,6 +291,267 @@ static const struct adis_ops adis16607_ops = {
 	.reset = adis16607_reset,
 };
 
+/*
+ * FIFO_DATA layout (52 bytes after the 2-byte command phase, DATA_CNTR
+ * enabled, no DIAG_STAT and no checksum). Each inertial channel is a big
+ * endian 32-bit word holding the 24-bit value in its upper bits, TEMP is a
+ * big endian 16-bit word:
+ *   0-3 ACCEL_X, 4-7 ACCEL_Y, 8-11 ACCEL_Z, 12-15 GYRO_X, 16-19 GYRO_Y,
+ *   20-23 GYRO_Z, 24-27 DELTVEL_X, 28-31 DELTVEL_Y, 32-35 DELTVEL_Z,
+ *   36-39 DELTANG_X, 40-43 DELTANG_Y, 44-47 DELTANG_Z, 48-49 TEMP,
+ *   50-51 DATA_CNTR
+ */
+static const u8 adis16607_fifo_offsets[] = {
+	[ADIS16607_SCAN_ACCEL_X] = 0,
+	[ADIS16607_SCAN_ACCEL_Y] = 4,
+	[ADIS16607_SCAN_ACCEL_Z] = 8,
+	[ADIS16607_SCAN_GYRO_X] = 12,
+	[ADIS16607_SCAN_GYRO_Y] = 16,
+	[ADIS16607_SCAN_GYRO_Z] = 20,
+	[ADIS16607_SCAN_DELTVEL_X] = 24,
+	[ADIS16607_SCAN_DELTVEL_Y] = 28,
+	[ADIS16607_SCAN_DELTVEL_Z] = 32,
+	[ADIS16607_SCAN_DELTANG_X] = 36,
+	[ADIS16607_SCAN_DELTANG_Y] = 40,
+	[ADIS16607_SCAN_DELTANG_Z] = 44,
+	[ADIS16607_SCAN_TEMP] = 48,
+};
+
+/* Pop one sample from the FIFO into st->fifo_buf with the FIFO_DATA command */
+static int adis16607_fifo_pop(struct adis16607 *st)
+{
+	struct spi_message msg;
+	struct spi_transfer xfer = {
+		.tx_buf = st->fifo_buf,
+		.rx_buf = st->fifo_buf,
+		.len = ADIS16607_FIFO_DATA_CMD_SIZE + ADIS16607_FIFO_DATA_LEN,
+	};
+
+	st->fifo_buf[0] = ADIS16607_FIFO_DATA_CMD;
+
+	spi_message_init_with_transfers(&msg, &xfer, 1);
+
+	return spi_sync(st->adis.spi, &msg);
+}
+
+/*
+ * Push the scan just popped into st->fifo_buf. The channels are described as
+ * big endian with their value in the upper bits, so the bytes are copied as
+ * they come from the device.
+ */
+static void adis16607_fifo_push_scan(struct iio_dev *indio_dev, s64 timestamp)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+	const u8 *sample = st->fifo_buf + ADIS16607_FIFO_DATA_CMD_SIZE;
+	unsigned int offset = 0;
+	int bit;
+
+	memset(st->data, 0, sizeof(st->data));
+
+	iio_for_each_active_channel(indio_dev, bit) {
+		unsigned int size = bit == ADIS16607_SCAN_TEMP ? sizeof(s16) :
+								  sizeof(s32);
+
+		memcpy(&st->data[offset], &sample[adis16607_fifo_offsets[bit]],
+		       size);
+		offset += size;
+	}
+
+	iio_push_to_buffers_with_ts(indio_dev, st->data, sizeof(st->data),
+				    timestamp);
+}
+
+/* Called with the adis lock held, so dec and clk_freq_mHz match each other */
+static s64 adis16607_sample_period_ns(struct adis16607 *st)
+{
+	u64 period_ns;
+
+	/* clk_freq_mHz is in millihertz, hence the MILLIHZ_PER_HZ factor */
+	period_ns = NSEC_PER_SEC;
+	period_ns *= MILLIHZ_PER_HZ;
+	period_ns *= st->dec + 1;
+
+	return DIV_ROUND_CLOSEST_ULL(period_ns, st->clk_freq_mHz);
+}
+
+/*
+ * Drain the device FIFO. DEV_NOK raises the interrupt on any DIAG_STAT flag,
+ * not just FIFO_THRESH_MET - the DIAG_STAT read below both checks which flag
+ * raised it and clears the latched status, and must happen before any FIFO
+ * pop, or we would pop for nothing on an unrelated flag.
+ */
+static irqreturn_t adis16607_irq_thread(int irq, void *p)
+{
+	struct iio_dev *indio_dev = p;
+	struct adis16607 *st = iio_priv(indio_dev);
+	s64 irq_timestamp = iio_get_time_ns(indio_dev);
+	u16 diag_stat, word_cnt, sample_cnt;
+	s64 period_ns, timestamp;
+	int ret;
+
+	adis_dev_auto_lock(&st->adis);
+
+	/* A failed read says nothing about who raised the interrupt */
+	ret = __adis_read_reg_16(&st->adis, ADIS16607_REG_DIAG_STAT, &diag_stat);
+	if (ret)
+		return IRQ_HANDLED;
+
+	if (!(diag_stat & ADIS16607_FIFO_THR_MET_MASK))
+		return IRQ_NONE;
+
+	ret = __adis_read_reg_16(&st->adis, ADIS16607_REG_FIFO_WORD_CNT, &word_cnt);
+	if (ret)
+		return IRQ_HANDLED;
+
+	sample_cnt = word_cnt / ADIS16607_FIFO_WORDS_PER_SAMPLE;
+	if (!sample_cnt)
+		return IRQ_HANDLED;
+
+	/*
+	 * irq_timestamp is when the newest sample tipped the FIFO over its
+	 * watermark. The FIFO pops oldest-first, so back-date the first
+	 * popped sample by the batch duration: the loop then counts up to
+	 * irq_timestamp for the newest sample, instead of projecting past it.
+	 */
+	period_ns = adis16607_sample_period_ns(st);
+	timestamp = irq_timestamp - (sample_cnt - 1) * period_ns;
+
+	for (unsigned int i = 0; i < sample_cnt; i++) {
+		ret = adis16607_fifo_pop(st);
+		if (ret)
+			return IRQ_HANDLED;
+
+		adis16607_fifo_push_scan(indio_dev, timestamp);
+		timestamp += period_ns;
+	}
+
+	return IRQ_HANDLED;
+}
+
+/* FIFO sysfs attributes */
+IIO_STATIC_CONST_DEVICE_ATTR(hwfifo_watermark_min, "1");
+IIO_STATIC_CONST_DEVICE_ATTR(hwfifo_watermark_max, __stringify(ADIS16607_MAX_FIFO_WM));
+
+static ssize_t hwfifo_watermark_show(struct device *dev,
+				     struct device_attribute *attr,
+				     char *buf)
+{
+	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
+	struct adis16607 *st = iio_priv(indio_dev);
+
+	return sysfs_emit(buf, "%u\n", st->fifo_watermark);
+}
+
+static ssize_t hwfifo_enabled_show(struct device *dev,
+				   struct device_attribute *attr,
+				   char *buf)
+{
+	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
+	struct adis16607 *st = iio_priv(indio_dev);
+	u16 val;
+	int ret;
+
+	ret = adis_read_reg_16(&st->adis, ADIS16607_REG_USER_FIFO_CFG, &val);
+	if (ret)
+		return ret;
+
+	return sysfs_emit(buf, "%d\n", (val & ADIS16607_FIFO_THR_MASK) ? 1 : 0);
+}
+
+static IIO_DEVICE_ATTR_RO(hwfifo_watermark, 0);
+static IIO_DEVICE_ATTR_RO(hwfifo_enabled, 0);
+
+static const struct iio_dev_attr *adis16607_fifo_attributes[] = {
+	&iio_dev_attr_hwfifo_watermark_min,
+	&iio_dev_attr_hwfifo_watermark_max,
+	&iio_dev_attr_hwfifo_watermark,
+	&iio_dev_attr_hwfifo_enabled,
+	NULL
+};
+
+static int adis16607_buffer_postenable(struct iio_dev *indio_dev)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+	struct adis *adis = &st->adis;
+	u16 threshold;
+	int ret;
+
+	adis_dev_auto_lock(adis);
+
+	/* Flush FIFO to start clean */
+	ret = __adis_write_reg_16(adis, ADIS16607_REG_USER_FIFO_CFG,
+				  ADIS16607_FIFO_FLUSH_MASK);
+	if (ret)
+		return ret;
+
+	/* Enable FIFO with watermark threshold (in word count) */
+	threshold = st->fifo_watermark * ADIS16607_FIFO_WORDS_PER_SAMPLE;
+	ret = __adis_write_reg_16(adis, ADIS16607_REG_USER_FIFO_CFG,
+				  threshold & ADIS16607_FIFO_THR_MASK);
+	if (ret)
+		return ret;
+
+	/*
+	 * The device cannot mask DEV_NOK for us: unrouting it leaves the pin
+	 * on its weak pull-up, which reads as asserted. Mask it on the host.
+	 */
+	enable_irq(adis->spi->irq);
+
+	return 0;
+}
+
+static int adis16607_buffer_predisable(struct iio_dev *indio_dev)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+
+	/* Waits for a running handler, so no drain races the FIFO disable */
+	disable_irq(st->adis.spi->irq);
+
+	return 0;
+}
+
+static int adis16607_buffer_postdisable(struct iio_dev *indio_dev)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+	struct adis *adis = &st->adis;
+	u16 diag_stat;
+	int ret;
+
+	adis_dev_auto_lock(adis);
+
+	/* Disable FIFO */
+	ret = __adis_write_reg_16(adis, ADIS16607_REG_USER_FIFO_CFG, 0);
+	if (ret)
+		return ret;
+
+	/*
+	 * Leave the device clean at the end of a session, so the next one
+	 * does not start on leftover samples and a still-latched
+	 * FIFO_THR_MET.
+	 */
+	ret = __adis_write_reg_16(adis, ADIS16607_REG_USER_FIFO_CFG,
+				  ADIS16607_FIFO_FLUSH_MASK);
+	if (ret)
+		return ret;
+
+	return __adis_read_reg_16(adis, ADIS16607_REG_DIAG_STAT, &diag_stat);
+}
+
+static const struct iio_buffer_setup_ops adis16607_buffer_ops = {
+	.postenable = adis16607_buffer_postenable,
+	.predisable = adis16607_buffer_predisable,
+	.postdisable = adis16607_buffer_postdisable,
+};
+
+static int adis16607_set_watermark(struct iio_dev *indio_dev, unsigned int val)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+
+	st->fifo_watermark = clamp(val, 1, ADIS16607_MAX_FIFO_WM);
+
+	return 0;
+}
+
 /*
  * Check if the delta between two values is within specified range.
  */
@@ -344,7 +639,8 @@ static int adis16607_sensor_self_test(struct adis16607 *st)
 
 /*
  * Called by __adis_initial_startup() right after reset, before self-test:
- * SPI Half-Duplex locking, dev_id verification and the bootloader check.
+ * SPI Half-Duplex locking, dev_id verification, the bootloader check,
+ * enabling 32-bit burst mode + DATA_CNTR and the DR/DEV_NOK pin routing.
  */
 static int adis16607_init(struct adis *adis)
 {
@@ -385,7 +681,29 @@ static int adis16607_init(struct adis *adis)
 	if (digital_status & ADIS16607_BOOTLOADER_BUSY_MASK)
 		return dev_err_probe(dev, -EBUSY, "bootloader is busy\n");
 
-	return 0;
+	/* Enable 32-bit burst mode and DATA_CNTR - one-time, used by FIFO pops */
+	ret = __adis_update_bits_base(adis, ADIS16607_REG_USER_DATA_CFG,
+				      ADIS16607_BURST32_MASK | ADIS16607_DATA_CNTR_EN_MASK,
+				      ADIS16607_BURST32_MASK | ADIS16607_DATA_CNTR_EN_MASK, 2);
+	if (ret)
+		return ret;
+
+	/*
+	 * DR_GPIO_MASK and DEV_NOK_MASK are updated here rather than written
+	 * blind, so this doesn't clobber the RESET_GPIO_MASK bit already
+	 * configured earlier in probe(). Per datasheet, DR pulses are what
+	 * drive the FIFO controller's internal enqueue logic. DR and
+	 * DEV_NOK are separate physical pins, so enabling DR_GPIO_MASK here
+	 * does not put DR's full-sample-rate pulses onto the interrupt line
+	 * - DEV_NOK_MASK routes the aggregate "any DIAG_STAT flag asserted"
+	 * signal onto the one physically-wired interrupt pin, which is what
+	 * actually fires on FIFO_THRESH_MET, at the (much lower) watermark
+	 * rate, not the sample rate.
+	 */
+	return __adis_update_bits_base(adis, ADIS16607_REG_USER_GPIO_CFG,
+				       ADIS16607_DR_GPIO_MASK | ADIS16607_DEV_NOK_MASK,
+				       FIELD_PREP(ADIS16607_DR_GPIO_MASK, 1) |
+				       FIELD_PREP(ADIS16607_DEV_NOK_MASK, 1), 2);
 }
 
 /*
@@ -602,21 +920,16 @@ static int adis16607_set_freq(struct adis16607 *st, u32 freq)
 
 /*
  * .address is an index into adis16607_chan_regs[] for this driver, not a
- * literal register like adis_single_conversion() expects, and the channel
- * spec carries no scan_type for it to take the register width and sign
- * extension from. Resolve both on a local copy rather than reimplementing
- * the helper's locking logic ourselves.
+ * literal register like adis_single_conversion() expects - resolve it on a
+ * local copy rather than reimplementing the helper's locking and
+ * sign-extension logic ourselves.
  */
 static int adis16607_raw_read(struct iio_dev *indio_dev,
 			      const struct iio_chan_spec *chan, int *val)
 {
 	struct iio_chan_spec raw_chan = *chan;
-	bool is_temp = chan->type == IIO_TEMP;
 
 	raw_chan.address = adis16607_chan_regs[chan->address].raw_reg;
-	raw_chan.scan_type.sign = 's';
-	raw_chan.scan_type.realbits = is_temp ? 16 : 24;
-	raw_chan.scan_type.storagebits = is_temp ? 16 : 32;
 
 	return adis_single_conversion(indio_dev, &raw_chan, 0, val);
 }
@@ -693,7 +1006,12 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 	u32 tmp;
 
 	switch (info) {
-	case IIO_CHAN_INFO_SAMP_FREQ:
+	case IIO_CHAN_INFO_SAMP_FREQ: {
+		/* The decimation must not change while the buffer is running */
+		IIO_DEV_ACQUIRE_DIRECT_MODE(indio_dev, claim);
+		if (IIO_DEV_ACQUIRE_FAILED(claim))
+			return -EBUSY;
+
 		if (val < 0 || val2 < 0)
 			return -EINVAL;
 
@@ -701,6 +1019,7 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 		tmp = val * MILLIHZ_PER_HZ +
 		      val2 / (MICROHZ_PER_HZ / MILLIHZ_PER_HZ);
 		return adis16607_set_freq(st, tmp);
+	}
 
 	case IIO_CHAN_INFO_CALIBBIAS: {
 		u16 reg = adis16607_chan_regs[chan->address].calib_bias_reg;
@@ -725,6 +1044,14 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 		.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE),	       \
 		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),       \
 		.address = (_idx),					       \
+		.scan_index = (_idx),					       \
+		.scan_type = {						       \
+			.sign = 's',					       \
+			.realbits = 24,					       \
+			.storagebits = 32,				       \
+			.shift = 8,					       \
+			.endianness = IIO_BE,				       \
+		},							       \
 	}
 
 #define ADIS16607_ACCEL_CHANNEL(_mod)					       \
@@ -744,6 +1071,14 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 		.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE),	       \
 		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),       \
 		.address = (_idx),					       \
+		.scan_index = (_idx),					       \
+		.scan_type = {						       \
+			.sign = 's',					       \
+			.realbits = 24,					       \
+			.storagebits = 32,				       \
+			.shift = 8,					       \
+			.endianness = IIO_BE,				       \
+		},							       \
 	}
 
 #define ADIS16607_DELTANG_CHAN(_mod)					       \
@@ -776,13 +1111,22 @@ static const struct iio_chan_spec adis16607_channels[] = {
 				      BIT(IIO_CHAN_INFO_OFFSET),
 		.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),
 		.address = ADIS16607_SCAN_TEMP,
+		.scan_index = ADIS16607_SCAN_TEMP,
+		.scan_type = {
+			.sign = 's',
+			.realbits = 16,
+			.storagebits = 16,
+			.endianness = IIO_BE,
+		},
 	},
+	IIO_CHAN_SOFT_TIMESTAMP(ADIS16607_SCAN_MAX),
 };
 
 static const struct iio_info adis16607_info = {
 	.read_raw = adis16607_read_raw,
 	.write_raw = adis16607_write_raw,
 	.debugfs_reg_access = adis_debugfs_reg_access,
+	.hwfifo_set_watermark = adis16607_set_watermark,
 };
 
 /*
@@ -814,6 +1158,7 @@ static const struct adis_data adis16607_data = {
 	.diag_stat_size = 2,
 	.prod_id_reg = ADIS16607_REG_DEV_ID,
 	.prod_id = 0x6000,
+	.has_fifo = true,
 	.unmasked_drdy = true,
 	.init = adis16607_init,
 	.self_test = adis16607_self_test,
@@ -972,7 +1317,19 @@ static int adis16607_probe(struct spi_device *spi)
 	indio_dev->info = &adis16607_info;
 	indio_dev->modes = INDIO_DIRECT_MODE;
 
+	if (!spi->irq)
+		return dev_err_probe(dev, -EINVAL, "interrupt is required\n");
+
+	/* The core's default; the device watermark follows buffer/watermark */
+	st->fifo_watermark = 1;
+
 	st->adis.ops = &adis16607_ops;
+	/*
+	 * DEV_NOK is the OR of the DIAG_STAT flags and stays high until
+	 * DIAG_STAT is read. Use a level interrupt so a flag raised while it
+	 * is already high is not lost.
+	 */
+	st->adis.irq_flag = IRQF_TRIGGER_HIGH;
 
 	ret = devm_regulator_get_enable(dev, "vdd");
 	if (ret)
@@ -1010,6 +1367,13 @@ static int adis16607_probe(struct spi_device *spi)
 	if (ret)
 		return ret;
 
+	ret = devm_adis_setup_kfifo_buffer(&st->adis, indio_dev,
+					   adis16607_irq_thread,
+					   &adis16607_buffer_ops,
+					   adis16607_fifo_attributes);
+	if (ret)
+		return ret;
+
 	ret = devm_iio_device_register(dev, indio_dev);
 	if (ret)
 		return ret;

-- 
2.43.0

