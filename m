From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Fri, 30 Jan 2026 17:10:23 +0100
Subject: [PATCH] iio: imu: inv_icm42600: fix odr switch when turning buffer
 off
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260130-inv-icm42600-fix-odr-change-when-turning-buffer-off-v1-1-f76fc3604bdc@tdk.com>
X-B4-Tracking: v=1; b=H4sIAO7XfGkC/y3NzQqDMAwH8FeRnBeoVpTtVcYOtiaaw9KRTh2I7
 74iHn/w/9ghkwlleFQ7GK2SJWlBfasgzoNOhDIWQ+OaztXeoeiKEt9toUOWH6bR8IpuMyl+F1P
 RCcPCTIaJGX0YfMf9vY2hh7L8MSrN8/X5Oo4/C1dNn4UAAAA=
X-Change-ID: 20260130-inv-icm42600-fix-odr-change-when-turning-buffer-off-3ba36f794cb7
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769789432; l=1938;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=V+V88fAK8S3LRNlRrvLoACHqnirAnUGI3yB4cFHD2YQ=;
 b=g1bZqJfpCPrJ6Njn9UJDzPM2DEnt6LVrFBiX/gWCn7lkV8DGRDW3D+/hYBGwzdGCiIHQzx6oV
 hLdoOSwSX6gBQ0waVHQe8B54J3gyCAmt5WQX/UWURwo/IEMsl/Fc+cs
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ODR switch is done in 2 steps when FIFO is on : change the ODR register
value and acknowledge change when reading the FIFO ODR change flag.
When we are switching odr and turning buffer off just afterward, we are
losing the FIFO ODR change flag and ODR switch is blocked.

Fix the issue by force applying any waiting ODR change when turning
buffer off.

Fixes: ec74ae9fd37c ("iio: imu: inv_icm42600: add accurate timestamping")
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Cc: stable@vger.kernel.org
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index ada968be954d480a2022bc8aa6918f32e5e543f7..68a395758031884792781d6eee748d273a86a22e 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -371,6 +371,8 @@ static int inv_icm42600_buffer_predisable(struct iio_dev *indio_dev)
 static int inv_icm42600_buffer_postdisable(struct iio_dev *indio_dev)
 {
 	struct inv_icm42600_state *st = iio_device_get_drvdata(indio_dev);
+	struct inv_icm42600_sensor_state *sensor_st = iio_priv(indio_dev);
+	struct inv_sensors_timestamp *ts = &sensor_st->ts;
 	struct device *dev = regmap_get_device(st->map);
 	unsigned int sensor;
 	unsigned int *watermark;
@@ -392,6 +394,8 @@ static int inv_icm42600_buffer_postdisable(struct iio_dev *indio_dev)
 
 	mutex_lock(&st->lock);
 
+	inv_sensors_timestamp_apply_odr(ts, 0, 0, 0);
+
 	ret = inv_icm42600_buffer_set_fifo_en(st, st->fifo.en & ~sensor);
 	if (ret)
 		goto out_unlock;

---
base-commit: 62b44ebc1f2c71db3ca2d4737c52e433f6f03038
change-id: 20260130-inv-icm42600-fix-odr-change-when-turning-buffer-off-3ba36f794cb7

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

