From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 03 Sep 2026 21:37:13 +0200
Subject: [PATCH] iio: imu: inv_icm42600: fix odr change not caught in
 certain cases
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-iio-imu-inv-icm42600-fix-odr-change-never-caught-v1-1-029c5f1cbce2@tdk.com>
X-B4-Tracking: v=1; b=H4sIAGjMmWoC/y2NwQqDMBBEf0X23IU0tYr9leIhJquuYFISEwriv
 3fbenzDzLwdEkWmBI9qh0iFEwcvcL1UYGfjJ0J2wqCVblSnbsgckNeM7AuyXWuJFY78xuAinhN
 PhQRMnuYNB9foutV346gFuX1FkvpP+ez/nPKwkN2+HjiOD6/NEpOUAAAA
X-Change-ID: 20260903-iio-imu-inv-icm42600-fix-odr-change-never-caught-bd624725ade7
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, stable@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788464239; l=2940;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=m60S/Iw6rtSEbJaApo5jUI0iF3VazngX65yETOcKHwE=;
 b=w9aaIbjDwjHyWh2vnYmdg7uSe/Z5FtSOJUuNtoDF944JZ7VLjbzR5zlMVdP5tnpRYSzShiv5R
 +pdmEs+el5vAuIShf+0fdu1LFJ0Ik6SZJe0qKkWiulg7tZuj16H8296
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When using both accel and gyro with different frequencies, the ODR
change flag in the FIFO header can be sometime in a packet with
invalid data. Since we are ignoring these packets, we miss the ODR
change and any further change are blocked until sensor is turned off.

Fix this by moving the packet data validity check after the ODR change
flag check.

Fixes: ec74ae9fd37c ("iio: imu: inv_icm42600: add accurate timestamping")
Cc: stable@vger.kernel.org
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c | 8 ++++----
 drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c  | 8 ++++----
 2 files changed, 8 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
index 3197081a808a..65d29de8ecf9 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
@@ -1235,15 +1235,15 @@ int inv_icm42600_accel_parse_fifo(struct iio_dev *indio_dev)
 		if (size <= 0)
 			return size;
 
-		/* skip packet if no accel data or data is invalid */
-		if (accel == NULL || !inv_icm42600_fifo_is_data_valid(accel))
-			continue;
-
 		/* update odr */
 		if (odr & INV_ICM42600_SENSOR_ACCEL)
 			inv_sensors_timestamp_apply_odr(ts, st->fifo.period,
 							st->fifo.nb.total, no);
 
+		/* skip packet if no accel data or data is invalid */
+		if (accel == NULL || !inv_icm42600_fifo_is_data_valid(accel))
+			continue;
+
 		memcpy(&buffer.accel, accel, sizeof(buffer.accel));
 		/* convert 8 bits FIFO temperature in high resolution format */
 		buffer.temp = temp ? (*temp * 64) : 0;
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
index 9de5c383665f..4e20d61d897b 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
@@ -816,15 +816,15 @@ int inv_icm42600_gyro_parse_fifo(struct iio_dev *indio_dev)
 		if (size <= 0)
 			return size;
 
-		/* skip packet if no gyro data or data is invalid */
-		if (gyro == NULL || !inv_icm42600_fifo_is_data_valid(gyro))
-			continue;
-
 		/* update odr */
 		if (odr & INV_ICM42600_SENSOR_GYRO)
 			inv_sensors_timestamp_apply_odr(ts, st->fifo.period,
 							st->fifo.nb.total, no);
 
+		/* skip packet if no gyro data or data is invalid */
+		if (gyro == NULL || !inv_icm42600_fifo_is_data_valid(gyro))
+			continue;
+
 		memcpy(&buffer.gyro, gyro, sizeof(buffer.gyro));
 		/* convert 8 bits FIFO temperature in high resolution format */
 		buffer.temp = temp ? (*temp * 64) : 0;

---
base-commit: 183f05a300eab41e4578337eac59335730dfebf9
change-id: 20260903-iio-imu-inv-icm42600-fix-odr-change-never-caught-bd624725ade7

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

