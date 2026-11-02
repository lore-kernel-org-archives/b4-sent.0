From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 02 Nov 2026 11:25:42 +0200
Subject: [PATCH v5 6/8] iio: imu: adis16607: Add FIFO-based
 buffered/triggered capture
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-adis16607-v5-6-4f98b0d271ac@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793611539; l=17592;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=c9yz9scEofjwj7cDg/VkgZi7ZazpJrvHaiUKtCvezKI=;
 b=D8KDxHS9oQUgpTV9Y/vcXB+8Uksf7zh//txANjWs0eUGzvLExs2N1nLiSnD+mXvaVw+F9EkQp
 EVlTvdFZTWyBLfk8drz4hHlVRcDJYUZQe0T+mphpCqU/YC4c8mZihfh
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add buffered capture via the device's hardware FIFO - the only
capture mode this driver supports. Popping the FIFO uses a dedicated
command and payload format (FIFO_DATA_CMD, 52 bytes, no checksum),
handled directly rather than through adislib's generic burst-read
helpers, which assume one fixed-shape read per trigger rather than a
variable-count drain loop.

The watermark-met condition is signaled via DEV_NOK on the device's
one interrupt pin, which stays asserted (level-triggered) until
DIAG_STAT is read and cleared - matching adislib's has_fifo contract.
DEV_NOK fires on any DIAG_STAT flag, not just FIFO_THRESH_MET, so the
trigger handler checks that specific bit before popping anything.
DR_GPIO_MASK stays enabled unconditionally: DR pulses drive the FIFO
controller's internal sample enqueue, independent of pin routing.

Watermark is configurable via the standard hwfifo_set_watermark
callback and the usual hwfifo_* sysfs attributes.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16607.c | 392 +++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 388 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/imu/adis16607.c b/drivers/iio/imu/adis16607.c
index 5e2c999e68ac..bd7752f7a1ec 100644
--- a/drivers/iio/imu/adis16607.c
+++ b/drivers/iio/imu/adis16607.c
@@ -13,6 +13,10 @@
 #include <linux/iio/buffer.h>
 #include <linux/iio/iio.h>
 #include <linux/iio/imu/adis.h>
+#include <linux/iio/sysfs.h>
+#include <linux/iio/trigger_consumer.h>
+#include <linux/interrupt.h>
+#include <linux/irq.h>
 #include <linux/math.h>
 #include <linux/minmax.h>
 #include <linux/module.h>
@@ -43,8 +47,11 @@
 #define ADIS16607_REG_Y_DELTANG		0x1A
 #define ADIS16607_REG_Z_DELTANG		0x1C
 #define ADIS16607_REG_TEMP		0x20
+#define ADIS16607_REG_FIFO_WORD_CNT	0x2B
 #define ADIS16607_REG_USER_GPIO_CFG	0x2F
 #define ADIS16607_REG_SPI_HALFDUPLEX	0x32
+#define ADIS16607_REG_USER_DATA_CFG	0x34
+#define ADIS16607_REG_USER_FIFO_CFG	0x35
 #define ADIS16607_REG_SOFT_RESET	0x36
 #define ADIS16607_REG_SELF_TEST		0x39
 #define ADIS16607_REG_DEC_RATE		0x3A
@@ -55,8 +62,29 @@
 
 /* Masks */
 #define ADIS16607_RESET_GPIO_MASK	GENMASK(2, 0)
