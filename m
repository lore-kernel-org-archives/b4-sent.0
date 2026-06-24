From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Wed, 24 Jun 2026 18:21:19 +0200
Subject: [PATCH v3 2/2] iio: imu: inv_icm42600: add buffer hwfifo watermark
 attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260624-inv-icm42600-add-buffer-hwfifo_attributes-v3-2-5d9a4c662f50@tdk.com>
References: <20260624-inv-icm42600-add-buffer-hwfifo_attributes-v3-0-5d9a4c662f50@tdk.com>
In-Reply-To: <20260624-inv-icm42600-add-buffer-hwfifo_attributes-v3-0-5d9a4c662f50@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782318086; l=5250;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=/OMY7ogSdwoJriwRH3VX0p+Ykwd/GzGTL7hQjjDqhEg=;
 b=LC7jlMJKwPSpYX3UqAAillCsVfAKZv+P5UxTmzLqwL4V/gsIQg2bjIRgKD7IZoDkLwY8Ig8LT
 B4VWW2xRL8fAlqg/7ldNRYFmNBBhIPPidzruIK7p48qiZn4qpValp8p
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add hwfifo_watermark/min/max/enabled buffer attributes.
Hardware FIFO is always enabled and used.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |  2 ++
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  |  5 +--
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 36 ++++++++++++++++++++++
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h |  1 +
 drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c   |  5 +--
 5 files changed, 45 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600.h b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
index c8b48a5c5ed0..7c9b63584a05 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
@@ -354,6 +354,8 @@ struct inv_icm42600_sensor_state {
 		cpu_to_le16((_wm) & GENMASK(11, 0))
 /* FIFO is 2048 bytes, let 12 samples for reading latency */
 #define INV_ICM42600_FIFO_WATERMARK_MAX			(2048 - 12 * 16)
+/* INV_ICM42600_FIFO_WATERMARK_MAX / 8 = 232 */
+#define INV_ICM42600_FIFO_WATERMARK_MAX_SAMPLES		232
 
 #define INV_ICM42600_REG_INT_CONFIG1			0x0064
 #define INV_ICM42600_INT_CONFIG1_TPULSE_DURATION	BIT(6)
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
index 532d5fdffaf8..1ab73953bef6 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
@@ -1186,8 +1186,9 @@ struct iio_dev *inv_icm42600_accel_init(struct inv_icm42600_state *st)
 	indio_dev->num_channels = ARRAY_SIZE(inv_icm42600_accel_channels);
 	indio_dev->available_scan_masks = inv_icm42600_accel_scan_masks;
 
-	ret = devm_iio_kfifo_buffer_setup(dev, indio_dev,
-					  &inv_icm42600_buffer_ops);
+	ret = devm_iio_kfifo_buffer_setup_ext(dev, indio_dev,
+					      &inv_icm42600_buffer_ops,
+					      inv_icm42600_buffer_attrs);
 	if (ret)
 		return ERR_PTR(ret);
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index 8ad6374409a9..faa9b460bfdf 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -9,9 +9,11 @@
 #include <linux/mutex.h>
 #include <linux/pm_runtime.h>
 #include <linux/regmap.h>
+#include <linux/stringify.h>
 
 #include <linux/iio/buffer.h>
 #include <linux/iio/iio.h>
+#include <linux/iio/sysfs.h>
 
 #include <linux/iio/common/inv_sensors_timestamp.h>
 
@@ -437,6 +439,40 @@ const struct iio_buffer_setup_ops inv_icm42600_buffer_ops = {
 	.postdisable = inv_icm42600_buffer_postdisable,
 };
 
+static ssize_t hwfifo_watermark_show(struct device *dev,
+				     struct device_attribute *attr,
+				     char *buf)
+{
+	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
+	struct inv_icm42600_state *st = iio_device_get_drvdata(indio_dev);
+	unsigned int wm;
+
+	guard(mutex)(&st->lock);
+
+	if (indio_dev == st->indio_accel)
+		wm = st->fifo.watermark.eff_accel;
+	else if (indio_dev == st->indio_gyro)
+		wm = st->fifo.watermark.eff_gyro;
+	else
+		return -EINVAL;
+
+	return sysfs_emit(buf, "%u\n", wm);
+}
+
+IIO_STATIC_CONST_DEVICE_ATTR(hwfifo_watermark_min, "1");
+IIO_STATIC_CONST_DEVICE_ATTR(hwfifo_watermark_max,
+			     __stringify(INV_ICM42600_FIFO_WATERMARK_MAX_SAMPLES));
+static IIO_DEVICE_ATTR_RO(hwfifo_watermark, 0);
+IIO_STATIC_CONST_DEVICE_ATTR(hwfifo_enabled, "1");
+
+const struct iio_dev_attr *inv_icm42600_buffer_attrs[] = {
+	&iio_dev_attr_hwfifo_watermark_min,
+	&iio_dev_attr_hwfifo_watermark_max,
+	&iio_dev_attr_hwfifo_watermark,
+	&iio_dev_attr_hwfifo_enabled,
+	NULL
+};
+
 int inv_icm42600_buffer_fifo_read(struct inv_icm42600_state *st,
 				  unsigned int max)
 {
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
index ffca4da1e249..522e158accc9 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
@@ -79,6 +79,7 @@ ssize_t inv_icm42600_fifo_decode_packet(const void *packet, const void **accel,
 					const void **timestamp, unsigned int *odr);
 
 extern const struct iio_buffer_setup_ops inv_icm42600_buffer_ops;
+extern const struct iio_dev_attr *inv_icm42600_buffer_attrs[];
 
 int inv_icm42600_buffer_init(struct inv_icm42600_state *st);
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
index 11339ddf1da3..7d4f6701f124 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
@@ -772,8 +772,9 @@ struct iio_dev *inv_icm42600_gyro_init(struct inv_icm42600_state *st)
 	indio_dev->available_scan_masks = inv_icm42600_gyro_scan_masks;
 	indio_dev->setup_ops = &inv_icm42600_buffer_ops;
 
-	ret = devm_iio_kfifo_buffer_setup(dev, indio_dev,
-					  &inv_icm42600_buffer_ops);
+	ret = devm_iio_kfifo_buffer_setup_ext(dev, indio_dev,
+					      &inv_icm42600_buffer_ops,
+					      inv_icm42600_buffer_attrs);
 	if (ret)
 		return ERR_PTR(ret);
 

-- 
2.54.0