+#define ADIS16607_DR_GPIO_MASK		GENMASK(11, 9)
+#define ADIS16607_DEV_NOK_MASK		GENMASK(14, 12)
+#define ADIS16607_DATA_CNTR_EN_MASK	BIT(14)
+#define ADIS16607_BURST32_MASK		BIT(15)
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
@@ -87,6 +115,12 @@ struct adis16607 {
 	const struct adis16607_chip_info *info;
 	unsigned long clk_freq_mHz;
 	u64 sample_period_ns;
+	u16 fifo_watermark;
+	/* IIO buffer for reordered data - sized for max channels */
+	IIO_DECLARE_BUFFER_WITH_TS(u8, data, ADIS16607_SCAN_DATA_SIZE);
+	/* Scratch buffer used for FIFO pop operations, see adis16607_fifo_pop() */
+	u8 fifo_buf[ADIS16607_FIFO_DATA_CMD_SIZE + ADIS16607_FIFO_DATA_LEN]
+		__aligned(IIO_DMA_MINALIGN);
 };
 
 enum {
@@ -229,6 +263,304 @@ static const struct adis_ops adis16607_ops = {
 	.reset = adis16607_reset,
 };
 
+/*
+ * FIFO/burst data offsets for each channel (in bytes from the data start,
+ * i.e. after the 4-byte command prefix).
+ * Each 32-bit inertial channel occupies 4 bytes (MSW + LSW), TEMP is 2 bytes.
+ *
+ * FIFO data layout (52 bytes, DATA_CNTR enabled, no checksum):
+ *   Offset 0-3:   ACCEL_X  (32-bit: MSW, LSW)
+ *   Offset 4-7:   ACCEL_Y
+ *   Offset 8-11:  ACCEL_Z
+ *   Offset 12-15: GYRO_X
+ *   Offset 16-19: GYRO_Y
+ *   Offset 20-23: GYRO_Z
+ *   Offset 24-27: DELTVEL_X
+ *   Offset 28-31: DELTVEL_Y
+ *   Offset 32-35: DELTVEL_Z
+ *   Offset 36-39: DELTANG_X
+ *   Offset 40-43: DELTANG_Y
+ *   Offset 44-47: DELTANG_Z
+ *   Offset 48-49: TEMP (16-bit)
+ *   Offset 50-51: DATA_CNTR (16-bit)
+ *
+ * Each 32-bit value encodes 24-bit sensor data as:
+ *   value_24bit = (MSW << 8) | (LSW >> 8)
+ */
+static const u8 adis16607_burst_offsets[] = {
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
+/*
+ * Pop a single sample from FIFO using FIFO_DATA command (0xA9).
+ * Returns the raw FIFO data in the provided buffer.
+ */
+static int adis16607_fifo_pop(struct adis16607 *st, u8 *data)
+{
+	struct spi_message msg;
+	struct spi_transfer xfer = {
+		.tx_buf = st->fifo_buf,
+		.rx_buf = st->fifo_buf,
+		.len = ADIS16607_FIFO_DATA_CMD_SIZE + ADIS16607_FIFO_DATA_LEN,
+	};
+	int ret;
+
+	/* FIFO data command */
+	st->fifo_buf[0] = ADIS16607_FIFO_DATA_CMD;
+
+	spi_message_init(&msg);
+	spi_message_add_tail(&xfer, &msg);
+
+	ret = spi_sync(st->adis.spi, &msg);
+	if (ret)
+		return ret;
+
+	/* Copy data starting after command bytes */
+	memcpy(data, st->fifo_buf + ADIS16607_FIFO_DATA_CMD_SIZE, ADIS16607_FIFO_DATA_LEN);
+	return 0;
+}
+
+/*
+ * Process a single FIFO sample and push to IIO buffer.
+ * FIFO data format differs from regular burst - no DIAG_STAT, data starts immediately.
+ *
+ * FIFO data layout (52 bytes):
+ *   Offset 0-3:   ACCEL_X (32-bit)
+ *   Offset 4-7:   ACCEL_Y (32-bit)
+ *   Offset 8-11:  ACCEL_Z (32-bit)
+ *   Offset 12-15: GYRO_X (32-bit)
+ *   Offset 16-19: GYRO_Y (32-bit)
+ *   Offset 20-23: GYRO_Z (32-bit)
+ *   Offset 24-27: DELTVEL_X (32-bit)
+ *   Offset 28-31: DELTVEL_Y (32-bit)
+ *   Offset 32-35: DELTVEL_Z (32-bit)
+ *   Offset 36-39: DELTANG_X (32-bit)
+ *   Offset 40-43: DELTANG_Y (32-bit)
+ *   Offset 44-47: DELTANG_Z (32-bit)
+ *   Offset 48-49: TEMP (16-bit)
+ *   Offset 50-51: DATA_CNTR (16-bit)
+ */
+static void adis16607_fifo_push_sample(struct iio_dev *indio_dev,
+				       u8 *fifo_data, s64 timestamp)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+	u16 msw, lsw;
+	s32 val24;
+	int bit, offset = 0;
+
+	memset(st->data, 0, sizeof(st->data));
+
+	iio_for_each_active_channel(indio_dev, bit) {
+		u8 burst_off;
+
+		/* Skip the soft timestamp channel - it has no burst offset */
+		if (bit >= ARRAY_SIZE(adis16607_burst_offsets))
+			continue;
+
+		burst_off = adis16607_burst_offsets[bit];
+
+		if (bit == ADIS16607_SCAN_TEMP) {
+			/* TEMP is 16-bit */
+			put_unaligned_be16(get_unaligned_be16(&fifo_data[burst_off]),
+					   &st->data[offset]);
+			offset += 2;
+		} else {
+			/* All other channels are 24-bit stored as 32-bit */
+			msw = get_unaligned_be16(&fifo_data[burst_off]);
+			lsw = get_unaligned_be16(&fifo_data[burst_off + 2]);
+			val24 = sign_extend32(((u32)msw << 8) | (lsw >> 8), 23);
+			put_unaligned_be32(val24, &st->data[offset]);
+			offset += 4;
+		}
+	}
+
+	iio_push_to_buffers_with_ts(indio_dev, st->data, sizeof(st->data),
+				    timestamp);
+}
+
+/*
+ * Drain the device FIFO. Triggered by the DEV_NOK interrupt, which fires on
+ * any DIAG_STAT flag, not just FIFO_THRESH_MET - the DIAG_STAT read below
+ * both checks which flag(s) raised the interrupt and clears the latched
+ * status, and must happen before any FIFO pop, or we'd pop for nothing on
+ * an unrelated flag.
+ */
+static void adis16607_fifo_drain(struct iio_dev *indio_dev, s64 irq_timestamp)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+	u8 fifo_sample[ADIS16607_FIFO_DATA_LEN];
+	u16 diag_stat, word_cnt, sample_cnt;
+	s64 timestamp;
+	int ret;
+
+	adis_dev_auto_lock(&st->adis);
+
+	/* Check if FIFO threshold is met */
+	ret = __adis_read_reg_16(&st->adis, ADIS16607_REG_DIAG_STAT, &diag_stat);
+	if (ret)
+		return;
+
+	if (!(diag_stat & ADIS16607_FIFO_THR_MET_MASK))
+		return;
+
+	/* Read FIFO word count */
+	ret = __adis_read_reg_16(&st->adis, ADIS16607_REG_FIFO_WORD_CNT, &word_cnt);
+	if (ret)
+		return;
+
+	/* Calculate number of complete samples */
+	sample_cnt = word_cnt / ADIS16607_FIFO_WORDS_PER_SAMPLE;
+	if (!sample_cnt)
+		return;
+
+	/*
+	 * irq_timestamp is the IRQ-fire time, i.e. when the newest (last
+	 * enqueued) sample tipped the FIFO over watermark. The FIFO pops
+	 * oldest-first, so back-date the first popped sample's timestamp by
+	 * the batch duration - the loop then counts back up to irq_timestamp
+	 * for the newest sample, instead of projecting past it.
+	 */
+	timestamp = irq_timestamp - (s64)(sample_cnt - 1) * st->sample_period_ns;
+
+	/* Pop and process each sample */
+	for (unsigned int i = 0; i < sample_cnt; i++) {
+		ret = adis16607_fifo_pop(st, fifo_sample);
+		if (ret)
+			return;
+
+		adis16607_fifo_push_sample(indio_dev, fifo_sample, timestamp);
+		timestamp += st->sample_period_ns;
+	}
+}
+
+static irqreturn_t adis16607_trigger_handler(int irq, void *p)
+{
+	struct iio_poll_func *pf = p;
+	struct iio_dev *indio_dev = pf->indio_dev;
+
+	adis16607_fifo_drain(indio_dev, pf->timestamp);
+	iio_trigger_notify_done(indio_dev->trig);
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
+	return __adis_write_reg_16(adis, ADIS16607_REG_USER_FIFO_CFG,
+				   threshold & ADIS16607_FIFO_THR_MASK);
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
+	 * Leave the device clean at the end of a session: the core attaches
+	 * the trigger before calling postenable(), so the next session's
+	 * handler could otherwise run on leftover samples and a still-latched
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
+	.postdisable = adis16607_buffer_postdisable,
+};
+
+static int adis16607_set_watermark(struct iio_dev *indio_dev, unsigned int val)
+{
+	struct adis16607 *st = iio_priv(indio_dev);
+
+	val = clamp(val, 1, ADIS16607_MAX_FIFO_WM);
+	st->fifo_watermark = val;
+
+	return 0;
+}
+
 /*
  * Check if the delta between two values is within specified range.
  */
@@ -316,7 +648,8 @@ static int adis16607_sensor_self_test(struct adis16607 *st)
 
 /*
  * Called by __adis_initial_startup() right after reset, before self-test:
- * SPI Half-Duplex locking, dev_id verification and the bootloader check.
+ * SPI Half-Duplex locking, dev_id verification, the bootloader check,
+ * enabling 32-bit burst mode + DATA_CNTR and the DR/DEV_NOK pin routing.
  */
 static int adis16607_init(struct adis *adis)
 {
@@ -357,7 +690,29 @@ static int adis16607_init(struct adis *adis)
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
@@ -609,7 +964,12 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
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
 
@@ -617,7 +977,7 @@ static int adis16607_write_raw(struct iio_dev *indio_dev,
 		tmp = val * MILLIHZ_PER_HZ +
 		      val2 / (MICROHZ_PER_HZ / MILLIHZ_PER_HZ);
 		return adis16607_set_freq(st, tmp);
-
+	}
 	default:
 		return -EINVAL;
 	}
@@ -716,6 +1076,7 @@ static const struct iio_info adis16607_info = {
 	.read_raw = adis16607_read_raw,
 	.write_raw = adis16607_write_raw,
 	.debugfs_reg_access = adis_debugfs_reg_access,
+	.hwfifo_set_watermark = adis16607_set_watermark,
 };
 
 static const char * const adis16607_status_error_msgs[] = {
@@ -737,6 +1098,7 @@ static const struct adis_data adis16607_data = {
 	.prod_id_reg = ADIS16607_REG_DEV_ID,
 	.prod_id = 0x6000,
 	.unmasked_drdy = true,
+	.has_fifo = true,
 	.init = adis16607_init,
 	.self_test = adis16607_self_test,
 	.status_error_msgs = adis16607_status_error_msgs,
@@ -800,6 +1162,7 @@ static int adis16607_probe(struct spi_device *spi)
 	struct device *dev = &spi->dev;
 	struct iio_dev *indio_dev;
 	struct adis16607 *st;
+	u32 irq_type;
 	int ret;
 
 	indio_dev = devm_iio_device_alloc(dev, sizeof(*st));
@@ -817,6 +1180,8 @@ static int adis16607_probe(struct spi_device *spi)
 	indio_dev->info = &adis16607_info;
 	indio_dev->modes = INDIO_DIRECT_MODE;
 
+	st->fifo_watermark = ADIS16607_MAX_FIFO_WM;
+
 	st->adis.ops = &adis16607_ops;
 
 	ret = devm_regulator_get_enable(dev, "vdd");
@@ -855,6 +1220,25 @@ static int adis16607_probe(struct spi_device *spi)
 	if (ret)
 		return ret;
 
+	/*
+	 * DEV_NOK stays asserted until DIAG_STAT is read, so the interrupt
+	 * must be level-triggered, active high.
+	 */
+	irq_type = irq_get_trigger_type(spi->irq);
+	if (irq_type != IRQ_TYPE_LEVEL_HIGH)
+		return dev_err_probe(dev, -EINVAL,
+				     "Invalid interrupt type 0x%x specified\n",
+				     irq_type);
+
+	st->adis.irq_flag = IRQF_TRIGGER_HIGH;
+
+	ret = devm_adis_setup_buffer_and_trigger_with_attrs(&st->adis, indio_dev,
+							    adis16607_trigger_handler,
+							    &adis16607_buffer_ops,
+							    adis16607_fifo_attributes);
+	if (ret)
+		return ret;
+
 	ret = devm_iio_device_register(dev, indio_dev);
 	if (ret)
 		return ret;

-- 
2.43.0

